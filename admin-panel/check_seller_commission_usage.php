<?php

require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "================================================================================\n";
echo "SELLER COMMISSION COLUMN USAGE ANALYSIS\n";
echo "================================================================================\n\n";

// Get sellers with commission set
$sellers = DB::select("
    SELECT id, name, store_name, commission
    FROM sellers
    WHERE commission IS NOT NULL AND commission > 0
    ORDER BY id
    LIMIT 10
");

echo "1️⃣  SELLERS WITH COMMISSION SET\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

foreach ($sellers as $s) {
    echo sprintf("Seller #%d: %s | Commission: %.2f%%\n",
        $s->id,
        $s->store_name ?: $s->name,
        $s->commission
    );
}

// Get statistics
$stats = DB::selectOne("
    SELECT
        COUNT(*) as total_sellers,
        COUNT(CASE WHEN commission IS NOT NULL AND commission > 0 THEN 1 END) as with_commission,
        COUNT(CASE WHEN commission IS NULL OR commission = 0 THEN 1 END) as without_commission,
        AVG(CASE WHEN commission > 0 THEN commission END) as avg_commission,
        MIN(CASE WHEN commission > 0 THEN commission END) as min_commission,
        MAX(commission) as max_commission
    FROM sellers
");

echo "\n\n2️⃣  COMMISSION STATISTICS\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

echo sprintf("Total Sellers: %d\n", $stats->total_sellers);
echo sprintf("With Commission: %d\n", $stats->with_commission);
echo sprintf("Without Commission (0 or NULL): %d\n", $stats->without_commission);
echo sprintf("Average Commission: %.2f%%\n", $stats->avg_commission ?: 0);
echo sprintf("Min Commission: %.2f%%\n", $stats->min_commission ?: 0);
echo sprintf("Max Commission: %.2f%%\n", $stats->max_commission ?: 0);

// Get sample transactions showing commission calculation
$sampleTransactions = DB::select("
    SELECT
        t.id,
        t.order_id,
        t.seller_id,
        s.name as seller_name,
        s.store_name,
        s.commission as seller_commission_percent,
        t.amount as seller_earnings,
        t.admin_commission,
        t.created_at
    FROM seller_wallet_transactions t
    JOIN sellers s ON s.id = t.seller_id
    WHERE t.type = 'order_commission'
        AND t.admin_commission > 0
        AND s.commission > 0
    ORDER BY t.created_at DESC
    LIMIT 5
");

echo "\n\n3️⃣  SAMPLE TRANSACTIONS SHOWING COMMISSION CALCULATION\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

foreach ($sampleTransactions as $t) {
    $totalOrderValue = $t->seller_earnings + $t->admin_commission;
    $calculatedCommission = ($totalOrderValue * $t->seller_commission_percent) / 100;
    $match = abs($calculatedCommission - $t->admin_commission) < 0.01 ? '✅' : '❌';

    echo sprintf("Transaction #%d (Order %s) | Seller: %s\n",
        $t->id, $t->order_id, $t->store_name ?: $t->seller_name
    );
    echo sprintf("  Commission Rate: %.2f%%\n", $t->seller_commission_percent);
    echo sprintf("  Order Value: ₹%.2f (Seller: ₹%.2f + Admin: ₹%.2f)\n",
        $totalOrderValue, $t->seller_earnings, $t->admin_commission
    );
    echo sprintf("  Expected Commission: ₹%.2f | Actual: ₹%.2f %s\n",
        $calculatedCommission, $t->admin_commission, $match
    );
    echo sprintf("  Date: %s\n\n", substr($t->created_at, 0, 10));
}

echo "\n\n4️⃣  HOW COMMISSION IS USED\n";
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";

echo "📍 Location: app/Services/SellerOrderSettlementService.php\n\n";

echo "When an order is delivered:\n";
echo "  1. System reads seller's commission percentage from sellers.commission column\n";
echo "  2. For each product in the order:\n";
echo "     - Item Total = Quantity × Price\n";
echo "     - Admin Commission = (Item Total × Commission %) / 100\n";
echo "     - Seller Amount = Item Total - Admin Commission\n";
echo "  3. Creates transaction in seller_wallet_transactions:\n";
echo "     - amount: Seller's earnings (Item Total - Commission)\n";
echo "     - admin_commission: Admin's share (Commission amount)\n";
echo "     - type: 'order_commission'\n\n";

echo "📍 Set During Registration:\n";
echo "  - Location: app/Http/Controllers/SellerRegistrationController.php\n";
echo "  - Admin sets commission % when approving seller registration\n";
echo "  - Can be updated later via seller profile update API\n\n";

echo "📍 Example Calculation:\n";
echo "  If Order Total = ₹1000 and Seller Commission = 10%:\n";
echo "    - Admin Commission = ₹100 (10% of ₹1000)\n";
echo "    - Seller Earnings = ₹900 (₹1000 - ₹100)\n\n";

echo "================================================================================\n";
echo "SUMMARY\n";
echo "================================================================================\n\n";

echo "The 'commission' column in the sellers table stores the PERCENTAGE that\n";
echo "the admin deducts from each order. This is seller-specific and can vary.\n\n";

echo "✅ Used in: Order settlement calculations\n";
echo "✅ Set by: Admin during seller registration/approval\n";
echo "✅ Updated: Via seller profile update API\n";
echo "✅ Range: 0-100 (percentage)\n\n";

echo "================================================================================\n";
