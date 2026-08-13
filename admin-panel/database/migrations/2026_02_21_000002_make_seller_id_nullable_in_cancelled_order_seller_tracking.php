<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('cancelled_order_seller_tracking', function (Blueprint $table) {
            $table->unsignedBigInteger('seller_id')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('cancelled_order_seller_tracking', function (Blueprint $table) {
            $table->unsignedBigInteger('seller_id')->nullable(false)->change();
        });
    }
};
