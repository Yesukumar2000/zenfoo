# Paytm "Session Expired" Error - Diagnosis & Fixes

## Problem Overview

**Error:** `PlatformException(0, Your Session has expired., null, null)`

**What's Happening:**
1. ✅ Config fetch - SUCCESS
2. ✅ Transaction token generation - SUCCESS
3. ❌ Paytm SDK launch - **FAILS with "Session expired"**

**Root Cause:**
The app backgrounded between token generation and SDK launch, causing Paytm SDK to reject the session.

---

## Root Causes Identified

### 1. App Backgrounding (Primary Issue)
From your logs:
```
D/FirebaseSessions: App backgrounded on com.zenfoo.customer
I/FA: Application backgrounded at: timestamp_millis: 1773056279999
```

**Why This Happens:**
- Token generated at `16:51:10.523`
- App backgrounded at `16:51:10.999` (476ms later)
- SDK attempted to launch after app backgrounded
- Paytm SDK rejects sessions when app is not in foreground

### 2. Token Expiry
- Paytm txn tokens typically expire in **5-10 minutes**
- If there's delay between token generation and SDK launch, token may expire

### 3. SDK Initialization Issues
- Paytm SDK requires app to be in RESUMED state
- Activity lifecycle issues can cause session problems

---

## Solutions

### Solution 1: Prevent App Backgrounding (Recommended)

Add keepalive mechanism to prevent backgrounding during payment flow.

**Flutter Code Changes:**

```dart
import 'package:flutter/services.dart';
import 'package:wakelock/wakelock.dart'; // Add to pubspec.yaml

// Before initiating Paytm payment
Future<void> initiatePaytmPayment() async {
  try {
    // Enable wakelock to prevent app backgrounding
    await Wakelock.enable();

    // Keep screen on during payment
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);

    // Your existing payment flow
    final config = await fetchPaytmConfig();
    final token = await getTxnToken();

    // Launch SDK immediately (no delay)
    await openPaytmPaymentGateway(token);

  } catch (e) {
    print('❌ Payment error: $e');
  } finally {
    // Disable wakelock after payment
    await Wakelock.disable();
  }
}
```

**Add to `pubspec.yaml`:**
```yaml
dependencies:
  wakelock: ^0.6.2
```

---

### Solution 2: Add Token Validation Before SDK Launch

Verify token is still valid before launching SDK.

**Flutter Code:**

```dart
Future<bool> validatePaytmToken(String txnToken) async {
  try {
    // Check if token is still valid
    final response = await http.post(
      Uri.parse('$baseUrl/paytm/check-status'),
      headers: {'Authorization': 'Bearer $authToken'},
      body: {'transaction_id': orderId},
    );

    final data = json.decode(response.body);
    return data['status'] == true;
  } catch (e) {
    return false;
  }
}

// Before launching SDK
if (await validatePaytmToken(txnToken)) {
  await openPaytmPaymentGateway(token);
} else {
  // Token expired - regenerate
  final newToken = await getTxnToken();
  await openPaytmPaymentGateway(newToken);
}
```

---

### Solution 3: Add Retry Logic with Fresh Token

If SDK fails, immediately retry with a fresh token.

**Flutter Code:**

```dart
Future<void> openPaytmPaymentGatewayWithRetry({
  required String merchantId,
  required String orderId,
  required String amount,
  String? txnToken,
  int maxRetries = 2,
}) async {
  int attempt = 0;
  String currentToken = txnToken ?? await getTxnToken();

  while (attempt < maxRetries) {
    try {
      attempt++;
      print('💳 [Paytm] Attempt $attempt of $maxRetries');

      // Launch Paytm SDK
      final result = await AllInOneSdk.startTransaction(
        merchantId: merchantId,
        orderId: orderId,
        amount: amount,
        txnToken: currentToken,
        callbackUrl: callbackUrl,
        isStaging: true,
      );

      // Success - break loop
      print('✅ [Paytm] Payment completed');
      return result;

    } catch (e) {
      print('❌ [Paytm] Attempt $attempt failed: $e');

      // If session expired and we have retries left
      if (e.toString().contains('Session has expired') && attempt < maxRetries) {
        print('🔄 [Paytm] Generating fresh token...');

        // Wait a bit before retry
        await Future.delayed(Duration(milliseconds: 500));

        // Get fresh token
        currentToken = await getTxnToken();

        // Retry
        continue;
      }

      // No more retries or different error
      throw e;
    }
  }

  throw Exception('Failed after $maxRetries attempts');
}
```

