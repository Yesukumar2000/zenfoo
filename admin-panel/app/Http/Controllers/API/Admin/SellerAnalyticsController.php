<?php

namespace App\Http\Controllers\API\Admin;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\City;
use App\Models\Order;
use App\Models\Product;
use App\Models\Seller;
use App\Models\SellerWalletTransaction;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx as XlsxWriter;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use Mpdf\Mpdf;
use Mpdf\Output\Destination;

class SellerAnalyticsController extends Controller
{
    /**
     * Get seller analytics data.
     */
    public function getAnalytics(Request $request, $sellerId)
    {
        $filter = $request->get('filter', 'monthly');
        $startDate = $request->get('start_date');
        $endDate = $request->get('end_date');

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
                $start = Carbon::now()->startOfMonth();
                $end = Carbon::now()->endOfMonth();
        }

        // Get seller info
        $seller = Seller::with('store')->find($sellerId);
        if (!$seller) {
            return CommonHelper::responseError('Seller not found');
        }

        // Summary metrics
        $summary = $this->getSummary($sellerId, $start, $end);

        // Orders over time
        $ordersOverTime = $this->getOrdersOverTime($sellerId, $start, $end, $filter);

        // Revenue over time
        $revenueOverTime = $this->getRevenueOverTime($sellerId, $start, $end, $filter);

        // Order status breakdown
        $statusBreakdown = $this->getStatusBreakdown($sellerId, $start, $end);

        // Payment methods
        $paymentMethods = $this->getPaymentMethods($sellerId, $start, $end);

        // Top products
        $topProducts = $this->getTopProducts($sellerId, $start, $end);

        // Order type split
        $orderTypeSplit = $this->getOrderTypeSplit($sellerId, $start, $end);

        // Monthly comparison
        $monthlyComparison = $this->getMonthlyComparison($sellerId, $start, $end, $filter);

        // Recent orders
        $recentOrders = $this->getRecentOrders($sellerId, $start, $end);

        $data = [
            'filter' => $filter,
            'start_date' => $start->toDateString(),
            'end_date' => $end->toDateString(),
            'seller' => [
                'id' => $seller->id,
                'name' => $seller->name,
                'store_name' => $seller->store ? $seller->store->name : null,
            ],
            'summary' => $summary,
            'orders_over_time' => $ordersOverTime,
            'revenue_over_time' => $revenueOverTime,
            'status_breakdown' => $statusBreakdown,
            'payment_methods' => $paymentMethods,
            'top_products' => $topProducts,
            'order_type_split' => $orderTypeSplit,
            'monthly_comparison' => $monthlyComparison,
            'recent_orders' => $recentOrders,
        ];

