<?php

namespace App\Http\Controllers\API\Seller;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Seller;
use App\Models\SellerWalletTransaction;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class SellerTransactionApiController extends Controller
{
    /**
     * Get authenticated seller from token
     */
    private function getAuthSeller(string $endpoint)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            Log::warning("SellerTransactionApi [{$endpoint}]: Auth token invalid or missing");
            return null;
        }

        Log::info("SellerTransactionApi [{$endpoint}]: Auth admin found", ['admin_id' => $admin->id]);

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            Log::warning("SellerTransactionApi [{$endpoint}]: No seller found for admin_id", ['admin_id' => $admin->id]);
            return null;
        }

        Log::info("SellerTransactionApi [{$endpoint}]: Seller identified", [
            'seller_id' => $seller->id,
            'admin_id' => $admin->id,
            'seller_name' => $seller->name ?? 'N/A',
        ]);

        return $seller;
    }

    /**
     * Credit types (money seller earns)
     */
    private function getCreditTypes()
    {
        return ['order_commission', 'credit', 'refund', 'order_item'];
    }

    /**
     * Debit types (money going out)
     */
    private function getDebitTypes()
    {
        return ['withdrawal', 'debit'];
    }

    /**
     * Calculate payable amount from transactions (amount - refundable_amount if refund applied)
     *
     * @param \Illuminate\Support\Collection $transactions
     * @return array ['total' => float, 'refund_deduction' => float, 'original_total' => float]
     */
    private function calculatePayableAmount($transactions)
    {
        $total = 0;
        $originalTotal = 0;
        $refundDeduction = 0;

        foreach ($transactions as $t) {
            $amount = (float) $t->amount;
            $originalTotal += $amount;

            // If refund already applied to this specific transaction, subtract it.
            // The seller only loses up to what they earned (net) — the platform
            // absorbs the rest. So cap the deduction at the seller's amount and
            // never let payable go below 0, matching the clamped balance_after.
            if ($t->is_refunded_to_customer && $t->refundable_amount > 0) {
                $refund = min($amount, (float) $t->refundable_amount);
                $amount -= $refund;
                $refundDeduction += $refund;
            }

            $total += $amount;
        }

        return [
            'total' => $total,
            'original_total' => $originalTotal,
            'refund_deduction' => $refundDeduction
        ];
    }

    /**
     * GET /api/seller/my-transactions
     *
     * All transactions with filters, search, pagination, and summary.
     *
     * Query Params:
     *   - page            (int, default: 1)
     *   - per_page         (int, default: 15, max: 50)
     *   - type             (string: order_commission|credit|refund|withdrawal|debit|order_item)
     *   - payment_status   (string: paid|unpaid)
     *   - from_date        (date: Y-m-d)
     *   - to_date          (date: Y-m-d)
     *   - search           (string: searches order_id, item_name, message)
     *   - sort_by          (string: created_at|amount|paid_at, default: created_at)
     *   - sort_order       (string: asc|desc, default: desc)
     */
    public function index(Request $request)
    {
        $seller = $this->getAuthSeller('index');

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        Log::info("SellerTransactionApi [index]: Fetching all transactions", [
            'seller_id' => $seller->id,
            'filters' => $request->only(['type', 'payment_status', 'from_date', 'to_date', 'search', 'sort_by', 'sort_order', 'page', 'per_page']),
        ]);

        $perPage = min((int) ($request->input('per_page', 15)), 50);

        $query = SellerWalletTransaction::where('seller_id', $seller->id);

        // Type filter
        if ($request->filled('type')) {
            $query->where('type', $request->type);
            Log::info("SellerTransactionApi [index]: Type filter applied", ['seller_id' => $seller->id, 'type' => $request->type]);
        }

        // Payment status filter
        if ($request->filled('payment_status')) {
            if ($request->payment_status === 'paid') {
                $query->where('is_paid_to_seller', true);
            } elseif ($request->payment_status === 'unpaid') {
                $query->where('is_paid_to_seller', false);
            }
            Log::info("SellerTransactionApi [index]: Payment status filter applied", ['seller_id' => $seller->id, 'payment_status' => $request->payment_status]);
        }

        // Date range filter
        if ($request->filled('from_date')) {
            $query->whereDate('created_at', '>=', $request->from_date);
        }
        if ($request->filled('to_date')) {
            $query->whereDate('created_at', '<=', $request->to_date);
        }
        if ($request->filled('from_date') || $request->filled('to_date')) {
            Log::info("SellerTransactionApi [index]: Date filter applied", ['seller_id' => $seller->id, 'from_date' => $request->from_date, 'to_date' => $request->to_date]);
        }

        // Search
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('order_id', 'like', "%{$search}%")
                  ->orWhere('item_name', 'like', "%{$search}%")
                  ->orWhere('message', 'like', "%{$search}%");
            });
            Log::info("SellerTransactionApi [index]: Search applied", ['seller_id' => $seller->id, 'search' => $search]);
        }

        // Sorting
        $sortBy = in_array($request->input('sort_by'), ['created_at', 'amount', 'paid_at'])
            ? $request->input('sort_by')
            : 'created_at';
        $sortOrder = $request->input('sort_order') === 'asc' ? 'asc' : 'desc';
        $query->orderBy($sortBy, $sortOrder);

        // Summary (unfiltered for this seller)
        $summaryQuery = SellerWalletTransaction::where('seller_id', $seller->id);
        $creditTypes = $this->getCreditTypes();
        $debitTypes = $this->getDebitTypes();

        // Calculate earnings with refund deductions
        $earningsTransactions = (clone $summaryQuery)->whereIn('type', $creditTypes)->get();
        $earningsCalc = $this->calculatePayableAmount($earningsTransactions);
        $totalEarnings = $earningsCalc['total'];
        $totalEarningsRefundDeduction = $earningsCalc['refund_deduction'];

        // Calculate deductions
        $deductionsTransactions = (clone $summaryQuery)->whereIn('type', $debitTypes)->get();
        $totalDeductions = $deductionsTransactions->sum('amount');

        // Calculate paid amount with refund deductions
        $paidTransactions = (clone $summaryQuery)->whereIn('type', $creditTypes)->where('is_paid_to_seller', true)->get();
        $paidCalc = $this->calculatePayableAmount($paidTransactions);
        $paidAmount = $paidCalc['total'];
        $paidRefundDeduction = $paidCalc['refund_deduction'];

        // Calculate pending amount with refund deductions
        $pendingTransactions = (clone $summaryQuery)->whereIn('type', $creditTypes)->where('is_paid_to_seller', false)->get();
        $pendingCalc = $this->calculatePayableAmount($pendingTransactions);
        $pendingAmount = $pendingCalc['total'];
        $pendingRefundDeduction = $pendingCalc['refund_deduction'];

        $totalCommission = (clone $summaryQuery)->sum('admin_commission');

        Log::info("SellerTransactionApi [index]: Summary calculations completed", [
            'seller_id' => $seller->id,
            'earnings' => [
                'original' => $earningsCalc['original_total'],
                'refund_deduction' => $totalEarningsRefundDeduction,
                'final' => $totalEarnings
            ],
            'paid' => [
                'original' => $paidCalc['original_total'],
                'refund_deduction' => $paidRefundDeduction,
                'final' => $paidAmount
            ],
            'pending' => [
                'original' => $pendingCalc['original_total'],
                'refund_deduction' => $pendingRefundDeduction,
                'final' => $pendingAmount
            ],
            'deductions' => $totalDeductions,
            'commission' => $totalCommission
        ]);

        // Paginate
        $transactions = $query->paginate($perPage);

        $items = collect($transactions->items())->map(function ($t) {
            return $this->formatTransaction($t);
        });

        Log::info("SellerTransactionApi [index]: Transactions fetched successfully", [
            'seller_id' => $seller->id,
            'total_records' => $transactions->total(),
            'current_page' => $transactions->currentPage(),
            'per_page' => $perPage
        ]);

        return response()->json([
            'status' => 1,
            'message' => 'Transactions fetched successfully',
            'data' => [
                'transactions' => $items,
                'summary' => [
                    'current_balance' => round((float) ($seller->balance ?? 0), 2),
                    'total_earnings' => round((float) $totalEarnings, 2),
                    'total_deductions' => round((float) $totalDeductions, 2),
                    'net_earnings' => round((float) ($totalEarnings - $totalDeductions), 2),
                    'paid_amount' => round((float) $paidAmount, 2),
                    'pending_amount' => round((float) $pendingAmount, 2),
                    'admin_due_amount' => round((float) $pendingAmount, 2),
                    'total_commission' => round((float) $totalCommission, 2),
                ],
                'pagination' => [
                    'total' => $transactions->total(),
                    'per_page' => $transactions->perPage(),
                    'current_page' => $transactions->currentPage(),
                    'last_page' => $transactions->lastPage(),
                    'has_more' => $transactions->hasMorePages(),
                ],
            ],
        ]);
    }

    /**
     * GET /api/seller/my-transactions/paid
     *
     * Paid transactions only, with date filters and pagination.
     *
     * Query Params:
     *   - page       (int, default: 1)
     *   - per_page    (int, default: 15, max: 50)
     *   - from_date   (date: Y-m-d)
     *   - to_date     (date: Y-m-d)
     */
    public function paid(Request $request)
    {
        $seller = $this->getAuthSeller('paid');

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        Log::info("SellerTransactionApi [paid]: Fetching paid transactions", [
            'seller_id' => $seller->id,
            'filters' => $request->only(['from_date', 'to_date', 'page', 'per_page']),
        ]);

        $perPage = min((int) ($request->input('per_page', 15)), 50);

        $query = SellerWalletTransaction::where('seller_id', $seller->id)
            ->where('is_paid_to_seller', true)
            ->orderBy('paid_at', 'desc');

        if ($request->filled('from_date')) {
            $query->whereDate('paid_at', '>=', $request->from_date);
        }
        if ($request->filled('to_date')) {
            $query->whereDate('paid_at', '<=', $request->to_date);
        }

        // Summary - Calculate paid amount with refund deductions
        $allPaidTransactions = SellerWalletTransaction::where('seller_id', $seller->id)
            ->where('is_paid_to_seller', true)
            ->get();

        $paidCalc = $this->calculatePayableAmount($allPaidTransactions);
        $totalPaid = $paidCalc['total'];

        Log::info("SellerTransactionApi [paid]: Paid amount calculated", [
            'seller_id' => $seller->id,
            'original_paid' => $paidCalc['original_total'],
            'refund_deduction' => $paidCalc['refund_deduction'],
            'final_paid' => $totalPaid,
            'transactions_count' => $allPaidTransactions->count()
        ]);

        $transactions = $query->paginate($perPage);

        $items = collect($transactions->items())->map(function ($t) {
            return $this->formatTransaction($t);
        });

        Log::info("SellerTransactionApi [paid]: Paid transactions fetched successfully", [
            'seller_id' => $seller->id,
            'total_records' => $transactions->total(),
            'current_page' => $transactions->currentPage(),
            'total_paid' => $totalPaid,
        ]);

        return response()->json([
            'status' => 1,
            'message' => 'Paid transactions fetched successfully',
            'data' => [
                'transactions' => $items,
                'summary' => [
                    'total_paid' => round((float) $totalPaid, 2),
                ],
                'pagination' => [
                    'total' => $transactions->total(),
                    'per_page' => $transactions->perPage(),
                    'current_page' => $transactions->currentPage(),
                    'last_page' => $transactions->lastPage(),
                    'has_more' => $transactions->hasMorePages(),
                ],
            ],
        ]);
    }

    /**
     * GET /api/seller/my-transactions/unpaid
     *
     * Unpaid/pending transactions only.
     *
     * Query Params:
     *   - page       (int, default: 1)
     *   - per_page    (int, default: 15, max: 50)
     *   - from_date   (date: Y-m-d)
     *   - to_date     (date: Y-m-d)
     */
    public function unpaid(Request $request)
    {
        $seller = $this->getAuthSeller('unpaid');

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        Log::info("SellerTransactionApi [unpaid]: Fetching unpaid transactions", [
            'seller_id' => $seller->id,
            'filters' => $request->only(['from_date', 'to_date', 'page', 'per_page']),
        ]);

        $perPage = min((int) ($request->input('per_page', 15)), 50);

        $query = SellerWalletTransaction::where('seller_id', $seller->id)
            ->where('is_paid_to_seller', false)
            ->orderBy('created_at', 'desc');

        if ($request->filled('from_date')) {
            $query->whereDate('created_at', '>=', $request->from_date);
        }
        if ($request->filled('to_date')) {
            $query->whereDate('created_at', '<=', $request->to_date);
        }

        // Summary - Calculate pending amount with refund deductions
        $allUnpaidTransactions = SellerWalletTransaction::where('seller_id', $seller->id)
            ->where('is_paid_to_seller', false)
            ->get();

        $pendingCalc = $this->calculatePayableAmount($allUnpaidTransactions);
        $totalPending = $pendingCalc['total'];

        Log::info("SellerTransactionApi [unpaid]: Pending amount calculated", [
            'seller_id' => $seller->id,
            'original_pending' => $pendingCalc['original_total'],
            'refund_deduction' => $pendingCalc['refund_deduction'],
            'final_pending' => $totalPending,
            'transactions_count' => $allUnpaidTransactions->count()
        ]);

        $transactions = $query->paginate($perPage);

        $items = collect($transactions->items())->map(function ($t) {
            return $this->formatTransaction($t);
        });

        Log::info("SellerTransactionApi [unpaid]: Unpaid transactions fetched successfully", [
            'seller_id' => $seller->id,
            'total_records' => $transactions->total(),
            'current_page' => $transactions->currentPage(),
            'total_pending' => $totalPending,
        ]);

        return response()->json([
            'status' => 1,
            'message' => 'Unpaid transactions fetched successfully',
            'data' => [
                'transactions' => $items,
                'summary' => [
                    'total_pending' => round((float) $totalPending, 2),
                ],
                'pagination' => [
                    'total' => $transactions->total(),
                    'per_page' => $transactions->perPage(),
                    'current_page' => $transactions->currentPage(),
                    'last_page' => $transactions->lastPage(),
                    'has_more' => $transactions->hasMorePages(),
                ],
            ],
        ]);
    }

    /**
     * GET /api/seller/my-transactions/summary
     *
     * Overall transaction summary with today / this week / this month / all-time breakdowns.
     */
    public function summary(Request $request)
    {
        $seller = $this->getAuthSeller('summary');

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        Log::info("SellerTransactionApi [summary]: Fetching transaction summary", [
            'seller_id' => $seller->id,
        ]);

        $creditTypes = $this->getCreditTypes();
        $debitTypes = $this->getDebitTypes();

        $baseQuery = SellerWalletTransaction::where('seller_id', $seller->id);

        // All-time - Calculate with refund deductions
        $allEarningsTransactions = (clone $baseQuery)->whereIn('type', $creditTypes)->get();
        $earningsCalc = $this->calculatePayableAmount($allEarningsTransactions);
        $totalEarnings = $earningsCalc['total'];

        $allDeductionsTransactions = (clone $baseQuery)->whereIn('type', $debitTypes)->get();
        $totalDeductions = $allDeductionsTransactions->sum('amount');

        $allPaidTransactions = (clone $baseQuery)->where('is_paid_to_seller', true)->whereIn('type', $creditTypes)->get();
        $paidCalc = $this->calculatePayableAmount($allPaidTransactions);
        $totalPaid = $paidCalc['total'];

        $allPendingTransactions = (clone $baseQuery)->where('is_paid_to_seller', false)->whereIn('type', $creditTypes)->get();
        $pendingCalc = $this->calculatePayableAmount($allPendingTransactions);
        $totalPending = $pendingCalc['total'];

        $totalCommission = (clone $baseQuery)->sum('admin_commission');
        $totalTransactions = (clone $baseQuery)->count();

        // Today - Calculate with refund deductions
        $todayEarningsTransactions = (clone $baseQuery)->whereIn('type', $creditTypes)
            ->whereDate('created_at', Carbon::today())->get();
        $todayEarningsCalc = $this->calculatePayableAmount($todayEarningsTransactions);
        $todayEarnings = $todayEarningsCalc['total'];

        $todayTransactions = (clone $baseQuery)
            ->whereDate('created_at', Carbon::today())->count();

        // This week (Monday to Sunday) - Calculate with refund deductions
        $weekStart = Carbon::now()->startOfWeek();
        $weekEnd = Carbon::now()->endOfWeek();
        $weekEarningsTransactions = (clone $baseQuery)->whereIn('type', $creditTypes)
            ->whereBetween('created_at', [$weekStart, $weekEnd])->get();
        $weekEarningsCalc = $this->calculatePayableAmount($weekEarningsTransactions);
        $weekEarnings = $weekEarningsCalc['total'];

        $weekTransactions = (clone $baseQuery)
            ->whereBetween('created_at', [$weekStart, $weekEnd])->count();

        // This month - Calculate with refund deductions
        $monthStart = Carbon::now()->startOfMonth();
        $monthEnd = Carbon::now()->endOfMonth();
        $monthEarningsTransactions = (clone $baseQuery)->whereIn('type', $creditTypes)
            ->whereBetween('created_at', [$monthStart, $monthEnd])->get();
        $monthEarningsCalc = $this->calculatePayableAmount($monthEarningsTransactions);
        $monthEarnings = $monthEarningsCalc['total'];

        $monthTransactions = (clone $baseQuery)
            ->whereBetween('created_at', [$monthStart, $monthEnd])->count();

        Log::info("SellerTransactionApi [summary]: Summary calculations completed", [
            'seller_id' => $seller->id,
            'all_time' => [
                'earnings_original' => $earningsCalc['original_total'],
                'earnings_refund_deduction' => $earningsCalc['refund_deduction'],
                'earnings_final' => $totalEarnings,
                'paid_original' => $paidCalc['original_total'],
                'paid_refund_deduction' => $paidCalc['refund_deduction'],
                'paid_final' => $totalPaid,
                'pending_original' => $pendingCalc['original_total'],
                'pending_refund_deduction' => $pendingCalc['refund_deduction'],
                'pending_final' => $totalPending,
                'deductions' => $totalDeductions,
                'commission' => $totalCommission,
                'transactions_count' => $totalTransactions
            ],
            'today' => [
                'earnings_original' => $todayEarningsCalc['original_total'],
                'earnings_refund_deduction' => $todayEarningsCalc['refund_deduction'],
                'earnings_final' => $todayEarnings,
                'transactions_count' => $todayTransactions
            ],
            'this_week' => [
                'earnings_original' => $weekEarningsCalc['original_total'],
                'earnings_refund_deduction' => $weekEarningsCalc['refund_deduction'],
                'earnings_final' => $weekEarnings,
                'transactions_count' => $weekTransactions
            ],
            'this_month' => [
                'earnings_original' => $monthEarningsCalc['original_total'],
                'earnings_refund_deduction' => $monthEarningsCalc['refund_deduction'],
                'earnings_final' => $monthEarnings,
                'transactions_count' => $monthTransactions
            ],
            'current_balance' => $seller->balance ?? 0
        ]);

        return response()->json([
            'status' => 1,
            'message' => 'Transaction summary fetched successfully',
            'data' => [
                'all_time' => [
                    'total_earnings' => round((float) $totalEarnings, 2),
                    'total_deductions' => round((float) $totalDeductions, 2),
                    'net_earnings' => round((float) ($totalEarnings - $totalDeductions), 2),
                    'total_paid' => round((float) $totalPaid, 2),
                    'total_pending' => round((float) $totalPending, 2),
                    'admin_due_amount' => round((float) $totalPending, 2),
                    'total_commission' => round((float) $totalCommission, 2),
                    'total_transactions' => (int) $totalTransactions,
                ],
                'today' => [
                    'earnings' => round((float) $todayEarnings, 2),
                    'transactions_count' => (int) $todayTransactions,
                ],
                'this_week' => [
                    'earnings' => round((float) $weekEarnings, 2),
                    'transactions_count' => (int) $weekTransactions,
                    'week_start' => $weekStart->format('Y-m-d'),
                    'week_end' => $weekEnd->format('Y-m-d'),
                ],
                'this_month' => [
                    'earnings' => round((float) $monthEarnings, 2),
                    'transactions_count' => (int) $monthTransactions,
                    'month' => Carbon::now()->format('F Y'),
                ],
                'current_balance' => round((float) ($seller->balance ?? 0), 2),
            ],
        ]);
    }

    /**
     * GET /api/seller/my-transactions/weekly
     *
     * Weekly payment breakdown with navigation (prev/next week).
     *
     * Query Params:
     *   - week_offset  (int, default: 0, 0=current, -1=last week, etc.)
     *   - per_page      (int, default: 15, max: 50)
     *   - page          (int, default: 1)
     */
    public function weekly(Request $request)
    {
        $seller = $this->getAuthSeller('weekly');

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        $weekOffset = (int) $request->input('week_offset', 0);
        $perPage = min((int) ($request->input('per_page', 15)), 50);

        // Calculate week start (Monday) and end (Sunday)
        $today = Carbon::now();
        $dayOfWeek = $today->dayOfWeek; // 0 = Sunday, 1 = Monday
        $daysToMonday = $dayOfWeek === 0 ? 6 : $dayOfWeek - 1;

        $weekStart = $today->copy()->subDays($daysToMonday)->addWeeks($weekOffset)->startOfDay();
        $weekEnd = $weekStart->copy()->addDays(6)->endOfDay();

        Log::info("SellerTransactionApi [weekly]: Fetching weekly transactions", [
            'seller_id' => $seller->id,
            'week_offset' => $weekOffset,
            'week_start' => $weekStart->format('Y-m-d'),
            'week_end' => $weekEnd->format('Y-m-d'),
            'page' => $request->input('page', 1),
            'per_page' => $perPage,
        ]);

        // Week query
        $weekQuery = SellerWalletTransaction::where('seller_id', $seller->id)
            ->whereBetween('created_at', [$weekStart, $weekEnd]);

        // Orders count (unique order_ids)
        $ordersCount = (clone $weekQuery)->whereNotNull('order_id')
            ->distinct('order_id')->count('order_id');

        // Calculate paid amount with refund deductions
        $paidTransactions = (clone $weekQuery)->where('is_paid_to_seller', true)->get();
        $paidCalc = $this->calculatePayableAmount($paidTransactions);
        $paidAmount = $paidCalc['total'];

        // Calculate unpaid amount with refund deductions
        $unpaidTransactions = (clone $weekQuery)->where('is_paid_to_seller', false)->get();
        $unpaidCalc = $this->calculatePayableAmount($unpaidTransactions);
        $unpaidAmount = $unpaidCalc['total'];

        // Calculate total earnings with refund deductions (credit types)
        $creditTypes = $this->getCreditTypes();
        $earningsTransactions = (clone $weekQuery)->whereIn('type', $creditTypes)->get();
        $earningsCalc = $this->calculatePayableAmount($earningsTransactions);
        $totalEarnings = $earningsCalc['total'];

        // Commission
        $totalCommission = (clone $weekQuery)->sum('admin_commission');

        Log::info("SellerTransactionApi [weekly]: Weekly calculations completed", [
            'seller_id' => $seller->id,
            'week_start' => $weekStart->format('Y-m-d'),
            'week_end' => $weekEnd->format('Y-m-d'),
            'orders_count' => $ordersCount,
            'earnings' => [
                'original' => $earningsCalc['original_total'],
                'refund_deduction' => $earningsCalc['refund_deduction'],
                'final' => $totalEarnings
            ],
            'paid' => [
                'original' => $paidCalc['original_total'],
                'refund_deduction' => $paidCalc['refund_deduction'],
                'final' => $paidAmount
            ],
            'unpaid' => [
                'original' => $unpaidCalc['original_total'],
                'refund_deduction' => $unpaidCalc['refund_deduction'],
                'final' => $unpaidAmount
            ],
            'commission' => $totalCommission
        ]);

        // Transactions list with pagination
        $transactions = (clone $weekQuery)->orderBy('created_at', 'desc')->paginate($perPage);

        $items = collect($transactions->items())->map(function ($t) {
            return $this->formatTransaction($t);
        });

        Log::info("SellerTransactionApi [weekly]: Weekly transactions fetched successfully", [
            'seller_id' => $seller->id,
            'week_start' => $weekStart->format('Y-m-d'),
            'week_end' => $weekEnd->format('Y-m-d'),
            'total_records' => $transactions->total(),
            'current_page' => $transactions->currentPage()
        ]);

        return response()->json([
            'status' => 1,
            'message' => 'Weekly transactions fetched successfully',
            'data' => [
                'week_start' => $weekStart->format('Y-m-d'),
                'week_end' => $weekEnd->format('Y-m-d'),
                'week_label' => $weekStart->format('d M') . ' - ' . $weekEnd->format('d M, Y'),
                'orders_count' => (int) $ordersCount,
                'total_earnings' => round((float) $totalEarnings, 2),
                'paid_amount' => round((float) $paidAmount, 2),
                'unpaid_amount' => round((float) $unpaidAmount, 2),
                'total_commission' => round((float) $totalCommission, 2),
                'transactions' => $items,
                'pagination' => [
                    'total' => $transactions->total(),
                    'per_page' => $transactions->perPage(),
                    'current_page' => $transactions->currentPage(),
                    'last_page' => $transactions->lastPage(),
                    'has_more' => $transactions->hasMorePages(),
                ],
            ],
        ]);
    }

    /**
     * GET /api/seller/my-transactions/{id}
     *
     * Single transaction details.
     */
    public function show($id)
    {
        $seller = $this->getAuthSeller('show');

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        Log::info("SellerTransactionApi [show]: Fetching transaction detail", [
            'seller_id' => $seller->id,
            'transaction_id' => $id,
        ]);

        $transaction = SellerWalletTransaction::where('seller_id', $seller->id)
            ->where('id', $id)
            ->first();

        if (!$transaction) {
            Log::warning("SellerTransactionApi [show]: Transaction not found", [
                'seller_id' => $seller->id,
                'transaction_id' => $id,
            ]);
            return CommonHelper::responseError("Transaction not found.");
        }

        // Calculate payable amount for logging
        $amount = (float) $transaction->amount;
        $refundableAmount = (float) ($transaction->refundable_amount ?? 0);
        $payableAmount = $amount;
        if ($transaction->is_refunded_to_customer && $refundableAmount > 0) {
            $payableAmount = max(0, $amount - $refundableAmount);
        }

        Log::info("SellerTransactionApi [show]: Transaction found", [
            'seller_id' => $seller->id,
            'transaction_id' => $transaction->id,
            'type' => $transaction->type,
            'amount' => $amount,
            'is_refunded_to_customer' => (bool) $transaction->is_refunded_to_customer,
            'refundable_amount' => $refundableAmount,
            'payable_amount' => $payableAmount,
            'is_paid' => $transaction->is_paid_to_seller,
            'order_id' => $transaction->order_id,
        ]);

        return response()->json([
            'status' => 1,
            'message' => 'Transaction details fetched successfully',
            'data' => $this->formatTransaction($transaction, true),
        ]);
    }

    /**
     * Format a single transaction for API response
     *
     * @param SellerWalletTransaction $t
     * @param bool $detailed  Include extra fields for single-view
     */
    private function formatTransaction(SellerWalletTransaction $t, bool $detailed = false): array
    {
        $creditTypes = $this->getCreditTypes();
        $isCredit = in_array($t->type, $creditTypes);

        // Calculate payable amount (amount - refundable_amount if refund applied)
        $amount = (float) $t->amount;
        $refundableAmount = (float) ($t->refundable_amount ?? 0);
        $isRefunded = (bool) $t->is_refunded_to_customer;

        // Seller's payable floors at 0: they lose at most their own net earning,
        // the platform absorbs the rest of a gross refund. This mirrors the
        // clamped balance_after so the two screens agree.
        $payableAmount = $amount;
        if ($isRefunded && $refundableAmount > 0) {
            $payableAmount = max(0, $amount - $refundableAmount);
        }

        // Sign is derived from the actual payable value (defensive: payable is
        // already floored at 0 above, so this never yields strings like "+-38.00").
        $payableSign = $payableAmount < 0 ? '-' : ($isCredit ? '+' : '-');

        $data = [
            'id' => $t->id,
            'order_id' => $t->order_id,
            'order_item_id' => $t->order_item_id,
            'item_name' => $t->item_name,
            'type' => $t->type,
            'type_label' => $this->getTypeLabel($t->type),
            'is_credit' => $isCredit,
            'amount' => round($amount, 2),
            'payable_amount' => round($payableAmount, 2),
            'formatted_amount' => ($isCredit ? '+' : '-') . number_format($amount, 2),
            'formatted_payable_amount' => $payableSign . number_format(abs($payableAmount), 2),
            'admin_commission' => round((float) ($t->admin_commission ?? 0), 2),
            'vendor_wait_charge' => round((float) ($t->vendor_wait_charge ?? 0), 2),
            'message' => $t->message,
            'is_paid_to_seller' => (bool) $t->is_paid_to_seller,
            'payment_status' => $t->is_paid_to_seller ? 'paid' : 'unpaid',
            'paid_at' => $t->paid_at ? Carbon::parse($t->paid_at)->format('Y-m-d H:i:s') : null,
            'payment_transaction_id' => $t->payment_transaction_id,
            'is_refunded_to_customer' => $isRefunded,
            'refundable_amount' => round($refundableAmount, 2),
            'created_at' => $t->created_at ? $t->created_at->format('Y-m-d H:i:s') : null,
        ];

        // Settlement breakdown (same shape as the order details screen) so the
        // app can show Product Amount / Commission / GST / Gateway Fees / Net.
        $settlementInfo = $this->buildSettlementInfo($t, $amount);
        if ($settlementInfo !== null) {
            $data['settlement_info'] = $settlementInfo;
        }

        if ($detailed) {
            $data['balance_before'] = round((float) ($t->balance_before ?? 0), 2);
            $data['balance_after'] = round((float) ($t->balance_after ?? 0), 2);
            $data['reference_type'] = $t->reference_type;
            $data['reference_id'] = $t->reference_id;
            $data['products_json'] = $t->products_json;
            $data['updated_at'] = $t->updated_at ? $t->updated_at->format('Y-m-d H:i:s') : null;

            Log::info("SellerTransactionApi [formatTransaction]: Detailed transaction formatted", [
                'transaction_id' => $t->id,
                'amount' => $amount,
                'is_refunded' => $isRefunded,
                'refundable_amount' => $refundableAmount,
                'payable_amount' => $payableAmount,
                'type' => $t->type,
                'is_paid' => $t->is_paid_to_seller
            ]);
        }

        return $data;
    }

    /**
     * Build the per-transaction settlement breakdown.
     *
     * Mirrors the breakdown shown on the seller order-details screen
     * (see SellerEarningsController) but scoped to a single wallet
     * transaction. Returns null when the transaction has no product data
     * (e.g. withdrawals/manual credits), so the app can simply skip it.
     *
     * @param float $netAmount  Net seller amount (commission/fees already deducted)
     * @return array<int, array{label: string, value: mixed}>|null
     */
    private function buildSettlementInfo(SellerWalletTransaction $t, float $netAmount): ?array
    {
        $products = $t->products_json;
        if (empty($products) || !is_array($products)) {
            return null;
        }

        $totalProductAmount = 0;
        $totalGst = 0;
        foreach ($products as $p) {
            $totalProductAmount += floatval($p['total_amount'] ?? 0);
            $totalGst += floatval($p['gst'] ?? 0);
        }

        if ($totalProductAmount <= 0) {
            return null;
        }

        $totalCommission = floatval($t->admin_commission ?? 0);
        $gstPercentage = floatval($t->gst_percentage ?? 0);
        $totalPaymentGatewayFees = floatval($t->payment_gateway_fees ?? 0);
        $vendorWaitCharge = floatval($t->vendor_wait_charge ?? 0);

        // Derive commission % from the actually-deducted commission against the
        // real product total, so the label stays correct even if the admin
        // later changes the configured commission rate.
        $commissionPercentage = round(($totalCommission / $totalProductAmount) * 100, 2);

        $paymentGatewayFeesPercent = floatval(
            \DB::table('settings')->where('variable', 'payment_gateway_fees')->value('value') ?? 0
        );

        $breakdown = [
            ['label' => 'Total Product Amount', 'value' => round($totalProductAmount, 2)],
            ['label' => 'Admin Commission (' . round($commissionPercentage, 2) . '%)', 'value' => round($totalCommission, 2)],
            ['label' => 'GST (' . round($gstPercentage, 2) . '%)', 'value' => round($totalGst, 2)],
            ['label' => 'Payment Gateway Fees (' . round($paymentGatewayFeesPercent, 2) . '%)', 'value' => round($totalPaymentGatewayFees, 2)],
        ];

        if ($vendorWaitCharge > 0) {
            $breakdown[] = ['label' => 'Vendor Waiting Charge', 'value' => round($vendorWaitCharge, 2)];
        }

        $breakdown[] = ['label' => 'Net Seller Amount', 'value' => round($netAmount, 2)];
        $breakdown[] = ['label' => 'Payment Status', 'value' => $t->is_paid_to_seller ? 'Paid' : 'Pending'];

        return $breakdown;
    }

    /**
     * Human-readable type label
     */
    private function getTypeLabel(string $type): string
    {
        $labels = [
            'order_commission' => 'Order Earning',
            'credit' => 'Credit',
            'refund' => 'Refund',
            'withdrawal' => 'Withdrawal',
            'debit' => 'Debit',
            'order_item' => 'Order Item',
            'adjustment' => 'Adjustment',
        ];

        return $labels[$type] ?? ucfirst(str_replace('_', ' ', $type));
    }
}
