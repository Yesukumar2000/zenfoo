<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\CustomerItemMissingReport;
use App\Models\SellerWalletTransaction;
use App\Models\WalletTransaction;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;

/**
 * Refunds & Disputes analytics — existing data only.
 *
 * There is no refunds/disputes/chargebacks table in this platform. So:
 *  - Refund lifecycle (pending/approved/rejected) comes from the customer
 *    issue-report system (customer_item_missing_reports where a refund was
 *    requested): status 2 = Approved, 3 = Rejected, everything else Pending.
 *  - Refund MONEY (amounts, trend, source) comes from wallet_transactions
 *    refund rows, attributed to orders.
 *  - Disputes = the full customer_item_missing_reports set, by status/type.
 *  - Top merchants = seller_wallet_transactions.refundable_amount by seller.
 *  - Chargebacks have NO data source and are reported as not tracked.
 */
class RefundDisputeAnalyticsController extends Controller
{
    private $reportStatusNames = [
        0 => 'Pending', 1 => 'In Progress', 2 => 'Resolved', 3 => 'Rejected',
        4 => 'Driver Assigned', 5 => 'Driver Took Item', 6 => 'Driver Returned Item',
    ];

    private $reportTypeLabels = ['missing' => 'Missing Item', 'wrong' => 'Wrong Item', 'return' => 'Return'];

    private function range(Request $request)
    {
        $to   = $request->filled('to_date')   ? Carbon::parse($request->to_date)->endOfDay()     : Carbon::now()->endOfDay();
        $from = $request->filled('from_date') ? Carbon::parse($request->from_date)->startOfDay() : Carbon::now()->subDays(30)->startOfDay();
        return [$from, $to];
    }

    /** Base query for customer refund payouts (money actually returned). */
    private function refundWalletQuery($from, $to)
    {
        return WalletTransaction::whereBetween('created_at', [$from, $to])
            ->where(function ($q) {
                // payment_type is set to 'Wallet Refund' / 'refund' on the two refund
                // code paths; the message prefix is the exact string those rows carry.
                $q->whereIn('payment_type', ['Wallet Refund', 'refund'])
                  ->orWhere('message', 'like', 'Refund for%');
            });
    }

    private function reportTypeLabel($t) { return $this->reportTypeLabels[$t] ?? ucfirst($t ?: 'Other'); }

    private function lifecycle($status) {
        if ((int) $status === 2) return 'Approved';
        if ((int) $status === 3) return 'Rejected';
        return 'Pending';
    }

    /** Run a query closure, returning $default (and logging) if it throws. */
    private function safe(callable $fn, $default = null)
    {
        try { return $fn(); }
        catch (\Throwable $e) {
            Log::warning('[RefundAnalytics] ' . $e->getMessage());
            return $default;
        }
    }

    private function hasReports() { return Schema::hasTable('customer_item_missing_reports'); }
    private function hasWallet()  { return Schema::hasTable('wallet_transactions'); }

