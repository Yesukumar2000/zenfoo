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
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->string('mobile_update_otp', 10)->nullable()->after('otp_login');
            $table->string('mobile_update_number', 15)->nullable()->after('mobile_update_otp');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->dropColumn(['mobile_update_otp', 'mobile_update_number']);
        });
    }
};
