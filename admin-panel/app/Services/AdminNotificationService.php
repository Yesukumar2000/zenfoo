<?php

namespace App\Services;

use App\Helpers\FCMHelper;
use App\Models\Admin;
use App\Models\AdminToken;
use App\Models\Setting;
use App\Models\PanelNotification;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class AdminNotificationService
{
    /**
     * Send notification to admin(s) - saves to panel_notifications and sends push notification
     *
     * @param int|array|null $adminIds - Admin ID(s) to notify. If null, notifies all admins.
     * @param string $title - Notification title
     * @param string $message - Notification message/body
     * @param string $type - Notification type: 'new_order', 'order_status', 'seller_registration', etc.
     * @param array $data - Additional data (order_id, seller_id, etc.)
     * @return array - Result with success status and message
     */
    public static function send(
        $adminIds,
        string $title,
        string $message,
        string $type = 'general',
        array $data = []
    ): array {
        try {
            // Get admin IDs - exclude Seller and Delivery Boy roles
            $excludedRoleIds = \DB::table('roles')
                ->whereIn('name', ['Seller', 'Delivery Boy'])
                ->pluck('id')
                ->toArray();

            if ($adminIds === null) {
                // Notify all admins (excluding Seller and Delivery Boy)
                $admins = Admin::whereNotIn('role_id', $excludedRoleIds)->get();
            } elseif (is_array($adminIds)) {
                $admins = Admin::whereIn('id', $adminIds)
                    ->whereNotIn('role_id', $excludedRoleIds)
                    ->get();
            } else {
                $admins = Admin::where('id', $adminIds)
                    ->whereNotIn('role_id', $excludedRoleIds)
                    ->get();
            }

            if ($admins->isEmpty()) {
                Log::warning("AdminNotificationService: No admins found");
                return [
                    'success' => false,
                    'message' => 'No admins found'
                ];
            }

            $successCount = 0;
            $failedCount = 0;

            foreach ($admins as $admin) {
                try {
                    // 1. Save to panel_notifications table
                    // Format: {"type":"new_order","order_id":163,"text":"You have Received new order  #163"}
                    $notificationData = [
                        'type' => $type,
                        'text' => $message,
                    ];

                    // Only add order_id if present
                    if (!empty($data['order_id'])) {
                        $notificationData['order_id'] = $data['order_id'];
                    }

                    // Only add seller_id if present
                    if (!empty($data['seller_id'])) {
                        $notificationData['seller_id'] = $data['seller_id'];
                    }

                    // Only add customer_id if present
                    if (!empty($data['customer_id'])) {
                        $notificationData['customer_id'] = $data['customer_id'];
                    }

                    // Only add driver_id if present
                    if (!empty($data['driver_id'])) {
                        $notificationData['driver_id'] = $data['driver_id'];
                    }

                    // Only add issue_id if present
                    if (!empty($data['issue_id'])) {
                        $notificationData['issue_id'] = $data['issue_id'];
                    }

                    $notification = PanelNotification::create([
                        'id' => Str::uuid()->toString(),
                        'type' => 'App\\Notifications\\' . self::getNotificationClass($type),
                        'notifiable_type' => 'App\\Models\\Admin',
                        'notifiable_id' => $admin->id,
                        'data' => $notificationData,
                        'read_at' => null,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);

                    Log::info("AdminNotificationService: Saved notification to panel_notifications", [
                        'admin_id' => $admin->id,
                        'notification_id' => $notification->id,
                        'data' => $notificationData
                    ]);

                    // 2. Send push notification
                    $pushResult = self::sendPushNotification($admin->id, $title, $message, $type, $data);

                    if ($pushResult['success']) {
                        $successCount++;
                    } else {
                        $failedCount++;
                    }

                } catch (\Exception $e) {
                    $failedCount++;
                    Log::error("AdminNotificationService: Error for admin {$admin->id}: " . $e->getMessage());
                }
            }

            return [
                'success' => $successCount > 0,
                'message' => "Notifications sent: {$successCount} success, {$failedCount} failed",
                'success_count' => $successCount,
                'failed_count' => $failedCount
            ];

        } catch (\Exception $e) {
            Log::error("AdminNotificationService: Exception: " . $e->getMessage());
            return [
                'success' => false,
                'message' => 'Error: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Send push notification to a specific admin
     */
    private static function sendPushNotification(
        int $adminId,
        string $title,
        string $message,
        string $type,
        array $data
    ): array {
        try {
            // Get admin's FCM tokens
            $tokens = AdminToken::where('user_id', $adminId)->get();

            if ($tokens->isEmpty()) {
                Log::warning("AdminNotificationService: No FCM tokens for admin {$adminId}");
                return ['success' => false, 'message' => 'No FCM tokens'];
            }

            // Get app logo
            $logo = Setting::get_value('logo');
            $logo = $logo ? url('/storage') . "/" . $logo : asset('images/favicon.png');

            // Determine click action URL
            $clickAction = $data['click_action'] ?? self::getClickAction($type, $data);

            $successCount = 0;

            foreach ($tokens as $tokenRecord) {
                try {
                    $fcmMsg = [
                        'title' => $title,
                        'body' => $message,
                        'message' => $message,
                        'type' => $type,
                        'icon' => $logo,
                        'click_action' => $clickAction,
                        'order_id' => $data['order_id'] ?? '',
                        'seller_id' => $data['seller_id'] ?? '',
                        'customer_id' => $data['customer_id'] ?? '',
                        'driver_id' => $data['driver_id'] ?? '',
                        'issue_id' => $data['issue_id'] ?? '',
                    ];

                    $notification = [
                        'title' => $title,
                        'body' => $message,
                    ];

                    $platform = $tokenRecord->platform ?? 'web';
                    $result = FCMHelper::send($platform, $tokenRecord->fcm_token, $fcmMsg, $notification);

                    if ($result && isset($result['name'])) {
                        $successCount++;
                    }
                } catch (\Exception $e) {
                    Log::error("AdminNotificationService: Push failed: " . $e->getMessage());
                }
            }

            return [
                'success' => $successCount > 0,
                'message' => "Push sent to {$successCount} devices"
            ];

        } catch (\Exception $e) {
            Log::error("AdminNotificationService: Push exception: " . $e->getMessage());
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    /**
     * Get notification class name based on type
     */
    private static function getNotificationClass(string $type): string
    {
        $classes = [
            'new_order' => 'OrderNotification',
            'order_status' => 'OrderNotification',
            'seller_registration' => 'SellerRegistrationNotification',
            'seller_delete_request' => 'SellerRegistrationNotification',
            'driver_delete_request' => 'GeneralNotification',
            'user_delete_request' => 'GeneralNotification',
            'customer_issue_report' => 'CustomerIssueReportNotification',
            'general' => 'GeneralNotification',
        ];

        return $classes[$type] ?? 'GeneralNotification';
    }

    /**
     * Get click action URL based on notification type
     */
    private static function getClickAction(string $type, array $data): string
    {
        switch ($type) {
            case 'new_order':
            case 'order_status':
                $orderId = $data['order_id'] ?? '';
                return url("/orders/view/{$orderId}");

            case 'chat_message':
                $orderId = $data['order_id'] ?? '';
                $senderType = $data['sender_type'] ?? '';
                $sellerId = $data['seller_id'] ?? '';
                $url = url("/orders/view/{$orderId}") . '?tab=support';
                if ($senderType) {
                    $url .= '&chat_type=' . $senderType;
                }
                if ($senderType === 'seller' && $sellerId) {
                    $url .= '&seller_id=' . $sellerId;
                }
                return $url;

            case 'seller_registration':
            case 'seller_delete_request':
                $sellerId = $data['seller_id'] ?? '';
                return url("/sellers/view/{$sellerId}");

            case 'customer_issue_report':
                $reportId = $data['report_id'] ?? '';
                return url("/customer-support/view/{$reportId}");

            case 'driver_delete_request':
                $driverId = $data['driver_id'] ?? '';
                return url("/delivery_boys/view/{$driverId}");

            case 'driver_document_update':
                $driverId = $data['driver_id'] ?? '';
                return url("/delivery_boys/view/{$driverId}");

            case 'driver_created_issue':
                $issueId = $data['issue_id'] ?? '';
                return url("/delivery-boys/issues/view/{$issueId}");

            case 'user_delete_request':
                $userId = $data['user_id'] ?? '';
                return url("/users/{$userId}");

            default:
                return url('/dashboard');
        }
    }

    /**
     * Notify all admins about a new order
     */
    public static function notifyNewOrder(int $orderId, string $orderNumber = null): array
    {
        $orderNum = $orderNumber ?? "#{$orderId}";
        return self::send(
            null, // All admins
            'New Order Received',
            "You have received new order {$orderNum}",
            'new_order',
            ['order_id' => $orderId, 'click_action' => url("/orders/view/{$orderId}")]
        );
    }

    /**
     * Notify all admins about order status change
     */
    public static function notifyOrderStatusChange(int $orderId, string $status, string $orderNumber = null): array
    {
        $orderNum = $orderNumber ?? "#{$orderId}";
        return self::send(
            null, // All admins
            'Order Status Updated',
            "Order {$orderNum} status changed to {$status}",
            'order_status',
            ['order_id' => $orderId, 'click_action' => url("/orders/view/{$orderId}")]
        );
    }

    /**
     * Notify all admins about new seller registration
     */
    public static function notifyNewSellerRegistration(int $sellerId, string $sellerName): array
    {
        return self::send(
            null, // All admins
            'New Seller Registration',
            "{$sellerName} has registered as a new seller",
            'seller_registration',
            ['seller_id' => $sellerId, 'click_action' => url("/sellers/view/{$sellerId}")]
        );
    }

    /**
     * Notify all admins about new customer issue report
     */
    public static function notifyCustomerIssueReport(int $reportId, int $orderId, string $reportType, string $customerName): array
    {
        $reportTypeLabel = $reportType === 'wrong' ? 'Wrong Item' : 'Missing Item';
        return self::send(
            null, // All admins
            'New Customer Issue Report',
            "{$customerName} has reported a {$reportTypeLabel} issue for Order #{$orderId}",
            'customer_issue_report',
            ['report_id' => $reportId, 'order_id' => $orderId, 'click_action' => url("/customer-support/view/{$reportId}")]
        );
    }

    /**
     * Notify all admins about driver document update
     */
    public static function notifyDriverDocumentUpdate(int $driverId, string $driverName, string $documentType): array
    {
        $documentLabel = match ($documentType) {
            'driving_license' => 'Driving License',
            'pan' => 'PAN Card',
            'aadhar' => 'Aadhar Card',
            'rc' => 'RC Book',
            'bank' => 'Bank Details',
            default => $documentType
        };

        return self::send(
            null, // All admins
            'Driver Document Updated',
            "{$driverName} has updated their {$documentLabel}. Please review and verify.",
            'driver_document_update',
            ['driver_id' => $driverId, 'click_action' => url("/delivery_boys/view/{$driverId}")]
        );
    }

    /**
     * Notify all admins about driver created issue
     */
    public static function notifyDriverCreatedIssue(int $issueId, int $driverId, string $driverName, string $issueType): array
    {
        $issueTypeLabel = match ($issueType) {
            'order_earning' => 'Order Earning',
            'incorrect_payout' => 'Incorrect Payout',
            'incentive' => 'Incentive',
            'multi_order' => 'Multi Order',
            'joining_bonus' => 'Joining Bonus',
            'pocketing_issue' => 'Pocketing Issue',
            'not_getting_order_issue' => 'Not Getting Orders',
            default => $issueType
        };

        return self::send(
            null, // All admins
            'New Driver Issue Reported',
            "{$driverName} has reported a {$issueTypeLabel} issue. Please review.",
            'driver_created_issue',
            [
                'driver_id' => $driverId,
                'issue_id' => $issueId,
                'click_action' => url("/delivery-boys/issues/view/{$issueId}")
            ]
        );
    }

    /**
     * Notify all admins about seller account deletion request
     */
    public static function notifySellerDeleteRequest(int $sellerId, string $sellerName): array
    {
        return self::send(
            null, // All admins
            'Seller Account Deleted',
            "{$sellerName} has deleted their account.",
            'seller_delete_request',
            ['seller_id' => $sellerId, 'click_action' => url("/sellers/view/{$sellerId}")]
        );
    }

    /**
     * Notify all admins about driver account deletion request
     */
    public static function notifyDriverDeleteRequest(int $driverId, string $driverName): array
    {
        return self::send(
            null, // All admins
            'Driver Account Deleted',
            "{$driverName} has deleted their account.",
            'driver_delete_request',
            ['driver_id' => $driverId, 'click_action' => url("/delivery_boys/view/{$driverId}")]
        );
    }

    /**
     * Notify all admins about customer account deletion
     */
    public static function notifyUserDeleteRequest(int $userId, string $userName): array
    {
        return self::send(
            null, // All admins
            'Customer Account Deleted',
            "{$userName} has deleted their account.",
            'user_delete_request',
            ['user_id' => $userId, 'click_action' => url("/users/{$userId}")]
        );
    }
}
