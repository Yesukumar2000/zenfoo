<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->text('delete_reason')->nullable()->after('deleted_at');
            $table->timestamp('delete_requested_at')->nullable()->after('delete_reason');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['delete_reason', 'delete_requested_at']);
        });
    }
};