    // =====================================================================
    //  OVERVIEW
    // =====================================================================
    public function overview(Request $request)
    {
        try {
            [$from, $to] = $this->range($request);
            $group = $request->get('group', 'daily');

            // --- Refund money (wallet refund rows) — guarded --------------
            $refundRows = $this->hasWallet()
                ? $this->safe(function () use ($from, $to) { return $this->refundWalletQuery($from, $to)->get(['order_id', 'amount', 'transaction_date', 'created_at']); }, collect())
                : collect();
            $totalRefundAmount = round($refundRows->sum('amount'), 2);
            $amountByOrder = [];
            foreach ($refundRows as $r) {
                $amountByOrder[$r->order_id] = ($amountByOrder[$r->order_id] ?? 0) + (float) $r->amount;
            }

            // --- Refund requests (lifecycle) from issue reports — guarded -
            $totalRefunds = 0; $approved = 0; $rejected = 0; $pending = 0; $totalDisputes = 0;
            $reqBase = null; $dispBase = null;
            if ($this->hasReports()) {
                $reqBase = CustomerItemMissingReport::whereBetween('created_at', [$from, $to])->where('is_refund_requested', 1);
                $totalRefunds = (int) $this->safe(function () use ($reqBase) { return (clone $reqBase)->count(); }, 0);
                $approved     = (int) $this->safe(function () use ($reqBase) { return (clone $reqBase)->where('status', 2)->count(); }, 0);
                $rejected     = (int) $this->safe(function () use ($reqBase) { return (clone $reqBase)->where('status', 3)->count(); }, 0);
                $pending      = $totalRefunds - $approved - $rejected;

                $dispBase = CustomerItemMissingReport::whereBetween('created_at', [$from, $to]);
                $totalDisputes = (int) $this->safe(function () use ($dispBase) { return (clone $dispBase)->count(); }, 0);
            }

            $stats = [
                'total_refund_amount' => $totalRefundAmount,
                'total_refunds'       => $totalRefunds,
                'pending_refunds'     => $pending,
                'approved_refunds'    => $approved,
                'total_disputes'      => $totalDisputes,
                'chargebacks'         => 0,   // no data source
            ];

            return response()->json([
                'status' => 1,
                'data'   => [
                    'stats'              => $stats,
                    'refund_trend'       => $this->safe(function () use ($refundRows, $from, $to, $group) { return $this->trend($refundRows, $from, $to, $group); }, ['labels' => [], 'amount' => [], 'count' => []]),
                    'refunds_by_status'  => [
                        ['name' => 'Approved', 'count' => $approved],
                        ['name' => 'Pending',  'count' => $pending],
                        ['name' => 'Rejected', 'count' => $rejected],
                    ],
                    'refunds_by_source'  => $this->safe(function () use ($refundRows, $amountByOrder, $from, $to) { return $this->bySource($refundRows, $amountByOrder, $from, $to); }, []),
                    'refunds_by_reason'  => $reqBase ? $this->safe(function () use ($reqBase, $amountByOrder) { return $this->byReason($reqBase, $amountByOrder, 5); }, []) : [],
                    'disputes_by_status' => $dispBase ? $this->safe(function () use ($dispBase) { return $this->disputesByStatus($dispBase); }, []) : [],
                    'disputes_by_type'   => $dispBase ? $this->safe(function () use ($dispBase, $amountByOrder) { return $this->disputesByType($dispBase, $amountByOrder); }, []) : [],
                    'recent_refunds'     => $this->safe(function () use ($amountByOrder) { return $this->recentRefunds($amountByOrder); }, []),
                    'recent_disputes'    => $this->safe(function () use ($amountByOrder) { return $this->recentDisputes($amountByOrder); }, []),
                    'chargebacks'        => null,   // not tracked -> card hidden
                    'top_merchants'      => $this->safe(function () use ($from, $to) { return $this->topMerchants($from, $to, 5); }, []),
                    'refund_insights'    => $reqBase ? $this->safe(function () use ($stats, $reqBase, $from, $to) { return $this->insights($stats, $reqBase, $from, $to); }, []) : [],
                    'dispute_statuses'   => array_values($this->reportStatusNames),
                ],
            ]);
        } catch (\Throwable $e) {
            // Last-resort safety net: never 500 the dashboard, log the cause.
            Log::error('[RefundAnalytics] overview fatal: ' . $e->getMessage());
            return response()->json([
                'status' => 1,
                'data'   => [
                    'stats' => ['total_refund_amount' => 0, 'total_refunds' => 0, 'pending_refunds' => 0, 'approved_refunds' => 0, 'total_disputes' => 0, 'chargebacks' => 0],
                    'refund_trend' => ['labels' => [], 'amount' => [], 'count' => []],
                    'refunds_by_status' => [], 'refunds_by_source' => [], 'refunds_by_reason' => [],
                    'disputes_by_status' => [], 'disputes_by_type' => [], 'recent_refunds' => [], 'recent_disputes' => [],
                    'chargebacks' => null, 'top_merchants' => [], 'refund_insights' => [],
                    'dispute_statuses' => array_values($this->reportStatusNames),
                ],
            ]);
        }
    }

