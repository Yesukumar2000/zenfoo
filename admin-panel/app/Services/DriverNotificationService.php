<?php

namespace App\Services;

use App\Helpers\FCMHelper;
use App\Models\AdminToken;
use App\Models\Category;
use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyNotification;
use App\Models\Product;
use App\Models\Role;
use App\Models\Setting;
use Illuminate\Support\Facades\Log;

class DriverNotificationService
{
    /**
     * Send notification to a specific driver (delivery boy)
     *
     * @param int $driverId - The delivery boy ID (from delivery_boys table)
     * @param string $title - Notification title
     * @param string $message - Notification message/body
     * @param string $image - Image URL for the notification (optional)
     * @param string $type - Notification type (e.g., 'order', 'general', 'promo')
     * @param int|null $orderItemId - Order item ID if related to an order
     * @param array $extraData - Any additional data to send with the notification
     * @return array - Result with success status and message
     */
    public static function send(
        int $driverId,
        string $title,
        string $message,
        string $image = '',
        string $type = 'general',
        ?int $orderItemId = null,
        array $extraData = []
    ): array {
        Log::info("DriverNotificationService::send - ENTRY", [
            'driver_id' => $driverId,
            'title' => $title,
            'message_preview' => substr($message, 0, 50),
            'image_param' => $image,
            'type' => $type,
            'order_item_id' => $orderItemId
        ]);

        try {
            // Get delivery boy to find admin_id
            $driver = DeliveryBoy::find($driverId);
            if (!$driver) {
                Log::warning("DriverNotificationService: Driver not found for ID: {$driverId}");
                return [
                    'success' => false,
                    'message' => 'Driver not found'
                ];
            }

            // Get driver's admin ID
            $adminId = $driver->admin_id;

            // Get driver FCM tokens from admin_tokens table
            $userTokens = AdminToken::where('user_id', $adminId)
                ->where('type', Role::$roleNameDeliveryBoy)
                ->pluck('fcm_token', 'platform')
                ->toArray();

            // dd(Role::$roleNameDeliveryBoy);

            if (empty($userTokens)) {
                Log::warning("DriverNotificationService: No FCM tokens found for driver ID: {$driverId} (Admin ID: {$adminId})");
                return [
                    'success' => false,
                    'message' => 'No FCM tokens found for this driver'
                ];
            }

            // Get Zenfoo logo image for notification
            $appUrl = rtrim(env('APP_URL', config('app.url')), '/');

            // Get app logo for notification icon
            $logo = Setting::get_value('logo');
            $logo = $logo ? $appUrl . '/storage/' . $logo : $appUrl . '/images/favicon.png';

            Log::info("DriverNotificationService: Image decision", [
                'incoming_image' => $image,
                'incoming_image_empty' => empty($image),
                'app_url' => $appUrl
            ]);

            $notificationImage = $image ?: $appUrl . '/assets/logo_zenfoo.png';

            Log::info("DriverNotificationService: Using notification image", [
                'app_url' => $appUrl,
                'notification_image' => $notificationImage,
                'original_image' => $image
            ]);

            // Build notification data
            $data = [
                'title' => $title,
                'message' => $message,
                'body' => $message,
                'image' => $notificationImage,
                'type' => $type,
                'order_item_id' => $orderItemId ?? '',
                'icon' => $logo,
            ];

            // Add category-specific data
            if ($type === 'category' && isset($extraData['category_id'])) {
                $category = Category::with('catActiveChilds')->find($extraData['category_id']);
                if ($category) {
                    $data['type_slug'] = $category->slug;
                    $data['type_name'] = $category->name;
                    $data['has_child'] = $category->has_child;
                    $data['has_active_child'] = $category->has_active_child;
                }
            }

            // Add product-specific data
            if ($type === 'product' && isset($extraData['product_id'])) {
                $data['type_slug'] = Product::where('id', $extraData['product_id'])->value('slug') ?? '';
            }

            // Merge any extra data
            $data = array_merge($data, $extraData);

            // Build FCM message
            $fcmMsg = [
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                'title' => $title,
                'message' => $message,
                'body' => $message,
                'type' => $type,
                'order_item_id' => (string) ($orderItemId ?? ''),
                'icon' => $logo,
                'image' => $notificationImage,
                'sound' => 'default',
            ];

            // Add extra data to FCM message
            foreach ($extraData as $key => $value) {
                $fcmMsg[$key] = is_array($value) ? json_encode($value) : (string) $value;
            }

            // Notification payload for iOS
            $notification = [
                'title' => $title,
                'body' => $message,
                'image' => $notificationImage,
            ];

            Log::info("DriverNotificationService: Sending notification to driver {$driverId}", [
                'title' => $title,
                'type' => $type,
                'tokens_count' => count($userTokens)
            ]);

            // Send to all driver devices
            $successCount = 0;
            $failCount = 0;

            foreach ($userTokens as $platform => $deviceToken) {
                try {
                    $result = FCMHelper::send($platform, $deviceToken, $fcmMsg, $notification);
                    if ($result && !isset($result['error'])) {
                        $successCount++;
                    } else {
                        $failCount++;
                    }
                } catch (\Exception $e) {
                    $failCount++;
                    Log::error("DriverNotificationService: Failed to send to device", [
                        'driver_id' => $driverId,
                        'platform' => $platform,
                        'error' => $e->getMessage()
                    ]);
                }
            }

            Log::info("DriverNotificationService: Notification sent", [
                'driver_id' => $driverId,
                'success_count' => $successCount,
                'fail_count' => $failCount
            ]);

            // Store notification in delivery_boy_notifications table
            $notificationRecord = DeliveryBoyNotification::create([
                'delivery_boy_id' => $driverId,
                'title' => $title,
                'message' => $message,
                'type' => $type,
                'order_item_id' => $orderItemId
            ]);

            Log::info("DriverNotificationService: Notification stored in database", [
                'notification_id' => $notificationRecord->id
            ]);

            return [
                'success' => $successCount > 0,
                'message' => "Notification sent to {$successCount} device(s), failed for {$failCount} device(s)",
                'success_count' => $successCount,
                'fail_count' => $failCount,
                'notification_id' => $notificationRecord->id
            ];

        } catch (\Exception $e) {
            Log::error("DriverNotificationService: Exception occurred", [
                'driver_id' => $driverId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to send notification: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Send notification to multiple drivers
     *
     * @param array $driverIds - Array of delivery boy IDs
     * @param string $title - Notification title
     * @param string $message - Notification message/body
     * @param string $image - Image URL for the notification (optional)
     * @param string $type - Notification type
     * @param int|null $orderItemId - Order item ID if related to an order
     * @param array $extraData - Any additional data
     * @return array - Result with success status and details
     */
    public static function sendToMultiple(
        array $driverIds,
        string $title,
        string $message,
        string $image = '',
        string $type = 'general',
        ?int $orderItemId = null,
        array $extraData = []
    ): array {
        $results = [
            'total_drivers' => count($driverIds),
            'success_count' => 0,
            'fail_count' => 0,
            'details' => []
        ];

        foreach ($driverIds as $driverId) {
            $result = self::send(
                $driverId,
                $title,
                $message,
                $image,
                $type,
                $orderItemId,
                $extraData
            );

            if ($result['success']) {
                $results['success_count']++;
            } else {
                $results['fail_count']++;
            }

            $results['details'][$driverId] = $result;
        }

        $results['success'] = $results['success_count'] > 0;
        $results['message'] = "Sent to {$results['success_count']} of {$results['total_drivers']} drivers";

        return $results;
    }

    /**
     * Notify driver that their account has been deleted by admin
     */
    public static function notifyDriverAccountDeleted(int $driverId): array
    {
        return self::send(
            $driverId,
            'Account Deleted',
            'Your driver account has been deleted by the admin. For any queries, please contact support.',
            '',
            'general'
        );
    }

    /**
     * Notify driver that their account has been restored by admin
     */
    public static function notifyDriverAccountRestored(int $driverId): array
    {
        return self::send(
            $driverId,
            'Account Restored',
            'Your driver account has been restored by the admin. You can now login and continue using the app.',
            '',
            'general'
        );
    }
}
