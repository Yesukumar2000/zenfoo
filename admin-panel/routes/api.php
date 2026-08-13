<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Laravel\Passport\Passport;
use App\Http\Controllers\CategoryTypeController;
use App\Http\Controllers\API\Seller\BulkProductUploadController as SellerBulkProductUploadController;
use App\Http\Controllers\API\AdminBulkProductUploadController;
use App\Services\FirestoreDeliveryBoyService;
use App\Http\Controllers\API\TestNotificationController;
use App\Http\Controllers\API\OrderArrivalTimeController;
// Download sample bulk upload Excel file (no auth required)
Route::get('download/sample-bulk-upload', function () {
    $path = public_path('sample_excel_zenfoo_product.xlsx');
    if (!file_exists($path)) {
        return response()->json(['message' => 'File not found.'], 404);
    }
    return response()->download($path, 'sample_excel_zenfoo_product.xlsx', [
        'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ]);
});

// Public FAQ by role
Route::get('faqs/by-role', [\App\Http\Controllers\API\FaqsApiController::class, 'getByRole'])->name('faqs.by-role');

// Public: Get banners by type (no auth required)
Route::get('home_slider_images/by_type', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'getByType']);

// Public: Get cities/zones (no auth required)
Route::get('public/cities', [\App\Http\Controllers\API\CityApiController::class, 'getCities']);

// Seller Agreement APIs (with auth)
Route::middleware('auth:api')->post('seller/agreement/download', [\App\Http\Controllers\API\SellerAgreementController::class, 'downloadAgreement']);
Route::middleware('auth:api')->post('seller/agreement/upload', [\App\Http\Controllers\API\Seller\AgreementController::class, 'uploadAgreement']);
Route::middleware('auth:api')->get('seller/agreement/download-uploaded', [\App\Http\Controllers\API\Seller\AgreementController::class, 'downloadUploadedAgreement']);
Route::middleware('auth:api')->get('seller/agreement/status', [\App\Http\Controllers\API\Seller\AgreementController::class, 'getAgreementStatus']);

// Test Notification Routes
Route::get('test/notification', [TestNotificationController::class, 'testAdminNotification']);
Route::get('test/notification/order', [TestNotificationController::class, 'testNewOrderNotification']);
Route::get('test/admin-tokens', [TestNotificationController::class, 'listAdminTokens']);

// Test route for available delivery boys near order sellers (with Firestore sync)
Route::get('test/available-drivers/{order_id}', function ($order_id) {
    $radiusKm = request()->input('radius', 10);

    $result = FirestoreDeliveryBoyService::getAndSyncAvailableDeliveryBoys(
        (int) $order_id,
        (float) $radiusKm
    );

    return response()->json([
        'status' => 1,
        'message' => 'Available delivery boys fetched and synced to Firestore',
        'order_id' => $order_id,
        'radius_km' => $radiusKm,
        'total_on_ride' => count($result['on_ride']),
        'total_not_on_ride' => count($result['not_on_ride']),
        'on_ride' => $result['on_ride'],
        'not_on_ride' => $result['not_on_ride'],
        'firestore_sync' => $result['firestore_sync']
    ]);
});

// Order Arrival Time Routes (for testing ETA calculations)
Route::get('test/order-arrival-time', [OrderArrivalTimeController::class, 'getTrackingByOrderId']);
Route::get('test/order-arrival-time/calculate', [OrderArrivalTimeController::class, 'calculateArrivalTime']);

// Seller Wallet APIs
Route::middleware('auth:api')->get('seller/wallet/overview', [\App\Http\Controllers\SellerWalletController::class, 'getWalletOverview']);
Route::middleware('auth:api')->get('seller/wallet/transactions', [\App\Http\Controllers\SellerWalletController::class, 'getTransactionHistory']);
Route::middleware('auth:api')->post('seller/wallet/withdrawal-request', [\App\Http\Controllers\SellerWalletController::class, 'createWithdrawalRequest']);
Route::middleware('auth:api')->get('seller/wallet/withdrawal-requests', [\App\Http\Controllers\SellerWalletController::class, 'getWithdrawalRequests']);
Route::middleware('auth:api')->get('seller/wallet/earnings-summary', [\App\Http\Controllers\SellerWalletController::class, 'getEarningsSummary']);

// Seller Support Chat (Seller -> Admin)
Route::middleware('auth:api')->group(function () {
    Route::group(['prefix' => 'seller/support-chat'], function () {
        Route::post('/send', [\App\Http\Controllers\API\AdminSellerChatController::class, 'sellerSendMessage']);
        Route::post('/order/send', [\App\Http\Controllers\API\AdminSellerChatController::class, 'sellerSendOrderMessage']);
        Route::get('/messages', [\App\Http\Controllers\API\AdminSellerChatController::class, 'sellerGetMessages']);
    });
});

// Admin Withdrawal Request Actions
Route::middleware('auth:api')->post('admin/wallet/withdrawal-request/{requestId}/approve', [\App\Http\Controllers\SellerWalletController::class, 'approveWithdrawalRequest']);
Route::middleware('auth:api')->post('admin/wallet/withdrawal-request/{requestId}/reject', [\App\Http\Controllers\SellerWalletController::class, 'rejectWithdrawalRequest']);

// Seller Transactions API (Admin view)
Route::middleware('auth:api')->get('seller/{sellerId}/transactions', [\App\Http\Controllers\API\SellerTransactionsController::class, 'index']);
Route::middleware('auth:api')->get('seller/{sellerId}/transactions/paid', [\App\Http\Controllers\API\SellerTransactionsController::class, 'paid']);
Route::middleware('auth:api')->get('seller/{sellerId}/transactions/need-to-pay', [\App\Http\Controllers\API\SellerTransactionsController::class, 'needToPay']);
Route::middleware('auth:api')->get('seller/{sellerId}/transactions/weekly', [\App\Http\Controllers\API\SellerTransactionsController::class, 'weeklyPayment']);
Route::middleware('auth:api')->get('sellers/pending-payouts-batch', [\App\Http\Controllers\API\SellerTransactionsController::class, 'getPendingPayoutsBatch']);
Route::middleware('auth:api')->get('seller/{sellerId}/pending-payouts', [\App\Http\Controllers\API\SellerTransactionsController::class, 'getPendingPayouts']);
Route::middleware('auth:api')->post('seller/{sellerId}/settle-pending-payouts', [\App\Http\Controllers\API\SellerTransactionsController::class, 'settlePendingPayouts']);
Route::middleware('auth:api')->post('seller/{sellerId}/transactions/mark-paid', [\App\Http\Controllers\API\SellerTransactionsController::class, 'markAsPaid']);
Route::middleware('auth:api')->get('seller/{sellerId}/transactions/{transactionId}', [\App\Http\Controllers\API\SellerTransactionsController::class, 'show']);
Route::middleware('auth:api')->get('seller/{sellerId}/bank-details', [\App\Http\Controllers\API\SellerTransactionsController::class, 'getBankDetails']);
Route::middleware('auth:api')->post('seller/{sellerId}/settle-payouts', [\App\Http\Controllers\API\SellerTransactionsController::class, 'settlePayouts']);

// Settings API
Route::middleware('auth:api')->get('settings', [\App\Http\Controllers\API\SettingsController::class, 'index']);
Route::middleware('auth:api')->post('settings/update', [\App\Http\Controllers\API\SettingsController::class, 'update']);
Route::middleware('auth:api')->post('settings/bulk-update', [\App\Http\Controllers\API\SettingsController::class, 'bulkUpdate']);
Route::middleware('auth:api')->post('settings/upload-video', [\App\Http\Controllers\API\SettingsController::class, 'uploadVideo']);
Route::middleware('auth:api')->post('settings/upload-image', [\App\Http\Controllers\API\SettingsController::class, 'uploadImage']);
Route::middleware('auth:api')->post('settings/upload-media', [\App\Http\Controllers\API\SettingsController::class, 'uploadMedia']);
Route::middleware('auth:api')->post('settings/test-s3', [\App\Http\Controllers\API\SettingsController::class, 'testS3']);

// Public Settings API (No Auth)
Route::get('support-contacts', [\App\Http\Controllers\API\SettingsController::class, 'supportContacts']);
Route::get('emergency-contacts', [\App\Http\Controllers\API\SettingsController::class, 'emergencyContacts']);

// Public Weather API (No Auth)
Route::post('weather/rain-check', [\App\Http\Controllers\API\DeliveryBoy\WeatherController::class, 'checkRain']);

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::group(['prefix' => 'install'], function () {

    Route::get('check-composer-updates', [\App\Http\Controllers\InstallController::class, 'checkUpdates'])->name('checkComposerUpdates');
    Route::get('requirements', [\App\Http\Controllers\InstallController::class, 'getRequirements']);
    Route::post('database', [\App\Http\Controllers\InstallController::class, 'setDatabase']);
    Route::post('purchase_code', [\App\Http\Controllers\InstallController::class, 'checkPurchaseCode']);
});

Route::post('login', [\App\Http\Controllers\API\AdminAuthController::class, 'login']);
Route::middleware('auth:api')->post('logout', [\App\Http\Controllers\API\AdminAuthController::class, 'logout']);
Route::post('forget-password', [\App\Http\Controllers\API\AdminAuthController::class, 'forgetPassword'])->name('forget-password');
Route::post('reset-password', [\App\Http\Controllers\API\AdminAuthController::class, 'resetPassword'])->name('reset-password');
Route::get('system_languages', [\App\Http\Controllers\API\LanguageApiController::class, 'getSystemLanguages']);

Route::post('seller/register', [\App\Http\Controllers\API\AdminAuthController::class, 'sellerRegister']);
Route::get('seller/privacy_policy', [\App\Http\Controllers\SellerController::class, 'getPrivacyPolicy']);
Route::get('seller/cities', [\App\Http\Controllers\API\CityApiController::class, 'getCities']);

Route::post('delivery_boy/register', [\App\Http\Controllers\API\AdminAuthController::class, 'deliveryBoyRegister']);

// Delivery Boy OTP Authentication
Route::post('delivery-boy/send-otp', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'sendOtp']);
Route::post('delivery-boy/verify-otp', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'verifyOtp']);
Route::middleware('auth:api')->post('delivery_boy/update-personal-details', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'updatePersonalDetails'])->name('delivery_boy.update_personal_details');

Route::post('delivery_boy/privacy_policy', [\App\Http\Controllers\DeliveryBoyController::class, 'getPrivacyPolicy']);
Route::get('delivery_boy/cities', [\App\Http\Controllers\API\CityApiController::class, 'getCities']);

// Delivery Boy UPI Verification APIs
Route::middleware('auth:api')->post('delivery-boy/upi/verify', [\App\Http\Controllers\API\DeliveryBoyUpiVerificationController::class, 'verifyUpi']);
Route::middleware('auth:api')->get('delivery-boy/upi/status', [\App\Http\Controllers\API\DeliveryBoyUpiVerificationController::class, 'getVerificationStatus']);
Route::middleware('auth:api')->post('delivery-boy/upi/re-verify', [\App\Http\Controllers\API\DeliveryBoyUpiVerificationController::class, 'reVerifyUpi']);

// Delivery Boy Order APIs (no auth required)
Route::get('delivery-boy/orders/seller-locations', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'getSellerLocations']);

// Delivery Boy Active Offers Test (no auth - pass delivery_boy_id as query param)
Route::get('delivery_boy/active-offers-test', [\App\Http\Controllers\API\DeliveryBoy\IncentiveOfferController::class, 'getActiveOffersTest']);

// Delivery Boy Order APIs (auth required)
Route::middleware('auth:api')->post('delivery-boy/orders/accept', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'acceptOrder']);
Route::middleware('auth:api')->get('delivery-boy/orders/seller-details', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'getSellerOrderDetails']);
Route::middleware('auth:api')->post('delivery-boy/orders/mark-picked', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'markAsDriverPicked']);
Route::middleware('auth:api')->get('delivery-boy/orders/summary', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'getOrderSummary']);
Route::middleware('auth:api')->post('delivery-boy/orders/collect-cash', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'collectCash']);
Route::middleware('auth:api')->post('delivery-boy/orders/mark-delivered', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'markDelivered']);
Route::middleware('auth:api')->post('delivery-boy/orders/settle-cash', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'settleCash']);
Route::middleware('auth:api')->post('delivery-boy/orders/verify-pin', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'verifyDeliveryPin']);
Route::middleware('auth:api')->post('delivery-boy/orders/notify-arrival', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'notifyArrival']);
Route::middleware('auth:api')->get('delivery-boy/trip-history', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'getTripHistory']);
Route::middleware('auth:api')->get('delivery-boy/order-history', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'getOrderHistory']);

// Delivery Boy QR Code Payment APIs
Route::middleware('auth:api')->post('delivery-boy/orders/generate-qr', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'generateOrderQRCode']);
Route::middleware('auth:api')->get('delivery-boy/merchant-qr', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'getMerchantStaticQR']);

// TEST ONLY - QR Code Generation without auth (DISABLE IN PRODUCTION!)
Route::post('test/generate-qr', [\App\Http\Controllers\API\DeliveryBoy\OrderController::class, 'testGenerateQRCode']);

// Driver Chatbot APIs
Route::middleware('auth:api')->get('delivery-boy/chatbot/questions', [\App\Http\Controllers\API\DeliveryBoy\DriverChatbotController::class, 'getQuestions']);
Route::middleware('auth:api')->post('delivery-boy/chatbot/answer', [\App\Http\Controllers\API\DeliveryBoy\DriverChatbotController::class, 'getAnswer']);

// Seller Ratings API
Route::middleware('auth:api')->get('seller/ratings', [\App\Http\Controllers\API\Seller\RatingController::class, 'getMyRatings']);
Route::middleware('auth:api')->get('seller/product-ratings', [\App\Http\Controllers\API\Seller\RatingController::class, 'getProductRatings']);

// Delivery Boy Ratings API
Route::middleware('auth:api')->get('delivery-boy/ratings', [\App\Http\Controllers\API\DeliveryBoy\RatingController::class, 'getMyRatings']);

// Order Chatting API (Customer <=> Driver <=> Seller)
Route::post('order/chat/send', [\App\Http\Controllers\API\OrderChattingController::class, 'send']);
Route::middleware('auth:api')->get('seller/notifications', [\App\Http\Controllers\API\SellerNotificationApiController::class, 'index']);
Route::post('order/chat/send-auth', [\App\Http\Controllers\API\OrderChatAuthController::class, 'send']);

// Admin Order Chatting API (Admin <=> Customer/Seller/Driver)
Route::post('admin/order/chat/send', [\App\Http\Controllers\API\AdminOrderChatController::class, 'send']);

// Order Chat Support API (Admin Panel - Firestore based)
Route::middleware('auth:api')->group(function () {
    Route::get('order-chat/messages', [\App\Http\Controllers\OrderChatController::class, 'getMessages']);
    Route::post('order-chat/send', [\App\Http\Controllers\OrderChatController::class, 'sendMessage']);
    Route::post('order-chat/mark-read', [\App\Http\Controllers\OrderChatController::class, 'markAsRead']);
    Route::get('order-chat/unread-count', [\App\Http\Controllers\OrderChatController::class, 'getUnreadCount']);
    Route::get('order-chat/all-unread-counts', [\App\Http\Controllers\OrderChatController::class, 'getAllUnreadCounts']);
    Route::get('order-chat/order-sellers', [\App\Http\Controllers\OrderChatController::class, 'getOrderSellers']);
});

// Performance and earnings tracking
Route::middleware('auth:api')->get('delivery-boy/performance/earnings', [\App\Http\Controllers\API\DeliveryBoy\PerformanceController::class, 'getEarningsPerformance'])->name('performance.earnings');
Route::middleware('auth:api')->get('delivery-boy/performance/floating-cash', [\App\Http\Controllers\API\DeliveryBoy\PerformanceController::class, 'getFloatingCash'])->name('performance.floating-cash');
Route::middleware('auth:api')->get('delivery-boy/performance/order-earnings', [\App\Http\Controllers\API\DeliveryBoy\PerformanceController::class, 'getOrderEarnings'])->name('performance.order-earnings');
Route::middleware('auth:api')->get('delivery-boy/performance/multi-order-earnings', [\App\Http\Controllers\API\DeliveryBoy\PerformanceController::class, 'getMultiOrderEarnings'])->name('performance.multi-order-earnings');
Route::middleware('auth:api')->get('delivery-boy/performance/multi-order-detail', [\App\Http\Controllers\API\DeliveryBoy\PerformanceController::class, 'getMultiOrderDetail'])->name('performance.multi-order-detail');
Route::middleware('auth:api')->get('delivery-boy/performance/order-earnings', [\App\Http\Controllers\API\DeliveryBoy\PerformanceController::class, 'getAllOrderEarnings'])->name('performance.order-earnings');
Route::middleware('auth:api')->get('delivery-boy/performance/weekly-summary', [\App\Http\Controllers\API\DeliveryBoy\PerformanceController::class, 'getWeeklySummary'])->name('performance.weekly-summary');
Route::middleware('auth:api')->get('delivery-boy/performance/payout-history', [\App\Http\Controllers\API\DeliveryBoy\PerformanceController::class, 'getPayoutHistory'])->name('performance.payout-history');
Route::middleware('auth:api')->get('delivery-boy/performance/payouts', [\App\Http\Controllers\API\DeliveryBoy\PerformanceController::class, 'getDriverPayouts'])->name('performance.payouts');
Route::middleware('auth:api')->get('delivery-boy/performance/earnings-sections', [\App\Http\Controllers\API\DeliveryBoy\PerformanceController::class, 'getDriverEarningsSections'])->name('performance.earnings-sections');
Route::middleware('auth:api')->get('delivery-boy/hand-cash', [\App\Http\Controllers\API\DeliveryBoy\PerformanceController::class, 'getHandCashDetails'])->name('delivery-boy.hand-cash');
Route::middleware('auth:api')->post('delivery-boy/hand-cash/generate-paytm-token', [\App\Http\Controllers\API\DeliveryBoy\PerformanceController::class, 'generatePaytmTokenForHandCash'])->name('delivery-boy.hand-cash.generate-paytm-token');
Route::middleware('auth:api')->post('delivery-boy/hand-cash/settle', [\App\Http\Controllers\API\DeliveryBoy\PerformanceController::class, 'settleHandCash'])->name('delivery-boy.hand-cash.settle');
Route::middleware('auth:api')->post('delivery-boy/order-cancelled', [\App\Http\Controllers\API\DeliveryBoy\PerformanceController::class, 'orderCancelled'])->name('delivery-boy.order-cancelled');