    /** Daily / weekly refund amount + count series. */
    private function trend($refundRows, $from, $to, $group)
    {
        $fmt = $group === 'weekly' ? 'o-\WW' : 'Y-m-d';
        $labels = []; $amount = []; $count = [];
        $buckets = [];

        $cursor = $from->copy()->startOfDay();
        while ($cursor->lte($to)) {
            $key = $group === 'weekly' ? $cursor->format('o-\WW') : $cursor->format('Y-m-d');
            if (!isset($buckets[$key])) { $buckets[$key] = ['a' => 0, 'c' => 0]; }
            $cursor->addDay();
        }
        foreach ($refundRows as $r) {
            $d = $r->created_at ? Carbon::parse($r->created_at) : null;
            if (!$d) continue;
            $key = $group === 'weekly' ? $d->format('o-\WW') : $d->format('Y-m-d');
            if (!isset($buckets[$key])) $buckets[$key] = ['a' => 0, 'c' => 0];
            $buckets[$key]['a'] += (float) $r->amount;
            $buckets[$key]['c'] += 1;
        }
        // keep last 90 buckets max
        if (count($buckets) > 90) $buckets = array_slice($buckets, -90, null, true);
        foreach ($buckets as $k => $v) { $labels[] = $k; $amount[] = round($v['a'], 2); $count[] = $v['c']; }

        return ['labels' => $labels, 'amount' => $amount, 'count' => $count];
    }

    /** Refund source: customer-issue-linked vs other (single ledger, no double count). */
    private function bySource($refundRows, $amountByOrder, $from, $to)
    {
        $orderIds = array_keys($amountByOrder);
        if (!count($orderIds)) return [];
        $reportOrderIds = CustomerItemMissingReport::whereIn('order_id', $orderIds)->pluck('order_id')->unique()->flip();

        $customer = 0; $other = 0;
        foreach ($amountByOrder as $orderId => $amt) {
            if (isset($reportOrderIds[$orderId])) $customer += $amt; else $other += $amt;
        }
        $out = [];
        if ($customer > 0) $out[] = ['name' => 'Customer Request', 'amount' => round($customer, 2)];
        if ($other > 0)    $out[] = ['name' => 'Admin / Gateway',  'amount' => round($other, 2)];
        return $out;
    }

    /** Refund reasons via report_type (missing/wrong/return), amount attributed from wallet. */
    private function byReason($reqBase, $amountByOrder, $limit = null)
    {
        $rows = (clone $reqBase)->get(['order_id', 'report_type']);
        $agg = [];
        foreach ($rows as $r) {
            $label = $this->reportTypeLabel($r->report_type);
            if (!isset($agg[$label])) $agg[$label] = ['count' => 0, 'amount' => 0];
            $agg[$label]['count']++;
            $agg[$label]['amount'] += $amountByOrder[$r->order_id] ?? 0;
        }
        $totalCount = array_sum(array_column($agg, 'count')) ?: 1;
        $out = [];
        foreach ($agg as $reason => $v) {
            $out[] = [
                'reason' => $reason, 'count' => $v['count'], 'amount' => round($v['amount'], 2),
                'pct' => round($v['count'] * 1000 / $totalCount) / 10,
            ];
        }
        usort($out, function ($a, $b) { return $b['count'] <=> $a['count']; });
        return $limit ? array_slice($out, 0, $limit) : $out;
    }

    private function disputesByStatus($dispBase)
    {
        $rows = (clone $dispBase)->select('status', DB::raw('COUNT(*) as c'))->groupBy('status')->get();
        $out = [];
        foreach ($rows as $r) {
            $out[] = ['name' => $this->reportStatusNames[$r->status] ?? ('Status ' . $r->status), 'count' => (int) $r->c];
        }
        usort($out, function ($a, $b) { return $b['count'] <=> $a['count']; });
        return $out;
    }

