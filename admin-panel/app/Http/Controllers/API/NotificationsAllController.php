<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\DeliveryBoyNotification;
use App\Models\User;
use App\Models\Seller;
use App\Models\DeliveryBoy;
use App\Models\BroadcastNotification;
use App\Models\AdminToken;
use App\Models\UserToken;
use App\Models\Role;
use App\Models\Setting;
use App\Helpers\FCMHelper;
use App\Services\MediaUploadService;
use App\Services\CustomerNotificationService;
use App\Services\SellerNotificationService;
use App\Services\DriverNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class NotificationsAllController extends Controller
{
    /**
     * Get notification statistics
     */
    public function stats()
    {
        try {
            $customerCount = Notification::where('role_name', 'customer')->count();
            $sellerCount = Notification::where('role_name', 'seller')->count();
            $driverCount = DeliveryBoyNotification::count();

            return response()->json([
                'success' => true,
                'data' => [
                    'total_notifications' => $customerCount + $sellerCount + $driverCount,
                    'customer_notifications' => $customerCount,
                    'seller_notifications' => $sellerCount,
                    'driver_notifications' => $driverCount,
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch stats: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get notifications list based on tab
     */
    public function index(Request $request)
    {
        try {
            $tab = $request->get('tab', 'customer');
            $perPage = $request->get('per_page', 15);
            $search = $request->get('search', '');

            if ($tab === 'driver') {
                // Fetch from delivery_boy_notifications table
                $query = DeliveryBoyNotification::with('deliveryBoy')
                    ->orderBy('created_at', 'desc');

                if ($search) {
                    $query->where(function ($q) use ($search) {
                        $q->where('title', 'like', "%{$search}%")
                          ->orWhere('message', 'like', "%{$search}%");
                    });
                }

                $notifications = $query->paginate($perPage);
            } else {
                // Fetch from notifications table based on role_name
                $query = Notification::where('role_name', $tab)
                    ->orderBy('date_sent', 'desc');

                if ($search) {
                    $query->where(function ($q) use ($search) {
                        $q->where('title', 'like', "%{$search}%")
                          ->orWhere('message', 'like', "%{$search}%");
                    });
                }

                $notifications = $query->paginate($perPage);

                // Load user relationship manually
                $notifications->getCollection()->transform(function ($notification) use ($tab) {
                    if ($notification->user_id) {
                        if ($tab === 'seller') {
                            // For sellers, get from sellers table
                            $seller = Seller::select('id', 'name', 'email', 'mobile')
                                ->find($notification->user_id);
                            $notification->user = $seller;
                        } else {
                            // For customers
                            $notification->user = User::select('id', 'name', 'email', 'mobile')
                                ->find($notification->user_id);
                        }
                    }
                    return $notification;
                });
            }

            return response()->json([
                'success' => true,
                'data' => $notifications
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch notifications: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete a notification
     */
    public function delete(Request $request)
    {
        try {
            $id = $request->get('id');
            $type = $request->get('type', 'customer');

            if ($type === 'driver') {
                $notification = DeliveryBoyNotification::find($id);
            } else {
                $notification = Notification::find($id);
            }

            if (!$notification) {
                return response()->json([
                    'success' => false,
                    'message' => 'Notification not found'
                ], 404);
            }

            $notification->delete();

            return response()->json([
                'success' => true,
                'message' => 'Notification deleted successfully'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete notification: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get send statistics (counts of active users by type)
     */
    public function sendStats()
    {
        try {
            // Get active customers count
            $customerCount = User::where('status', User::$active)->count();

            // Get active sellers count
            $sellerCount = Seller::where('status', Seller::$statusActive)->count();

            // Get active drivers count
            $driverCount = DeliveryBoy::where('status', DeliveryBoy::$statusActive)->count();

            return response()->json([
                'success' => true,
                'data' => [
                    'customer_count' => $customerCount,
                    'seller_count' => $sellerCount,
                    'driver_count' => $driverCount,
                    'total_count' => $customerCount + $sellerCount + $driverCount,
                ]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch send stats: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get recent broadcast notifications
     */
    public function recentBroadcasts()
    {
        try {
            $broadcasts = BroadcastNotification::orderBy('created_at', 'desc')
                ->limit(10)
                ->get();

            return response()->json([
                'success' => true,
                'data' => $broadcasts
            ]);
        } catch (\Exception $e) {
            // If table doesn't exist, return empty array
            return response()->json([
                'success' => true,
                'data' => []
            ]);
        }
    }

    /**
     * Send notification to selected target type
     * Uses FCM token deduplication to prevent duplicate push notifications
     * when the same device is logged into multiple accounts
     */
    public function send(Request $request)
    {
        try {
            $request->validate([
                'target_type' => 'required|in:customer,seller,driver,all',
                'title' => 'required|string|max:100',
                'message' => 'required|string|max:500',
                'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:5120'
            ]);

            $targetType = $request->input('target_type');
            $title = $request->input('title');
            $message = $request->input('message');
            $imageUrl = '';

            // Upload image if provided
            if ($request->hasFile('image')) {
                $imageUrl = MediaUploadService::upload(
                    $request->file('image'),
                    'notifications',
                    'public'
                );
            }

            Log::info("NotificationsAllController: Sending broadcast notification", [
                'target_type' => $targetType,
                'title' => $title,
                'image_url' => $imageUrl
            ]);

            $results = [
                'customer' => ['total' => 0, 'success' => 0, 'fail' => 0, 'db_stored' => 0],
                'seller' => ['total' => 0, 'success' => 0, 'fail' => 0, 'db_stored' => 0],
                'driver' => ['total' => 0, 'success' => 0, 'fail' => 0, 'db_stored' => 0],
            ];

            // Collect unique FCM tokens to prevent duplicate push notifications
            // Key: fcm_token, Value: ['platform' => platform, 'type' => type]
            $uniqueTokens = [];

            // Get app logo and notification image
            $logo = Setting::get_value('logo');
            $logo = $logo ? url('/storage') . "/" . $logo : asset('images/favicon.png');
            $appUrl = rtrim(env('APP_URL', config('app.url')), '/');
            $notificationImage = $imageUrl ?: $appUrl . '/assets/logo_zenfoo.png';

            // Build FCM message
            $fcmMsg = [
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                'title' => $title,
                'message' => $message,
                'body' => $message,
                'type' => 'broadcast',
                'icon' => $logo,
                'image' => $notificationImage,
                'sound' => 'default',
                'broadcast' => 'true',
            ];

            // Notification payload for iOS
            $notification = [
                'title' => $title,
                'body' => $message,
                'image' => $notificationImage,
            ];

            // Process customers
            if ($targetType === 'customer' || $targetType === 'all') {
                $customers = User::where('status', User::$active)->get(['id']);
                $results['customer']['total'] = $customers->count();

                foreach ($customers as $customer) {
                    // Get customer FCM tokens from user_tokens table
                    $tokens = UserToken::where('user_id', $customer->id)
                        ->where('type', 'customer')
                        ->get(['fcm_token', 'platform']);

                    foreach ($tokens as $token) {
                        if (!empty($token->fcm_token) && !isset($uniqueTokens[$token->fcm_token])) {
                            $uniqueTokens[$token->fcm_token] = [
                                'platform' => $token->platform ?? 'android',
                                'type' => 'customer'
                            ];
                        }
                    }

                    // Store notification in database
                    try {
                        Notification::create([
                            'user_id' => $customer->id,
                            'role_name' => 'customer',
                            'title' => $title,
                            'message' => $message,
                            'type' => 'broadcast',
                            'type_id' => 0,
                            'type_link' => '',
                            'image' => $imageUrl,
                            'data' => json_encode(['broadcast' => true]),
                            'date_sent' => now(),
                        ]);
                        $results['customer']['db_stored']++;
                    } catch (\Exception $e) {
                        Log::warning("Failed to store customer notification: " . $e->getMessage());
                    }
                }
            }

            // Process sellers
            if ($targetType === 'seller' || $targetType === 'all') {
                $sellers = Seller::where('status', Seller::$statusActive)->get(['id', 'admin_id']);
                $results['seller']['total'] = $sellers->count();

                foreach ($sellers as $seller) {
                    // Get seller FCM tokens from admin_tokens table using admin_id
                    $tokens = AdminToken::where('user_id', $seller->admin_id)
                        ->where('type', Role::$roleNameSeller)
                        ->get(['fcm_token', 'platform']);

                    foreach ($tokens as $token) {
                        if (!empty($token->fcm_token) && !isset($uniqueTokens[$token->fcm_token])) {
                            $uniqueTokens[$token->fcm_token] = [
                                'platform' => $token->platform ?? 'android',
                                'type' => 'seller'
                            ];
                        }
                    }

                    // Store notification in database
                    try {
                        Notification::create([
                            'user_id' => $seller->id,
                            'role_name' => 'seller',
                            'title' => $title,
                            'message' => $message,
                            'type' => 'broadcast',
                            'type_id' => 0,
                            'type_link' => '',
                            'image' => $imageUrl,
                            'data' => json_encode(['broadcast' => true]),
                            'date_sent' => now(),
                        ]);
                        $results['seller']['db_stored']++;
                    } catch (\Exception $e) {
                        Log::warning("Failed to store seller notification: " . $e->getMessage());
                    }
                }
            }

            // Process drivers
            if ($targetType === 'driver' || $targetType === 'all') {
                $drivers = DeliveryBoy::where('status', DeliveryBoy::$statusActive)->get(['id', 'admin_id']);
                $results['driver']['total'] = $drivers->count();

                foreach ($drivers as $driver) {
                    // Get driver FCM tokens from admin_tokens table using admin_id
                    $tokens = AdminToken::where('user_id', $driver->admin_id)
                        ->where('type', Role::$roleNameDeliveryBoy)
                        ->get(['fcm_token', 'platform']);

                    foreach ($tokens as $token) {
                        if (!empty($token->fcm_token) && !isset($uniqueTokens[$token->fcm_token])) {
                            $uniqueTokens[$token->fcm_token] = [
                                'platform' => $token->platform ?? 'android',
                                'type' => 'driver'
                            ];
                        }
                    }

                    // Store notification in database
                    try {
                        DeliveryBoyNotification::create([
                            'delivery_boy_id' => $driver->id,
                            'title' => $title,
                            'message' => $message,
                            'type' => 'broadcast',
                            'order_item_id' => null,
                        ]);
                        $results['driver']['db_stored']++;
                    } catch (\Exception $e) {
                        Log::warning("Failed to store driver notification: " . $e->getMessage());
                    }
                }
            }

            Log::info("NotificationsAllController: Collected unique FCM tokens", [
                'unique_tokens_count' => count($uniqueTokens),
                'target_type' => $targetType
            ]);

            // Send push notification once per unique FCM token
            $fcmSuccessCount = 0;
            $fcmFailCount = 0;

            foreach ($uniqueTokens as $fcmToken => $tokenInfo) {
                try {
                    $result = FCMHelper::send($tokenInfo['platform'], $fcmToken, $fcmMsg, $notification);
                    if ($result && !isset($result['error'])) {
                        $fcmSuccessCount++;
                        // Increment success count for the appropriate type
                        $results[$tokenInfo['type']]['success']++;
                    } else {
                        $fcmFailCount++;
                        $results[$tokenInfo['type']]['fail']++;
                    }
                } catch (\Exception $e) {
                    $fcmFailCount++;
                    $results[$tokenInfo['type']]['fail']++;
                    Log::warning("FCM send failed for token", [
                        'error' => $e->getMessage(),
                        'type' => $tokenInfo['type']
                    ]);
                }
            }

            // Calculate totals
            $totalSent = $fcmSuccessCount;
            $totalFailed = $fcmFailCount;
            $totalTargeted = $results['customer']['total'] + $results['seller']['total'] + $results['driver']['total'];
            $totalDbStored = $results['customer']['db_stored'] + $results['seller']['db_stored'] + $results['driver']['db_stored'];

            // Store broadcast notification record
            try {
                BroadcastNotification::create([
                    'target_type' => $targetType,
                    'title' => $title,
                    'message' => $message,
                    'image' => $imageUrl,
                    'total_sent' => $totalSent,
                    'total_failed' => $totalFailed,
                    'results' => json_encode($results),
                ]);
            } catch (\Exception $e) {
                Log::warning("BroadcastNotification table not found: " . $e->getMessage());
            }

            Log::info("NotificationsAllController: Broadcast notification completed", [
                'total_targeted' => $totalTargeted,
                'unique_tokens_sent' => $totalSent,
                'unique_tokens_failed' => $totalFailed,
                'db_records_stored' => $totalDbStored,
                'results' => $results
            ]);

            return response()->json([
                'success' => $totalSent > 0 || $totalDbStored > 0,
                'message' => "Notification sent successfully!",
                'data' => [
                    'total_targeted' => $totalTargeted,
                    'total_sent' => $totalSent,
                    'total_failed' => $totalFailed,
                    'db_stored' => $totalDbStored,
                    'details' => $results
                ]
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed: ' . implode(', ', array_map(function($errors) {
                    return implode(', ', $errors);
                }, $e->errors()))
            ], 422);
        } catch (\Exception $e) {
            Log::error("NotificationsAllController: Error sending notification", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to send notification: ' . $e->getMessage()
            ], 500);
        }
    }
}
