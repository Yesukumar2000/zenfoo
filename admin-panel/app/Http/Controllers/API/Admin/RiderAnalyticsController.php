<?php

namespace App\Http\Controllers\API\Admin;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Rider Analytics overview dashboard.
 *
 * Separate from DeliveryBoyAnalyticsController (left untouched). All metrics
 * are computed from real tables:
 *   - riders            : delivery_boys (status 1 = Active)
 *   - online state      : delivery_boy_sessions (logout_at IS NULL) + delivery_boy_daily_tracking.online_status
 *   - deliveries        : orders.delivery_boy_id + orders.active_status (6=Delivered, 7=Cancelled, 8=Returned)
 *   - earnings          : delivery_boy_transactions.driver_earnings (= delivery_charge + delivery_tip + bonus_amount)
 *   - delivery duration : orders.delivered_at_time - orders.driver_accepted_at_time
 *   - on-time           : delivered_at_time <= driver_accepted_at_time + estimated_time_of_delivery (minutes)
 *   - acceptance        : order_delivery_boy_notifications.status = 'accepted'
 *   - ratings           : order_driver_ratings.rating
 *   - order type        : order_combo_items (combo) / order_items -> sellers.store_id -> stores.is_food|is_meat|is_vegetable
 */
class RiderAnalyticsController extends Controller
{
    const STATUS_DELIVERED = 6;
    const STATUS_CANCELLED = 7;
    const STATUS_RETURNED  = 8;
    const STATUS_PAYMENT_PENDING = 1;

    /** Resolve [from, to] and the equally-sized previous period. */
    private function ranges(Request $request)
    {
        $to   = $request->filled('to_date') ? Carbon::parse($request->to_date)->endOfDay() : Carbon::now()->endOfDay();
        $from = $request->filled('from_date') ? Carbon::parse($request->from_date)->startOfDay() : Carbon::now()->subDays(29)->startOfDay();

        $days     = max(1, $from->diffInDays($to) + 1);
        $prevTo   = $from->copy()->subSecond();
        $prevFrom = $prevTo->copy()->subDays($days - 1)->startOfDay();

        return [$from, $to, $prevFrom, $prevTo, $days];
    }

    private function delta($current, $previous)
    {
        $current  = (float) $current;
        $previous = (float) $previous;
        if ($previous > 0) {
            $pct = round((($current - $previous) / $previous) * 100, 1);
        } else {
            $pct = $current > 0 ? 100 : 0;
        }
        return ['change_percent' => $pct, 'is_positive' => $current >= $previous];
    }

    /** Base orders query for rider deliveries within a range. */
    private function ordersQuery($from, $to, $cityId = null)
    {
        $q = DB::table('orders')
            ->whereNotNull('orders.delivery_boy_id')
            ->where('orders.active_status', '!=', self::STATUS_PAYMENT_PENDING)
            ->whereBetween('orders.created_at', [$from, $to]);

        if ($cityId) {
            $q->join('delivery_boys as db_c', 'db_c.id', '=', 'orders.delivery_boy_id')
                ->where('db_c.city_id', $cityId);
        }
        return $q;
    }

    // =====================================================================
    //  OVERVIEW
    // =====================================================================
    public function overview(Request $request)
    {
        [$from, $to, $prevFrom, $prevTo, $days] = $this->ranges($request);
        $cityId = $request->input('city_id');

        $data = [
            'range' => [
                'from' => $from->toDateString(),
                'to'   => $to->toDateString(),
                'compare_from' => $prevFrom->toDateString(),
                'compare_to'   => $prevTo->toDateString(),
                'days' => $days,
            ],
            'stats'                => $this->stats($from, $to, $prevFrom, $prevTo, $cityId),
            'deliveries_trend'     => $this->deliveriesTrend($from, $to, $cityId),
            'deliveries_by_type'   => $this->deliveriesByType($from, $to, $cityId),
            'rider_status'         => $this->riderStatus($cityId),
            'earnings_overview'    => $this->earningsOverview($from, $to, $cityId),
            'performance_summary'  => $this->performanceSummary($from, $to, $prevFrom, $prevTo, $cityId),
            'top_by_deliveries'    => $this->topRiders($from, $to, 'deliveries', $cityId),
            'top_by_earnings'      => $this->topRiders($from, $to, 'earnings', $cityId),
            'earnings_breakdown'   => $this->earningsBreakdown($from, $to, $cityId),
            'availability_heatmap' => $this->availabilityHeatmap($from, $to, $cityId),
            'payout_summary'       => $this->payoutSummary($cityId),
        ];
        $data['insights'] = $this->insights($data);

        return CommonHelper::responseWithData($data);
    }

