<?php

require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "================================================================================\n";
echo "LIVE DATABASE ANALYSIS - Refunded Transactions\n";
echo "================================================================================\n\n";

// 1. Find all sellers with refunded transactions (paid or unpaid)
echo "1️⃣  SELLERS WITH REFUNDED TRANSACTIONS\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

$sellersWithRefunds = DB::select("
    SELECT
        s.id,
        s.name,
        s.store_name,
        COUNT(*) as refunded_txn_count,
        SUM(CASE WHEN t.is_paid_to_seller = 0 THEN 1 ELSE 0 END) as unpaid_refunded_count,
        SUM(CASE WHEN t.is_paid_to_seller = 1 THEN 1 ELSE 0 END) as paid_refunded_count,
        SUM(t.amount) as total_original,
        SUM(t.refundable_amount) as total_refunds,
        SUM(CASE
            WHEN t.refundable_amount > 0
            THEN t.amount - t.refundable_amount
            ELSE t.amount
        END) as total_payable
    FROM seller_wallet_transactions t
    JOIN sellers s ON s.id = t.seller_id
    WHERE t.is_refunded_to_customer = 1
        AND t.refundable_amount > 0
    GROUP BY s.id, s.name, s.store_name
    ORDER BY unpaid_refunded_count DESC, refunded_txn_count DESC
    LIMIT 10
");

if (count($sellersWithRefunds) > 0) {
    foreach ($sellersWithRefunds as $seller) {
        echo sprintf("Seller #%d: %s (%s)\n", $seller->id, $seller->name, $seller->store_name);
        echo sprintf("  Total Refunded Txns: %d (Unpaid: %d, Paid: %d)\n",
            $seller->refunded_txn_count,
            $seller->unpaid_refunded_count,
            $seller->paid_refunded_count
        );
        echo sprintf("  Original Amount: ₹%.2f\n", $seller->total_original);
        echo sprintf("  Total Refunds:  -₹%.2f\n", $seller->total_refunds);
        echo "  ─────────────────────────\n";
        echo sprintf("  Net Payable:     ₹%.2f\n", $seller->total_payable);
        echo "\n";
    }
} else {
    echo "No sellers with refunded transactions found.\n\n";
}

// 2. Find sellers with UNPAID refunded transactions (for testing)
echo "\n2️⃣  SELLERS WITH UNPAID REFUNDED TRANSACTIONS (For Testing)\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

$sellersWithUnpaidRefunds = DB::select("
    SELECT
        s.id,
        s.name,
        s.store_name,
        COUNT(*) as unpaid_refunded_count,
        SUM(t.amount) as original_total,
        SUM(t.refundable_amount) as refund_total,
        SUM(t.amount - t.refundable_amount) as payable_total
    FROM seller_wallet_transactions t
    JOIN sellers s ON s.id = t.seller_id
    WHERE t.is_paid_to_seller = 0
        AND t.is_refunded_to_customer = 1
        AND t.refundable_amount > 0
    GROUP BY s.id, s.name, s.store_name
    ORDER BY unpaid_refunded_count DESC
    LIMIT 5
");

if (count($sellersWithUnpaidRefunds) > 0) {
    echo "⚠️  Found sellers with unpaid refunded transactions:\n\n";

    foreach ($sellersWithUnpaidRefunds as $seller) {
        echo sprintf("✅ Seller #%d: %s\n", $seller->id, $seller->name);
        echo sprintf("   Unpaid Refunded Txns: %d\n", $seller->unpaid_refunded_count);
        echo sprintf("   Original: ₹%.2f - Refund: ₹%.2f = Payable: ₹%.2f\n",
            $seller->original_total,
            $seller->refund_total,
            $seller->payable_total
        );
        echo "\n";

        // Show detailed transactions for this seller
        $transactions = DB::select("
            SELECT
                id, order_id, type, amount, refundable_amount,
                amount - refundable_amount as payable_amount,
                created_at, message
            FROM seller_wallet_transactions
            WHERE seller_id = ?
                AND is_paid_to_seller = 0
                AND is_refunded_to_customer = 1
                AND refundable_amount > 0
            ORDER BY created_at DESC
            LIMIT 5
        ", [$seller->id]);

        foreach ($transactions as $t) {
            echo sprintf("   • Txn #%d (Order %s): ₹%.2f - ₹%.2f = ₹%.2f\n",
                $t->id, $t->order_id, $t->amount, $t->refundable_amount, $t->payable_amount
            );
        }
        echo "\n";
    }
} else {
    echo "✅ No unpaid refunded transactions found.\n";
    echo "All refunded transactions have been paid.\n\n";
}

// 3. Total statistics
echo "\n3️⃣  OVERALL REFUND STATISTICS\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

$stats = DB::selectOne("
    SELECT
        COUNT(*) as total_refunded_txns,
        SUM(CASE WHEN is_paid_to_seller = 1 THEN 1 ELSE 0 END) as paid_refunded,
        SUM(CASE WHEN is_paid_to_seller = 0 THEN 1 ELSE 0 END) as unpaid_refunded,
        SUM(amount) as total_original,
        SUM(refundable_amount) as total_refunds,
        SUM(amount - refundable_amount) as total_net
    FROM seller_wallet_transactions
    WHERE is_refunded_to_customer = 1
        AND refundable_amount > 0
");

echo sprintf("Total Refunded Transactions: %d\n", $stats->total_refunded_txns);
echo sprintf("  - Paid: %d\n", $stats->paid_refunded);
echo sprintf("  - Unpaid: %d ⚠️\n", $stats->unpaid_refunded);
echo "\n";
echo sprintf("Original Amount: ₹%.2f\n", $stats->total_original);
echo sprintf("Total Refunds:  -₹%.2f\n", $stats->total_refunds);
echo "─────────────────────────\n";
echo sprintf("Net Amount:      ₹%.2f\n", $stats->total_net);

// 4. Edge cases check
echo "\n\n4️⃣  EDGE CASES TO TEST\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

// Full refund (amount = refund)
$fullRefunds = DB::select("
    SELECT id, seller_id, order_id, amount, refundable_amount, is_paid_to_seller
    FROM seller_wallet_transactions
    WHERE is_refunded_to_customer = 1
        AND refundable_amount > 0
        AND ABS(amount - refundable_amount) < 0.01
    LIMIT 3
");

if (count($fullRefunds) > 0) {
    echo "🔴 Full Refunds (Amount = Refund, Payable = 0):\n";
    foreach ($fullRefunds as $t) {
        echo sprintf("   Txn #%d: ₹%.2f - ₹%.2f = ₹0.00 [%s]\n",
            $t->id, $t->amount, $t->refundable_amount,
            $t->is_paid_to_seller ? 'Paid' : 'Unpaid'
        );
    }
    echo "\n";
}

// Refund > Amount (seller owes admin)
$negativePayable = DB::select("
    SELECT id, seller_id, order_id, amount, refundable_amount,
           amount - refundable_amount as payable, is_paid_to_seller
    FROM seller_wallet_transactions
    WHERE is_refunded_to_customer = 1
        AND refundable_amount > amount
    LIMIT 3
");

if (count($negativePayable) > 0) {
    echo "🟠 Refund > Commission (Negative Payable):\n";
    foreach ($negativePayable as $t) {
        echo sprintf("   Txn #%d: ₹%.2f - ₹%.2f = ₹%.2f [%s]\n",
            $t->id, $t->amount, $t->refundable_amount, $t->payable,
            $t->is_paid_to_seller ? 'Paid' : 'Unpaid'
        );
    }
    echo "\n";
}

echo "\n================================================================================\n";
echo "Analysis complete! Use the seller IDs above for testing in admin panel.\n";
echo "================================================================================\n";
