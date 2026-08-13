<?php

namespace App\Support;

use Illuminate\Support\Facades\Http;

/**
 * Finds a commercial-quality product photo for a name.
 *
 * Source order matters and was decided by testing against the real catalogue:
 *
 *  1. **Pexels** — professional food/product photography, and its search
 *     actually understands "raw chicken breast". Needs PEXELS_API_KEY.
 *  2. **Openverse** — key-less fallback. Usable for produce, unreliable for
 *     anything else: it returned a cat for "ginger", a NASA black-hole image
 *     for "dates", a flatworm for "fig" and a garlic press for "garlic".
 *
 * Both go through the same relevance gate, because the failure mode that
 * matters is not "no photo" — it is a confidently wrong photo on a storefront.
 */
class StockPhotoFinder
{
    private const UA = 'ZenfooCatalogSeeder/1.0 (kmadhu@techlanditsolutions.com)';

    /** Titles/alt text that mean "not a clean product shot". */
    private const REJECT = [
        'illustration', 'drawing', 'painting', 'sketch', 'vintage', 'engraving',
        'logo', 'cartoon', 'diagram', 'poster', 'sign',
    ];

    /** Extra rejects for meat and fish: the animal alive is useless here. */
    public const REJECT_LIVE_ANIMAL = [
        'live', 'alive', 'farm', 'field', 'flock', 'herd', 'wildlife', 'zoo',
        'aquarium', 'swimming', 'underwater', 'reef', 'pasture', 'grazing',
        'hen', 'rooster', 'chick ', 'feather',
    ];

    /** Photos already handed out this run, so no two tiles share one. */
    private array $used = [];

    /** @param array<string> $seedUsed image URLs already in use in the catalogue */
    public function __construct(array $seedUsed = [])
    {
        foreach ($seedUsed as $u) {
            $this->used[$u] = true;
        }
    }

    public function markUsed(string $url): void
    {
        $this->used[$url] = true;
    }

    public static function hasPexelsKey(): bool
    {
        return (bool) env('PEXELS_API_KEY');
    }

    /**
     * @param string        $query      what to search for
     * @param array<string> $mustWords  at least one must appear in the caption
     * @param array<string> $extraReject additional caption rejects
     * @return array{url:string,title:string,w:int,source:string}|null
     */
    /**
     * @param array<string> $requireAny caption must ALSO contain one of these.
     *        For meat and fish this is the only thing that reliably separates a
     *        product shot from a restaurant plate or a live animal: excluding
     *        "grilled" just surfaced "a cute young lamb standing in a field".
     */
    public function find(string $query, array $mustWords, array $extraReject = [], array $requireAny = [], bool $matchAll = false): ?array
    {
        $this->requireAny = $requireAny;
        $this->matchAll = $matchAll;

        foreach ([$query, $query . ' isolated white background'] as $q) {
            if ($hit = $this->pexels($q, $mustWords, $extraReject)) {
                return $hit;
            }
        }

        foreach ([$query . ' white background', $query] as $q) {
            if ($hit = $this->openverse($q, $mustWords, $extraReject)) {
                return $hit;
            }
        }

        return null;
    }

    /** @var array<string> */
    private array $requireAny = [];

    /** When true, a candidate must actually have a white background. */
    private bool $whiteOnly = false;

    /** When true, EVERY word in mustWords must appear in the caption. */
    private bool $matchAll = false;

    public function requireWhiteBackground(bool $on = true): void
    {
        $this->whiteOnly = $on;
    }

    /**
     * Rewrite an image URL to a small thumbnail.
     *
     * Pexels and Openverse both honour w/h query params; for anything else the
     * original is returned and the size guard in hasWhiteBackground() catches
     * it.
     */
    private function thumbUrl(string $url, int $px): string
    {
        $parts = parse_url($url);
        if (!isset($parts['host'])) {
            return $url;
        }

        if (str_contains($parts['host'], 'pexels.com')) {
            parse_str($parts['query'] ?? '', $q);
            $q['w'] = $px;
            $q['h'] = $px;
            $q['fit'] = 'contain';
            $q['auto'] = 'compress';
            return $parts['scheme'] . '://' . $parts['host'] . $parts['path'] . '?' . http_build_query($q);
        }

        return $url;
    }

