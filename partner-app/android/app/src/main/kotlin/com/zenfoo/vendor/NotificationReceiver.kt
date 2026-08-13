package com.zenfoo.vendor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class NotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("NotificationReceiver", "Received broadcast: ${intent.action}")

        // When notification arrives, launch the app
        if (intent.action == "com.zenfoo.vendor.NOTIFICATION_RECEIVED") {
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            context.startActivity(launchIntent)
            Log.d("NotificationReceiver", "App launched from notification")
        }
    }
}
