<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('wallet_transactions', function (Blueprint $table) {
            $table->unsignedBigInteger('created_by_admin_id')->nullable()->comment('Admin/staff who created this entry, null = system');
            $table->index('created_by_admin_id');
        });
    }

    public function down(): void
    {
        Schema::table('wallet_transactions', function (Blueprint $table) {
            $table->dropIndex(['created_by_admin_id']);
            $table->dropColumn('created_by_admin_id');
        });
    }
};
