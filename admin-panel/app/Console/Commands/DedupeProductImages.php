<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Stops the meat, fish and camel sections showing the same photo over and over.
 *
 * Store 18 had 19 mutton products sharing ONE image and store 20 has 20 camel
 * products sharing one; five "filler" images between them cover roughly a
 * hundred products. Two adjacent tiles with the identical picture is the single
 * most obvious thing wrong with those sections, and it predates any seeding.
 *
 * No new photography is needed for most of it. The products added by
 * zenfoo:stock-up already carry a correct per-cut photo — "Mutton Keema",
 * "Mutton Liver", "Rohu", "Pomfret", "Crab" — so this matches the filler-image
 * products onto those by name and reuses them.
 *
 * Pack sizes deliberately keep sharing one photo: "Mutton Keema 500g" and
 * "Mutton Keema 1kg" are the same cut, and every quick-commerce catalogue shows
 * them with the same picture. What gets fixed is different *cuts* sharing one.
 *
 * A filler image is identified by how many products use it, not by a hardcoded
 * URL, so this stays correct as the catalogue changes.
 *
 *   php artisan zenfoo:dedupe-images --dry-run
 *   php artisan zenfoo:dedupe-images
 *   php artisan zenfoo:dedupe-images --undo
 */
class DedupeProductImages extends Command
{
    protected $signature = 'zenfoo:dedupe-images
        {--stores=14,18,19,20 : Stores to work on}
        {--threshold=3 : An image used by at least this many products counts as filler}
        {--dry-run : Report what would change, change nothing}
        {--force : Run again on top of a previous run (see the note in handle)}
        {--undo : Restore the previous images, then stop}';

    protected $description = 'Give meat, fish and camel products distinct photos instead of one repeated filler';

    private const JOURNAL = 'image-dedupe.json';

    /**
     * A donor name may only be reused for a second cut if every word in it
     * appears in at most this many of the store's products. "rohu" appears in
     * four and is a real species match; "chicken" appears in thirty and says
     * nothing beyond which animal it came from.
     */
    private const DISTINCTIVE_FREQ = 4;

    /**
     * Noise to strip before comparing two product names.
     *
     * Pack sizes and marketing words are exactly what differs between a good
     * donor ("Mutton Liver") and the product needing its photo ("Mutton Liver
     * Fresh 500g"), so they must not count against the match.
     */
    private const NOISE = [
        'fresh', 'whole', 'pack', 'of', 'piece', 'pieces', 'pcs', 'rocky', 'new',
        'kg', 'gm', 'g', 'ml', 'l',
    ];

    /**
     * Butcher's terms for the same cut, so the right photo is found.
     *
     * A drumstick is a leg piece, and keema is mince — without this the leg
     * photo went unused while "Chicken Drumstick" fell back to a whole bird.
     */
    private const SYNONYM = [
        'drumstick' => 'leg',
        'tangdi'    => 'leg',
        'mince'     => 'keema',
        'fillet'    => 'steak',
    ];

