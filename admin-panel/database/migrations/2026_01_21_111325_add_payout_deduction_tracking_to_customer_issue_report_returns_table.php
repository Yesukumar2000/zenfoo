<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddPayoutDeductionTrackingToCustomerIssueReportReturnsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('customer_issue_report_returns', function (Blueprint $table) {
            $table->tinyInteger('is_deducted_from_payout')->nullable()->default(null)->after('is_return_accepted');
            $table->timestamp('deducted_at')->nullable()->after('is_deducted_from_payout');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('customer_issue_report_returns', function (Blueprint $table) {
            $table->dropColumn('is_deducted_from_payout');
            $table->dropColumn('deducted_at');
        });
    }
}
