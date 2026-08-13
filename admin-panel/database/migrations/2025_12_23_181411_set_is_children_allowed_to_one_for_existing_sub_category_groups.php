<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::table('sub_category_groups')
            ->update(['is_children_allowed' => 1]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Optional: revert back to 0 if rollback is needed
        DB::table('sub_category_groups')
            ->update(['is_children_allowed' => 0]);
    }
};
