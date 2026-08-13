# Seller Wallet System - API Documentation

## Overview

The Seller Wallet System provides comprehensive tracking of seller earnings, withdrawals, and transaction history. It automatically credits sellers when orders are delivered and allows sellers to request withdrawals with an admin approval workflow.

## Key Features

- **Automatic Crediting**: Sellers are automatically credited when orders/order items are marked as "Delivered" or self-pickup orders are "Picked Up"
- **Commission Deduction**: Admin commission is automatically deducted before crediting seller wallet
- **Balance Tracking**: Every transaction records before/after balances for complete audit trail
- **Withdrawal Workflow**: Request → Pending → Admin Approval → Processing → Completed
- **Transaction Types**: Credit, Debit, Withdrawal, Order Commission, Refund, Adjustment
- **Comprehensive Statistics**: Track earnings by day, month, year, and total

---

## Money Flow Diagram

```
Order Delivered
    ↓
Calculate: Item Total = quantity × discounted_price
    ↓
Calculate: Commission Amount = (Item Total × commission_percent) / 100
    ↓
Calculate: Seller Amount = Item Total - Commission Amount
    ↓
Get Current Balance (balance_before)
    ↓
Calculate: New Balance = balance_before + seller_amount (balance_after)
    ↓
Create Wallet Transaction Record:
  - type: order_commission
  - amount: seller_amount
  - balance_before: current balance
  - balance_after: new balance
  - reference_type: order_item
  - reference_id: order_item_id
    ↓
Update Seller Balance
    ↓
Commit Transaction
```

---

## Data Sources

The wallet system fetches data from multiple tables for accurate tracking:

### 1. Current Balance
- **Source**: `sellers.balance` column
- **Description**: Real-time wallet balance that gets updated on every credit/debit transaction

### 2. Completed Orders & Earnings
- **Source**: `seller_wallet_transactions` table
- **Filter**: `type IN ('order_commission', 'credit', 'refund')`
- **Description**: All credited amounts from delivered orders and refunds

### 3. Withdrawals
- **Source**: `seller_wallet_transactions` table (for completed withdrawals)
- **Filter**: `type = 'withdrawal'`
- **Description**: Total amount withdrawn from wallet

### 4. Pending Withdrawals
- **Source**: `seller_withdrawal_requests` table
- **Filter**: `status IN ('pending', 'approved', 'processing')`
- **Description**: Withdrawal requests that are not yet completed

### 5. Today's Earnings
- **Source**: `seller_wallet_transactions` table
- **Filter**: `type = 'order_commission' AND DATE(created_at) = today`
- **Description**: Earnings from orders delivered today

### 6. Cancelled Orders
- **Source**: `order_items` table
- **Filter**: `active_status = 7` (Cancelled)
- **Description**: Total value of cancelled orders (not credited to wallet)

### 7. Returned Orders
- **Source**: `order_items` table
- **Filter**: `active_status = 8` (Returned)
- **Description**: Total value of returned orders (debited from wallet if already credited)

### 8. Transaction History
- **Source**: `seller_wallet_transactions` table
- **Description**: Complete audit trail of all wallet activities with before/after balances

---

## API Endpoints

All wallet APIs require authentication using the seller's API token.

### 1. Get Wallet Overview

**Endpoint**: `GET /api/seller/wallet/overview`

**Description**: Returns the seller's wallet overview including current balance, total earnings, withdrawals, and recent transactions.

**Headers**:
```
Authorization: Bearer {seller_token}
Content-Type: application/json
```

**Response**:
```json
{
    "status": 1,
    "message": "Wallet overview fetched successfully",
    "data": {
        "current_balance": 15750.50,
        "total_earned": 25000.00,
        "total_withdrawn": 9000.00,
        "pending_withdrawals": 1500.00,
        "available_for_withdrawal": 14250.50,
        "today_earnings": 450.00,
        "cancelled_orders_value": 2500.00,
        "returned_orders_value": 1200.00,
        "recent_transactions": [
            {
                "id": 123,
                "type": "order_commission",
                "amount": 450.00,
                "formatted_amount": "+₹450.00",
                "balance_before": 15300.50,
                "balance_after": 15750.50,
                "reference_type": "order_item",
                "reference_id": 456,
                "message": "Order #789 delivered - Item: Premium Product",
                "created_at": "2025-12-20 14:30:00"
            },
            {
                "id": 122,
                "type": "withdrawal",
                "amount": 2000.00,
                "formatted_amount": "-₹2,000.00",
                "balance_before": 17300.50,
                "balance_after": 15300.50,
                "reference_type": "withdrawal",
                "reference_id": 45,
                "message": "Withdrawal request approved",
                "created_at": "2025-12-19 10:15:00"
            }
        ]
    }
}
```