// Payment status and order blocking
Route::middleware('auth:api')->get('delivery-boy/payment/status', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getDriverPaymentStatus'])->name('payment.status');

// Emergency contacts
Route::middleware('auth:api')->get('delivery-boy/emergency-contacts', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getEmergencyContacts'])->name('emergency-contacts');

// Driver transactions by week
Route::middleware('auth:api')->get('delivery-boy/transactions/by-week', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getDriverTransactionsByWeek'])->name('transactions.by-week');

// Driver issues
Route::middleware('auth:api')->post('delivery-boy/issues/submit', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'submitDriverIssue'])->name('issues.submit');
Route::middleware('auth:api')->get('delivery-boy/issues', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getDriverIssues'])->name('issues.list');

// Not getting orders help screen
Route::middleware('auth:api')->get('delivery-boy/help/not-getting-orders', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getNotGettingOrdersHelp'])->name('help.not-getting-orders');
Route::post('delivery-boy/help/not-getting-orders/save', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'saveNotGettingOrdersHelp'])->name('help.not-getting-orders.save');

// Delivery tips tracking
Route::middleware('auth:api')->get('delivery-boy/tips/weekly', [\App\Http\Controllers\API\DeliveryBoy\DeliveryTipsController::class, 'getWeeklyTips'])->name('tips.weekly');
Route::middleware('auth:api')->get('delivery-boy/tips/daily', [\App\Http\Controllers\API\DeliveryBoy\DeliveryTipsController::class, 'getDailyTips'])->name('tips.daily');
Route::middleware('auth:api')->get('delivery-boy/tips/range', [\App\Http\Controllers\API\DeliveryBoy\DeliveryTipsController::class, 'getRangeTips'])->name('tips.range');

// Multi-order earnings tracking
Route::middleware('auth:api')->get('delivery-boy/earnings/multi-order', [\App\Http\Controllers\API\DeliveryBoy\MultiOrderEarningsController::class, 'getMultiOrderEarnings'])->name('earnings.multi-order');

// Driver location tracking
Route::middleware('auth:api')->get('delivery-boy/location/order-history', [\App\Http\Controllers\API\DeliveryBoy\DriverLocationController::class, 'getOrderLocationHistory'])->name('location.order-history');

// Weather / Rain check
Route::middleware('auth:api')->post('delivery-boy/weather/rain-check', [\App\Http\Controllers\API\DeliveryBoy\WeatherController::class, 'checkRain'])->name('weather.rain-check');
Route::middleware('auth:api')->post('delivery-boy/weather/rain-verify', [\App\Http\Controllers\API\DeliveryBoy\WeatherController::class, 'verifyRain'])->name('weather.rain-verify');

// Manual Payment Routes (Driver pays admin via UPI/Bank)
Route::middleware('auth:api')->get('delivery-boy/admin-payment-details', [\App\Http\Controllers\API\DeliveryBoy\ManualPaymentController::class, 'getAdminPaymentDetails'])->name('manual-payment.admin-details');
Route::middleware('auth:api')->post('delivery-boy/submit-payment-proof', [\App\Http\Controllers\API\DeliveryBoy\ManualPaymentController::class, 'submitPaymentProof'])->name('manual-payment.submit-proof');
Route::middleware('auth:api')->get('delivery-boy/manual-payment-history', [\App\Http\Controllers\API\DeliveryBoy\ManualPaymentController::class, 'getPaymentHistory'])->name('manual-payment.history');

// Driver Support Chat (Driver -> Admin)
Route::middleware('auth:api')->group(function () {
    Route::group(['prefix' => 'delivery-boy/support-chat'], function () {
        Route::post('/send', [\App\Http\Controllers\API\AdminDeliveryBoyChatController::class, 'deliveryBoySendMessage']);
        Route::post('/order/send', [\App\Http\Controllers\API\AdminDeliveryBoyChatController::class, 'deliveryBoySendOrderMessage']);
        Route::get('/messages', [\App\Http\Controllers\API\AdminDeliveryBoyChatController::class, 'deliveryBoyGetMessages']);
    });
});

Route::get('validate', [\App\Http\Controllers\API\AdminAuthController::class, 'validateLogin']);

Route::get('delivery-boy-privacy-policy', [\App\Http\Controllers\API\PrivacyPolicyDeliveryBoyApiController::class, 'printPrivacyPolicy']);
Route::get('delivery-boy-terms-conditions', [\App\Http\Controllers\API\PrivacyPolicyDeliveryBoyApiController::class, 'printTermsConditions']);

Route::get('seller-privacy-policy', [\App\Http\Controllers\API\PrivacyPolicySellerApiController::class, 'printPrivacyPolicy']);
Route::get('seller-terms-conditions', [\App\Http\Controllers\API\PrivacyPolicySellerApiController::class, 'printTermsConditions']);

Route::get('seller/categories', [\App\Http\Controllers\API\CategoryApiController::class, 'getMainCategories']);
Route::get('seller/seller_commission', [\App\Http\Controllers\API\SellerApiController::class, 'getSellerCommission']);

Route::get('role', [\App\Http\Controllers\API\RoleApiController::class, 'index']);

// Role management endpoints — kept at /api/role/* to match the frontend (RoleApiController).
// Authenticated with auth:api. Moved out of the 'admin' prefix group (was /api/admin/role/*).
Route::group(['prefix' => 'role', 'middleware' => ['auth:api']], function () {
    Route::get('permissions', [\App\Http\Controllers\API\RoleApiController::class, 'getPermissions']);
    Route::post('save', [\App\Http\Controllers\API\RoleApiController::class, 'save'])->name('role.save');
    Route::get('edit/{id}', [\App\Http\Controllers\API\RoleApiController::class, 'edit']);
    Route::post('update', [\App\Http\Controllers\API\RoleApiController::class, 'update'])->name('role.update');
    Route::post('delete', [\App\Http\Controllers\API\RoleApiController::class, 'delete'])->name('role.delete');
});

// User Management dashboard (separate from System Users). Authenticated.
Route::group(['prefix' => 'user-management', 'middleware' => ['auth:api']], function () {
    Route::get('overview', [\App\Http\Controllers\API\UserManagementController::class, 'overview']);
    Route::get('security', [\App\Http\Controllers\API\UserManagementController::class, 'security']);
    Route::get('export', [\App\Http\Controllers\API\UserManagementController::class, 'export']);

    // Users
    Route::get('users', [\App\Http\Controllers\API\UserManagementController::class, 'users']);
    Route::post('users/save', [\App\Http\Controllers\API\UserManagementController::class, 'saveUser']);
    Route::post('users/update', [\App\Http\Controllers\API\UserManagementController::class, 'updateUser']);
    Route::post('users/delete', [\App\Http\Controllers\API\UserManagementController::class, 'deleteUser']);
    Route::post('users/toggle-block', [\App\Http\Controllers\API\UserManagementController::class, 'toggleBlock']);

    // Departments
    Route::get('departments', [\App\Http\Controllers\API\UserManagementController::class, 'departments']);
    Route::post('departments/save', [\App\Http\Controllers\API\UserManagementController::class, 'saveDepartment']);
    Route::post('departments/update', [\App\Http\Controllers\API\UserManagementController::class, 'updateDepartment']);
    Route::post('departments/delete', [\App\Http\Controllers\API\UserManagementController::class, 'deleteDepartment']);

    // Activity / Login history / Sessions
    Route::get('activity-logs', [\App\Http\Controllers\API\UserManagementController::class, 'activityLogs']);
    Route::get('login-history', [\App\Http\Controllers\API\UserManagementController::class, 'loginHistory']);
    Route::get('sessions', [\App\Http\Controllers\API\UserManagementController::class, 'sessions']);
    Route::post('sessions/revoke', [\App\Http\Controllers\API\UserManagementController::class, 'revokeSession']);

    // KYC
    Route::get('kyc', [\App\Http\Controllers\API\UserManagementController::class, 'kycList']);
    Route::post('kyc/update-status', [\App\Http\Controllers\API\UserManagementController::class, 'updateKycStatus']);
});

// Rider Analytics dashboard (separate from delivery-boy-analytics). Authenticated.
Route::group(['prefix' => 'rider-analytics', 'middleware' => ['auth:api']], function () {
    Route::get('overview', [\App\Http\Controllers\API\Admin\RiderAnalyticsController::class, 'overview']);
});

// Notification Analytics dashboard (Phase 1 — existing data only). Authenticated.
Route::group(['prefix' => 'notification-analytics', 'middleware' => ['auth:api']], function () {
    Route::get('overview', [\App\Http\Controllers\API\NotificationAnalyticsController::class, 'overview']);
    Route::get('notifications', [\App\Http\Controllers\API\NotificationAnalyticsController::class, 'notifications']);
    Route::get('templates', [\App\Http\Controllers\API\NotificationAnalyticsController::class, 'templates']);
    Route::get('delivery-logs', [\App\Http\Controllers\API\NotificationAnalyticsController::class, 'deliveryLogs']);
    Route::get('subscribers', [\App\Http\Controllers\API\NotificationAnalyticsController::class, 'subscribers']);
});

// Refunds & Disputes analytics (existing data only). Authenticated.
Route::group(['prefix' => 'refund-dispute-analytics', 'middleware' => ['auth:api']], function () {
    Route::get('overview', [\App\Http\Controllers\API\RefundDisputeAnalyticsController::class, 'overview']);
    Route::get('refunds', [\App\Http\Controllers\API\RefundDisputeAnalyticsController::class, 'refunds']);
    Route::get('disputes', [\App\Http\Controllers\API\RefundDisputeAnalyticsController::class, 'disputes']);
    Route::get('reasons', [\App\Http\Controllers\API\RefundDisputeAnalyticsController::class, 'reasons']);
    Route::get('export', [\App\Http\Controllers\API\RefundDisputeAnalyticsController::class, 'export']);
});

// Payouts & Settlement analytics (existing data only). Authenticated.
Route::group(['prefix' => 'payout-settlement-analytics', 'middleware' => ['auth:api']], function () {
    Route::get('overview', [\App\Http\Controllers\API\PayoutSettlementAnalyticsController::class, 'overview']);
    Route::get('rider-payouts', [\App\Http\Controllers\API\PayoutSettlementAnalyticsController::class, 'riderPayouts']);
    Route::get('merchant-settlements', [\App\Http\Controllers\API\PayoutSettlementAnalyticsController::class, 'merchantSettlements']);
    Route::get('payout-requests', [\App\Http\Controllers\API\PayoutSettlementAnalyticsController::class, 'payoutRequests']);
    Route::get('export', [\App\Http\Controllers\API\PayoutSettlementAnalyticsController::class, 'export']);
});

// PhonePe Callback Route (no authentication - called by PhonePe server)
Route::post('phonepe/callback', [\App\Http\Controllers\API\PhonePeController::class, 'callback'])->name('phonepe.callback');

// Paytm Callback Route (no authentication - called by Paytm server)
Route::post('paytm/callback', [\App\Http\Controllers\API\PaytmPaymentController::class, 'callback'])->name('paytm.callback');

// Paytm Webhook Routes (no authentication - called by Paytm server)
Route::post('paytm/payment-webhook', [\App\Http\Controllers\API\PaytmWebhookController::class, 'handlePaymentWebhook'])->name('paytm.payment.webhook');
Route::post('paytm/test-webhook', [\App\Http\Controllers\API\PaytmWebhookController::class, 'testWebhook'])->name('paytm.test.webhook');
Route::get('paytm/webhook-status', [\App\Http\Controllers\API\PaytmWebhookController::class, 'webhookStatus'])->name('paytm.webhook.status');

// Paytm Test Routes (no authentication - for testing/debugging)
Route::get('paytm/test/check-refund-status', [\App\Http\Controllers\API\PaytmTestController::class, 'checkRefundStatus'])->name('paytm.test.check-refund-status');

// Customer Notifications (Send push notifications to specific customers - no auth required)
Route::group(['prefix' => 'customer-notifications'], function () {
    Route::post('send', [\App\Http\Controllers\API\CustomerNotificationApiController::class, 'send'])->name('customer-notifications.send');
    Route::post('send-bulk', [\App\Http\Controllers\API\CustomerNotificationApiController::class, 'sendBulk'])->name('customer-notifications.send-bulk');
    Route::post('send-test', [\App\Http\Controllers\API\CustomerNotificationApiController::class, 'sendTest'])->name('customer-notifications.send-test');
});

// Seller Notifications (Send push notifications to specific sellers - no auth required)
Route::group(['prefix' => 'seller-notifications'], function () {
    Route::post('send', [\App\Http\Controllers\API\SellerNotificationApiController::class, 'send'])->name('seller-notifications.send');
    Route::post('send-bulk', [\App\Http\Controllers\API\SellerNotificationApiController::class, 'sendBulk'])->name('seller-notifications.send-bulk');
    Route::post('send-test', [\App\Http\Controllers\API\SellerNotificationApiController::class, 'sendTest'])->name('seller-notifications.send-test');
});

// Driver Notifications (Send push notifications to specific drivers - no auth required)
Route::group(['prefix' => 'driver-notifications'], function () {
    Route::post('send', [\App\Http\Controllers\API\DriverNotificationApiController::class, 'send'])->name('driver-notifications.send');
    Route::post('send-bulk', [\App\Http\Controllers\API\DriverNotificationApiController::class, 'sendBulk'])->name('driver-notifications.send-bulk');
    Route::post('send-test', [\App\Http\Controllers\API\DriverNotificationApiController::class, 'sendTest'])->name('driver-notifications.send-test');
});
// Delivery Boy Broadcast Notifications (Send notifications to all delivery boys)
Route::group(['prefix' => 'delivery-boy-broadcast-notifications'], function () {
    Route::get('/', [\App\Http\Controllers\API\DeliveryBoyBroadcastNotificationController::class, 'index']);
    Route::post('/send', [\App\Http\Controllers\API\DeliveryBoyBroadcastNotificationController::class, 'send']);
    Route::post('/delete', [\App\Http\Controllers\API\DeliveryBoyBroadcastNotificationController::class, 'delete']);
    Route::get('/stats', [\App\Http\Controllers\API\DeliveryBoyBroadcastNotificationController::class, 'stats']);
});

// Notifications All - Customer, Seller, Driver notifications management
Route::group(['prefix' => 'notifications-all'], function () {
    Route::get('/', [\App\Http\Controllers\API\NotificationsAllController::class, 'index']);
    Route::get('/stats', [\App\Http\Controllers\API\NotificationsAllController::class, 'stats']);
    Route::post('/delete', [\App\Http\Controllers\API\NotificationsAllController::class, 'delete']);
    Route::get('/send-stats', [\App\Http\Controllers\API\NotificationsAllController::class, 'sendStats']);
    Route::get('/recent-broadcasts', [\App\Http\Controllers\API\NotificationsAllController::class, 'recentBroadcasts']);
    Route::post('/send', [\App\Http\Controllers\API\NotificationsAllController::class, 'send']);
});

// Customer Issue Report Refund Breakdown (no auth - for testing)
Route::get('customer_issue_reports/refund_breakdown', [\App\Http\Controllers\API\CustomerIssueReportsApiController::class, 'getRefundBreakdown']);

Route::middleware('auth:api')->group(function () {
    Route::get('admin_settings', [\App\Http\Controllers\Controller::class, 'getAdminSettings']);
    Route::get('dashboard', [\App\Http\Controllers\Controller::class, 'dashboard']);
    Route::get('get_top_notifications', [\App\Http\Controllers\Controller::class, 'getTopNotifications']);
    Route::get('notification_read', [\App\Http\Controllers\Controller::class, 'markAsReadNotifications']);
    Route::post('notification_read', [\App\Http\Controllers\Controller::class, 'markAsReadNotifications']);
    Route::post('notification_read_all', [\App\Http\Controllers\Controller::class, 'markAllNotificationsAsRead']);
    Route::get('create_slug/{text}', [\App\Http\Controllers\Controller::class, 'createSlug']);

    // Admin Delivery Boy Gig System Routes
    Route::group(['prefix' => 'admin/delivery-boys'], function () {
        // Live Tracking
        Route::get('tracking/live', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'getLiveTracking']);
        Route::get('tracking/export', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'exportLiveTracking']);
        Route::get('tracking/sessions', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'getSessions']);
        Route::get('tracking/sessions/export', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'exportSessions']);
        Route::get('tracking/reports', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'getDailyReports']);
        Route::get('tracking/reports/export', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'exportReports']);

        // Gig Management
        Route::get('gigs', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'getAllGigs']);
        Route::post('gigs/create', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'createGig']);
        Route::post('gigs/update', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'updateGig']);
        Route::post('gigs/delete', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'deleteGig']);

        // Gig Slots Management
        Route::get('gigs/slots', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'getGigSlots']);
        Route::post('gigs/slots/create', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'createGigSlots']);
        Route::post('gigs/slots/create-multiple', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'createMultipleGigSlots']);
        Route::post('gigs/slots/update', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'updateGigSlot']);
        Route::get('gigs/slots/bookings', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'getSlotBookings']);

        // Gig Bookings Management
        Route::get('gigs/bookings', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'getAllBookings']);
        Route::post('gigs/bookings/cancel', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'cancelBooking']);
        Route::get('gigs/bookings/export', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'exportBookings']);

        // Single Gig Route (must be last to avoid conflicts)
        Route::get('gigs/{id}', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'getGig']);

        // Incentive Offers
        Route::get('offers', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'getAllOffers']);
        Route::get('offers/active', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'getActiveOffers']);
        Route::get('offers/{id}', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'getOffer']);
        Route::post('offers/create', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'createOffer']);
        Route::post('offers/update', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'updateOffer']);
        Route::post('offers/delete', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'deleteOffer']);
        Route::post(
            'offers/update-status-toggle-admin',
            [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'updateOfferStatus']
        );

        // Offers Progress
        Route::get('offers/progress', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'getPartnerProgress']);
        Route::get('offers/progress/export', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'exportProgress']);

        // Offers Payouts
        Route::get('offers/payouts', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'getAllPayouts']);
        Route::post('offers/payouts/process', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'processPayout']);
        Route::get('offers/payouts/export', [\App\Http\Controllers\API\Admin\DeliveryBoyAdminController::class, 'exportPayouts']);

        // Manual Payment Management (Driver pays admin via UPI/Bank)
        Route::get('manual-payments', [\App\Http\Controllers\Admin\ManualPaymentController::class, 'apiIndex']);
        Route::post('manual-payments/{id}/approve', [\App\Http\Controllers\Admin\ManualPaymentController::class, 'apiApprove']);
        Route::post('manual-payments/{id}/reject', [\App\Http\Controllers\Admin\ManualPaymentController::class, 'apiReject']);
        Route::post('{deliveryBoyId}/manually-reduce-hand-cash', [\App\Http\Controllers\Admin\ManualPaymentController::class, 'apiManuallyReduceHandCash']);
    });

    // Admin Driver Duty Issues Routes
    Route::get('admin/driver-duty-issues', [\App\Http\Controllers\API\Admin\DriverDutyIssueAdminController::class, 'index']);
    Route::get('admin/driver-duty-issues/{id}', [\App\Http\Controllers\API\Admin\DriverDutyIssueAdminController::class, 'show']);
    Route::post('admin/driver-duty-issues/{id}/respond', [\App\Http\Controllers\API\Admin\DriverDutyIssueAdminController::class, 'respond']);
    Route::delete('admin/driver-duty-issues/{id}', [\App\Http\Controllers\API\Admin\DriverDutyIssueAdminController::class, 'destroy']);

    // Admin Driver Issues Zenfoo Routes
    Route::get('admin/driver-issues-zenfoo', [\App\Http\Controllers\API\Admin\DriverIssueZenfooController::class, 'index']);
    Route::post('admin/driver-issues-zenfoo/transactions', [\App\Http\Controllers\API\Admin\DriverIssueZenfooController::class, 'getTransactions']);
    Route::get('admin/driver-issues-zenfoo/{id}', [\App\Http\Controllers\API\Admin\DriverIssueZenfooController::class, 'show']);
    Route::post('admin/driver-issues-zenfoo/{id}/respond', [\App\Http\Controllers\API\Admin\DriverIssueZenfooController::class, 'respond']);

    // Admin Vehicles Management Routes
    Route::group(['prefix' => 'admin/vehicles'], function () {
        Route::get('/', [\App\Http\Controllers\API\Admin\VehicleController::class, 'index']);
        Route::get('/active', [\App\Http\Controllers\API\Admin\VehicleController::class, 'getActiveVehicles']);
        Route::get('/{id}', [\App\Http\Controllers\API\Admin\VehicleController::class, 'show']);
        Route::post('/create', [\App\Http\Controllers\API\Admin\VehicleController::class, 'store']);
        Route::post('/update', [\App\Http\Controllers\API\Admin\VehicleController::class, 'update']);
        Route::post('/delete', [\App\Http\Controllers\API\Admin\VehicleController::class, 'destroy']);
        Route::post('/toggle-status', [\App\Http\Controllers\API\Admin\VehicleController::class, 'toggleStatus']);
    });

    // Admin Driver Performance Dashboard Routes
    Route::group(['prefix' => 'admin/driver-performance'], function () {
        Route::get('dashboard', [\App\Http\Controllers\API\Admin\DriverPerformanceController::class, 'getDashboardData']);
        Route::get('drivers-list', [\App\Http\Controllers\API\Admin\DriverPerformanceController::class, 'getDriversList']);
        Route::get('driver', [\App\Http\Controllers\API\Admin\DriverPerformanceController::class, 'getDriverPerformance']);
        Route::get('weekly-comparison', [\App\Http\Controllers\API\Admin\DriverPerformanceController::class, 'getWeeklyComparison']);
        Route::get('monthly-comparison', [\App\Http\Controllers\API\Admin\DriverPerformanceController::class, 'getMonthlyComparison']);
        Route::get('yearly', [\App\Http\Controllers\API\Admin\DriverPerformanceController::class, 'getYearlyPerformance']);
    });

    Route::group(['prefix' => 'categories'], function () {
        Route::get('/', [\App\Http\Controllers\API\CategoryApiController::class, 'getCategories']);
        Route::get('/all', [\App\Http\Controllers\API\CategoryApiController::class, 'getAllCategories']);
        Route::get('main', [\App\Http\Controllers\API\CategoryApiController::class, 'getMainCategories']);
        Route::get('active', [\App\Http\Controllers\API\CategoryApiController::class, 'getActiveCategories']);
        Route::post('save', [\App\Http\Controllers\API\CategoryApiController::class, 'save'])->name('categories.save');
        Route::post('update', [\App\Http\Controllers\API\CategoryApiController::class, 'update'])->name('categories.update');
        Route::post('delete', [\App\Http\Controllers\API\CategoryApiController::class, 'delete'])->name('categories.delete');
        Route::get('options', [\App\Http\Controllers\API\CategoryApiController::class, 'getOptions']);
        Route::get('row_order', [\App\Http\Controllers\API\CategoryApiController::class, 'getCategoriesByRowOrder']);
        Route::post('updateOrder', [\App\Http\Controllers\API\CategoryApiController::class, 'updateCategoriesOrder'])->name('categories.updateOrder');
        Route::get('product_count', [\App\Http\Controllers\API\CategoryApiController::class, 'countProductCategoryWise']);
        Route::get('seller_categories', [\App\Http\Controllers\API\CategoryApiController::class, 'getSellerCategories']);
        Route::get('/check-slug/{slug}', [\App\Http\Controllers\API\CategoryApiController::class,  'checkSlug']);
        Route::get('types', [\App\Http\Controllers\API\CategoryApiController::class, 'getCategoryTypesByCategoryId']);
        Route::post('store-seller-category', [\App\Http\Controllers\API\CategoryApiController::class, 'storeSellerCategory']);
    });

    Route::group(['prefix' => 'subcategories'], function () {
        Route::get('/all', [\App\Http\Controllers\API\SubCategoryApiController::class, 'getSubcategory']);
        Route::get('/{id?}', [\App\Http\Controllers\API\SubCategoryApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\SubCategoryApiController::class, 'save'])->name('subcategories.save');
        Route::post('update', [\App\Http\Controllers\API\SubCategoryApiController::class, 'update'])->name('subcategories.update');
        Route::post('delete', [\App\Http\Controllers\API\SubCategoryApiController::class, 'delete'])->name('subcategories.delete');
    });

    Route::group(['prefix' => 'seo_settings'], function () {
        Route::get('/', [\App\Http\Controllers\API\SeoSettingsApiController::class, 'getSeoSettings']);
        Route::post('save', [\App\Http\Controllers\API\SeoSettingsApiController::class, 'save'])->name('seo_settings.save');
        Route::post('update', [\App\Http\Controllers\API\SeoSettingsApiController::class, 'update'])->name('seo_settings.update');
        Route::post('delete', [\App\Http\Controllers\API\SeoSettingsApiController::class, 'delete'])->name('seo_settings.delete');
    });

    // Combos
    Route::group(['prefix' => 'combos'], function () {
        Route::get('/', [\App\Http\Controllers\API\ComboController::class, 'getCombos']);
        Route::get('/products', [\App\Http\Controllers\API\ComboController::class, 'getProductsForCombo']);
        Route::get('/{id}/edit', [\App\Http\Controllers\API\ComboController::class, 'edit']);
        Route::post('/save', [\App\Http\Controllers\API\ComboController::class, 'save'])->name('combos.save');
        Route::post('/{id}', [\App\Http\Controllers\API\ComboController::class, 'save'])->name('combos.update');
        Route::post('/delete/combo', [\App\Http\Controllers\API\ComboController::class, 'destroy'])->name('combos.delete');
        Route::post('/change', [\App\Http\Controllers\API\ComboController::class, 'changeStatus'])->name('combos.change');
    });

    // Special Items
     Route::group(['prefix' => 'special'], function () {
        Route::get('/', [\App\Http\Controllers\API\SpecialItemController::class, 'getSpecialItem']);
        Route::post('/save', [\App\Http\Controllers\API\SpecialItemController::class, 'save'])->name('special.save');
        Route::get('/{id}/edit', [\App\Http\Controllers\API\SpecialItemController::class, 'edit']);
        Route::post('/{id}', [\App\Http\Controllers\API\SpecialItemController::class, 'save'])->name('special.update');
        Route::post('/delete', [\App\Http\Controllers\API\SpecialItemController::class, 'destroy'])->name('special.delete');
        Route::post('/change', [\App\Http\Controllers\API\SpecialItemController::class, 'changeStatus'])->name('special.change');
    });

    // Group Category
     Route::group(['prefix' => 'group-category'], function () {
        Route::get('/', [\App\Http\Controllers\API\CategoryGroupController::class, 'getGroupCategory']);
        Route::post('/save', [\App\Http\Controllers\API\CategoryGroupController::class, 'save'])->name('category.save');
        Route::get('/{id}/edit', [\App\Http\Controllers\API\CategoryGroupController::class, 'edit']);
        Route::post('/update/{id}', [\App\Http\Controllers\API\CategoryGroupController::class, 'update'])->name('category.update.one');
        Route::post('/delete', [\App\Http\Controllers\API\CategoryGroupController::class, 'destroy'])->name('category.delete.one');
        Route::post('/change', [\App\Http\Controllers\API\CategoryGroupController::class, 'changeStatus'])->name('category.change.one');
        Route::get('row_order', [\App\Http\Controllers\API\CategoryGroupController::class, 'getCategoryGroupsByRowOrder']);
        Route::post('updateOrder', [\App\Http\Controllers\API\CategoryGroupController::class, 'updateCategoryGroupsOrder'])->name('category-groups.updateOrder');
    });

    // Store
     Route::group(['prefix' => 'stores'], function () {
        Route::get('/category-groups', [\App\Http\Controllers\API\StoreController::class, 'getCategoryGroups']);
        Route::get('/', [\App\Http\Controllers\API\StoreController::class, 'index']);
        Route::post('/save', [\App\Http\Controllers\API\StoreController::class, 'save']);
        Route::post('/update/{id}', [\App\Http\Controllers\API\StoreController::class, 'update']);
        Route::post('/delete', [\App\Http\Controllers\API\StoreController::class, 'delete']);
        Route::get('/{id}/edit', [\App\Http\Controllers\API\StoreController::class, 'edit']);
    });

    // Group Sub Category
     Route::group(['prefix' => 'group-sub-category'], function () {
        Route::get('/', [\App\Http\Controllers\API\SubCategoryGroupController::class, 'getGroupSubCategory']);
        Route::post('/save', [\App\Http\Controllers\API\SubCategoryGroupController::class, 'save']);
        Route::get('/{id}/edit', [\App\Http\Controllers\API\SubCategoryGroupController::class, 'edit']);
        Route::post('/', [\App\Http\Controllers\API\SubCategoryGroupController::class, 'save'])->name('category.update.two');
        Route::post('/delete', [\App\Http\Controllers\API\SubCategoryGroupController::class, 'destroy'])->name('category.delete.two');
        Route::post('/update', [\App\Http\Controllers\API\SubCategoryGroupController::class, 'update'])->name('category.update.three');
        Route::get('row_order', [\App\Http\Controllers\API\SubCategoryGroupController::class, 'getSubCategoryGroupsByRowOrder']);
        Route::post('updateOrder', [\App\Http\Controllers\API\SubCategoryGroupController::class, 'updateSubCategoryGroupsOrder'])->name('sub-category-groups.updateOrder');
    });

    // Group Products
     Route::group(['prefix' => 'group-products'], function () {
        Route::get('/', [\App\Http\Controllers\API\GroupProductApisController::class, 'getGroupProducts']);
        Route::post('/save', [\App\Http\Controllers\API\GroupProductApisController::class, 'save']);
        Route::get('/{id}/edit', [\App\Http\Controllers\API\GroupProductApisController::class, 'edit']);
        Route::post('/', [\App\Http\Controllers\API\GroupProductApisController::class, 'save'])->name('category.update');
        Route::post('/delete', [\App\Http\Controllers\API\GroupProductApisController::class, 'destroy'])->name('category.delete');
        Route::post('/change', [\App\Http\Controllers\API\GroupProductApisController::class, 'changeStatus'])->name('category.change');
    });

    Route::group(['prefix' => 'products'], function () {
        Route::get('/', [\App\Http\Controllers\API\ProductApisController::class, 'getProducts']);
        Route::get('active', [\App\Http\Controllers\API\ProductApisController::class, 'getActiveProducts']);

        Route::post('save', [\App\Http\Controllers\API\ProductApisController::class, 'save'])->name('products.save');
        Route::post('update', [\App\Http\Controllers\API\ProductApisController::class, 'update'])->name('products.update');
        Route::post('delete', [\App\Http\Controllers\API\ProductApisController::class, 'delete'])->name('products.delete');
        Route::post('multiple_delete', [\App\Http\Controllers\API\ProductApisController::class, 'multipleDelete'])->name('products.multiple_delete');

        Route::get('edit/{id}', [\App\Http\Controllers\API\ProductApisController::class, 'edit']);

        Route::post('change', [\App\Http\Controllers\API\ProductApisController::class, 'changeStatus'])->name('products.change');
        Route::post('change-approve', [\App\Http\Controllers\API\ProductApisController::class, 'changeApproveStatus'])->name('products.change_approve');

        Route::get('product_info', [\App\Http\Controllers\API\ProductApisController::class, 'getProducts']);
        Route::get('order_list', [\App\Http\Controllers\API\ProductApisController::class, 'getProductsOrderList']);
        Route::post('updateOrder', [\App\Http\Controllers\API\ProductApisController::class, 'updateProductsOrder'])->name('products.updateOrder');

        Route::post('bulk_upload', [\App\Http\Controllers\API\ProductApisController::class, 'bulkUpload'])->name('products.bulk_upload');
        Route::get('download_product_data_excel', [\App\Http\Controllers\API\ProductApisController::class, 'downloadProductDataExcel']);
        Route::post('bulk_update', [\App\Http\Controllers\API\ProductApisController::class, 'bulkUpdate'])->name('products.bulk_update');
        Route::get('ratings_list', [\App\Http\Controllers\API\ProductApisController::class, 'productRatingsList']);
        Route::group(['prefix' => 'taxes'], function () {
            Route::get('/', [\App\Http\Controllers\API\TaxesApiController::class, 'index']);
            Route::post('save', [\App\Http\Controllers\API\TaxesApiController::class, 'save'])->name('taxes.save');
            Route::post('update', [\App\Http\Controllers\API\TaxesApiController::class, 'update'])->name('taxes.update');
            Route::post('delete', [\App\Http\Controllers\API\TaxesApiController::class, 'delete'])->name('taxes.delete');
        });
        Route::group(['prefix' => 'brands'], function () {
            Route::get('/', [\App\Http\Controllers\API\BrandsApiController::class, 'list']);
            Route::post('save', [\App\Http\Controllers\API\BrandsApiController::class, 'save'])->name('brands.save');
            Route::post('update', [\App\Http\Controllers\API\BrandsApiController::class, 'update'])->name('brands.update');
            Route::post('delete', [\App\Http\Controllers\API\BrandsApiController::class, 'delete'])->name('brands.delete');
            Route::get('/get', [\App\Http\Controllers\API\BrandsApiController::class, 'getBrands']);
            Route::get('/categories', [\App\Http\Controllers\API\BrandsApiController::class, 'getCategories']);
        });
        Route::group(['prefix' => 'customer-app-sections'], function () {
            Route::get('/', [\App\Http\Controllers\API\CustomerAppSectionController::class, 'list']);
            Route::post('save', [\App\Http\Controllers\API\CustomerAppSectionController::class, 'save'])->name('customer-app-sections.save');
            Route::post('update', [\App\Http\Controllers\API\CustomerAppSectionController::class, 'update'])->name('customer-app-sections.update');
            Route::post('delete', [\App\Http\Controllers\API\CustomerAppSectionController::class, 'delete'])->name('customer-app-sections.delete');
            Route::get('row_order', [\App\Http\Controllers\API\CustomerAppSectionController::class, 'getSectionsByRowOrder']);
            Route::post('updateOrder', [\App\Http\Controllers\API\CustomerAppSectionController::class, 'updateSectionsOrder'])->name('customer-app-sections.updateOrder');
            Route::get('/{id}', [\App\Http\Controllers\API\CustomerAppSectionController::class, 'show'])->name('customer-app-sections.show');
        });
        Route::group(['prefix' => 'customer-app-section-products'], function () {
            Route::get('/', [\App\Http\Controllers\API\CustomerAppSectionProductController::class, 'list']);
            Route::post('save', [\App\Http\Controllers\API\CustomerAppSectionProductController::class, 'save'])->name('customer-app-section-products.save');
            Route::post('update', [\App\Http\Controllers\API\CustomerAppSectionProductController::class, 'update'])->name('customer-app-section-products.update');
            Route::post('delete', [\App\Http\Controllers\API\CustomerAppSectionProductController::class, 'delete'])->name('customer-app-section-products.delete');
            Route::delete('delete-all/{sectionId}', [\App\Http\Controllers\API\CustomerAppSectionProductController::class, 'deleteAll'])->name('customer-app-section-products.deleteAll');
            Route::post('reorder', [\App\Http\Controllers\API\CustomerAppSectionProductController::class, 'reorder'])->name('customer-app-section-products.reorder');
            Route::get('/{id}', [\App\Http\Controllers\API\CustomerAppSectionProductController::class, 'show'])->name('customer-app-section-products.show');
        });
        Route::group(['prefix' => 'tags'], function () {
            Route::get('/', [\App\Http\Controllers\API\TagsApiController::class, 'search']);
        });
        Route::get('get_product_variants', [\App\Http\Controllers\API\ProductApisController::class, 'getProductVariants']);
        Route::post('update_variant_stock', [\App\Http\Controllers\API\ProductApisController::class, 'updateVariantStock']);
        Route::get('by_seller', [\App\Http\Controllers\API\ProductApisController::class, 'getProductsBySeller']);
    });

    Route::group(['prefix' => 'sellers'], function () {
        Route::get('/', [\App\Http\Controllers\API\SellerApiController::class, 'getSellers']);
        Route::post('save', [\App\Http\Controllers\API\SellerApiController::class, 'save'])->name('sellers.save');
        Route::post('update', [\App\Http\Controllers\API\SellerApiController::class, 'update'])->name('sellers.update');
        Route::post('delete', [\App\Http\Controllers\API\SellerApiController::class, 'delete'])->name('sellers.delete');
        Route::get('edit/{id}', [\App\Http\Controllers\API\SellerApiController::class, 'edit']);
        Route::post('update_status', [\App\Http\Controllers\API\SellerApiController::class, 'updateStatus'])->name('sellers.update-status');
        Route::post('update_document_status', [\App\Http\Controllers\API\SellerApiController::class, 'updateDocumentStatus'])->name('sellers.update-document-status');
        Route::get('updateCommission', [\App\Http\Controllers\API\SellerApiController::class, 'updateCommission'])->name('sellers.updateCommission');

        // Seller View APIs
        Route::get('view/{id}/overview', [\App\Http\Controllers\API\SellerViewApiController::class, 'getOverview']);
        Route::get('view/{id}/reviews', [\App\Http\Controllers\API\SellerViewApiController::class, 'getReviews']);
        Route::post('view/update-commission', [\App\Http\Controllers\API\SellerViewApiController::class, 'updateCommissionValue']);
        Route::post('view/update-gst', [\App\Http\Controllers\API\SellerViewApiController::class, 'updateGstValue']);
        Route::get('view/{id}/categories', [\App\Http\Controllers\API\SellerViewApiController::class, 'getSellerCategories']);
        Route::post('view/store-category-group', [\App\Http\Controllers\API\SellerViewApiController::class, 'storeSellerCategoryGroup']);
        Route::post('view/store-sub-category-group', [\App\Http\Controllers\API\SellerViewApiController::class, 'storeSellerSubCategoryGroup']);
        Route::get('view/{id}/brands', [\App\Http\Controllers\API\SellerViewApiController::class, 'getSellerBrands']);
    });

    // Marts (Super Mart Sellers - store_id = 17)
    Route::get('marts', [\App\Http\Controllers\API\SellerApiController::class, 'getMarts']);

    // Food Products (store_id = 15)
    Route::get('food-products', [\App\Http\Controllers\API\Admin\FoodProductsController::class, 'getProducts']);
    Route::get('food-products/seller-categories', [\App\Http\Controllers\API\Admin\FoodProductsController::class, 'getSellerCategories']);

    Route::group(['prefix' => 'seller_registration_helper'], function () {
        Route::get('/', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'store']);
        Route::get('show/{id}', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'show']);
        Route::post('update/{id}', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'update']);
        Route::post('delete/{id}', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'destroy']);
    });

    Route::group(['prefix' => 'home_slider_images'], function () {
        Route::get('/', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'save'])->name('home_slider_images.save');
        Route::post('update', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'update'])->name('home_slider_images.update');
        Route::post('delete', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'delete'])->name('home_slider_images.delete');
        Route::get('app_launch_banner', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'getAppLaunchBanner']);
        Route::post('app_launch_banner/update', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'updateAppLaunchBanner']);
        Route::get('promotional', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'getPromotionalBanners']);
        Route::get('special_items', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'getSpecialItems']);
        Route::post('special_items/update', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'updateSpecialItems']);
    });

    Route::group(['prefix' => 'promo_code'], function () {
        Route::get('/', [\App\Http\Controllers\API\PromoCodeApiController::class, 'index']);
        Route::get('/get-sellers-list', [\App\Http\Controllers\API\PromoCodeApiController::class, 'getSellers']);
        Route::post('save', [\App\Http\Controllers\API\PromoCodeApiController::class, 'save'])->name('promo_code.save');
        Route::post('update', [\App\Http\Controllers\API\PromoCodeApiController::class, 'update'])->name('promo_code.update');
        Route::post('delete', [\App\Http\Controllers\API\PromoCodeApiController::class, 'delete'])->name('promo_code.delete');
    });

    // Thinking Items (What are you thinking?)
    Route::group(['prefix' => 'thinking-items'], function () {
        Route::get('/', [\App\Http\Controllers\API\ThinkingItemsApiController::class, 'index']);
        Route::get('/categories', [\App\Http\Controllers\API\ThinkingItemsApiController::class, 'getCategories']);
        Route::get('/{id}', [\App\Http\Controllers\API\ThinkingItemsApiController::class, 'show']);
        Route::post('/', [\App\Http\Controllers\API\ThinkingItemsApiController::class, 'save'])->name('thinking_items.save');
        Route::post('/update', [\App\Http\Controllers\API\ThinkingItemsApiController::class, 'update'])->name('thinking_items.update');
        Route::post('/toggle-status', [\App\Http\Controllers\API\ThinkingItemsApiController::class, 'toggleStatus'])->name('thinking_items.toggle_status');
        Route::delete('/{id}', [\App\Http\Controllers\API\ThinkingItemsApiController::class, 'delete'])->name('thinking_items.delete');
    });

    Route::group(['prefix' => 'zenfoo_offers'], function () {
        Route::get('/', [\App\Http\Controllers\API\ZenfooOfferController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\ZenfooOfferController::class, 'save'])->name('zenfoo_offers.save');
        Route::post('update', [\App\Http\Controllers\API\ZenfooOfferController::class, 'update'])->name('zenfoo_offers.update');
        Route::post('delete', [\App\Http\Controllers\API\ZenfooOfferController::class, 'delete'])->name('zenfoo_offers.delete');
    });

    // User Offers - Order Rewards & Banners
    Route::group(['prefix' => 'user_offers'], function () {
        // Order Rewards
        Route::get('order_rewards', [\App\Http\Controllers\API\UserOffersController::class, 'getOrderRewards']);
        Route::post('order_rewards/save', [\App\Http\Controllers\API\UserOffersController::class, 'saveOrderReward'])->name('user_offers.order_rewards.save');
        Route::post('order_rewards/update', [\App\Http\Controllers\API\UserOffersController::class, 'updateOrderReward'])->name('user_offers.order_rewards.update');
        Route::post('order_rewards/delete', [\App\Http\Controllers\API\UserOffersController::class, 'deleteOrderReward'])->name('user_offers.order_rewards.delete');

        // Offer Banners
        Route::get('banners', [\App\Http\Controllers\API\UserOffersController::class, 'getOfferBanners']);
        Route::post('banners/save', [\App\Http\Controllers\API\UserOffersController::class, 'saveOfferBanner'])->name('user_offers.banners.save');
        Route::post('banners/update', [\App\Http\Controllers\API\UserOffersController::class, 'updateOfferBanner'])->name('user_offers.banners.update');
        Route::post('banners/delete', [\App\Http\Controllers\API\UserOffersController::class, 'deleteOfferBanner'])->name('user_offers.banners.delete');

        // Claimed Milestones (Admin view)
        Route::get('claimed_milestones', [\App\Http\Controllers\API\UserOffersController::class, 'getClaimedMilestones']);
    });

    Route::group(['prefix' => 'delivery_settings'], function () {
        Route::get('/', [\App\Http\Controllers\API\TimeSlotsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\TimeSlotsApiController::class, 'save'])->name('time_slots.save');
        Route::post('update', [\App\Http\Controllers\API\TimeSlotsApiController::class, 'update'])->name('time_slots.update');
        Route::post('delete', [\App\Http\Controllers\API\TimeSlotsApiController::class, 'delete'])->name('time_slots.delete');
        Route::post('saveTimeSlotsSettings', [\App\Http\Controllers\API\TimeSlotsApiController::class, 'saveTimeSlotsSettings'])->name('time_slots.saveTimeSlotsSettings');
        Route::get('getTimeSlotsSettings', [\App\Http\Controllers\API\TimeSlotsApiController::class, 'getTimeSlotsSettings']);
    });

    Route::group(['prefix' => 'units'], function () {
        Route::get('/', [\App\Http\Controllers\API\UnitApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\UnitApiController::class, 'save'])->name('units.save');
        Route::post('update', [\App\Http\Controllers\API\UnitApiController::class, 'update'])->name('units.update');
        Route::post('delete', [\App\Http\Controllers\API\UnitApiController::class, 'delete'])->name('units.delete');
        Route::get('/get', [\App\Http\Controllers\API\UnitApiController::class, 'getUnits']);
    });


    Route::group(['prefix' => 'payment_methods'], function () {
        Route::get('/', [\App\Http\Controllers\API\PaymentMethodsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\PaymentMethodsApiController::class, 'save'])->name('payment_methods.save');
    });

    Route::group(['prefix' => 'sms_settings'], function () {
        Route::get('/', [\App\Http\Controllers\API\SmsSettingsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\SmsSettingsApiController::class, 'save'])->name('sms_settings.save');
    });

    Route::group(['prefix' => 'sms_templates'], function () {
        Route::get('/', [\App\Http\Controllers\API\SmsTemplatesApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\SmsTemplatesApiController::class, 'save'])->name('sms_templates.save');
        Route::post('update', [\App\Http\Controllers\API\SmsTemplatesApiController::class, 'update'])->name('sms_templates.update');
    });

    Route::group(['prefix' => 'store_settings'], function () {
        Route::get('/', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'index']);
        Route::post('save_store_basic_setting', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'save_store_basic_setting'])->name('store_settings.save_store_basic_setting');
        Route::post('save_address_setting', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'save_address_setting'])->name('store_settings.save_address_setting');
        Route::post('save_other_setting', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'save_other_setting'])->name('store_settings.save_other_setting');
        Route::post('save_delivery_boy_setting', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'save_delivery_boy_setting'])->name('store_settings.save_delivery_boy_setting');
        Route::post('save_app_setting', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'save_app_setting'])->name('store_settings.save_app_setting');
        Route::post('save_frontend_home_setting', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'save_frontend_home_setting'])->name('store_settings.save_frontend_home_setting');
        Route::post('save_smtp_mail_setting', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'save_smtp_mail_setting'])->name('store_settings.save_smtp_mail_setting');
        Route::post('save_third_party_api_setting', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'save_third_party_api_setting'])->name('store_settings.save_third_party_api_setting');
        Route::post('save_seller_setting', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'save_seller_setting'])->name('store_settings.save_seller_setting');
        Route::post('save_login_setting', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'save_login_setting'])->name('store_settings.save_login_setting');
        Route::post('save_cart_setting', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'save_cart_setting'])->name('store_settings.save_cart_setting');
        Route::post('save_refer_earn_setting', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'save_refer_earn_setting'])->name('store_settings.save_refer_earn_setting');
        Route::post('save_additional_charges', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'save_additional_charges'])->name('store_settings.save_additional_charges');
        Route::get('get_additional_charges', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'get_additional_charges']);
        Route::get('/purchase_code', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'getPurchaseCode']);
        Route::get('/purchase_code/{code}', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'purchaseCode']);
        Route::get('/purchase_code_updater', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'getPurchaseCodeUpdater']);
        Route::post('/test_mail', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'testMail']);
    });

    Route::group(['prefix' => 'mail_settings'], function () {
        Route::get('/', [\App\Http\Controllers\API\MailSettingsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\MailSettingsApiController::class, 'save'])->name('mail_settings.save');
    });

    Route::group(['prefix' => 'firebase'], function () {
        Route::get('/', [\App\Http\Controllers\API\FirebaseApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\FirebaseApiController::class, 'save'])->name('firebase.save');
    });

    Route::group(['prefix' => 'popup'], function () {
        Route::get('/', [\App\Http\Controllers\API\PopupApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\PopupApiController::class, 'save'])->name('popup.save');
    });


    Route::group(['prefix' => 'notification_settings'], function () {
        Route::get('/', [\App\Http\Controllers\API\NotificationSettingsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\NotificationSettingsApiController::class, 'save'])->name('notification_settings.save');
    });
    Route::group(['prefix' => 'contact_us'], function () {
        Route::get('/', [\App\Http\Controllers\API\ContactUsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\ContactUsApiController::class, 'save'])->name('contact_us.save');
    });
    Route::group(['prefix' => 'about_us'], function () {
        Route::get('/', [\App\Http\Controllers\API\AboutUsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\AboutUsApiController::class, 'save'])->name('about_us.save');
    });


    Route::group(['prefix' => 'privacy_policy'], function () {
        Route::get('/', [\App\Http\Controllers\API\PrivacyPolicyApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\PrivacyPolicyApiController::class, 'save'])->name('privacy_policy.save');
    });

    Route::group(['prefix' => 'privacy_policy_delivery_boy'], function () {
        Route::get('/', [\App\Http\Controllers\API\PrivacyPolicyDeliveryBoyApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\PrivacyPolicyDeliveryBoyApiController::class, 'save'])->name('privacy_policy_delivery_boy.save');
    });

    Route::group(['prefix' => 'privacy_policy_manager_app'], function () {
        Route::get('/', [\App\Http\Controllers\API\PrivacyPolicyManagerAppApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\PrivacyPolicyManagerAppApiController::class, 'save'])->name('privacy_policy_manager_app.save');
    });

    Route::group(['prefix' => 'privacy_policy_seller'], function () {
        Route::get('/', [\App\Http\Controllers\API\PrivacyPolicySellerApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\PrivacyPolicySellerApiController::class, 'save'])->name('privacy_policy_seller.save');
    });

    Route::group(['prefix' => 'about_contact'], function () {
        Route::get('/', [\App\Http\Controllers\API\AboutContactApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\AboutContactApiController::class, 'save'])->name('about_contact.save');
    });

    Route::group(['prefix' => 'notifications'], function () {
        Route::get('/', [\App\Http\Controllers\API\NotificationsApiController::class, 'index']);
        Route::get('delivery_boy_notifications', [\App\Http\Controllers\API\Customer\SectionsApiController::class, 'getDeliveryBoyNotifications']);
        Route::post('save', [\App\Http\Controllers\API\NotificationsApiController::class, 'save'])->name('notifications.save');
        Route::post('delete', [\App\Http\Controllers\API\NotificationsApiController::class, 'delete'])->name('notifications.delete');
    });

    // Messages (Admin <=> Customer, Admin <=> Seller)
    Route::group(['prefix' => 'messages'], function () {
        Route::get('/', [\App\Http\Controllers\API\MessagesApiController::class, 'getMessages']);
        Route::get('/conversations', [\App\Http\Controllers\API\MessagesApiController::class, 'getConversationsList']);
        Route::get('/conversation', [\App\Http\Controllers\API\MessagesApiController::class, 'getConversation']);
        Route::get('/unread-count', [\App\Http\Controllers\API\MessagesApiController::class, 'getUnreadCount']);
        Route::get('/view/{id}', [\App\Http\Controllers\API\MessagesApiController::class, 'view']);
        Route::post('/send', [\App\Http\Controllers\API\MessagesApiController::class, 'send'])->name('messages.send');
        Route::post('/mark-as-read', [\App\Http\Controllers\API\MessagesApiController::class, 'markAsRead'])->name('messages.markAsRead');
        Route::post('/mark-conversation-as-read', [\App\Http\Controllers\API\MessagesApiController::class, 'markConversationAsRead'])->name('messages.markConversationAsRead');
        Route::post('/delete', [\App\Http\Controllers\API\MessagesApiController::class, 'delete'])->name('messages.delete');
        Route::post('/delete-multiple', [\App\Http\Controllers\API\MessagesApiController::class, 'deleteMultiple'])->name('messages.deleteMultiple');
    });

    // Seller <=> Delivery Boy Messages
    Route::group(['prefix' => 'seller-delivery-messages'], function () {
        Route::get('/conversation', [\App\Http\Controllers\API\SellerDeliveryMessagesApiController::class, 'getConversation']);
        Route::get('/seller-conversations', [\App\Http\Controllers\API\SellerDeliveryMessagesApiController::class, 'getSellerConversationsList']);
        Route::get('/delivery-boy-conversations', [\App\Http\Controllers\API\SellerDeliveryMessagesApiController::class, 'getDeliveryBoyConversationsList']);
        Route::get('/unread-count', [\App\Http\Controllers\API\SellerDeliveryMessagesApiController::class, 'getUnreadCount']);
        Route::post('/send', [\App\Http\Controllers\API\SellerDeliveryMessagesApiController::class, 'send'])->name('seller-delivery-messages.send');
        Route::post('/mark-conversation-as-read', [\App\Http\Controllers\API\SellerDeliveryMessagesApiController::class, 'markConversationAsRead'])->name('seller-delivery-messages.markConversationAsRead');
        Route::post('/delete', [\App\Http\Controllers\API\SellerDeliveryMessagesApiController::class, 'delete'])->name('seller-delivery-messages.delete');
    });

    Route::group(['prefix' => 'emails'], function () {
        Route::get('/', [\App\Http\Controllers\API\EmailsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\EmailsApiController::class, 'save'])->name('emails.save');
        Route::post('delete', [\App\Http\Controllers\API\EmailsApiController::class, 'delete'])->name('emails.delete');
    });
    Route::group(['prefix' => 'email_templates'], function () {
        Route::get('/', [\App\Http\Controllers\API\EmailTemplatesApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\EmailTemplatesApiController::class, 'save'])->name('email_templates.save');
        Route::post('update', [\App\Http\Controllers\API\EmailTemplatesApiController::class, 'update'])->name('email_templates.update');
        Route::post('delete', [\App\Http\Controllers\API\EmailTemplatesApiController::class, 'delete'])->name('email_templates.delete');
    });
    Route::group(['prefix' => 'sections'], function () {
        Route::get('/', [\App\Http\Controllers\API\SectionsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\SectionsApiController::class, 'save'])->name('sections.save');
        Route::post('update', [\App\Http\Controllers\API\SectionsApiController::class, 'update'])->name('sections.update');
        Route::post('delete', [\App\Http\Controllers\API\SectionsApiController::class, 'delete'])->name('sections.delete');
        Route::get('row_order', [\App\Http\Controllers\API\SectionsApiController::class, 'getSectionsByRowOrder']);
        Route::post('updateOrder', [\App\Http\Controllers\API\SectionsApiController::class, 'updateSectionsOrder'])->name('sections.updateOrder');
    });

    Route::group(['prefix' => 'offers'], function () {
        Route::get('/', [\App\Http\Controllers\API\OffersApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\OffersApiController::class, 'save'])->name('offers.save');
        Route::post('update', [\App\Http\Controllers\API\OffersApiController::class, 'update'])->name('offers.update');
        Route::post('delete', [\App\Http\Controllers\API\OffersApiController::class, 'delete'])->name('offers.delete');
    });

    Route::group(['prefix' => 'delivery_boys'], function () {
        Route::get('/', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getDeliveryBoy']);
        Route::get('bonus_settings', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getDeliveryBoyBonusSettings']);

        Route::post('save', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'save'])->name('delivery_boys.save');
        Route::get('edit/{id}', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'edit']);
        Route::get('live-tracking', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getLiveTrackingData']);
        Route::get('{id}', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'show'])->where('id', '[0-9]+');
        Route::get('{id}/location', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getLocation'])->where('id', '[0-9]+');
        Route::get('{id}/orders', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getOrders'])->where('id', '[0-9]+');
        Route::get('{id}/hand-cash', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getHandCash'])->where('id', '[0-9]+');
        Route::get('{id}/surge-charges', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getSurgeCharges'])->where('id', '[0-9]+');
        Route::get('pending-payouts', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getAllPendingPayouts']);
        Route::get('{id}/payouts', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getPayouts'])->where('id', '[0-9]+');
        Route::get('{id}/unsettled-payouts', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getUnsettledPayouts'])->where('id', '[0-9]+');
        Route::get('{id}/pending-referrals', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getPendingReferrals'])->where('id', '[0-9]+');
        Route::post('{id}/settle-payouts', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'settlePayouts'])->where('id', '[0-9]+');
        Route::get('{id}/bank-details', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getBankDetails'])->where('id', '[0-9]+');
        Route::get('{id}/incentives', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getIncentives'])->where('id', '[0-9]+');
        Route::get('{id}/pending-incentives', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getPendingIncentives'])->where('id', '[0-9]+');
        Route::get('{id}/ratings', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getRatings'])->where('id', '[0-9]+');
        Route::get('{id}/transactions/weekly', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'getWeeklyTransactions'])->where('id', '[0-9]+');
        Route::post('check-payout-status', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'checkPayoutStatus']);
        Route::post('update', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'update'])->name('delivery_boys.update');
        Route::post('delete', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'delete'])->name('delivery_boys.delete');
        Route::post('update-status', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'updateStatus'])->name('delivery_boys.update-status');
        Route::post('update-document-status', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'updateDocumentStatus'])->name('delivery_boys.update-document-status');
        Route::post('update-hand-cash-limit', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'updateHandCashLimit'])->name('delivery_boys.update-hand-cash-limit');
        Route::get('problematic', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'problematicDrivers'])->name('delivery_boys.problematic');
        Route::post('mark-problematic', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'markProblematic'])->name('delivery_boys.mark-problematic');
        Route::post('unmark-problematic', [\App\Http\Controllers\API\DeliveryBoysApiController::class, 'unmarkProblematic'])->name('delivery_boys.unmark-problematic');
    });

    // Bank Verification Routes (Reverse Penny Drop)
    Route::group(['prefix' => 'bank-verification'], function () {
        // Auth required routes (for delivery boy app)
        Route::post('initiate', [\App\Http\Controllers\API\BankVerificationController::class, 'initiateVerification']);
        Route::post('check-status', [\App\Http\Controllers\API\BankVerificationController::class, 'checkStatus']);
        Route::get('my-status', [\App\Http\Controllers\API\BankVerificationController::class, 'getMyVerificationStatus']);

        // Admin route (get status by delivery boy ID)
        Route::get('status/{id}', [\App\Http\Controllers\API\BankVerificationController::class, 'getVerificationDetails'])->where('id', '[0-9]+');

        // PhonePe webhook/callback routes (no auth required)
        Route::post('callback', [\App\Http\Controllers\API\BankVerificationController::class, 'handleCallback']);
        Route::match(['get', 'post'], 'redirect', [\App\Http\Controllers\API\BankVerificationController::class, 'handleRedirect']);
    });

    Route::group(['prefix' => 'vehicles'], function () {
        Route::get('/', [\App\Http\Controllers\API\VehicleApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\VehicleApiController::class, 'save'])->name('vehicles.save');
        Route::post('update', [\App\Http\Controllers\API\VehicleApiController::class, 'update'])->name('vehicles.update');
        Route::post('delete', [\App\Http\Controllers\API\VehicleApiController::class, 'delete'])->name('vehicles.delete');
        Route::post('update-status', [\App\Http\Controllers\API\VehicleApiController::class, 'updateStatus'])->name('vehicles.update-status');
    });

    Route::group(['prefix' => 'store-locations'], function () {
        Route::get('/', [\App\Http\Controllers\API\StoreLocationController::class, 'index']);
        Route::get('edit/{id}', [\App\Http\Controllers\API\StoreLocationController::class, 'edit']);
        Route::post('save', [\App\Http\Controllers\API\StoreLocationController::class, 'save'])->name('store-locations.save');
        Route::post('update', [\App\Http\Controllers\API\StoreLocationController::class, 'update'])->name('store-locations.update');
        Route::post('delete', [\App\Http\Controllers\API\StoreLocationController::class, 'delete'])->name('store-locations.delete');
        Route::post('update-status', [\App\Http\Controllers\API\StoreLocationController::class, 'updateStatus'])->name('store-locations.update-status');
    });

   

    Route::group(['prefix' => 'fund_transfers'], function () {
        Route::get('/', [\App\Http\Controllers\API\FundTransfersApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\FundTransfersApiController::class, 'save'])->name('fund_transfers.save');
    });

    Route::group(['prefix' => 'cash_collection'], function () {
        Route::get('/', [\App\Http\Controllers\API\CashCollectionApiController::class, 'getCashCollection']);
        Route::post('save', [\App\Http\Controllers\API\CashCollectionApiController::class, 'save'])->name('cash_collection.save');
    });

    Route::group(['prefix' => 'front_end_policies'], function () {
        Route::get('/', [\App\Http\Controllers\API\FrontEndPoliciesApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\FrontEndPoliciesApiController::class, 'save'])->name('front_end_policies.save');
    });

    Route::group(['prefix' => 'web_settings'], function () {
        Route::get('/', [\App\Http\Controllers\API\WebSettingsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\WebSettingsApiController::class, 'save'])->name('web_settings.save');
    });

    Route::group(['prefix' => 'front_end_about'], function () {
        Route::get('/', [\App\Http\Controllers\API\FrontEndAboutApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\FrontEndAboutApiController::class, 'save'])->name('front_end_about.save');
    });

    Route::group(['prefix' => 'social_media'], function () {
        Route::get('/', [\App\Http\Controllers\API\SocialMediaApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\SocialMediaApiController::class, 'save'])->name('social_media.save');;
        Route::post('update', [\App\Http\Controllers\API\SocialMediaApiController::class, 'update'])->name('social_media.update');
        Route::post('delete', [\App\Http\Controllers\API\SocialMediaApiController::class, 'delete'])->name('social_media.delete');
    });

    Route::group(['prefix' => 'customers'], function () {
        Route::get('/', [\App\Http\Controllers\API\CustomersApiController::class, 'getCustomers']);
        Route::get('/{id}', [\App\Http\Controllers\API\CustomersApiController::class, 'getCustomer']);
        Route::get('/{id}/analytics', [\App\Http\Controllers\API\CustomersApiController::class, 'getCustomerAnalytics']);
        Route::get('/{id}/transactions', [\App\Http\Controllers\API\TransactionsApiController::class, 'getCustomerTransactions']);
        Route::post('change', [\App\Http\Controllers\API\CustomersApiController::class, 'changeStatus'])->name('customers.change');
        Route::post('/{id}/update', [\App\Http\Controllers\API\CustomersApiController::class, 'updateCustomer'])->name('customers.update');
    });

    // Admin-Customer Chat Routes
    Route::group(['prefix' => 'customer-chat'], function () {
        Route::get('/', [\App\Http\Controllers\API\AdminCustomerChatController::class, 'getAllChats']);
        Route::get('/{customerId}/messages', [\App\Http\Controllers\API\AdminCustomerChatController::class, 'getMessages']);
        Route::post('/initialize', [\App\Http\Controllers\API\AdminCustomerChatController::class, 'initializeChat']);
        Route::post('/send', [\App\Http\Controllers\API\AdminCustomerChatController::class, 'sendMessage']);
        Route::post('/mark-read', [\App\Http\Controllers\API\AdminCustomerChatController::class, 'markAsRead']);
        Route::post('/delete', [\App\Http\Controllers\API\AdminCustomerChatController::class, 'deleteChat']);
    });

    // Customer Suggestions Routes
    Route::group(['prefix' => 'admin/customer-suggestions'], function () {
        Route::get('/', [\App\Http\Controllers\API\Admin\CustomerSuggestionController::class, 'index']);
        Route::post('/{id}/respond', [\App\Http\Controllers\API\Admin\CustomerSuggestionController::class, 'respond']);
    });

    // Admin-Delivery Boy Chat Routes
    Route::group(['prefix' => 'delivery-boy-chat'], function () {
        Route::get('/', [\App\Http\Controllers\API\AdminDeliveryBoyChatController::class, 'getAllChats']);
        Route::get('/{deliveryBoyId}/messages', [\App\Http\Controllers\API\AdminDeliveryBoyChatController::class, 'getMessages']);
        Route::post('/initialize', [\App\Http\Controllers\API\AdminDeliveryBoyChatController::class, 'initializeChat']);
        Route::post('/send', [\App\Http\Controllers\API\AdminDeliveryBoyChatController::class, 'sendMessage']);
        Route::post('/mark-read', [\App\Http\Controllers\API\AdminDeliveryBoyChatController::class, 'markAsRead']);
        Route::post('/delete', [\App\Http\Controllers\API\AdminDeliveryBoyChatController::class, 'deleteChat']);
    });

    // Admin-Seller Chat Routes
    Route::group(['prefix' => 'seller-chat'], function () {
        Route::get('/', [\App\Http\Controllers\API\AdminSellerChatController::class, 'getAllChats']);
        Route::get('/{sellerId}/messages', [\App\Http\Controllers\API\AdminSellerChatController::class, 'getMessages']);
        Route::post('/initialize', [\App\Http\Controllers\API\AdminSellerChatController::class, 'initializeChat']);
        Route::post('/send', [\App\Http\Controllers\API\AdminSellerChatController::class, 'sendMessage']);
        Route::post('/mark-read', [\App\Http\Controllers\API\AdminSellerChatController::class, 'markAsRead']);
        Route::post('/delete', [\App\Http\Controllers\API\AdminSellerChatController::class, 'deleteChat']);
    });

    Route::group(['prefix' => 'wallet_transactions'], function () {
        Route::get('/', [\App\Http\Controllers\API\WalletTransactionsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\WalletTransactionsApiController::class, 'save'])->name('wallet_transactions.save');
        Route::post('create_phonepe_transaction', [\App\Http\Controllers\API\WalletTransactionsApiController::class, 'createPhonePeTransaction'])->name('wallet_transactions.create_phonepe_transaction');
        Route::post('verify_phonepe_transaction', [\App\Http\Controllers\API\WalletTransactionsApiController::class, 'verifyPhonePeTransaction'])->name('wallet_transactions.verify_phonepe_transaction');
    });

    // PhonePe Payment Routes (Alternative endpoints using PhonePeController)
    Route::group(['prefix' => 'phonepe'], function () {
        Route::post('initiate-payment', [\App\Http\Controllers\API\PhonePeController::class, 'initiatePayment'])->name('phonepe.initiate');
        Route::post('check-status', [\App\Http\Controllers\API\PhonePeController::class, 'checkStatus'])->name('phonepe.status');
        Route::post('redirect', [\App\Http\Controllers\API\PhonePeController::class, 'redirect'])->name('phonepe.redirect');
    });

    // Paytm Payment Routes (Callback route is defined outside auth middleware above)
    Route::group(['prefix' => 'paytm'], function () {
        Route::post('verify-payment', [\App\Http\Controllers\API\PaytmPaymentController::class, 'verifyPayment'])->name('paytm.verify');
        Route::post('check-status', [\App\Http\Controllers\API\PaytmPaymentController::class, 'checkStatus'])->name('paytm.status');

        // TEST ROUTES - FOR DEVELOPMENT ONLY (Remove in production)
        Route::group(['prefix' => 'test'], function () {
            Route::post('create-mock-payment', [\App\Http\Controllers\API\PaytmTestController::class, 'createMockPayment'])->name('paytm.test.create');
            Route::get('transactions', [\App\Http\Controllers\API\PaytmTestController::class, 'getTestTransactions'])->name('paytm.test.list');
            Route::delete('clear-transactions', [\App\Http\Controllers\API\PaytmTestController::class, 'clearTestTransactions'])->name('paytm.test.clear');
        });
    });

    // Paytm Transactions Management (Admin)
    Route::group(['prefix' => 'paytm_transactions'], function () {
        Route::get('/', [\App\Http\Controllers\API\PaytmTransactionsApiController::class, 'index'])->name('paytm_transactions.index');
        Route::get('/{id}', [\App\Http\Controllers\API\PaytmTransactionsApiController::class, 'show'])->name('paytm_transactions.show');
        Route::get('/export/csv', [\App\Http\Controllers\API\PaytmTransactionsApiController::class, 'export'])->name('paytm_transactions.export');
        Route::get('/filter/users', [\App\Http\Controllers\API\PaytmTransactionsApiController::class, 'getUsers'])->name('paytm_transactions.users');
    });

    Route::group(['prefix' => 'transactions'], function () {
        Route::get('/', [\App\Http\Controllers\API\TransactionsApiController::class, 'index']);
    });
    Route::group(['prefix' => 'wishlists'], function () {
        Route::get('/', [\App\Http\Controllers\API\WishlistsApiController::class, 'index']);
        Route::post('send-notification', [\App\Http\Controllers\API\WishlistsApiController::class, 'sendNotification']);
        Route::post('send-notification-to-users', [\App\Http\Controllers\API\WishlistsApiController::class, 'sendNotificationToUsers']);
    });

    Route::group(['prefix' => 'system_users'], function () {
        Route::get('/', [\App\Http\Controllers\API\SystemUsersApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\SystemUsersApiController::class, 'save'])->name('system_users.save');
        Route::post('update', [\App\Http\Controllers\API\SystemUsersApiController::class, 'update'])->name('system_users.update');
        Route::post('delete', [\App\Http\Controllers\API\SystemUsersApiController::class, 'delete'])->name('system_users.delete');
        Route::post('change_password', [\App\Http\Controllers\API\SystemUsersApiController::class, 'changePassword'])->name('system_users.change_password');
    });

    Route::group(['prefix' => 'withdrawal_requests'], function () {
        Route::get('/', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'index']);
        Route::post('update', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'update'])->name('withdrawal_requests.update');
        Route::post('delete', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'delete'])->name('withdrawal_requests.delete');

        Route::post('/add', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'addWithdrawalRequests']);
        Route::get('get', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'getWithdrawalRequests']);
        Route::get('get_balance', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'getBalance']);
    });

    Route::group(['prefix' => 'return_requests'], function () {
        Route::get('/', [\App\Http\Controllers\API\ReturnRequestsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\ReturnRequestsApiController::class, 'save'])->name('return_requests.save');
        Route::post('update', [\App\Http\Controllers\API\ReturnRequestsApiController::class, 'update'])->name('return_requests.update');
        Route::post('delete', [\App\Http\Controllers\API\ReturnRequestsApiController::class, 'delete'])->name('return_requests.delete');
        Route::post('delivery_boy', [\App\Http\Controllers\API\ReturnRequestsApiController::class, 'deliveryBoyReturnRequests'])->name('return_requests.delivery_boy');
    });

    Route::group(['prefix' => 'customer_issue_reports'], function () {
        Route::get('/', [\App\Http\Controllers\API\CustomerIssueReportsApiController::class, 'getReports']);
        Route::get('show', [\App\Http\Controllers\API\CustomerIssueReportsApiController::class, 'show']);
        Route::get('by_order', [\App\Http\Controllers\API\CustomerIssueReportsApiController::class, 'getReportsByOrderId']);
        Route::post('update', [\App\Http\Controllers\API\CustomerIssueReportsApiController::class, 'update'])->name('customer_issue_reports.update');
        Route::post('delete', [\App\Http\Controllers\API\CustomerIssueReportsApiController::class, 'delete'])->name('customer_issue_reports.delete');
        Route::post('update_zenfoo_return', [\App\Http\Controllers\API\CustomerIssueReportsApiController::class, 'updateZenfooReturnStatus'])->name('customer_issue_reports.update_zenfoo_return');
    });

    Route::group(['prefix' => 'sales_reports'], function () {
        Route::get('/', [\App\Http\Controllers\API\SalesReportsApiController::class, 'getSalesReport']);
        Route::get('/export_excel', [\App\Http\Controllers\API\SalesReportsApiController::class, 'excelSalesReport']);

    });

    Route::group(['prefix' => 'product_sales_reports'], function () {
        Route::get('/', [\App\Http\Controllers\API\ProductSalesReportsApiController::class, 'getProductSalesReport']);
    });

    Route::group(['prefix' => 'order_statuses'], function () {
        Route::get('/', [\App\Http\Controllers\API\OrderStatusApiController::class, 'getOrderStatus']);
        Route::get('/self_pickup', [\App\Http\Controllers\API\OrderStatusApiController::class, 'getSelfPickupOrderStatus']);
        Route::get('/processing', [\App\Http\Controllers\API\OrderStatusApiController::class, 'getProcessingOrderStatus']);
    });

    // Order Analytics
    Route::get('order-analytics', [\App\Http\Controllers\API\Admin\OrderAnalyticsController::class, 'getAnalytics']);
    Route::get('order-analytics/export-excel', [\App\Http\Controllers\API\Admin\OrderAnalyticsController::class, 'exportExcel']);
    Route::get('order-analytics/export-pdf', [\App\Http\Controllers\API\Admin\OrderAnalyticsController::class, 'exportPdf']);

    // User Analytics
    Route::get('user-analytics', [\App\Http\Controllers\API\Admin\UserAnalyticsController::class, 'getAnalytics']);
    Route::get('user-analytics/export-excel', [\App\Http\Controllers\API\Admin\UserAnalyticsController::class, 'exportExcel']);
    Route::get('user-analytics/export-pdf', [\App\Http\Controllers\API\Admin\UserAnalyticsController::class, 'exportPdf']);

    // Seller Analytics (All Sellers - Sidebar)
    Route::get('seller-analytics', [\App\Http\Controllers\API\Admin\SellerAnalyticsController::class, 'getAllSellersAnalytics']);

    // Merchant Analytics (Overview - Sidebar)
    Route::get('merchant-analytics/overview', [\App\Http\Controllers\API\Admin\SellerAnalyticsController::class, 'getMerchantOverview']);
    Route::get('merchant-analytics/export-excel', [\App\Http\Controllers\API\Admin\SellerAnalyticsController::class, 'exportMerchantExcel']);
    Route::get('merchant-analytics/export-pdf', [\App\Http\Controllers\API\Admin\SellerAnalyticsController::class, 'exportMerchantPdf']);

    // Delivery Boy Analytics (All Delivery Boys - Sidebar)
    Route::get('delivery-boy-analytics', [\App\Http\Controllers\API\Admin\DeliveryBoyAnalyticsController::class, 'getAllDeliveryBoysAnalytics']);

    // Seller Analytics (Individual Seller - Tab)
    Route::get('sellers/view/{id}/analytics', [\App\Http\Controllers\API\Admin\SellerAnalyticsController::class, 'getAnalytics']);
    Route::get('sellers/view/{id}/analytics/export-excel', [\App\Http\Controllers\API\Admin\SellerAnalyticsController::class, 'exportExcel']);
    Route::get('sellers/view/{id}/analytics/export-pdf', [\App\Http\Controllers\API\Admin\SellerAnalyticsController::class, 'exportPdf']);

    // Delivery Boy Analytics
    Route::get('delivery_boys/view/{id}/analytics', [\App\Http\Controllers\API\Admin\DeliveryBoyAnalyticsController::class, 'getAnalytics']);
    Route::get('delivery_boys/view/{id}/analytics/export-excel', [\App\Http\Controllers\API\Admin\DeliveryBoyAnalyticsController::class, 'exportExcel']);
    Route::get('delivery_boys/view/{id}/analytics/export-pdf', [\App\Http\Controllers\API\Admin\DeliveryBoyAnalyticsController::class, 'exportPdf']);

    Route::group(['prefix' => 'orders'], function () {
        //Route::get('/', [\App\Http\Controllers\API\OrdersApiController::class, 'index']);
        Route::get('/', [\App\Http\Controllers\API\OrdersApiController::class, 'getOrders']);
        Route::get('/status-counts', [\App\Http\Controllers\API\OrdersApiController::class, 'getOrderStatusCounts']);
        Route::get('/self_pickup', [\App\Http\Controllers\API\OrdersApiController::class, 'getSelfPickupOrders']);
        Route::get('/view/{id}', [\App\Http\Controllers\API\OrdersApiController::class, 'view']);
        Route::get('/invoice-details/{id}', [\App\Http\Controllers\API\OrdersApiController::class, 'getInvoiceDetails']);

        Route::get('invoice', [\App\Http\Controllers\API\OrdersApiController::class, 'generateOrderInvoice']);
        Route::post('invoice_download', [\App\Http\Controllers\API\OrdersApiController::class, 'downloadOrderInvoice']);

        Route::post('/delete', [\App\Http\Controllers\API\OrdersApiController::class, 'delete'])->name('orders.delete');
        Route::post('/delete_item', [\App\Http\Controllers\API\OrdersApiController::class, 'deleteItem'])->name('orders.deleteItem');
        Route::get('/weekly_sales', [\App\Http\Controllers\API\OrdersApiController::class, 'getWeeklySales']);
        Route::get('/weekly_returns', [\App\Http\Controllers\API\OrdersApiController::class, 'getWeeklyReturns']);

        Route::post('/update_status', [\App\Http\Controllers\API\OrdersApiController::class, 'updateStatus'])->name('orders.update_status');
        Route::post('/update_self_pickup_status', [\App\Http\Controllers\API\OrdersApiController::class, 'updateSelfPickupOrderStatus'])->name('orders.update_self_pickup_status');
        Route::post('/assign_delivery_boy', [\App\Http\Controllers\API\OrdersApiController::class, 'assignDeliveryBoy'])->name('orders.assign_delivery_boy');
        Route::post('/admin_assign_delivery_boy', [\App\Http\Controllers\API\OrdersApiController::class, 'adminAssignDeliveryBoy'])->name('orders.admin_assign_delivery_boy');

        // Emergency Driver Change
        Route::post('/search_driver_by_phone', [\App\Http\Controllers\API\OrdersApiController::class, 'searchDriverByPhone'])->name('orders.search_driver_by_phone');
        Route::post('/find_nearby_drivers', [\App\Http\Controllers\API\OrdersApiController::class, 'findNearbyDrivers'])->name('orders.find_nearby_drivers');
        Route::post('/emergency_change_driver', [\App\Http\Controllers\API\OrdersApiController::class, 'emergencyChangeDriver'])->name('orders.emergency_change_driver');

        Route::post('/update_items_status', [\App\Http\Controllers\API\OrdersApiController::class, 'updateItemsStatus'])->name('orders.update_items_status');
        Route::post('/assign-seller', [\App\Http\Controllers\API\OrdersApiController::class, 'assignSeller'])->name('orders.assign_seller');
        Route::post('/admin_cancel_order', [\App\Http\Controllers\API\OrdersApiController::class, 'adminCancelOrder'])->name('orders.admin_cancel_order');
        Route::get('/cancel_reasons', [\App\Http\Controllers\API\OrdersApiController::class, 'cancelReasons'])->name('orders.cancel_reasons');
        Route::get('/stuck_orders', [\App\Http\Controllers\API\OrdersApiController::class, 'stuckOrders'])->name('orders.stuck_orders');
        Route::post('/cancelled_order_stores', [\App\Http\Controllers\API\OrdersApiController::class, 'cancelledOrderStores'])->name('orders.cancelled_order_stores');
        Route::post('/pay_store_for_cancelled_order', [\App\Http\Controllers\API\OrdersApiController::class, 'payStoreForCancelledOrder'])->name('orders.pay_store_for_cancelled_order');

    });

    // Product Order Policy routes
    Route::group(['prefix' => 'product-policy'], function () {
        Route::get('/return', [\App\Http\Controllers\API\ProductOrderPolicyController::class, 'checkReturn']);
        Route::get('/cancel', [\App\Http\Controllers\API\ProductOrderPolicyController::class, 'checkCancel']);
        Route::get('/check',  [\App\Http\Controllers\API\ProductOrderPolicyController::class, 'checkBoth']);
    });

    Route::group(['prefix' => 'orders'], function () {

        // Driver notifications routes
        Route::get('/{id}/driver-notifications', [\App\Http\Controllers\API\OrdersApiController::class, 'getDriverNotifications']);
        Route::post('/{id}/retry-driver-notification', [\App\Http\Controllers\API\OrdersApiController::class, 'retryDriverNotification']);

        // Zenfoo store items tracking route
        Route::get('/{id}/zenfoo-store-tracking', [\App\Http\Controllers\API\ZenfooStoreItemsController::class, 'getZenfooStoreTracking']);
        Route::post('/{id}/zenfoo-update-prep-time', [\App\Http\Controllers\API\ZenfooStoreItemsController::class, 'updatePrepTime']);
        Route::post('/{id}/zenfoo-mark-as-packed', [\App\Http\Controllers\API\ZenfooStoreItemsController::class, 'markAsPacked']);
        Route::post('/{id}/zenfoo-verify-otp', [\App\Http\Controllers\API\ZenfooStoreItemsController::class, 'verifyOtp']);
    });

});

