<?php

namespace App\Console\Commands;

use Database\Seeders\DemoWorld\DemoWorld;
use Illuminate\Console\Command;

/**
 * Draws the KYC / proof images the demo vendors and drivers upload:
 * PAN card, Aadhaar card, FSSAI certificate, cancelled cheque, driving
 * licence, GST certificate and a couple of storefront placeholders.
 *
 * WHY THESE ARE DELIBERATELY FAKE-LOOKING
 * ---------------------------------------
 * The point is to exercise the admin panel's document viewer, the approve /
 * reject flow, the zoom modal and the thumbnail grid — that only needs a file
 * of the right shape with fields in the right places. It does NOT need a
 * convincing replica of an Indian government ID, and producing one would be a
 * genuinely bad idea. So every image gets:
 *
 *   - a large diagonal "SAMPLE — NOT A VALID DOCUMENT" watermark
 *   - a footer stating it was generated for demo purposes
 *   - masked / reserved-series numbers that fail real validation
 *   - no government emblem, seal, hologram or issuing-authority branding
 *
 * They will look right in your UI and be unmistakable to a human.
 *
 * Run: php artisan zenfoo:demo-documents
 */
class GenerateDemoDocuments extends Command
{
    protected $signature = 'zenfoo:demo-documents
        {--force : Redraw files that already exist}';

    protected $description = 'Generate watermarked SAMPLE KYC/document images used by the demo world seeders';

    /** Card canvas size — roughly ID-1 ratio at a readable resolution. */
    private const W = 1000;
    private const H = 640;

    /** A4-ish portrait for certificates. */
    private const CERT_W = 900;
    private const CERT_H = 1200;

    /**
     * Merchandising artwork used by DemoMerchandisingSeeder.
     * slug => [headline, subline, width, height]
     */
    private const BANNERS = [
        'banner-slider-1'   => ['10 MINUTE GROCERY',   'Fresh picks delivered to your door',   1200, 500],
        'banner-slider-2'   => ['FRESH FROM THE FARM', 'Vegetables and fruits, picked today',  1200, 500],
        'banner-slider-3'   => ['MEAT AND SEAFOOD',    'Cut to order, cleaned, chilled',       1200, 500],
        'banner-slider-4'   => ['MONSOON ESSENTIALS',  'Stock up before the rain hits',        1200, 500],
        'banner-slider-5'   => ['SUPER MART SAVERS',   'Household staples at pack prices',     1200, 500],
        'banner-offer-1'    => ['FLAT Rs.100 OFF',     'On your first three orders',            800, 800],
        'banner-offer-2'    => ['WEEKEND BONUS',       'Rs.50 back on orders above Rs.499',     800, 800],
        'banner-offer-3'    => ['REFER AND EARN',      'Rs.100 for you, Rs.100 for them',       800, 800],
        'banner-campaign-1' => ['BRAND SPOTLIGHT',     'Handpicked favourites, one place',    1400, 600],
        'banner-campaign-2' => ['PANTRY RESTOCK',      'Everything the kitchen ran out of',   1400, 600],
    ];

    private string $dir;

