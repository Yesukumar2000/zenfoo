<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Add extra_floating_deposited to issue_type enum
        DB::statement("ALTER TABLE driver_issues_zenfoo MODIFY COLUMN issue_type ENUM('incorrect_payout','incentive','multi_order','joining_bonus','order_earning','pocketing_issue','not_getting_order_issue','extra_floating_deposited') NOT NULL");

        Schema::table('driver_issues_zenfoo', function (Blueprint $table) {
            $table->decimal('amount', 10, 2)->nullable()->after('attachments');
            $table->enum('pay_type', ['upi', 'bank'])->nullable()->after('amount');
        });
    }

    public function down(): void
    {
        Schema::table('driver_issues_zenfoo', function (Blueprint $table) {
            $table->dropColumn(['amount', 'pay_type']);
        });

        DB::statement("ALTER TABLE driver_issues_zenfoo MODIFY COLUMN issue_type ENUM('incorrect_payout','incentive','multi_order','joining_bonus','order_earning','pocketing_issue','not_getting_order_issue') NOT NULL");
    }
};