        return CommonHelper::responseWithData($data);
    }

    /**
     * Get all sellers analytics data with zone filtering.
     */
    public function getAllSellersAnalytics(Request $request)
    {
        Log::info('======================================');
        Log::info('ALL SELLERS ANALYTICS API REQUEST');
        Log::info('======================================');
        Log::info('Request Parameters:', $request->all());

        $filter = $request->get('filter', 'monthly');
        $startDate = $request->get('start_date');
        $endDate = $request->get('end_date');
        $cityId = $request->get('city_id');

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
                $start = Carbon::now()->startOfMonth();
                $end = Carbon::now()->endOfMonth();
        }

        Log::info('Date Range:', [
            'start' => $start->toDateTimeString(),
            'end' => $end->toDateTimeString(),
            'city_id' => $cityId
        ]);

        // Summary metrics for all sellers
        $summary = $this->getAllSellersSummary($start, $end, $cityId);

        // Top sellers by revenue
        $topSellersByRevenue = $this->getTopSellersByRevenue($start, $end, $cityId);

        // Top sellers by orders
        $topSellersByOrders = $this->getTopSellersByOrders($start, $end, $cityId);

        // Sellers by zone
        $sellersByZone = $this->getSellersByZone($cityId);

        // Revenue trend over time (all sellers)
        $revenueTrend = $this->getAllSellersRevenueTrend($start, $end, $filter, $cityId);

        // Orders trend over time (all sellers)
        $ordersTrend = $this->getAllSellersOrdersTrend($start, $end, $filter, $cityId);

        // Payment methods distribution
        $paymentMethodsDistribution = $this->getAllSellersPaymentMethods($start, $end, $cityId);

        // Active vs inactive sellers
        $sellerActivity = $this->getSellerActivity($start, $end, $cityId);

        $data = [
            'filter' => $filter,
            'start_date' => $start->toDateString(),
            'end_date' => $end->toDateString(),
            'summary' => $summary,
            'top_sellers_by_revenue' => $topSellersByRevenue,
            'top_sellers_by_orders' => $topSellersByOrders,
            'sellers_by_zone' => $sellersByZone,
            'revenue_trend' => $revenueTrend,
            'orders_trend' => $ordersTrend,
            'payment_methods' => $paymentMethodsDistribution,
            'seller_activity' => $sellerActivity,
        ];

        Log::info('======================================');
        Log::info('ALL SELLERS ANALYTICS RESPONSE SUMMARY');
        Log::info('======================================');
        Log::info('Response Summary:', [
            'total_sellers' => $summary['total_sellers'] ?? 0,
            'active_sellers' => $summary['active_sellers'] ?? 0,
            'total_revenue' => $summary['total_revenue'] ?? 0,
            'total_orders' => $summary['total_orders'] ?? 0,
        ]);
        Log::info('======================================');

        return CommonHelper::responseWithData($data);
    }

    private function getAllSellersSummary(Carbon $start, Carbon $end, ?string $cityId = null)
    {
        Log::info('=== getAllSellersSummary START ===');

        // Total sellers
        $totalSellersQuery = Seller::select(DB::raw('COUNT(DISTINCT sellers.id) as total'))
            ->where('sellers.status', 1);

        if ($cityId) {
            $totalSellersQuery->where('sellers.city_id', $cityId);
        }

        Log::info('Total Sellers Query SQL:', [
            'sql' => $totalSellersQuery->toSql(),
            'bindings' => $totalSellersQuery->getBindings()
        ]);

        $totalSellers = $totalSellersQuery->value('total') ?? 0;
        Log::info('Total Sellers Result:', ['count' => $totalSellers]);

        // Active sellers (who had orders in period)
        $activeQuery = Seller::select(DB::raw('COUNT(DISTINCT sellers.id) as total'))
            ->join('order_items', 'sellers.id', '=', 'order_items.seller_id')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->where('sellers.status', 1)
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $activeQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        Log::info('Active Sellers Query SQL:', [
            'sql' => $activeQuery->toSql(),
            'bindings' => $activeQuery->getBindings()
        ]);

        $activeSellers = $activeQuery->value('total') ?? 0;
        Log::info('Active Sellers Result:', ['count' => $activeSellers]);

        // Total orders and revenue
        $ordersQuery = Order::select(
                DB::raw('COUNT(DISTINCT orders.id) as total_orders'),
                DB::raw('COALESCE(SUM(orders.final_total), 0) as total_revenue')
            )
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $ordersQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $ordersData = $ordersQuery->first();
        $totalOrders = $ordersData->total_orders ?? 0;
        $totalRevenue = floatval($ordersData->total_revenue ?? 0);

        Log::info('Orders Data Result:', [
            'total_orders' => $totalOrders,
            'total_revenue' => $totalRevenue
        ]);

        $avgRevenuePerSeller = $activeSellers > 0 ? round($totalRevenue / $activeSellers, 2) : 0;
        $avgOrdersPerSeller = $activeSellers > 0 ? round($totalOrders / $activeSellers, 2) : 0;

        $result = [
            'total_sellers' => $totalSellers,
            'active_sellers' => $activeSellers,
            'inactive_sellers' => max(0, $totalSellers - $activeSellers),
            'total_orders' => $totalOrders,
            'total_revenue' => round($totalRevenue, 2),
            'avg_revenue_per_seller' => $avgRevenuePerSeller,
            'avg_orders_per_seller' => $avgOrdersPerSeller,
        ];

        Log::info('getAllSellersSummary Final Result:', $result);
        Log::info('=== getAllSellersSummary END ===');

        return $result;
    }

    private function getTopSellersByRevenue(Carbon $start, Carbon $end, ?string $cityId = null, int $limit = 10)
    {
        $query = Seller::select(
                'sellers.id',
                'sellers.name',
                'stores.name as store_name',
                DB::raw('COUNT(DISTINCT orders.id) as order_count'),
                DB::raw('COALESCE(SUM(orders.final_total), 0) as total_revenue')
            )
            ->join('order_items', 'sellers.id', '=', 'order_items.seller_id')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->leftJoin('stores', 'sellers.store_id', '=', 'stores.id')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $query->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $sellers = $query->groupBy('sellers.id', 'sellers.name', 'stores.name')
            ->orderByDesc('total_revenue')
            ->limit($limit)
            ->get();

        $result = [];
        foreach ($sellers as $seller) {
            $result[] = [
                'seller_id' => $seller->id,
                'seller_name' => $seller->name,
                'store_name' => $seller->store_name ?? '-',
                'order_count' => $seller->order_count,
                'total_revenue' => round($seller->total_revenue, 2),
            ];
        }

        return $result;
    }

    private function getTopSellersByOrders(Carbon $start, Carbon $end, ?string $cityId = null, int $limit = 10)
    {
        $query = Seller::select(
                'sellers.id',
                'sellers.name',
                DB::raw('COUNT(DISTINCT orders.id) as order_count'),
                DB::raw('COALESCE(SUM(orders.final_total), 0) as total_revenue')
            )
            ->join('order_items', 'sellers.id', '=', 'order_items.seller_id')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $query->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $sellers = $query->groupBy('sellers.id', 'sellers.name')
            ->orderByDesc('order_count')
            ->limit($limit)
            ->get();

        $result = [];
        foreach ($sellers as $seller) {
            $result[] = [
                'seller_id' => $seller->id,
                'seller_name' => $seller->name,
                'order_count' => $seller->order_count,
                'total_revenue' => round($seller->total_revenue, 2),
            ];
        }

        return $result;
    }

    private function getSellersByZone(?string $cityId = null)
    {
        Log::info('=== getSellersByZone START ===', ['city_id' => $cityId]);

        $query = Seller::select('sellers.city_id', DB::raw('COUNT(DISTINCT sellers.id) as seller_count'))
            ->where('sellers.status', 1)
            ->whereNotNull('sellers.city_id');

        if ($cityId) {
            $query->where('sellers.city_id', $cityId);
        }

        $zones = $query->groupBy('sellers.city_id')
            ->orderByDesc('seller_count')
            ->limit(10)
            ->get();

        Log::info('getSellersByZone Raw Results:', [
            'zones_count' => $zones->count(),
            'zones_data' => $zones->toArray()
        ]);

        $labels = [];
        $values = [];

        foreach ($zones as $zone) {
            $city = City::find($zone->city_id);
            if ($city) {
                $labels[] = $city->name;
                $values[] = $zone->seller_count;
            }
        }

        Log::info('=== getSellersByZone END ===', [
            'labels' => $labels,
            'values' => $values
        ]);

        return [
            'labels' => $labels,
            'values' => $values,
        ];
    }

    private function getAllSellersRevenueTrend(Carbon $start, Carbon $end, string $filter, ?string $cityId = null)
    {
        $ordersQuery = Order::select('orders.created_at', 'orders.final_total')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $ordersQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $orders = $ordersQuery->get();

        $grouped = [];
        foreach ($orders as $order) {
            $key = $this->getDateKey($order->created_at, $filter, $start, $end);
            if (!isset($grouped[$key])) {
                $grouped[$key] = 0;
            }
            $grouped[$key] += floatval($order->final_total);
        }

        ksort($grouped);

        return [
            'labels' => array_keys($grouped),
            'values' => array_map(fn($v) => round($v, 2), array_values($grouped)),
        ];
    }

    private function getAllSellersOrdersTrend(Carbon $start, Carbon $end, string $filter, ?string $cityId = null)
    {
        $ordersQuery = Order::select('orders.created_at')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $ordersQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $orders = $ordersQuery->get();

        $grouped = [];
        foreach ($orders as $order) {
            $key = $this->getDateKey($order->created_at, $filter, $start, $end);
            if (!isset($grouped[$key])) {
                $grouped[$key] = 0;
            }
            $grouped[$key]++;
        }

        ksort($grouped);

        return [
            'labels' => array_keys($grouped),
            'values' => array_values($grouped),
        ];
    }

    private function getAllSellersPaymentMethods(Carbon $start, Carbon $end, ?string $cityId = null)
    {
        $query = Order::select('orders.payment_method', DB::raw('COUNT(DISTINCT orders.id) as count'))
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $query->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $methods = $query->groupBy('orders.payment_method')->get();

        $labels = [];
        $values = [];

        foreach ($methods as $method) {
            $labels[] = ucwords(str_replace('_', ' ', $method->payment_method));
            $values[] = $method->count;
        }

        return [
            'labels' => $labels,
            'values' => $values,
        ];
    }

    private function getSellerActivity(Carbon $start, Carbon $end, ?string $cityId = null)
    {
        // Active sellers
        $activeQuery = Seller::select(DB::raw('COUNT(DISTINCT sellers.id) as total'))
            ->join('order_items', 'sellers.id', '=', 'order_items.seller_id')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->where('sellers.status', 1)
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $activeQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $activeSellers = $activeQuery->value('total') ?? 0;

        // Total sellers
        $totalQuery = Seller::select(DB::raw('COUNT(DISTINCT sellers.id) as total'))
            ->where('sellers.status', 1)
            ->where('sellers.created_at', '<=', $end);

        if ($cityId) {
            $totalQuery->where('sellers.city_id', $cityId);
        }

        $totalSellers = $totalQuery->value('total') ?? 0;
        $inactiveSellers = max(0, $totalSellers - $activeSellers);

        return [
            'labels' => ['Active Sellers', 'Inactive Sellers'],
            'values' => [$activeSellers, $inactiveSellers],
        ];
    }

    /**
     * Get summary metrics.
     */
    private function getSummary($sellerId, Carbon $start, Carbon $end)
    {
        // Orders in period
        $ordersQuery = Order::where('seller_id', $sellerId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1]);

        $totalOrders = $ordersQuery->count();
        $totalRevenue = floatval($ordersQuery->sum('final_total'));
        $avgOrderValue = $totalOrders > 0 ? $totalRevenue / $totalOrders : 0;

        // Lifetime stats
        $lifetimeOrders = Order::where('seller_id', $sellerId)
            ->whereNotIn('active_status', [1])
            ->count();

        $lifetimeRevenue = floatval(Order::where('seller_id', $sellerId)
            ->whereNotIn('active_status', [1])
            ->sum('final_total'));

        // Product stats
        $totalProducts = Product::where('seller_id', $sellerId)->count();
        $activeProducts = Product::where('seller_id', $sellerId)
            ->where('status', 1)
            ->count();

        // Ratings
        $avgRating = DB::table('order_ratings')
            ->join('orders', 'order_ratings.order_id', '=', 'orders.id')
            ->where('orders.seller_id', $sellerId)
            ->avg('order_ratings.seller_rating');

        $totalReviews = DB::table('order_ratings')
            ->join('orders', 'order_ratings.order_id', '=', 'orders.id')
            ->where('orders.seller_id', $sellerId)
            ->whereNotNull('order_ratings.seller_rating')
            ->count();

        // Commission (approximate - based on final_total)
        $seller = Seller::with('store')->find($sellerId);
        $commissionRate = $seller && $seller->store ? ($seller->store->commission_rate ?? 0) : 0;
        $commissionEarned = $totalRevenue * ($commissionRate / 100);

        return [
            'total_orders' => $totalOrders,
            'total_revenue' => round($totalRevenue, 2),
            'avg_order_value' => round($avgOrderValue, 2),
            'lifetime_orders' => $lifetimeOrders,
            'lifetime_revenue' => round($lifetimeRevenue, 2),
            'total_products' => $totalProducts,
            'active_products' => $activeProducts,
            'avg_rating' => round($avgRating ?? 0, 2),
            'total_reviews' => $totalReviews,
            'commission_earned' => round($commissionEarned, 2),
        ];
    }

    /**
     * Get orders over time.
     */
    private function getOrdersOverTime($sellerId, Carbon $start, Carbon $end, string $filter)
    {
        $orders = Order::select('created_at')
            ->where('seller_id', $sellerId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1])
            ->get();

        $grouped = [];
        foreach ($orders as $order) {
            $key = $this->getDateKey($order->created_at, $filter, $start, $end);
            if (!isset($grouped[$key])) {
                $grouped[$key] = 0;
            }
            $grouped[$key]++;
        }

        ksort($grouped);

        return [
            'labels' => array_keys($grouped),
            'values' => array_values($grouped),
        ];
    }

    /**
     * Get revenue over time.
     */
    private function getRevenueOverTime($sellerId, Carbon $start, Carbon $end, string $filter)
    {
        $orders = Order::select('created_at', 'final_total')
            ->where('seller_id', $sellerId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1])
            ->get();

        $grouped = [];
        foreach ($orders as $order) {
            $key = $this->getDateKey($order->created_at, $filter, $start, $end);
            if (!isset($grouped[$key])) {
                $grouped[$key] = 0;
            }
            $grouped[$key] += floatval($order->final_total);
        }

        ksort($grouped);

        return [
            'labels' => array_keys($grouped),
            'values' => array_map(fn($v) => round($v, 2), array_values($grouped)),
        ];
    }

    /**
     * Get status breakdown.
     */
    private function getStatusBreakdown($sellerId, Carbon $start, Carbon $end)
    {
        $statusMap = [
            2 => 'Received',
            3 => 'Processed',
            5 => 'Out for Delivery',
            6 => 'Delivered',
            7 => 'Cancelled',
            8 => 'Returned',
        ];

        $counts = Order::select('active_status', DB::raw('COUNT(*) as count'))
            ->where('seller_id', $sellerId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1])
            ->groupBy('active_status')
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
     * Get payment methods.
     */
    private function getPaymentMethods($sellerId, Carbon $start, Carbon $end)
    {
        $methods = Order::select('payment_method', DB::raw('COUNT(*) as count'))
            ->where('seller_id', $sellerId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1])
            ->groupBy('payment_method')
            ->get();

        $labels = [];
        $values = [];

        foreach ($methods as $method) {
            $labels[] = ucwords(str_replace('_', ' ', $method->payment_method));
            $values[] = $method->count;
        }

        return [
            'labels' => $labels,
            'values' => $values,
        ];
    }

    /**
     * Get top products.
     */
    private function getTopProducts($sellerId, Carbon $start, Carbon $end, int $limit = 10)
    {
        // Get top products by order count
        $topByOrders = DB::table('order_items')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->join('products', 'order_items.product_id', '=', 'products.id')
            ->select(
                'products.id',
                'products.name',
                DB::raw('COUNT(DISTINCT orders.id) as order_count'),
                DB::raw('SUM(order_items.quantity) as total_quantity'),
                DB::raw('SUM(order_items.price * order_items.quantity) as total_revenue')
            )
            ->where('orders.seller_id', $sellerId)
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->groupBy('products.id', 'products.name')
            ->orderByDesc('order_count')
            ->limit($limit)
            ->get();

        // Get top products by revenue
        $topByRevenue = DB::table('order_items')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->join('products', 'order_items.product_id', '=', 'products.id')
            ->select(
                'products.id',
                'products.name',
                DB::raw('SUM(order_items.price * order_items.quantity) as total_revenue'),
                DB::raw('SUM(order_items.quantity) as total_quantity')
            )
            ->where('orders.seller_id', $sellerId)
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->groupBy('products.id', 'products.name')
            ->orderByDesc('total_revenue')
            ->limit($limit)
            ->get();

        $byOrders = [];
        foreach ($topByOrders as $product) {
            $byOrders[] = [
                'product_id' => $product->id,
                'product_name' => $product->name,
                'order_count' => $product->order_count,
                'total_quantity' => $product->total_quantity,
                'total_revenue' => round($product->total_revenue, 2),
            ];
        }

        $byRevenue = [];
        foreach ($topByRevenue as $product) {
            $byRevenue[] = [
                'product_id' => $product->id,
                'product_name' => $product->name,
                'total_revenue' => round($product->total_revenue, 2),
                'total_quantity' => $product->total_quantity,
            ];
        }

        return [
            'by_orders' => $byOrders,
            'by_revenue' => $byRevenue,
        ];
    }

    /**
     * Get order type split.
     */
    private function getOrderTypeSplit($sellerId, Carbon $start, Carbon $end)
    {
        // Delivery type
        $deliveryType = Order::select('order_type', DB::raw('COUNT(*) as count'))
            ->where('seller_id', $sellerId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1])
            ->groupBy('order_type')
            ->get()
            ->pluck('count', 'order_type')
            ->toArray();

        // Preorder vs regular
        $preorderCount = Order::where('seller_id', $sellerId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1])
            ->where('is_preorder', 1)
            ->count();

        $regularCount = Order::where('seller_id', $sellerId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1])
            ->where(function ($q) {
                $q->where('is_preorder', 0)->orWhereNull('is_preorder');
            })
            ->count();

        return [
            'delivery_type' => [
                'labels' => array_map(fn($k) => ucfirst($k), array_keys($deliveryType)),
                'values' => array_values($deliveryType),
            ],
            'order_mode' => [
                'labels' => ['Regular', 'Pre-order'],
                'values' => [$regularCount, $preorderCount],
            ],
        ];
    }

    /**
     * Get monthly comparison.
     */
    private function getMonthlyComparison($sellerId, Carbon $start, Carbon $end, string $filter)
    {
        $diffDays = $start->diffInDays($end);

        // Calculate previous period
        $prevEnd = $start->copy()->subSecond();
        $prevStart = $prevEnd->copy()->subDays($diffDays)->startOfDay();

        $currentMetrics = $this->getComparisonMetrics($sellerId, $start, $end);
        $previousMetrics = $this->getComparisonMetrics($sellerId, $prevStart, $prevEnd);

        $metrics = ['orders', 'revenue', 'avg_order_value'];
        $comparison = [];

        foreach ($metrics as $metric) {
            $current = $currentMetrics[$metric];
            $previous = $previousMetrics[$metric];
            $change = $current - $previous;
            $changePercent = $previous > 0 ? round(($change / $previous) * 100, 1) : ($current > 0 ? 100 : 0);

            $comparison[$metric] = [
                'current' => round($current, 2),
                'previous' => round($previous, 2),
                'change' => round($change, 2),
                'change_percent' => $changePercent,
                'is_positive' => $change >= 0,
            ];
        }

        return [
            'current_period' => $this->getPeriodLabel($filter, $start, $end),
            'previous_period' => $this->getPeriodLabel($filter, $prevStart, $prevEnd),
            'metrics' => $comparison,
        ];
    }

    /**
     * Get comparison metrics.
     */
    private function getComparisonMetrics($sellerId, Carbon $start, Carbon $end)
    {
        $ordersQuery = Order::where('seller_id', $sellerId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1]);

        $totalOrders = $ordersQuery->count();
        $totalRevenue = floatval($ordersQuery->sum('final_total'));
        $avgOrderValue = $totalOrders > 0 ? $totalRevenue / $totalOrders : 0;

        return [
            'orders' => $totalOrders,
            'revenue' => $totalRevenue,
            'avg_order_value' => $avgOrderValue,
        ];
    }

    /**
     * Get recent orders.
     */
    private function getRecentOrders($sellerId, Carbon $start, Carbon $end, int $limit = 20)
    {
        $orders = Order::where('seller_id', $sellerId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1])
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get();

        $statusMap = [
            2 => 'Received', 3 => 'Processed', 5 => 'Out for Delivery',
            6 => 'Delivered', 7 => 'Cancelled', 8 => 'Returned',
        ];

        $recentOrders = [];
        foreach ($orders as $order) {
            $recentOrders[] = [
                'order_id' => $order->id,
                'unique_order_id' => $order->order_number,
                'customer_name' => $order->user ? $order->user->name : '-',
                'amount' => round($order->final_total, 2),
                'status' => $statusMap[$order->active_status] ?? 'Unknown',
                'payment_method' => ucwords(str_replace('_', ' ', $order->payment_method ?? '-')),
                'created_at' => Carbon::parse($order->created_at)->format('d M Y, h:i A'),
            ];
        }

        return $recentOrders;
    }

    /**
     * Helper: Get date key.
     */
    private function getDateKey($createdAt, string $filter, Carbon $start, Carbon $end): string
    {
        $date = Carbon::parse($createdAt);
        $diffDays = $start->diffInDays($end);

        if ($filter === 'daily') {
            return $date->format('h A');
        } elseif ($filter === 'weekly') {
            return $date->format('D, M d');
        } elseif ($filter === 'monthly') {
            return $date->format('M d');
        } else {
            if ($diffDays <= 1) {
                return $date->format('h A');
            } elseif ($diffDays <= 31) {
                return $date->format('M d');
            } else {
                return $date->format('M Y');
            }
        }
    }

    /**
     * Helper: Get period label.
     */
    private function getPeriodLabel(string $filter, Carbon $start, Carbon $end): string
    {
        switch ($filter) {
            case 'daily':
                return 'Today (' . $start->format('d M') . ')';
            case 'weekly':
                return 'This Week (' . $start->format('d M') . ' - ' . $end->format('d M') . ')';
            case 'monthly':
                return 'This Month (' . $start->format('M Y') . ')';
            default:
                return $start->format('d M Y') . ' - ' . $end->format('d M Y');
        }
    }

    /**
     * Export as Excel.
     */
    public function exportExcel(Request $request, $sellerId)
    {
        // Implementation similar to User Analytics
        return response()->json(['message' => 'Excel export not yet implemented']);
    }

    /**
     * Export as PDF.
     */
    public function exportPdf(Request $request, $sellerId)
    {
        // Implementation similar to User Analytics
        return response()->json(['message' => 'PDF export not yet implemented']);
    }

    // =====================================================================
    //  MERCHANT ANALYTICS - OVERVIEW
    // =====================================================================

    /**
     * Merchant Analytics overview dashboard (sidebar page).
     *
     * A "merchant" is a seller (sellers table); status 7 (Removed) is excluded
     * everywhere. Every figure below comes from real tables:
     *   - merchants   : sellers.status (0 Pending, 1 Active, 2 Rejected, 3 Inactive)
     *   - revenue     : order_items.quantity * order_items.discounted_price
     *                   (the same basis SellerOrderSettlementService bills on, so
     *                   revenue and commission tie out; orders.final_total is NOT
     *                   used - it double-counts once joined to order_items)
     *   - commission  : seller_wallet_transactions.admin_commission
     *                   (type = order_commission), bucketed by orders.created_at
     *                   to match the Profit & Loss page
     *   - payouts     : seller_wallet_transactions.is_paid_to_seller
     *   - type        : stores.is_food / is_meat / is_vegetable / is_super_mart
     *   - categories  : order_items -> product_variants -> products -> categories
     *
     * Known accuracy limits, surfaced to the admin via the `notes` key rather
     * than hidden: commission only exists once an order is DELIVERED (settlement
     * writes the wallet row then), so a period's commission understates until its
     * orders finish delivering, and it never backfills; Zenfoo-owned stores have
     * order_items.seller_id = NULL, earn no commission and are excluded; combo
     * orders live in order_combo_items JSON and are outside the category join.
     *
     * Returns the raw data array. The JSON endpoint and both exports all go
     * through here, so an export can never drift from what the page shows.
     */
    private function buildMerchantOverviewData(Request $request): array
    {
        [$filter, $start, $end] = $this->parseMerchantDateRange($request);
        [$prevStart, $prevEnd] = $this->getMerchantPreviousPeriod($filter, $start, $end);
        $cityId = $request->get('city_id') ?: null;

        $typeMap = $this->getMerchantTypeMap();

        $current = $this->getMerchantTotals($start, $end, $cityId);
        $previous = $this->getMerchantTotals($prevStart, $prevEnd, $cityId);
        $payouts = $this->getMerchantPendingPayouts($cityId);

        $data = [
            'filter' => $filter,
            'start_date' => $start->toDateString(),
            'end_date' => $end->toDateString(),
            'city_id' => $cityId,
            'current_period' => $this->getPeriodLabel($filter, $start, $end),
            'previous_period' => $this->getMerchantPreviousPeriodLabel($filter, $prevStart, $prevEnd),
            'summary' => $this->getMerchantSummary($current, $previous, $payouts),
            'performance_trend' => $this->getMerchantPerformanceTrend($start, $end, $filter, $cityId),
            'top_merchants' => $this->getTopMerchants($start, $end, $cityId, $typeMap),
            'commission_by_type' => $this->getMerchantCommissionByType($start, $end, $cityId, $typeMap),
            'merchants_by_status' => $this->getMerchantsByStatus($cityId),
            'revenue_by_type' => $this->getMerchantRevenueByType($start, $end, $cityId, $typeMap),
            'top_categories' => $this->getMerchantTopCategories($start, $end, $cityId),
            'payout_summary' => $this->getMerchantPayoutSummary($start, $end, $cityId, $typeMap),
            'recent_registrations' => $this->getRecentMerchantRegistrations($cityId, $typeMap),
            'notes' => [
                'Commission is recorded when an order is delivered, and is bucketed by order date. Recent periods understate until their orders complete delivery.',
                'Zenfoo-owned store items carry no merchant and are excluded from merchant revenue, commission and counts.',
                'Combo orders are not included in Top Categories by Sales.',
            ],
        ];

        $data['insights'] = $this->getMerchantInsights($data);

        return $data;
    }

    /**
     * Merchant Analytics overview dashboard (sidebar page).
     */
    public function getMerchantOverview(Request $request)
    {
        return CommonHelper::responseWithData($this->buildMerchantOverviewData($request));
    }

    /**
     * Export the merchant overview as Excel.
     */
    public function exportMerchantExcel(Request $request)
    {
        $data = $this->buildMerchantOverviewData($request);
        $section = $request->get('section', 'all');

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

        $zoneLabel = $this->getMerchantZoneLabel($data['city_id']);

        // Summary + trend
        if (in_array($section, ['all', 'summary'])) {
            $sheet = $spreadsheet->createSheet();
            $sheet->setTitle('Summary');
            $sheet->setCellValue('A1', 'Merchant Analytics' . $zoneLabel);
            $sheet->setCellValue('A2', 'Period: ' . $data['current_period'] . '  |  Compare: ' . $data['previous_period']);
            $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);

            $row = 4;
            foreach (['Metric', 'Current', 'Previous', 'Change %'] as $i => $h) {
                $sheet->setCellValue(chr(65 + $i) . $row, $h);
            }
            $sheet->getStyle("A{$row}:D{$row}")->applyFromArray($headerStyle);

            $s = $data['summary'];
            $summaryRows = [
                ['Total Merchants', $s['total_merchants']],
                ['Active Merchants', $s['active_merchants']],
                ['New Merchants', $s['new_merchants']],
                ['Merchant Revenue (₹)', $s['total_revenue']],
                ['Commission Earned (₹)', $s['total_commission']],
            ];
            foreach ($summaryRows as $sRow) {
                $row++;
                $sheet->setCellValue('A' . $row, $sRow[0]);
                $sheet->setCellValue('B' . $row, $sRow[1]['current']);
                $sheet->setCellValue('C' . $row, $sRow[1]['previous']);
                $sheet->setCellValue('D' . $row, $sRow[1]['change_percent']);
                $sheet->getStyle("A{$row}:D{$row}")->applyFromArray($cellBorder);
            }
            // Pending payouts is a running balance, so it has no comparison.
            $row++;
            $sheet->setCellValue('A' . $row, 'Pending Payouts (₹) - all time');
            $sheet->setCellValue('B' . $row, $s['pending_payouts']['current']);
            $sheet->setCellValue('C' . $row, 'across ' . $s['pending_payouts']['merchants'] . ' merchants');
            $sheet->getStyle("A{$row}:D{$row}")->applyFromArray($cellBorder);

            // Performance trend
            $row += 2;
            $sheet->setCellValue('A' . $row, 'Performance Trend');
            $sheet->getStyle('A' . $row)->getFont()->setBold(true);
            $row++;
            foreach (['Period', 'Revenue (₹)', 'Commission (₹)'] as $i => $h) {
                $sheet->setCellValue(chr(65 + $i) . $row, $h);
            }
            $sheet->getStyle("A{$row}:C{$row}")->applyFromArray($headerStyle);
            foreach ($data['performance_trend']['labels'] as $i => $label) {
                $row++;
                $sheet->setCellValue('A' . $row, $label);
                $sheet->setCellValue('B' . $row, $data['performance_trend']['revenue'][$i]);
                $sheet->setCellValue('C' . $row, $data['performance_trend']['commission'][$i]);
                $sheet->getStyle("A{$row}:C{$row}")->applyFromArray($cellBorder);
            }

            foreach (range('A', 'D') as $c) {
                $sheet->getColumnDimension($c)->setAutoSize(true);
            }
        }

        // Top merchants
        if (in_array($section, ['all', 'merchants'])) {
            $sheet = $spreadsheet->createSheet();
            $sheet->setTitle('Top Merchants');
            $sheet->setCellValue('A1', 'Top Merchants by Revenue' . $zoneLabel);
            $sheet->setCellValue('A2', 'Period: ' . $data['current_period']);
            $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);

            $headers = ['#', 'Merchant', 'Type', 'Revenue (₹)', 'Orders', 'Commission (₹)'];
            foreach ($headers as $i => $h) {
                $sheet->setCellValue(chr(65 + $i) . '4', $h);
            }
            $sheet->getStyle('A4:F4')->applyFromArray($headerStyle);

            $row = 5;
            foreach ($data['top_merchants'] as $i => $m) {
                $sheet->setCellValue('A' . $row, $i + 1);
                $sheet->setCellValue('B' . $row, $m['name']);
                $sheet->setCellValue('C' . $row, $m['type']);
                $sheet->setCellValue('D' . $row, $m['revenue']);
                $sheet->setCellValue('E' . $row, $m['orders']);
                $sheet->setCellValue('F' . $row, $m['commission']);
                $sheet->getStyle("A{$row}:F{$row}")->applyFromArray($cellBorder);
                $row++;
            }
            foreach (range('A', 'F') as $c) {
                $sheet->getColumnDimension($c)->setAutoSize(true);
            }
        }

        // Commission & payout summary
        if (in_array($section, ['all', 'payouts'])) {
            $sheet = $spreadsheet->createSheet();
            $sheet->setTitle('Commission & Payouts');
            $sheet->setCellValue('A1', 'Merchant Commission & Payout Summary' . $zoneLabel);
            $sheet->setCellValue('A2', 'Revenue/Commission: ' . $data['current_period'] . '  |  Paid/Pending: all time');
            $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);

            $headers = ['Type', 'Merchants', 'Revenue (₹)', 'Commission (₹)', 'Paid (₹)', 'Pending (₹)'];
            foreach ($headers as $i => $h) {
                $sheet->setCellValue(chr(65 + $i) . '4', $h);
            }
            $sheet->getStyle('A4:F4')->applyFromArray($headerStyle);

            $row = 5;
            foreach ($data['payout_summary']['rows'] as $r) {
                $sheet->setCellValue('A' . $row, $r['type']);
                $sheet->setCellValue('B' . $row, $r['merchants']);
                $sheet->setCellValue('C' . $row, $r['revenue']);
                $sheet->setCellValue('D' . $row, $r['commission']);
                $sheet->setCellValue('E' . $row, $r['paid']);
                $sheet->setCellValue('F' . $row, $r['pending']);
                $sheet->getStyle("A{$row}:F{$row}")->applyFromArray($cellBorder);
                $row++;
            }
            $t = $data['payout_summary']['total'];
            $sheet->setCellValue('A' . $row, $t['type']);
            $sheet->setCellValue('B' . $row, $t['merchants']);
            $sheet->setCellValue('C' . $row, $t['revenue']);
            $sheet->setCellValue('D' . $row, $t['commission']);
            $sheet->setCellValue('E' . $row, $t['paid']);
            $sheet->setCellValue('F' . $row, $t['pending']);
            $sheet->getStyle("A{$row}:F{$row}")->applyFromArray($cellBorder);
            $sheet->getStyle("A{$row}:F{$row}")->getFont()->setBold(true);

            foreach (range('A', 'F') as $c) {
                $sheet->getColumnDimension($c)->setAutoSize(true);
            }
        }

        // Recent registrations
        if (in_array($section, ['all', 'registrations'])) {
            $sheet = $spreadsheet->createSheet();
            $sheet->setTitle('Registrations');
            $sheet->setCellValue('A1', 'Recent Merchant Registrations' . $zoneLabel);
            $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);

            $headers = ['Merchant', 'Type', 'Registered On', 'Status'];
            foreach ($headers as $i => $h) {
                $sheet->setCellValue(chr(65 + $i) . '3', $h);
            }
            $sheet->getStyle('A3:D3')->applyFromArray($headerStyle);

            $row = 4;
            foreach ($data['recent_registrations'] as $r) {
                $sheet->setCellValue('A' . $row, $r['name']);
                $sheet->setCellValue('B' . $row, $r['type']);
                $sheet->setCellValue('C' . $row, $r['registered_on']);
                $sheet->setCellValue('D' . $row, $r['status']);
                $sheet->getStyle("A{$row}:D{$row}")->applyFromArray($cellBorder);
                $row++;
            }
            foreach (range('A', 'D') as $c) {
                $sheet->getColumnDimension($c)->setAutoSize(true);
            }
        }

        // The accuracy caveats travel with the export, not just the screen.
        $sheet = $spreadsheet->createSheet();
        $sheet->setTitle('Notes');
        $sheet->setCellValue('A1', 'How these numbers are calculated');
        $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);
        $row = 3;
        foreach ($data['notes'] as $note) {
            $sheet->setCellValue('A' . $row, '- ' . $note);
            $row++;
        }
        $sheet->getColumnDimension('A')->setWidth(120);
        $sheet->getStyle('A3:A' . $row)->getAlignment()->setWrapText(true);

        $spreadsheet->setActiveSheetIndex(0);
        $filename = 'merchant_analytics_' . $section . '.xlsx';

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
     * Export the merchant overview as PDF.
     */
    public function exportMerchantPdf(Request $request)
    {
        $data = $this->buildMerchantOverviewData($request);
        $section = $request->get('section', 'all');
        $zoneLabel = $this->getMerchantZoneLabel($data['city_id']);

        $money = function ($v) {
            return '₹' . number_format((float) $v, 2);
        };

        $html = '<style>
            body { font-family: sans-serif; font-size: 11px; color: #222; }
            h1 { font-size: 18px; margin: 0 0 4px 0; }
            h2 { font-size: 13px; margin: 16px 0 6px 0; border-bottom: 1px solid #ddd; padding-bottom: 3px; }
            .meta { color: #666; font-size: 10px; margin-bottom: 10px; }
            table { width: 100%; border-collapse: collapse; margin-bottom: 8px; }
            th { background: #4CAF50; color: #fff; padding: 5px; text-align: left; font-size: 10px; }
            td { padding: 5px; border-bottom: 1px solid #eee; font-size: 10px; }
            td.num, th.num { text-align: right; }
            tr.total td { font-weight: bold; border-top: 2px solid #ccc; }
            .notes { margin-top: 14px; padding: 8px; background: #f7f7f7; border-left: 3px solid #9AC444; }
            .notes li { margin-bottom: 3px; color: #555; font-size: 9px; }
        </style>';

        $html .= '<h1>Merchant Analytics' . htmlspecialchars($zoneLabel) . '</h1>';
        $html .= '<div class="meta">Period: ' . htmlspecialchars($data['current_period'])
            . ' &nbsp;|&nbsp; Compare: ' . htmlspecialchars($data['previous_period']) . '</div>';

        if (in_array($section, ['all', 'summary'])) {
            $s = $data['summary'];
            $html .= '<h2>Summary</h2><table><tr><th>Metric</th><th class="num">Current</th><th class="num">Previous</th><th class="num">Change</th></tr>';
            $rows = [
                ['Total Merchants', $s['total_merchants'], false],
                ['Active Merchants', $s['active_merchants'], false],
                ['New Merchants', $s['new_merchants'], false],
                ['Merchant Revenue', $s['total_revenue'], true],
                ['Commission Earned', $s['total_commission'], true],
            ];
            foreach ($rows as $r) {
                $fmt = $r[2] ? $money : function ($v) { return number_format((float) $v); };
                $html .= '<tr><td>' . $r[0] . '</td><td class="num">' . $fmt($r[1]['current'])
                    . '</td><td class="num">' . $fmt($r[1]['previous'])
                    . '</td><td class="num">' . $r[1]['change_percent'] . '%</td></tr>';
            }
            $html .= '<tr><td>Pending Payouts <em>(all time)</em></td><td class="num">' . $money($s['pending_payouts']['current'])
                . '</td><td colspan="2">across ' . $s['pending_payouts']['merchants'] . ' merchants</td></tr>';
            $html .= '</table>';
        }

        if (in_array($section, ['all', 'merchants'])) {
            $html .= '<h2>Top Merchants by Revenue</h2><table><tr><th>#</th><th>Merchant</th><th>Type</th><th class="num">Revenue</th><th class="num">Orders</th><th class="num">Commission</th></tr>';
            foreach ($data['top_merchants'] as $i => $m) {
                $html .= '<tr><td>' . ($i + 1) . '</td><td>' . htmlspecialchars($m['name'])
                    . '</td><td>' . htmlspecialchars($m['type'])
                    . '</td><td class="num">' . $money($m['revenue'])
                    . '</td><td class="num">' . number_format($m['orders'])
                    . '</td><td class="num">' . $money($m['commission']) . '</td></tr>';
            }
            if (empty($data['top_merchants'])) {
                $html .= '<tr><td colspan="6">No data for this period</td></tr>';
            }
            $html .= '</table>';
        }

        if (in_array($section, ['all', 'payouts'])) {
            $html .= '<h2>Commission &amp; Payout Summary</h2>';
            $html .= '<div class="meta">Revenue/Commission: selected period &nbsp;|&nbsp; Paid/Pending: all time</div>';
            $html .= '<table><tr><th>Type</th><th class="num">Merchants</th><th class="num">Revenue</th><th class="num">Commission</th><th class="num">Paid</th><th class="num">Pending</th></tr>';
            foreach ($data['payout_summary']['rows'] as $r) {
                $html .= '<tr><td>' . htmlspecialchars($r['type']) . '</td><td class="num">' . number_format($r['merchants'])
                    . '</td><td class="num">' . $money($r['revenue'])
                    . '</td><td class="num">' . $money($r['commission'])
                    . '</td><td class="num">' . $money($r['paid'])
                    . '</td><td class="num">' . $money($r['pending']) . '</td></tr>';
            }
            $t = $data['payout_summary']['total'];
            $html .= '<tr class="total"><td>' . $t['type'] . '</td><td class="num">' . number_format($t['merchants'])
                . '</td><td class="num">' . $money($t['revenue'])
                . '</td><td class="num">' . $money($t['commission'])
                . '</td><td class="num">' . $money($t['paid'])
                . '</td><td class="num">' . $money($t['pending']) . '</td></tr></table>';
        }

        if (in_array($section, ['all', 'registrations'])) {
            $html .= '<h2>Recent Merchant Registrations</h2><table><tr><th>Merchant</th><th>Type</th><th>Registered On</th><th>Status</th></tr>';
            foreach ($data['recent_registrations'] as $r) {
                $html .= '<tr><td>' . htmlspecialchars($r['name']) . '</td><td>' . htmlspecialchars($r['type'])
                    . '</td><td>' . htmlspecialchars($r['registered_on'])
                    . '</td><td>' . htmlspecialchars($r['status']) . '</td></tr>';
            }
            $html .= '</table>';
        }

        // The accuracy caveats travel with the export, not just the screen.
        $html .= '<div class="notes"><strong>How these numbers are calculated</strong><ul>';
        foreach ($data['notes'] as $note) {
            $html .= '<li>' . htmlspecialchars($note) . '</li>';
        }
        $html .= '</ul></div>';

        $mpdf = new Mpdf(['mode' => 'utf-8', 'format' => 'A4', 'margin_top' => 12, 'margin_bottom' => 12]);
        $mpdf->WriteHTML($html);

        $filename = 'merchant_analytics_' . $section . '.pdf';

        return response($mpdf->Output($filename, Destination::STRING_RETURN), 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="' . $filename . '"',
        ]);
    }

    /**
     * Helper: " | Zone: X" suffix for export headers, or '' when unfiltered.
     */
    private function getMerchantZoneLabel($cityId): string
    {
        if (!$cityId) {
            return '';
        }
        $city = City::find($cityId);
        return $city ? ' | Zone: ' . $city->name : '';
    }

    /**
     * Helper: Resolve [filter, start, end] for the merchant overview.
     */
    private function parseMerchantDateRange(Request $request): array
    {
        $filter = $request->get('filter', 'monthly');
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
            case 'custom':
                $start = $startDate ? Carbon::parse($startDate)->startOfDay() : Carbon::now()->subDays(30)->startOfDay();
                $end = $endDate ? Carbon::parse($endDate)->endOfDay() : Carbon::now()->endOfDay();
                break;
            case 'monthly':
            default:
                $filter = 'monthly';
                $start = Carbon::now()->startOfMonth();
                $end = Carbon::now()->endOfMonth();
        }

        return [$filter, $start, $end];
    }

    /**
     * Helper: Previous comparison period. Monthly aligns to the previous
     * calendar month; everything else uses the same-length preceding window.
     */
    private function getMerchantPreviousPeriod(string $filter, Carbon $start, Carbon $end): array
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

        return [$prevStart, $prevEnd->copy()->endOfDay()];
    }

    /**
     * Helper: Label for the comparison period.
     *
     * getPeriodLabel() words everything from the current period's point of view
     * ("This Month"), so the previous period needs its own wording.
     */
    private function getMerchantPreviousPeriodLabel(string $filter, Carbon $prevStart, Carbon $prevEnd): string
    {
        switch ($filter) {
            case 'daily':
                return 'Yesterday (' . $prevStart->format('d M') . ')';
            case 'weekly':
                return 'Last Week (' . $prevStart->format('d M') . ' - ' . $prevEnd->format('d M') . ')';
            case 'monthly':
                return 'Last Month (' . $prevStart->format('M Y') . ')';
            default:
                return $prevStart->format('d M Y') . ' - ' . $prevEnd->format('d M Y');
        }
    }

    /**
     * Helper: Build a current-vs-previous comparison block for one metric.
     */
    private function buildMerchantDelta(float $cur, float $prev): array
    {
        $change = $cur - $prev;
        $changePercent = $prev > 0 ? round(($change / $prev) * 100, 1) : ($cur > 0 ? 100 : 0);

        return [
            'current' => round($cur, 2),
            'previous' => round($prev, 2),
            'change' => round($change, 2),
            'change_percent' => $changePercent,
            'is_positive' => $change >= 0,
        ];
    }

    /**
     * Helper: Apply the city/zone filter to a query already joined to `orders`.
     */
    private function applyMerchantCityFilter($query, ?string $cityId)
    {
        if ($cityId) {
            $query->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }
        return $query;
    }

    /**
     * Helper: Classify every merchant as Restaurant / Grocery / Combo (Both) /
     * Others from their stores' flags.
     *
     * A seller's stores are sellers.store_id plus sellers.other_store_ids (a JSON
     * array with no relation defined), so both are considered. A seller whose
     * stores span a food flag AND a grocery flag is "Combo (Both)" - which is
     * what makes that bucket real rather than decorative.
     *
     * Note: is_food/is_meat/is_vegetable/is_super_mart are four independent
     * booleans with nothing enforcing exclusivity. This uses the reporting
     * precedence (food wins), matching OrderAnalyticsController::getOrderCategoryMap.
     *
     * @return array [seller_id => type]
     */
    private function getMerchantTypeMap(): array
    {
        $sellers = DB::table('sellers')
            ->where('status', '!=', Seller::$statusRemoved)
            ->select('id', 'store_id', 'other_store_ids')
            ->get();

        // Collect every store id referenced by any seller.
        $sellerStores = [];
        $allStoreIds = [];
        foreach ($sellers as $seller) {
            $ids = [];
            if (!empty($seller->store_id)) {
                $ids[] = (int) $seller->store_id;
            }
            if (!empty($seller->other_store_ids)) {
                $decoded = json_decode($seller->other_store_ids, true);
                if (is_array($decoded)) {
                    foreach ($decoded as $sid) {
                        if (is_numeric($sid)) {
                            $ids[] = (int) $sid;
                        }
                    }
                }
            }
            $ids = array_values(array_unique($ids));
            $sellerStores[$seller->id] = $ids;
            foreach ($ids as $sid) {
                $allStoreIds[$sid] = true;
            }
        }

        $flags = [];
        if (!empty($allStoreIds)) {
            $flags = DB::table('stores')
                ->whereIn('id', array_keys($allStoreIds))
                ->select('id', 'is_food', 'is_meat', 'is_vegetable', 'is_super_mart')
                ->get()
                ->keyBy('id');
        }

        $map = [];
        foreach ($sellerStores as $sellerId => $storeIds) {
            $isFood = false;
            $isGrocery = false;
            foreach ($storeIds as $sid) {
                $store = $flags[$sid] ?? null;
                if (!$store) {
                    continue;
                }
                if ((int) $store->is_food === 1) {
                    $isFood = true;
                }
                if ((int) $store->is_meat === 1 || (int) $store->is_vegetable === 1 || (int) $store->is_super_mart === 1) {
                    $isGrocery = true;
                }
            }

            if ($isFood && $isGrocery) {
                $map[$sellerId] = 'Combo (Both)';
            } elseif ($isFood) {
                $map[$sellerId] = 'Restaurant';
            } elseif ($isGrocery) {
                $map[$sellerId] = 'Grocery';
            } else {
                $map[$sellerId] = 'Others';
            }
        }

        return $map;
    }

    /**
     * Helper: Per-merchant revenue and order counts for a period.
     *
     * Revenue is summed off order_items line values, NOT orders.final_total -
     * joining orders to order_items and summing final_total credits the whole
     * order total once per line item.
     *
     * @return array [seller_id => ['revenue' => float, 'orders' => int]]
     */
    private function getMerchantRevenueBySeller(Carbon $start, Carbon $end, ?string $cityId = null): array
    {
        $query = DB::table('order_items')
            ->join('orders', 'orders.id', '=', 'order_items.order_id')
            ->whereNotNull('order_items.seller_id')
            ->whereNull('order_items.deleted_at')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyMerchantCityFilter($query, $cityId);

        $rows = $query->select(
                'order_items.seller_id',
                DB::raw('COALESCE(SUM(order_items.quantity * order_items.discounted_price), 0) as revenue'),
                DB::raw('COUNT(DISTINCT order_items.order_id) as orders')
            )
            ->groupBy('order_items.seller_id')
            ->get();

        $out = [];
        foreach ($rows as $row) {
            $out[(int) $row->seller_id] = [
                'revenue' => floatval($row->revenue),
                'orders' => intval($row->orders),
            ];
        }

        return $out;
    }

    /**
     * Helper: Per-merchant admin commission for a period, from settlements.
     *
     * @return array [seller_id => float]
     */
    private function getMerchantCommissionBySeller(Carbon $start, Carbon $end, ?string $cityId = null): array
    {
        $query = DB::table('seller_wallet_transactions as swt')
            ->join('orders', 'orders.id', '=', 'swt.order_id')
            ->where('swt.type', SellerWalletTransaction::TYPE_ORDER_COMMISSION)
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyMerchantCityFilter($query, $cityId);

        return $query->select(
                'swt.seller_id',
                DB::raw('COALESCE(SUM(swt.admin_commission), 0) as commission')
            )
            ->groupBy('swt.seller_id')
            ->pluck('commission', 'swt.seller_id')
            ->map(function ($v) {
                return floatval($v);
            })
            ->toArray();
    }

    /**
     * Helper: Headline totals for a period.
     */
    private function getMerchantTotals(Carbon $start, Carbon $end, ?string $cityId = null): array
    {
        $revenueBySeller = $this->getMerchantRevenueBySeller($start, $end, $cityId);
        $commissionBySeller = $this->getMerchantCommissionBySeller($start, $end, $cityId);

        // Total merchants = every non-removed seller that existed by period end.
        $totalMerchants = DB::table('sellers')
            ->where('status', '!=', Seller::$statusRemoved)
            ->where('created_at', '<=', $end)
            ->when($cityId, function ($q) use ($cityId) {
                $q->where('city_id', $cityId);
            })
            ->count();

        // New merchants = registered within the period.
        $newMerchants = DB::table('sellers')
            ->where('status', '!=', Seller::$statusRemoved)
            ->whereBetween('created_at', [$start, $end])
            ->when($cityId, function ($q) use ($cityId) {
                $q->where('city_id', $cityId);
            })
            ->count();

        return [
            'total_merchants' => $totalMerchants,
            // Active = transacted in the period (matches the existing seller pages).
            'active_merchants' => count($revenueBySeller),
            'new_merchants' => $newMerchants,
            'total_revenue' => array_sum(array_column($revenueBySeller, 'revenue')),
            'total_commission' => array_sum($commissionBySeller),
        ];
    }

    /**
     * Helper: Pending payouts - money owed to merchants but not yet paid.
     *
     * Deliberately NOT date-filtered: this is a running balance since inception
     * (`is_paid_to_seller = 0`), the same definition SellerTransactionsController
     * settles against. Refunded amounts are netted off exactly as that controller
     * does, so this tile reconciles with the Pending Payouts page.
     */
    private function getMerchantPendingPayouts(?string $cityId = null): array
    {
        $query = DB::table('seller_wallet_transactions as swt')
            ->where('swt.is_paid_to_seller', 0);

        if ($cityId) {
            $query->join('sellers as s_p', 's_p.id', '=', 'swt.seller_id')
                ->where('s_p.city_id', $cityId);
        }

        $rows = $query->select(
                'swt.seller_id',
                'swt.amount',
                'swt.is_refunded_to_customer',
                'swt.refundable_amount'
            )
            ->get();

        $total = 0.0;
        $sellers = [];
        foreach ($rows as $row) {
            $amount = floatval($row->amount);
            if (!empty($row->is_refunded_to_customer) && floatval($row->refundable_amount) > 0) {
                $amount -= floatval($row->refundable_amount);
            }
            $total += $amount;
            if (!empty($row->seller_id)) {
                $sellers[(int) $row->seller_id] = true;
            }
        }

        return [
            'amount' => round($total, 2),
            'merchants' => count($sellers),
        ];
    }

    /**
     * Helper: The six headline stat tiles.
     */
    private function getMerchantSummary(array $current, array $previous, array $payouts): array
    {
        return [
            'total_merchants' => $this->buildMerchantDelta($current['total_merchants'], $previous['total_merchants']),
            'active_merchants' => $this->buildMerchantDelta($current['active_merchants'], $previous['active_merchants']),
            'new_merchants' => $this->buildMerchantDelta($current['new_merchants'], $previous['new_merchants']),
            'total_revenue' => $this->buildMerchantDelta($current['total_revenue'], $previous['total_revenue']),
            'total_commission' => $this->buildMerchantDelta($current['total_commission'], $previous['total_commission']),
            // Running balance, not a period metric - no comparison arrow.
            'pending_payouts' => [
                'current' => $payouts['amount'],
                'merchants' => $payouts['merchants'],
            ],
        ];
    }

    /**
     * Helper: Revenue and commission per time bucket for the trend chart.
     */
    private function getMerchantPerformanceTrend(Carbon $start, Carbon $end, string $filter, ?string $cityId = null): array
    {
        $buckets = [];

        $add = function ($createdAt, $key, $value) use (&$buckets, $filter, $start, $end) {
            [$sortKey, $label] = $this->getMerchantDateBucket($createdAt, $filter, $start, $end);
            if (!isset($buckets[$sortKey])) {
                $buckets[$sortKey] = ['label' => $label, 'revenue' => 0.0, 'commission' => 0.0];
            }
            $buckets[$sortKey][$key] += $value;
        };

        $revenueQuery = DB::table('order_items')
            ->join('orders', 'orders.id', '=', 'order_items.order_id')
            ->whereNotNull('order_items.seller_id')
            ->whereNull('order_items.deleted_at')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyMerchantCityFilter($revenueQuery, $cityId);

        $revenueRows = $revenueQuery->select(
                DB::raw('orders.created_at as created_at'),
                DB::raw('SUM(order_items.quantity * order_items.discounted_price) as revenue')
            )
            ->groupBy('orders.id', 'orders.created_at')
            ->get();
        foreach ($revenueRows as $row) {
            $add($row->created_at, 'revenue', floatval($row->revenue));
        }

        $commissionQuery = DB::table('seller_wallet_transactions as swt')
            ->join('orders', 'orders.id', '=', 'swt.order_id')
            ->where('swt.type', SellerWalletTransaction::TYPE_ORDER_COMMISSION)
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyMerchantCityFilter($commissionQuery, $cityId);

        $commissionRows = $commissionQuery->select('orders.created_at', 'swt.admin_commission')->get();
        foreach ($commissionRows as $row) {
            $add($row->created_at, 'commission', floatval($row->admin_commission));
        }

        ksort($buckets);

        $labels = [];
        $revenue = [];
        $commission = [];
        foreach ($buckets as $bucket) {
            $labels[] = $bucket['label'];
            $revenue[] = round($bucket['revenue'], 2);
            $commission[] = round($bucket['commission'], 2);
        }

        return [
            'labels' => $labels,
            'revenue' => $revenue,
            'commission' => $commission,
        ];
    }

    /**
     * Helper: Map a timestamp to a [sort key, display label] pair. Hourly for a
     * single day, monthly beyond 31 days, daily otherwise.
     */
    private function getMerchantDateBucket($createdAt, string $filter, Carbon $start, Carbon $end): array
    {
        $date = Carbon::parse($createdAt);
        $diffDays = $start->diffInDays($end);

        if ($filter === 'daily' || ($filter === 'custom' && $diffDays <= 1)) {
            return [$date->format('YmdH'), $date->format('h A')];
        }
        if ($diffDays > 31) {
            return [$date->format('Ym'), $date->format('M Y')];
        }
        return [$date->format('Ymd'), $date->format('d M')];
    }

    /**
     * Helper: Top merchants by revenue, with their orders and commission.
     */
    private function getTopMerchants(Carbon $start, Carbon $end, ?string $cityId, array $typeMap, int $limit = 10): array
    {
        $revenueBySeller = $this->getMerchantRevenueBySeller($start, $end, $cityId);
        if (empty($revenueBySeller)) {
            return [];
        }

        $commissionBySeller = $this->getMerchantCommissionBySeller($start, $end, $cityId);

        arsort($revenueBySeller);
        $topIds = array_slice(array_keys($revenueBySeller), 0, $limit, true);

        $names = DB::table('sellers')
            ->leftJoin('stores', 'sellers.store_id', '=', 'stores.id')
            ->whereIn('sellers.id', $topIds)
            ->select('sellers.id', 'sellers.name', 'stores.name as store_name')
            ->get()
            ->keyBy('id');

        $out = [];
        foreach ($topIds as $sellerId) {
            $seller = $names[$sellerId] ?? null;
            $out[] = [
                'seller_id' => $sellerId,
                'name' => $seller->store_name ?? $seller->name ?? ('Merchant #' . $sellerId),
                'type' => $typeMap[$sellerId] ?? 'Others',
                'revenue' => round($revenueBySeller[$sellerId]['revenue'], 2),
                'orders' => $revenueBySeller[$sellerId]['orders'],
                'commission' => round($commissionBySeller[$sellerId] ?? 0, 2),
            ];
        }

        return $out;
    }

    /**
     * Helper: Roll a [seller_id => value] map up into merchant-type buckets.
     */
    private function bucketByMerchantType(array $valueBySeller, array $typeMap): array
    {
        $buckets = ['Restaurant' => 0.0, 'Grocery' => 0.0, 'Combo (Both)' => 0.0, 'Others' => 0.0];
        foreach ($valueBySeller as $sellerId => $value) {
            $type = $typeMap[$sellerId] ?? 'Others';
            $buckets[$type] += floatval($value);
        }
        return $buckets;
    }

    /**
     * Helper: Format type buckets as a donut payload.
     */
    private function formatMerchantTypeBuckets(array $buckets, string $valueKey = 'value'): array
    {
        $total = array_sum($buckets);
        $items = [];
        foreach ($buckets as $name => $value) {
            $items[] = [
                'name' => $name,
                $valueKey => round($value, 2),
                'percentage' => $total > 0 ? round($value * 100 / $total, 1) : 0,
            ];
        }
        return ['total' => round($total, 2), 'items' => $items];
    }

    /**
     * Helper: Commission split by merchant type.
     */
    private function getMerchantCommissionByType(Carbon $start, Carbon $end, ?string $cityId, array $typeMap): array
    {
        $commissionBySeller = $this->getMerchantCommissionBySeller($start, $end, $cityId);
        return $this->formatMerchantTypeBuckets(
            $this->bucketByMerchantType($commissionBySeller, $typeMap)
        );
    }

    /**
     * Helper: Revenue split by merchant type.
     */
    private function getMerchantRevenueByType(Carbon $start, Carbon $end, ?string $cityId, array $typeMap): array
    {
        $revenueBySeller = $this->getMerchantRevenueBySeller($start, $end, $cityId);
        $flat = [];
        foreach ($revenueBySeller as $sellerId => $row) {
            $flat[$sellerId] = $row['revenue'];
        }
        return $this->formatMerchantTypeBuckets(
            $this->bucketByMerchantType($flat, $typeMap)
        );
    }

    /**
     * Helper: Merchants by account status.
     *
     * The mockup asked for Active/Inactive/Suspended/Pending; the sellers table
     * has no "suspended" state, so this reports what actually exists:
     * Active (1), Inactive (3 Deactivated), Pending (0 Registered), Rejected (2).
     * Status 7 (Removed) is excluded.
     */
    private function getMerchantsByStatus(?string $cityId = null): array
    {
        $rows = DB::table('sellers')
            ->where('status', '!=', Seller::$statusRemoved)
            ->when($cityId, function ($q) use ($cityId) {
                $q->where('city_id', $cityId);
            })
            ->select('status', DB::raw('COUNT(*) as total'))
            ->groupBy('status')
            ->pluck('total', 'status')
            ->toArray();

        $labels = [
            Seller::$statusActive => 'Active',
            Seller::$statusDeactivated => 'Inactive',
            Seller::$statusRegistered => 'Pending',
            Seller::$statusRejected => 'Rejected',
        ];

        $total = array_sum($rows);
        $items = [];
        foreach ($labels as $status => $label) {
            $count = (int) ($rows[$status] ?? 0);
            $items[] = [
                'name' => $label,
                'count' => $count,
                'percentage' => $total > 0 ? round($count * 100 / $total, 1) : 0,
            ];
        }

        return ['total' => $total, 'items' => $items];
    }

    /**
     * Helper: Top product categories by merchant sales.
     *
     * Join path is order_items -> product_variants -> products -> categories;
     * order_items has no product_id of its own. Combo orders are stored as JSON
     * in order_combo_items and cannot be reached from here - see `notes`.
     */
    private function getMerchantTopCategories(Carbon $start, Carbon $end, ?string $cityId = null, int $limit = 5): array
    {
        $query = DB::table('order_items')
            ->join('orders', 'orders.id', '=', 'order_items.order_id')
            ->join('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->join('products', 'product_variants.product_id', '=', 'products.id')
            ->join('categories', 'products.category_id', '=', 'categories.id')
            ->whereNotNull('order_items.seller_id')
            ->whereNull('order_items.deleted_at')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);
        $this->applyMerchantCityFilter($query, $cityId);

        $rows = $query->select(
                'categories.name',
                DB::raw('COALESCE(SUM(order_items.quantity * order_items.discounted_price), 0) as revenue')
            )
            ->groupBy('categories.id', 'categories.name')
            ->orderByDesc('revenue')
            ->limit($limit)
            ->get();

        $out = [];
        foreach ($rows as $row) {
            $out[] = [
                'name' => $row->name,
                'revenue' => round(floatval($row->revenue), 2),
            ];
        }

        return $out;
    }

    /**
     * Helper: Commission and payout summary table, by merchant type.
     *
     * Revenue and commission are period-scoped; paid/pending are running
     * balances off is_paid_to_seller, consistent with the Pending Payouts tile.
     */
    private function getMerchantPayoutSummary(Carbon $start, Carbon $end, ?string $cityId, array $typeMap): array
    {
        $revenueBySeller = $this->getMerchantRevenueBySeller($start, $end, $cityId);
        $commissionBySeller = $this->getMerchantCommissionBySeller($start, $end, $cityId);

        $flatRevenue = [];
        foreach ($revenueBySeller as $sellerId => $row) {
            $flatRevenue[$sellerId] = $row['revenue'];
        }

        // Merchant counts per type (every non-removed seller, not just traders).
        $merchantCounts = ['Restaurant' => 0, 'Grocery' => 0, 'Combo (Both)' => 0, 'Others' => 0];
        $countable = DB::table('sellers')
            ->where('status', '!=', Seller::$statusRemoved)
            ->when($cityId, function ($q) use ($cityId) {
                $q->where('city_id', $cityId);
            })
            ->pluck('id');
        foreach ($countable as $sellerId) {
            $type = $typeMap[$sellerId] ?? 'Others';
            $merchantCounts[$type]++;
        }

        // Paid vs pending, split by type.
        $payoutQuery = DB::table('seller_wallet_transactions as swt');
        if ($cityId) {
            $payoutQuery->join('sellers as s_ps', 's_ps.id', '=', 'swt.seller_id')
                ->where('s_ps.city_id', $cityId);
        }
        $payoutRows = $payoutQuery->select(
                'swt.seller_id',
                'swt.amount',
                'swt.is_paid_to_seller',
                'swt.is_refunded_to_customer',
                'swt.refundable_amount'
            )
            ->get();

        $paid = ['Restaurant' => 0.0, 'Grocery' => 0.0, 'Combo (Both)' => 0.0, 'Others' => 0.0];
        $pending = $paid;
        foreach ($payoutRows as $row) {
            $type = $typeMap[$row->seller_id] ?? 'Others';
            $amount = floatval($row->amount);
            if (!empty($row->is_refunded_to_customer) && floatval($row->refundable_amount) > 0) {
                $amount -= floatval($row->refundable_amount);
            }
            if (!empty($row->is_paid_to_seller)) {
                $paid[$type] += $amount;
            } else {
                $pending[$type] += $amount;
            }
        }

        $revenueByType = $this->bucketByMerchantType($flatRevenue, $typeMap);
        $commissionByType = $this->bucketByMerchantType($commissionBySeller, $typeMap);

        $rows = [];
        $totals = ['merchants' => 0, 'revenue' => 0.0, 'commission' => 0.0, 'paid' => 0.0, 'pending' => 0.0];
        foreach (['Restaurant', 'Grocery', 'Combo (Both)', 'Others'] as $type) {
            $row = [
                'type' => $type,
                'merchants' => $merchantCounts[$type],
                'revenue' => round($revenueByType[$type], 2),
                'commission' => round($commissionByType[$type], 2),
                'paid' => round($paid[$type], 2),
                'pending' => round($pending[$type], 2),
            ];
            $rows[] = $row;
            $totals['merchants'] += $row['merchants'];
            $totals['revenue'] += $row['revenue'];
            $totals['commission'] += $row['commission'];
            $totals['paid'] += $row['paid'];
            $totals['pending'] += $row['pending'];
        }

        $totals['type'] = 'Total';
        foreach (['revenue', 'commission', 'paid', 'pending'] as $key) {
            $totals[$key] = round($totals[$key], 2);
        }

        return ['rows' => $rows, 'total' => $totals];
    }

    /**
     * Helper: The most recently registered merchants.
     */
    private function getRecentMerchantRegistrations(?string $cityId, array $typeMap, int $limit = 5): array
    {
        $rows = DB::table('sellers')
            ->leftJoin('stores', 'sellers.store_id', '=', 'stores.id')
            ->where('sellers.status', '!=', Seller::$statusRemoved)
            ->when($cityId, function ($q) use ($cityId) {
                $q->where('sellers.city_id', $cityId);
            })
            ->select(
                'sellers.id',
                'sellers.name',
                'sellers.status',
                'sellers.created_at',
                'stores.name as store_name'
            )
            ->orderByDesc('sellers.created_at')
            ->limit($limit)
            ->get();

        $statusLabels = [
            Seller::$statusRegistered => 'Pending',
            Seller::$statusActive => 'Active',
            Seller::$statusRejected => 'Rejected',
            Seller::$statusDeactivated => 'Inactive',
        ];

        $out = [];
        foreach ($rows as $row) {
            $out[] = [
                'seller_id' => $row->id,
                'name' => $row->store_name ?: ($row->name ?: 'Merchant #' . $row->id),
                'type' => $typeMap[$row->id] ?? 'Others',
                'registered_on' => $row->created_at ? Carbon::parse($row->created_at)->format('d M Y') : '-',
                'status' => $statusLabels[$row->status] ?? 'Unknown',
            ];
        }

        return $out;
    }

    /**
     * Helper: Plain-language callouts derived from the numbers already computed.
     */
    private function getMerchantInsights(array $data): array
    {
        $out = [];

        $top = $data['top_merchants'][0] ?? null;
        if ($top) {
            $out[] = [
                'icon' => 'star',
                'type' => 'success',
                'text' => $top['name'] . ' is the top performing merchant by revenue (₹'
                    . number_format($top['revenue'], 2) . ').',
            ];
        }

        $revenue = $data['summary']['total_revenue'];
        $out[] = [
            'icon' => 'chart',
            'type' => $revenue['is_positive'] ? 'success' : 'warning',
            'text' => 'Merchant revenue ' . ($revenue['is_positive'] ? 'grew' : 'fell') . ' by '
                . abs($revenue['change_percent']) . '% vs ' . $data['previous_period'] . '.',
        ];

        $new = $data['summary']['new_merchants'];
        if ($new['current'] > 0) {
            $out[] = [
                'icon' => 'user-plus',
                'type' => 'success',
                'text' => (int) $new['current'] . ' new merchants joined in ' . $data['current_period'] . '.',
            ];
        }

        $payouts = $data['summary']['pending_payouts'];
        if ($payouts['current'] > 0) {
            $out[] = [
                'icon' => 'alert',
                'type' => 'warning',
                'text' => '₹' . number_format($payouts['current'], 2) . ' pending across '
                    . $payouts['merchants'] . ' merchants (all time, not limited to this period).',
            ];
        }

        $pendingApproval = 0;
        foreach ($data['merchants_by_status']['items'] as $item) {
            if ($item['name'] === 'Pending') {
                $pendingApproval = $item['count'];
            }
        }
        if ($pendingApproval > 0) {
            $out[] = [
                'icon' => 'clock',
                'type' => 'warning',
                'text' => $pendingApproval . ' merchants are awaiting onboarding approval.',
            ];
        }

        return $out;
    }
}
