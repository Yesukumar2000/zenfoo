<?php

namespace App\Http\Controllers\API\Admin;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\City;
use App\Models\Order;
use App\Models\PromoCode;
use App\Models\SellerWalletTransaction;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx as XlsxWriter;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use Mpdf\Mpdf;
use Mpdf\Output\Destination;

class OrderAnalyticsController extends Controller
{
    /**
     * Get order analytics data with date filters.
     */
    public function getAnalytics(Request $request)
    {
        $filter = $request->get('filter', 'daily'); // daily, weekly, monthly, custom
        $startDate = $request->get('start_date');
        $endDate = $request->get('end_date');
        $customFilter = $request->get('custom_filter'); // pre_order filter
        $storeId = $request->get('store_id'); // store filter
        $sellerId = $request->get('seller_id'); // seller filter

        // Determine date range
        switch ($filter) {
            case 'daily':
                $start = Carbon::today();
                $end = Carbon::today()->endOfDay();
                break;
            case 'weekly':
                $start = Carbon::now()->startOfWeek();
                $end = Carbon::now()->endOfWeek();
                break;
            case 'monthly':
                $start = Carbon::now()->startOfMonth();
                $end = Carbon::now()->endOfMonth();
                break;
            case 'custom':
                $start = $startDate ? Carbon::parse($startDate)->startOfDay() : Carbon::now()->subDays(30)->startOfDay();
                $end = $endDate ? Carbon::parse($endDate)->endOfDay() : Carbon::now()->endOfDay();
                break;
            default:
                $start = Carbon::today();
                $end = Carbon::today()->endOfDay();
        }

        $cityId = $request->get('city_id');

        // Summary cards
        $summary = $this->getSummaryCards($start, $end, $cityId, $customFilter, $storeId, $sellerId);

        // Orders over time (for line/bar chart)
        $ordersOverTime = $this->getOrdersOverTime($start, $end, $filter, $cityId, $customFilter, $storeId, $sellerId);

        // Status breakdown (for pie/donut chart)
        $statusBreakdown = $this->getStatusBreakdown($start, $end, $cityId, $customFilter, $storeId, $sellerId);

        // Payment method split (for pie chart)
        $paymentMethodSplit = $this->getPaymentMethodSplit($start, $end, $cityId, $customFilter, $storeId, $sellerId);

        // Revenue breakdown from cart_metadata (for stacked bar/donut)
        $revenueBreakdown = $this->getRevenueBreakdown($start, $end, $cityId, $customFilter, $storeId, $sellerId);

        // Delivery & tips trend
        $deliveryTrend = $this->getDeliveryTrend($start, $end, $filter, $cityId, $customFilter, $storeId, $sellerId);

        // Order type split (doorstep vs selfpickup, preorder vs regular)
        $orderTypeSplit = $this->getOrderTypeSplit($start, $end, $cityId, $customFilter, $storeId, $sellerId);

        // Orders by Type (Restaurant/Grocery/Combo/Uncategorized) — one order, one category
        $ordersByType = $this->getOrdersByType($start, $end, $cityId, $customFilter, $storeId, $sellerId);

        // Top cities by order count
        $topCities = $this->getTopCities($start, $end, $cityId, $customFilter, $storeId, $sellerId);

        // Order Type Performance matrix (per category outcome stats)
        $orderTypePerformance = $this->getOrderTypePerformance($start, $end, $cityId, $customFilter, $storeId, $sellerId);

        // Orders by Day of Week + Time of Day heatmap
        $ordersByTime = $this->getOrdersByTime($start, $end, $cityId, $customFilter, $storeId, $sellerId);

        // Top cancellation reasons (grouped from order_items.cancellation_reason)
        $topCancellationReasons = $this->getTopCancellationReasons($start, $end, $cityId, $customFilter, $storeId, $sellerId);

        // Combo performance (combo-only economics, independent of loose items)
        $comboPerformance = $this->getComboPerformance($start, $end, $cityId, $customFilter, $storeId, $sellerId);

        // Coupon/Promo analytics
        $couponAnalytics = $this->getCouponAnalytics($start, $end, $cityId, $customFilter, $storeId, $sellerId);

        // Profit/Loss comparison vs previous period
        $profitLossComparison = $this->getProfitLossComparison($start, $end, $filter, $cityId, $customFilter, $storeId, $sellerId);

        // Platform profit analysis (commission income minus platform-funded promo).
        // Reuses the promo totals already computed in the comparison above.
        $profitAnalysis = $this->getProfitAnalysis($start, $end, $filter, $cityId, $customFilter, $storeId, $sellerId, $profitLossComparison);

        $data = [
            'filter' => $filter,
            'start_date' => $start->toDateString(),
            'end_date' => $end->toDateString(),
            'custom_filter' => $customFilter,
            'store_id' => $storeId,
            'seller_id' => $sellerId,
            'profit_loss_comparison' => $profitLossComparison,
            'profit_analysis' => $profitAnalysis,
            'summary' => $summary,
            'orders_over_time' => $ordersOverTime,
            'status_breakdown' => $statusBreakdown,
            'payment_method_split' => $paymentMethodSplit,
            'revenue_breakdown' => $revenueBreakdown,
            'delivery_trend' => $deliveryTrend,
            'order_type_split' => $orderTypeSplit,
            'orders_by_type' => $ordersByType,
            'top_cities' => $topCities,
            'order_type_performance' => $orderTypePerformance,
            'orders_by_time' => $ordersByTime,
            'top_cancellation_reasons' => $topCancellationReasons,
            'combo_performance' => $comboPerformance,
            'coupon_analytics' => $couponAnalytics,
        ];

        return CommonHelper::responseWithData($data);
    }

    /**
     * Summary cards: total orders, revenue, avg order value, total savings, etc.
     */
    private function getSummaryCards(Carbon $start, Carbon $end, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        $query = Order::whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($query, $cityId);
        $this->applyCustomFilter($query, $customFilter);
        $this->applyStoreSellerFilter($query, $storeId, $sellerId);
        $orders = $query->get();

        $totalOrders = $orders->count();
        $totalRevenue = 0;
        $totalMRP = 0;
        $totalSavings = 0;
        $totalDeliveryCharge = 0;
        $totalDeliveryTips = 0;
        $totalPromoDiscount = 0;
        $totalWalletUsed = 0;

        foreach ($orders as $order) {
            $meta = $order->cart_metadata;
            if ($meta && isset($meta['billing_summary'])) {
                $bs = $meta['billing_summary'];
                $totalRevenue += floatval($bs['to_be_paid'] ?? 0);
                $totalMRP += floatval($bs['items_mrp'] ?? 0) + floatval($bs['combo_mrp'] ?? 0);
                $totalSavings += floatval($bs['total_savings'] ?? 0);
                $totalDeliveryCharge += floatval($bs['delivery_charge'] ?? 0);
                $totalDeliveryTips += floatval($bs['delivery_tip'] ?? 0);
                $totalPromoDiscount += floatval($bs['promocode_discount'] ?? 0);
                $totalWalletUsed += floatval($bs['wallet_deduction'] ?? 0);
            } else {
                // Fallback to order columns if cart_metadata is missing
                $totalRevenue += floatval($order->final_total ?? 0);
                $totalMRP += floatval($order->total ?? 0);
                $totalDeliveryCharge += floatval($order->delivery_charge ?? 0);
                $totalPromoDiscount += floatval($order->promo_discount ?? 0);
                $totalWalletUsed += floatval($order->wallet_balance ?? 0);
            }
        }

        $avgOrderValue = $totalOrders > 0 ? round($totalRevenue / $totalOrders, 2) : 0;

        return [
            'total_orders' => $totalOrders,
            'total_revenue' => round($totalRevenue, 2),
            'avg_order_value' => $avgOrderValue,
            'total_mrp' => round($totalMRP, 2),
            'total_savings' => round($totalSavings, 2),
            'total_delivery_charge' => round($totalDeliveryCharge, 2),
            'total_delivery_tips' => round($totalDeliveryTips, 2),
            'total_promo_discount' => round($totalPromoDiscount, 2),
            'total_wallet_used' => round($totalWalletUsed, 2),
        ];
    }

    /**
     * Orders count + revenue over time for line/bar chart.
     */
    private function getOrdersOverTime(Carbon $start, Carbon $end, string $filter, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        $groupFormat = $this->getDateGroupFormat($filter, $start, $end);

        $query = Order::select(
                DB::raw("{$groupFormat['select']} as date_label"),
                DB::raw('COUNT(*) as order_count'),
                DB::raw('COALESCE(SUM(orders.final_total), 0) as revenue')
            )
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($query, $cityId);
        $this->applyCustomFilter($query, $customFilter);
        $this->applyStoreSellerFilter($query, $storeId, $sellerId);
        $orders = $query->groupBy('date_label')
            ->orderBy('date_label')
            ->get();

        // Also extract cart_metadata revenue per group
        $rawQuery = Order::select('orders.created_at', 'orders.cart_metadata', 'orders.final_total', 'orders.active_status')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($rawQuery, $cityId);
        $this->applyCustomFilter($rawQuery, $customFilter);
        $this->applyStoreSellerFilter($rawQuery, $storeId, $sellerId);
        $rawOrders = $rawQuery->get();

        $grouped = [];
        foreach ($rawOrders as $order) {
            $key = $this->getDateKey($order->created_at, $filter, $start, $end);
            if (!isset($grouped[$key])) {
                $grouped[$key] = ['order_count' => 0, 'completed' => 0, 'cancelled' => 0, 'revenue' => 0, 'mrp' => 0, 'savings' => 0];
            }
            $grouped[$key]['order_count']++;
            // active_status: 6 = Delivered (Completed), 7 = Cancelled
            if ((int) $order->active_status === 6) {
                $grouped[$key]['completed']++;
            } elseif ((int) $order->active_status === 7) {
                $grouped[$key]['cancelled']++;
            }

            $meta = $order->cart_metadata;
            if ($meta && isset($meta['billing_summary'])) {
                $bs = $meta['billing_summary'];
                $grouped[$key]['revenue'] += floatval($bs['to_be_paid'] ?? 0);
                $grouped[$key]['mrp'] += floatval($bs['items_mrp'] ?? 0) + floatval($bs['combo_mrp'] ?? 0);
                $grouped[$key]['savings'] += floatval($bs['total_savings'] ?? 0);
            } else {
                $grouped[$key]['revenue'] += floatval($order->final_total ?? 0);
            }
        }

        // Sort by key
        ksort($grouped);

        $labels = [];
        $orderCounts = [];
        $completedCounts = [];
        $cancelledCounts = [];
        $revenues = [];
        $mrps = [];
        $savings = [];

        foreach ($grouped as $key => $data) {
            $labels[] = $key;
            $orderCounts[] = $data['order_count'];
            $completedCounts[] = $data['completed'];
            $cancelledCounts[] = $data['cancelled'];
            $revenues[] = round($data['revenue'], 2);
            $mrps[] = round($data['mrp'], 2);
            $savings[] = round($data['savings'], 2);
        }

        return [
            'labels' => $labels,
            'order_counts' => $orderCounts,
            'completed_counts' => $completedCounts,
            'cancelled_counts' => $cancelledCounts,
            'revenues' => $revenues,
            'mrps' => $mrps,
            'savings' => $savings,
        ];
    }

    /**
     * Order status breakdown for donut chart.
     */
    private function getStatusBreakdown(Carbon $start, Carbon $end, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        $statusMap = [
            2 => 'Received',
            3 => 'Processed',
            5 => 'Out for Delivery',
            6 => 'Delivered',
            7 => 'Cancelled',
            8 => 'Returned',
            12 => 'Pre-order Pending',
        ];

        $query = Order::select('orders.active_status', DB::raw('COUNT(*) as count'))
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($query, $cityId);
        $this->applyCustomFilter($query, $customFilter);
        $this->applyStoreSellerFilter($query, $storeId, $sellerId);
        $counts = $query->groupBy('orders.active_status')
            ->get()
            ->pluck('count', 'active_status')
            ->toArray();

        $labels = [];
        $values = [];

        foreach ($statusMap as $statusId => $name) {
            if (isset($counts[$statusId]) && $counts[$statusId] > 0) {
                $labels[] = $name;
                $values[] = $counts[$statusId];
            }
        }

        return [
            'labels' => $labels,
            'values' => $values,
        ];
    }

