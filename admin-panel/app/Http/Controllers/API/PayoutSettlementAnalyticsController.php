<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\SellerWalletTransaction;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

/**
 * Payouts & Settlement analytics — existing data only.
 *
 * Canonical sources (no single unified disbursements table exists):
 *  - Rider payouts   -> delivery_boy_payout_history (amount, status enum, completed_at)
 *  - Merchant settle -> seller_wallet_transactions where is_paid_to_seller = 1 (amount, paid_at, admin_commission)
 *  - Payout requests -> withdrawal_requests (type, type_id, amount, status 0/1/2)
 *  - Payment method  -> derived (delivery_boys.payment_mode for riders; bank for merchants) — no per-payout method column
 *
 * Every section is computed defensively: if the live DB is missing a table or
 * column (e.g. a migration not yet run in production), that section degrades to
 * zero/empty and the real error is logged, rather than 500-ing the whole page.
 */
class PayoutSettlementAnalyticsController extends Controller
{
    /**
     * Seller wallet "money in" types — mirrors SellerTransactionsController so
     * our settlement/pending figures match the rest of the admin panel.
     */
    private $creditTypes = ['order_commission', 'credit', 'refund'];

    private $colCache = [];

    private function range(Request $request)
    {
        $to   = $request->filled('to_date')   ? Carbon::parse($request->to_date)->endOfDay()     : Carbon::now()->endOfDay();
        $from = $request->filled('from_date') ? Carbon::parse($request->from_date)->startOfDay() : Carbon::now()->subDays(30)->startOfDay();
        return [$from, $to];
    }

    /** Cached, exception-safe column check (production DB may lag on migrations). */
    private function hasCol($table, $col)
    {
        $k = "$table.$col";
        if (!array_key_exists($k, $this->colCache)) {
            try { $this->colCache[$k] = Schema::hasColumn($table, $col); }
            catch (\Throwable $e) { $this->colCache[$k] = false; }
        }
        return $this->colCache[$k];
    }

    /** Run a query closure, returning $default (and logging) if it throws. */
    private function safe(callable $fn, $default = null)
    {
        try { return $fn(); }
        catch (\Throwable $e) {
            Log::warning('[PayoutAnalytics] ' . $e->getMessage());
            return $default;
        }
    }

    private function hasPayoutHistory() { return Schema::hasTable('delivery_boy_payout_history'); }

    /** Does the merchant-settlement schema exist on this DB? */
    private function merchantReady()
    {
        return Schema::hasTable('seller_wallet_transactions')
            && $this->hasCol('seller_wallet_transactions', 'is_paid_to_seller')
            && $this->hasCol('seller_wallet_transactions', 'paid_at')
            && $this->hasCol('seller_wallet_transactions', 'type');
    }

    /** Rider payouts marked disbursed, within range (by completed_at, falling back to created_at). */
    private function riderPaidQuery($from, $to)
    {
        return DB::table('delivery_boy_payout_history')
            ->where('status', 'success')
            ->whereBetween(DB::raw('COALESCE(completed_at, created_at)'), [$from, $to]);
    }

    /** Merchant amounts settled to sellers, within range (by paid_at). */
    private function merchantPaidQuery($from, $to)
    {
        return SellerWalletTransaction::where('is_paid_to_seller', 1)
            ->whereIn('type', $this->creditTypes)
            ->whereBetween('paid_at', [$from, $to]);
    }

    /** SELECT expression for a rider's payment method (falls back if column absent). */
    private function payModeSelect()
    {
        return $this->hasCol('delivery_boys', 'payment_mode') ? 'd.payment_mode' : DB::raw("'UPI' as payment_mode");
    }

    /** SELECT expression for merchant commission sum (falls back to 0 if column absent). */
    private function commissionSelect()
    {
        return $this->hasCol('seller_wallet_transactions', 'admin_commission')
            ? DB::raw('SUM(admin_commission) as commission') : DB::raw('0 as commission');
    }

