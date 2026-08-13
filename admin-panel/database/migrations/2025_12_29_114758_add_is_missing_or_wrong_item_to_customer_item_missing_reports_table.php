<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddIsMissingOrWrongItemToCustomerItemMissingReportsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('customer_item_missing_reports', function (Blueprint $table) {
            $table->enum('report_type', ['missing', 'wrong'])->default('missing')->after('order_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('customer_item_missing_reports', function (Blueprint $table) {
            $table->dropColumn('report_type');
        });
    }
}