    // ---------------- Stat cards ----------------
    private function stats($from, $to, $prevFrom, $prevTo, $cityId)
    {
        $totalRiders = DB::table('delivery_boys')->where('status', 1)
            ->when($cityId, function ($q) use ($cityId) { $q->where('city_id', $cityId); })
            ->count();

        $metrics = function ($start, $end) use ($cityId) {
            $activeRiders = (clone $this->ordersQuery($start, $end, $cityId))
                ->distinct()->count('orders.delivery_boy_id');

            $deliveries = (clone $this->ordersQuery($start, $end, $cityId))
                ->where('orders.active_status', self::STATUS_DELIVERED)
                ->count('orders.id');

            $earnings = (float) DB::table('delivery_boy_transactions')
                ->whereBetween('created_at', [$start, $end])
                ->when($cityId, function ($q) use ($cityId) {
                    $q->join('delivery_boys as db_e', 'db_e.id', '=', 'delivery_boy_transactions.delivery_boy_id')
                      ->where('db_e.city_id', $cityId);
                })
                ->sum('delivery_boy_transactions.driver_earnings');

            // Avg delivery time (minutes): accepted -> delivered
            $avgTime = (float) (clone $this->ordersQuery($start, $end, $cityId))
                ->where('orders.active_status', self::STATUS_DELIVERED)
                ->whereNotNull('orders.driver_accepted_at_time')
                ->whereNotNull('orders.delivered_at_time')
                ->avg(DB::raw('TIMESTAMPDIFF(MINUTE, orders.driver_accepted_at_time, orders.delivered_at_time)'));

            return [
                'active_riders'   => $activeRiders,
                'deliveries'      => $deliveries,
                'earnings'        => round($earnings, 2),
                'avg_per_rider'   => $activeRiders > 0 ? round($earnings / $activeRiders, 2) : 0,
                'avg_delivery_time' => round($avgTime, 1),
            ];
        };

        $cur  = $metrics($from, $to);
        $prev = $metrics($prevFrom, $prevTo);

        $prevTotalRiders = DB::table('delivery_boys')->where('status', 1)
            ->when($cityId, function ($q) use ($cityId) { $q->where('city_id', $cityId); })
            ->where('created_at', '<=', $prevTo)->count();

        return [
            'total_riders' => [
                'value' => $totalRiders,
                'delta' => $this->delta($totalRiders, $prevTotalRiders),
            ],
            'active_riders' => [
                'value' => $cur['active_riders'],
                'delta' => $this->delta($cur['active_riders'], $prev['active_riders']),
            ],
            'total_deliveries' => [
                'value' => $cur['deliveries'],
                'delta' => $this->delta($cur['deliveries'], $prev['deliveries']),
            ],
            'total_earnings' => [
                'value' => $cur['earnings'],
                'delta' => $this->delta($cur['earnings'], $prev['earnings']),
            ],
            'avg_earnings_per_rider' => [
                'value' => $cur['avg_per_rider'],
                'delta' => $this->delta($cur['avg_per_rider'], $prev['avg_per_rider']),
            ],
            'avg_delivery_time' => [
                'value' => $cur['avg_delivery_time'],
                // lower is better -> invert positivity
                'delta' => array_merge(
                    $this->delta($cur['avg_delivery_time'], $prev['avg_delivery_time']),
                    ['is_positive' => $cur['avg_delivery_time'] <= $prev['avg_delivery_time']]
                ),
            ],
        ];
    }

