<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Backfill sellers.vendor_gst_percent from the admin-configured Vendor
 * GST Configurations settings, joined through the seller's store
 * category flags.
 *
 * Dry-run by default. Pass --commit to actually persist the values.
 *
 * Usage:
 *   php artisan vendor-gst:backfill              # preview, no writes
 *   php artisan vendor-gst:backfill --commit     # apply the backfill
 *   php artisan vendor-gst:backfill --overwrite  # also overwrite non-null rows
 */
class BackfillVendorGstPercent extends Command
{
    protected $signature = 'vendor-gst:backfill
                            {--commit : Persist the resolved values to sellers.vendor_gst_percent}
                            {--overwrite : Also rewrite rows that already have a vendor_gst_percent}';

    protected $description = 'Backfill sellers.vendor_gst_percent from Vendor GST Configurations (dry-run unless --commit).';

    public function handle(): int
    {
        if (!Schema::hasColumn('sellers', 'vendor_gst_percent')) {
            $this->error('Column sellers.vendor_gst_percent is missing. Run `php artisan migrate` first.');
            return self::FAILURE;
        }

        $rates = $this->loadGstRates();
        $missing = array_filter($rates, fn ($v) => $v === null);
        if (count($missing) === count($rates)) {
            $this->error('No vendor_gst_* values configured in settings. Admin must save Vendor GST Configurations first.');
            return self::FAILURE;
        }
        if (!empty($missing)) {
            $this->warn('Some categories have no configured rate and will be skipped: ' . implode(', ', array_keys($missing)));
        }

        $query = DB::table('sellers as s')
            ->join('stores as st', 'st.id', '=', 's.store_id')
            ->select(
                's.id',
                's.store_id',
                's.vendor_gst_percent as current_rate',
                's.commission',
                'st.name as store_name',
                'st.is_meat',
                'st.is_food',
                'st.is_super_mart',
                'st.is_vegetable'
            );
        if (!$this->option('overwrite')) {
            $query->whereNull('s.vendor_gst_percent');
        }

        $rows = $query->get();
        if ($rows->isEmpty()) {
            $this->info('Nothing to do — no matching sellers.');
            return self::SUCCESS;
        }

        $previewRows = [];
        $writes = [];
        $skipped = 0;

        foreach ($rows as $row) {
            [$category, $newRate] = $this->resolveCategoryRate($row, $rates);

            if ($newRate === null) {
                $skipped++;
                continue;
            }

            $previewRows[] = [
                $row->id,
                $row->store_name,
                $category,
                $row->current_rate ?? '—',
                $newRate,
            ];
            $writes[$row->id] = $newRate;
        }

        if (empty($writes)) {
            $this->info('No sellers matched a configured GST category. Skipped: ' . $skipped);
            return self::SUCCESS;
        }

        $this->table(
            ['seller_id', 'store_name', 'category', 'current %', 'new %'],
            $previewRows
        );

        if ($skipped) {
            $this->warn("Skipped {$skipped} seller(s) (no category flag set on their store).");
        }

        if (!$this->option('commit')) {
            $this->info('DRY-RUN. ' . count($writes) . ' row(s) would be updated.');
            $this->line('Pass --commit to actually persist.');
            return self::SUCCESS;
        }

        if (!$this->confirm('Apply ' . count($writes) . ' update(s) now?', true)) {
            $this->warn('Aborted by user.');
            return self::SUCCESS;
        }

        DB::transaction(function () use ($writes) {
            foreach ($writes as $sellerId => $rate) {
                DB::table('sellers')->where('id', $sellerId)->update([
                    'vendor_gst_percent' => $rate,
                ]);
            }
        });

        $this->info('Updated ' . count($writes) . ' seller row(s).');
        return self::SUCCESS;
    }

    /**
     * Returns ['Category Label', float|null] for the given store row.
     * Same precedence as
     * SellerOrderSettlementService::resolveVendorGstPercent.
     */
    private function resolveCategoryRate($row, array $rates): array
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

    /**
     * Read the four Vendor GST Configurations values from settings.
     */
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
