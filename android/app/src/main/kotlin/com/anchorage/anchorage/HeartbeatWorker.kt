package com.anchorage.anchorage

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.tasks.await

/**
 * WorkManager worker that sends a heartbeat to Firebase every 4 hours.
 * Stores: user UUID, timestamp, vpn_active, guard_active.
 * Used by the accountability system to detect when ANCHORAGE is inactive.
 */
class HeartbeatWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            val auth = FirebaseAuth.getInstance()
            if (auth.currentUser == null) {
                auth.signInAnonymously().await()
            }
            val uid = auth.currentUser?.uid ?: return Result.retry()

            val vpnActive = AnchorageVpnService.isRunning
            val guardActive = AppGuardService.serviceRunning

            val data = hashMapOf(
                "uid" to uid,
                "timestamp" to com.google.firebase.firestore.FieldValue.serverTimestamp(),
                "vpn_active" to vpnActive,
                "guard_active" to guardActive,
                "client_time" to System.currentTimeMillis(),
            )

            FirebaseFirestore.getInstance()
                .collection("users")
                .document(uid)
                .collection("heartbeats")
                .document("latest")
                .set(data, SetOptions.merge())
                .await()

            Log.d(TAG, "Heartbeat sent: vpn=$vpnActive, guard=$guardActive")
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Heartbeat failed", e)
            Result.retry()
        }
    }

    companion object {
        private const val TAG = "HeartbeatWorker"
        const val WORK_NAME = "anchorage_heartbeat"
    }
}
