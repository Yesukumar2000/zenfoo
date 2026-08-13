<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Helpers\Paytm;
use App\Models\Setting;
use App\Models\PaytmTransaction;
use Illuminate\Support\Facades\Http;

class TestPaytmRefundApi extends Command
{
    protected $signature = 'paytm:test-refund {--order_id= : Test with a real order ID}';
    protected $description = 'Diagnose whether Paytm Refund API is enabled on live vs test merchant account';

    public function handle()
    {
        $this->info('');
        $this->info('============================================================');
        $this->info('   PAYTM REFUND API DIAGNOSTIC TEST');
        $this->info('============================================================');
        $this->info('');

        // ─── TEST 1: Live credentials - Transaction Status API ───
        $this->testEnvironment('live', [
            'merchant_id' => Setting::get_value('paytm_live_merchant_id') ?: Setting::get_value('paytm_merchant_id'),
            'merchant_key' => Setting::get_value('paytm_live_merchant_key') ?: Setting::get_value('paytm_merchant_key'),
            'url' => 'https://secure.paytmpayments.com/',
        ]);

        $this->info('');
        $this->info('------------------------------------------------------------');
        $this->info('');

        // ─── TEST 2: Test credentials ───
        $this->testEnvironment('test', [
            'merchant_id' => Setting::get_value('paytm_test_merchant_id'),
            'merchant_key' => Setting::get_value('paytm_test_merchant_key'),
            'url' => 'https://securestage.paytmpayments.com/',
        ]);

        $this->info('');
        $this->info('============================================================');
        $this->info('   FINAL VERDICT');
        $this->info('============================================================');
        $this->info('');
        $this->line('Compare the error codes above:');
        $this->line('');
        $this->line('  FAKE order refund on LIVE  => Error code: ???');
        $this->line('  FAKE order refund on TEST  => Error code: ???');
        $this->line('');
        $this->line('If LIVE returns 600 for FAKE order but TEST returns');
        $this->line('a different code (like 334/327/INVALID_ORDER):');
        $this->warn('  => Refund API is NOT ENABLED on your live account.');
        $this->warn('  => Contact Paytm support to enable it.');
        $this->line('');
        $this->line('If BOTH return the same error code for FAKE order:');
        $this->info('  => Refund API IS enabled. Issue is with UPI/bank.');
        $this->line('');

        return 0;
    }

    private function testEnvironment(string $env, array $credentials): void
    {
        $label = strtoupper($env);
        $this->info("[ {$label} ENVIRONMENT ]");
        $this->info('');

        if (empty($credentials['merchant_id']) || empty($credentials['merchant_key'])) {
            $this->error("  {$label} credentials not found in settings. Skipping.");
            return;
        }

        $this->line("  Merchant ID:  {$credentials['merchant_id']}");
        $this->line("  Merchant Key: " . substr($credentials['merchant_key'], 0, 4) . '****' . substr($credentials['merchant_key'], -4));
        $this->line("  API URL:      {$credentials['url']}");
        $this->info('');

        // ─── Sub-test A: Transaction Status API with a FAKE order ───
        $this->info("  [A] Testing Transaction Status API (verify credentials work)...");
        $fakeOrderId = 'DIAG_TEST_' . time() . '_' . rand(1000, 9999);
        $statusResult = $this->callTransactionStatus($credentials, $fakeOrderId);
        $this->line("      Order ID (fake): {$fakeOrderId}");
        $this->line("      HTTP Status:     {$statusResult['http_code']}");
        $this->line("      Result Status:   {$statusResult['result_status']}");
        $this->line("      Result Code:     {$statusResult['result_code']}");
        $this->line("      Result Msg:      {$statusResult['result_msg']}");

        if ($statusResult['http_code'] === 200) {
            $this->info("      => API is reachable. Credentials accepted by Paytm.");
        } else {
            $this->error("      => API call failed. Credentials may be wrong.");
        }
        $this->info('');

        // ─── Sub-test B: If real order provided and env is live, check real transaction ───
        $realOrderId = $this->option('order_id');
        if ($realOrderId && $env === 'live') {
            $paytmTxn = PaytmTransaction::where('order_id', $realOrderId)
                ->orderBy('id', 'desc')
                ->first();

            if ($paytmTxn) {
                $this->info("  [B] Verifying REAL transaction (Order #{$realOrderId}) on Paytm...");
                $realStatus = $this->callTransactionStatus($credentials, $paytmTxn->txn_id);
                $this->line("      Paytm Order ID:  {$paytmTxn->txn_id}");
                $this->line("      Paytm Txn ID:    {$paytmTxn->paytm_txn_id}");
                $this->line("      Payment Mode:    {$paytmTxn->payment_mode}");
                $this->line("      Bank:            " . ($paytmTxn->bank_name ?: 'N/A'));
                $this->line("      Gateway:         " . ($paytmTxn->gateway_name ?: 'N/A'));
                $this->line("      Amount:          {$paytmTxn->amount}");
                $this->line("      Txn Status:      {$realStatus['result_status']}");
                $this->line("      refundAmt:       " . ($realStatus['refund_amt'] ?? 'N/A'));
                $this->info('');

                // ─── Sub-test C: Attempt refund on REAL transaction ───
                $this->info("  [C] Attempting REFUND on REAL transaction (Order #{$realOrderId})...");
                $realRefund = $this->callRefundApi(
                    $credentials,
                    $paytmTxn->txn_id,
                    $paytmTxn->paytm_txn_id,
                    $paytmTxn->amount
                );
                $this->printRefundResult($realRefund, "REAL order refund on {$label}");
                $this->info('');
            } else {
                $this->warn("  [B] No paytm_transactions record found for order #{$realOrderId}. Skipping real txn test.");
                $this->info('');
            }
        }

        // ─── Sub-test D: Attempt refund with FAKE order (THE KEY DIAGNOSTIC TEST) ───
        $this->info("  [D] Attempting REFUND with FAKE order (KEY DIAGNOSTIC TEST)...");
        $this->line("      This tells us if the Refund API endpoint is enabled at all.");
        $this->line("      If enabled: Paytm returns 'Order not found' type error (334/327).");
        $this->line("      If NOT enabled: Paytm returns error 600 or access denied.");
        $this->info('');

        $fakeRefund = $this->callRefundApi(
            $credentials,
            'FAKE_ORDER_DIAG_' . time(),
            'FAKE_TXN_DIAG_' . time(),
            1.00
        );
        $this->printRefundResult($fakeRefund, "FAKE order refund on {$label}");
    }