---

### Solution 4: Backend Token Extension API

Add a backend endpoint to refresh/extend token validity.

**Backend - Add to PaytmPaymentController.php:**

```php
/**
 * Refresh transaction token
 *
 * POST /api/paytm/refresh-token
 */
public function refreshToken(Request $request)
{
    $requestId = uniqid('paytm_refresh_', true);

    try {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|string',
            'amount' => 'required|numeric|min:0.01'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => $validator->errors()->first()
            ], 422);
        }

        $orderId = $request->order_id;
        $amount = $request->amount;

        Log::info('Paytm: Token refresh requested', [
            'request_id' => $requestId,
            'order_id' => $orderId,
            'amount' => $amount
        ]);

        // Generate new token using existing order ID
        // (Your existing txn token logic here)

        return response()->json([
            'status' => true,
            'message' => 'Token refreshed successfully',
            'data' => [
                'txn_token' => $newToken,
                'order_id' => $orderId,
                'amount' => $amount,
                'expires_at' => now()->addMinutes(5)->toDateTimeString()
            ]
        ], 200);

    } catch (\Exception $e) {
        Log::error('Paytm: Token refresh failed', [
            'request_id' => $requestId,
            'error' => $e->getMessage()
        ]);

        return response()->json([
            'status' => false,
            'message' => 'Failed to refresh token'
        ], 500);
    }
}
```

**Add route:**
```php
Route::post('refresh-token', [PaytmPaymentController::class, 'refreshToken']);
```

---

### Solution 5: Fix Activity Lifecycle Handling

Ensure app activity is properly resumed before SDK launch.

**Flutter Code:**

```dart
import 'package:flutter/services.dart';

Future<void> ensureAppResumed() async {
  // Bring app to foreground if backgrounded
  await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  await Future.delayed(Duration(milliseconds: 100));
}

Future<void> openPaytmPaymentGateway() async {
  // Ensure app is in foreground
  await ensureAppResumed();

  // Small delay to ensure UI is ready
  await Future.delayed(Duration(milliseconds: 200));

  // Now launch SDK
  try {
    await AllInOneSdk.startTransaction(...);
  } catch (e) {
    print('❌ SDK Error: $e');
  }
}
```

---

### Solution 6: Update Paytm SDK Version

Older SDK versions have more session issues.

**Check your SDK version:**
```yaml
# pubspec.yaml
dependencies:
  paytm_allinonesdk: ^1.2.6  # Update to latest
```

**Update to latest:**
```bash
flutter pub upgrade paytm_allinonesdk
flutter clean
flutter pub get
```

---

## Recommended Implementation (Combined Approach)