    /**
     * Does this image sit on a white background?
     *
     * Checked by sampling the border pixels rather than trusting the caption:
     * plenty of photos are described as "isolated on white" and are not, and
     * plenty of clean packshots never say so. Downloads the image once and
     * looks at the actual pixels, which is the only reliable test.
     */
    private function hasWhiteBackground(string $url): bool
    {
        try {
            // Probe a THUMBNAIL, never the full image. imagecreatefromstring
            // decodes to raw pixels — a 6000x4000 Pexels photo is ~96 MB in
            // memory and blows PHP's 128 MB limit after a couple of items.
            // A 240 px probe is ~0.2 MB and shows the same background.
            $probe = $this->thumbUrl($url, 240);

            $bytes = @file_get_contents($probe, false, stream_context_create([
                'http' => ['header' => "User-Agent: " . self::UA . "\r\n", 'timeout' => 45],
            ]));
            if (!$bytes) {
                return false;
            }

            // Refuse anything still large enough to be a decode risk.
            if (strlen($bytes) > 3_000_000) {
                unset($bytes);
                return false;
            }

            $im = @imagecreatefromstring($bytes);
            unset($bytes);
            if (!$im) {
                return false;
            }

            $w = imagesx($im);
            $h = imagesy($im);
            $samples = 0;
            $white = 0;

            // Walk the four edges, one inset pixel in, at 40 points per edge.
            for ($i = 0; $i < 40; $i++) {
                $fx = (int) ($w * $i / 40);
                $fy = (int) ($h * $i / 40);

                foreach ([[$fx, 2], [$fx, $h - 3], [2, $fy], [$w - 3, $fy]] as [$x, $y]) {
                    $x = max(0, min($w - 1, $x));
                    $y = max(0, min($h - 1, $y));
                    $rgb = imagecolorat($im, $x, $y);
                    $r = ($rgb >> 16) & 0xFF;
                    $g = ($rgb >> 8) & 0xFF;
                    $b = $rgb & 0xFF;

                    $samples++;
                    // Near-white and near-neutral: bright, with little colour cast.
                    if ($r > 232 && $g > 232 && $b > 232 && (max($r, $g, $b) - min($r, $g, $b)) < 14) {
                        $white++;
                    }
                }
            }

            imagedestroy($im);

            return $samples > 0 && ($white / $samples) >= 0.85;
        } catch (\Throwable $e) {
            return false;
        }
    }

    /* ─────────────────────────── Pexels ───────────────────────────── */

    private function pexels(string $query, array $mustWords, array $extraReject): ?array
    {
        $key = env('PEXELS_API_KEY');
        if (!$key) {
            return null;
        }

        try {
            usleep(250000);
            $res = Http::withHeaders(['Authorization' => $key, 'User-Agent' => self::UA])
                ->timeout(45)
                ->get('https://api.pexels.com/v1/search', [
                    'query' => $query, 'per_page' => 40, 'orientation' => 'square',
                ]);

            $photos = $res->json('photos') ?? [];
            if (!$photos) {
                // Square can be sparse; retry without the constraint.
                usleep(250000);
                $photos = Http::withHeaders(['Authorization' => $key, 'User-Agent' => self::UA])
                    ->timeout(45)
                    ->get('https://api.pexels.com/v1/search', ['query' => $query, 'per_page' => 40])
                    ->json('photos') ?? [];
            }
        } catch (\Throwable $e) {
            return null;
        }

        $best = null;

        foreach ($photos as $p) {
            // `large` is ~940px wide and already compressed — right for a phone
            // tile, and far lighter than the 6000px original.
            $url = $p['src']['large'] ?? ($p['src']['medium'] ?? null);
            $caption = strtolower(($p['alt'] ?? '') . ' ' . ($p['photographer'] ?? ''));
            $w = (int) ($p['width'] ?? 0);

            if (!$url || isset($this->used[$url])) {
                continue;
            }
            if (!$this->captionPasses($caption, $mustWords, $extraReject)) {
                continue;
            }

            // Verify the background before accepting, not after.
            if ($this->whiteOnly && !$this->hasWhiteBackground($url)) {
                continue;
            }

            // Pexels orders by relevance, so the first survivor is the best one.
            $best = ['url' => $url, 'title' => $p['alt'] ?: 'pexels photo', 'w' => $w, 'source' => 'pexels'];
            break;
        }

        if ($best) {
            $this->used[$best['url']] = true;
        }

        return $best;
    }