    public function handle(): int
    {
        if (!extension_loaded('gd')) {
            $this->error('The GD extension is required. Enable extension=gd in php.ini.');
            return self::FAILURE;
        }

        $this->dir = public_path(DemoWorld::DOC_DIR);
        if (!is_dir($this->dir)) {
            mkdir($this->dir, 0755, true);
        }

        $made = 0;

        // One set per vendor and per driver, so no two uploads are identical.
        for ($i = 1; $i <= DemoWorld::N_VENDORS; $i++) {
            $key = "vendor|$i";
            $state = $i % 3 === 0 ? 'Andhra Pradesh' : 'Telangana';
            $name = strtoupper(DemoWorld::fullName($key));

            $made += $this->idCard("vendor-{$i}-pan", 'PERMANENT ACCOUNT NUMBER CARD', '#1d4ed8', [
                'Name'            => $name,
                'Father\'s Name'  => strtoupper(DemoWorld::fullName($key . '|father')),
                'Date of Birth'   => sprintf('%02d/%02d/19%02d',
                    DemoWorld::intFor($key . '|d', 1, 28), DemoWorld::intFor($key . '|m', 1, 12), DemoWorld::intFor($key . '|y', 70, 99)),
                'PAN'             => DemoWorld::pan($key),
            ]);

            $made += $this->idCard("vendor-{$i}-aadhaar", 'IDENTITY CARD (SAMPLE LAYOUT)', '#b45309', [
                'Name'          => $name,
                'Date of Birth' => sprintf('%02d/%02d/19%02d',
                    DemoWorld::intFor($key . '|d', 1, 28), DemoWorld::intFor($key . '|m', 1, 12), DemoWorld::intFor($key . '|y', 70, 99)),
                'Gender'        => DemoWorld::chance($key . '|g', 55) ? 'MALE' : 'FEMALE',
                'Number'        => DemoWorld::aadhaar($key),
            ]);

            $made += $this->certificate("vendor-{$i}-fssai", 'FOOD BUSINESS LICENCE', [
                'Licence Number'  => DemoWorld::fssai($key),
                'Business Name'   => DemoWorld::VENDOR_TEMPLATES[($i - 1) % count(DemoWorld::VENDOR_TEMPLATES)]['name'],
                'Proprietor'      => $name,
                'Category'        => 'Retail / Quick Commerce',
                'Valid Upto'      => '31/03/20' . DemoWorld::intFor($key . '|v', 27, 30),
                'State'           => $state,
            ]);

            $made += $this->certificate("vendor-{$i}-gst", 'GOODS AND SERVICES TAX REGISTRATION', [
                'GSTIN'          => DemoWorld::gstin($key, $state),
                'Legal Name'     => $name,
                'Trade Name'     => DemoWorld::VENDOR_TEMPLATES[($i - 1) % count(DemoWorld::VENDOR_TEMPLATES)]['name'],
                'Constitution'   => 'Proprietorship',
                'Date of Liability' => '01/04/2024',
                'State'          => $state,
            ]);

            $bank = DemoWorld::pick($key . '|bank', DemoWorld::BANKS);
            $made += $this->cheque("vendor-{$i}-cheque", $name, $bank[0],
                DemoWorld::accountNumber($key), DemoWorld::ifsc($bank[1], $key));

            $made += $this->storefront("vendor-{$i}-store",
                DemoWorld::VENDOR_TEMPLATES[($i - 1) % count(DemoWorld::VENDOR_TEMPLATES)]['name']);
        }

        // Merchandising artwork: home-screen sliders, offer tiles, campaign heroes.
        foreach (self::BANNERS as $slug => [$headline, $sub, $w, $h]) {
            $made += $this->banner($slug, $headline, $sub, $w, $h);
        }

        for ($i = 1; $i <= DemoWorld::N_DRIVERS; $i++) {
            $key = "driver|$i";
            $state = $i % 3 === 0 ? 'Andhra Pradesh' : 'Telangana';
            $name = strtoupper(DemoWorld::fullName($key));

            $made += $this->idCard("driver-{$i}-licence", 'DRIVING LICENCE (SAMPLE LAYOUT)', '#047857', [
                'Name'       => $name,
                'DL Number'  => DemoWorld::drivingLicence($key, $state),
                'Valid Till' => '31/12/20' . DemoWorld::intFor($key . '|v', 28, 34),
                'Class'      => 'MCWG, LMV',
                'State'      => $state,
            ]);

            $made += $this->idCard("driver-{$i}-aadhaar", 'IDENTITY CARD (SAMPLE LAYOUT)', '#b45309', [
                'Name'   => $name,
                'Gender' => DemoWorld::chance($key . '|g', 80) ? 'MALE' : 'FEMALE',
                'Number' => DemoWorld::aadhaar($key),
            ]);

            $made += $this->avatar("driver-{$i}-photo", $name);
        }

        $this->info("Wrote {$made} file(s) to public/" . DemoWorld::DOC_DIR);
        $this->line('Every image carries a SAMPLE watermark and non-valid numbers.');

        return self::SUCCESS;
    }

    /* ─────────────────────────── drawing ─────────────────────────── */

    private function path(string $slug): string
    {
        return $this->dir . DIRECTORY_SEPARATOR . $slug . '.png';
    }

    private function skip(string $slug): bool
    {
        return !$this->option('force') && file_exists($this->path($slug));
    }

