<?php

require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

$sellerId = 32; // CinnaMan's Café

echo "================================================================================\n";
echo "SELLER #32 - CinnaMan's Café - PAYABLE AMOUNT CALCULATION\n";
echo "================================================================================\n\n";

// Get seller info
$seller = DB::selectOne("SELECT id, name, store_name, balance FROM sellers WHERE id = ?", [$sellerId]);

if (!$seller) {
    echo "Seller not found!\n";
    exit(1);
}

echo sprintf("Seller: %s (%s)\n", $seller->name, $seller->store_name);
echo sprintf("Current Wallet Balance: ₹%.2f\n\n", $seller->balance ?? 0);

// Get ALL unpaid transactions
$unpaidTransactions = DB::select("
    SELECT
        id, order_id, type, amount,
        is_refunded_to_customer,
        refundable_amount,
        message,
        created_at
    FROM seller_wallet_transactions
    WHERE seller_id = ?
        AND is_paid_to_seller = 0
    ORDER BY created_at DESC
", [$sellerId]);

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "UNPAID TRANSACTIONS\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

if (count($unpaidTransactions) === 0) {
    echo "✅ No unpaid transactions found.\n";
    echo "Admin owes: ₹0.00\n\n";
} else {
    echo sprintf("Found %d unpaid transaction(s):\n\n", count($unpaidTransactions));

    // Calculate using the same logic as get-transactions API
    $totalPayable = 0;
    $totalOriginal = 0;
    $totalRefundDeduction = 0;

    foreach ($unpaidTransactions as $t) {
        $amount = (float) $t->amount;
        $totalOriginal += $amount;

        $refundAmount = 0;
        $payableAmount = $amount;

        // Apply the same logic: if is_refunded_to_customer AND refundable_amount > 0
        if ($t->is_refunded_to_customer && $t->refundable_amount > 0) {
            $refundAmount = (float) $t->refundable_amount;
            $payableAmount = $amount - $refundAmount;
            $totalRefundDeduction += $refundAmount;
        }

        $totalPayable += $payableAmount;

        // Display transaction
        echo sprintf("Transaction #%d (Order: %s)\n", $t->id, $t->order_id ?? 'N/A');
        echo sprintf("  Type: %s | Date: %s\n", $t->type, $t->created_at);
        echo sprintf("  Amount: ₹%.2f", $amount);

        if ($refundAmount > 0) {
            echo sprintf(" - Refund: ₹%.2f = Payable: ₹%.2f ⚠️\n", $refundAmount, $payableAmount);
        } else {
            echo sprintf(" = Payable: ₹%.2f\n", $payableAmount);
        }

        if ($t->message) {
            echo sprintf("  Message: %s\n", substr($t->message, 0, 80));
        }
        echo "\n";
    }

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    echo "CALCULATION SUMMARY (Using get-transactions API logic)\n";
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

    echo sprintf("Original Total:  ₹%.2f\n", $totalOriginal);
    if ($totalRefundDeduction > 0) {
        echo sprintf("Refund Deduction: -₹%.2f\n", $totalRefundDeduction);
        echo "─────────────────────────\n";
    }
    echo sprintf("ADMIN OWES:      ₹%.2f\n", $totalPayable);
}

// Get paid transactions for reference
$paidTransactions = DB::selectOne("
    SELECT
        COUNT(*) as count,
        SUM(amount) as original_total,
        SUM(CASE WHEN is_refunded_to_customer = 1 THEN refundable_amount ELSE 0 END) as refund_total,
        SUM(CASE
            WHEN is_refunded_to_customer = 1 AND refundable_amount > 0
            THEN amount - refundable_amount
            ELSE amount
        END) as paid_total
    FROM seller_wallet_transactions
    WHERE seller_id = ? AND is_paid_to_seller = 1
", [$sellerId]);

echo "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "PAID TRANSACTIONS (For Reference)\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

if ($paidTransactions->count > 0) {
    echo sprintf("Total Paid: %d transaction(s)\n", $paidTransactions->count);
    echo sprintf("Original: ₹%.2f - Refunds: ₹%.2f = Paid: ₹%.2f\n",
        $paidTransactions->original_total,
        $paidTransactions->refund_total,
        $paidTransactions->paid_total
    );
} else {
    echo "No paid transactions.\n";
}

echo "\n================================================================================\n";
echo "NOW CHECK ADMIN PANEL:\n";
echo "1. Go to Seller Transactions > Weekly Payment\n";
echo "2. Select Seller #32 (CinnaMan's Café)\n";
echo "3. Verify 'Need to Pay' amount matches the calculation above\n";
echo "4. Check storage/logs/laravel.log for detailed breakdown\n";
echo "================================================================================\n";
