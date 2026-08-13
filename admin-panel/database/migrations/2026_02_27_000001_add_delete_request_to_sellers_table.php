<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddDeleteRequestToSellersTable extends Migration
{
    public function up()
    {
        Schema::table('sellers', function (Blueprint $table) {
            $table->text('delete_reason')->nullable()->after('change_order_status_delivered');
            $table->timestamp('delete_requested_at')->nullable()->after('delete_reason');
        });
    }

    public function down()
    {
        Schema::table('sellers', function (Blueprint $table) {
            $table->dropColumn(['delete_reason', 'delete_requested_at']);
        });
    }
}
