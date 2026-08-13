<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Seed 50 units for food ordering, groceries, and sweets booking
     *
     * @return void
     */
    public function up()
    {
        $units = [
            // ============ WEIGHT UNITS ============
            // Existing: 1-Kilogram(kg), 2-Grams(gm), 3-Pieces(pcs)
            ['id' => 4, 'name' => 'Milligram', 'short_code' => 'mg', 'parent_id' => 2, 'conversion' => 1],
            ['id' => 5, 'name' => 'Quintal', 'short_code' => 'qtl', 'parent_id' => 1, 'conversion' => 100],
            ['id' => 6, 'name' => 'Ton', 'short_code' => 'ton', 'parent_id' => 1, 'conversion' => 1000],

            // ============ VOLUME UNITS ============
            ['id' => 7, 'name' => 'Litre', 'short_code' => 'L', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 8, 'name' => 'Millilitre', 'short_code' => 'ml', 'parent_id' => 7, 'conversion' => 1],
            ['id' => 9, 'name' => 'Gallon', 'short_code' => 'gal', 'parent_id' => 7, 'conversion' => 3.785],
            ['id' => 10, 'name' => 'Fluid Ounce', 'short_code' => 'fl oz', 'parent_id' => 7, 'conversion' => 0.0296],

            // ============ COUNT/QUANTITY UNITS ============
            ['id' => 11, 'name' => 'Dozen', 'short_code' => 'dz', 'parent_id' => 3, 'conversion' => 12],
            ['id' => 12, 'name' => 'Half Dozen', 'short_code' => 'half-dz', 'parent_id' => 3, 'conversion' => 6],
            ['id' => 13, 'name' => 'Pair', 'short_code' => 'pair', 'parent_id' => 3, 'conversion' => 2],
            ['id' => 14, 'name' => 'Unit', 'short_code' => 'unit', 'parent_id' => 0, 'conversion' => 1],

            // ============ PACKAGING UNITS ============
            ['id' => 15, 'name' => 'Pack', 'short_code' => 'pack', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 16, 'name' => 'Packet', 'short_code' => 'pkt', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 17, 'name' => 'Box', 'short_code' => 'box', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 18, 'name' => 'Bottle', 'short_code' => 'btl', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 19, 'name' => 'Can', 'short_code' => 'can', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 20, 'name' => 'Jar', 'short_code' => 'jar', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 21, 'name' => 'Tray', 'short_code' => 'tray', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 22, 'name' => 'Bundle', 'short_code' => 'bundle', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 23, 'name' => 'Carton', 'short_code' => 'ctn', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 24, 'name' => 'Pouch', 'short_code' => 'pouch', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 25, 'name' => 'Sachet', 'short_code' => 'sachet', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 26, 'name' => 'Tube', 'short_code' => 'tube', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 27, 'name' => 'Container', 'short_code' => 'cont', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 28, 'name' => 'Bag', 'short_code' => 'bag', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 29, 'name' => 'Tin', 'short_code' => 'tin', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 30, 'name' => 'Wrapper', 'short_code' => 'wrap', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 31, 'name' => 'Roll', 'short_code' => 'roll', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 32, 'name' => 'Strip', 'short_code' => 'strip', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 33, 'name' => 'Crate', 'short_code' => 'crate', 'parent_id' => 0, 'conversion' => 1],

            // ============ FOOD SERVICE UNITS ============
            ['id' => 34, 'name' => 'Plate', 'short_code' => 'plate', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 35, 'name' => 'Serving', 'short_code' => 'serving', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 36, 'name' => 'Portion', 'short_code' => 'portion', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 37, 'name' => 'Bowl', 'short_code' => 'bowl', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 38, 'name' => 'Cup', 'short_code' => 'cup', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 39, 'name' => 'Glass', 'short_code' => 'glass', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 40, 'name' => 'Mug', 'short_code' => 'mug', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 41, 'name' => 'Slice', 'short_code' => 'slice', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 42, 'name' => 'Scoop', 'short_code' => 'scoop', 'parent_id' => 0, 'conversion' => 1],

            // ============ MEAL/COMBO UNITS ============
            ['id' => 43, 'name' => 'Combo', 'short_code' => 'combo', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 44, 'name' => 'Set', 'short_code' => 'set', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 45, 'name' => 'Thali', 'short_code' => 'thali', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 46, 'name' => 'Meal', 'short_code' => 'meal', 'parent_id' => 0, 'conversion' => 1],

            // ============ SIZE VARIANTS ============
            ['id' => 47, 'name' => 'Small', 'short_code' => 'S', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 48, 'name' => 'Medium', 'short_code' => 'M', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 49, 'name' => 'Large', 'short_code' => 'L', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 50, 'name' => 'Extra Large', 'short_code' => 'XL', 'parent_id' => 0, 'conversion' => 1],

            // ============ COOKING/BAKING UNITS ============
            ['id' => 51, 'name' => 'Teaspoon', 'short_code' => 'tsp', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 52, 'name' => 'Tablespoon', 'short_code' => 'tbsp', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 53, 'name' => 'Pinch', 'short_code' => 'pinch', 'parent_id' => 0, 'conversion' => 1],
        ];

        foreach ($units as $unit) {
            // Check if unit already exists by id or short_code
            $exists = DB::table('units')
                ->where('id', $unit['id'])
                ->orWhere('short_code', $unit['short_code'])
                ->exists();

            if (!$exists) {
                DB::table('units')->insert($unit);
            }
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // Remove units with id >= 4 (keep original 3)
        DB::table('units')->where('id', '>=', 4)->delete();
    }
};
