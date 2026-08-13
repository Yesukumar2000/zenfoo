<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddBeforeCleaningAndPiecesToProductsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('products', function (Blueprint $table) {
            $table->string('before_cleaning_weight', 100)->nullable()->after('is_cleaned')->comment('Weight before cleaning, e.g. "1 kg" (for fish store)');
            $table->string('pieces', 100)->nullable()->after('after_cleaning_weight')->comment('Number/range of pieces, e.g. "7-11" (for fish store)');
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
            $table->dropColumn(['before_cleaning_weight', 'pieces']);
        });
    }
}
