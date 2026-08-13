<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Create pivot table for many-to-many relationship
        Schema::create('delivery_boy_store_location', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('delivery_boy_id');
            $table->unsignedBigInteger('store_location_id');
            $table->timestamps();

            $table->foreign('delivery_boy_id')->references('id')->on('delivery_boys')->onDelete('cascade');
            $table->foreign('store_location_id')->references('id')->on('store_locations')->onDelete('cascade');

            // Prevent duplicate assignments with custom short name
            $table->unique(['delivery_boy_id', 'store_location_id'], 'db_store_location_unique');
        });

        // Remove the old single store_location_id column from delivery_boys table
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->dropForeign(['store_location_id']);
            $table->dropColumn('store_location_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // Add back the single store_location_id column
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->unsignedBigInteger('store_location_id')->nullable()->after('vehicle_id');
            $table->foreign('store_location_id')->references('id')->on('store_locations')->onDelete('set null');
        });

        Schema::dropIfExists('delivery_boy_store_location');
    }
};
