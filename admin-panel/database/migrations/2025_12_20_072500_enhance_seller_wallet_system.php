<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class EnhanceSellerWalletSystem extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Enhance seller_wallet_transactions table
        Schema::table('seller_wallet_transactions', function (Blueprint $table) {
            // Add before and after balance tracking
            $table->decimal('balance_before', 10, 2)->default(0)->after('amount');
            $table->decimal('balance_after', 10, 2)->default(0)->after('balance_before');

            // Add reference fields
            $table->string('reference_type')->nullable()->after('order_item_id')->comment('withdrawal, order, credit, debit, refund, commission, adjustment');
            $table->unsignedBigInteger('reference_id')->nullable()->after('reference_type')->comment('ID of the referenced record');

            // Enhance existing fields
            $table->text('admin_note')->nullable()->after('message')->comment('Admin note for manual transactions');
            $table->unsignedBigInteger('processed_by')->nullable()->after('admin_note')->comment('Admin ID who processed this transaction');

            // Add indexes for better performance
            $table->index('seller_id');
            $table->index('order_id');
            $table->index(['reference_type', 'reference_id']);
            $table->index('created_at');
        });

        // Create seller_withdrawal_requests table
        Schema::create('seller_withdrawal_requests', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('seller_id');
            $table->decimal('amount', 10, 2);
            $table->decimal('balance_before', 10, 2)->default(0);
            $table->decimal('balance_after', 10, 2)->nullable()->comment('Balance after withdrawal (set when approved)');

            // Bank details (can be different from seller's registered account)
            $table->string('account_number');
            $table->string('bank_ifsc_code');
            $table->string('account_name');
            $table->string('bank_name');
            $table->string('branch_name')->nullable();

            // Status tracking
            $table->enum('status', ['pending', 'approved', 'rejected', 'processing', 'completed'])->default('pending');
            $table->text('seller_note')->nullable()->comment('Seller note with withdrawal request');
            $table->text('admin_note')->nullable()->comment('Admin note for rejection or approval');

            // Processing details
            $table->unsignedBigInteger('processed_by')->nullable()->comment('Admin ID who processed');
            $table->timestamp('processed_at')->nullable();
            $table->string('payment_method')->nullable()->comment('NEFT, RTGS, UPI, etc.');
            $table->string('transaction_reference')->nullable()->comment('Bank transaction reference number');

            $table->timestamps();

            // Indexes
            $table->index('seller_id');
            $table->index('status');
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // Drop new table
        Schema::dropIfExists('seller_withdrawal_requests');

        // Remove added columns from seller_wallet_transactions
        Schema::table('seller_wallet_transactions', function (Blueprint $table) {
            $table->dropIndex(['seller_id']);
            $table->dropIndex(['order_id']);
            $table->dropIndex(['reference_type', 'reference_id']);
            $table->dropIndex(['created_at']);

            $table->dropColumn([
                'balance_before',
                'balance_after',
                'reference_type',
                'reference_id',
                'admin_note',
                'processed_by',
            ]);
        });
    }
}
