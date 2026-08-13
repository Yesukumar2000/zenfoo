<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class UpdateStoresTableAddStoreFields extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('sellers', function (Blueprint $table) {

            // Make existing columns nullable
            $table->string('address_proof')->nullable()->change();
            $table->string('pan_number')->nullable()->change();
            $table->unsignedBigInteger('city_id')->nullable()->change();

            // Add new fields
            $table->string('store_location')->after('city_id');
            $table->string('store_city')->after('store_location');

            // File uploads
            $table->string('pan_img')->nullable()->after('tax_number');
            $table->string('fssai_img')->nullable()->after('pan_img');

            // Multiple images stored as JSON
            $table->json('store_images')->nullable()->after('fssai_img');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('sellers', function (Blueprint $table) {

            // revert nullable changes (optional)
            $table->string('address_proof')->nullable(false)->change();
            $table->string('pan_number')->nullable(false)->change();
            $table->unsignedBigInteger('city_id')->nullable(false)->change();

            // drop new columns
            $table->dropColumn([
                'store_location',
                'store_city',
                'pan_img',
                'fssai_img',
                'store_images',
            ]);
        });
    }
}
