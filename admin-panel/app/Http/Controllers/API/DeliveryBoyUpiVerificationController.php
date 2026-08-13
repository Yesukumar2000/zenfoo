<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Services\PaytmPaymentCaptureService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class DeliveryBoyUpiVerificationController extends Controller
{
    /**
     * Verify delivery boy's UPI ID with Paytm transaction
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function verifyUpi(Request $request)
    {
        try {
            // Validation
            $validator = Validator::make($request->all(), [
                'delivery_boy_id' => 'required|exists:delivery_boys,id',
                'upi_id' => 'required|string|max:100',
                'paytm_order_id' => 'required|string|max:255'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Validate UPI ID format
            $upiValidation = $this->validateUpiId($request->upi_id);
            if (!$upiValidation['valid']) {
                return CommonHelper::responseError($upiValidation['error']);
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::findOrFail($request->delivery_boy_id);

            // Check if UPI ID already verified for another delivery boy
            $existingUpi = DeliveryBoy::where('upi_id', $request->upi_id)
                ->where('is_upi_verified', 1)
                ->where('id', '!=', $deliveryBoy->id)
                ->first();

            if ($existingUpi) {
                return CommonHelper::responseError('This UPI ID is already verified with another delivery boy');
            }

            Log::info('Delivery Boy UPI Verification Started', [
                'delivery_boy_id' => $deliveryBoy->id,
                'upi_id' => $request->upi_id,
                'paytm_order_id' => $request->paytm_order_id
            ]);

            // Verify payment with Paytm
            $paymentVerification = PaytmPaymentCaptureService::verifyPayment(
                $request->paytm_order_id,
                1.00 // Expected amount is ₹1
            );

            if (!$paymentVerification['success']) {
                Log::error('Paytm Verification Failed for Delivery Boy', [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'error' => $paymentVerification['error']
                ]);

                return CommonHelper::responseError(
                    $paymentVerification['error'] ?? 'Payment verification failed. Please try again.'
                );
            }

            $paymentData = $paymentVerification['data'];

            // Validate payment mode is UPI
            if (isset($paymentData['payment_mode']) &&
                strtoupper($paymentData['payment_mode']) !== 'UPI') {
                return CommonHelper::responseError(
                    'Payment must be made via UPI. Payment mode detected: ' . $paymentData['payment_mode']
                );
            }

            // Start transaction to update delivery boy
            DB::beginTransaction();

            try {
                // Prepare payment information JSON
                $paymentInfo = [
                    'verification_transaction' => $paymentData,
                    'verified_at' => now()->toDateTimeString(),
                    'verification_method' => 'paytm_upi_1_rupee'
                ];

                // Update delivery boy
                $deliveryBoy->update([
                    'upi_id' => $request->upi_id,
                    'upi_verification_transaction_id' => $paymentData['transaction_id'],
                    'other_payment_information' => json_encode($paymentInfo),
                    'is_upi_verified' => 1,
                    'upi_verified_at' => now(),
                    'payment_mode' => 'UPI'
                ]);

                DB::commit();

                Log::info('Delivery Boy UPI Verified Successfully', [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'upi_id' => $request->upi_id,
                    'transaction_id' => $paymentData['transaction_id']
                ]);

                return CommonHelper::responseWithData([
                    'message' => 'UPI ID verified successfully',
                    'delivery_boy' => $deliveryBoy->fresh(),
                    'verification_details' => [
                        'upi_id' => $deliveryBoy->upi_id,
                        'verified_at' => $deliveryBoy->upi_verified_at,
                        'transaction_id' => $paymentData['transaction_id'],
                        'amount_paid' => $paymentData['amount']
                    ]
                ]);

            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
            }

        } catch (\Exception $e) {
            Log::error('Delivery Boy UPI Verification Error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return CommonHelper::responseError('Failed to verify UPI ID. Please try again.');
        }
    }

    /**
     * Validate UPI ID format
     *
     * @param string $upiId
     * @return array
     */
    private function validateUpiId($upiId)
    {
        // UPI ID format: username@provider
        // Examples: 9876543210@paytm, name@ybl, user@oksbi

        if (empty($upiId)) {
            return [
                'valid' => false,
                'error' => 'UPI ID cannot be empty'
            ];
        }

        // Check basic format: should contain @ symbol
        if (strpos($upiId, '@') === false) {
            return [
                'valid' => false,
                'error' => 'Invalid UPI ID format. UPI ID must contain @ symbol (e.g., 9876543210@paytm)'
            ];
        }

        // Split by @ symbol
        $parts = explode('@', $upiId);

        // Should have exactly 2 parts
        if (count($parts) !== 2) {
            return [
                'valid' => false,
                'error' => 'Invalid UPI ID format. Format should be: username@provider'
            ];
        }

        list($username, $provider) = $parts;

        // Validate username (before @)
        if (empty($username) || strlen($username) < 3) {
            return [
                'valid' => false,
                'error' => 'UPI ID username must be at least 3 characters'
            ];
        }

        // Validate provider (after @)
        if (empty($provider) || strlen($provider) < 2) {
            return [
                'valid' => false,
                'error' => 'Invalid UPI ID provider'
            ];
        }

        // Check for valid characters (alphanumeric, dots, underscores, hyphens)
        if (!preg_match('/^[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+$/', $upiId)) {
            return [
                'valid' => false,
                'error' => 'UPI ID contains invalid characters. Only letters, numbers, dots, underscores and hyphens are allowed'
            ];
        }

        return [
            'valid' => true
        ];
    }

    /**
     * Get UPI verification status for a delivery boy
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getVerificationStatus(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'delivery_boy_id' => 'required|exists:delivery_boys,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $deliveryBoy = DeliveryBoy::findOrFail($request->delivery_boy_id);

            $status = [
                'is_verified' => (bool) $deliveryBoy->is_upi_verified,
                'upi_id' => $deliveryBoy->upi_id,
                'verified_at' => $deliveryBoy->upi_verified_at,
                'payment_mode' => $deliveryBoy->payment_mode
            ];

            // Parse payment information if exists
            if ($deliveryBoy->other_payment_information) {
                try {
                    $paymentInfo = json_decode($deliveryBoy->other_payment_information, true);
                    if (isset($paymentInfo['verification_transaction'])) {
                        $status['verification_transaction_id'] = $paymentInfo['verification_transaction']['transaction_id'] ?? null;
                    }
                } catch (\Exception $e) {
                    // Ignore JSON parse errors
                }
            }

            return CommonHelper::responseWithData($status);

        } catch (\Exception $e) {
            Log::error('Get UPI Verification Status Error', [
                'error' => $e->getMessage()
            ]);

            return CommonHelper::responseError('Failed to fetch verification status');
        }
    }

    /**
     * Re-verify UPI ID (for updating UPI ID)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function reVerifyUpi(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'delivery_boy_id' => 'required|exists:delivery_boys,id',
                'new_upi_id' => 'required|string|max:100',
                'paytm_order_id' => 'required|string|max:255'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Reset verification status first
            $deliveryBoy = DeliveryBoy::findOrFail($request->delivery_boy_id);
            $deliveryBoy->update([
                'is_upi_verified' => 0,
                'upi_verified_at' => null
            ]);

            // Call verify with new UPI ID
            $request->merge(['upi_id' => $request->new_upi_id]);
            return $this->verifyUpi($request);

        } catch (\Exception $e) {
            Log::error('Re-verify UPI Error', [
                'error' => $e->getMessage()
            ]);

            return CommonHelper::responseError('Failed to re-verify UPI ID');
        }
    }
}