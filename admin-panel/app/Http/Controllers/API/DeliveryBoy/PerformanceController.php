<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyDailyTracking;
use App\Models\Order;
use App\Models\DeliveryBoyTransaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use App\Models\Setting;
use App\Services\FirestoreDeliveryBoyService;

class PerformanceController extends Controller
{
    /**
     * Get earnings performance data - Daily, Weekly, Monthly
     * GET /api/delivery_boy/performance/earnings
     *
     * Query Parameters:
     * - period: 'daily', 'weekly', or 'monthly' (default: daily)
     * - date: For daily (YYYY-MM-DD), or specific week/month (defaults to today)
     * - offset: Navigation offset (-1 for previous, 1 for next, 0 for current)
     * - from_date: For weekly/monthly range queries (YYYY-MM-DD)
     * - to_date: For weekly/monthly range queries (YYYY-MM-DD)
     */
    public function getEarningsPerformance(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            $period = $request->query('period', 'daily'); // daily, weekly, monthly
            $date = $request->query('date'); // specific date or null for today
            $offset = (int) $request->query('offset', 0); // Navigation offset
            $fromDate = $request->query('from_date'); // For range queries
            $toDate = $request->query('to_date'); // For range queries

            // Apply offset to date if provided
            if ($offset !== 0 && !$fromDate && !$toDate) {
                $baseDate = $date ? Carbon::parse($date) : Carbon::today();

                if ($period === 'daily') {
                    $date = $baseDate->addDays($offset)->toDateString();
                } elseif ($period === 'weekly') {
                    $date = $baseDate->addWeeks($offset)->toDateString();
                } elseif ($period === 'monthly') {
                    $date = $baseDate->addMonths($offset)->toDateString();
                }
            }

            $data = match ($period) {
                'daily' => $this->getDailyPerformance($deliveryBoy, $date),
                'weekly' => $this->getWeeklyPerformance($deliveryBoy, $date, $fromDate, $toDate),
                'monthly' => $this->getMonthlyPerformance($deliveryBoy, $date, $fromDate, $toDate),
                default => $this->getDailyPerformance($deliveryBoy, $date)
            };

            return response()->json([
                'status' => true,
                'message' => ucfirst($period) . ' performance retrieved successfully',
                'data' => $data
            ]);

        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get daily performance data
     */
    private function getDailyPerformance(DeliveryBoy $deliveryBoy, $dateStr = null)
    {
        $date = $dateStr ? Carbon::parse($dateStr) : Carbon::today();

        $tracking = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
            ->whereDate('tracking_date', $date->toDateString())
            ->first();

        $todayOrders = Order::where('delivery_boy_id', $deliveryBoy->id)
            ->whereDate('created_at', $date->toDateString())
            ->get();

        // Get earnings by type from transactions
        $earningsByType = $this->getEarningsByType($deliveryBoy, $date, $date);

        // Get daily metrics (distance and login)
        $dailyMetrics = $this->getDailyMetrics($deliveryBoy, $date);

        return [
            'period_type' => 'daily',
            'date' => $date->toIso8601String(),
            'earnings_overview' => [
                'total_earnings' => (float) $earningsByType['total'],
                'order_earnings' => (float) $earningsByType['order'],
                'multi_order_earnings' => (float) $earningsByType['multi_order'],
                'incentive_earnings' => (float) $earningsByType['incentive'],
                'referral_bonus' => (float) $earningsByType['referral_bonus'],
                'tips' => (float) $earningsByType['tips'],
            ],
            'todays_performance' => [
                'distance_covered' => $dailyMetrics['distance'],
                'total_orders' => $todayOrders->count(),
                'orders_completed' => (int) ($tracking ? $tracking->gigs_completed : 0),
                'orders_cancelled' => (int) ($tracking ? $tracking->orders_cancelled : 0),
                'login_hours' => $this->formatLoginHours($dailyMetrics['login_minutes'] / 60),
            ],
            'earnings_breakdown' => $this->getEarningsBreakdown($deliveryBoy, $date, $date),
            'available_dates' => $this->getAvailableDates($deliveryBoy, 'daily', $date->toDateString()),
        ];
    }

    /**
     * Get weekly performance data
     * If from_date and to_date provided, returns range of weeks
     * Otherwise, returns single week based on date parameter
     */
    private function getWeeklyPerformance(DeliveryBoy $deliveryBoy, $dateStr = null, $fromDateStr = null, $toDateStr = null)
    {
        // If date range provided, return multiple weeks
        if ($fromDateStr && $toDateStr) {
            return $this->getWeeklyRangePerformance($deliveryBoy, $fromDateStr, $toDateStr);
        }

        // Single week view
        $date = $dateStr ? Carbon::parse($dateStr) : Carbon::today();

        // Get week start and end
        $weekStart = $date->copy()->startOfWeek();
        $weekEnd = $date->copy()->endOfWeek();

        $trackings = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
            ->whereBetween('tracking_date', [$weekStart->toDateString(), $weekEnd->toDateString()])
            ->get();

        $orders = Order::where('delivery_boy_id', $deliveryBoy->id)
            ->whereBetween('created_at', [$weekStart->toDateTimeString(), $weekEnd->copy()->endOfDay()->toDateTimeString()])
            ->get();

        // Daily breakdown for chart
        $dailyData = [];
        for ($i = 0; $i < 7; $i++) {
            $currentDay = $weekStart->copy()->addDays($i);
            $dayTracking = $trackings->firstWhere('tracking_date', $currentDay->toDateString());

            $dailyOrdersCount = $orders->filter(function($order) use ($currentDay) {
                return Carbon::parse($order->created_at)->toDateString() === $currentDay->toDateString();
            })->count();

            // Get earnings by type for this day
            $dayEarningsByType = $this->getEarningsByType($deliveryBoy, $currentDay, $currentDay);

            // Get daily metrics (distance and login)
            $dailyMetrics = $this->getDailyMetrics($deliveryBoy, $currentDay);

            $dailyData[] = [
                'date' => $currentDay->toDateString(),
                'day_name' => $currentDay->format('D'),
                'day_number' => $currentDay->day,
                'total_earnings' => (float) $dayEarningsByType['total'],
                'order_earnings' => (float) $dayEarningsByType['order'],
                'multi_order_earnings' => (float) $dayEarningsByType['multi_order'],
                'incentive_earnings' => (float) $dayEarningsByType['incentive'],
                'referral_bonus' => (float) $dayEarningsByType['referral_bonus'],
                'tips' => (float) $dayEarningsByType['tips'],
                'total_orders' => $dailyOrdersCount,
                'orders_completed' => (int) ($dayTracking ? $dayTracking->gigs_completed : 0),
                'orders_cancelled' => (int) ($dayTracking ? $dayTracking->orders_cancelled : 0),
                'distance_covered' => $dailyMetrics['distance'],
                'login_hours' => $this->formatLoginHours($dailyMetrics['login_minutes'] / 60),
            ];
        }

        // Get week earnings by type
        $weekEarningsByType = $this->getEarningsByType($deliveryBoy, $weekStart, $weekEnd);

        return [
            'period_type' => 'weekly',
            'week_start' => $weekStart->toIso8601String(),
            'week_end' => $weekEnd->toIso8601String(),
            'earnings_overview' => [
                'total_earnings' => (float) $weekEarningsByType['total'],
                'order_earnings' => (float) $weekEarningsByType['order'],
                'multi_order_earnings' => (float) $weekEarningsByType['multi_order'],
                'incentive_earnings' => (float) $weekEarningsByType['incentive'],
                'referral_bonus' => (float) $weekEarningsByType['referral_bonus'],
                'tips' => (float) $weekEarningsByType['tips'],
            ],
            'todays_performance' => [
                'distance_covered' => (float) $trackings->sum('total_distance_km'),
                'total_orders' => $orders->count(),
                'orders_completed' => (int) $trackings->sum('gigs_completed'),
                'orders_cancelled' => (int) $trackings->sum('orders_cancelled'),
                'login_hours' => $this->formatLoginHours($trackings->sum('total_login_minutes') / 60),
            ],
            'daily_breakdown' => $dailyData,
            'earnings_breakdown' => $this->getEarningsBreakdown($deliveryBoy, $weekStart, $weekEnd),
            'available_dates' => $this->getAvailableDates($deliveryBoy, 'weekly', $date->toDateString()),
        ];
    }

    /**
     * Get weekly performance for a date range (multiple weeks)
     */
    private function getWeeklyRangePerformance(DeliveryBoy $deliveryBoy, $fromDateStr, $toDateStr)
    {
        $fromDate = Carbon::parse($fromDateStr);
        $toDate = Carbon::parse($toDateStr);

        $trackings = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
            ->whereBetween('tracking_date', [$fromDate->toDateString(), $toDate->toDateString()])
            ->orderBy('tracking_date')
            ->get();

        $orders = Order::where('delivery_boy_id', $deliveryBoy->id)
            ->whereBetween('created_at', [$fromDate->startOfDay(), $toDate->endOfDay()])
            ->get();

        // Group by week
        $weeklyData = [];
        $currentWeekStart = $fromDate->copy()->startOfWeek();

        while ($currentWeekStart->lte($toDate)) {
            $currentWeekEnd = $currentWeekStart->copy()->endOfWeek();
            if ($currentWeekEnd->gt($toDate)) {
                $currentWeekEnd = $toDate->copy();
            }

            $weekTrackings = $trackings->whereBetween('tracking_date', [
                $currentWeekStart->toDateString(),
                $currentWeekEnd->toDateString()
            ]);

            $weekOrders = $orders->filter(function($order) use ($currentWeekStart, $currentWeekEnd) {
                $orderDate = Carbon::parse($order->created_at)->toDateString();
                return $orderDate >= $currentWeekStart->toDateString() && $orderDate <= $currentWeekEnd->toDateString();
            });

            if ($weekTrackings->count() > 0 || $weekOrders->count() > 0) {
                $weekEnd = min($currentWeekEnd, $toDate);
                $weekEarnings = $this->getEarningsByType($deliveryBoy, $currentWeekStart, $weekEnd);

                $weeklyData[] = [
                    'week' => 'Week ' . count($weeklyData) + 1,
                    'start_date' => $currentWeekStart->toDateString(),
                    'end_date' => $weekEnd->toDateString(),
                    'earnings' => (float) $weekEarnings['total'],
                    'order_earnings' => (float) $weekEarnings['order'],
                    'multi_order_earnings' => (float) $weekEarnings['multi_order'],
                    'incentive_earnings' => (float) $weekEarnings['incentive'],
                    'referral_bonus' => (float) $weekEarnings['referral_bonus'],
                    'tips' => (float) $weekEarnings['tips'],
                    'orders' => $weekOrders->count(),
                    'orders_completed' => (int) $weekTrackings->sum('gigs_completed'),
                    'orders_cancelled' => (int) $weekTrackings->sum('orders_cancelled'),
                    'distance' => (float) $weekTrackings->sum('total_distance_km'),
                    'login_hours' => $this->formatLoginHours($weekTrackings->sum('total_login_minutes') / 60),
                ];
            }

            $currentWeekStart->addWeek();
        }

        // Get range earnings by type
        $rangeEarnings = $this->getEarningsByType($deliveryBoy, $fromDate, $toDate);

        return [
            'period_type' => 'weekly_range',
            'range_start' => $fromDate->toIso8601String(),
            'range_end' => $toDate->toIso8601String(),
            'earnings_overview' => [
                'total_earnings' => (float) $rangeEarnings['total'],
                'order_earnings' => (float) $rangeEarnings['order'],
                'multi_order_earnings' => (float) $rangeEarnings['multi_order'],
                'incentive_earnings' => (float) $rangeEarnings['incentive'],
                'referral_bonus' => (float) $rangeEarnings['referral_bonus'],
                'tips' => (float) $rangeEarnings['tips'],
            ],
            'performance_summary' => [
                'distance_covered' => (float) $trackings->sum('total_distance_km'),
                'total_orders' => $orders->count(),
                'orders_completed' => (int) $trackings->sum('gigs_completed'),
                'orders_cancelled' => (int) $trackings->sum('orders_cancelled'),
                'login_hours' => $this->formatLoginHours($trackings->sum('total_login_minutes') / 60),
            ],
            'weekly_breakdown' => $weeklyData,
        ];
    }

    /**
     * Get monthly performance data
     * If from_date and to_date provided, returns range of months
     * Otherwise, returns single month based on date parameter
     */
    private function getMonthlyPerformance(DeliveryBoy $deliveryBoy, $dateStr = null, $fromDateStr = null, $toDateStr = null)
    {
        // If date range provided, return multiple months
        if ($fromDateStr && $toDateStr) {
            return $this->getMonthlyRangePerformance($deliveryBoy, $fromDateStr, $toDateStr);
        }

        // Single month view
        $date = $dateStr ? Carbon::parse($dateStr) : Carbon::today();

        // Get month start and end
        $monthStart = $date->copy()->startOfMonth();
        $monthEnd = $date->copy()->endOfMonth();

        $trackings = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
            ->whereBetween('tracking_date', [$monthStart->toDateString(), $monthEnd->toDateString()])
            ->get();

        $orders = Order::where('delivery_boy_id', $deliveryBoy->id)
            ->whereBetween('created_at', [$monthStart->startOfDay(), $monthEnd->endOfDay()])
            ->get();

        // Weekly breakdown for chart
        $weeklyData = [];
        $currentWeekStart = $monthStart->copy()->startOfWeek();

        while ($currentWeekStart->lte($monthEnd)) {
            $currentWeekEnd = $currentWeekStart->copy()->endOfWeek();

            $weekTrackings = $trackings->whereBetween('tracking_date', [
                $currentWeekStart->toDateString(),
                min($currentWeekEnd, $monthEnd)->toDateString()
            ]);

            $weekOrders = $orders->filter(function($order) use ($currentWeekStart, $currentWeekEnd, $monthEnd) {
                $orderDate = Carbon::parse($order->created_at)->toDateString();
                $weekEnd = min($currentWeekEnd, $monthEnd)->toDateString();
                return $orderDate >= $currentWeekStart->toDateString() && $orderDate <= $weekEnd;
            });

            if ($weekTrackings->count() > 0 || $weekOrders->count() > 0) {
                $weekEnd = min($currentWeekEnd, $monthEnd);
                $weekEarnings = $this->getEarningsByType($deliveryBoy, $currentWeekStart, $weekEnd);

                $weeklyData[] = [
                    'week' => 'Week ' . count($weeklyData) + 1,
                    'start_date' => $currentWeekStart->toDateString(),
                    'end_date' => $weekEnd->toDateString(),
                    'earnings' => (float) $weekEarnings['total'],
                    'order_earnings' => (float) $weekEarnings['order'],
                    'multi_order_earnings' => (float) $weekEarnings['multi_order'],
                    'incentive_earnings' => (float) $weekEarnings['incentive'],
                    'referral_bonus' => (float) $weekEarnings['referral_bonus'],
                    'tips' => (float) $weekEarnings['tips'],
                    'orders' => $weekOrders->count(),
                    'orders_completed' => (int) $weekTrackings->sum('gigs_completed'),
                    'orders_cancelled' => (int) $weekTrackings->sum('orders_cancelled'),
                    'distance' => (float) $weekTrackings->sum('total_distance_km'),
                    'login_hours' => $this->formatLoginHours($weekTrackings->sum('total_login_minutes') / 60),
                ];
            }

            $currentWeekStart->addWeek();
        }

        // Get month earnings by type
        $monthEarnings = $this->getEarningsByType($deliveryBoy, $monthStart, $monthEnd);

        return [
            'period_type' => 'monthly',
            'month' => $date->format('F Y'),
            'month_start' => $monthStart->toIso8601String(),
            'month_end' => $monthEnd->toIso8601String(),
            'earnings_overview' => [
                'total_earnings' => (float) $monthEarnings['total'],
                'order_earnings' => (float) $monthEarnings['order'],
                'multi_order_earnings' => (float) $monthEarnings['multi_order'],
                'incentive_earnings' => (float) $monthEarnings['incentive'],
                'referral_bonus' => (float) $monthEarnings['referral_bonus'],
                'tips' => (float) $monthEarnings['tips'],
            ],
            'todays_performance' => [
                'distance_covered' => (float) $trackings->sum('total_distance_km'),
                'total_orders' => $orders->count(),
                'orders_completed' => (int) $trackings->sum('gigs_completed'),
                'orders_cancelled' => (int) $trackings->sum('orders_cancelled'),
                'login_hours' => $this->formatLoginHours($trackings->sum('total_login_minutes') / 60),
            ],
            'weekly_breakdown' => $weeklyData,
            'earnings_breakdown' => $this->getEarningsBreakdown($deliveryBoy, $monthStart, $monthEnd),
            'available_dates' => $this->getAvailableDates($deliveryBoy, 'monthly', $date->toDateString()),
        ];
    }

    /**
     * Get monthly performance for a date range (multiple months)
     */
    private function getMonthlyRangePerformance(DeliveryBoy $deliveryBoy, $fromDateStr, $toDateStr)
    {
        $fromDate = Carbon::parse($fromDateStr);
        $toDate = Carbon::parse($toDateStr);

        $trackings = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
            ->whereBetween('tracking_date', [$fromDate->toDateString(), $toDate->toDateString()])
            ->orderBy('tracking_date')
            ->get();

        $orders = Order::where('delivery_boy_id', $deliveryBoy->id)
            ->whereBetween('created_at', [$fromDate->startOfDay(), $toDate->endOfDay()])
            ->get();

        // Group by month
        $monthlyData = [];
        $currentMonthStart = $fromDate->copy()->startOfMonth();

        while ($currentMonthStart->lte($toDate)) {
            $currentMonthEnd = $currentMonthStart->copy()->endOfMonth();
            if ($currentMonthEnd->gt($toDate)) {
                $currentMonthEnd = $toDate->copy();
            }

            $monthTrackings = $trackings->whereBetween('tracking_date', [
                $currentMonthStart->toDateString(),
                $currentMonthEnd->toDateString()
            ]);

            $monthOrders = $orders->filter(function($order) use ($currentMonthStart, $currentMonthEnd) {
                $orderDate = Carbon::parse($order->created_at)->toDateString();
                return $orderDate >= $currentMonthStart->toDateString() && $orderDate <= $currentMonthEnd->toDateString();
            });

            if ($monthTrackings->count() > 0 || $monthOrders->count() > 0) {
                $monthEarnings = $this->getEarningsByType($deliveryBoy, $currentMonthStart, $currentMonthEnd);

                $monthlyData[] = [
                    'month' => $currentMonthStart->format('M Y'),
                    'month_number' => count($monthlyData) + 1,
                    'start_date' => $currentMonthStart->toDateString(),
                    'end_date' => $currentMonthEnd->toDateString(),
                    'earnings' => (float) $monthEarnings['total'],
                    'order_earnings' => (float) $monthEarnings['order'],
                    'multi_order_earnings' => (float) $monthEarnings['multi_order'],
                    'incentive_earnings' => (float) $monthEarnings['incentive'],
                    'referral_bonus' => (float) $monthEarnings['referral_bonus'],
                    'tips' => (float) $monthEarnings['tips'],
                    'orders' => $monthOrders->count(),
                    'orders_completed' => (int) $monthTrackings->sum('gigs_completed'),
                    'orders_cancelled' => (int) $monthTrackings->sum('orders_cancelled'),
                    'distance' => (float) $monthTrackings->sum('total_distance_km'),
                    'login_hours' => $this->formatLoginHours($monthTrackings->sum('total_login_minutes') / 60),
                ];
            }

            $currentMonthStart->addMonth()->startOfMonth();
        }

        // Get range earnings by type
        $rangeEarnings = $this->getEarningsByType($deliveryBoy, $fromDate, $toDate);

        return [
            'period_type' => 'monthly_range',
            'range_start' => $fromDate->toIso8601String(),
            'range_end' => $toDate->toIso8601String(),
            'earnings_overview' => [
                'total_earnings' => (float) $rangeEarnings['total'],
                'order_earnings' => (float) $rangeEarnings['order'],
                'multi_order_earnings' => (float) $rangeEarnings['multi_order'],
                'incentive_earnings' => (float) $rangeEarnings['incentive'],
                'referral_bonus' => (float) $rangeEarnings['referral_bonus'],
                'tips' => (float) $rangeEarnings['tips'],
            ],
            'performance_summary' => [
                'distance_covered' => (float) $trackings->sum('total_distance_km'),
                'total_orders' => $orders->count(),
                'orders_completed' => (int) $trackings->sum('gigs_completed'),
                'orders_cancelled' => (int) $trackings->sum('orders_cancelled'),
                'login_hours' => $this->formatLoginHours($trackings->sum('total_login_minutes') / 60),
            ],
            'monthly_breakdown' => $monthlyData,
        ];
    }

    /**
     * Get earnings totals by type
     */
    private function getEarningsByType(DeliveryBoy $deliveryBoy, Carbon $startDate, Carbon $endDate)
    {
        // Get delivered orders for this delivery boy in the date range
        $orders = Order::where('delivery_boy_id', $deliveryBoy->id)
            ->whereDate('created_at', '>=', $startDate->toDateString())
            ->whereDate('created_at', '<=', $endDate->toDateString())
            ->whereIn('active_status', ['6', '7', '8'])
            ->get();

        // Pre-load transactions for these orders from delivery_boy_transactions (source of truth)
        $orderIds = $orders->pluck('id')->toArray();
        $orderTransactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
            ->whereIn('order_id', $orderIds)
            ->where('status', 'success')
            ->get()
            ->keyBy('order_id');

        // Get incentive and referral bonus transactions for this period
        $incentiveEarnings = (float) DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
            ->where('type', 'incentive')
            ->whereDate('created_at', '>=', $startDate->toDateString())
            ->whereDate('created_at', '<=', $endDate->toDateString())
            ->sum('amount');

        $referralBonusEarnings = (float) DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
            ->where('type', 'referral_bonus')
            ->whereDate('created_at', '>=', $startDate->toDateString())
            ->whereDate('created_at', '<=', $endDate->toDateString())
            ->sum('amount');

        // Calculate order earnings and tips from transactions
        $orderEarnings = 0;
        $tipsTotal = 0;
        $multiOrderEarnings = 0;

        foreach ($orders as $order) {
            $txn = $orderTransactions->get($order->id);

            if ($txn) {
                $orderEarnings += (float) ($txn->driver_earnings ?? 0);
                $tipsTotal += (float) ($txn->delivery_tip ?? 0);
            }

            // Add multi-order bonus earnings from orders table
            if ($order->delivery_boy_bonus_amount) {
                $multiOrderEarnings += (float) $order->delivery_boy_bonus_amount;
            }
        }

        return [
            'order' => (float) $orderEarnings,
            'multi_order' => (float) $multiOrderEarnings,
            'incentive' => (float) $incentiveEarnings,
            'referral_bonus' => (float) $referralBonusEarnings,
            'tips' => (float) $tipsTotal,
            'total' => (float) ($orderEarnings + $multiOrderEarnings + $incentiveEarnings + $referralBonusEarnings + $tipsTotal),
        ];
    }

    /**
     * Get earnings breakdown by type
     */
    private function getEarningsBreakdown(DeliveryBoy $deliveryBoy, Carbon $startDate, Carbon $endDate)
    {
        // Use the same calculation as getEarningsByType
        $earningsByType = $this->getEarningsByType($deliveryBoy, $startDate, $endDate);

        $orderEarnings = $earningsByType['order'];
        $multiOrderEarnings = $earningsByType['multi_order'];
        $incentiveEarnings = $earningsByType['incentive'];
        $referralBonusEarnings = $earningsByType['referral_bonus'];
        $tips = $earningsByType['tips'];

        $totalEarnings = $earningsByType['total'];

        return [
            [
                'name' => 'Order earnings',
                'description' => 'Earning you receive per order.',
                'amount' => (float) $orderEarnings,
                'percentage' => $totalEarnings > 0 ? round(($orderEarnings / $totalEarnings) * 100, 2) : 0,
                'icon' => 'package',
            ],
            [
                'name' => 'Multi order earnings',
                'description' => 'Extra amount for multiple orders.',
                'amount' => (float) $multiOrderEarnings,
                'percentage' => $totalEarnings > 0 ? round(($multiOrderEarnings / $totalEarnings) * 100, 2) : 0,
                'icon' => 'boxes',
            ],
            [
                'name' => 'Incentives',
                'description' => 'Extra pay for completing gigs.',
                'amount' => (float) $incentiveEarnings,
                'percentage' => $totalEarnings > 0 ? round(($incentiveEarnings / $totalEarnings) * 100, 2) : 0,
                'icon' => 'gift',
            ],
            [
                'name' => 'Referral bonus',
                'description' => 'Bonus for referring new drivers.',
                'amount' => (float) $referralBonusEarnings,
                'percentage' => $totalEarnings > 0 ? round(($referralBonusEarnings / $totalEarnings) * 100, 2) : 0,
                'icon' => 'users',
            ],
            [
                'name' => 'Customer tips',
                'description' => 'Tips received from customers.',
                'amount' => (float) $tips,
                'percentage' => $totalEarnings > 0 ? round(($tips / $totalEarnings) * 100, 2) : 0,
                'icon' => 'star',
            ],
        ];
    }

    /**
     * Get available dates for selection with navigation
     */
    private function getAvailableDates(DeliveryBoy $deliveryBoy, $period, $currentDateStr = null)
    {
        $baseQuery = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id);

        if ($period === 'daily') {
            // Get all dates with data
            $dates = $baseQuery->orderBy('tracking_date', 'desc')
                ->pluck('tracking_date')
                ->map(fn($date) => Carbon::parse($date)->toDateString())
                ->unique()
                ->take(30)
                ->toArray();

            $currentDate = $currentDateStr ? Carbon::parse($currentDateStr) : Carbon::now();
            $previousDate = $currentDate->copy()->subDay();
            $nextDate = $currentDate->copy()->addDay();

            return [
                'type' => 'daily',
                'current_date' => $currentDate->toDateString(),
                'previous_date' => $previousDate->toDateString(),
                'next_date' => $nextDate->toDateString(),
                'dates' => $dates,
            ];
        } elseif ($period === 'weekly') {
            // Get all weeks with data
            $weeks = $baseQuery->selectRaw('YEAR(tracking_date) as year, WEEK(tracking_date) as week')
                ->distinct()
                ->orderByDesc('year')
                ->orderByDesc('week')
                ->take(12)
                ->get();

            $weekDates = [];
            foreach ($weeks as $w) {
                $weekStart = Carbon::now()->setISODate($w->year, $w->week);
                $weekDates[] = $weekStart->toDateString();
            }

            // Calculate current, previous, and next week
            $currentWeekStart = $currentDateStr ? Carbon::parse($currentDateStr)->startOfWeek() : Carbon::now()->startOfWeek();
            $previousWeekStart = $currentWeekStart->copy()->subWeek();
            $nextWeekStart = $currentWeekStart->copy()->addWeek();

            return [
                'type' => 'weekly',
                'current_week_start' => $currentWeekStart->toDateString(),
                'previous_week_start' => $previousWeekStart->toDateString(),
                'next_week_start' => $nextWeekStart->toDateString(),
                'weeks' => $weekDates,
            ];
        } elseif ($period === 'monthly') {
            // Get all months with data
            $months = $baseQuery->selectRaw('DATE_FORMAT(tracking_date, "%Y-%m") as month')
                ->distinct()
                ->orderByDesc('month')
                ->take(12)
                ->pluck('month')
                ->toArray();

            // Calculate current, previous, and next month
            $currentMonth = $currentDateStr ? Carbon::parse($currentDateStr) : Carbon::now();
            $previousMonth = $currentMonth->copy()->subMonth();
            $nextMonth = $currentMonth->copy()->addMonth();

            return [
                'type' => 'monthly',
                'current_month' => $currentMonth->format('Y-m'),
                'previous_month' => $previousMonth->format('Y-m'),
                'next_month' => $nextMonth->format('Y-m'),
                'months' => $months,
            ];
        }

        return [];
    }