    public function handle(): int
    {
        $conn = config('database.default');
        $this->line('Database: <comment>' . config("database.connections.$conn.database")
            . '</comment> @ <comment>' . config("database.connections.$conn.host") . '</comment>');

        if ($this->option('undo')) {
            return $this->undo();
        }

        // Running twice makes things WORSE, not better. The second pass sees
        // the photos this command just spread across three or four products,
        // counts them as filler by the same threshold, and collapses them
        // again — one run took store 14 from a healthy spread down to every
        // chicken product showing the same whole bird. Undo first, then re-run.
        if (file_exists($this->journalPath()) && !$this->option('force') && !$this->option('dry-run')) {
            $this->error('A previous run has not been undone.');
            $this->line('  Re-running compounds: this pass would treat its own output as filler.');
            $this->line('  Undo it first: <comment>php artisan zenfoo:dedupe-images --undo</comment>');
            return self::FAILURE;
        }

        $stores = array_map('intval', explode(',', (string) $this->option('stores')));
        $threshold = max(2, (int) $this->option('threshold'));
        $dry = (bool) $this->option('dry-run');

        if ($dry) {
            $this->line('<comment>DRY RUN</comment> — nothing will be written.');
        }

        $journal = $this->loadJournal();
        $changed = 0;
        $unmatched = [];

        foreach ($stores as $storeId) {
            $products = DB::table('products')
                ->where('store_id', $storeId)
                ->whereNull('deleted_at')
                ->where('status', 1)
                ->orderBy('name')
                ->get(['id', 'name', 'image', 'seller_id']);

            if ($products->isEmpty()) {
                continue;
            }

            // How many products lean on each image.
            $usage = [];
            foreach ($products as $p) {
                $usage[$p->image] = ($usage[$p->image] ?? 0) + 1;
            }

            // Donors: products whose photo is already specific to them.
            $donors = [];
            foreach ($products as $p) {
                if (($usage[$p->image] ?? 0) < $threshold && $p->image) {
                    $donors[] = ['key' => $this->normalise($p->name), 'name' => $p->name, 'image' => $p->image];
                }
            }

            $this->newLine();
            $this->line("<info>store {$storeId}</info> — " . $products->count() . ' products, '
                . count(array_unique($products->pluck('image')->all())) . ' distinct images, '
                . count($donors) . ' usable donors');

            // Products sharing a filler image, grouped by cut so that pack
            // sizes of one cut all receive the same photo.
            $needy = [];
            foreach ($products as $p) {
                if (($usage[$p->image] ?? 0) >= $threshold) {
                    $needy[$this->normalise($p->name)][] = $p;
                }
            }

            // How common each word is in this store, for the rarity weighting.
            $freq = [];
            foreach ($products as $p) {
                foreach (array_unique(explode(' ', $this->normalise($p->name))) as $w) {
                    if ($w !== '') {
                        $freq[$w] = ($freq[$w] ?? 0) + 1;
                    }
                }
            }

            $taken = [];

            // A product whose name exactly matches a donor gets first refusal,
            // then the rest in order of rarity. Without the exact pass,
            // "Chicken Biryani Cut" claimed the "Chicken Curry Cut" photo and
            // left the actual "Chicken Curry Cut 1kg" with a whole bird.
            $donorKeys = array_flip(array_column($donors, 'key'));
            uksort($needy, function ($a, $b) use ($freq, $donorKeys) {
                $exact = fn ($k) => isset($donorKeys[$k]) ? 1 : 0;
                if ($exact($a) !== $exact($b)) {
                    return $exact($b) <=> $exact($a);
                }
                $rare = function ($k) use ($freq) {
                    $s = 0;
                    foreach (explode(' ', $k) as $w) {
                        $s += 1 / max(1, $freq[$w] ?? 1);
                    }
                    return $s;
                };
                return $rare($b) <=> $rare($a);
            });

            foreach ($needy as $key => $group) {
                $best = $this->bestDonor($key, $donors, $taken, $freq);

                if (!$best) {
                    foreach ($group as $p) {
                        $unmatched[] = "store {$storeId}  {$p->name}";
                    }
                    continue;
                }

                $taken[$best['image']] = ($taken[$best['image']] ?? 0) + 1;

                $names = implode(', ', array_map(fn ($p) => $p->name, $group));
                $this->line(sprintf('  %-46s ← %s', mb_strimwidth($names, 0, 44, '…'), $best['name']));

                foreach ($group as $p) {
                    if (!$dry) {
                        $journal[] = ['id' => $p->id, 'old' => $p->image];
                        DB::table('products')->where('id', $p->id)->update(['image' => $best['image']]);
                    }
                    $changed++;
                }
            }
        }

        if (!$dry && $changed) {
            $this->saveJournal($journal);
        }

        if ($unmatched) {
            $this->newLine();
            $this->warn('  no donor found (' . count($unmatched) . ') — these keep the filler photo:');
            foreach ($unmatched as $u) {
                $this->line("    {$u}");
            }
        }

        $this->newLine();
        $this->info("{$changed} product image(s) " . ($dry ? 'would be reassigned' : 'reassigned') . '. No products added or removed.');
        if (!$dry && $changed) {
            $this->line('  Revert with <comment>php artisan zenfoo:dedupe-images --undo</comment>');
        }

        return self::SUCCESS;
    }

