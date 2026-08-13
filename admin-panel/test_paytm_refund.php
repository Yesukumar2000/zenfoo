<?php

/**
 * Paytm Refund API Diagnostic Script
 *
 * Tests refund API on both TEST and LIVE environments using the correct
 * Paytm refund endpoints from official documentation.
 *
 * Usage: php test_paytm_refund.php
 */


require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Helpers\Paytm;
use App\Models\Setting;
use App\Models\PaytmTransaction;

echo "\n";
echo "============================================================\n";
echo "   PAYTM REFUND API DIAGNOSTIC TEST\n";
echo "   Correct URLs from Paytm Official Docs\n";
echo "============================================================\n\n";

// ─── Credentials ───
$liveMid = Setting::get_value('paytm_live_merchant_id') ?: Setting::get_value('paytm_merchant_id');
$liveKey = Setting::get_value('paytm_live_merchant_key') ?: Setting::get_value('paytm_merchant_key');
$testMid = Setting::get_value('paytm_test_merchant_id');
$testKey = Setting::get_value('paytm_test_merchant_key');

// ─── Correct Paytm refund URLs from official docs ───
$LIVE_REFUND_URL = "https://router.paytm.in/aoa-refund-service/refund/apply";
$TEST_REFUND_URL = "https://stage-router.paytm.in/aoa-refund-service/refund/apply";

// ─── Old (wrong) URL we were using ───
$OLD_LIVE_URL = "https://secure.paytmpayments.com/refund/apply";
$OLD_TEST_URL = "https://securestage.paytmpayments.com/refund/apply";

// ─── Real transaction from order 422 ───
$realOrderId = 422;
$paytmTxn = PaytmTransaction::where('order_id', $realOrderId)->orderBy('id', 'desc')->first();

echo "CREDENTIALS:\n";
echo "  Live MID:  {$liveMid}\n";
echo "  Live Key:  " . substr($liveKey, 0, 4) . "****" . substr($liveKey, -4) . " (length: " . strlen($liveKey) . ")\n";
echo "  Test MID:  {$testMid}\n";
echo "  Test Key:  " . substr($testKey, 0, 4) . "****" . substr($testKey, -4) . " (length: " . strlen($testKey) . ")\n";
echo "\n";

if ($paytmTxn) {
    echo "REAL TRANSACTION (Order #{$realOrderId}):\n";
    echo "  Paytm Order ID: {$paytmTxn->txn_id}\n";
    echo "  Paytm Txn ID:   {$paytmTxn->paytm_txn_id}\n";
    echo "  Payment Mode:   {$paytmTxn->payment_mode}\n";
    echo "  Bank:           " . ($paytmTxn->bank_name ?: 'N/A') . "\n";
    echo "  Gateway:        " . ($paytmTxn->gateway_name ?: 'N/A') . "\n";
    echo "  Amount:         {$paytmTxn->amount}\n";
    echo "\n";
}

echo "============================================================\n";
echo "   TEST 1: LIVE keys + CORRECT URL (router.paytm.in)\n";
echo "   Real order #{$realOrderId}\n";
echo "============================================================\n\n";

if ($paytmTxn) {
    $result = callRefundApi(
        $LIVE_REFUND_URL,
        $liveMid,
        $liveKey,
        $paytmTxn->txn_id,
        $paytmTxn->paytm_txn_id,
        $paytmTxn->amount
    );
    printResult($result, "LIVE + CORRECT URL + REAL ORDER");
} else {
    echo "  SKIPPED — No paytm_transactions record for order #{$realOrderId}\n\n";
}

echo "============================================================\n";
echo "   TEST 2: LIVE keys + OLD URL (secure.paytmpayments.com)\n";
echo "   Real order #{$realOrderId} (what we were doing before)\n";
echo "============================================================\n\n";

if ($paytmTxn) {
    $result = callRefundApi(
        $OLD_LIVE_URL,
        $liveMid,
        $liveKey,
        $paytmTxn->txn_id,
        $paytmTxn->paytm_txn_id,
        $paytmTxn->amount
    );
    printResult($result, "LIVE + OLD URL + REAL ORDER");
} else {
    echo "  SKIPPED — No paytm_transactions record for order #{$realOrderId}\n\n";
}

echo "============================================================\n";
echo "   TEST 3: TEST keys + CORRECT URL (stage-router.paytm.in)\n";
echo "   Fake order (just testing if API is reachable)\n";
echo "============================================================\n\n";

$result = callRefundApi(
    $TEST_REFUND_URL,
    $testMid,
    $testKey,
    'FAKE_ORDER_DIAG_' . time(),
    'FAKE_TXN_DIAG_' . time(),
    1.00
);
printResult($result, "TEST + CORRECT URL + FAKE ORDER");

echo "============================================================\n";
echo "   TEST 4: LIVE keys + CORRECT URL + FAKE order\n";
echo "   Tests if refund API is enabled at all on live account\n";
echo "============================================================\n\n";

$result = callRefundApi(
    $LIVE_REFUND_URL,
    $liveMid,
    $liveKey,
    'FAKE_ORDER_DIAG_' . time(),
    'FAKE_TXN_DIAG_' . time(),
    1.00
);
printResult($result, "LIVE + CORRECT URL + FAKE ORDER");

