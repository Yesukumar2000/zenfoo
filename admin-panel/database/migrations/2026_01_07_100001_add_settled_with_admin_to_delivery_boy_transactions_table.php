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
            $table->boolean('settled_with_admin')->default(false)->after('transaction_date');
            $table->dateTime('settled_at')->nullable()->after('settled_with_admin');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('delivery_boy_transactions', function (Blueprint $table) {
            $table->dropColumn(['settled_with_admin', 'settled_at']);
        });
    }
};
