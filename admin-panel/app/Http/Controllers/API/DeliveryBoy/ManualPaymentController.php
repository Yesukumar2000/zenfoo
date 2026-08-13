<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\DeliveryBoyManualPayment;
use App\Models\DeliveryBoy;
use App\Models\Setting;
use App\Helpers\CommonHelper;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use App\Services\AdminNotificationService;
use App\Services\MediaUploadService;
use Carbon\Carbon;

class ManualPaymentController extends Controller
{
    /**
     * Get admin payment details (UPI & bank)
     *
     * GET /api/delivery-boy/admin-payment-details
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getAdminPaymentDetails(Request $request)
    {
        try {
            $authUser = $request->user();
            $deliveryBoy = DeliveryBoy::where('admin_id', $authUser->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery boy profile not found");
            }

            // Resolve the uploaded Zenfoo QR image to a full URL (stored value may
            // already be an absolute URL, or a relative storage path).
            $qrImageValue = Setting::get_value('admin_qr_image');
            $qrImageUrl = null;
            if (!empty($qrImageValue)) {
                $qrImageUrl = str_starts_with($qrImageValue, 'http')
                    ? $qrImageValue
                    : asset('storage/' . $qrImageValue);
            }

            $paymentDetails = [
                'upi_id' => Setting::get_value('admin_upi_id'),
                'bank_details' => [
                    'bank_name' => Setting::get_value('admin_bank_name'),
                    'account_number' => Setting::get_value('admin_bank_account_number'),
                    'ifsc_code' => Setting::get_value('admin_bank_ifsc_code'),
                    'account_holder_name' => Setting::get_value('admin_bank_account_holder_name'),
                ],
                // Which deposit methods the admin has enabled (1 = on, 0 = off).
                'methods' => [
                    'bank' => (int) (Setting::get_value('deposit_method_bank') ?: 0),
                    'upi'  => (int) (Setting::get_value('deposit_method_upi') ?: 0),
                    'qr'   => (int) (Setting::get_value('deposit_method_qr') ?: 0),
                ],
                'qr_image' => $qrImageUrl,
            ];

            return CommonHelper::responseSuccessWithData("Admin payment details retrieved successfully", $paymentDetails);
        } catch (\Exception $e) {
            Log::error('Error fetching admin payment details: ' . $e->getMessage());
            return CommonHelper::responseError("Failed to fetch payment details");
        }
    }

    /**
     * Submit payment proof
     *
     * POST /api/delivery-boy/submit-payment-proof
     * Body: {
     *   "transaction_id": "UTR123456789",
     *   "amount": "500.00",
     *   "proof_image": file
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function submitPaymentProof(Request $request)
    {
        try {
            $authUser = $request->user();
            $deliveryBoy = DeliveryBoy::where('admin_id', $authUser->id)->first();

            if (!$deliveryBoy) {
                Log::error('Delivery boy profile not found', ['user_id' => $authUser->id]);
                return CommonHelper::responseError("Delivery boy profile not found");
            }

            Log::info('=== Manual Payment Submission Started ===', [
                'delivery_boy_id' => $deliveryBoy->id,
                'delivery_boy_name' => $deliveryBoy->name,
                'request_data' => $request->except('proof_image')
            ]);

            // Validate input
            $validator = Validator::make($request->all(), [
                'transaction_id' => 'required|string|max:255',
                'amount' => 'required|numeric|min:1',
                'proof_image' => 'required|image|mimes:jpeg,png,jpg|max:5120', // 5MB max
            ]);

            if ($validator->fails()) {
                Log::warning('Validation failed for manual payment', [
                    'errors' => $validator->errors()->toArray(),
                    'delivery_boy_id' => $deliveryBoy->id
                ]);
                return CommonHelper::responseError($validator->errors()->first());
            }

            Log::info('Validation passed');

            // Upload proof image using MediaUploadService
            $proofImageUrl = null;
            if ($request->hasFile('proof_image')) {
                Log::info('Proof image file detected', [
                    'original_name' => $request->file('proof_image')->getClientOriginalName(),
                    'size' => $request->file('proof_image')->getSize(),
                    'mime_type' => $request->file('proof_image')->getMimeType()
                ]);

                try {
                    $proofImageUrl = MediaUploadService::upload(
                        $request->file('proof_image'),
                        'payment_proofs',
                        'public'
                    );

                    Log::info('Image uploaded successfully', [
                        'url' => $proofImageUrl
                    ]);
                } catch (\Exception $e) {
                    Log::error('Image upload failed', [
                        'error' => $e->getMessage(),
                        'trace' => $e->getTraceAsString()
                    ]);
                    return CommonHelper::responseError("Failed to upload proof image: " . $e->getMessage());
                }
            } else {
                Log::warning('No proof image file in request');
            }

            // Create manual payment record
            Log::info('Creating payment record in database');
            try {
                $payment = DeliveryBoyManualPayment::create([
                    'delivery_boy_id' => $deliveryBoy->id,
                    'transaction_id' => $request->transaction_id,
                    'amount' => $request->amount,
                    'proof_image' => $proofImageUrl,
                    'status' => 'pending',
                ]);

                Log::info('Payment record created successfully', [
                    'payment_id' => $payment->id,
                    'transaction_id' => $payment->transaction_id,
                    'amount' => $payment->amount
                ]);
            } catch (\Exception $e) {
                Log::error('Failed to create payment record', [
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString()
                ]);
                return CommonHelper::responseError("Failed to create payment record: " . $e->getMessage());
            }

            // Send notification to admin
            try {
                $actionUrl = url('/admin/manual-payments/' . $payment->id);

                AdminNotificationService::send(
                    adminIds: null, // Send to all admins
                    title: "New Manual Payment Submission",
                    message: "Driver #{$deliveryBoy->id} - {$deliveryBoy->name} submitted payment proof for ₹{$request->amount}. Transaction ID: {$request->transaction_id}",
                    type: 'manual_payment_submitted',
                    data: [
                        'payment_id' => $payment->id,
                        'delivery_boy_id' => $deliveryBoy->id,
                        'delivery_boy_name' => $deliveryBoy->name,
                        'amount' => $request->amount,
                        'transaction_id' => $request->transaction_id,
                        'click_action' => $actionUrl
                    ]
                );

                Log::info('Manual payment notification sent to admin successfully', [
                    'payment_id' => $payment->id
                ]);
            } catch (\Exception $e) {
                // Log notification failure but don't break the flow
                Log::warning('Failed to send manual payment notification to admin', [
                    'error' => $e->getMessage(),
                    'payment_id' => $payment->id
                ]);
            }

            Log::info('=== Manual Payment Submission Completed Successfully ===', [
                'payment_id' => $payment->id
            ]);

            return CommonHelper::responseSuccessWithData(
                "Payment proof submitted successfully. Awaiting admin approval.",
                $payment
            );
        } catch (\Exception $e) {
            $userId = null;
            try {
                $userId = $request->user()->id ?? null;
            } catch (\Exception $userError) {
                // User not authenticated
            }

            Log::error('=== CRITICAL ERROR in submitPaymentProof ===', [
                'error_message' => $e->getMessage(),
                'error_file' => $e->getFile(),
                'error_line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
                'user_id' => $userId ?? 'unknown'
            ]);
            return CommonHelper::responseError("Failed to submit payment proof: " . $e->getMessage());
        }
    }

    /**
     * Get payment history for the logged-in delivery boy
     *
     * GET /api/delivery-boy/manual-payment-history
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getPaymentHistory(Request $request)
    {
        try {
            $authUser = $request->user();
            $deliveryBoy = DeliveryBoy::where('admin_id', $authUser->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery boy profile not found");
            }

            $period = $request->period ?? 'weekly';
            $offset = (int) ($request->offset ?? 0);
            $limit = (int) ($request->limit ?? 5);
            $page = (int) ($request->page ?? 1);
            $paginationSkip = ($page - 1) * $limit;

            // Calculate date range
            $now = Carbon::now();
            $startDate = null;
            $endDate = null;
            $periodName = '';

            if ($period === 'daily') {
                $startDate = $now->clone()->addDays($offset)->startOfDay();
                $endDate = $startDate->clone()->endOfDay();
                $periodName = $startDate->format('D, M d, Y');
            } elseif ($period === 'weekly') {
                $currentWeekStart = $now->clone()->startOfWeek();
                $startDate = $currentWeekStart->clone()->addWeeks($offset);
                $endDate = $startDate->clone()->endOfWeek();
                $periodName = $startDate->format('M d') . ' - ' . $endDate->format('M d, Y');
            } else {
                $currentMonthStart = $now->clone()->startOfMonth();
                $startDate = $currentMonthStart->clone()->addMonths($offset);
                $endDate = $startDate->clone()->endOfMonth();
                $periodName = $startDate->format('F Y');
            }

            // Base query
            $baseQuery = DeliveryBoyManualPayment::where('delivery_boy_id', $deliveryBoy->id)
                ->whereDate('created_at', '>=', $startDate->toDateString())
                ->whereDate('created_at', '<=', $endDate->toDateString());

            // Summary
            $totalCount = $baseQuery->count();
            $totalAmount = (float) $baseQuery->sum('amount');
            $approvedAmount = (float) (clone $baseQuery)->where('status', 'approved')->sum('amount');
            $pendingAmount = (float) (clone $baseQuery)->where('status', 'pending')->sum('amount');

            // Paginated results
            $payments = (clone $baseQuery)
                ->orderBy('created_at', 'desc')
                ->skip($paginationSkip)
                ->take($limit)
                ->get()
                ->map(function ($payment) {
                    $proofImageUrl = null;
                    if ($payment->proof_image) {
                        if (str_starts_with($payment->proof_image, 'http')) {
                            $proofImageUrl = $payment->proof_image;
                        } else {
                            $proofImageUrl = asset('storage/' . $payment->proof_image);
                        }
                    }

                    return [
                        'id' => $payment->id,
                        'transaction_id' => $payment->transaction_id,
                        'amount' => (float) $payment->amount,
                        'status' => $payment->status,
                        'proof_image' => $proofImageUrl,
                        'admin_notes' => $payment->admin_notes,
                        'submitted_at' => $payment->created_at->format('Y-m-d H:i:s'),
                        'approved_at' => $payment->approved_at ? $payment->approved_at->format('Y-m-d H:i:s') : null,
                    ];
                });

            return CommonHelper::responseWithData([
                'period' => $period,
                'period_name' => $periodName,
                'start_date' => $startDate->toDateString(),
                'end_date' => $endDate->toDateString(),
                'summary' => [
                    'total_payments' => $totalCount,
                    'total_amount' => (float) round($totalAmount, 2),
                    'approved_amount' => (float) round($approvedAmount, 2),
                    'pending_amount' => (float) round($pendingAmount, 2),
                ],
                'pagination' => [
                    'total' => $totalCount,
                    'page' => $page,
                    'limit' => $limit,
                    'total_pages' => (int) ceil($totalCount / max($limit, 1)),
                ],
                'payments' => $payments,
            ]);
        } catch (\Exception $e) {
            Log::error('Error fetching payment history: ' . $e->getMessage());
            return CommonHelper::responseError("Failed to fetch payment history");
        }
    }
}
