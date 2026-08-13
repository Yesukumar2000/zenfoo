<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('sub_category_groups', function (Blueprint $table) {
            $table->boolean('is_children_allowed')
                  ->default(0)
                  ->after('id');

            $table->index('is_children_allowed');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('sub_category_groups', function (Blueprint $table) {
            $table->dropIndex(['is_children_allowed']);
            $table->dropColumn('is_children_allowed');
        });
    }
};
