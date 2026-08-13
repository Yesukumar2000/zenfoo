@php
use Illuminate\Support\Facades\Crypt;

    $logo="";
    $app_name="";
    $support_email="";
    $support_number="";
    $google_place_api_key = "";
    $google_map_api_key = "";
    $googleMapApiKey = "";
    $currency = "";
    $purchase_code = "";
    $logo_full_path = "";
    $delivery_boy_bonus_settings = 0;
    $isDemoMode = 0;

    $website_url = "";
    $copyright_details = "";



    // Firebase keys
    $apiKey = "";
    $authDomain = "";
    $projectId = "";
    $storageBucket = "";
    $messagingSenderId = "";
    $appId = "";
    $measurementId = "";
    $vapidKey = "";


    if(isInstalled()){
        $app_name = \App\Models\Setting::get_value('app_name');
        if($app_name == "" || $app_name == null){
            $app_name = "eGrocer";
        }
        $support_email = \App\Models\Setting::get_value('support_email');
        if($support_email == "" || $support_email == null){
            $support_email = "";
        }
        $support_number = \App\Models\Setting::get_value('support_number');
        if($support_number == "" || $support_number == null){
            $support_number = "";
        }

        $logo = \App\Models\Setting::get_value('logo') ?? "";
        if($logo!==""){
            $logo_full_path =  url('/').'/storage/'.$logo;
        }else{
            $logo_full_path =  asset('images/favicon.png');
        }

        $panel_login_background_img = \App\Models\Setting::get_value('panel_login_background_img') ?? "";
        $panel_login_background_img_full_path = '';
        if($panel_login_background_img!==""){
            $panel_login_background_img_full_path =  url('/').'/storage/'.$panel_login_background_img;
        }else{
            $panel_login_background_img_full_path =  asset('images/panel_login_background_img.jpg');
        }

        $google_place_api_key = \App\Models\Setting::get_value('google_place_api_key') ?? "";
        $google_map_api_key = \App\Models\Setting::get_value('google_map_api_key') ?? "";
        $apiKey = \App\Models\Setting::get_value('apiKey') ?? "";
        $googleMapApiKey = \App\Models\Setting::get_value('googleMapApiKey') ?? "";
        $currency = \App\Models\Setting::get_value('currency') ?? "$";
        $purchase_code = \App\Models\Setting::get_value('purchase_code') ?? "";
        $purchase_code = Crypt::encryptString($purchase_code);

        $website_url = \App\Models\Setting::get_value('website_url') ?? "";
        $copyright_details = \App\Models\Setting::get_value('copyright_details') ?? "";

        $delivery_boy_bonus_settings = \App\Models\Setting::get_value('delivery_boy_bonus_settings') ?? 0;

        // Firebase keys
        $authDomain = \App\Models\Setting::get_value('authDomain') ?? "";
        $projectId = \App\Models\Setting::get_value('projectId') ?? "";
        $storageBucket = \App\Models\Setting::get_value('storageBucket') ?? "";
        $messagingSenderId = \App\Models\Setting::get_value('messagingSenderId') ?? "";
        $appId = \App\Models\Setting::get_value('appId') ?? "";
        $measurementId = \App\Models\Setting::get_value('measurementId') ?? "";
        $vapidKey = \App\Models\Setting::get_value('fcm_vapid_key') ?? "";
        $isDemoMode = isDemoMode() ?? 0;
    }
@endphp

<!DOCTYPE html>
<html  class="{{ app()->isLocale('ar') ? 'rtl' : '' }}"> 
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}" />

    <title>{{ $app_name??'eGrocer' }}</title>
    <link rel="shortcut icon" href="{{ $logo_full_path }}">