    /**
     * Top cancellation reasons, grouped from the free-text
     * order_items.cancellation_reason column. Counts distinct orders per reason
     * within the same date/city/store/seller scope as the rest of the analytics.
     *
     * Note: an order can have items cancelled for different reasons, so it may
     * appear under more than one reason. `total` is the sum of the per-reason
     * counts (not distinct cancelled orders), which keeps the displayed
     * percentages summing to 100%.
     */
    private function getTopCancellationReasons(Carbon $start, Carbon $end, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        $query = Order::join('order_items', 'orders.id', '=', 'order_items.order_id')
            ->select(
                DB::raw('TRIM(order_items.cancellation_reason) as reason'),
                DB::raw('COUNT(DISTINCT orders.id) as orders_count')
            )
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->whereNotNull('order_items.cancellation_reason')
            ->whereRaw("TRIM(order_items.cancellation_reason) <> ''");
        $this->applyCityFilter($query, $cityId);
        $this->applyCustomFilter($query, $customFilter);
        $this->applyStoreSellerFilter($query, $storeId, $sellerId);

        $rows = $query->groupBy(DB::raw('TRIM(order_items.cancellation_reason)'))
            ->orderByDesc('orders_count')
            ->get();

        // Merge near-duplicate free-text reasons: entries that match once case,
        // repeated whitespace and trailing punctuation are ignored collapse into
        // one row (e.g. "changed mind" and "Changed my mind." stay separate, but
        // "Changed my mind" and "changed my mind ." merge). The display label is
        // the spelling used by the most orders.
        $normalize = function ($s) {
            $s = preg_replace('/\s+/', ' ', trim((string) $s));
            $s = rtrim($s, " \t\n\r\0\x0B.");
            return mb_strtolower($s);
        };

        $merged = []; // normalized key => [label, label_count, orders]
        foreach ($rows as $r) {
            $key = $normalize($r->reason);
            if ($key === '') {
                continue;
            }
            $count = (int) $r->orders_count;
            if (!isset($merged[$key])) {
                $merged[$key] = ['label' => trim((string) $r->reason), 'label_count' => 0, 'orders' => 0];
            }
            $merged[$key]['orders'] += $count;
            // Keep the spelling that the most orders used as the display label.
            if ($count > $merged[$key]['label_count']) {
                $merged[$key]['label'] = trim((string) $r->reason);
                $merged[$key]['label_count'] = $count;
            }
        }

        // Highest order count first (the DB sort no longer holds after merging).
        usort($merged, function ($a, $b) {
            return $b['orders'] <=> $a['orders'];
        });

        $total = 0;
        foreach ($merged as $m) {
            $total += $m['orders'];
        }

        $reasons = [];
        foreach ($merged as $m) {
            $reasons[] = [
                'reason' => $m['label'],
                'orders' => $m['orders'],
                'percent' => $total > 0 ? round(($m['orders'] / $total) * 1000) / 10 : 0,
            ];
        }

        // Cap the table at the top 8 reasons; roll the long tail into "Other".
        $topN = 8;
        if (count($reasons) > $topN) {
            $top = array_slice($reasons, 0, $topN);
            $otherCount = 0;
            foreach (array_slice($reasons, $topN) as $r) {
                $otherCount += $r['orders'];
            }
            if ($otherCount > 0) {
                $top[] = [
                    'reason' => 'Other',
                    'orders' => $otherCount,
                    'percent' => $total > 0 ? round(($otherCount / $total) * 1000) / 10 : 0,
                ];
            }
            $reasons = $top;
        }

        return [
            'reasons' => $reasons,
            'total' => $total,
        ];
    }

    /**
     * Payment method split for pie chart.
     */
    private function getPaymentMethodSplit(Carbon $start, Carbon $end, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        $query = Order::select('orders.payment_method', DB::raw('COUNT(*) as count'))
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($query, $cityId);
        $this->applyCustomFilter($query, $customFilter);
        $this->applyStoreSellerFilter($query, $storeId, $sellerId);
        $methods = $query->groupBy('orders.payment_method')
            ->get();

        $labels = [];
        $values = [];

        foreach ($methods as $method) {
            $label = ucwords(str_replace('_', ' ', $method->payment_method));
            $labels[] = $label;
            $values[] = $method->count;
        }

        return [
            'labels' => $labels,
            'values' => $values,
        ];
    }

    /**
     * Revenue breakdown from cart_metadata: MRP, Discount, Delivery, Tips, Promo, Wallet.
     */
    private function getRevenueBreakdown(Carbon $start, Carbon $end, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        $query = Order::select('orders.cart_metadata', 'orders.total', 'orders.delivery_charge', 'orders.discount', 'orders.promo_discount', 'orders.wallet_balance', 'orders.final_total', 'orders.active_status')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($query, $cityId);
        $this->applyCustomFilter($query, $customFilter);
        $this->applyStoreSellerFilter($query, $storeId, $sellerId);
        $orders = $query->get();

        $breakdown = [
            'items_mrp' => 0,
            'combo_mrp' => 0,
            'discount' => 0,
            'delivery_charge' => 0,
            'delivery_tip' => 0,
            'promo_discount' => 0,
            'wallet_deduction' => 0,
            'rain_surcharge' => 0,
            'multi_order_charges' => 0,
            'gst_charges' => 0,
            'cancellation_revenue' => 0,
            'to_be_paid' => 0,
        ];

        foreach ($orders as $order) {
            $meta = $order->cart_metadata;
            if ($meta && isset($meta['billing_summary'])) {
                $bs = $meta['billing_summary'];
                $orderToBePaid = floatval($bs['to_be_paid'] ?? 0);
                $breakdown['items_mrp'] += floatval($bs['items_mrp'] ?? 0);
                $breakdown['combo_mrp'] += floatval($bs['combo_mrp'] ?? 0);
                $breakdown['discount'] += floatval($bs['discount'] ?? 0);
                $breakdown['delivery_charge'] += floatval($bs['delivery_charge'] ?? 0);
                $breakdown['delivery_tip'] += floatval($bs['delivery_tip'] ?? 0);
                $breakdown['promo_discount'] += floatval($bs['promocode_discount'] ?? 0);
                $breakdown['wallet_deduction'] += floatval($bs['wallet_deduction'] ?? 0);
                $breakdown['rain_surcharge'] += floatval($bs['rain_surcharge'] ?? 0);
                $breakdown['multi_order_charges'] += floatval($bs['multi_order_charges'] ?? 0);
                $breakdown['gst_charges'] += floatval($bs['gst_charges'] ?? 0);
                $breakdown['to_be_paid'] += $orderToBePaid;
            } else {
                $orderToBePaid = floatval($order->final_total ?? 0);
                $breakdown['items_mrp'] += floatval($order->total ?? 0);
                $breakdown['delivery_charge'] += floatval($order->delivery_charge ?? 0);
                $breakdown['discount'] += floatval($order->discount ?? 0);
                $breakdown['promo_discount'] += floatval($order->promo_discount ?? 0);
                $breakdown['wallet_deduction'] += floatval($order->wallet_balance ?? 0);
                $breakdown['to_be_paid'] += $orderToBePaid;
            }

            // Revenue tied up in cancelled orders (active_status 7 = Cancelled)
            if ((int) $order->active_status === 7) {
                $breakdown['cancellation_revenue'] += $orderToBePaid;
            }
        }

        // Round all values
        foreach ($breakdown as $key => $value) {
            $breakdown[$key] = round($value, 2);
        }

        return $breakdown;
    }

    /**
     * Delivery charge + tips trend over time.
     */
    private function getDeliveryTrend(Carbon $start, Carbon $end, string $filter, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        $query = Order::select('orders.created_at', 'orders.cart_metadata', 'orders.delivery_charge')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($query, $cityId);
        $this->applyCustomFilter($query, $customFilter);
        $this->applyStoreSellerFilter($query, $storeId, $sellerId);
        $orders = $query->get();

        $grouped = [];

        foreach ($orders as $order) {
            $key = $this->getDateKey($order->created_at, $filter, $start, $end);
            if (!isset($grouped[$key])) {
                $grouped[$key] = ['delivery_charge' => 0, 'delivery_tip' => 0, 'rain_surcharge' => 0];
            }

            $meta = $order->cart_metadata;
            if ($meta && isset($meta['billing_summary'])) {
                $bs = $meta['billing_summary'];
                $grouped[$key]['delivery_charge'] += floatval($bs['delivery_charge'] ?? 0);
                $grouped[$key]['delivery_tip'] += floatval($bs['delivery_tip'] ?? 0);
                $grouped[$key]['rain_surcharge'] += floatval($bs['rain_surcharge'] ?? 0);
            } else {
                $grouped[$key]['delivery_charge'] += floatval($order->delivery_charge ?? 0);
            }
        }

        ksort($grouped);

        $labels = [];
        $deliveryCharges = [];
        $deliveryTips = [];
        $rainSurcharges = [];

        foreach ($grouped as $key => $data) {
            $labels[] = $key;
            $deliveryCharges[] = round($data['delivery_charge'], 2);
            $deliveryTips[] = round($data['delivery_tip'], 2);
            $rainSurcharges[] = round($data['rain_surcharge'], 2);
        }

        return [
            'labels' => $labels,
            'delivery_charges' => $deliveryCharges,
            'delivery_tips' => $deliveryTips,
            'rain_surcharges' => $rainSurcharges,
        ];
    }

    /**
     * Order type split: doorstep vs selfpickup, preorder vs regular.
     */
    private function getOrderTypeSplit(Carbon $start, Carbon $end, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        // Delivery type
        $dtQuery = Order::select('orders.order_type', DB::raw('COUNT(*) as count'))
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($dtQuery, $cityId);
        $this->applyCustomFilter($dtQuery, $customFilter);
        $this->applyStoreSellerFilter($dtQuery, $storeId, $sellerId);
        $deliveryType = $dtQuery->groupBy('orders.order_type')
            ->get()
            ->pluck('count', 'order_type')
            ->toArray();

        // Preorder vs regular
        $preQuery = Order::whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->where('orders.is_preorder', 1);
        $this->applyCityFilter($preQuery, $cityId);
        $this->applyCustomFilter($preQuery, $customFilter);
        $this->applyStoreSellerFilter($preQuery, $storeId, $sellerId);
        $preorderCount = $preQuery->count();

        $regQuery = Order::whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->where(function ($q) {
                $q->where('orders.is_preorder', 0)->orWhereNull('orders.is_preorder');
            });
        $this->applyCityFilter($regQuery, $cityId);
        $this->applyCustomFilter($regQuery, $customFilter);
        $this->applyStoreSellerFilter($regQuery, $storeId, $sellerId);
        $regularCount = $regQuery->count();

        // Promo usage
        $wpQuery = Order::whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->whereNotNull('orders.promo_code')
            ->where('orders.promo_code', '!=', '');
        $this->applyCityFilter($wpQuery, $cityId);
        $this->applyCustomFilter($wpQuery, $customFilter);
        $this->applyStoreSellerFilter($wpQuery, $storeId, $sellerId);
        $withPromo = $wpQuery->count();

        $wopQuery = Order::whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->where(function ($q) {
                $q->whereNull('orders.promo_code')->orWhere('orders.promo_code', '');
            });
        $this->applyCityFilter($wopQuery, $cityId);
        $this->applyCustomFilter($wopQuery, $customFilter);
        $this->applyStoreSellerFilter($wopQuery, $storeId, $sellerId);
        $withoutPromo = $wopQuery->count();

        return [
            'delivery_type' => [
                'labels' => array_map(function ($k) { return ucfirst($k); }, array_keys($deliveryType)),
                'values' => array_values($deliveryType),
            ],
            'order_mode' => [
                'labels' => ['Regular', 'Pre-order'],
                'values' => [$regularCount, $preorderCount],
            ],
            'promo_usage' => [
                'labels' => ['Without Promo', 'With Promo'],
                'values' => [$withoutPromo, $withPromo],
            ],
        ];
    }