// Test route - no auth (remove after testing)
Route::post('test/orders/{id}/retry-driver-job', [\App\Http\Controllers\API\OrdersApiController::class, 'testRetryDriverJob']);

// Re-open admin group for remaining routes
Route::group(['prefix' => 'admin', 'middleware' => ['auth:api']], function () {
    // PreOrders Routes
    Route::group(['prefix' => 'preorders'], function () {
        Route::get('/', [\App\Http\Controllers\API\PreOrderController::class, 'getPreOrders']);
        Route::get('/stats', [\App\Http\Controllers\API\PreOrderController::class, 'getPreOrderStats']);
        Route::get('/store-wise-analytics', [\App\Http\Controllers\API\PreOrderController::class, 'getStoreWiseAnalytics']);
        Route::get('/view/{id}', [\App\Http\Controllers\API\PreOrderController::class, 'getPreOrderDetails']);
        Route::get('/store-orders', [\App\Http\Controllers\API\PreOrderController::class, 'getStoreOrders']);
        Route::post('/assign-sellers', [\App\Http\Controllers\API\PreOrderController::class, 'assignSellers']);
    });

    Route::get('/sellers/by-store/{store_id}', [\App\Http\Controllers\API\SellerApiController::class, 'getSellersByStore']);

    // NOTE: Role management routes moved to top-level /api/role/* (see near the `role` index
    // route above) to match the frontend, which posts to /api/role/save — not /api/admin/role/save.


    Route::group(['prefix' => 'media'], function () {
        Route::get('/', [\App\Http\Controllers\API\MediaApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\MediaApiController::class, 'save'])->name('media.save');
        Route::post('delete', [\App\Http\Controllers\API\MediaApiController::class, 'delete'])->name('media.delete');
        Route::post('multiple_delete', [\App\Http\Controllers\API\MediaApiController::class, 'multipleDelete'])->name('media.multiple_delete');
    });

    Route::group(['prefix' => 'seller_wallet_transactions'], function () {
        Route::get('/', [\App\Http\Controllers\API\SellerWalletTransactionsApiController::class, 'getSellerWalletTransactions']);
        Route::post('save', [\App\Http\Controllers\API\SellerWalletTransactionsApiController::class, 'save'])->name('seller_wallet_transactions.save');

    });

    // Seller Transactions for Admin Panel (by seller ID)
    Route::get('seller_transactions', [\App\Http\Controllers\API\SellerTransactionsController::class, 'getTransactions']);

    Route::group(['prefix' => 'shipping_methods'], function () {
        Route::get('/', [\App\Http\Controllers\API\ShippingMethodsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\ShippingMethodsApiController::class, 'save'])->name('shipping_methods.save');
    });
    Route::post('shiprocket_webhook', [\App\Http\Controllers\API\ShippingMethodsApiController::class, 'shiprocket_webhook']);

    Route::group(['prefix' => 'newsletter'], function () {
        Route::get('/', [\App\Http\Controllers\API\NewsletterApiController::class, 'index']);
    });

    Route::group(['prefix' => 'seller_commissions'], function () {
        Route::get('/', [\App\Http\Controllers\API\SellerCommissionsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\SellerCommissionsApiController::class, 'save'])->name('seller_commissions.save');
        Route::get('edit/{id}', [\App\Http\Controllers\API\SellerCommissionsApiController::class, 'edit']);
        Route::post('update', [\App\Http\Controllers\API\SellerCommissionsApiController::class, 'update'])->name('seller_commissions.update');
        Route::post('delete', [\App\Http\Controllers\API\SellerCommissionsApiController::class, 'delete'])->name('seller_commissions.delete');
        Route::get('formData/{id}', [\App\Http\Controllers\API\SellerCommissionsApiController::class, 'formData']);
    });
    // Route::get('countries', [\App\Http\Controllers\API\CountryApiController::class, 'index']);
    Route::group(['prefix' => 'cities'], function () {
        Route::get('/', [\App\Http\Controllers\API\CityApiController::class, 'getCities']);
        Route::post('save', [\App\Http\Controllers\API\CityApiController::class, 'save'])->name('cities.save');
        Route::post('save_boundary', [\App\Http\Controllers\API\CityApiController::class, 'save_boundary'])->name('cities.save_boundary');
        Route::get('edit/{id}', [\App\Http\Controllers\API\CityApiController::class, 'edit']);
        Route::post('update', [\App\Http\Controllers\API\CityApiController::class, 'update'])->name('cities.update');
        Route::post('delete', [\App\Http\Controllers\API\CityApiController::class, 'delete'])->name('cities.delete');
    });

    Route::group(['prefix' => 'faqs'], function () {
        Route::get('/', [\App\Http\Controllers\API\FaqsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\FaqsApiController::class, 'save'])->name('faqs.save');
        Route::post('update', [\App\Http\Controllers\API\FaqsApiController::class, 'update'])->name('faqs.update');
        Route::post('delete', [\App\Http\Controllers\API\FaqsApiController::class, 'delete'])->name('faqs.delete');
    });


    Route::group(['prefix' => 'languages'], function () {
        Route::get('/', [\App\Http\Controllers\API\LanguageApiController::class, 'index']);
        Route::get('supported_languages', [\App\Http\Controllers\API\LanguageApiController::class, 'getSupportedLanguages']);
        Route::post('save', [\App\Http\Controllers\API\LanguageApiController::class, 'save'])->name('languages.save');
        Route::post('update', [\App\Http\Controllers\API\LanguageApiController::class, 'update'])->name('languages.update');
        Route::post('delete', [\App\Http\Controllers\API\LanguageApiController::class, 'delete'])->name('languages.delete');
    });

    Route::group(['prefix' => 'countries'], function () {
        Route::get('/', [\App\Http\Controllers\API\CountryApiController::class, 'index']);
        Route::get('/active', [\App\Http\Controllers\API\CountryApiController::class, 'active']);
        Route::post('save', [\App\Http\Controllers\API\CountryApiController::class, 'save'])->name('countries.save');
        Route::post('update', [\App\Http\Controllers\API\CountryApiController::class, 'update'])->name('countries.update');
        Route::post('delete', [\App\Http\Controllers\API\CountryApiController::class, 'delete'])->name('countries.delete');
    });


    Route::group(['prefix' => 'panel_notification'], function () {
        Route::get('/', [\App\Http\Controllers\API\NotificationPanelApiController::class, 'getNotifications']);
    });

    Route::get('set_seller_wallet_transaction', [\App\Http\Controllers\Controller::class, 'setSellerWalletTransaction']);
    //Route::get('database_backup', [App\Http\Controllers\DatabaseBackupController::class, 'download'])->name('database_backup.download');
    Route::get('database_backup_download', [App\Http\Controllers\DatabaseBackupController::class, 'download_db_backup'])->name('database_backup_download.download_db_backup');

}); // end of admin prefix group


