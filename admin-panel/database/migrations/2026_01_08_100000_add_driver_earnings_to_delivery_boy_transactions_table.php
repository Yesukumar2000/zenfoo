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
        Schema::table('delivery_boy_transactions', function (Blueprint $table) {
            $table->double('delivery_charge')->default(0)->after('amount')->comment('Delivery charge - driver keeps this');
            $table->double('delivery_tip')->default(0)->after('delivery_charge')->comment('Delivery tip - driver keeps this');
            $table->double('bonus_amount')->default(0)->after('delivery_tip')->comment('Bonus amount - driver keeps this');
            $table->double('driver_earnings')->default(0)->after('bonus_amount')->comment('Total driver earnings (delivery_charge + delivery_tip + bonus_amount)');
            $table->double('admin_cash')->default(0)->after('driver_earnings')->comment('Cash to be settled with admin (amount - driver_earnings)');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('delivery_boy_transactions', function (Blueprint $table) {
            $table->dropColumn(['delivery_charge', 'delivery_tip', 'bonus_amount', 'driver_earnings', 'admin_cash']);
        });
    }
};
