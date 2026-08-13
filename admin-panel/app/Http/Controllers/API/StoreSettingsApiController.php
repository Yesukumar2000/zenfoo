<?php

namespace App\Http\Controllers\API;
use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\ApiCallTracking;
use Cassandra\Type\Set;
use Illuminate\Http\Request;
use App\Models\Setting;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Config;


class StoreSettingsApiController extends Controller
{
    public function index()
    {
        $timezone_options = CommonHelper::getTimezoneOptions();
        $countries = json_decode(file_get_contents(base_path('config/countries_currency.json')),true);
        $store_settingsArray = array(
                "system_configurations" => 1,
                "system_timezone_gmt" => "+05:30",
                "system_configurations_id" => "13",
                "app_name" => "",
                "support_number" => "",
                "support_email" => "",

                "is_version_system_on" => 0,
                "required_force_update" => 0,
                "current_version" => "1.0.0",

                "ios_is_version_system_on" => 0,
                "ios_required_force_update" => 0,
                "ios_current_version" => "1.0.0",

                "logo" => "",
                "copyright_details" => "",
                "store_address" => "",
                'map_latitude' => "",
                "map_longitude" => "",
                "currency" => "",
                "currency_code" => "",
                "decimal_point" => "",
                "system_timezone" => "",
                "default_city_id" => 0,

                "max_cart_items_count" => "",
                "min_order_amount" => "",
                "low_stock_limit" => "",


                "delivery_boy_bonus_settings" => 0,
                "delivery_boy_bonus_type" => 0,
                "delivery_boy_bonus_percentage" => 0,
                "delivery_boy_bonus_min_amount" => 0,
                "delivery_boy_bonus_max_amount" => 0,

                "area_wise_delivery_charge" => 0,
                "min_amount" => "",
                "delivery_charge" => "",
                "is_refer_earn_on" => 0,
                "min_refer_earn_order_amount" => "",
                "refer_earn_bonus" => "",
                "refer_earn_method" => "",
                "max_refer_earn_amount" => "",
                "minimum_withdrawal_amount" => "",
                "max_product_return_days" => "",

                "user_wallet_refill_limit" => "",
                "tax_name" => "",
                "tax_number" => "",

                "from_mail" => "",
                "reply_to" => "",
                "generate_otp" => 0,

                "app_mode_customer" => 0,
                "app_mode_customer_remark" => "",

                "app_mode_seller" => 0,
                "app_mode_seller_remark" => "",

                "app_mode_delivery_boy" => 0,
                "app_mode_delivery_boy_remark" => "",

                "mailer" => "smtp",
                "smtp_from_mail" => "",
                "smtp_reply_to" => "",
                "smtp_email_password" => "",
                "smtp_host" => "",
                "smtp_port" => "",
                "smtp_content_type" => "",
                "smtp_encryption_type" => "",
                "google_place_api_key" => "",
                "google_map_api_key" => "",
                "apiKey" => "",
                "googleMapApiKey" => "",
                "text_gen_key" => "",
                "fssai_lic_img" => "",
                "is_category_section_in_homepage" => "",
                "is_brand_section_in_homepage" => "",
                "is_seller_section_in_homepage" => "",
                "is_country_section_in_homepage" => "",
                "count_category_section_in_homepage" => "",
                "count_brand_section_in_homepage" => "",
                "count_seller_section_in_homepage" => "",
                "count_country_section_in_homepage" => "",
                "one_seller_cart" => "",
                "self_pickup_mode" => "",
                "playstore_url" => "",
                "appstore_url" => "",
                "guest_cart" => "",
                "phone_login" => "",
                "google_login" => "",
                "apple_login" => "",
                "email_login" => "",
                "panel_login_background_img",
                "notification_delay_after_cart_addition",
                "notification_interval",
                "notification_stop_time",
            );
        $variables = array_keys($store_settingsArray);
        $store_settings = Setting::whereIn('variable',$variables )->get();

        $login_settingsArray = array(
            "phone_login" => "",
                "google_login" => "",
                "apple_login" => "",
                "email_login" => "",
                 "phone_auth_otp" => "",
                "phone_auth_password" => "",
                "firebase_authentication" => "",
                "custom_sms_gateway_otp_based" => ""
            );
            $login_variables = array_keys($login_settingsArray);
            $login_settings = Setting::whereIn('variable',$login_variables )->get();

         $refer_earn_settingsArray = array(
            "referral_min_order_amount" => "",
                "referral_credit_first_order" => ""
            );
            $refer_earn_variables = array_keys($refer_earn_settingsArray);
            $refer_earn_settings = Setting::whereIn('variable',$refer_earn_variables )->get();

        $data = array(
            "store_settingsObject" => $store_settingsArray,
            "timezone_options" => $timezone_options,
            "currency_code" => $countries,
            "store_settings" => $store_settings,
            "login_settings" => $login_settings,
            "refer_earn_settings" => $refer_earn_settings
        );
        return CommonHelper::responseWithData($data);
    }

