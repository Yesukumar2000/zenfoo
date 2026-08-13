<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddDescriptionToStoresTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('stores', function (Blueprint $table) {
            // make icon nullable
            $table->string('icon')->nullable()->change();

            // add description column
            $table->text('description')->nullable()->after('icon');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('stores', function (Blueprint $table) {

            // revert icon to NOT NULL (optional — remove if not needed)
            $table->string('icon')->nullable(false)->change();

            // drop the description column
            $table->dropColumn('description');
        });
    }
}