    // =====================================================================
    //  OVERVIEW
    // =====================================================================
    public function overview(Request $request)
    {
        try {
        [$from, $to] = $this->range($request);
        $group = $request->get('group', 'daily');

        // --- Rider payouts (guarded) ------------------------------------
        $riderTotal = 0; $riderSuccess = 0; $riderFailed = 0; $riderPending = 0;
        if ($this->hasPayoutHistory()) {
            $riderTotal   = (float) $this->safe(function () use ($from, $to) { return $this->riderPaidQuery($from, $to)->sum('amount'); }, 0);
            $riderSuccess = (int)   $this->safe(function () use ($from, $to) { return $this->riderPaidQuery($from, $to)->count(); }, 0);
            $riderFailed  = (int)   $this->safe(function () use ($from, $to) {
                return DB::table('delivery_boy_payout_history')->where('status', 'failed')->whereBetween('created_at', [$from, $to])->count();
            }, 0);
            $riderPending = (float) $this->safe(function () use ($from, $to) {
                return DB::table('delivery_boy_payout_history')->whereIn('status', ['pending', 'processing'])->whereBetween('created_at', [$from, $to])->sum('amount');
            }, 0);
        }

        // --- Merchant settlements (guarded) -----------------------------
        $merchantTotal = 0; $merchantPaidCnt = 0; $merchantPending = 0;
        if ($this->merchantReady()) {
            $merchantTotal   = (float) $this->safe(function () use ($from, $to) { return $this->merchantPaidQuery($from, $to)->sum('amount'); }, 0);
            $merchantPaidCnt = (int)   $this->safe(function () use ($from, $to) { return $this->merchantPaidQuery($from, $to)->count(); }, 0);
            $merchantPending = (float) $this->safe(function () use ($from, $to) {
                return SellerWalletTransaction::where('is_paid_to_seller', 0)->whereIn('type', $this->creditTypes)->whereBetween('created_at', [$from, $to])->sum('amount');
            }, 0);
        }

        $stats = [
            'total_disbursed'      => round($riderTotal + $merchantTotal, 2),
            'rider_payouts'        => round($riderTotal, 2),
            'merchant_settlements' => round($merchantTotal, 2),
            'pending_amount'       => round($riderPending + $merchantPending, 2),
            'successful_txn'       => $riderSuccess + $merchantPaidCnt,
            'failed_txn'           => $riderFailed,
        ];

        return response()->json([
            'status' => 1,
            'data'   => [
                'stats'                       => $stats,
                'payout_trend'                => $this->safe(function () use ($from, $to, $group) { return $this->trend($from, $to, $group); }, ['labels' => [], 'rider' => [], 'merchant' => []]),
                'disbursement_by_type'        => [
                    ['name' => 'Rider Payouts', 'amount' => round($riderTotal, 2)],
                    ['name' => 'Merchant Settlements', 'amount' => round($merchantTotal, 2)],
                ],
                'payout_status'               => ['success' => $stats['successful_txn'], 'failed' => $stats['failed_txn']],
                'recent_rider_payouts'        => $this->safe(function () { return $this->recentRiderPayouts(); }, []),
                'recent_merchant_settlements' => $this->safe(function () use ($from, $to) { return $this->recentMerchantSettlements($from, $to); }, []),
                'payout_requests'             => $this->safe(function () { return $this->recentRequests(6); }, []),
                'request_counts'              => $this->safe(function () { return $this->requestCounts(); }, null),
                'payment_methods'             => $this->safe(function () use ($from, $to) { return $this->paymentMethods($from, $to); }, []),
                'method_totals'               => $this->methodTotals,
                'insights'                    => $this->safe(function () use ($stats) { return $this->insights($stats); }, []),
                'request_statuses'            => ['Pending', 'Approved', 'Rejected'],
            ],
        ]);
        } catch (\Throwable $e) {
            // Last-resort safety net: never 500 the dashboard, log the cause.
            Log::error('[PayoutAnalytics] overview fatal: ' . $e->getMessage());
            return response()->json([
                'status' => 1,
                'data'   => [
                    'stats' => ['total_disbursed' => 0, 'rider_payouts' => 0, 'merchant_settlements' => 0, 'pending_amount' => 0, 'successful_txn' => 0, 'failed_txn' => 0],
                    'payout_trend' => ['labels' => [], 'rider' => [], 'merchant' => []],
                    'disbursement_by_type' => [], 'payout_status' => ['success' => 0, 'failed' => 0],
                    'recent_rider_payouts' => [], 'recent_merchant_settlements' => [], 'payout_requests' => [],
                    'request_counts' => null, 'payment_methods' => [], 'method_totals' => null, 'insights' => [],
                    'request_statuses' => ['Pending', 'Approved', 'Rejected'],
                ],
            ]);
        }
    }

