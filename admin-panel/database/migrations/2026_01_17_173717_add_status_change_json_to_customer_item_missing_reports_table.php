<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddStatusChangeJsonToCustomerItemMissingReportsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('customer_item_missing_reports', function (Blueprint $table) {
            $table->json('status_change_json')->nullable()->after('admin_remarks');
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
            $table->dropColumn('status_change_json');
        });
    }
}
