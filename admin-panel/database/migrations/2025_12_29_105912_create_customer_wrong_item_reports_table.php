<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateCustomerWrongItemReportsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('customer_wrong_item_reports', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('customer_id');
            $table->unsignedBigInteger('order_id');
            $table->string('img_url', 500)->nullable();
            $table->string('description', 200);
            $table->boolean('is_refund_requested')->default(0);
            $table->tinyInteger('status')->default(0)->comment('0 = pending, 1 = in_progress, 2 = resolved, 3 = rejected');
            $table->text('admin_remarks')->nullable();
            $table->timestamps();

            $table->index('customer_id');
            $table->index('order_id');
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
        Schema::dropIfExists('customer_wrong_item_reports');
    }
}
