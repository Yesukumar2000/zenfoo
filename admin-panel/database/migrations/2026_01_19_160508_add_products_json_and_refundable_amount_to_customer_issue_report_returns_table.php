<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddProductsJsonAndRefundableAmountToCustomerIssueReportReturnsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('customer_issue_report_returns', function (Blueprint $table) {
            $table->json('products_json')->nullable()->after('product_ids');
            $table->decimal('refundable_amount', 10, 2)->nullable()->after('products_json');
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
            $table->dropColumn('products_json');
            $table->dropColumn('refundable_amount');
        });
    }
}
