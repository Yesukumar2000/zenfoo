<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Seller;
use App\Models\SellerWalletTransaction;
use App\Services\SellerNotificationService;
use App\Services\SellerRazorpayPayoutService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class SellerTransactionsController extends Controller
{
    /**
     * Get transactions for a specific seller
     */
    public function index(Request $request, $sellerId)
    {
        // Verify seller exists
        $seller = Seller::find($sellerId);

        if (!$seller) {
            return response()->json([
                'success' => false,
                'message' => 'Seller not found'
            ], 404);
        }

        

        $query = SellerWalletTransaction::with('orderItem')
            ->where('seller_id', $sellerId)
            ->orderBy('created_at', 'desc');

        // Apply filters
        if ($request->filled('from_date')) {
            $query->whereDate('created_at', '>=', $request->from_date);
        }

        if ($request->filled('to_date')) {
            $query->whereDate('created_at', '<=', $request->to_date);
        }

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        if ($request->filled('payment_status')) {
            if ($request->payment_status === 'paid') {
                $query->where('is_paid_to_seller', true);
            } elseif ($request->payment_status === 'unpaid') {
                $query->where('is_paid_to_seller', false);
            }
        }

        // Get summary data
        $summaryQuery = SellerWalletTransaction::where('seller_id', $sellerId);

        // Credit types: order_commission, credit, refund (money coming in)
        $creditTypes = ['order_commission', 'credit', 'refund'];
        // Debit types: withdrawal, debit, commission (money going out)
        $debitTypes = ['withdrawal', 'debit'];

        $totalEarnings = (clone $summaryQuery)->whereIn('type', $creditTypes)->sum('amount');
        $totalDeductions = (clone $summaryQuery)->whereIn('type', $debitTypes)->sum('amount');
        $paidAmount = (clone $summaryQuery)->whereIn('type', $creditTypes)->where('is_paid_to_seller', true)->sum('amount');
        $pendingAmount = (clone $summaryQuery)->whereIn('type', $creditTypes)->where('is_paid_to_seller', false)->sum('amount');
        $totalCommission = (clone $summaryQuery)->sum('admin_commission');

        $summary = [
            'total_earnings' => (float) $totalEarnings - (float) $totalDeductions,
            'paid_amount' => (float) $paidAmount,
            'pending_amount' => (float) $pendingAmount,
            'total_commission' => (float) $totalCommission
        ];

        // Paginate results
        $perPage = $request->input('per_page', 15);
        $transactions = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $transactions,
            'summary' => $summary
        ]);
    }

    /**
     * Mark transactions as paid
     */
    public function markAsPaid(Request $request, $sellerId)
    {
        $request->validate([
            'transaction_ids' => 'required|array',
            'transaction_ids.*' => 'exists:seller_wallet_transactions,id',
            'payment_transaction_id' => 'nullable|string|max:255'
        ]);

        $updated = SellerWalletTransaction::where('seller_id', $sellerId)
            ->whereIn('id', $request->transaction_ids)
            ->where('is_paid_to_seller', false)
            ->update([
                'is_paid_to_seller' => true,
                'payment_transaction_id' => $request->payment_transaction_id,
                'paid_at' => now(),
                'paid_by' => auth()->id()
            ]);

        return response()->json([
            'success' => true,
            'message' => "{$updated} transaction(s) marked as paid"
        ]);
    }

    /**
     * Get transaction details
     */
    public function show($sellerId, $transactionId)
    {
        $transaction = SellerWalletTransaction::where('seller_id', $sellerId)
            ->where('id', $transactionId)
            ->first();

        if (!$transaction) {
            return response()->json([
                'success' => false,
                'message' => 'Transaction not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $transaction
        ]);
    }

    /**
     * Get paid transactions for a specific seller
     */
    public function paid(Request $request, $sellerId)
    {
        $seller = Seller::find($sellerId);

        if (!$seller) {
            return response()->json([
                'success' => false,
                'message' => 'Seller not found'
            ], 404);
        }

        $query = SellerWalletTransaction::with('orderItem')
            ->where('seller_id', $sellerId)
            ->where('is_paid_to_seller', true)
            ->orderBy('paid_at', 'desc');

        // Apply filters
        if ($request->filled('from_date')) {
            $query->whereDate('paid_at', '>=', $request->from_date);
        }

        if ($request->filled('to_date')) {
            $query->whereDate('paid_at', '<=', $request->to_date);
        }

        // Get summary
        $totalPaid = SellerWalletTransaction::where('seller_id', $sellerId)
            ->where('is_paid_to_seller', true)
            ->sum('amount');

        $summary = [
            'total_paid' => (float) $totalPaid
        ];

        $perPage = $request->input('per_page', 15);
        $transactions = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $transactions,
            'summary' => $summary
        ]);
    }

    /**
     * Get unpaid/pending transactions for a specific seller (need to pay)
     */
    public function needToPay(Request $request, $sellerId)
    {
        $seller = Seller::find($sellerId);

        if (!$seller) {
            return response()->json([
                'success' => false,
                'message' => 'Seller not found'
            ], 404);
        }

        $query = SellerWalletTransaction::with('orderItem')
            ->where('seller_id', $sellerId)
            ->where('is_paid_to_seller', false)
            ->orderBy('created_at', 'desc');

        // Apply filters
        if ($request->filled('from_date')) {
            $query->whereDate('created_at', '>=', $request->from_date);
        }

        if ($request->filled('to_date')) {
            $query->whereDate('created_at', '<=', $request->to_date);
        }

        // Get summary
        $totalPending = SellerWalletTransaction::where('seller_id', $sellerId)
            ->where('is_paid_to_seller', false)
            ->sum('amount');

        $summary = [
            'total_pending' => (float) $totalPending
        ];

        $perPage = $request->input('per_page', 15);
        $transactions = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $transactions,
            'summary' => $summary
        ]);
    }

    /**
     * Get weekly payment summary for a specific seller
     * Shows orders count, paid amount, and need to pay amount for a given week
     */
    public function weeklyPayment(Request $request, $sellerId)
    {
        $seller = Seller::find($sellerId);

        if (!$seller) {
            return response()->json([
                'success' => false,
                'message' => 'Seller not found'
            ], 404);
        }

        // Get week offset from request (0 = current week, -1 = last week, etc.)
        $weekOffset = (int) $request->input('week_offset', 0);

        // Calculate week start (Monday) and end (Sunday)
        $today = now();
        $dayOfWeek = $today->dayOfWeek; // 0 = Sunday, 1 = Monday, ...
        $daysToMonday = $dayOfWeek === 0 ? 6 : $dayOfWeek - 1;

        $weekStart = $today->copy()->subDays($daysToMonday)->addWeeks($weekOffset)->startOfDay();
        $weekEnd = $weekStart->copy()->addDays(6)->endOfDay();

        // Query transactions for the week
        $weekQuery = SellerWalletTransaction::with('orderItem')
            ->where('seller_id', $sellerId)
            ->whereBetween('created_at', [$weekStart, $weekEnd]);

        // Orders count (unique order_ids)
        $ordersCount = (clone $weekQuery)->whereNotNull('order_id')->distinct('order_id')->count('order_id');

        // Paid amount (is_paid_to_seller = 1)
        $paidAmount = (clone $weekQuery)->where('is_paid_to_seller', 1)->sum('amount');

        // Get unpaid transactions for calculation
        $unpaidTransactionsForCalc = (clone $weekQuery)->where('is_paid_to_seller', 0)->get();

        Log::info("Weekly Payout: Starting calculation", [
            'seller_id' => $sellerId,
            'week_start' => $weekStart->format('Y-m-d'),
            'week_end' => $weekEnd->format('Y-m-d'),
            'unpaid_transactions_count' => $unpaidTransactionsForCalc->count()
        ]);

        // Calculate need to pay: Use amount, subtract refundable_amount if refund was applied
        $needToPayAmount = 0;
        $originalTotalAmount = 0;
        $refundDeduction = 0;
        $refundedTransactions = [];

        foreach ($unpaidTransactionsForCalc as $transaction) {
            $transactionAmount = (float) $transaction->amount;
            $originalTotalAmount += $transactionAmount;

            // If refund already applied to this specific transaction, subtract it
            if ($transaction->is_refunded_to_customer && $transaction->refundable_amount > 0) {
                $refundAmount = (float) $transaction->refundable_amount;
                $transactionAmount -= $refundAmount;
                $refundDeduction += $refundAmount;

                $refundedTransactions[] = [
                    'transaction_id' => $transaction->id,
                    'order_id' => $transaction->order_id,
                    'original_amount' => (float) $transaction->amount,
                    'refund_amount' => $refundAmount,
                    'payable_amount' => $transactionAmount
                ];

                Log::info("Weekly Payout: Refund found on transaction", [
                    'seller_id' => $sellerId,
                    'transaction_id' => $transaction->id,
                    'order_id' => $transaction->order_id,
                    'original_amount' => (float) $transaction->amount,
                    'refund_amount' => $refundAmount,
                    'payable_amount' => $transactionAmount
                ]);
            }

            $needToPayAmount += $transactionAmount;
        }

        Log::info("Weekly Payout: Calculation completed", [
            'seller_id' => $sellerId,
            'week_start' => $weekStart->format('Y-m-d'),
            'week_end' => $weekEnd->format('Y-m-d'),
            'original_total' => $originalTotalAmount,
            'refund_deduction' => $refundDeduction,
            'final_need_to_pay' => $needToPayAmount,
            'refunded_transactions_count' => count($refundedTransactions),
            'refunded_transactions' => $refundedTransactions
        ]);

        // Get transactions list with pagination
        $perPage = $request->input('per_page', 15);
        $transactions = (clone $weekQuery)->orderBy('created_at', 'desc')->paginate($perPage);

        // Get all unpaid transactions for the week (for payment modal)
        $unpaidTransactions = (clone $weekQuery)->where('is_paid_to_seller', 0)->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => [
                'week_start' => $weekStart->format('Y-m-d'),
                'week_end' => $weekEnd->format('Y-m-d'),
                'orders_count' => (int) $ordersCount,
                'paid_amount' => (float) $paidAmount,
                'need_to_pay' => (float) $needToPayAmount,
                'refund_deduction' => (float) $refundDeduction
            ],
            'transactions' => $transactions,
            'unpaid_transactions' => $unpaidTransactions
        ]);
    }

    /**
     * Get seller's bank details for payout verification
     */
    public function getBankDetails($sellerId)
    {
        try {
            $seller = Seller::find($sellerId);

            if (!$seller) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seller not found'
                ], 404);
            }

            $bankDetails = SellerRazorpayPayoutService::getSellerBankDetails($sellerId);

            if (!$bankDetails['success']) {
                return response()->json([
                    'success' => false,
                    'message' => $bankDetails['error']
                ], 400);
            }

            // Mask account number for display
            $accountNumber = $bankDetails['data']['account_number'];
            $maskedAccount = str_repeat('*', strlen($accountNumber) - 4) . substr($accountNumber, -4);

            return response()->json([
                'success' => true,
                'data' => [
                    'bank_name' => $bankDetails['data']['bank_name'],
                    'account_holder_name' => $bankDetails['data']['account_holder_name'],
                    'account_number_masked' => $maskedAccount,
                    'ifsc_code' => $bankDetails['data']['ifsc_code'],
                    'is_verified' => $bankDetails['data']['is_verified'] ?? false
                ]
            ]);

        } catch (\Exception $e) {
            Log::error("Get Seller Bank Details Error: ", [
                'seller_id' => $sellerId,
                'message' => $e->getMessage()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch bank details'
            ], 500);
        }
    }

    /**
     * Process payout settlement for selected transactions
     * Uses PhonePe payout API to transfer funds to seller's bank account
     */
    public function settlePayouts(Request $request, $sellerId)
    {
        try {
            Log::info('Seller Settle Payouts: Request received', [
                'seller_id' => $sellerId,
                'request_data' => $request->all()
            ]);

            $seller = Seller::find($sellerId);

            if (!$seller) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seller not found'
                ], 404);
            }

            // Validate request
            $validator = Validator::make($request->all(), [
                'transaction_ids' => 'required|array|min:1',
                'transaction_ids.*' => 'required|integer|exists:seller_wallet_transactions,id',
                'total_amount' => 'required|numeric|min:0.01'
            ], [
                'transaction_ids.required' => 'Please select at least one transaction to settle.',
                'transaction_ids.array' => 'Invalid transaction selection.',
                'transaction_ids.min' => 'Please select at least one transaction.',
                'total_amount.required' => 'Total amount is required.',
                'total_amount.min' => 'Amount must be greater than zero.'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => $validator->errors()->first()
                ], 422);
            }

            $transactionIds = $request->transaction_ids;
            $totalAmount = (float) $request->total_amount;

            // Verify transactions belong to this seller and are unpaid
            $validTransactions = SellerWalletTransaction::whereIn('id', $transactionIds)
                ->where('seller_id', $sellerId)
                ->where('is_paid_to_seller', false)
                ->get();

            if ($validTransactions->count() !== count($transactionIds)) {
                Log::warning('Seller Settle Payouts: Invalid transactions detected', [
                    'seller_id' => $sellerId,
                    'requested_ids' => $transactionIds,
                    'valid_count' => $validTransactions->count()
                ]);
                return response()->json([
                    'success' => false,
                    'message' => 'Some transactions are invalid or already paid.'
                ], 400);
            }

            // Verify total amount matches
            $calculatedAmount = $validTransactions->sum('amount');
            if (abs($calculatedAmount - $totalAmount) > 0.01) {
                Log::warning('Seller Settle Payouts: Amount mismatch', [
                    'seller_id' => $sellerId,
                    'calculated_amount' => $calculatedAmount,
                    'requested_amount' => $totalAmount
                ]);
                return response()->json([
                    'success' => false,
                    'message' => 'Amount mismatch. Please refresh and try again.'
                ], 400);
            }

            // Get order_ids from the selected transactions
            $orderIds = $validTransactions->pluck('order_id')->filter()->unique()->values()->toArray();

            // Calculate refundable amount to deduct from accepted returns
            $refundDeduction = 0;
            $refundDetails = [];

            if (!empty($orderIds)) {
                // Get report_ids from customer_item_missing_reports that match the order_ids
                $reportIds = DB::table('customer_item_missing_reports')
                    ->whereIn('order_id', $orderIds)
                    ->pluck('id')
                    ->toArray();

                if (!empty($reportIds)) {
                    // Get accepted returns for this seller with matching report_ids
                    $acceptedReturns = DB::table('customer_issue_report_returns')
                        ->where('seller_id', $sellerId)
                        ->where('is_return_accepted', 1)
                        ->whereIn('report_id', $reportIds)
                        ->whereNull('is_deducted_from_payout') // Only get returns not yet deducted
                        ->get();

                    foreach ($acceptedReturns as $return) {
                        $refundAmount = (float) ($return->refundable_amount ?? 0);
                        if ($refundAmount > 0) {
                            $refundDeduction += $refundAmount;
                            $refundDetails[] = [
                                'return_id' => $return->id,
                                'report_id' => $return->report_id,
                                'refundable_amount' => $refundAmount
                            ];
                        }
                    }
                }
            }

            // Calculate final payout amount after deduction
            $finalPayoutAmount = $totalAmount - $refundDeduction;

            Log::info('Seller Settle Payouts: Refund deduction calculated', [
                'seller_id' => $sellerId,
                'original_amount' => $totalAmount,
                'refund_deduction' => $refundDeduction,
                'final_payout_amount' => $finalPayoutAmount,
                'refund_details' => $refundDetails
            ]);

            // Ensure final amount is not negative
            if ($finalPayoutAmount <= 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'Payout amount after refund deduction is zero or negative. Total refunds: Rs. ' . number_format($refundDeduction, 2)
                ], 400);
            }

            // Process payout via RazorpayX with the final amount after deduction
            $payoutResult = SellerRazorpayPayoutService::processPayoutToSeller(
                $sellerId,
                $transactionIds,
                $finalPayoutAmount
            );

            // Mark the returns as deducted if payout is successful
            if ($payoutResult['success'] && !empty($refundDetails)) {
                $returnIds = array_column($refundDetails, 'return_id');
                DB::table('customer_issue_report_returns')
                    ->whereIn('id', $returnIds)
                    ->update([
                        'is_deducted_from_payout' => 1,
                        'deducted_at' => now(),
                        'updated_at' => now()
                    ]);

                // Update the message column in transactions to include refund deduction info
                // Group refund amounts by order_id for clear messaging
                $refundByOrder = [];
                foreach ($refundDetails as $detail) {
                    // Get order_id from the report
                    $report = DB::table('customer_item_missing_reports')
                        ->where('id', $detail['report_id'])
                        ->first();
                    if ($report) {
                        $orderId = $report->order_id;
                        if (!isset($refundByOrder[$orderId])) {
                            $refundByOrder[$orderId] = 0;
                        }
                        $refundByOrder[$orderId] += $detail['refundable_amount'];
                    }
                }

                // Update message for each transaction that has a refund deduction
                foreach ($validTransactions as $transaction) {
                    if (isset($refundByOrder[$transaction->order_id])) {
                        $deductedAmount = $refundByOrder[$transaction->order_id];
                        $formattedDeduction = number_format($deductedAmount, 2);

                        // Append refund deduction info to existing message
                        $currentMessage = $transaction->message ?? '';
                        $refundMessage = " | Refund deducted: Rs. {$formattedDeduction} (Customer return accepted)";
                        $newMessage = $currentMessage . $refundMessage;

                        SellerWalletTransaction::where('id', $transaction->id)
                            ->update(['message' => $newMessage]);
                    }
                }
            }

            if (!$payoutResult['success']) {
                Log::error('Seller Settle Payouts: Payout failed', [
                    'seller_id' => $sellerId,
                    'error' => $payoutResult['error']
                ]);
                return response()->json([
                    'success' => false,
                    'message' => $payoutResult['error']
                ], 400);
            }

            Log::info('Seller Settle Payouts: Payout initiated successfully', [
                'seller_id' => $sellerId,
                'original_amount' => $totalAmount,
                'refund_deduction' => $refundDeduction,
                'final_amount' => $finalPayoutAmount,
                'transaction_count' => count($transactionIds),
                'payout_data' => $payoutResult['data'] ?? []
            ]);

            // Send notification to seller about the payout
            try {
                $formattedAmount = number_format($finalPayoutAmount, 2);
                $notificationMessage = "Rs. {$formattedAmount} has been settled to your bank account by admin.";
                if ($refundDeduction > 0) {
                    $formattedDeduction = number_format($refundDeduction, 2);
                    $notificationMessage .= " (Rs. {$formattedDeduction} deducted for customer refunds)";
                }
                SellerNotificationService::send(
                    (int) $sellerId,
                    'Payment Received',
                    $notificationMessage,
                    '',
                    'wallet',
                    null,
                    [
                        'payout_transaction_id' => $payoutResult['data']['payout_transaction_id'] ?? null,
                        'original_amount' => $totalAmount,
                        'refund_deduction' => $refundDeduction,
                        'final_amount' => $finalPayoutAmount
                    ]
                );
            } catch (\Exception $notificationException) {
                Log::warning('Seller Settle Payouts: Failed to send notification', [
                    'seller_id' => $sellerId,
                    'error' => $notificationException->getMessage()
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => $refundDeduction > 0
                    ? 'Payout initiated successfully with refund deduction applied'
                    : 'Payout initiated successfully',
                'data' => [
                    'payout_transaction_id' => $payoutResult['data']['payout_transaction_id'] ?? null,
                    'original_amount' => $totalAmount,
                    'refund_deduction' => $refundDeduction,
                    'final_amount' => $finalPayoutAmount,
                    'refund_details' => $refundDetails,
                    'status' => $payoutResult['data']['status'] ?? 'processing'
                ]
            ]);

        } catch (\Exception $e) {
            Log::error("Seller Settle Payouts Error: ", [
                'seller_id' => $sellerId,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to process payout. Please try again.'
            ], 500);
        }
    }

    /**
     * Get all pending (unpaid) payouts for a specific seller
     */
    public function getPendingPayouts($sellerId)
    {
        try {
            $seller = Seller::find($sellerId);

            if (!$seller) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seller not found'
                ], 404);
            }

            // Get all unpaid transactions
            $unpaidTransactions = SellerWalletTransaction::where('seller_id', $sellerId)
                ->where('is_paid_to_seller', 0)
                ->orderBy('created_at', 'desc')
                ->get();

            // Calculate total pending: Use amount, subtract refundable_amount if refund was applied
            $totalPending = 0;
            $totalOriginal = 0;
            $refundDeduction = 0;
            $refundDetails = [];

            foreach ($unpaidTransactions as $transaction) {
                $transactionAmount = (float) $transaction->amount;
                $totalOriginal += $transactionAmount;

                // If refund already applied to this specific transaction, subtract it
                if ($transaction->is_refunded_to_customer && $transaction->refundable_amount > 0) {
                    $refundAmount = (float) $transaction->refundable_amount;
                    $transactionAmount -= $refundAmount;
                    $refundDeduction += $refundAmount;

                    $refundDetails[] = [
                        'transaction_id' => $transaction->id,
                        'order_id' => $transaction->order_id,
                        'refundable_amount' => $refundAmount
                    ];
                }

                $totalPending += $transactionAmount;
            }

            // Get bank details
            $bankDetailsResult = SellerRazorpayPayoutService::getSellerBankDetails($sellerId);
            $bankDetails = null;

            if ($bankDetailsResult['success']) {
                $accountNumber = $bankDetailsResult['data']['account_number'];
                $maskedAccount = str_repeat('*', strlen($accountNumber) - 4) . substr($accountNumber, -4);

                $bankDetails = [
                    'bank_name' => $bankDetailsResult['data']['bank_name'],
                    'account_holder_name' => $bankDetailsResult['data']['account_holder_name'],
                    'account_number_masked' => $maskedAccount,
                    'ifsc_code' => $bankDetailsResult['data']['ifsc_code'],
                    'is_verified' => $bankDetailsResult['data']['is_verified'] ?? false
                ];
            }

            return response()->json([
                'success' => true,
                'data' => [
                    'total_pending' => (float) $totalPending,
                    'original_pending' => (float) $totalOriginal,
                    'refund_deduction' => (float) $refundDeduction,
                    'transactions_count' => $unpaidTransactions->count(),
                    'bank_details' => $bankDetails,
                    'refund_details' => $refundDetails,
                    'transactions' => $unpaidTransactions->map(function ($t) {
                        return [
                            'id' => $t->id,
                            'order_id' => $t->order_id,
                            'item_name' => $t->item_name,
                            'type' => $t->type,
                            'amount' => (float) $t->amount,
                            'balance_after' => (float) ($t->balance_after ?? $t->amount),
                            'admin_commission' => (float) ($t->admin_commission ?? 0),
                            'gst_percentage' => (float) ($t->gst_percentage ?? 0),
                            'payment_gateway_fees' => (float) ($t->payment_gateway_fees ?? 0),
                            'vendor_wait_charge' => (float) ($t->vendor_wait_charge ?? 0),
                            'products_json' => $t->products_json,
                            'message' => $t->message,
                            'is_refunded_to_customer' => (bool) $t->is_refunded_to_customer,
                            'refundable_amount' => (float) ($t->refundable_amount ?? 0),
                            'created_at' => $t->created_at ? $t->created_at->format('Y-m-d H:i:s') : null
                        ];
                    })
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Get Pending Payouts Error', [
                'seller_id' => $sellerId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch pending payouts'
            ], 500);
        }
    }

    /**
     * Get pending payouts for ALL sellers in one batch call
     * Much faster than individual calls per seller
     */
    public function getPendingPayoutsBatch()
    {
        try {
            // Get all unpaid transactions grouped by seller
            $unpaidTransactions = SellerWalletTransaction::where('is_paid_to_seller', 0)
                ->select([
                    'seller_id',
                    'amount',
                    'is_refunded_to_customer',
                    'refundable_amount'
                ])
                ->get()
                ->groupBy('seller_id');

            $result = [];

            foreach ($unpaidTransactions as $sellerId => $transactions) {
                $totalPending = 0;
                $totalOriginal = 0;
                $refundDeduction = 0;

                foreach ($transactions as $transaction) {
                    $transactionAmount = (float) $transaction->amount;
                    $totalOriginal += $transactionAmount;

                    // Apply refund deduction if applicable
                    if ($transaction->is_refunded_to_customer && $transaction->refundable_amount > 0) {
                        $refundAmount = (float) $transaction->refundable_amount;
                        $transactionAmount -= $refundAmount;
                        $refundDeduction += $refundAmount;
                    }

                    $totalPending += $transactionAmount;
                }

                $result[$sellerId] = [
                    'seller_id' => (int) $sellerId,
                    'total_pending' => round($totalPending, 2),
                    'original_pending' => round($totalOriginal, 2),
                    'refund_deduction' => round($refundDeduction, 2),
                    'transactions_count' => $transactions->count()
                ];
            }

            Log::info('Pending Payouts Batch: Fetched successfully', [
                'sellers_count' => count($result),
                'total_transactions' => SellerWalletTransaction::where('is_paid_to_seller', 0)->count()
            ]);

            return response()->json([
                'success' => true,
                'data' => $result
            ]);

        } catch (\Exception $e) {
            Log::error('Pending Payouts Batch: Error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch pending payouts batch'
            ], 500);
        }
    }

    /**
     * Settle all pending payouts with manual transaction ID
     */
    public function settlePendingPayouts(Request $request, $sellerId)
    {
        try {
            Log::info('Settle Pending Payouts: Request received', [
                'seller_id' => $sellerId,
                'request_data' => $request->all()
            ]);

            $seller = Seller::find($sellerId);

            if (!$seller) {
                return response()->json([
                    'success' => false,
                    'message' => 'Seller not found'
                ], 404);
            }

            // Validate request
            $validator = Validator::make($request->all(), [
                'transaction_ids' => 'required|array|min:1',
                'transaction_ids.*' => 'required|integer|exists:seller_wallet_transactions,id',
                'manual_transaction_id' => 'required|string|max:255',
                'total_amount' => 'required|numeric|min:0.01'
            ], [
                'transaction_ids.required' => 'Please select at least one transaction to settle.',
                'manual_transaction_id.required' => 'Transaction ID is required.',
                'total_amount.required' => 'Total amount is required.'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => $validator->errors()->first()
                ], 422);
            }

            $transactionIds = $request->transaction_ids;
            $manualTransactionId = $request->manual_transaction_id;
            $requestedAmount = (float) $request->total_amount;

            // Verify transactions belong to this seller and are unpaid
            $validTransactions = SellerWalletTransaction::whereIn('id', $transactionIds)
                ->where('seller_id', $sellerId)
                ->where('is_paid_to_seller', false)
                ->get();

            if ($validTransactions->count() !== count($transactionIds)) {
                Log::warning('Settle Pending Payouts: Invalid transactions detected', [
                    'seller_id' => $sellerId,
                    'requested_ids' => $transactionIds,
                    'valid_count' => $validTransactions->count()
                ]);
                return response()->json([
                    'success' => false,
                    'message' => 'Some transactions are invalid or already paid.'
                ], 400);
            }

            // Calculate total: Use amount, subtract refundable_amount if refund was applied
            $calculatedAmount = 0;
            $originalAmount = 0;
            $refundDeduction = 0;
            $refundDetails = [];

            foreach ($validTransactions as $transaction) {
                $transactionAmount = (float) $transaction->amount;
                $originalAmount += $transactionAmount;

                // If refund already applied to this specific transaction, subtract it
                if ($transaction->is_refunded_to_customer && $transaction->refundable_amount > 0) {
                    $refundAmount = (float) $transaction->refundable_amount;
                    $transactionAmount -= $refundAmount;
                    $refundDeduction += $refundAmount;

                    $refundDetails[] = [
                        'transaction_id' => $transaction->id,
                        'order_id' => $transaction->order_id,
                        'refundable_amount' => $refundAmount
                    ];
                }

                $calculatedAmount += $transactionAmount;
            }

            // Final amount is already calculated
            $finalAmount = $calculatedAmount;

            // Verify amount matches
            if (abs($finalAmount - $requestedAmount) > 0.01) {
                Log::warning('Settle Pending Payouts: Amount mismatch', [
                    'seller_id' => $sellerId,
                    'calculated_amount' => $finalAmount,
                    'requested_amount' => $requestedAmount,
                    'refund_deduction' => $refundDeduction
                ]);
                return response()->json([
                    'success' => false,
                    'message' => 'Amount mismatch. Please refresh and try again.'
                ], 400);
            }

            // Ensure final amount is positive
            if ($finalAmount <= 0) {
                return response()->json([
                    'success' => false,
                    'message' => 'Payout amount is zero or negative. Total refunds: Rs. ' . number_format($refundDeduction, 2)
                ], 400);
            }

            // Process in transaction
            DB::beginTransaction();

            try {
                // Get admin user ID safely
                $adminId = null;
                $authUser = auth()->guard('api')->user();
                if ($authUser) {
                    // Verify user exists in users table
                    $userExists = DB::table('users')->where('id', $authUser->id)->exists();
                    if ($userExists) {
                        $adminId = $authUser->id;
                    }
                }

                // Update all transactions as paid
                SellerWalletTransaction::whereIn('id', $transactionIds)
                    ->update([
                        'is_paid_to_seller' => true,
                        'payment_transaction_id' => $manualTransactionId,
                        'paid_at' => now(),
                        'paid_by' => $adminId
                    ]);

                // Note: Refund amounts are already tracked in the transaction records themselves
                // via is_refunded_to_customer and refundable_amount fields.
                // No need to mark anything separately or update messages.

                DB::commit();

                Log::info('Settle Pending Payouts: Success', [
                    'seller_id' => $sellerId,
                    'transaction_count' => count($transactionIds),
                    'original_amount' => $originalAmount,
                    'refund_deduction' => $refundDeduction,
                    'final_amount' => $finalAmount,
                    'manual_transaction_id' => $manualTransactionId
                ]);

                // Send notification to seller
                try {
                    $notificationMessage = "Rs. " . number_format($finalAmount, 2) . " has been settled to your bank account by admin. Transaction ID: " . $manualTransactionId;
                    if ($refundDeduction > 0) {
                        $notificationMessage .= " (Rs. " . number_format($refundDeduction, 2) . " deducted for customer refunds)";
                    }

                    SellerNotificationService::send(
                        (int) $sellerId,
                        'Payment Received',
                        $notificationMessage,
                        '',
                        'wallet',
                        null,
                        [
                            'manual_transaction_id' => $manualTransactionId,
                            'original_amount' => $originalAmount,
                            'refund_deduction' => $refundDeduction,
                            'final_amount' => $finalAmount
                        ]
                    );
                } catch (\Exception $notificationException) {
                    Log::warning('Settle Pending Payouts: Failed to send notification', [
                        'seller_id' => $sellerId,
                        'error' => $notificationException->getMessage()
                    ]);
                }

                return response()->json([
                    'success' => true,
                    'message' => $refundDeduction > 0
                        ? 'Payout settled successfully with refund deduction applied'
                        : 'Payout settled successfully',
                    'data' => [
                        'manual_transaction_id' => $manualTransactionId,
                        'original_amount' => $originalAmount,
                        'refund_deduction' => $refundDeduction,
                        'final_amount' => $finalAmount,
                        'transactions_count' => count($transactionIds),
                        'refund_details' => $refundDetails
                    ]
                ]);

            } catch (\Exception $dbException) {
                DB::rollBack();
                throw $dbException;
            }

        } catch (\Exception $e) {
            Log::error('Settle Pending Payouts Error', [
                'seller_id' => $sellerId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to process payout. Please try again.'
            ], 500);
        }
    }
}