    private function disputesByType($dispBase, $amountByOrder)
    {
        $rows = (clone $dispBase)->get(['order_id', 'report_type']);
        $agg = [];
        foreach ($rows as $r) {
            $label = $this->reportTypeLabel($r->report_type);
            if (!isset($agg[$label])) $agg[$label] = ['count' => 0, 'amount' => 0];
            $agg[$label]['count']++;
            $agg[$label]['amount'] += $amountByOrder[$r->order_id] ?? 0;
        }
        $totalCount = array_sum(array_column($agg, 'count')) ?: 1;
        $out = [];
        foreach ($agg as $type => $v) {
            $out[] = ['type' => $type, 'count' => $v['count'], 'amount' => round($v['amount'], 2), 'pct' => round($v['count'] * 1000 / $totalCount) / 10];
        }
        usort($out, function ($a, $b) { return $b['count'] <=> $a['count']; });
        return $out;
    }

    private function recentRefunds($amountByOrder)
    {
        $rows = CustomerItemMissingReport::with('customer:id,name')->where('is_refund_requested', 1)
            ->orderByDesc('created_at')->limit(8)->get();
        return $rows->map(function ($r) use ($amountByOrder) {
            return [
                'id'        => $r->id,
                'refund_id' => 'RFN-' . str_pad($r->id, 5, '0', STR_PAD_LEFT),
                'order_id'  => 'ORD-' . $r->order_id,
                'user'      => optional($r->customer)->name ?: ('Customer #' . $r->customer_id),
                'type'      => $this->reportTypeLabel($r->report_type),
                'reason'    => $r->description ?: $this->reportTypeLabel($r->report_type),
                'amount'    => round($amountByOrder[$r->order_id] ?? 0, 2),
                'status'    => $this->lifecycle($r->status),
                'date'      => (string) $r->created_at,
            ];
        })->values();
    }

    private function recentDisputes($amountByOrder)
    {
        $rows = CustomerItemMissingReport::with('customer:id,name')->orderByDesc('created_at')->limit(8)->get();
        return $rows->map(function ($r) use ($amountByOrder) {
            return [
                'id'         => $r->id,
                'dispute_id' => 'DSP-' . str_pad($r->id, 5, '0', STR_PAD_LEFT),
                'order_id'   => 'ORD-' . $r->order_id,
                'user'       => optional($r->customer)->name ?: ('Customer #' . $r->customer_id),
                'type'       => $this->reportTypeLabel($r->report_type),
                'amount'     => round($amountByOrder[$r->order_id] ?? 0, 2),
                'status'     => $this->reportStatusNames[$r->status] ?? 'Unknown',
                'date'       => (string) $r->created_at,
            ];
        })->values();
    }

    /** Top merchants by refund amount (seller_wallet_transactions). */
    private function topMerchants($from, $to, $limit = 5)
    {
        if (!Schema::hasTable('seller_wallet_transactions')) return [];
        $rows = SellerWalletTransaction::whereBetween('created_at', [$from, $to])
            ->where('is_refunded_to_customer', 1)
            ->whereNotNull('seller_id')
            ->select('seller_id', DB::raw('COUNT(*) as refunds'), DB::raw('SUM(refundable_amount) as amount'))
            ->groupBy('seller_id')->orderByDesc('amount')->limit($limit)->get();

        if ($rows->isEmpty()) return [];
        $sellers = DB::table('sellers')->whereIn('id', $rows->pluck('seller_id'))->get(['id', 'name', 'store_name'])->keyBy('id');
        return $rows->map(function ($r) use ($sellers) {
            $s = $sellers->get($r->seller_id);
            $name = $s ? ($s->store_name ?: $s->name) : null;
            return ['name' => $name ?: ('Seller #' . $r->seller_id), 'refunds' => (int) $r->refunds, 'amount' => round((float) $r->amount, 2)];
        })->values();
    }

