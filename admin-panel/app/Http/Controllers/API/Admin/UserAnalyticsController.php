<?php

namespace App\Http\Controllers\API\Admin;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\City;
use App\Models\Order;
use App\Models\User;
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

class UserAnalyticsController extends Controller
{
    /**
     * Get user analytics data with date filters.
     */
    public function getAnalytics(Request $request)
    {
        Log::info('======================================');
        Log::info('USER ANALYTICS API REQUEST');
        Log::info('======================================');
        Log::info('Request Parameters:', $request->all());

        $filter = $request->get('filter', 'daily');
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
                $start = Carbon::today();
                $end = Carbon::today()->endOfDay();
        }

        $cityId = $request->get('city_id');

        // User summary metrics
        $summary = $this->getUserSummary($start, $end, $cityId);

        // User registrations over time
        $registrationsTrend = $this->getRegistrationsTrend($start, $end, $filter, $cityId);

        // Active vs Inactive users
        $userActivity = $this->getUserActivity($start, $end, $cityId);

        // User segmentation by order count
        // $userSegmentation = $this->getUserSegmentation($start, $end, $cityId);

        // Registration sources
        // $registrationSources = $this->getRegistrationSources($start, $end, $cityId);

        // Top customers by revenue and orders
        $topCustomers = $this->getTopCustomers($start, $end, $cityId);

        // Users by zone/city
        $usersByZone = $this->getUsersByZone($cityId);

        // Customer behavior
        $customerBehavior = $this->getCustomerBehavior($start, $end, $cityId);

        // New customers in period
        $newCustomers = $this->getNewCustomers($start, $end, $cityId);

        // Retention metrics
        $retentionMetrics = $this->getRetentionMetrics($start, $end, $cityId);

        $data = [
            'filter' => $filter,
            'start_date' => $start->toDateString(),
            'end_date' => $end->toDateString(),
            'summary' => $summary,
            'registrations_trend' => $registrationsTrend,
            'user_activity' => $userActivity,
            // 'user_segmentation' => $userSegmentation,
            // 'registration_sources' => $registrationSources,
            'top_customers' => $topCustomers,
            'users_by_zone' => $usersByZone,
            'customer_behavior' => $customerBehavior,
            'new_customers' => $newCustomers,
            'retention_metrics' => $retentionMetrics,
        ];

        Log::info('======================================');
        Log::info('USER ANALYTICS API RESPONSE SUMMARY');
        Log::info('======================================');
        Log::info('Response Summary Counts:', [
            'total_users' => $summary['total_users'] ?? 0,
            'new_registrations' => $summary['new_registrations'] ?? 0,
            'active_users' => $summary['active_users'] ?? 0,
            'inactive_users' => $summary['inactive_users'] ?? 0,
            'new_customers_count' => count($newCustomers ?? []),
            'top_customers_by_revenue_count' => count($data['top_customers']['by_revenue'] ?? []),
            'top_customers_by_orders_count' => count($data['top_customers']['by_orders'] ?? []),
        ]);
        Log::info('======================================');

