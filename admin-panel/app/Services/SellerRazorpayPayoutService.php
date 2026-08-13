<?php

namespace App\Services;

use App\Models\Seller;
use App\Models\SellerWalletTransaction;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

class SellerRazorpayPayoutService
{
    // Payout status constants
    const PAYOUT_STATUS_PENDING = 'pending';
    const PAYOUT_STATUS_SUCCESS = 'success';
    const PAYOUT_STATUS_FAILED = 'failed';
    const PAYOUT_STATUS_PROCESSING = 'processing';

    /**
     * Process payout to seller's bank account using RazorpayX
     *
     * @param int $sellerId
     * @param array $transactionIds Array of transaction IDs to settle
     * @param float $totalAmount Total amount to pay
     * @return array
     */
    public static function processPayoutToSeller($sellerId, $transactionIds, $totalAmount)
    {
        try {
            Log::info('Seller RazorpayX Payout: Starting payout process', [
                'seller_id' => $sellerId,
                'transaction_ids' => $transactionIds,
                'total_amount' => $totalAmount
            ]);

            // Validate input
            if (empty($transactionIds)) {
                return [
                    'success' => false,
                    'error' => 'No transactions selected for payout'
                ];
            }

            if ($totalAmount <= 0) {
                return [
                    'success' => false,
                    'error' => 'Invalid payout amount'
                ];
            }

            // Get seller details
            $seller = Seller::find($sellerId);
            if (!$seller) {
                return [
                    'success' => false,
                    'error' => 'Seller not found'
                ];
            }

            // Get bank details
            $bankDetails = self::getSellerBankDetails($sellerId);
            if (!$bankDetails['success']) {
                return $bankDetails;
            }

            // Generate unique payout transaction ID
            $payoutTransactionId = self::generatePayoutTransactionId($sellerId);

            Log::info('Seller RazorpayX Payout: Bank details retrieved', [
                'seller_id' => $sellerId,
                'payout_transaction_id' => $payoutTransactionId,
                'bank_name' => $bankDetails['data']['bank_name'],
                'account_holder_name' => $bankDetails['data']['account_holder_name'],
                'account_number_masked' => self::maskAccountNumber($bankDetails['data']['account_number']),
                'ifsc_code' => $bankDetails['data']['ifsc_code']
            ]);

            // Prepare beneficiary data for RazorpayX
            $beneficiary = [
                'name' => $bankDetails['data']['account_holder_name'],
                'account_number' => $bankDetails['data']['account_number'],
                'ifsc' => $bankDetails['data']['ifsc_code'],
                'email' => $seller->email ?? null,
                'phone' => $seller->phone ?? null,
                'type' => 'vendor',
                'narration' => 'Seller Payout ' . $payoutTransactionId
            ];

            // Create payout using RazorpayX
            $payoutResult = RazorpayPayoutService::createPayout(
                $beneficiary,
                $totalAmount,
                'vendor_bill',
                $payoutTransactionId
            );

            if (!$payoutResult['success']) {
                Log::error('Seller RazorpayX Payout: Payout creation failed', [
                    'seller_id' => $sellerId,
                    'payout_transaction_id' => $payoutTransactionId,
                    'error' => $payoutResult['error']
                ]);
                return $payoutResult;
            }

            // Create payout record and mark transactions as paid
            $payoutRecord = self::createPayoutRecord(
                $sellerId,
                $payoutTransactionId,
                $transactionIds,
                $totalAmount,
                $payoutResult
            );

            Log::info('Seller RazorpayX Payout: Payout initiated successfully', [
                'seller_id' => $sellerId,
                'payout_transaction_id' => $payoutTransactionId,
                'razorpay_payout_id' => $payoutResult['data']['payout_id'] ?? null,
                'amount' => $totalAmount
            ]);

            return [
                'success' => true,
                'message' => 'Payout initiated successfully',
                'data' => [
                    'payout_transaction_id' => $payoutTransactionId,
                    'razorpay_payout_id' => $payoutResult['data']['payout_id'] ?? null,
                    'amount' => $totalAmount,
                    'status' => self::PAYOUT_STATUS_PROCESSING,
                    'utr' => $payoutResult['data']['utr'] ?? null,
                    'razorpay_response' => $payoutResult['data'] ?? []
                ]
            ];

        } catch (\Exception $e) {
            Log::error('Seller RazorpayX Payout: Exception during payout process', [
                'seller_id' => $sellerId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'error' => 'Payout processing failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Get bank details for seller from seller_bank_accounts table
     */
    public static function getSellerBankDetails($sellerId)
    {
        try {
            Log::info('Seller RazorpayX Payout: Fetching bank details', [
                'seller_id' => $sellerId
            ]);

            $bankDetails = DB::table('seller_bank_accounts')
                ->where('seller_id', $sellerId)
                ->where('is_default', 1)
                ->select([
                    'bank_name',
                    'account_holder_name',
                    'account_number',
                    'ifsc_code',
                    'is_verified'
                ])
                ->first();

            if (!$bankDetails) {
                // Try to get any bank account if no default is set
                $bankDetails = DB::table('seller_bank_accounts')
                    ->where('seller_id', $sellerId)
                    ->select([
                        'bank_name',
                        'account_holder_name',
                        'account_number',
                        'ifsc_code',
                        'is_verified'
                    ])
                    ->first();
            }

            if (!$bankDetails) {
                Log::warning('Seller RazorpayX Payout: No bank details found', [
                    'seller_id' => $sellerId
                ]);
                return [
                    'success' => false,
                    'error' => 'Bank details not found for this seller. Please add bank account first.'
                ];
            }

            // Validate required fields
            $requiredFields = ['bank_name', 'account_holder_name', 'account_number', 'ifsc_code'];
            foreach ($requiredFields as $field) {
                if (empty($bankDetails->$field)) {
                    return [
                        'success' => false,
                        'error' => 'Missing required bank detail: ' . str_replace('_', ' ', $field)
                    ];
                }
            }

            // Validate IFSC code format (11 characters)
            if (strlen($bankDetails->ifsc_code) !== 11) {
                return [
                    'success' => false,
                    'error' => 'Invalid IFSC code format'
                ];
            }

            return [
                'success' => true,
                'data' => [
                    'bank_name' => $bankDetails->bank_name,
                    'account_holder_name' => $bankDetails->account_holder_name,
                    'account_number' => $bankDetails->account_number,
                    'ifsc_code' => $bankDetails->ifsc_code,
                    'is_verified' => $bankDetails->is_verified ?? false
                ]
            ];

        } catch (\Exception $e) {
            Log::error('Seller RazorpayX Payout: Exception fetching bank details', [
                'seller_id' => $sellerId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'error' => 'Failed to fetch bank details: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Create payout record and update transactions as paid
     */
    private static function createPayoutRecord($sellerId, $payoutTransactionId, $transactionIds, $amount, $payoutResult)
    {
        try {
            DB::beginTransaction();

            // Mark all selected transactions as paid
            SellerWalletTransaction::whereIn('id', $transactionIds)
                ->where('seller_id', $sellerId)
                ->update([
                    'is_paid_to_seller' => true,
                    'payment_transaction_id' => $payoutTransactionId,
                    'paid_at' => Carbon::now(),
                    'paid_by' => auth()->id()
                ]);

            DB::commit();

            Log::info('Seller RazorpayX Payout: Transactions marked as paid', [
                'seller_id' => $sellerId,
                'payout_transaction_id' => $payoutTransactionId,
                'transaction_count' => count($transactionIds)
            ]);

            return true;

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Seller RazorpayX Payout: Failed to create payout record', [
                'seller_id' => $sellerId,
                'error' => $e->getMessage()
            ]);
            return false;
        }
    }

    /**
     * Check payout status from RazorpayX
     */
    public static function checkPayoutStatus($razorpayPayoutId)
    {
        try {
            $result = RazorpayPayoutService::getPayoutStatus($razorpayPayoutId);

            if ($result['success']) {
                return [
                    'success' => true,
                    'data' => [
                        'status' => RazorpayPayoutService::mapStatus($result['data']['status']),
                        'razorpay_status' => $result['data']['status'],
                        'utr' => $result['data']['utr'] ?? null
                    ]
                ];
            }

            return $result;

        } catch (\Exception $e) {
            Log::error('Seller RazorpayX Payout: Exception checking status', [
                'razorpay_payout_id' => $razorpayPayoutId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'error' => 'Failed to check payout status'
            ];
        }
    }

    /**
     * Generate unique payout transaction ID
     */
    private static function generatePayoutTransactionId($sellerId)
    {
        $timestamp = Carbon::now()->format('YmdHis');
        $random = strtoupper(substr(md5(uniqid(mt_rand(), true)), 0, 6));
        return "SRPO_{$sellerId}_{$timestamp}_{$random}";
    }

    /**
     * Mask account number for logging (show last 4 digits)
     */
    private static function maskAccountNumber($accountNumber)
    {
        if (strlen($accountNumber) <= 4) {
            return '****';
        }
        return str_repeat('*', strlen($accountNumber) - 4) . substr($accountNumber, -4);
    }
}
