package com.zenfoo.partner

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import androidx.core.app.NotificationCompat

class FloatingService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var floatingView: View
    private var viewAdded = false
    private var initialX: Int = 0
    private var initialY: Int = 0
    private var initialTouchX: Float = 0f
    private var initialTouchY: Float = 0f

    companion object {
        private const val NOTIFICATION_ID = 9999
        private const val CHANNEL_ID = "FloatingServiceChannel"
        private const val PREF_NAME = "FloatingButtonPrefs"
        private const val KEY_POSITION_X = "position_x"
        private const val KEY_POSITION_Y = "position_y"
        private const val DEFAULT_X = 20
        private const val DEFAULT_Y = 300
    }

    override fun onCreate() {
        super.onCreate()

        // Start as foreground service
        startForeground(NOTIFICATION_ID, createNotification())

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        // Inflate the floating view layout
        floatingView = LayoutInflater.from(this)
            .inflate(R.layout.floating_button, null)

        // Set up window parameters
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.TOP or Gravity.END

        // Load saved position from SharedPreferences
        val prefs = getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        params.x = prefs.getInt(KEY_POSITION_X, DEFAULT_X)
        params.y = prefs.getInt(KEY_POSITION_Y, DEFAULT_Y)

        // Check if SYSTEM_ALERT_WINDOW permission is granted (Android 6.0+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                Log.e("FloatingService", "SYSTEM_ALERT_WINDOW permission not granted by user")
                Log.i("FloatingService", "User must enable 'Display over other apps' permission in settings")
                stopSelf()
                return
            }
        }

        // Add view to window manager with error handling
        try {
            windowManager.addView(floatingView, params)
            viewAdded = true
            Log.i("FloatingService", "Overlay window added successfully")
        } catch (e: WindowManager.BadTokenException) {
            // Handle permission denied for overlay window
            Log.e("FloatingService", "Failed to add overlay window (BadTokenException): ${e.message}")
            Log.e("FloatingService", "This may indicate overlay permission is not granted on this device")
            stopSelf()
            return
        } catch (e: Exception) {
            // Handle other exceptions
            Log.e("FloatingService", "Unexpected error adding overlay: ${e.message}", e)
            stopSelf()
            return
        }

        // Set up touch listener for dragging and clicking
        floatingView.setOnTouchListener(object : View.OnTouchListener {
            private var lastAction: Int = 0
            private val MAX_CLICK_DURATION = 200

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params.x
                        initialY = params.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        lastAction = MotionEvent.ACTION_DOWN
                        return true
                    }

                    MotionEvent.ACTION_MOVE -> {
                        params.x = initialX + (initialTouchX - event.rawX).toInt()
                        params.y = initialY + (event.rawY - initialTouchY).toInt()
                        windowManager.updateViewLayout(floatingView, params)
                        lastAction = MotionEvent.ACTION_MOVE
                        return true
                    }

                    MotionEvent.ACTION_UP -> {
                        if (lastAction == MotionEvent.ACTION_DOWN) {
                            // It's a click, open the app
                            openApp()
                        } else if (lastAction == MotionEvent.ACTION_MOVE) {
                            // User finished dragging, save the new position
                            savePosition(params.x, params.y)
                        }
                        return true
                    }
                }
                return false
            }
        })
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // START_NOT_STICKY (instead of Service's START_STICKY default) so the system
        // never resurrects the overlay on its own after the app process is gone.
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        // Driver swiped the app away from recents - the floating button must go with it.
        Log.i("FloatingService", "Task removed - stopping overlay")
        stopSelf()
    }

    private fun openApp() {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        intent?.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        intent?.putExtra("FROM_OVERLAY", true)
        startActivity(intent)
    }

    private fun savePosition(x: Int, y: Int) {
        val prefs = getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        prefs.edit().apply {
            putInt(KEY_POSITION_X, x)
            putInt(KEY_POSITION_Y, y)
            apply()
        }
    }

    private fun createNotification(): Notification {
        // Create notification channel for Android O and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Zenfoo Delivery Overlay",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows floating delivery icon"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }

        // Create intent to open app when notification is tapped
        val notificationIntent = packageManager.getLaunchIntentForPackage(packageName)
        notificationIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        notificationIntent?.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        // Build notification
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Zenfoo Delivery")
            .setContentText("You're online - Tap to open app")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        if (viewAdded && ::floatingView.isInitialized) {
            try {
                windowManager.removeView(floatingView)
                Log.i("FloatingService", "Overlay window removed successfully")
            } catch (e: Exception) {
                Log.e("FloatingService", "Error removing overlay view: ${e.message}")
            } finally {
                viewAdded = false
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
