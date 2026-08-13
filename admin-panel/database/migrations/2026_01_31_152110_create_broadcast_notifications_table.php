<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateBroadcastNotificationsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('broadcast_notifications', function (Blueprint $table) {
            $table->id();
            $table->enum('target_type', ['customer', 'seller', 'driver', 'all']);
            $table->string('title');
            $table->text('message');
            $table->string('image')->nullable();
            $table->integer('total_sent')->default(0);
            $table->integer('total_failed')->default(0);
            $table->json('results')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('broadcast_notifications');
    }
}