    // ---------------- Deliveries trend ----------------
    private function deliveriesTrend($from, $to, $cityId)
    {
        $rows = (clone $this->ordersQuery($from, $to, $cityId))
            ->select(
                DB::raw('DATE(orders.created_at) as d'),
                DB::raw('COUNT(orders.id) as deliveries'),
                DB::raw('COUNT(DISTINCT orders.delivery_boy_id) as riders')
            )
            ->groupBy(DB::raw('DATE(orders.created_at)'))
            ->orderBy('d')
            ->get()->keyBy('d');

        $series = [];
        $cursor = $from->copy();
        while ($cursor->lte($to)) {
            $key = $cursor->toDateString();
            $row = $rows->get($key);
            $series[] = [
                'date'       => $cursor->format('M d'),
                'deliveries' => $row ? (int) $row->deliveries : 0,
                'riders'     => $row ? (int) $row->riders : 0,
            ];
            $cursor->addDay();
        }
        return $series;
    }

    // ---------------- Deliveries by type ----------------
    private function deliveriesByType($from, $to, $cityId)
    {
        $orderIds = (clone $this->ordersQuery($from, $to, $cityId))
            ->where('orders.active_status', self::STATUS_DELIVERED)
            ->pluck('orders.id');

        $total = $orderIds->count();
        if ($total === 0) {
            return [];
        }

        // Combo orders
        $comboIds = DB::table('order_combo_items')
            ->whereIn('order_id', $orderIds)
            ->distinct()->pluck('order_id')->all();
        $comboSet = array_flip($comboIds);

        // Classify the rest via store flags on the order's sellers
        $rows = DB::table('order_items')
            ->join('sellers', 'sellers.id', '=', 'order_items.seller_id')
            ->join('stores', 'stores.id', '=', 'sellers.store_id')
            ->whereIn('order_items.order_id', $orderIds)
            ->select(
                'order_items.order_id',
                DB::raw('MAX(stores.is_food) as is_food'),
                DB::raw('MAX(stores.is_meat) as is_meat'),
                DB::raw('MAX(stores.is_vegetable) as is_veg'),
                DB::raw('MAX(stores.is_super_mart) as is_mart')
            )
            ->groupBy('order_items.order_id')
            ->get();

        $counts = ['Restaurant Orders' => 0, 'Grocery Orders' => 0, 'Combo Orders' => 0, 'Others' => 0];
        $seen = [];
        foreach ($rows as $r) {
            $seen[$r->order_id] = true;
            if (isset($comboSet[$r->order_id])) {
                $counts['Combo Orders']++;
            } elseif ((int) $r->is_food === 1) {
                $counts['Restaurant Orders']++;
            } elseif ((int) $r->is_veg === 1 || (int) $r->is_mart === 1 || (int) $r->is_meat === 1) {
                $counts['Grocery Orders']++;
            } else {
                $counts['Others']++;
            }
        }
        // Orders with no matching items/stores
        foreach ($orderIds as $id) {
            if (!isset($seen[$id])) {
                if (isset($comboSet[$id])) $counts['Combo Orders']++;
                else $counts['Others']++;
            }
        }

        $out = [];
        foreach ($counts as $label => $count) {
            $out[] = [
                'name'       => $label,
                'count'      => $count,
                'percentage' => $total > 0 ? round($count * 100 / $total, 1) : 0,
            ];
        }
        return $out;
    }

