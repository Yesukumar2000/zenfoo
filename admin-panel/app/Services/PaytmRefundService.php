<?php

namespace App\Services;

use App\Helpers\Paytm;
use App\Models\Setting;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PaytmRefundService
{
    private $merchantId;
    private $merchantKey;
    private $environment;
    private $apiBaseUrl;
    private $mockMode;

    public function __construct()
    {
        $credentials = Paytm::get_credentials();

        $this->merchantId = $credentials['paytm_merchant_id'];
        $this->merchantKey = $credentials['paytm_merchant_key'];
        $this->environment = $credentials['paytm_payment_mode'];
        $this->apiBaseUrl = $credentials['url'];
        $this->mockMode = Setting::get_value('paytm_refund_mock_mode') ?? false;

        Log::info('PaytmRefundService initialized', [
            'environment' => $this->environment,
            'api_url' => $this->apiBaseUrl,
            'merchant_id' => $this->merchantId,
            'merchant_key_present' => !empty($this->merchantKey),
            'merchant_key_length' => strlen($this->merchantKey ?? ''),
            'mock_mode' => $this->mockMode,
        ]);
    }

    /**
     * Initiate refund for a Paytm transaction
     */
    public function initiateRefund(string $originalTransactionId, float $amount, int $orderId, string $paytmOrderId = null): array
    {
        $requestId = uniqid('paytm_refund_', true);

        try {
            Log::info('=== PAYTM REFUND START ===', [
                'request_id' => $requestId,
                'order_id' => $orderId,
                'original_transaction_id' => $originalTransactionId,
                'paytm_order_id_provided' => $paytmOrderId,
                'refund_amount' => $amount,
                'environment' => $this->environment,
                'merchant_id' => $this->merchantId,
                'api_base_url' => $this->apiBaseUrl,
                'mock_mode' => $this->mockMode,
            ]);

            // Validate inputs
            if (empty($originalTransactionId)) {
                Log::error('Paytm Refund: VALIDATION FAILED - Empty transaction ID', [
                    'request_id' => $requestId,
                    'order_id' => $orderId,
                ]);
                return ['success' => false, 'error' => 'Invalid transaction ID provided'];
            }

            if ($amount <= 0) {
                Log::error('Paytm Refund: VALIDATION FAILED - Invalid refund amount', [
                    'request_id' => $requestId,
                    'order_id' => $orderId,
                    'amount' => $amount,
                ]);
                return ['success' => false, 'error' => 'Refund amount must be greater than zero'];
            }

            $refundId = 'REFUND_' . $orderId . '_' . time() . '_' . rand(1000, 9999);

            if ($this->mockMode) {
                Log::info('=== PAYTM REFUND: MOCK MODE ===', [
                    'request_id' => $requestId,
                    'order_id' => $orderId,
                    'refund_id' => $refundId,
                    'amount' => $amount,
                ]);
                return [
                    'success' => true,
                    'refund_transaction_id' => $refundId,
                    'message' => 'Refund initiated successfully (Mock Mode)',
                    'data' => [
                        'orderId' => $originalTransactionId,
                        'refundId' => $refundId,
                        'txnId' => $originalTransactionId,
                        'refundAmount' => $amount,
                        'resultStatus' => 'TXN_SUCCESS',
                        'resultCode' => '10',
                        'resultMsg' => 'Refund Successful (Mock)',
                        'txnType' => 'REFUND',
                    ],
                ];
            }

            // ─── PRE-REFUND: Verify original transaction with Paytm ───
            $orderIdForRefund = $paytmOrderId ?? $originalTransactionId;
            $txnVerification = $this->verifyOriginalTransaction($requestId, $orderId, $orderIdForRefund, $originalTransactionId, $amount);

            // Extract txnType from verification (mandatory parameter)
            $txnType = $txnVerification['txn_type'] ?? 'SALE';

            Log::info('Paytm Refund: txnType extracted from transaction status', [
                'request_id' => $requestId,
                'order_id' => $orderId,
                'txnType' => $txnType,
                'source' => $txnVerification['txn_type'] ? 'from_paytm_api' : 'default_fallback',
            ]);

            // ─── BUILD REFUND REQUEST ───
            $paytmParams = [
                "body" => [
                    "mid" => $this->merchantId,
                    "orderId" => $orderIdForRefund,
                    "refId" => $refundId,
                    "refundAmount" => (string) number_format($amount, 2, '.', ''),
                    "txnId" => $originalTransactionId,
                    "txnType" => $txnType,
                    "refundDestination" => "TO_SOURCE",
                ],
            ];

            $requestBodyJson = json_encode($paytmParams["body"], JSON_UNESCAPED_SLASHES);
            $checksum = Paytm::generateSignature($requestBodyJson, $this->merchantKey);
            $paytmParams["head"] = ["signature" => $checksum];

            $url = $this->apiBaseUrl . "refund/apply";

            Log::info('Paytm Refund: Sending refund request WITH txnType parameter', [
                'request_id' => $requestId,
                'order_id' => $orderId,
                'url' => $url,
                'refund_id' => $refundId,
                'request_body' => $paytmParams['body'],
                'body_json_for_checksum' => $requestBodyJson,
                'txnType_included' => isset($paytmParams['body']['txnType']),
                'txnType_value' => $paytmParams['body']['txnType'] ?? 'NOT_SET',
            ]);

            // ─── CALL PAYTM API ───
            $response = Http::withHeaders([
                'Content-Type' => 'application/json',
            ])->timeout(30)->post($url, $paytmParams);

            $responseData = $response->json();

            Log::info('Paytm Refund: Raw API response', [
                'request_id' => $requestId,
                'order_id' => $orderId,
                'http_status_code' => $response->status(),
                'raw_response_body' => $response->body(),
            ]);

            // ─── PROCESS RESPONSE ───
            $resultStatus = $responseData['body']['resultInfo']['resultStatus'] ?? null;
            $resultCode = $responseData['body']['resultInfo']['resultCode'] ?? null;
            $resultMsg = $responseData['body']['resultInfo']['resultMsg'] ?? null;

            if ($response->successful() && in_array($resultStatus, ['TXN_SUCCESS', 'PENDING'])) {
                Log::info('=== PAYTM REFUND SUCCESS ===', [
                    'request_id' => $requestId,
                    'order_id' => $orderId,
                    'refund_id' => $refundId,
                    'paytm_refund_id' => $responseData['body']['refundId'] ?? null,
                    'result_status' => $resultStatus,
                    'result_code' => $resultCode,
                    'result_msg' => $resultMsg,
                ]);

                return [
                    'success' => true,
                    'refund_transaction_id' => $responseData['body']['refundId'] ?? $refundId,
                    'internal_refund_id' => $refundId,  // Our internal refund ID (REFUND_xxx)
                    'message' => $resultMsg ?? 'Refund initiated successfully',
                    'status' => $resultStatus,
                    'data' => $responseData['body'] ?? null,
                ];
            }

            // ─── REFUND FAILED: Run full diagnostic ───
            $errorMessage = $resultMsg ?? 'Refund initiation failed';
            $errorCode = $resultCode ?? 'UNKNOWN_ERROR';
            $errorStatus = $resultStatus ?? 'FAILED';

            $this->logRefundFailureDiagnosis(
                $requestId, $orderId, $refundId, $url,
                $errorCode, $errorMessage, $errorStatus,
                $paytmParams['body'], $responseData,
                $txnVerification
            );

            return [
                'success' => false,
                'error' => $errorMessage,
                'code' => $errorCode,
                'status' => $errorStatus,
            ];

        } catch (\Exception $e) {
            Log::error('=== PAYTM REFUND EXCEPTION ===', [
                'request_id' => $requestId,
                'order_id' => $orderId,
                'original_transaction_id' => $originalTransactionId,
                'paytm_order_id' => $paytmOrderId,
                'environment' => $this->environment,
                'error_message' => $e->getMessage(),
                'error_file' => $e->getFile(),
                'error_line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
            ]);

            return ['success' => false, 'error' => 'Failed to initiate refund: ' . $e->getMessage()];
        }
    }

    /**
     * Verify original transaction with Paytm and run pre-refund checks.
     * Returns verification data for later diagnosis.
     */
    private function verifyOriginalTransaction(string $requestId, int $orderId, string $paytmOrderId, string $paytmTxnId, float $refundAmount): array
    {
        $result = [
            'api_reachable' => false,
            'txn_found' => false,
            'txn_status' => null,
            'txn_amount' => null,
            'refund_amt_on_paytm' => null,
            'payment_mode' => null,
            'bank_name' => null,
            'gateway_name' => null,
            'txn_date' => null,
            'txn_type' => null,
            'mid_matches' => false,
            'orderId_matches' => false,
            'txnId_matches' => false,
            'amount_within_limit' => false,
            'no_previous_refund' => false,
            'checks' => [],
        ];

        try {
            $statusResponse = Paytm::transaction_status($paytmOrderId);
            $statusData = json_decode($statusResponse, true);

            $body = $statusData['body'] ?? [];
            $resultInfo = $body['resultInfo'] ?? [];

            $result['api_reachable'] = true;
            $result['txn_status'] = $resultInfo['resultStatus'] ?? 'UNKNOWN';
            $result['txn_found'] = $result['txn_status'] === 'TXN_SUCCESS';
            $result['txn_amount'] = $body['txnAmount'] ?? null;
            $result['refund_amt_on_paytm'] = $body['refundAmt'] ?? null;
            $result['payment_mode'] = $body['paymentMode'] ?? null;
            $result['bank_name'] = $body['bankName'] ?? null;
            $result['gateway_name'] = $body['gatewayName'] ?? null;
            $result['txn_date'] = $body['txnDate'] ?? null;
            $result['txn_type'] = $body['txnType'] ?? null;
            $result['mid_matches'] = ($body['mid'] ?? '') === $this->merchantId;
            $result['orderId_matches'] = ($body['orderId'] ?? '') === $paytmOrderId;
            $result['txnId_matches'] = ($body['txnId'] ?? '') === $paytmTxnId;

            $paytmAmount = floatval($result['txn_amount'] ?? 0);
            $paytmRefunded = floatval($result['refund_amt_on_paytm'] ?? 0);
            $result['amount_within_limit'] = $refundAmount <= ($paytmAmount - $paytmRefunded);
            $result['no_previous_refund'] = $paytmRefunded == 0;

            // Build check results
            $result['checks'] = [
                'PAYTM_API_REACHABLE' => $result['api_reachable'] ? 'PASS' : 'FAIL',
                'TXN_FOUND_ON_PAYTM' => $result['txn_found'] ? 'PASS - TXN_SUCCESS' : 'FAIL - Status: ' . $result['txn_status'],
                'MID_MATCHES' => $result['mid_matches'] ? 'PASS' : 'FAIL - Paytm MID: ' . ($body['mid'] ?? 'N/A') . ', Our MID: ' . $this->merchantId,
                'ORDER_ID_MATCHES' => $result['orderId_matches'] ? 'PASS' : 'FAIL - Paytm orderId: ' . ($body['orderId'] ?? 'N/A') . ', Sent: ' . $paytmOrderId,
                'TXN_ID_MATCHES' => $result['txnId_matches'] ? 'PASS' : 'FAIL - Paytm txnId: ' . ($body['txnId'] ?? 'N/A') . ', Sent: ' . $paytmTxnId,
                'REFUND_AMOUNT_OK' => $result['amount_within_limit'] ? 'PASS - Refund: ' . $refundAmount . ', Txn: ' . $paytmAmount . ', Already refunded: ' . $paytmRefunded : 'FAIL - Refund: ' . $refundAmount . ' exceeds available: ' . ($paytmAmount - $paytmRefunded),
                'NO_PREVIOUS_REFUND' => $result['no_previous_refund'] ? 'PASS - refundAmt on Paytm: 0.0' : 'WARNING - Already refunded: ' . $paytmRefunded . ' on Paytm',
                'PAYMENT_MODE' => $result['payment_mode'] ?? 'UNKNOWN',
                'BANK_NAME' => $result['bank_name'] ?: 'NOT_PROVIDED_BY_PAYTM',
                'GATEWAY' => $result['gateway_name'] ?? 'UNKNOWN',
                'TXN_TYPE' => $result['txn_type'] ?? 'UNKNOWN',
                'TXN_DATE' => $result['txn_date'] ?? 'UNKNOWN',
                'ENVIRONMENT' => $this->environment,
            ];

            Log::info('=== PAYTM REFUND PRE-CHECK RESULTS ===', [
                'request_id' => $requestId,
                'order_id' => $orderId,
                'checks' => $result['checks'],
            ]);

        } catch (\Exception $e) {
            $result['checks'] = ['PAYTM_API_REACHABLE' => 'FAIL - ' . $e->getMessage()];
            Log::warning('Paytm Refund: Pre-check failed (non-blocking)', [
                'request_id' => $requestId,
                'order_id' => $orderId,
                'error' => $e->getMessage(),
            ]);
        }

        return $result;
    }

    /**
     * Log detailed failure diagnosis when refund fails.
     */
    private function logRefundFailureDiagnosis(
        string $requestId, int $orderId, string $refundId, string $url,
        string $errorCode, string $errorMessage, string $errorStatus,
        array $requestBody, ?array $responseData,
        array $txnVerification
    ): void {
        $checks = $txnVerification['checks'] ?? [];

        // Build elimination-style diagnosis
        $diagnosis = [];

        // Check 1: Was the transaction found on Paytm?
        if (!$txnVerification['txn_found']) {
            $diagnosis[] = 'LIKELY CAUSE: Original transaction not found or not successful on Paytm. Status: ' . ($txnVerification['txn_status'] ?? 'UNKNOWN');
        }

        // Check 2: MID mismatch?
        if (!$txnVerification['mid_matches'] && $txnVerification['api_reachable']) {
            $diagnosis[] = 'LIKELY CAUSE: Merchant ID mismatch between our config and Paytm record.';
        }

        // Check 3: Order ID mismatch?
        if (!$txnVerification['orderId_matches'] && $txnVerification['api_reachable']) {
            $diagnosis[] = 'LIKELY CAUSE: orderId sent in refund does not match Paytm record.';
        }

        // Check 4: Txn ID mismatch?
        if (!$txnVerification['txnId_matches'] && $txnVerification['api_reachable']) {
            $diagnosis[] = 'LIKELY CAUSE: txnId sent in refund does not match Paytm record.';
        }

        // Check 5: Amount exceeds?
        if (!$txnVerification['amount_within_limit'] && $txnVerification['api_reachable']) {
            $diagnosis[] = 'LIKELY CAUSE: Refund amount exceeds available balance (original amount minus already refunded).';
        }

        // Check 6: Already refunded?
        if (!$txnVerification['no_previous_refund'] && $txnVerification['api_reachable']) {
            $diagnosis[] = 'WARNING: Transaction has previous refund of ' . $txnVerification['refund_amt_on_paytm'] . '. Could be partially/fully refunded.';
        }

        // Check 7: If ALL checks passed but still failed...
        $allPassed = $txnVerification['txn_found']
            && $txnVerification['mid_matches']
            && $txnVerification['orderId_matches']
            && $txnVerification['txnId_matches']
            && $txnVerification['amount_within_limit']
            && $txnVerification['no_previous_refund'];

        if ($allPassed && $txnVerification['api_reachable']) {
            $paymentMode = $txnVerification['payment_mode'] ?? 'UNKNOWN';
            $gateway = $txnVerification['gateway_name'] ?? 'UNKNOWN';
            $bankName = $txnVerification['bank_name'] ?: 'NOT_PROVIDED';

            $diagnosis[] = 'ALL PRE-CHECKS PASSED — Transaction is valid, IDs match, amount is correct, no prior refund.';
            $diagnosis[] = 'REMAINING POSSIBLE CAUSES:';

            if (strtoupper($paymentMode) === 'UPI') {
                $diagnosis[] = "  1. [UPI BANK RESTRICTION] Payment was via UPI (gateway: {$gateway}, bank: {$bankName}). Some banks block automated UPI refunds via API. Try manual refund from Paytm dashboard.";
                $diagnosis[] = "  2. [MERCHANT CONFIG] Refund API may not be activated for this MID ({$this->merchantId}) on {$this->environment} environment. Contact Paytm support.";
                $diagnosis[] = "  3. [SETTLEMENT PENDING] Transaction may not be settled yet. UPI settlements can take up to 48 hours.";
            } else {
                $diagnosis[] = "  1. [MERCHANT CONFIG] Refund API may not be activated for this MID ({$this->merchantId}) on {$this->environment} environment. Contact Paytm support.";
                $diagnosis[] = "  2. [BANK RESTRICTION] Bank ({$bankName}) may have restricted refunds for payment mode: {$paymentMode}.";
                $diagnosis[] = "  3. [SETTLEMENT PENDING] Transaction may not be settled yet.";
            }

            $diagnosis[] = 'ACTION: Try manual refund from Paytm Business Dashboard. If manual refund also fails, issue is with bank. If manual works but API does not, issue is with merchant API config.';
        }

        Log::error('=== PAYTM REFUND FAILED ===', [
            'request_id' => $requestId,
            'order_id' => $orderId,
            'refund_id' => $refundId,
            'error_code' => $errorCode,
            'error_status' => $errorStatus,
            'error_message' => $errorMessage,
            'environment' => $this->environment,
            'merchant_id' => $this->merchantId,
            'refund_url' => $url,
            'request_sent' => $requestBody,
            'txnType_was_included' => isset($requestBody['txnType']),
            'txnType_value_sent' => $requestBody['txnType'] ?? 'NOT_INCLUDED',
            'all_parameters_sent' => array_keys($requestBody),
            'paytm_response' => $responseData,
        ]);

        Log::error('=== PAYTM REFUND DIAGNOSIS ===', [
            'request_id' => $requestId,
            'order_id' => $orderId,
            'error_code' => $errorCode,
            'pre_checks' => $checks,
            'diagnosis' => $diagnosis,
            'payment_mode' => $txnVerification['payment_mode'] ?? 'UNKNOWN',
            'gateway' => $txnVerification['gateway_name'] ?? 'UNKNOWN',
            'bank' => $txnVerification['bank_name'] ?: 'NOT_PROVIDED_BY_PAYTM',
            'txn_date' => $txnVerification['txn_date'] ?? 'UNKNOWN',
            'txn_type' => $txnVerification['txn_type'] ?? 'UNKNOWN',
            'refund_amt_on_paytm' => $txnVerification['refund_amt_on_paytm'] ?? 'UNKNOWN',
        ]);
    }

    /**
     * Check refund status from Paytm
     */
    public function checkRefundStatus(string $refundId, string $orderId): array
    {
        $requestId = uniqid('paytm_refund_status_', true);

        try {
            Log::info('Paytm Refund Status Check: Start', [
                'request_id' => $requestId,
                'refund_id' => $refundId,
                'order_id' => $orderId,
            ]);

            $paytmParams = [
                "body" => [
                    "mid" => $this->merchantId,
                    "orderId" => $orderId,
                    "refId" => $refundId,
                ],
            ];

            $checksum = Paytm::generateSignature(
                json_encode($paytmParams["body"], JSON_UNESCAPED_SLASHES),
                $this->merchantKey
            );

            $paytmParams["head"] = ["signature" => $checksum];

            $url = $this->apiBaseUrl . "refund/status";

            $response = Http::withHeaders([
                'Content-Type' => 'application/json',
            ])->timeout(30)->post($url, $paytmParams);

            $responseData = $response->json();

            Log::info('Paytm Refund Status Check: Response', [
                'request_id' => $requestId,
                'refund_id' => $refundId,
                'http_status_code' => $response->status(),
                'response' => $responseData,
            ]);

            if ($response->successful() && isset($responseData['body'])) {
                return [
                    'success' => true,
                    'data' => $responseData['body'],
                    'status' => $responseData['body']['resultInfo']['resultStatus'] ?? 'UNKNOWN',
                    'message' => $responseData['body']['resultInfo']['resultMsg'] ?? '',
                ];
            } else {
                return [
                    'success' => false,
                    'error' => $responseData['body']['resultInfo']['resultMsg'] ?? 'Status check failed',
                ];
            }

        } catch (\Exception $e) {
            Log::error('Paytm Refund Status Check Exception', [
                'request_id' => $requestId,
                'refund_id' => $refundId,
                'error' => $e->getMessage(),
            ]);

            return ['success' => false, 'error' => $e->getMessage()];
        }
    }
}
