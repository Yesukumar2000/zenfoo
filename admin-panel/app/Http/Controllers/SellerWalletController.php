<?php

namespace App\Http\Controllers;

use App\Models\Seller;
use App\Models\SellerWalletTransaction;
use App\Models\SellerWithdrawalRequest;
use App\Models\Order;
use App\Models\OrderItem;
use App\Helpers\CommonHelper;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class SellerWalletController extends Controller
{
    /**
     * Get wallet overview with current balance and recent transactions
     */
    public function getWalletOverview(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        // Get current balance
        $currentBalance = $seller->balance ?? 0;

        // Get statistics from seller_wallet_transactions table
        $totalEarned = SellerWalletTransaction::where('seller_id', $seller->id)
            ->whereIn('type', [
                SellerWalletTransaction::TYPE_CREDIT,
                SellerWalletTransaction::TYPE_ORDER_COMMISSION,
                SellerWalletTransaction::TYPE_REFUND
            ])
            ->sum('amount');

        $totalWithdrawn = SellerWalletTransaction::where('seller_id', $seller->id)
            ->where('type', SellerWalletTransaction::TYPE_WITHDRAWAL)
            ->sum('amount');

        $pendingWithdrawals = SellerWithdrawalRequest::where('seller_id', $seller->id)
            ->whereIn('status', [
                SellerWithdrawalRequest::STATUS_PENDING,
                SellerWithdrawalRequest::STATUS_APPROVED,
                SellerWithdrawalRequest::STATUS_PROCESSING
            ])
            ->sum('amount');

        // Get today's earnings from wallet transactions
        $todayEarnings = SellerWalletTransaction::where('seller_id', $seller->id)
            ->whereIn('type', [SellerWalletTransaction::TYPE_ORDER_COMMISSION])
            ->whereDate('created_at', now()->toDateString())
            ->sum('amount');

        // Get cancelled and returned orders count from orders table
        $cancelledOrdersValue = OrderItem::where('seller_id', $seller->id)
            ->where('active_status', 7) // Cancelled
            ->sum(DB::raw('quantity * discounted_price'));

        $returnedOrdersValue = OrderItem::where('seller_id', $seller->id)
            ->where('active_status', 8) // Returned
            ->sum(DB::raw('quantity * discounted_price'));

        // Get recent transactions (last 10)
        $recentTransactions = SellerWalletTransaction::where('seller_id', $seller->id)
            ->orderBy('created_at', 'DESC')
            ->limit(10)
            ->get()
            ->map(function($transaction) {
                return [
                    'id' => $transaction->id,
                    'type' => $transaction->type,
                    'amount' => (float) $transaction->amount,
                    'formatted_amount' => $transaction->formatted_amount,
                    'balance_before' => (float) $transaction->balance_before,
                    'balance_after' => (float) $transaction->balance_after,
                    'message' => $transaction->message,
                    'reference_type' => $transaction->reference_type,
                    'reference_id' => $transaction->reference_id,
                    'order_id' => $transaction->order_id,
                    'created_at' => $transaction->created_at->format('Y-m-d H:i:s'),
                ];
            });

        return response()->json([
            'status' => 1,
            'message' => 'Wallet overview fetched successfully',
            'data' => [
                'current_balance' => (float) $currentBalance,
                'total_earned' => (float) $totalEarned,
                'total_withdrawn' => (float) $totalWithdrawn,
                'pending_withdrawals' => (float) $pendingWithdrawals,
                'available_for_withdrawal' => (float) ($currentBalance - $pendingWithdrawals),
                'today_earnings' => (float) $todayEarnings,
                'cancelled_orders_value' => (float) $cancelledOrdersValue,
                'returned_orders_value' => (float) $returnedOrdersValue,
                'recent_transactions' => $recentTransactions,
            ]
        ]);
    }

    /**
     * Get paginated transaction history with filters
     */
    public function getTransactionHistory(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        // Pagination and filters
        $perPage = $request->input('per_page', 20);
        $page = $request->input('page', 1);
        $type = $request->input('type'); // credit, debit, withdrawal, etc.
        $startDate = $request->input('start_date');
        $endDate = $request->input('end_date');

        $query = SellerWalletTransaction::where('seller_id', $seller->id);

        // Apply type filter
        if ($type) {
            $query->where('type', $type);
        }

        // Apply date range filter
        if ($startDate && $endDate) {
            $query->whereBetween('created_at', [$startDate, $endDate]);
        }

        // Get total count
        $total = $query->count();

        // Get transactions
        $transactions = $query->orderBy('created_at', 'DESC')
            ->skip(($page - 1) * $perPage)
            ->take($perPage)
            ->get()
            ->map(function($transaction) {
                return [
                    'id' => $transaction->id,
                    'type' => $transaction->type,
                    'amount' => (float) $transaction->amount,
                    'formatted_amount' => $transaction->formatted_amount,
                    'balance_before' => (float) $transaction->balance_before,
                    'balance_after' => (float) $transaction->balance_after,
                    'message' => $transaction->message,
                    'reference_type' => $transaction->reference_type,
                    'reference_id' => $transaction->reference_id,
                    'order_id' => $transaction->order_id,
                    'order_item_id' => $transaction->order_item_id,
                    'admin_note' => $transaction->admin_note,
                    'created_at' => $transaction->created_at->format('Y-m-d H:i:s'),
                ];
            });

        return response()->json([
            'status' => 1,
            'message' => 'Transaction history fetched successfully',
            'data' => [
                'transactions' => $transactions,
                'pagination' => [
                    'total' => $total,
                    'per_page' => $perPage,
                    'current_page' => $page,
                    'last_page' => ceil($total / $perPage),
                ]
            ]
        ]);
    }

    /**
     * Create withdrawal request
     */
    public function createWithdrawalRequest(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        // Validation
        $validator = Validator::make($request->all(), [
            'amount' => 'required|numeric|min:100', // Minimum withdrawal amount
            'account_number' => 'required|string',
            'bank_ifsc_code' => 'required|string',
            'account_name' => 'required|string',
            'bank_name' => 'required|string',
            'branch_name' => 'nullable|string',
            'seller_note' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $requestedAmount = $request->amount;

        // Check if seller has sufficient balance
        $currentBalance = $seller->balance ?? 0;

        // Check pending withdrawals
        $pendingWithdrawals = SellerWithdrawalRequest::where('seller_id', $seller->id)
            ->where('status', SellerWithdrawalRequest::STATUS_PENDING)
            ->sum('amount');

        $availableBalance = $currentBalance - $pendingWithdrawals;

        if ($requestedAmount > $availableBalance) {
            return CommonHelper::responseError("Insufficient balance. Available for withdrawal: ₹" . number_format($availableBalance, 2));
        }

        try {
            DB::beginTransaction();

            // Calculate new balance after withdrawal
            $balanceAfter = $currentBalance - $requestedAmount;

            // Create withdrawal request
            $withdrawalRequest = SellerWithdrawalRequest::create([
                'seller_id' => $seller->id,
                'amount' => $requestedAmount,
                'balance_before' => $currentBalance,
                'balance_after' => $balanceAfter,
                'account_number' => $request->account_number,
                'bank_ifsc_code' => $request->bank_ifsc_code,
                'account_name' => $request->account_name,
                'bank_name' => $request->bank_name,
                'branch_name' => $request->branch_name,
                'seller_note' => $request->seller_note,
                'status' => SellerWithdrawalRequest::STATUS_PENDING,
            ]);

            // Deduct amount from seller balance immediately
            $seller->balance = $balanceAfter;
            $seller->save();

            // Create wallet transaction record (debit)
            SellerWalletTransaction::create([
                'seller_id' => $seller->id,
                'type' => SellerWalletTransaction::TYPE_WITHDRAWAL,
                'amount' => $requestedAmount,
                'balance_before' => $currentBalance,
                'balance_after' => $balanceAfter,
                'reference_type' => SellerWalletTransaction::REF_WITHDRAWAL,
                'reference_id' => $withdrawalRequest->id,
                'message' => 'Withdrawal request created - Pending approval',
                'status' => 1,
            ]);

            DB::commit();

            return response()->json([
                'status' => 1,
                'message' => 'Withdrawal request created successfully. Amount has been deducted from your balance. It will be processed within 2-3 business days.',
                'data' => [
                    'withdrawal_request_id' => $withdrawalRequest->id,
                    'amount' => (float) $withdrawalRequest->amount,
                    'balance_before' => (float) $currentBalance,
                    'balance_after' => (float) $balanceAfter,
                    'status' => $withdrawalRequest->status,
                    'created_at' => $withdrawalRequest->created_at->format('Y-m-d H:i:s'),
                ]
            ]);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Withdrawal Request Error:", [$e->getMessage()]);
            return CommonHelper::responseError("Failed to create withdrawal request.");
        }
    }

    /**
     * Get withdrawal requests history
     */
    public function getWithdrawalRequests(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        $perPage = $request->input('per_page', 20);
        $page = $request->input('page', 1);
        $status = $request->input('status'); // pending, approved, rejected, completed

        $query = SellerWithdrawalRequest::where('seller_id', $seller->id);

        if ($status) {
            $query->where('status', $status);
        }

        $total = $query->count();

        $withdrawalRequests = $query->orderBy('created_at', 'DESC')
            ->skip(($page - 1) * $perPage)
            ->take($perPage)
            ->get()
            ->map(function($request) {
                return [
                    'id' => $request->id,
                    'amount' => (float) $request->amount,
                    'balance_before' => (float) $request->balance_before,
                    'balance_after' => $request->balance_after ? (float) $request->balance_after : null,
                    'account_number' => substr($request->account_number, -4), // Show only last 4 digits
                    'bank_name' => $request->bank_name,
                    'account_name' => $request->account_name,
                    'status' => $request->status,
                    'seller_note' => $request->seller_note,
                    'admin_note' => $request->admin_note,
                    'payment_method' => $request->payment_method,
                    'transaction_reference' => $request->transaction_reference,
                    'processed_at' => $request->processed_at ? $request->processed_at->format('Y-m-d H:i:s') : null,
                    'created_at' => $request->created_at->format('Y-m-d H:i:s'),
                ];
            });

        return response()->json([
            'status' => 1,
            'message' => 'Withdrawal requests fetched successfully',
            'data' => [
                'withdrawal_requests' => $withdrawalRequests,
                'pagination' => [
                    'total' => $total,
                    'per_page' => $perPage,
                    'current_page' => $page,
                    'last_page' => ceil($total / $perPage),
                ]
            ]
        ]);
    }

    /**
     * Approve withdrawal request (Admin)
     */
    public function approveWithdrawalRequest(Request $request, $requestId)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $withdrawalRequest = SellerWithdrawalRequest::find($requestId);

        if (!$withdrawalRequest) {
            return CommonHelper::responseError("Withdrawal request not found.");
        }

        // Verify the withdrawal request belongs to a seller under this admin
        $seller = Seller::where('id', $withdrawalRequest->seller_id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller not found.");
        }

        // Check if request is already processed
        if ($withdrawalRequest->status !== SellerWithdrawalRequest::STATUS_PENDING) {
            return CommonHelper::responseError("Withdrawal request has already been processed.");
        }

        $validator = Validator::make($request->all(), [
            'admin_note' => 'nullable|string|max:500',
            'payment_method' => 'nullable|string|max:100',
            'transaction_reference' => 'nullable|string|max:100',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            DB::beginTransaction();

            // Update withdrawal request status to approved
            $withdrawalRequest->status = SellerWithdrawalRequest::STATUS_APPROVED;
            $withdrawalRequest->admin_note = $request->input('admin_note');
            $withdrawalRequest->payment_method = $request->input('payment_method');
            $withdrawalRequest->transaction_reference = $request->input('transaction_reference');
            $withdrawalRequest->processed_at = now();
            $withdrawalRequest->save();

            // Update the wallet transaction message to indicate approval
            $walletTransaction = SellerWalletTransaction::where('seller_id', $seller->id)
                ->where('reference_type', SellerWalletTransaction::REF_WITHDRAWAL)
                ->where('reference_id', $withdrawalRequest->id)
                ->first();

            if ($walletTransaction) {
                $walletTransaction->message = 'Withdrawal request approved - Amount transferred';
                $walletTransaction->save();
            }

            DB::commit();

            // TODO: Send notification to seller about approval
            // You can implement notification logic here

            return response()->json([
                'status' => 1,
                'message' => 'Withdrawal request approved successfully',
                'data' => [
                    'withdrawal_request' => [
                        'id' => $withdrawalRequest->id,
                        'amount' => (float) $withdrawalRequest->amount,
                        'status' => $withdrawalRequest->status,
                        'processed_at' => $withdrawalRequest->processed_at->format('Y-m-d H:i:s'),
                    ]
                ]
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return CommonHelper::responseError("Failed to approve withdrawal request: " . $e->getMessage());
        }
    }

    /**
     * Reject withdrawal request (Admin)
     */
    public function rejectWithdrawalRequest(Request $request, $requestId)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $withdrawalRequest = SellerWithdrawalRequest::find($requestId);

        if (!$withdrawalRequest) {
            return CommonHelper::responseError("Withdrawal request not found.");
        }

        // Verify the withdrawal request belongs to a seller under this admin
        $seller = Seller::where('id', $withdrawalRequest->seller_id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller not found.");
        }

        // Check if request is already processed
        if ($withdrawalRequest->status !== SellerWithdrawalRequest::STATUS_PENDING) {
            return CommonHelper::responseError("Withdrawal request has already been processed.");
        }

        $validator = Validator::make($request->all(), [
            'admin_note' => 'required|string|max:500',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            DB::beginTransaction();

            // Get current seller balance
            $currentBalance = $seller->balance;

            // Add the withdrawal amount back to seller balance
            $refundAmount = $withdrawalRequest->amount;
            $balanceAfter = $currentBalance + $refundAmount;

            // Update seller balance
            $seller->balance = $balanceAfter;
            $seller->save();

            // Update withdrawal request status to rejected
            $withdrawalRequest->status = SellerWithdrawalRequest::STATUS_REJECTED;
            $withdrawalRequest->admin_note = $request->input('admin_note');
            $withdrawalRequest->processed_at = now();
            $withdrawalRequest->save();

            // Update the original wallet transaction message
            $originalTransaction = SellerWalletTransaction::where('seller_id', $seller->id)
                ->where('reference_type', SellerWalletTransaction::REF_WITHDRAWAL)
                ->where('reference_id', $withdrawalRequest->id)
                ->first();

            if ($originalTransaction) {
                $originalTransaction->message = 'Withdrawal request rejected - Amount refunded';
                $originalTransaction->save();
            }

            // Create a new wallet transaction for the refund (credit)
            SellerWalletTransaction::create([
                'seller_id' => $seller->id,
                'type' => SellerWalletTransaction::TYPE_REFUND,
                'amount' => $refundAmount,
                'balance_before' => $currentBalance,
                'balance_after' => $balanceAfter,
                'reference_type' => SellerWalletTransaction::REF_WITHDRAWAL,
                'reference_id' => $withdrawalRequest->id,
                'message' => 'Withdrawal request rejected - Amount refunded to wallet',
                'status' => 1,
            ]);

            DB::commit();

            // TODO: Send notification to seller about rejection with reason
            // You can implement notification logic here

            return response()->json([
                'status' => 1,
                'message' => 'Withdrawal request rejected and amount refunded successfully',
                'data' => [
                    'withdrawal_request' => [
                        'id' => $withdrawalRequest->id,
                        'amount' => (float) $withdrawalRequest->amount,
                        'status' => $withdrawalRequest->status,
                        'refunded_amount' => (float) $refundAmount,
                        'new_balance' => (float) $balanceAfter,
                        'processed_at' => $withdrawalRequest->processed_at->format('Y-m-d H:i:s'),
                    ]
                ]
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            return CommonHelper::responseError("Failed to reject withdrawal request: " . $e->getMessage());
        }
    }

    /**
     * Get wallet earnings summary (for statistics)
     */
    public function getEarningsSummary(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return CommonHelper::responseError("Seller profile not found.");
        }

        // Get earnings for different time periods
        $today = now()->startOfDay();
        $thisMonth = now()->startOfMonth();
        $thisYear = now()->startOfYear();

        $todayEarnings = SellerWalletTransaction::where('seller_id', $seller->id)
            ->whereIn('type', [SellerWalletTransaction::TYPE_ORDER_COMMISSION])
            ->where('created_at', '>=', $today)
            ->sum('amount');

        $monthlyEarnings = SellerWalletTransaction::where('seller_id', $seller->id)
            ->whereIn('type', [SellerWalletTransaction::TYPE_ORDER_COMMISSION])
            ->where('created_at', '>=', $thisMonth)
            ->sum('amount');

        $yearlyEarnings = SellerWalletTransaction::where('seller_id', $seller->id)
            ->whereIn('type', [SellerWalletTransaction::TYPE_ORDER_COMMISSION])
            ->where('created_at', '>=', $thisYear)
            ->sum('amount');

        $totalEarnings = SellerWalletTransaction::where('seller_id', $seller->id)
            ->whereIn('type', [SellerWalletTransaction::TYPE_ORDER_COMMISSION])
            ->sum('amount');

        return response()->json([
            'status' => 1,
            'message' => 'Earnings summary fetched successfully',
            'data' => [
                'today_earnings' => (float) $todayEarnings,
                'monthly_earnings' => (float) $monthlyEarnings,
                'yearly_earnings' => (float) $yearlyEarnings,
                'total_earnings' => (float) $totalEarnings,
                'current_balance' => (float) $seller->balance,
            ]
        ]);
    }

    /**
     * Credit wallet on order delivery
     * This should be called when order status changes to "Delivered"
     */
    public static function creditOrderAmount(OrderItem $orderItem)
    {
        try {
            DB::beginTransaction();

            $seller = Seller::find($orderItem->seller_id);

            if (!$seller) {
                Log::error("Seller not found for order item", ['order_item_id' => $orderItem->id]);
                return false;
            }

            // Check if already credited
            $existingTransaction = SellerWalletTransaction::where('order_item_id', $orderItem->id)
                ->where('type', SellerWalletTransaction::TYPE_ORDER_COMMISSION)
                ->first();

            if ($existingTransaction) {
                Log::info("Order item already credited", ['order_item_id' => $orderItem->id]);
                return true; // Already credited
            }

            // Calculate amount after commission
            $itemTotal = $orderItem->quantity * $orderItem->discounted_price;
            $commissionPercent = $seller->commission ?? 0;
            $commissionAmount = ($itemTotal * $commissionPercent) / 100;
            $sellerAmount = $itemTotal - $commissionAmount;

            // Get current balance
            $balanceBefore = $seller->balance ?? 0;
            $balanceAfter = $balanceBefore + $sellerAmount;

            // Create wallet transaction
            SellerWalletTransaction::create([
                'seller_id' => $seller->id,
                'order_id' => $orderItem->order_id,
                'order_item_id' => $orderItem->id,
                'type' => SellerWalletTransaction::TYPE_ORDER_COMMISSION,
                'amount' => $sellerAmount,
                'balance_before' => $balanceBefore,
                'balance_after' => $balanceAfter,
                'reference_type' => SellerWalletTransaction::REF_ORDER_ITEM,
                'reference_id' => $orderItem->id,
                'message' => "Order #" . $orderItem->order_id . " delivered - Item: " . $orderItem->product_name,
                'status' => 1,
            ]);

            // Update seller balance
            $seller->balance = $balanceAfter;
            $seller->save();

            DB::commit();

            Log::info("Order amount credited to seller wallet", [
                'seller_id' => $seller->id,
                'order_item_id' => $orderItem->id,
                'amount' => $sellerAmount,
                'commission' => $commissionAmount,
            ]);

            return true;

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Error crediting order amount to wallet:", [
                'error' => $e->getMessage(),
                'order_item_id' => $orderItem->id ?? null,
            ]);
            return false;
        }
    }
}
