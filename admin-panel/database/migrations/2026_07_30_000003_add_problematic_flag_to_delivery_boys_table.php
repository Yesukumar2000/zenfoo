<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->tinyInteger('is_problematic')->default(0)->comment('1 = held back by admin, no new orders');
            $table->string('problematic_reason', 500)->nullable();
            $table->unsignedBigInteger('problematic_order_id')->nullable()->comment('Order that caused the flag');
            $table->unsignedBigInteger('marked_problematic_by')->nullable()->comment('Admin/staff user id');
            $table->timestamp('marked_problematic_at')->nullable();

            $table->index('is_problematic');
        });
    }

    public function down(): void
    {
        Schema::table('delivery_boys', function (Blueprint $table) {
            $table->dropIndex(['is_problematic']);
            $table->dropColumn([
                'is_problematic',
                'problematic_reason',
                'problematic_order_id',
                'marked_problematic_by',
                'marked_problematic_at',
            ]);
        });
    }
};
