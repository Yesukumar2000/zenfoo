<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Account Deletion Request</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background: #f5f5f5;
            color: #333;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }
        .card {
            background: #fff;
            width: 100%;
            max-width: 420px;
            border-radius: 16px;
            box-shadow: 0 4px 20px rgba(0,0,0,.1);
            padding: 36px 32px;
        }
        .logo { font-size: 30px; font-weight: 800; color: #9AC444; text-align: center; margin-bottom: 2px; }
        .brand-sub { color: #888; font-size: 13px; text-align: center; margin-bottom: 26px; }
        h1 { font-size: 20px; margin-bottom: 6px; color: #333; }
        p.sub { color: #888; font-size: 14px; margin-bottom: 24px; }
        label { display: block; font-size: 13px; font-weight: 600; margin: 14px 0 6px; color: #555; }
        input, textarea {
            width: 100%;
            padding: 12px;
            border: 1px solid #e0e0e0;
            border-radius: 12px;
            font-size: 15px;
            outline: none;
            font-family: inherit;
        }
        textarea { resize: vertical; }
        input:focus, textarea:focus { border-color: #9AC444; box-shadow: 0 0 0 3px rgba(154,196,68,.2); }
        button {
            width: 100%;
            margin-top: 24px;
            padding: 14px;
            background: #9AC444;
            color: #fff;
            border: none;
            border-radius: 12px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
        }
        button:hover { background: #8ab33a; }
        .error { color: #e53935; font-size: 12px; margin-top: 4px; display: none; }

        /* Success popup */
        .overlay {
            position: fixed;
            inset: 0;
            background: rgba(0,0,0,.45);
            display: none;
            align-items: center;
            justify-content: center;
            padding: 16px;
        }
        .overlay.show { display: flex; }
        .popup {
            background: #fff;
            border-radius: 16px;
            padding: 36px 32px;
            max-width: 360px;
            width: 100%;
            text-align: center;
            box-shadow: 0 20px 50px rgba(0,0,0,.2);
        }
        .check {
            width: 64px; height: 64px;
            margin: 0 auto 16px;
            border-radius: 50%;
            background: #eef6dd;
            display: flex; align-items: center; justify-content: center;
            font-size: 34px; color: #9AC444;
        }
        .popup h2 { font-size: 19px; margin-bottom: 8px; color: #333; }
        .popup p { color: #888; font-size: 14px; margin-bottom: 22px; }
        .popup button { margin-top: 0; }
    </style>
</head>
<body>
    <div class="card">
        <div class="logo">Zenfoo</div>
        <div class="brand-sub">Fast Delivery App</div>
        <h1>Request Account Deletion</h1>
        <p class="sub">Submit your details and we'll process the deletion of your account and associated data.</p>

        <form id="deleteForm" novalidate>
            <label for="name">Name</label>
            <input type="text" id="name" name="name" placeholder="Your full name">
            <div class="error" id="nameError">Please enter your name.</div>

            <label for="email">Email</label>
            <input type="email" id="email" name="email" placeholder="you@example.com">
            <div class="error" id="emailError">Please enter a valid email.</div>

            <label for="reason">Reason for deletion</label>
            <textarea id="reason" name="reason" rows="4" placeholder="Tell us why you want to delete your account"></textarea>
            <div class="error" id="reasonError">Please tell us the reason for deletion.</div>

            <button type="submit">Submit Deletion Request</button>
        </form>
    </div>

    <div class="overlay" id="overlay">
        <div class="popup">
            <div class="check">&#10003;</div>
            <h2>Deletion Successful</h2>
            <p>Your account has been deleted successfully.</p>
            <button type="button" id="closePopup">Done</button>
        </div>
    </div>

    <script>
        var form = document.getElementById('deleteForm');
        var overlay = document.getElementById('overlay');

        form.addEventListener('submit', function (e) {
            e.preventDefault();
            var name = document.getElementById('name');
            var email = document.getElementById('email');
            var reason = document.getElementById('reason');
            var nameError = document.getElementById('nameError');
            var emailError = document.getElementById('emailError');
            var reasonError = document.getElementById('reasonError');
            var valid = true;

            if (!name.value.trim()) { nameError.style.display = 'block'; valid = false; }
            else { nameError.style.display = 'none'; }

            var emailOk = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.value.trim());
            if (!emailOk) { emailError.style.display = 'block'; valid = false; }
            else { emailError.style.display = 'none'; }

            if (!reason.value.trim()) { reasonError.style.display = 'block'; valid = false; }
            else { reasonError.style.display = 'none'; }

            if (!valid) return;

            // Dummy submit — show success popup.
            overlay.classList.add('show');
            form.reset();
        });

        document.getElementById('closePopup').addEventListener('click', function () {
            overlay.classList.remove('show');
        });
        overlay.addEventListener('click', function (e) {
            if (e.target === overlay) overlay.classList.remove('show');
        });
    </script>
</body>
</html>
