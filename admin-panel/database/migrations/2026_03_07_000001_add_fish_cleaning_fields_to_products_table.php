<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddFishCleaningFieldsToProductsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('products', function (Blueprint $table) {
            $table->tinyInteger('is_cleaned')->default(0)->after('is_skinned_one')->comment('0=Not Cleaned, 1=Cleaned (for fish store)');
            $table->decimal('after_cleaning_weight', 10, 2)->nullable()->after('is_cleaned')->comment('Weight after cleaning (for fish store)');
            $table->text('video_url')->nullable()->after('after_cleaning_weight')->comment('Optional video URL for meat products');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn(['is_cleaned', 'after_cleaning_weight', 'video_url']);
        });
    }
}