<!-- Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700&display=swap" rel="stylesheet">

    <link rel="stylesheet" href="{{ asset('assets/css/bootstrap.css')}}">
    <link rel="stylesheet" href="{{ asset('assets/js/tinymce/content.min.css') }}">
    <link rel="stylesheet" href="{{ asset('assets/js/tinymce/skin.min.css') }}">


    <link rel="stylesheet" href="{{ asset('assets/vendors/iconly/bold.css') }}">
{{--        <link rel="stylesheet" href="{{ asset('assets/vendors/fontawesome/all.min.css') }}">--}}
    <link rel="stylesheet" href="{{ asset('assets/vendors/perfect-scrollbar/perfect-scrollbar.css') }}">
    <link rel="stylesheet" href="{{ asset('assets/vendors/bootstrap-icons/bootstrap-icons.css') }}">
    <link rel="stylesheet" href="{{ asset('assets/css/app.css') }}">
    <link rel="stylesheet" href="{{ asset('css/app.css') }}?v={{ filemtime(public_path('css/app.css')) }}">
    <link rel="stylesheet" href="{{ asset('assets/css/style.css') }}">
    <link rel="stylesheet" href="{{ asset('assets/css/boostrap_vue.css') }}">
    <link rel="stylesheet" href="{{ asset('assets/css/pages/form-element-select.css') }}">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.3/css/all.min.css" rel="stylesheet">
    <!-- Auth -->
    <link rel="stylesheet" href="{{ asset('assets/css/pages/auth.css') }}">
    <link rel="stylesheet" href="{{ asset('assets/css/pages/error.css') }}">
    <!-- Styles -->

    <link rel="stylesheet" href="{{ asset('assets/css/custom/common.css') }}">
    <link rel="stylesheet" href="{{ asset('assets/dark-mode/app-dark.css') }}">
  
    @if (isDemoMode())
        <!-- Google tag (gtag.js) -->
        <script async src="https://www.googletagmanager.com/gtag/js?id=G-CZZ7MV8RBB"></script>
        <script>
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());

            gtag('config', 'G-CZZ7MV8RBB');
        </script>
    @endif

</head>
<body >
{{-- <script src="{{ asset('assets/dark-mode/initTheme.js') }}"></script> --}}
<div id="app">
    <router-view></router-view>
</div>

<!--You can comment this or remove these 3 lines so popup update will stop-->
@if(auth()->user() && auth()->user()->role_id==1)
    @include('vendor.laraupdater.notification')
@endif

<script src="https://code.jquery.com/jquery-3.6.0.min.js" integrity="sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=" crossorigin="anonymous"></script>
<script src="{{ asset('assets/vendors/perfect-scrollbar/perfect-scrollbar.min.js') }}"></script>
<script src="{{ asset('assets/js/bootstrap.bundle.min.js') }}"></script>
<script src="{{ asset('assets/js/mazer.js') }}"></script>
<script src="{{ asset('assets/js/extensions/form-element-select.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/tinymce.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/theme.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/model.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/icons.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/anchor/plugin.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/autolink/plugin.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/charmap/plugin.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/codesample/plugin.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/emoticons/plugin.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/image/plugin.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/link/plugin.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/lists/plugin.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/media/plugin.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/searchreplace/plugin.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/table/plugin.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/visualblocks/plugin.min.js') }}"></script>
<script src="{{ asset('assets/js/tinymce/wordcount/plugin.min.js') }}"></script>

<script>
    window.baseUrl = '{{ url('/') }}';
    window.appName = "{{ $app_name }}";
    window.supportEmail = "{{ $support_email }}";
    window.supportNumber = "{{ $support_number }}";
    window.MapApiKey = "{{ $google_place_api_key }}";
    window.GoogleMapApiKey = "{{ $googleMapApiKey }}";
    window.appLogo = "{{ $logo }}";
    window.panelLoginBackgroundImg = "{{ $panel_login_background_img_full_path ?? '' }}";
    window.currency = "{{ $currency }}";
    window.isInstalled = "{{ isInstalled() }}";
    window.purchase_code = "{{ $purchase_code }}";

    window.websiteUrl = "{{ $website_url }}";
    window.copyrightDetails = "{!! $copyright_details !!}";


    window.deliveryBoyBonusSettings = "{{ $delivery_boy_bonus_settings }}";
    window.isDemo = "{{ $isDemoMode }}";
    window.currentVersion = "{{ currentVersion() }}";

    @auth
    /* Login*/
    window.UserPermissions = {!! json_encode(Auth::user()->allPermissions, true) !!};
    window.Role = "{!! Auth::user()->role->name !!}";
    @else
    /* Not Login*/
    window.UserPermissions = [];
    window.Role = '';
    @endauth
</script>
<script src="{{ asset('js/app.js') }}?v={{ filemtime(public_path('js/app.js')) }}"></script>
{{--<script src="{{ mix('js/app.js') }}" ></script>
<script src="{{ route('assets.lang')  }}"></script>
--}}

{{--<script src="{{ route('assets.lang')  }}"></script>--}}


@if(isInstalled())
{{--<script src="{{ route('assets.firebase-messaging-sw')  }}"></script>--}}
@endif
<!--Web Push-->
<!-- The core Firebase JS SDK is always required and must be listed first -->
<script src="https://www.gstatic.com/firebasejs/8.3.2/firebase.js"></script>

