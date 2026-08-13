<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Propose (and optionally apply) category flag fixes for stores that
 * are missing all four category flags. The proposal is inferred from
 * the store name using conservative keyword rules.
 *
 * Usage:
 *   php artisan vendor-gst:repair-store-flags             # dry-run, suggestions only
 *   php artisan vendor-gst:repair-store-flags --commit    # apply confidently-classified rows
 *
 * Keyword rules (case-insensitive, in priority order):
 *   meat | chicken | mutton | lamb | beef | pork | fish | camel  -> is_meat
 *   vegetable | fruit | veg                                       -> is_vegetable
 *   super mart | supermart                                        -> is_super_mart
 *   food | restaurant | cuisine | kitchen                         -> is_food
 *   grocery | mart                                                -> AMBIGUOUS (skipped)
 *
 * Stores that don't match any rule are listed under UNCLASSIFIED and
 * skipped — set them manually via the Stores admin page.
 */
class RepairStoreCategoryFlags extends Command
{
    protected $signature = 'vendor-gst:repair-store-flags
                            {--commit : Persist the inferred flags to the stores table}';

    protected $description = 'Suggest is_food/is_meat/is_vegetable/is_super_mart for stores missing all flags.';

    private const RULES = [
        // priority order — first matching keyword wins
        ['flag' => 'is_meat',       'keywords' => ['meat', 'chicken', 'mutton', 'lamb', 'beef', 'pork', 'fish', 'camel']],
        ['flag' => 'is_vegetable',  'keywords' => ['vegetable', 'fruit', ' veg', 'veg ']],
        ['flag' => 'is_super_mart', 'keywords' => ['super mart', 'supermart', 'supermarket']],
        ['flag' => 'is_food',       'keywords' => ['food', 'restaurant', 'cuisine', 'kitchen']],
    ];

    private const AMBIGUOUS_KEYWORDS = ['grocery', ' mart', 'mart '];

    public function handle(): int
    {
        $stores = DB::table('stores')
            ->select('id', 'name', 'is_food', 'is_meat', 'is_vegetable', 'is_super_mart')
            ->where(function ($q) {
                $q->whereNull('is_food')->orWhere('is_food', 0);
            })
            ->where(function ($q) {
                $q->whereNull('is_meat')->orWhere('is_meat', 0);
            })
            ->where(function ($q) {
                $q->whereNull('is_vegetable')->orWhere('is_vegetable', 0);
            })
            ->where(function ($q) {
                $q->whereNull('is_super_mart')->orWhere('is_super_mart', 0);
            })
            ->orderBy('id')
            ->get();

        if ($stores->isEmpty()) {
            $this->info('All stores already have a category flag set.');
            return self::SUCCESS;
        }

        $confident = [];
        $ambiguous = [];
        $unclassified = [];

        foreach ($stores as $store) {
            $name = strtolower(' ' . ($store->name ?? '') . ' ');

            if ($this->matchesAny($name, self::AMBIGUOUS_KEYWORDS)) {
                $ambiguous[] = [$store->id, $store->name, 'matches "grocery"/"mart" — set flag manually'];
                continue;
            }

            $matched = null;
            foreach (self::RULES as $rule) {
                if ($this->matchesAny($name, $rule['keywords'])) {
                    $matched = $rule['flag'];
                    break;
                }
            }

            if ($matched) {
                $confident[] = [$store->id, $store->name, $matched];
            } else {
                $unclassified[] = [$store->id, $store->name, 'no keyword match'];
            }
        }

        if (!empty($confident)) {
            $this->info('Confident classifications:');
            $this->table(['store_id', 'store_name', 'flag to set'], $confident);
        }
        if (!empty($ambiguous)) {
            $this->warn('Ambiguous (skipped — set manually):');
            $this->table(['store_id', 'store_name', 'reason'], $ambiguous);
        }
        if (!empty($unclassified)) {
            $this->warn('Unclassified (skipped — no keyword match):');
            $this->table(['store_id', 'store_name', 'reason'], $unclassified);
        }

        if (!$this->option('commit')) {
            $this->newLine();
            $this->info('DRY-RUN. ' . count($confident) . ' store(s) would be updated.');
            $this->line('Pass --commit to apply the confident classifications.');
            return self::SUCCESS;
        }

        if (empty($confident)) {
            $this->warn('Nothing confident to apply.');
            return self::SUCCESS;
        }

        if (!$this->confirm('Apply ' . count($confident) . ' flag update(s) now?', true)) {
            $this->warn('Aborted by user.');
            return self::SUCCESS;
        }

        DB::transaction(function () use ($confident) {
            foreach ($confident as [$id, , $flag]) {
                DB::table('stores')->where('id', $id)->update([$flag => 1]);
            }
        });

        $this->info('Updated ' . count($confident) . ' store(s). Next step: php artisan vendor-gst:backfill --overwrite --commit');
        return self::SUCCESS;
    }

    private function matchesAny(string $haystack, array $needles): bool
    {
        foreach ($needles as $needle) {
            if (str_contains($haystack, strtolower($needle))) {
                return true;
            }
        }
        return false;
    }
}