    /**
     * Orders by Type (Restaurant / Grocery / Combo / Uncategorized).
     *
     * Classification rule — one order belongs to EXACTLY one category, so the
     * slices always sum to total orders:
     *   1. Order has any combo item             -> Combo
     *   2. Else the primary (earliest) store's flag:
     *        is_food                            -> Restaurant
     *        is_meat|is_vegetable|is_super_mart -> Grocery
     *   3. Else (no store link / unflagged store) -> Uncategorized
     *
     * "Primary store" = store_id of the order's earliest order_seller_status_tracking row.
     * Uncategorized exists because ~23% of orders have no store linkage in the data;
     * coverage_percent reports how many orders were classifiable.
     */
    private function getOrdersByType(Carbon $start, Carbon $end, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        $idQuery = Order::select('orders.id')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($idQuery, $cityId);
        $this->applyCustomFilter($idQuery, $customFilter);
        $this->applyStoreSellerFilter($idQuery, $storeId, $sellerId);
        $orderIds = $idQuery->pluck('orders.id')->all();

        $total = count($orderIds);

        if ($total === 0) {
            return [
                'labels' => [], 'values' => [],
                'total_orders' => 0, 'classified' => 0, 'coverage_percent' => 0,
            ];
        }

        // Classify via the shared single-source-of-truth classifier.
        $catMap = $this->getOrderCategoryMap($orderIds);
        $counts = [
            'Restaurant Orders' => 0,
            'Grocery Orders' => 0,
            'Combo Orders' => 0,
            'Uncategorized' => 0,
        ];
        foreach ($catMap as $cat) {
            $counts[$cat]++;
        }

        // Keep slice order; drop zero-value slices from the donut.
        $labels = [];
        $values = [];
        foreach ($counts as $label => $val) {
            if ($val > 0) {
                $labels[] = $label;
                $values[] = $val;
            }
        }

        $classified = $total - $counts['Uncategorized'];

        return [
            'labels' => $labels,
            'values' => $values,
            'total_orders' => $total,
            'classified' => $classified,
            'coverage_percent' => round(($classified / $total) * 100, 1),
        ];
    }

    /**
     * Shared order classifier — maps each order id to EXACTLY one category label
     * ('Restaurant Orders' | 'Grocery Orders' | 'Combo Orders' | 'Uncategorized').
     *
     * Single source of truth used by both the Orders-by-Type donut and the Order
     * Type Performance table, so the two always reconcile to total orders.
     * Rule: combo item -> Combo; else primary (earliest) store flag
     * (is_food -> Restaurant; is_meat|is_vegetable|is_super_mart -> Grocery);
     * else Uncategorized.
     */
    private function getOrderCategoryMap(array $orderIds): array
    {
        if (empty($orderIds)) {
            return [];
        }

        // Combo orders within scope
        $comboSet = array_flip(
            DB::table('order_combo_items')->whereIn('order_id', $orderIds)->distinct()->pluck('order_id')->all()
        );

        // Primary (earliest) store per order
        $primaryStore = [];
        foreach (DB::table('order_seller_status_tracking')
            ->select('order_id', 'store_id')
            ->whereIn('order_id', $orderIds)
            ->whereNotNull('store_id')
            ->orderBy('id')
            ->get() as $r) {
            if (!isset($primaryStore[$r->order_id])) {
                $primaryStore[$r->order_id] = $r->store_id;
            }
        }

        // Store category map (is_food = restaurant; meat/veg/supermart = grocery)
        $storeCat = [];
        foreach (DB::table('stores')->select('id', 'is_food', 'is_meat', 'is_vegetable', 'is_super_mart')->get() as $s) {
            if ((int) $s->is_food === 1) {
                $storeCat[$s->id] = 'Restaurant Orders';
            } elseif ((int) $s->is_meat === 1 || (int) $s->is_vegetable === 1 || (int) $s->is_super_mart === 1) {
                $storeCat[$s->id] = 'Grocery Orders';
            } else {
                $storeCat[$s->id] = null;
            }
        }

        $map = [];
        foreach ($orderIds as $oid) {
            if (isset($comboSet[$oid])) {
                $map[$oid] = 'Combo Orders';
                continue;
            }
            $sid = $primaryStore[$oid] ?? null;
            $cat = $sid !== null ? ($storeCat[$sid] ?? null) : null;
            $map[$oid] = $cat ?: 'Uncategorized';
        }

        return $map;
    }

    /**
     * Order Type Performance matrix: per category (Restaurant / Grocery / Combo /
     * Uncategorized) — total, completed, cancelled, returned, avg order value,
     * completion rate. Reuses getOrderCategoryMap so rows sum to total orders.
     */
    private function getOrderTypePerformance(Carbon $start, Carbon $end, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        $query = Order::select('orders.id', 'orders.active_status', 'orders.cart_metadata', 'orders.final_total')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($query, $cityId);
        $this->applyCustomFilter($query, $customFilter);
        $this->applyStoreSellerFilter($query, $storeId, $sellerId);
        $orders = $query->get();

        $catMap = $this->getOrderCategoryMap($orders->pluck('id')->all());

        $cats = ['Restaurant Orders', 'Grocery Orders', 'Combo Orders', 'Uncategorized'];
        $stats = [];
        foreach ($cats as $c) {
            $stats[$c] = ['total' => 0, 'completed' => 0, 'cancelled' => 0, 'returned' => 0, 'revenue' => 0];
        }

        foreach ($orders as $o) {
            $c = $catMap[$o->id] ?? 'Uncategorized';
            $stats[$c]['total']++;
            $st = (int) $o->active_status;
            if ($st === 6) {
                $stats[$c]['completed']++;
            } elseif ($st === 7) {
                $stats[$c]['cancelled']++;
            } elseif ($st === 8) {
                $stats[$c]['returned']++;
            }
            $meta = $o->cart_metadata;
            $stats[$c]['revenue'] += ($meta && isset($meta['billing_summary']))
                ? floatval($meta['billing_summary']['to_be_paid'] ?? 0)
                : floatval($o->final_total ?? 0);
        }

        $rows = [];
        $totals = ['total' => 0, 'completed' => 0, 'cancelled' => 0, 'returned' => 0, 'revenue' => 0];
        foreach ($cats as $c) {
            $s = $stats[$c];
            if ($s['total'] === 0) {
                continue;
            }
            $rows[] = [
                'type' => $c,
                'total' => $s['total'],
                'completed' => $s['completed'],
                'cancelled' => $s['cancelled'],
                'returned' => $s['returned'],
                'avg_order_value' => round($s['revenue'] / $s['total'], 2),
                'completion_rate' => round(($s['completed'] / $s['total']) * 100, 1),
            ];
            foreach (['total', 'completed', 'cancelled', 'returned', 'revenue'] as $k) {
                $totals[$k] += $s[$k];
            }
        }

        return [
            'rows' => $rows,
            'totals' => [
                'total' => $totals['total'],
                'completed' => $totals['completed'],
                'cancelled' => $totals['cancelled'],
                'returned' => $totals['returned'],
                'avg_order_value' => $totals['total'] > 0 ? round($totals['revenue'] / $totals['total'], 2) : 0,
                'completion_rate' => $totals['total'] > 0 ? round(($totals['completed'] / $totals['total']) * 100, 1) : 0,
            ],
        ];
    }

    /**
     * Orders by Day of Week + Time of Day heatmap. Hour-of-day uses the app
     * timezone (Asia/Kolkata / IST), matching how created_at is stored, so the
     * "all times in IST" labelling is accurate. Time buckets are 4-hour blocks.
     */
    private function getOrdersByTime(Carbon $start, Carbon $end, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        $query = Order::select('orders.created_at')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($query, $cityId);
        $this->applyCustomFilter($query, $customFilter);
        $this->applyStoreSellerFilter($query, $storeId, $sellerId);
        $orders = $query->get();

        $days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        $blocks = ['12 AM - 4 AM', '4 AM - 8 AM', '8 AM - 12 PM', '12 PM - 4 PM', '4 PM - 8 PM', '8 PM - 12 AM'];

        $dayOfWeek = array_fill(0, 7, 0);
        $matrix = [];
        foreach ($blocks as $b) {
            $matrix[$b] = array_fill(0, 7, 0);
        }

        foreach ($orders as $o) {
            $c = Carbon::parse($o->created_at);
            $dow = $c->isoWeekday() - 1;   // 0=Mon .. 6=Sun
            $blockIdx = intdiv($c->hour, 4); // 0..5
            $dayOfWeek[$dow]++;
            $matrix[$blocks[$blockIdx]][$dow]++;
        }

        return [
            'days' => $days,
            'day_of_week' => $dayOfWeek,
            'time_of_day' => [
                'blocks' => $blocks,
                'matrix' => $matrix,
            ],
        ];
    }

    /**
     * Combo Performance card. Isolates combo economics (independent of any
     * loose items that share the same order) by aggregating the
     * order_combo_items rows belonging to in-scope orders.
     *
     * Revenue = SUM(total_products_price) (combo selling price);
     * Savings = SUM(total_actual_price - total_products_price) (MRP vs selling).
     * Respects the same date/city/store/seller/order-type scope as the page.
     */
    private function getComboPerformance(Carbon $start, Carbon $end, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        $empty = [
            'combo_orders' => 0,
            'combos_sold' => 0,
            'combo_revenue' => 0,
            'combo_savings' => 0,
            'top_combos' => [],
        ];

        // Orders in scope that contain at least one combo item.
        $orderQuery = Order::select('orders.id')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->whereExists(function ($q) {
                $q->select(DB::raw(1))
                    ->from('order_combo_items')
                    ->whereColumn('order_combo_items.order_id', 'orders.id');
            });
        $this->applyCityFilter($orderQuery, $cityId);
        $this->applyCustomFilter($orderQuery, $customFilter);
        $this->applyStoreSellerFilter($orderQuery, $storeId, $sellerId);
        $orderIds = $orderQuery->pluck('orders.id')->all();

        if (empty($orderIds)) {
            return $empty;
        }

        $totals = DB::table('order_combo_items')
            ->whereIn('order_id', $orderIds)
            ->selectRaw('COUNT(*) as combos_sold')
            ->selectRaw('COALESCE(SUM(total_products_price), 0) as revenue')
            ->selectRaw('COALESCE(SUM(total_actual_price), 0) as mrp')
            ->first();

        $topRows = DB::table('order_combo_items')
            ->whereIn('order_id', $orderIds)
            ->select('combo_name', DB::raw('COUNT(*) as qty'), DB::raw('COALESCE(SUM(total_products_price), 0) as revenue'))
            ->groupBy('combo_name')
            ->orderByDesc('revenue')
            ->limit(5)
            ->get();

        $topCombos = [];
        foreach ($topRows as $r) {
            $topCombos[] = [
                'name' => $r->combo_name ?: 'Combo Pack',
                'qty' => (int) $r->qty,
                'revenue' => round(floatval($r->revenue), 2),
            ];
        }

        return [
            'combo_orders' => count($orderIds),
            'combos_sold' => (int) ($totals->combos_sold ?? 0),
            'combo_revenue' => round(floatval($totals->revenue ?? 0), 2),
            'combo_savings' => round(floatval(($totals->mrp ?? 0) - ($totals->revenue ?? 0)), 2),
            'top_combos' => $topCombos,
        ];
    }

