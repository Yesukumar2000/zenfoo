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
        Schema::table('orders', function (Blueprint $table) {
            $table->double('driver_accepted_lat')->nullable()->default(null)->after('delivery_boy_id');
            $table->double('driver_accepted_lon')->nullable()->default(null)->after('driver_accepted_lat');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['driver_accepted_lat', 'driver_accepted_lon']);
        });
    }
};
