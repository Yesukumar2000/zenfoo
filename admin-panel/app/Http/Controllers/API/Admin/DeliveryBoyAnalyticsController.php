<?php

namespace App\Http\Controllers\API\Admin;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\City;
use App\Models\DeliveryBoy;
use App\Models\Order;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DeliveryBoyAnalyticsController extends Controller
{
    /**
     * Get delivery boy analytics.
     */
    public function getAnalytics(Request $request, $deliveryBoyId)
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

        // Get delivery boy info
        $deliveryBoy = DeliveryBoy::find($deliveryBoyId);
        if (!$deliveryBoy) {
            return CommonHelper::responseError('Delivery boy not found');
        }

        // Summary metrics
        $summary = $this->getSummary($deliveryBoyId, $start, $end);

        // Deliveries over time
        $deliveriesOverTime = $this->getDeliveriesOverTime($deliveryBoyId, $start, $end, $filter);

        // Earnings over time
        $earningsOverTime = $this->getEarningsOverTime($deliveryBoyId, $start, $end, $filter);

        // Delivery status breakdown
        $statusBreakdown = $this->getStatusBreakdown($deliveryBoyId, $start, $end);

        // Earnings breakdown
        $earningsBreakdown = $this->getEarningsBreakdown($deliveryBoyId, $start, $end);

        // Peak hours
        $peakHours = $this->getPeakHours($deliveryBoyId, $start, $end);

        // Zone distribution
        $zoneDistribution = $this->getZoneDistribution($deliveryBoyId, $start, $end);

        // Performance comparison
        $performanceComparison = $this->getPerformanceComparison($deliveryBoyId, $start, $end, $filter);

        // Recent deliveries
        $recentDeliveries = $this->getRecentDeliveries($deliveryBoyId, $start, $end);

        $data = [
            'filter' => $filter,
            'start_date' => $start->toDateString(),
            'end_date' => $end->toDateString(),
            'delivery_boy' => [
                'id' => $deliveryBoy->id,
                'name' => $deliveryBoy->name,
                'mobile' => $deliveryBoy->mobile,
            ],
            'summary' => $summary,
            'deliveries_over_time' => $deliveriesOverTime,
            'earnings_over_time' => $earningsOverTime,
            'status_breakdown' => $statusBreakdown,
            'earnings_breakdown' => $earningsBreakdown,
            'peak_hours' => $peakHours,
            'zone_distribution' => $zoneDistribution,
            'performance_comparison' => $performanceComparison,
            'recent_deliveries' => $recentDeliveries,
        ];

        return CommonHelper::responseWithData($data);
    }

    /**
     * Get all delivery boys analytics data with zone filtering.
     */
    public function getAllDeliveryBoysAnalytics(Request $request)
    {
        Log::info('======================================');
        Log::info('ALL DELIVERY BOYS ANALYTICS API REQUEST');
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

        // Summary metrics for all delivery boys
        $summary = $this->getAllDeliveryBoysSummary($start, $end, $cityId);

        // Top delivery boys by deliveries
        $topByDeliveries = $this->getTopDeliveryBoysByDeliveries($start, $end, $cityId);

        // Top delivery boys by earnings
        $topByEarnings = $this->getTopDeliveryBoysByEarnings($start, $end, $cityId);

        // Delivery boys by zone
        $deliveryBoysByZone = $this->getDeliveryBoysByZone($cityId);

        // Deliveries trend over time
        $deliveriesTrend = $this->getAllDeliveryBoysDeliveriesTrend($start, $end, $filter, $cityId);

        // Earnings trend over time
        $earningsTrend = $this->getAllDeliveryBoysEarningsTrend($start, $end, $filter, $cityId);

        // Active vs inactive delivery boys
        $deliveryBoyActivity = $this->getDeliveryBoyActivity($start, $end, $cityId);

        // Delivery status distribution
        $statusDistribution = $this->getAllDeliveryBoysStatusDistribution($start, $end, $cityId);

        $data = [
            'filter' => $filter,
            'start_date' => $start->toDateString(),
            'end_date' => $end->toDateString(),
            'summary' => $summary,
            'top_by_deliveries' => $topByDeliveries,
            'top_by_earnings' => $topByEarnings,
            'delivery_boys_by_zone' => $deliveryBoysByZone,
            'deliveries_trend' => $deliveriesTrend,
            'earnings_trend' => $earningsTrend,
            'delivery_boy_activity' => $deliveryBoyActivity,
            'status_distribution' => $statusDistribution,
        ];

        Log::info('======================================');
        Log::info('ALL DELIVERY BOYS ANALYTICS RESPONSE SUMMARY');
        Log::info('======================================');
        Log::info('Response Summary:', [
            'total_delivery_boys' => $summary['total_delivery_boys'] ?? 0,
            'active_delivery_boys' => $summary['active_delivery_boys'] ?? 0,
            'total_deliveries' => $summary['total_deliveries'] ?? 0,
            'total_earnings' => $summary['total_earnings'] ?? 0,
        ]);
        Log::info('======================================');

        return CommonHelper::responseWithData($data);
    }

    private function getAllDeliveryBoysSummary(Carbon $start, Carbon $end, ?string $cityId = null)
    {
        Log::info('=== getAllDeliveryBoysSummary START ===');

        // Total delivery boys
        $totalQuery = DeliveryBoy::select(DB::raw('COUNT(DISTINCT id) as total'))
            ->where('status', 1);

        // Note: Delivery boys don't have direct city association, so zone filter applies to their orders

        Log::info('Total Delivery Boys Query SQL:', [
            'sql' => $totalQuery->toSql(),
            'bindings' => $totalQuery->getBindings()
        ]);

        $totalDeliveryBoys = $totalQuery->value('total') ?? 0;
        Log::info('Total Delivery Boys Result:', ['count' => $totalDeliveryBoys]);

        // Active delivery boys (who had deliveries in period)
        $activeQuery = DeliveryBoy::select(DB::raw('COUNT(DISTINCT delivery_boys.id) as total'))
            ->join('orders', 'delivery_boys.id', '=', 'orders.delivery_boy_id')
            ->where('delivery_boys.status', 1)
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $activeQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        Log::info('Active Delivery Boys Query SQL:', [
            'sql' => $activeQuery->toSql(),
            'bindings' => $activeQuery->getBindings()
        ]);

        $activeDeliveryBoys = $activeQuery->value('total') ?? 0;
        Log::info('Active Delivery Boys Result:', ['count' => $activeDeliveryBoys]);

        // Total deliveries
        $deliveriesQuery = Order::select(DB::raw('COUNT(DISTINCT orders.id) as total'))
            ->whereNotNull('orders.delivery_boy_id')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $deliveriesQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $totalDeliveries = $deliveriesQuery->value('total') ?? 0;

        // Total earnings (delivery charges + tips)
        $earningsQuery = Order::select(
                DB::raw('COALESCE(SUM(orders.delivery_charge), 0) as total_delivery_charges'),
                DB::raw('COALESCE(SUM(orders.delivery_tip), 0) as total_tips')
            )
            ->whereNotNull('orders.delivery_boy_id')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $earningsQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $earningsData = $earningsQuery->first();
        $totalEarnings = floatval($earningsData->total_delivery_charges ?? 0) + floatval($earningsData->total_tips ?? 0);

        Log::info('Deliveries & Earnings Result:', [
            'total_deliveries' => $totalDeliveries,
            'total_earnings' => $totalEarnings
        ]);

        $avgDeliveriesPerBoy = $activeDeliveryBoys > 0 ? round($totalDeliveries / $activeDeliveryBoys, 2) : 0;
        $avgEarningsPerBoy = $activeDeliveryBoys > 0 ? round($totalEarnings / $activeDeliveryBoys, 2) : 0;

        $result = [
            'total_delivery_boys' => $totalDeliveryBoys,
            'active_delivery_boys' => $activeDeliveryBoys,
            'inactive_delivery_boys' => max(0, $totalDeliveryBoys - $activeDeliveryBoys),
            'total_deliveries' => $totalDeliveries,
            'total_earnings' => round($totalEarnings, 2),
            'avg_deliveries_per_boy' => $avgDeliveriesPerBoy,
            'avg_earnings_per_boy' => $avgEarningsPerBoy,
        ];

        Log::info('getAllDeliveryBoysSummary Final Result:', $result);
        Log::info('=== getAllDeliveryBoysSummary END ===');

        return $result;
    }

    private function getTopDeliveryBoysByDeliveries(Carbon $start, Carbon $end, ?string $cityId = null, int $limit = 10)
    {
        $query = DeliveryBoy::select(
                'delivery_boys.id',
                'delivery_boys.name',
                'delivery_boys.mobile',
                DB::raw('COUNT(DISTINCT orders.id) as delivery_count'),
                DB::raw('COALESCE(SUM(orders.delivery_charge), 0) + COALESCE(SUM(orders.delivery_tip), 0) as total_earnings')
            )
            ->join('orders', 'delivery_boys.id', '=', 'orders.delivery_boy_id')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $query->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $deliveryBoys = $query->groupBy('delivery_boys.id', 'delivery_boys.name', 'delivery_boys.mobile')
            ->orderByDesc('delivery_count')
            ->limit($limit)
            ->get();

        $result = [];
        foreach ($deliveryBoys as $boy) {
            $result[] = [
                'delivery_boy_id' => $boy->id,
                'name' => $boy->name,
                'mobile' => $boy->mobile,
                'delivery_count' => $boy->delivery_count,
                'total_earnings' => round($boy->total_earnings, 2),
            ];
        }

        return $result;
    }

    private function getTopDeliveryBoysByEarnings(Carbon $start, Carbon $end, ?string $cityId = null, int $limit = 10)
    {
        $query = DeliveryBoy::select(
                'delivery_boys.id',
                'delivery_boys.name',
                DB::raw('COUNT(DISTINCT orders.id) as delivery_count'),
                DB::raw('COALESCE(SUM(orders.delivery_charge), 0) + COALESCE(SUM(orders.delivery_tip), 0) as total_earnings')
            )
            ->join('orders', 'delivery_boys.id', '=', 'orders.delivery_boy_id')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $query->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $deliveryBoys = $query->groupBy('delivery_boys.id', 'delivery_boys.name')
            ->orderByDesc('total_earnings')
            ->limit($limit)
            ->get();

        $result = [];
        foreach ($deliveryBoys as $boy) {
            $result[] = [
                'delivery_boy_id' => $boy->id,
                'name' => $boy->name,
                'delivery_count' => $boy->delivery_count,
                'total_earnings' => round($boy->total_earnings, 2),
            ];
        }

        return $result;
    }

    private function getDeliveryBoysByZone(?string $cityId = null)
    {
        Log::info('=== getDeliveryBoysByZone START ===', ['city_id' => $cityId]);

        // Count delivery boys by the zones they deliver to
        $query = DB::table('delivery_boys')
            ->join('orders', 'delivery_boys.id', '=', 'orders.delivery_boy_id')
            ->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
            ->select('user_addresses.city_id', DB::raw('COUNT(DISTINCT delivery_boys.id) as delivery_boy_count'))
            ->where('delivery_boys.status', 1)
            ->whereNotNull('user_addresses.city_id');

        if ($cityId) {
            $query->where('user_addresses.city_id', $cityId);
        }

        $zones = $query->groupBy('user_addresses.city_id')
            ->orderByDesc('delivery_boy_count')
            ->limit(10)
            ->get();

        Log::info('getDeliveryBoysByZone Raw Results:', [
            'zones_count' => $zones->count(),
            'zones_data' => json_decode(json_encode($zones), true)
        ]);

        $labels = [];
        $values = [];

        foreach ($zones as $zone) {
            $city = City::find($zone->city_id);
            if ($city) {
                $labels[] = $city->name;
                $values[] = $zone->delivery_boy_count;
            }
        }

        Log::info('=== getDeliveryBoysByZone END ===', [
            'labels' => $labels,
            'values' => $values
        ]);

        return [
            'labels' => $labels,
            'values' => $values,
        ];
    }

    private function getAllDeliveryBoysDeliveriesTrend(Carbon $start, Carbon $end, string $filter, ?string $cityId = null)
    {
        $ordersQuery = Order::select('orders.created_at')
            ->whereNotNull('orders.delivery_boy_id')
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

    private function getAllDeliveryBoysEarningsTrend(Carbon $start, Carbon $end, string $filter, ?string $cityId = null)
    {
        $ordersQuery = Order::select('orders.created_at', 'orders.delivery_charge', 'orders.delivery_tip')
            ->whereNotNull('orders.delivery_boy_id')
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
            $grouped[$key] += floatval($order->delivery_charge ?? 0) + floatval($order->delivery_tip ?? 0);
        }

        ksort($grouped);

        return [
            'labels' => array_keys($grouped),
            'values' => array_map(fn($v) => round($v, 2), array_values($grouped)),
        ];
    }

    private function getDeliveryBoyActivity(Carbon $start, Carbon $end, ?string $cityId = null)
    {
        // Active delivery boys
        $activeQuery = DeliveryBoy::select(DB::raw('COUNT(DISTINCT delivery_boys.id) as total'))
            ->join('orders', 'delivery_boys.id', '=', 'orders.delivery_boy_id')
            ->where('delivery_boys.status', 1)
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $activeQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $activeCount = $activeQuery->value('total') ?? 0;

        // Total delivery boys
        $totalQuery = DeliveryBoy::select(DB::raw('COUNT(DISTINCT id) as total'))
            ->where('status', 1)
            ->where('created_at', '<=', $end);

        $totalCount = $totalQuery->value('total') ?? 0;
        $inactiveCount = max(0, $totalCount - $activeCount);

        return [
            'labels' => ['Active Delivery Boys', 'Inactive Delivery Boys'],
            'values' => [$activeCount, $inactiveCount],
        ];
    }

    private function getAllDeliveryBoysStatusDistribution(Carbon $start, Carbon $end, ?string $cityId = null)
    {
        $statusMap = [
            5 => 'Out for Delivery',
            6 => 'Delivered',
            7 => 'Cancelled',
            8 => 'Returned',
        ];

        $query = Order::select('orders.active_status', DB::raw('COUNT(DISTINCT orders.id) as count'))
            ->whereNotNull('orders.delivery_boy_id')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $query->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

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
     * Get summary metrics.
     */
    private function getSummary($deliveryBoyId, Carbon $start, Carbon $end)
    {
        // Deliveries in period
        $deliveriesQuery = Order::where('delivery_boy_id', $deliveryBoyId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1]);

        $totalDeliveries = $deliveriesQuery->count();

        $completedDeliveries = Order::where('delivery_boy_id', $deliveryBoyId)
            ->whereBetween('created_at', [$start, $end])
            ->where('active_status', 6) // Delivered
            ->count();

        $cancelledDeliveries = Order::where('delivery_boy_id', $deliveryBoyId)
            ->whereBetween('created_at', [$start, $end])
            ->whereIn('active_status', [7, 8]) // Cancelled or Returned
            ->count();

        // Lifetime stats
        $lifetimeDeliveries = Order::where('delivery_boy_id', $deliveryBoyId)
            ->whereNotIn('active_status', [1])
            ->count();

        // Earnings (delivery charge)
        $totalEarnings = floatval($deliveriesQuery->sum('delivery_charge'));

        // Tips
        $totalTips = 0;
        $orders = $deliveriesQuery->get();
        foreach ($orders as $order) {
            $meta = $order->cart_metadata;
            if ($meta && isset($meta['billing_summary']['delivery_tip'])) {
                $totalTips += floatval($meta['billing_summary']['delivery_tip']);
            }
        }

        // Incentives (from delivery_boy_incentives table if exists)
        $totalIncentives = DB::table('delivery_boy_incentives')
            ->where('delivery_boy_id', $deliveryBoyId)
            ->whereBetween('created_at', [$start, $end])
            ->sum('amount');

        // Ratings
        $avgRating = DB::table('order_ratings')
            ->join('orders', 'order_ratings.order_id', '=', 'orders.id')
            ->where('orders.delivery_boy_id', $deliveryBoyId)
            ->whereBetween('orders.created_at', [$start, $end])
            ->avg('order_ratings.delivery_boy_rating');

        $totalRatings = DB::table('order_ratings')
            ->join('orders', 'order_ratings.order_id', '=', 'orders.id')
            ->where('orders.delivery_boy_id', $deliveryBoyId)
            ->whereNotNull('order_ratings.delivery_boy_rating')
            ->count();

        // On-time delivery rate (assuming delivered orders are on-time for now)
        $onTimeRate = $totalDeliveries > 0 ? round(($completedDeliveries / $totalDeliveries) * 100, 1) : 0;

        return [
            'total_deliveries' => $totalDeliveries,
            'completed_deliveries' => $completedDeliveries,
            'cancelled_deliveries' => $cancelledDeliveries,
            'lifetime_deliveries' => $lifetimeDeliveries,
            'total_earnings' => round($totalEarnings, 2),
            'total_tips' => round($totalTips, 2),
            'total_incentives' => round($totalIncentives ?? 0, 2),
            'combined_earnings' => round($totalEarnings + $totalTips + ($totalIncentives ?? 0), 2),
            'avg_rating' => round($avgRating ?? 0, 2),
            'total_ratings' => $totalRatings,
            'on_time_rate' => $onTimeRate,
        ];
    }

    /**
     * Get deliveries over time.
     */
    private function getDeliveriesOverTime($deliveryBoyId, Carbon $start, Carbon $end, string $filter)
    {
        $deliveries = Order::select('created_at')
            ->where('delivery_boy_id', $deliveryBoyId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1])
            ->get();

        $grouped = [];
        foreach ($deliveries as $delivery) {
            $key = $this->getDateKey($delivery->created_at, $filter, $start, $end);
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
     * Get earnings over time.
     */
    private function getEarningsOverTime($deliveryBoyId, Carbon $start, Carbon $end, string $filter)
    {
        $orders = Order::select('created_at', 'delivery_charge', 'cart_metadata')
            ->where('delivery_boy_id', $deliveryBoyId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1])
            ->get();

        $grouped = [];
        foreach ($orders as $order) {
            $key = $this->getDateKey($order->created_at, $filter, $start, $end);
            if (!isset($grouped[$key])) {
                $grouped[$key] = ['base' => 0, 'tips' => 0, 'total' => 0];
            }

            $deliveryCharge = floatval($order->delivery_charge);
            $tip = 0;

            $meta = $order->cart_metadata;
            if ($meta && isset($meta['billing_summary']['delivery_tip'])) {
                $tip = floatval($meta['billing_summary']['delivery_tip']);
            }

            $grouped[$key]['base'] += $deliveryCharge;
            $grouped[$key]['tips'] += $tip;
            $grouped[$key]['total'] += ($deliveryCharge + $tip);
        }

        ksort($grouped);

        return [
            'labels' => array_keys($grouped),
            'base_earnings' => array_map(fn($v) => round($v['base'], 2), array_values($grouped)),
            'tips' => array_map(fn($v) => round($v['tips'], 2), array_values($grouped)),
            'total_earnings' => array_map(fn($v) => round($v['total'], 2), array_values($grouped)),
        ];
    }

    /**
     * Get status breakdown.
     */
    private function getStatusBreakdown($deliveryBoyId, Carbon $start, Carbon $end)
    {
        $statusMap = [
            6 => 'Delivered',
            7 => 'Cancelled',
            8 => 'Returned',
        ];

        $counts = Order::select('active_status', DB::raw('COUNT(*) as count'))
            ->where('delivery_boy_id', $deliveryBoyId)
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
     * Get earnings breakdown.
     */
    private function getEarningsBreakdown($deliveryBoyId, Carbon $start, Carbon $end)
    {
        $orders = Order::select('delivery_charge', 'cart_metadata')
            ->where('delivery_boy_id', $deliveryBoyId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1])
            ->get();

        $baseEarnings = 0;
        $tips = 0;

        foreach ($orders as $order) {
            $baseEarnings += floatval($order->delivery_charge);

            $meta = $order->cart_metadata;
            if ($meta && isset($meta['billing_summary']['delivery_tip'])) {
                $tips += floatval($meta['billing_summary']['delivery_tip']);
            }
        }

        // Incentives
        $incentives = DB::table('delivery_boy_incentives')
            ->where('delivery_boy_id', $deliveryBoyId)
            ->whereBetween('created_at', [$start, $end])
            ->sum('amount');

        // Surge charges (if applicable)
        $surgeCharges = DB::table('delivery_boy_surge_charges')
            ->where('delivery_boy_id', $deliveryBoyId)
            ->whereBetween('created_at', [$start, $end])
            ->sum('amount');

        return [
            'labels' => ['Base Pay', 'Tips', 'Incentives', 'Surge Charges'],
            'values' => [
                round($baseEarnings, 2),
                round($tips, 2),
                round($incentives ?? 0, 2),
                round($surgeCharges ?? 0, 2),
            ],
        ];
    }

    /**
     * Get peak hours.
     */
    private function getPeakHours($deliveryBoyId, Carbon $start, Carbon $end)
    {
        $orders = Order::select(DB::raw('HOUR(created_at) as hour'), DB::raw('COUNT(*) as count'))
            ->where('delivery_boy_id', $deliveryBoyId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1])
            ->groupBy('hour')
            ->orderBy('hour')
            ->get();

        $hours = [];
        $counts = [];

        for ($i = 0; $i < 24; $i++) {
            $hours[] = sprintf('%02d:00', $i);
            $counts[] = 0;
        }

        foreach ($orders as $order) {
            $counts[$order->hour] = $order->count;
        }

        return [
            'labels' => $hours,
            'values' => $counts,
        ];
    }

    /**
     * Get zone distribution.
     */
    private function getZoneDistribution($deliveryBoyId, Carbon $start, Carbon $end)
    {
        $zones = DB::table('orders')
            ->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
            ->join('cities', 'user_addresses.city_id', '=', 'cities.id')
            ->select('cities.name', DB::raw('COUNT(*) as count'))
            ->where('orders.delivery_boy_id', $deliveryBoyId)
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->groupBy('cities.id', 'cities.name')
            ->orderByDesc('count')
            ->limit(10)
            ->get();

        $labels = [];
        $values = [];

        foreach ($zones as $zone) {
            $labels[] = $zone->name;
            $values[] = $zone->count;
        }

        return [
            'labels' => $labels,
            'values' => $values,
        ];
    }

    /**
     * Get performance comparison.
     */
    private function getPerformanceComparison($deliveryBoyId, Carbon $start, Carbon $end, string $filter)
    {
        $diffDays = $start->diffInDays($end);

        // Calculate previous period
        $prevEnd = $start->copy()->subSecond();
        $prevStart = $prevEnd->copy()->subDays($diffDays)->startOfDay();

        $currentMetrics = $this->getComparisonMetrics($deliveryBoyId, $start, $end);
        $previousMetrics = $this->getComparisonMetrics($deliveryBoyId, $prevStart, $prevEnd);

        $metrics = ['deliveries', 'earnings', 'avg_rating'];
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
    private function getComparisonMetrics($deliveryBoyId, Carbon $start, Carbon $end)
    {
        $ordersQuery = Order::where('delivery_boy_id', $deliveryBoyId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1]);

        $totalDeliveries = $ordersQuery->count();
        $totalEarnings = floatval($ordersQuery->sum('delivery_charge'));

        $avgRating = DB::table('order_ratings')
            ->join('orders', 'order_ratings.order_id', '=', 'orders.id')
            ->where('orders.delivery_boy_id', $deliveryBoyId)
            ->whereBetween('orders.created_at', [$start, $end])
            ->avg('order_ratings.delivery_boy_rating');

        return [
            'deliveries' => $totalDeliveries,
            'earnings' => $totalEarnings,
            'avg_rating' => $avgRating ?? 0,
        ];
    }

    /**
     * Get recent deliveries.
     */
    private function getRecentDeliveries($deliveryBoyId, Carbon $start, Carbon $end, int $limit = 20)
    {
        $orders = Order::where('delivery_boy_id', $deliveryBoyId)
            ->whereBetween('created_at', [$start, $end])
            ->whereNotIn('active_status', [1])
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get();

        $statusMap = [
            2 => 'Received', 3 => 'Processed', 5 => 'Out for Delivery',
            6 => 'Delivered', 7 => 'Cancelled', 8 => 'Returned',
        ];

        $recentDeliveries = [];
        foreach ($orders as $order) {
            $tip = 0;
            $meta = $order->cart_metadata;
            if ($meta && isset($meta['billing_summary']['delivery_tip'])) {
                $tip = floatval($meta['billing_summary']['delivery_tip']);
            }

            $rating = DB::table('order_ratings')
                ->where('order_id', $order->id)
                ->value('delivery_boy_rating');

            $zone = $order->address && $order->address->city ? $order->address->city->name : '-';

            $recentDeliveries[] = [
                'order_id' => $order->id,
                'unique_order_id' => $order->order_number,
                'customer_name' => $order->user ? $order->user->name : '-',
                'zone' => $zone,
                'earnings' => round(floatval($order->delivery_charge) + $tip, 2),
                'tip' => round($tip, 2),
                'status' => $statusMap[$order->active_status] ?? 'Unknown',
                'rating' => $rating ? round($rating, 1) : '-',
                'created_at' => Carbon::parse($order->created_at)->format('d M Y, h:i A'),
            ];
        }

        return $recentDeliveries;
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
    public function exportExcel(Request $request, $deliveryBoyId)
    {
        return response()->json(['message' => 'Excel export not yet implemented']);
    }

    /**
     * Export as PDF.
     */
    public function exportPdf(Request $request, $deliveryBoyId)
    {
        return response()->json(['message' => 'PDF export not yet implemented']);
    }
}