@php
    // Get the currently selected language from session or default config
   
    $lang = session('app_locale') ?? 'en';
if(isInstalled()){
    if(!$lang){
        $default = \DB::table('languages')->where('is_default', 1)->where('system_type', 4)->value('json_data');
        if (!$default) {
            $lang = session('app_locale', config('app.locale', 'en'));
       
    } else {
        // Get supported language details from DB
        $supported_language_id = \DB::table('languages')
            ->where('is_default',1)
            ->where('system_type', 4)
            ->value('supported_language_id');

        $code = \DB::table('supported_languages')->where('id', $supported_language_id)->value('code');
        $lang =$code;
    }
	}
    }
  
    session(['app_locale' => $lang]);
    $file = file_get_contents(resource_path('lang/' . $lang . '.json'));
@endphp

<script>

     let lang = JSON.stringify(<?php  echo $file; ?>);
     localStorage.setItem('language', lang);


    @if($apiKey!='' && $authDomain!='' && $authDomain!='' && $projectId!='' && $storageBucket!='' && $messagingSenderId!='' && $appId!='' && $measurementId!='')

        var firebaseConfig = {
            apiKey: "{{ $apiKey }}",
            authDomain: "{{ $authDomain }}",
            projectId: "{{ $projectId }}",
            storageBucket: "{{ $storageBucket }}",
            messagingSenderId: "{{ $messagingSenderId }}",
            appId: "{{ $appId }}",
            measurementId: "{{ $measurementId }}"
        };

        var firebaseCheck =  firebase.initializeApp(firebaseConfig);

        console.log('[FCM Debug] Checking notification support...');

        // Flag to prevent duplicate FCM registration
        var fcmStarted = false;
        var messaging = null;

        // Global function to initialize FCM - call this after login
        window.initFCM = function() {
            console.log('[FCM Debug] initFCM called');

            if (fcmStarted) {
                console.log('[FCM Debug] FCM already initialized, skipping...');
                return;
            }

            if (!('Notification' in window)) {
                console.log('[FCM Debug] Notification API not available');
                return;
            }

            if (!firebase.messaging.isSupported()) {
                console.log('[FCM Debug] Firebase messaging not supported');
                return;
            }

            console.log('[FCM Debug] Notification API available');
            console.log('[FCM Debug] firebase.messaging.isSupported():', firebase.messaging.isSupported());

            messaging = firebase.messaging();
            console.log('[FCM Debug] Messaging initialized, registering service worker...');

            // Register the service worker with update handling for Edge
            navigator.serviceWorker.register('/firebase-messaging-sw.js', { updateViaCache: 'none' })
                .then(function(registration) {
                    console.log('[FCM Debug] Service Worker registered with scope:', registration.scope);

                    // Force check for updates (important for Edge)
                    registration.update().then(function() {
                        console.log('[FCM Debug] Service Worker update check completed');
                    }).catch(function(e) {
                        console.log('[FCM Debug] Service Worker update check failed:', e);
                    });

                    // Wait for the service worker to be ready/active
                    if (registration.active) {
                        console.log('[FCM Debug] Service Worker already active');
                        registerFCMToken(registration);
                    } else {
                        console.log('[FCM Debug] Waiting for Service Worker to activate...');
                        registration.addEventListener('updatefound', function() {
                            const newWorker = registration.installing;
                            newWorker.addEventListener('statechange', function() {
                                if (newWorker.state === 'activated') {
                                    console.log('[FCM Debug] Service Worker activated');
                                    registerFCMToken(registration);
                                }
                            });
                        });
                        // Also try after a short delay as fallback
                        setTimeout(function() {
                            if (registration.active && !fcmStarted) {
                                registerFCMToken(registration);
                            }
                        }, 1000);
                    }

                    // Listen for controllerchange - handle when new SW takes over
                    navigator.serviceWorker.addEventListener('controllerchange', function() {
                        console.log('[FCM Debug] Service Worker controller changed - new version active');
                    });
                })
                .catch(function(error) {
                    console.error('[FCM Debug] Service Worker registration failed:', error);
                });
        };

        function registerFCMToken(swRegistration) {
            // Prevent duplicate calls
            if (fcmStarted) {
                console.log('[FCM Debug] FCM token already registered, skipping...');
                return;
            }

            @if($vapidKey == '')
            // getToken() cannot mint a web push token without the VAPID key, and the
            // error it throws is opaque. Fail loudly with the fix instead.
            console.error('[FCM Debug] No web push VAPID key configured. Set it in Settings > Firebase Settings; browser notifications stay off until then.');
            return;
            @endif

            fcmStarted = true;

            console.log('[FCM Debug] Requesting notification permission...');
            Notification.requestPermission()
                .then(function (permission) {
                    console.log('[FCM Debug] Permission result:', permission);
                    if (permission === 'granted') {
                        console.log('[FCM Debug] Permission granted, getting token...');
                        return messaging.getToken({
                            serviceWorkerRegistration: swRegistration,
                            vapidKey: '{{ $vapidKey }}'
                        });
                    } else {
                        throw new Error('Notification permission denied');
                    }
                })
                .then(function (token) {
                    if (!token) {
                        console.error('[FCM Debug] No token received');
                        return;
                    }
                    console.log('[FCM Debug] Token received:', token);
                    // Store FCM token in localStorage for logout cleanup
                    window.localStorage.setItem('fcm_token', token);
                    $.ajaxSetup({
                        headers: {
                            'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                        }
                    });
                    console.log('[FCM Debug] Sending token to server...');
                    $.ajax({
                        url: '{{ route("fcmToken") }}',
                        type: 'POST',
                        data: {
                            token: token
                        },
                        dataType: 'JSON',
                        success: function (response) {
                            console.log('[FCM Debug] Token saved successfully:', response);
                        },
                        error: function (error) {
                            console.error('[FCM Debug] Error saving token:', error);
                        },
                    });

                    // Setup message listener after token is registered
                    setupMessageListener();
                }).catch(function (error) {
                    console.error('[FCM Debug] Error in FCM flow:', error);
            });
        }

        function setupMessageListener() {
            if (!messaging) return;

                // Preload notification sound for faster playback
                var notificationSound = new Audio("{{ asset('assets/order_sound.wav') }}");
                notificationSound.load();

                // Enable sound after first user interaction (browser autoplay policy)
                var soundEnabled = false;
                document.addEventListener('click', function enableSound() {
                    notificationSound.play().then(function() {
                        notificationSound.pause();
                        notificationSound.currentTime = 0;
                        soundEnabled = true;
                        console.log('[FCM] Sound enabled after user interaction');
                    }).catch(function() {});
                    document.removeEventListener('click', enableSound);
                }, { once: true });

                messaging.onMessage(function (payload) {
                    console.log('[FCM] Foreground message received:', payload);

                    const notification = payload.data || {};
                    const title = notification.title || 'New Notification';
                    const body = notification.body || notification.message || '';

                    // Play notification sound
                    console.log('[FCM] Playing notification sound...');
                    notificationSound.currentTime = 0;
                    notificationSound.play().then(function() {
                        console.log('[FCM] Sound played successfully');
                    }).catch(function(e) {
                        console.log('[FCM] Sound blocked by browser:', e.message);
                        console.log('[FCM] Click anywhere on the page to enable sound');
                    });

                    // Show toastr notification for all foreground messages
                    toastr.options = {
                        "onclick": function() {
                            if (notification.click_action) {
                                // Navigate in same window instead of opening new tab
                                window.location.href = notification.click_action;
                            }
                        },
                        "showDuration": "60000",
                        "hideDuration": "20000",
                        "timeOut": "60000",
                        "extendedTimeOut": "10000",
                        "closeButton": true,
                    };
                    toastr.info(body, title);

                    // Show Windows native notification using Service Worker
                    if (Notification.permission === 'granted' && navigator.serviceWorker.controller) {
                        navigator.serviceWorker.ready.then(function(registration) {
                            registration.showNotification(title, {
                                body: body,
                                icon: notification.icon || '/images/favicon.png',
                                badge: '/images/favicon.png',
                                tag: 'zenfoo-fg-' + Date.now(),
                                requireInteraction: false,
                                data: notification
                            });
                        });
                    }
                });

            // Listen for messages from service worker (for debugging click events)
            navigator.serviceWorker.addEventListener('message', function(event) {
                console.log('[FCM Main] Message from Service Worker:', event.data);
                if (event.data && event.data.type === 'NOTIFICATION_CLICKED') {
                    console.log('[FCM Main] Notification was clicked! URL:', event.data.url);
                }
            });
        }

        // Auto-init FCM if user is already authenticated and not on login page
        @auth
        var isLoginPage = window.location.href.indexOf('/login') !== -1 || window.location.hash.indexOf('/login') !== -1;
        if (!isLoginPage) {
            console.log('[FCM Debug] User authenticated, auto-initializing FCM...');
            window.initFCM();
        }
        @endauth

    @endif
</script>

</body>
</html>
