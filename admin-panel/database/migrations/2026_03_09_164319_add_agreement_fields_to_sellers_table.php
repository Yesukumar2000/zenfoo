<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddAgreementFieldsToSellersTable extends Migration
{
    /**
     * Run the migrations.
     * Adds seller agreement PDF storage and verification status
     *
     * @return void
     */
    public function up()
    {
        Schema::table('sellers', function (Blueprint $table) {
            $table->text('agreement_pdf')->nullable()->after('fssai_img');
            $table->tinyInteger('agreement_status')->nullable()->default(0)->comment('0=pending,1=approved,2=rejected')->after('agreement_pdf');
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
            $table->dropColumn(['agreement_pdf', 'agreement_status']);
        });
    }
}
