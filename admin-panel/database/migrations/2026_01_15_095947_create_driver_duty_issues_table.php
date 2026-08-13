<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateDriverDutyIssuesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('driver_duty_issues', function (Blueprint $table) {
            $table->id();
            $table->enum('type', ['not_getting_orders', 'change_zone']);
            $table->unsignedBigInteger('delivery_boy_id');
            $table->dateTime('date_of_issue');
            $table->text('admin_response')->nullable();
            $table->timestamps();

            $table->foreign('delivery_boy_id')->references('id')->on('delivery_boys')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('driver_duty_issues');
    }
}