        return CommonHelper::responseWithData($data);
    }

    /**
     * Get user summary metrics.
     */
    private function getUserSummary(Carbon $start, Carbon $end, ?string $cityId = null)
    {
        Log::info('=== getUserSummary START ===');
        Log::info('Parameters:', [
            'start_date' => $start->toDateTimeString(),
            'end_date' => $end->toDateTimeString(),
            'city_id' => $cityId
        ]);

        // Debug: Check user_addresses table for this city
        if ($cityId) {
            $addressCount = DB::table('user_addresses')
                ->where('city_id', $cityId)
                ->count();

            $sampleAddresses = DB::table('user_addresses')
                ->where('city_id', $cityId)
                ->limit(5)
                ->get(['id', 'user_id', 'city_id']);

            Log::info('Debug - user_addresses data for city:', [
                'city_id' => $cityId,
                'total_addresses_count' => $addressCount,
                'sample_addresses' => $sampleAddresses->toArray()
            ]);

            // Check how many distinct users have addresses in this city
            $distinctUsersWithAddresses = DB::table('user_addresses')
                ->where('city_id', $cityId)
                ->distinct()
                ->count('user_id');

            Log::info('Debug - Distinct users with addresses in city:', [
                'city_id' => $cityId,
                'distinct_user_count' => $distinctUsersWithAddresses
            ]);
        }

        // Total users (all time)
        $totalUsersQuery = User::select(DB::raw('COUNT(DISTINCT users.id) as total'))
            ->where('users.type', '!=', 'admin');

        if ($cityId) {
            $totalUsersQuery->join('user_addresses', 'users.id', '=', 'user_addresses.user_id')
                ->where('user_addresses.city_id', $cityId);
        }

        Log::info('Total Users Query SQL:', [
            'sql' => $totalUsersQuery->toSql(),
            'bindings' => $totalUsersQuery->getBindings()
        ]);

        $totalUsers = $totalUsersQuery->value('total') ?? 0;

        Log::info('Total Users Result:', ['count' => $totalUsers]);

        // New registrations in period
        $newUsersQuery = User::select(DB::raw('COUNT(DISTINCT users.id) as total'))
            ->where('users.type', '!=', 'admin')
            ->whereBetween('users.created_at', [$start, $end]);

        if ($cityId) {
            $newUsersQuery->join('user_addresses', 'users.id', '=', 'user_addresses.user_id')
                ->where('user_addresses.city_id', $cityId);
        }

        Log::info('New Registrations Query SQL:', [
            'sql' => $newUsersQuery->toSql(),
            'bindings' => $newUsersQuery->getBindings()
        ]);

        $newRegistrations = $newUsersQuery->value('total') ?? 0;

        Log::info('New Registrations Result:', ['count' => $newRegistrations]);

        // Active users (users who placed orders in period)
        $activeUsersQuery = User::select(DB::raw('COUNT(DISTINCT users.id) as total'))
            ->join('orders', 'users.id', '=', 'orders.user_id')
            ->where('users.type', '!=', 'admin')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $activeUsersQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        Log::info('Active Users Query SQL:', [
            'sql' => $activeUsersQuery->toSql(),
            'bindings' => $activeUsersQuery->getBindings()
        ]);

        $activeUsers = $activeUsersQuery->value('total') ?? 0;

        Log::info('Active Users Result:', ['count' => $activeUsers]);

        // Inactive users
        $inactiveUsers = max(0, $totalUsers - $activeUsers);

        // Get orders data for active users
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

        Log::info('Orders Data Query SQL:', [
            'sql' => $ordersQuery->toSql(),
            'bindings' => $ordersQuery->getBindings()
        ]);

        $ordersData = $ordersQuery->first();

        $totalOrders = $ordersData->total_orders ?? 0;
        $totalRevenue = floatval($ordersData->total_revenue ?? 0);

        Log::info('Orders Data Result:', [
            'total_orders' => $totalOrders,
            'total_revenue' => $totalRevenue
        ]);

        $avgOrdersPerUser = $activeUsers > 0 ? round($totalOrders / $activeUsers, 2) : 0;
        $avgRevenuePerUser = $activeUsers > 0 ? round($totalRevenue / $activeUsers, 2) : 0;

        // Total customer lifetime value
        $totalLtvQuery = Order::select(DB::raw('COALESCE(SUM(orders.final_total), 0) as ltv'))
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $totalLtvQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        Log::info('Total LTV Query SQL:', [
            'sql' => $totalLtvQuery->toSql(),
            'bindings' => $totalLtvQuery->getBindings()
        ]);

        $totalLtv = floatval($totalLtvQuery->value('ltv'));

        Log::info('Total LTV Result:', ['ltv' => $totalLtv]);

        $result = [
            'total_users' => $totalUsers,
            'new_registrations' => $newRegistrations,
            'active_users' => $activeUsers,
            'inactive_users' => $inactiveUsers,
            'avg_orders_per_user' => $avgOrdersPerUser,
            'avg_revenue_per_user' => $avgRevenuePerUser,
            'total_customer_ltv' => round($totalLtv, 2),
            'total_orders_in_period' => $totalOrders,
            'total_revenue_in_period' => round($totalRevenue, 2),
        ];

        Log::info('getUserSummary Final Result:', $result);
        Log::info('=== getUserSummary END ===');

        return $result;
    }

    /**
     * Get user registrations trend over time.
     */
    private function getRegistrationsTrend(Carbon $start, Carbon $end, string $filter, ?string $cityId = null)
    {
        $query = User::select('users.created_at')
            ->where('users.type', '!=', 'admin')
            ->whereBetween('users.created_at', [$start, $end]);

        if ($cityId) {
            $query->join('user_addresses', 'users.id', '=', 'user_addresses.user_id')
                ->where('user_addresses.city_id', $cityId)
                ->distinct();
        }

        $users = $query->get();

        $grouped = [];
        foreach ($users as $user) {
            $key = $this->getDateKey($user->created_at, $filter, $start, $end);
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
     * Get active vs inactive users.
     */
    private function getUserActivity(Carbon $start, Carbon $end, ?string $cityId = null)
    {
        Log::info('=== getUserActivity START ===', ['city_id' => $cityId]);

        // Active users (users who placed orders in the period)
        $activeUsersQuery = User::select(DB::raw('COUNT(DISTINCT users.id) as total'))
            ->join('orders', 'users.id', '=', 'orders.user_id')
            ->where('users.type', '!=', 'admin')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $activeUsersQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        Log::info('getUserActivity - Active Users Query:', [
            'sql' => $activeUsersQuery->toSql(),
            'bindings' => $activeUsersQuery->getBindings()
        ]);

        $activeUsers = $activeUsersQuery->value('total') ?? 0;

        Log::info('getUserActivity - Active Users:', ['count' => $activeUsers]);

        // Total users up to end date
        $totalUsersQuery = User::select(DB::raw('COUNT(DISTINCT users.id) as total'))
            ->where('users.type', '!=', 'admin')
            ->where('users.created_at', '<=', $end);

        if ($cityId) {
            $totalUsersQuery->join('user_addresses', 'users.id', '=', 'user_addresses.user_id')
                ->where('user_addresses.city_id', $cityId);
        }

        Log::info('getUserActivity - Total Users Query:', [
            'sql' => $totalUsersQuery->toSql(),
            'bindings' => $totalUsersQuery->getBindings()
        ]);

        $totalUsers = $totalUsersQuery->value('total') ?? 0;

        Log::info('getUserActivity - Total Users:', ['count' => $totalUsers]);

        $inactiveUsers = max(0, $totalUsers - $activeUsers);

        Log::info('=== getUserActivity END ===', [
            'active' => $activeUsers,
            'inactive' => $inactiveUsers,
            'total' => $totalUsers
        ]);

        return [
            'labels' => ['Active Users', 'Inactive Users'],
            'values' => [$activeUsers, $inactiveUsers],
        ];
    }

    // /**
    //  * Get user segmentation by order count.
    //  */
    // private function getUserSegmentation(Carbon $start, Carbon $end, ?string $cityId = null)
    // {
    //     $usersQuery = User::select('users.id')
    //         ->where('users.type', '!=', 'admin')
    //         ->leftJoin('orders', function ($join) use ($start, $end) {
    //             $join->on('users.id', '=', 'orders.user_id')
    //                 ->whereBetween('orders.created_at', [$start, $end])
    //                 ->whereNotIn('orders.active_status', [1]);
    //         });

    //     if ($cityId) {
    //         $usersQuery->leftJoin('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
    //             ->where(function ($q) use ($cityId) {
    //                 $q->whereNull('user_addresses.city_id')
    //                   ->orWhere('user_addresses.city_id', $cityId);
    //             });
    //     }

    //     $userOrderCounts = $usersQuery->groupBy('users.id')
    //         ->get([DB::raw('COUNT(orders.id) as order_count')]);

    //     $segments = [
    //         'First-time (1)' => 0,
    //         'Occasional (2-5)' => 0,
    //         'Regular (6-10)' => 0,
    //         'Loyal (11-20)' => 0,
    //         'VIP (21+)' => 0,
    //     ];

    //     foreach ($userOrderCounts as $user) {
    //         $count = $user->order_count;
    //         if ($count == 1) {
    //             $segments['First-time (1)']++;
    //         } elseif ($count >= 2 && $count <= 5) {
    //             $segments['Occasional (2-5)']++;
    //         } elseif ($count >= 6 && $count <= 10) {
    //             $segments['Regular (6-10)']++;
    //         } elseif ($count >= 11 && $count <= 20) {
    //             $segments['Loyal (11-20)']++;
    //         } elseif ($count >= 21) {
    //             $segments['VIP (21+)']++;
    //         }
    //     }

    //     $labels = [];
    //     $values = [];
    //     foreach ($segments as $label => $value) {
    //         if ($value > 0) {
    //             $labels[] = $label;
    //             $values[] = $value;
    //         }
    //     }

    //     return [
    //         'labels' => $labels,
    //         'values' => $values,
    //     ];
    // }

    // /**
    //  * Get registration sources.
    //  */
    // private function getRegistrationSources(Carbon $start, Carbon $end, ?string $cityId = null)
    // {
    //     $query = User::select('type', DB::raw('COUNT(*) as count'))
    //         ->where('type', '!=', 'admin')
    //         ->whereBetween('created_at', [$start, $end])
    //         ->whereIn('type', ['phone', 'google', 'apple']);

    //     if ($cityId) {
    //         $query->whereHas('addresses', function ($q) use ($cityId) {
    //             $q->where('city_id', $cityId);
    //         });
    //     }

    //     $sources = $query->groupBy('type')->get();

    //     $labels = [];
    //     $values = [];

    //     foreach ($sources as $source) {
    //         $labels[] = ucfirst($source->type);
    //         $values[] = $source->count;
    //     }

    //     return [
    //         'labels' => $labels,
    //         'values' => $values,
    //     ];
    // }

    /**
     * Get top customers.
     */
    private function getTopCustomers(Carbon $start, Carbon $end, ?string $cityId = null, int $limit = 10)
    {
        $ordersQuery = Order::select(
                'orders.user_id',
                DB::raw('COUNT(DISTINCT orders.id) as order_count'),
                DB::raw('COALESCE(SUM(orders.final_total), 0) as total_spent'),
                DB::raw('COALESCE(AVG(orders.final_total), 0) as avg_order_value'),
                DB::raw('MAX(orders.created_at) as last_order_date'),
                DB::raw('MIN(orders.created_at) as first_order_date')
            )
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $ordersQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $customerStats = $ordersQuery->groupBy('orders.user_id')
            ->orderByDesc('total_spent')
            ->limit($limit)
            ->get();

        $topByRevenue = [];
        $topByOrders = [];

        foreach ($customerStats as $stat) {
            $user = User::find($stat->user_id);
            if ($user) {
                $topByRevenue[] = [
                    'user_id' => $user->id,
                    'name' => $user->name,
                    'mobile' => $user->mobile,
                    'order_count' => $stat->order_count,
                    'total_spent' => round($stat->total_spent, 2),
                    'avg_order_value' => round($stat->avg_order_value, 2),
                    'last_order_date' => $stat->last_order_date ? Carbon::parse($stat->last_order_date)->format('d M Y') : '-',
                    'first_order_date' => $stat->first_order_date ? Carbon::parse($stat->first_order_date)->format('d M Y') : '-',
                    'days_since_last_order' => $stat->last_order_date ? Carbon::parse($stat->last_order_date)->diffInDays(Carbon::now()) : '-',
                ];
            }
        }

        // Top by order count
        $ordersByCountQuery = Order::select(
                'orders.user_id',
                DB::raw('COUNT(DISTINCT orders.id) as order_count'),
                DB::raw('COALESCE(SUM(orders.final_total), 0) as total_spent')
            )
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $ordersByCountQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $topByOrdersData = $ordersByCountQuery->groupBy('orders.user_id')
            ->orderByDesc('order_count')
            ->limit($limit)
            ->get();

        foreach ($topByOrdersData as $stat) {
            $user = User::find($stat->user_id);
            if ($user) {
                $topByOrders[] = [
                    'user_id' => $user->id,
                    'name' => $user->name,
                    'order_count' => $stat->order_count,
                    'total_spent' => round($stat->total_spent, 2),
                ];
            }
        }

        return [
            'by_revenue' => $topByRevenue,
            'by_orders' => $topByOrders,
        ];
    }

    /**
     * Get users by zone.
     */
    private function getUsersByZone(?string $cityId = null)
    {
        Log::info('=== getUsersByZone START ===', ['city_id' => $cityId]);

        $query = User::select('user_addresses.city_id', DB::raw('COUNT(DISTINCT users.id) as user_count'))
            ->join('user_addresses', 'users.id', '=', 'user_addresses.user_id')
            ->where('users.type', '!=', 'admin')
            ->whereNotNull('user_addresses.city_id');

        if ($cityId) {
            $query->where('user_addresses.city_id', $cityId);
        }

        Log::info('getUsersByZone Query:', [
            'sql' => $query->toSql(),
            'bindings' => $query->getBindings()
        ]);

        $zones = $query->groupBy('user_addresses.city_id')
            ->orderByDesc('user_count')
            ->limit(10)
            ->get();

        Log::info('getUsersByZone Raw Results:', [
            'zones_count' => $zones->count(),
            'zones_data' => $zones->toArray()
        ]);

        $labels = [];
        $values = [];

        foreach ($zones as $zone) {
            $city = City::find($zone->city_id);
            if ($city) {
                $labels[] = $city->name;
                $values[] = $zone->user_count;
            }
        }

        Log::info('=== getUsersByZone END ===', [
            'labels' => $labels,
            'values' => $values
        ]);

        return [
            'labels' => $labels,
            'values' => $values,
        ];
    }

    /**
     * Get customer behavior.
     */
    private function getCustomerBehavior(Carbon $start, Carbon $end, ?string $cityId = null)
    {
        // Payment methods
        $paymentQuery = Order::select('orders.payment_method', DB::raw('COUNT(DISTINCT orders.id) as count'))
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $paymentQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $paymentMethods = $paymentQuery->groupBy('orders.payment_method')->get();

        $paymentLabels = [];
        $paymentValues = [];
        foreach ($paymentMethods as $pm) {
            $paymentLabels[] = ucwords(str_replace('_', ' ', $pm->payment_method));
            $paymentValues[] = $pm->count;
        }

        // Delivery types
        // $deliveryQuery = Order::select('order_type', DB::raw('COUNT(*) as count'))
        //     ->whereBetween('created_at', [$start, $end])
        //     ->whereNotIn('active_status', [1]);

        // if ($cityId) {
        //     $deliveryQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
        //         ->where('user_addresses.city_id', $cityId);
        // }

        // $deliveryTypes = $deliveryQuery->groupBy('order_type')->get();

        // $deliveryLabels = [];
        // $deliveryValues = [];
        // foreach ($deliveryTypes as $dt) {
        //     $deliveryLabels[] = ucfirst($dt->order_type);
        //     $deliveryValues[] = $dt->count;
        // }

        // Promo usage rate
        $totalOrdersQuery = Order::select(DB::raw('COUNT(DISTINCT orders.id) as total'))
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $totalOrdersQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $totalOrders = $totalOrdersQuery->value('total') ?? 0;

        $ordersWithPromoQuery = Order::select(DB::raw('COUNT(DISTINCT orders.id) as total'))
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->whereNotNull('orders.promo_code')
            ->where('orders.promo_code', '!=', '');

        if ($cityId) {
            $ordersWithPromoQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $ordersWithPromo = $ordersWithPromoQuery->value('total') ?? 0;

        $promoUsageRate = $totalOrders > 0 ? round(($ordersWithPromo / $totalOrders) * 100, 1) : 0;

        return [
            'payment_methods' => [
                'labels' => $paymentLabels,
                'values' => $paymentValues,
            ],
            // 'delivery_types' => [
            //     'labels' => $deliveryLabels,
            //     'values' => $deliveryValues,
            // ],
            'promo_usage_rate' => $promoUsageRate,
        ];
    }

    /**
     * Get new customers.
     */
    private function getNewCustomers(Carbon $start, Carbon $end, ?string $cityId = null, int $limit = 50)
    {
        $query = User::select('users.*')
            ->where('users.type', '!=', 'admin')
            ->whereBetween('users.created_at', [$start, $end]);

        if ($cityId) {
            $query->join('user_addresses', 'users.id', '=', 'user_addresses.user_id')
                ->where('user_addresses.city_id', $cityId)
                ->distinct();
        }

        $newUsers = $query->orderByDesc('users.created_at')
            ->limit($limit)
            ->get();

        $customers = [];
        foreach ($newUsers as $user) {
            $firstOrderQuery = Order::select('orders.*')
                ->where('orders.user_id', $user->id)
                ->whereNotIn('orders.active_status', [1])
                ->orderBy('orders.created_at', 'asc');

            if ($cityId) {
                $firstOrderQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                    ->where('user_addresses.city_id', $cityId);
            }

            $firstOrder = $firstOrderQuery->first();

            $totalOrdersQuery = Order::select(
                    DB::raw('COUNT(DISTINCT orders.id) as order_count'),
                    DB::raw('COALESCE(SUM(orders.final_total), 0) as total_spent')
                )
                ->where('orders.user_id', $user->id)
                ->whereNotIn('orders.active_status', [1]);

            if ($cityId) {
                $totalOrdersQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                    ->where('user_addresses.city_id', $cityId);
            }

            $orderData = $totalOrdersQuery->first();
            $orderCount = $orderData->order_count ?? 0;
            $totalSpent = floatval($orderData->total_spent ?? 0);

            $customers[] = [
                'user_id' => $user->id,
                'name' => $user->name,
                'mobile' => $user->mobile,
                'email' => $user->email,
                'registered_date' => Carbon::parse($user->created_at)->format('d M Y'),
                'first_order_date' => $firstOrder ? Carbon::parse($firstOrder->created_at)->format('d M Y') : '-',
                'total_orders' => $orderCount,
                'total_spent' => round($totalSpent, 2),
            ];
        }

        return $customers;
    }

    /**
     * Get retention metrics.
     */
    private function getRetentionMetrics(Carbon $start, Carbon $end, ?string $cityId = null)
    {
        // Total active users (users with at least 1 order in period)
        $usersWithOrdersQuery = User::select(DB::raw('COUNT(DISTINCT users.id) as total'))
            ->join('orders', 'users.id', '=', 'orders.user_id')
            ->where('users.type', '!=', 'admin')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $usersWithOrdersQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $totalActiveUsers = $usersWithOrdersQuery->value('total') ?? 0;

        // Repeat customers (users with 2+ orders in period)
        $repeatCustomersQuery = User::select(DB::raw('COUNT(DISTINCT users.id) as total'))
            ->join('orders', 'users.id', '=', 'orders.user_id')
            ->where('users.type', '!=', 'admin')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1]);

        if ($cityId) {
            $repeatCustomersQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $repeatCustomersQuery->groupBy('users.id')
            ->havingRaw('COUNT(DISTINCT orders.id) >= 2');

        $repeatCustomers = $repeatCustomersQuery->count();

        $retentionRate = $totalActiveUsers > 0 ? round(($repeatCustomers / $totalActiveUsers) * 100, 1) : 0;

        // Avg days between orders
        $repeatOrdersQuery = Order::select('orders.user_id', 'orders.created_at')
            ->whereBetween('orders.created_at', [$start, $end])
            ->whereNotIn('orders.active_status', [1])
            ->whereIn('orders.user_id', function ($q) use ($start, $end, $cityId) {
                $q->select('orders.user_id')
                    ->from('orders')
                    ->whereBetween('orders.created_at', [$start, $end])
                    ->whereNotIn('orders.active_status', [1]);
                if ($cityId) {
                    $q->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                        ->where('user_addresses.city_id', $cityId);
                }
                $q->groupBy('orders.user_id')
                    ->havingRaw('COUNT(DISTINCT orders.id) >= 2');
            })
            ->orderBy('orders.user_id')
            ->orderBy('orders.created_at');

        if ($cityId) {
            $repeatOrdersQuery->join('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
                ->where('user_addresses.city_id', $cityId);
        }

        $repeatOrders = $repeatOrdersQuery->get();

        $daysBetweenOrders = [];
        $prevUserId = null;
        $prevDate = null;

        foreach ($repeatOrders as $order) {
            if ($prevUserId === $order->user_id && $prevDate) {
                $days = Carbon::parse($prevDate)->diffInDays(Carbon::parse($order->created_at));
                $daysBetweenOrders[] = $days;
            }
            $prevUserId = $order->user_id;
            $prevDate = $order->created_at;
        }

        $avgDaysBetweenOrders = count($daysBetweenOrders) > 0 ? round(array_sum($daysBetweenOrders) / count($daysBetweenOrders), 1) : 0;

        return [
            'retention_rate' => $retentionRate,
            'repeat_customers' => $repeatCustomers,
            'total_active_users' => $totalActiveUsers,
            'avg_days_between_orders' => $avgDaysBetweenOrders,
        ];
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
     * Helper: Parse date range.
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
     * Helper: Get city name.
     */
    private function getCityName(?string $cityId): string
    {
        if (!$cityId) return '';
        $city = City::find($cityId);
        return $city ? $city->name : '';
    }

    /**
     * Export as Excel.
     */
    public function exportExcel(Request $request)
    {
        [$filter, $start, $end] = $this->parseDateRange($request);
        $section = $request->get('section', 'all');
        $cityId = $request->get('city_id');
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

        // Summary Sheet
        if (in_array($section, ['all', 'summary'])) {
            $summary = $this->getUserSummary($start, $end, $cityId);
            $retentionMetrics = $this->getRetentionMetrics($start, $end, $cityId);

            $sheet = $spreadsheet->createSheet();
            $sheet->setTitle('Summary');

            $sheet->setCellValue('A1', 'User Analytics Summary' . $zoneLabel);
            $sheet->setCellValue('A2', 'Period: ' . $dateLabel);
            $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);

            $row = 4;
            $sheet->setCellValue('A' . $row, 'Metric');
            $sheet->setCellValue('B' . $row, 'Value');
            $sheet->getStyle("A{$row}:B{$row}")->applyFromArray($headerStyle);

            $summaryRows = [
                ['Total Users', $summary['total_users']],
                ['New Registrations', $summary['new_registrations']],
                ['Active Users', $summary['active_users']],
                ['Avg Orders/User', $summary['avg_orders_per_user']],
                ['Avg Revenue/User', '₹' . number_format($summary['avg_revenue_per_user'], 2)],
                ['Retention Rate', $retentionMetrics['retention_rate'] . '%'],
            ];

            foreach ($summaryRows as $sRow) {
                $row++;
                $sheet->setCellValue('A' . $row, $sRow[0]);
                $sheet->setCellValue('B' . $row, $sRow[1]);
                $sheet->getStyle("A{$row}:B{$row}")->applyFromArray($cellBorder);
            }

            $sheet->getColumnDimension('A')->setAutoSize(true);
            $sheet->getColumnDimension('B')->setAutoSize(true);
        }

        // Top Customers Sheet
        if (in_array($section, ['all', 'top-customers'])) {
            $topCustomers = $this->getTopCustomers($start, $end, $cityId, 50);

            $sheet = $spreadsheet->createSheet();
            $sheet->setTitle('Top Customers');

            $sheet->setCellValue('A1', 'Top Customers' . $zoneLabel);
            $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);

            $headers = ['#', 'Name', 'Mobile', 'Orders', 'Total Spent', 'Avg Order Value'];
            $col = 'A';
            foreach ($headers as $header) {
                $sheet->setCellValue($col . '3', $header);
                $col++;
            }
            $sheet->getStyle('A3:F3')->applyFromArray($headerStyle);

            $row = 4;
            $index = 1;
            foreach ($topCustomers['by_revenue'] as $customer) {
                $sheet->setCellValue('A' . $row, $index);
                $sheet->setCellValue('B' . $row, $customer['name']);
                $sheet->setCellValue('C' . $row, $customer['mobile']);
                $sheet->setCellValue('D' . $row, $customer['order_count']);
                $sheet->setCellValue('E' . $row, $customer['total_spent']);
                $sheet->setCellValue('F' . $row, $customer['avg_order_value']);
                $sheet->getStyle("A{$row}:F{$row}")->applyFromArray($cellBorder);
                $row++;
                $index++;
            }

            foreach (range('A', 'F') as $c) {
                $sheet->getColumnDimension($c)->setAutoSize(true);
            }
        }

        $spreadsheet->setActiveSheetIndex(0);

        $filename = 'user_analytics_' . $start->format('Ymd') . '.xlsx';

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
     * Export as PDF.
     */
    public function exportPdf(Request $request)
    {
        [$filter, $start, $end] = $this->parseDateRange($request);
        $cityId = $request->get('city_id');
        $cityName = $this->getCityName($cityId);
        $zoneLabel = $cityName ? ' | Zone: ' . $cityName : '';

        $dateLabel = $start->format('d M Y') . ' - ' . $end->format('d M Y');
        $summary = $this->getUserSummary($start, $end, $cityId);
        $retentionMetrics = $this->getRetentionMetrics($start, $end, $cityId);
        $topCustomers = $this->getTopCustomers($start, $end, $cityId, 20);

        $html = '<style>
            body { font-family: sans-serif; font-size: 12px; color: #333; }
            h1 { color: #4CAF50; font-size: 20px; }
            table { width: 100%; border-collapse: collapse; margin-bottom: 15px; }
            th { background-color: #4CAF50; color: white; padding: 8px; }
            td { padding: 6px; border-bottom: 1px solid #ddd; }
            .bold { font-weight: bold; }
        </style>';

        $html .= '<h1>User Analytics Report' . $zoneLabel . '</h1>';
        $html .= '<p>Period: ' . $dateLabel . '</p>';

        $html .= '<h2>Summary</h2>';
        $html .= '<table><tr><th>Metric</th><th>Value</th></tr>';
        $html .= '<tr><td>Total Users</td><td class="bold">' . $summary['total_users'] . '</td></tr>';
        $html .= '<tr><td>New Registrations</td><td class="bold">' . $summary['new_registrations'] . '</td></tr>';
        $html .= '<tr><td>Active Users</td><td class="bold">' . $summary['active_users'] . '</td></tr>';
        $html .= '<tr><td>Retention Rate</td><td class="bold">' . $retentionMetrics['retention_rate'] . '%</td></tr>';
        $html .= '</table>';

        $html .= '<h2>Top Customers</h2>';
        $html .= '<table><tr><th>#</th><th>Name</th><th>Orders</th><th>Total Spent</th></tr>';
        $ci = 1;
        foreach ($topCustomers['by_revenue'] as $customer) {
            $html .= '<tr>';
            $html .= '<td>' . $ci . '</td>';
            $html .= '<td class="bold">' . $customer['name'] . '</td>';
            $html .= '<td>' . $customer['order_count'] . '</td>';
            $html .= '<td>₹' . number_format($customer['total_spent'], 2) . '</td>';
            $html .= '</tr>';
            $ci++;
        }
        $html .= '</table>';

        $mpdf = new Mpdf();
        $mpdf->WriteHTML($html);

        $filename = 'user_analytics_' . $start->format('Ymd') . '.pdf';

        return response($mpdf->Output($filename, Destination::STRING_RETURN), 200, [
            'Content-Type' => 'application/pdf',
            'Content-Disposition' => 'attachment; filename="' . $filename . '"',
        ]);
    }
}
