<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddPreorderColumnsToOrdersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->tinyInteger('is_preorder')->default(0)->after('order_type')->comment('0=Regular Order, 1=Preorder');
            $table->timestamp('preorder_placed_at')->nullable()->after('is_preorder')->comment('When preorder was placed');
            $table->timestamp('preorder_process_date')->nullable()->after('preorder_placed_at')->comment('When preorder will be processed (Friday 6:30 AM)');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['is_preorder', 'preorder_placed_at', 'preorder_process_date']);
        });
    }
}
