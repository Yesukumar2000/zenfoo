<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateLearningVideosTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('learning_videos', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('topic_id');
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('video_url');
            $table->string('video_type')->default('upload')->comment('upload, youtube, vimeo, etc.');
            $table->string('thumbnail')->nullable();
            $table->integer('duration')->nullable()->comment('Duration in seconds');
            $table->integer('sort_order')->default(0);
            $table->tinyInteger('status')->default(1)->comment('1: Active, 0: Inactive');
            $table->unsignedBigInteger('created_by')->nullable();
            $table->timestamps();

            $table->foreign('topic_id')->references('id')->on('learning_topics')->onDelete('cascade');
            $table->index('topic_id');
            $table->index('status');
            $table->index('sort_order');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('learning_videos');
    }
}
