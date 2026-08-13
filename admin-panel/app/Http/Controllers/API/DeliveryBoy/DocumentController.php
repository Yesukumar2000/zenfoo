<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyDocument;
use App\Services\AdminNotificationService;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class DocumentController extends Controller
{
    /**
     * Upload all documents (initial submission)
     *
     * POST /api/delivery_boy/upload-all-documents
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function uploadAllDocuments(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Validation rules
            $validator = Validator::make($request->all(), [
                'driving_license_number' => 'required|string|max:50',
                'driving_license_front' => 'required|image|mimes:jpeg,jpg,png|max:5120',
                'driving_license_back' => 'required|image|mimes:jpeg,jpg,png|max:5120',
                'rc_number' => 'required|string|max:50',
                'rc_front' => 'required|image|mimes:jpeg,jpg,png|max:5120',
                'rc_back' => 'required|image|mimes:jpeg,jpg,png|max:5120',
                'aadhar_number' => 'required|digits:12',
                'aadhar_front' => 'required|image|mimes:jpeg,jpg,png|max:5120',
                'aadhar_back' => 'required|image|mimes:jpeg,jpg,png|max:5120',
                'pan_number' => 'required|string|size:10|regex:/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/',
                'pan_front' => 'required|image|mimes:jpeg,jpg,png|max:5120',
                'pan_back' => 'required|image|mimes:jpeg,jpg,png|max:5120',
                'bank_name' => 'required|string|max:100',
                'account_holder_name' => 'required|string|max:100',
                'account_number' => 'required|string|max:50',
                'ifsc_code' => 'required|string|size:11|regex:/^[A-Z]{4}0[A-Z0-9]{6}$/',
                'bank_passbook_image' => 'required|image|mimes:jpeg,jpg,png|max:5120',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Check if documents already exist
            $document = DeliveryBoyDocument::where('delivery_boy_id', $deliveryBoy->id)->first();

            if ($document) {
                return CommonHelper::responseError('Documents already uploaded. Use update-documents API to modify.');
            }

            // Create new document record
            $document = new DeliveryBoyDocument();
            $document->delivery_boy_id = $deliveryBoy->id;

            // Upload driving license
            $document->driving_license_number = $request->driving_license_number;
            if ($request->hasFile('driving_license_front')) {
                $document->driving_license_front_path = MediaUploadService::upload(
                    $request->file('driving_license_front'),
                    'delivery_boy/documents/driving_license'
                );
            }
            if ($request->hasFile('driving_license_back')) {
                $document->driving_license_back_path = MediaUploadService::upload(
                    $request->file('driving_license_back'),
                    'delivery_boy/documents/driving_license'
                );
            }
            $document->driving_license_status = 'pending_verification';

            // Upload RC
            $document->rc_number = $request->rc_number;
            if ($request->hasFile('rc_front')) {
                $document->rc_front_path = MediaUploadService::upload(
                    $request->file('rc_front'),
                    'delivery_boy/documents/rc'
                );
            }
            if ($request->hasFile('rc_back')) {
                $document->rc_back_path = MediaUploadService::upload(
                    $request->file('rc_back'),
                    'delivery_boy/documents/rc'
                );
            }
            $document->rc_status = 'pending_verification';

            // Upload Aadhar
            $document->aadhar_number = $request->aadhar_number;
            if ($request->hasFile('aadhar_front')) {
                $document->aadhar_front_path = MediaUploadService::upload(
                    $request->file('aadhar_front'),
                    'delivery_boy/documents/aadhar'
                );
            }
            if ($request->hasFile('aadhar_back')) {
                $document->aadhar_back_path = MediaUploadService::upload(
                    $request->file('aadhar_back'),
                    'delivery_boy/documents/aadhar'
                );
            }
            $document->aadhar_status = 'pending_verification';

            // Upload PAN
            $document->pan_number = $request->pan_number;
            if ($request->hasFile('pan_front')) {
                $document->pan_front_path = MediaUploadService::upload(
                    $request->file('pan_front'),
                    'delivery_boy/documents/pan'
                );
            }
            if ($request->hasFile('pan_back')) {
                $document->pan_back_path = MediaUploadService::upload(
                    $request->file('pan_back'),
                    'delivery_boy/documents/pan'
                );
            }
            $document->pan_status = 'pending_verification';

            // Upload Bank Details
            $document->bank_name = $request->bank_name;
            $document->account_holder_name = $request->account_holder_name;
            $document->account_number = $request->account_number;
            $document->ifsc_code = $request->ifsc_code;
            if ($request->hasFile('bank_passbook_image')) {
                $document->bank_passbook_image_path = MediaUploadService::upload(
                    $request->file('bank_passbook_image'),
                    'delivery_boy/documents/bank'
                );
            }
            $document->bank_details_status = 'pending_verification';

            $document->save();

            Log::info('All documents uploaded for delivery boy', [
                'delivery_boy_id' => $deliveryBoy->id,
                'document_id' => $document->id
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Documents uploaded successfully',
                'data' => [
                    'document_id' => $document->id,
                    'status' => 'pending_verification'
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to upload documents', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return response()->json([
                'status' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update documents (partial update)
     *
     * POST /api/delivery_boy/update-documents
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateDocuments(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Get or create document record
            $document = DeliveryBoyDocument::firstOrCreate(
                ['delivery_boy_id' => $deliveryBoy->id]
            );

            // Validation rules (all optional)
            $validator = Validator::make($request->all(), [
                'driving_license_number' => 'nullable|string|max:50',
                'driving_license_front' => 'nullable|image|mimes:jpeg,jpg,png|max:5120',
                'driving_license_back' => 'nullable|image|mimes:jpeg,jpg,png|max:5120',
                'rc_number' => 'nullable|string|max:50',
                'rc_front' => 'nullable|image|mimes:jpeg,jpg,png|max:5120',
                'rc_back' => 'nullable|image|mimes:jpeg,jpg,png|max:5120',
                'aadhar_number' => 'nullable|digits:12',
                'aadhar_front' => 'nullable|image|mimes:jpeg,jpg,png|max:5120',
                'aadhar_back' => 'nullable|image|mimes:jpeg,jpg,png|max:5120',
                'pan_number' => 'nullable|string|size:10|regex:/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/',
                'pan_front' => 'nullable|image|mimes:jpeg,jpg,png|max:5120',
                'pan_back' => 'nullable|image|mimes:jpeg,jpg,png|max:5120',
                'bank_name' => 'nullable|string|max:100',
                'account_holder_name' => 'nullable|string|max:100',
                'account_number' => 'nullable|string|max:50',
                'ifsc_code' => 'nullable|string|size:11|regex:/^[A-Z]{4}0[A-Z0-9]{6}$/',
                'bank_passbook_image' => 'nullable|image|mimes:jpeg,jpg,png|max:5120',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $updatedFields = [];

            // Update driving license
            if ($request->has('driving_license_number')) {
                $document->driving_license_number = $request->driving_license_number;
                $updatedFields[] = 'driving_license_number';
            }
            if ($request->hasFile('driving_license_front')) {
                $document->driving_license_front_path = MediaUploadService::upload(
                    $request->file('driving_license_front'),
                    'delivery_boy/documents/driving_license',
                    'public',
                    $document->driving_license_front_path
                );
                $document->driving_license_status = 'pending_verification';
                $updatedFields[] = 'driving_license_front';
            }
            if ($request->hasFile('driving_license_back')) {
                $document->driving_license_back_path = MediaUploadService::upload(
                    $request->file('driving_license_back'),
                    'delivery_boy/documents/driving_license',
                    'public',
                    $document->driving_license_back_path
                );
                $document->driving_license_status = 'pending_verification';
                $updatedFields[] = 'driving_license_back';
            }

            // Update RC
            if ($request->has('rc_number')) {
                $document->rc_number = $request->rc_number;
                $updatedFields[] = 'rc_number';
            }
            if ($request->hasFile('rc_front')) {
                $document->rc_front_path = MediaUploadService::upload(
                    $request->file('rc_front'),
                    'delivery_boy/documents/rc',
                    'public',
                    $document->rc_front_path
                );
                $document->rc_status = 'pending_verification';
                $updatedFields[] = 'rc_front';
            }
            if ($request->hasFile('rc_back')) {
                $document->rc_back_path = MediaUploadService::upload(
                    $request->file('rc_back'),
                    'delivery_boy/documents/rc',
                    'public',
                    $document->rc_back_path
                );
                $document->rc_status = 'pending_verification';
                $updatedFields[] = 'rc_back';
            }

            // Update Aadhar
            if ($request->has('aadhar_number')) {
                $document->aadhar_number = $request->aadhar_number;
                $updatedFields[] = 'aadhar_number';
            }
            if ($request->hasFile('aadhar_front')) {
                $document->aadhar_front_path = MediaUploadService::upload(
                    $request->file('aadhar_front'),
                    'delivery_boy/documents/aadhar',
                    'public',
                    $document->aadhar_front_path
                );
                $document->aadhar_status = 'pending_verification';
                $updatedFields[] = 'aadhar_front';
            }
            if ($request->hasFile('aadhar_back')) {
                $document->aadhar_back_path = MediaUploadService::upload(
                    $request->file('aadhar_back'),
                    'delivery_boy/documents/aadhar',
                    'public',
                    $document->aadhar_back_path
                );
                $document->aadhar_status = 'pending_verification';
                $updatedFields[] = 'aadhar_back';
            }

            // Update PAN
            if ($request->has('pan_number')) {
                $document->pan_number = $request->pan_number;
                $updatedFields[] = 'pan_number';
            }
            if ($request->hasFile('pan_front')) {
                $document->pan_front_path = MediaUploadService::upload(
                    $request->file('pan_front'),
                    'delivery_boy/documents/pan',
                    'public',
                    $document->pan_front_path
                );
                $document->pan_status = 'pending_verification';
                $updatedFields[] = 'pan_front';
            }
            if ($request->hasFile('pan_back')) {
                $document->pan_back_path = MediaUploadService::upload(
                    $request->file('pan_back'),
                    'delivery_boy/documents/pan',
                    'public',
                    $document->pan_back_path
                );
                $document->pan_status = 'pending_verification';
                $updatedFields[] = 'pan_back';
            }

            // Update Bank Details
            if ($request->has('bank_name')) {
                $document->bank_name = $request->bank_name;
                $updatedFields[] = 'bank_name';
            }
            if ($request->has('account_holder_name')) {
                $document->account_holder_name = $request->account_holder_name;
                $updatedFields[] = 'account_holder_name';
            }
            if ($request->has('account_number')) {
                $document->account_number = $request->account_number;
                $updatedFields[] = 'account_number';
            }
            if ($request->has('ifsc_code')) {
                $document->ifsc_code = $request->ifsc_code;
                $updatedFields[] = 'ifsc_code';
            }
            if ($request->hasFile('bank_passbook_image')) {
                $document->bank_passbook_image_path = MediaUploadService::upload(
                    $request->file('bank_passbook_image'),
                    'delivery_boy/documents/bank',
                    'public',
                    $document->bank_passbook_image_path
                );
                $document->bank_details_status = 'pending_verification';
                $updatedFields[] = 'bank_passbook_image';
            }

            if (empty($updatedFields)) {
                return response()->json([
                    'status' => false,
                    'message' => 'No fields to update',
                    'errors' => []
                ], 400);
            }

            $document->save();

            // Check if all documents are verified
            $allVerified = (
                $document->driving_license_status === 'verified' &&
                $document->rc_status === 'verified' &&
                $document->aadhar_status === 'verified' &&
                $document->pan_status === 'verified' &&
                $document->bank_details_status === 'verified'
            );

            // Check if any documents are rejected
            $anyRejected = in_array('rejected', [
                $document->driving_license_status,
                $document->rc_status,
                $document->aadhar_status,
                $document->pan_status,
                $document->bank_details_status
            ]);

            // Update delivery boy status if all verified and no rejections
            if (!$anyRejected) {
                $deliveryBoy->status = 0; // Active
                $deliveryBoy->rejection_remark = null;
                $deliveryBoy->remark = null;
                $deliveryBoy->save();

                Log::info('Delivery boy status updated to active - all documents verified', [
                    'delivery_boy_id' => $deliveryBoy->id
                ]);
            }

            Log::info('Documents updated for delivery boy', [
                'delivery_boy_id' => $deliveryBoy->id,
                'updated_fields' => $updatedFields
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Documents updated successfully',
                'data' => [
                    'updated_fields' => $updatedFields,
                    'status' => 'pending_verification',
                    'delivery_boy_status' => $allVerified && !$anyRejected ? 'active' : 'pending'
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update documents', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return response()->json([
                'status' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update driving license only
     *
     * POST /api/delivery_boy/update-driving-license
     *
     * Handles multiple scenarios:
     * 1. Only license number update (no photos)
     * 2. License number + file uploads
     * 3. License number + URL strings for images
     * 4. Mix: file upload for front, URL for back (or vice versa)
     * 5. Only update images (no number change)
     * 6. Update single image only
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateDrivingLicense(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Check if at least one field is provided
            if (!$request->has('driving_license_number') &&
                !$request->hasFile('driving_license_front') && !$request->has('driving_license_front_url') &&
                !$request->hasFile('driving_license_back') && !$request->has('driving_license_back_url')) {
                return CommonHelper::responseError('At least one field (driving_license_number, driving_license_front, driving_license_front_url, driving_license_back, driving_license_back_url) is required.');
            }

            // Build validation rules dynamically based on what's provided
            $rules = [];
            $messages = [];

            // Driving license number validation (optional but must be valid if provided)
            if ($request->has('driving_license_number') && $request->driving_license_number !== null && $request->driving_license_number !== '') {
                $rules['driving_license_number'] = 'string|max:50';
            }

            // Driving license front - can be file upload OR URL string
            if ($request->hasFile('driving_license_front')) {
                $rules['driving_license_front'] = 'image|mimes:jpeg,jpg,png|max:5120';
            } elseif ($request->has('driving_license_front_url') && $request->driving_license_front_url !== null && $request->driving_license_front_url !== '') {
                $rules['driving_license_front_url'] = 'url';
                $messages['driving_license_front_url.url'] = 'Driving license front URL must be a valid URL.';
            }

            // Driving license back - can be file upload OR URL string
            if ($request->hasFile('driving_license_back')) {
                $rules['driving_license_back'] = 'image|mimes:jpeg,jpg,png|max:5120';
            } elseif ($request->has('driving_license_back_url') && $request->driving_license_back_url !== null && $request->driving_license_back_url !== '') {
                $rules['driving_license_back_url'] = 'url';
                $messages['driving_license_back_url.url'] = 'Driving license back URL must be a valid URL.';
            }

            if (!empty($rules)) {
                $validator = Validator::make($request->all(), $rules, $messages);

                if ($validator->fails()) {
                    return CommonHelper::responseError($validator->errors()->first());
                }
            }

            // Start database transaction
            DB::beginTransaction();

            try {
                // Get or create document record
                $document = DeliveryBoyDocument::firstOrCreate(
                    ['delivery_boy_id' => $deliveryBoy->id]
                );

                // Store old paths for cleanup on failure
                $oldFrontPath = $document->driving_license_front_path;
                $oldBackPath = $document->driving_license_back_path;

                $updatedFields = [];

                // Update driving license number if provided
                if ($request->has('driving_license_number') && $request->driving_license_number !== null && $request->driving_license_number !== '') {
                    $document->driving_license_number = strtoupper($request->driving_license_number);
                    $updatedFields[] = 'driving_license_number';
                }

                // Handle driving license front image
                if ($request->hasFile('driving_license_front')) {
                    // File upload
                    $document->driving_license_front_path = MediaUploadService::upload(
                        $request->file('driving_license_front'),
                        'delivery_boy/documents/driving_license',
                        'public',
                        $document->driving_license_front_path
                    );
                    $updatedFields[] = 'driving_license_front (file)';
                } elseif ($request->has('driving_license_front_url') && $request->driving_license_front_url !== null && $request->driving_license_front_url !== '') {
                    // URL string - store directly
                    $document->driving_license_front_path = $request->driving_license_front_url;
                    $updatedFields[] = 'driving_license_front (url)';
                }

                // Handle driving license back image
                if ($request->hasFile('driving_license_back')) {
                    // File upload
                    $document->driving_license_back_path = MediaUploadService::upload(
                        $request->file('driving_license_back'),
                        'delivery_boy/documents/driving_license',
                        'public',
                        $document->driving_license_back_path
                    );
                    $updatedFields[] = 'driving_license_back (file)';
                } elseif ($request->has('driving_license_back_url') && $request->driving_license_back_url !== null && $request->driving_license_back_url !== '') {
                    // URL string - store directly
                    $document->driving_license_back_path = $request->driving_license_back_url;
                    $updatedFields[] = 'driving_license_back (url)';
                }

                // Set status to pending verification if any field was updated
                if (!empty($updatedFields)) {
                    $document->driving_license_status = 'pending_verification';
                }

                $document->save();

                // Commit transaction
                DB::commit();

                // Send notification to admin panel
                try {
                    AdminNotificationService::notifyDriverDocumentUpdate(
                        $deliveryBoy->id,
                        $deliveryBoy->name,
                        'driving_license'
                    );
                } catch (\Exception $notificationException) {
                    Log::error('Failed to send admin notification for driving license update', [
                        'delivery_boy_id' => $deliveryBoy->id,
                        'error' => $notificationException->getMessage()
                    ]);
                }
            } catch (\Exception $uploadException) {
                // Rollback database changes
                DB::rollBack();

                // Clean up any newly uploaded files (only if they were file uploads, not URLs)
                if ($request->hasFile('driving_license_front') && isset($document->driving_license_front_path) && $document->driving_license_front_path !== $oldFrontPath) {
                    MediaUploadService::deleteByUrl($document->driving_license_front_path);
                }
                if ($request->hasFile('driving_license_back') && isset($document->driving_license_back_path) && $document->driving_license_back_path !== $oldBackPath) {
                    MediaUploadService::deleteByUrl($document->driving_license_back_path);
                }

                throw $uploadException;
            }

            Log::info('Driving license updated for delivery boy', [
                'delivery_boy_id' => $deliveryBoy->id,
                'document_id' => $document->id,
                'updated_fields' => $updatedFields
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Driving license updated successfully',
                'data' => [
                    'driving_license' => [
                        'number' => $document->driving_license_number,
                        'front_image_url' => $document->driving_license_front_url,
                        'back_image_url' => $document->driving_license_back_url,
                        'status' => $document->driving_license_status
                    ],
                    'updated_fields' => $updatedFields
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update driving license', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return response()->json([
                'status' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update PAN card only
     *
     * POST /api/delivery_boy/update-pan
     *
     * Handles multiple scenarios:
     * 1. Only PAN number update (no photos)
     * 2. PAN number + file uploads
     * 3. PAN number + URL strings for images
     * 4. Mix: file upload for front, URL for back (or vice versa)
     * 5. Only update images (no number change)
     * 6. Update single image only
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updatePan(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Check if at least one field is provided
            if (!$request->has('pan_number') &&
                !$request->hasFile('pan_front') && !$request->has('pan_front_url') &&
                !$request->hasFile('pan_back') && !$request->has('pan_back_url')) {
                return CommonHelper::responseError('At least one field (pan_number, pan_front, pan_front_url, pan_back, pan_back_url) is required.');
            }

            // Build validation rules dynamically based on what's provided
            $rules = [];
            $messages = [];

            // PAN number validation (optional but must be valid format if provided)
            if ($request->has('pan_number') && $request->pan_number !== null && $request->pan_number !== '') {
                $rules['pan_number'] = 'string|size:10|regex:/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/';
                $messages['pan_number.regex'] = 'PAN number must be in format: ABCDE1234F';
            }

            // PAN front - can be file upload OR URL string
            if ($request->hasFile('pan_front')) {
                $rules['pan_front'] = 'image|mimes:jpeg,jpg,png|max:5120';
            } elseif ($request->has('pan_front_url') && $request->pan_front_url !== null && $request->pan_front_url !== '') {
                $rules['pan_front_url'] = 'url';
                $messages['pan_front_url.url'] = 'PAN front URL must be a valid URL.';
            }

            // PAN back - can be file upload OR URL string
            if ($request->hasFile('pan_back')) {
                $rules['pan_back'] = 'image|mimes:jpeg,jpg,png|max:5120';
            } elseif ($request->has('pan_back_url') && $request->pan_back_url !== null && $request->pan_back_url !== '') {
                $rules['pan_back_url'] = 'url';
                $messages['pan_back_url.url'] = 'PAN back URL must be a valid URL.';
            }

            if (!empty($rules)) {
                $validator = Validator::make($request->all(), $rules, $messages);

                if ($validator->fails()) {
                    return CommonHelper::responseError($validator->errors()->first());
                }
            }

            // Start database transaction
            DB::beginTransaction();

            try {
                // Get or create document record
                $document = DeliveryBoyDocument::firstOrCreate(
                    ['delivery_boy_id' => $deliveryBoy->id]
                );

                // Store old paths for cleanup on failure
                $oldFrontPath = $document->pan_front_path;
                $oldBackPath = $document->pan_back_path;

                $updatedFields = [];

                // Update PAN number if provided
                if ($request->has('pan_number') && $request->pan_number !== null && $request->pan_number !== '') {
                    $document->pan_number = strtoupper($request->pan_number);
                    $updatedFields[] = 'pan_number';
                }

                // Handle PAN front image
                if ($request->hasFile('pan_front')) {
                    // File upload
                    $document->pan_front_path = MediaUploadService::upload(
                        $request->file('pan_front'),
                        'delivery_boy/documents/pan',
                        'public',
                        $document->pan_front_path
                    );
                    $updatedFields[] = 'pan_front (file)';
                } elseif ($request->has('pan_front_url') && $request->pan_front_url !== null && $request->pan_front_url !== '') {
                    // URL string - store directly
                    $document->pan_front_path = $request->pan_front_url;
                    $updatedFields[] = 'pan_front (url)';
                }

                // Handle PAN back image
                if ($request->hasFile('pan_back')) {
                    // File upload
                    $document->pan_back_path = MediaUploadService::upload(
                        $request->file('pan_back'),
                        'delivery_boy/documents/pan',
                        'public',
                        $document->pan_back_path
                    );
                    $updatedFields[] = 'pan_back (file)';
                } elseif ($request->has('pan_back_url') && $request->pan_back_url !== null && $request->pan_back_url !== '') {
                    // URL string - store directly
                    $document->pan_back_path = $request->pan_back_url;
                    $updatedFields[] = 'pan_back (url)';
                }

                // Set status to pending verification if any field was updated
                if (!empty($updatedFields)) {
                    $document->pan_status = 'pending_verification';
                }

                $document->save();

                // Commit transaction
                DB::commit();

                // Send notification to admin panel
                try {
                    AdminNotificationService::notifyDriverDocumentUpdate(
                        $deliveryBoy->id,
                        $deliveryBoy->name,
                        'pan'
                    );
                } catch (\Exception $notificationException) {
                    Log::error('Failed to send admin notification for PAN update', [
                        'delivery_boy_id' => $deliveryBoy->id,
                        'error' => $notificationException->getMessage()
                    ]);
                }
            } catch (\Exception $uploadException) {
                // Rollback database changes
                DB::rollBack();

                // Clean up any newly uploaded files (only if they were file uploads, not URLs)
                if ($request->hasFile('pan_front') && isset($document->pan_front_path) && $document->pan_front_path !== $oldFrontPath) {
                    MediaUploadService::deleteByUrl($document->pan_front_path);
                }
                if ($request->hasFile('pan_back') && isset($document->pan_back_path) && $document->pan_back_path !== $oldBackPath) {
                    MediaUploadService::deleteByUrl($document->pan_back_path);
                }

                throw $uploadException;
            }

            Log::info('PAN card updated for delivery boy', [
                'delivery_boy_id' => $deliveryBoy->id,
                'document_id' => $document->id,
                'updated_fields' => $updatedFields
            ]);

            return response()->json([
                'status' => true,
                'message' => 'PAN card updated successfully',
                'data' => [
                    'pan' => [
                        'number' => $document->pan_number,
                        'front_image_url' => $document->pan_front_url,
                        'back_image_url' => $document->pan_back_url,
                        'status' => $document->pan_status
                    ],
                    'updated_fields' => $updatedFields
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update PAN card', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return response()->json([
                'status' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get all documents
     *
     * GET /api/delivery_boy/get-documents
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getDocuments(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Get document record
            $document = DeliveryBoyDocument::where('delivery_boy_id', $deliveryBoy->id)->first();

            if (!$document) {
                return response()->json([
                    'status' => true,
                    'message' => 'No documents found',
                    'data' => [
                        'driving_license' => [
                            'number' => null,
                            'front_image_url' => null,
                            'back_image_url' => null,
                            'status' => 'not_uploaded'
                        ],
                        'rc' => [
                            'number' => null,
                            'front_image_url' => null,
                            'back_image_url' => null,
                            'status' => 'not_uploaded'
                        ],
                        'aadhar' => [
                            'number' => null,
                            'front_image_url' => null,
                            'back_image_url' => null,
                            'status' => 'not_uploaded'
                        ],
                        'pan' => [
                            'number' => null,
                            'front_image_url' => null,
                            'back_image_url' => null,
                            'status' => 'not_uploaded'
                        ],
                        'bank_details' => [
                            'bank_name' => null,
                            'account_holder_name' => null,
                            'account_number' => null,
                            'ifsc_code' => null,
                            'passbook_image_url' => null,
                            'status' => 'not_uploaded'
                        ],
                        'overall_status' => 'not_uploaded'
                    ]
                ]);
            }

            return response()->json([
                'status' => true,
                'message' => 'Documents retrieved successfully',
                'data' => [
                    'driving_license' => [
                        'number' => $document->driving_license_number,
                        'front_image_url' => $document->driving_license_front_url,
                        'back_image_url' => $document->driving_license_back_url,
                        'status' => $document->driving_license_status
                    ],
                    'rc' => [
                        'number' => $document->rc_number,
                        'front_image_url' => $document->rc_front_url,
                        'back_image_url' => $document->rc_back_url,
                        'status' => $document->rc_status
                    ],
                    'aadhar' => [
                        'number' => $document->aadhar_number,
                        'front_image_url' => $document->aadhar_front_url,
                        'back_image_url' => $document->aadhar_back_url,
                        'status' => $document->aadhar_status
                    ],
                    'pan' => [
                        'number' => $document->pan_number,
                        'front_image_url' => $document->pan_front_url,
                        'back_image_url' => $document->pan_back_url,
                        'status' => $document->pan_status
                    ],
                    'bank_details' => [
                        'bank_name' => $document->bank_name,
                        'account_holder_name' => $document->account_holder_name,
                        'account_number' => $document->account_number,
                        'ifsc_code' => $document->ifsc_code,
                        'passbook_image_url' => $document->bank_passbook_image_url,
                        'status' => $document->bank_details_status
                    ],
                    'overall_status' => $document->overall_status
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get documents', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return response()->json([
                'status' => false,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get driving license details
     *
     * GET /api/delivery_boy/get-driving-license
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getDrivingLicense(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Get document record
            $document = DeliveryBoyDocument::where('delivery_boy_id', $deliveryBoy->id)->first();

            if (!$document || !$document->driving_license_number) {
                return CommonHelper::responseWithData([
                    'driving_license' => [
                        'number' => null,
                        'front_image_url' => null,
                        'back_image_url' => null,
                        'status' => 'not_uploaded'
                    ]
                ]);
            }

            return CommonHelper::responseWithData([
                'driving_license' => [
                    'number' => $document->driving_license_number,
                    'front_image_url' => $document->driving_license_front_path,
                    'back_image_url' => $document->driving_license_back_path,
                    'status' => $document->driving_license_status ?? 'not_uploaded'
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get driving license', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError('Failed to fetch driving license details.');
        }
    }

    /**
     * Get PAN card details
     *
     * GET /api/delivery_boy/get-pan
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getPan(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Get document record
            $document = DeliveryBoyDocument::where('delivery_boy_id', $deliveryBoy->id)->first();

            if (!$document || !$document->pan_number) {
                return CommonHelper::responseWithData([
                    'pan' => [
                        'number' => null,
                        'front_image_url' => null,
                        'back_image_url' => null,
                        'status' => 'not_uploaded'
                    ]
                ]);
            }

            return CommonHelper::responseWithData([
                'pan' => [
                    'number' => $document->pan_number,
                    'front_image_url' => $document->pan_front_path,
                    'back_image_url' => $document->pan_back_path,
                    'status' => $document->pan_status ?? 'not_uploaded'
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get PAN details', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError('Failed to fetch PAN details.');
        }
    }
}
