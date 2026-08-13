<?php

namespace App\Http\Controllers\API\Admin;

use App\Http\Controllers\Controller;
use App\Helpers\CommonHelper;
use App\Models\City;
use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyTransaction;
use App\Models\Order;
use App\Models\OrderStatusList;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class DriverPerformanceController extends Controller
{
    /**
     * Get Performance Dashboard Data
     */
    public function getDashboardData(Request $request)
    {
        $data = [];

        // Get filter parameters
        $period   = $request->input('period', 'monthly'); // daily, weekly, monthly, yearly
        $startDate = $request->input('start_date');
        $endDate   = $request->input('end_date');
        $driverId  = $request->input('driver_id');
        $cityId    = $request->input('city_id');

        // Set date range based on period
        $dateRange = $this->getDateRange($period, $startDate, $endDate);

        // Resolve all valid city IDs once (used by "other" filter)
        $allCityIds = $cityId ? City::pluck('id') : collect();

        // Overview Stats
        $data['overview'] = $this->getOverviewStats($dateRange, $driverId, $cityId, $allCityIds);

        // Top Drivers
        $data['top_drivers'] = $this->getTopDrivers($dateRange, 10, $cityId, $allCityIds);

        // Earnings Chart Data
        $data['earnings_chart'] = $this->getEarningsChartData($dateRange, $period, $driverId, $cityId, $allCityIds);

        // Orders Chart Data
        $data['orders_chart'] = $this->getOrdersChartData($dateRange, $period, $driverId, $cityId, $allCityIds);

        // Driver Distribution (Pie Chart)
        $data['driver_distribution'] = $this->getDriverDistribution($cityId, $allCityIds);

        // Performance by Day of Week
        $data['performance_by_day'] = $this->getPerformanceByDayOfWeek($dateRange, $driverId, $cityId, $allCityIds);

        // Current month and year for display
        $data['current_month'] = Carbon::now()->format('F Y');

        return CommonHelper::responseWithData($data);
    }

    /**
     * Apply city filter to a query that already has delivery_boys joined.
     * $prefix = the table alias used for delivery_boys in the join.
     */
    private function applyCityFilterJoined($query, $cityId, $allCityIds, $prefix = 'delivery_boys')
    {
        if ($cityId === 'other') {
            $query->where(function ($q) use ($allCityIds, $prefix) {
                $q->whereNull("{$prefix}.city_id")
                  ->orWhere("{$prefix}.city_id", 0)
                  ->orWhere("{$prefix}.city_id", '')
                  ->orWhereNotIn("{$prefix}.city_id", $allCityIds);
            });
        } else {
            $query->where("{$prefix}.city_id", $cityId);
        }

        return $query;
    }

    /**
     * Apply city filter directly on a DeliveryBoy model query (city_id is on the model table itself).
     */
    private function applyCityFilterDirect($query, $cityId, $allCityIds)
    {
        if ($cityId === 'other') {
            $query->where(function ($q) use ($allCityIds) {
                $q->whereNull('city_id')
                  ->orWhere('city_id', 0)
                  ->orWhere('city_id', '')
                  ->orWhereNotIn('city_id', $allCityIds);
            });
        } else {
            $query->where('city_id', $cityId);
        }

        return $query;
    }

    /**
     * Get Overview Statistics
     */
    private function getOverviewStats($dateRange, $driverId = null, $cityId = null, $allCityIds = null)
    {
        $query = DeliveryBoyTransaction::select('delivery_boy_transactions.*')
            ->whereBetween('delivery_boy_transactions.created_at', [$dateRange['start'], $dateRange['end']])
            ->where('delivery_boy_transactions.type', '!=', 'incentive');

        if ($cityId) {
            $query->join('delivery_boys', 'delivery_boy_transactions.delivery_boy_id', '=', 'delivery_boys.id');
            $this->applyCityFilterJoined($query, $cityId, $allCityIds);
        }

        if ($driverId) {
            $query->where('delivery_boy_transactions.delivery_boy_id', $driverId);
        }

        $transactions = $query->get();

        // Total Earnings
        $totalEarnings = $transactions->sum('driver_earnings');

        // Total Orders
        $totalOrders = $transactions->count();

        // Unique Drivers
        $uniqueDrivers = $transactions->pluck('delivery_boy_id')->unique()->count();

        // Average Earnings per Order
        $avgEarningsPerOrder = $totalOrders > 0 ? round($totalEarnings / $totalOrders, 2) : 0;

        // Average Orders per Driver
        $avgOrdersPerDriver = $uniqueDrivers > 0 ? round($totalOrders / $uniqueDrivers, 2) : 0;

        // Delivered Orders Count
        $deliveredOrders = Order::from('orders')
            ->whereBetween('orders.updated_at', [$dateRange['start'], $dateRange['end']])
            ->where('orders.active_status', OrderStatusList::$delivered);

        if ($driverId) {
            $deliveredOrders->where('orders.delivery_boy_id', $driverId);
        }
        if ($cityId) {
            $deliveredOrders->join('delivery_boys as db_ov', 'orders.delivery_boy_id', '=', 'db_ov.id');
            $this->applyCityFilterJoined($deliveredOrders, $cityId, $allCityIds, 'db_ov');
        }
        $deliveredCount = $deliveredOrders->count();

        // Active Drivers (status = approved/active)
        $activeDriversQuery = DeliveryBoy::where('status', DeliveryBoy::$statusActive);
        $totalDriversQuery  = DeliveryBoy::query();
        if ($cityId) {
            $this->applyCityFilterDirect($activeDriversQuery, $cityId, $allCityIds);
            $this->applyCityFilterDirect($totalDriversQuery, $cityId, $allCityIds);
        }
        $activeDrivers = $activeDriversQuery->count();
        $totalDrivers  = $totalDriversQuery->count();

        return [
            'total_earnings'        => round($totalEarnings, 2),
            'total_orders'          => $totalOrders,
            'delivered_orders'      => $deliveredCount,
            'unique_drivers'        => $uniqueDrivers,
            'active_drivers'        => $activeDrivers,
            'total_drivers'         => $totalDrivers,
            'avg_earnings_per_order' => $avgEarningsPerOrder,
            'avg_orders_per_driver'  => $avgOrdersPerDriver,
        ];
    }

    /**
     * Get Top Drivers
     */
    private function getTopDrivers($dateRange, $limit = 10, $cityId = null, $allCityIds = null)
    {
        $query = DeliveryBoyTransaction::select(
                'delivery_boy_transactions.delivery_boy_id',
                'delivery_boys.name as driver_name',
                'delivery_boys.mobile',
                'delivery_boys.profile_image',
                DB::raw("COUNT(delivery_boy_transactions.id) as order_count"),
                DB::raw("ROUND(SUM(delivery_boy_transactions.driver_earnings), 2) as total_earnings")
            )
            ->leftJoin('delivery_boys', 'delivery_boy_transactions.delivery_boy_id', '=', 'delivery_boys.id')
            ->where('delivery_boy_transactions.type', '!=', 'incentive')
            ->whereBetween('delivery_boy_transactions.created_at', [$dateRange['start'], $dateRange['end']])
            ->whereNotNull('delivery_boys.name');

        if ($cityId) {
            $this->applyCityFilterJoined($query, $cityId, $allCityIds);
        }

        return $query
            ->groupBy('delivery_boy_transactions.delivery_boy_id')
            ->orderBy('total_earnings', 'DESC')
            ->limit($limit)
            ->get();
    }

    /**
     * Get Earnings Chart Data
     */
    private function getEarningsChartData($dateRange, $period, $driverId = null, $cityId = null, $allCityIds = null)
    {
        $dateFormat = $this->getDateFormat($period);

        $query = DeliveryBoyTransaction::select(
                DB::raw("DATE_FORMAT(delivery_boy_transactions.created_at, '{$dateFormat}') as period"),
                DB::raw("ROUND(SUM(delivery_boy_transactions.driver_earnings), 2) as total_earnings"),
                DB::raw("COUNT(delivery_boy_transactions.id) as order_count")
            )
            ->where('delivery_boy_transactions.type', '!=', 'incentive')
            ->whereBetween('delivery_boy_transactions.created_at', [$dateRange['start'], $dateRange['end']]);

        if ($cityId) {
            $query->join('delivery_boys', 'delivery_boy_transactions.delivery_boy_id', '=', 'delivery_boys.id');
            $this->applyCityFilterJoined($query, $cityId, $allCityIds);
        }

        if ($driverId) {
            $query->where('delivery_boy_transactions.delivery_boy_id', $driverId);
        }

        $results = $query->groupBy('period')
            ->orderBy('period', 'ASC')
            ->get();

        return [
            'labels'   => $results->pluck('period')->toArray(),
            'earnings' => $results->pluck('total_earnings')->toArray(),
            'orders'   => $results->pluck('order_count')->toArray(),
        ];
    }

    /**
     * Get Orders Chart Data
     */
    private function getOrdersChartData($dateRange, $period, $driverId = null, $cityId = null, $allCityIds = null)
    {
        $dateFormat = $this->getDateFormat($period);

        // Helper closure to build per-status order query
        $buildOrderQuery = function ($status, $dbAlias) use ($dateRange, $dateFormat, $driverId, $cityId, $allCityIds) {
            $q = Order::from('orders')
                ->select(
                    DB::raw("DATE_FORMAT(orders.updated_at, '{$dateFormat}') as period"),
                    DB::raw("COUNT(orders.id) as count")
                )
                ->where('orders.active_status', $status)
                ->whereBetween('orders.updated_at', [$dateRange['start'], $dateRange['end']]);

            if ($driverId) {
                $q->where('orders.delivery_boy_id', $driverId);
            }

            if ($cityId) {
                $q->join("delivery_boys as {$dbAlias}", 'orders.delivery_boy_id', '=', "{$dbAlias}.id");
                $this->applyCityFilterJoined($q, $cityId, $allCityIds, $dbAlias);
            }

            return $q->groupBy('period')->orderBy('period', 'ASC')->pluck('count', 'period')->toArray();
        };

        $delivered = $buildOrderQuery(OrderStatusList::$delivered, 'db_del');
        $cancelled = $buildOrderQuery(OrderStatusList::$cancelled, 'db_can');
        $returned  = $buildOrderQuery(OrderStatusList::$returned,  'db_ret');

        // Merge all labels
        $allLabels = array_unique(array_merge(
            array_keys($delivered),
            array_keys($cancelled),
            array_keys($returned)
        ));
        sort($allLabels);

        $deliveredData = [];
        $cancelledData = [];
        $returnedData  = [];

        foreach ($allLabels as $label) {
            $deliveredData[] = $delivered[$label] ?? 0;
            $cancelledData[] = $cancelled[$label] ?? 0;
            $returnedData[]  = $returned[$label]  ?? 0;
        }

        return [
            'labels'    => $allLabels,
            'delivered' => $deliveredData,
            'cancelled' => $cancelledData,
            'returned'  => $returnedData,
        ];
    }

    /**
     * Get Driver Distribution (Pie Chart)
     */
    private function getDriverDistribution($cityId = null, $allCityIds = null)
    {
        $buildQuery = function ($baseQuery) use ($cityId, $allCityIds) {
            if ($cityId) {
                $this->applyCityFilterDirect($baseQuery, $cityId, $allCityIds);
            }
            return $baseQuery;
        };

        $active      = $buildQuery(DeliveryBoy::where('status', DeliveryBoy::$statusActive))->count();
        $registered  = $buildQuery(DeliveryBoy::where('status', DeliveryBoy::$statusRegistered))->count();
        $deactivated = $buildQuery(DeliveryBoy::where('status', DeliveryBoy::$statusDeactivated))->count();
        $rejected    = $buildQuery(DeliveryBoy::where('status', DeliveryBoy::$statusRejected))->count();

        return [
            'labels' => ['Active', 'Registered', 'Deactivated', 'Rejected'],
            'data'   => [$active, $registered, $deactivated, $rejected],
            'colors' => ['#28a745', '#ffc107', '#dc3545', '#6c757d'],
        ];
    }

    /**
     * Get Performance by Day of Week
     */
    private function getPerformanceByDayOfWeek($dateRange, $driverId = null, $cityId = null, $allCityIds = null)
    {
        $query = DeliveryBoyTransaction::select(
                DB::raw("DAYOFWEEK(delivery_boy_transactions.created_at) as day_of_week"),
                DB::raw("ROUND(SUM(delivery_boy_transactions.driver_earnings), 2) as total_earnings"),
                DB::raw("COUNT(delivery_boy_transactions.id) as order_count")
            )
            ->where('delivery_boy_transactions.type', '!=', 'incentive')
            ->whereBetween('delivery_boy_transactions.created_at', [$dateRange['start'], $dateRange['end']]);

        if ($cityId) {
            $query->join('delivery_boys', 'delivery_boy_transactions.delivery_boy_id', '=', 'delivery_boys.id');
            $this->applyCityFilterJoined($query, $cityId, $allCityIds);
        }

        if ($driverId) {
            $query->where('delivery_boy_transactions.delivery_boy_id', $driverId);
        }

        $results = $query->groupBy('day_of_week')
            ->orderBy('day_of_week', 'ASC')
            ->get()
            ->keyBy('day_of_week');

        $days     = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        $earnings = [];
        $orders   = [];

        for ($i = 1; $i <= 7; $i++) {
            $earnings[] = $results->has($i) ? $results[$i]->total_earnings : 0;
            $orders[]   = $results->has($i) ? $results[$i]->order_count : 0;
        }

        return [
            'labels'   => $days,
            'earnings' => $earnings,
            'orders'   => $orders,
        ];
    }

    /**
     * Get All Drivers List for Filter
     */
    public function getDriversList(Request $request)
    {
        $query = DeliveryBoy::select('id', 'name', 'mobile', 'status')
            ->where('status', '!=', DeliveryBoy::$statusRemoved)
            ->orderBy('name', 'ASC');

        if ($request->has('search') && !empty($request->input('search'))) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('mobile', 'like', "%{$search}%");
            });
        }

        $drivers = $query->get();

        return CommonHelper::responseWithData($drivers);
    }

    /**
     * Get Individual Driver Performance
     */
    public function getDriverPerformance(Request $request)
    {
        $driverId = $request->input('driver_id');

        if (!$driverId) {
            return CommonHelper::responseError('Driver ID is required');
        }

        $driver = DeliveryBoy::with('city', 'vehicle')->find($driverId);

        if (!$driver) {
            return CommonHelper::responseError('Driver not found');
        }

        $period    = $request->input('period', 'monthly');
        $startDate = $request->input('start_date');
        $endDate   = $request->input('end_date');
        $dateRange = $this->getDateRange($period, $startDate, $endDate);

        // Driver Info
        $data['driver'] = [
            'id'              => $driver->id,
            'name'            => $driver->name,
            'mobile'          => $driver->mobile,
            'email'           => $driver->email,
            'status'          => $driver->status,
            'city'            => $driver->city ? $driver->city->name : null,
            'vehicle'         => $driver->vehicle ? $driver->vehicle->name : null,
            'balance'         => $driver->balance,
            'profile_image_url' => $driver->profile_image_url,
        ];

        // Performance Stats (no zone filter for individual driver view)
        $data['stats'] = $this->getOverviewStats($dateRange, $driverId);

        // Recent Transactions
        $data['recent_transactions'] = DeliveryBoyTransaction::select(
                'id', 'order_id', 'type', 'driver_earnings', 'amount', 'created_at'
            )
            ->where('delivery_boy_id', $driverId)
            ->orderBy('created_at', 'DESC')
            ->limit(20)
            ->get();

        // Earnings Chart
        $data['earnings_chart'] = $this->getEarningsChartData($dateRange, $period, $driverId);

        // Performance by Day
        $data['performance_by_day'] = $this->getPerformanceByDayOfWeek($dateRange, $driverId);

        return CommonHelper::responseWithData($data);
    }

    /**
     * Get Weekly Performance Comparison
     */
    public function getWeeklyComparison(Request $request)
    {
        $currentWeekStart = Carbon::now()->startOfWeek();
        $currentWeekEnd   = Carbon::now()->endOfWeek();
        $lastWeekStart    = Carbon::now()->subWeek()->startOfWeek();
        $lastWeekEnd      = Carbon::now()->subWeek()->endOfWeek();

        // Current Week Stats
        $currentWeek = DeliveryBoyTransaction::where('type', '!=', 'incentive')
            ->whereBetween('created_at', [$currentWeekStart, $currentWeekEnd])
            ->selectRaw('ROUND(SUM(driver_earnings), 2) as total_earnings, COUNT(id) as order_count')
            ->first();

        // Last Week Stats
        $lastWeek = DeliveryBoyTransaction::where('type', '!=', 'incentive')
            ->whereBetween('created_at', [$lastWeekStart, $lastWeekEnd])
            ->selectRaw('ROUND(SUM(driver_earnings), 2) as total_earnings, COUNT(id) as order_count')
            ->first();

        // Calculate percentage changes
        $earningsChange = $lastWeek->total_earnings > 0
            ? round((($currentWeek->total_earnings - $lastWeek->total_earnings) / $lastWeek->total_earnings) * 100, 2)
            : 0;

        $ordersChange = $lastWeek->order_count > 0
            ? round((($currentWeek->order_count - $lastWeek->order_count) / $lastWeek->order_count) * 100, 2)
            : 0;

        return CommonHelper::responseWithData([
            'current_week' => [
                'earnings'   => $currentWeek->total_earnings ?? 0,
                'orders'     => $currentWeek->order_count ?? 0,
                'start_date' => $currentWeekStart->format('Y-m-d'),
                'end_date'   => $currentWeekEnd->format('Y-m-d'),
            ],
            'last_week' => [
                'earnings'   => $lastWeek->total_earnings ?? 0,
                'orders'     => $lastWeek->order_count ?? 0,
                'start_date' => $lastWeekStart->format('Y-m-d'),
                'end_date'   => $lastWeekEnd->format('Y-m-d'),
            ],
            'changes' => [
                'earnings_percentage' => $earningsChange,
                'orders_percentage'   => $ordersChange,
            ]
        ]);
    }

    /**
     * Get Monthly Performance Comparison
     */
    public function getMonthlyComparison(Request $request)
    {
        $currentMonthStart = Carbon::now()->startOfMonth();
        $currentMonthEnd   = Carbon::now()->endOfMonth();
        $lastMonthStart    = Carbon::now()->subMonth()->startOfMonth();
        $lastMonthEnd      = Carbon::now()->subMonth()->endOfMonth();

        // Current Month Stats
        $currentMonth = DeliveryBoyTransaction::where('type', '!=', 'incentive')
            ->whereBetween('created_at', [$currentMonthStart, $currentMonthEnd])
            ->selectRaw('ROUND(SUM(driver_earnings), 2) as total_earnings, COUNT(id) as order_count')
            ->first();

        // Last Month Stats
        $lastMonth = DeliveryBoyTransaction::where('type', '!=', 'incentive')
            ->whereBetween('created_at', [$lastMonthStart, $lastMonthEnd])
            ->selectRaw('ROUND(SUM(driver_earnings), 2) as total_earnings, COUNT(id) as order_count')
            ->first();

        // Calculate percentage changes
        $earningsChange = $lastMonth->total_earnings > 0
            ? round((($currentMonth->total_earnings - $lastMonth->total_earnings) / $lastMonth->total_earnings) * 100, 2)
            : 0;

        $ordersChange = $lastMonth->order_count > 0
            ? round((($currentMonth->order_count - $lastMonth->order_count) / $lastMonth->order_count) * 100, 2)
            : 0;

        return CommonHelper::responseWithData([
            'current_month' => [
                'name'     => Carbon::now()->format('F'),
                'earnings' => $currentMonth->total_earnings ?? 0,
                'orders'   => $currentMonth->order_count ?? 0,
            ],
            'last_month' => [
                'name'     => Carbon::now()->subMonth()->format('F'),
                'earnings' => $lastMonth->total_earnings ?? 0,
                'orders'   => $lastMonth->order_count ?? 0,
            ],
            'changes' => [
                'earnings_percentage' => $earningsChange,
                'orders_percentage'   => $ordersChange,
            ]
        ]);
    }

    /**
     * Get Yearly Performance Data
     */
    public function getYearlyPerformance(Request $request)
    {
        $year = $request->input('year', Carbon::now()->year);

        $monthlyData = DeliveryBoyTransaction::select(
                DB::raw("MONTH(created_at) as month"),
                DB::raw("ROUND(SUM(driver_earnings), 2) as total_earnings"),
                DB::raw("COUNT(id) as order_count"),
                DB::raw("COUNT(DISTINCT delivery_boy_id) as unique_drivers")
            )
            ->where('type', '!=', 'incentive')
            ->whereYear('created_at', $year)
            ->groupBy('month')
            ->orderBy('month', 'ASC')
            ->get()
            ->keyBy('month');

        $months   = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        $earnings = [];
        $orders   = [];
        $drivers  = [];

        for ($i = 1; $i <= 12; $i++) {
            $earnings[] = $monthlyData->has($i) ? $monthlyData[$i]->total_earnings : 0;
            $orders[]   = $monthlyData->has($i) ? $monthlyData[$i]->order_count : 0;
            $drivers[]  = $monthlyData->has($i) ? $monthlyData[$i]->unique_drivers : 0;
        }

        // Calculate totals
        $totalEarnings = array_sum($earnings);
        $totalOrders   = array_sum($orders);

        return CommonHelper::responseWithData([
            'year'    => $year,
            'labels'  => $months,
            'earnings' => $earnings,
            'orders'  => $orders,
            'drivers' => $drivers,
            'totals'  => [
                'earnings' => round($totalEarnings, 2),
                'orders'   => $totalOrders,
            ]
        ]);
    }

    /**
     * Helper: Get Date Range based on period
     */
    private function getDateRange($period, $startDate = null, $endDate = null)
    {
        if ($startDate && $endDate) {
            return [
                'start' => Carbon::parse($startDate)->startOfDay(),
                'end'   => Carbon::parse($endDate)->endOfDay(),
            ];
        }

        switch ($period) {
            case 'daily':
                return [
                    'start' => Carbon::now()->startOfDay(),
                    'end'   => Carbon::now()->endOfDay(),
                ];
            case 'weekly':
                return [
                    'start' => Carbon::now()->startOfWeek(),
                    'end'   => Carbon::now()->endOfWeek(),
                ];
            case 'yearly':
                return [
                    'start' => Carbon::now()->startOfYear(),
                    'end'   => Carbon::now()->endOfYear(),
                ];
            case 'monthly':
            default:
                return [
                    'start' => Carbon::now()->startOfMonth(),
                    'end'   => Carbon::now()->endOfMonth(),
                ];
        }
    }

    /**
     * Helper: Get GROUP BY clause based on period
     */
    private function getGroupByClause($period)
    {
        switch ($period) {
            case 'daily':
                return 'HOUR(created_at)';
            case 'weekly':
                return 'DAYOFWEEK(created_at)';
            case 'yearly':
                return 'MONTH(created_at)';
            case 'monthly':
            default:
                return 'DATE(created_at)';
        }
    }

    /**
     * Helper: Get DATE_FORMAT based on period
     */
    private function getDateFormat($period)
    {
        switch ($period) {
            case 'daily':
                return '%H:00';
            case 'weekly':
                return '%a';
            case 'yearly':
                return '%b';
            case 'monthly':
            default:
                return '%d %b';
        }
    }
}
