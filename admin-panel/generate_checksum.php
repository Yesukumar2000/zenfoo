<?php

/**
 * Generate Paytm checksum for Postman testing
 *
 * Usage: php generate_checksum.php
 *
 * Copy the full JSON output and paste directly into Postman Body (raw JSON)
 */

function paytm_encrypt($input, $key) {
    $iv = "@@@@&&&&####$$$$";
    return openssl_encrypt($input, "AES-128-CBC", $key, 0, $iv);
}

function generateRandomString($length) {
    $chars = "9876543210ZYXWVUTSRQPONMLKJIHGFEDCBAabcdefghijklmnopqrstuvwxyz!@#\$&_";
    $random = "";
    for ($i = 0; $i < $length; $i++) {
        $random .= $chars[rand(0, strlen($chars) - 1)];
    }
    return $random;
}

function generateSignature($params, $key) {
    $salt = generateRandomString(4);
    $finalString = $params . "|" . $salt;
    $hash = hash("sha256", $finalString);
    return paytm_encrypt($hash . $salt, $key);
}

// ---- CONFIG (change these as needed) ----
$merchantId  = 'SrjVNS79487613879240';  // Live MID
$merchantKey = 'N2g#nkkD@9FBHPR5';      // Live Key
$orderId     = 'TEST_ORDER_' . time();   // Unique order ID
$amount      = '1.00';                   // Amount in rupees

// ---- Build request body ----
$body = [
    'mid'          => $merchantId,
    'orderId'      => $orderId,
    'amount'       => $amount,
    'businessType' => 'UPI_QR_CODE',
    'posId'        => 'ZENFOO_TEST',
];

$bodyJson = json_encode($body, JSON_UNESCAPED_SLASHES);
$checksum = generateSignature($bodyJson, $merchantKey);

$fullRequest = [
    'head' => [
        'clientId'  => $merchantId,
        'version'   => 'v1',
        'tokenType' => 'CHECKSUM',
        'signature' => $checksum,
    ],
    'body' => $body,
];

echo "\n";
echo "=== PAYTM QR CODE - POSTMAN REQUEST ===\n\n";
echo "URL:    POST https://secure.paytmpayments.com/paymentservices/qr/create\n";
echo "Header: Content-Type: application/json\n\n";
echo "Order ID: $orderId\n";
echo "Amount:   Rs $amount\n\n";
echo "--- COPY BELOW JSON INTO POSTMAN BODY (raw > JSON) ---\n\n";
echo json_encode($fullRequest, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
echo "\n\n--- END ---\n";