    private function trend($from, $to, $group)
    {
        $riderRows = $this->hasPayoutHistory()
            ? $this->riderPaidQuery($from, $to)->select(DB::raw('COALESCE(completed_at, created_at) as d'), 'amount')->get()
            : collect();
        $merchantRows = $this->merchantReady()
            ? $this->merchantPaidQuery($from, $to)->select('paid_at as d', 'amount')->get()
            : collect();

        $buckets = [];
        $cursor = $from->copy()->startOfDay();
        while ($cursor->lte($to)) {
            $key = $group === 'weekly' ? $cursor->format('o-\WW') : $cursor->format('Y-m-d');
            if (!isset($buckets[$key])) $buckets[$key] = ['r' => 0, 'm' => 0];
            $cursor->addDay();
        }
        $put = function ($rows, $slot) use (&$buckets, $group) {
            foreach ($rows as $row) {
                if (!$row->d) continue;
                $key = Carbon::parse($row->d)->format($group === 'weekly' ? 'o-\WW' : 'Y-m-d');
                if (!isset($buckets[$key])) $buckets[$key] = ['r' => 0, 'm' => 0];
                $buckets[$key][$slot] += (float) $row->amount;
            }
        };
        $put($riderRows, 'r');
        $put($merchantRows, 'm');
        if (count($buckets) > 90) $buckets = array_slice($buckets, -90, null, true);

        $labels = []; $rider = []; $merchant = [];
        foreach ($buckets as $k => $v) { $labels[] = $k; $rider[] = round($v['r'], 2); $merchant[] = round($v['m'], 2); }
        return ['labels' => $labels, 'rider' => $rider, 'merchant' => $merchant];
    }

    private function recentRiderPayouts()
    {
        if (!$this->hasPayoutHistory()) return [];
        $rows = DB::table('delivery_boy_payout_history as p')
            ->leftJoin('delivery_boys as d', 'd.id', '=', 'p.delivery_boy_id')
            ->orderByDesc('p.id')->limit(6)
            ->get(['p.id', 'p.delivery_boy_id', 'p.amount', 'p.status', 'p.transaction_ids', 'p.completed_at', 'p.created_at',
                   'd.name as rider_name', $this->payModeSelect()]);
        return collect($rows)->map(function ($r) {
            $deliveries = 0;
            if ($r->transaction_ids) { $ids = json_decode($r->transaction_ids, true); $deliveries = is_array($ids) ? count($ids) : 0; }
            return [
                'id'         => $r->id,
                'name'       => $r->rider_name ?: ('Rider #' . $r->delivery_boy_id),
                'rider_id'   => 'RD' . $r->delivery_boy_id,
                'deliveries' => $deliveries,
                'earnings'   => round((float) $r->amount, 2),
                'payout'     => round((float) $r->amount, 2),
                'method'     => ($r->payment_mode ?? null) ?: 'UPI',
                'status'     => ucfirst($r->status),
                'date'       => (string) ($r->completed_at ?: $r->created_at),
            ];
        })->values();
    }

    private function recentMerchantSettlements($from, $to)
    {
        if (!$this->merchantReady()) return [];
        $rows = $this->merchantPaidQuery($from, $to)
            ->select('seller_id',
                DB::raw('COUNT(DISTINCT order_id) as orders'),
                DB::raw('SUM(amount) as settlement'),
                $this->commissionSelect(),
                DB::raw('MAX(paid_at) as last_paid'))
            ->groupBy('seller_id')->orderByDesc('last_paid')->limit(6)->get();

        if ($rows->isEmpty()) return [];
        $sellers = DB::table('sellers')->whereIn('id', $rows->pluck('seller_id'))->get(['id', 'name', 'store_name'])->keyBy('id');
        return $rows->map(function ($r) use ($sellers) {
            $s = $sellers->get($r->seller_id);
            $name = $s ? ($s->store_name ?: $s->name) : null;
            $settlement = round((float) $r->settlement, 2);
            $commission = round((float) $r->commission, 2);
            return [
                'id'          => $r->seller_id,
                'name'        => $name ?: ('Seller #' . $r->seller_id),
                'merchant_id' => 'MRC' . $r->seller_id,
                'orders'      => (int) $r->orders,
                'sales'       => round($settlement + $commission, 2),
                'commission'  => $commission,
                'settlement'  => $settlement,
                'status'      => 'Success',
                'date'        => (string) $r->last_paid,
            ];
        })->values();
    }

