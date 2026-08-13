<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateThinkingItemsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('thinking_items', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('img_url')->nullable();
            $table->tinyInteger('status')->default(1)->comment('1: Active, 0: Inactive');
            $table->unsignedBigInteger('category_id');
            $table->timestamps();

            // Foreign key constraint
            $table->foreign('category_id')
                  ->references('id')
                  ->on('categories')
                  ->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('thinking_items');
    }
}
