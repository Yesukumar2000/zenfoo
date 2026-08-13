<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("ALTER TABLE driver_issues_zenfoo MODIFY COLUMN issue_type ENUM('incorrect_payout','incentive','multi_order','joining_bonus','order_earning','pocketing_issue','not_getting_order_issue','extra_floating_deposited','cash_deposit_issue') NOT NULL");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE driver_issues_zenfoo MODIFY COLUMN issue_type ENUM('incorrect_payout','incentive','multi_order','joining_bonus','order_earning','pocketing_issue','not_getting_order_issue','extra_floating_deposited') NOT NULL");
    }
};