    /**
     * Get daily metrics (distance and login hours)
     * If tracking data is 0, calculate from sessions
     */
    private function getDailyMetrics(DeliveryBoy $deliveryBoy, Carbon $date)
    {
        $tracking = DeliveryBoyDailyTracking::where('delivery_boy_id', $deliveryBoy->id)
            ->whereDate('tracking_date', $date->toDateString())
            ->first();

        $distance = $tracking ? $tracking->total_distance_km : 0;
        $loginMinutes = $tracking ? $tracking->total_login_minutes : 0;

        // If tracking shows 0, try to calculate from sessions
        if ($loginMinutes == 0) {
            $sessions = \App\Models\DeliveryBoySession::where('delivery_boy_id', $deliveryBoy->id)
                ->whereDate('login_at', $date->toDateString())
                ->get();

            foreach ($sessions as $session) {
                if ($session->logout_at) {
                    $loginMinutes += $session->duration_minutes;
                }
            }
        }

        return [
            'distance' => (float) $distance,
            'login_minutes' => (int) $loginMinutes,
        ];
    }

    /**
     * Get floating cash to be settled with admin
     * GET /api/delivery_boy/performance/floating-cash
     *
     * Query Parameters:
     * - period: 'weekly' or 'monthly' (default: weekly)
     * - offset: Navigation offset (-1 for previous, 1 for next, 0 for current)
     * - status: 'pending' or 'settled' (default: pending)
     */
    public function getFloatingCash(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            $period = $request->period ?? 'weekly';
            $offset = (int) ($request->offset ?? 0);
            $status = $request->status ?? 'pending'; // pending or settled

            // Calculate date range
            $now = Carbon::now();
            $startDate = null;
            $endDate = null;
            $periodName = '';

            if ($period === 'weekly') {
                // Calculate week boundaries
                $currentWeekStart = $now->clone()->startOfWeek();
                $startDate = $currentWeekStart->clone()->addWeeks($offset);
                $endDate = $startDate->clone()->endOfWeek();
                $periodName = $startDate->format('M d') . ' - ' . $endDate->format('M d, Y');
            } else {
                // Monthly
                $currentMonthStart = $now->clone()->startOfMonth();
                $startDate = $currentMonthStart->clone()->addMonths($offset);
                $endDate = $startDate->clone()->endOfMonth();
                $periodName = $startDate->format('F Y');
            }

            // Build query based on settlement status
            $query = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->whereDate('transaction_date', '>=', $startDate->toDateString())
                ->whereDate('transaction_date', '<=', $endDate->toDateString())
                ->where('status', 'success')
                ->where('is_hand_cash', 1);

            if ($status === 'pending') {
                $query->where('settled_with_admin', false);
            } else {
                $query->where('settled_with_admin', true);
            }

            $transactions = $query->with('order')->orderBy('transaction_date', 'desc')->get();

            // Group transactions by order and calculate totals
            $groupedData = [];
            $totalAdminCash = 0;
            $totalSettledCash = 0;

            foreach ($transactions as $transaction) {
                $orderId = $transaction->order_id;
                $adminCash = $transaction->admin_cash ?? 0;
                $isSettled = $transaction->settled_with_admin;

                if (!isset($groupedData[$orderId])) {
                    $order = $transaction->order;
                    $groupedData[$orderId] = [
                        'order_id' => $orderId,
                        'order_number' => $order?->order_number ?? 'N/A',
                        'transaction_date' => $transaction->transaction_date,
                        'transaction_type' => $transaction->type,
                        'admin_cash' => (float) $adminCash,
                        'is_settled' => (bool) $isSettled,
                        'settled_at' => $transaction->settled_at,
                        'order_details' => [
                            'customer_name' => $order?->customer_name ?? 'N/A',
                            'delivery_address' => $order?->delivery_address ?? 'N/A',
                        ]
                    ];
                } else {
                    // Add to existing order if multiple transactions
                    $groupedData[$orderId]['admin_cash'] += (float) $adminCash;
                }

                if ($isSettled) {
                    $totalSettledCash += $adminCash;
                } else {
                    $totalAdminCash += $adminCash;
                }
            }

            // Sort by transaction date
            if (!empty($groupedData)) {
                usort($groupedData, function ($a, $b) {
                    return strtotime($b['transaction_date']) - strtotime($a['transaction_date']);
                });
            }

            return CommonHelper::responseWithData([
                'period' => $period,
                'period_name' => $periodName,
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
                'status' => $status,
                'summary' => [
                    'total_pending_cash' => $status === 'pending' ? (float) $totalAdminCash : 0,
                    'total_settled_cash' => $status === 'settled' ? (float) $totalSettledCash : 0,
                    'total_transactions' => count($groupedData),
                ],
                'transactions' => array_values($groupedData),
            ]);

        } catch (\Exception $e) {
            \Log::error('Floating cash error: ' . $e->getMessage());
            return CommonHelper::responseError('Something went wrong!');
        }
    }

    /**
     * Get order-wise earnings breakdown with all deductions
     * GET /api/delivery_boy/performance/order-earnings
     *
     * Query Parameters:
     * - period: 'weekly' or 'monthly' (default: weekly)
     * - offset: Navigation offset (-1 for previous, 1 for next, 0 for current)
     * - status: 'delivered' or 'all' (default: delivered)
     */
    public function getOrderEarnings(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            $period = $request->period ?? 'weekly';
            $offset = (int) ($request->offset ?? 0);
            $status = $request->status ?? 'delivered';

            // Calculate date range
            $now = Carbon::now();
            $startDate = null;
            $endDate = null;
            $periodName = '';

            if ($period === 'daily') {
                $date = $request->date ? Carbon::parse($request->date) : $now->clone();
                $startDate = $date->clone()->addDays($offset)->startOfDay();
                $endDate = $startDate->clone()->endOfDay();
                $periodName = $startDate->format('M d, Y');
            } elseif ($period === 'weekly') {
                $currentWeekStart = $now->clone()->startOfWeek();
                $startDate = $currentWeekStart->clone()->addWeeks($offset);
                $endDate = $startDate->clone()->endOfWeek();
                $periodName = $startDate->format('M d') . ' - ' . $endDate->format('M d, Y');
            } else {
                $currentMonthStart = $now->clone()->startOfMonth();
                $startDate = $currentMonthStart->clone()->addMonths($offset);
                $endDate = $startDate->clone()->endOfMonth();
                $periodName = $startDate->format('F Y');
            }

            // Build query
            $query = Order::where('delivery_boy_id', $deliveryBoy->id)
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString());

            if ($status === 'delivered') {
                $query->whereIn('active_status', ['6', '7', '8']);
            }

            $orders = $query->orderBy('created_at', 'desc')->get();

            // Pre-load transactions for these orders from delivery_boy_transactions
            $orderIds = $orders->pluck('id')->toArray();
            $transactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->whereIn('order_id', $orderIds)
                ->where('status', 'success')
                ->get()
                ->keyBy('order_id');

            // Calculate earnings per order and totals
            $orderEarnings = [];
            $totals = [
                'order_amount' => 0,
                'delivery_charge' => 0,
                'delivery_tip' => 0,
                'bonus_amount' => 0,
                'admin_cash' => 0,
                'delivery_boy_earnings' => 0,
                'total_orders' => count($orders),
            ];

            foreach ($orders as $order) {
                $orderAmount = (float) ($order->final_total ?? $order->total ?? 0);
                $bonusAmount = (float) ($order->delivery_boy_bonus_amount ?? 0);

                // Get earnings from delivery_boy_transactions (actual source of truth)
                $txn = $transactions->get($order->id);
                $deliveryCharge = (float) ($txn->delivery_charge ?? 0);
                $deliveryTip = (float) ($txn->delivery_tip ?? 0);
                $adminCash = (float) ($txn->admin_cash ?? 0);
                $driverEarnings = (float) ($txn->driver_earnings ?? 0);

                // If no transaction found, fallback to order's delivery_charge column
                if (!$txn) {
                    $deliveryCharge = (float) ($order->delivery_charge ?? 0);
                    $driverEarnings = $deliveryCharge + $bonusAmount;
                }

                $orderEarnings[] = [
                    'order_id' => $order->id,
                    'order_number' => $order->order_number,
                    'order_date' => $order->created_at,
                    'delivery_address' => $order->address,
                    'status' => $order->active_status,
                    'breakdown' => [
                        'order_amount' => (float) $orderAmount,
                        'delivery_charge' => (float) $deliveryCharge,
                        'delivery_tip' => (float) $deliveryTip,
                        'bonus_amount' => (float) $bonusAmount,
                    ],
                    'deductions' => [
                        'admin_cash' => (float) $adminCash,
                    ],
                    'net_earning' => (float) $driverEarnings,
                    'delivery_boy_earning' => (float) $driverEarnings,
                ];

                // Add to totals
                $totals['order_amount'] += $orderAmount;
                $totals['delivery_charge'] += $deliveryCharge;
                $totals['delivery_tip'] += $deliveryTip;
                $totals['bonus_amount'] += $bonusAmount;
                $totals['admin_cash'] += $adminCash;
                $totals['delivery_boy_earnings'] += $driverEarnings;
            }

            // Calculate net earnings
            $totals['net_earnings'] = $totals['delivery_boy_earnings'];

            // Get incentive earnings for this period
            $incentiveTransactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->where('type', 'incentive')
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString())
                ->get();

            $totalIncentiveEarned = (float) $incentiveTransactions->sum('amount');
            $settledIncentive = (float) $incentiveTransactions->filter(fn($t) => !empty($t->settled_at))->sum('amount');
            $pendingIncentive = (float) $incentiveTransactions->filter(fn($t) => empty($t->settled_at))->sum('amount');

            // Get referral bonus earnings for this period
            $referralTransactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->where('type', 'referral_bonus')
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString())
                ->get();

            $totalReferralBonus = (float) $referralTransactions->sum('amount');
            $settledReferral = (float) $referralTransactions->filter(fn($t) => !empty($t->settled_at))->sum('amount');
            $pendingReferral = (float) $referralTransactions->filter(fn($t) => empty($t->settled_at))->sum('amount');

            return CommonHelper::responseWithData([
                'period' => $period,
                'period_name' => $periodName,
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
                'status' => $status,
                'summary' => [
                    'total_orders' => $totals['total_orders'],
                    'total_order_amount' => (float) $totals['order_amount'],
                    'total_delivery_charge' => (float) $totals['delivery_charge'],
                    'total_delivery_tip' => (float) $totals['delivery_tip'],
                    'total_bonus_amount' => (float) $totals['bonus_amount'],
                    'total_admin_deductions' => (float) $totals['admin_cash'],
                    'total_delivery_boy_earnings' => (float) $totals['delivery_boy_earnings'],
                    'total_net_earnings' => (float) $totals['net_earnings'],
                    'total_incentive_earned' => $totalIncentiveEarned,
                    'settled_incentive' => $settledIncentive,
                    'pending_incentive' => $pendingIncentive,
                    'total_referral_bonus' => $totalReferralBonus,
                    'settled_referral' => $settledReferral,
                    'pending_referral' => $pendingReferral,
                ],
                'orders' => $orderEarnings,
            ]);

        } catch (\Exception $e) {
            \Log::error('Order earnings error: ' . $e->getMessage());
            return CommonHelper::responseError('Something went wrong!');
        }
    }

    /**
     * Get multi-order bonus earnings details
     * GET /api/delivery_boy/performance/multi-order-earnings
     *
     * Query Parameters:
     * - period: 'weekly' or 'monthly' (default: weekly)
     * - offset: Navigation offset (-1 for previous, 1 for next, 0 for current)
     */
    public function getMultiOrderEarnings(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            $period = $request->period ?? 'weekly';
            $offset = (int) ($request->offset ?? 0);
            $limit = (int) ($request->limit ?? 5);
            $page = (int) ($request->page ?? 1);
            $paginationSkip = ($page - 1) * $limit;

            // Calculate date range
            $now = Carbon::now();
            $startDate = null;
            $endDate = null;
            $periodName = '';

            if ($period === 'daily') {
                $startDate = $now->clone()->addDays($offset)->startOfDay();
                $endDate = $startDate->clone()->endOfDay();
                $periodName = $startDate->format('D, M d, Y');
            } elseif ($period === 'weekly') {
                $currentWeekStart = $now->clone()->startOfWeek();
                $startDate = $currentWeekStart->clone()->addWeeks($offset);
                $endDate = $startDate->clone()->endOfWeek();
                $periodName = $startDate->format('M d') . ' - ' . $endDate->format('M d, Y');
            } else {
                $currentMonthStart = $now->clone()->startOfMonth();
                $startDate = $currentMonthStart->clone()->addMonths($offset);
                $endDate = $startDate->clone()->endOfMonth();
                $periodName = $startDate->format('F Y');
            }

            // Base query for orders with multi-order bonuses
            $baseQuery = Order::where('delivery_boy_id', $deliveryBoy->id)
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString())
                ->whereIn('active_status', ['6', '7', '8'])
                ->where('delivery_boy_bonus_amount', '>', 0);

            // Summary from all matching orders
            $totalCount = $baseQuery->count();
            $totalBonus = (float) $baseQuery->sum('delivery_boy_bonus_amount');
            $averageBonus = $totalCount > 0 ? $totalBonus / $totalCount : 0;
            $maxBonus = (float) ($baseQuery->max('delivery_boy_bonus_amount') ?? 0);
            $minBonus = (float) ($baseQuery->min('delivery_boy_bonus_amount') ?? 0);

            // Get paginated orders
            $orders = $baseQuery->orderBy('created_at', 'desc')
                ->skip($paginationSkip)
                ->take($limit)
                ->get();

            // Pre-load customer names
            $userIds = $orders->pluck('user_id')->unique()->filter()->toArray();
            $customerNames = \App\Models\User::whereIn('id', $userIds)->pluck('name', 'id');

            // Pre-load store data from order_seller_status_tracking -> sellers
            $orderIds = $orders->pluck('id')->toArray();
            $orderStoreData = DB::table('order_seller_status_tracking as ost')
                ->leftJoin('sellers as s', 'ost.store_id', '=', 's.id')
                ->whereIn('ost.order_id', $orderIds)
                ->select('ost.order_id', 'ost.store_id', 's.store_name')
                ->get()
                ->groupBy('order_id');

            // Build paginated order data
            $multiOrderData = [];

            foreach ($orders as $order) {
                $bonusAmount = (float) ($order->delivery_boy_bonus_amount ?? 0);

                $storeRows = $orderStoreData->get($order->id, collect());
                $storeNames = $storeRows->pluck('store_name')->filter()->unique()->values()->toArray();
                $storeSellers = range(1, max($storeRows->count(), 1));

                $multiOrderData[] = [
                    'order_id' => $order->id,
                    'order_number' => $order->order_number,
                    'order_date' => $order->created_at,
                    'customer_name' => $customerNames->get($order->user_id, ''),
                    'store_names' => $storeNames,
                    'store_sellers' => $storeSellers,
                    'delivery_address' => $order->address,
                    'bonus_amount' => (float) $bonusAmount,
                    'order_status' => $order->active_status,
                ];
            }

            return CommonHelper::responseWithData([
                'period' => $period,
                'period_name' => $periodName,
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
                'summary' => [
                    'total_multi_order_bonus' => (float) $totalBonus,
                    'total_orders_with_bonus' => $totalCount,
                    'average_bonus_per_order' => (float) round($averageBonus, 2),
                    'max_bonus' => (float) $maxBonus,
                    'min_bonus' => (float) $minBonus,
                ],
                'pagination' => [
                    'total' => $totalCount,
                    'page' => $page,
                    'limit' => $limit,
                    'total_pages' => (int) ceil($totalCount / $limit),
                ],
                'orders' => $multiOrderData,
            ]);

        } catch (\Exception $e) {
            \Log::error('Multi-order earnings error: ' . $e->getMessage());
            return CommonHelper::responseError('Something went wrong!');
        }
    }

    /**
     * Get all order earnings (normal + multi orders) by period
     * GET /api/delivery-boy/performance/order-earnings?period=daily&offset=0
     */
    public function getAllOrderEarnings(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            $period = $request->period ?? 'weekly';
            $offset = (int) ($request->offset ?? 0);
            $limit = (int) ($request->limit ?? 5);
            $page = (int) ($request->page ?? 1);
            $paginationSkip = ($page - 1) * $limit;

            // Calculate date range
            $now = Carbon::now();
            $startDate = null;
            $endDate = null;
            $periodName = '';

            if ($period === 'daily') {
                $startDate = $now->clone()->addDays($offset)->startOfDay();
                $endDate = $startDate->clone()->endOfDay();
                $periodName = $startDate->format('D, M d, Y');
            } elseif ($period === 'weekly') {
                $currentWeekStart = $now->clone()->startOfWeek();
                $startDate = $currentWeekStart->clone()->addWeeks($offset);
                $endDate = $startDate->clone()->endOfWeek();
                $periodName = $startDate->format('M d') . ' - ' . $endDate->format('M d, Y');
            } else {
                $currentMonthStart = $now->clone()->startOfMonth();
                $startDate = $currentMonthStart->clone()->addMonths($offset);
                $endDate = $startDate->clone()->endOfMonth();
                $periodName = $startDate->format('F Y');
            }

            $isCancelled = (int) ($request->is_cancelled ?? 0);

            if ($isCancelled) {
                // Get cancelled order IDs for this driver in the date range
                $cancelledRows = DB::table('delivery_boy_order_cancellations')
                    ->where('delivery_boy_id', $deliveryBoy->id)
                    ->whereDate('created_at', '>=', $startDate->toDateString())
                    ->whereDate('created_at', '<=', $endDate->toDateString());

                $totalCount = $cancelledRows->count();
                $cancelledOrderIds = $cancelledRows->pluck('order_id')->toArray();

                // Get cancel_count keyed by order_id
                $cancelCounts = DB::table('delivery_boy_order_cancellations')
                    ->where('delivery_boy_id', $deliveryBoy->id)
                    ->whereIn('order_id', $cancelledOrderIds)
                    ->pluck('cancel_count', 'order_id');

                // Base query for cancelled orders
                $baseQuery = Order::whereIn('id', $cancelledOrderIds);
            } else {
                // Base query for ALL completed orders (normal + multi)
                $baseQuery = Order::where('delivery_boy_id', $deliveryBoy->id)
                    ->whereDate('created_at', '>=', $startDate->toDateString())
                    ->whereDate('created_at', '<=', $endDate->toDateString())
                    ->whereIn('active_status', ['6', '7', '8']);

                $totalCount = $baseQuery->count();
            }

            $totalBonus = (float) $baseQuery->sum('delivery_boy_bonus_amount');

            // Get transactions for total driver_earnings
            $allOrderIds = $baseQuery->pluck('id')->toArray();
            $allTransactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->whereIn('order_id', $allOrderIds)
                ->where('status', 'success')
                ->get();

            $totalDriverEarnings = (float) $allTransactions->sum('driver_earnings');
            $totalDeliveryCharge = (float) $allTransactions->sum('delivery_charge');
            $totalDeliveryTip = (float) $allTransactions->sum('delivery_tip');
            $totalRainSurcharge = (float) $allTransactions->sum('rain_surcharge');
            $totalVendorWaitCharge = (float) $allTransactions->sum('vendor_wait_charge');
            $totalVendorWaitCharge = (float) $allTransactions->sum('vendor_wait_charge');

            // Get paginated orders
            $orders = $baseQuery->orderBy('created_at', 'desc')
                ->skip($paginationSkip)
                ->take($limit)
                ->get();

            // Pre-load customer names
            $userIds = $orders->pluck('user_id')->unique()->filter()->toArray();
            $customerNames = \App\Models\User::whereIn('id', $userIds)->pluck('name', 'id');

            // Pre-load store data from order_seller_status_tracking -> sellers
            $orderIds = $orders->pluck('id')->toArray();
            $orderStoreData = DB::table('order_seller_status_tracking as ost')
                ->leftJoin('sellers as s', 'ost.store_id', '=', 's.id')
                ->whereIn('ost.order_id', $orderIds)
                ->select('ost.order_id', 'ost.store_id', 's.store_name')
                ->get()
                ->groupBy('order_id');

            // Pre-load transactions for paginated orders
            $orderTransactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->whereIn('order_id', $orderIds)
                ->where('status', 'success')
                ->get()
                ->keyBy('order_id');

            // Build paginated order data
            $orderData = [];

            foreach ($orders as $order) {
                $bonusAmount = (float) ($order->delivery_boy_bonus_amount ?? 0);
                $isMultiOrder = $bonusAmount > 0;

                $storeRows = $orderStoreData->get($order->id, collect());
                $storeNames = $storeRows->pluck('store_name')->filter()->unique()->values()->toArray();
                $storeSellers = $storeRows->count() > 0 ? range(1, $storeRows->count()) : [1];

                $txn = $orderTransactions->get($order->id);

                $item = [
                    'order_id' => $order->id,
                    'order_number' => $order->order_number,
                    'order_date' => $order->created_at,
                    'customer_name' => $customerNames->get($order->user_id, ''),
                    'store_names' => $storeNames,
                    'store_sellers' => $storeSellers,
                    'delivery_address' => $order->address,
                    'is_multi_order' => $isMultiOrder,
                    'bonus_amount' => $bonusAmount,
                    'delivery_charge' => (float) ($txn->delivery_charge ?? 0),
                    'delivery_tip' => (float) ($txn->delivery_tip ?? 0),
                    'rain_surcharge' => (float) ($txn->rain_surcharge ?? 0),
                    'vendor_wait_charge' => (float) ($txn->vendor_wait_charge ?? 0),
                    'driver_earnings' => (float) ($txn->driver_earnings ?? 0),
                    'order_status' => $order->active_status,
                ];

                if ($isCancelled) {
                    $item['cancel_count'] = (int) ($cancelCounts[$order->id] ?? 0);
                }

                $orderData[] = $item;
            }

            $summary = [
                'total_orders' => $totalCount,
                'total_driver_earnings' => (float) round($totalDriverEarnings, 2),
                'total_delivery_charge' => (float) round($totalDeliveryCharge, 2),
                'total_delivery_tip' => (float) round($totalDeliveryTip, 2),
                'total_multi_order_bonus' => (float) round($totalBonus, 2),
                'total_rain_surcharge' => (float) round($totalRainSurcharge, 2),
                'total_vendor_wait_charge' => (float) round($totalVendorWaitCharge, 2),
            ];

            if ($isCancelled) {
                $summary['total_cancellations'] = $totalCount;
            }

            return CommonHelper::responseWithData([
                'period' => $period,
                'period_name' => $periodName,
                'is_cancelled' => $isCancelled,
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
                'summary' => $summary,
                'pagination' => [
                    'total' => $totalCount,
                    'page' => $page,
                    'limit' => $limit,
                    'total_pages' => (int) ceil($totalCount / $limit),
                ],
                'orders' => $orderData,
            ]);

        } catch (\Exception $e) {
            \Log::error('All order earnings error: ' . $e->getMessage());
            return CommonHelper::responseError('Something went wrong!');
        }
    }

    /**
     * Get overall weekly summary with all earnings details
     * GET /api/delivery_boy/performance/weekly-summary
     *
     * Query Parameters:
     * - offset: Navigation offset (-1 for previous, 1 for next, 0 for current)
     */
    public function getWeeklySummary(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            $offset = (int) ($request->offset ?? 0);

            // Calculate week boundaries
            $now = Carbon::now();
            $currentWeekStart = $now->clone()->startOfWeek();
            $startDate = $currentWeekStart->clone()->addWeeks($offset);
            $endDate = $startDate->clone()->endOfWeek();
            $periodName = $startDate->format('M d') . ' - ' . $endDate->format('M d, Y');

            // Get orders for this week (status 6/7/8)
            $orders = Order::where('delivery_boy_id', $deliveryBoy->id)
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString())
                ->whereIn('active_status', ['6', '7', '8'])
                ->get();

            // Get order transactions from delivery_boy_transactions (source of truth)
            $orderIds = $orders->pluck('id')->toArray();
            $orderTransactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->whereIn('order_id', $orderIds)
                ->where('status', 'success')
                ->get();

            // Calculate order earnings from transactions
            $orderEarnings = 0;
            $customerTips = 0;
            $multiOrderBonus = 0;

            foreach ($orderTransactions as $txn) {
                $orderEarnings += (float) ($txn->driver_earnings ?? 0);
                $customerTips += (float) ($txn->delivery_tip ?? 0);
                $multiOrderBonus += (float) ($txn->bonus_amount ?? 0);
            }

            // Get incentive earnings for this week
            $incentiveTransactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->where('type', 'incentive')
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString())
                ->get();

            $incentiveEarnings = (float) $incentiveTransactions->sum('amount');
            $settledIncentive = (float) $incentiveTransactions->filter(fn($t) => !empty($t->settled_at))->sum('amount');
            $pendingIncentive = (float) $incentiveTransactions->filter(fn($t) => empty($t->settled_at))->sum('amount');

            // Get referral bonus earnings for this week
            $referralTransactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->where('type', 'referral_bonus')
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString())
                ->get();

            $referralBonusEarnings = (float) $referralTransactions->sum('amount');
            $settledReferral = (float) $referralTransactions->filter(fn($t) => !empty($t->settled_at))->sum('amount');
            $pendingReferral = (float) $referralTransactions->filter(fn($t) => empty($t->settled_at))->sum('amount');

            // Total earnings = driver_earnings (from order txns) + incentive + referral
            $totalEarnings = $orderEarnings + $incentiveEarnings + $referralBonusEarnings;

            // Get overall pending floating cash (all pending transactions, not just from this week)
            $totalFloatingCash = (float) DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->where('status', 'success')
                ->where('settled_with_admin', false)
                ->where('admin_cash', '>', 0)
                ->whereNull('payout_reference')
                ->sum('admin_cash');

            // Get payout details where payout_reference is not null
            $totalPaidOut = (float) DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->whereNotNull('payout_reference')
                ->where('status', 'success')
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString())
                ->sum('driver_earnings');

            $payoutTransactionCount = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->whereNotNull('payout_reference')
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString())
                ->count();

            // Count orders with bonus
            $bonusOrdersCount = $orders->filter(fn($o) => $o->delivery_boy_bonus_amount > 0)->count();

            return CommonHelper::responseWithData([
                'period' => 'weekly',
                'period_name' => $periodName,
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
                'summary' => [
                    'total_earnings' => (float) round($totalEarnings, 2),
                    'breakdown' => [
                        'order_earnings' => (float) round($orderEarnings, 2),
                        'multi_order_bonus' => (float) round($multiOrderBonus, 2),
                        'customer_tips' => (float) round($customerTips, 2),
                        'incentive_earnings' => (float) round($incentiveEarnings, 2),
                        'referral_bonus' => (float) round($referralBonusEarnings, 2),
                    ],
                    'total_incentive_earned' => (float) round($incentiveEarnings, 2),
                    'settled_incentive' => (float) round($settledIncentive, 2),
                    'pending_incentive' => (float) round($pendingIncentive, 2),
                    'total_referral_bonus' => (float) round($referralBonusEarnings, 2),
                    'settled_referral' => (float) round($settledReferral, 2),
                    'pending_referral' => (float) round($pendingReferral, 2),
                    'floating_cash_pending' => (float) round($totalFloatingCash, 2),
                    'gross_earnings' => (float) round($totalEarnings, 2),
                    'payout_details' => [
                        'total_paid_out' => (float) round($totalPaidOut, 2),
                        'payout_transactions' => (int) $payoutTransactionCount,
                    ],
                ],
                'statistics' => [
                    'total_orders' => count($orders),
                    'total_transactions' => count($orderTransactions),
                    'average_earning_per_order' => count($orders) > 0 ? (float) round($orderEarnings / count($orders), 2) : 0,
                    'average_tip_per_order' => count($orders) > 0 ? (float) round($customerTips / count($orders), 2) : 0,
                    'total_bonus_orders' => (int) $bonusOrdersCount,
                ],
            ]);

        } catch (\Exception $e) {
            \Log::error('Weekly summary error: ' . $e->getMessage());
            return CommonHelper::responseError('Something went wrong!');
        }
    }

    /**
     * Get payout history with transaction details
     * GET /api/delivery_boy/performance/payout-history
     *
     * Query Parameters:
     * - page: Pagination page (default: 1)
     * - per_page: Items per page (default: 20)
     * - offset: Weekly offset (-1 for previous, 1 for next, 0 for current)
     */
    public function getPayoutHistory(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            $period = $request->period ?? 'weekly';
            $offset = (int) ($request->offset ?? 0);
            $limit = (int) ($request->limit ?? 5);
            $page = (int) ($request->page ?? 1);
            $paginationSkip = ($page - 1) * $limit;

            // Calculate date range
            $now = Carbon::now();
            $startDate = null;
            $endDate = null;
            $periodName = '';

            if ($period === 'daily') {
                $startDate = $now->clone()->addDays($offset)->startOfDay();
                $endDate = $startDate->clone()->endOfDay();
                $periodName = $startDate->format('D, M d, Y');
            } elseif ($period === 'weekly') {
                $currentWeekStart = $now->clone()->startOfWeek();
                $startDate = $currentWeekStart->clone()->addWeeks($offset);
                $endDate = $startDate->clone()->endOfWeek();
                $periodName = $startDate->format('M d') . ' - ' . $endDate->format('M d, Y');
            } else {
                $currentMonthStart = $now->clone()->startOfMonth();
                $startDate = $currentMonthStart->clone()->addMonths($offset);
                $endDate = $startDate->clone()->endOfMonth();
                $periodName = $startDate->format('F Y');
            }

            // Base query for payout transactions
            $baseQuery = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->whereNotNull('payout_reference')
                ->where('status', 'success')
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString());

            // Summary from all matching
            $totalCount = $baseQuery->count();
            $totalPaidOut = (float) $baseQuery->sum('driver_earnings');

            // Paginated results
            $transactions = (clone $baseQuery)
                ->orderBy('created_at', 'desc')
                ->skip($paginationSkip)
                ->take($limit)
                ->get();

            $formattedTransactions = $transactions->map(function ($transaction) {
                return [
                    'id' => $transaction->id,
                    'order_id' => $transaction->order_id,
                    'type' => $transaction->type,
                    'amount' => (float) round($transaction->driver_earnings, 2),
                    'payout_reference' => $transaction->payout_reference,
                    'status' => $transaction->status,
                    'message' => $transaction->message,
                    'transaction_date' => $transaction->transaction_date,
                    'created_at' => $transaction->created_at,
                    'updated_at' => $transaction->updated_at,
                ];
            })->values();

            return CommonHelper::responseWithData([
                'period' => $period,
                'period_name' => $periodName,
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
                'payout_summary' => [
                    'total_paid_out' => (float) round($totalPaidOut, 2),
                    'total_transactions' => $totalCount,
                    'average_payout_amount' => $totalCount > 0 ? (float) round($totalPaidOut / $totalCount, 2) : 0,
                ],
                'pagination' => [
                    'total' => $totalCount,
                    'page' => $page,
                    'limit' => $limit,
                    'total_pages' => (int) ceil($totalCount / max($limit, 1)),
                ],
                'transactions' => $formattedTransactions,
            ]);

        } catch (\Exception $e) {
            \Log::error('Payout history error: ' . $e->getMessage());
            return CommonHelper::responseError('Something went wrong!');
        }
    }

    /**
     * Get driver payouts (settled & unsettled) by period
     * GET /api/delivery-boy/performance/payouts?period=weekly&offset=0
     */
    public function getDriverPayouts(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            $period = $request->period ?? 'weekly';
            $offset = (int) ($request->offset ?? 0);
            $limit = (int) ($request->limit ?? 5);
            $page = (int) ($request->page ?? 1);
            $paginationSkip = ($page - 1) * $limit;

            // Calculate date range
            $now = Carbon::now();
            $startDate = null;
            $endDate = null;
            $periodName = '';

            if ($period === 'daily') {
                $startDate = $now->clone()->addDays($offset)->startOfDay();
                $endDate = $startDate->clone()->endOfDay();
                $periodName = $startDate->format('D, M d, Y');
            } elseif ($period === 'weekly') {
                $currentWeekStart = $now->clone()->startOfWeek();
                $startDate = $currentWeekStart->clone()->addWeeks($offset);
                $endDate = $startDate->clone()->endOfWeek();
                $periodName = $startDate->format('M d') . ' - ' . $endDate->format('M d, Y');
            } else {
                $currentMonthStart = $now->clone()->startOfMonth();
                $startDate = $currentMonthStart->clone()->addMonths($offset);
                $endDate = $startDate->clone()->endOfMonth();
                $periodName = $startDate->format('F Y');
            }

            // Common filters
            $baseFilters = function ($query) use ($deliveryBoy, $startDate, $endDate) {
                return $query->where('delivery_boy_id', $deliveryBoy->id)
                    ->where('is_hand_cash', 0)
                    ->where('type', '!=', 'incentive')
                    ->whereDate('created_at', '>=', $startDate->toDateString())
                    ->whereDate('created_at', '<=', $endDate->toDateString());
            };

            // Settled summary
            $settledQuery = $baseFilters(DB::table('delivery_boy_transactions'))->where('settled_with_admin', 1);
            $settledAmount = (float) (clone $settledQuery)->sum('driver_earnings');
            $settledCount = (clone $settledQuery)->count();

            // Unsettled summary
            $unsettledQuery = $baseFilters(DB::table('delivery_boy_transactions'))->where('settled_with_admin', 0);
            $unsettledAmount = (float) (clone $unsettledQuery)->sum('driver_earnings');
            $unsettledCount = (clone $unsettledQuery)->count();

            $totalCount = $settledCount + $unsettledCount;

            // Settled transactions (paginated)
            $settledTransactions = $baseFilters(DB::table('delivery_boy_transactions'))
                ->where('settled_with_admin', 1)
                ->orderBy('settled_at', 'desc')
                ->orderBy('created_at', 'desc')
                ->skip($paginationSkip)
                ->take($limit)
                ->get()
                ->map(function ($txn) {
                    return [
                        'id' => $txn->id,
                        'order_id' => $txn->order_id,
                        'type' => $txn->type,
                        'delivery_charge' => (float) ($txn->delivery_charge ?? 0),
                        'delivery_tip' => (float) ($txn->delivery_tip ?? 0),
                        'rain_surcharge' => (float) ($txn->rain_surcharge ?? 0),
                        'bonus_amount' => (float) ($txn->bonus_amount ?? 0),
                        'driver_earnings' => (float) ($txn->driver_earnings ?? 0),
                        'admin_cash' => (float) ($txn->admin_cash ?? 0),
                        'payout_reference' => $txn->payout_reference,
                        'bank_acc_number' => $txn->bank_acc_number,
                        'status' => $txn->status,
                        'message' => $txn->message,
                        'transaction_date' => $txn->transaction_date,
                        'settled_at' => $txn->settled_at,
                    ];
                })->values();

            // Unsettled transactions (paginated)
            $unsettledTransactions = $baseFilters(DB::table('delivery_boy_transactions'))
                ->where('settled_with_admin', 0)
                ->orderBy('transaction_date', 'desc')
                ->orderBy('created_at', 'desc')
                ->skip($paginationSkip)
                ->take($limit)
                ->get()
                ->map(function ($txn) {
                    return [
                        'id' => $txn->id,
                        'order_id' => $txn->order_id,
                        'type' => $txn->type,
                        'delivery_charge' => (float) ($txn->delivery_charge ?? 0),
                        'delivery_tip' => (float) ($txn->delivery_tip ?? 0),
                        'rain_surcharge' => (float) ($txn->rain_surcharge ?? 0),
                        'bonus_amount' => (float) ($txn->bonus_amount ?? 0),
                        'driver_earnings' => (float) ($txn->driver_earnings ?? 0),
                        'admin_cash' => (float) ($txn->admin_cash ?? 0),
                        'status' => $txn->status,
                        'message' => $txn->message,
                        'transaction_date' => $txn->transaction_date,
                    ];
                })->values();

            return CommonHelper::responseWithData([
                'period' => $period,
                'period_name' => $periodName,
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
                'summary' => [
                    'settled_amount' => (float) round($settledAmount, 2),
                    'settled_count' => $settledCount,
                    'unsettled_amount' => (float) round($unsettledAmount, 2),
                    'unsettled_count' => $unsettledCount,
                    'total_transactions' => $totalCount,
                ],
                'pagination' => [
                    'page' => $page,
                    'limit' => $limit,
                ],
                'settled_transactions' => $settledTransactions,
                'unsettled_transactions' => $unsettledTransactions,
            ]);

        } catch (\Exception $e) {
            \Log::error('Driver payouts error: ' . $e->getMessage());
            return CommonHelper::responseError('Something went wrong!');
        }
    }

    /**
     * Get driver earnings broken down into uniform sections
     * GET /api/delivery-boy/performance/earnings-sections?period=weekly&offset=0
     *
     * Sections: earnings, customer_tips, rain_surcharge, referral, incentive, multi_order
     * Each section has: key, label, total, count, transactions[]
     * Each transaction has: id, order_id, amount, status, message, date
     */
    public function getDriverEarningsSections(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            $period = $request->period ?? 'weekly';
            $offset = (int) ($request->offset ?? 0);
            $limit = (int) ($request->limit ?? 10);
            $page = (int) ($request->page ?? 1);
            $paginationSkip = ($page - 1) * $limit;

            // Calculate date range
            $now = Carbon::now();
            $startDate = null;
            $endDate = null;
            $periodName = '';

            if ($period === 'daily') {
                $startDate = $now->clone()->addDays($offset)->startOfDay();
                $endDate = $startDate->clone()->endOfDay();
                $periodName = $startDate->format('D, M d, Y');
            } elseif ($period === 'weekly') {
                $currentWeekStart = $now->clone()->startOfWeek();
                $startDate = $currentWeekStart->clone()->addWeeks($offset);
                $endDate = $startDate->clone()->endOfWeek();
                $periodName = $startDate->format('M d') . ' - ' . $endDate->format('M d, Y');
            } else {
                $currentMonthStart = $now->clone()->startOfMonth();
                $startDate = $currentMonthStart->clone()->addMonths($offset);
                $endDate = $startDate->clone()->endOfMonth();
                $periodName = $startDate->format('F Y');
            }

            // Fetch all transactions in date range (non-hand-cash)
            $query = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->where('is_hand_cash', 0)
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString());

            // Filter by settled status if provided
            if ($request->has('is_settled')) {
                $query->where('settled_with_admin', (int) $request->is_settled);
            }

            $allTransactions = $query->orderBy('created_at', 'desc')->get();

            // Order transactions (exclude incentive and referral_bonus)
            $orderTransactions = $allTransactions->filter(function ($txn) {
                return !in_array($txn->type, ['incentive', 'referral_bonus']);
            });

            // --- Section 1: Earnings (delivery_charge) ---
            $earningsItems = $orderTransactions->filter(fn($txn) => ($txn->delivery_charge ?? 0) > 0);
            $earningsTotal = (float) $earningsItems->sum('delivery_charge');
            $earningsTransactions = $earningsItems->skip($paginationSkip)->take($limit)->map(function ($txn) {
                return [
                    'id' => $txn->id,
                    'order_id' => $txn->order_id,
                    'amount' => (float) ($txn->delivery_charge ?? 0),
                    'message' => $txn->message,
                    'payout_reference' => $txn->payout_reference,
                    'is_settled' => (int) ($txn->settled_with_admin ?? 0),
                    'settled_at' => $txn->settled_at ?? null,
                    'date' => $txn->transaction_date ?? $txn->created_at,
                ];
            })->values();

            // --- Section 2: Customer Tips ---
            $tipsItems = $orderTransactions->filter(fn($txn) => ($txn->delivery_tip ?? 0) > 0);
            $tipsTotal = (float) $tipsItems->sum('delivery_tip');
            $tipsTransactions = $tipsItems->skip($paginationSkip)->take($limit)->map(function ($txn) {
                return [
                    'id' => $txn->id,
                    'order_id' => $txn->order_id,
                    'amount' => (float) ($txn->delivery_tip ?? 0),
                    'message' => $txn->message,
                    'payout_reference' => $txn->payout_reference,
                    'is_settled' => (int) ($txn->settled_with_admin ?? 0),
                    'settled_at' => $txn->settled_at ?? null,
                    'date' => $txn->transaction_date ?? $txn->created_at,
                ];
            })->values();

            // --- Section 3: Rain Surcharge ---
            $rainItems = $orderTransactions->filter(fn($txn) => ($txn->rain_surcharge ?? 0) > 0);
            $rainTotal = (float) $rainItems->sum('rain_surcharge');
            $rainTransactions = $rainItems->skip($paginationSkip)->take($limit)->map(function ($txn) {
                return [
                    'id' => $txn->id,
                    'order_id' => $txn->order_id,
                    'amount' => (float) ($txn->rain_surcharge ?? 0),
                    'message' => $txn->message,
                    'payout_reference' => $txn->payout_reference,
                    'is_settled' => (int) ($txn->settled_with_admin ?? 0),
                    'settled_at' => $txn->settled_at ?? null,
                    'date' => $txn->transaction_date ?? $txn->created_at,
                ];
            })->values();

            // --- Section 4: Referral Bonus ---
            $referralItems = $allTransactions->filter(fn($txn) => $txn->type === 'referral_bonus');
            $referralTotal = (float) $referralItems->sum('amount');
            $referralTransactions = $referralItems->skip($paginationSkip)->take($limit)->map(function ($txn) {
                return [
                    'id' => $txn->id,
                    'order_id' => $txn->order_id,
                    'amount' => (float) ($txn->amount ?? 0),
                    'message' => $txn->message,
                    'payout_reference' => $txn->payout_reference,
                    'is_settled' => (int) ($txn->settled_with_admin ?? 0),
                    'settled_at' => $txn->settled_at ?? null,
                    'date' => $txn->transaction_date ?? $txn->created_at,
                ];
            })->values();

            // --- Section 5: Incentive ---
            $incentiveItems = $allTransactions->filter(fn($txn) => $txn->type === 'incentive');
            $incentiveTotal = (float) $incentiveItems->sum('amount');
            $incentiveTransactions = $incentiveItems->skip($paginationSkip)->take($limit)->map(function ($txn) {
                return [
                    'id' => $txn->id,
                    'order_id' => $txn->order_id,
                    'amount' => (float) ($txn->amount ?? 0),
                    'message' => $txn->message,
                    'payout_reference' => $txn->payout_reference,
                    'is_settled' => (int) ($txn->settled_with_admin ?? 0),
                    'settled_at' => $txn->settled_at ?? null,
                    'date' => $txn->transaction_date ?? $txn->created_at,
                ];
            })->values();

            // --- Section 6: Multi Order Bonus (commented out for now) ---
            // $multiOrderItems = $orderTransactions->filter(fn($txn) => ($txn->bonus_amount ?? 0) > 0);
            // $multiOrderTotal = (float) $multiOrderItems->sum('bonus_amount');
            // $multiOrderTransactions = $multiOrderItems->skip($paginationSkip)->take($limit)->map(function ($txn) {
            //     return [
            //         'id' => $txn->id,
            //         'order_id' => $txn->order_id,
            //         'amount' => (float) ($txn->bonus_amount ?? 0),
            //         'message' => $txn->message,
            //         'payout_reference' => $txn->payout_reference,
            //         'is_settled' => (int) ($txn->settled_with_admin ?? 0),
            //         'settled_at' => $txn->settled_at ?? null,
            //         'date' => $txn->transaction_date ?? $txn->created_at,
            //     ];
            // })->values();

            // Grand total
            $grandTotal = $earningsTotal + $tipsTotal + $rainTotal + $referralTotal + $incentiveTotal;

            // Build sections array
            $sections = [
                [
                    'key' => 'earnings',
                    'label' => 'Delivery Earnings',
                    'total' => (float) round($earningsTotal, 2),
                    'count' => $earningsItems->count(),
                    'transactions' => $earningsTransactions,
                ],
                [
                    'key' => 'customer_tips',
                    'label' => 'Customer Tips',
                    'total' => (float) round($tipsTotal, 2),
                    'count' => $tipsItems->count(),
                    'transactions' => $tipsTransactions,
                ],
                [
                    'key' => 'rain_surcharge',
                    'label' => 'Rain Surcharge',
                    'total' => (float) round($rainTotal, 2),
                    'count' => $rainItems->count(),
                    'transactions' => $rainTransactions,
                ],
                [
                    'key' => 'referral',
                    'label' => 'Referral Bonus',
                    'total' => (float) round($referralTotal, 2),
                    'count' => $referralItems->count(),
                    'transactions' => $referralTransactions,
                ],
                [
                    'key' => 'incentive',
                    'label' => 'Incentives',
                    'total' => (float) round($incentiveTotal, 2),
                    'count' => $incentiveItems->count(),
                    'transactions' => $incentiveTransactions,
                ],
                // [
                //     'key' => 'multi_order',
                //     'label' => 'Multi Order Bonus',
                //     'total' => (float) round($multiOrderTotal, 2),
                //     'count' => $multiOrderItems->count(),
                //     'transactions' => $multiOrderTransactions,
                // ],
            ];

            return CommonHelper::responseWithData([
                'period' => $period,
                'period_name' => $periodName,
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
                'total_earnings' => $earningsItems->count() + $tipsItems->count() + $rainItems->count() + $referralItems->count() + $incentiveItems->count(),
                'grand_total' => (float) round($grandTotal, 2),
                'pagination' => [
                    'page' => $page,
                    'limit' => $limit,
                ],
                'sections' => $sections,
            ]);

        } catch (\Exception $e) {
            \Log::error('Driver earnings sections error: ' . $e->getMessage());
            return CommonHelper::responseError('Something went wrong!');
        }
    }

    /**
     * Get hand cash details for the authenticated driver
     * GET /api/delivery-boy/hand-cash
     *
     * Returns all hand cash related data including:
     * - Total cash in hand
     * - Pending settlement amount
     * - Settled amount
     * - Transaction history
     *
     * Query Parameters:
     * - page: Pagination page (default: 1)
     * - per_page: Items per page (default: 20)
     */
    public function getHandCashDetails(Request $request)
    {
        try {
            // Authenticate user
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            // Get delivery boy record
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            // Get all hand cash transactions for summary calculations
            $allHandCash = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->where('is_hand_cash', 1)
                ->get();

            // Calculate totals based on admin_cash (amount driver owes to admin)
            $totalHandCash = $allHandCash->sum('admin_cash');
            $settledTotal = $allHandCash->where('settled_with_admin', 1)->sum('admin_cash');
            $notSettledTotal = $allHandCash->where('settled_with_admin', 0)->sum('admin_cash');

            // Calculate transaction counts
            $totalCount = $allHandCash->count();
            $settledCount = $allHandCash->where('settled_with_admin', 1)->count();
            $notSettledCount = $allHandCash->where('settled_with_admin', 0)->count();

            // Build query for paginated transactions
            $query = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->where('is_hand_cash', 1);

            // Filter by is_settled if provided
            if ($request->has('is_settled')) {
                $isSettled = (int) $request->input('is_settled');
                $query->where('settled_with_admin', $isSettled);
            }

            // Pagination
            $perPage = (int) ($request->input('per_page', 10));
            $page = (int) ($request->input('page', 1));

            $transactions = $query->orderBy('created_at', 'DESC')
                ->paginate($perPage, ['*'], 'page', $page);

            // Return response
            return CommonHelper::responseWithData([
                'summary' => [
                    'total_hand_cash' => (float) $totalHandCash,
                    'settled_with_admin_total' => (float) $settledTotal,
                    'not_settled_with_admin_total' => (float) $notSettledTotal,
                    'total_transactions_count' => (int) $totalCount,
                    'settled_count' => (int) $settledCount,
                    'not_settled_count' => (int) $notSettledCount
                ],
                'pagination' => [
                    'current_page' => $transactions->currentPage(),
                    'per_page' => $transactions->perPage(),
                    'total_items' => $transactions->total(),
                    'total_pages' => $transactions->lastPage()
                ],
                'transactions' => $transactions->items()
            ]);

        } catch (\Exception $e) {
            \Log::error('Hand Cash Details API Error: ' . $e->getMessage());
            return CommonHelper::responseError('Something went wrong!');
        }
    }

    /**
     * Generate Paytm transaction token for hand cash settlement
     * POST /api/delivery-boy/hand-cash/generate-paytm-token
     *
     * @param Request $request
     * - amount: amount to settle with admin
     */
    public function generatePaytmTokenForHandCash(Request $request)
    {
        $requestId = 'paytm_handcash_' . time() . '_' . uniqid();

        try {
            Log::info('=== GENERATE PAYTM TOKEN FOR HAND CASH START ===', [
                'request_id' => $requestId
            ]);

            // Authenticate user
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            // Get delivery boy record
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            // Validate amount
            $amount = $request->input('amount');
            if (!$amount || !is_numeric($amount) || $amount <= 0) {
                return CommonHelper::responseError('Valid amount is required');
            }

            $amount = floatval($amount);

            Log::info('→ Delivery boy hand cash settlement token request', [
                'request_id' => $requestId,
                'delivery_boy_id' => $deliveryBoy->id,
                'amount' => $amount
            ]);

            // Get Paytm credentials
            $credentials = \App\Helpers\Paytm::get_credentials();

            Log::info('→ Paytm credentials loaded', [
                'request_id' => $requestId,
                'environment' => $credentials['paytm_payment_mode'],
                'merchant_id' => substr($credentials['paytm_merchant_id'], 0, 5) . '***'
            ]);

            // Generate unique order ID for hand cash settlement
            $orderId = 'HANDCASH_SETTLE_' . $deliveryBoy->id . '_' . time() . '_' . uniqid();

            Log::info('→ Generated order ID', [
                'request_id' => $requestId,
                'order_id' => $orderId
            ]);

            // Prepare Paytm params for token generation
            $paytmParams = [
                "body" => [
                    "requestType" => "Payment",
                    "mid" => $credentials['paytm_merchant_id'],
                    "websiteName" => $credentials['paytm_website'],
                    "orderId" => $orderId,
                    "callbackUrl" => $credentials['url'] . "theia/paytmCallback?ORDER_ID=" . $orderId,
                    "txnAmount" => [
                        "value" => number_format($amount, 2, '.', ''),
                        "currency" => "INR",
                    ],
                    "userInfo" => [
                        "custId" => "DELIVERY_BOY_" . $deliveryBoy->id,
                    ],
                ]
            ];

            Log::info('→ Preparing Paytm request', [
                'request_id' => $requestId,
                'params' => $paytmParams
            ]);

            // Generate checksum
            $checksum = \App\Helpers\Paytm::generateSignature(
                json_encode($paytmParams["body"], JSON_UNESCAPED_SLASHES),
                $credentials['paytm_merchant_key']
            );

            $paytmParams["head"] = ["signature" => $checksum];

            Log::info('→ Checksum generated', [
                'request_id' => $requestId,
                'checksum' => substr($checksum, 0, 10) . '...'
            ]);

            // Build Paytm API URL
            $url = $credentials['url'] . "theia/api/v1/initiateTransaction?mid=" . $credentials['paytm_merchant_id'] . "&orderId=" . $orderId;

            Log::info('→ Calling Paytm API', [
                'request_id' => $requestId,
                'url' => $url
            ]);

            // Make API call to Paytm
            $ch = curl_init($url);
            curl_setopt($ch, CURLOPT_POST, 1);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($paytmParams, JSON_UNESCAPED_SLASHES));
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_HTTPHEADER, ["Content-Type: application/json"]);
            curl_setopt($ch, CURLOPT_TIMEOUT, 30);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $curlError = curl_error($ch);
            curl_close($ch);

            if ($curlError) {
                Log::error('→ CURL error occurred', [
                    'request_id' => $requestId,
                    'error' => $curlError
                ]);
                return CommonHelper::responseError('Failed to connect to payment gateway');
            }

            Log::info('→ Paytm API response received', [
                'request_id' => $requestId,
                'http_code' => $httpCode,
                'response' => $response
            ]);

            // Parse response
            $responseData = json_decode($response, true);

            if (!$responseData || !isset($responseData['body'])) {
                Log::error('→ Invalid response from Paytm', [
                    'request_id' => $requestId,
                    'response' => $response
                ]);
                return CommonHelper::responseError('Invalid response from payment gateway');
            }

            $body = $responseData['body'];
            $resultInfo = $body['resultInfo'] ?? [];

            // Check if token generation was successful
            if (isset($body['txnToken']) && !empty($body['txnToken'])) {
                Log::info('=== PAYTM TOKEN GENERATED SUCCESSFULLY ===', [
                    'request_id' => $requestId,
                    'order_id' => $orderId,
                    'token' => substr($body['txnToken'], 0, 20) . '...'
                ]);

                return CommonHelper::responseWithData([
                    'txn_token' => $body['txnToken'],
                    'order_id' => $orderId,
                    'amount' => $amount,
                    'merchant_id' => $credentials['paytm_merchant_id'],
                    'website' => $credentials['paytm_website'],
                    'callback_url' => $credentials['url'] . "theia/paytmCallback?ORDER_ID=" . $orderId,
                    'type' => 'hand_cash_settlement'
                ], 'Transaction token generated successfully');
            } else {
                Log::error('→ Failed to generate token', [
                    'request_id' => $requestId,
                    'result_code' => $resultInfo['resultCode'] ?? 'N/A',
                    'result_msg' => $resultInfo['resultMsg'] ?? 'N/A'
                ]);

                return CommonHelper::responseError(
                    'Failed to generate payment token: ' . ($resultInfo['resultMsg'] ?? 'Unknown error')
                );
            }

        } catch (\Exception $e) {
            Log::error('=== PAYTM TOKEN GENERATION ERROR ===', [
                'request_id' => $requestId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to generate payment token');
        }
    }

    /**
     * Settle hand cash with admin
     * POST /api/delivery-boy/hand-cash/settle
     *
     * @param Request $request
     * - transaction_ids: array of transaction IDs to settle
     * - payment_transaction_id: payment gateway transaction ID
     * - payment_gateway: 'razorpay', 'phonepe', or 'paytm' (optional, auto-detected from settings)
     */
    public function settleHandCash(Request $request)
    {
        try {
            // Authenticate user
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            // Get delivery boy record
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            // Validate request
            $transactionIds = $request->input('transaction_ids');
            $paymentTransactionId = $request->input('payment_transaction_id');

            if (empty($transactionIds) || !is_array($transactionIds)) {
                return CommonHelper::responseError('transaction_ids is required and must be an array');
            }

            if (empty($paymentTransactionId)) {
                return CommonHelper::responseError('payment_transaction_id is required');
            }

            // Get the transactions to settle
            $transactions = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->where('is_hand_cash', 1)
                ->where('settled_with_admin', 0)
                ->whereIn('id', $transactionIds)
                ->get();

            if ($transactions->isEmpty()) {
                return CommonHelper::responseError('No valid unsettled transactions found');
            }

            // Calculate total amount to settle
            $totalAmount = $transactions->sum('amount');

            // Determine payment gateway from settings or request
            $paymentGateway = $request->input('payment_gateway');
            if (!$paymentGateway) {
                // Get payment method from settings table
                $paymentMethodSetting = DB::table('settings')
                    ->where('variable', 'payment_method_name')
                    ->first();

                $paymentGateway = $paymentMethodSetting->value ?? 'razorpay';
            }

            // Check if payment verification should be skipped (for testing)
            $skipVerificationSetting = DB::table('settings')
                ->where('variable', 'skip_payment_verification')
                ->first();
            $skipVerification = $skipVerificationSetting && $skipVerificationSetting->value === 'true';

            Log::info('Hand Cash Settlement: Starting', [
                'delivery_boy_id' => $deliveryBoy->id,
                'transaction_ids' => $transactionIds,
                'payment_transaction_id' => $paymentTransactionId,
                'payment_gateway' => $paymentGateway,
                'total_amount' => $totalAmount,
                'skip_verification' => $skipVerification
            ]);

            // Verify/capture payment based on gateway (skip if testing mode enabled)
            $paymentResult = null;

            if ($skipVerification) {
                // Skip payment verification for testing
                Log::info('Hand Cash Settlement: SKIPPING payment verification (test mode)');
                $paymentResult = [
                    'success' => true,
                    'message' => 'Payment verification skipped (test mode)',
                    'data' => [
                        'payment_id' => $paymentTransactionId,
                        'amount' => $totalAmount,
                        'status' => 'test_mode'
                    ]
                ];
            } elseif ($paymentGateway === 'razorpay') {
                $paymentResult = \App\Services\RazorpayPaymentCaptureService::verifyAndCapture(
                    $paymentTransactionId,
                    $totalAmount
                );
            } elseif ($paymentGateway === 'phonepe') {
                $paymentResult = \App\Services\PhonePePaymentCaptureService::verifyPayment(
                    $paymentTransactionId,
                    $totalAmount
                );
            } elseif ($paymentGateway === 'paytm') {
                $paymentResult = \App\Services\PaytmPaymentCaptureService::verifyPayment(
                    $paymentTransactionId,
                    $totalAmount
                );
            } else {
                return CommonHelper::responseError('Invalid payment gateway: ' . $paymentGateway);
            }

            Log::info('Hand Cash Settlement: Payment verification result', [
                'payment_result' => $paymentResult
            ]);

            // Check if payment verification was successful
            if (!$paymentResult['success']) {
                return CommonHelper::responseError('Payment verification failed: ' . ($paymentResult['error'] ?? 'Unknown error'));
            }

            // Update transactions as settled
            $now = now();
            DB::table('delivery_boy_transactions')
                ->whereIn('id', $transactionIds)
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->update([
                    'settled_with_admin' => 1,
                    'settled_at' => $now,
                    'payout_reference' => $paymentTransactionId,
                    'updated_at' => $now
                ]);

            Log::info('Hand Cash Settlement: Transactions updated', [
                'transaction_ids' => $transactionIds,
                'settled_at' => $now,
                'payout_reference' => $paymentTransactionId
            ]);

            return CommonHelper::responseWithData([
                'message' => 'Hand cash settled successfully',
                'settled_transaction_ids' => $transactionIds,
                'total_amount_settled' => $totalAmount,
                'payment_transaction_id' => $paymentTransactionId,
                'payment_gateway' => $paymentGateway,
                'settled_at' => $now->toDateTimeString()
            ]);

        } catch (\Exception $e) {
            Log::error('Hand Cash Settlement Error: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Something went wrong!');
        }
    }

    /**
     * Increment orders_cancelled count in daily tracking
     * POST /api/delivery-boy/order-cancelled
     *
     * @param Request $request
     * - order_id: (optional) the order ID that was cancelled
     */
    public function orderCancelled(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            $today = Carbon::today()->toDateString();

            $tracking = DeliveryBoyDailyTracking::firstOrCreate(
                [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'tracking_date' => $today,
                ],
                [
                    'online_status' => 'offline',
                    'total_login_minutes' => 0,
                    'total_earnings' => 0,
                    'total_distance_km' => 0,
                    'gigs_completed' => 0,
                    'orders_delivered' => 0,
                    'orders_cancelled' => 0,
                ]
            );

            $tracking->orders_cancelled += 1;
            $tracking->save();

            // Store cancellation record with order_id
            $orderId = $request->input('order_id');
            if ($orderId) {
                $cancellation = DB::table('delivery_boy_order_cancellations')
                    ->where('delivery_boy_id', $deliveryBoy->id)
                    ->where('order_id', $orderId)
                    ->first();

                if ($cancellation) {
                    DB::table('delivery_boy_order_cancellations')
                        ->where('id', $cancellation->id)
                        ->update([
                            'cancel_count' => $cancellation->cancel_count + 1,
                            'updated_at' => now(),
                        ]);
                } else {
                    DB::table('delivery_boy_order_cancellations')->insert([
                        'delivery_boy_id' => $deliveryBoy->id,
                        'order_id' => $orderId,
                        'cancel_count' => 1,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }

            Log::info('Order cancelled tracked', [
                'delivery_boy_id' => $deliveryBoy->id,
                'order_id' => $orderId,
                'date' => $today,
                'total_cancelled_today' => $tracking->orders_cancelled,
            ]);

            return CommonHelper::responseWithData([
                'orders_cancelled_today' => (int) $tracking->orders_cancelled,
            ], 'Order cancellation recorded successfully');

        } catch (\Exception $e) {
            Log::error('Order cancelled tracking error: ' . $e->getMessage());
            return CommonHelper::responseError('Something went wrong!');
        }
    }

    /**
     * Get detailed multi-order data for a specific order
     * GET /api/delivery-boy/performance/multi-order-detail?order_id=433
     */
    public function getMultiOrderDetail(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized');
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy not found');
            }

            $orderId = $request->input('order_id');
            if (empty($orderId)) {
                return CommonHelper::responseError('order_id is required');
            }

            // Get order with customer info
            $order = DB::table('orders')
                ->join('users', 'users.id', '=', 'orders.user_id')
                ->where('orders.id', $orderId)
                ->where('orders.delivery_boy_id', $deliveryBoy->id)
                ->select(
                    'orders.id',
                    'orders.orders_id',
                    'orders.address',
                    'orders.latitude',
                    'orders.longitude',
                    'orders.mobile',
                    'orders.order_type',
                    'orders.active_status',
                    'orders.payment_method',
                    'orders.delivery_boy_bonus_amount',
                    'orders.delivery_boy_bonus_details',
                    'orders.cart_metadata',
                    'orders.is_rain_surcharge',
                    'orders.rain_surcharge_amount',
                    'orders.created_at',
                    'orders.delivered_at_time',
                    'orders.driver_accepted_at_time',
                    'orders.driver_accepted_lat',
                    'orders.driver_accepted_lon',
                    'users.id as customer_id',
                    'users.name as customer_name',
                    'users.mobile as customer_mobile'
                )
                ->first();

            if (!$order) {
                return CommonHelper::responseError('Order not found');
            }

            // Get seller locations from order_seller_status_tracking
            $sellerTrackingRows = DB::table('order_seller_status_tracking as ost')
                ->leftJoin('sellers as s', 'ost.seller_id', '=', 's.id')
                ->where('ost.order_id', $orderId)
                ->select(
                    'ost.id as tracking_id',
                    'ost.seller_id',
                    'ost.store_id',
                    'ost.is_zenfoo_store',
                    'ost.status',
                    'ost.driver_arrived_at_seller',
                    's.store_name',
                    's.store_location',
                    's.lat_long',
                    's.mobile as seller_mobile'
                )
                ->get();

            // Build seller locations with parsed coordinates
            $sellerLocations = [];
            foreach ($sellerTrackingRows as $row) {
                $latitude = null;
                $longitude = null;

                if (!empty($row->lat_long)) {
                    $coords = explode(',', $row->lat_long);
                    if (count($coords) === 2) {
                        $latitude = (float) trim($coords[0]);
                        $longitude = (float) trim($coords[1]);
                    }
                }

                // For Zenfoo store entries (seller_id is null), get location from store_locations
                if ($row->is_zenfoo_store && empty($row->seller_id)) {
                    $zenfooLocation = $this->getZenfooStoreLocation($orderId);
                    if ($zenfooLocation) {
                        $sellerLocations[] = $zenfooLocation;
                        continue;
                    }
                }

                $sellerLocations[] = [
                    'tracking_id' => $row->tracking_id,
                    'seller_id' => $row->seller_id,
                    'store_id' => $row->store_id,
                    'is_zenfoo_store' => (bool) $row->is_zenfoo_store,
                    'store_name' => $row->store_name,
                    'seller_address' => $row->store_location,
                    'seller_mobile' => $row->seller_mobile,
                    'latitude' => $latitude,
                    'longitude' => $longitude,
                    'status' => $row->status,
                    'driver_arrived_at' => $row->driver_arrived_at_seller,
                ];
            }

            // Driver accepted location
            $driverLat = $order->driver_accepted_lat ? (float) $order->driver_accepted_lat : null;
            $driverLon = $order->driver_accepted_lon ? (float) $order->driver_accepted_lon : null;
            $driverAcceptedTime = $order->driver_accepted_at_time ? Carbon::parse($order->driver_accepted_at_time) : null;

            // Calculate route: driver → sellers → customer with distance and time
            $totalRouteDistance = 0;
            $routeLegs = [];

            for ($i = 0; $i < count($sellerLocations); $i++) {
                $current = $sellerLocations[$i];
                $distance = null;
                $timeTaken = null;

                if ($i === 0) {
                    // First leg: driver accepted location → first seller
                    if ($driverLat && $driverLon && $current['latitude'] && $current['longitude']) {
                        $distance = round(FirestoreDeliveryBoyService::calculateDistance(
                            $driverLat, $driverLon,
                            $current['latitude'], $current['longitude']
                        ) ?? 0, 2);
                        $totalRouteDistance += $distance;
                    }
                    // Time: first seller driver_arrived_at - driver_accepted_at_time
                    if ($driverAcceptedTime && !empty($current['driver_arrived_at'])) {
                        $arrivedAt = Carbon::parse($current['driver_arrived_at']);
                        $diffMinutes = $driverAcceptedTime->diffInMinutes($arrivedAt);
                        $timeTaken = $diffMinutes . ' min';
                    }
                } else {
                    // Subsequent legs: previous seller → current seller
                    $prev = $sellerLocations[$i - 1];
                    if ($prev['latitude'] && $prev['longitude'] && $current['latitude'] && $current['longitude']) {
                        $distance = round(FirestoreDeliveryBoyService::calculateDistance(
                            $prev['latitude'], $prev['longitude'],
                            $current['latitude'], $current['longitude']
                        ) ?? 0, 2);
                        $totalRouteDistance += $distance;
                    }
                    // Time: current seller driver_arrived_at - previous seller driver_arrived_at
                    if (!empty($prev['driver_arrived_at']) && !empty($current['driver_arrived_at'])) {
                        $prevArrived = Carbon::parse($prev['driver_arrived_at']);
                        $currArrived = Carbon::parse($current['driver_arrived_at']);
                        $diffMinutes = $prevArrived->diffInMinutes($currArrived);
                        $timeTaken = $diffMinutes . ' min';
                    }
                }

                $routeLegs[] = array_merge($current, [
                    'leg' => $i + 1,
                    'leg_type' => 'pickup',
                    'distance_from_previous_km' => $distance ?? 0,
                    'time_taken' => $timeTaken ?? '0 min',
                ]);
            }

            // Last seller → Customer leg
            $lastSeller = end($sellerLocations);
            $lastLegDistance = 0;
            $lastLegTime = '0 min';
            if ($lastSeller && $lastSeller['latitude'] && $lastSeller['longitude'] && $order->latitude && $order->longitude) {
                $lastLegDistance = round(FirestoreDeliveryBoyService::calculateDistance(
                    (float) $lastSeller['latitude'], (float) $lastSeller['longitude'],
                    (float) $order->latitude, (float) $order->longitude
                ) ?? 0, 2);
                $totalRouteDistance += $lastLegDistance;
            }
            // Time: delivered_at_time - last seller driver_arrived_at
            if ($lastSeller && !empty($lastSeller['driver_arrived_at']) && !empty($order->delivered_at_time)) {
                $lastArrived = Carbon::parse($lastSeller['driver_arrived_at']);
                $deliveredAt = Carbon::parse($order->delivered_at_time);
                $diffMinutes = $lastArrived->diffInMinutes($deliveredAt);
                $lastLegTime = $diffMinutes . ' min';
            }

            // Add customer as final leg
            $routeLegs[] = [
                'leg' => count($sellerLocations) + 1,
                'leg_type' => 'delivery',
                'store_name' => null,
                'seller_address' => null,
                'customer_name' => $order->customer_name,
                'delivery_address' => $order->address,
                'latitude' => $order->latitude ? (float) $order->latitude : null,
                'longitude' => $order->longitude ? (float) $order->longitude : null,
                'distance_from_previous_km' => $lastLegDistance ?? 0,
                'time_taken' => $lastLegTime ?? '0 min',
            ];

            // Get earnings from transaction
            $txn = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
                ->where('order_id', $orderId)
                ->where('status', 'success')
                ->first();

            $cartMeta = json_decode($order->cart_metadata, true);
            $deliveryTip = $cartMeta['cart_info']['delivery_tip'] ?? 0;
            $deliveryCharge = $cartMeta['billing_summary']['delivery_charge'] ?? 0;
            $totalOrderValue = $cartMeta['billing_summary']['to_be_paid'] ?? 0;

            // Multi-order bonus info
            $storeSellers = range(1, count($sellerTrackingRows));
            $storeNames = collect($sellerLocations)->pluck('store_name')->filter()->unique()->values()->toArray();

            return CommonHelper::responseWithData([
                'order_id' => (int) $order->id,
                'orders_id' => $order->orders_id,
                'order_date' => $order->created_at,
                'delivered_at' => $order->delivered_at_time,
                'active_status' => $order->active_status,
                'payment_method' => $order->payment_method,
                'order_type' => $order->order_type,

                'customer' => [
                    'id' => (int) $order->customer_id,
                    'name' => $order->customer_name,
                    'mobile' => $order->customer_mobile,
                    'delivery_address' => $order->address,
                    'latitude' => $order->latitude ? (float) $order->latitude : null,
                    'longitude' => $order->longitude ? (float) $order->longitude : null,
                ],

                'store_names' => $storeNames,
                'store_sellers' => $storeSellers,

                'driver_start' => [
                    'latitude' => $driverLat,
                    'longitude' => $driverLon,
                    'accepted_at' => $order->driver_accepted_at_time,
                ],

                'total_distance_km' => round($totalRouteDistance, 2),
                'total_time' => ($driverAcceptedTime && $order->delivered_at_time)
                    ? $driverAcceptedTime->diffInMinutes(Carbon::parse($order->delivered_at_time)) . ' min'
                    : '0 min',

                'route' => [
                    'total_stops' => count($routeLegs),
                    'total_route_distance_km' => round($totalRouteDistance, 2),
                    'legs' => $routeLegs,
                ],

                'is_prepaid' => strtolower($order->payment_method) !== 'cod' ? 1 : 0,
                'earnings' => [
                    'delivery_charge' => (float) ($txn->delivery_charge ?? $deliveryCharge),
                    'delivery_tip' => (float) ($txn->delivery_tip ?? $deliveryTip),
                    'multi_order_bonus' => (float) ($order->delivery_boy_bonus_amount ?? 0),
                    'rain_surcharge' => (float) ($txn->rain_surcharge ?? 0),
                    'vendor_wait_charge' => (float) ($txn->vendor_wait_charge ?? 0),
                    'driver_earnings' => (float) ($txn->driver_earnings ?? 0),
                    'admin_cash' => strtolower($order->payment_method) !== 'cod' ? 0 : (float) ($txn->admin_cash ?? 0),
                    'total_order_value' => (float) $totalOrderValue,
                ],

                'is_rain_surcharge' => (bool) ($order->is_rain_surcharge ?? false),
                'rain_surcharge_amount' => (float) ($order->rain_surcharge_amount ?? 0),
            ]);

        } catch (\Exception $e) {
            Log::error('Multi-order detail error: ' . $e->getMessage());
            return CommonHelper::responseError('Something went wrong!');
        }
    }

    /**
     * Get Zenfoo store location for an order based on city
     */
    private function getZenfooStoreLocation(int $orderId): ?array
    {
        $order = DB::table('orders')
            ->leftJoin('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
            ->where('orders.id', $orderId)
            ->select('user_addresses.city_id')
            ->first();

        if (!$order || !$order->city_id) {
            return null;
        }

        $storeLocation = DB::table('store_locations')
            ->where('city_id', $order->city_id)
            ->where('status', 1)
            ->first();

        if (!$storeLocation) {
            return null;
        }

        return [
            'tracking_id' => null,
            'seller_id' => null,
            'store_id' => 12,
            'is_zenfoo_store' => true,
            'store_name' => $storeLocation->name,
            'seller_address' => $storeLocation->address,
            'seller_mobile' => null,
            'latitude' => $storeLocation->latitude ? (float) $storeLocation->latitude : null,
            'longitude' => $storeLocation->longitude ? (float) $storeLocation->longitude : null,
            'status' => null,
            'driver_arrived_at' => null,
        ];
    }

    /**
     * Format login hours to HH:MM:SS
     */
    private function formatLoginHours($hours)
    {
        $totalSeconds = (int) ($hours * 3600);
        $h = floor($totalSeconds / 3600);
        $m = floor(($totalSeconds % 3600) / 60);
        $s = $totalSeconds % 60;

        return sprintf('%02d:%02d:%02d', $h, $m, $s);
    }
}
