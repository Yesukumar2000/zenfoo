<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->text('delete_reason')->nullable()->after('rejection_remark');
            $table->timestamp('delete_requested_at')->nullable()->after('delete_reason');
            $table->timestamp('deleted_at')->nullable()->after('delete_requested_at');
        });
    }

    public function down(): void
    {
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->dropColumn(['delete_reason', 'delete_requested_at', 'deleted_at']);
        });
    }
};