    private function insights($stats, $reqBase, $from, $to)
    {
        $out = [];
        $out[] = '<b>' . number_format($stats['total_refunds']) . '</b> refund requests worth <b>₹' . number_format($stats['total_refund_amount'], 2) . '</b> in this period.';

        $reasons = $this->byReason($reqBase, [], 1);
        if (count($reasons)) {
            $out[] = 'Top reason: <b>' . $reasons[0]['reason'] . '</b> (' . $reasons[0]['pct'] . '% of refund requests).';
        }
        if ($stats['pending_refunds'] > 0) {
            $out[] = '<b>' . number_format($stats['pending_refunds']) . '</b> refund requests are pending action.';
        }
        $total = $stats['total_refunds'] ?: 1;
        $out[] = 'Approval rate: <b>' . round($stats['approved_refunds'] * 100 / $total, 1) . '%</b> of refund requests approved.';
        return $out;
    }

    // =====================================================================
    //  REFUNDS (refund-request reports, paginated)
    // =====================================================================
    public function refunds(Request $request)
    {
        try {
            $status  = $request->get('status', '');
            $search  = $request->get('search', '');
            $perPage = (int) $request->get('per_page', 15);

            [$from, $to] = $this->range($request);
            $q = CustomerItemMissingReport::with('customer:id,name')->where('is_refund_requested', 1)
                ->whereBetween('created_at', [$from, $to])->orderByDesc('created_at');
            if ($status) {
                if ($status === 'Approved') $q->where('status', 2);
                elseif ($status === 'Rejected') $q->where('status', 3);
                elseif ($status === 'Pending') $q->whereNotIn('status', [2, 3]);
                else $q->where('status', array_search($status, $this->reportStatusNames));
            }
            if ($search) {
                $q->where(function ($x) use ($search) {
                    $x->where('order_id', 'like', "%{$search}%")->orWhere('description', 'like', "%{$search}%");
                });
            }
            $page = $q->paginate($perPage);

            // attribute amounts for this page's orders
            $orderIds = $page->getCollection()->pluck('order_id')->all();
            $amountByOrder = $this->amountMapForOrders($orderIds);

            $page->getCollection()->transform(function ($r) use ($amountByOrder) {
                return [
                    'id'        => $r->id,
                    'refund_id' => 'RFN-' . str_pad($r->id, 5, '0', STR_PAD_LEFT),
                    'order_id'  => 'ORD-' . $r->order_id,
                    'user'      => optional($r->customer)->name ?: ('Customer #' . $r->customer_id),
                    'type'      => $this->reportTypeLabel($r->report_type),
                    'reason'    => $r->description ?: $this->reportTypeLabel($r->report_type),
                    'amount'    => round($amountByOrder[$r->order_id] ?? 0, 2),
                    'status'    => $this->lifecycle($r->status),
                    'date'      => (string) $r->created_at,
                ];
            });
            return response()->json(['status' => 1, 'data' => $page]);
        } catch (\Throwable $e) {
            Log::warning('[RefundAnalytics] refunds: ' . $e->getMessage());
            return response()->json(['status' => 1, 'data' => ['data' => [], 'current_page' => 1, 'last_page' => 1]]);
        }
    }

    private function amountMapForOrders($orderIds)
    {
        if (!count($orderIds)) return [];
        $rows = WalletTransaction::whereIn('order_id', $orderIds)
            ->where(function ($q) {
                $q->whereIn('payment_type', ['Wallet Refund', 'refund'])->orWhere('message', 'like', 'Refund for%');
            })
            ->select('order_id', DB::raw('SUM(amount) as amt'))->groupBy('order_id')->pluck('amt', 'order_id');
        return $rows->toArray();
    }

