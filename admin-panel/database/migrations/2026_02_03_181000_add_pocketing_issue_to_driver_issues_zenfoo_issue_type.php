<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // For MySQL, we need to use raw SQL to modify enum
        DB::statement("ALTER TABLE driver_issues_zenfoo MODIFY COLUMN issue_type ENUM('incorrect_payout', 'incentive', 'multi_order', 'joining_bonus', 'order_earning', 'pocketing_issue') NOT NULL");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revert back to previous enum values
        DB::statement("ALTER TABLE driver_issues_zenfoo MODIFY COLUMN issue_type ENUM('incorrect_payout', 'incentive', 'multi_order', 'joining_bonus', 'order_earning') NOT NULL");
    }
};
