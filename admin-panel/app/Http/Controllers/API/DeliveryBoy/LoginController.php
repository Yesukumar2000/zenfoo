<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\DeliveryBoy;
use App\Models\Admin;
use App\Models\Role;
use Validator;
use Exception;
use App\Helpers\CommonHelper;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Models\AdminToken;
use App\Models\Setting;
use App\Services\SmsService;
use App\Services\MediaUploadService;
use App\Models\DeliveryBoyReferralTracking;

class LoginController extends Controller
{
    /**
     * Send OTP to delivery boy
     *
     * POST /api/delivery-boy/send-otp
     * Body: {
     *   "phone": "9876543210",
     *   "referral_code": "1001" (optional)
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function sendOtp(Request $request)
    {
        try {
            // Validate input
            $validator = Validator::make($request->all(), [
                'phone' => 'required|digits:10',
                'referral_code' => 'nullable|string|max:20'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $phone = $request->phone;
            $referralCode = $request->input('referral_code');

            // Additional validation: ensure exactly 10 digits
            if (strlen($phone) != 10) {
                return CommonHelper::responseError('Phone number must be exactly 10 digits');
            }

            // Validate referral code if provided
            $referringDeliveryBoy = null;
            if (!empty($referralCode)) {
                $referringDeliveryBoy = DeliveryBoy::where('referral_code', $referralCode)->first();

                if (!$referringDeliveryBoy) {
                    return CommonHelper::responseError('Referral code is not valid');
                }
            }

            // Special test numbers - direct OTP
            $testNumbers = ['9999999999', '7702480125', '9912378442'];
            if (in_array($phone, $testNumbers)) {
                $otp = 1234;
            } else {
                $otp = rand(1000, 9999);
            }

            // Send OTP via SMS only if not test number
            if (!in_array($phone, $testNumbers)) {
                $smsResult = SmsService::sendDeliveryOtp($phone, $otp);

                if (!$smsResult['success']) {
                    return CommonHelper::responseError($smsResult['message']);
                }
            }

            // Check existing delivery boy
            $deliveryBoy = DeliveryBoy::where('mobile', $phone)->first();

            if ($deliveryBoy) {
                // Check if driver account is soft-deleted
                if ($deliveryBoy->deleted_at) {
                    $supportNumber = Setting::support_value('support_number', 'driver');
                    $supportEmail = Setting::support_value('support_email', 'driver');
                    $contactInfo = '';
                    if ($supportNumber) $contactInfo .= ' Phone: ' . $supportNumber;
                    if ($supportEmail) $contactInfo .= ' Email: ' . $supportEmail;

                    return response()->json([
                        'success' => 0,
                        'message' => 'This account has been deleted. For any queries, please contact admin.' . $contactInfo
                    ], 400);
                }

                // Update existing delivery boy with new OTP
                $deliveryBoy->otp_login = $otp;
                $deliveryBoy->save();

                Log::info('OTP sent to existing delivery boy', [
                    'phone' => $phone,
                    'delivery_boy_id' => $deliveryBoy->id
                ]);
            } else {
                // Check if admin with this phone already exists (allow dual roles)
                $existingAdmin = Admin::where('mobile', $phone)->first();

                if ($existingAdmin) {
                    // Admin exists - check if they're trying to add delivery boy role
                    if ($existingAdmin->role_id == 3) {
                        // Seller wants to also be a delivery boy - create new admin for delivery boy role
                        $admin = new Admin();
                        $admin->mobile = $phone;
                        $admin->email = $existingAdmin->email ?: " ";
                        $admin->username = $existingAdmin->username;
                        $admin->password = $existingAdmin->password; // Use same password
                        $admin->created_by = 1;
                        $admin->role_id = 4; // Delivery Boy role ID
                        $admin->save();

                        Log::info('Seller registered as delivery boy (dual role)', [
                            'phone' => $phone,
                            'seller_admin_id' => $existingAdmin->id,
                            'delivery_admin_id' => $admin->id
                        ]);
                    } else if ($existingAdmin->role_id == 4) {
                        // Admin exists with delivery boy role but no delivery_boy record
                        $admin = $existingAdmin;
                    } else {
                        return CommonHelper::responseError('This phone number is already registered with a different role. Please contact support.');
                    }
                } else {
                    // Create new admin user for delivery boy
                    $admin = new Admin();
                    $admin->mobile = $phone;
                    $admin->email = " ";
                    $admin->password = bcrypt("StrongPass123@21985422344");
                    $admin->created_by = 1;
                    $admin->role_id = 4; // Delivery Boy role ID
                    $admin->save();
                }

                // Create new delivery boy
                $deliveryBoy = new DeliveryBoy();
                $deliveryBoy->mobile = $phone;
                $deliveryBoy->name = $phone; // Temporary name, can be updated later
                $deliveryBoy->address = ''; // Will be filled during profile completion
                $deliveryBoy->otp_login = $otp;
                $deliveryBoy->status = DeliveryBoy::$statusRegistered; // Registered status
                $deliveryBoy->admin_id = $admin->id;

                // Set referring delivery boy if referral code was provided
                if ($referringDeliveryBoy) {
                    $deliveryBoy->referred_by = $referringDeliveryBoy->id;
                }

                $deliveryBoy->save();

                // Auto-generate referral code for new delivery boy
                $deliveryBoy->referral_code = $this->generateReferralCode($deliveryBoy->id);
                $deliveryBoy->save();

                // Create referral tracking record if referred by someone
                if ($referringDeliveryBoy) {
                    $requiredOrders = Setting::get_value('referral_driver_order_count') ?? 5;
                    $bonusAmount = Setting::get_value('referral_driver_amount') ?? 200;

                    DeliveryBoyReferralTracking::create([
                        'referring_delivery_boy_id' => $referringDeliveryBoy->id,
                        'referred_delivery_boy_id' => $deliveryBoy->id,
                        'required_orders_count' => $requiredOrders,
                        'bonus_amount' => $bonusAmount,
                        'completed_orders_count' => 0,
                        'is_bonus_paid' => false
                    ]);

                    Log::info('Referral tracking record created', [
                        'referring_delivery_boy_id' => $referringDeliveryBoy->id,
                        'referred_delivery_boy_id' => $deliveryBoy->id
                    ]);
                }

                Log::info('OTP sent to new delivery boy', [
                    'phone' => $phone,
                    'delivery_boy_id' => $deliveryBoy->id
                ]);
            }

            return CommonHelper::responseWithData([
                'phone' => $phone,
                'message' => 'OTP sent successfully'
            ]);

        } catch (Exception $e) {
            Log::error('Failed to send OTP to delivery boy', [
                'error' => $e->getMessage(),
                'phone' => $request->phone
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Verify OTP and login delivery boy
     *
     * POST /api/delivery-boy/verify-otp
     * Body: {
     *   "phone": "9876543210",
     *   "otp": "1234",
     *   "fcm_token": "firebase_token" (optional),
     *   "platform": "android" (optional)
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function verifyOtp(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'phone' => 'required|digits:10',
                'otp'   => 'required|digits:4'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Step 1: Get delivery boy by mobile
            $deliveryBoy = DeliveryBoy::where('mobile', $request->phone)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Check if driver account is soft-deleted
            if ($deliveryBoy->deleted_at) {
                $supportNumber = Setting::support_value('support_number', 'driver');
                $supportEmail = Setting::support_value('support_email', 'driver');
                $contactInfo = '';
                if ($supportNumber) $contactInfo .= ' Phone: ' . $supportNumber;
                if ($supportEmail) $contactInfo .= ' Email: ' . $supportEmail;

                return CommonHelper::responseError('This account has been deleted. For any queries, please contact admin.' . $contactInfo);
            }

            // Step 2: Verify OTP
            if ($deliveryBoy->otp_login != $request->otp) {
                return CommonHelper::responseError('Invalid OTP!');
            }

            // Clear OTP after successful verification
            $deliveryBoy->otp_login = null;
            $deliveryBoy->save();

            // Step 3: Get Admin user mapped to delivery boy
            $user = Admin::find($deliveryBoy->admin_id);

            if (!$user) {
                return CommonHelper::responseError('Admin account not found for this delivery boy!');
            }

            // Login user and generate token for all statuses
            Auth::login($user, false);

            // Save device token (optional)
            if (!empty($request->fcm_token)) {
                AdminToken::updateOrCreate(
                    [
                        'user_id' => $user->id,
                        'type' => Role::$roleNameDeliveryBoy,
                    ],
                    [
                        'fcm_token' => $request->fcm_token,
                        'platform' => $request->platform ?? 'android'
                    ]
                );
            }

            // Generate access token
            $accessToken = $user->createToken('authToken')->accessToken;

            // Load delivery boy with relationships
            $deliveryBoy->load('city');

            // Format delivery boy data
            $deliveryBoyData = [
                'id' => $deliveryBoy->id,
                'name' => $deliveryBoy->name,
                'mobile' => $deliveryBoy->mobile,
                'email' => $deliveryBoy->email,
                'address' => $deliveryBoy->address,
                'bonus_type' => $deliveryBoy->bonus_type,
                'bonus' => $deliveryBoy->bonus,
                'balance' => $deliveryBoy->balance,
                'city_id' => $deliveryBoy->city_id,
                'city_name' => $deliveryBoy->city ? $deliveryBoy->city->name : '',
                'status' => $deliveryBoy->status,
                'status_name' => $this->getStatusName($deliveryBoy->status),
                'remark' => $deliveryBoy->remark ?? '',
                'driving_license_url' => $deliveryBoy->driving_license_url,
                'national_identity_card_url' => $deliveryBoy->national_identity_card_url,
                'pending_order_count' => $deliveryBoy->pending_order_count,
                'orders_priority' => $deliveryBoy->orders_priority ?? DeliveryBoy::$priorityBoth,
                'orders_priority_name' => $this->getOrderPriorityName($deliveryBoy->orders_priority ?? DeliveryBoy::$priorityBoth),
                'referral_code' => $deliveryBoy->referral_code,
                'referred_by' => $deliveryBoy->referred_by,
                'created_at' => $deliveryBoy->created_at->toIso8601String(),
            ];

            // Prepare response data
            $responseData = [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'mobile' => $user->mobile,
                    'role_id' => $user->role_id,
                ],
                'delivery_boy' => $deliveryBoyData,
                'access_token' => $accessToken,
                'token_type' => 'Bearer'
            ];

            // Add status-specific messages
            if ($deliveryBoy->status == DeliveryBoy::$statusRegistered) {
                $responseData['message'] = 'Your request is under review, you will get notification after approval!';
            } elseif ($deliveryBoy->status == DeliveryBoy::$statusRejected) {
                $responseData['message'] = 'Your request was rejected, please contact Administrator!';
            } elseif ($deliveryBoy->status == DeliveryBoy::$statusDeactivated) {
                $responseData['message'] = 'Your account is deactivated, please contact Administrator!';
            } elseif ($deliveryBoy->status == DeliveryBoy::$statusRemoved) {
                $responseData['message'] = 'Your account has been removed. Please contact Administrator!';
            } else {
                $responseData['message'] = 'Login successful';
            }

            Log::info('Delivery boy verified OTP successfully', [
                'delivery_boy_id' => $deliveryBoy->id,
                'phone' => $request->phone,
                'status' => $deliveryBoy->status
            ]);

            return CommonHelper::responseWithData($responseData);

        } catch (\Exception $e) {
            Log::error('Failed to verify delivery boy OTP', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'phone' => $request->phone
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update delivery boy personal details
     *
     * POST /api/delivery-boy/update-personal-details
     * Body: {
     *   "name": "John Doe",
     *   "email": "john@example.com",
     *   "dob": "1990-01-15",
     *   "address": "123 Main Street, City",
     *   "latitude": "19.0760",
     *   "longitude": "72.8777",
     *   "city_id": 5
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updatePersonalDetails(Request $request)
    {

        Log::info('Delivery boy update personal details', [
            'request' => $request->all()
        ]);
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Validate input
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'email' => 'nullable|email|max:255',
                'dob' => 'nullable|date|before:today',
                'address' => 'required|string',
                'latitude' => 'nullable',
                'longitude' => 'nullable',
                'city_id' => 'nullable|integer|exists:cities,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Update personal details
            $deliveryBoy->name = $request->name;

            if ($request->has('email')) {
                $deliveryBoy->email = $request->email;
            }

            if ($request->has('dob')) {
                $deliveryBoy->dob = $request->dob;
            }

            $deliveryBoy->address = $request->address;

            // Store latitude and longitude if provided
            if ($request->has('latitude') && $request->has('longitude')) {
                // Store as JSON or separate fields based on your DB schema
                // Assuming you might need to add these fields to the delivery_boys table
                $deliveryBoy->latitude = $request->latitude;
                $deliveryBoy->longitude = $request->longitude;
            }

            if ($request->has('city_id')) {
                $deliveryBoy->city_id = $request->city_id;
            }

            $deliveryBoy->save();

            // Also update admin name if needed
            $user->username = $request->name;
            if ($request->has('email') && !empty($request->email)) {
                $user->email = $request->email;
            }
            $user->save();

            // Load relationships
            $deliveryBoy->load('city');

            // Format response
            $deliveryBoyData = [
                'id' => $deliveryBoy->id,
                'name' => $deliveryBoy->name,
                'mobile' => $deliveryBoy->mobile,
                'email' => $deliveryBoy->email,
                'dob' => $deliveryBoy->dob,
                'address' => $deliveryBoy->address,
                'latitude' => $deliveryBoy->latitude ?? null,
                'longitude' => $deliveryBoy->longitude ?? null,
                'city_id' => $deliveryBoy->city_id,
                'city_name' => $deliveryBoy->city ? $deliveryBoy->city->name : '',
                'bonus_type' => $deliveryBoy->bonus_type,
                'bonus' => $deliveryBoy->bonus,
                'balance' => $deliveryBoy->balance,
                'status' => $deliveryBoy->status,
                'status_name' => $this->getStatusName($deliveryBoy->status),
                'driving_license_url' => $deliveryBoy->driving_license_url,
                'national_identity_card_url' => $deliveryBoy->national_identity_card_url,
                'updated_at' => $deliveryBoy->updated_at->toIso8601String(),
            ];

            Log::info('Delivery boy personal details updated', [
                'delivery_boy_id' => $deliveryBoy->id,
                'user_id' => $user->id
            ]);

            return CommonHelper::responseWithData([
                'delivery_boy' => $deliveryBoyData,
                'message' => 'Personal details updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update delivery boy personal details', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get delivery boy personal details
     *
     * GET /api/delivery_boy/get-personal-details
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getPersonalDetails(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Get delivery boy with relationships
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)
                ->with(['city', 'vehicle', 'storeLocations.city', 'documents'])
                ->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Format store locations
            $storeLocations = $deliveryBoy->storeLocations->map(function ($location) {
                return [
                    'id' => $location->id,
                    'name' => $location->name,
                    'address' => $location->address,
                    'latitude' => $location->latitude,
                    'longitude' => $location->longitude,
                    'phone' => $location->phone,
                    'email' => $location->email,
                    'city_id' => $location->city_id,
                    'city_name' => $location->city ? $location->city->name : '',
                ];
            });

            // Format documents
            $documents = null;
            $allDocsUploaded = false;
            if ($deliveryBoy->documents) {
                $doc = $deliveryBoy->documents;

                // Check if all documents are uploaded
                $allDocsUploaded = !empty($doc->driving_license_number) &&
                    !empty($doc->driving_license_front_url) &&
                    !empty($doc->driving_license_back_url) &&
                    !empty($doc->rc_number) &&
                    !empty($doc->rc_front_url) &&
                    !empty($doc->rc_back_url) &&
                    !empty($doc->aadhar_number) &&
                    !empty($doc->aadhar_front_url) &&
                    !empty($doc->aadhar_back_url) &&
                    !empty($doc->pan_number) &&
                    !empty($doc->pan_front_url) &&
                    !empty($doc->pan_back_url) &&
                    !empty($doc->bank_name) &&
                    !empty($doc->account_holder_name) &&
                    !empty($doc->account_number) &&
                    !empty($doc->ifsc_code) &&
                    !empty($doc->bank_passbook_image_url);

                // Set overall status to 'not_uploaded' if any document is missing
                $overallStatus = $allDocsUploaded ? $doc->overall_status : 'not_uploaded';

                $documents = [
                    'driving_license' => [
                        'number' => $doc->driving_license_number,
                        'front_image_url' => $doc->driving_license_front_url,
                        'back_image_url' => $doc->driving_license_back_url,
                        'status' => $doc->driving_license_status
                    ],
                    'rc' => [
                        'number' => $doc->rc_number,
                        'front_image_url' => $doc->rc_front_url,
                        'back_image_url' => $doc->rc_back_url,
                        'status' => $doc->rc_status
                    ],
                    'aadhar' => [
                        'number' => $doc->aadhar_number,
                        'front_image_url' => $doc->aadhar_front_url,
                        'back_image_url' => $doc->aadhar_back_url,
                        'status' => $doc->aadhar_status
                    ],
                    'pan' => [
                        'number' => $doc->pan_number,
                        'front_image_url' => $doc->pan_front_url,
                        'back_image_url' => $doc->pan_back_url,
                        'status' => $doc->pan_status
                    ],
                    'bank_details' => [
                        'bank_name' => $doc->bank_name,
                        'account_holder_name' => $doc->account_holder_name,
                        'account_number' => $doc->account_number,
                        'ifsc_code' => $doc->ifsc_code,
                        'passbook_image_url' => $doc->bank_passbook_image_url,
                        'status' => $doc->bank_details_status
                    ],
                    'overall_status' => $overallStatus
                ];
            }

            // Format complete delivery boy data
            $deliveryBoyData = [
                'id' => $deliveryBoy->id,
                'name' => $deliveryBoy->name,
                'mobile' => $deliveryBoy->mobile,
                'email' => $deliveryBoy->email,
                'profile_image' => $deliveryBoy->profile_image,
                'profile_image_url' => $deliveryBoy->profile_image_url,
                'dob' => $deliveryBoy->dob,
                'address' => $deliveryBoy->address,
                'latitude' => $deliveryBoy->latitude ?? null,
                'longitude' => $deliveryBoy->longitude ?? null,
                'city_id' => $deliveryBoy->city_id,
                'city_name' => $deliveryBoy->city ? $deliveryBoy->city->name : '',
                'vehicle_id' => $deliveryBoy->vehicle_id,
                'vehicle_name' => $deliveryBoy->vehicle ? $deliveryBoy->vehicle->name : null,
                'vehicle_image_url' => $deliveryBoy->vehicle ? $deliveryBoy->vehicle->image_url : null,
                'store_locations' => $storeLocations,
                'store_locations_count' => $storeLocations->count(),
                'bonus_type' => $deliveryBoy->bonus_type,
                'bonus' => $deliveryBoy->bonus,
                'balance' => $deliveryBoy->balance,
                'status' => $deliveryBoy->status,
                'status_name' => $this->getStatusName($deliveryBoy->status),
                'remark' => $deliveryBoy->remark ?? '',
                'rejection_remark' => $deliveryBoy->rejection_remark ?? '',
                'driving_license' => $deliveryBoy->driving_license,
                'driving_license_url' => $deliveryBoy->driving_license_url,
                'national_identity_card' => $deliveryBoy->national_identity_card,
                'national_identity_card_url' => $deliveryBoy->national_identity_card_url,
                'bank_account_number' => $deliveryBoy->bank_account_number,
                'bank_name' => $deliveryBoy->bank_name,
                'account_name' => $deliveryBoy->account_name,
                'ifsc_code' => $deliveryBoy->ifsc_code,
                'other_payment_information' => $deliveryBoy->other_payment_information,
                'is_available' => $deliveryBoy->is_available,
                'cash_received' => $deliveryBoy->cash_received,
                'pending_order_count' => $deliveryBoy->pending_order_count,
                'orders_priority' => $deliveryBoy->orders_priority ?? DeliveryBoy::$priorityBoth,
                'orders_priority_name' => $this->getOrderPriorityName($deliveryBoy->orders_priority ?? DeliveryBoy::$priorityBoth),
                'referral_code' => $deliveryBoy->referral_code,
                'referred_by' => $deliveryBoy->referred_by,
                'documents' => $documents,
                'is_details_given' => $allDocsUploaded ? 1 : 0,
                'created_at' => $deliveryBoy->created_at->toIso8601String(),
                'updated_at' => $deliveryBoy->updated_at->toIso8601String(),
            ];

            return CommonHelper::responseWithData([
                'delivery_boy' => $deliveryBoyData
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get delivery boy personal details', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update delivery boy profile with documents
     *
     * POST /api/delivery_boy/update-profile
     * Body (multipart/form-data): {
     *   "name": "John Doe",
     *   "email": "john@example.com",
     *   "dob": "1990-01-15",
     *   "address": "123 Main Street, City",
     *   "latitude": "19.0760",
     *   "longitude": "72.8777",
     *   "city_id": 5,
     *   "driving_license": File (image),
     *   "national_identity_card": File (image),
     *   "bank_account_number": "1234567890",
     *   "bank_name": "State Bank",
     *   "account_name": "John Doe",
     *   "ifsc_code": "SBIN0001234",
     *   "other_payment_information": "UPI: john@paytm"
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateProfile(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Validate input
            $validator = Validator::make($request->all(), [
                'name' => 'nullable|string|max:255',
                'email' => 'nullable|email|max:255',
                'dob' => 'nullable|date|before:today',
                'address' => 'nullable|string',
                'latitude' => 'nullable|numeric',
                'longitude' => 'nullable|numeric',
                'city_id' => 'nullable|integer|exists:cities,id',
                'driving_license' => 'nullable|image|mimes:jpeg,jpg,png,gif|max:5120',
                'national_identity_card' => 'nullable|image|mimes:jpeg,jpg,png,gif|max:5120',
                'bank_account_number' => 'nullable|string|max:255',
                'bank_name' => 'nullable|string|max:255',
                'account_name' => 'nullable|string|max:255',
                'ifsc_code' => 'nullable|string|max:255',
                'other_payment_information' => 'nullable|string'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Update basic details
            if ($request->has('name')) {
                $deliveryBoy->name = $request->name;
                $user->name = $request->name;
            }

            if ($request->has('email')) {
                $deliveryBoy->email = $request->email;
                if (!empty($request->email)) {
                    $user->email = $request->email;
                }
            }

            if ($request->has('dob')) {
                $deliveryBoy->dob = $request->dob;
            }

            if ($request->has('address')) {
                $deliveryBoy->address = $request->address;
            }

            // Store latitude and longitude
            if ($request->has('latitude') && $request->has('longitude')) {
                $deliveryBoy->latitude = $request->latitude;
                $deliveryBoy->longitude = $request->longitude;
            }

            if ($request->has('city_id')) {
                $deliveryBoy->city_id = $request->city_id;
            }

            // Handle driving license upload
            if ($request->hasFile('driving_license')) {
                $deliveryBoy->driving_license = MediaUploadService::upload(
                    $request->file('driving_license'),
                    'delivery_boy/driving_licenses',
                    'public',
                    $deliveryBoy->driving_license
                );
            }

            // Handle national identity card upload
            if ($request->hasFile('national_identity_card')) {
                $deliveryBoy->national_identity_card = MediaUploadService::upload(
                    $request->file('national_identity_card'),
                    'delivery_boy/identity_cards',
                    'public',
                    $deliveryBoy->national_identity_card
                );
            }

            // Update bank details
            if ($request->has('bank_account_number')) {
                $deliveryBoy->bank_account_number = $request->bank_account_number;
            }

            if ($request->has('bank_name')) {
                $deliveryBoy->bank_name = $request->bank_name;
            }

            if ($request->has('account_name')) {
                $deliveryBoy->account_name = $request->account_name;
            }

            if ($request->has('ifsc_code')) {
                $deliveryBoy->ifsc_code = $request->ifsc_code;
            }

            if ($request->has('other_payment_information')) {
                $deliveryBoy->other_payment_information = $request->other_payment_information;
            }

            $deliveryBoy->save();
            $user->save();

            // Load relationships
            $deliveryBoy->load('city');

            // Format response
            $deliveryBoyData = [
                'id' => $deliveryBoy->id,
                'name' => $deliveryBoy->name,
                'mobile' => $deliveryBoy->mobile,
                'email' => $deliveryBoy->email,
                'dob' => $deliveryBoy->dob,
                'address' => $deliveryBoy->address,
                'latitude' => $deliveryBoy->latitude ?? null,
                'longitude' => $deliveryBoy->longitude ?? null,
                'city_id' => $deliveryBoy->city_id,
                'city_name' => $deliveryBoy->city ? $deliveryBoy->city->name : '',
                'bonus_type' => $deliveryBoy->bonus_type,
                'bonus' => $deliveryBoy->bonus,
                'balance' => $deliveryBoy->balance,
                'status' => $deliveryBoy->status,
                'status_name' => $this->getStatusName($deliveryBoy->status),
                'driving_license_url' => $deliveryBoy->driving_license_url,
                'national_identity_card_url' => $deliveryBoy->national_identity_card_url,
                'bank_account_number' => $deliveryBoy->bank_account_number,
                'bank_name' => $deliveryBoy->bank_name,
                'account_name' => $deliveryBoy->account_name,
                'ifsc_code' => $deliveryBoy->ifsc_code,
                'other_payment_information' => $deliveryBoy->other_payment_information,
                'updated_at' => $deliveryBoy->updated_at->toIso8601String(),
            ];

            Log::info('Delivery boy profile updated', [
                'delivery_boy_id' => $deliveryBoy->id,
                'user_id' => $user->id
            ]);

            return CommonHelper::responseWithData([
                'delivery_boy' => $deliveryBoyData,
                'message' => 'Profile updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update delivery boy profile', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get nearby cities based on delivery boy's current location
     *
     * GET /api/delivery_boy/nearby-cities
     * Query Parameters:
     *   - latitude (optional): Current latitude (overrides stored location)
     *   - longitude (optional): Current longitude (overrides stored location)
     *   - radius (optional): Search radius in kilometers (default: 50)
     *   - limit (optional): Number of results (default: 10)
     *   - search (optional): Search term to filter cities by name, state, zone, or address
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getNearbyCities(Request $request)
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

            // Get latitude and longitude from request or delivery boy profile
            $latitude = $request->input('latitude', $deliveryBoy->latitude);
            $longitude = $request->input('longitude', $deliveryBoy->longitude);

            if (!$latitude || !$longitude) {
                return CommonHelper::responseError('Location not available. Please update your profile with location or provide latitude and longitude.');
            }

            // Get search radius (default 50 km)
            $radius = $request->input('radius', 50);
            $limit = $request->input('limit', 10);

            // Build query with Haversine formula to calculate distance
            $query = \App\Models\City::select('*')
                ->selectRaw(
                    '( 6371 * acos( cos( radians(?) ) * cos( radians( latitude ) ) * cos( radians( longitude ) - radians(?) ) + sin( radians(?) ) * sin( radians( latitude ) ) ) ) AS distance',
                    [$latitude, $longitude, $latitude]
                );

            // Apply search filter if provided
            if ($request->has('search') && !empty($request->input('search'))) {
                $searchTerm = $request->input('search');
                $query->where(function ($q) use ($searchTerm) {
                    $q->where('name', 'like', '%' . $searchTerm . '%')
                        ->orWhere('state', 'like', '%' . $searchTerm . '%')
                        ->orWhere('zone', 'like', '%' . $searchTerm . '%')
                        ->orWhere('formatted_address', 'like', '%' . $searchTerm . '%');
                });
            }

            // Filter by radius and order by distance
            $cities = $query
            // ->having('distance', '<=', $radius)
                ->orderBy('distance', 'asc')
                ->limit($limit)
                ->get();

            $formattedCities = $cities->map(function ($city) {
                return [
                    'id' => $city->id,
                    'name' => $city->name,
                    'state' => $city->state,
                    'zone' => $city->zone,
                    'latitude' => $city->latitude,
                    'longitude' => $city->longitude,
                    'formatted_address' => $city->formatted_address,
                    'max_deliverable_distance' => $city->max_deliverable_distance,
                    'distance_km' => round($city->distance, 2),
                ];
            });

            return CommonHelper::responseWithData([
                'current_location' => [
                    'latitude' => $latitude,
                    'longitude' => $longitude,
                ],
                'search_radius_km' => $radius,
                'cities' => $formattedCities,
                'total' => $formattedCities->count(),
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get nearby cities for delivery boy', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get available vehicles for delivery boy
     *
     * GET /api/delivery_boy/vehicles
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function getVehicles()
    {
        try {
            $vehicles = \App\Models\Vehicle::active()
                ->orderBy('name', 'asc')
                ->get();

            $formattedVehicles = $vehicles->map(function ($vehicle) {
                return [
                    'id' => $vehicle->id,
                    'name' => $vehicle->name,
                    'image' => $vehicle->image,
                    'image_url' => $vehicle->image_url,
                ];
            });

            return CommonHelper::responseWithData($formattedVehicles, $formattedVehicles->count());

        } catch (\Exception $e) {
            Log::error('Failed to get vehicles for delivery boy', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to retrieve vehicles');
        }
    }

    /**
     * Select vehicle for delivery boy
     *
     * POST /api/delivery_boy/select-vehicle
     * Body: {
     *   "vehicle_id": 1
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function selectVehicle(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            $validator = Validator::make($request->all(), [
                'vehicle_id' => 'required|exists:vehicles,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Check if vehicle is active
            $vehicle = \App\Models\Vehicle::find($request->vehicle_id);
            if (!$vehicle || $vehicle->status != 1) {
                return CommonHelper::responseError('Selected vehicle is not available!');
            }

            // Update vehicle
            $deliveryBoy->vehicle_id = $request->vehicle_id;
            $deliveryBoy->save();

            Log::info('Delivery boy selected vehicle', [
                'delivery_boy_id' => $deliveryBoy->id,
                'vehicle_id' => $request->vehicle_id
            ]);

            return CommonHelper::responseWithData([
                'vehicle' => [
                    'id' => $vehicle->id,
                    'name' => $vehicle->name,
                    'image_url' => $vehicle->image_url,
                ],
                'message' => 'Vehicle selected successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to select vehicle for delivery boy', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update delivery boy city
     *
     * POST /api/delivery_boy/update-city
     * Body: {
     *   "city_id": 5
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateCity(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            $validator = Validator::make($request->all(), [
                'city_id' => 'required|exists:cities,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Get city details
            $city = \App\Models\City::find($request->city_id);
            if (!$city) {
                return CommonHelper::responseError('Selected city is not available!');
            }

            // Update city
            $deliveryBoy->city_id = $request->city_id;
            $deliveryBoy->save();

            Log::info('Delivery boy updated city', [
                'delivery_boy_id' => $deliveryBoy->id,
                'city_id' => $request->city_id
            ]);

            return CommonHelper::responseWithData([
                'city' => [
                    'id' => $city->id,
                    'name' => $city->name,
                    'state' => $city->state,
                    'zone' => $city->zone,
                    'formatted_address' => $city->formatted_address,
                ],
                'message' => 'City updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update city for delivery boy', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update delivery boy profile image
     *
     * POST /api/delivery_boy/update-profile-image
     * Body (multipart/form-data): {
     *   "profile_image": File (image)
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateProfileImage(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                Log::warning('updateProfileImage: Unauthenticated request', [
                    'ip' => $request->ip(),
                    'user_agent' => $request->userAgent(),
                ]);
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            Log::info('updateProfileImage: Request received', [
                'user_id'    => $user->id,
                'user_email' => $user->email ?? null,
                'user_name'  => $user->name ?? null,
                'ip'         => $request->ip(),
            ]);

            $validator = Validator::make($request->all(), [
                'profile_image' => 'required|image|mimes:jpeg,jpg,png,gif|max:5120'
            ]);

            if ($validator->fails()) {
                Log::warning('updateProfileImage: Validation failed', [
                    'user_id' => $user->id,
                    'errors'  => $validator->errors()->toArray(),
                ]);
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            Log::info('updateProfileImage: DeliveryBoy lookup', [
                'user_id'          => $user->id,
                'user_email'       => $user->email ?? null,
                'delivery_boy_found' => $deliveryBoy ? true : false,
                'delivery_boy_id'  => $deliveryBoy->id ?? null,
            ]);

            if (!$deliveryBoy) {
                Log::error('updateProfileImage: Delivery boy account not found', [
                    'user_id'    => $user->id,
                    'user_email' => $user->email ?? null,
                    'user_name'  => $user->name ?? null,
                ]);
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Handle profile image upload
            if ($request->hasFile('profile_image')) {
                $profileImageUrl = MediaUploadService::upload(
                    $request->file('profile_image'),
                    'delivery_boy/profile_images',
                    'public',
                    $deliveryBoy->profile_image
                );
                $deliveryBoy->profile_image = $profileImageUrl;
                $deliveryBoy->save();

                Log::info('Delivery boy profile image updated', [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'profile_image' => $profileImageUrl
                ]);
            }

            return CommonHelper::responseWithData([
                'profile_image' => $deliveryBoy->profile_image,
                'profile_image_url' => $deliveryBoy->profile_image_url,
                'message' => 'Profile image updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update profile image for delivery boy', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get store locations by city for delivery boy
     *
     * GET /api/delivery_boy/store-locations
     * Query Parameters:
     *   - city_id (optional): Filter by city (if not provided, uses delivery boy's city)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getStoreLocations(Request $request)
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

            // Get city_id from request or use delivery boy's city
            $cityId = $request->input('city_id', $deliveryBoy->city_id);

            if (!$cityId) {
                return CommonHelper::responseError('City not specified. Please update your city or provide city_id parameter.');
            }

            // Get active store locations for the city
            $storeLocations = \App\Models\StoreLocation::active()
                ->byCity($cityId)
                ->with('city')
                ->orderBy('name', 'asc')
                ->get();

            $formattedLocations = $storeLocations->map(function ($location) {
                return [
                    'id' => $location->id,
                    'name' => $location->name,
                    'address' => $location->address,
                    'latitude' => $location->latitude,
                    'longitude' => $location->longitude,
                    'phone' => $location->phone,
                    'email' => $location->email,
                    'city_id' => $location->city_id,
                    'city_name' => $location->city ? $location->city->name : '',
                ];
            });

            return CommonHelper::responseWithData([
                'store_locations' => $formattedLocations,
                'total' => $formattedLocations->count(),
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get store locations for delivery boy', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError('Failed to retrieve store locations');
        }
    }

    /**
     * Select store locations for delivery boy (multi-select)
     *
     * POST /api/delivery_boy/select-store-locations
     * Body: {
     *   "store_location_ids": [1, 2, 3]
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function selectStoreLocations(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            $validator = Validator::make($request->all(), [
                'store_location_ids' => 'required|array',
                'store_location_ids.*' => 'exists:store_locations,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Get store location IDs
            $storeLocationIds = $request->store_location_ids;

            // Verify all store locations are active
            $storeLocations = \App\Models\StoreLocation::whereIn('id', $storeLocationIds)
                ->where('status', 1)
                ->get();

            if ($storeLocations->count() !== count($storeLocationIds)) {
                return CommonHelper::responseError('One or more selected store locations are not available!');
            }

            // Sync store locations (replaces all existing selections)
            $deliveryBoy->storeLocations()->sync($storeLocationIds);

            // Reload with relationships
            $deliveryBoy->load('storeLocations.city');

            // Format response
            $formattedLocations = $deliveryBoy->storeLocations->map(function ($location) {
                return [
                    'id' => $location->id,
                    'name' => $location->name,
                    'address' => $location->address,
                    'latitude' => $location->latitude,
                    'longitude' => $location->longitude,
                    'phone' => $location->phone,
                    'email' => $location->email,
                    'city_id' => $location->city_id,
                    'city_name' => $location->city ? $location->city->name : '',
                ];
            });

            Log::info('Delivery boy selected store locations', [
                'delivery_boy_id' => $deliveryBoy->id,
                'store_location_ids' => $storeLocationIds,
                'count' => count($storeLocationIds)
            ]);

            return CommonHelper::responseWithData([
                'store_locations' => $formattedLocations,
                'total' => $formattedLocations->count(),
                'message' => 'Store locations selected successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to select store locations for delivery boy', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update delivery boy order priority
     *
     * POST /api/delivery_boy/update-order-priority
     * Body: {
     *   "orders_priority": 0
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateOrderPriority(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            $validator = Validator::make($request->all(), [
                'orders_priority' => 'required|integer|in:0,1,2'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found!');
            }

            // Update order priority
            $deliveryBoy->orders_priority = $request->orders_priority;
            $deliveryBoy->save();

            Log::info('Delivery boy order priority updated', [
                'delivery_boy_id' => $deliveryBoy->id,
                'orders_priority' => $request->orders_priority
            ]);

            return CommonHelper::responseWithData([
                'orders_priority' => $deliveryBoy->orders_priority,
                'orders_priority_name' => $this->getOrderPriorityName($deliveryBoy->orders_priority),
                'message' => 'Order priority updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update order priority for delivery boy', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get delivery boy order priority
     *
     * GET /api/delivery_boy/get-order-priority
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getOrderPriority(Request $request)
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

            // Get all available priority options
            $priorityOptions = [
                // [
                //     'value' => DeliveryBoy::$priorityBoth,
                //     'label' => DeliveryBoy::$PriorityBoth,
                //     'description' => 'Accept all types of orders'
                // ],
                [
                    'value' => DeliveryBoy::$priorityFoodGrocery,
                    'label' => DeliveryBoy::$PriorityFoodGrocery,
                    'description' => 'Accept orders from Zenfoo managed stores only'
                ],
                [
                    'value' => DeliveryBoy::$priorityMultiOrders,
                    'label' => DeliveryBoy::$PriorityMultiOrders,
                    'description' => 'Accept multiple orders together from any category (food, grocery, supermart, or any type)'
                ]
            ];

            return CommonHelper::responseWithData([
                'current_priority' => $deliveryBoy->orders_priority ?? DeliveryBoy::$priorityBoth,
                'current_priority_name' => $this->getOrderPriorityName($deliveryBoy->orders_priority ?? DeliveryBoy::$priorityBoth),
                'priority_options' => $priorityOptions
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get order priority for delivery boy', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Helper function to get status name
     *
     * @param int $status
     * @return string
     */
    private function getStatusName($status)
    {
        switch ($status) {
            case DeliveryBoy::$statusRegistered:
                return DeliveryBoy::$Registered;
            case DeliveryBoy::$statusActive:
                return DeliveryBoy::$Active;
            case DeliveryBoy::$statusRejected:
                return DeliveryBoy::$Rejected;
            case DeliveryBoy::$statusDeactivated:
                return DeliveryBoy::$Deactivated;
            case DeliveryBoy::$statusRemoved:
                return DeliveryBoy::$Removed;
            default:
                return 'Unknown';
        }
    }

