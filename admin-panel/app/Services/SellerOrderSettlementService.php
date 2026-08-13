<?php

namespace App\Services;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderComboItem;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\Seller;
use App\Models\SellerWalletTransaction;
use App\Models\Store;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SellerOrderSettlementService
{
    /**
     * Settle order amounts for all sellers involved in the order
     * Called when order is marked as delivered
     *
     * @param int $orderId
     * @return array ['success' => bool, 'message' => string, 'settlements' => array]
     */
    public static function settleOrderForSellers(int $orderId): array
    {
        $settlements = [];

        Log::info("=== SELLER ORDER SETTLEMENT START ===", [
            'order_id' => $orderId,
            'timestamp' => now()->toDateTimeString()
        ]);

        try {
            // Get all seller tracking records for this order
            $sellerTrackings = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->get();

            Log::info("Fetched seller tracking records", [
                'order_id' => $orderId,
                'tracking_count' => $sellerTrackings->count(),
                'tracking_data' => $sellerTrackings->toArray()
            ]);

            if ($sellerTrackings->isEmpty()) {
                Log::info("No seller tracking found for order", ['order_id' => $orderId]);
                return [
                    'success' => true,
                    'message' => 'No sellers to settle for this order',
                    'settlements' => []
                ];
            }

            foreach ($sellerTrackings as $tracking) {
                // Skip if seller_id is null (Zenfoo store items)
                if (empty($tracking->seller_id)) {
                    Log::info("Skipping Zenfoo store items (no seller_id)", [
                        'order_id' => $orderId,
                        'store_id' => $tracking->store_id
                    ]);
                    continue;
                }

                Log::info("Processing settlement for seller", [
                    'order_id' => $orderId,
                    'seller_id' => $tracking->seller_id,
                    'store_id' => $tracking->store_id
                ]);

                // Process settlement for this seller
                $result = self::settleForSeller($orderId, $tracking->seller_id, $tracking->store_id);

                if ($result['success']) {
                    $settlements[] = $result['data'];
                    Log::info("Settlement successful for seller", [
                        'order_id' => $orderId,
                        'seller_id' => $tracking->seller_id,
                        'settlement_data' => $result['data']
                    ]);
                } else {
                    Log::error("Failed to settle for seller", [
                        'order_id' => $orderId,
                        'seller_id' => $tracking->seller_id,
                        'error' => $result['message']
                    ]);
                }
            }

            Log::info("=== SELLER ORDER SETTLEMENT END ===", [
                'order_id' => $orderId,
                'total_settlements' => count($settlements),
                'timestamp' => now()->toDateTimeString()
            ]);

            return [
                'success' => true,
                'message' => 'Order settled successfully for ' . count($settlements) . ' seller(s)',
                'settlements' => $settlements
            ];

        } catch (\Exception $e) {
            Log::error("=== SELLER ORDER SETTLEMENT ERROR ===", [
                'order_id' => $orderId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Error settling order: ' . $e->getMessage(),
                'settlements' => $settlements
            ];
        }
    }

    /**
     * Settle an order for the sellers who had already cooked the food, when the order
     * is being cancelled instead of delivered.
     *
     * The store cooked and cannot sell the food again, so it is paid exactly as if the
     * order had been delivered — same commission, GST and payout queue. Sellers who had
     * not started preparing are skipped.
     *
     * Must be called BEFORE the order_seller_status_tracking rows are archived and
     * deleted, because the settlement reads them.
     *
     * @param int $orderId
     * @return array ['success' => bool, 'message' => string, 'settlements' => array]
     */
    public static function settleCookedSellersForCancelledOrder(int $orderId): array
    {
        $cookedStatuses = ['packed_by_seller', 'given_to_delivery_partner'];
        $settlements = [];

        try {
            $sellerTrackings = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->whereIn('status', $cookedStatuses)
                ->get();

            Log::info('Cancelled order settlement: sellers who had already cooked', [
                'order_id' => $orderId,
                'tracking_count' => $sellerTrackings->count(),
                'statuses' => $cookedStatuses,
            ]);

            foreach ($sellerTrackings as $tracking) {
                // Zenfoo's own store has no seller to pay
                if (empty($tracking->seller_id)) {
                    continue;
                }

                // settleForSeller refuses a second entry for the same order and seller,
                // so this can never pay twice.
                $result = self::settleForSeller($orderId, $tracking->seller_id, $tracking->store_id);

                if ($result['success']) {
                    $settlements[] = $result['data'];
                    Log::info('Cancelled order settlement: seller paid', [
                        'order_id'  => $orderId,
                        'seller_id' => $tracking->seller_id,
                        'status'    => $tracking->status,
                    ]);
                } else {
                    Log::error('Cancelled order settlement: seller not paid', [
                        'order_id'  => $orderId,
                        'seller_id' => $tracking->seller_id,
                        'error'     => $result['message'],
                    ]);
                }
            }

            return [
                'success' => true,
                'message' => 'Settled ' . count($settlements) . ' seller(s) for cancelled order',
                'settlements' => $settlements,
            ];
        } catch (\Exception $e) {
            Log::error('Cancelled order settlement failed', [
                'order_id' => $orderId,
                'error'    => $e->getMessage(),
            ]);

            return [
                'success' => false,
                'message' => 'Error settling cancelled order: ' . $e->getMessage(),
                'settlements' => $settlements,
            ];
        }
    }

    /**
     * Settle order amount for a specific seller
     * Processes both order_items and order_combo_items tables
     * Creates a SINGLE transaction per seller per order with products_json
     *
     * @param int $orderId
     * @param int $sellerId
     * @param int|null $storeId
     * @return array
     */
    private static function settleForSeller(int $orderId, int $sellerId, ?int $storeId = null): array
    {
        Log::info("--- settleForSeller START ---", [
            'order_id' => $orderId,
            'seller_id' => $sellerId,
            'store_id' => $storeId
        ]);

        try {
            DB::beginTransaction();

            // Get seller
            $seller = Seller::find($sellerId);

            if (!$seller) {
                DB::rollBack();
                Log::error("Seller not found", ['seller_id' => $sellerId]);
                return [
                    'success' => false,
                    'message' => 'Seller not found',
                    'data' => null
                ];
            }

            Log::info("Seller found", [
                'seller_id' => $seller->id,
                'seller_name' => $seller->name ?? $seller->store_name ?? 'Unknown',
                'commission_percent' => $seller->commission ?? 0,
                'gst_percent' => $seller->vendor_gst_percent ?? 0,
                'current_balance' => $seller->balance ?? 0
            ]);

            if (empty($storeId)) {
                DB::rollBack();
                Log::error("Store ID is required", ['seller_id' => $sellerId]);
                return [
                    'success' => false,
                    'message' => 'Store ID is required to find order items',
                    'data' => null
                ];
            }

            // Check if this order is already settled for this seller
            $existingTransaction = SellerWalletTransaction::where('order_id', $orderId)
                ->where('seller_id', $sellerId)
                ->where('type', SellerWalletTransaction::TYPE_ORDER_COMMISSION)
                ->first();

            if ($existingTransaction) {
                DB::rollBack();
                Log::info("Order already settled for this seller", [
                    'order_id' => $orderId,
                    'seller_id' => $sellerId,
                    'existing_transaction_id' => $existingTransaction->id
                ]);
                return [
                    'success' => true,
                    'message' => 'Order already settled for this seller',
                    'data' => [
                        'seller_id' => $sellerId,
                        'already_settled' => true,
                        'existing_transaction_id' => $existingTransaction->id
                    ]
                ];
            }

            // Initialize variables
            $productsJson = [];
            $totalAmount = 0;
            $totalCommission = 0;
            $totalGst = 0;
            $totalSellerAmount = 0;
            $sellerCommissionFallback = floatval($seller->commission ?? 0);
            $sellerGstPercent = floatval($seller->vendor_gst_percent ?? 0);
            $currentBalance = floatval($seller->balance ?? 0);

            // Determine vendor GST + commission from store category flags
            // (configured in Store Settings → Vendor GST / Vendor Commission
            // Configurations). Precedence: is_meat > is_food >
            // is_super_mart > is_vegetable. Falls back to the seller's
            // own per-row override when no flag matches.
            $gstPercent = self::resolveVendorGstPercent($storeId, $sellerGstPercent);
            $commissionPercent = self::resolveVendorCommissionPercent($storeId, $sellerCommissionFallback);

            // Read platform-wide fees configured in admin store settings
            $paymentGatewayFeesPercent = floatval(
                DB::table('settings')->where('variable', 'payment_gateway_fees')->value('value') ?? 0
            );

            Log::info("Starting product collection", [
                'order_id' => $orderId,
                'store_id' => $storeId,
                'commission_percent' => $commissionPercent,
                'seller_gst_percent' => $sellerGstPercent,
                'gst_percent' => $gstPercent
            ]);

            // ========================================
            // 1. Process ORDER_ITEMS table
            // ========================================
            $orderItemsResult = self::processOrderItems($orderId, $storeId, $commissionPercent, $gstPercent);

            if (!empty($orderItemsResult['products'])) {
                $productsJson = array_merge($productsJson, $orderItemsResult['products']);
                $totalAmount += $orderItemsResult['total_amount'];
                $totalCommission += $orderItemsResult['total_commission'];
                $totalGst += $orderItemsResult['total_gst'];
                $totalSellerAmount += $orderItemsResult['total_seller_amount'];
            }

            Log::info("Order items processed", [
                'order_id' => $orderId,
                'products_count' => count($orderItemsResult['products']),
                'total_amount' => $orderItemsResult['total_amount'],
                'total_commission' => $orderItemsResult['total_commission'],
                'total_gst' => $orderItemsResult['total_gst'],
                'total_seller_amount' => $orderItemsResult['total_seller_amount']
            ]);

            // ========================================
            // 2. Process ORDER_COMBO_ITEMS table
            // ========================================
            $comboItemsResult = self::processComboItems($orderId, $storeId, $commissionPercent, $gstPercent);

            if (!empty($comboItemsResult['products'])) {
                $productsJson = array_merge($productsJson, $comboItemsResult['products']);
                $totalAmount += $comboItemsResult['total_amount'];
                $totalCommission += $comboItemsResult['total_commission'];
                $totalGst += $comboItemsResult['total_gst'];
                $totalSellerAmount += $comboItemsResult['total_seller_amount'];
            }

            Log::info("Combo items processed", [
                'order_id' => $orderId,
                'products_count' => count($comboItemsResult['products']),
                'total_amount' => $comboItemsResult['total_amount'],
                'total_commission' => $comboItemsResult['total_commission'],
                'total_gst' => $comboItemsResult['total_gst'],
                'total_seller_amount' => $comboItemsResult['total_seller_amount']
            ]);

            // ========================================
            // 3. Check if we have any products to settle
            // ========================================
            if (empty($productsJson)) {
                DB::rollBack();
                Log::warning("No products found for this seller in this order", [
                    'order_id' => $orderId,
                    'seller_id' => $sellerId,
                    'store_id' => $storeId
                ]);
                return [
                    'success' => false,
                    'message' => 'No products found for this seller in this order',
                    'data' => null
                ];
            }

            // ========================================
            // 4. Create SINGLE transaction for this order
            // ========================================
            // Payment gateway fees are calculated on the gross order amount for this seller
            $totalPaymentGatewayFees = round(($totalAmount * $paymentGatewayFeesPercent) / 100, 2);
            $totalSellerAmount = $totalSellerAmount - $totalPaymentGatewayFees;

            // Vendor waiting charge: deducted from this seller's payout for this order
            // (and paid out to the driver via the delivery_boy_transaction). Stored on
            // order_seller_status_tracking by markAsDriverPicked. Zenfoo rows have
            // seller_id = null so they never reach this code path.
            $vendorWaitCharge = (float) (DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->where('seller_id', $sellerId)
                ->where('store_id', $storeId)
                ->value('vendor_wait_charge') ?? 0);

            $totalSellerAmount = $totalSellerAmount - $vendorWaitCharge;

            $balanceBefore = $currentBalance;
            $balanceAfter = $balanceBefore + $totalSellerAmount;

            // Generate item names summary for the item_name field
            $itemNames = array_map(function($p) {
                return $p['product_name'] . ' (x' . $p['quantity'] . ')';
            }, $productsJson);
            $itemNameSummary = implode(', ', array_slice($itemNames, 0, 3));
            if (count($itemNames) > 3) {
                $itemNameSummary .= ' +' . (count($itemNames) - 3) . ' more';
            }

            Log::info("Creating wallet transaction", [
                'order_id' => $orderId,
                'seller_id' => $seller->id,
                'total_products' => count($productsJson),
                'total_amount' => $totalAmount,
                'total_commission' => $totalCommission,
                'total_gst' => $totalGst,
                'payment_gateway_fees_percent' => $paymentGatewayFeesPercent,
                'total_payment_gateway_fees' => $totalPaymentGatewayFees,
                'vendor_wait_charge' => $vendorWaitCharge,
                'total_seller_amount' => $totalSellerAmount,
                'balance_before' => $balanceBefore,
                'balance_after' => $balanceAfter,
                'item_name_summary' => $itemNameSummary
            ]);

            $transaction = SellerWalletTransaction::create([
                'seller_id' => $seller->id,
                'order_id' => $orderId,
                'order_item_id' => null, // No longer tracking individual items
                'item_name' => $itemNameSummary,
                'products_json' => $productsJson,
                'type' => SellerWalletTransaction::TYPE_ORDER_COMMISSION,
                'amount' => $totalSellerAmount,
                'admin_commission' => $totalCommission,
                'gst_percentage' => $gstPercent,
                'payment_gateway_fees' => $totalPaymentGatewayFees,
                'vendor_wait_charge' => $vendorWaitCharge,
                'balance_before' => $balanceBefore,
                'balance_after' => $balanceAfter,
                'reference_type' => SellerWalletTransaction::REF_ORDER,
                'reference_id' => $orderId,
                'message' => "Order #" . $orderId . " - " . count($productsJson) . " product(s)"
                    . ($vendorWaitCharge > 0 ? sprintf(' | Waiting charge deducted: ₹%.2f', $vendorWaitCharge) : ''),
                'status' => 1,
                'is_paid_to_seller' => false,
            ]);

            Log::info("Wallet transaction created", [
                'transaction_id' => $transaction->id,
                'order_id' => $orderId,
                'seller_id' => $seller->id
            ]);

            // ========================================
            // 5. Update seller balance
            // ========================================
            $seller->balance = $balanceAfter;
            $seller->save();

            Log::info("Seller balance updated", [
                'seller_id' => $seller->id,
                'old_balance' => $balanceBefore,
                'new_balance' => $balanceAfter,
                'amount_added' => $totalSellerAmount
            ]);

            DB::commit();

            Log::info("--- settleForSeller SUCCESS ---", [
                'order_id' => $orderId,
                'seller_id' => $sellerId,
                'transaction_id' => $transaction->id,
                'total_products' => count($productsJson),
                'total_amount' => $totalAmount,
                'commission_percent' => $commissionPercent,
                'total_commission' => $totalCommission,
                'gst_percent' => $gstPercent,
                'total_gst' => $totalGst,
                'total_seller_amount' => $totalSellerAmount,
                'balance_after' => $balanceAfter
            ]);

            return [
                'success' => true,
                'message' => 'Settlement successful',
                'data' => [
                    'seller_id' => $sellerId,
                    'store_id' => $storeId,
                    'seller_name' => $seller->name ?? $seller->store_name ?? 'Unknown',
                    'order_id' => $orderId,
                    'transaction_id' => $transaction->id,
                    'total_products' => count($productsJson),
                    'total_amount' => $totalAmount,
                    'commission_percent' => $commissionPercent,
                    'total_commission' => $totalCommission,
                    'gst_percent' => $gstPercent,
                    'total_gst' => $totalGst,
                    'payment_gateway_fees_percent' => $paymentGatewayFeesPercent,
                    'total_payment_gateway_fees' => $totalPaymentGatewayFees,
                    'vendor_wait_charge' => $vendorWaitCharge,
                    'total_seller_amount' => $totalSellerAmount,
                    'balance_before' => $balanceBefore,
                    'balance_after' => $balanceAfter,
                    'products' => $productsJson
                ]
            ];

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("--- settleForSeller ERROR ---", [
                'order_id' => $orderId,
                'seller_id' => $sellerId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => $e->getMessage(),
                'data' => null
            ];
        }
    }

    /**
     * Resolve vendor GST percent for a store based on its category flags.
     * Precedence: is_meat > is_food > is_super_mart > is_vegetable. Falls back to the seller's own GST when no flag is set.
     */
    private static function resolveVendorGstPercent(int $storeId, float $fallback): float
    {
        $store = Store::find($storeId);
        if (!$store) {
            return $fallback;
        }

        $variable = null;
        if (!empty($store->is_meat)) {
            $variable = 'vendor_gst_chicken_meat';
        } elseif (!empty($store->is_food)) {
            $variable = 'vendor_gst_food';
        } elseif (!empty($store->is_super_mart)) {
            $variable = 'vendor_gst_super_mart';
        } elseif (!empty($store->is_vegetable)) {
            $variable = 'vendor_gst_vegetables_fruits';
        }

        if (!$variable) {
            return $fallback;
        }

        $value = DB::table('settings')->where('variable', $variable)->value('value');
        if ($value === null || $value === '') {
            return $fallback;
        }

        return floatval($value);
    }

    /**
     * Resolve vendor commission percent for a store based on its
     * category flags. Same precedence as resolveVendorGstPercent. Falls
     * back to the seller's own per-row commission when no flag is set
     * or no setting is configured.
     */
    private static function resolveVendorCommissionPercent(int $storeId, float $fallback): float
    {
        $store = Store::find($storeId);
        if (!$store) {
            return $fallback;
        }

        $variable = null;
        if (!empty($store->is_meat)) {
            $variable = 'vendor_commission_chicken_meat';
        } elseif (!empty($store->is_food)) {
            $variable = 'vendor_commission_food';
        } elseif (!empty($store->is_super_mart)) {
            $variable = 'vendor_commission_super_mart';
        } elseif (!empty($store->is_vegetable)) {
            $variable = 'vendor_commission_vegetables_fruits';
        }

        if (!$variable) {
            return $fallback;
        }

        $value = DB::table('settings')->where('variable', $variable)->value('value');
        if ($value === null || $value === '') {
            return $fallback;
        }

        return floatval($value);
    }

    /**
     * Process order_items table and collect products for this seller's store
     *
     * @param int $orderId
     * @param int $storeId
     * @param float $commissionPercent
     * @param float $gstPercent
     * @return array
     */
    private static function processOrderItems(int $orderId, int $storeId, float $commissionPercent, float $gstPercent): array
    {
        Log::info("Processing order_items", [
            'order_id' => $orderId,
            'store_id' => $storeId,
            'commission_percent' => $commissionPercent,
            'gst_percent' => $gstPercent
        ]);

        $products = [];
        $totalAmount = 0;
        $totalCommission = 0;
        $totalGst = 0;
        $totalSellerAmount = 0;

        // Get order items for this store
        // order_items -> product_variant_id -> product_variants -> product_id -> products -> store_id
        $orderItems = OrderItem::where('order_id', $orderId)
            ->whereHas('productVariant.product', function ($query) use ($storeId) {
                $query->where('store_id', $storeId);
            })
            ->get();

        Log::info("Found order items", [
            'order_id' => $orderId,
            'store_id' => $storeId,
            'count' => $orderItems->count()
        ]);

        foreach ($orderItems as $item) {
            // Get product details
            $productVariant = ProductVariant::find($item->product_variant_id);
            $product = $productVariant ? Product::find($productVariant->product_id) : null;

            $quantity = floatval($item->quantity);
            $unitPrice = floatval($item->discounted_price); // Use discounted_price for order_items
            $itemTotal = $quantity * $unitPrice;
            $itemCommission = ($itemTotal * $commissionPercent) / 100;
            $itemGst = ($itemTotal * $gstPercent) / 100;
            $itemSellerAmount = $itemTotal - $itemCommission - $itemGst;

            Log::debug("Processing order item", [
                'order_item_id' => $item->id,
                'product_id' => $product ? $product->id : null,
                'product_name' => $item->product_name,
                'quantity' => $quantity,
                'unit_price' => $unitPrice,
                'item_total' => $itemTotal,
                'commission' => $itemCommission,
                'gst' => $itemGst,
                'seller_amount' => $itemSellerAmount
            ]);

            $products[] = [
                'product_id' => $product ? $product->id : null,
                'product_variant_id' => $item->product_variant_id,
                'product_name' => $item->product_name,
                'quantity' => $quantity,
                'amount' => $unitPrice,
                'total_amount' => $itemTotal,
                'commission' => $itemCommission,
                'gst' => $itemGst,
                'seller_amount' => $itemSellerAmount,
                'source' => 'order_item',
                'order_item_id' => $item->id
            ];

            $totalAmount += $itemTotal;
            $totalCommission += $itemCommission;
            $totalGst += $itemGst;
            $totalSellerAmount += $itemSellerAmount;
        }

        Log::info("Order items processing complete", [
            'order_id' => $orderId,
            'products_count' => count($products),
            'total_amount' => $totalAmount,
            'total_commission' => $totalCommission,
            'total_gst' => $totalGst,
            'total_seller_amount' => $totalSellerAmount
        ]);

        return [
            'products' => $products,
            'total_amount' => $totalAmount,
            'total_commission' => $totalCommission,
            'total_gst' => $totalGst,
            'total_seller_amount' => $totalSellerAmount
        ];
    }

    /**
     * Process order_combo_items table and collect products for this seller's store
     *
     * @param int $orderId
     * @param int $storeId
     * @param float $commissionPercent
     * @param float $gstPercent
     * @return array
     */
    private static function processComboItems(int $orderId, int $storeId, float $commissionPercent, float $gstPercent): array
    {
        Log::info("Processing order_combo_items", [
            'order_id' => $orderId,
            'store_id' => $storeId,
            'commission_percent' => $commissionPercent,
            'gst_percent' => $gstPercent
        ]);

        $products = [];
        $totalAmount = 0;
        $totalCommission = 0;
        $totalGst = 0;
        $totalSellerAmount = 0;

        // Get all combo items for this order
        $comboItems = OrderComboItem::where('order_id', $orderId)->get();

        Log::info("Found combo items", [
            'order_id' => $orderId,
            'combo_items_count' => $comboItems->count()
        ]);

        foreach ($comboItems as $comboItem) {
            // Parse the products JSON
            $comboProducts = $comboItem->products;

            if (empty($comboProducts) || !is_array($comboProducts)) {
                Log::warning("Combo item has no products or invalid format", [
                    'combo_item_id' => $comboItem->id,
                    'order_id' => $orderId
                ]);
                continue;
            }

            Log::debug("Processing combo item", [
                'combo_item_id' => $comboItem->id,
                'combo_name' => $comboItem->combo_name,
                'products_count' => count($comboProducts)
            ]);

            // Process each product in the combo
            foreach ($comboProducts as $comboProduct) {
                $productId = $comboProduct['product_id'] ?? null;

                if (empty($productId)) {
                    Log::warning("Combo product has no product_id", [
                        'combo_item_id' => $comboItem->id,
                        'combo_product' => $comboProduct
                    ]);
                    continue;
                }

                // Check if this product belongs to the seller's store
                $product = Product::find($productId);

                if (!$product) {
                    Log::warning("Product not found", [
                        'product_id' => $productId,
                        'combo_item_id' => $comboItem->id
                    ]);
                    continue;
                }

                // Check if product belongs to this store
                if ($product->store_id != $storeId) {
                    Log::debug("Product does not belong to this store, skipping", [
                        'product_id' => $productId,
                        'product_store_id' => $product->store_id,
                        'expected_store_id' => $storeId
                    ]);
                    continue;
                }

                $quantity = floatval($comboProduct['quantity'] ?? 1);
                $unitPrice = floatval($comboProduct['price'] ?? 0); // Use price from combo JSON
                $itemTotal = $quantity * $unitPrice;
                $itemCommission = ($itemTotal * $commissionPercent) / 100;
                $itemGst = ($itemTotal * $gstPercent) / 100;
                $itemSellerAmount = $itemTotal - $itemCommission - $itemGst;

                Log::debug("Processing combo product (belongs to seller)", [
                    'product_id' => $productId,
                    'product_name' => $comboProduct['product_name'] ?? $product->name,
                    'quantity' => $quantity,
                    'unit_price' => $unitPrice,
                    'item_total' => $itemTotal,
                    'commission' => $itemCommission,
                    'gst' => $itemGst,
                    'seller_amount' => $itemSellerAmount
                ]);

                $products[] = [
                    'product_id' => $productId,
                    'product_variant_id' => $comboProduct['variant_id'] ?? null,
                    'product_name' => $comboProduct['product_name'] ?? $product->name,
                    'quantity' => $quantity,
                    'amount' => $unitPrice,
                    'total_amount' => $itemTotal,
                    'commission' => $itemCommission,
                    'gst' => $itemGst,
                    'seller_amount' => $itemSellerAmount,
                    'source' => 'combo_item',
                    'combo_item_id' => $comboItem->id,
                    'combo_name' => $comboItem->combo_name
                ];

                $totalAmount += $itemTotal;
                $totalCommission += $itemCommission;
                $totalGst += $itemGst;
                $totalSellerAmount += $itemSellerAmount;
            }
        }

        Log::info("Combo items processing complete", [
            'order_id' => $orderId,
            'products_count' => count($products),
            'total_amount' => $totalAmount,
            'total_commission' => $totalCommission,
            'total_gst' => $totalGst,
            'total_seller_amount' => $totalSellerAmount
        ]);

        return [
            'products' => $products,
            'total_amount' => $totalAmount,
            'total_commission' => $totalCommission,
            'total_gst' => $totalGst,
            'total_seller_amount' => $totalSellerAmount
        ];
    }
}