---

### 2. Get Transaction History

**Endpoint**: `GET /api/seller/wallet/transactions`

**Description**: Returns paginated transaction history with optional filters.

**Headers**:
```
Authorization: Bearer {seller_token}
Content-Type: application/json
```

**Query Parameters**:
- `page` (optional): Page number for pagination (default: 1)
- `per_page` (optional): Number of records per page (default: 20, max: 100)
- `type` (optional): Filter by transaction type (`credit`, `debit`, `withdrawal`, `order_commission`, `refund`, `adjustment`)
- `from_date` (optional): Filter from date (format: YYYY-MM-DD)
- `to_date` (optional): Filter to date (format: YYYY-MM-DD)

**Example Request**:
```
GET /api/seller/wallet/transactions?page=1&per_page=10&type=order_commission&from_date=2025-12-01&to_date=2025-12-31
```

**Response**:
```json
{
    "status": 1,
    "message": "Transaction history retrieved successfully",
    "data": {
        "current_page": 1,
        "data": [
            {
                "id": 123,
                "seller_id": 45,
                "order_id": 789,
                "order_item_id": 456,
                "type": "order_commission",
                "amount": 450.00,
                "formatted_amount": "+₹450.00",
                "balance_before": 15300.50,
                "balance_after": 15750.50,
                "reference_type": "order_item",
                "reference_id": 456,
                "message": "Order #789 delivered - Item: Premium Product",
                "admin_note": null,
                "status": 1,
                "processed_by": null,
                "created_at": "2025-12-20 14:30:00",
                "updated_at": "2025-12-20 14:30:00"
            }
        ],
        "first_page_url": "http://example.com/api/seller/wallet/transactions?page=1",
        "from": 1,
        "last_page": 5,
        "last_page_url": "http://example.com/api/seller/wallet/transactions?page=5",
        "next_page_url": "http://example.com/api/seller/wallet/transactions?page=2",
        "path": "http://example.com/api/seller/wallet/transactions",
        "per_page": 10,
        "prev_page_url": null,
        "to": 10,
        "total": 45
    }
}
```

---

### 3. Create Withdrawal Request

**Endpoint**: `POST /api/seller/wallet/withdrawal-request`

**Description**: Creates a new withdrawal request for the seller. Requires minimum withdrawal amount validation and sufficient balance.

**Headers**:
```
Authorization: Bearer {seller_token}
Content-Type: application/json
```

**Request Body**:
```json
{
    "amount": 5000.00,
    "account_number": "1234567890",
    "bank_ifsc_code": "SBIN0001234",
    "account_name": "John Doe Store",
    "bank_name": "State Bank of India",
    "branch_name": "Main Branch",
    "seller_note": "Monthly withdrawal request"
}
```

**Field Descriptions**:
- `amount` (required, numeric, min: 100): Withdrawal amount
- `account_number` (required, string): Bank account number
- `bank_ifsc_code` (required, string): Bank IFSC code
- `account_name` (required, string): Account holder name
- `bank_name` (required, string): Bank name
- `branch_name` (optional, string): Bank branch name
- `seller_note` (optional, string): Optional note from seller

**Response - Success**:
```json
{
    "status": 1,
    "message": "Withdrawal request created successfully. It will be processed within 3-5 business days.",
    "data": {
        "id": 67,
        "seller_id": 45,
        "amount": 5000.00,
        "balance_before": 15750.50,
        "balance_after": null,
        "account_number": "1234567890",
        "bank_ifsc_code": "SBIN0001234",
        "account_name": "John Doe Store",
        "bank_name": "State Bank of India",
        "branch_name": "Main Branch",
        "status": "pending",
        "seller_note": "Monthly withdrawal request",
        "admin_note": null,
        "processed_by": null,
        "processed_at": null,
        "payment_method": null,
        "transaction_reference": null,
        "created_at": "2025-12-20 15:00:00",
        "updated_at": "2025-12-20 15:00:00"
    }
}
```

**Response - Insufficient Balance**:
```json
{
    "status": 0,
    "message": "Insufficient balance. Your current balance is ₹450.00"
}
```

**Response - Below Minimum Amount**:
```json
{
    "status": 0,
    "message": "Minimum withdrawal amount is ₹100.00"
}
```