    /** A landscape ID-card style document with a coloured header band. */
    private function idCard(string $slug, string $title, string $accent, array $fields): int
    {
        if ($this->skip($slug)) {
            return 0;
        }

        $im = imagecreatetruecolor(self::W, self::H);
        imagefill($im, 0, 0, $this->rgb($im, '#f8fafc'));

        $accentC = $this->rgb($im, $accent);
        $ink = $this->rgb($im, '#0f172a');
        $muted = $this->rgb($im, '#64748b');
        $line = $this->rgb($im, '#cbd5e1');

        // Header band
        imagefilledrectangle($im, 0, 0, self::W, 96, $accentC);
        $this->text($im, $title, 32, 36, 5, $this->rgb($im, '#ffffff'));
        $this->text($im, 'GENERATED DEMO DOCUMENT', 32, 66, 2, $this->rgb($im, '#e2e8f0'));

        // Photo box
        imagerectangle($im, 700, 140, 940, 430, $line);
        $this->text($im, 'PHOTO', 790, 280, 3, $muted);

        // Fields
        $y = 160;
        foreach ($fields as $label => $value) {
            $this->text($im, strtoupper($label), 48, $y, 2, $muted);
            $this->text($im, (string) $value, 48, $y + 24, 4, $ink);
            $y += 78;
        }

        // Signature strip
        imageline($im, 48, self::H - 120, 380, self::H - 120, $line);
        $this->text($im, 'SIGNATURE (NOT PROVIDED)', 48, self::H - 110, 2, $muted);

        $this->watermark($im, self::W, self::H);
        $this->footer($im, self::W, self::H);

        imagepng($im, $this->path($slug));
        imagedestroy($im);

        return 1;
    }

    /** A portrait certificate with a field table. */
    private function certificate(string $slug, string $title, array $fields): int
    {
        if ($this->skip($slug)) {
            return 0;
        }

        $im = imagecreatetruecolor(self::CERT_W, self::CERT_H);
        imagefill($im, 0, 0, $this->rgb($im, '#ffffff'));

        $ink = $this->rgb($im, '#0f172a');
        $muted = $this->rgb($im, '#64748b');
        $line = $this->rgb($im, '#cbd5e1');
        $accent = $this->rgb($im, '#7c3aed');

        // Border
        imagerectangle($im, 24, 24, self::CERT_W - 24, self::CERT_H - 24, $line);
        imagerectangle($im, 30, 30, self::CERT_W - 30, self::CERT_H - 30, $line);

        imagefilledrectangle($im, 30, 30, self::CERT_W - 30, 130, $accent);
        $this->text($im, $title, 60, 60, 4, $this->rgb($im, '#ffffff'));
        $this->text($im, 'SAMPLE CERTIFICATE — FOR APPLICATION DEMO ONLY', 60, 96, 2, $this->rgb($im, '#ede9fe'));

        $y = 200;
        foreach ($fields as $label => $value) {
            $this->text($im, strtoupper($label), 70, $y, 2, $muted);
            $this->text($im, (string) $value, 70, $y + 26, 3, $ink);
            imageline($im, 70, $y + 62, self::CERT_W - 70, $y + 62, $line);
            $y += 96;
        }

        $this->text($im, 'This document was generated by an automated seeder to populate a', 70, self::CERT_H - 220, 2, $muted);
        $this->text($im, 'demonstration environment. It is not issued by any authority and', 70, self::CERT_H - 196, 2, $muted);
        $this->text($im, 'confers no licence, registration or legal standing whatsoever.', 70, self::CERT_H - 172, 2, $muted);

        $this->watermark($im, self::CERT_W, self::CERT_H);
        $this->footer($im, self::CERT_W, self::CERT_H);

        imagepng($im, $this->path($slug));
        imagedestroy($im);

        return 1;
    }

