<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'stripe' => [
        'model'  => 'App\Models\User',
        'key'    => env('STRIPE_API_PUBLIC'),
        'secret' => env('STRIPE_API_SECRET'),
    ],

    'fast2sms' => [
        'api_key' => env('FAST2SMS_API_KEY'),
        'sender_id' => env('FAST2SMS_SENDER_ID'),
        'message_id' => env('FAST2SMS_MESSAGE_ID'),
        'delivery_boy_message_id' => env('FAST2SMS_DELIVERY_BOY_MESSAGE_ID'),
        'customer_message_id' => env('FAST2SMS_CUSTOMER_MESSAGE_ID'),
    ],

    'phonepe' => [
        'merchant_id' => env('PHONEPE_MERCHANT_ID', 'M23TSU3JHDUZ0'),
        'client_id' => env('PHONEPE_CLIENT_ID', 'M23TSU3JHDUZ0_2601211145'),
        'client_secret' => env('PHONEPE_CLIENT_SECRET', 'MTIyNTBkNTMtNTY3MC00ZWJmLWFjMTYtY2E5ZmNjNTliOWYw'),
        'is_production' => env('PHONEPE_IS_PRODUCTION', false),
        // Mock mode for local development - simulates payouts without calling PhonePe API
        // Defaults to true when not in production
        'mock_mode' => env('PHONEPE_MOCK_MODE', null),
    ],

    // RazorpayX Payout Configuration
    'razorpayx' => [
        'key_id' => env('RAZORPAYX_KEY_ID'),
        'key_secret' => env('RAZORPAYX_KEY_SECRET'),
        'account_number' => env('RAZORPAYX_ACCOUNT_NUMBER'),
        'is_production' => env('RAZORPAYX_IS_PRODUCTION', false),
        'mock_mode' => env('RAZORPAYX_MOCK_MODE', true),
    ],

];
