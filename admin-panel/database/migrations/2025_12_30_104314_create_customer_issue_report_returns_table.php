<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateCustomerIssueReportReturnsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('customer_issue_report_returns', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('report_id');
            $table->unsignedBigInteger('seller_id');
            $table->unsignedBigInteger('customer_id');
            $table->date('date');
            $table->json('product_ids');
            $table->unsignedBigInteger('delivery_partner_id')->nullable();
            $table->date('delivered_date')->nullable();
            $table->tinyInteger('is_return_accepted')->default(0);
            $table->timestamps();

            $table->foreign('report_id')->references('id')->on('customer_item_missing_reports')->onDelete('cascade');
            $table->foreign('seller_id')->references('id')->on('sellers')->onDelete('cascade');
            $table->foreign('customer_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('delivery_partner_id')->references('id')->on('delivery_boys')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('customer_issue_report_returns');
    }
}
