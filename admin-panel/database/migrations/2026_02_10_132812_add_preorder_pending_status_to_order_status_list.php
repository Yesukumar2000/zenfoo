<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class AddPreorderPendingStatusToOrderStatusList extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Insert Preorder Pending status
        DB::table('order_status_lists')->insertOrIgnore([
            'status' => 'Preorder Pending'
        ]);
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // Remove Preorder Pending status
        DB::table('order_status_lists')->where('status', 'Preorder Pending')->delete();
    }
}
