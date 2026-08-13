<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddCategoryNameAadharFssaiToSellersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('sellers', function (Blueprint $table) {
            $table->string('category_name')->nullable()->after('id');
            $table->string('aadhar_number')->nullable()->after('category_name');
            $table->string('fssai_number')->nullable()->after('aadhar_number');
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
            $table->dropColumn(['category_name', 'aadhar_number', 'fssai_number']);
        });
    }
}
