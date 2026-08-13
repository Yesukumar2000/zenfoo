<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\FirestoreOrderChatService;
use App\Services\CustomerNotificationService;
use App\Services\SellerNotificationService;
use App\Services\DriverNotificationService;
use App\Helpers\CommonHelper;
use App\Models\Order;
use App\Models\Seller;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class OrderChatController extends Controller
{
    /**
     * Get sellers for a specific order from order_seller_status_tracking table
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getOrderSellers(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            // Get unique seller IDs from order_seller_status_tracking
            $sellerIds = DB::table('order_seller_status_tracking')
                ->where('order_id', $request->order_id)
                ->distinct()
                ->pluck('seller_id')
                ->toArray();

            if (empty($sellerIds)) {
                return response()->json([
                    'status' => 1,
                    'message' => 'No sellers found for this order',
                    'data' => []
                ]);
            }

            // Get seller details
            $sellers = Seller::whereIn('id', $sellerIds)
                ->select('id', 'name', 'store_name', 'mobile')
                ->get()
                ->map(function ($seller) {
                    return [
                        'id' => $seller->id,
                        'name' => $seller->name ?? $seller->store_name ?? 'Seller #' . $seller->id,
                        'store_name' => $seller->store_name,
                        'chat_type' => 'seller_' . $seller->id
                    ];
                });

            return response()->json([
                'status' => 1,
                'message' => 'Order sellers fetched successfully',
                'data' => $sellers
            ]);

        } catch (\Exception $e) {
            Log::error('OrderChatController: Error fetching order sellers', [
                'order_id' => $request->order_id,
                'error' => $e->getMessage()
            ]);

            return CommonHelper::responseError('Failed to fetch order sellers');
        }
    }

    /**
     * Get chat messages for a specific order and chat type
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getMessages(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
            'chat_type' => 'required|string|max:50'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Validate chat_type format (customer, driver, or seller_*)
        $chatType = $request->chat_type;
        if (!$this->isValidChatType($chatType)) {
            return CommonHelper::responseError('Invalid chat type');
        }

        $result = FirestoreOrderChatService::getMessages(
            $request->order_id,
            $chatType
        );

        if ($result['success']) {
            return response()->json([
                'status' => 1,
                'message' => $result['message'],
                'data' => $result['data']
            ]);
        }

        return CommonHelper::responseError($result['message']);
    }

    /**
     * Send a message to a specific order chat
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function sendMessage(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
            'chat_type' => 'required|string|max:50',
            'message' => 'required|string|max:5000'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Validate chat_type format
        $chatType = $request->chat_type;
        if (!$this->isValidChatType($chatType)) {
            return CommonHelper::responseError('Invalid chat type');
        }

        // Get admin info from auth
        $admin = auth()->user();

        if (!$admin) {
            return CommonHelper::responseError('Unauthorized');
        }

        // Determine recipient type based on chat type
        $recipientType = $this->getRecipientType($chatType);

        $result = FirestoreOrderChatService::sendMessage(
            $request->order_id,
            $chatType,
            $request->message,
            (string) $admin->id,
            $admin->name ?? 'Admin',
            'admin',
            $recipientType
        );

        if ($result['success']) {
            // Send push notification to the recipient
            $this->sendChatNotification(
                $request->order_id,
                $chatType,
                $request->message
            );

            return response()->json([
                'status' => 1,
                'message' => $result['message'],
                'data' => $result['data']
            ]);
        }

        return CommonHelper::responseError($result['message']);
    }

    /**
     * Send push notification for chat message
     *
     * @param int $orderId
     * @param string $chatType
     * @param string $message
     * @return void
     */
    private function sendChatNotification(int $orderId, string $chatType, string $message): void
    {
        try {
            $order = Order::find($orderId);
            if (!$order) {
                Log::warning('OrderChatController: Order not found for notification', ['order_id' => $orderId]);
                return;
            }

            $title = "New message from Support Team";
            // Truncate message for notification if too long
            $notificationMessage = strlen($message) > 100 ? substr($message, 0, 97) . '...' : $message;

            $extraData = [
                'order_id' => (string) $orderId,
                'chat_type' => $chatType,
                'data_only' => true  // Skip android.notification to prevent duplicate notifications
            ];

            if ($chatType === 'customer') {
                // Send notification to customer
                if ($order->user_id) {
                    CustomerNotificationService::send(
                        (int) $order->user_id,
                        $title,
                        $notificationMessage,
                        '',
                        'order_chat',
                        $orderId,
                        $extraData
                    );
                    Log::info('OrderChatController: Customer notification sent', [
                        'order_id' => $orderId,
                        'customer_id' => $order->user_id
                    ]);
                }
            } elseif ($chatType === 'driver') {
                // Send notification to driver
                if ($order->delivery_boy_id) {
                    DriverNotificationService::send(
                        (int) $order->delivery_boy_id,
                        $title,
                        $notificationMessage,
                        '',
                        'order_chat',
                        null,
                        $extraData
                    );
                    Log::info('OrderChatController: Driver notification sent', [
                        'order_id' => $orderId,
                        'driver_id' => $order->delivery_boy_id
                    ]);
                }
            } elseif (str_starts_with($chatType, 'seller_')) {
                // Extract seller ID from chat type (e.g., seller_123 -> 123)
                $sellerId = (int) str_replace('seller_', '', $chatType);
                if ($sellerId > 0) {
                    SellerNotificationService::send(
                        $sellerId,
                        $title,
                        $notificationMessage,
                        '',
                        'order_chat',
                        $orderId,
                        $extraData
                    );
                    Log::info('OrderChatController: Seller notification sent', [
                        'order_id' => $orderId,
                        'seller_id' => $sellerId
                    ]);
                }
            }
        } catch (\Exception $e) {
            // Log error but don't fail the chat message send
            Log::error('OrderChatController: Failed to send chat notification', [
                'order_id' => $orderId,
                'chat_type' => $chatType,
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * Mark messages as read
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function markAsRead(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
            'chat_type' => 'required|string|max:50',
            'message_ids' => 'required|array',
            'message_ids.*' => 'required|string'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Validate chat_type format
        $chatType = $request->chat_type;
        if (!$this->isValidChatType($chatType)) {
            return CommonHelper::responseError('Invalid chat type');
        }

        $result = FirestoreOrderChatService::markMessagesAsRead(
            $request->order_id,
            $chatType,
            $request->message_ids
        );

        if ($result['success']) {
            return response()->json([
                'status' => 1,
                'message' => $result['message'],
                'data' => $result['data']
            ]);
        }

        return CommonHelper::responseError($result['message']);
    }

    /**
     * Get unread message count for a specific order and chat type
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getUnreadCount(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer',
            'chat_type' => 'required|string|max:50'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Validate chat_type format
        $chatType = $request->chat_type;
        if (!$this->isValidChatType($chatType)) {
            return CommonHelper::responseError('Invalid chat type');
        }

        $result = FirestoreOrderChatService::getUnreadCount(
            $request->order_id,
            $chatType,
            'admin'
        );

        if ($result['success']) {
            return response()->json([
                'status' => 1,
                'message' => $result['message'],
                'data' => $result['data']
            ]);
        }

        return CommonHelper::responseError($result['message']);
    }

    /**
     * Get unread counts for all chat types for a specific order
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getAllUnreadCounts(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|integer'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $unreadCounts = [
            'customer' => 0,
            'driver' => 0,
            'sellers' => []
        ];

        // Get customer unread count
        $customerResult = FirestoreOrderChatService::getUnreadCount(
            $request->order_id,
            'customer',
            'admin'
        );
        $unreadCounts['customer'] = $customerResult['data']['unread_count'] ?? 0;

        // Get driver unread count
        $driverResult = FirestoreOrderChatService::getUnreadCount(
            $request->order_id,
            'driver',
            'admin'
        );
        $unreadCounts['driver'] = $driverResult['data']['unread_count'] ?? 0;

        // Get seller unread counts
        $sellerIds = DB::table('order_seller_status_tracking')
            ->where('order_id', $request->order_id)
            ->distinct()
            ->pluck('seller_id')
            ->toArray();

        foreach ($sellerIds as $sellerId) {
            $chatType = 'seller_' . $sellerId;
            $sellerResult = FirestoreOrderChatService::getUnreadCount(
                $request->order_id,
                $chatType,
                'admin'
            );
            $unreadCounts['sellers'][$chatType] = $sellerResult['data']['unread_count'] ?? 0;
        }

        return response()->json([
            'status' => 1,
            'message' => 'Unread counts fetched successfully',
            'data' => $unreadCounts
        ]);
    }

    /**
     * Validate chat type format
     *
     * @param string $chatType
     * @return bool
     */
    private function isValidChatType(string $chatType): bool
    {
        // Allow: customer, driver, seller_*
        if (in_array($chatType, ['customer', 'driver'])) {
            return true;
        }

        // Check for seller_* format
        if (preg_match('/^seller_\d+$/', $chatType)) {
            return true;
        }

        return false;
    }

    /**
     * Get recipient type based on chat type
     *
     * @param string $chatType
     * @return string
     */
    private function getRecipientType(string $chatType): string
    {
        if ($chatType === 'customer') {
            return 'customer';
        }
        if ($chatType === 'driver') {
            return 'driver';
        }
        if (str_starts_with($chatType, 'seller_')) {
            return 'seller';
        }
        return $chatType;
    }
}
