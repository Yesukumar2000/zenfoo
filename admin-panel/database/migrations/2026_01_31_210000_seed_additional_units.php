<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Seed additional units (30 more units to complete 50 total)
     *
     * @return void
     */
    public function up()
    {
        $units = [
            // ============ MORE PACKAGING UNITS ============
            ['id' => 23, 'name' => 'Sachet', 'short_code' => 'sachet', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 24, 'name' => 'Tube', 'short_code' => 'tube', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 25, 'name' => 'Container', 'short_code' => 'cont', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 26, 'name' => 'Bag', 'short_code' => 'bag', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 27, 'name' => 'Tin', 'short_code' => 'tin', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 28, 'name' => 'Wrapper', 'short_code' => 'wrap', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 29, 'name' => 'Roll', 'short_code' => 'roll', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 30, 'name' => 'Strip', 'short_code' => 'strip', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 31, 'name' => 'Crate', 'short_code' => 'crate', 'parent_id' => 0, 'conversion' => 1],

            // ============ FOOD SERVICE UNITS ============
            ['id' => 32, 'name' => 'Plate', 'short_code' => 'plate', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 33, 'name' => 'Serving', 'short_code' => 'serving', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 34, 'name' => 'Portion', 'short_code' => 'portion', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 35, 'name' => 'Bowl', 'short_code' => 'bowl', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 36, 'name' => 'Cup', 'short_code' => 'cup', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 37, 'name' => 'Glass', 'short_code' => 'glass', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 38, 'name' => 'Mug', 'short_code' => 'mug', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 39, 'name' => 'Slice', 'short_code' => 'slice', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 40, 'name' => 'Scoop', 'short_code' => 'scoop', 'parent_id' => 0, 'conversion' => 1],

            // ============ MEAL/COMBO UNITS ============
            ['id' => 41, 'name' => 'Combo', 'short_code' => 'combo', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 42, 'name' => 'Set', 'short_code' => 'set', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 43, 'name' => 'Thali', 'short_code' => 'thali', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 44, 'name' => 'Meal', 'short_code' => 'meal', 'parent_id' => 0, 'conversion' => 1],

            // ============ SIZE VARIANTS ============
            ['id' => 45, 'name' => 'Small', 'short_code' => 'S', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 46, 'name' => 'Medium', 'short_code' => 'M', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 47, 'name' => 'Large', 'short_code' => 'L', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 48, 'name' => 'Extra Large', 'short_code' => 'XL', 'parent_id' => 0, 'conversion' => 1],

            // ============ COOKING/BAKING UNITS ============
            ['id' => 49, 'name' => 'Teaspoon', 'short_code' => 'tsp', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 50, 'name' => 'Tablespoon', 'short_code' => 'tbsp', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 51, 'name' => 'Pinch', 'short_code' => 'pinch', 'parent_id' => 0, 'conversion' => 1],

            // ============ EXTRA UNITS ============
            ['id' => 52, 'name' => 'Half', 'short_code' => 'half', 'parent_id' => 0, 'conversion' => 1],
            ['id' => 53, 'name' => 'Quarter', 'short_code' => 'qtr', 'parent_id' => 0, 'conversion' => 1],
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
        // Remove units with id >= 23
        DB::table('units')->where('id', '>=', 23)->delete();
    }
};
