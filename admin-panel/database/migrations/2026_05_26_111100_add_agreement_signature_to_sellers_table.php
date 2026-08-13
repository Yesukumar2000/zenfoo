<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddAgreementSignatureToSellersTable extends Migration
{
    /**
     * Run the migrations.
     * Adds storage for the raw digital signature image (PNG) captured at agreement signing.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('sellers', function (Blueprint $table) {
            $table->text('agreement_signature')->nullable()->after('agreement_status');
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
            $table->dropColumn('agreement_signature');
        });
    }
}