**Response - Validation Error**:
```json
{
    "status": 0,
    "message": "The amount field is required."
}
```

---

### 4. Get Withdrawal Requests

**Endpoint**: `GET /api/seller/wallet/withdrawal-requests`

**Description**: Returns paginated list of seller's withdrawal requests with optional status filter.

**Headers**:
```
Authorization: Bearer {seller_token}
Content-Type: application/json
```

**Query Parameters**:
- `page` (optional): Page number for pagination (default: 1)
- `per_page` (optional): Number of records per page (default: 20, max: 100)
- `status` (optional): Filter by status (`pending`, `approved`, `rejected`, `processing`, `completed`)

**Example Request**:
```
GET /api/seller/wallet/withdrawal-requests?page=1&per_page=10&status=pending
```

**Response**:
```json
{
    "status": 1,
    "message": "Withdrawal requests retrieved successfully",
    "data": {
        "current_page": 1,
        "data": [
            {
                "id": 67,
                "seller_id": 45,
                "amount": 5000.00,
                "balance_before": 15750.50,
                "balance_after": null,
                "account_number": "1234567890",
                "bank_ifsc_code": "SBIN0001234",
                "account_name": "John Doe Store",
                "bank_name": "State Bank of India",
                "branch_name": "Main Branch",
                "status": "pending",
                "seller_note": "Monthly withdrawal request",
                "admin_note": null,
                "processed_by": null,
                "processed_at": null,
                "payment_method": null,
                "transaction_reference": null,
                "created_at": "2025-12-20 15:00:00",
                "updated_at": "2025-12-20 15:00:00"
            },
            {
                "id": 66,
                "seller_id": 45,
                "amount": 3000.00,
                "balance_before": 12000.00,
                "balance_after": 9000.00,
                "account_number": "1234567890",
                "bank_ifsc_code": "SBIN0001234",
                "account_name": "John Doe Store",
                "bank_name": "State Bank of India",
                "branch_name": "Main Branch",
                "status": "completed",
                "seller_note": null,
                "admin_note": "Processed via NEFT",
                "processed_by": 1,
                "processed_at": "2025-12-18 11:30:00",
                "payment_method": "NEFT",
                "transaction_reference": "NEFT123456789",
                "created_at": "2025-12-17 10:00:00",
                "updated_at": "2025-12-18 11:30:00"
            }
        ],
        "first_page_url": "http://example.com/api/seller/wallet/withdrawal-requests?page=1",
        "from": 1,
        "last_page": 3,
        "last_page_url": "http://example.com/api/seller/wallet/withdrawal-requests?page=3",
        "next_page_url": "http://example.com/api/seller/wallet/withdrawal-requests?page=2",
        "path": "http://example.com/api/seller/wallet/withdrawal-requests",
        "per_page": 10,
        "prev_page_url": null,
        "to": 10,
        "total": 25
    }
}
```

---

### 5. Get Earnings Summary

**Endpoint**: `GET /api/seller/wallet/earnings-summary`

**Description**: Returns comprehensive earnings breakdown by time period.

**Headers**:
```
Authorization: Bearer {seller_token}
Content-Type: application/json
```

**Response**:
```json
{
    "status": 1,
    "message": "Earnings summary retrieved successfully",
    "data": {
        "today": {
            "total_credits": 1250.00,
            "total_debits": 0.00,
            "net_earnings": 1250.00,
            "order_count": 5,
            "average_per_order": 250.00
        },
        "this_month": {
            "total_credits": 18500.00,
            "total_debits": 5000.00,
            "net_earnings": 13500.00,
            "order_count": 42,
            "average_per_order": 440.48
        },
        "this_year": {
            "total_credits": 125000.00,
            "total_debits": 45000.00,
            "net_earnings": 80000.00,
            "order_count": 320,
            "average_per_order": 390.63
        },
        "all_time": {
            "total_credits": 250000.00,
            "total_debits": 90000.00,
            "net_earnings": 160000.00,
            "order_count": 650,
            "average_per_order": 384.62,
            "total_withdrawals": 90000.00,
            "current_balance": 15750.50
        }
    }
}
```

---

## Withdrawal Request Workflow

### Status Flow

```
pending → approved → processing → completed
   ↓
rejected (terminal state)
```

### Status Descriptions

1. **pending**: Withdrawal request created by seller, awaiting admin review
2. **approved**: Admin has approved the withdrawal request
3. **rejected**: Admin has rejected the withdrawal request (terminal state)
4. **processing**: Payment is being processed
5. **completed**: Withdrawal completed and amount transferred to seller's bank account

