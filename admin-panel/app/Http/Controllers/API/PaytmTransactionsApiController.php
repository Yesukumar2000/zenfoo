<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\PaytmTransaction;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PaytmTransactionsApiController extends Controller
{
    /**
     * Get all Paytm transactions with filters
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        try {
            $query = PaytmTransaction::with(['user:id,name,email,mobile'])
                ->orderBy('created_at', 'desc');

            // Filter by status
            if ($request->has('status') && $request->status != '') {
                $query->where('status', $request->status);
            }

            // Filter by type of payment
            if ($request->has('type_of_payment') && $request->type_of_payment != '') {
                $query->where('type_of_payment', $request->type_of_payment);
            }

            // Filter by user
            if ($request->has('user_id') && $request->user_id != '') {
                $query->where('user_id', $request->user_id);
            }

            // Filter by date range
            if ($request->has('start_date') && $request->start_date != '') {
                $query->whereDate('transaction_date', '>=', $request->start_date);
            }

            if ($request->has('end_date') && $request->end_date != '') {
                $query->whereDate('transaction_date', '<=', $request->end_date);
            }

            // Search by transaction ID
            if ($request->has('search') && $request->search != '') {
                $search = $request->search;
                $query->where(function ($q) use ($search) {
                    $q->where('txn_id', 'LIKE', "%{$search}%")
                        ->orWhere('paytm_txn_id', 'LIKE', "%{$search}%")
                        ->orWhere('bank_txn_id', 'LIKE', "%{$search}%");
                });
            }

            // Filter by captured status
            if ($request->has('is_captured') && $request->is_captured !== '') {
                $query->where('is_captured', $request->is_captured);
            }

            // Pagination
            $perPage = $request->get('per_page', 25);
            $transactions = $query->paginate($perPage);

            // Get statistics
            $stats = $this->getStatistics($request);

            return response()->json([
                'status' => true,
                'data' => [
                    'transactions' => $transactions,
                    'statistics' => $stats
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Admin: Failed to fetch Paytm transactions', [
                'error' => $e->getMessage()
            ]);

            return CommonHelper::responseError('Failed to fetch transactions: ' . $e->getMessage());
        }
    }

    /**
     * Get transaction statistics
     *
     * @param Request $request
     * @return array
     */
    private function getStatistics($request)
    {
        try {
            $query = PaytmTransaction::query();

            // Apply same filters as index
            if ($request->has('status') && $request->status != '') {
                $query->where('status', $request->status);
            }

            if ($request->has('type_of_payment') && $request->type_of_payment != '') {
                $query->where('type_of_payment', $request->type_of_payment);
            }

            if ($request->has('start_date') && $request->start_date != '') {
                $query->whereDate('transaction_date', '>=', $request->start_date);
            }

            if ($request->has('end_date') && $request->end_date != '') {
                $query->whereDate('transaction_date', '<=', $request->end_date);
            }

            $total = $query->count();
            $totalAmount = $query->sum('amount');
            $successful = $query->where('status', PaytmTransaction::$statusSuccess)->count();
            $failed = $query->where('status', PaytmTransaction::$statusFailed)->count();
            $pending = $query->where('status', PaytmTransaction::$statusPending)->count();
            $captured = $query->where('is_captured', 1)->count();

            return [
                'total_transactions' => $total,
                'total_amount' => floatval($totalAmount),
                'successful_count' => $successful,
                'failed_count' => $failed,
                'pending_count' => $pending,
                'captured_count' => $captured,
                'success_rate' => $total > 0 ? round(($successful / $total) * 100, 2) : 0
            ];

        } catch (\Exception $e) {
            Log::error('Admin: Failed to calculate statistics', [
                'error' => $e->getMessage()
            ]);

            return [
                'total_transactions' => 0,
                'total_amount' => 0,
                'successful_count' => 0,
                'failed_count' => 0,
                'pending_count' => 0,
                'captured_count' => 0,
                'success_rate' => 0
            ];
        }
    }

    /**
     * Get single transaction details
     *
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function show($id)
    {
        try {
            $transaction = PaytmTransaction::with(['user:id,name,email,mobile'])
                ->findOrFail($id);

            // Parse metadata if exists
            if ($transaction->metadata) {
                $transaction->parsed_metadata = json_decode($transaction->metadata, true);
            }

            return response()->json([
                'status' => true,
                'data' => [
                    'transaction' => $transaction
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Admin: Failed to fetch transaction details', [
                'id' => $id,
                'error' => $e->getMessage()
            ]);

            return CommonHelper::responseError('Transaction not found');
        }
    }

    /**
     * Export transactions to CSV
     *
     * @param Request $request
     * @return \Illuminate\Http\Response
     */
    public function export(Request $request)
    {
        try {
            $query = PaytmTransaction::with(['user:id,name,email'])
                ->orderBy('created_at', 'desc');

            // Apply filters (same as index)
            if ($request->has('status') && $request->status != '') {
                $query->where('status', $request->status);
            }

            if ($request->has('type_of_payment') && $request->type_of_payment != '') {
                $query->where('type_of_payment', $request->type_of_payment);
            }

            if ($request->has('start_date') && $request->start_date != '') {
                $query->whereDate('transaction_date', '>=', $request->start_date);
            }

            if ($request->has('end_date') && $request->end_date != '') {
                $query->whereDate('transaction_date', '<=', $request->end_date);
            }

            $transactions = $query->get();

            // Generate CSV
            $filename = 'paytm_transactions_' . date('Y-m-d_His') . '.csv';
            $headers = [
                'Content-Type' => 'text/csv',
                'Content-Disposition' => "attachment; filename=\"{$filename}\"",
            ];

            $callback = function () use ($transactions) {
                $file = fopen('php://output', 'w');

                // Headers
                fputcsv($file, [
                    'ID',
                    'Transaction ID',
                    'Paytm Txn ID',
                    'Bank Txn ID',
                    'User Name',
                    'User Email',
                    'Amount',
                    'Payment Mode',
                    'Bank Name',
                    'Status',
                    'Captured',
                    'Type',
                    'Transaction Date',
                    'Created At'
                ]);

                // Data
                foreach ($transactions as $txn) {
                    fputcsv($file, [
                        $txn->id,
                        $txn->txn_id,
                        $txn->paytm_txn_id,
                        $txn->bank_txn_id,
                        $txn->user ? $txn->user->name : 'N/A',
                        $txn->user ? $txn->user->email : 'N/A',
                        $txn->amount,
                        $txn->payment_mode,
                        $txn->bank_name,
                        $txn->status,
                        $txn->is_captured ? 'Yes' : 'No',
                        $txn->type_of_payment,
                        $txn->transaction_date,
                        $txn->created_at
                    ]);
                }

                fclose($file);
            };

            return response()->stream($callback, 200, $headers);

        } catch (\Exception $e) {
            Log::error('Admin: Failed to export transactions', [
                'error' => $e->getMessage()
            ]);

            return CommonHelper::responseError('Failed to export transactions');
        }
    }

    /**
     * Get users list for filter dropdown
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function getUsers()
    {
        try {
            $users = User::whereIn('id', function ($query) {
                    $query->select('user_id')
                        ->from('paytm_transactions')
                        ->distinct();
                })
                ->select('id', 'name', 'email')
                ->orderBy('name')
                ->get();

            return response()->json([
                'status' => true,
                'data' => [
                    'users' => $users
                ]
            ]);

        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to fetch users');
        }
    }
}
