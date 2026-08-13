<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * End-to-end diagnostic for the Vendor GST flow.
 *
 * Verifies (read-only):
 *   1. Current admin-configured rates in `settings`.
 *   2. Each seller's persisted snapshot in `sellers.vendor_gst_percent`.
 *   3. What the live resolver would return right now for each seller,
 *      i.e. the value the partner app sees on /api/seller/registration-data-dev.
 *   4. Drift between snapshot and live (snapshot stale after an admin rate change).
 *
 * Usage:
 *   php artisan vendor-gst:check                 # all sellers, full table
 *   php artisan vendor-gst:check --seller-id=89  # one seller only
 *   php artisan vendor-gst:check --drift-only    # only rows where snapshot != live
 */
class CheckVendorGstResolution extends Command
{
    protected $signature = 'vendor-gst:check
                            {--seller-id= : Limit output to a single seller}
                            {--drift-only : Only show rows where snapshot != live}';

    protected $description = 'Read-only diagnostic of the vendor GST resolution pipeline.';

    public function handle(): int
    {
        $rates = $this->loadGstRates();
        $this->renderAdminSettingsTable($rates);

        if (!Schema::hasColumn('sellers', 'vendor_gst_percent')) {
            $this->error('Column sellers.vendor_gst_percent is missing. Run `php artisan migrate` first.');
            return self::FAILURE;
        }

        $query = DB::table('sellers as s')
            ->join('stores as st', 'st.id', '=', 's.store_id')
            ->select(
                's.id',
                's.store_id',
                's.vendor_gst_percent as snapshot',
                'st.name as store_name',
                'st.is_meat',
                'st.is_food',
                'st.is_super_mart',
                'st.is_vegetable'
            )
            ->orderBy('s.id');

        if ($sellerId = $this->option('seller-id')) {
            $query->where('s.id', (int) $sellerId);
        }

        $rows = $query->get();
        if ($rows->isEmpty()) {
            $this->warn('No sellers matched.');
            return self::SUCCESS;
        }

        $tableRows = [];
        $driftCount = 0;
        $noCategoryCount = 0;
        $missingRateCount = 0;

        foreach ($rows as $row) {
            [$category, $liveRate] = $this->resolve($row, $rates);

            $snapshot = $row->snapshot;
            $drift = ($snapshot !== null && $liveRate !== null && (float) $snapshot !== (float) $liveRate);

            if ($category === '(no category flag)') {
                $noCategoryCount++;
            } elseif ($liveRate === null) {
                $missingRateCount++;
            } elseif ($drift) {
                $driftCount++;
            }

            if ($this->option('drift-only') && !$drift) {
                continue;
            }

            $status = '✓ OK';
            if ($category === '(no category flag)') {
                $status = '⚠ no category';
            } elseif ($liveRate === null) {
                $status = '⚠ setting unset';
            } elseif ($snapshot === null) {
                $status = '⚠ no snapshot';
            } elseif ($drift) {
                $status = '⚠ stale snapshot';
            }

            $tableRows[] = [
                $row->id,
                $row->store_name,
                $category,
                $snapshot ?? '—',
                $liveRate ?? '—',
                $status,
            ];
        }

        if (empty($tableRows)) {
            $this->info($this->option('drift-only')
                ? 'No drift detected. Every seller\'s snapshot matches the live rate.'
                : 'No rows to display.');
        } else {
            $this->table(
                ['seller_id', 'store_name', 'category', 'snapshot %', 'live %', 'status'],
                $tableRows
            );
        }

        $this->newLine();
        $this->info('Summary:');
        $this->line("  Sellers scanned: " . $rows->count());
        $this->line("  No category flag on store: $noCategoryCount");
        $this->line("  Category set but setting unconfigured: $missingRateCount");
        $this->line("  Snapshot stale vs live (drift): $driftCount");
        $this->newLine();
        $this->line('To re-snapshot drifted rows: php artisan vendor-gst:backfill --overwrite --commit');

        return self::SUCCESS;
    }

    private function renderAdminSettingsTable(array $rates): void
    {
        $this->info('Current Vendor GST Configurations (from settings table):');
        $this->table(
            ['variable', 'category', 'value %'],
            [
                ['vendor_gst_vegetables_fruits', 'Vegetables & Fruits', $rates['vendor_gst_vegetables_fruits'] ?? 'unset'],
                ['vendor_gst_chicken_meat',      'Chicken & Meat',      $rates['vendor_gst_chicken_meat']      ?? 'unset'],
                ['vendor_gst_food',              'Food',                $rates['vendor_gst_food']              ?? 'unset'],
                ['vendor_gst_super_mart',        'Super Mart',          $rates['vendor_gst_super_mart']        ?? 'unset'],
            ]
        );
        $this->newLine();
    }

    private function resolve($row, array $rates): array
    {
        if (!empty($row->is_meat)) {
            return ['Chicken & Meat', $rates['vendor_gst_chicken_meat']];
        }
        if (!empty($row->is_food)) {
            return ['Food', $rates['vendor_gst_food']];
        }
        if (!empty($row->is_super_mart)) {
            return ['Super Mart', $rates['vendor_gst_super_mart']];
        }
        if (!empty($row->is_vegetable)) {
            return ['Vegetables & Fruits', $rates['vendor_gst_vegetables_fruits']];
        }
        return ['(no category flag)', null];
    }

    private function loadGstRates(): array
    {
        $variables = [
            'vendor_gst_chicken_meat',
            'vendor_gst_food',
            'vendor_gst_super_mart',
            'vendor_gst_vegetables_fruits',
        ];

        $pairs = DB::table('settings')
            ->whereIn('variable', $variables)
            ->pluck('value', 'variable')
            ->toArray();

        $rates = [];
        foreach ($variables as $variable) {
            $value = $pairs[$variable] ?? null;
            $rates[$variable] = ($value === null || $value === '') ? null : (float) $value;
        }
        return $rates;
    }
}