### Withdrawal Flow Logic

**On Withdrawal Request Creation** (by seller):
1. Validate requested amount against available balance
2. Calculate `balance_after = current_balance - requested_amount`
3. Create withdrawal request record with status 'pending'
4. **Immediately deduct amount from seller balance**
5. Create wallet transaction record (TYPE_WITHDRAWAL, debit)
6. This prevents sellers from requesting multiple withdrawals with the same balance

**On Approval** (by admin):
1. Change withdrawal request status to 'approved'
2. Add optional admin notes, payment method, transaction reference
3. Update wallet transaction message to indicate approval
4. **No balance changes** (already deducted on request creation)
5. Send notification to seller

**On Rejection** (by admin):
1. Change withdrawal request status to 'rejected'
2. **Add the withdrawal amount back to seller balance** (refund)
3. Update original wallet transaction message
4. Create new wallet transaction record (TYPE_REFUND, credit) for the refund
5. Add admin note with rejection reason
6. Send notification to seller with reason

---

## Admin API Endpoints

### 1. Approve Withdrawal Request

**Endpoint**: `POST /api/admin/wallet/withdrawal-request/{requestId}/approve`

**Description**: Approves a pending withdrawal request. This endpoint only changes the status to approved and sends notification. The balance was already deducted when the seller created the request.

**Headers**:
```
Authorization: Bearer {admin_token}
Content-Type: application/json
```

**Path Parameters**:
- `requestId` (required): The ID of the withdrawal request to approve

**Request Body**:
```json
{
    "admin_note": "Approved. Payment will be processed via bank transfer.",
    "payment_method": "Bank Transfer",
    "transaction_reference": "TXN123456789"
}
```

**Request Parameters**:
- `admin_note` (optional): Admin's note about the approval
- `payment_method` (optional): Method of payment (e.g., "Bank Transfer", "UPI", "Check")
- `transaction_reference` (optional): Payment transaction reference number

**Response**:
```json
{
    "status": 1,
    "message": "Withdrawal request approved successfully",
    "data": {
        "withdrawal_request": {
            "id": 15,
            "amount": 5000.00,
            "status": "approved",
            "processed_at": "2025-12-20 14:30:00"
        }
    }
}
```

**Error Responses**:

Invalid withdrawal request:
```json
{
    "status": 0,
    "message": "Withdrawal request not found."
}
```

Already processed:
```json
{
    "status": 0,
    "message": "Withdrawal request has already been processed."
}
```

---

### 2. Reject Withdrawal Request

**Endpoint**: `POST /api/admin/wallet/withdrawal-request/{requestId}/reject`

**Description**: Rejects a pending withdrawal request, adds the amount back to the seller's wallet, and sends notification with rejection reason.

**Headers**:
```
Authorization: Bearer {admin_token}
Content-Type: application/json
```

**Path Parameters**:
- `requestId` (required): The ID of the withdrawal request to reject

**Request Body**:
```json
{
    "admin_note": "Rejected due to incomplete KYC documentation. Please submit required documents and reapply."
}
```

**Request Parameters**:
- `admin_note` (required): Admin's note explaining the rejection reason (max 500 characters)

**Response**:
```json
{
    "status": 1,
    "message": "Withdrawal request rejected and amount refunded successfully",
    "data": {
        "withdrawal_request": {
            "id": 15,
            "amount": 5000.00,
            "status": "rejected",
            "refunded_amount": 5000.00,
            "new_balance": 20750.50,
            "processed_at": "2025-12-20 14:35:00"
        }
    }
}
```

**Error Responses**:

Invalid withdrawal request:
```json
{
    "status": 0,
    "message": "Withdrawal request not found."
}
```

Already processed:
```json
{
    "status": 0,
    "message": "Withdrawal request has already been processed."
}
```

Missing admin note:
```json
{
    "status": 0,
    "message": "The admin note field is required."
}
```

---

## Auto-Credit Logic

### When Does Auto-Credit Happen?

Sellers are automatically credited in the following scenarios:

#### 1. Regular Delivery Orders
When an order is marked as **"Delivered"** (status_id = 6):
- All non-cancelled, non-returned order items are credited to respective sellers
- Triggered in: `OrdersApiController@updateStatus()` and `OrdersApiController@updateItemsStatus()`

