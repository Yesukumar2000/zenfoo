<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateDriverIssuesZenfooTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('driver_issues_zenfoo', function (Blueprint $table) {
            $table->id();
            $table->enum('issue_type', ['incorrect_payout', 'incentive', 'multi_order', 'joining_bonus']);
            $table->unsignedBigInteger('driver_id');
            $table->json('issue_ids')->nullable();
            $table->text('description');
            $table->json('attachments')->nullable();
            $table->enum('status', ['pending', 'resolved', 'rejected'])->default('pending');
            $table->text('admin_message')->nullable();
            $table->timestamps();

            // Foreign key constraint
            $table->foreign('driver_id')->references('id')->on('delivery_boys')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('driver_issues_zenfoo');
    }
}
