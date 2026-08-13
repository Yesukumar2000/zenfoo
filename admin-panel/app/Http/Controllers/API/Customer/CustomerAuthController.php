<?php

// namespace App\Http\Controllers\Api\Customer;
namespace App\Http\Controllers\API\Customer;

use App\Helpers\CommonHelper;
use App\Helpers\SmsHelper;
use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Models\Cart;
use App\Models\Setting;
use App\Models\SmsVerification;
use App\Models\UserToken;
use App\Models\WalletTransaction;
use App\Services\MediaUploadService;
use App\Services\SmsService;
use App\Services\UserSmsService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use Kreait\Firebase\Factory;
use Response;
use Illuminate\Support\Facades\Mail;
use App\Mail\VerifyEmail;
use Carbon\Carbon;
use Illuminate\Support\Str;


class CustomerAuthController extends Controller
{
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'country_code'      => 'required',
            'phone'      => 'required',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        
        $user = User::where('mobile', $request->phone)
                ->where('status', 0)
                ->first();

            if ($user) {
                return CommonHelper::responseSuccess('user_deactivated');
            }

            $user = User::withTrashed()->firstOrCreate(
                ['mobile' => $request->phone],
                ['country_code' => $request->country_code]
            );

            // referral_code is not fillable, so firstOrCreate cannot set it —
            // assign it directly, otherwise every account created here ends up
            // with no code of its own and can never refer anyone.
            if (blank($user->referral_code)) {
                $user->referral_code = strtoupper(substr(sha1(microtime()), 0, 6));
                $user->save();
            }

        // Check if user account is soft-deleted
        if ($user->deleted_at) {
            $supportNumber = Setting::support_value('support_number', 'customer');
            $supportEmail = Setting::support_value('support_email', 'customer');
            $contactInfo = '';
            if ($supportNumber) $contactInfo .= ' Phone: ' . $supportNumber;
            if ($supportEmail) $contactInfo .= ' Email: ' . $supportEmail;

            return CommonHelper::responseError('This account has been deleted. For any queries, please contact admin.' . $contactInfo);
        }

        Auth::login($user);

        $accessToken = $user->createToken('authToken')->accessToken;
        $user->referral_code = $user->referral_code ?? "";
        $user->status = intval($user->status) ?? 0;

        $res = ['user' => $user, 'access_token' => $accessToken];
        // **Update or create FCM token**
        if (isset($request->fcm_token)) {
            $token = UserToken::where("fcm_token", $request->fcm_token)->first();
            if ($token) {
                $token->user_id = auth()->user()->id;
                $token->platform = $request->platform;
                $token->fcm_token = $request->fcm_token;
                $token->save();
            } elseif (UserToken::where('user_id', auth()->user()->id)->where('platform', $request->platform)->exists()) {
                $existingToken = UserToken::where('user_id', auth()->user()->id)->where('platform', $request->platform)->first();
                $existingToken->fcm_token = $request->fcm_token;
                $existingToken->save();
            } else {
                UserToken::firstOrCreate([
                    'user_id' => auth()->user()->id,
                    'type'    => 'customer',
                    'fcm_token' => $request->fcm_token,
                    'platform'  => $request->platform
                ]);
            }
        }

        $phone = $request->input('phone');

        // Use fixed OTP "1234" for testing phone number 9999999999
        if ($phone === '9999999999') {
            $otp = 1234;
        } else {
            $otp = rand(1000, 9999);
        }

        // Send OTP via SMS
        $smsResult = UserSmsService::sendOtp($phone, $otp);

        if (!$smsResult['success']) {
            Log::error($smsResult['message']);
            $otp = 1234;

            // return CommonHelper::responseError($smsResult['message']);
        }

        // Set OTP expiration time, for example, 10 minutes
        $expiresAt = Carbon::now()->addMinutes(10);

        $fullPhone = $request->input('country_code') . $request->input('phone');