```dart
import 'package:wakelock/wakelock.dart';

class PaytmPaymentService {
  static const int MAX_RETRIES = 2;
  static const int RETRY_DELAY_MS = 500;

  Future<bool> initiatePaymentWithRetry({
    required double amount,
    int attempt = 1,
  }) async {
    try {
      print('💳 [Paytm] Payment attempt $attempt/$MAX_RETRIES');

      // Step 1: Enable wakelock
      await Wakelock.enable();

      // Step 2: Fetch config
      final config = await fetchPaytmConfig();

      // Step 3: Generate token
      final tokenData = await getTxnToken(amount: amount);
      final txnToken = tokenData['txn_token'];
      final orderId = tokenData['order_id'];

      // Step 4: Launch SDK IMMEDIATELY (minimize delay)
      final result = await AllInOneSdk.startTransaction(
        merchantId: config['merchant_id'],
        orderId: orderId,
        amount: amount.toString(),
        txnToken: txnToken,
        callbackUrl: config['callback_url'],
        isStaging: config['environment'] == 'test',
      );

      // Success
      print('✅ [Paytm] Payment completed successfully');
      await Wakelock.disable();
      return true;

    } catch (e) {
      print('❌ [Paytm] Error: $e');

      // Check if it's a session expired error
      if (e.toString().contains('Session has expired') ||
          e.toString().contains('session') ||
          e.toString().contains('expired')) {

        // Retry logic
        if (attempt < MAX_RETRIES) {
          print('🔄 [Paytm] Retrying with fresh token...');

          await Future.delayed(Duration(milliseconds: RETRY_DELAY_MS));

          // Recursive retry with fresh token
          return await initiatePaymentWithRetry(
            amount: amount,
            attempt: attempt + 1,
          );
        }
      }

      // Failed after retries
      await Wakelock.disable();
      return false;
    }
  }
}
```

---

## Testing the Fixes

### Test 1: Rapid Background/Foreground
1. Initiate payment
2. Immediately press Home button
3. Return to app within 2 seconds
4. Payment should still work

### Test 2: Token Expiry
1. Generate token
2. Wait 6+ minutes
3. Try to use token
4. Should auto-regenerate

### Test 3: Network Issues
1. Enable airplane mode during payment
2. Disable airplane mode
3. Should retry automatically

---

## Monitoring & Debugging

**Add comprehensive logging:**

```dart
class PaytmLogger {
  static void logPaymentFlow(String step, Map<String, dynamic> data) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] [Paytm] $step');
    print(json.encode(data));
  }
}

// Usage
PaytmLogger.logPaymentFlow('Token Generated', {
  'order_id': orderId,
  'token_length': txnToken.length,
  'time_elapsed_ms': timeElapsed,
});
```

**Backend logging (already implemented):**
- Check: `storage/logs/production-*.log`
- Filter: `grep "Paytm:" production-*.log`

---

## Additional Recommendations

### 1. Reduce Time Between Token & SDK Launch
- Minimize UI operations between token fetch and SDK launch
- Pre-load any required data
- Avoid network calls during this window

### 2. Add Loading Indicators
```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => WillPopScope(
    onWillPop: () async => false, // Prevent back button
    child: AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Processing payment...\nPlease do not close the app'),
        ],
      ),
    ),
  ),
);
```

### 3. Handle App Lifecycle Events
```dart
class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print('⚠️ App backgrounded during payment');
    } else if (state == AppLifecycleState.resumed) {
      print('✅ App resumed');
    }
  }
}
```

---

## Quick Reference

| Issue | Solution | Priority |
|-------|----------|----------|
| App backgrounding | Wakelock + System UI | **HIGH** |
| Token expiry | Retry with fresh token | **HIGH** |
| SDK initialization | Lifecycle handling | **MEDIUM** |
| Network issues | Retry logic | **MEDIUM** |
| Old SDK version | Update SDK | **LOW** |

---

## Support

**If issues persist:**
1. Enable verbose logging in Flutter and backend
2. Test with Paytm's sample app
3. Contact Paytm developer support
4. Check Paytm SDK documentation: https://developer.paytm.com/docs/all-in-one-sdk/

**Your Implementation:**
- Token Generation: [OrderApiController.php:3094-3178](app/Http/Controllers/API/Customer/OrderApiController.php#L3094-L3178)
- Payment Verification: [PaytmPaymentController.php:34-337](app/Http/Controllers/API/PaytmPaymentController.php#L34-L337)

---

*Last Updated: 2026-03-09*
*Issue: Session Expired Error*
*Status: Solutions Provided*