    private function callTransactionStatus(array $credentials, string $orderId): array
    {
        try {
            $paytmParams = [
                "body" => [
                    "mid" => $credentials['merchant_id'],
                    "orderId" => $orderId,
                ],
            ];

            $checksum = Paytm::generateSignature(
                json_encode($paytmParams["body"], JSON_UNESCAPED_SLASHES),
                $credentials['merchant_key']
            );

            $paytmParams["head"] = ["signature" => $checksum];

            $url = $credentials['url'] . "v3/order/status";

            $response = Http::withHeaders(['Content-Type' => 'application/json'])
                ->timeout(30)
                ->post($url, $paytmParams);

            $data = $response->json();

            return [
                'http_code' => $response->status(),
                'result_status' => $data['body']['resultInfo']['resultStatus'] ?? 'N/A',
                'result_code' => $data['body']['resultInfo']['resultCode'] ?? 'N/A',
                'result_msg' => $data['body']['resultInfo']['resultMsg'] ?? 'N/A',
                'refund_amt' => $data['body']['refundAmt'] ?? null,
                'raw' => $data,
            ];
        } catch (\Exception $e) {
            return [
                'http_code' => 0,
                'result_status' => 'EXCEPTION',
                'result_code' => 'EXCEPTION',
                'result_msg' => $e->getMessage(),
                'refund_amt' => null,
                'raw' => null,
            ];
        }
    }

    private function callRefundApi(array $credentials, string $orderId, string $txnId, float $amount): array
    {
        try {
            $refundId = 'DIAG_REFUND_' . time() . '_' . rand(1000, 9999);

            $paytmParams = [
                "body" => [
                    "mid" => $credentials['merchant_id'],
                    "txnType" => "REFUND",
                    "orderId" => $orderId,
                    "txnId" => $txnId,
                    "refundAmount" => number_format($amount, 2, '.', ''),
                    "refId" => $refundId,
                ],
            ];

            $checksum = Paytm::generateSignature(
                json_encode($paytmParams["body"], JSON_UNESCAPED_SLASHES),
                $credentials['merchant_key']
            );

            $paytmParams["head"] = ["signature" => $checksum];

            $url = $credentials['url'] . "refund/apply";

            $response = Http::withHeaders(['Content-Type' => 'application/json'])
                ->timeout(30)
                ->post($url, $paytmParams);

            $data = $response->json();

            return [
                'http_code' => $response->status(),
                'result_status' => $data['body']['resultInfo']['resultStatus'] ?? 'N/A',
                'result_code' => $data['body']['resultInfo']['resultCode'] ?? 'N/A',
                'result_msg' => $data['body']['resultInfo']['resultMsg'] ?? 'N/A',
                'refund_id' => $refundId,
                'request_sent' => $paytmParams['body'],
                'raw' => $data,
            ];
        } catch (\Exception $e) {
            return [
                'http_code' => 0,
                'result_status' => 'EXCEPTION',
                'result_code' => 'EXCEPTION',
                'result_msg' => $e->getMessage(),
                'refund_id' => null,
                'request_sent' => null,
                'raw' => null,
            ];
        }
    }

    private function printRefundResult(array $result, string $label): void
    {
        $this->line("      Result Status:   {$result['result_status']}");
        $this->line("      Result Code:     {$result['result_code']}");
        $this->line("      Result Msg:      {$result['result_msg']}");
        $this->line("      HTTP Status:     {$result['http_code']}");

        $code = $result['result_code'];

        // Interpret the result
        if ($code === '10' || $result['result_status'] === 'TXN_SUCCESS' || $result['result_status'] === 'PENDING') {
            $this->info("      => REFUND API IS ENABLED and refund was SUCCESSFUL!");
        } elseif ($code === '600') {
            $this->error("      => ERROR 600: \"Invalid refund request or restricted by bank\"");
            $this->error("      => {$label}: REFUND API MAY NOT BE ENABLED");
        } elseif (in_array($code, ['334', '327', '330', '501'])) {
            $this->info("      => REFUND API IS ENABLED (got expected error for invalid order: {$code})");
        } else {
            $this->warn("      => Unexpected error code: {$code}. Check raw response.");
        }

        $this->line("      -------");
    }
}