echo "============================================================\n";
echo "   TEST 5: TEST keys + OLD URL (securestage.paytmpayments.com)\n";
echo "   Fake order — confirm test endpoint works\n";
echo "============================================================\n\n";

$result = callRefundApi(
    $OLD_TEST_URL,
    $testMid,
    $testKey,
    'FAKE_ORDER_DIAG_' . time(),
    'FAKE_TXN_DIAG_' . time(),
    1.00
);
printResult($result, "TEST + OLD URL + FAKE ORDER");

echo "============================================================\n";
echo "   TEST 6: LIVE keys + OLD URL + FAKE order\n";
echo "   Tests if refund API is enabled at all on live account\n";
echo "============================================================\n\n";

$result = callRefundApi(
    $OLD_LIVE_URL,
    $liveMid,
    $liveKey,
    'FAKE_ORDER_DIAG_' . time(),
    'FAKE_TXN_DIAG_' . time(),
    1.00
);
printResult($result, "LIVE + OLD URL + FAKE ORDER");

echo "============================================================\n";
echo "   DONE — Compare results above\n";
echo "============================================================\n\n";
echo "KEY COMPARISON:\n";
echo "  If TEST+OLD URL returns 'order not found' type error (334/327)\n";
echo "  but LIVE+OLD URL returns 600 for a FAKE order:\n";
echo "    => Refund API not enabled on live account.\n\n";
echo "  If BOTH return similar 'order not found' errors:\n";
echo "    => Refund API IS enabled. Issue is UPI/bank specific.\n\n";


// ─── Functions ───

function callRefundApi(string $url, string $mid, string $key, string $orderId, string $txnId, float $amount): array
{
    $refundId = 'DIAG_' . time() . '_' . rand(1000, 9999);

    $body = [
        "mid" => $mid,
        "orderId" => $orderId,
        "refId" => $refundId,
        "refundAmount" => number_format($amount, 2, '.', ''),
        "txnId" => $txnId,
        "refundDestination" => "TO_SOURCE",
    ];

    $paytmParams = ["body" => $body];

    $checksum = Paytm::generateSignature(
        json_encode($body, JSON_UNESCAPED_SLASHES),
        $key
    );

    // Head with additional fields as per Paytm official docs
    $paytmParams["head"] = [
        "clientId" => "C11",
        "version" => "v1",
        "requestTimestamp" => (string) round(microtime(true) * 1000),
        "signature" => $checksum,
    ];

    $postData = json_encode($paytmParams, JSON_UNESCAPED_SLASHES);

    echo "  URL:     {$url}\n";
    echo "  MID:     {$mid}\n";
    echo "  OrderID: {$orderId}\n";
    echo "  TxnID:   {$txnId}\n";
    echo "  Amount:  {$body['refundAmount']}\n";
    echo "  RefID:   {$refundId}\n";
    echo "  refundDestination: TO_SOURCE\n";
    echo "\n  Calling Paytm...\n\n";

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ["Content-Type: application/json"]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    // Skip SSL verification for local testing only
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    $parsed = json_decode($response, true);

    return [
        'http_code' => $httpCode,
        'curl_error' => $curlError,
        'result_status' => $parsed['body']['resultInfo']['resultStatus'] ?? 'N/A',
        'result_code' => $parsed['body']['resultInfo']['resultCode'] ?? 'N/A',
        'result_msg' => $parsed['body']['resultInfo']['resultMsg'] ?? 'N/A',
        'raw_response' => $response,
    ];
}

function printResult(array $result, string $label): void
{
    echo "  ┌─────────────────────────────────────────────\n";
    echo "  │ {$label}\n";
    echo "  ├─────────────────────────────────────────────\n";
    echo "  │ HTTP Status:    {$result['http_code']}\n";
    echo "  │ Result Status:  {$result['result_status']}\n";
    echo "  │ Result Code:    {$result['result_code']}\n";
    echo "  │ Result Msg:     {$result['result_msg']}\n";

    if ($result['curl_error']) {
        echo "  │ CURL Error:     {$result['curl_error']}\n";
    }

    // Verdict
    $code = $result['result_code'];
    if ($code === '10' || $result['result_status'] === 'TXN_SUCCESS' || $result['result_status'] === 'PENDING') {
        echo "  │\n";
        echo "  │ >>> REFUND SUCCESSFUL! API IS WORKING! <<<\n";
    } elseif ($code === '600') {
        echo "  │\n";
        echo "  │ >>> ERROR 600: Refund API issue (wrong URL or not enabled) <<<\n";
    } elseif (in_array($code, ['334', '327', '330'])) {
        echo "  │\n";
        echo "  │ >>> API IS REACHABLE & ENABLED (expected error for invalid order) <<<\n";
    } elseif ($code === '501') {
        echo "  │\n";
        echo "  │ >>> SYSTEM ERROR at Paytm (may be temporary) <<<\n";
    }

    echo "  └─────────────────────────────────────────────\n";
    echo "\n  Raw: {$result['raw_response']}\n\n";
}
