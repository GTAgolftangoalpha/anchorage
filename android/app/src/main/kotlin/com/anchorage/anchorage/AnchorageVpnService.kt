package com.anchorage.anchorage

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.VpnService
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import android.provider.Settings as AndroidSettings
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.util.concurrent.TimeUnit

class AnchorageVpnService : VpnService() {

    private var vpnInterface: ParcelFileDescriptor? = null
    private var vpnThread: Thread? = null

    // Volatile reference — loadBlocklist() swaps in a new HashSet atomically so
    // the packet-loop thread always sees a consistent snapshot.
    @Volatile private var blocklist: HashSet<String> = HashSet()

    // Custom user-added domains — separate from the main blocklist for hot-reload.
    @Volatile private var customBlocklist: HashSet<String> = HashSet()

    // Set to true once the blocklist is fully loaded and ready to query.
    // While false, DNS responses return SERVFAIL — nothing resolves until VPN
    // protection is fully armed, closing the boot startup window.
    @Volatile private var blocklistReady = false

    // Post overlay startService to main thread — calling from the VPN packet-loop
    // background thread is silently dropped on Samsung Android 14.
    private val mainHandler = Handler(Looper.getMainLooper())

    // Debounce: don't spam OverlayService for rapid DNS retries on same domain
    private var lastBlockedDomain = ""
    private var lastBlockedTime = 0L

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: "(null)"
        Log.d(TAG, "onStartCommand: action=$action")
        when (intent?.action) {
            ACTION_STOP -> {
                stopVpn()
                return START_NOT_STICKY
            }
            else -> startVpn()
        }
        return START_STICKY
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy: cleaning up")
        isRunning = false
        blocklistReady = false
        activeInstance = null
        vpnThread?.interrupt()
        try { vpnInterface?.close() } catch (_: Exception) {}
        vpnInterface = null
        super.onDestroy()
    }

    override fun onRevoke() {
        Log.w(TAG, "onRevoke: VPN permission revoked by system")
        isRunning = false
        stopSelf()
    }

    // ── Start / Stop ──────────────────────────────────────────────────────────

    private fun startVpn() {
        Log.d(TAG, "startVpn: isRunning=$isRunning")
        if (isRunning) {
            Log.d(TAG, "startVpn: already running — no-op")
            return
        }

        postForegroundNotification()

        activeInstance = this

        // Load blocklist in a background thread in parallel with tunnel setup.
        // Until loadBlocklist() completes and sets blocklistReady=true, all DNS
        // queries return SERVFAIL — the network is inaccessible but protected.
        blocklistReady = false
        Thread({
            try {
                loadBlocklist()
                loadCustomBlocklist()
            } catch (e: Exception) {
                Log.e(TAG, "startVpn: blocklist load failed", e)
            }
        }, "anchorage-blocklist").start()

        // Establish the VPN tunnel immediately — routes are active within ~1 second.
        // The packet loop starts here and handles SERVFAIL until the blocklist is ready.
        Thread({
            try {
                establishTunnel()
            } catch (e: Exception) {
                Log.e(TAG, "startVpn: tunnel failed", e)
            }
        }, "anchorage-vpn").start()
    }

    private fun stopVpn() {
        Log.d(TAG, "stopVpn: stopping")
        isRunning = false
        blocklistReady = false
        vpnThread?.interrupt()
        try { vpnInterface?.close() } catch (_: Exception) {}
        vpnInterface = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun establishTunnel() {
        Log.d(TAG, "establishTunnel: building VPN interface")
        try {
            val builder = Builder()
            builder.setSession("ANCHORAGE VPN")
            builder.addAddress("10.111.222.1", 24)
            builder.addDnsServer("10.111.222.2")
            builder.setBlocking(true)

            // DNS-only routing: only route the fake DNS IP and the blocked-domain
            // sentinel IP through TUN. All real traffic bypasses the VPN entirely —
            // no TCP proxying is needed and browser performance is unaffected.
            //
            // Flow for blocked domains:
            //   DNS query → 10.111.222.2:53 → TUN → we return A=10.111.222.3
            //   Chrome TCP SYN → 10.111.222.3 → TUN → we send RST
            //   Overlay fires at DNS-query time via notifyDomainBlocked()
            //
            // Flow for allowed domains:
            //   DNS query → 10.111.222.2:53 → TUN → we forward to 8.8.8.8 → real IP
            //   Chrome TCP → real IP → bypasses TUN → normal internet
            builder.addRoute("10.111.222.2", 32)   // intercept DNS queries
            builder.addRoute("10.111.222.3", 32)   // intercept connections to blocked domains

            Log.d(TAG, "establishTunnel: calling establish()")
            vpnInterface = builder.establish()

            if (vpnInterface == null) {
                Log.e(TAG, "establishTunnel: establish() returned null — VPN permission not held!")
                stopSelf()
                return
            }

            isRunning = true
            Log.d(TAG, "establishTunnel: TUN fd=${vpnInterface!!.fd} — VPN is UP")

            scheduleBlocklistUpdate()
            runPacketLoop()
        } catch (e: Exception) {
            Log.e(TAG, "establishTunnel: FAILED", e)
            isRunning = false
            stopSelf()
        }
    }

    // ── Packet loop ───────────────────────────────────────────────────────────

    private fun runPacketLoop() {
        val fd = vpnInterface?.fileDescriptor ?: run {
            Log.e(TAG, "runPacketLoop: null file descriptor")
            return
        }
        val input = FileInputStream(fd)
        val output = FileOutputStream(fd)
        val buffer = ByteArray(32767)
        var packetCount = 0L

        Log.d(TAG, "runPacketLoop: entering loop")
        vpnThread = Thread.currentThread()

        while (isRunning) {
            val len = try {
                input.read(buffer)
            } catch (e: Exception) {
                if (isRunning) Log.w(TAG, "runPacketLoop: read error — ${e.message}")
                break
            }

            if (len <= 0) continue

            packetCount++
            if (packetCount == 1L || packetCount % 500 == 0L) {
                Log.d(TAG, "runPacketLoop: packet #$packetCount len=$len")
            }

            try {
                handlePacket(buffer.copyOf(len), output)
            } catch (e: Exception) {
                Log.w(TAG, "runPacketLoop: handlePacket error — ${e.message}")
            }
        }

        Log.d(TAG, "runPacketLoop: exited after $packetCount packets")
    }

    private fun handlePacket(packet: ByteArray, output: FileOutputStream) {
        if (packet.size < 20) return
        val ipVersion = (packet[0].toInt() and 0xF0) shr 4
        if (ipVersion != 4) return

        when (packet[9].toInt() and 0xFF) {
            17 -> handleUdp(packet, output)
            6  -> handleTcp(packet, output)
        }
    }

    // ── UDP handling ──────────────────────────────────────────────────────────

    private fun handleUdp(packet: ByteArray, output: FileOutputStream) {
        val ipHeaderLen = (packet[0].toInt() and 0x0F) * 4
        if (packet.size < ipHeaderLen + 8) return

        val destPort = ((packet[ipHeaderLen + 2].toInt() and 0xFF) shl 8) or
                (packet[ipHeaderLen + 3].toInt() and 0xFF)

        // With DNS-only routing, only DNS queries (UDP/53) arrive on 10.111.222.2.
        // Drop anything else (e.g. QUIC retries to 10.111.222.3).
        if (destPort != 53) return

        val dnsOffset = ipHeaderLen + 8
        if (packet.size <= dnsOffset) return
        handleDns(packet, packet.copyOfRange(dnsOffset, packet.size), output)
    }

    // ── DNS handling ──────────────────────────────────────────────────────────

    private fun handleDns(originalPacket: ByteArray, dns: ByteArray, output: FileOutputStream) {
        if (dns.size < 12) return

        val txId = ((dns[0].toInt() and 0xFF) shl 8) or (dns[1].toInt() and 0xFF)
        val questionCount = ((dns[4].toInt() and 0xFF) shl 8) or (dns[5].toInt() and 0xFF)
        if (questionCount == 0) return

        val domain = parseDnsName(dns, 12) ?: return
        val nameLen = dnsNameByteLength(dns, 12)
        val qTypeOffset = 12 + nameLen
        if (qTypeOffset + 3 >= dns.size) return
        val qType = ((dns[qTypeOffset].toInt() and 0xFF) shl 8) or (dns[qTypeOffset + 1].toInt() and 0xFF)

        // Whitelist always wins — forward even while blocklist is still loading,
        // so Firebase/Google services are never disrupted during startup.
        if (isWhitelisted(domain)) {
            Log.v(TAG, "DNS ALLOWED (whitelist): $domain → forwarding")
            forwardDns(dns, originalPacket, output)
            return
        }

        // Blocklist still loading — return SERVFAIL so nothing resolves until
        // VPN protection is fully armed. Closes the boot startup window.
        if (!blocklistReady) {
            Log.d(TAG, "DNS SERVFAIL (loading): $domain")
            writeUdpResponse(originalPacket, buildServfailResponse(txId, dns), output)
            return
        }

        if (isBlocked(domain)) {
            Log.i(TAG, "DNS BLOCKED: $domain (qType=$qType) → ${ipStr(BLOCKED_DOMAIN_IP)}")
            val response = buildBlockedDnsResponse(txId, dns, BLOCKED_DOMAIN_IP)
            writeUdpResponse(originalPacket, response, output)
            notifyDomainBlocked(domain)
        } else {
            Log.d(TAG, "DNS query: $domain (qType=$qType) → forwarding")
            forwardDns(dns, originalPacket, output)
        }
    }

    private fun buildServfailResponse(txId: Int, query: ByteArray): ByteArray {
        val baos = ByteArrayOutputStream()
        val dos = DataOutputStream(baos)
        val nameLen = dnsNameByteLength(query, 12)
        val qEnd = (12 + nameLen + 4).coerceAtMost(query.size)
        dos.writeShort(txId)
        dos.writeShort(0x8182)   // QR=1, RD=1, RA=1, RCODE=2 (SERVFAIL)
        dos.writeShort(1); dos.writeShort(0); dos.writeShort(0); dos.writeShort(0)
        dos.write(query, 12, qEnd - 12)
        return baos.toByteArray()
    }

    /** Returns true if the domain matches the permanent whitelist and must always resolve normally. */
    private fun isWhitelisted(domain: String): Boolean {
        val d = domain.lowercase().trimEnd('.')
        return WHITELIST_SUFFIXES.any { suffix -> d == suffix || d.endsWith(".$suffix") }
    }

    private fun isBlocked(domain: String): Boolean {
        var d = domain.lowercase().trimEnd('.')
        while (d.contains('.')) {
            if (blocklist.contains(d) || customBlocklist.contains(d)) return true
            d = d.substringAfter('.')
        }
        return false
    }

    private fun parseDnsName(data: ByteArray, startOffset: Int): String? {
        val sb = StringBuilder()
        var i = startOffset
        var jumped = false

        while (i < data.size) {
            val len = data[i].toInt() and 0xFF
            when {
                len == 0 -> break
                (len and 0xC0) == 0xC0 -> {
                    if (i + 1 >= data.size) return null
                    val ptr = ((len and 0x3F) shl 8) or (data[i + 1].toInt() and 0xFF)
                    if (!jumped) { i += 2 }
                    i = ptr
                    jumped = true
                }
                else -> {
                    i++
                    if (i + len > data.size) return null
                    if (sb.isNotEmpty()) sb.append('.')
                    sb.append(String(data, i, len, Charsets.US_ASCII))
                    i += len
                }
            }
        }
        return sb.toString().ifEmpty { null }
    }

    private fun dnsNameByteLength(data: ByteArray, startOffset: Int): Int {
        var i = startOffset
        while (i < data.size) {
            val len = data[i].toInt() and 0xFF
            if (len == 0) return i - startOffset + 1
            if ((len and 0xC0) == 0xC0) return i - startOffset + 2
            i += len + 1
        }
        return i - startOffset
    }

    private fun buildBlockedDnsResponse(txId: Int, query: ByteArray, ip: ByteArray): ByteArray {
        val baos = ByteArrayOutputStream()
        val dos = DataOutputStream(baos)

        val nameLen = dnsNameByteLength(query, 12)
        val qEnd = (12 + nameLen + 4).coerceAtMost(query.size)

        dos.writeShort(txId)
        dos.writeShort(0x8180)  // QR=1, AA=1, RD=1, RA=1, RCODE=0
        dos.writeShort(1); dos.writeShort(1); dos.writeShort(0); dos.writeShort(0)
        dos.write(query, 12, qEnd - 12)
        dos.writeShort(0xC00C.toShort().toInt())
        dos.writeShort(1); dos.writeShort(1)
        dos.writeInt(60)
        dos.writeShort(4)
        dos.write(ip)

        return baos.toByteArray()
    }

    private fun forwardDns(dnsQuery: ByteArray, originalPacket: ByteArray, output: FileOutputStream) {
        Thread({
            try {
                val sock = DatagramSocket()
                protect(sock)
                sock.soTimeout = 3_000
                sock.send(DatagramPacket(dnsQuery, dnsQuery.size, InetAddress.getByName("8.8.8.8"), 53))
                val buf = ByteArray(4096)
                val resp = DatagramPacket(buf, buf.size)
                sock.receive(resp)
                sock.close()
                writeUdpResponse(originalPacket, resp.data.copyOf(resp.length), output)
            } catch (e: Exception) {
                Log.w(TAG, "forwardDns: ${e.message}")
            }
        }, "anchorage-dns-fwd").start()
    }

    private fun writeUdpResponse(originalPacket: ByteArray, dnsData: ByteArray, output: FileOutputStream) {
        val ipHeaderLen = (originalPacket[0].toInt() and 0x0F) * 4
        val srcIp = originalPacket.copyOfRange(12, 16)
        val srcPort = ((originalPacket[ipHeaderLen].toInt() and 0xFF) shl 8) or
                (originalPacket[ipHeaderLen + 1].toInt() and 0xFF)
        writeUdpPacket(FAKE_DNS_IP, 53, srcIp, srcPort, dnsData, output)
    }

    private fun writeUdpPacket(
        srcIp: ByteArray, srcPort: Int,
        dstIp: ByteArray, dstPort: Int,
        data: ByteArray,
        output: FileOutputStream
    ) {
        val totalLen = 20 + 8 + data.size
        val pkt = ByteArray(totalLen)

        pkt[0] = 0x45.toByte(); pkt[1] = 0
        pkt[2] = (totalLen shr 8).toByte(); pkt[3] = (totalLen and 0xFF).toByte()
        pkt[4] = 0; pkt[5] = 1; pkt[6] = 0x40; pkt[7] = 0
        pkt[8] = 64; pkt[9] = 17; pkt[10] = 0; pkt[11] = 0
        System.arraycopy(srcIp, 0, pkt, 12, 4)
        System.arraycopy(dstIp, 0, pkt, 16, 4)
        val chk = ipChecksum(pkt, 20)
        pkt[10] = (chk shr 8).toByte(); pkt[11] = (chk and 0xFF).toByte()

        pkt[20] = (srcPort shr 8).toByte(); pkt[21] = (srcPort and 0xFF).toByte()
        pkt[22] = (dstPort shr 8).toByte(); pkt[23] = (dstPort and 0xFF).toByte()
        val udpLen = 8 + data.size
        pkt[24] = (udpLen shr 8).toByte(); pkt[25] = (udpLen and 0xFF).toByte()
        pkt[26] = 0; pkt[27] = 0

        System.arraycopy(data, 0, pkt, 28, data.size)
        synchronized(output) { output.write(pkt) }
    }

    // ── TCP handling ──────────────────────────────────────────────────────────
    //
    // With DNS-only routing, the only TCP packets that arrive here are connections
    // to BLOCKED_DOMAIN_IP (10.111.222.3). RST all SYN packets — the overlay
    // launched by notifyDomainBlocked() handles the user-facing UX.

    private fun handleTcp(packet: ByteArray, output: FileOutputStream) {
        val ipHeaderLen = (packet[0].toInt() and 0x0F) * 4
        if (packet.size < ipHeaderLen + 20) return

        val flags = packet[ipHeaderLen + 13].toInt() and 0xFF
        if ((flags and 0x02) == 0) return  // only act on SYN

        val srcIp = packet.copyOfRange(12, 16)
        val dstIp = packet.copyOfRange(16, 20)
        val srcPort = ((packet[ipHeaderLen].toInt() and 0xFF) shl 8) or
                (packet[ipHeaderLen + 1].toInt() and 0xFF)
        val dstPort = ((packet[ipHeaderLen + 2].toInt() and 0xFF) shl 8) or
                (packet[ipHeaderLen + 3].toInt() and 0xFF)
        val seqNum = ((packet[ipHeaderLen + 4].toLong() and 0xFF) shl 24) or
                ((packet[ipHeaderLen + 5].toLong() and 0xFF) shl 16) or
                ((packet[ipHeaderLen + 6].toLong() and 0xFF) shl 8) or
                (packet[ipHeaderLen + 7].toLong() and 0xFF)

        Log.d(TAG, "TCP RST blocked domain ${ipStr(dstIp)}:$dstPort")
        sendTcpRst(srcIp, srcPort, dstIp, dstPort, (seqNum + 1).toInt(), output)
    }

    // ── Notify domain blocked ─────────────────────────────────────────────────

    /**
     * Shows the ANCHORAGE blocked-domain overlay over the user's current app.
     * Debounced to 3 seconds per domain to avoid spamming on rapid DNS retries.
     * Also invokes [blockedDomainListener] (wired to Flutter MethodChannel by MainActivity).
     */
    private fun notifyDomainBlocked(domain: String) {
        val now = System.currentTimeMillis()
        if (domain == lastBlockedDomain && now - lastBlockedTime < 3_000) return
        lastBlockedDomain = domain
        lastBlockedTime = now

        // Don't show the blocked-domain overlay when ANCHORAGE itself is in the foreground.
        // Our own SDKs (Firebase logging, Braze) may query domains that are in the blocklist;
        // showing an overlay over our own UI would be confusing and incorrect.
        // Only trust the foreground data if it was updated recently — stale data means the
        // guard lost track of the foreground app and we should NOT suppress the overlay.
        val foregroundFresh = now - AppGuardService.lastKnownForegroundTime < FOREGROUND_STALE_MS
        if (foregroundFresh && AppGuardService.lastKnownForeground == packageName) {
            Log.d(TAG, "notifyDomainBlocked: ANCHORAGE in foreground — suppressing overlay for '$domain'")
            blockedDomainListener?.invoke(domain)
            return
        }

        // Suppress overlay for known infrastructure/analytics domains that appear in the
        // Steven Black list for ad-network reasons but are not actual porn content.
        // Only real porn domains should produce a user-visible intercept overlay.
        if (isInfrastructureDomain(domain)) {
            Log.d(TAG, "notifyDomainBlocked: infrastructure domain '$domain' blocked silently")
            blockedDomainListener?.invoke(domain)
            return
        }

        // Post to main thread — startService from VPN packet-loop background thread
        // is silently dropped on Samsung Android 14.
        mainHandler.post {
            if (AndroidSettings.canDrawOverlays(this)) {
                try {
                    startService(Intent(this, OverlayService::class.java).apply {
                        putExtra(OverlayService.EXTRA_DOMAIN, domain)
                    })
                    Log.i(TAG, "notifyDomainBlocked: started OverlayService for '$domain'")
                } catch (e: Exception) {
                    Log.w(TAG, "notifyDomainBlocked: OverlayService start failed: ${e.message}")
                }
            } else {
                Log.w(TAG, "notifyDomainBlocked: overlay permission not granted — skipping overlay")
            }
        }

        blockedDomainListener?.invoke(domain)
    }

    /**
     * Returns true for known infrastructure/analytics domains that appear in the Steven Black
     * blocklist for ad-network reasons but are not porn content — these are blocked silently
     * (DNS blocked, TCP RST'd) without showing a user-visible overlay.
     */
    private fun isInfrastructureDomain(domain: String): Boolean {
        val d = domain.lowercase().trimEnd('.')
        return INFRASTRUCTURE_SUFFIXES.any { suffix -> d == suffix || d.endsWith(".$suffix") }
    }

    // ── TCP RST ───────────────────────────────────────────────────────────────

    private fun sendTcpRst(
        clientIp: ByteArray, clientPort: Int,
        serverIp: ByteArray, serverPort: Int,
        ackNum: Int,
        output: FileOutputStream
    ) {
        val pkt = ByteArray(40)
        pkt[0] = 0x45.toByte(); pkt[1] = 0; pkt[2] = 0; pkt[3] = 40
        pkt[4] = 0; pkt[5] = 2; pkt[6] = 0x40; pkt[7] = 0
        pkt[8] = 64; pkt[9] = 6; pkt[10] = 0; pkt[11] = 0
        System.arraycopy(serverIp, 0, pkt, 12, 4)
        System.arraycopy(clientIp, 0, pkt, 16, 4)
        val ipChk = ipChecksum(pkt, 20)
        pkt[10] = (ipChk shr 8).toByte(); pkt[11] = (ipChk and 0xFF).toByte()

        pkt[20] = (serverPort shr 8).toByte(); pkt[21] = (serverPort and 0xFF).toByte()
        pkt[22] = (clientPort shr 8).toByte(); pkt[23] = (clientPort and 0xFF).toByte()
        pkt[24] = 0; pkt[25] = 0; pkt[26] = 0; pkt[27] = 0
        pkt[28] = (ackNum shr 24).toByte()
        pkt[29] = ((ackNum shr 16) and 0xFF).toByte()
        pkt[30] = ((ackNum shr 8) and 0xFF).toByte()
        pkt[31] = (ackNum and 0xFF).toByte()
        pkt[32] = 0x50.toByte()
        pkt[33] = 0x14.toByte()  // RST + ACK
        pkt[34] = 0; pkt[35] = 0; pkt[36] = 0; pkt[37] = 0; pkt[38] = 0; pkt[39] = 0

        synchronized(output) { output.write(pkt) }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun ipChecksum(header: ByteArray, len: Int): Int {
        var sum = 0; var i = 0
        while (i < len) {
            sum += ((header[i].toInt() and 0xFF) shl 8) or
                    (if (i + 1 < len) header[i + 1].toInt() and 0xFF else 0)
            i += 2
        }
        while (sum shr 16 != 0) sum = (sum and 0xFFFF) + (sum shr 16)
        return sum.inv() and 0xFFFF
    }

    private fun ipStr(ip: ByteArray): String =
        "${ip[0].toInt() and 0xFF}.${ip[1].toInt() and 0xFF}.${ip[2].toInt() and 0xFF}.${ip[3].toInt() and 0xFF}"

    // ── Blocklist ─────────────────────────────────────────────────────────────

    private fun loadBlocklist() {
        val start = System.currentTimeMillis()
        val updated = File(filesDir, "blocklist.txt")
        val stream = if (updated.exists()) {
            Log.d(TAG, "loadBlocklist: loading updated list (${updated.length()} bytes)")
            updated.inputStream()
        } else {
            Log.d(TAG, "loadBlocklist: loading bundled asset")
            assets.open("blocklist.txt")
        }
        // Build into a new HashSet and assign atomically — safe because the
        // volatile write is visible to the packet-loop thread immediately.
        val newList = HashSet<String>(200_000)
        stream.bufferedReader().use { reader ->
            reader.lineSequence()
                .map { it.trim() }
                .filter { it.isNotEmpty() && !it.startsWith('#') }
                .forEach { newList.add(it) }
        }
        blocklist = newList
        blocklistReady = true
        val elapsed = System.currentTimeMillis() - start
        Log.d(TAG, "loadBlocklist: loaded ${blocklist.size} domains in ${elapsed}ms — VPN fully armed")
    }

    private fun loadCustomBlocklist() {
        val file = File(filesDir, "custom_blocklist.txt")
        if (!file.exists()) {
            Log.d(TAG, "loadCustomBlocklist: no custom blocklist file")
            return
        }
        val newList = HashSet<String>()
        file.bufferedReader().use { reader ->
            reader.lineSequence()
                .map { it.trim().lowercase() }
                .filter { it.isNotEmpty() }
                .forEach { newList.add(it) }
        }
        customBlocklist = newList
        Log.d(TAG, "loadCustomBlocklist: loaded ${newList.size} custom domains")
    }

    private fun scheduleBlocklistUpdate() {
        val req = PeriodicWorkRequestBuilder<BlocklistUpdateWorker>(14, TimeUnit.DAYS).build()
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "blocklist_update", ExistingPeriodicWorkPolicy.KEEP, req
        )
        Log.d(TAG, "scheduleBlocklistUpdate: enqueued 14-day periodic work")
    }

    // ── Foreground notification ───────────────────────────────────────────────

    private fun postForegroundNotification() {
        val nm = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (nm.getNotificationChannel(CHANNEL_ID) == null) {
            NotificationChannel(CHANNEL_ID, "ANCHORAGE VPN", NotificationManager.IMPORTANCE_LOW).apply {
                description = "ANCHORAGE is actively protecting you"
                setShowBadge(false)
            }.also { nm.createNotificationChannel(it) }
        }
        val pi = PendingIntent.getActivity(this, 0,
            Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ANCHORAGE is protecting you ⚓")
            .setContentText("VPN filter active — explicit content blocked")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pi)
            .setOngoing(true).setSilent(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SYSTEM_EXEMPTED)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    override fun onBind(intent: Intent?) = super.onBind(intent)

    companion object {
        const val ACTION_START = "com.anchorage.anchorage.VPN_START"
        const val ACTION_STOP  = "com.anchorage.anchorage.VPN_STOP"

        private const val TAG = "AnchorageVPN"
        private const val NOTIFICATION_ID = 1002
        private const val CHANNEL_ID = "anchorage_vpn"

        /**
         * Max age of [AppGuardService.lastKnownForegroundTime] before we consider
         * the foreground data stale. When stale, do NOT suppress VPN overlays —
         * the guard may have lost track of the foreground app (Samsung event expiry).
         */
        private const val FOREGROUND_STALE_MS = 30_000L

        // 10.111.222.2 — fake DNS server (DNS queries are routed here via addRoute)
        private val FAKE_DNS_IP = byteArrayOf(10, 111, 222.toByte(), 2)

        // 10.111.222.3 — returned in A record for blocked domains.
        // TCP connections here receive RST; the overlay handles the UX.
        private val BLOCKED_DOMAIN_IP = byteArrayOf(10, 111, 222.toByte(), 3)

        /**
         * Called when a domain is blocked. Wired by [MainActivity] to the Flutter
         * VPN MethodChannel so Flutter can track or display blocked domains.
         */
        @Volatile var blockedDomainListener: ((String) -> Unit)? = null

        @Volatile var isRunning = false

        /** Reference to the running service instance for hot-reload of custom blocklist. */
        @Volatile var activeInstance: AnchorageVpnService? = null

        fun reloadCustomDomains() {
            activeInstance?.loadCustomBlocklist()
        }

        /**
         * Permanent DNS whitelist — these domains always resolve normally, regardless of whether
         * they appear in the Steven Black blocklist. Use for critical infrastructure that must
         * never be blocked (Google services, Firebase, Apple, key analytics SDKs).
         */
        private val WHITELIST_SUFFIXES = setOf(
            "google.com", "googleapis.com", "gstatic.com", "googlevideo.com",
            "googleusercontent.com", "googletagmanager.com",
            "firebase.com", "firebaseapp.com", "firebaseio.com", "firebasestorage.googleapis.com",
            "goog", // Google's own TLD
            "braze.com",
            "revenuecat.com",
            "apple.com", "icloud.com", "mzstatic.com",
        )

        /**
         * Domain suffixes that should be blocked silently (no overlay).
         * These appear in the Steven Black list due to ad-network associations, not porn content.
         * Any domain whose root matches one of these will be DNS-blocked without showing
         * the user a visible interception overlay.
         */
        private val INFRASTRUCTURE_SUFFIXES = setOf(
            // Google / Firebase
            "googleapis.com", "gstatic.com", "google.com", "googlevideo.com",
            "firebase.com", "firebaseapp.com", "firebaseio.com",
            "crashlytics.com", "app-measurement.com",
            "googletagmanager.com", "doubleclick.net",
            "googleadservices.com", "googlesyndication.com", "2mdn.net",
            // Analytics / marketing SDKs
            "braze.com", "branch.io",
            "facebook.com", "fbcdn.net",
            "appsflyer.com", "adjust.com", "kochava.com",
            "mixpanel.com", "amplitude.com", "segment.io", "segment.com",
        )
    }
}
