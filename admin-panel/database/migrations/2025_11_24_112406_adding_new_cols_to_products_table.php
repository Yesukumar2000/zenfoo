<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddingNewColsToProductsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('products', function (Blueprint $table) {

                // Add other_info column
                $table->text('other_info')->nullable()->after('item_type_id');

                // Add tax column - choose decimal if you need numeric arithmetic
                $table->decimal('tax', 8, 2)->nullable()->after('other_info');
                // alternatively: $table->string('tax')->nullable()->after('other_info');
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
            if (Schema::hasColumn('products', 'tax')) {
                $table->dropColumn('tax');
            }
            if (Schema::hasColumn('products', 'other_info')) {
                $table->dropColumn('other_info');
            }
        });
    
    }
}
