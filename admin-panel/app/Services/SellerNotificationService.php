<?php

namespace App\Services;

use App\Helpers\FCMHelper;
use App\Models\AdminToken;
use App\Models\Category;
use App\Models\Notification;
use App\Models\Product;
use App\Models\Role;
use App\Models\Seller;
use App\Models\Setting;
use Illuminate\Support\Facades\Log;

class SellerNotificationService
{
    /**
     * Send notification to a specific seller
     *
     * @param int $sellerId - The seller ID (from sellers table)
     * @param string $title - Notification title
     * @param string $message - Notification message/body
     * @param string $image - Image URL for the notification (optional)
     * @param string $pageNavigation - Navigation type: 'category', 'product', 'order', 'home', 'offers', etc.
     * @param int|string $navigationId - ID for the navigation (category_id, product_id, order_id, etc.)
     * @param array $extraData - Any additional data to send with the notification
     * @return array - Result with success status and message
     */
    public static function send(
        int $sellerId,
        string $title,
        string $message,
        string $image = '',
        string $pageNavigation = '',
        $navigationId = null,
        array $extraData = []
    ): array {
        // Debug: Log all incoming parameters
        Log::info("SellerNotificationService::send - ENTRY", [
            'seller_id' => $sellerId,
            'title' => $title,
            'message_preview' => substr($message, 0, 50),
            'image_param' => $image,
            'image_empty' => empty($image),
            'image_length' => strlen($image),
            'page_navigation' => $pageNavigation,
            'navigation_id' => $navigationId
        ]);

        try {
            // Get seller to find admin_id
            $seller = Seller::find($sellerId);
            if (!$seller) {
                Log::warning("SellerNotificationService: Seller not found for ID: {$sellerId}");
                return [
                    'success' => false,
                    'message' => 'Seller not found'
                ];
            }

            // Get seller's admin ID
            $adminId = $seller->admin_id;

            // Get seller FCM tokens from admin_tokens table
            $userTokens = AdminToken::where('user_id', $adminId)
                ->where('type', Role::$roleNameSeller)
                ->pluck('fcm_token', 'platform')
                ->toArray();

            if (empty($userTokens)) {
                Log::warning("SellerNotificationService: No FCM tokens found for seller ID: {$sellerId} (Admin ID: {$adminId})");
                return [
                    'success' => false,
                    'message' => 'No FCM tokens found for this seller'
                ];
            }

            // Get app logo for notification icon
            $logo = Setting::get_value('logo');
            $logo = $logo ? url('/storage') . "/" . $logo : asset('images/favicon.png');

            // Get Zenfoo logo image for notification (use APP_URL from env)
            $appUrl = rtrim(env('APP_URL', config('app.url')), '/');

            // Debug: Log the image decision process
            Log::info("SellerNotificationService: Image decision", [
                'incoming_image' => $image,
                'incoming_image_empty' => empty($image),
                'incoming_image_truthy' => $image ? 'truthy' : 'falsy',
                'app_url' => $appUrl
            ]);

            $notificationImage = $image ?: $appUrl . '/assets/logo_zenfoo.png';

            Log::info("SellerNotificationService: Using notification image", [
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

            Log::info("SellerNotificationService: Sending notification to seller {$sellerId}", [
                'title' => $title,
                'type' => $pageNavigation,
                'tokens_count' => count($userTokens)
            ]);

            // Send to all seller devices
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
                    Log::error("SellerNotificationService: Failed to send to device", [
                        'seller_id' => $sellerId,
                        'platform' => $platform,
                        'error' => $e->getMessage()
                    ]);
                }
            }

            Log::info("SellerNotificationService: Notification sent", [
                'seller_id' => $sellerId,
                'success_count' => $successCount,
                'fail_count' => $failCount
            ]);

            // Store notification in database
            $notificationRecord = new Notification();
            $notificationRecord->user_id = $sellerId;
            $notificationRecord->role_name = 'seller';
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
                'seller_id' => $sellerId,
                'admin_id' => $adminId,
                'page_navigation' => $pageNavigation,
                'navigation_id' => $navigationId,
                'image_url' => $notificationImage,
            ]);
            $notificationRecord->date_sent = now();
            $notificationRecord->save();

            Log::info("SellerNotificationService: Notification stored in database", [
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
            Log::error("SellerNotificationService: Exception occurred", [
                'seller_id' => $sellerId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to send notification: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Send notification to multiple sellers
     *
     * @param array $sellerIds - Array of seller IDs
     * @param string $title - Notification title
     * @param string $message - Notification message/body
     * @param string $image - Image URL for the notification (optional)
     * @param string $pageNavigation - Navigation type
     * @param int|string $navigationId - ID for the navigation
     * @param array $extraData - Any additional data
     * @return array - Result with success status and details
     */
    public static function sendToMultiple(
        array $sellerIds,
        string $title,
        string $message,
        string $image = '',
        string $pageNavigation = '',
        $navigationId = null,
        array $extraData = []
    ): array {
        $results = [
            'total_sellers' => count($sellerIds),
            'success_count' => 0,
            'fail_count' => 0,
            'details' => []
        ];

        foreach ($sellerIds as $sellerId) {
            $result = self::send(
                $sellerId,
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

            $results['details'][$sellerId] = $result;
        }

        $results['success'] = $results['success_count'] > 0;
        $results['message'] = "Sent to {$results['success_count']} of {$results['total_sellers']} sellers";

        return $results;
    }

    /**
     * Notify seller that their account has been deleted by admin
     */
    public static function notifySellerAccountDeleted(int $sellerId): array
    {
        return self::send(
            $sellerId,
            'Account Deleted',
            'Your seller account has been deleted by the admin. For any queries, please contact support.',
            '',
            'home',
            0
        );
    }

    /**
     * Notify seller that their account has been restored by admin
     */
    public static function notifySellerAccountRestored(int $sellerId): array
    {
        return self::send(
            $sellerId,
            'Account Restored',
            'Your seller account has been restored by the admin. You can now login and continue using the app.',
            '',
            'home',
            0
        );
    }
}
