<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class AddReturnToReportTypeEnumInCustomerItemMissingReportsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        DB::statement("ALTER TABLE customer_item_missing_reports MODIFY COLUMN report_type ENUM('missing', 'wrong', 'return') NOT NULL DEFAULT 'missing'");
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        DB::statement("ALTER TABLE customer_item_missing_reports MODIFY COLUMN report_type ENUM('missing', 'wrong') NOT NULL DEFAULT 'missing'");
    }
}
