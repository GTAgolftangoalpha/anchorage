package com.anchorage.anchorage

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/**
 * Downloads the latest Steven Black porn blocklist every 14 days and
 * stores it in [Context.getFilesDir]/blocklist.txt.
 *
 * [AnchorageVpnService] prefers this updated file over the bundled asset.
 */
class BlocklistUpdateWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        Log.d(TAG, "doWork: starting blocklist download")

        return try {
            val url = URL(BLOCKLIST_URL)
            val conn = url.openConnection() as HttpURLConnection
            conn.connectTimeout = 30_000
            conn.readTimeout = 90_000
            conn.connect()

            if (conn.responseCode != 200) {
                Log.w(TAG, "doWork: HTTP ${conn.responseCode} — will retry")
                return Result.retry()
            }

            val outputFile = File(applicationContext.filesDir, "blocklist.txt")
            val tmpFile = File(applicationContext.filesDir, "blocklist.tmp")

            conn.inputStream.bufferedReader().use { reader ->
                tmpFile.bufferedWriter().use { writer ->
                    reader.lineSequence()
                        .filter { it.startsWith("0.0.0.0 ") }
                        .map { it.split("\\s+".toRegex())[1] }
                        .filter { it != "0.0.0.0" && !it.startsWith("localhost") }
                        .forEach { domain ->
                            writer.write(domain)
                            writer.newLine()
                        }
                }
            }

            tmpFile.renameTo(outputFile)
            Log.d(TAG, "doWork: blocklist updated (${outputFile.length()} bytes)")

            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "doWork: download failed — ${e.message}")
            Result.retry()
        }
    }

    companion object {
        private const val TAG = "BlocklistWorker"
        private const val BLOCKLIST_URL =
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts"
    }
}
