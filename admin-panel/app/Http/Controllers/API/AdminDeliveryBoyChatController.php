<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Services\AdminNotificationService;
use App\Services\DriverNotificationService;
use App\Services\FirestoreAdminDeliveryBoyChatService;
use App\Services\FirestoreOrderChatService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class AdminDeliveryBoyChatController extends Controller
{
    /**
     * Get all delivery boy chats for admin panel listing
     */
    public function getAllChats(Request $request)
    {
        try {
            $limit = $request->input('limit', 50);

            $result = FirestoreAdminDeliveryBoyChatService::getAllChats($limit);

            if ($result['success']) {
                return CommonHelper::responseWithData($result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminDeliveryBoyChatController: Error getting all chats', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to get chats');
        }
    }

    /**
     * Initialize chat for a delivery boy
     */
    public function initializeChat(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'delivery_boy_id' => 'required|integer|exists:delivery_boys,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $deliveryBoyId = $request->input('delivery_boy_id');
            $deliveryBoy = DeliveryBoy::find($deliveryBoyId);
            $deliveryBoyName = $deliveryBoy ? ($deliveryBoy->name ?? '') : '';

            $result = FirestoreAdminDeliveryBoyChatService::initializeChat($deliveryBoyId, $deliveryBoyName);

            if ($result['success']) {
                return CommonHelper::responseSuccessWithData($result['message'], $result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminDeliveryBoyChatController: Error initializing chat', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to initialize chat');
        }
    }

    /**
     * Send message to delivery boy
     */
    public function sendMessage(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'delivery_boy_id' => 'required|integer',
                'message' => 'required|string|max:2000'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $deliveryBoyId = $request->input('delivery_boy_id');
            $message = $request->input('message');
            $adminId = auth()->id() ?? 0;

            $result = FirestoreAdminDeliveryBoyChatService::sendMessage(
                $deliveryBoyId,
                $adminId,
                $message,
                'admin'
            );

            if ($result['success']) {
                // Send push notification to delivery boy
                try {
                    DriverNotificationService::send(
                        $deliveryBoyId,
                        'New Message from Admin',
                        $message,
                        '',
                        'admin_chat',
                        null,
                        ['chat_type' => 'admin_support']
                    );
                } catch (\Exception $notifError) {
                    Log::warning('AdminDeliveryBoyChatController: Failed to send notification', [
                        'delivery_boy_id' => $deliveryBoyId,
                        'error' => $notifError->getMessage()
                    ]);
                }

                return CommonHelper::responseSuccessWithData($result['message'], $result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminDeliveryBoyChatController: Error sending message', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to send message');
        }
    }

    /**
     * Get messages for a specific delivery boy chat
     */
    public function getMessages(Request $request, $deliveryBoyId)
    {
        try {
            $limit = $request->input('limit', 50);

            $result = FirestoreAdminDeliveryBoyChatService::getMessages((int) $deliveryBoyId, $limit);

            if ($result['success']) {
                // Also get delivery boy details
                $deliveryBoy = DeliveryBoy::find($deliveryBoyId);
                $result['data']['delivery_boy'] = $deliveryBoy ? [
                    'id' => $deliveryBoy->id,
                    'name' => $deliveryBoy->name,
                    'mobile' => $deliveryBoy->mobile,
                    'email' => $deliveryBoy->email
                ] : null;

                return CommonHelper::responseWithData($result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminDeliveryBoyChatController: Error getting messages', [
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to get messages');
        }
    }

    /**
     * Mark messages as read
     */
    public function markAsRead(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'delivery_boy_id' => 'required|integer'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $deliveryBoyId = $request->input('delivery_boy_id');

            $result = FirestoreAdminDeliveryBoyChatService::markAsRead($deliveryBoyId);

            if ($result['success']) {
                return CommonHelper::responseSuccess($result['message']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminDeliveryBoyChatController: Error marking as read', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to mark as read');
        }
    }

    /**
     * Delete chat for a delivery boy
     */
    public function deleteChat(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'delivery_boy_id' => 'required|integer'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $deliveryBoyId = $request->input('delivery_boy_id');

            $result = FirestoreAdminDeliveryBoyChatService::deleteChat($deliveryBoyId);

            if ($result['success']) {
                return CommonHelper::responseSuccess($result['message']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminDeliveryBoyChatController: Error deleting chat', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to delete chat');
        }
    }

    /**
     * Delivery boy sends message to admin support
     * Auth guard: api (uses Admin model, then looks up DeliveryBoy)
     * Sends notification to admin with type 'driver_support_screen'
     */
    public function deliveryBoySendMessage(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'message' => 'required|string|max:2000'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Get authenticated user (Admin model)
            $user = auth()->user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized', 401);
            }

            // Get delivery boy by admin_id
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found', 404);
            }

            $deliveryBoyId = $deliveryBoy->id;
            $message = $request->input('message');
            $deliveryBoyName = $deliveryBoy->name ?? 'Driver';

            // Initialize chat if not exists
            FirestoreAdminDeliveryBoyChatService::initializeChat($deliveryBoyId, $deliveryBoyName);

            // Send the message
            $result = FirestoreAdminDeliveryBoyChatService::sendMessage(
                $deliveryBoyId,
                $deliveryBoyId,
                $message,
                'delivery_boy'
            );

            if ($result['success']) {
                // Send push notification to admin
                try {
                    AdminNotificationService::send(
                        null, // Send to all admins
                        'New Support Message from Driver',
                        "New message from {$deliveryBoyName}: " . (strlen($message) > 50 ? substr($message, 0, 50) . '...' : $message),
                        'driver_support_screen',
                        [
                            'driver_id' => (string) $deliveryBoyId,
                            'delivery_boy_id' => (string) $deliveryBoyId,
                            'click_action' => url("/delivery_boys/view/{$deliveryBoyId}?tab=support")
                        ]
                    );
                } catch (\Exception $notifError) {
                    Log::warning('AdminDeliveryBoyChatController: Failed to send admin notification', [
                        'delivery_boy_id' => $deliveryBoyId,
                        'error' => $notifError->getMessage()
                    ]);
                }

                return CommonHelper::responseSuccessWithData($result['message'], $result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminDeliveryBoyChatController: Error in deliveryBoySendMessage', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to send message');
        }
    }

    /**
     * Get messages for delivery boy's own chat with admin
     * Auth guard: api (uses Admin model, then looks up DeliveryBoy)
     */
    public function deliveryBoyGetMessages(Request $request)
    {
        try {
            // Get authenticated user (Admin model)
            $user = auth()->user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized', 401);
            }

            // Get delivery boy by admin_id
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found', 404);
            }

            $deliveryBoyId = $deliveryBoy->id;
            $limit = $request->input('limit', 50);

            $result = FirestoreAdminDeliveryBoyChatService::getMessages($deliveryBoyId, $limit);

            if ($result['success']) {
                return CommonHelper::responseWithData($result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminDeliveryBoyChatController: Error in deliveryBoyGetMessages', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to get messages');
        }
    }

    /**
     * Delivery boy sends order-related message to admin support
     * Auth guard: api
     */
    public function deliveryBoySendOrderMessage(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'message' => 'required|string|max:2000',
                'order_id' => 'required|integer'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $user = auth()->user();
            if (!$user) {
                return CommonHelper::responseError('Unauthorized', 401);
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError('Delivery boy account not found', 404);
            }

            $deliveryBoyId = $deliveryBoy->id;
            $message = $request->input('message');
            $orderId = $request->input('order_id');
            $deliveryBoyName = $deliveryBoy->name ?? 'Driver';

            // Send push notification to admin
            try {
                AdminNotificationService::send(
                    null,
                    'Order #' . $orderId . ' - Driver Support',
                    "Message from {$deliveryBoyName}: " . (strlen($message) > 50 ? substr($message, 0, 50) . '...' : $message),
                    'chat_message',
                    [
                        'order_id' => (string) $orderId,
                        'driver_id' => (string) $deliveryBoyId,
                        'sender_type' => 'driver',
                    ]
                );
            } catch (\Exception $notifError) {
                Log::warning('AdminDeliveryBoyChatController: Failed to send admin notification', [
                    'delivery_boy_id' => $deliveryBoyId,
                    'order_id' => $orderId,
                    'error' => $notifError->getMessage()
                ]);
            }

            return CommonHelper::responseSuccess('Message sent to admin');
        } catch (\Exception $e) {
            Log::error('AdminDeliveryBoyChatController: Error in deliveryBoySendOrderMessage', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to send message');
        }
    }
}
