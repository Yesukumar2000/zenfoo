<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\Request;

class TransactionsApiController extends Controller
{
    public function index(){
        $transactions = Transaction::select('users.name', 'transactions.*')
            ->leftJoin('users', 'transactions.user_id', '=', 'users.id')
            ->orderBy('transactions.id','DESC')->get();
        return CommonHelper::responseWithData($transactions);
    }

    public function getCustomerTransactions(Request $request, $customerId)
    {
        $perPage = $request->get('per_page', 10);
        $search = $request->get('search', '');
        $type = $request->get('type', 'all'); // 'all', 'payments', 'wallet'

        // Get payment transactions
        $paymentsQuery = Transaction::select(
                'transactions.id',
                'transactions.user_id',
                'transactions.order_id',
                'transactions.type as payment_type',
                'transactions.txn_id',
                'transactions.amount',
                'transactions.status',
                'transactions.message',
                'transactions.created_at',
                \DB::raw("'payment' as transaction_category")
            )
            ->where('transactions.user_id', $customerId);

        // Get wallet transactions
        $walletQuery = \App\Models\WalletTransaction::select(
                'wallet_transactions.id',
                'wallet_transactions.user_id',
                'wallet_transactions.order_id',
                'wallet_transactions.type as payment_type',
                'wallet_transactions.txn_id',
                'wallet_transactions.amount',
                \DB::raw("CASE WHEN wallet_transactions.status = 1 THEN 'success' ELSE 'failed' END as status"),
                'wallet_transactions.message',
                'wallet_transactions.created_at',
                \DB::raw("'wallet' as transaction_category")
            )
            ->where('wallet_transactions.user_id', $customerId);

        // Apply search filter
        if ($search) {
            $paymentsQuery->where(function($q) use ($search) {
                $q->where('transactions.txn_id', 'like', "%{$search}%")
                  ->orWhere('transactions.message', 'like', "%{$search}%")
                  ->orWhere('transactions.type', 'like', "%{$search}%");
            });

            $walletQuery->where(function($q) use ($search) {
                $q->where('wallet_transactions.txn_id', 'like', "%{$search}%")
                  ->orWhere('wallet_transactions.message', 'like', "%{$search}%")
                  ->orWhere('wallet_transactions.type', 'like', "%{$search}%");
            });
        }

        // Build query based on type filter
        if ($type === 'payments') {
            $query = $paymentsQuery;
        } elseif ($type === 'wallet') {
            $query = $walletQuery;
        } else {
            // Union both queries
            $query = $paymentsQuery->unionAll($walletQuery);
        }

        // Get total count
        $totalQuery = \DB::table(\DB::raw("({$query->toSql()}) as combined"))
            ->mergeBindings($query->getQuery());
        $total = $totalQuery->count();

        // Get paginated results with ordering
        $page = $request->get('page', 1);
        $offset = ($page - 1) * $perPage;

        $transactions = \DB::table(\DB::raw("({$query->toSql()}) as combined"))
            ->mergeBindings($query->getQuery())
            ->orderBy('created_at', 'DESC')
            ->offset($offset)
            ->limit($perPage)
            ->get();

        return CommonHelper::responseWithData([
            'transactions' => $transactions,
            'total' => $total,
            'per_page' => $perPage,
            'current_page' => (int) $page
        ]);
    }
}