#### 2. Self-Pickup Orders
When a self-pickup order is marked as **"Picked Up"** (status_id = 11):
- All non-cancelled order items are credited to respective sellers
- Triggered in: `OrdersApiController@updateSelfPickupOrderStatus()`

### Commission Calculation

```php
// Example calculation
$itemTotal = $orderItem->quantity * $orderItem->discounted_price;
// Example: 5 × ₹200 = ₹1,000

$commissionPercent = $seller->commission ?? 0;
// Example: 15%

$commissionAmount = ($itemTotal * $commissionPercent) / 100;
// Example: (₹1,000 × 15) / 100 = ₹150

$sellerAmount = $itemTotal - $commissionAmount;
// Example: ₹1,000 - ₹150 = ₹850

// ₹850 is credited to seller wallet
// ₹150 goes to admin as commission
```

### Duplicate Prevention

The system checks if a transaction already exists for the order item before creating a new credit transaction:

```php
$existingTransaction = SellerWalletTransaction::where('order_item_id', $orderItem->id)
    ->where('type', SellerWalletTransaction::TYPE_ORDER_COMMISSION)
    ->first();

if ($existingTransaction) {
    return true; // Skip, already credited
}
```

This prevents double-crediting if the order status is updated multiple times.

---

## Transaction Types

### Credit Types (Increase Balance)

1. **order_commission**: Amount credited from delivered orders (after commission deduction)
2. **credit**: Manual credit by admin
3. **refund**: Refund credited to seller wallet

### Debit Types (Decrease Balance)

1. **withdrawal**: Amount withdrawn by seller
2. **debit**: Manual debit by admin
3. **adjustment**: Admin adjustment (can be positive or negative)

---

## Reference Types

Each transaction is linked to its source record:

- **order**: Links to `orders` table
- **order_item**: Links to `order_items` table (most common for auto-credits)
- **withdrawal**: Links to `seller_withdrawal_requests` table
- **refund**: Links to refund record
- **commission**: Links to commission record
- **adjustment**: Links to adjustment record

---

## Database Schema

### seller_wallet_transactions Table

```sql
CREATE TABLE seller_wallet_transactions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NULL,
    order_item_id BIGINT UNSIGNED NULL,
    seller_id BIGINT UNSIGNED NOT NULL,
    type VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    balance_before DECIMAL(10,2) DEFAULT 0,
    balance_after DECIMAL(10,2) DEFAULT 0,
    reference_type VARCHAR(255) NULL COMMENT 'withdrawal, order, credit, debit, refund, commission, adjustment',
    reference_id BIGINT UNSIGNED NULL COMMENT 'ID of the referenced record',
    message TEXT NULL,
    admin_note TEXT NULL COMMENT 'Admin note for manual transactions',
    status TINYINT(1) DEFAULT 1,
    processed_by BIGINT UNSIGNED NULL COMMENT 'Admin ID who processed this transaction',
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,

    INDEX idx_seller_id (seller_id),
    INDEX idx_order_id (order_id),
    INDEX idx_reference (reference_type, reference_id),
    INDEX idx_created_at (created_at)
);
```

### seller_withdrawal_requests Table

```sql
CREATE TABLE seller_withdrawal_requests (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    seller_id BIGINT UNSIGNED NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    balance_before DECIMAL(10,2) DEFAULT 0,
    balance_after DECIMAL(10,2) NULL COMMENT 'Balance after withdrawal (set when approved)',

    -- Bank details
    account_number VARCHAR(255) NOT NULL,
    bank_ifsc_code VARCHAR(255) NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    bank_name VARCHAR(255) NOT NULL,
    branch_name VARCHAR(255) NULL,

    -- Status tracking
    status ENUM('pending', 'approved', 'rejected', 'processing', 'completed') DEFAULT 'pending',
    seller_note TEXT NULL COMMENT 'Seller note with withdrawal request',
    admin_note TEXT NULL COMMENT 'Admin note for rejection or approval',

    -- Processing details
    processed_by BIGINT UNSIGNED NULL COMMENT 'Admin ID who processed',
    processed_at TIMESTAMP NULL,
    payment_method VARCHAR(255) NULL COMMENT 'NEFT, RTGS, UPI, etc.',
    transaction_reference VARCHAR(255) NULL COMMENT 'Bank transaction reference number',

    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,

    INDEX idx_seller_id (seller_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);
```

---

## Integration Points

### Files Modified for Auto-Credit