    // ---- Payout requests (unified withdrawal_requests) ------------------
    private $requestTypeLabel = ['delivery_boy' => 'Rider', 'seller' => 'Merchant', 'user' => 'Customer'];
    private $requestStatusName = [0 => 'Pending', 1 => 'Approved', 2 => 'Rejected'];

    private function recentRequests($limit)
    {
        if (!Schema::hasTable('withdrawal_requests')) return [];
        $rows = DB::table('withdrawal_requests')->orderByDesc('id')->limit($limit)->get();
        return $this->mapRequests($rows);
    }

    private function mapRequests($rows)
    {
        $byType = collect($rows)->groupBy('type');
        $names = [];
        foreach ($byType as $type => $group) {
            $ids = collect($group)->pluck('type_id')->unique()->all();
            if ($type === 'seller' && Schema::hasTable('sellers')) {
                $names['seller'] = DB::table('sellers')->whereIn('id', $ids)->get(['id', 'name', 'store_name'])->keyBy('id');
            } elseif ($type === 'delivery_boy' && Schema::hasTable('delivery_boys')) {
                $names['delivery_boy'] = DB::table('delivery_boys')->whereIn('id', $ids)->get(['id', 'name'])->keyBy('id');
            } elseif ($type === 'user' && Schema::hasTable('users')) {
                $names['user'] = DB::table('users')->whereIn('id', $ids)->get(['id', 'name'])->keyBy('id');
            }
        }
        return collect($rows)->map(function ($r) use ($names) {
            $rec = isset($names[$r->type]) ? $names[$r->type]->get($r->type_id) : null;
            $name = $rec ? (($r->type === 'seller' ? ($rec->store_name ?: $rec->name) : $rec->name)) : ('#' . $r->type_id);
            return [
                'id'        => $r->id,
                'user_type' => $this->requestTypeLabel[$r->type] ?? ucfirst($r->type),
                'name'      => $name,
                'amount'    => round((float) $r->amount, 2),
                'method'    => '-',
                'status'    => $this->requestStatusName[$r->status] ?? 'Unknown',
                'date'      => (string) $r->created_at,
            ];
        })->values();
    }

    private function requestCounts()
    {
        if (!Schema::hasTable('withdrawal_requests')) return null;
        $rows = DB::table('withdrawal_requests')->select('status', DB::raw('COUNT(*) as c'))->groupBy('status')->pluck('c', 'status');
        return [
            'pending'  => (int) ($rows[0] ?? 0),
            'approved' => (int) ($rows[1] ?? 0),
            'rejected' => (int) ($rows[2] ?? 0),
        ];
    }

    // ---- Payment methods (derived) --------------------------------------
    public $methodTotals = null;

    private function paymentMethods($from, $to)
    {
        $agg = [];
        // Riders: grouped by their preferred payment_mode (PhonePe UPI/bank)
        if ($this->hasPayoutHistory()) {
            $modeExpr = $this->hasCol('delivery_boys', 'payment_mode') ? "COALESCE(d.payment_mode, 'UPI')" : "'UPI'";
            $rows = $this->riderPaidQuery($from, $to)
                ->leftJoin('delivery_boys as d', 'd.id', '=', 'delivery_boy_payout_history.delivery_boy_id')
                ->select(DB::raw("$modeExpr as m"),
                         DB::raw('COUNT(*) as c'), DB::raw('SUM(delivery_boy_payout_history.amount) as a'))
                ->groupBy(DB::raw($modeExpr))->get();
            foreach ($rows as $r) {
                $m = $r->m ?: 'UPI';
                if (!isset($agg[$m])) $agg[$m] = ['transactions' => 0, 'amount' => 0];
                $agg[$m]['transactions'] += (int) $r->c;
                $agg[$m]['amount'] += (float) $r->a;
            }
        }
        // Merchants: settled via bank transfer (no per-settlement method column)
        if ($this->merchantReady()) {
            $mc = (int) $this->merchantPaidQuery($from, $to)->count();
            $ma = (float) $this->merchantPaidQuery($from, $to)->sum('amount');
            if ($mc > 0) {
                if (!isset($agg['Bank Transfer'])) $agg['Bank Transfer'] = ['transactions' => 0, 'amount' => 0];
                $agg['Bank Transfer']['transactions'] += $mc;
                $agg['Bank Transfer']['amount'] += $ma;
            }
        }

        $totalAmt = array_sum(array_column($agg, 'amount')) ?: 1;
        $totalTxn = array_sum(array_column($agg, 'transactions'));
        $out = [];
        foreach ($agg as $method => $v) {
            $out[] = [
                'method' => $method, 'transactions' => $v['transactions'], 'amount' => round($v['amount'], 2),
                'pct' => round($v['amount'] * 1000 / $totalAmt) / 10,
            ];
        }
        usort($out, function ($a, $b) { return $b['amount'] <=> $a['amount']; });
        $this->methodTotals = ['transactions' => $totalTxn, 'amount' => round(array_sum(array_column($agg, 'amount')), 2)];
        return $out;
    }

