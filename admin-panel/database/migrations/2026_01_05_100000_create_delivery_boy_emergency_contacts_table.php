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
        Schema::create('delivery_boy_emergency_contacts', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('delivery_boy_id');
            $table->string('name');
            $table->string('mobile_number');
            $table->string('relation');
            $table->timestamps();

            // Foreign key constraint
            $table->foreign('delivery_boy_id')
                  ->references('id')
                  ->on('delivery_boys')
                  ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('delivery_boy_emergency_contacts');
    }
};