    /**
     * Top cities by order count. Percentage is share of geolocated orders
     * (orders joinable to a city) so the column reconciles to ~100%.
     */
    private function getTopCities(Carbon $start, Carbon $end, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        $base = Order::join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
            ->join('cities', 'user_addresses.city_id', '=', 'cities.id')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        // city filter inline (user_addresses already joined; avoid applyCityFilter's duplicate join)
        if ($cityId) {
            $base->where('user_addresses.city_id', $cityId);
        }
        $this->applyCustomFilter($base, $customFilter);
        $this->applyStoreSellerFilter($base, $storeId, $sellerId);

        $totalGeo = (clone $base)->count();

        $rows = $base->select('cities.id', 'cities.name', DB::raw('COUNT(*) as order_count'))
            ->groupBy('cities.id', 'cities.name')
            ->orderByDesc('order_count')
            ->limit(10)
            ->get();

        $cities = [];
        foreach ($rows as $r) {
            $cities[] = [
                'city' => $r->name,
                'order_count' => (int) $r->order_count,
                'percent' => $totalGeo > 0 ? round(($r->order_count / $totalGeo) * 100, 1) : 0,
            ];
        }

        return [
            'cities' => $cities,
            'total_geolocated' => $totalGeo,
        ];
    }

    /**
     * Coupon/Promo code analytics: top coupons, usage count, total discount given, avg discount per coupon.
     */
    private function getCouponAnalytics(Carbon $start, Carbon $end, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        // Top coupons by usage count
        $tcQuery = Order::select(
                'orders.promo_code',
                'orders.promo_code_id',
                DB::raw('COUNT(*) as usage_count'),
                DB::raw('COALESCE(SUM(orders.promo_discount), 0) as total_discount_given'),
                DB::raw('COALESCE(AVG(orders.promo_discount), 0) as avg_discount'),
                DB::raw('COALESCE(SUM(orders.final_total), 0) as total_revenue')
            )
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->whereNotNull('orders.promo_code')
            ->where('orders.promo_code', '!=', '');
        $this->applyCityFilter($tcQuery, $cityId);
        $this->applyCustomFilter($tcQuery, $customFilter);
        $this->applyStoreSellerFilter($tcQuery, $storeId, $sellerId);
        $topCoupons = $tcQuery->groupBy('orders.promo_code', 'orders.promo_code_id')
            ->orderByDesc('usage_count')
            ->limit(10)
            ->get();

        // Enrich with promo code details from promo_codes table
        $couponDetails = [];
        $couponLabels = [];
        $couponUsageCounts = [];
        $couponDiscounts = [];

        foreach ($topCoupons as $coupon) {
            $promoInfo = null;
            if ($coupon->promo_code_id > 0) {
                $promoInfo = PromoCode::find($coupon->promo_code_id);
            }

            $couponDetails[] = [
                'promo_code' => $coupon->promo_code,
                'usage_count' => $coupon->usage_count,
                'total_discount_given' => round($coupon->total_discount_given, 2),
                'avg_discount' => round($coupon->avg_discount, 2),
                'total_revenue' => round($coupon->total_revenue, 2),
                'discount_type' => $promoInfo->discount_type ?? '-',
                'discount_value' => $promoInfo->discount ?? 0,
                'max_discount_amount' => $promoInfo->max_discount_amount ?? 0,
                'min_order_amount' => $promoInfo->minimum_order_amount ?? 0,
            ];

            $couponLabels[] = $coupon->promo_code;
            $couponUsageCounts[] = $coupon->usage_count;
            $couponDiscounts[] = round($coupon->total_discount_given, 2);
        }

        // Also get cart_metadata-based promo discount totals for more accuracy
        $metaQuery = Order::select('orders.cart_metadata', 'orders.promo_code', 'orders.promo_discount')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->whereNotNull('orders.promo_code')
            ->where('orders.promo_code', '!=', '');
        $this->applyCityFilter($metaQuery, $cityId);
        $this->applyCustomFilter($metaQuery, $customFilter);
        $this->applyStoreSellerFilter($metaQuery, $storeId, $sellerId);
        $orders = $metaQuery->get();

        $totalPromoFromMeta = 0;
        $totalWalletSavedByPromo = 0;
        foreach ($orders as $order) {
            $meta = $order->cart_metadata;
            if ($meta && isset($meta['billing_summary'])) {
                $totalPromoFromMeta += floatval($meta['billing_summary']['promocode_discount'] ?? 0);
            } else {
                $totalPromoFromMeta += floatval($order->promo_discount ?? 0);
            }
        }

        // Summary stats
        $towpQuery = Order::whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->whereNotNull('orders.promo_code')
            ->where('orders.promo_code', '!=', '');
        $this->applyCityFilter($towpQuery, $cityId);
        $this->applyCustomFilter($towpQuery, $customFilter);
        $this->applyStoreSellerFilter($towpQuery, $storeId, $sellerId);
        $totalOrdersWithPromo = $towpQuery->count();

        $toaQuery = Order::whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($toaQuery, $cityId);
        $this->applyCustomFilter($toaQuery, $customFilter);
        $this->applyStoreSellerFilter($toaQuery, $storeId, $sellerId);
        $totalOrdersAll = $toaQuery->count();

        $ucuQuery = Order::whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->whereNotNull('orders.promo_code')
            ->where('orders.promo_code', '!=', '');
        $this->applyCityFilter($ucuQuery, $cityId);
        $this->applyCustomFilter($ucuQuery, $customFilter);
        $this->applyStoreSellerFilter($ucuQuery, $storeId, $sellerId);
        $uniqueCouponsUsed = $ucuQuery->distinct('orders.promo_code')
            ->count('orders.promo_code');

        return [
            'summary' => [
                'total_orders_with_promo' => $totalOrdersWithPromo,
                'total_orders' => $totalOrdersAll,
                'promo_usage_rate' => $totalOrdersAll > 0 ? round(($totalOrdersWithPromo / $totalOrdersAll) * 100, 1) : 0,
                'unique_coupons_used' => $uniqueCouponsUsed,
                'total_promo_discount' => round($totalPromoFromMeta, 2),
                'avg_promo_discount' => $totalOrdersWithPromo > 0 ? round($totalPromoFromMeta / $totalOrdersWithPromo, 2) : 0,
            ],
            'top_coupons' => $couponDetails,
            'chart' => [
                'labels' => $couponLabels,
                'usage_counts' => $couponUsageCounts,
                'discounts' => $couponDiscounts,
            ],
        ];
    }

    /**
     * Helper: Get date key for grouping orders.
     */
    private function getDateKey($createdAt, string $filter, Carbon $start, Carbon $end): string
    {
        $date = Carbon::parse($createdAt);
        $diffDays = $start->diffInDays($end);

        if ($filter === 'daily') {
            return $date->format('h A'); // 01 AM, 02 PM, etc.
        } elseif ($filter === 'weekly') {
            return $date->format('D, M d'); // Mon, Feb 24
        } elseif ($filter === 'monthly') {
            return $date->format('M d'); // Feb 24
        } else {
            // Custom: auto-decide based on range
            if ($diffDays <= 1) {
                return $date->format('h A');
            } elseif ($diffDays <= 31) {
                return $date->format('M d');
            } else {
                return $date->format('M Y'); // Feb 2026
            }
        }
    }

    /**
     * Helper: Get SQL date group format.
     */
    private function getDateGroupFormat(string $filter, Carbon $start, Carbon $end): array
    {
        $diffDays = $start->diffInDays($end);

        // Using MySQL DATE_FORMAT (qualified with orders. to avoid ambiguity on JOIN)
        if ($filter === 'daily') {
            return ['select' => "DATE_FORMAT(orders.created_at, '%h %p')"];
        } elseif ($filter === 'weekly') {
            return ['select' => "DATE_FORMAT(orders.created_at, '%a, %b %d')"];
        } elseif ($filter === 'monthly') {
            return ['select' => "DATE_FORMAT(orders.created_at, '%b %d')"];
        } else {
            if ($diffDays <= 1) {
                return ['select' => "DATE_FORMAT(orders.created_at, '%h %p')"];
            } elseif ($diffDays <= 31) {
                return ['select' => "DATE_FORMAT(orders.created_at, '%b %d')"];
            } else {
                return ['select' => "DATE_FORMAT(orders.created_at, '%b %Y')"];
            }
        }
    }

    /**
     * Profit/Loss comparison: current period vs previous equivalent period.
     * e.g., This week vs Last week, This month vs Last month, Today vs Yesterday.
     */
    private function getProfitLossComparison(Carbon $start, Carbon $end, string $filter, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null)
    {
        [$prevStart, $prevEnd] = $this->getPreviousPeriod($filter, $start, $end);

        $periodLabels = $this->getPeriodLabels($filter, $start, $end, $prevStart, $prevEnd);

        $currentSummary = $this->getComparisonMetrics($start, $end, $cityId, $customFilter, $storeId, $sellerId);
        $previousSummary = $this->getComparisonMetrics($prevStart, $prevEnd, $cityId, $customFilter, $storeId, $sellerId);

        // Calculate changes
        $metrics = ['revenue', 'orders', 'avg_order_value', 'total_discount', 'delivery_charges', 'promo_discount'];
        $comparison = [];

        // Metrics where a decrease is the favorable outcome (lower discounts = better margin).
        $lowerIsBetter = ['total_discount', 'promo_discount'];

        foreach ($metrics as $metric) {
            $current = $currentSummary[$metric];
            $previous = $previousSummary[$metric];
            $change = $current - $previous;
            $changePercent = $previous > 0 ? round(($change / $previous) * 100, 1) : ($current > 0 ? 100 : 0);

            $comparison[$metric] = [
                'current' => round($current, 2),
                'previous' => round($previous, 2),
                'change' => round($change, 2),
                'change_percent' => $changePercent,
                // Raw direction of the change (did the number rise?).
                'is_positive' => $change >= 0,
                // Whether the change is good for the business. Single source of truth
                // consumed by the UI and the Excel/PDF exports.
                'is_favorable' => in_array($metric, $lowerIsBetter) ? $change <= 0 : $change >= 0,
            ];
        }

        // Chart data: only comparable-scale financial metrics (excludes Orders, Avg Order Value, Promo Discount which are too small to visualize alongside Revenue/Delivery)
        $chartMetrics = ['revenue', 'total_discount', 'delivery_charges'];
        $chartLabels = ['Revenue', 'Total Discounts', 'Delivery Charges'];
        $currentValues = array_map(fn($m) => $comparison[$m]['current'], $chartMetrics);
        $previousValues = array_map(fn($m) => $comparison[$m]['previous'], $chartMetrics);

        return [
            'current_period' => $periodLabels['current'],
            'previous_period' => $periodLabels['previous'],
            'prev_start_date' => $prevStart->toDateString(),
            'prev_end_date' => $prevEnd->toDateString(),
            'metrics' => $comparison,
            'chart' => [
                'labels' => $chartLabels,
                'current' => $currentValues,
                'previous' => $previousValues,
            ],
        ];
    }

    /**
     * Helper: Get key metrics for a date range (used for comparison).
     */
    private function getComparisonMetrics(Carbon $start, Carbon $end, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null): array
    {
        $query = Order::whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($query, $cityId);
        $this->applyCustomFilter($query, $customFilter);
        $this->applyStoreSellerFilter($query, $storeId, $sellerId);
        $orders = $query->get();

        $totalOrders = $orders->count();
        $revenue = 0;
        $totalDiscount = 0;
        $deliveryCharges = 0;
        $promoDiscount = 0;

        foreach ($orders as $order) {
            $meta = $order->cart_metadata;
            if ($meta && isset($meta['billing_summary'])) {
                $bs = $meta['billing_summary'];
                $revenue += floatval($bs['to_be_paid'] ?? 0);
                $totalDiscount += floatval($bs['discount'] ?? 0) + floatval($bs['total_savings'] ?? 0);
                $deliveryCharges += floatval($bs['delivery_charge'] ?? 0);
                $promoDiscount += floatval($bs['promocode_discount'] ?? 0);
            } else {
                $revenue += floatval($order->final_total ?? 0);
                $totalDiscount += floatval($order->discount ?? 0);
                $deliveryCharges += floatval($order->delivery_charge ?? 0);
                $promoDiscount += floatval($order->promo_discount ?? 0);
            }
        }

        return [
            'revenue' => $revenue,
            'orders' => $totalOrders,
            'avg_order_value' => $totalOrders > 0 ? $revenue / $totalOrders : 0,
            'total_discount' => $totalDiscount,
            'delivery_charges' => $deliveryCharges,
            'promo_discount' => $promoDiscount,
        ];
    }

