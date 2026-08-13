<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class FirebaseApiController extends Controller
{
    public function index()
    {
        $firebase = CommonHelper::getFirebaseKeys();
        
        $filePath = base_path('config/firebase.json');
        $fileExists = file_exists($filePath);
        $firebase[] = [
            'variable' => 'file_exists',
            'value' => $fileExists ? '1' : '0'
        ];
        
        return CommonHelper::responseWithData($firebase);
    }

    public function save(Request $request)
    {
        $validator = Validator::make($request->all(),[
            'apiKey' => 'required',
            'authDomain' => 'required',
            'projectId' => 'required',
            'storageBucket' => 'required',
            'messagingSenderId' => 'required',
            'appId' => 'required',
            'measurementId' => 'required',
            'jsonFile' => $request->hasFile('jsonFile')?'mimes:json':'',
        ]);
        if ($validator->fails()) {

            return CommonHelper::responseError($validator->errors()->first());
        }

        if($request->hasFile('jsonFile'))
        {
            $file = $request->file('jsonFile');
            if( $file == false ) {
                return CommonHelper::responseError("Error in opening file");
            }
            $fileName = $file->getRealPath();
            $data = file_get_contents($fileName);
            $value = json_decode($data, true);
            $jsonFileValue = json_encode($value);
            file_put_contents(base_path('config/firebase.json'), $jsonFileValue);
        }

        foreach ($request->all() as $key => $value){
            $value = $value ?? " ";
            $setting = Setting::where('variable', $key)->first();
            if ($setting) {
                $setting->variable = $key;
                $setting->value = ($key=='jsonFile' && isset($jsonFileValue)) ? $jsonFileValue : $value;
                $setting->save();
            } else {
                $setting = new Setting();
                $setting->variable = $key;
                $setting->value = ($key=='jsonFile' && isset($jsonFileValue)) ? $jsonFileValue : $value;
                $setting->save();
            }
        }
        return CommonHelper::responseSuccess("Firebase Settings Saved Successfully!");
    }

    public function firebaseMessagingJsCode(){

        $apiKey = \App\Models\Setting::get_value('apiKey') ?? "";
        $projectId = \App\Models\Setting::get_value('projectId') ?? "";
        $messagingSenderId = \App\Models\Setting::get_value('messagingSenderId') ?? "";
        $appId = \App\Models\Setting::get_value('appId') ?? "";

        $jsCode = <<<JS
// Service Worker Version: 13.0 - Edge browser compatibility fix
importScripts("https://www.gstatic.com/firebasejs/8.3.2/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.3.2/firebase-messaging.js");

console.log('[SW v13] Service worker loaded - Edge compatible');

firebase.initializeApp({
    apiKey: "{$apiKey}",
    projectId: "{$projectId}",
    messagingSenderId: "{$messagingSenderId}",
    appId: "{$appId}",
});

const messaging = firebase.messaging();

// Store notification data globally for click handling
let lastNotificationData = null;

// Handle all push messages and show our own notification
// This ensures click handling works in ALL browsers (Chrome, Edge, Firefox)
self.addEventListener('push', function(event) {
    console.log('[SW v13] ====== PUSH EVENT RECEIVED ======');
    console.log('[SW v13] Event:', event);

    let data = {};
    let notificationPayload = null;

    if (event.data) {
        try {
            const payload = event.data.json();
            console.log('[SW v13] Payload:', JSON.stringify(payload));

            // Get data from various possible locations
            data = payload.data || {};

            // Check if there's a notification payload from FCM
            if (payload.notification) {
                notificationPayload = payload.notification;
                // Merge notification.data if exists
                if (payload.notification.data) {
                    data = { ...data, ...payload.notification.data };
                }
            }
        } catch(e) {
            console.log('[SW v13] Parse error:', e);
            // Try to get raw text
            try {
                console.log('[SW v13] Raw data:', event.data.text());
            } catch(e2) {}
        }
    } else {
        console.log('[SW v13] No event data!');
    }

    lastNotificationData = data;

    // Build notification options
    const title = (notificationPayload && notificationPayload.title) || data.title || 'New Notification';
    const body = (notificationPayload && notificationPayload.body) || data.body || data.message || '';
    const icon = (notificationPayload && notificationPayload.icon) || data.icon || '/images/favicon.png';

    // Use unique tag with timestamp to ensure each notification shows
    const uniqueTag = 'zenfoo-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);

    const options = {
        body: body,
        icon: icon,
        badge: '/images/favicon.png',
        tag: uniqueTag,
        data: data,  // This is crucial - stores click_action for notificationclick handler
        requireInteraction: true,  // Keep notification visible until user interacts (better for Edge)
        renotify: true,  // Important for Edge - ensures notification shows even with similar tag
        silent: false,
        vibrate: [200, 100, 200]  // Vibration pattern for mobile Edge
    };

    console.log('[SW v13] Showing notification:', title);
    console.log('[SW v13] Options:', JSON.stringify(options));

    // Show notification - use waitUntil to ensure it completes
    const notificationPromise = self.registration.showNotification(title, options)
        .then(function() {
            console.log('[SW v13] Notification shown successfully');
        })
        .catch(function(error) {
            console.error('[SW v13] Failed to show notification:', error);
        });

    event.waitUntil(notificationPromise);
});

// Helper function to notify all clients about events
function notifyAllClients(message) {
    clients.matchAll({ type: 'window', includeUncontrolled: true })
        .then(function(clientList) {
            clientList.forEach(function(client) {
                client.postMessage(message);
            });
        });
}

// Handle notification click - Version 13.0 with improved Edge support
self.addEventListener('notificationclick', function(event) {
    console.log('[SW v13] ====== NOTIFICATION CLICK EVENT ======');

    // Get the notification data BEFORE closing
    const data = event.notification.data || lastNotificationData || {};
    console.log('[SW v13] Notification data:', JSON.stringify(data));

    // Close notification first
    event.notification.close();

    // Get URL to open - ensure it's absolute
    let url = data.click_action || data.link || '';
    if (!url) {
        url = self.location.origin + '/dashboard';
    }
    // Make sure URL is absolute
    if (url && !url.startsWith('http')) {
        url = self.location.origin + (url.startsWith('/') ? '' : '/') + url;
    }
    console.log('[SW v13] Will open URL:', url);

    // Log to Laravel server (non-blocking)
    fetch(self.location.origin + '/log_notification_click', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            url: url,
            data: data,
            timestamp: new Date().toISOString(),
            event: 'notification_click',
            browser: navigator.userAgent
        })
    }).then(function(response) {
        console.log('[SW v13] Server log response:', response.status);
    }).catch(function(error) {
        console.log('[SW v13] Server log failed:', error);
    });

    // Focus existing window or open new one
    event.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true })
            .then(function(clientList) {
                console.log('[SW v13] Found ' + clientList.length + ' clients');
                // Try to find an existing window with same origin
                for (var i = 0; i < clientList.length; i++) {
                    var client = clientList[i];
                    console.log('[SW v13] Client URL:', client.url);
                    if (client.url.indexOf(self.location.origin) !== -1 && 'focus' in client) {
                        console.log('[SW v13] Focusing existing window and navigating');
                        return client.focus().then(function(focusedClient) {
                            if (focusedClient && 'navigate' in focusedClient) {
                                return focusedClient.navigate(url);
                            }
                        });
                    }
                }
                // No existing window found, open new one
                console.log('[SW v13] Opening new window');
                return clients.openWindow(url);
            })
            .then(function(windowClient) {
                console.log('[SW v13] Window operation completed');
            })
            .catch(function(error) {
                console.error('[SW v13] Failed to handle click:', error);
                // Fallback: try to open window anyway
                return clients.openWindow(url);
            })
    );
});

// Handle notification close (for debugging)
self.addEventListener('notificationclose', function(event) {
    console.log('[SW v13] Notification closed (dismissed):', event.notification.tag);
});

// Log when service worker activates - immediately claim all clients
self.addEventListener('activate', function(event) {
    console.log('[SW v13] Service worker activated');
    event.waitUntil(
        self.clients.claim().then(function() {
            console.log('[SW v13] Claimed all clients');
        })
    );
});

// Handle install event - skip waiting to activate immediately
self.addEventListener('install', function(event) {
    console.log('[SW v13] Service worker installing');
    event.waitUntil(self.skipWaiting());
});

console.log('[SW v13] Service worker script fully parsed');
JS;

        return response($jsCode, 200)
            ->header('Content-Type', 'application/javascript')
            ->header('Cache-Control', 'no-cache, no-store, must-revalidate, max-age=0')
            ->header('Pragma', 'no-cache')
            ->header('Expires', '0')
            ->header('Service-Worker-Allowed', '/');
    }
}
