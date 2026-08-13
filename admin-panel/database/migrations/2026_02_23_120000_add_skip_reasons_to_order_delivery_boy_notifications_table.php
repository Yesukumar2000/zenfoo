<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddSkipReasonsToOrderDeliveryBoyNotificationsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('order_delivery_boy_notifications', function (Blueprint $table) {
            $table->json('skip_reasons')->nullable()->after('error_message');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('order_delivery_boy_notifications', function (Blueprint $table) {
            $table->dropColumn('skip_reasons');
        });
    }
}