    /**
     * Platform profit analysis.
     *
     * "Profit" here is the platform's commission income (admin commission
     * charged to sellers on each delivered item, recorded by
     * SellerOrderSettlementService) minus the promo discounts the platform
     * funds. Payment-gateway fees and GST are pass-through and excluded;
     * item cost-price margin and delivery margin are not tracked in this app.
     *
     * @param array $plc The profit/loss comparison already computed for this
     *                    request, reused for billing-summary-accurate promo totals.
     */
    private function getProfitAnalysis(Carbon $start, Carbon $end, string $filter, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null, array $plc = [])
    {
        [$prevStart, $prevEnd] = $this->getPreviousPeriod($filter, $start, $end);
        $periodLabels = $this->getPeriodLabels($filter, $start, $end, $prevStart, $prevEnd);

        $current = $this->getSettlementTotals($start, $end, $cityId, $customFilter, $storeId, $sellerId);
        $previous = $this->getSettlementTotals($prevStart, $prevEnd, $cityId, $customFilter, $storeId, $sellerId);

        // Promo discount the platform funds (billing-summary accurate, reused from
        // the comparison block so we don't re-scan orders here).
        $promoCurrent = floatval($plc['metrics']['promo_discount']['current'] ?? 0);
        $promoPrevious = floatval($plc['metrics']['promo_discount']['previous'] ?? 0);

        $netCurrent = $current['commission'] - $promoCurrent;
        $netPrevious = $previous['commission'] - $promoPrevious;

        // Build a comparison block (current vs previous) for one metric.
        $build = function (float $cur, float $prev, bool $lowerIsBetter = false) {
            $change = $cur - $prev;
            $changePercent = $prev > 0 ? round(($change / $prev) * 100, 1) : ($cur > 0 ? 100 : 0);
            return [
                'current' => round($cur, 2),
                'previous' => round($prev, 2),
                'change' => round($change, 2),
                'change_percent' => $changePercent,
                'is_positive' => $change >= 0,
                'is_favorable' => $lowerIsBetter ? $change <= 0 : $change >= 0,
            ];
        };

        // Settled item value (net of GST) = what the platform collected on
        // settled items = seller payout + commission + gateway fees. Used only
        // as the denominator for the effective take rate.
        $grossSettled = $current['commission'] + $current['seller_payout'] + $current['gateway_fees'];
        $takeRate = $grossSettled > 0 ? round(($current['commission'] / $grossSettled) * 100, 1) : 0;
        $avgProfitPerOrder = $current['settled_orders'] > 0 ? round($netCurrent / $current['settled_orders'], 2) : 0;

        return [
            'available' => $current['settled_orders'] > 0 || $previous['settled_orders'] > 0,
            'current_period' => $periodLabels['current'],
            'previous_period' => $periodLabels['previous'],
            'metrics' => [
                'net_profit' => $build($netCurrent, $netPrevious),
                'commission_income' => $build($current['commission'], $previous['commission']),
                'promo_cost' => $build($promoCurrent, $promoPrevious, true),
                'gateway_fees' => $build($current['gateway_fees'], $previous['gateway_fees']),
            ],
            'take_rate' => $takeRate,
            'avg_profit_per_order' => $avgProfitPerOrder,
            'settled_orders' => $current['settled_orders'],
            'seller_payout' => round($current['seller_payout'], 2),
            'chart' => $this->getProfitTrend($start, $end, $filter, $cityId, $customFilter, $storeId, $sellerId),
        ];
    }

    /**
     * Helper: Sum settlement amounts (admin commission, gateway fees, seller
     * payout) from seller_wallet_transactions for orders created in the range.
     * Only delivered/settled orders have these rows, so undelivered orders
     * naturally contribute zero.
     */
    private function getSettlementTotals(Carbon $start, Carbon $end, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null): array
    {
        $query = DB::table('seller_wallet_transactions as swt')
            ->join('orders', 'orders.id', '=', 'swt.order_id')
            ->where('swt.type', SellerWalletTransaction::TYPE_ORDER_COMMISSION)
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($query, $cityId);
        $this->applyCustomFilter($query, $customFilter);
        $this->applyStoreSellerFilter($query, $storeId, $sellerId);

        $row = $query->selectRaw(
            'COALESCE(SUM(swt.admin_commission), 0) as commission, '
            . 'COALESCE(SUM(swt.payment_gateway_fees), 0) as gateway_fees, '
            . 'COALESCE(SUM(swt.amount), 0) as seller_payout, '
            . 'COUNT(DISTINCT swt.order_id) as settled_orders'
        )->first();

        return [
            'commission' => floatval($row->commission ?? 0),
            'gateway_fees' => floatval($row->gateway_fees ?? 0),
            'seller_payout' => floatval($row->seller_payout ?? 0),
            'settled_orders' => intval($row->settled_orders ?? 0),
        ];
    }

    /**
     * Helper: Time series of commission income, platform-funded promo cost and
     * net profit across the current period, for the profit chart.
     */
    private function getProfitTrend(Carbon $start, Carbon $end, string $filter, ?string $cityId = null, ?string $customFilter = null, ?string $storeId = null, ?string $sellerId = null): array
    {
        $buckets = []; // sortKey => ['label' => string, 'commission' => float, 'promo' => float]

        // Commission income per bucket (from settlements joined to orders).
        $swtQuery = DB::table('seller_wallet_transactions as swt')
            ->join('orders', 'orders.id', '=', 'swt.order_id')
            ->where('swt.type', SellerWalletTransaction::TYPE_ORDER_COMMISSION)
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($swtQuery, $cityId);
        $this->applyCustomFilter($swtQuery, $customFilter);
        $this->applyStoreSellerFilter($swtQuery, $storeId, $sellerId);
        foreach ($swtQuery->select('orders.created_at', 'swt.admin_commission')->get() as $r) {
            [$key, $label] = $this->getDateBucket($r->created_at, $filter, $start, $end);
            if (!isset($buckets[$key])) {
                $buckets[$key] = ['label' => $label, 'commission' => 0, 'promo' => 0];
            }
            $buckets[$key]['commission'] += floatval($r->admin_commission);
        }

        // Platform-funded promo cost per bucket (from order billing summary).
        $orderQuery = Order::select('orders.created_at', 'orders.cart_metadata', 'orders.promo_discount')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyCityFilter($orderQuery, $cityId);
        $this->applyCustomFilter($orderQuery, $customFilter);
        $this->applyStoreSellerFilter($orderQuery, $storeId, $sellerId);
        foreach ($orderQuery->get() as $order) {
            [$key, $label] = $this->getDateBucket($order->created_at, $filter, $start, $end);
            if (!isset($buckets[$key])) {
                $buckets[$key] = ['label' => $label, 'commission' => 0, 'promo' => 0];
            }
            $meta = $order->cart_metadata;
            if ($meta && isset($meta['billing_summary'])) {
                $buckets[$key]['promo'] += floatval($meta['billing_summary']['promocode_discount'] ?? 0);
            } else {
                $buckets[$key]['promo'] += floatval($order->promo_discount ?? 0);
            }
        }

        ksort($buckets); // sortKey is chronological (YmdH / Ymd / Ym)

        $labels = [];
        $commission = [];
        $promo = [];
        $net = [];
        foreach ($buckets as $b) {
            $labels[] = $b['label'];
            $commission[] = round($b['commission'], 2);
            $promo[] = round($b['promo'], 2);
            $net[] = round($b['commission'] - $b['promo'], 2);
        }

        return [
            'labels' => $labels,
            'commission' => $commission,
            'promo' => $promo,
            'net' => $net,
        ];
    }

    /**
     * Helper: Map a timestamp to a [chronological sort key, display label] pair.
     * The display label matches getDateKey(); the sort key guarantees correct
     * chronological ordering (getDateKey labels alone sort incorrectly).
     */
    private function getDateBucket($createdAt, string $filter, Carbon $start, Carbon $end): array
    {
        $date = Carbon::parse($createdAt);
        $diffDays = $start->diffInDays($end);

        if ($filter === 'daily' || ($filter === 'custom' && $diffDays <= 1)) {
            $sortKey = $date->format('YmdH');
        } elseif ($filter === 'custom' && $diffDays > 31) {
            $sortKey = $date->format('Ym');
        } else {
            $sortKey = $date->format('Ymd');
        }

        return [$sortKey, $this->getDateKey($createdAt, $filter, $start, $end)];
    }

    /**
     * Helper: Compute the previous comparison period for a filter.
     * Monthly aligns to the full previous calendar month; other filters use the
     * same-length window immediately preceding the current one.
     */
    private function getPreviousPeriod(string $filter, Carbon $start, Carbon $end): array
    {
        if ($filter === 'monthly') {
            return [
                $start->copy()->subMonthNoOverflow()->startOfMonth(),
                $start->copy()->subMonthNoOverflow()->endOfMonth(),
            ];
        }

        $diffDays = $start->diffInDays($end);
        $prevEnd = $start->copy()->subSecond();
        $prevStart = $prevEnd->copy()->subDays($diffDays)->startOfDay();

        return [$prevStart, $prevEnd->endOfDay()];
    }

    /**
     * Helper: Get human-readable period labels.
     */
    private function getPeriodLabels(string $filter, Carbon $start, Carbon $end, Carbon $prevStart, Carbon $prevEnd): array
    {
        switch ($filter) {
            case 'daily':
                return [
                    'current' => 'Today (' . $start->format('d M') . ')',
                    'previous' => 'Yesterday (' . $prevStart->format('d M') . ')',
                ];
            case 'weekly':
                return [
                    'current' => 'This Week (' . $start->format('d M') . ' - ' . $end->format('d M') . ')',
                    'previous' => 'Last Week (' . $prevStart->format('d M') . ' - ' . $prevEnd->format('d M') . ')',
                ];
            case 'monthly':
                return [
                    'current' => 'This Month (' . $start->format('M Y') . ')',
                    'previous' => 'Last Month (' . $prevStart->format('M Y') . ')',
                ];
            default:
                return [
                    'current' => $start->format('d M Y') . ' - ' . $end->format('d M Y'),
                    'previous' => $prevStart->format('d M Y') . ' - ' . $prevEnd->format('d M Y'),
                ];
        }
    }

    /**
     * Helper: Parse date range from request (reused by analytics + exports).
     */
    private function parseDateRange(Request $request): array
    {
        $filter = $request->get('filter', 'daily');
        $startDate = $request->get('start_date');
        $endDate = $request->get('end_date');

        switch ($filter) {
            case 'daily':
                $start = Carbon::today();
                $end = Carbon::today()->endOfDay();
                break;
            case 'weekly':
                $start = Carbon::now()->startOfWeek();
                $end = Carbon::now()->endOfWeek();
                break;
            case 'monthly':
                $start = Carbon::now()->startOfMonth();
                $end = Carbon::now()->endOfMonth();
                break;
            case 'custom':
                $start = $startDate ? Carbon::parse($startDate)->startOfDay() : Carbon::now()->subDays(30)->startOfDay();
                $end = $endDate ? Carbon::parse($endDate)->endOfDay() : Carbon::now()->endOfDay();
                break;
            default:
                $start = Carbon::today();
                $end = Carbon::today()->endOfDay();
        }

        return [$filter, $start, $end];
    }

