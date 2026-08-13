package com.zenfoo.vendor

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle notification intent when app is reopened from notification
        if (intent.action == "FLUTTER_NOTIFICATION_CLICK") {
            setIntent(intent)
        }
    }
}
