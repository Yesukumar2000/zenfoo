<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddPromoCodeFieldToCartMetadata extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        if (!Schema::hasColumn('cart_metadata', 'promo_code')) {
            Schema::table('cart_metadata', function (Blueprint $table) {
                $table->string('promo_code', 50)->nullable()->after('promocode_id');
            });
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        if (Schema::hasColumn('cart_metadata', 'promo_code')) {
            Schema::table('cart_metadata', function (Blueprint $table) {
                $table->dropColumn('promo_code');
            });
        }
    }
}
