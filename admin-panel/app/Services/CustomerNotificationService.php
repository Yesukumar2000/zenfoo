<?php

namespace App\Services;

use App\Helpers\FCMHelper;
use App\Models\Category;
use App\Models\Notification;
use App\Models\Product;
use App\Models\Setting;
use App\Models\UserToken;
use Illuminate\Support\Facades\Log;

class CustomerNotificationService
{
    /**
     * Send notification to a specific customer
     *
     * @param int $customerId - The customer user ID
     * @param string $title - Notification title
     * @param string $message - Notification message/body
     * @param string $image - Image URL for the notification (optional)
     * @param string $pageNavigation - Navigation type: 'category', 'product', 'order', 'home', 'offers', etc.
     * @param int|string $navigationId - ID for the navigation (category_id, product_id, order_id, etc.)
     * @param array $extraData - Any additional data to send with the notification
     * @return array - Result with success status and message
     */
    public static function send(
        int $customerId,
        string $title,
        string $message,
        string $image = '',
        string $pageNavigation = '',
        $navigationId = null,
        array $extraData = []
    ): array {
        try {
            // Get customer FCM tokens
            $userTokens = UserToken::where('user_id', $customerId)
                ->where('type', 'customer')
                ->pluck('fcm_token', 'platform')
                ->toArray();

            if (empty($userTokens)) {
                Log::warning("CustomerNotificationService: No FCM tokens found for customer ID: {$customerId}");
                return [
                    'success' => false,
                    'message' => 'No FCM tokens found for this customer'
                ];
            }

            // Get app logo for notification icon
            $logo = Setting::get_value('logo');
            $logo = $logo ? url('/storage') . "/" . $logo : asset('images/favicon.png');

            // Get Zenfoo logo image for notification (use APP_URL from env)
            $appUrl = rtrim(env('APP_URL', config('app.url')), '/');
            $notificationImage = $image ?: $appUrl . '/assets/logo_zenfoo.png';

            Log::info("CustomerNotificationService: Using notification image", [
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
                'type' => $pageNavigation,
                'id' => $navigationId ?? '',
                'icon' => $logo,
            ];

            // Add category-specific data
            if ($pageNavigation === 'category' && $navigationId) {
                $category = Category::with('catActiveChilds')->find($navigationId);
                if ($category) {
                    $data['type_slug'] = $category->slug;
                    $data['type_name'] = $category->name;
                    $data['has_child'] = $category->has_child;
                    $data['has_active_child'] = $category->has_active_child;
                } else {
                    $data['type_slug'] = '';
                    $data['type_name'] = '';
                    $data['has_child'] = 0;
                    $data['has_active_child'] = 0;
                }
            }

            // Add product-specific data
            if ($pageNavigation === 'product' && $navigationId) {
                $data['type_slug'] = Product::where('id', $navigationId)->value('slug') ?? '';
            }

            // Merge any extra data
            $data = array_merge($data, $extraData);

            // Build FCM message
            $fcmMsg = [
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                'title' => $title,
                'message' => $message,
                'body' => $message,
                'type' => $pageNavigation,
                'id' => (string) ($navigationId ?? ''),
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

            Log::info("CustomerNotificationService: Sending notification to customer {$customerId}", [
                'title' => $title,
                'type' => $pageNavigation,
                'tokens_count' => count($userTokens)
            ]);

            // Send to all customer devices
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
                    Log::error("CustomerNotificationService: Failed to send to device", [
                        'customer_id' => $customerId,
                        'platform' => $platform,
                        'error' => $e->getMessage()
                    ]);
                }
            }

            Log::info("CustomerNotificationService: Notification sent", [
                'customer_id' => $customerId,
                'success_count' => $successCount,
                'fail_count' => $failCount
            ]);

            // Store notification in database
            $notificationRecord = new Notification();
            $notificationRecord->user_id = $customerId;
            $notificationRecord->role_name = 'customer';
            $notificationRecord->title = $title;
            $notificationRecord->message = $message;
            $notificationRecord->type = $pageNavigation ?: '';
            $notificationRecord->type_id = !empty($navigationId) ? (int) $navigationId : 0;
            $notificationRecord->type_link = $extraData['url'] ?? '';
            $notificationRecord->image = $image;
            $notificationRecord->data = json_encode([
                'fcm_message' => $fcmMsg,
                'notification_payload' => $notification,
                'extra_data' => $extraData,
                'customer_id' => $customerId,
                'page_navigation' => $pageNavigation,
                'navigation_id' => $navigationId,
                'image_url' => $notificationImage,
            ]);
            $notificationRecord->date_sent = now();
            $notificationRecord->save();

            Log::info("CustomerNotificationService: Notification stored in database", [
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
            Log::error("CustomerNotificationService: Exception occurred", [
                'customer_id' => $customerId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to send notification: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Send notification to multiple customers
     *
     * @param array $customerIds - Array of customer user IDs
     * @param string $title - Notification title
     * @param string $message - Notification message/body
     * @param string $image - Image URL for the notification (optional)
     * @param string $pageNavigation - Navigation type
     * @param int|string $navigationId - ID for the navigation
     * @param array $extraData - Any additional data
     * @return array - Result with success status and details
     */
    public static function sendToMultiple(
        array $customerIds,
        string $title,
        string $message,
        string $image = '',
        string $pageNavigation = '',
        $navigationId = null,
        array $extraData = []
    ): array {
        $results = [
            'total_customers' => count($customerIds),
            'success_count' => 0,
            'fail_count' => 0,
            'details' => []
        ];

        foreach ($customerIds as $customerId) {
            $result = self::send(
                $customerId,
                $title,
                $message,
                $image,
                $pageNavigation,
                $navigationId,
                $extraData
            );

            if ($result['success']) {
                $results['success_count']++;
            } else {
                $results['fail_count']++;
            }

            $results['details'][$customerId] = $result;
        }

        $results['success'] = $results['success_count'] > 0;
        $results['message'] = "Sent to {$results['success_count']} of {$results['total_customers']} customers";

        return $results;
    }

    /**
     * Notify customer that their account has been deleted by admin
     */
    public static function notifyUserAccountDeleted(int $customerId): array
    {
        return self::send(
            $customerId,
            'Account Deleted',
            'Your customer account has been deleted by the admin. For any queries, please contact support.',
            '',
            'home'
        );
    }

    /**
     * Notify customer that their account has been restored by admin
     */
    public static function notifyUserAccountRestored(int $customerId): array
    {
        return self::send(
            $customerId,
            'Account Restored',
            'Your customer account has been restored by the admin. You can now login and continue using the app.',
            '',
            'home'
        );
    }
}