    /**
     * Helper function to get order priority name
     *
     * @param int $priority
     * @return string
     */
    private function getOrderPriorityName($priority)
    {
        switch ($priority) {
            case DeliveryBoy::$priorityBoth:
                return DeliveryBoy::$PriorityBoth;
            case DeliveryBoy::$priorityFoodGrocery:
                return DeliveryBoy::$PriorityFoodGrocery;
            case DeliveryBoy::$priorityMultiOrders:
                return DeliveryBoy::$PriorityMultiOrders;
            default:
                return DeliveryBoy::$PriorityBoth;
        }
    }

    /**
     * Update FCM Token for Delivery Boy
     *
     * POST /api/delivery_boy/update-fcm-token
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateFcmToken(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized. Please login to continue.');
            }

            // Validation rules
            $validator = Validator::make($request->all(), [
                'fcm_token' => 'required|string',
                'platform' => 'nullable|string|in:android,ios,web'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Start database transaction
            DB::beginTransaction();

            try {
                // Update or create FCM token record
                AdminToken::updateOrCreate(
                    [
                        'user_id' => $user->id,
                        'type' => Role::$roleNameDeliveryBoy,
                    ],
                    [
                        'fcm_token' => $request->fcm_token,
                        'platform' => $request->platform ?? 'android'
                    ]
                );

                // Commit transaction
                DB::commit();
            } catch (\Exception $dbException) {
                // Rollback database changes
                DB::rollBack();
                throw $dbException;
            }

            Log::info('FCM token updated for delivery boy', [
                'user_id' => $user->id,
                'platform' => $request->platform ?? 'android'
            ]);

            return response()->json([
                'status' => true,
                'message' => 'FCM token updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update FCM token', [
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
     * Generate unique referral code for delivery boy
     * Uses sequential numbering starting from 1001
     *
     * @param int $deliveryBoyId
     * @return string
     */
    private function generateReferralCode($deliveryBoyId)
    {
        // Get the highest referral code number
        $lastReferralCode = DB::table('delivery_boys')
            ->whereNotNull('referral_code')
            ->orderByRaw('CAST(referral_code AS UNSIGNED) DESC')
            ->value('referral_code');

        if ($lastReferralCode) {
            // Increment the last code
            $nextCode = (int)$lastReferralCode + 1;
        } else {
            // Start from 1001 if no codes exist yet
            $nextCode = 1001;
        }

        // Ensure uniqueness (in case of concurrent requests)
        while (DB::table('delivery_boys')->where('referral_code', (string)$nextCode)->exists()) {
            $nextCode++;
        }

        return (string)$nextCode;
    }

