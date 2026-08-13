<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddSellerIdsStoreIdsToPromoCodesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('promo_codes', function (Blueprint $table) {
            $table->text('seller_ids')->nullable()->after('id');
            $table->boolean('is_specific_sellers')->default('0')->after('seller_ids');
            $table->text('store_ids')->nullable()->after('is_specific_sellers');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('promo_codes', function (Blueprint $table) {
            $table->dropColumn(['seller_ids','is_specific_sellers','store_ids']);
        });
    }
}