1. **app/Http/Controllers/API/OrdersApiController.php**
   - `updateStatus()`: Lines 855-862 - Credits wallet on regular delivery
   - `updateItemsStatus()`: Lines 1024-1027 - Credits wallet on individual item delivery
   - `updateSelfPickupOrderStatus()`: Lines 1112-1121 - Credits wallet on self-pickup completion

2. **app/Http/Controllers/SellerWalletController.php**
   - `creditOrderAmount()`: Static method that handles the actual crediting logic

### Notification Integration

When order status changes trigger wallet credits, the existing notification system is used:
- Sellers receive push notifications about order delivery
- Transaction appears in their wallet immediately
- No separate wallet credit notification is sent (to avoid duplicate notifications)

---

## Error Handling

### Common Error Codes

```json
{
    "status": 0,
    "message": "Error message here"
}
```

### Possible Error Messages

1. **Unauthorized seller**: Token is invalid or missing
2. **Seller not found**: Seller record doesn't exist
3. **Insufficient balance**: Withdrawal amount exceeds current balance
4. **Minimum withdrawal amount is ₹X**: Withdrawal below minimum threshold
5. **Validation errors**: Missing or invalid required fields
6. **Something went wrong**: General server error (check logs)

---

## Testing Checklist

### Auto-Credit Testing

- [ ] Create order and mark as delivered - verify wallet credited
- [ ] Update individual order item status to delivered - verify wallet credited
- [ ] Create self-pickup order and mark as picked up - verify wallet credited
- [ ] Verify commission is deducted correctly
- [ ] Verify duplicate prevention works (update status twice)
- [ ] Check balance_before and balance_after are recorded correctly
- [ ] Verify transaction record created with correct reference_type and reference_id

### Withdrawal Testing

- [ ] Create withdrawal request with valid amount
- [ ] Try withdrawal with insufficient balance - should fail
- [ ] Try withdrawal below minimum amount - should fail
- [ ] Verify withdrawal request appears in list
- [ ] Filter withdrawal requests by status
- [ ] Admin approval flow (requires admin panel implementation)

### Statistics Testing

- [ ] Verify earnings summary shows correct totals
- [ ] Check today's earnings calculation
- [ ] Check monthly earnings calculation
- [ ] Check yearly earnings calculation
- [ ] Verify transaction history pagination
- [ ] Test transaction filters (type, date range)

---

## Migration Instructions

1. **Backup Database**: Always backup before running migrations
   ```bash
   php artisan backup:db
   ```

2. **Run Migration**:
   ```bash
   php artisan migrate
   ```

3. **Verify Tables Created**:
   ```bash
   php artisan tinker
   >>> DB::table('seller_wallet_transactions')->count();
   >>> DB::table('seller_withdrawal_requests')->count();
   ```

4. **Check Existing Data**: If sellers already have a `balance` column, the new system will use that as the starting point.

---

## Future Enhancements

### Potential Features

1. **Admin Panel APIs**:
   - ✅ Approve/reject withdrawal requests (Implemented)
   - Manual wallet adjustments
   - Bulk withdrawal processing
   - Wallet reports and analytics

2. **Notifications**:
   - Withdrawal request status updates
   - Low balance warnings
   - Weekly/monthly earnings summary

3. **Advanced Features**:
   - Scheduled automatic withdrawals
   - Multiple bank accounts per seller
   - Wallet to wallet transfers
   - Referral earnings tracking
   - Tax deduction certificates

4. **Reporting**:
   - Export transaction history as CSV/PDF
   - Tax reports
   - Commission reports
   - Monthly statements

---

## Support and Troubleshooting

### Common Issues

**Issue**: Wallet not credited after order delivery
- **Check**: Verify order status is exactly 6 (delivered) or 11 (self-pickup picked)
- **Check**: Verify order item is not cancelled or returned
- **Check**: Check application logs for errors
- **Check**: Verify seller_id exists in sellers table

**Issue**: Duplicate credits appearing
- **Solution**: The system has built-in duplicate prevention, but if this occurs, check the `creditOrderAmount()` method logic

**Issue**: Incorrect commission calculation
- **Check**: Verify seller's commission percentage in `sellers.commission` field
- **Check**: Verify order item's `discounted_price` and `quantity` fields

### Logs to Check

```bash
# Laravel log file
tail -f storage/logs/laravel.log

# Look for wallet-related errors
grep -i "wallet" storage/logs/laravel.log
grep -i "credit" storage/logs/laravel.log
```

---

## Contact

For questions or issues related to the Seller Wallet System, please contact the development team or create an issue in the project repository.