    // =====================================================================
    //  DISPUTES (all issue reports, paginated)
    // =====================================================================
    public function disputes(Request $request)
    {
        try {
            $status  = $request->get('status', '');
            $search  = $request->get('search', '');
            $perPage = (int) $request->get('per_page', 15);

            [$from, $to] = $this->range($request);
            $q = CustomerItemMissingReport::with('customer:id,name')
                ->whereBetween('created_at', [$from, $to])->orderByDesc('created_at');
            if ($status) {
                $code = array_search($status, $this->reportStatusNames);
                if ($code !== false) $q->where('status', $code);
            }
            if ($search) {
                $q->where(function ($x) use ($search) {
                    $x->where('order_id', 'like', "%{$search}%")->orWhere('description', 'like', "%{$search}%");
                });
            }
            $page = $q->paginate($perPage);

            $orderIds = $page->getCollection()->pluck('order_id')->all();
            $amountByOrder = $this->amountMapForOrders($orderIds);

            $page->getCollection()->transform(function ($r) use ($amountByOrder) {
                return [
                    'id'         => $r->id,
                    'dispute_id' => 'DSP-' . str_pad($r->id, 5, '0', STR_PAD_LEFT),
                    'order_id'   => 'ORD-' . $r->order_id,
                    'user'       => optional($r->customer)->name ?: ('Customer #' . $r->customer_id),
                    'type'       => $this->reportTypeLabel($r->report_type),
                    'amount'     => round($amountByOrder[$r->order_id] ?? 0, 2),
                    'status'     => $this->reportStatusNames[$r->status] ?? 'Unknown',
                    'date'       => (string) $r->created_at,
                ];
            });
            return response()->json(['status' => 1, 'data' => $page]);
        } catch (\Throwable $e) {
            Log::warning('[RefundAnalytics] disputes: ' . $e->getMessage());
            return response()->json(['status' => 1, 'data' => ['data' => [], 'current_page' => 1, 'last_page' => 1]]);
        }
    }

    // =====================================================================
    //  REASONS (full report_type breakdown)
    // =====================================================================
    public function reasons(Request $request)
    {
        try {
            [$from, $to] = $this->range($request);
            $refundRows = $this->refundWalletQuery($from, $to)->get(['order_id', 'amount']);
            $amountByOrder = [];
            foreach ($refundRows as $r) $amountByOrder[$r->order_id] = ($amountByOrder[$r->order_id] ?? 0) + (float) $r->amount;

            $reqBase = CustomerItemMissingReport::whereBetween('created_at', [$from, $to])->where('is_refund_requested', 1);
            return response()->json(['status' => 1, 'data' => ['records' => $this->byReason($reqBase, $amountByOrder)]]);
        } catch (\Throwable $e) {
            Log::warning('[RefundAnalytics] reasons: ' . $e->getMessage());
            return response()->json(['status' => 1, 'data' => ['records' => []]]);
        }
    }

    // =====================================================================
    //  EXPORT (CSV of refund requests in range)
    // =====================================================================
    public function export(Request $request)
    {
        [$from, $to] = $this->range($request);
        $rows = CustomerItemMissingReport::with('customer:id,name')->where('is_refund_requested', 1)
            ->whereBetween('created_at', [$from, $to])->orderByDesc('created_at')->get();
        $amountByOrder = $this->amountMapForOrders($rows->pluck('order_id')->all());

        $headers = ['Content-Type' => 'text/csv', 'Content-Disposition' => 'attachment; filename="refunds_report.csv"'];
        $callback = function () use ($rows, $amountByOrder) {
            $out = fopen('php://output', 'w');
            fputcsv($out, ['Refund ID', 'Order ID', 'Customer', 'Type', 'Status', 'Amount', 'Date']);
            foreach ($rows as $r) {
                fputcsv($out, [
                    'RFN-' . str_pad($r->id, 5, '0', STR_PAD_LEFT),
                    'ORD-' . $r->order_id,
                    optional($r->customer)->name ?: ('Customer #' . $r->customer_id),
                    $this->reportTypeLabel($r->report_type),
                    $this->lifecycle($r->status),
                    round($amountByOrder[$r->order_id] ?? 0, 2),
                    (string) $r->created_at,
                ]);
            }
            fclose($out);
        };
        return response()->stream($callback, 200, $headers);
    }
}
