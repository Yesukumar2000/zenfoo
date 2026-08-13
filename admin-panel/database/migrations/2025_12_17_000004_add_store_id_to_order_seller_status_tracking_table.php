<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('order_seller_status_tracking', function (Blueprint $table) {
            $table->unsignedBigInteger('store_id')->nullable()->after('seller_id');
            $table->index('store_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('order_seller_status_tracking', function (Blueprint $table) {
            $table->dropIndex(['store_id']);
            $table->dropColumn('store_id');
        });
    }
};
