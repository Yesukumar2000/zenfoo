<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\Unit;
use Illuminate\Database\Seeder;

/**
 * Bulk-fills the fish-cut fields (before_cleaning_weight, after_cleaning_weight,
 * pieces) for all fish-store (store_id = 19) products that don't have them yet.
 *
 * Values are ESTIMATES derived from each product's primary variant weight:
 *   - before_cleaning_weight = the variant's quantity (e.g. "1 kg")
 *   - after_cleaning_weight  ~ 55% of that weight (whole fish lose ~45% to cleaning)
 *   - pieces                 = a weight-based range (~6-10 per kg)
 * Only EMPTY fields are written, so any value entered by hand is preserved.
 *
 * Run:  php artisan db:seed --class=FishCleaningDataSeeder
 */
class FishCleaningDataSeeder extends Seeder
{
    /** Fraction of weight that remains after cleaning. */
    const YIELD_RATIO = 0.55;

    public function run()
    {
        $products = Product::where('store_id', 19)->get();

        $filled = 0;
        $skipped = 0;

        foreach ($products as $product) {
            $variant = ProductVariant::where('product_id', $product->id)
                ->orderBy('id')
                ->first();

            if (!$variant) {
                $skipped++;
                continue;
            }

            $unit = Unit::find($variant->stock_unit_id);
            $shortCode = $unit ? trim($unit->short_code) : '';
            $measurement = (float) $variant->measurement;

            if ($measurement <= 0) {
                $skipped++;
                continue;
            }

            // Weight in kilograms (only weight-based units can yield after/pieces).
            $kg = $this->toKilograms($measurement, $shortCode);

            $dirty = false;

            // Before cleaning weight = the listed quantity, e.g. "1 kg" / "500 g".
            if ($this->isEmpty($product->before_cleaning_weight)) {
                $product->before_cleaning_weight =
                    $this->trimNumber($measurement) . ' ' . $shortCode;
                $dirty = true;
            }

            if ($kg !== null && $kg > 0) {
                if ($this->isEmpty($product->after_cleaning_weight)) {
                    $product->after_cleaning_weight = $this->formatWeight($kg * self::YIELD_RATIO);
                    $dirty = true;
                }

                if ($this->isEmpty($product->pieces)) {
                    $low = max(1, (int) round($kg * 6));
                    $high = (int) round($kg * 10);
                    if ($high <= $low) {
                        $high = $low + 2;
                    }
                    $product->pieces = $low . '-' . $high;
                    $dirty = true;
                }

                // These products are now described as cleaned cuts.
                if ((int) $product->is_cleaned !== 1) {
                    $product->is_cleaned = 1;
                    $dirty = true;
                }
            }

            if ($dirty) {
                $product->save();
                $filled++;
                $this->command->info(
                    "#{$product->id} {$product->name} => before: {$product->before_cleaning_weight}, "
                    . "after: {$product->after_cleaning_weight}, pieces: {$product->pieces}"
                );
            } else {
                $skipped++;
            }
        }

        $this->command->info("Done. Filled {$filled} products, skipped {$skipped}.");
    }

    private function isEmpty($value): bool
    {
        return $value === null || trim((string) $value) === '';
    }

    /** Convert a measurement + unit short code to kilograms, or null if not weight-based. */
    private function toKilograms(float $measurement, string $shortCode): ?float
    {
        $code = strtolower(trim($shortCode));
        if (in_array($code, ['kg', 'kgs', 'kilogram', 'kilograms'])) {
            return $measurement;
        }
        if (in_array($code, ['g', 'gm', 'gms', 'gram', 'grams'])) {
            return $measurement / 1000;
        }
        return null; // pcs, dozen, etc. — no weight-based yield.
    }

    /** Pretty weight: grams when < 1 kg (rounded to 10 g), otherwise kg. */
    private function formatWeight(float $kg): string
    {
        if ($kg < 1) {
            $grams = (int) (round(($kg * 1000) / 10) * 10);
            return $grams . ' g';
        }
        return $this->trimNumber(round($kg, 2)) . ' kg';
    }

    /** "1.00" -> "1", "1.50" -> "1.5". */
    private function trimNumber(float $n): string
    {
        return rtrim(rtrim(number_format($n, 2, '.', ''), '0'), '.');
    }
}
