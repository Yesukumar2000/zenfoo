<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddDocumentStatusToSellersTable extends Migration
{
    /**
     * Run the migrations.
     * 0 = pending, 1 = approved, 2 = rejected
     *
     * @return void
     */
    public function up()
    {
        Schema::table('sellers', function (Blueprint $table) {
            $table->tinyInteger('aadhar_status')->default(0)->comment('0=pending,1=approved,2=rejected')->after('national_identity_card');
            $table->tinyInteger('pan_status')->default(0)->comment('0=pending,1=approved,2=rejected')->after('pan_img');
            $table->tinyInteger('fssai_status')->default(0)->comment('0=pending,1=approved,2=rejected')->after('fssai_img');
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
            $table->dropColumn(['aadhar_status', 'pan_status', 'fssai_status']);
        });
    }
}
