<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('order_items', function (Blueprint $table) {
            // Make seller_id nullable to support Zenfoo store (admin-managed) products
            $table->unsignedBigInteger('seller_id')->nullable()->change();
        });

        Schema::table('order_seller_status_tracking', function (Blueprint $table) {
            // Make seller_id nullable to support Zenfoo store (admin-managed) products
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
        Schema::table('order_items', function (Blueprint $table) {
            // Revert seller_id to NOT NULL
            $table->unsignedBigInteger('seller_id')->nullable(false)->change();
        });

        Schema::table('order_seller_status_tracking', function (Blueprint $table) {
            // Revert seller_id to NOT NULL
            $table->unsignedBigInteger('seller_id')->nullable(false)->change();
        });
    }
};
