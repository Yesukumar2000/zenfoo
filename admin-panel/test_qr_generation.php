<?php


/**
 * Test script for QR code generation
 *
 * Run this script to test if the QR code generation is working properly
 * Usage: php test_qr_generation.php
 */

require __DIR__ . '/vendor/autoload.php';

use SimpleSoftwareIO\QrCode\Generator;

echo "=== Testing QR Code Generation ===\n\n";

try {
    // Test 1: Check if library is installed
    echo "Test 1: Checking if SimpleSoftwareIO QR Code library is installed...\n";
    if (class_exists('\SimpleSoftwareIO\QrCode\Generator')) {
        echo "✓ Library is installed!\n\n";
    } else {
        echo "✗ Library NOT found!\n";
        exit(1);
    }

    // Test 2: Generate a simple QR code
    echo "Test 2: Generating a simple test QR code...\n";
    $qrGenerator = new Generator();
    $testQrCode = $qrGenerator
        ->format('png')
        ->size(300)
        ->errorCorrection('H')
        ->margin(2)
        ->generate('Test QR Code - Hello World!');

    echo "✓ QR code generated successfully!\n";
    echo "   Size: " . strlen($testQrCode) . " bytes\n\n";

    // Test 3: Generate UPI payment QR code
    echo "Test 3: Generating UPI payment QR code...\n";
    $upiString = "upi://pay?pa=test@paytm&pn=Test%20Merchant&am=100.50&tr=ORDER123&tn=Test%20Order&cu=INR";
    $upiQrCode = $qrGenerator
        ->format('png')
        ->size(300)
        ->errorCorrection('H')
        ->margin(2)
        ->generate($upiString);

    echo "✓ UPI QR code generated successfully!\n";
    echo "   UPI String: $upiString\n";
    echo "   Size: " . strlen($upiQrCode) . " bytes\n\n";

    // Test 4: Convert to base64
    echo "Test 4: Converting to base64...\n";
    $base64 = base64_encode($upiQrCode);
    $dataUri = 'data:image/png;base64,' . $base64;
    echo "✓ Converted to base64 successfully!\n";
    echo "   Base64 length: " . strlen($base64) . " characters\n";
    echo "   Data URI length: " . strlen($dataUri) . " characters\n\n";

    // Test 5: Save to file
    echo "Test 5: Saving QR code to file...\n";
    $testDir = __DIR__ . '/storage/app/public/qr_codes_test';
    if (!file_exists($testDir)) {
        mkdir($testDir, 0755, true);
    }

    $testFilePath = $testDir . '/test_qr_' . time() . '.png';
    file_put_contents($testFilePath, $upiQrCode);
    echo "✓ QR code saved successfully!\n";
    echo "   File path: $testFilePath\n";
    echo "   File size: " . filesize($testFilePath) . " bytes\n\n";

    // Summary
    echo "=== All Tests Passed! ===\n";
    echo "The QR code generation system is working correctly.\n";
    echo "You can find the test QR code at: $testFilePath\n";
    echo "\nTo test in your app:\n";
    echo "1. Scan the generated QR code with any UPI app\n";
    echo "2. You should see: Test Merchant, Amount: ₹100.50\n";
    echo "3. Transaction reference: ORDER123\n\n";

} catch (Exception $e) {
    echo "✗ Error occurred!\n";
    echo "   Error: " . $e->getMessage() . "\n";
    echo "   File: " . $e->getFile() . ":" . $e->getLine() . "\n";
    exit(1);
}
