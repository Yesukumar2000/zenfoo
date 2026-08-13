# Paytm Dashboard Configuration Guide

## Overview
This guide explains how to configure the callback URL in your Paytm Merchant Dashboard for both Test and Production environments.

---

## Your Callback URL

```
https://wheat-rook-708688.hostingersite.com/api/paytm/callback
```

---

## Configuration Steps

### 1. Login to Paytm Merchant Dashboard

**Test/Staging Environment:**
- URL: https://dashboard.paytm.com/next/
- Use your test merchant credentials

**Production Environment:**
- URL: https://dashboard.paytm.com/
- Use your live merchant credentials

---

### 2. Navigate to Developer Settings

1. After login, look for **"Developer Settings"** or **"API Configuration"** in the left sidebar
2. Click on **"API Keys"** or **"Webhooks/Callback Settings"**

Alternative path:
- **Dashboard** → **Settings** → **API Configuration** → **Webhooks**

---

### 3. Configure Callback URL

#### Option A: Webhook Configuration (Recommended)

1. Find the **"Webhook URL"** or **"Callback URL"** section
2. Click **"Add URL"** or **"Edit"**
3. Enter your callback URL:
   ```
   https://wheat-rook-708688.hostingersite.com/api/paytm/callback
   ```
4. Save the configuration

#### Option B: Per-Transaction Callback (Alternative)