    public function save_login_setting(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'at_least_one' => 'At least one of phone login or google login must be enabled.',
        ]);

        $validator->after(function ($validator) use ($request) {
            // Validate that at least one of phone_login or google_login is enabled
            if (!$request->phone_login && !$request->google_login) {
                $validator->errors()->add('phone_login', 'At least one of phone login or google login must be enabled.');
                $validator->errors()->add('google_login', 'At least one of phone login or google login must be enabled.');
            }

            // Additional validation if phone_login is enabled
            if ($request->phone_login) {
                if (!$request->firebase_authentication && !$request->custom_sms_gateway_otp_based) {
                    $validator->errors()->add('firebase_authentication', 'When phone login is enabled, either Firebase Authentication or Custom SMS Gateway OTP Based must be enabled.');
                    $validator->errors()->add('custom_sms_gateway_otp_based', 'When phone login is enabled, either Firebase Authentication or Custom SMS Gateway OTP Based must be enabled.');
                }
            }
        });

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        foreach ($request->all() as $key => $value){
            $value = $value ?? " ";
            $setting = Setting::where('variable', $key)->first();
            if ($setting) {
                $setting->variable = $key;
                $setting->value = $value;

                $setting->save();
            } else {
                $setting = new Setting();
                $setting->variable = $key;
                $setting->value = $value;

                $setting->save();
            }
        }
        return CommonHelper::responseSuccess("Login Settings Saved Successfully!");
    }
    public function save_refer_earn_setting(Request $request)
    {
         foreach ($request->all() as $key => $value){
            $value = $value ?? " ";
            $setting = Setting::where('variable', $key)->first();
            if ($setting) {
                $setting->variable = $key;
                $setting->value =  $value;

                $setting->save();
            } else {
                $setting = new Setting();
                $setting->variable = $key;
                $setting->value = $value;

                $setting->save();
            }
        }
        return CommonHelper::responseSuccess("Refer Earn Settings Saved Successfully!");
    }

    /**
     * Save store basic settings (logo, app name, support details, etc.)
     */
    public function save_store_basic_setting(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'logo' => $request->hasFile('logo') ? 'mimes:jpeg,jpg,png,gif' : '',
            'fssai_lic_img' => $request->hasFile('fssai_lic_img') ? 'mimes:jpeg,jpg,png,gif' : '',
            'panel_login_background_img' => $request->hasFile('panel_login_background_img') ? 'mimes:jpeg,jpg,png,gif' : '',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        if($request->hasFile('logo'))
        {
            $file = $request->file('logo');
            $fileName = time().'_'.rand(1111,99999).'.'.$file->getClientOriginalExtension();
            $logo = Storage::disk('public')->putFileAs('logo', $file,$fileName);
        }
        if($request->hasFile('fssai_lic_img'))
        {
            $file1 = $request->file('fssai_lic_img');
            $fileName1 = time().'_'.rand(1111,99999).'.'.$file1->getClientOriginalExtension();
            $fssai_lic_img = Storage::disk('public')->putFileAs('fssai_lic_img', $file1,$fileName1);
        }
        if($request->hasFile('panel_login_background_img'))
        {
            $file2= $request->file('panel_login_background_img');
            $fileName2 = time().'_'.rand(1111,99999).'.'.$file2->getClientOriginalExtension();
            $panel_login_background_img = Storage::disk('public')->putFileAs('panel_login_background_img', $file2,$fileName2);
        }

        // Define store basic settings variables
        $store_basic_variables = [
            'system_configurations', 'system_timezone_gmt', 'system_configurations_id',
            'app_name', 'support_number', 'support_email', 'logo', 'fssai_lic_img',
            'panel_login_background_img', 'copyright_details'
        ];

        foreach ($request->all() as $key => $value) {
            if (in_array($key, $store_basic_variables)) {
                $value = $value ?? " ";
                $setting = Setting::where('variable', $key)->first();

                if ($setting) {
                    $setting->variable = $key;
                    $setting->value = ($key == 'logo' && isset($logo)) ? $logo :
                                    (($key == 'fssai_lic_img' && isset($fssai_lic_img)) ? $fssai_lic_img :
                                    (($key == 'panel_login_background_img' && isset($panel_login_background_img)) ? $panel_login_background_img :
                                    (($key == 'copyright_details') ? str_replace(["\r\n", "\r", "\n"], '<br/>', $request->copyright_details) : $value)));
                    $setting->save();
                } else {
                    $setting = new Setting();
                    $setting->variable = $key;
                    $setting->value = ($key == 'logo' && isset($logo)) ? $logo :
                                    (($key == 'fssai_lic_img' && isset($fssai_lic_img)) ? $fssai_lic_img :
                                    (($key == 'panel_login_background_img' && isset($panel_login_background_img)) ? $panel_login_background_img : $value));
                    $setting->save();
                }
            }
        }

        return CommonHelper::responseSuccess("Store Settings Saved Successfully!");
    }

    /**
     * Save address settings (store address, coordinates, currency, timezone, etc.)
     */
    public function save_address_setting(Request $request)
    {
        $address_variables = [
            'store_address', 'map_latitude', 'map_longitude', 'currency',
            'currency_code', 'decimal_point', 'system_timezone', 'default_city_id'
        ];

        foreach ($request->all() as $key => $value) {
            if (in_array($key, $address_variables)) {
                $value = $value ?? " ";
                $setting = Setting::where('variable', $key)->first();

                if ($setting) {
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                } else {
                    $setting = new Setting();
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                }
            }
        }

        return CommonHelper::responseSuccess("Address Settings Saved Successfully!");
    }

    /**
     * Save other settings (cart limits, order amounts, stock limits, etc.)
     */
    public function save_other_setting(Request $request)
    {
        $other_variables = [
            'max_cart_items_count', 'min_order_amount', 'low_stock_limit'
        ];

        foreach ($request->all() as $key => $value) {
            if (in_array($key, $other_variables)) {
                $value = $value ?? " ";
                $setting = Setting::where('variable', $key)->first();

                if ($setting) {
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                } else {
                    $setting = new Setting();
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                }
            }
        }

        return CommonHelper::responseSuccess("Other Settings Saved Successfully!");
    }

    /**
     * Save delivery boy settings (bonus settings, OTP system, etc.)
     */
    public function save_delivery_boy_setting(Request $request)
    {
        $delivery_boy_variables = [
            'delivery_boy_bonus_settings', 'delivery_boy_bonus_type',
            'delivery_boy_bonus_percentage', 'delivery_boy_bonus_min_amount',
            'delivery_boy_bonus_max_amount', 'generate_otp'
        ];

        foreach ($request->all() as $key => $value) {
            if (in_array($key, $delivery_boy_variables)) {
                $value = $value ?? " ";
                $setting = Setting::where('variable', $key)->first();

                if ($setting) {
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                } else {
                    $setting = new Setting();
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                }
            }
        }

        return CommonHelper::responseSuccess("Delivery Boy Settings Saved Successfully!");
    }

    /**
     * Save app settings (app modes, version control, store URLs, etc.)
     */
    public function save_app_setting(Request $request)
    {
        $app_variables = [
            'app_mode_customer', 'app_mode_customer_remark', 'app_mode_seller',
            'app_mode_seller_remark', 'app_mode_delivery_boy', 'app_mode_delivery_boy_remark',
            'playstore_url', 'appstore_url', 'is_version_system_on', 'required_force_update',
            'current_version', 'ios_is_version_system_on', 'ios_required_force_update', 'ios_current_version'
        ];

        foreach ($request->all() as $key => $value) {
            if (in_array($key, $app_variables)) {
                $value = $value ?? " ";
                $setting = Setting::where('variable', $key)->first();

                if ($setting) {
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                } else {
                    $setting = new Setting();
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                }
            }
        }

        return CommonHelper::responseSuccess("App Settings Saved Successfully!");
    }

    /**
     * Save frontend home settings (category, brand, seller sections, etc.)
     */
    public function save_frontend_home_setting(Request $request)
    {
        $frontend_home_variables = [
            'is_category_section_in_homepage', 'count_category_section_in_homepage',
            'is_brand_section_in_homepage', 'count_brand_section_in_homepage',
            'is_seller_section_in_homepage', 'count_seller_section_in_homepage',
            'is_country_section_in_homepage', 'count_country_section_in_homepage'
        ];

        foreach ($request->all() as $key => $value) {
            if (in_array($key, $frontend_home_variables)) {
                $value = $value ?? " ";
                $setting = Setting::where('variable', $key)->first();

                if ($setting) {
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                } else {
                    $setting = new Setting();
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                }
            }
        }

        return CommonHelper::responseSuccess("Frontend Home Settings Saved Successfully!");
    }

    /**
     * Save SMTP mail settings
     */
    public function save_smtp_mail_setting(Request $request)
    {
        $smtp_variables = [
            'mailer', 'smtp_from_mail', 'smtp_reply_to', 'smtp_email_password', 'smtp_host',
            'smtp_port', 'smtp_content_type', 'smtp_encryption_type'
        ];

        foreach ($request->all() as $key => $value) {
            if (in_array($key, $smtp_variables)) {
                $value = $value ?? " ";
                $setting = Setting::where('variable', $key)->first();

                if ($setting) {
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                } else {
                    $setting = new Setting();
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                }
            }
        }

        return CommonHelper::responseSuccess("SMTP Mail Settings Saved Successfully!");
    }

    /**
     * Save third party API credentials
     */
    public function save_third_party_api_setting(Request $request)
    {
        $api_variables = ['google_place_api_key', 'google_map_api_key', 'apiKey', 'googleMapApiKey', 'text_gen_key'];

        foreach ($request->all() as $key => $value) {
            if (in_array($key, $api_variables)) {
                $value = $value ?? " ";

                // Note: google_place_api_key and google_map_api_key are already encrypted on the frontend
                // apiKey, googleMapApiKey, android_map_key, and ios_map_key are stored as original unencrypted values

                $setting = Setting::where('variable', $key)->first();

                if ($setting) {
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                } else {
                    $setting = new Setting();
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                }
            }
        }

        return CommonHelper::responseSuccess("Third Party API Settings Saved Successfully!");
    }

    /**
     * Save seller settings
     */
    public function save_seller_setting(Request $request)
    {
        $seller_variables = ['one_seller_cart', 'seller_commission', 'self_pickup_mode'];

        foreach ($request->all() as $key => $value) {
            if (in_array($key, $seller_variables)) {
                $value = $value ?? " ";
                $setting = Setting::where('variable', $key)->first();

                if ($setting) {
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                } else {
                    $setting = new Setting();
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                }
            }
        }

        return CommonHelper::responseSuccess("Seller Settings Saved Successfully!");
    }

    /**
     * Save cart settings
     */
    public function save_cart_setting(Request $request)
    {
        $cart_variables = [
            'cart_notification', 'notification_delay_after_cart_addition',
            'notification_interval', 'notification_stop_time'
        ];

        foreach ($request->all() as $key => $value) {
            if (in_array($key, $cart_variables)) {
                $value = $value ?? " ";
                $setting = Setting::where('variable', $key)->first();

                if ($setting) {
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                } else {
                    $setting = new Setting();
                    $setting->variable = $key;
                    $setting->value = $value;
                    $setting->save();
                }
            }
        }

        return CommonHelper::responseSuccess("Cart Settings Saved Successfully!");
    }

    public function get_additional_charges()
    {
        $setting = Setting::where('variable', 'additional_charges')->first();
        $charges = $setting ? json_decode($setting->value, true) : [];
        return CommonHelper::responseWithData($charges);
    }

    public function save_additional_charges(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'additional_charges' => 'required|json',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $setting = Setting::where('variable', 'additional_charges')->first();
        if ($setting) {
            $setting->value = $request->additional_charges;
            $setting->save();
        } else {
            $setting = new Setting();
            $setting->variable = 'additional_charges';
            $setting->value = $request->additional_charges;
            $setting->save();
        }

        return CommonHelper::responseSuccess("Additional Charges Saved Successfully!");
    }

    public function getPurchaseCode(){
        $code = Setting::get_value('purchase_code')??'';

        return CommonHelper::responseWithData($code);
    }

    public function purchaseCode($code,$type=0){

        $domain = env('APP_URL');
        $path = 'https://validator.wrteam.in/egrocer_validator?purchase_code='.$code.'&domain_url='.$domain;
        $response = file_get_contents($path);
        $data = json_decode($response,true);

        $valid = false;
        if(isset($data['error']) && $data['error']==false){
            $valid = true;
        }

        $setting = Setting::where('variable', 'purchase_code')->first()??new Setting();
        $setting->variable = 'purchase_code';
        $setting->value = $valid?$code:'';
        $setting->save();

        if($type){
            return $valid;
        }else{
            return CommonHelper::responseWithData($response);
        }

    }
    public function getPurchaseCodeUpdater(){
        $code = Setting::get_value('purchase_code')??'';

        $domain = env('APP_URL');
        $path = 'https://validator.wrteam.in/egrocer_validator?purchase_code='.$code.'&domain_url='.$domain;
        $response = file_get_contents($path);
        $data = json_decode($response,true);

        $valid = false;
        if(isset($data['error']) && $data['error']==false){
            $valid = true;
        }
        if($code == 'direct_sale_from_wrteam'){
            $valid = true;
        }

        $setting = Setting::where('variable', 'purchase_code')->first()??new Setting();
        $setting->variable = 'purchase_code';
        $setting->value = $valid?$code:'';
        $setting->save();

        return $valid;
    }

    public function testMail(Request $request){

        $validator = Validator::make($request->all(),[
            'mailer' => 'required',
            'email' => 'required|email',
            'host' => 'required',
            'username' => 'required',
            'password' => 'required',
            'port' => 'required',
            'encryption' => 'required',
            'support_email' => 'required',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $config = [
            'driver' => $request->mailer,
            'host' => $request->host,
            'username' => $request->username,
            'password' => $request->password,
            'port' => $request->port,
            'encryption' => $request->encryption,
            'from'       => [
                'address' => $request->username,
                'name'    => $request->app_name,
            ]
        ];

        \Config::set('mail', $config);


       try {


            \Mail::send([],[], function ($message) use ($request) {
                $message->to($request->email)
                    ->subject('Testing Mail')
                    ->html('Email Test Successfully!');
                $message->from($request->username, $request->app_name);
            });

            return CommonHelper::responseSuccess("Test Mail Sent Successfully!");

         }catch (\Exception $e){
            dd($e->getMessage());
             return CommonHelper::responseError($e->getMessage());
         }

    }

    /**
     * Google Places Autocomplete API
     * Provides location suggestions based on user input
     */
    public function googlePlacesAutocomplete(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'input' => 'required|string|min:2',
            'language' => 'nullable|string|size:2',
            'types' => 'nullable|string',
            'components' => 'nullable|string',
            'sessiontoken' => 'nullable|string',
            'source' => 'required|string|in:app,web',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Track API call
        ApiCallTracking::incrementCallCount('google_places_autocomplete', $request->source);

        try {
            // Get Google Places API key from settings
            $apiKey = Setting::get_value('googleMapApiKey');

            if (empty($apiKey)) {
                return CommonHelper::responseError('Google Places API key not configured');
            }

            // Build the API URL
            $baseUrl = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
            $params = [
                'input' => $request->input,
                'key' => $apiKey,
                'language' => $request->language ?? 'en',
            ];

            // Add optional parameters
            if ($request->types) {
                $params['types'] = $request->types;
            }

            if ($request->components) {
                $params['components'] = $request->components;
            }

            if ($request->sessiontoken) {
                $params['sessiontoken'] = $request->sessiontoken;
            }

            // Make the request to Google Places API
            $url = $baseUrl . '?' . http_build_query($params);

            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $url);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($ch, CURLOPT_TIMEOUT, 30);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $curlError = curl_error($ch);
            curl_close($ch);

            if ($curlError) {
                return CommonHelper::responseError('Network error: ' . $curlError);
            }

            if ($httpCode !== 200) {
                return CommonHelper::responseError('Failed to fetch location suggestions');
            }

            $data = json_decode($response, true);

            if (json_last_error() !== JSON_ERROR_NONE) {
                return CommonHelper::responseError('Invalid response from Google Places API');
            }

            // Check if Google API returned an error
            if (isset($data['status']) && $data['status'] !== 'OK' && $data['status'] !== 'ZERO_RESULTS') {
                $errorMessage = $data['error_message'] ?? 'Google Places API error: ' . $data['status'];
                return CommonHelper::responseError($errorMessage);
            }

            // Format the response for frontend consumption
            $suggestions = [];
            if (isset($data['predictions']) && is_array($data['predictions'])) {
                foreach ($data['predictions'] as $prediction) {
                    // Extract main text and secondary text from structured_formatting
                    $mainText = '';
                    $secondaryText = '';
                    $mainTextMatches = [];
                    
                    if (isset($prediction['structured_formatting'])) {
                        $mainText = $prediction['structured_formatting']['main_text'] ?? '';
                        $secondaryText = $prediction['structured_formatting']['secondary_text'] ?? '';
                        
                        // Extract matches for main text
                        if (isset($prediction['structured_formatting']['main_text_matched_substrings'])) {
                            foreach ($prediction['structured_formatting']['main_text_matched_substrings'] as $match) {
                                $mainTextMatches[] = [
                                    'endOffset' => $match['offset'] + $match['length']
                                ];
                            }
                        }
                    }
                    
                    // Extract matches for full text
                    $textMatches = [];
                    if (isset($prediction['matched_substrings'])) {
                        foreach ($prediction['matched_substrings'] as $match) {
                            $textMatches[] = [
                                'endOffset' => $match['offset'] + $match['length']
                            ];
                        }
                    }
                    
                    $suggestions[] = [
                        'placePrediction' => [
                            'place' => 'places/' . ($prediction['place_id'] ?? ''),
                            'placeId' => $prediction['place_id'] ?? '',
                            'text' => [
                                'text' => $prediction['description'] ?? '',
                                'matches' => $textMatches
                            ],
                            'structuredFormat' => [
                                'mainText' => [
                                    'text' => $mainText,
                                    'matches' => $mainTextMatches
                                ],
                                'secondaryText' => [
                                    'text' => $secondaryText
                                ]
                            ],
                            'types' => $prediction['types'] ?? []
                        ]
                    ];
                }
            }

            return CommonHelper::responseWithData([
                'suggestions' => $suggestions,
                'status' => $data['status'] ?? 'OK'
            ]);

        } catch (\Exception $e) {
            Log::error('Google Places Autocomplete Error: ' . $e->getMessage());
            return CommonHelper::responseError('An error occurred while fetching location suggestions');
        }
    }

    /**
     * Google Places Details API
     * Get detailed information about a specific place
     */
    public function googlePlacesDetails(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'place_id' => 'required|string',
            'fields' => 'nullable|string',
            'language' => 'nullable|string|size:2',
            'sessiontoken' => 'nullable|string',
            'source' => 'required|string|in:app,web',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Track API call
        ApiCallTracking::incrementCallCount('google_places_details', $request->source);

        try {
            // Get Google Places API key from settings
            $apiKey = Setting::get_value('googleMapApiKey');

            if (empty($apiKey)) {
                return CommonHelper::responseError('Google Places API key not configured');
            }

            // Build the API URL with comprehensive fields
            $baseUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
            $params = [
                'place_id' => $request->place_id,
                'key' => $apiKey,
                'language' => $request->language ?? 'en',
                'fields' => $request->fields ?? 'name,place_id,types,formatted_address,address_components,geometry,photos,website,url,utc_offset,icon,icon_background_color,icon_mask_base_uri,price_level,rating,user_ratings_total,reviews,opening_hours,business_status,formatted_phone_number,international_phone_number,editorial_summary'
            ];

            // Add optional parameters
            if ($request->sessiontoken) {
                $params['sessiontoken'] = $request->sessiontoken;
            }

            // Make the request to Google Places API
            $url = $baseUrl . '?' . http_build_query($params);
            
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $url);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($ch, CURLOPT_TIMEOUT, 30);
            
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode !== 200) {
                return CommonHelper::responseError('Failed to fetch place details');
            }

            $data = json_decode($response, true);

            if (json_last_error() !== JSON_ERROR_NONE) {
                return CommonHelper::responseError('Invalid response from Google Places API');
            }

            // Check if Google API returned an error
            if (isset($data['status']) && $data['status'] !== 'OK') {
                $errorMessage = $data['error_message'] ?? 'Google Places API error: ' . $data['status'];
                return CommonHelper::responseError($errorMessage);
            }

            // Transform the response to match the desired format
            $result = $data['result'] ?? [];
            
            $formattedResponse = [
                'name' => 'places/' . ($result['place_id'] ?? ''),
                'id' => $result['place_id'] ?? '',
                'types' => $result['types'] ?? [],
                'formattedAddress' => $result['formatted_address'] ?? '',
                'addressComponents' => [],
                'location' => [
                    'latitude' => $result['geometry']['location']['lat'] ?? 0,
                    'longitude' => $result['geometry']['location']['lng'] ?? 0
                ],
                'viewport' => [
                    'low' => [
                        'latitude' => $result['geometry']['viewport']['southwest']['lat'] ?? 0,
                        'longitude' => $result['geometry']['viewport']['southwest']['lng'] ?? 0
                    ],
                    'high' => [
                        'latitude' => $result['geometry']['viewport']['northeast']['lat'] ?? 0,
                        'longitude' => $result['geometry']['viewport']['northeast']['lng'] ?? 0
                    ]
                ],
                'googleMapsUri' => $result['url'] ?? '',
                'websiteUri' => $result['website'] ?? '',
                'utcOffsetMinutes' => $result['utc_offset'] ?? 0,
                'adrFormatAddress' => $this->generateAdrFormatAddress($result['address_components'] ?? []),
                'iconMaskBaseUri' => $result['icon_mask_base_uri'] ?? '',
                'iconBackgroundColor' => $result['icon_background_color'] ?? '',
                'displayName' => [
                    'text' => $result['name'] ?? '',
                    'languageCode' => $request->language ?? 'en'
                ],
                'shortFormattedAddress' => $this->getShortFormattedAddress($result['address_components'] ?? []),
                'photos' => [],
                'pureServiceAreaBusiness' => false,
                'googleMapsLinks' => [
                    'directionsUri' => $result['url'] ?? '',
                    'placeUri' => $result['url'] ?? '',
                    'photosUri' => $result['url'] ?? ''
                ],
                // 'timeZone' => [
                //     'id' => $this->getTimeZoneId($result['geometry']['location']['lat'] ?? 0, $result['geometry']['location']['lng'] ?? 0)
                // ]
            ];

            // Process address components
            if (isset($result['address_components']) && is_array($result['address_components'])) {
                foreach ($result['address_components'] as $component) {
                    $formattedResponse['addressComponents'][] = [
                        'longText' => $component['long_name'] ?? '',
                        'shortText' => $component['short_name'] ?? '',
                        'types' => $component['types'] ?? [],
                        'languageCode' => $request->language ?? 'en'
                    ];
                }
            }

            // Process photos
            if (isset($result['photos']) && is_array($result['photos'])) {
                foreach ($result['photos'] as $photo) {
                    $formattedResponse['photos'][] = [
                        'name' => 'places/' . ($result['place_id'] ?? '') . '/photos/' . ($photo['photo_reference'] ?? ''),
                        'widthPx' => $photo['width'] ?? 0,
                        'heightPx' => $photo['height'] ?? 0,
                        'authorAttributions' => [
                            [
                                'displayName' => $photo['html_attributions'][0] ?? 'Unknown',
                                'uri' => '',
                                'photoUri' => ''
                            ]
                        ],
                        'flagContentUri' => '',
                        'googleMapsUri' => ''
                    ];
                }
            }

            return CommonHelper::responseWithData($formattedResponse);

        } catch (\Exception $e) {
            Log::error('Google Places Details Error: ' . $e->getMessage());
            return CommonHelper::responseError('An error occurred while fetching place details');
        }
    }

    /**
     * Generate ADR format address from address components
     */
    private function generateAdrFormatAddress($addressComponents)
    {
        $adrParts = [];
        
        foreach ($addressComponents as $component) {
            $types = $component['types'] ?? [];
            $longName = $component['long_name'] ?? '';
            
            if (in_array('locality', $types)) {
                $adrParts[] = '<span class="locality">' . $longName . '</span>';
            } elseif (in_array('administrative_area_level_1', $types)) {
                $adrParts[] = '<span class="region">' . $longName . '</span>';
            } elseif (in_array('country', $types)) {
                $adrParts[] = '<span class="country-name">' . $longName . '</span>';
            }
        }
        
        return implode(', ', $adrParts);
    }

    /**
     * Get short formatted address (usually just the locality)
     */
    private function getShortFormattedAddress($addressComponents)
    {
        foreach ($addressComponents as $component) {
            $types = $component['types'] ?? [];
            if (in_array('locality', $types)) {
                return $component['long_name'] ?? '';
            }
        }
        return '';
    }

    /**
     * Get timezone ID based on coordinates
     */
    // private function getTimeZoneId($latitude, $longitude)
    // {
    //     // This is a simplified timezone detection
    //     // In a real implementation, you might want to use a timezone API
    //     // For now, returning a default timezone
    //     return 'Asia/Calcutta';
    // }

    /**
     * Google Maps Geocoding API
     * Convert coordinates to address with fixed radius of 500
     */
    public function googleMapsGeocoding(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'source' => 'required|string|in:app,web',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Track API call
        ApiCallTracking::incrementCallCount('google_maps_geocoding', $request->source);

        try {
            // Get Google Places API key from settings
            $apiKey = Setting::get_value('googleMapApiKey');

            if (empty($apiKey)) {
                return CommonHelper::responseError('Google Maps API key not configured');
            }

            // Build the API URL with fixed radius of 500
            $baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
            $params = [
                'key' => $apiKey,
                'latlng' => $request->latitude . ',' . $request->longitude,
                'radius' => 500,
            ];

            // Make the request to Google Maps Geocoding API
            $url = $baseUrl . '?' . http_build_query($params);
            
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $url);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($ch, CURLOPT_TIMEOUT, 30);
            curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
            curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (compatible; eGrocer/1.0)');
            
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $curlError = curl_error($ch);
            $curlInfo = curl_getinfo($ch);
            curl_close($ch);

            if ($curlError) {
                return CommonHelper::responseError('Network error: ' . $curlError);
            }

            if ($httpCode !== 200) {
                return CommonHelper::responseError('Failed to fetch geocoding data. HTTP Code: ' . $httpCode);
            }

            if (empty($response)) {
                return CommonHelper::responseError('Empty response from Google Maps API');
            }

            $data = json_decode($response, true);

            if (json_last_error() !== JSON_ERROR_NONE) {
                return CommonHelper::responseError('Invalid response from Google Maps Geocoding API: ' . json_last_error_msg());
            }

            // Check if Google API returned an error
            if (isset($data['status']) && $data['status'] !== 'OK' && $data['status'] !== 'ZERO_RESULTS') {
                $errorMessage = $data['error_message'] ?? 'Google Maps Geocoding API error: ' . $data['status'];
                return CommonHelper::responseError($errorMessage);
            }

            // Format the response for better consumption
            $formattedResults = [];
            if (isset($data['results']) && is_array($data['results'])) {
                foreach ($data['results'] as $result) {
                    $formattedResults[] = [
                        'formatted_address' => $result['formatted_address'] ?? '',
                        'geometry' => $result['geometry'] ?? [],
                        'place_id' => $result['place_id'] ?? '',
                        'types' => $result['types'] ?? [],
                        'address_components' => $result['address_components'] ?? [],
                        'partial_match' => $result['partial_match'] ?? false,
                    ];
                }
            }

            return CommonHelper::responseWithData([
                'results' => $formattedResults,
                'status' => $data['status'] ?? 'OK',
                'radius' => 500
            ]);

        } catch (\Exception $e) {
            Log::error('Google Maps Geocoding Error: ' . $e->getMessage());
            return CommonHelper::responseError('An error occurred while processing geocoding request: ' . $e->getMessage());
        }
    }

    /**
     * Google Gemini AI API
     * Generate content using Google's Gemini AI model
     */
    public function googleGeminiAI(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'prompt' => 'required|string|min:1|max:10000',
            'source' => 'required|string|in:app,web',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Track API call
        ApiCallTracking::incrementCallCount('google_gemini', $request->source);

        try {
            // Get Google Gemini API key from settings
            $apiKey = Setting::get_value('text_gen_key');
            
            if (empty($apiKey)) {
                return CommonHelper::responseError('Google Gemini API key not configured');
            }

            // Build the API URL
            $baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
            $url = $baseUrl . '?key=' . $apiKey;

            // Prepare the request payload - simplified format
            $payload = [
                'contents' => [
                    [
                        'parts' => [
                            [
                                'text' => $request->prompt
                            ]
                        ]
                    ]
                ]
            ];

            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $url);
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($ch, CURLOPT_TIMEOUT, 60);
            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                'Content-Type: application/json',
                'Accept: application/json'
            ]);
            
            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $curlError = curl_error($ch);
            curl_close($ch);
            // Log::info($response);
            if ($curlError) {
                return CommonHelper::responseError('Network error: ' . $curlError);
            }

            if ($httpCode !== 200) {
                return CommonHelper::responseError('Failed to generate content. HTTP Code: ' . $httpCode);
            }

            if (empty($response)) {
                return CommonHelper::responseError('Empty response from Google Gemini API');
            }

            $data = json_decode($response, true);

            if (json_last_error() !== JSON_ERROR_NONE) {
                return CommonHelper::responseError('Invalid response from Google Gemini API: ' . json_last_error_msg());
            }

            // Check if Gemini API returned an error
            if (isset($data['error'])) {
                $errorMessage = $data['error']['message'] ?? 'Google Gemini API error';
                return CommonHelper::responseError('Gemini API Error: ' . $errorMessage);
            }

            // Extract only the generated content - simplified response
            $generatedContent = '';
            if (isset($data['candidates'][0]['content']['parts'][0]['text'])) {
                $generatedContent = $data['candidates'][0]['content']['parts'][0]['text'];
            } else {
                return CommonHelper::responseError('No content generated by Gemini AI');
            }

            // Return only the essential data
            return CommonHelper::responseWithData($generatedContent);

        } catch (\Exception $e) {
            Log::error('Google Gemini AI Error: ' . $e->getMessage());
            return CommonHelper::responseError('An error occurred while generating content: ' . $e->getMessage());
        }
    }
}