    /** Product name reduced to the words that identify the cut. */
    private function normalise(string $name): string
    {
        $s = mb_strtolower($name);
        // Keep what is inside the brackets — "Bangda (Mackerel)" and "Chicken
        // Mince (Keema)" carry the identifying word there, and dropping it was
        // why every fish in store 19 failed to find a donor.
        $s = preg_replace('/\d+\s*(kg|g|gm|ml|l)\b/', ' ', $s);
        $s = preg_replace('/[^a-z0-9 ]/', ' ', $s);

        $words = array_diff(preg_split('/\s+/', trim($s)), self::NOISE);
        $words = array_filter($words, fn ($w) => $w !== '' && !ctype_digit($w));
        $words = array_map(fn ($w) => self::SYNONYM[$this->stem($w)] ?? $this->stem($w), $words);
        $words = array_unique($words);
        sort($words);

        return implode(' ', $words);
    }

    /** Crude singular form, enough to make "Chicken Legs" meet "Leg Piece". */
    private function stem(string $w): string
    {
        return (strlen($w) > 3 && str_ends_with($w, 's') && !str_ends_with($w, 'ss'))
            ? substr($w, 0, -1)
            : $w;
    }

    /**
     * Donor whose name shares the most words with this cut.
     *
     * Requires the first word to agree, so "Mutton Liver" cannot be handed to a
     * chicken product just because both end in "liver".
     */
    private function bestDonor(string $key, array $donors, array $taken, array $freq): ?array
    {
        $want = explode(' ', $key);
        if (!$want || $want[0] === '') {
            return null;
        }

        $best = null;
        $bestScore = 0;

        foreach ($donors as $d) {
            $have = explode(' ', $d['key']);

            // One photo must not cover two different cuts. The same base item
            // may reuse it — "Rohu Fish Whole" and "Rohu Fish Steaks" should
            // both show the Rohu photo — but only when the donor's name is
            // distinctive. A one-word donor like "chicken" is contained in
            // every product name in the store, and letting it be reused handed
            // the whole of store 14 a single whole-bird photo.
            if (isset($taken[$d['image']])) {
                if ($taken[$d['image']] >= 2 || count(array_diff($have, $want))) {
                    continue;
                }
                foreach ($have as $w) {
                    if (($freq[$w] ?? 0) > self::DISTINCTIVE_FREQ) {
                        continue 2;
                    }
                }
            }
            $common = array_intersect($want, $have);
            $shared = count($common);
            if (!$shared) {
                continue;
            }

            // The animal (mutton / chicken / camel / prawns) must match.
            if (!in_array($want[0], $have, true) && !in_array($have[0], $want, true)) {
                continue;
            }

            // A donor whose whole name appears in the product's name is a real
            // match even on one word: "Mackerel" inside "Bangda (Mackerel) 500g".
            $contained = $shared === count($have);
            if ($shared < 2 && !$contained) {
                continue;
            }

            // Weight each shared word by how rare it is in this store. Without
            // this, "Katla Fish Whole" tied between the donors "Katla" and
            // "Fish" and took whichever came first — the generic one.
            $weight = 0;
            foreach ($common as $w) {
                $weight += 1 / max(1, $freq[$w] ?? 1);
            }

            $score = $weight * 100 + ($contained ? 5 : 0) - abs(count($have) - count($want));

            if ($score > $bestScore) {
                $bestScore = $score;
                $best = $d;
            }
        }

        return $best;
    }

    private function undo(): int
    {
        $journal = $this->loadJournal();
        if (!$journal) {
            $this->info('No journal — nothing to restore.');
            return self::SUCCESS;
        }

        foreach (array_reverse($journal) as $r) {
            DB::table('products')->where('id', $r['id'])->update(['image' => $r['old']]);
        }

        @unlink($this->journalPath());
        $this->info('Restored ' . count($journal) . ' product image(s).');

        return self::SUCCESS;
    }

    private function journalPath(): string
    {
        return storage_path('app/' . self::JOURNAL);
    }

    private function loadJournal(): array
    {
        return file_exists($this->journalPath())
            ? (json_decode(file_get_contents($this->journalPath()), true) ?: [])
            : [];
    }

    private function saveJournal(array $rows): void
    {
        if (!is_dir(dirname($this->journalPath()))) {
            mkdir(dirname($this->journalPath()), 0755, true);
        }
        file_put_contents($this->journalPath(), json_encode($rows, JSON_UNESCAPED_SLASHES));
    }
}
