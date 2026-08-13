<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Helpers\PhonePeHelper;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\WalletTransaction;
use App\Models\Transaction;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class WalletTransactionsApiController extends Controller
{
    public function index(){
        $customers = User::orderBy('id','DESC')->get();
        $walletTransactions = WalletTransaction::select('users.name', 'wallet_transactions.*')
            ->leftJoin('users', 'wallet_transactions.user_id', '=', 'users.id')
            ->orderBy('wallet_transactions.id','DESC')->get();
        $data = array(
            'customers' => $customers,
            'walletTransactions' => $walletTransactions
        );
        return CommonHelper::responseWithData($data);
    }
    public function save(Request $request){
        $validator = Validator::make($request->all(),[
            'customer' => 'required',
            'type' => 'required',
            'amount' => 'required'
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $customerData = json_decode($request->customer);
        $walletTransactions = new WalletTransaction();
        $walletTransactions->user_id = $customerData->id;
        $walletTransactions->type = $request->type;
        $walletTransactions->amount	 = $request->amount;
        $walletTransactions->txn_id	 = 'admin';
        $walletTransactions->payment_type = 'admin';
        $walletTransactions->message = $request->message;
        $walletTransactions->status = 1;
        $walletTransactions->created_by_admin_id = auth()->user()->id ?? null;
        $walletTransactions->save();

        $customer = User::find($customerData->id);
        $customer->balance = ($request->type == 'debit')?($customer->balance - $request->amount):($customer->balance + $request->amount);
        $customer->save();
        return CommonHelper::responseSuccess("Wallet Transaction Saved Successfully!");
    }

    /**
     * Create PhonePe transaction for wallet recharge
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function createPhonePeTransaction(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'amount' => 'required|numeric|min:1',
                'mobile_number' => 'nullable|string',
                'redirect_url' => 'nullable|string',
                'callback_url' => 'nullable|string'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $user = auth()->user();
            if (!$user) {
                return CommonHelper::responseError('User not authenticated');
            }

            // Convert amount to paise (PhonePe requires amount in paise)
            $amountInPaise = (int) ($request->amount * 100);

            // Generate unique transaction ID
            $transactionId = 'TXN_' . $user->id . '_' . time() . '_' . mt_rand(1000, 9999);

            // Create transaction data for PhonePe
            $transactionData = [
                'amount' => $amountInPaise,
                'merchantTransactionId' => $transactionId,
                'merchantUserId' => 'USER_' . $user->id,
                'mobileNumber' => $request->mobile_number ?? $user->mobile ?? '',
                'redirectUrl' => $request->redirect_url ?? url('/phonepe/redirect'),
                'callbackUrl' => $request->callback_url ?? url('/api/phonepe/callback')
            ];

            // Create PhonePe transaction using helper
            $phonePeResponse = PhonePeHelper::createTransaction($transactionData);

            if (!$phonePeResponse['success']) {
                Log::error('PhonePe Transaction Creation Failed', [
                    'user_id' => $user->id,
                    'error' => $phonePeResponse['error']
                ]);
                return CommonHelper::responseError('Failed to create PhonePe transaction: ' . $phonePeResponse['error']);
            }

            // Store transaction in database with pending status
            DB::beginTransaction();
            try {
                $transaction = new Transaction();
                $transaction->user_id = $user->id;
                $transaction->order_id = 0; // 0 for wallet recharge
                $transaction->type = Transaction::$paymentTypePhonepe;
                $transaction->txn_id = $transactionId;
                $transaction->amount = $request->amount;
                $transaction->status = 'pending';
                $transaction->message = 'PhonePe wallet recharge initiated';
                $transaction->transaction_date = now();
                $transaction->save();

                DB::commit();

                Log::info('PhonePe Transaction Stored', [
                    'user_id' => $user->id,
                    'transaction_id' => $transactionId,
                    'amount' => $request->amount
                ]);

                return CommonHelper::responseWithData([
                    'body' => $phonePeResponse['body'],
                    'checksum' => $phonePeResponse['checksum'],
                    'transaction_id' => $transactionId,
                    'merchant_id' => PhonePeHelper::getMerchantId()
                ]);

            } catch (\Exception $e) {
                DB::rollBack();
                Log::error('Failed to store PhonePe transaction', [
                    'user_id' => $user->id,
                    'error' => $e->getMessage()
                ]);
                return CommonHelper::responseError('Failed to store transaction: ' . $e->getMessage());
            }

        } catch (\Exception $e) {
            Log::error('PhonePe Transaction Creation Exception', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('An error occurred: ' . $e->getMessage());
        }
    }

    /**
     * Verify PhonePe transaction and update wallet balance
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function verifyPhonePeTransaction(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'transaction_id' => 'required|string'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $user = auth()->user();
            if (!$user) {
                return CommonHelper::responseError('User not authenticated');
            }

            $transactionId = $request->transaction_id;

            // Find transaction in database
            $transaction = Transaction::where('txn_id', $transactionId)
                ->where('user_id', $user->id)
                ->first();

            if (!$transaction) {
                return CommonHelper::responseError('Transaction not found');
            }

            // If already successful, return success
            if ($transaction->status === Transaction::$statusSuccess) {
                return CommonHelper::responseWithData([
                    'payment_status' => 'SUCCESS',
                    'amount' => $transaction->amount,
                    'message' => 'Payment already verified'
                ]);
            }

            // Verify transaction with PhonePe
            $isProduction = config('services.phonepe.is_production', false);
            $verificationResponse = PhonePeHelper::verifyTransaction($transactionId, $isProduction);

            if (!$verificationResponse['success']) {
                Log::error('PhonePe Verification Failed', [
                    'user_id' => $user->id,
                    'transaction_id' => $transactionId,
                    'error' => $verificationResponse['error']
                ]);

                // Update transaction status to failed
                $transaction->status = Transaction::$statusFailed;
                $transaction->message = 'Payment verification failed: ' . ($verificationResponse['error'] ?? 'Unknown error');
                $transaction->save();

                return CommonHelper::responseError('Payment verification failed: ' . ($verificationResponse['error'] ?? 'Unknown error'));
            }

            $paymentData = $verificationResponse['data'];
            $paymentStatus = $paymentData['state'] ?? 'FAILED';

            DB::beginTransaction();
            try {
                if ($paymentStatus === 'COMPLETED') {
                    // Update transaction status
                    $transaction->status = Transaction::$statusSuccess;
                    $transaction->message = 'Payment successful';
                    $transaction->payu_txn_id = $paymentData['transactionId'] ?? '';
                    $transaction->save();

                    // Add amount to user's wallet
                    $user->balance = $user->balance + $transaction->amount;
                    $user->save();

                    // Create wallet transaction record
                    $walletTransaction = new WalletTransaction();
                    $walletTransaction->user_id = $user->id;
                    $walletTransaction->type = 'credit';
                    $walletTransaction->amount = $transaction->amount;
                    $walletTransaction->txn_id = $transactionId;
                    $walletTransaction->payment_type = Transaction::$paymentTypePhonepe;
                    $walletTransaction->message = 'Wallet recharged via PhonePe';
                    $walletTransaction->status = 1;
                    $walletTransaction->save();

                    DB::commit();

                    Log::info('PhonePe Payment Verified Successfully', [
                        'user_id' => $user->id,
                        'transaction_id' => $transactionId,
                        'amount' => $transaction->amount,
                        'new_balance' => $user->balance
                    ]);

                    return CommonHelper::responseWithData([
                        'payment_status' => 'SUCCESS',
                        'amount' => $transaction->amount,
                        'balance' => $user->balance,
                        'message' => 'Payment successful and wallet credited'
                    ]);

                } else {
                    // Payment failed or pending
                    $transaction->status = $paymentStatus === 'PENDING' ? 'pending' : Transaction::$statusFailed;
                    $transaction->message = 'Payment status: ' . $paymentStatus;
                    $transaction->save();

                    DB::commit();

                    return CommonHelper::responseError('Payment ' . strtolower($paymentStatus));
                }

            } catch (\Exception $e) {
                DB::rollBack();
                Log::error('Failed to update wallet after PhonePe verification', [
                    'user_id' => $user->id,
                    'transaction_id' => $transactionId,
                    'error' => $e->getMessage()
                ]);
                return CommonHelper::responseError('Failed to update wallet: ' . $e->getMessage());
            }

        } catch (\Exception $e) {
            Log::error('PhonePe Verification Exception', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('An error occurred: ' . $e->getMessage());
        }
    }
}