/*Seller*/
/***********************************************************************************************/

Route::middleware('auth:api')->group(function () {
    Route::group(['prefix' => 'seller'], function () {
        /*Dashboard*/
        Route::get('dashboard', [\App\Http\Controllers\SellerController::class, 'index']);
        Route::get('get_products', [\App\Http\Controllers\API\ProductApisController::class, 'getProducts_sellerapp']);
        Route::post('update_seller_status', [\App\Http\Controllers\API\SellerApiController::class, 'updateStatus'])->name('sellers.update_seller_status');
        Route::post('get_seller_status', [\App\Http\Controllers\API\SellerApiController::class, 'getStatus'])->name('sellers.get_seller_status');
        Route::post('details', [\App\Http\Controllers\API\AdminAuthController::class, 'saveSellerDetails'])->name('sellers.details');
         // Point of Sale Routes
        Route::group(['prefix' => 'pos'], function () {
            Route::get('users', [\App\Http\Controllers\API\SellerPosController::class, 'getUsersList']);
            Route::post('register_user', [\App\Http\Controllers\API\SellerPosController::class, 'registerUser']);
            Route::post('place_order', [\App\Http\Controllers\API\SellerPosController::class, 'placeOrder']);
            Route::post('update_order', [\App\Http\Controllers\API\SellerPosController::class, 'updateOrder']);
            Route::get('products', [\App\Http\Controllers\API\SellerPosController::class, 'getProducts']);
            Route::get('categories', [\App\Http\Controllers\API\SellerPosController::class, 'getSellerCategories']);
            Route::get('store-name', [\App\Http\Controllers\API\SellerPosController::class, 'getSellerStoreName']);
        });
        Route::get('products/product_info', [\App\Http\Controllers\SellerController::class, 'getProducts']);
        Route::get('orders/weekly_sales', [\App\Http\Controllers\SellerController::class, 'getWeeklySales']);
        Route::get('/seller_categories_list', [\App\Http\Controllers\API\CategoryApiController::class, 'getCategories']);
        Route::get('categories/product_count', [\App\Http\Controllers\SellerController::class, 'countProductCategoryWise']);
        Route::get('orders', [\App\Http\Controllers\SellerController::class, 'getOrders']);
        Route::get('seller_orders', [\App\Http\Controllers\API\OrdersApiController::class, 'getSellerOrders']);
        Route::get('self_pickup_orders', [\App\Http\Controllers\SellerController::class, 'getSelfPickupOrders']);
        Route::post('update_self_pickup_status', [\App\Http\Controllers\API\OrdersApiController::class, 'updateSelfPickupOrderStatus'])->name('orders.update_self_pickup_status');

        Route::get('order_by_id', [\App\Http\Controllers\SellerController::class, 'getOrder']);

        Route::post('update_status', [\App\Http\Controllers\API\OrdersApiController::class, 'updateStatus'])->name('seller.update_status');
        Route::post('assign_delivery_boy', [\App\Http\Controllers\API\OrdersApiController::class, 'assignDeliveryBoy'])->name('seller.assign_delivery_boy');

        Route::get('order_statuses', [\App\Http\Controllers\SellerController::class, 'getOrderStatus']);
        Route::get('self_pickup_order_statuses', [\App\Http\Controllers\API\OrderStatusApiController::class, 'getSelfPickupOrderStatus']);
        Route::get('return_requests', [\App\Http\Controllers\API\ReturnRequestsApiController::class, 'sellerIndex']);
        Route::post('return_request_status_update', [\App\Http\Controllers\API\ReturnRequestsApiController::class, 'sellerUpdate'])->name('seller.return_requests.update');
        Route::post('return_requests_delete', [\App\Http\Controllers\API\ReturnRequestsApiController::class, 'sellerDelete'])->name('seller.return_requests.delete');
        Route::get('product_sales_reports', [\App\Http\Controllers\SellerController::class, 'getProductSalesReport']);
        Route::get('sales_reports', [\App\Http\Controllers\SellerController::class, 'getSalesReport']);
        Route::get('/reports', [App\Http\Controllers\SellerController::class, 'getReports']);
        Route::get('/orders/{orderId}/items', [App\Http\Controllers\SellerController::class, 'getOrderItems']);
        Route::get('settings', [\App\Http\Controllers\SellerController::class, 'getSettings']);
        Route::get('delivery_boys', [\App\Http\Controllers\SellerController::class, 'getDeliveryBoys']);

        Route::get('main_categories', [\App\Http\Controllers\SellerController::class, 'getMainCategories']);
        Route::get('seller_categories', [\App\Http\Controllers\API\CategoryApiController::class, 'getSellerCategories']);

        Route::get('city', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getCity']);

        Route::get('countries', [\App\Http\Controllers\API\CountryApiController::class, 'getCountries']);


        Route::group(['prefix' => 'brands'], function () {
            Route::get('/', [\App\Http\Controllers\API\BrandsApiController::class, 'getBrands']);
            Route::post('save', [\App\Http\Controllers\API\BrandsApiController::class, 'save'])->name('seller.brands.save');
            Route::post('update', [\App\Http\Controllers\API\BrandsApiController::class, 'update'])->name('brands.update');
            Route::post('delete', [\App\Http\Controllers\API\BrandsApiController::class, 'delete'])->name('brands.delete');
        });

        Route::group(['prefix' => 'units'], function () {
            Route::get('/', [\App\Http\Controllers\API\UnitApiController::class, 'getUnits']);
            Route::post('save', [\App\Http\Controllers\API\UnitApiController::class, 'save'])->name('units.save');
            Route::post('update', [\App\Http\Controllers\API\UnitApiController::class, 'update'])->name('units.update');
            Route::post('delete', [\App\Http\Controllers\API\UnitApiController::class, 'delete'])->name('units.delete');
        });

         Route::group(['prefix' => 'taxes'], function () {
            Route::get('/', [\App\Http\Controllers\API\TaxesApiController::class, 'getTaxes']);
            Route::post('save', [\App\Http\Controllers\API\TaxesApiController::class, 'save'])->name('taxes.save');
            Route::post('update', [\App\Http\Controllers\API\TaxesApiController::class, 'update'])->name('taxes.update');
            Route::post('delete', [\App\Http\Controllers\API\TaxesApiController::class, 'delete'])->name('taxes.delete');
        });

        Route::group(['prefix' => 'mail_settings'], function () {
            Route::get('/', [\App\Http\Controllers\API\MailSettingsApiController::class, 'index']);
            Route::post('save', [\App\Http\Controllers\API\MailSettingsApiController::class, 'save'])->name('seller.mail_settings.save');
        });

        Route::group(['prefix' => 'products'], function () {
            Route::get('/', [\App\Http\Controllers\API\ProductApisController::class, 'getProducts']);
            Route::get('active', [\App\Http\Controllers\API\ProductApisController::class, 'getActiveProducts']);
            Route::get('/product_by_id', [\App\Http\Controllers\API\ProductApisController::class, 'getProduct']);
            Route::post('save', [\App\Http\Controllers\API\ProductApisController::class, 'save'])->name('products.save');
            Route::get('edit/{id}', [\App\Http\Controllers\API\ProductApisController::class, 'edit']);
            Route::post('update', [\App\Http\Controllers\API\ProductApisController::class, 'update'])->name('products.update');
            Route::post('delete', [\App\Http\Controllers\API\ProductApisController::class, 'delete'])->name('products.delete');
            Route::post('multiple_delete', [\App\Http\Controllers\API\ProductApisController::class, 'multipleDelete'])->name('products.multiple_delete');
            Route::get('/brands', [\App\Http\Controllers\API\BrandsApiController::class, 'index']);
            Route::get('/taxes', [\App\Http\Controllers\API\TaxesApiController::class, 'index']);
            Route::get('ratings_list', [\App\Http\Controllers\API\ProductApisController::class, 'productRatingsList']);
            Route::get('/tags', [\App\Http\Controllers\API\TagsApiController::class, 'search']);
            Route::post('bulk_upload', [\App\Http\Controllers\API\ProductApisController::class, 'bulkUpload'])->name('products.bulk_upload');
            Route::get('download_product_data_excel', [\App\Http\Controllers\API\ProductApisController::class, 'downloadProductDataExcel']);
            Route::post('bulk_update', [\App\Http\Controllers\API\ProductApisController::class, 'bulkUpdate'])->name('products.bulk_update');
            Route::get('get_product_variants', [\App\Http\Controllers\API\ProductApisController::class, 'getProductVariants']);
            Route::post('update_variant_stock', [\App\Http\Controllers\API\ProductApisController::class, 'updateVariantStock']);
        });
        Route::get('/seller_wallet_transactions', [\App\Http\Controllers\API\SellerWalletTransactionsApiController::class, 'getSellerWalletTransactions']);
        Route::post('/delete_seller_account', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'deleteSellerAccount'])->name('seller.delete_seller_account');
        Route::group(['prefix' => 'withdrawal_requests'], function () {
            Route::get('/', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'index']);
            Route::post('update', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'update'])->name('withdrawal_requests.update');
            Route::post('delete', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'delete'])->name('withdrawal_requests.delete');

            Route::post('/add', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'addWithdrawalRequests']);
            Route::get('get', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'getWithdrawalRequests']);
            Route::get('get_balance', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'getBalance']);
        });
        Route::post('/google_gemini', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'googleGeminiAI']);

    });
}); // end of seller auth:api group


