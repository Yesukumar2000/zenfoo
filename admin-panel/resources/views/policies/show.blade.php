<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="robots" content="index, follow">
    <title>{{ $title }} | Zenfoo</title>
    <meta name="description" content="{{ $title }} for Zenfoo — your food & grocery delivery app.">
    <link rel="icon" type="image/png" href="{{ asset('images/logo.png') }}">
    <style>
        :root {
            --brand: #9AC444;
            --brand-dark: #7DA635;
            --brand-light: #BDE17E;
            --ink: #221F1F;
            --muted: #6C6969;
            --line: #ECECEC;
            --bg: #F5F7F0;
        }
        * { box-sizing: border-box; }
        html { -webkit-text-size-adjust: 100%; }
        body {
            margin: 0;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            color: var(--ink);
            background: var(--bg);
            line-height: 1.7;
        }
        .site-header {
            background: linear-gradient(135deg, var(--brand) 0%, var(--brand-dark) 100%);
            color: #fff;
            padding: 28px 20px;
            text-align: center;
        }
        .brand {
            display: inline-flex;
            align-items: center;
            gap: 12px;
        }
        .brand img {
            height: 44px;
            width: 44px;
            object-fit: contain;
            background: #fff;
            border-radius: 12px;
            padding: 5px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.15);
        }
        .brand .name {
            font-size: 28px;
            font-weight: 800;
            letter-spacing: 0.5px;
        }
        .site-header .tagline {
            margin-top: 6px;
            font-size: 14px;
            opacity: 0.92;
        }
        .wrap {
            max-width: 820px;
            margin: -24px auto 40px;
            padding: 0 16px;
        }
        .card {
            background: #fff;
            border-radius: 16px;
            box-shadow: 0 8px 30px rgba(34,31,31,0.08);
            padding: 36px 38px;
        }
        .doc-title {
            margin: 0 0 4px;
            font-size: 26px;
            font-weight: 800;
            color: var(--brand-dark);
        }
        .doc-rule {
            height: 4px;
            width: 64px;
            background: var(--brand);
            border-radius: 4px;
            margin: 10px 0 24px;
        }
        .content h2 { font-size: 22px; color: var(--ink); margin: 26px 0 10px; }
        .content h3 {
            font-size: 18px;
            color: var(--brand-dark);
            margin: 26px 0 8px;
            padding-bottom: 6px;
            border-bottom: 1px solid var(--line);
        }
        .content h4 { font-size: 15px; color: var(--ink); margin: 16px 0 6px; }
        .content p { margin: 10px 0; color: #34302f; }
        .content ul { margin: 10px 0 16px; padding-left: 22px; }
        .content li { margin: 6px 0; }
        .content a { color: var(--brand-dark); }
        .content strong { color: var(--ink); }
        .site-footer {
            text-align: center;
            color: var(--muted);
            font-size: 13px;
            padding: 8px 16px 30px;
        }
        .site-footer a { color: var(--brand-dark); text-decoration: none; }
        @media (max-width: 600px) {
            .card { padding: 24px 20px; border-radius: 14px; }
            .brand .name { font-size: 24px; }
            .doc-title { font-size: 22px; }
        }
    </style>
</head>
<body>
    <header class="site-header">
        <div class="brand">
            <img src="{{ asset('images/logo.png') }}" alt="Zenfoo logo">
            <span class="name">Zenfoo</span>
        </div>
        <div class="tagline">Food &amp; Grocery Delivery</div>
    </header>

    <main class="wrap">
        <div class="card">
            <h1 class="doc-title">{{ $title }}</h1>
            <div class="doc-rule"></div>
            <div class="content">
                {!! $content !!}
            </div>
        </div>
    </main>

    <footer class="site-footer">
        &copy; {{ date('Y') }} Zenfoo Products Pvt. Ltd. &nbsp;&middot;&nbsp;
        <a href="mailto:support@zenfoo.in">support@zenfoo.in</a>
    </footer>
</body>
</html>