    /** A cancelled-cheque style image for bank verification screens. */
    private function cheque(string $slug, string $holder, string $bank, string $account, string $ifsc): int
    {
        if ($this->skip($slug)) {
            return 0;
        }

        $w = 1100;
        $h = 480;
        $im = imagecreatetruecolor($w, $h);
        imagefill($im, 0, 0, $this->rgb($im, '#eef2ff'));

        $ink = $this->rgb($im, '#1e293b');
        $muted = $this->rgb($im, '#64748b');
        $line = $this->rgb($im, '#94a3b8');
        $red = $this->rgb($im, '#dc2626');

        $this->text($im, strtoupper($bank), 40, 40, 5, $ink);
        $this->text($im, 'SAMPLE BRANCH, HYDERABAD', 40, 78, 2, $muted);

        imageline($im, 40, 190, $w - 40, 190, $line);
        $this->text($im, 'PAY', 40, 160, 3, $muted);
        imageline($im, 40, 260, $w - 300, 260, $line);

        $this->text($im, 'A/C HOLDER', 40, 300, 2, $muted);
        $this->text($im, $holder, 40, 324, 4, $ink);

        $this->text($im, 'A/C NO', 520, 300, 2, $muted);
        $this->text($im, $account, 520, 324, 4, $ink);

        $this->text($im, 'IFSC', 820, 300, 2, $muted);
        $this->text($im, $ifsc, 820, 324, 4, $ink);

        // MICR band
        imagefilledrectangle($im, 0, $h - 70, $w, $h - 20, $this->rgb($im, '#e2e8f0'));
        $this->text($im, '000000  ' . $ifsc . '  ' . $account . '  10', 40, $h - 56, 3, $muted);

        // "CANCELLED" stroke
        imagesetthickness($im, 6);
        imageline($im, 120, 380, $w - 120, 120, $red);
        imagesetthickness($im, 1);
        $this->text($im, 'CANCELLED — SAMPLE', 380, 210, 5, $red);

        $this->watermark($im, $w, $h);
        $this->footer($im, $w, $h);

        imagepng($im, $this->path($slug));
        imagedestroy($im);

        return 1;
    }

    /** A flat-colour storefront placeholder with the shop name. */
    private function storefront(string $slug, string $name): int
    {
        if ($this->skip($slug)) {
            return 0;
        }

        $w = 1200;
        $h = 800;
        $im = imagecreatetruecolor($w, $h);

        $palette = ['#0f766e', '#7c3aed', '#b45309', '#be123c', '#1d4ed8', '#15803d'];
        $bg = $this->rgb($im, DemoWorld::pick($slug, $palette));
        imagefill($im, 0, 0, $bg);

        // Awning stripes
        $stripe = $this->rgb($im, '#ffffff');
        for ($x = 0; $x < $w; $x += 120) {
            imagefilledrectangle($im, $x, 0, $x + 60, 140, $stripe);
        }

        imagefilledrectangle($im, 120, 300, $w - 120, 620, $this->rgb($im, '#0f172a'));
        $this->text($im, strtoupper($name), 160, 420, 5, $this->rgb($im, '#ffffff'));
        $this->text($im, 'SAMPLE STOREFRONT IMAGE', 160, 470, 3, $this->rgb($im, '#94a3b8'));

        $this->footer($im, $w, $h);

        imagepng($im, $this->path($slug));
        imagedestroy($im);

        return 1;
    }

    /**
     * A merchandising banner: diagonal two-tone field, headline, subline.
     *
     * No SAMPLE watermark here — these are promotional artwork, not documents,
     * and a watermark across the home screen would look broken rather than
     * honest. The "ZENFOO DEMO" corner tag is enough.
     */
    private function banner(string $slug, string $headline, string $sub, int $w, int $h): int
    {
        if ($this->skip($slug)) {
            return 0;
        }

        $im = imagecreatetruecolor($w, $h);

        $schemes = [
            ['#0f766e', '#14b8a6'], ['#7c3aed', '#a78bfa'], ['#b45309', '#f59e0b'],
            ['#be123c', '#fb7185'], ['#1d4ed8', '#60a5fa'], ['#15803d', '#4ade80'],
        ];
        [$dark, $light] = DemoWorld::pick($slug, $schemes);

        imagefill($im, 0, 0, $this->rgb($im, $dark));

        // Diagonal wedge of the lighter tone across the right side.
        $accent = $this->rgb($im, $light);
        imagefilledpolygon($im, [
            (int) ($w * 0.55), 0,
            $w, 0,
            $w, $h,
            (int) ($w * 0.35), $h,
        ], 4, $accent);

        // Faint circles for a little depth.
        $tint = imagecolorallocatealpha($im, 255, 255, 255, 108);
        imagefilledellipse($im, (int) ($w * 0.82), (int) ($h * 0.30), (int) ($h * 0.9), (int) ($h * 0.9), $tint);
        imagefilledellipse($im, (int) ($w * 0.14), (int) ($h * 0.80), (int) ($h * 0.6), (int) ($h * 0.6), $tint);

        $pad = (int) ($w * 0.06);
        $this->text($im, $headline, $pad, (int) ($h * 0.38), 5, $this->rgb($im, '#ffffff'));
        $this->text($im, $sub, $pad, (int) ($h * 0.38) + 34, 3, $this->rgb($im, '#e2e8f0'));

        // Corner tag so nobody mistakes it for finished brand artwork.
        $tag = $this->rgb($im, '#0f172a');
        imagefilledrectangle($im, 0, $h - 24, 190, $h, $tag);
        $this->text($im, 'ZENFOO DEMO ASSET', 8, $h - 20, 2, $this->rgb($im, '#f8fafc'));

        imagepng($im, $this->path($slug));
        imagedestroy($im);

        return 1;
    }

