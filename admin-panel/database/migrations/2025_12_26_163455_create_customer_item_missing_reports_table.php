<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateCustomerItemMissingReportsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('customer_item_missing_reports', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('customer_id');
            $table->unsignedBigInteger('order_id');
            $table->json('selected_items')->nullable()->comment('JSON of selected store items with products');
            $table->json('selected_combo_items')->nullable()->comment('JSON of selected combo items with products');
            $table->text('description')->nullable()->comment('Customer description of the issue');
            $table->boolean('is_refund_requested')->default(0)->comment('1 = refund requested, 0 = not requested');
            $table->tinyInteger('status')->default(0)->comment('0 = pending, 1 = in_progress, 2 = resolved, 3 = rejected');
            $table->text('admin_remarks')->nullable()->comment('Admin response/remarks');
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
        Schema::dropIfExists('customer_item_missing_reports');
    }
}