    /* ────────────────────────── Openverse ─────────────────────────── */

    private function openverse(string $query, array $mustWords, array $extraReject): ?array
    {
        try {
            usleep(400000);
            $res = Http::withHeaders(['User-Agent' => self::UA])->timeout(45)
                ->get('https://api.openverse.org/v1/images/', [
                    'q' => $query, 'license_type' => 'commercial',
                    'page_size' => 20, 'mature' => 'false',
                ]);
            $results = $res->json('results') ?? [];
        } catch (\Throwable $e) {
            return null;
        }

        $best = null;

        foreach ($results as $r) {
            $url = $r['url'] ?? '';
            $title = strtolower($r['title'] ?? '');
            $w = (int) ($r['width'] ?? 0);
            $h = (int) ($r['height'] ?? 0);

            if (!str_starts_with($url, 'https://')) continue;
            if (!in_array(strtolower($r['filetype'] ?? ''), ['jpg', 'jpeg', 'png'], true)) continue;
            if ($w < 900) continue;
            if ($h > 0 && ($w / $h > 2.4 || $h / $w > 2.4)) continue;
            if (isset($this->used[$url])) continue;
            if (!$this->captionPasses($title, $mustWords, $extraReject)) continue;
            if ($this->whiteOnly && !$this->hasWhiteBackground($url)) continue;

            $studio = str_contains($title, 'white background') || str_contains($title, 'isolated');
            $score = ($studio ? 1_000_000_000 : 0) + $w;

            if (!$best || $score > $best['score']) {
                $best = ['url' => $url, 'title' => $r['title'], 'w' => $w,
                         'source' => 'openverse', 'score' => $score];
            }
        }

        if ($best) {
            $this->used[$best['url']] = true;
            unset($best['score']);
        }

        return $best;
    }

    /* ───────────────────────── relevance ──────────────────────────── */

    /**
     * At least one required word must appear as a whole word, and no reject
     * word may appear. Without this, ranking by size alone returns the biggest
     * file for the query rather than the right subject.
     */
    private function captionPasses(string $caption, array $mustWords, array $extraReject): bool
    {
        if ($caption === '') {
            return false;
        }

        if ($this->matchAll) {
            // The words ARE the product name, so every one must appear.
            // Any-word matching let "Snake Gourd" accept "Dragon Gourd" and
            // "Green Chilli" accept an Asian stir-fry.
            foreach ($mustWords as $word) {
                if (!preg_match('/\b' . preg_quote($word, '/') . '(s|es)?\b/i', $caption)) {
                    return false;
                }
            }
        } else {
            // The words are synonyms for one subject; any hit is enough.
            $relevant = false;
            foreach ($mustWords as $word) {
                if (preg_match('/\b' . preg_quote($word, '/') . '(s|es)?\b/i', $caption)) {
                    $relevant = true;
                    break;
                }
            }
            if (!$relevant) {
                return false;
            }
        }

        foreach (array_merge(self::REJECT, $extraReject) as $bad) {
            if (str_contains($caption, $bad)) {
                return false;
            }
        }

        if ($this->requireAny) {
            foreach ($this->requireAny as $need) {
                if (str_contains($caption, $need)) {
                    return true;
                }
            }
            return false;
        }

        return true;
    }
}
