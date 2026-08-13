<?php

namespace App\Helpers;

use Illuminate\Support\Facades\Http;

class SmsHelper
{
    public static function sendSms($mobile, $message)
    {
        $apiKey = "0WYHx6cJMQrmkLlC1AyKsz8dfo9uT7wSFE3PVbXIBZ5etvRjpnZq7pWMvlh4xRrLD81njPbdOuoVE26T";

        $url = 'https://www.fast2sms.com/dev/bulkV2?' . http_build_query([
                'authorization' => $apiKey,  // MUST be in URL for GET
                'route' => 'dlt',
                'sender_id' => 'TCSTLL',
                'message' => 201510,
                'variables_values' => $message,
                'numbers' => $mobile,
            ]);

            $response = Http::get($url);

        // Check response
        $data = $response->json();
        \Log::info('Fast2SMS GET Response:', $data);

        return $data;

    }
}