    private function insights($stats)
    {
        $out = [];
        $disb = $stats['total_disbursed'] ?: 1;
        $out[] = 'Total disbursed <b>₹' . number_format($stats['total_disbursed'], 2) . '</b> across <b>' . number_format($stats['successful_txn']) . '</b> transactions.';
        $out[] = 'Rider payouts make up <b>' . round($stats['rider_payouts'] * 100 / $disb, 1) . '%</b> of total disbursed.';
        $counts = $this->safe(function () { return $this->requestCounts(); }, null);
        if ($counts && $counts['pending'] > 0) $out[] = '<b>' . number_format($counts['pending']) . '</b> payout requests are pending action.';
        if ($stats['failed_txn'] > 0) $out[] = '<b>' . number_format($stats['failed_txn']) . '</b> payout transactions failed.';
        if ($stats['pending_amount'] > 0) $out[] = '<b>₹' . number_format($stats['pending_amount'], 2) . '</b> is pending disbursement.';
        return $out;
    }

    // =====================================================================
    //  RIDER PAYOUTS (paginated)
    // =====================================================================
    public function riderPayouts(Request $request)
    {
        try {
            if (!$this->hasPayoutHistory()) return response()->json(['status' => 1, 'data' => ['data' => [], 'current_page' => 1, 'last_page' => 1]]);
            [$from, $to] = $this->range($request);
            $search = $request->get('search', '');
            $perPage = (int) $request->get('per_page', 15);

            $q = DB::table('delivery_boy_payout_history as p')
                ->leftJoin('delivery_boys as d', 'd.id', '=', 'p.delivery_boy_id')
                ->whereBetween(DB::raw('COALESCE(p.completed_at, p.created_at)'), [$from, $to])
                ->orderByDesc('p.id')
                ->select('p.id', 'p.delivery_boy_id', 'p.amount', 'p.status', 'p.transaction_ids', 'p.completed_at', 'p.created_at',
                         'd.name as rider_name', $this->payModeSelect());
            if ($search) {
                $q->where(function ($x) use ($search) {
                    $x->where('d.name', 'like', "%{$search}%")->orWhere('p.payout_transaction_id', 'like', "%{$search}%");
                });
            }
            $page = $q->paginate($perPage);
            $page->getCollection()->transform(function ($r) {
                $deliveries = 0;
                if ($r->transaction_ids) { $ids = json_decode($r->transaction_ids, true); $deliveries = is_array($ids) ? count($ids) : 0; }
                return [
                    'id' => $r->id, 'name' => $r->rider_name ?: ('Rider #' . $r->delivery_boy_id), 'rider_id' => 'RD' . $r->delivery_boy_id,
                    'deliveries' => $deliveries, 'earnings' => round((float) $r->amount, 2), 'payout' => round((float) $r->amount, 2),
                    'method' => (($r->payment_mode ?? null) ?: 'UPI'), 'status' => ucfirst($r->status), 'date' => (string) ($r->completed_at ?: $r->created_at),
                ];
            });
            return response()->json(['status' => 1, 'data' => $page]);
        } catch (\Exception $e) {
            Log::warning('[PayoutAnalytics] riderPayouts: ' . $e->getMessage());
            return response()->json(['status' => 1, 'data' => ['data' => [], 'current_page' => 1, 'last_page' => 1]]);
        }
    }

