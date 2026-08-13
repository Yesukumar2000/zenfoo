#!/bin/bash

# PhonePe Backend Test Script
# This script tests your Laravel backend's PhonePe integration

echo "======================================"
echo "PhonePe Backend Integration Test"
echo "======================================"
echo ""

# Configuration
BACKEND_URL="https://wheat-rook-708688.hostingersite.com/customer/phonepe/initiate-payment"
TEST_AMOUNT="100"
TEST_USER_ID="7702480129"
TEST_MOBILE="7702480129"

echo "Testing endpoint: $BACKEND_URL"
echo "Test amount: ₹$TEST_AMOUNT"
echo ""

# Test the endpoint
echo "Sending request..."
echo ""

RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$BACKEND_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"amount\": \"$TEST_AMOUNT\",
    \"user_id\": \"$TEST_USER_ID\",
    \"mobile_number\": \"$TEST_MOBILE\",
    \"payment_mode\": \"UPI\"
  }")

# Extract HTTP status code
HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_STATUS")

echo "======================================"
echo "Response:"
echo "======================================"
echo "HTTP Status: $HTTP_STATUS"
echo ""
echo "Body:"
echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
echo ""

# Analyze response
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ SUCCESS! Backend is working correctly."
    echo ""

    # Check if response contains orderId and token
    if echo "$BODY" | grep -q "orderId" && echo "$BODY" | grep -q "token"; then
        echo "✅ Response contains orderId and token (NEW FORMAT)"
        echo "✅ Flutter app will work correctly with this response!"
    else
        echo "⚠️  WARNING: Response doesn't contain orderId/token"
        echo "❌ This is the OLD FORMAT - Flutter app needs NEW FORMAT"
    fi
else
    echo "❌ ERROR! Backend returned status $HTTP_STATUS"
    echo ""

    if echo "$BODY" | grep -q "Key not found for the merchant"; then
        echo "🔍 Diagnosis: 'Key not found for the merchant'"
        echo ""
        echo "This error means one of the following:"
        echo "  1. PhonePeController.php hasn't been deployed yet"
        echo "  2. Environment variables are missing in .env file"
        echo "  3. PhonePe test credentials are incorrect"
        echo ""
        echo "📋 Action Required:"
        echo "  1. Deploy PhonePeController.php to app/Http/Controllers/Customer/"
        echo "  2. Add to .env:"
        echo "     PHONEPE_MERCHANT_ID=PGTESTPAYUAT"
        echo "     PHONEPE_SALT_KEY=96434309-7796-489d-8924-ab56988a6076"
        echo "     PHONEPE_SALT_INDEX=1"
        echo "     PHONEPE_ENVIRONMENT=SANDBOX"
        echo "  3. Run: php artisan config:clear"
        echo "  4. Check Laravel logs: storage/logs/laravel.log"
    fi
fi

echo ""
echo "======================================"
echo "Test complete!"
echo "======================================"