    /**
     * Helper: Apply city/zone filter to an Order query if city_id is provided.
     */
    private function applyCityFilter($query, ?string $cityId)
    {
        if ($cityId) {
            $query->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                  ->where('user_addresses.city_id', $cityId);
        }
        return $query;
    }

    /**
     * Helper: Apply custom pre-order filter to an Order query if custom_filter is provided.
     */
    private function applyCustomFilter($query, ?string $customFilter)
    {
        if ($customFilter !== null && $customFilter !== '') {
            if ($customFilter == '1') {
                // Pre-orders only
                $query->where('orders.is_preorder', 1);
            } elseif ($customFilter == '0') {
                // Regular orders only
                $query->where(function ($q) {
                    $q->where('orders.is_preorder', 0)->orWhereNull('orders.is_preorder');
                });
            } elseif ($customFilter == '2') {
                // Combo orders only (orders that contain at least one combo item)
                $query->whereExists(function ($subQuery) {
                    $subQuery->select(DB::raw(1))
                        ->from('order_combo_items')
                        ->whereColumn('order_combo_items.order_id', 'orders.id');
                });
            }
        }
        return $query;
    }

    /**
     * Helper: Apply store and seller filters using order_seller_status_tracking table.
     */
    private function applyStoreSellerFilter($query, ?string $storeId = null, ?string $sellerId = null)
    {
        if ($storeId || $sellerId) {
            $query->whereExists(function ($subQuery) use ($storeId, $sellerId) {
                $subQuery->select(DB::raw(1))
                    ->from('order_seller_status_tracking')
                    ->whereColumn('order_seller_status_tracking.order_id', 'orders.id');

                if ($storeId) {
                    $subQuery->where('order_seller_status_tracking.store_id', $storeId);
                }

                if ($sellerId) {
                    $subQuery->where('order_seller_status_tracking.seller_id', $sellerId);
                }
            });
        }
        return $query;
    }

    /**
     * Helper: Get city name by ID.
     */
    private function getCityName(?string $cityId): string
    {
        if (!$cityId) return '';
        $city = City::find($cityId);
        return $city ? $city->name : '';
    }

