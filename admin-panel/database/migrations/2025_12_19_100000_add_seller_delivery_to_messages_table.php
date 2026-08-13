<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Modify conversation_type enum to include 'seller_delivery'
        DB::statement("ALTER TABLE messages MODIFY COLUMN conversation_type ENUM('customer', 'seller', 'seller_delivery') NOT NULL");

        // Modify sender_type enum to include 'delivery_boy'
        DB::statement("ALTER TABLE messages MODIFY COLUMN sender_type ENUM('admin', 'customer', 'seller', 'delivery_boy') NOT NULL");

        // Add seller_id column for seller_delivery conversations
        Schema::table('messages', function (Blueprint $table) {
            $table->unsignedBigInteger('seller_id')->nullable()->after('admin_id');
            $table->index('seller_id');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // Remove seller_id column
        Schema::table('messages', function (Blueprint $table) {
            $table->dropIndex(['seller_id']);
            $table->dropColumn('seller_id');
        });

        // Revert conversation_type enum
        DB::statement("ALTER TABLE messages MODIFY COLUMN conversation_type ENUM('customer', 'seller') NOT NULL");

        // Revert sender_type enum
        DB::statement("ALTER TABLE messages MODIFY COLUMN sender_type ENUM('admin', 'customer', 'seller') NOT NULL");
    }
};
