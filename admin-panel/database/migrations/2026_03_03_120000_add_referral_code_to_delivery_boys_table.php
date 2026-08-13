<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use App\Models\DeliveryBoy;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->string('referral_code', 20)->nullable()->unique()->after('mobile');
            $table->unsignedBigInteger('referred_by')->nullable()->after('referral_code');

            // Add foreign key constraint
            $table->foreign('referred_by')
                  ->references('id')
                  ->on('delivery_boys')
                  ->onDelete('set null');
        });

        // Generate referral codes for existing delivery boys
        $this->generateReferralCodes();
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->dropForeign(['referred_by']);
            $table->dropColumn(['referral_code', 'referred_by']);
        });
    }

    /**
     * Generate referral codes for existing delivery boys
     * Starting from 1001, 1002, 1003, etc.
     */
    private function generateReferralCodes()
    {
        // Get all delivery boys ordered by ID
        $deliveryBoys = DB::table('delivery_boys')
            ->whereNull('referral_code')
            ->orderBy('id', 'asc')
            ->get();

        $startingCode = 1001;

        foreach ($deliveryBoys as $index => $deliveryBoy) {
            $referralCode = (string)($startingCode + $index);

            DB::table('delivery_boys')
                ->where('id', $deliveryBoy->id)
                ->update(['referral_code' => $referralCode]);
        }
    }
};