    /**
     * Export analytics data as Excel.
     */
    public function exportExcel(Request $request)
    {
        [$filter, $start, $end] = $this->parseDateRange($request);
        $section = $request->get('section', 'all'); // all, summary, orders, coupons
        $cityId = $request->get('city_id');
        $customFilter = $request->get('custom_filter');
        $storeId = $request->get('store_id');
        $sellerId = $request->get('seller_id');
        $cityName = $this->getCityName($cityId);

        $spreadsheet = new Spreadsheet();
        $spreadsheet->removeSheetByIndex(0);

        $headerStyle = [
            'font' => ['bold' => true, 'color' => ['rgb' => 'FFFFFF'], 'size' => 11],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '4CAF50']],
            'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER],
            'borders' => ['allBorders' => ['borderStyle' => Border::BORDER_THIN]],
        ];
        $cellBorder = [
            'borders' => ['allBorders' => ['borderStyle' => Border::BORDER_THIN, 'color' => ['rgb' => 'DDDDDD']]],
        ];

        $dateLabel = $start->format('d M Y') . ' - ' . $end->format('d M Y');
        $zoneLabel = $cityName ? ' | Zone: ' . $cityName : '';

        // Sheet 0: Profit/Loss Comparison (only when explicitly requested from Profit/Loss page)
        if ($section === 'comparison') {
            $plc = $this->getProfitLossComparison($start, $end, $filter, $cityId, $customFilter, $storeId, $sellerId);

            $sheet = $spreadsheet->createSheet();
            $sheet->setTitle('Profit-Loss Comparison');

            $sheet->setCellValue('A1', 'Profit / Loss Comparison' . $zoneLabel);
            $sheet->setCellValue('A2', $plc['current_period'] . '  vs  ' . $plc['previous_period']);
            $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);
            $sheet->getStyle('A2')->getFont()->setItalic(true);

            $row = 4;
            $sheet->setCellValue('A' . $row, 'Metric');
            $sheet->setCellValue('B' . $row, 'Current Period');
            $sheet->setCellValue('C' . $row, 'Previous Period');
            $sheet->setCellValue('D' . $row, 'Change');
            $sheet->setCellValue('E' . $row, 'Change %');
            $sheet->setCellValue('F' . $row, 'Status');
            $sheet->getStyle("A{$row}:F{$row}")->applyFromArray($headerStyle);

            $metricLabels = [
                'revenue' => 'Revenue',
                'orders' => 'Total Orders',
                'avg_order_value' => 'Avg Order Value',
                'total_discount' => 'Total Discounts',
                'delivery_charges' => 'Delivery Charges',
                'promo_discount' => 'Promo Discount',
            ];

            foreach ($metricLabels as $key => $label) {
                $m = $plc['metrics'][$key];
                $row++;
                $sheet->setCellValue('A' . $row, $label);
                $isAmount = $key !== 'orders';
                $sheet->setCellValue('B' . $row, $isAmount ? '₹' . number_format($m['current'], 2) : $m['current']);
                $sheet->setCellValue('C' . $row, $isAmount ? '₹' . number_format($m['previous'], 2) : $m['previous']);
                $sheet->setCellValue('D' . $row, ($m['change'] >= 0 ? '+' : '') . ($isAmount ? '₹' . number_format($m['change'], 2) : $m['change']));
                $sheet->setCellValue('E' . $row, ($m['change_percent'] >= 0 ? '+' : '') . $m['change_percent'] . '%');
                $sheet->setCellValue('F' . $row, $m['is_favorable'] ? 'UP' : 'DOWN');
                $sheet->getStyle("A{$row}:F{$row}")->applyFromArray($cellBorder);

                // Color the status cell
                $statusColor = $m['is_favorable'] ? '4CAF50' : 'FF4560';
                $sheet->getStyle("F{$row}")->getFont()->setBold(true)->getColor()->setRGB($statusColor);
                $sheet->getStyle("D{$row}")->getFont()->getColor()->setRGB($statusColor);
                $sheet->getStyle("E{$row}")->getFont()->getColor()->setRGB($statusColor);
            }

            foreach (range('A', 'F') as $c) {
                $sheet->getColumnDimension($c)->setAutoSize(true);
            }
        }

        // Sheet 1: Summary
        if (in_array($section, ['all', 'summary'])) {
            $summary = $this->getSummaryCards($start, $end, $cityId, $customFilter, $storeId, $sellerId);
            $revenueBreakdown = $this->getRevenueBreakdown($start, $end, $cityId, $customFilter, $storeId, $sellerId);

            $sheet = $spreadsheet->createSheet();
            $sheet->setTitle('Summary');

            $sheet->setCellValue('A1', 'Order Analytics Summary' . $zoneLabel);
            $sheet->setCellValue('A2', 'Period: ' . $dateLabel . ' (' . ucfirst($filter) . ')');
            $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);
            $sheet->getStyle('A2')->getFont()->setItalic(true);

            // Summary cards
            $row = 4;
            $sheet->setCellValue('A' . $row, 'Metric');
            $sheet->setCellValue('B' . $row, 'Value');
            $sheet->getStyle("A{$row}:B{$row}")->applyFromArray($headerStyle);

            $summaryRows = [
                ['Total Orders', $summary['total_orders']],
                ['Total Revenue', '₹' . number_format($summary['total_revenue'], 2)],
                ['Avg Order Value', '₹' . number_format($summary['avg_order_value'], 2)],
                ['Total MRP', '₹' . number_format($summary['total_mrp'], 2)],
                ['Delivery Charges', '₹' . number_format($summary['total_delivery_charge'], 2)],
                ['Delivery Tips', '₹' . number_format($summary['total_delivery_tips'], 2)],
                ['Promo Discounts', '₹' . number_format($summary['total_promo_discount'], 2)],
                ['Wallet Used', '₹' . number_format($summary['total_wallet_used'], 2)],
            ];

            foreach ($summaryRows as $sRow) {
                $row++;
                $sheet->setCellValue('A' . $row, $sRow[0]);
                $sheet->setCellValue('B' . $row, $sRow[1]);
                $sheet->getStyle("A{$row}:B{$row}")->applyFromArray($cellBorder);
            }

            // Revenue breakdown
            $row += 2;
            $sheet->setCellValue('A' . $row, 'Revenue Breakdown');
            $sheet->getStyle('A' . $row)->getFont()->setBold(true)->setSize(12);
            $row++;
            $sheet->setCellValue('A' . $row, 'Component');
            $sheet->setCellValue('B' . $row, 'Amount');
            $sheet->getStyle("A{$row}:B{$row}")->applyFromArray($headerStyle);

            $breakdownRows = [
                ['Items MRP', $revenueBreakdown['items_mrp']],
                ['Combo MRP', $revenueBreakdown['combo_mrp']],
                ['Discount', $revenueBreakdown['discount']],
                ['Delivery Charge', $revenueBreakdown['delivery_charge']],
                ['Delivery Tip', $revenueBreakdown['delivery_tip']],
                ['Promo Discount', $revenueBreakdown['promo_discount']],
                ['Wallet Deduction', $revenueBreakdown['wallet_deduction']],
                ['Rain Surcharge', $revenueBreakdown['rain_surcharge']],
                ['Multi Order Charges', $revenueBreakdown['multi_order_charges']],
                ['GST Charges', $revenueBreakdown['gst_charges']],
                ['Net Revenue (To Be Paid)', $revenueBreakdown['to_be_paid']],
            ];

            foreach ($breakdownRows as $bRow) {
                $row++;
                $sheet->setCellValue('A' . $row, $bRow[0]);
                $sheet->setCellValue('B' . $row, '₹' . number_format($bRow[1], 2));
                $sheet->getStyle("A{$row}:B{$row}")->applyFromArray($cellBorder);
            }

            $sheet->getColumnDimension('A')->setAutoSize(true);
            $sheet->getColumnDimension('B')->setAutoSize(true);
        }

        // Sheet 2: Orders List
        if (in_array($section, ['all', 'orders'])) {
            $olQuery = Order::whereBetween('orders.created_at', [$start, $end])
                ->whereNotIn('orders.active_status', [1])
                ->orderBy('orders.created_at', 'desc');
            $this->applyCityFilter($olQuery, $cityId);
            $this->applyCustomFilter($olQuery, $customFilter);
            $this->applyStoreSellerFilter($olQuery, $storeId, $sellerId);
            $orders = $olQuery->get();

            $statusMap = [
                1 => 'Payment Pending', 2 => 'Received', 3 => 'Processed',
                5 => 'Out for Delivery', 6 => 'Delivered', 7 => 'Cancelled',
                8 => 'Returned', 12 => 'Pre-order Pending',
            ];

            $sheet = $spreadsheet->createSheet();
            $sheet->setTitle('Orders');

            $sheet->setCellValue('A1', 'Orders List (' . $dateLabel . ')' . $zoneLabel);
            $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);

            $headers = ['#', 'Order ID', 'Date', 'Status', 'Payment Method', 'Order Type',
                'Items MRP', 'Discount', 'Delivery Charge', 'Delivery Tip',
                'Promo Code', 'Promo Discount', 'Wallet Used', 'Total Paid'];
            $col = 'A';
            foreach ($headers as $header) {
                $sheet->setCellValue($col . '3', $header);
                $col++;
            }
            $sheet->getStyle('A3:N3')->applyFromArray($headerStyle);

            $row = 4;
            $index = 1;
            foreach ($orders as $order) {
                $meta = $order->cart_metadata;
                $bs = ($meta && isset($meta['billing_summary'])) ? $meta['billing_summary'] : null;

                $sheet->setCellValue('A' . $row, $index);
                $sheet->setCellValue('B' . $row, $order->order_number);
                $sheet->setCellValue('C' . $row, Carbon::parse($order->created_at)->format('d M Y h:i A'));
                $sheet->setCellValue('D' . $row, $statusMap[$order->active_status] ?? $order->active_status);
                $sheet->setCellValue('E' . $row, ucwords(str_replace('_', ' ', $order->payment_method ?? '-')));
                $sheet->setCellValue('F' . $row, ucfirst($order->order_type ?? '-'));
                $sheet->setCellValue('G' . $row, $bs ? floatval($bs['items_mrp'] ?? 0) + floatval($bs['combo_mrp'] ?? 0) : floatval($order->total ?? 0));
                $sheet->setCellValue('H' . $row, $bs ? floatval($bs['discount'] ?? 0) : floatval($order->discount ?? 0));
                $sheet->setCellValue('I' . $row, $bs ? floatval($bs['delivery_charge'] ?? 0) : floatval($order->delivery_charge ?? 0));
                $sheet->setCellValue('J' . $row, $bs ? floatval($bs['delivery_tip'] ?? 0) : 0);
                $sheet->setCellValue('K' . $row, $order->promo_code ?? '-');
                $sheet->setCellValue('L' . $row, $bs ? floatval($bs['promocode_discount'] ?? 0) : floatval($order->promo_discount ?? 0));
                $sheet->setCellValue('M' . $row, $bs ? floatval($bs['wallet_deduction'] ?? 0) : floatval($order->wallet_balance ?? 0));
                $sheet->setCellValue('N' . $row, $bs ? floatval($bs['to_be_paid'] ?? 0) : floatval($order->final_total ?? 0));
                $sheet->getStyle("A{$row}:N{$row}")->applyFromArray($cellBorder);

                $row++;
                $index++;
            }

            foreach (range('A', 'N') as $c) {
                $sheet->getColumnDimension($c)->setAutoSize(true);
            }
        }

        // Sheet 3: Coupon Analytics
        if (in_array($section, ['all', 'coupons'])) {
            $couponData = $this->getCouponAnalytics($start, $end, $cityId, $customFilter, $storeId, $sellerId);

            $sheet = $spreadsheet->createSheet();
            $sheet->setTitle('Coupon Analytics');

            $sheet->setCellValue('A1', 'Coupon Analytics (' . $dateLabel . ')' . $zoneLabel);
            $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);

            // Coupon summary
            $row = 3;
            $sheet->setCellValue('A' . $row, 'Metric');
            $sheet->setCellValue('B' . $row, 'Value');
            $sheet->getStyle("A{$row}:B{$row}")->applyFromArray($headerStyle);

            $cs = $couponData['summary'];
            $couponSummaryRows = [
                ['Orders with Promo', $cs['total_orders_with_promo']],
                ['Total Orders', $cs['total_orders']],
                ['Promo Usage Rate', $cs['promo_usage_rate'] . '%'],
                ['Unique Coupons Used', $cs['unique_coupons_used']],
                ['Total Promo Discount', '₹' . number_format($cs['total_promo_discount'], 2)],
                ['Avg Discount per Order', '₹' . number_format($cs['avg_promo_discount'], 2)],
            ];

            foreach ($couponSummaryRows as $csRow) {
                $row++;
                $sheet->setCellValue('A' . $row, $csRow[0]);
                $sheet->setCellValue('B' . $row, $csRow[1]);
                $sheet->getStyle("A{$row}:B{$row}")->applyFromArray($cellBorder);
            }

            // Top coupons table
            $row += 2;
            $sheet->setCellValue('A' . $row, 'Top Coupons');
            $sheet->getStyle('A' . $row)->getFont()->setBold(true)->setSize(12);
            $row++;

            $couponHeaders = ['#', 'Promo Code', 'Type', 'Discount Value', 'Max Discount',
                'Min Order', 'Times Used', 'Total Discount Given', 'Avg Discount', 'Revenue Generated'];
            $col = 'A';
            foreach ($couponHeaders as $ch) {
                $sheet->setCellValue($col . $row, $ch);
                $col++;
            }
            $sheet->getStyle("A{$row}:J{$row}")->applyFromArray($headerStyle);

            $ci = 1;
            foreach ($couponData['top_coupons'] as $coupon) {
                $row++;
                $sheet->setCellValue('A' . $row, $ci);
                $sheet->setCellValue('B' . $row, $coupon['promo_code']);
                $sheet->setCellValue('C' . $row, $coupon['discount_type']);
                $sheet->setCellValue('D' . $row, $coupon['discount_type'] === 'percentage' ? $coupon['discount_value'] . '%' : '₹' . $coupon['discount_value']);
                $sheet->setCellValue('E' . $row, '₹' . number_format($coupon['max_discount_amount'], 2));
                $sheet->setCellValue('F' . $row, '₹' . number_format($coupon['min_order_amount'], 2));
                $sheet->setCellValue('G' . $row, $coupon['usage_count']);
                $sheet->setCellValue('H' . $row, '₹' . number_format($coupon['total_discount_given'], 2));
                $sheet->setCellValue('I' . $row, '₹' . number_format($coupon['avg_discount'], 2));
                $sheet->setCellValue('J' . $row, '₹' . number_format($coupon['total_revenue'], 2));
                $sheet->getStyle("A{$row}:J{$row}")->applyFromArray($cellBorder);
                $ci++;
            }

            foreach (range('A', 'J') as $c) {
                $sheet->getColumnDimension($c)->setAutoSize(true);
            }
        }

        $spreadsheet->setActiveSheetIndex(0);

        $filename = 'order_analytics_' . $start->format('Ymd') . '_' . $end->format('Ymd') . '.xlsx';

        return response()->stream(function () use ($spreadsheet) {
            $writer = new XlsxWriter($spreadsheet);
            $writer->save('php://output');
        }, 200, [
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'Content-Disposition' => 'attachment; filename="' . $filename . '"',
            'Cache-Control' => 'max-age=0',
        ]);
    }

    /**
     * Export analytics data as PDF.
     */
    public function exportPdf(Request $request)
    {
        [$filter, $start, $end] = $this->parseDateRange($request);
        $section = $request->get('section', 'all');
        $cityId = $request->get('city_id');
        $customFilter = $request->get('custom_filter');
        $storeId = $request->get('store_id');
        $sellerId = $request->get('seller_id');
        $cityName = $this->getCityName($cityId);
        $zoneLabel = $cityName ? ' | Zone: ' . $cityName : '';

        $dateLabel = $start->format('d M Y') . ' - ' . $end->format('d M Y');
        $summary = $this->getSummaryCards($start, $end, $cityId, $customFilter, $storeId, $sellerId);
        $revenueBreakdown = $this->getRevenueBreakdown($start, $end, $cityId, $customFilter, $storeId, $sellerId);
        $statusBreakdown = $this->getStatusBreakdown($start, $end, $cityId, $customFilter, $storeId, $sellerId);
        $paymentMethodSplit = $this->getPaymentMethodSplit($start, $end, $cityId, $customFilter, $storeId, $sellerId);
        $orderTypeSplit = $this->getOrderTypeSplit($start, $end, $cityId, $customFilter, $storeId, $sellerId);
        $couponData = $this->getCouponAnalytics($start, $end, $cityId, $customFilter, $storeId, $sellerId);

        $html = '<style>
            body { font-family: sans-serif; font-size: 12px; color: #333; }
            h1 { color: #4CAF50; font-size: 20px; margin-bottom: 5px; }
            h2 { color: #333; font-size: 15px; margin-top: 20px; border-bottom: 2px solid #4CAF50; padding-bottom: 4px; }
            .subtitle { color: #777; font-size: 12px; margin-bottom: 15px; }
            table { width: 100%; border-collapse: collapse; margin-bottom: 15px; }
            th { background-color: #4CAF50; color: white; padding: 8px 6px; text-align: left; font-size: 11px; }
            td { padding: 6px; border-bottom: 1px solid #ddd; font-size: 11px; }
            tr:nth-child(even) { background-color: #f9f9f9; }
            .text-right { text-align: right; }
            .text-center { text-align: center; }
            .bold { font-weight: bold; }
            .text-danger { color: #FF4560; }
            .text-success { color: #4CAF50; }
            .summary-grid { width: 100%; }
            .summary-grid td { border: 1px solid #ddd; padding: 10px; text-align: center; width: 25%; }
            .summary-grid .label { font-size: 10px; color: #777; text-transform: uppercase; }
            .summary-grid .value { font-size: 16px; font-weight: bold; color: #333; margin-top: 4px; }
        </style>';

        // Logo + Title header
        $logoPath = public_path('images/logo.png');
        $html .= '<table style="width:100%; border:none; margin-bottom:10px;"><tr style="background:none;">';
        $html .= '<td style="width:50px; border:none; padding:0 10px 0 0; vertical-align:middle;">';
        $html .= '<img src="' . $logoPath . '" width="45" height="45" />';
        $html .= '</td>';
        $html .= '<td style="border:none; padding:0; vertical-align:middle;">';
        $html .= '<h1 style="margin:0;">Order Analytics Report</h1>';
        $html .= '<div class="subtitle" style="margin:2px 0 0 0;">Period: ' . $dateLabel . ' (' . ucfirst($filter) . ')' . $zoneLabel . '</div>';
        $html .= '</td>';
        $html .= '</tr></table>';
        $html .= '<hr style="border:none; border-top:2px solid #4CAF50; margin:0 0 15px 0;" />';

        // Profit/Loss Comparison (only when explicitly requested from Profit/Loss page)
        if ($section === 'comparison') {
            $plc = $this->getProfitLossComparison($start, $end, $filter, $cityId, $customFilter, $storeId, $sellerId);

            $html .= '<h2>Profit / Loss Comparison</h2>';
            $html .= '<div style="font-size:11px; color:#555; margin-bottom:12px;">' . $plc['current_period'] . ' vs ' . $plc['previous_period'] . '</div>';

            // Visual bar chart (HTML/CSS) - each metric scaled to its own max
            $chartMetrics = [
                'revenue' => 'Revenue',
                'orders' => 'Orders',
                'avg_order_value' => 'Avg Order Value',
                'total_discount' => 'Total Discounts',
                'delivery_charges' => 'Delivery Charges',
                'promo_discount' => 'Promo Discount',
            ];

            $html .= '<div style="margin-bottom:20px; padding:15px; border:1px solid #e0e0e0; border-radius:6px; background:#fafafa;">';
            $html .= '<div style="font-size:13px; font-weight:bold; margin-bottom:12px;">Current vs Previous Period</div>';

            // Legend - using Unicode squares (mPDF doesn't handle div inside td well)
            $html .= '<p style="font-size:11px; margin:0 0 12px 0; color:#333;">';
            $html .= '<span style="color:#9AC444; font-size:14px;">&#9632;</span> ' . $plc['current_period'];
            $html .= ' &nbsp;&nbsp;&nbsp; ';
            $html .= '<span style="color:#546E7A; font-size:14px;">&#9632;</span> ' . $plc['previous_period'];
            $html .= '</p>';

            foreach ($chartMetrics as $key => $label) {
                $cur = $plc['metrics'][$key]['current'];
                $prev = $plc['metrics'][$key]['previous'];
                $isAmount = $key !== 'orders';
                $rowMax = max(abs($cur), abs($prev), 1);
                $curWidth = max(3, round((abs($cur) / $rowMax) * 60));
                $prevWidth = max(3, round((abs($prev) / $rowMax) * 60));
                $curLabel = $isAmount ? '₹' . number_format($cur, 2) : number_format($cur, 0);
                $prevLabel = $isAmount ? '₹' . number_format($prev, 2) : number_format($prev, 0);

                $html .= '<table style="width:100%; border:none; margin:0 0 8px 0;">';
                // Metric label row
                $html .= '<tr style="background:none;"><td colspan="2" style="border:none; padding:0 0 3px 0; font-size:10px; font-weight:bold; color:#333;">' . $label . '</td></tr>';
                // Current bar row
                $html .= '<tr style="background:none;">';
                $html .= '<td style="width:' . $curWidth . '%; border:none; padding:0; background:#9AC444; height:14px;"></td>';
                $html .= '<td style="border:none; padding:0 0 0 6px; font-size:9px; font-weight:bold; color:#333;">' . $curLabel . '</td>';
                $html .= '</tr>';
                // Previous bar row
                $html .= '<tr style="background:none;">';
                $html .= '<td style="width:' . $prevWidth . '%; border:none; padding:0; background:#546E7A; height:14px;"></td>';
                $html .= '<td style="border:none; padding:0 0 0 6px; font-size:9px; font-weight:bold; color:#666;">' . $prevLabel . '</td>';
                $html .= '</tr>';
                $html .= '</table>';
            }
            $html .= '</div>';

            // Detailed comparison table
            $html .= '<table><tr><th>Metric</th><th class="text-right">Current</th><th class="text-right">Previous</th><th class="text-right">Change</th><th class="text-right">%</th><th class="text-center">Status</th></tr>';

            $metricLabels = [
                'revenue' => 'Revenue',
                'orders' => 'Total Orders',
                'avg_order_value' => 'Avg Order Value',
                'total_discount' => 'Total Discounts',
                'delivery_charges' => 'Delivery Charges',
                'promo_discount' => 'Promo Discount',
            ];

            foreach ($metricLabels as $key => $label) {
                $m = $plc['metrics'][$key];
                $isAmount = $key !== 'orders';
                $color = $m['is_favorable'] ? '#4CAF50' : '#FF4560';
                $arrow = $m['is_favorable'] ? '&#9650;' : '&#9660;';

                $html .= '<tr>';
                $html .= '<td class="bold">' . $label . '</td>';
                $html .= '<td class="text-right">' . ($isAmount ? '₹' . number_format($m['current'], 2) : $m['current']) . '</td>';
                $html .= '<td class="text-right">' . ($isAmount ? '₹' . number_format($m['previous'], 2) : $m['previous']) . '</td>';
                $html .= '<td class="text-right bold" style="color:' . $color . '">' . ($m['change'] >= 0 ? '+' : '') . ($isAmount ? '₹' . number_format($m['change'], 2) : $m['change']) . '</td>';
                $html .= '<td class="text-right bold" style="color:' . $color . '">' . ($m['change_percent'] >= 0 ? '+' : '') . $m['change_percent'] . '%</td>';
                $html .= '<td class="text-center bold" style="color:' . $color . '">' . $arrow . '</td>';
                $html .= '</tr>';
            }
            $html .= '</table>';
        }

        // Summary cards
        if (in_array($section, ['all', 'summary'])) {
            $html .= '<h2>Summary</h2>';
            $html .= '<table class="summary-grid"><tr>';
            $cards = [
                ['Total Orders', $summary['total_orders'], ''],
                ['Total Revenue', $summary['total_revenue'], '₹'],
                ['Avg Order Value', $summary['avg_order_value'], '₹'],
                ['Total MRP', $summary['total_mrp'], '₹'],
            ];
            foreach ($cards as $card) {
                $html .= '<td><div class="label">' . $card[0] . '</div><div class="value">' . $card[2] . number_format($card[1], $card[2] ? 2 : 0) . '</div></td>';
            }
            $html .= '</tr><tr>';
            $cards2 = [
                ['Delivery Charges', $summary['total_delivery_charge'], '₹'],
                ['Delivery Tips', $summary['total_delivery_tips'], '₹'],
                ['Promo Discounts', $summary['total_promo_discount'], '₹'],
            ];
            foreach ($cards2 as $card) {
                $html .= '<td><div class="label">' . $card[0] . '</div><div class="value">' . $card[2] . number_format($card[1], 2) . '</div></td>';
            }
            $html .= '</tr></table>';

            // Revenue breakdown table
            $html .= '<h2>Revenue Breakdown</h2>';
            $html .= '<table><tr><th>Component</th><th class="text-right">Amount</th></tr>';
            $breakdownItems = [
                ['Items MRP', $revenueBreakdown['items_mrp'], false],
                ['Combo MRP', $revenueBreakdown['combo_mrp'], false],
                ['Discount', $revenueBreakdown['discount'], true],
                ['Promo Discount', $revenueBreakdown['promo_discount'], true],
                ['Wallet Deduction', $revenueBreakdown['wallet_deduction'], true],
                ['Delivery Charge', $revenueBreakdown['delivery_charge'], false],
                ['Delivery Tip', $revenueBreakdown['delivery_tip'], false],
                ['Rain Surcharge', $revenueBreakdown['rain_surcharge'], false],
                ['Multi Order Charges', $revenueBreakdown['multi_order_charges'], false],
                ['GST Charges', $revenueBreakdown['gst_charges'], false],
                ['Net Revenue (To Be Paid)', $revenueBreakdown['to_be_paid'], false],
            ];
            foreach ($breakdownItems as $item) {
                $class = $item[2] ? 'text-danger' : 'text-success';
                $prefix = $item[2] ? '(-) ' : '';
                $html .= '<tr><td>' . $prefix . $item[0] . '</td><td class="text-right bold ' . $class . '">₹' . number_format($item[1], 2) . '</td></tr>';
            }
            $html .= '</table>';

            // Status breakdown
            $html .= '<h2>Order Status Breakdown</h2>';
            $html .= '<table><tr><th>Status</th><th class="text-right">Count</th></tr>';
            foreach ($statusBreakdown['labels'] as $i => $label) {
                $html .= '<tr><td>' . $label . '</td><td class="text-right bold">' . $statusBreakdown['values'][$i] . '</td></tr>';
            }
            $html .= '</table>';

            // Payment methods
            $html .= '<h2>Payment Methods</h2>';
            $html .= '<table><tr><th>Method</th><th class="text-right">Count</th></tr>';
            foreach ($paymentMethodSplit['labels'] as $i => $label) {
                $html .= '<tr><td>' . $label . '</td><td class="text-right bold">' . $paymentMethodSplit['values'][$i] . '</td></tr>';
            }
            $html .= '</table>';

        }

        // Coupon analytics
        if (in_array($section, ['all', 'coupons'])) {
            $cs = $couponData['summary'];
            $html .= '<h2>Coupon / Promo Analytics</h2>';
            $html .= '<table><tr><th>Metric</th><th class="text-right">Value</th></tr>';
            $html .= '<tr><td>Orders with Promo</td><td class="text-right bold">' . $cs['total_orders_with_promo'] . '</td></tr>';
            $html .= '<tr><td>Promo Usage Rate</td><td class="text-right bold">' . $cs['promo_usage_rate'] . '%</td></tr>';
            $html .= '<tr><td>Unique Coupons Used</td><td class="text-right bold">' . $cs['unique_coupons_used'] . '</td></tr>';
            $html .= '<tr><td>Total Promo Discount</td><td class="text-right bold text-danger">₹' . number_format($cs['total_promo_discount'], 2) . '</td></tr>';
            $html .= '<tr><td>Avg Discount/Order</td><td class="text-right bold">₹' . number_format($cs['avg_promo_discount'], 2) . '</td></tr>';
            $html .= '</table>';

            if (!empty($couponData['top_coupons'])) {
                $html .= '<h2>Top Coupons</h2>';
                $html .= '<table><tr><th>#</th><th>Code</th><th>Type</th><th class="text-right">Value</th><th class="text-center">Used</th><th class="text-right">Discount Given</th><th class="text-right">Revenue</th></tr>';
                $ci = 1;
                foreach ($couponData['top_coupons'] as $coupon) {
                    $discVal = $coupon['discount_type'] === 'percentage' ? $coupon['discount_value'] . '%' : '₹' . $coupon['discount_value'];
                    $html .= '<tr>';
                    $html .= '<td>' . $ci . '</td>';
                    $html .= '<td class="bold">' . $coupon['promo_code'] . '</td>';
                    $html .= '<td>' . $coupon['discount_type'] . '</td>';
                    $html .= '<td class="text-right">' . $discVal . '</td>';
                    $html .= '<td class="text-center bold">' . $coupon['usage_count'] . '</td>';
                    $html .= '<td class="text-right text-danger bold">₹' . number_format($coupon['total_discount_given'], 2) . '</td>';
                    $html .= '<td class="text-right text-success bold">₹' . number_format($coupon['total_revenue'], 2) . '</td>';
                    $html .= '</tr>';
                    $ci++;
                }
                $html .= '</table>';
            }
        }

        // Orders list
        if (in_array($section, ['all', 'orders'])) {
            $pdfOlQuery = Order::whereBetween('orders.created_at', [$start, $end])
                ->whereNotIn('orders.active_status', [1])
                ->orderBy('orders.created_at', 'desc');
            $this->applyCityFilter($pdfOlQuery, $cityId);
            $this->applyCustomFilter($pdfOlQuery, $customFilter);
            $this->applyStoreSellerFilter($pdfOlQuery, $storeId, $sellerId);
            $orders = $pdfOlQuery->get();

            $statusMap = [
                1 => 'Payment Pending', 2 => 'Received', 3 => 'Processed',
                5 => 'Out for Delivery', 6 => 'Delivered', 7 => 'Cancelled',
                8 => 'Returned', 12 => 'Pre-order Pending',
            ];

            if ($section === 'all') {
                $html .= '<pagebreak />';
            }
            $html .= '<h2>Orders List</h2>';
            $html .= '<table><tr><th>#</th><th>Order ID</th><th>Date</th><th>Status</th><th>Payment</th><th class="text-right">MRP</th><th class="text-right">Discount</th><th class="text-right">Paid</th></tr>';

            $ci = 1;
            foreach ($orders as $order) {
                $meta = $order->cart_metadata;
                $bs = ($meta && isset($meta['billing_summary'])) ? $meta['billing_summary'] : null;
                $mrp = $bs ? floatval($bs['items_mrp'] ?? 0) + floatval($bs['combo_mrp'] ?? 0) : floatval($order->total ?? 0);
                $discount = $bs ? floatval($bs['discount'] ?? 0) + floatval($bs['promocode_discount'] ?? 0) : floatval($order->discount ?? 0) + floatval($order->promo_discount ?? 0);
                $paid = $bs ? floatval($bs['to_be_paid'] ?? 0) : floatval($order->final_total ?? 0);

                $html .= '<tr>';
                $html .= '<td>' . $ci . '</td>';
                $html .= '<td>' . ($order->order_number) . '</td>';
                $html .= '<td>' . Carbon::parse($order->created_at)->format('d M Y') . '</td>';
                $html .= '<td>' . ($statusMap[$order->active_status] ?? $order->active_status) . '</td>';
                $html .= '<td>' . ucwords(str_replace('_', ' ', $order->payment_method ?? '-')) . '</td>';
                $html .= '<td class="text-right">₹' . number_format($mrp, 2) . '</td>';
                $html .= '<td class="text-right text-danger">₹' . number_format($discount, 2) . '</td>';
                $html .= '<td class="text-right bold text-success">₹' . number_format($paid, 2) . '</td>';
                $html .= '</tr>';
                $ci++;
            }
            $html .= '</table>';
        }

        $mpdf = new Mpdf([
            'margin_top' => 15,
            'margin_bottom' => 15,
            'margin_left' => 12,
            'margin_right' => 12,
            'default_font' => 'sans-serif',
        ]);
        $mpdf->SetTitle('Order Analytics Report');
        $mpdf->SetAuthor('Zenfoo Admin');
        $mpdf->WriteHTML($html);

        $filename = 'order_analytics_' . $start->format('Ymd') . '_' . $end->format('Ymd') . '.pdf';

        return response($mpdf->Output($filename, Destination::STRING_RETURN), 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="' . $filename . '"',
        ]);
    }
}
