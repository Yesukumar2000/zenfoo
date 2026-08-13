<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateCustomerClaimedMilestonesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('customer_claimed_milestones', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('customer_id');
            $table->unsignedBigInteger('milestone_id')->nullable();
            $table->json('milestone_meta_data');
            $table->date('claimed_date');
            $table->decimal('reward_amount', 10, 2)->default(0);
            $table->enum('status', ['claimed', 'used'])->default('claimed');
            $table->unsignedBigInteger('used_in_order_id')->nullable();
            $table->date('used_date')->nullable();
            $table->timestamps();

            $table->index('customer_id');
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('customer_claimed_milestones');
    }
}
