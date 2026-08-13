<?php

namespace App\Http\Controllers\API;

use App\Helpers\FCMHelper;
use App\Http\Controllers\Controller;
use App\Models\AdminToken;
use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyBroadcastNotification;
use App\Models\Role;
use App\Models\Setting;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class DeliveryBoyBroadcastNotificationController extends Controller
{
    /**
     * Get list of all broadcast notifications
     */
    public function index(Request $request)
    {
        try {
            $perPage = $request->get('per_page', 15);
            $search = $request->get('search', '');

            $query = DeliveryBoyBroadcastNotification::orderBy('created_at', 'desc');

            if ($search) {
                $query->where(function ($q) use ($search) {
                    $q->where('title', 'like', "%{$search}%")
                      ->orWhere('message', 'like', "%{$search}%");
                });
            }

            $notifications = $query->paginate($perPage);

            // Add image_url to each notification
            $notifications->getCollection()->transform(function ($notification) {
                $notification->image_url = $notification->image_url;
                return $notification;
            });

            return response()->json([
                'success' => true,
                'data' => $notifications,
                'message' => 'Notifications fetched successfully'
            ]);
        } catch (\Exception $e) {
            Log::error('DeliveryBoyBroadcastNotificationController@index: Error', [
                'error' => $e->getMessage()
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch notifications'
            ], 500);
        }
    }

    /**
     * Send notification to all delivery boys
     */
    public function send(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'message' => 'required|string',
            'type' => 'nullable|string|in:general,promo,announcement',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first()
            ], 422);
        }

        try {
            $title = $request->title;
            $message = $request->message;
            $type = $request->type ?? 'announcement';
            $imageUrl = null;

            // Handle image upload using MediaUploadService
            if ($request->hasFile('image')) {
                $imageUrl = MediaUploadService::upload(
                    $request->file('image'),
                    'notifications/delivery_boys'
                );
            }

            // Get all FCM tokens for delivery boys from admin_tokens table
            $deliveryBoyTokens = AdminToken::where('type', Role::$roleNameDeliveryBoy)
                ->whereNotNull('fcm_token')
                ->where('fcm_token', '!=', '')
                ->get();
            
            // dd($deliveryBoyTokens);

            if ($deliveryBoyTokens->isEmpty()) {
                return response()->json([
                    'success' => false,
                    'message' => 'No delivery boys with FCM tokens found'
                ], 400);
            }

            $totalTokens = $deliveryBoyTokens->count();

            // dd($totalTokens);


            // Create broadcast notification record (store full URL in database)
            $broadcastNotification = DeliveryBoyBroadcastNotification::create([
                'title' => $title,
                'message' => $message,
                'image' => $imageUrl,
                'type' => $type,
                'total_delivery_boys' => $totalTokens,
                'status' => DeliveryBoyBroadcastNotification::STATUS_SENDING,
                'sent_by' => auth()->id(),
                'sent_at' => now(),
            ]);

            Log::info('DeliveryBoyBroadcastNotificationController@send: Starting broadcast', [
                'broadcast_id' => $broadcastNotification->id,
                'title' => $title,
                'total_tokens' => $totalTokens,
            ]);

            // Get app logo for notification icon
            $logo = Setting::get_value('logo');
            $logo = $logo ? url('/storage') . "/" . $logo : asset('images/favicon.png');

            // Default notification image
            $appUrl = rtrim(env('APP_URL', config('app.url')), '/');
            $notificationImage = $imageUrl ?: $appUrl . '/assets/logo_zenfoo.png';

            // Build notification data
            $fcmMsg = [
                'title' => $title,
                'body' => $message,
                'icon' => $logo,
                'image' => $notificationImage,
                'type' => $type,
                'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            ];

            $notification = [
                'title' => $title,
                'body' => $message,
                'sound' => 'default',
            ];

            $successCount = 0;
            $failCount = 0;

            // Send to each token
            foreach ($deliveryBoyTokens as $tokenRecord) {
                try {
                    $result = FCMHelper::send(
                        $tokenRecord->platform ?? 'android',
                        $tokenRecord->fcm_token,
                        $fcmMsg,
                        $notification
                    );

                    // FCM returns {"name": "projects/xxx/messages/xxx"} on success
                    // FCM returns {"error": {...}} on failure
                    // FCMHelper returns false on curl/connection failure
                    if ($result && isset($result['name']) && !isset($result['error'])) {
                        $successCount++;
                        Log::info('DeliveryBoyBroadcastNotificationController: Notification sent successfully', [
                            'user_id' => $tokenRecord->user_id,
                            'platform' => $tokenRecord->platform,
                            'fcm_message_id' => $result['name'],
                        ]);
                    } else {
                        $failCount++;
                        Log::warning('DeliveryBoyBroadcastNotificationController: Failed to send notification', [
                            'user_id' => $tokenRecord->user_id,
                            'platform' => $tokenRecord->platform,
                            'result' => $result,
                        ]);
                    }
                } catch (\Exception $e) {
                    $failCount++;
                    Log::error('DeliveryBoyBroadcastNotificationController: Exception sending notification', [
                        'user_id' => $tokenRecord->user_id,
                        'error' => $e->getMessage(),
                    ]);
                }
            }

            // Update broadcast notification record with results
            $broadcastNotification->update([
                'success_count' => $successCount,
                'failed_count' => $failCount,
                'status' => $successCount > 0
                    ? DeliveryBoyBroadcastNotification::STATUS_COMPLETED
                    : DeliveryBoyBroadcastNotification::STATUS_FAILED,
            ]);

            Log::info('DeliveryBoyBroadcastNotificationController@send: Broadcast completed', [
                'broadcast_id' => $broadcastNotification->id,
                'success_count' => $successCount,
                'fail_count' => $failCount,
            ]);

            return response()->json([
                'success' => true,
                'message' => "Notification sent to {$successCount} of {$totalTokens} delivery boys",
                'data' => [
                    'broadcast_id' => $broadcastNotification->id,
                    'total_delivery_boys' => $totalTokens,
                    'success_count' => $successCount,
                    'fail_count' => $failCount,
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('DeliveryBoyBroadcastNotificationController@send: Error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Failed to send notifications: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Delete a broadcast notification record
     */
    public function delete(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:delivery_boy_broadcast_notifications,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first()
            ], 422);
        }

        try {
            $notification = DeliveryBoyBroadcastNotification::find($request->id);

            // Delete image if exists (image now stores full URL)
            if ($notification->image) {
                MediaUploadService::deleteByUrl($notification->image, 's3');
            }

            $notification->delete();

            return response()->json([
                'success' => true,
                'message' => 'Notification deleted successfully'
            ]);
        } catch (\Exception $e) {
            Log::error('DeliveryBoyBroadcastNotificationController@delete: Error', [
                'error' => $e->getMessage()
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to delete notification'
            ], 500);
        }
    }

    /**
     * Get statistics/summary
     */
    public function stats()
    {
        try {
            $totalNotifications = DeliveryBoyBroadcastNotification::count();

            // Count delivery boys with FCM tokens from admin_tokens table
            $totalDeliveryBoysWithTokens = AdminToken::where('type', Role::$roleNameDeliveryBoy)
                ->whereNotNull('fcm_token')
                ->where('fcm_token', '!=', '')
                ->count();

            $last30Days = DeliveryBoyBroadcastNotification::recent(30)->count();
            $totalSuccessful = DeliveryBoyBroadcastNotification::completed()->sum('success_count');

            return response()->json([
                'success' => true,
                'data' => [
                    'total_notifications' => $totalNotifications,
                    'total_active_delivery_boys' => $totalDeliveryBoysWithTokens,
                    'notifications_last_30_days' => $last30Days,
                    'total_successful_deliveries' => $totalSuccessful,
                ]
            ]);
        } catch (\Exception $e) {
            Log::error('DeliveryBoyBroadcastNotificationController@stats: Error', [
                'error' => $e->getMessage()
            ]);
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch stats'
            ], 500);
        }
    }
}