    // ---------------- Rider status ----------------
    private function riderStatus($cityId)
    {
        $activeAccounts = DB::table('delivery_boys')->where('status', 1)
            ->when($cityId, function ($q) use ($cityId) { $q->where('city_id', $cityId); });

        $totalActive = (clone $activeAccounts)->count();

        // Online = has an open session
        $onlineIds = DB::table('delivery_boy_sessions')
            ->whereNull('logout_at')
            ->distinct()->pluck('delivery_boy_id')->all();

        $online = (clone $activeAccounts)->whereIn('id', $onlineIds ?: [0])->count();

        // Busy (on a ride) from today's rollup — the only third state that exists
        $busyIds = DB::table('delivery_boy_daily_tracking')
            ->whereDate('tracking_date', Carbon::now()->toDateString())
            ->where('online_status', 'busy')
            ->distinct()->pluck('delivery_boy_id')->all();
        $busy = (clone $activeAccounts)->whereIn('id', $busyIds ?: [0])->count();
        $online = max(0, $online - $busy);

        $offline = max(0, $totalActive - $online - $busy);

        // Inactive = accounts that are not Active status
        $inactive = DB::table('delivery_boys')->where('status', '!=', 1)
            ->when($cityId, function ($q) use ($cityId) { $q->where('city_id', $cityId); })
            ->count();

        $total = $totalActive + $inactive;
        $mk = function ($name, $count) use ($total) {
            return [
                'name' => $name,
                'count' => $count,
                'percentage' => $total > 0 ? round($count * 100 / $total, 1) : 0,
            ];
        };
        return [
            'total' => $total,
            'items' => [
                $mk('Online', $online),
                $mk('Busy', $busy),
                $mk('Offline', $offline),
                $mk('Inactive', $inactive),
            ],
        ];
    }

    // ---------------- Earnings overview ----------------
    private function earningsOverview($from, $to, $cityId)
    {
        $rows = DB::table('delivery_boy_transactions')
            ->whereBetween('delivery_boy_transactions.created_at', [$from, $to])
            ->when($cityId, function ($q) use ($cityId) {
                $q->join('delivery_boys as db_o', 'db_o.id', '=', 'delivery_boy_transactions.delivery_boy_id')
                  ->where('db_o.city_id', $cityId);
            })
            ->select(
                DB::raw('DATE(delivery_boy_transactions.created_at) as d'),
                DB::raw('SUM(delivery_boy_transactions.driver_earnings) as earnings'),
                DB::raw('COUNT(DISTINCT delivery_boy_transactions.delivery_boy_id) as riders')
            )
            ->groupBy(DB::raw('DATE(delivery_boy_transactions.created_at)'))
            ->orderBy('d')->get()->keyBy('d');

        $series = [];
        $cursor = $from->copy();
        while ($cursor->lte($to)) {
            $key = $cursor->toDateString();
            $row = $rows->get($key);
            $earn = $row ? (float) $row->earnings : 0;
            $riders = $row ? (int) $row->riders : 0;
            $series[] = [
                'date'     => $cursor->format('M d'),
                'earnings' => round($earn, 2),
                'avg_per_rider' => $riders > 0 ? round($earn / $riders, 2) : 0,
            ];
            $cursor->addDay();
        }
        return $series;
    }

