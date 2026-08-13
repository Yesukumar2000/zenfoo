<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('messages', function (Blueprint $table) {
            $table->id();

            // Conversation type: 'customer' (customer <=> admin) or 'seller' (seller <=> admin)
            $table->enum('conversation_type', ['customer', 'seller']);

            // The customer or seller who is part of the conversation
            $table->unsignedBigInteger('participant_id');

            // The admin involved in the conversation
            $table->unsignedBigInteger('admin_id')->nullable();

            // Who sent this message: 'admin', 'customer', or 'seller'
            $table->enum('sender_type', ['admin', 'customer', 'seller']);

            // The actual sender's user id
            $table->unsignedBigInteger('sender_id');

            // Message content
            $table->text('message');

            // Optional attachment
            $table->string('attachment')->nullable();

            // Read status
            $table->timestamp('read_at')->nullable();

            $table->timestamps();

            // Indexes for faster queries
            $table->index(['conversation_type', 'participant_id']);
            $table->index(['sender_type', 'sender_id']);
            $table->index('admin_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('messages');
    }
};