    /** An initials avatar for driver profile photos. */
    private function avatar(string $slug, string $name): int
    {
        if ($this->skip($slug)) {
            return 0;
        }

        $size = 400;
        $im = imagecreatetruecolor($size, $size);

        $palette = ['#0369a1', '#7c3aed', '#b91c1c', '#047857', '#c2410c', '#4338ca'];
        imagefill($im, 0, 0, $this->rgb($im, DemoWorld::pick($slug, $palette)));

        $parts = preg_split('/\s+/', trim($name));
        $initials = strtoupper(substr($parts[0], 0, 1) . substr($parts[1] ?? '', 0, 1));

        $this->text($im, $initials, 150, 170, 5, $this->rgb($im, '#ffffff'));
        $this->text($im, 'DEMO', 165, 320, 2, $this->rgb($im, '#e2e8f0'));

        imagepng($im, $this->path($slug));
        imagedestroy($im);

        return 1;
    }

    /* ───────────────────────── primitives ───────────────────────── */

    private function rgb($im, string $hex): int
    {
        [$r, $g, $b] = sscanf(ltrim($hex, '#'), '%2x%2x%2x');
        return imagecolorallocate($im, $r, $g, $b);
    }

    /**
     * Built-in bitmap fonts only (size 1–5) so this works on any PHP build
     * without needing a TTF shipped in the repo. Size 5 is ~15px wide glyphs,
     * which is why the layout uses generous spacing.
     *
     * Those fonts are single-byte, so a UTF-8 em dash renders as mojibake —
     * everything is folded to ASCII before it's drawn.
     */
    private function text($im, string $s, int $x, int $y, int $size, int $color): void
    {
        imagestring($im, $size, $x, $y, $this->ascii($s), $color);
    }

    /** Fold typographic punctuation to ASCII and drop anything else non-ASCII. */
    private function ascii(string $s): string
    {
        $s = strtr($s, [
            '—' => '-', '–' => '-', '‑' => '-',
            '“' => '"', '”' => '"', '‘' => "'", '’' => "'",
            '₹' => 'Rs.', '…' => '...',
        ]);

        return preg_replace('/[^\x20-\x7E]/', '', $s) ?? $s;
    }

    /** Big diagonal SAMPLE stripe across the whole image. */
    private function watermark($im, int $w, int $h): void
    {
        $wm = imagecolorallocatealpha($im, 220, 38, 38, 88);
        imagesetthickness($im, 3);

        // Repeat the label along the diagonal so it can't be cropped out.
        $label = 'SAMPLE - NOT A VALID DOCUMENT';
        $steps = max(3, (int) ceil($w / 320));
        for ($i = 0; $i < $steps; $i++) {
            $x = (int) ($i * ($w / $steps));
            $y = (int) ($h - ($i + 0.5) * ($h / $steps));
            imagestring($im, 5, $x, $y, $label, $wm);
        }

        imageline($im, 0, $h, $w, 0, $wm);
        imagesetthickness($im, 1);
    }

    private function footer($im, int $w, int $h): void
    {
        $bar = $this->rgb($im, '#111827');
        imagefilledrectangle($im, 0, $h - 26, $w, $h, $bar);
        $this->text($im, 'ZENFOO DEMO DATA - AUTOGENERATED - NOT A GENUINE DOCUMENT', 10, $h - 22, 2,
            $this->rgb($im, '#f9fafb'));
    }
}
