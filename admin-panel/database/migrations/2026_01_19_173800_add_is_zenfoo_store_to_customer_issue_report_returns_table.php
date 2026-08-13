<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddIsZenfooStoreToCustomerIssueReportReturnsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('customer_issue_report_returns', function (Blueprint $table) {
            $table->tinyInteger('is_zenfoo_store')->default(0)->after('is_return_accepted');
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
            $table->dropColumn('is_zenfoo_store');
        });
    }
}
