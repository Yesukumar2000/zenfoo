<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddPayoutFieldsToSellerWalletTransactionsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('seller_wallet_transactions', function (Blueprint $table) {
            // Add admin_commission column if it doesn't exist
            if (!Schema::hasColumn('seller_wallet_transactions', 'admin_commission')) {
                $table->double('admin_commission')->default(0.00)->after('amount');
            }

            // Add balance tracking columns if they don't exist
            if (!Schema::hasColumn('seller_wallet_transactions', 'balance_before')) {
                $table->double('balance_before')->default(0.00)->after('admin_commission');
            }
            if (!Schema::hasColumn('seller_wallet_transactions', 'balance_after')) {
                $table->double('balance_after')->default(0.00)->after('balance_before');
            }

            // Add reference columns if they don't exist
            if (!Schema::hasColumn('seller_wallet_transactions', 'reference_type')) {
                $table->string('reference_type')->nullable()->after('balance_after');
            }
            if (!Schema::hasColumn('seller_wallet_transactions', 'reference_id')) {
                $table->unsignedBigInteger('reference_id')->nullable()->after('reference_type');
            }

            // Add payout tracking fields
            $table->string('item_name')->nullable()->after('order_item_id');
            $table->boolean('is_paid_to_seller')->default(false)->after('status');
            $table->string('payment_transaction_id')->nullable()->after('is_paid_to_seller');
            $table->timestamp('paid_at')->nullable()->after('payment_transaction_id');
            $table->unsignedBigInteger('paid_by')->nullable()->after('paid_at');

            $table->foreign('paid_by')->references('id')->on('users')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('seller_wallet_transactions', function (Blueprint $table) {
            $table->dropForeign(['paid_by']);
            $table->dropColumn([
                'is_paid_to_seller',
                'payment_transaction_id',
                'paid_at',
                'paid_by',
                'item_name',
                'admin_commission',
                'balance_before',
                'balance_after',
                'reference_type',
                'reference_id'
            ]);
        });
    }
}
