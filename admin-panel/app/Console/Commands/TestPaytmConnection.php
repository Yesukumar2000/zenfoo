<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Helpers\Paytm;
use App\Models\Setting;

class TestPaytmConnection extends Command
{
    protected $signature = 'paytm:test';
    protected $description = 'Test Paytm API connection and credentials';

    public function handle()
    {
        $this->info('=== PAYTM CONNECTION TEST ===');
        $this->newLine();

        try {
            // Get credentials
            $credentials = Paytm::get_credentials();

            $this->info('📋 Current Configuration:');
            $this->line('Environment: ' . $credentials['paytm_payment_mode']);
            $this->line('Merchant ID: ' . $credentials['paytm_merchant_id']);
            $this->line('Merchant Key: ' . substr($credentials['paytm_merchant_key'], 0, 4) . '...' . substr($credentials['paytm_merchant_key'], -4));
            $this->line('Website: ' . $credentials['paytm_website']);
            $this->line('API URL: ' . $credentials['url']);
            $this->newLine();

            // Generate test transaction
            $orderId = 'TEST_' . time() . '_' . rand(1000, 9999);
            $amount = '10.00';

            $this->info('🔄 Testing Transaction Token Generation...');
            $this->line('Test Order ID: ' . $orderId);
            $this->line('Test Amount: ₹' . $amount);
            $this->newLine();

            // Prepare Paytm params
            $paytmParams = [
                "body" => [
                    "requestType" => "Payment",
                    "mid" => $credentials['paytm_merchant_id'],
                    "websiteName" => $credentials['paytm_website'],
                    "orderId" => $orderId,
                    "callbackUrl" => $credentials['url'] . "theia/paytmCallback?ORDER_ID=" . $orderId,
                    "txnAmount" => [
                        "value" => $amount,
                        "currency" => "INR",
                    ],
                    "userInfo" => [
                        "custId" => "TEST_CUSTOMER",
                    ],
                ]
            ];

            // Generate checksum
            $checksum = Paytm::generateSignature(
                json_encode($paytmParams["body"], JSON_UNESCAPED_SLASHES),
                $credentials['paytm_merchant_key']
            );

            $paytmParams["head"] = ["signature" => $checksum];

            // Build URL
            $url = $credentials['url'] . "theia/api/v1/initiateTransaction?mid=" . $credentials['paytm_merchant_id'] . "&orderId=" . $orderId;

            $this->line('API Endpoint: ' . $url);
            $this->newLine();

            // Make API call
            $this->info('📡 Calling Paytm API...');

            $ch = curl_init($url);
            curl_setopt($ch, CURLOPT_POST, 1);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($paytmParams, JSON_UNESCAPED_SLASHES));
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_HTTPHEADER, ["Content-Type: application/json"]);
            curl_setopt($ch, CURLOPT_TIMEOUT, 30);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            $curlError = curl_error($ch);
            curl_close($ch);

            $this->newLine();
            $this->line('HTTP Status Code: ' . $httpCode);

            if ($curlError) {
                $this->error('❌ CURL Error: ' . $curlError);
                return 1;
            }

            $this->newLine();
            $this->info('📥 Response:');
            $this->line($response);
            $this->newLine();

            // Parse response
            $decoded = json_decode($response, true);

            if (!$decoded) {
                $this->error('❌ Invalid JSON response from Paytm');
                return 1;
            }

            $resultStatus = $decoded['body']['resultInfo']['resultStatus'] ?? 'N/A';
            $resultCode = $decoded['body']['resultInfo']['resultCode'] ?? 'N/A';
            $resultMsg = $decoded['body']['resultInfo']['resultMsg'] ?? 'N/A';

            $this->info('📊 Result Details:');
            $this->line('Status: ' . $resultStatus);
            $this->line('Code: ' . $resultCode);
            $this->line('Message: ' . $resultMsg);
            $this->newLine();

            // Interpret results
            if (isset($decoded['body']['txnToken'])) {
                $this->info('✅ SUCCESS! Paytm test merchant is ACTIVATED!');
                $this->line('Transaction Token: ' . substr($decoded['body']['txnToken'], 0, 20) . '...');
                $this->newLine();
                $this->info('🎉 Your Paytm integration is ready to use!');
                return 0;
            } else {
                $this->newLine();
                $this->error('❌ FAILED! Merchant not activated or credentials incorrect.');
                $this->newLine();

                // Provide specific guidance based on error code
                switch ($resultCode) {
                    case '501':
                        $this->warn('Error 501: System Error');
                        $this->line('This typically means:');
                        $this->line('1. Test merchant account is NOT activated by Paytm');
                        $this->line('2. API access not enabled for your merchant');
                        $this->newLine();
                        $this->info('Action Required:');
                        $this->line('Contact Paytm support at: paytm-business-support@paytm.com');
                        $this->line('Or enable mock mode: php artisan tinker');
                        $this->line('Then run: Setting::updateOrCreate([\'variable\' => \'paytm_mock_mode\'], [\'value\' => \'1\'])');
                        break;

                    case '331':
                        $this->warn('Error 331: Invalid Checksum');
                        $this->line('Good news: Merchant IS activated!');
                        $this->line('Issue: Merchant key is incorrect');
                        $this->newLine();
                        $this->info('Action Required:');
                        $this->line('Verify merchant key in Paytm dashboard matches your database');
                        break;

                    case '400':
                        $this->warn('Error 400: Bad Request');
                        $this->line('Good news: Merchant IS activated!');
                        $this->line('Issue: Request format or parameters incorrect');
                        break;

                    case '141':
                        $this->warn('Error 141: Invalid Merchant ID');
                        $this->line('Issue: Merchant ID is incorrect');
                        $this->newLine();
                        $this->info('Action Required:');
                        $this->line('Verify merchant ID in Paytm dashboard matches your database');
                        break;

                    default:
                        $this->warn('Unknown error code: ' . $resultCode);
                        $this->line('Message: ' . $resultMsg);
                }

                return 1;
            }

        } catch (\Exception $e) {
            $this->error('❌ Exception occurred: ' . $e->getMessage());
            $this->line('File: ' . $e->getFile());
            $this->line('Line: ' . $e->getLine());
            return 1;
        }
    }
}