If webhooks are not available, Paytm allows setting callback URL per transaction:
- This is already handled in your code at [OrderApiController.php:3075](app/Http/Controllers/API/Customer/OrderApiController.php#L3075)
- The callback URL is sent with each transaction request

---

### 4. Whitelist Your Domain

**Important:** You must whitelist your server's domain/IP for security.

1. Navigate to **"Security Settings"** or **"Whitelisted Domains"**
2. Add your domain:
   ```
   wheat-rook-708688.hostingersite.com
   ```
3. Add your server IP address (if required)
4. Save the changes

---

### 5. Enable Callback Notifications

1. Ensure **"Enable Webhook"** or **"Enable Callback Notifications"** is turned **ON**
2. Select which events to receive callbacks for:
   - ✅ Payment Success
   - ✅ Payment Failure
   - ✅ Refund Success
   - ✅ Refund Failure

---

### 6. Configure Response Mode

1. Set **Response Mode** to: **POST**
2. Set **Response Format** to: **JSON** (if available)

---

### 7. Save and Test

1. Click **"Save"** or **"Update"**
2. Use the **"Test Webhook"** button if available
3. Paytm will send a test callback to your URL
4. Check your logs to verify receipt:
   ```bash
   tail -f storage/logs/production-*.log | grep "Paytm: Callback"
   ```

---

## Configuration for Both Environments

You need to configure callbacks in **BOTH** test and production environments:

### Test Environment
- Merchant ID: `eMmqJZ59036384322689`
- Dashboard: https://dashboard.paytm.com/next/
- Callback URL: `https://wheat-rook-708688.hostingersite.com/api/paytm/callback`

### Production Environment (When going live)
- Merchant ID: [Your Live Merchant ID]
- Dashboard: https://dashboard.paytm.com/
- Callback URL: `https://wheat-rook-708688.hostingersite.com/api/paytm/callback` (or your production domain)

---

## Verification Checklist

After configuration, verify the following:

- [ ] Callback URL is correctly entered in Paytm dashboard
- [ ] Domain is whitelisted
- [ ] Webhook/Callback is enabled
- [ ] Response mode is set to POST
- [ ] Test webhook sent successfully
- [ ] Your server logs show callback receipt
- [ ] Callback route is accessible (test with Postman)
- [ ] HTTPS is enabled on your domain (required by Paytm)
- [ ] No firewall blocking Paytm's callback requests

---

## Test Your Callback URL

### Method 1: Using Paytm's Test Function
1. In Paytm Dashboard, use the **"Test Webhook"** button
2. Check your application logs for callback receipt

### Method 2: Using Postman/cURL
```bash
curl -X POST https://wheat-rook-708688.hostingersite.com/api/paytm/callback \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "ORDERID=TEST_ORDER_123&TXNID=TEST_TXN_456&STATUS=TXN_SUCCESS&TXNAMOUNT=100.00"
```

### Method 3: Check Application Logs
```bash
# SSH into your server and run:
tail -f storage/logs/production-*.log | grep "Paytm: Callback"
```

You should see log entries like:
```
[2026-03-09 16:51:10] production.INFO: Paytm: Callback received {"request_id":"paytm_callback_...","all_data":{...}}
```

---

## Common Issues & Solutions

### Issue 1: Callback Not Received
**Solution:**
- Verify URL is whitelisted in Paytm dashboard
- Check firewall/server settings
- Ensure HTTPS is enabled
- Check if domain is accessible from Paytm's servers

### Issue 2: Checksum Mismatch
**Solution:**
- Verify merchant key in your settings matches Paytm dashboard
- Check environment (test vs live) credentials

### Issue 3: 404 Error on Callback
**Solution:**
- Run `php artisan route:cache` to refresh routes
- Verify route is registered: `php artisan route:list | grep paytm`
- Check web server configuration (Apache/Nginx)

### Issue 4: Authentication Error
**Solution:**
- Callback route should NOT require authentication
- Paytm server won't have auth tokens
- Our route is correctly configured without auth middleware

---

## Paytm Callback Parameters

Your callback will receive these parameters:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `ORDERID` | Your order ID | `ONLINE_PAYMENT_ORDER_40_...` |
| `TXNID` | Paytm transaction ID | `202603091651...` |
| `STATUS` | Payment status | `TXN_SUCCESS`, `TXN_FAILURE` |
| `TXNAMOUNT` | Transaction amount | `563.00` |
| `PAYMENTMODE` | Payment method | `UPI`, `CARD`, `WALLET` |
| `BANKNAME` | Bank name | `HDFC`, `ICICI`, etc. |
| `BANKTXNID` | Bank transaction ID | `BNK123456...` |
| `CHECKSUMHASH` | Security checksum | `abc123...` |
| `RESPCODE` | Response code | `01` (success) |
| `RESPMSG` | Response message | `Txn Success` |
| `TXNDATE` | Transaction date | `2026-03-09 16:51:10` |
| `GATEWAYNAME` | Gateway used | `HDFC` |

---

## Security Best Practices

1. **Always verify checksum** - Our code does this automatically
2. **Use HTTPS only** - Paytm requires secure connections
3. **Whitelist Paytm IPs** - Add Paytm's server IPs to your firewall allowlist
4. **Log all callbacks** - Our code logs everything for audit
5. **Rate limiting** - Consider adding rate limiting to prevent abuse
6. **IP validation** - Optionally validate callbacks come from Paytm's IPs

---

## Support & Documentation

**Paytm Developer Documentation:**
- Main Docs: https://developer.paytm.com/docs/
- Integration Guide: https://developer.paytm.com/docs/all-in-one-sdk/
- API Reference: https://developer.paytm.com/docs/api/

**Paytm Support:**
- Email: developer@paytm.com
- Support Portal: https://paytm.com/care/

**Your Implementation:**
- Callback Handler: [PaytmPaymentController.php:566-762](app/Http/Controllers/API/PaytmPaymentController.php#L566-L762)
- Callback Route: [routes/api.php:954](routes/api.php#L954)
- Callback URL: `https://wheat-rook-708688.hostingersite.com/api/paytm/callback`

---

## Need Help?

If you encounter any issues:
1. Check application logs: `storage/logs/production-*.log`
2. Verify Paytm dashboard configuration
3. Test callback manually with Postman
4. Contact Paytm support if needed
5. Review this documentation

---

*Last Updated: 2026-03-09*
*Environment: Test (Staging)*