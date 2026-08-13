<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddOrdersSinceLastFaceVerifyToDeliveryBoysTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->integer('orders_since_last_face_verify')->default(0)->after('is_available');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->dropColumn('orders_since_last_face_verify');
        });
    }
}