    // ---------------- Performance summary ----------------
    private function performanceSummary($from, $to, $prevFrom, $prevTo, $cityId)
    {
        $calc = function ($start, $end) use ($cityId) {
            $assigned = (clone $this->ordersQuery($start, $end, $cityId))->count('orders.id');
            $delivered = (clone $this->ordersQuery($start, $end, $cityId))
                ->where('orders.active_status', self::STATUS_DELIVERED)->count('orders.id');
            $cancelled = (clone $this->ordersQuery($start, $end, $cityId))
                ->whereIn('orders.active_status', [self::STATUS_CANCELLED, self::STATUS_RETURNED])->count('orders.id');

            // Real on-time rate: delivered within accepted + ETA
            $eta = (clone $this->ordersQuery($start, $end, $cityId))
                ->where('orders.active_status', self::STATUS_DELIVERED)
                ->whereNotNull('orders.driver_accepted_at_time')
                ->whereNotNull('orders.delivered_at_time')
                ->whereNotNull('orders.estimated_time_of_delivery')
                ->where('orders.estimated_time_of_delivery', '>', 0);
            $etaTotal = (clone $eta)->count('orders.id');
            $onTime = (clone $eta)->whereRaw(
                'orders.delivered_at_time <= DATE_ADD(orders.driver_accepted_at_time, INTERVAL orders.estimated_time_of_delivery MINUTE)'
            )->count('orders.id');

            // Dispatch acceptance rate
            $notifTotal = DB::table('order_delivery_boy_notifications')
                ->whereBetween('created_at', [$start, $end])->count();
            $notifAccepted = DB::table('order_delivery_boy_notifications')
                ->whereBetween('created_at', [$start, $end])->where('status', 'accepted')->count();

            return [
                'on_time_rate'      => $etaTotal > 0 ? round($onTime * 100 / $etaTotal, 1) : 0,
                'acceptance_rate'   => $notifTotal > 0 ? round($notifAccepted * 100 / $notifTotal, 1) : 0,
                'cancellation_rate' => $assigned > 0 ? round($cancelled * 100 / $assigned, 1) : 0,
                'completion_rate'   => $assigned > 0 ? round($delivered * 100 / $assigned, 1) : 0,
            ];
        };

        $cur  = $calc($from, $to);
        $prev = $calc($prevFrom, $prevTo);

        $out = [];
        foreach ($cur as $key => $val) {
            $d = $this->delta($val, $prev[$key]);
            if ($key === 'cancellation_rate') {
                $d['is_positive'] = $val <= $prev[$key]; // lower is better
            }
            $out[$key] = ['value' => $val, 'delta' => $d];
        }
        return $out;
    }

    // ---------------- Top riders ----------------
    private function topRiders($from, $to, $sortBy, $cityId)
    {
        $deliveries = (clone $this->ordersQuery($from, $to, $cityId))
            ->where('orders.active_status', self::STATUS_DELIVERED)
            ->select('orders.delivery_boy_id', DB::raw('COUNT(orders.id) as deliveries'))
            ->groupBy('orders.delivery_boy_id')
            ->pluck('deliveries', 'orders.delivery_boy_id');

        $earnings = DB::table('delivery_boy_transactions')
            ->whereBetween('created_at', [$from, $to])
            ->select('delivery_boy_id', DB::raw('SUM(driver_earnings) as earnings'))
            ->groupBy('delivery_boy_id')
            ->pluck('earnings', 'delivery_boy_id');

        $ratings = DB::table('order_driver_ratings')
            ->select('delivery_boy_id', DB::raw('AVG(rating) as avg_rating'))
            ->groupBy('delivery_boy_id')
            ->pluck('avg_rating', 'delivery_boy_id');

        $ids = collect($deliveries->keys())->merge($earnings->keys())->unique()->filter()->values();
        if ($ids->isEmpty()) return [];

        $names = DB::table('delivery_boys')->whereIn('id', $ids)
            ->when($cityId, function ($q) use ($cityId) { $q->where('city_id', $cityId); })
            ->pluck('name', 'id');

        $rows = [];
        foreach ($names as $id => $name) {
            $rows[] = [
                'id'         => $id,
                'name'       => $name ?: 'Rider #' . $id,
                'deliveries' => (int) ($deliveries[$id] ?? 0),
                'earnings'   => round((float) ($earnings[$id] ?? 0), 2),
                'rating'     => isset($ratings[$id]) ? round((float) $ratings[$id], 1) : null,
            ];
        }
        usort($rows, function ($a, $b) use ($sortBy) {
            return $sortBy === 'earnings'
                ? $b['earnings'] <=> $a['earnings']
                : $b['deliveries'] <=> $a['deliveries'];
        });
        return array_slice($rows, 0, 5);
    }

