<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Opening Zenfoo...</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #f5f5f5; display: flex; align-items: center; justify-content: center; min-height: 100vh; }
        .card { background: white; border-radius: 16px; padding: 40px 32px; text-align: center; max-width: 360px; width: 90%; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        .logo { font-size: 32px; font-weight: 800; color: #9AC444; margin-bottom: 8px; }
        .subtitle { color: #888; font-size: 14px; margin-bottom: 32px; }
        .product-name { font-size: 18px; font-weight: 600; color: #333; margin-bottom: 24px; }
        .btn { display: block; padding: 14px 24px; border-radius: 12px; font-size: 16px; font-weight: 600; text-decoration: none; margin-bottom: 12px; cursor: pointer; border: none; width: 100%; }
        .btn-primary { background: #9AC444; color: white; }
        .btn-secondary { background: #f0f0f0; color: #555; font-size: 14px; }
        .spinner { width: 36px; height: 36px; border: 3px solid #e0e0e0; border-top-color: #9AC444; border-radius: 50%; animation: spin 0.8s linear infinite; margin: 0 auto 20px; }
        @keyframes spin { to { transform: rotate(360deg); } }
    </style>
</head>
<body>
    <div class="card">
        <div class="logo">Zenfoo</div>
        <div class="subtitle">Fast Delivery App</div>
        <div class="spinner" id="spinner"></div>
        <div class="product-name" id="status">Opening in app...</div>
        <a href="{{ $playStoreUrl }}" class="btn btn-secondary" id="storeBtn" style="display:none">
            📲 Download Zenfoo App
        </a>
        <a href="{{ $appScheme }}" class="btn btn-primary" id="openBtn" style="display:none">
            Open in Zenfoo
        </a>
    </div>

    <script>
        var appScheme = "{{ $appScheme }}";
        var playStoreUrl = "{{ $playStoreUrl }}";
        var appOpened = false;

        // Try to open the app
        window.location.href = appScheme;

        // After 2 seconds, if still here, show Play Store option
        setTimeout(function() {
            if (!appOpened) {
                document.getElementById('spinner').style.display = 'none';
                document.getElementById('status').textContent = 'App not installed?';
                document.getElementById('storeBtn').style.display = 'block';
                document.getElementById('openBtn').style.display = 'block';
            }
        }, 2000);

        document.addEventListener('visibilitychange', function() {
            if (document.hidden) appOpened = true;
        });
    </script>
</body>
</html>
