<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Services\CustomerNotificationService;
use App\Services\DriverNotificationService;
use App\Services\SellerNotificationService;
use App\Models\DeliveryBoy;
use App\Models\Seller;

class OrderChatAuthController extends Controller
{
    /**
     * Send chat notification using auth token
     *
     * Auth guards based on sender_type:
     * - customer: auth:api-customers
     * - driver: auth:api
     * - seller: auth:api
     *
     * Valid chat combinations:
     * - customer <=> driver
     * - seller <=> driver
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function send(Request $request)
    {
        $rules = [
            'order_id' => 'required|integer',
            'message' => 'required|string',
            'sender_type' => 'required|in:customer,driver,seller',
            'receiver_type' => 'required|in:customer,driver,seller'
        ];

        // If driver is sending to seller, seller_id is required
        if ($request->input('sender_type') === 'driver' && $request->input('receiver_type') === 'seller') {
            $rules['seller_id'] = 'required|integer';
        }

        $request->validate($rules);

        $orderId = $request->input('order_id');
        $message = $request->input('message');
        $senderType = $request->input('sender_type');
        $receiverType = $request->input('receiver_type');

        // Validate chat combination - only customer<=>driver and seller<=>driver allowed
        $validCombinations = [
            'customer' => ['driver'],
            'driver' => ['customer', 'seller'],
            'seller' => ['driver']
        ];

        if (!in_array($receiverType, $validCombinations[$senderType])) {
            return response()->json([
                'status' => 0,
                'message' => "Chat between {$senderType} and {$receiverType} is not allowed"
            ], 400);
        }

        // Authenticate based on sender_type
        if ($senderType === 'customer') {
            $authUser = auth()->guard('api-customers')->user();
            $guardUsed = 'api-customers';
        } else {
            // Both driver and seller use api guard
            $authUser = auth()->guard('api')->user();
            $guardUsed = 'api';
        }

        if (!$authUser) {
            Log::warning('Chat API: Unauthorized access attempt', [
                'sender_type' => $senderType,
                'guard_used' => $guardUsed,
                'has_bearer_token' => $request->bearerToken() ? true : false
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized'
            ], 401);
        }

        // Get order details
        $order = DB::table('orders')
            ->where('id', $orderId)
            ->select('id', 'user_id', 'delivery_boy_id')
            ->first();

        if (!$order) {
            return response()->json([
                'status' => 0,
                'message' => 'Order not found'
            ], 404);
        }

        $customerId = $order->user_id;
        $driverId = $order->delivery_boy_id;
        $senderId = null;
        $senderName = null;
        $sellerId = null;

        // Validate the authenticated user and get sender info
        if ($senderType === 'customer') {
            if ($authUser->id != $order->user_id) {
                return response()->json([
                    'status' => 0,
                    'message' => 'You are not authorized to send messages for this order'
                ], 403);
            }
            $senderId = $authUser->id;
            $customer = DB::table('users')->where('id', $customerId)->select('name')->first();
            $senderName = $customer->name ?? 'Customer';
        } elseif ($senderType === 'driver') {
            $deliveryBoy = DeliveryBoy::where('admin_id', $authUser->id)->first();

            if (!$deliveryBoy || $deliveryBoy->id != $order->delivery_boy_id) {
                return response()->json([
                    'status' => 0,
                    'message' => 'You are not authorized to send messages for this order'
                ], 403);
            }
            $senderId = $deliveryBoy->id;
            $senderName = $deliveryBoy->name ?? 'Delivery Partner';
        } elseif ($senderType === 'seller') {
            $seller = Seller::where('admin_id', $authUser->id)->first();

            // dd($seller->id);

            if (!$seller) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Seller not found'
                ], 404);
            }

            // Check if this seller has items in this order
            $sellerInOrder = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->where('seller_id', $seller->id)
                ->exists();

            if (!$sellerInOrder) {
                return response()->json([
                    'status' => 0,
                    'message' => 'You are not authorized to send messages for this order'
                ], 403);
            }
            $senderId = $seller->id;
            $sellerId = $seller->id;
            $senderName = $seller->store_name ?? $seller->name ?? 'Seller';
        }

        // Check if delivery boy is assigned
        if (!$driverId) {
            return response()->json([
                'status' => 0,
                'message' => 'No delivery boy assigned to this order yet'
            ], 400);
        }

        // For driver sending to seller, validate seller exists in order
        if ($senderType === 'driver' && $receiverType === 'seller') {
            $sellerId = $request->input('seller_id');

            $sellerInOrder = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->where('seller_id', $sellerId)
                ->exists();

            if (!$sellerInOrder) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Seller not found in this order'
                ], 404);
            }
        }

        // Send notification to the recipient
        $this->sendChatNotification(
            $orderId,
            $senderType,
            $receiverType,
            $senderId,
            $senderName,
            $customerId,
            $driverId,
            $sellerId,
            $message
        );

        return response()->json([
            'status' => 1,
            'message' => 'Notification sent successfully'
        ]);
    }

    /**
     * Send push notification to the chat recipient
     *
     * @param int $orderId
     * @param string $senderType
     * @param string $receiverType
     * @param int $senderId
     * @param string $senderName
     * @param int $customerId
     * @param int $driverId
     * @param int|null $sellerId
     * @param string $message
     * @return void
     */
    private function sendChatNotification(
        int $orderId,
        string $senderType,
        string $receiverType,
        int $senderId,
        string $senderName,
        int $customerId,
        int $driverId,
        ?int $sellerId,
        string $message
    ): void {
        try {
            $title = "New message from {$senderName}";
            $body = strlen($message) > 100 ? substr($message, 0, 100) . '...' : $message;

            if ($receiverType === 'driver') {
                // Send notification to driver
                DriverNotificationService::send(
                    $driverId,
                    $title,
                    $body,
                    '',
                    'chat_message',
                    $orderId,
                    [
                        'order_id' => (string) $orderId,
                        'sender_type' => $senderType,
                        'sender_id' => (string) $senderId
                    ]
                );

                Log::info('Chat notification sent to driver', [
                    'order_id' => $orderId,
                    'driver_id' => $driverId,
                    'from' => $senderType
                ]);
            } elseif ($receiverType === 'customer') {
                // Send notification to customer
                CustomerNotificationService::send(
                    $customerId,
                    $title,
                    $body,
                    '',
                    'chat',
                    $orderId,
                    [
                        'type' => 'chat_message',
                        'order_id' => (string) $orderId,
                        'sender_type' => $senderType,
                        'sender_id' => (string) $senderId
                    ]
                );

                Log::info('Chat notification sent to customer', [
                    'order_id' => $orderId,
                    'customer_id' => $customerId,
                    'from' => $senderType
                ]);
            } elseif ($receiverType === 'seller' && $sellerId) {
                // Send notification to seller
                SellerNotificationService::send(
                    $sellerId,
                    $title,
                    $body,
                    '',
                    'chat_message',
                    $orderId,
                    [
                        'order_id' => (string) $orderId,
                        'sender_type' => $senderType,
                        'sender_id' => (string) $senderId
                    ]
                );

                Log::info('Chat notification sent to seller', [
                    'order_id' => $orderId,
                    'seller_id' => $sellerId,
                    'from' => $senderType
                ]);
            }
        } catch (\Exception $e) {
            Log::error('Failed to send chat notification', [
                'order_id' => $orderId,
                'sender_type' => $senderType,
                'receiver_type' => $receiverType,
                'error' => $e->getMessage()
            ]);
        }
    }
}
