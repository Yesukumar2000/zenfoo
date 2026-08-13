package com.zenfoo.partner

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "floating_button"
    private var methodChannel: MethodChannel? = null
    private var launchedFromOverlay: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Check if launched from overlay
        launchedFromOverlay = intent?.getBooleanExtra("FROM_OVERLAY", false) ?: false
    }

    override fun onDestroy() {
        // Activity is genuinely going away (back-out / finish), not a transient
        // recreation - make sure the floating button doesn't outlive it.
        if (isFinishing) {
            stopService(Intent(this, FloatingService::class.java))
        }
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Check if reopened from overlay
        val fromOverlay = intent.getBooleanExtra("FROM_OVERLAY", false)
        if (fromOverlay) {
            launchedFromOverlay = true
            // Notify Flutter that we're coming from overlay
            methodChannel?.invokeMethod("onOpenFromOverlay", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkPermission" -> {
                        val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            Settings.canDrawOverlays(this)
                        } else {
                            true
                        }
                        result.success(hasPermission)
                    }

                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            if (!Settings.canDrawOverlays(this)) {
                                val intent = Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName")
                                )
                                startActivity(intent)
                            }
                        }
                        result.success(true)
                    }

                    "startFloating" -> {
                        val serviceIntent = Intent(this, FloatingService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success(true)
                    }

                    "stopFloating" -> {
                        stopService(Intent(this, FloatingService::class.java))
                        result.success(true)
                    }

                    "wasLaunchedFromOverlay" -> {
                        val wasFromOverlay = launchedFromOverlay
                        launchedFromOverlay = false // Reset after reading
                        result.success(wasFromOverlay)
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