    // ---------------- Earnings breakdown ----------------
    private function earningsBreakdown($from, $to, $cityId)
    {
        $q = DB::table('delivery_boy_transactions')
            ->whereBetween('delivery_boy_transactions.created_at', [$from, $to])
            ->when($cityId, function ($qq) use ($cityId) {
                $qq->join('delivery_boys as db_b', 'db_b.id', '=', 'delivery_boy_transactions.delivery_boy_id')
                   ->where('db_b.city_id', $cityId);
            });

        $row = (clone $q)->select(
            DB::raw('COALESCE(SUM(delivery_boy_transactions.delivery_charge),0) as base_fare'),
            DB::raw('COALESCE(SUM(delivery_boy_transactions.delivery_tip),0) as tips'),
            DB::raw('COALESCE(SUM(delivery_boy_transactions.bonus_amount),0) as bonus'),
            DB::raw('COALESCE(SUM(delivery_boy_transactions.rain_surcharge),0) as surge'),
            DB::raw('COALESCE(SUM(delivery_boy_transactions.vendor_wait_charge),0) as wait_charge')
        )->first();

        $incentives = (float) (clone $q)->where('delivery_boy_transactions.type', 'incentive')
            ->sum('delivery_boy_transactions.amount');

        $base   = (float) ($row->base_fare ?? 0);
        $tips   = (float) ($row->tips ?? 0);
        $others = (float) ($row->bonus ?? 0) + (float) ($row->surge ?? 0) + (float) ($row->wait_charge ?? 0);
        $total  = $base + $tips + $incentives + $others;

        $mk = function ($name, $val) use ($total) {
            return [
                'name'       => $name,
                'value'      => round($val, 2),
                'percentage' => $total > 0 ? round($val * 100 / $total, 1) : 0,
            ];
        };
        return [
            'total' => round($total, 2),
            'items' => [
                $mk('Base Fare', $base),
                $mk('Incentives', $incentives),
                $mk('Tips', $tips),
                $mk('Others', $others),
            ],
        ];
    }

    // ---------------- Availability heatmap (day x hour) ----------------
    private function availabilityHeatmap($from, $to, $cityId)
    {
        // Count sessions active per weekday/hour using login_at as the anchor.
        $rows = DB::table('delivery_boy_sessions')
            ->whereBetween('delivery_boy_sessions.login_at', [$from, $to])
            ->when($cityId, function ($q) use ($cityId) {
                $q->join('delivery_boys as db_h', 'db_h.id', '=', 'delivery_boy_sessions.delivery_boy_id')
                  ->where('db_h.city_id', $cityId);
            })
            ->select(
                DB::raw('DAYOFWEEK(delivery_boy_sessions.login_at) as dow'), // 1=Sun..7=Sat
                DB::raw('HOUR(delivery_boy_sessions.login_at) as hr'),
                DB::raw('COUNT(DISTINCT delivery_boy_sessions.delivery_boy_id) as riders')
            )
            ->groupBy(DB::raw('DAYOFWEEK(delivery_boy_sessions.login_at)'), DB::raw('HOUR(delivery_boy_sessions.login_at)'))
            ->get();

        $matrix = [];
        foreach ($rows as $r) {
            $matrix[(int) $r->dow][(int) $r->hr] = (int) $r->riders;
        }

        $days = [2 => 'Mon', 3 => 'Tue', 4 => 'Wed', 5 => 'Thu', 6 => 'Fri', 7 => 'Sat', 1 => 'Sun'];
        $out = [];
        $max = 0;
        foreach ($days as $dow => $label) {
            $cells = [];
            for ($h = 0; $h < 24; $h++) {
                $v = $matrix[$dow][$h] ?? 0;
                $max = max($max, $v);
                $cells[] = ['hour' => $h, 'value' => $v];
            }
            $out[] = ['day' => $label, 'cells' => $cells];
        }
        return ['max' => $max, 'rows' => $out];
    }