/*delivery_boy*/
/***********************************************************************************************/

Route::middleware('auth:api')->group(function () {
    Route::group(['prefix' => 'delivery_boy'], function () {
        Route::get('dashboard', [\App\Http\Controllers\DeliveryBoyController::class, 'index']);
        Route::get('orders', [\App\Http\Controllers\DeliveryBoyController::class, 'getOrders']);
        Route::get('order_by_id', [\App\Http\Controllers\DeliveryBoyController::class, 'getOrder']);
        Route::post('update_status', [\App\Http\Controllers\API\OrdersApiController::class, 'updateStatus'])->name('delivery_boy.update_status');
        Route::get('order_statuses', [\App\Http\Controllers\DeliveryBoyController::class, 'getOrderStatus']);
        Route::post('details', [\App\Http\Controllers\API\AdminAuthController::class, 'saveDeliveryBoyDetails'])->name('delivery_boy.details');
        Route::get('get-personal-details', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'getPersonalDetails'])->name('delivery_boy.get_personal_details');
        Route::post('update-profile', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'updateProfile'])->name('delivery_boy.update_profile');
        Route::post('update-profile-image', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'updateProfileImage'])->name('delivery_boy.update_profile_image');
        Route::get('nearby-cities', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'getNearbyCities'])->name('delivery_boy.nearby_cities');
        Route::get('vehicles', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'getVehicles'])->name('delivery_boy.vehicles');
        Route::post('select-vehicle', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'selectVehicle'])->name('delivery_boy.select_vehicle');
        Route::post('update-city', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'updateCity'])->name('delivery_boy.update_city');
        Route::get('store-locations', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'getStoreLocations'])->name('delivery_boy.store_locations');
        Route::post('select-store-locations', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'selectStoreLocations'])->name('delivery_boy.select_store_locations');

        // Order Priority APIs
        Route::get('get-order-priority', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'getOrderPriority'])->name('delivery_boy.get_order_priority');
        Route::post('update-order-priority', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'updateOrderPriority'])->name('delivery_boy.update_order_priority');

        // FCM Token API
        Route::post('update-fcm-token', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'updateFcmToken'])->name('delivery_boy.update_fcm_token');

        // Mobile Update API (OTP based)
        Route::get('get-mobile', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'getMobile'])->name('delivery_boy.get_mobile');
        Route::post('send-mobile-update-otp', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'sendMobileUpdateOtp'])->name('delivery_boy.send_mobile_update_otp');
        Route::post('verify-mobile-update-otp', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'verifyMobileUpdateOtp'])->name('delivery_boy.verify_mobile_update_otp');

        // Referral Tracking API
        Route::get('referral-tracking', [\App\Http\Controllers\API\DeliveryBoy\LoginController::class, 'getReferralTracking'])->name('delivery_boy.referral_tracking');

        // Document APIs
        Route::post('upload-all-documents', [\App\Http\Controllers\API\DeliveryBoy\DocumentController::class, 'uploadAllDocuments'])->name('delivery_boy.upload_all_documents');
        Route::post('update-documents', [\App\Http\Controllers\API\DeliveryBoy\DocumentController::class, 'updateDocuments'])->name('delivery_boy.update_documents');
        Route::get('get-driving-license', [\App\Http\Controllers\API\DeliveryBoy\DocumentController::class, 'getDrivingLicense'])->name('delivery_boy.get_driving_license');
        Route::post('update-driving-license', [\App\Http\Controllers\API\DeliveryBoy\DocumentController::class, 'updateDrivingLicense'])->name('delivery_boy.update_driving_license');
        Route::get('get-pan', [\App\Http\Controllers\API\DeliveryBoy\DocumentController::class, 'getPan'])->name('delivery_boy.get_pan');
        Route::post('update-pan', [\App\Http\Controllers\API\DeliveryBoy\DocumentController::class, 'updatePan'])->name('delivery_boy.update_pan');
        Route::get('get-documents', [\App\Http\Controllers\API\DeliveryBoy\DocumentController::class, 'getDocuments'])->name('delivery_boy.get_documents');

        // Emergency Contact APIs
        Route::get('emergency-contacts', [\App\Http\Controllers\API\DeliveryBoy\EmergencyContactController::class, 'index'])->name('delivery_boy.emergency_contacts.index');
        Route::post('emergency-contacts', [\App\Http\Controllers\API\DeliveryBoy\EmergencyContactController::class, 'store'])->name('delivery_boy.emergency_contacts.store');
        Route::get('emergency-contacts/{id}', [\App\Http\Controllers\API\DeliveryBoy\EmergencyContactController::class, 'show'])->name('delivery_boy.emergency_contacts.show');
        Route::put('emergency-contacts/{id}', [\App\Http\Controllers\API\DeliveryBoy\EmergencyContactController::class, 'update'])->name('delivery_boy.emergency_contacts.update');
        Route::delete('emergency-contacts/{id}', [\App\Http\Controllers\API\DeliveryBoy\EmergencyContactController::class, 'destroy'])->name('delivery_boy.emergency_contacts.destroy');

        // Session Management APIs (Flutter compatible)
        Route::post('start-session', [\App\Http\Controllers\API\DeliveryBoy\GigTrackingController::class, 'startSession'])->name('delivery_boy.start_session');
        Route::post('end-session', [\App\Http\Controllers\API\DeliveryBoy\GigTrackingController::class, 'endSession'])->name('delivery_boy.end_session');
        Route::post('update-location', [\App\Http\Controllers\API\DeliveryBoy\GigTrackingController::class, 'updateLocation'])->name('delivery_boy.update_location');
        Route::get('tracking/today', [\App\Http\Controllers\API\DeliveryBoy\GigTrackingController::class, 'getTodayStats'])->name('delivery_boy.tracking.today');
        Route::get('tracking/active', [\App\Http\Controllers\API\DeliveryBoy\GigTrackingController::class, 'getActiveSession'])->name('delivery_boy.tracking.active');

        // Gig Management APIs (Flutter compatible)
        Route::get('available-gigs', [\App\Http\Controllers\API\DeliveryBoy\GigManagementController::class, 'getAvailableGigs'])->name('delivery_boy.available_gigs');
        Route::get('gig-details/{id}', [\App\Http\Controllers\API\DeliveryBoy\GigManagementController::class, 'getGigDetails'])->name('delivery_boy.gig_details');
        Route::post('book-gig', [\App\Http\Controllers\API\DeliveryBoy\GigManagementController::class, 'bookGig'])->name('delivery_boy.book_gig');
        Route::get('my-bookings', [\App\Http\Controllers\API\DeliveryBoy\GigManagementController::class, 'getMyBookings'])->name('delivery_boy.my_bookings');
        Route::post('cancel-booking', [\App\Http\Controllers\API\DeliveryBoy\GigManagementController::class, 'cancelBooking'])->name('delivery_boy.cancel_booking');
        Route::post('complete-gig', [\App\Http\Controllers\API\DeliveryBoy\GigManagementController::class, 'completeGig'])->name('delivery_boy.complete_gig');
        Route::get('gig-history', [\App\Http\Controllers\API\DeliveryBoy\GigManagementController::class, 'getGigHistory'])->name('delivery_boy.gig_history');

        // Incentive Offer APIs (Flutter compatible)
        Route::get('active-offers', [\App\Http\Controllers\API\DeliveryBoy\IncentiveOfferController::class, 'getActiveOffers'])->name('delivery_boy.active_offers');
        Route::get('all-offers', [\App\Http\Controllers\API\DeliveryBoy\IncentiveOfferController::class, 'getAllOffers'])->name('delivery_boy.all_offers');
        Route::get('offer-details', [\App\Http\Controllers\API\DeliveryBoy\IncentiveOfferController::class, 'getOfferDetails'])->name('delivery_boy.offer_details');
        Route::get('my-offer-progress', [\App\Http\Controllers\API\DeliveryBoy\IncentiveOfferController::class, 'getMyProgress'])->name('delivery_boy.my_offer_progress');

        // Driver Duty Issue APIs
        Route::post('duty-issue/store', [\App\Http\Controllers\API\DeliveryBoy\DriverDutyIssueController::class, 'store'])->name('delivery_boy.duty_issue.store');
        Route::post('duty-issue/update-city', [\App\Http\Controllers\API\DeliveryBoy\DriverDutyIssueController::class, 'updateCity'])->name('delivery_boy.duty_issue.update_city');

        Route::get('cash_collection', [\App\Http\Controllers\DeliveryBoyController::class, 'getCashCollection']);
        Route::get('fund_transfers', [\App\Http\Controllers\DeliveryBoyController::class, 'getFundTransfers']);

        Route::get('product_sales_reports', [\App\Http\Controllers\DeliveryBoyController::class, 'getProductSalesReport']);
        Route::get('sales_reports', [\App\Http\Controllers\DeliveryBoyController::class, 'getSalesReport']);
        Route::get('settings', [\App\Http\Controllers\DeliveryBoyController::class, 'getSettings']);
        Route::get('city', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getCity']);

        Route::group(['prefix' => 'mail_settings'], function () {
            Route::get('/', [\App\Http\Controllers\API\MailSettingsApiController::class, 'index']);
            Route::post('save', [\App\Http\Controllers\API\MailSettingsApiController::class, 'save'])->name('delivery_boy.mail_settings.save');
        });
        Route::post('/delete_delivery_boy_account', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'deleteDeliveryBoyAccount'])->name('delivery_boy.delete_delivery_boy_account');

        Route::group(['prefix' => 'withdrawal_requests'], function () {
            Route::get('/', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'index']);
            Route::post('/add', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'addWithdrawalRequests']);
            Route::get('get', [\App\Http\Controllers\API\WithdrawalRequestsApiController::class, 'getWithdrawalRequests']);
        });
        Route::get('/return_requests', [\App\Http\Controllers\API\ReturnRequestsApiController::class, 'deliveryBoyIndex']);
        Route::post('return_request_status_update', [\App\Http\Controllers\API\ReturnRequestsApiController::class, 'deliveryBoyUpdate'])->name('delivery_boy.return_requests.update');
        Route::post('manage_live_tracking', [\App\Http\Controllers\DeliveryBoyController::class, 'manageLiveTracking'])->name('delivery_boy.manage_live_tracking');
    });
}); // end of delivery_boy auth:api group
Route::prefix('oauth')->group(function () {
    Route::post('token', '\Laravel\Passport\Http\Controllers\AccessTokenController@issueToken');
    Route::get('tokens', '\Laravel\Passport\Http\Controllers\AuthorizedAccessTokenController@forUser');
    Route::delete('tokens/{token_id}', '\Laravel\Passport\Http\Controllers\AuthorizedAccessTokenController@destroy');
    Route::post('token/refresh', '\Laravel\Passport\Http\Controllers\TransientTokenController@refresh');
});

