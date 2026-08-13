<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class MakeSellerIdNullableInCustomerIssueReportReturnsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('customer_issue_report_returns', function (Blueprint $table) {
            // Drop the foreign key constraint first
            $table->dropForeign(['seller_id']);

            // Make seller_id nullable
            $table->unsignedBigInteger('seller_id')->nullable()->change();
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
            // Make seller_id not nullable again
            $table->unsignedBigInteger('seller_id')->nullable(false)->change();

            // Re-add the foreign key constraint
            $table->foreign('seller_id')->references('id')->on('sellers')->onDelete('cascade');
        });
    }
}
