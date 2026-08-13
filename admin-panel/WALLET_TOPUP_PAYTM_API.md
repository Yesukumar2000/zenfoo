# Wallet Top-Up with Paytm - API Documentation

This document describes the complete flow for wallet top-up using Paytm payment gateway.

## Base URL
```
{{base_url}}/api/customer
```

## Authentication
All endpoints require authentication using Bearer token.

Header:
```
Authorization: Bearer {access_token}
```

---

## Complete Wallet Top-Up Flow

### Step 1: Generate Paytm Transaction Token

**Endpoint:** `POST /generate-paytm-txn-token`

**Request Body:**
```json
{
    "type": "wallet",
    "wallet_amount": 500
}
```

**Success Response (200):**
```json
{
    "success": 1,
    "message": "Transaction token generated successfully",
    "data": {
        "txn_token": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0",
        "order_id": "WALLET_TOPUP_123_1709987654_abc123",
        "amount": 500,
        "merchant_id": "YOUR_MERCHANT_ID",
        "website": "WEBSTAGING",
        "callback_url": "https://yourapp.com/paytm/callback",
        "type": "wallet"
    }
}
```

**Notes:**
- `order_id` is auto-generated with format: `WALLET_TOPUP_{user_id}_{timestamp}_{unique_id}`
- `txn_token` is used for Paytm payment in Flutter app
- `amount` is the wallet top-up amount

---

### Step 2: Make Payment on Paytm (Flutter Side)

Customer completes payment using Paytm SDK in Flutter app using the `txn_token` from Step 1.

After payment, Paytm returns `transaction_id` (TXNID).

---

### Step 3: Verify Payment (Optional but Recommended)

**Endpoint:** `POST /api/paytm/verify-payment`

**Request Body:**
```json
{
    "transaction_id": "WALLET_TOPUP_123_1709987654_abc123",
    "amount": 500,
    "type_of_payment": "wallet_topup"
}
```

**Success Response (200):**
```json
{
    "status": true,
    "message": "Payment verified and captured successfully",
    "data": {
        "transaction_id": "WALLET_TOPUP_123_1709987654_abc123",
        "paytm_transaction_id": "20260309111212345678",
        "bank_transaction_id": "HDFC987654321",
        "amount": 500,
        "payment_status": "success",
        "payment_mode": "UPI",
        "bank_name": "HDFC",
        "transaction_date": "2026-03-09 12:30:45",
        "captured": true,
        "type_of_payment": "wallet_topup"
    }
}
```

**Notes:**
- This step stores the payment in `paytm_transactions` table
- Verifies payment with Paytm gateway
- Returns payment details for confirmation

---

### Step 4: Add Money to Wallet with Paytm Verification

**Endpoint:** `POST /add_wallet_balance`

**Request Body (Paytm Payment):**
```json
{
    "type": "credit",
    "amount": 500,
    "payment_method": "paytm",
    "transaction_id": "WALLET_TOPUP_123_1709987654_abc123",
    "message": "Wallet recharge via Paytm"
}
```

**Request Body (Manual - Admin Only):**
```json
{
    "type": "credit",
    "amount": 500,
    "payment_method": "manual",
    "message": "Admin credit"
}
```

**Success Response (200):**
```json
{
    "success": 1,
    "message": "Wallet recharged successfully",
    "data": {
        "new_balance": 1500,
        "wallet_transaction_id": 456,
        "amount": 500,
        "type": "credit"
    }
}
```

**Error Responses:**

**Payment Not Found (400):**
```json
{
    "success": 0,
    "message": "Payment transaction not found. Please verify your payment first."
}
```

**Payment Not Successful (400):**
```json
{
    "success": 0,
    "message": "Payment was not successful. Status: failed"
}
```

**Payment Already Used (400):**
```json
{
    "success": 0,
    "message": "This payment has already been used for wallet credit."
}
```

**Invalid Payment Type (400):**
```json
{
    "success": 0,
    "message": "This payment is not for wallet top-up."
}
```

**Amount Mismatch (400):**
```json
{
    "success": 0,
    "message": "Amount mismatch. Payment amount: ₹500.00, Requested: ₹450.00"
}
```

---

## Verification Logic

When `payment_method` is "paytm" and `transaction_id` is provided, the API performs these checks:

1. ✅ **Payment Exists**: Checks if Paytm payment exists in database
2. ✅ **Payment Belongs to User**: Verifies the payment is for the authenticated user
3. ✅ **Payment Successful**: Status must be "success"
4. ✅ **Payment Captured**: Payment must be captured (auto-captured by Paytm)
5. ✅ **Correct Payment Type**: Must be "wallet_topup" (not "order_placing")
6. ✅ **Not Already Used**: Payment not already linked to another wallet transaction
7. ✅ **Amount Matches**: Requested amount matches payment amount

If all checks pass, the wallet is credited and the payment is linked to the wallet transaction.

---

## Database Structure