    // ---------------- Payout summary ----------------
    private function payoutSummary($cityId)
    {
        $thisMonthStart = Carbon::now()->startOfMonth();
        $lastMonthStart = Carbon::now()->subMonth()->startOfMonth();
        $lastMonthEnd   = Carbon::now()->subMonth()->endOfMonth();

        $base = function () use ($cityId) {
            return DB::table('delivery_boy_transactions')
                ->where('delivery_boy_transactions.is_hand_cash', 0)
                ->where('delivery_boy_transactions.type', '!=', 'incentive')
                ->when($cityId, function ($q) use ($cityId) {
                    $q->join('delivery_boys as db_p', 'db_p.id', '=', 'delivery_boy_transactions.delivery_boy_id')
                      ->where('db_p.city_id', $cityId);
                });
        };

        $bucket = function ($q) use ($thisMonthStart, $lastMonthStart, $lastMonthEnd) {
            return [
                'riders'     => (clone $q)->distinct()->count('delivery_boy_transactions.delivery_boy_id'),
                'total'      => round((float) (clone $q)->sum('delivery_boy_transactions.driver_earnings'), 2),
                'this_month' => round((float) (clone $q)->where('delivery_boy_transactions.created_at', '>=', $thisMonthStart)->sum('delivery_boy_transactions.driver_earnings'), 2),
                'last_month' => round((float) (clone $q)->whereBetween('delivery_boy_transactions.created_at', [$lastMonthStart, $lastMonthEnd])->sum('delivery_boy_transactions.driver_earnings'), 2),
            ];
        };

        // Paid   = settled with admin
        $paid = $bucket((clone $base())->where('delivery_boy_transactions.settled_with_admin', 1));
        $paid['status'] = 'Paid';
        $paid['pending'] = 0;

        // Pending = not settled yet
        $pendingQ = (clone $base())->where('delivery_boy_transactions.settled_with_admin', 0)
            ->where(function ($q) { $q->where('delivery_boy_transactions.status', '!=', 'failed')->orWhereNull('delivery_boy_transactions.status'); });
        $pending = $bucket($pendingQ);
        $pending['status'] = 'Pending';
        $pending['pending'] = $pending['total'];

        // Failed = transaction failed
        $failedQ = (clone $base())->where('delivery_boy_transactions.status', 'failed');
        $failed = $bucket($failedQ);
        $failed['status'] = 'Failed';
        $failed['pending'] = $failed['total'];

        $total = [
            'status'     => 'Total',
            'riders'     => (clone $base())->distinct()->count('delivery_boy_transactions.delivery_boy_id'),
            'total'      => round($paid['total'] + $pending['total'] + $failed['total'], 2),
            'this_month' => round($paid['this_month'] + $pending['this_month'] + $failed['this_month'], 2),
            'last_month' => round($paid['last_month'] + $pending['last_month'] + $failed['last_month'], 2),
            'pending'    => round($pending['total'] + $failed['total'], 2),
        ];

        return ['rows' => [$paid, $pending, $failed], 'total' => $total];
    }

    // ---------------- Insights ----------------
    private function insights($data)
    {
        $out = [];
        $s = $data['stats'];

        $e = $s['total_earnings'];
        $out[] = [
            'icon' => 'chart',
            'type' => $e['delta']['is_positive'] ? 'success' : 'warning',
            'text' => 'Total earnings ' . ($e['delta']['is_positive'] ? 'increased' : 'decreased') . ' by '
                . abs($e['delta']['change_percent']) . '% compared to the previous period.',
        ];

        $t = $s['avg_delivery_time'];
        if ($t['value'] > 0) {
            $out[] = [
                'icon' => 'clock',
                'type' => $t['delta']['is_positive'] ? 'success' : 'warning',
                'text' => 'Average delivery time is ' . $t['value'] . ' mins ('
                    . ($t['delta']['is_positive'] ? 'improved' : 'up') . ' '
                    . abs($t['delta']['change_percent']) . '%).',
            ];
        }

        $p = $data['performance_summary']['on_time_rate'];
        $out[] = [
            'icon' => 'check',
            'type' => $p['delta']['is_positive'] ? 'success' : 'warning',
            'text' => 'On-time delivery rate is ' . $p['value'] . '% ('
                . ($p['delta']['is_positive'] ? 'up' : 'down') . ' '
                . abs($p['delta']['change_percent']) . '%).',
        ];

        $pend = $data['payout_summary']['rows'][1] ?? null;
        if ($pend && $pend['riders'] > 0) {
            $out[] = [
                'icon' => 'alert',
                'type' => 'warning',
                'text' => 'You have ' . $pend['riders'] . ' riders with pending payouts.',
            ];
        }
        return $out;
    }
}