// Public route for POS invoice
Route::get('pos/invoice/{id}', [\App\Http\Controllers\API\SellerPosController::class, 'showInvoice']);

// Order items — public, no auth required
Route::get('order-items', [\App\Http\Controllers\API\OrderItemsController::class, 'index']);

// Paytm Payment Routes (Delivery Boy)
Route::middleware(['auth:api'])->group(function () {
    Route::group(['prefix' => 'delivery-boy/paytm'], function () {
        // Get Paytm configuration (public keys only, NOT merchant_key)
        Route::get('config', [\App\Http\Controllers\API\PaytmPaymentController::class, 'getConfigForDeliveryBoy'])->name('delivery_boy.paytm.config');
    });
});

Route::get('get-all-combo-types', [\App\Http\Controllers\API\ComboController::class, 'getAllTypesCombos'])->name('combo.get-all-types');
Route::post('create-or-update-combo-type', [\App\Http\Controllers\API\ComboController::class, 'editOrAddComboType'])->name('combo.type-add-or-edit');
Route::delete('delete-the-combo-type', [\App\Http\Controllers\API\ComboController::class, 'deleteComboType'])->name('combo.delete-type');

Route::get('get-all-combo-categories', [\App\Http\Controllers\API\ComboController::class, 'getAllCategoriesCombos'])->name('combo.get-all-categories');
Route::post('create-or-update-combo-category', [\App\Http\Controllers\API\ComboController::class, 'editOrAddComboCatgeory'])->name('combo.category-add-or-edit');
Route::delete('delete-the-combo-category', [\App\Http\Controllers\API\ComboController::class, 'deleteComboCategory'])->name('combo.delete-category');

