<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class FixManualPaymentsApprovedByForeignKey extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('delivery_boy_manual_payments', function (Blueprint $table) {
            // Drop the old foreign key that references users table
            $table->dropForeign(['approved_by']);

            // Add new foreign key that references admins table
            $table->foreign('approved_by')->references('id')->on('admins')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('delivery_boy_manual_payments', function (Blueprint $table) {
            // Drop the admins foreign key
            $table->dropForeign(['approved_by']);

            // Restore the original foreign key to users table
            $table->foreign('approved_by')->references('id')->on('users')->onDelete('set null');
        });
    }
}
