<?php

require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

$sellerId = 32; // CinnaMan's Café

echo "================================================================================\n";
echo "SELLER #32 - OLD LOGIC CALCULATION (Before Refund Deduction Feature)\n";
echo "================================================================================\n\n";

// Get seller info
$seller = DB::selectOne("SELECT id, name, store_name, balance FROM sellers WHERE id = ?", [$sellerId]);

if (!$seller) {
    echo "Seller not found!\n";
    exit(1);
}

echo sprintf("Seller: %s (%s)\n", $seller->name, $seller->store_name);
echo sprintf("Current Wallet Balance: ₹%.2f\n\n", $seller->balance ?? 0);

// Get ALL unpaid transactions (same as API does)
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
echo "OLD LOGIC (Just sum amounts - NO refund deduction)\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

// Define credit types (types that increase seller earnings - same as API)
$creditTypes = ['order_commission', 'credit', 'refund', 'order_item'];

$allTransactions = 0;
$creditTransactions = 0;
$debitTransactions = 0;

$totalAll = 0;
$totalCredit = 0;
$totalDebit = 0;

echo "All Unpaid Transactions:\n\n";

foreach ($unpaidTransactions as $t) {
    $amount = (float) $t->amount;
    $allTransactions++;
    $totalAll += $amount;

    $isCredit = in_array($t->type, $creditTypes);

    if ($isCredit) {
        $creditTransactions++;
        $totalCredit += $amount;
        $mark = "✅ CREDIT";
    } else {
        $debitTransactions++;
        $totalDebit += $amount;
        $mark = "❌ DEBIT";
    }

    echo sprintf("  #%d | %s | %-20s | ₹%8.2f | %s\n",
        $t->id,
        substr($t->created_at, 0, 10),
        $t->type,
        $amount,
        $mark
    );

    if ($t->is_refunded_to_customer && $t->refundable_amount > 0) {
        echo sprintf("       ⚠️  Has refund: ₹%.2f (but OLD logic ignores this)\n", $t->refundable_amount);
    }
}

echo "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "SUMMARY\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

echo "All Transactions:\n";
echo sprintf("  Count: %d\n", $allTransactions);
echo sprintf("  Total: ₹%.2f\n\n", $totalAll);

echo "Credit Transactions (commission, delivery_charge, tip):\n";
echo sprintf("  Count: %d\n", $creditTransactions);
echo sprintf("  Total: ₹%.2f ← This is what OLD API would show\n\n", $totalCredit);

echo "Debit Transactions (other types):\n";
echo sprintf("  Count: %d\n", $debitTransactions);
echo sprintf("  Total: ₹%.2f\n\n", $totalDebit);

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
echo "COMPARISON\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

echo sprintf("OLD Logic (sum of credit amounts):          ₹%.2f\n", $totalCredit);
echo sprintf("NEW Logic (with refund deduction):         ₹17,346.60\n");
echo sprintf("Seller App Currently Shows:                11,000+\n\n");

if (abs($totalCredit - 17346.60) < 1) {
    echo "✅ OLD and NEW logic match (no refunds on unpaid transactions)\n";
} else {
    echo sprintf("⚠️  Difference: ₹%.2f\n", abs($totalCredit - 17346.60));
}

if ($totalCredit > 11000 && $totalCredit < 18000) {
    if (abs($totalCredit - 11000) < 7000) {
        echo "\n⚠️  Seller app showing ~₹11,000 but calculation shows ₹" . number_format($totalCredit, 2) . "\n";
        echo "Possible reasons:\n";
        echo "  1. Seller app may be filtering by date range (weekly/monthly)\n";
        echo "  2. Seller app may be using different transaction type filters\n";
        echo "  3. There might be some paid transactions not marked correctly\n";
        echo "  4. Cache issue in seller app\n";
    }
}

echo "\n================================================================================\n";
echo "Run this to compare with seller app:\n";
echo "  OLD API endpoint: {{dev_url}}/api/seller/my-transactions?type=unpaid\n";
echo "  Check the 'total_pending' or similar field in the response\n";
echo "================================================================================\n";