Route::get('get-all-stores-data', [\App\Http\Controllers\API\ProductApisController::class, 'getAllStores'])->name('combo.get-all-stores');
Route::get('get-data-based-on-store-selection', [\App\Http\Controllers\API\ProductApisController::class, 'dataBasedOnStoreSelection'])->name('combo.get-data-based-on-store-selection');
Route::get('get-data-based-on-category-selection', [\App\Http\Controllers\API\ProductApisController::class, 'dataBasedOnCategoryGroupSelection'])->name('combo.get-data-based-on-category-selection');
Route::get('get-data-based-on-sub-category-selection', [\App\Http\Controllers\API\ProductApisController::class, 'dataBasedOnSubCategoryGroupSelection'])->name('combo.get-data-based-on-sub-category-selection');
Route::get('get-all-four-dropdowns', [\App\Http\Controllers\API\ProductApisController::class, 'getFullStoreData'])->name('get-full-store-data');


Route::post('send-otp-seller-phone', [\App\Http\Controllers\API\Seller\LoginController::class, 'sendOtp']);
Route::post('verify-otp-seller-phone', [\App\Http\Controllers\API\Seller\LoginController::class, 'verifyOtp']);
Route::middleware('auth:api')->post('seller/update-fcm-token', [\App\Http\Controllers\API\Seller\LoginController::class, 'updateFcmToken']);


Route::middleware('auth:sanctum')->get('seller/get-seller-register-data', [\App\Http\Controllers\API\AdminAuthController::class, 'getSellerRegistrationData']);
Route::get('seller/get-all-categories-data', [\App\Http\Controllers\API\AdminAuthController::class, 'getCategoriesAllData']);
Route::get('registration-data', [\App\Http\Controllers\API\AdminAuthController::class, 'getSellerRegistrationForGetMethod']);



Route::middleware('auth:api')->get('seller/registration-data-dev', [\App\Http\Controllers\SellerRegistrationController::class, 'getSellerRegistrationData']);
// Route::post('seller/post-registration-data-dev', [\App\Http\Controllers\SellerRegistrationController::class, 'sellerRegister']);

Route::middleware('auth:api')->post(
    'seller/post-registration-data-dev',
    [\App\Http\Controllers\SellerRegistrationController::class, 'sellerRegister']
);



Route::middleware('auth:api')->post(
    'seller/post-registration-data-dev-from-admin',
    [\App\Http\Controllers\SellerRegistrationController::class, 'sellerRegisterFromAdmin']
);

Route::middleware('auth:api')->post(
    'seller/update-seller-from-admin/{id}',
    [\App\Http\Controllers\SellerRegistrationController::class, 'sellerUpdateFromAdmin']
);

// Route::get('seller/get-categories-dev', [\App\Http\Controllers\SellerRegistrationController::class, 'getCategoriesAllData']);
Route::get('seller/get-categories-dev/{store_id}', [\App\Http\Controllers\SellerRegistrationController::class, 'getCategoriesByStoreId']);
Route::get('get-store-data-for-admin/{store_id}', [\App\Http\Controllers\SellerRegistrationController::class, 'getSellerRegistrationDataForAdmin']);


Route::middleware('auth:api')->get('seller/get-shop-status-of-seller', [\App\Http\Controllers\SellerRegistrationController::class, 'getShopStatusOfSeller']);
Route::middleware('auth:api')->post('seller/update-shop-status-of-seller', [\App\Http\Controllers\SellerRegistrationController::class, 'updateShopStatusOfSeller']);

Route::middleware('auth:api')->get('seller/shop-timings', [\App\Http\Controllers\SellerRegistrationController::class, 'getShopTimings']);
Route::middleware('auth:api')->post('seller/update-shop-timings', [\App\Http\Controllers\SellerRegistrationController::class, 'updateShopTimings']);
Route::post('seller/update-store-location-dev', [\App\Http\Controllers\SellerRegistrationController::class, 'updateShopLocationLatLong']);



Route::get('seller/get-data-based-on-store-selection', [\App\Http\Controllers\SellerRegistrationController::class, 'dataBasedOnStoreSelectionSeller'])->name('combo.get-data-based-on-store-selection');
Route::get('seller/get-data-based-on-category-selection', [\App\Http\Controllers\SellerRegistrationController::class, 'dataBasedOnCategoryGroupSelectionSeller'])->name('combo.get-data-based-on-category-selection');
Route::get('seller/get-data-based-on-sub-category-selection', [\App\Http\Controllers\SellerRegistrationController::class, 'dataBasedOnSubCategoryGroupSelectionSeller'])->name('combo.get-data-based-on-sub-category-selection');



Route::get('category-types', [CategoryTypeController::class, 'getAll']);       
Route::get('seller/category-types', [CategoryTypeController::class, 'getAll']);
Route::post('category-types', [CategoryTypeController::class, 'store']);       
Route::put('category-types/{id}', [CategoryTypeController::class, 'update']); 
Route::delete('category-types/{id}', [CategoryTypeController::class, 'destroy']);

Route::delete('category-types/{id}', [CategoryTypeController::class, 'destroy']);



Route::get('seller/get-all-brands', [CategoryTypeController::class, 'getAllBrands']);
Route::post('seller/post-product', [CategoryTypeController::class, 'saveProductSeller']);
// Public: Bulk upload step-by-step instructions for seller app UI (no auth required)
Route::get('seller/bulk-upload-instructions', [SellerBulkProductUploadController::class, 'bulkUploadInstructions']);

Route::middleware('auth:api')->get('seller/bulk-upload-template', [SellerBulkProductUploadController::class, 'downloadTemplate']);
Route::middleware('auth:api')->post('seller/bulk-upload-products', [SellerBulkProductUploadController::class, 'upload']);

// Admin bulk product upload
Route::middleware('auth:api')->get('admin/bulk-upload/sellers-list', [AdminBulkProductUploadController::class, 'sellersList']);
Route::middleware('auth:api')->get('admin/bulk-upload/template', [AdminBulkProductUploadController::class, 'downloadTemplate']);
Route::middleware('auth:api')->post('admin/bulk-upload/products', [AdminBulkProductUploadController::class, 'upload']);
Route::get('seller/get-products-seller', [CategoryTypeController::class, 'getSellerProducts']);
Route::get('seller/get-low-stock-products', [CategoryTypeController::class, 'getSellerLowStockProducts']);
Route::get('seller/get-sold-out-products', [CategoryTypeController::class, 'getSellerSoldOutProducts']);

Route::get('seller/get-all-units', [CategoryTypeController::class, 'getAllUnits']);
Route::get('settings/default-maps-key', [CategoryTypeController::class, 'getDefaultMapsKey']);

Route::get('seller/get-single-product-of-seller/{id}', [CategoryTypeController::class, 'singleProduct']);    
Route::post('seller/update-single-product/{id}', [CategoryTypeController::class, 'updateProductSeller']);



Route::post('seller/delete-variant/{id}', [CategoryTypeController::class, 'deleteVariant']);
Route::post('seller/delete-product/{id}', [CategoryTypeController::class, 'deleteProduct']);
Route::get('get-coupons-for-customers', [\App\Http\Controllers\API\PromoCodeApiController::class, 'getCouponsForCustomer']);

