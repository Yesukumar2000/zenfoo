<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Services\CustomerNotificationService;
use App\Services\DriverNotificationService;
use App\Services\SellerNotificationService;
use App\Services\AdminNotificationService;
use App\Models\DeliveryBoy;
use App\Models\Seller;
use App\Models\Admin;
use App\Services\FirestoreOrderChatService;

class AdminOrderChatController extends Controller
{
    /**
     * Send chat notification for admin conversations
     *
     * Auth guard: auth:api (admin)
     *
     * Valid chat combinations:
     * - admin <=> customer
     * - admin <=> seller
     * - admin <=> driver
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function send(Request $request)
    {
        $rules = [
            'order_id' => 'required|integer',
            'message' => 'required|string',
            'sender_type' => 'required|in:admin,customer,seller,driver',
            'receiver_type' => 'required|in:admin,customer,seller,driver'
        ];

        // If sending to/from seller, seller_id is required
        if ($request->input('receiver_type') === 'seller' || $request->input('sender_type') === 'seller') {
            $rules['seller_id'] = 'required|integer';
        }

        $request->validate($rules);

        $orderId = $request->input('order_id');
        $message = $request->input('message');
        $senderType = $request->input('sender_type');
        $receiverType = $request->input('receiver_type');
        $sellerId = $request->input('seller_id');

        // Validate chat combination - only admin <=> (customer/seller/driver) allowed
        $validCombinations = [
            'admin' => ['customer', 'seller', 'driver'],
            'customer' => ['admin'],
            'seller' => ['admin'],
            'driver' => ['admin']
        ];

        if (!in_array($receiverType, $validCombinations[$senderType])) {
            return response()->json([
                'status' => 0,
                'message' => "Chat between {$senderType} and {$receiverType} is not allowed in this endpoint"
            ], 400);
        }

        // Authenticate based on sender_type
        if ($senderType === 'customer') {
            $authUser = auth()->guard('api-customers')->user();
            $guardUsed = 'api-customers';
        } else {
            // admin, driver, seller use api guard
            $authUser = auth()->guard('api')->user();
            $guardUsed = 'api';
        }

        if (!$authUser) {
            Log::warning('Admin Chat API: Unauthorized access attempt', [
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

        // Validate the authenticated user and get sender info
        if ($senderType === 'admin') {
            // Verify user is an admin (not seller or driver)
            $isAdmin = $this->isUserAdmin($authUser->id);
            if (!$isAdmin) {
                return response()->json([
                    'status' => 0,
                    'message' => 'You are not authorized as admin'
                ], 403);
            }
            $senderId = $authUser->id;
            $senderName = $authUser->name ?? 'Support';
        } elseif ($senderType === 'customer') {
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

            if (!$seller) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Seller not found'
                ], 404);
            }

            // Validate seller_id matches authenticated seller
            if ($seller->id != $sellerId) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Seller ID does not match authenticated user'
                ], 403);
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
            $senderName = $seller->store_name ?? $seller->name ?? 'Seller';
        }

        // For admin sending to seller, validate seller exists in order
        if ($senderType === 'admin' && $receiverType === 'seller') {
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

        // For admin sending to driver, check if driver is assigned
        if ($senderType === 'admin' && $receiverType === 'driver') {
            if (!$driverId) {
                return response()->json([
                    'status' => 0,
                    'message' => 'No delivery boy assigned to this order yet'
                ], 400);
            }
        }

        // Determine Firestore chat_type
        $chatType = '';
        if ($senderType === 'customer' || $receiverType === 'customer') {
            $chatType = 'customer';
        } elseif ($senderType === 'driver' || $receiverType === 'driver') {
            $chatType = 'driver';
        } elseif ($senderType === 'seller' || $receiverType === 'seller') {
            // Use the seller ID (either sender or receiver)
            $targetSellerId = ($senderType === 'seller' ? $senderId : $sellerId);
            $chatType = 'seller_' . $targetSellerId;
        }

        // Save message to Firestore
        $firestoreResult = FirestoreOrderChatService::sendMessage(
            (int) $orderId,
            $chatType,
            $message,
            (string) $senderId,
            $senderName,
            $senderType,
            $receiverType
        );

        if (!$firestoreResult['success']) {
            Log::error('AdminOrderChatController: Failed to save message to Firestore', [
                'order_id' => $orderId,
                'chat_type' => $chatType,
                'error' => $firestoreResult['message'] ?? 'Unknown error'
            ]);
            // We still proceed to send notification, as it might be critical
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
     * Check if user is an admin (not seller or driver)
     *
     * @param int $userId
     * @return bool
     */
    private function isUserAdmin(int $userId): bool
    {
        // Check if user has a seller record
        $isSeller = Seller::where('admin_id', $userId)->exists();
        if ($isSeller) {
            return false;
        }

        // Check if user has a delivery boy record
        $isDriver = DeliveryBoy::where('admin_id', $userId)->exists();
        if ($isDriver) {
            return false;
        }

        return true;
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
     * @param int|null $driverId
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
        ?int $driverId,
        ?int $sellerId,
        string $message
    ): void {
        try {
            $title = "New message from {$senderName}";
            $body = strlen($message) > 100 ? substr($message, 0, 100) . '...' : $message;

            if ($receiverType === 'admin') {
                // Build extra data for admin notification
                $adminExtraData = [
                    'order_id' => (string) $orderId,
                    'sender_type' => $senderType,
                    'sender_id' => (string) $senderId
                ];

                // Add seller_id if sender is seller (for navigation to specific seller tab)
                if ($senderType === 'seller' && $sellerId) {
                    $adminExtraData['seller_id'] = (string) $sellerId;
                }

                // Send notification to admin
                AdminNotificationService::send(
                    null, // null means all admins
                    $title,
                    $body,
                    'chat_message',
                    $adminExtraData
                );

                Log::info('Chat notification sent to admin', [
                    'order_id' => $orderId,
                    'from' => $senderType,
                    'sender_id' => $senderId
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

                Log::info('Chat notification sent to customer from admin', [
                    'order_id' => $orderId,
                    'customer_id' => $customerId
                ]);
            } elseif ($receiverType === 'driver' && $driverId) {
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

                Log::info('Chat notification sent to driver from admin', [
                    'order_id' => $orderId,
                    'driver_id' => $driverId
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

                Log::info('Chat notification sent to seller from admin', [
                    'order_id' => $orderId,
                    'seller_id' => $sellerId
                ]);
            }
        } catch (\Exception $e) {
            Log::error('Failed to send admin chat notification', [
                'order_id' => $orderId,
                'sender_type' => $senderType,
                'receiver_type' => $receiverType,
                'error' => $e->getMessage()
            ]);
        }
    }
}
