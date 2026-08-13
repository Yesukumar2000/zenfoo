<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class Adding3NewColsToProductsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('products', function (Blueprint $table) {
            $table->unsignedBigInteger('item_type_id')->nullable()->after('store_id');
                $table->foreign('item_type_id')
                    ->references('id')
                    ->on('category_types')
                    ->onDelete('set null'); // change to cascade/restrict if you prefer

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
            // Drop foreign key first (use array syntax)
            if (Schema::hasColumn('products', 'item_type_id')) {
                $table->dropForeign(['item_type_id']);
            }

            // Then drop columns if they exist
            if (Schema::hasColumn('products', 'tax')) {
                $table->dropColumn('tax');
            }
            if (Schema::hasColumn('products', 'other_info')) {
                $table->dropColumn('other_info');
            }
            if (Schema::hasColumn('products', 'item_type_id')) {
                $table->dropColumn('item_type_id');
            }
        });
    
    }


}