        // Store the OTP in the database
        SmsVerification::insert([
            'phone' => $fullPhone,
            'otp' => $otp,
            'status' => 'pending',
            'expires_at' => $expiresAt,
            'created_at' => Carbon::now(),
            'updated_at' => Carbon::now(),
        ]);

        return CommonHelper::responseSuccess("OTP sent Successfully!");
    }

    public function verifyContact(Request $request)
    {
        $validator = Validator::make($request->all(),[
            'phone' => 'required|numeric',
            'otp' => 'required|string',
            'country_code' => 'required|string',
        ]);
        
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
    
        $phone = $request->input('country_code').$request->input('phone');
        $otp = $request->input('otp');
    
        // Retrieve the OTP record
        $otpRecord = SmsVerification::where('phone', $phone)
                ->latest('created_at') // Fetch the latest record based on created_at
                ->first();

        if ($otpRecord && $otpRecord->otp == $otp && $otpRecord->status == 'pending' &&  \Carbon\Carbon::parse($otpRecord->expires_at)->timezone('Asia/Kolkata') > \Carbon\Carbon::now('Asia/Kolkata')) {
            $otpRecord->status = 'verified';
            $otpRecord->save();
            // Retrieve the user from the users table where mobile = phone and type = phone
            $phone =$request->input('phone');
            $user = User::where('mobile', $phone)->first();
            if ($user) {
                // Check if user account is soft-deleted
                if ($user->deleted_at) {
                    $supportNumber = Setting::support_value('support_number', 'customer');
                    $supportEmail = Setting::support_value('support_email', 'customer');
                    $contactInfo = '';
                    if ($supportNumber) $contactInfo .= ' Phone: ' . $supportNumber;
                    if ($supportEmail) $contactInfo .= ' Email: ' . $supportEmail;

                    return CommonHelper::responseError('This account has been deleted. For any queries, please contact admin.' . $contactInfo);
                }

                // login() creates the account with firstOrCreate before the OTP
                // is ever verified, so a first-time signup lands HERE, not in
                // the create branch below — which is why referral attribution
                // has to happen on this path too. Guarded so an established
                // customer cannot be retro-attributed: the code only applies
                // while the account has none and has never ordered.
                if (filled($request->referral_code) && blank($user->friends_code) && !$user->orders()->exists()) {
                    $referrer = User::where('status', 1)
                        ->where('referral_code', $request->referral_code)
                        ->first();
                    if ($referrer && $referrer->id != $user->id) {
                        $user->friends_code = $request->referral_code;
                        $user->save();
                    }
                }

                // Self-heal accounts created before referral codes were issued
                // on signup, so they can refer without waiting for a backfill.
                if (blank($user->referral_code)) {
                    $user->referral_code = strtoupper(substr(sha1(microtime()), 0, 6));
                    $user->save();
                }

                $accessToken = $user->createToken('authToken')->accessToken;
                $user->referral_code = $user->referral_code ?? "";
                $res = ['user' => $user, 'access_token' => $accessToken];
                return CommonHelper::responseSuccessWithData("OTP is valid! User found.", $res);
            } else {
                // OTP is valid but no account exists yet — create the customer now.
                $user = new User();
                $user->name = $request->get('name', '');
                $user->email = $request->get('email', '');
                $user->profile = '';
                $user->referral_code = strtoupper(substr(sha1(microtime()), 0, 6));
                $user->status = 1;
                $user->country_code = $request->input('country_code', '');
                $user->mobile = $phone;
                $user->type = 'phone';
                $user->password = null;

                // Attribute the referral: the entered code must belong to an
                // existing active customer. friends_code is what the order/bonus
                // pipeline reads to credit the referrer after the first order.
                if (filled($request->referral_code)) {
                    $referrer = User::where('status', 1)
                        ->where('referral_code', $request->referral_code)
                        ->first();
                    if ($referrer) {
                        $user->friends_code = $request->referral_code;
                    }
                }

                // Handle Stripe customer creation (mirrors register()).
                $stripeSettings = CommonHelper::getSettings(['stripe_payment_method']);
                $stripePaymentMethod = $stripeSettings['stripe_payment_method'] ?? null;
                if ($stripePaymentMethod == 1) {
                    try {
                        $user->createOrGetStripeCustomer();
                    } catch (\Exception $e) {
                        Log::error('Stripe Error: ' . $e->getMessage());
                    }
                }

                $user->save();

                Auth::login($user);
                $accessToken = $user->createToken('authToken')->accessToken;
                $res = ['user' => $user, 'access_token' => $accessToken];

                return CommonHelper::responseSuccessWithData("OTP is valid! User found.", $res);
            }
        } else {
            return CommonHelper::responseError("OTP is invalid or has expired.");
        }
    }


    public function register(Request $request)
    {
        $requestData = $request->all();

        $validator = Validator::make($requestData, [
            'type'            => 'required|in:phone,apple,google,email',
            'mobile'          => 'required_if:type,phone|numeric',
            'email'           => 'required_if:type,apple,google,email|email',
            'phone_auth_type' => 'nullable|in:phone_auth_otp,phone_auth_password',
            'password'        => [
                'nullable',
                'min:6',
                function ($attribute, $value, $fail) use ($request) {
                    if (
                        ($request->type == 'phone' && $request->phone_auth_type == 'phone_auth_password') ||
                        $request->type == 'email'
                    ) {
                        if (empty($value)) {
                            $fail('The password field is required.');
                        }
                    }
                }
            ],
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            if ($request->type == 'phone') {
                $user = User::where('mobile', $request->mobile)
                    ->where('type', $request->type)
                    ->first();

                // if (!$user) {
                //     return CommonHelper::responseError('user_not_exist');
                // }
                // if($request->phone_auth_type == 'phone_auth_password'){
                //     if (empty($user->password)) {
                //         return CommonHelper::responseError('user_exist_password_blank');
                //     }
                // }
                // Auth::login($user);
                // if (
                //     ($request->type == 'email' || ($request->type == 'phone' && $request->phone_auth_type == 'phone_auth_password'))
                // ) {
                //     if (empty($user->password) || !password_verify($request->password, $user->password)) {
                //         return CommonHelper::responseError(__('invalid_password'));
                //     }
                // }
                // $accessToken = $user->createToken('authToken')->accessToken;
                // $user->referral_code = $user->referral_code ?? "";
                // $user->status = intval($user->status) ?? 0;
                // $res = ['user' => $user, 'access_token' => $accessToken];
                if ($user) {
                    return CommonHelper::responseError('user_already_exist');
                }
            }
            if (in_array($request->type, ['email'])) {
                $user = User::where('email', $request->email)
                    ->where('is_verified', 0)
                    ->where('type', $request->type)
                    ->first();

                if ($user) {
                    return CommonHelper::responseError('email_not_verified');
                }
            }

            if (in_array($request->type, ['google', 'apple', 'email'])) {
                $user = User::where('email', $request->email)->first();

                if ($user) {
                    return CommonHelper::responseError('user_exist_with_' . $user->type);
                }
            }

            if ($request->type == 'phone') {
                $user = User::where('type', $request->type)
                    ->where('mobile', $request->mobile)
                    ->where('is_verified', 1)
                    ->first();
            } elseif (in_array($request->type, ['google', 'apple', 'email'])) {
                $user = User::where('type', $request->type)
                    ->where('email', $request->email)
                    ->first();
            }

            if ($user) {
                if ($user->status == User::$deactive) {
                    return CommonHelper::responseError(__('this_customer_account_is_deactivated_kindly_contact_admin'));
                }
            } else {
                // Create a new user
                $referral_code = strtoupper(substr(sha1(microtime()), 0, 6));

                $user = new User();
                $user->name = $request->get('name', '');
                $user->email = $request->get('email', '');
                $user->profile = $request->get('profile', '');
                $user->referral_code = $referral_code;
                $user->status = 1;
                $user->country_code = $request->get('country_code', '');
                $user->mobile = $request->get('mobile', '');
                $user->password = $request->password ? bcrypt($request->password) : null;
                $user->type = $request->type;

                // Attribute the referral. The customer app sends the friend's
                // code as `referral_code`; accept legacy `friends_code` too.
                // Only attribute when the code belongs to an existing active
                // customer, mirroring verify_user(). friends_code is what the
                // order/bonus pipeline reads to credit the referrer.
                $enteredCode = $request->referral_code ?? $request->friends_code ?? null;
                if (filled($enteredCode)) {
                    $referrer = User::where('status', 1)
                        ->where('referral_code', $enteredCode)
                        ->first();
                    if ($referrer) {
                        $user->friends_code = $enteredCode;
                    }
                }

                // Email Verification Process
                if ($request->type == 'email') {
                    $verificationCode = rand(100000, 999999);
                    $user->email_verification_code = $verificationCode;
                    $user->is_verified = false;

                    try {
                        $data = [
                            'type' => 'verify_email',
                            'code' => $verificationCode,
                        ];
                        $subject = 'Mail from ' . Setting::get_value('app_name');
                        CommonHelper::sendMail($user->email, $subject, $data);
                        Log::info('Verification email sent to ' . $user->email);

                        $user->save();
                        return CommonHelper::responseSuccess('verification_mail_sent_successfully');
                    } catch (\Exception $e) {
                        Log::error('Failed to send verification email: ' . $e->getMessage());
                        return CommonHelper::responseError('Failed to send verification email.');
                    }
                }

                // Handle Stripe customer creation
                $stripeSettings = CommonHelper::getSettings(['stripe_payment_method']);
                $stripePaymentMethod = $stripeSettings['stripe_payment_method'] ?? null;

                if ($stripePaymentMethod == 1) {
                    try {
                        $user->createOrGetStripeCustomer();
                    } catch (\Exception $e) {
                        Log::error('Stripe Error: ' . $e->getMessage());
                    }
                } else {
                    Log::warning('Stripe Payment Method setting not found or disabled.');
                }

                $user->save();
            }

            // Authenticate user
            Auth::login($user);
            $accessToken = $user->createToken('authToken')->accessToken;
            $res = ['user' => $user, 'access_token' => $accessToken];

            // Save FCM token if provided
            if ($request->has('fcm_token') && filled($request->fcm_token)) {
                UserToken::updateOrCreate(
                    ['fcm_token' => $request->fcm_token],
                    [
                        'user_id' => auth()->user()->id,
                        'platform' => $request->platform ?? 'unknown',
                        'type' => 'customer',
                    ]
                );
            }

            return CommonHelper::responseWithData($res);
        } catch (\Exception $e) {
            Log::error('Register : ' . $e->getMessage());
            return CommonHelper::responseError($e->getMessage());
        }
    }


    public function logout(Request $request)
    {
        if (isset($request->fcm_token)) {
            $userToken = UserToken::where('type', 'customer')
                ->where('user_id', $request->user()->id)
                ->where('fcm_token', $request->fcm_token)->first();
            if ($userToken) {
                $userToken->delete();
            }
        }

        $token = $request->user()->token();
        $token->revoke();

        return CommonHelper::responseSuccess(__('you_have_been_successfully_logged_out'));
    }

    public function notLogin()
    {
        return CommonHelper::responseError(__('unauthorized'));
    }

    public function deleteAccount(Request $request)
    {
        try {
            $user_id = auth()->user()->id;
            $user = User::where('id', $user_id)->first();

            if (!$user) {
                return CommonHelper::responseError("User account not found!");
            }

            if ($user->mobile == '9876543210') {
                return CommonHelper::responseError("This function is not available in demo mode!");
            }

            // Soft delete the user account with reason
            $user->delete_reason = $request->reason ?? 'No reason provided';
            $user->delete_requested_at = now();
            $user->save();
            $user->delete(); // Soft delete

            // Notify admin about user account deletion
            \App\Services\AdminNotificationService::notifyUserDeleteRequest(
                $user->id,
                $user->name ?? $user->mobile ?? 'Customer #' . $user->id
            );

            return CommonHelper::responseSuccess("Your account has been deleted successfully.");
        } catch (\Exception $e) {
            Log::error('deleteAccount: ' . $e->getMessage());
            return CommonHelper::responseError($e->getMessage());
        }
    }

    public function editProfile(Request $request)
    {
        $user = auth()->user();
        $newMobile = $request->input('mobile');
        $hasOtp = $request->has('otp');

        // Scenario 1: Mobile is being changed but OTP is not provided yet - Send OTP
        if ($newMobile && !$hasOtp && $newMobile !== $user->mobile) {
            // Validate mobile is unique
            $validator = Validator::make($request->all(), [
                'mobile' => 'required|unique:users,mobile,' . $user->id . ',id,deleted_at,NULL',
            ], [
                'mobile.unique' => 'This mobile number is already registered.',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Generate and send OTP
            $otp = rand(1000, 9999);
            $smsResult = SmsService::sendOtp($newMobile, $otp);

            if (!$smsResult['success']) {
                return CommonHelper::responseError('Failed to send OTP: ' . $smsResult['message']);
            }

            // Store OTP in database with 10 minutes expiration
            $expiresAt = \Carbon\Carbon::now('Asia/Kolkata')->addMinutes(10);

            SmsVerification::updateOrCreate(
                ['phone' => $newMobile],
                [
                    'otp' => $otp,
                    'status' => 'pending',
                    'expires_at' => $expiresAt,
                ]
            );

            return CommonHelper::responseWithData([
                'message' => 'OTP sent successfully to your new mobile number.',
                'otp_required' => true,
                'mobile' => $newMobile,
            ]);
        }

        // Scenario 2: OTP is provided - Verify and update profile
        $validatorRules = [
            'name' => 'required',
            'email' => 'required|unique:users,email,' . $user->id . ',id,deleted_at,NULL',
        ];

        // If OTP is provided, validate mobile and OTP
        if ($hasOtp) {
            $validatorRules['mobile'] = 'required|unique:users,mobile,' . $user->id . ',id,deleted_at,NULL';
            $validatorRules['otp'] = 'required|string';
        }

        $validator = Validator::make($request->all(), $validatorRules, [
            'email.unique' => 'The :attribute has already been taken.',
            'mobile.unique' => 'The :attribute has already been taken.',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Verify OTP if provided
        if ($hasOtp && $newMobile) {
            $otpRecord = SmsVerification::where('phone', $newMobile)
                ->where('status', 'pending')
                ->first();

            if (!$otpRecord) {
                return CommonHelper::responseError('OTP request not found. Please request a new OTP first.');
            }

            if ($otpRecord->otp !== $request->input('otp')) {
                return CommonHelper::responseError('Invalid OTP. Please try again.');
            }

            if (\Carbon\Carbon::parse($otpRecord->expires_at)->timezone('Asia/Kolkata') <= \Carbon\Carbon::now('Asia/Kolkata')) {
                return CommonHelper::responseError('OTP has expired. Please request a new OTP.');
            }

            // Mark OTP as verified and update mobile number
            $otpRecord->status = 'verified';
            $otpRecord->save();

            $user->mobile = $newMobile;
        }

        // Update basic profile info
        $user->name = $request->name;
        $user->email = $request->email;

        // Handle profile image upload
        if ($request->hasFile('profile')) {
            try {
                $profile = MediaUploadService::upload($request->file('profile'), 'customers');
                $user->profile = $profile;
            } catch (\Exception $e) {
                return CommonHelper::responseError('Profile upload failed: ' . $e->getMessage());
            }
        }

        // Handle new user onboarding
        if ($user->status == 2) {
            if (isset($request->referral_code)) {
                $validCode = User::where('status', 1)
                    ->where('referral_code', $request->referral_code)->first();
                if ($validCode) {
                    $user->friends_code = $request->referral_code;
                }
            }
            $user->status = 1;
            CommonHelper::setDefaultMailSetting($user->id, 0);
        }

        $user->save();

        return  CommonHelper::responseSuccess(__('profile_updated_successfully'));
    }

    public function ResetPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'old_password' => 'required',
            'new_password' => 'required|min:6|confirmed',
        ], [
            'new_password.confirmed' => __('The new password confirmation does not match.')
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user = auth()->user();

        // Verify that the old password matches the current password in the database
        if (!Hash::check($request->old_password, $user->password)) {
            return CommonHelper::responseError(__('The old password is incorrect.'));
        }

        // Update password to new password
        $user->password = bcrypt($request->new_password);
        $user->save();

        return CommonHelper::responseSuccess(__('password_updated_successfully'));
    }

    public function uploadProfile(Request $request)
    {

        $validator = Validator::make($request->all(), [
            'profile' => 'required',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user = auth()->user();
        if ($request->hasFile('profile')) {
            try {
                $profile = MediaUploadService::uploadWithFullUrl($request->file('profile'), 'customers');
                $user->profile = $profile;
                $user->save();
            } catch (\Exception $e) {
                return CommonHelper::responseError('Profile upload failed: ' . $e->getMessage());
            }
        }
        return  CommonHelper::responseSuccess(__('profile_updated_successfully'));
    }

    public function addFcmToken(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'fcm_token' => 'required|string',
            'platform' => 'required|string|in:android,ios,web', // Adjust platform types as per your app
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user = $request->user('api-customers');
        $user_id = $user ? $user->id : 0;

        $token = UserToken::where('fcm_token', $request->fcm_token)->first();

        if ($token) {
            if ($token->user_id == 0 && $user_id != 0) {
                // Link anonymous token to logged-in user
                $token->user_id = $user_id;
                $token->platform = $request->platform;
                $token->save();
                return CommonHelper::responseSuccess(__('token_updated_successfully'));
            }

            // Token already exists and is correctly linked
            return CommonHelper::responseSuccess(__('token_already_exists'));
        }

        // Create new token
        UserToken::create([
            'user_id' => $user_id,
            'type' => 'customer',
            'fcm_token' => $request->fcm_token,
            'platform' => $request->platform,
        ]);

        return CommonHelper::responseSuccess(__('token_added_successfully'));
    }

    public function updateFcmToken(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'fcm_token' => 'required',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : '';

        $token = UserToken::where("fcm_token", $request->fcm_token)->first();

        if (isset($user_id) && $user_id != "" && !empty($token) && ($token->user_id == 0 || $token->user_id == "")) {
            $token->user_id = $user_id;
            $token->platform = $request->platform;
            $token->save();
            return CommonHelper::responseSuccess(__('token_updated_successfully'));
        } else {
            UserToken::firstOrCreate([
                'user_id' => 0,
                'type' => 'customer',
                'fcm_token' => $request->fcm_token,
                'platform' => $request->platform
            ]);
            return CommonHelper::responseSuccess(__('token_added_successfully'));
        }
    }

    public function getLoginUserDetails(Request $request)
    {
        $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : '';
        $total = Cart::select(DB::raw('COUNT(carts.id) AS total'))->Join('products', 'carts.product_id', '=', 'products.id')->where('carts.save_for_later', '=', 0)->where('user_id', '=', $user_id)->first();
        $total = $total->makeHidden(['image_url']);
        $user = User::select('id', 'name', 'email', 'country_code', 'mobile', 'profile', 'balance', 'referral_code', 'status')->where('id', $user_id)->first();
        if (!empty($user)) {
            return Response::json(array('status' => 1, 'message' => 'success', 'total' => 1, 'cart_items_count' => $total->total, 'user' => $user));
        } else {
            return CommonHelper::responseError(__('unauthorized'));
        }
    }

    /**
     * Validate a friend's referral code before/at signup so the app can give
     * immediate feedback. Non-blocking: signup never fails on a bad code, but
     * the user is told whether it will actually be applied.
     */
    public function validateReferralCode(Request $request)
    {
        $code = trim((string) $request->input('referral_code', ''));

        if ($code === '') {
            return Response::json([
                'status' => 0,
                'valid' => false,
                'message' => 'Please enter a referral code',
            ]);
        }

        $referrer = User::where('status', 1)
            ->where('referral_code', $code)
            ->first();

        if (!$referrer) {
            return Response::json([
                'status' => 0,
                'valid' => false,
                'message' => 'Invalid referral code',
            ]);
        }

        return Response::json([
            'status' => 1,
            'valid' => true,
            'message' => 'Referral code applied',
            'referrer_name' => $referrer->name ?: '',
        ]);
    }

    /**
     * Referral earnings summary for the logged-in user: how many friends joined
     * with their code, how many converted into a paid bonus, and the total
     * earned (plus the configured credit/cap for display).
     */
    public function getReferralStats(Request $request)
    {
        $userId = $request->user('api-customers') ? $request->user('api-customers')->id : '';
        if ($userId === '') {
            return CommonHelper::responseError(__('unauthorized'));
        }

        $user = User::select('id', 'referral_code')->where('id', $userId)->first();
        if (!$user) {
            return CommonHelper::responseError(__('unauthorized'));
        }

        $referralCode = $user->referral_code ?? '';

        // Friends who signed up using this user's code.
        $friendsJoined = $referralCode === '' ? 0
            : User::where('friends_code', $referralCode)->count();

        // Bonuses actually credited to this user.
        $bonusQuery = WalletTransaction::where('user_id', $userId)
            ->where('type', 'credit')
            ->where('message', CommonHelper::REFERRAL_BONUS_MESSAGE);

        $successfulReferrals = (clone $bonusQuery)->count();
        $totalEarned = (float) (clone $bonusQuery)->sum('amount');

        $cap = (float) Setting::get_value('max_refer_earn_amount');

        return Response::json([
            'status' => 1,
            'message' => 'success',
            'data' => [
                'referral_code' => $referralCode,
                'friends_joined' => $friendsJoined,
                'successful_referrals' => $successfulReferrals,
                'pending_referrals' => max(0, $friendsJoined - $successfulReferrals),
                'total_earned' => $totalEarned,
                'referral_credit_first_order' => (float) Setting::get_value('referral_credit_first_order'),
                'referral_min_order_amount' => (float) Setting::get_value('referral_min_order_amount'),
                'max_refer_earn_amount' => $cap,
                'remaining_earnings' => $cap > 0 ? max(0, $cap - $totalEarned) : null,
            ],
        ]);
    }

    public function verifyEmail(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'code' => 'required|numeric',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || $user->email_verification_code != $request->code) {
            return CommonHelper::responseError(__('Invalid verification code'));
        }

        // Mark the user as verified
        $user->is_verified = true;
        $user->email_verification_code = null; // Clear the verification code
        $user->save();

        $accessToken = $user->createToken('authToken')->accessToken;

        $res = ['user' => $user, 'access_token' => $accessToken];
        return CommonHelper::responseWithData($res);
    }
    public function forgetPasswordOtp(Request $request)
    {

        $requestData = $request->all();
        $validator = Validator::make($requestData, [
            'email' => 'required|email',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }


        $user = User::where('type', 'email')
            ->where('email', $request->email)
            ->where('is_verified', 1)
            ->first();


        if ($user) {
            $verificationCode = rand(100000, 999999);

            $user->email_verification_code = $verificationCode;

            // Send forgot password code to email
            try {
                $data = [];
                $data['type'] = 'verify_email';
                $data['code'] = $verificationCode;
                $subject = 'Mail from ' . env('APP_NAME');
                // Mail::to($user->email)->send(new VerifyEmail($verificationCode));
                commonHelper::sendMail($user->email, $subject, $data);
                // Email sent successfully, you can log this or proceed as needed
                Log::info('Verification email sent to ' . $user->email);
                // Save the user record
                $user->save();
                return CommonHelper::responseSuccess('verification_mail_sent_successfully');
            } catch (\Exception $e) {
                // Handle any errors that occur during sending
                Log::error('Failed to send verification email: ' . $e->getMessage());
                return CommonHelper::responseError('Failed to send verification email.');
            }
        } else {
            return CommonHelper::responseError('email_is_not_registered');
        }
    }

    public function forgotPassword(Request $request)
    {
        $requestData = $request->all();

        // Validation rules
        $validator = Validator::make($requestData, [
            'type'    => 'required|in:phone,google,apple,email',
            'email'   => 'required_if:type,email|email',
            'mobile'  => 'required_if:type,phone|numeric',
            'otp_verify_method' => 'required_if:type,phone|in:twilio,firebase',
            'otp'               => 'required_if:otp_verify_method,twilio|integer',
            'password' => 'required|string|min:6|confirmed',
            'password_confirmation' => 'required'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        if ($request->type === 'email') {
            // Check OTP in users table for email
            $user = User::where('email', $request->email)
                ->where('email_verification_code', $request->otp)
                ->first();

            if (!$user) {
                return CommonHelper::responseError('Invalid or expired OTP');
            }
        } elseif ($request->type === 'phone') {
            if ($request->otp_verify_method === 'twilio') {
                // Check OTP in sms_verifications table for phone
                $smsVerification = DB::table('sms_verifications')
                    ->where('phone', $request->mobile)
                    ->where('otp', $request->otp)
                    ->first();

                if (!$smsVerification) {
                    return CommonHelper::responseError('Invalid or expired OTP');
                }
            }

            // If otp_verify_method is 'firebase', skip OTP check
            // Find the user based on mobile after OTP verification (or directly for Firebase)
            $user = User::where('mobile', $request->mobile)->first();

            if (!$user) {
                return CommonHelper::responseError('User not found');
            }
        }

        if (!$user) {
            return CommonHelper::responseError('Invalid request');
        }

        // Reset password
        $user->password = Hash::make($request->password);
        $user->email_verification_code = null; // Clear OTP for email
        $user->save();

        return CommonHelper::responseSuccess(__('password_updated_successfully'));
    }
    public function verifyUserExist(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'mobile' => 'required|string',
            'country_code' => 'required|string',
            'type'    => 'required|in:phone,google,apple,email',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user = User::where('mobile', $request->mobile)
            ->where('country_code', $request->country_code)
            ->where('type', $request->type)
            ->first();

        if (!$user) {
            return CommonHelper::responseError('user_not_exist');
        }

        // if (empty($user->password)) {
        //     return CommonHelper::responseSuccessWithData('user_exist_password_blank', $user);
        // }

        return CommonHelper::responseSuccess('user_already_exist');
    }

    public function updateChildrenAllowed(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'is_children_allowed' => 'required|in:0,1',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $user = $request->user('api-customers');

            if (!$user) {
                return CommonHelper::responseError(__('unauthorized'));
            }

            $user->is_children_allowed = $request->is_children_allowed;
            $user->save();

            return CommonHelper::responseSuccess(__('Children allowed setting updated successfully'));
        } catch (\Exception $e) {
            Log::error('updateChildrenAllowed: ' . $e->getMessage());
            return CommonHelper::responseError($e->getMessage());
        }
    }

    public function getChildrenAllowed(Request $request)
    {
        try {
            $user = $request->user('api-customers');

            if (!$user) {
                return CommonHelper::responseError(__('unauthorized'));
            }

            return response()->json([
                'status' => 1,
                'is_children_allowed' => (int) $user->is_children_allowed,
            ], 200);
        } catch (\Exception $e) {
            Log::error('getChildrenAllowed: ' . $e->getMessage());
            return CommonHelper::responseError($e->getMessage());
        }
    }
}
