<?php

namespace App\Http\Controllers\API\Seller;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Seller;
use App\Models\Admin;
use App\Models\Role;

use Validator;
use Exception;
use App\Helpers\CommonHelper;
use Illuminate\Support\Facades\Auth;

use App\Models\AdminToken;
use App\Models\Setting;
use App\Services\SmsService;


class LoginController extends Controller
{
    /**
     * Send OTP
     */
    public function sendOtp(Request $request)
    {
        try {

            // Validate input
            $validator = Validator::make($request->all(), [
                'phone' => 'required|digits:10'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => 0,
                    'message' => $validator->errors()->flatten()->first()
                ], 422);
            }

            $phone = $request->phone;

            // Use fixed OTP "1234" for testing phone number 9000000001
            if ($phone === '9000000001') {
                $otp = 1234;
            } else {
                $otp = rand(1000, 9999);
            }

            // Send OTP via SMS
            $smsResult = SmsService::sendOtp($phone, $otp);

            if (!$smsResult['success']) {
                return response()->json([
                    'success' => 0,
                    'message' => $smsResult['message']
                ], 500);
            }

            // Check existing seller and admin
            $seller = Seller::where('mobile', $phone)->first();
            $admin = Admin::where('mobile', $phone)->first();

            if ($seller) {
                // Check if seller account is soft-deleted
                if ($seller->deleted_at) {
                    $supportNumber = Setting::support_value('support_number', 'seller');
                    $supportEmail = Setting::support_value('support_email', 'seller');
                    $contactInfo = '';
                    if ($supportNumber) $contactInfo .= ' Phone: ' . $supportNumber;
                    if ($supportEmail) $contactInfo .= ' Email: ' . $supportEmail;

                    return response()->json([
                        'success' => 0,
                        'message' => 'This account has been deleted. For any queries, please contact admin.' . $contactInfo
                    ], 400);
                }

                // Update OTP for existing seller
                $seller->otp_login = $otp;
                $seller->save();

                // Ensure admin account exists for this seller
                if (!$admin) {
                    $admin = new Admin();
                    $admin->mobile = $phone;
                    $admin->email = " ";
                    $admin->password = bcrypt("StrongPass123@21985422344");
                    $admin->created_by = 1;
                    $admin->role_id = 3;
                    $admin->save();

                    $seller->admin_id = $admin->id;
                    $seller->save();
                }
            } else {
                // Check if admin with this phone already exists (allow dual roles)
                if ($admin) {
                    // Check if it's a delivery boy (role_id = 4)
                    if ($admin->role_id == 4) {
                        // Delivery boy wants to also be a seller - create new admin for seller role
                        $newAdmin = new Admin();
                        $newAdmin->mobile = $phone;
                        $newAdmin->email = $admin->email ?: " ";
                        $newAdmin->username = $admin->username;
                        $newAdmin->password = $admin->password; // Use same password
                        $newAdmin->created_by = 1;
                        $newAdmin->role_id = 3; // Seller role ID
                        $newAdmin->save();
                        $admin = $newAdmin;

                        \Log::info('Delivery boy registered as seller (dual role)', [
                            'phone' => $phone,
                            'delivery_admin_id' => $admin->id,
                            'seller_admin_id' => $newAdmin->id
                        ]);
                    } else if ($admin->role_id == 3) {
                        // Admin exists with seller role but no seller record, use existing admin
                        // This is fine, continue
                    } else {
                        return response()->json([
                            'success' => 0,
                            'message' => 'This phone number is already registered with a different role. Please contact support.'
                        ], 400);
                    }
                } else {
                    // Create new admin account
                    $admin = new Admin();
                    $admin->mobile = $phone;
                    $admin->email = " ";
                    $admin->password = bcrypt("StrongPass123@21985422344");
                    $admin->created_by = 1;
                    $admin->role_id = 3;
                    $admin->save();
                }

                $seller = new Seller();
                $seller->mobile = $phone;
                $seller->otp_login = $otp;
                // $seller->status = 0;
                $seller->admin_id = $admin->id;
                $seller->save();
            }

            return response()->json([
                'success' => 1,
                'message' => 'OTP sent successfully',
                'data' => [
                    'phone' => $phone
                ]
            ]);

        } catch (Exception $e) {

            return response()->json([
                "success" => 0,
                "message" => $e->getMessage()
            ], 500);
        }
    }

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

            // Step 1: Get seller by mobile
            $seller = Seller::where('mobile', $request->phone)->first();

            if (!$seller) {
                return CommonHelper::responseError('Seller account not found!');
            }

            // Check if seller account is soft-deleted
            if ($seller->deleted_at) {
                $supportNumber = Setting::support_value('support_number', 'seller');
                $supportEmail = Setting::support_value('support_email', 'seller');
                $contactInfo = '';
                if ($supportNumber) $contactInfo .= ' Phone: ' . $supportNumber;
                if ($supportEmail) $contactInfo .= ' Email: ' . $supportEmail;

                return CommonHelper::responseError('This account has been deleted. For any queries, please contact admin.' . $contactInfo);
            }

            // Step 2: Verify OTP
            if ($seller->otp_login != $request->otp) {
                return CommonHelper::responseError('Invalid OTP!');
            }

            // Clear OTP after successful verification
            $seller->otp_login = null;
            $seller->save();

            // Step 3: Check Seller status
            // if ($seller->status == Seller::$statusRegistered) {
            //     return CommonHelper::responseSuccess(
            //         "Your request is under review, you will get notification after approval!"
            //     );
            // }

            // if ($seller->status == Seller::$statusRejected) {
            //     $data["status"] = $seller->status;
            //     $data["remark"] = $seller->remark ?? "";
            //     return CommonHelper::responseSuccess(
            //         "Your request was rejected, please contact Administrator!",
            //         $data
            //     );
            // }

            // if ($seller->status == Seller::$statusDeactivated) {
            //     return CommonHelper::responseSuccess("Your account is deactivated, please contact Administrator!");
            // }

            // Step 4: Get Admin user mapped to Seller
            $user = Admin::find($seller->admin_id);

            if (!$user) {
                return CommonHelper::responseSuccess('Admin account not found for this seller!');
            }

            // Login user
            Auth::login($user, false);

            // Save device token (optional)
            if (!empty($request->fcm_token)) {
                AdminToken::updateOrCreate(
                    [
                        'user_id' => $user->id,
                        'type' => Role::$roleNameSeller,
                    ],
                    [
                        'fcm_token' => $request->fcm_token,
                        'platform' => $request->platform
                    ]
                );
            }

            // Generate access token
            $accessToken = $user->createToken('authToken')->accessToken;

            return CommonHelper::responseWithData([
                'user' => $user,
                'seller' => $seller,
                'access_token' => $accessToken
            ]);

        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update FCM Token
     * POST /api/seller/update-fcm-token
     */
    public function updateFcmToken(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'fcm_token' => 'required|string',
                'platform' => 'required|in:android,ios'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $seller = auth()->user();
            $fcmToken = $request->input('fcm_token');
            $platform = $request->input('platform');

            // Update or create FCM token record
            AdminToken::updateOrCreate(
                [
                    'user_id' => $seller->id,
                    'type' => Role::$roleNameSeller,
                ],
                [
                    'fcm_token' => $fcmToken,
                    'platform' => $platform
                ]
            );

            return CommonHelper::responseSuccess('FCM token updated successfully');
        } catch (\Exception $e) {
            return CommonHelper::responseError('Failed to update FCM token: ' . $e->getMessage());
        }
    }


}