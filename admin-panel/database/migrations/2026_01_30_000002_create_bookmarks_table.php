<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateBookmarksTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('bookmarks', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('bookmarkable_type'); // 'App\Models\Product', 'App\Models\Seller', 'App\Models\Combo'
            $table->unsignedBigInteger('bookmarkable_id'); // id of the product, seller, or combo
            $table->string('type'); // product, seller, combo (for easier filtering)
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');

            $table->index('user_id');
            $table->index(['bookmarkable_type', 'bookmarkable_id']);
            $table->index('type');
            $table->unique(['user_id', 'bookmarkable_type', 'bookmarkable_id']);
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('bookmarks');
    }
}
