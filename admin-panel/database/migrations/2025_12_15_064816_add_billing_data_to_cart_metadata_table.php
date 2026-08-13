<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddBillingDataToCartMetadataTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('cart_metadata', function (Blueprint $table) {
            $table->json('billing_breakdown')->nullable()->after('combo_notes');
            $table->json('billing_summary')->nullable()->after('billing_breakdown');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('cart_metadata', function (Blueprint $table) {
            $table->dropColumn(['billing_breakdown', 'billing_summary']);
        });
    }
}
