<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Services\ReversePennyDropService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class BankVerificationController extends Controller
{
    /**
     * Get authenticated delivery boy from token
     *
     * @return array ['success' => bool, 'delivery_boy' => DeliveryBoy|null, 'error' => string|null]
     */
    private function getAuthenticatedDeliveryBoy()
    {
        // Get authenticated user from token
        $driver_data_admin = auth()->guard('api')->user();

        if (!$driver_data_admin) {
            return [
                'success' => false,
                'delivery_boy' => null,
                'error' => 'Unauthorized. Please login again.'
            ];
        }

        // Get delivery boy linked to this admin
        $deliveryBoy = DeliveryBoy::where('admin_id', $driver_data_admin->id)->first();

        if (!$deliveryBoy) {
            return [
                'success' => false,
                'delivery_boy' => null,
                'error' => 'Delivery boy not found'
            ];
        }

        return [
            'success' => true,
            'delivery_boy' => $deliveryBoy,
            'error' => null
        ];
    }

    /**
     * Initiate bank verification via Reverse Penny Drop
     * Driver will pay ₹1 to verify their bank account
     * Uses auth token to identify delivery boy
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function initiateVerification(Request $request)
    {
        try {
            // Get authenticated delivery boy
            $authResult = $this->getAuthenticatedDeliveryBoy();

            if (!$authResult['success']) {
                return response()->json([
                    'status' => 0,
                    'message' => $authResult['error']
                ], 401);
            }

            $deliveryBoy = $authResult['delivery_boy'];
            $deliveryBoyId = $deliveryBoy->id;

            Log::info('Bank Verification: Initiation request received', [
                'delivery_boy_id' => $deliveryBoyId,
                'delivery_boy_name' => $deliveryBoy->name
            ]);

            // Check if already verified
            $verificationStatus = ReversePennyDropService::getVerificationStatus($deliveryBoyId);

            if ($verificationStatus['success'] && isset($verificationStatus['verified']) && $verificationStatus['verified']) {
                return CommonHelper::responseError('Bank account is already verified.');
            }

            // Build callback and redirect URLs
            $baseUrl = config('app.url');
            $redirectUrl = $baseUrl . '/api/bank-verification/redirect';
            $callbackUrl = $baseUrl . '/api/bank-verification/callback';

            // Initiate verification
            $result = ReversePennyDropService::initiateVerification(
                $deliveryBoyId,
                $redirectUrl,
                $callbackUrl
            );

            if (!$result['success']) {
                Log::error('Bank Verification: Initiation failed', [
                    'delivery_boy_id' => $deliveryBoyId,
                    'error' => $result['error']
                ]);
                return CommonHelper::responseError($result['error']);
            }

            Log::info('Bank Verification: Initiated successfully', [
                'delivery_boy_id' => $deliveryBoyId,
                'transaction_id' => $result['data']['transaction_id']
            ]);

            return CommonHelper::responseWithData([
                'message' => 'Verification initiated. Please complete the ₹1 payment.',
                'transaction_id' => $result['data']['transaction_id'],
                'payment_url' => $result['data']['payment_url'],
                'amount' => $result['data']['amount']
            ]);

        } catch (Exception $e) {
            Log::error('Bank Verification: Exception during initiation', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to initiate bank verification.');
        }
    }

    /**
     * Check verification status
     * Uses auth token to identify delivery boy
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function checkStatus(Request $request)
    {
        try {
            // If transaction ID provided, check payment status (no auth needed for this)
            if ($request->has('transaction_id') && $request->transaction_id) {
                $result = ReversePennyDropService::checkPaymentStatus($request->transaction_id);

                if ($result['success']) {
                    return CommonHelper::responseWithData([
                        'verified' => true,
                        'message' => 'Bank account verified successfully',
                        'bank_details' => $result['data']['bank_details'] ?? []
                    ]);
                }

                // Return current status
                return CommonHelper::responseWithData([
                    'verified' => false,
                    'status' => $result['status'] ?? 'pending',
                    'message' => $result['error'] ?? 'Verification pending'
                ]);
            }

            // Get authenticated delivery boy
            $authResult = $this->getAuthenticatedDeliveryBoy();

            if (!$authResult['success']) {
                return response()->json([
                    'status' => 0,
                    'message' => $authResult['error']
                ], 401);
            }

            $deliveryBoy = $authResult['delivery_boy'];

            // Get overall verification status for this delivery boy
            $result = ReversePennyDropService::getVerificationStatus($deliveryBoy->id);

            if (!$result['success']) {
                return CommonHelper::responseError($result['error']);
            }

            return CommonHelper::responseWithData($result);

        } catch (Exception $e) {
            Log::error('Bank Verification: Exception checking status', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to check verification status.');
        }
    }

    /**
     * Get my bank verification details
     * Uses auth token to identify delivery boy
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getMyVerificationStatus(Request $request)
    {
        try {
            // Get authenticated delivery boy
            $authResult = $this->getAuthenticatedDeliveryBoy();

            if (!$authResult['success']) {
                return response()->json([
                    'status' => 0,
                    'message' => $authResult['error']
                ], 401);
            }

            $deliveryBoy = $authResult['delivery_boy'];

            $result = ReversePennyDropService::getVerificationStatus($deliveryBoy->id);

            if (!$result['success']) {
                return CommonHelper::responseError($result['error']);
            }

            return CommonHelper::responseWithData($result);

        } catch (Exception $e) {
            Log::error('Bank Verification: Exception getting my status', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to get verification status.');
        }
    }

    /**
     * Handle PhonePe callback/webhook
     * No auth required - PhonePe sends this directly
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function handleCallback(Request $request)
    {
        try {
            Log::info('Bank Verification: Callback received', [
                'all_data' => $request->all()
            ]);

            $callbackData = [
                'response' => $request->input('response'),
                'checksum' => $request->header('X-VERIFY') ?? $request->input('checksum')
            ];

            $result = ReversePennyDropService::handleCallback($callbackData);

            if ($result['success']) {
                Log::info('Bank Verification: Callback processed successfully');
                return response()->json(['success' => true], 200);
            }

            Log::warning('Bank Verification: Callback processing failed', [
                'error' => $result['error']
            ]);

            return response()->json(['success' => false], 200);

        } catch (Exception $e) {
            Log::error('Bank Verification: Exception handling callback', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return response()->json(['success' => false], 200);
        }
    }

    /**
     * Handle redirect after payment
     * No auth required - user is redirected here from PhonePe
     *
     * @param Request $request
     * @return \Illuminate\Http\RedirectResponse|\Illuminate\View\View
     */
    public function handleRedirect(Request $request)
    {
        try {
            Log::info('Bank Verification: Redirect received', [
                'all_data' => $request->all()
            ]);

            $transactionId = $request->input('txnId') ?? $request->input('transactionId');

            if (!$transactionId) {
                Log::warning('Bank Verification: No transaction ID in redirect');
                return redirect('/bank-verification-result?status=error&message=Invalid transaction');
            }

            // Check payment status
            $result = ReversePennyDropService::checkPaymentStatus($transactionId);

            if ($result['success']) {
                Log::info('Bank Verification: Payment successful via redirect', [
                    'transaction_id' => $transactionId
                ]);
                return redirect('/bank-verification-result?status=success&txnId=' . $transactionId);
            }

            Log::info('Bank Verification: Payment not successful via redirect', [
                'transaction_id' => $transactionId,
                'status' => $result['status'] ?? 'unknown'
            ]);

            $status = $result['status'] ?? 'pending';
            return redirect('/bank-verification-result?status=' . $status . '&txnId=' . $transactionId);

        } catch (Exception $e) {
            Log::error('Bank Verification: Exception handling redirect', [
                'error' => $e->getMessage()
            ]);
            return redirect('/bank-verification-result?status=error&message=Processing error');
        }
    }

    /**
     * Get verification details for a specific delivery boy (Admin use)
     * For admin panel - uses delivery boy ID from URL
     *
     * @param int $id Delivery boy ID
     * @return \Illuminate\Http\JsonResponse
     */
    public function getVerificationDetails($id)
    {
        try {
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError('Invalid delivery boy ID.');
            }

            $result = ReversePennyDropService::getVerificationStatus($id);

            if (!$result['success']) {
                return CommonHelper::responseError($result['error']);
            }

            return CommonHelper::responseWithData($result);

        } catch (Exception $e) {
            Log::error('Bank Verification: Exception getting details', [
                'delivery_boy_id' => $id,
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to get verification details.');
        }
    }
}