Route::get('get-sellers-list-using-order-id/{id}', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'getSellersByOrder']);

Route::middleware('auth:api')->post('seller/store-seller-sweet-house-category', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'storeSellerSweetHouseCategory']);
Route::middleware('auth:api')->get('seller/get-seller-sweet-house-category', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'GetSellerSweetHouseCategory']);


Route::middleware('auth:api')->post(
    'seller/update-seller-sweet-house-category/{id}',
    [\App\Http\Controllers\SellerRegistrationHelperController::class, 'updateSellerSweetHouseCategory']
);

Route::middleware('auth:api')->delete(
    'seller/delete-seller-sweet-house-category/{id}',
    [\App\Http\Controllers\SellerRegistrationHelperController::class, 'deleteSellerSweetHouseCategory']
);


Route::middleware('auth:api')->post(
    'seller/store-category-type',
    [\App\Http\Controllers\SellerRegistrationHelperController::class, 'storeCategoryType']
);


Route::get('seller/get-seller-registration-helper', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'index']);
Route::post('orders/assign-seller', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'assignSellerToStore']);


Route::middleware('auth:api')->get('seller/orders/get-for-seller', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'getSellerAssignedOrders']);
Route::middleware('auth:api')->get('seller/orders/status-tracking', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'getSellerOrderStatusTracking']);

Route::middleware('auth:api')->get('seller/orders/order-statuses', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'getOrderStatuses']);
Route::middleware('auth:api')->post('seller/orders/update-preparation-time', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'updatePreparationTime']);
Route::middleware('auth:api')->post('seller/orders/update-order-status', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'updateOrderStatus']);
Route::middleware('auth:api')->post('seller/orders/verify-delivery-otp', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'verifyDeliveryOTP']);
Route::middleware('auth:api')->get('seller/orders/status-tracking', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'getSellerOrderStatusTracking']);
Route::middleware('auth:api')->post('seller/orders/update-prep-time', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'updateSellerOrderPrepTime']);
Route::middleware('auth:api')->post('seller/orders/update-tracking-status', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'updateSellerOrderTrackingStatus']);
Route::middleware('auth:api')->post('seller/orders/verify-otp-update-status', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'verifyOtpAndUpdateTrackingStatus']);
// Seller Order Invoice API - For thermal printer (USB printing)
Route::middleware('auth:api')->get('seller/orders/invoice', [\App\Http\Controllers\API\OrderInvoiceController::class, 'getOrderInvoice']);

// Seller Chatbot APIs
Route::middleware('auth:api')->get('seller/chatbot/questions', [\App\Http\Controllers\API\Seller\SellerChatbotController::class, 'getQuestions']);
Route::middleware('auth:api')->post('seller/chatbot/answer', [\App\Http\Controllers\API\Seller\SellerChatbotController::class, 'getAnswer']);

// Seller Issue Report Returns
// Route::middleware('auth:api')->get('seller/issue-report-returns', [\App\Http\Controllers\SellerRegistrationHelperController::class, 'getIssueReportReturns']);

Route::get('seller/category-types', [CategoryTypeController::class, 'getAll']);
Route::post('seller/category-types', [CategoryTypeController::class, 'store']);
Route::put('seller/category-types/{id}', [CategoryTypeController::class, 'update']);
Route::delete('seller/category-types/{id}', [CategoryTypeController::class, 'destroy']);

Route::middleware('auth:api')->get('seller/sweetshop/products-by-category', [CategoryTypeController::class, 'getSweetshopProductsByCategory']);

// User API - Get sweetshop products by category for a specific seller
Route::get('sweetshop/products-by-category', [CategoryTypeController::class, 'getUserSweetshopProductsByCategory']);

// Seller Bank Account APIs
Route::middleware('auth:api')->prefix('seller/bank-accounts')->group(function () {
    Route::get('/', [\App\Http\Controllers\SellerBankAccountController::class, 'index']);
    Route::post('/', [\App\Http\Controllers\SellerBankAccountController::class, 'store']);
    Route::post('/{id}', [\App\Http\Controllers\SellerBankAccountController::class, 'update']);
    Route::delete('/{id}', [\App\Http\Controllers\SellerBankAccountController::class, 'destroy']);
    Route::post('/{id}/set-default', [\App\Http\Controllers\SellerBankAccountController::class, 'setDefault']);
});

// App Pages APIs (Terms, Privacy, About) - Public access
Route::prefix('pages')->group(function () {
    Route::get('/', [\App\Http\Controllers\AppPageController::class, 'index']);
    Route::get('terms', [\App\Http\Controllers\AppPageController::class, 'terms']);
    Route::get('privacy', [\App\Http\Controllers\AppPageController::class, 'privacy']);
    Route::get('about', [\App\Http\Controllers\AppPageController::class, 'about']);
    Route::get('{pageType}', [\App\Http\Controllers\AppPageController::class, 'show']);
});

// Seller Statistics APIs
Route::middleware('auth:api')->get('seller/statistics', [\App\Http\Controllers\SellerStatisticsController::class, 'getSellerStatistics']);
Route::middleware('auth:api')->get('seller/earnings', [\App\Http\Controllers\SellerEarningsController::class, 'getSellerEarnings']);
Route::middleware('auth:api')->get('seller/banners', [\App\Http\Controllers\SellerStatisticsController::class, 'getSellerBanners']);
Route::middleware('auth:api')->get('seller/store-categories', [\App\Http\Controllers\SellerStatisticsController::class, 'getSellerStoreWithCategories']);
Route::middleware('auth:api')->get('seller/products-by-category', [\App\Http\Controllers\SellerStatisticsController::class, 'getSellerProductsByCategory']);

// Seller Registration Update APIs
Route::middleware('auth:api')->post('seller/update-personal-details', [\App\Http\Controllers\SellerRegistrationController::class, 'updateSellerPersonalDetails']);
Route::middleware('auth:api')->post('seller/update-store-details', [\App\Http\Controllers\SellerRegistrationController::class, 'updateSellerStoreDetails']);


// Public Seller Statistics API (for users)
Route::get('seller/statistics-public', [\App\Http\Controllers\SellerStatisticsController::class, 'getSellerStatisticsByID']);

// Public Banners API — category + store type banners, no auth
Route::get('seller/public-banners', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'getPublicBanners']);

// Public Seller Login Background
Route::get('seller/login-bg', [\App\Http\Controllers\API\SettingsController::class, 'getSellerLoginBg']);

Route::group(['prefix' => 'seller', 'middleware' => ['auth:api']], function () {
    Route::get('category-groups', [\App\Http\Controllers\API\Seller\SubCategorySellerController::class, 'list']);
    Route::get('category-groups/{id}', [\App\Http\Controllers\API\Seller\SubCategorySellerController::class, 'show']);
    Route::post('category-groups', [\App\Http\Controllers\API\Seller\SubCategorySellerController::class, 'store']);
    Route::post('category-groups/{id}', [\App\Http\Controllers\API\Seller\SubCategorySellerController::class, 'update']);
    Route::delete('category-groups/{id}', [\App\Http\Controllers\API\Seller\SubCategorySellerController::class, 'destroy']);


    // CATEGORY GROUP CRUD
    Route::post('store-category-grouping', [\App\Http\Controllers\API\Seller\SubCategorySellerController::class, 'storeCategoryGroup']);
    Route::get('get-category-grouping', [\App\Http\Controllers\API\Seller\SubCategorySellerController::class, 'indexCategoryGroup']);
    Route::post('update-category-grouping/{id}', [\App\Http\Controllers\API\Seller\SubCategorySellerController::class, 'updateCategoryGroup']);
    Route::delete('delete-category-grouping/{id}', [\App\Http\Controllers\API\Seller\SubCategorySellerController::class, 'destroyCategoryGroup']);
    
    Route::get('get-categories-by-seller-token', [\App\Http\Controllers\SellerRegistrationController::class, 'dataBasedOnStoreSelectionSellerAuthToken']);

});


Route::group(['prefix' => 'seller', 'middleware' => ['auth:api']], function () {
    Route::get('brands', [App\Http\Controllers\API\Seller\BrandSellerController::class, 'getAllBrands']);
    Route::get('brands/{id}', [App\Http\Controllers\API\Seller\BrandSellerController::class, 'show']);
    Route::post('brands', [App\Http\Controllers\API\Seller\BrandSellerController::class, 'store']);
    Route::post('brands/{id}', [App\Http\Controllers\API\Seller\BrandSellerController::class, 'update']);
    Route::delete('brands/{id}', [App\Http\Controllers\API\Seller\BrandSellerController::class, 'destroy']);
});

// Seller Customer Issue Report Returns APIs
Route::group(['prefix' => 'seller', 'middleware' => ['auth:api']], function () {
    Route::get('issue-report-returns', [App\Http\Controllers\API\Seller\CustomerIssueReportReturnController::class, 'getReturns']);
    Route::get('issue-report-returns/{return_id}', [App\Http\Controllers\API\Seller\CustomerIssueReportReturnController::class, 'getReturnById']);
    Route::post('issue-report-returns/update-status', [App\Http\Controllers\API\Seller\CustomerIssueReportReturnController::class, 'updateReturnStatus']);
    Route::get('issue-report', [App\Http\Controllers\API\Seller\CustomerIssueReportReturnController::class, 'getReportById']);
});

// Seller App - My Transactions APIs
Route::group(['prefix' => 'seller', 'middleware' => ['auth:api']], function () {
    Route::get('my-transactions', [App\Http\Controllers\API\Seller\SellerTransactionApiController::class, 'index']);
    Route::get('my-transactions/paid', [App\Http\Controllers\API\Seller\SellerTransactionApiController::class, 'paid']);
    Route::get('my-transactions/unpaid', [App\Http\Controllers\API\Seller\SellerTransactionApiController::class, 'unpaid']);
    Route::get('my-transactions/summary', [App\Http\Controllers\API\Seller\SellerTransactionApiController::class, 'summary']);
    Route::get('my-transactions/weekly', [App\Http\Controllers\API\Seller\SellerTransactionApiController::class, 'weekly']);
    Route::get('my-transactions/{id}', [App\Http\Controllers\API\Seller\SellerTransactionApiController::class, 'show']);
});

// Claimable Banner (Setting) - No Auth Required
Route::get('user_offers/claimable_banner', [\App\Http\Controllers\API\UserOffersController::class, 'getClaimableBanner']);
Route::post('user_offers/claimable_banner/save', [\App\Http\Controllers\API\UserOffersController::class, 'saveClaimableBanner'])->name('user_offers.claimable_banner.save');
Route::post('user_offers/claimable_banner/delete', [\App\Http\Controllers\API\UserOffersController::class, 'deleteClaimableBanner'])->name('user_offers.claimable_banner.delete');

// Learning API for Mobile Apps - No Auth Required
Route::group(['prefix' => 'learning'], function () {
    Route::get('topics', [\App\Http\Controllers\API\LearningApiController::class, 'getTopics']);
    Route::get('topic/{id}', [\App\Http\Controllers\API\LearningApiController::class, 'getTopicDetails']);
    Route::get('videos', [\App\Http\Controllers\API\LearningApiController::class, 'getVideos']);
    Route::get('video/{id}', [\App\Http\Controllers\API\LearningApiController::class, 'getVideoDetails']);
});



 // Learning Topics Management
    Route::group(['prefix' => 'learning_topics'], function () {
        Route::get('/', [\App\Http\Controllers\API\LearningTopicsApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\LearningTopicsApiController::class, 'save'])->name('learning_topics.save');
        Route::post('update', [\App\Http\Controllers\API\LearningTopicsApiController::class, 'update'])->name('learning_topics.update');
        Route::post('delete', [\App\Http\Controllers\API\LearningTopicsApiController::class, 'delete'])->name('learning_topics.delete');
        Route::post('update-status', [\App\Http\Controllers\API\LearningTopicsApiController::class, 'updateStatus'])->name('learning_topics.update-status');
    });

    // Learning Videos Management
    Route::group(['prefix' => 'learning_videos'], function () {
        Route::get('/', [\App\Http\Controllers\API\LearningVideosApiController::class, 'index']);
        Route::post('save', [\App\Http\Controllers\API\LearningVideosApiController::class, 'save'])->name('learning_videos.save');
        Route::post('update', [\App\Http\Controllers\API\LearningVideosApiController::class, 'update'])->name('learning_videos.update');
        Route::post('delete', [\App\Http\Controllers\API\LearningVideosApiController::class, 'delete'])->name('learning_videos.delete');
        Route::post('update-status', [\App\Http\Controllers\API\LearningVideosApiController::class, 'updateStatus'])->name('learning_videos.update-status');
    });

// Pre Orders Management (Admin Panel)
Route::group(['prefix' => 'preorders'], function () {
    Route::get('/', [\App\Http\Controllers\API\PreOrderController::class, 'getPreOrders']);
    Route::get('/stats', [\App\Http\Controllers\API\PreOrderController::class, 'getPreOrderStats']);
    Route::get('/store-wise-analytics', [\App\Http\Controllers\API\PreOrderController::class, 'getStoreWiseAnalytics']);
    Route::get('/store-orders', [\App\Http\Controllers\API\PreOrderController::class, 'getStoreOrders']);
    Route::get('/export/pdf', [\App\Http\Controllers\API\PreOrderController::class, 'exportPDF']);
    Route::get('/export/excel', [\App\Http\Controllers\API\PreOrderController::class, 'exportExcel']);
    Route::get('/{id}/pdf', [\App\Http\Controllers\API\PreOrderController::class, 'downloadOrderPDF']);
    Route::get('/{id}', [\App\Http\Controllers\API\PreOrderController::class, 'getPreOrderDetails']);
});

// Pre Order Items Management (Admin Panel)
Route::group(['prefix' => 'pre-order-items'], function () {
    Route::get('/all', [\App\Http\Controllers\API\PreOrderItemController::class, 'getAllPreOrderItems']);
    Route::get('/products', [\App\Http\Controllers\API\PreOrderItemController::class, 'getProducts']);
    Route::post('/save', [\App\Http\Controllers\API\PreOrderItemController::class, 'savePreOrderItems']);
});

// Seller Account Deletion APIs (Admin)
Route::middleware('auth:api')->group(function () {
    Route::post('seller-account-deletion/soft-delete', [\App\Http\Controllers\API\SellerAccountDeletionController::class, 'softDeleteSeller']);
    Route::post('seller-account-deletion/restore', [\App\Http\Controllers\API\SellerAccountDeletionController::class, 'restoreSeller']);
});

// Driver Account Deletion APIs (Admin)
Route::middleware('auth:api')->group(function () {
    Route::post('driver-account-deletion/soft-delete', [\App\Http\Controllers\API\DriverAccountDeletionController::class, 'softDeleteDriver']);
    Route::post('driver-account-deletion/restore', [\App\Http\Controllers\API\DriverAccountDeletionController::class, 'restoreDriver']);
});

// User Account Deletion APIs (Admin)
Route::middleware('auth:api')->group(function () {
    Route::post('user-account-deletion/soft-delete', [\App\Http\Controllers\API\UserAccountDeletionController::class, 'softDeleteUser']);
    Route::post('user-account-deletion/restore', [\App\Http\Controllers\API\UserAccountDeletionController::class, 'restoreUser']);
});

    Route::group(['prefix' => 'cities'], function () {
        Route::get('/', [\App\Http\Controllers\API\CityApiController::class, 'getCities']);
        Route::post('save', [\App\Http\Controllers\API\CityApiController::class, 'save'])->name('cities.save');
        Route::post('save_boundary', [\App\Http\Controllers\API\CityApiController::class, 'save_boundary'])->name('cities.save_boundary');
        Route::get('edit/{id}', [\App\Http\Controllers\API\CityApiController::class, 'edit']);
        Route::post('update', [\App\Http\Controllers\API\CityApiController::class, 'update'])->name('cities.update');
        Route::post('delete', [\App\Http\Controllers\API\CityApiController::class, 'delete'])->name('cities.delete');
    });

// Product Images API (Public - No Auth Required)
// Optimized for Flutter app lazy loading and scrollable animations
Route::group(['prefix' => 'product-images'], function () {
    Route::get('/', [\App\Http\Controllers\API\ProductImagesApiController::class, 'getProductImages']);
    Route::get('/flat', [\App\Http\Controllers\API\ProductImagesApiController::class, 'getFlatImageUrls']);
});

// Stores and Sellers API for Order Analytics
Route::get('/stores', [\App\Http\Controllers\API\Admin\StoreController::class, 'getAllStores']);
Route::get('/stores/{store_id}/sellers', [\App\Http\Controllers\API\Admin\StoreController::class, 'getSellersByStore']);

// Brand Campaigns Admin API (CRUD)
Route::middleware('auth:api')->group(function () {
    Route::get('/admin/brand-campaigns', [\App\Http\Controllers\API\Admin\BrandCampaignController::class, 'index']);
    Route::get('/admin/brand-campaigns/{id}', [\App\Http\Controllers\API\Admin\BrandCampaignController::class, 'show']);
    Route::post('/admin/brand-campaigns', [\App\Http\Controllers\API\Admin\BrandCampaignController::class, 'store']);
    Route::put('/admin/brand-campaigns/{id}', [\App\Http\Controllers\API\Admin\BrandCampaignController::class, 'update']);
    Route::patch('/admin/brand-campaigns/{id}', [\App\Http\Controllers\API\Admin\BrandCampaignController::class, 'update']);
    Route::delete('/admin/brand-campaigns/{id}', [\App\Http\Controllers\API\Admin\BrandCampaignController::class, 'destroy']);

    // Brand Campaign Products Admin API
    Route::get('/admin/brand-campaign-products', [\App\Http\Controllers\API\Admin\BrandCampaignProductController::class, 'index']);
    Route::get('/admin/brand-campaign-products/available-products', [\App\Http\Controllers\API\Admin\BrandCampaignProductController::class, 'getAvailableProducts']);
    Route::post('/admin/brand-campaign-products', [\App\Http\Controllers\API\Admin\BrandCampaignProductController::class, 'store']);
    Route::put('/admin/brand-campaign-products/{id}', [\App\Http\Controllers\API\Admin\BrandCampaignProductController::class, 'update']);
    Route::delete('/admin/brand-campaign-products/{id}', [\App\Http\Controllers\API\Admin\BrandCampaignProductController::class, 'destroy']);
    Route::delete('/admin/brand-campaign-products/delete-all/{campaignId}', [\App\Http\Controllers\API\Admin\BrandCampaignProductController::class, 'deleteAll']);
    Route::post('/admin/brand-campaign-products/reorder', [\App\Http\Controllers\API\Admin\BrandCampaignProductController::class, 'reorder']);
});

// ⚠️ DEVELOPMENT/TESTING APIs - NO AUTHENTICATION REQUIRED ⚠️
// WARNING: These endpoints should be disabled or protected in production
Route::group(['prefix' => 'dev'], function () {
    // Auto-book all available gigs for today for a delivery boy
    Route::post('/auto-book-today-gigs', [\App\Http\Controllers\API\DevController::class, 'autoBookTodayGigs']);
});