### paytm_transactions Table
```sql
- id (Primary Key)
- user_id (Foreign Key to users)
- order_id (nullable - null for wallet topup)
- wallet_transaction_id (nullable - links to wallet_transactions)
- txn_id (Unique - our transaction ID)
- paytm_txn_id (Paytm's TXNID)
- amount
- payment_mode (UPI, CC, DC, NB, etc.)
- bank_name
- status (success, failed, pending)
- is_captured (1 or 0)
- type_of_payment (order_placing or wallet_topup)
- transaction_date
- is_refunded (for refunds)
- refund_id (nullable)
- created_at, updated_at
```

### wallet_transactions Table
```sql
- id (Primary Key)
- user_id (Foreign Key to users)
- order_id (nullable)
- order_item_id (nullable)
- type (credit or debit)
- amount
- txn_id (nullable - Paytm transaction ID)
- payment_type (paytm, phonepe, manual, refund, etc.)
- message (Description)
- status (1 = success)
- created_at, updated_at
```

**Relationship:**
- `paytm_transactions.wallet_transaction_id` → `wallet_transactions.id` (One-to-One)
- This ensures each Paytm payment can only be used once for wallet credit

---

## Complete Flutter Integration Example

```dart
// Step 1: Generate txnToken
var response = await api.post('/customer/generate-paytm-txn-token', {
  'type': 'wallet',
  'wallet_amount': 500
});

String txnToken = response['data']['txn_token'];
String orderId = response['data']['order_id'];
String amount = response['data']['amount'].toString();
String mid = response['data']['merchant_id'];

// Step 2: Initiate Paytm Payment
var paytmResponse = await Paytm.startTransaction(
  mid: mid,
  orderId: orderId,
  amount: amount,
  txnToken: txnToken,
  callbackUrl: "https://yourapp.com/paytm/callback",
  staging: true, // false for production
);

String transactionId = paytmResponse.txnId;

// Step 3: Verify Payment (Optional)
await api.post('/api/paytm/verify-payment', {
  'transaction_id': transactionId,
  'amount': 500,
  'type_of_payment': 'wallet_topup'
});

// Step 4: Credit Wallet
var walletResponse = await api.post('/customer/add_wallet_balance', {
  'type': 'credit',
  'amount': 500,
  'payment_method': 'paytm',
  'transaction_id': transactionId
});

print('New Balance: ${walletResponse['data']['new_balance']}');
```

---

## Security Features

1. **Payment Verification**: All Paytm payments are verified with Paytm gateway before wallet credit
2. **One-Time Use**: Each payment can only be used once (via `wallet_transaction_id` link)
3. **User Validation**: Payments are verified to belong to the authenticated user
4. **Amount Validation**: Payment amount must match requested amount
5. **Type Validation**: Only "wallet_topup" payments accepted (not "order_placing")
6. **Transaction Logging**: Comprehensive logging at every step for debugging
7. **Database Transactions**: All operations wrapped in DB transactions for consistency

---

## Logs Format

All operations are logged with the following structure:

```
=== ADD WALLET BALANCE REQUEST START ===
Request ID: wallet_add_65f1234567890
User ID: 123
Payment Method: paytm
Transaction ID: WALLET_TOPUP_123_1709987654_abc123

→ Paytm payment verification required
→ Paytm payment verified successfully
→ Updating user balance (Old: ₹1000, New: ₹1500)
→ Wallet transaction created (ID: 456)
→ Paytm transaction linked to wallet (Paytm ID: 789)

=== ADD WALLET BALANCE SUCCESS ===
Wallet Transaction ID: 456
Amount: ₹500
New Balance: ₹1500
```

---

## Testing

### Test with Mock Mode

1. Set `paytm_refund_mock_mode` to `true` in settings (for testing)
2. Use `/api/paytm/test/create-transaction` to create a test payment
3. Use the returned `transaction_id` for wallet top-up testing

### Production Testing Checklist

- [ ] Configure Paytm test credentials in admin panel
- [ ] Test wallet top-up flow end-to-end
- [ ] Verify payment verification works
- [ ] Check wallet balance updates correctly
- [ ] Verify payment can't be used twice
- [ ] Test amount mismatch validation
- [ ] Test invalid payment type rejection
- [ ] Switch to production credentials
- [ ] Test with real payment (small amount)

---

## Notes

- **Order ID for Wallet**: Always starts with `WALLET_TOPUP_` prefix
- **Payment Type**: Must be set to `wallet_topup` in verify-payment API
- **Manual Credit**: `payment_method: "manual"` can be used by admin without transaction_id
- **Insufficient Balance**: Debit operations check for sufficient balance
- **Floating Point**: Amount comparison allows 0.01 difference for floating point precision

---

## Support

For issues or questions:
1. Check logs in `storage/logs/laravel.log`
2. Search for request_id to trace the complete flow
3. Verify Paytm credentials are correct
4. Ensure migration has been run: `2026_03_09_123001_add_wallet_transaction_id_to_paytm_transactions_table.php`