    /**
     * Get referral tracking data for delivery boy
     *
     * GET /api/delivery-boy/referral-tracking
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getReferralTracking(Request $request)
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

            // Get referrals made by this driver
            $myReferrals = DeliveryBoyReferralTracking::where('referring_delivery_boy_id', $deliveryBoy->id)
                ->with('referredDeliveryBoy')
                ->get()
                ->map(function ($tracking) {
                    return [
                        'referred_driver_id' => $tracking->referred_delivery_boy_id,
                        'referred_driver_name' => $tracking->referredDeliveryBoy->name,
                        'referred_driver_mobile' => $tracking->referredDeliveryBoy->mobile,
                        'completed_orders' => $tracking->completed_orders_count,
                        'required_orders' => $tracking->required_orders_count,
                        'progress_percentage' => $tracking->getProgressPercentage(),
                        'bonus_earned' => $tracking->is_bonus_paid,
                        'bonus_amount' => $tracking->bonus_amount,
                        'bonus_paid_at' => $tracking->bonus_paid_at ? $tracking->bonus_paid_at->toIso8601String() : null,
                        'created_at' => $tracking->created_at->toIso8601String()
                    ];
                });

            // Calculate total bonuses earned
            $bonusesEarned = DeliveryBoyReferralTracking::where('referring_delivery_boy_id', $deliveryBoy->id)
                ->where('is_bonus_paid', true)
                ->count();

            $totalBonusAmount = DeliveryBoyReferralTracking::where('referring_delivery_boy_id', $deliveryBoy->id)
                ->where('is_bonus_paid', true)
                ->sum('bonus_amount');

            // Get info about who referred this driver
            $whoReferredMe = null;
            if ($deliveryBoy->referred_by) {
                $myReferralTracking = DeliveryBoyReferralTracking::where('referred_delivery_boy_id', $deliveryBoy->id)
                    ->with('referringDeliveryBoy')
                    ->first();

                if ($myReferralTracking) {
                    $whoReferredMe = [
                        'referring_driver_id' => $myReferralTracking->referring_delivery_boy_id,
                        'referring_driver_name' => $myReferralTracking->referringDeliveryBoy->name,
                        'my_completed_orders' => $myReferralTracking->completed_orders_count,
                        'required_orders' => $myReferralTracking->required_orders_count,
                        'progress_percentage' => $myReferralTracking->getProgressPercentage(),
                        'bonus_status' => $myReferralTracking->is_bonus_paid ? 'paid' : 'pending'
                    ];
                }
            }

            $responseData = [
                'my_referral_code' => $deliveryBoy->referral_code,
                'my_referrals' => $myReferrals,
                'total_referrals' => $myReferrals->count(),
                'bonuses_earned' => $bonusesEarned,
                'total_bonus_amount' => (float)$totalBonusAmount,
                'who_referred_me' => $whoReferredMe
            ];

            return CommonHelper::responseWithData($responseData);

        } catch (\Exception $e) {
            Log::error('Failed to get referral tracking data', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError('Failed to retrieve referral tracking data.');
        }
    }

    /**
     * Update Mobile Number for Delivery Boy
     *
     * POST /api/delivery_boy/update-mobile
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateMobile(Request $request)
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
                'mobile' => 'required|string|min:10|max:15',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Check if mobile already exists in delivery_boys table (excluding current user)
            $existingDeliveryBoy = DeliveryBoy::where('mobile', $request->mobile)
                ->where('id', '!=', $deliveryBoy->id)
                ->first();

            if ($existingDeliveryBoy) {
                return CommonHelper::responseError('This mobile number is already registered with another delivery boy.');
            }

            // Check if mobile already exists in admins table (excluding current user)
            $existingAdmin = Admin::where('mobile', $request->mobile)
                ->where('id', '!=', $user->id)
                ->first();

            if ($existingAdmin) {
                return CommonHelper::responseError('This mobile number is already registered with another user.');
            }

            // Start database transaction
            DB::beginTransaction();

            try {
                // Update mobile in delivery_boys table
                $deliveryBoy->mobile = $request->mobile;
                $deliveryBoy->save();

                // Update mobile in admins table
                $admin = Admin::find($user->id);
                if ($admin) {
                    $admin->mobile = $request->mobile;
                    $admin->save();
                }

                // Commit transaction
                DB::commit();
            } catch (\Exception $dbException) {
                // Rollback database changes
                DB::rollBack();
                throw $dbException;
            }

            Log::info('Mobile number updated for delivery boy', [
                'delivery_boy_id' => $deliveryBoy->id,
                'admin_id' => $user->id,
                'new_mobile' => $request->mobile
            ]);

            return response()->json([
                'status' => true,
                'message' => 'Mobile number updated successfully',
                'data' => [
                    'mobile' => $deliveryBoy->mobile
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update mobile number', [
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
     * Get mobile number
     *
     * GET /api/delivery_boy/get-mobile
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getMobile(Request $request)
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

            return CommonHelper::responseWithData([
                'mobile' => $deliveryBoy->mobile,
                'delivery_boy_id' => $deliveryBoy->id,
                'name' => $deliveryBoy->name
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get mobile number', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError('Failed to fetch mobile number.');
        }
    }

    /**
     * Send OTP for mobile number update
     * Checks if the new mobile is not already registered, then sends OTP
     *
     * POST /api/delivery_boy/send-mobile-update-otp
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function sendMobileUpdateOtp(Request $request)
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
                'mobile' => 'required|digits:10',
            ], [
                'mobile.required' => 'Mobile number is required.',
                'mobile.digits' => 'Mobile number must be exactly 10 digits.'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $newMobile = $request->mobile;

            // Check if same as current mobile
            if ($deliveryBoy->mobile === $newMobile) {
                return CommonHelper::responseError('New mobile number is same as current mobile number.');
            }

            // Check if mobile already exists in delivery_boys table (excluding current user)
            $existingDeliveryBoy = DeliveryBoy::where('mobile', $newMobile)
                ->where('id', '!=', $deliveryBoy->id)
                ->first();

            if ($existingDeliveryBoy) {
                return CommonHelper::responseError('This mobile number is already registered with another delivery boy.');
            }

            // Check if mobile already exists in admins table (excluding current user)
            $existingAdmin = Admin::where('mobile', $newMobile)
                ->where('id', '!=', $user->id)
                ->first();

            if ($existingAdmin) {
                return CommonHelper::responseError('This mobile number is already registered with another user.');
            }

            // Generate OTP
            $testNumbers = ['9999999999', '7702480125', '9912378442'];
            if (in_array($newMobile, $testNumbers)) {
                $otp = 1234;
            } else {
                $otp = rand(1000, 9999);
            }

            // Send OTP via SMS only if not test number
            if (!in_array($newMobile, $testNumbers)) {
                $smsResult = SmsService::sendDeliveryOtp($newMobile, $otp);

                if (!$smsResult['success']) {
                    return CommonHelper::responseError($smsResult['message']);
                }
            }

            // Store OTP and new mobile in delivery boy record for verification
            $deliveryBoy->mobile_update_otp = $otp;
            $deliveryBoy->mobile_update_number = $newMobile;
            $deliveryBoy->save();

            Log::info('Mobile update OTP sent', [
                'delivery_boy_id' => $deliveryBoy->id,
                'new_mobile' => $newMobile
            ]);

            return CommonHelper::responseWithData([
                'mobile' => $newMobile,
                'message' => 'OTP sent successfully to the new mobile number.'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to send mobile update OTP', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError('Failed to send OTP. Please try again.');
        }
    }

    /**
     * Verify OTP and update mobile number
     *
     * POST /api/delivery_boy/verify-mobile-update-otp
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function verifyMobileUpdateOtp(Request $request)
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
                'mobile' => 'required|digits:10',
                'otp' => 'required|digits:4',
            ], [
                'mobile.required' => 'Mobile number is required.',
                'mobile.digits' => 'Mobile number must be exactly 10 digits.',
                'otp.required' => 'OTP is required.',
                'otp.digits' => 'OTP must be exactly 4 digits.'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $newMobile = $request->mobile;
            $otp = $request->otp;

            // Check if OTP request exists
            if (empty($deliveryBoy->mobile_update_otp) || empty($deliveryBoy->mobile_update_number)) {
                return CommonHelper::responseError('No OTP request found. Please request OTP first.');
            }

            // Check if mobile matches the one OTP was sent to
            if ($deliveryBoy->mobile_update_number !== $newMobile) {
                return CommonHelper::responseError('Mobile number does not match. Please request OTP again.');
            }

            // Verify OTP
            if ($deliveryBoy->mobile_update_otp != $otp) {
                return CommonHelper::responseError('Invalid OTP. Please try again.');
            }

            // Re-check if mobile already exists (in case someone registered it while OTP was pending)
            $existingDeliveryBoy = DeliveryBoy::where('mobile', $newMobile)
                ->where('id', '!=', $deliveryBoy->id)
                ->first();

            if ($existingDeliveryBoy) {
                // Clear OTP fields
                $deliveryBoy->mobile_update_otp = null;
                $deliveryBoy->mobile_update_number = null;
                $deliveryBoy->save();
                return CommonHelper::responseError('This mobile number is already registered with another delivery boy.');
            }

            // Start database transaction
            DB::beginTransaction();

            try {
                // Update mobile in delivery_boys table
                $deliveryBoy->mobile = $newMobile;
                $deliveryBoy->mobile_update_otp = null;
                $deliveryBoy->mobile_update_number = null;
                $deliveryBoy->save();

                // Update mobile in admins table
                $admin = Admin::find($user->id);
                if ($admin) {
                    $admin->mobile = $newMobile;
                    $admin->save();
                }

                // Commit transaction
                DB::commit();
            } catch (\Exception $dbException) {
                DB::rollBack();
                throw $dbException;
            }

            Log::info('Mobile number updated successfully', [
                'delivery_boy_id' => $deliveryBoy->id,
                'admin_id' => $user->id,
                'new_mobile' => $newMobile
            ]);

            return CommonHelper::responseWithData([
                'mobile' => $newMobile,
                'message' => 'Mobile number updated successfully.'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to verify mobile update OTP', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::id()
            ]);
            return CommonHelper::responseError('Failed to update mobile number. Please try again.');
        }
    }
}
