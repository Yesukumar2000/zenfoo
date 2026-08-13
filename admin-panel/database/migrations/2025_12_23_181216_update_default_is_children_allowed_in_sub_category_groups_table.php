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
                  ->default(1)
                  ->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('sub_category_groups', function (Blueprint $table) {
            $table->boolean('is_children_allowed')
                  ->default(0)
                  ->change();
        });
    }
};