    // =====================================================================
    //  MERCHANT SETTLEMENTS (paginated, grouped by seller)
    // =====================================================================
    public function merchantSettlements(Request $request)
    {
        try {
            if (!$this->merchantReady()) return response()->json(['status' => 1, 'data' => ['data' => [], 'current_page' => 1, 'last_page' => 1]]);
            [$from, $to] = $this->range($request);
            $search = $request->get('search', '');
            $perPage = (int) $request->get('per_page', 15);

            $q = $this->merchantPaidQuery($from, $to)
                ->select('seller_id',
                    DB::raw('COUNT(DISTINCT order_id) as orders'),
                    DB::raw('SUM(amount) as settlement'),
                    $this->commissionSelect(),
                    DB::raw('MAX(paid_at) as last_paid'))
                ->groupBy('seller_id')->orderByDesc('last_paid');

            // Search by merchant name / store name -> constrain to matching seller ids.
            if ($search) {
                $matchIds = DB::table('sellers')
                    ->where('name', 'like', "%{$search}%")
                    ->orWhere('store_name', 'like', "%{$search}%")
                    ->pluck('id')->all();
                $q->whereIn('seller_id', $matchIds ?: [-1]);
            }

            $page = $q->paginate($perPage);

            $sellers = DB::table('sellers')->whereIn('id', $page->getCollection()->pluck('seller_id'))
                ->get(['id', 'name', 'store_name'])->keyBy('id');

            $page->getCollection()->transform(function ($r) use ($sellers) {
                $s = $sellers->get($r->seller_id);
                $name = $s ? ($s->store_name ?: $s->name) : null;
                $settlement = round((float) $r->settlement, 2);
                $commission = round((float) $r->commission, 2);
                return [
                    'id' => $r->seller_id, 'name' => $name ?: ('Seller #' . $r->seller_id), 'merchant_id' => 'MRC' . $r->seller_id,
                    'orders' => (int) $r->orders, 'sales' => round($settlement + $commission, 2), 'commission' => $commission,
                    'settlement' => $settlement, 'status' => 'Success', 'date' => (string) $r->last_paid,
                ];
            });
            return response()->json(['status' => 1, 'data' => $page]);
        } catch (\Exception $e) {
            Log::warning('[PayoutAnalytics] merchantSettlements: ' . $e->getMessage());
            return response()->json(['status' => 1, 'data' => ['data' => [], 'current_page' => 1, 'last_page' => 1]]);
        }
    }

    // =====================================================================
    //  PAYOUT REQUESTS (paginated)
    // =====================================================================
    public function payoutRequests(Request $request)
    {
        try {
            if (!Schema::hasTable('withdrawal_requests')) return response()->json(['status' => 1, 'data' => ['data' => [], 'current_page' => 1, 'last_page' => 1]]);
            [$from, $to] = $this->range($request);
            $status = $request->get('status', '');
            $perPage = (int) $request->get('per_page', 15);

            $q = DB::table('withdrawal_requests')->whereBetween('created_at', [$from, $to])->orderByDesc('id');
            if ($status !== '') {
                $code = array_search($status, $this->requestStatusName);
                if ($code !== false) $q->where('status', $code);
            }
            $page = $q->paginate($perPage);
            $mapped = $this->mapRequests($page->getCollection());
            $page->setCollection($mapped);
            return response()->json(['status' => 1, 'data' => $page]);
        } catch (\Exception $e) {
            Log::warning('[PayoutAnalytics] payoutRequests: ' . $e->getMessage());
            return response()->json(['status' => 1, 'data' => ['data' => [], 'current_page' => 1, 'last_page' => 1]]);
        }
    }

    // =====================================================================
    //  EXPORT (CSV of rider payouts)
    // =====================================================================
    public function export(Request $request)
    {
        [$from, $to] = $this->range($request);
        $riders = ($this->hasPayoutHistory())
            ? $this->safe(function () use ($from, $to) {
                return DB::table('delivery_boy_payout_history as p')->leftJoin('delivery_boys as d', 'd.id', '=', 'p.delivery_boy_id')
                    ->whereBetween(DB::raw('COALESCE(p.completed_at, p.created_at)'), [$from, $to])
                    ->get(['p.id', 'p.delivery_boy_id', 'p.amount', 'p.status', 'p.completed_at', 'd.name as rider_name']);
            }, collect())
            : collect();

        $headers = ['Content-Type' => 'text/csv', 'Content-Disposition' => 'attachment; filename="payouts_report.csv"'];
        $callback = function () use ($riders) {
            $out = fopen('php://output', 'w');
            fputcsv($out, ['Type', 'ID', 'Name', 'Amount', 'Status', 'Date']);
            foreach ($riders as $r) {
                fputcsv($out, ['Rider Payout', 'RD' . $r->delivery_boy_id, $r->rider_name, $r->amount, ucfirst($r->status), (string) $r->completed_at]);
            }
            fclose($out);
        };
        return response()->stream($callback, 200, $headers);
    }
}
