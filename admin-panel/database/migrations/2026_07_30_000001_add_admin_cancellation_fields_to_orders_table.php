<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('cancellation_reason', 50)->nullable()->comment('Reason code, see Order::$cancelReasons');
            $table->text('cancellation_note')->nullable()->comment('Free text typed by admin');
            $table->unsignedBigInteger('cancelled_by_admin_id')->nullable()->comment('Admin/staff user who cancelled');
            $table->timestamp('cancelled_at')->nullable();
            $table->string('refund_mode', 20)->nullable()->comment('wallet | gateway | none');
            $table->decimal('refund_to_wallet_amount', 12, 2)->nullable();

            $table->index('cancellation_reason');
            $table->index('cancelled_by_admin_id');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropIndex(['cancellation_reason']);
            $table->dropIndex(['cancelled_by_admin_id']);
            $table->dropColumn([
                'cancellation_reason',
                'cancellation_note',
                'cancelled_by_admin_id',
                'cancelled_at',
                'refund_mode',
                'refund_to_wallet_amount',
            ]);
        });
    }
};
