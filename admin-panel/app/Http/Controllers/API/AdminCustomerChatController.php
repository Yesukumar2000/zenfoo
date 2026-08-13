<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\AdminNotificationService;
use App\Services\CustomerNotificationService;
use App\Services\FirestoreAdminCustomerChatService;
use App\Services\FirestoreOrderChatService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class AdminCustomerChatController extends Controller
{
    /**
     * Get all customer chats for admin panel listing
     */
    public function getAllChats(Request $request)
    {
        try {
            $limit = $request->input('limit', 50);

            $result = FirestoreAdminCustomerChatService::getAllChats($limit);

            if ($result['success']) {
                return CommonHelper::responseWithData($result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminCustomerChatController: Error getting all chats', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to get chats');
        }
    }

    /**
     * Initialize chat for a customer
     */
    public function initializeChat(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'customer_id' => 'required|integer|exists:users,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $customerId = $request->input('customer_id');
            $customer = User::find($customerId);
            $customerName = $customer ? ($customer->name ?? '') : '';

            $result = FirestoreAdminCustomerChatService::initializeChat($customerId, $customerName);

            if ($result['success']) {
                return CommonHelper::responseSuccessWithData($result['message'], $result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminCustomerChatController: Error initializing chat', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to initialize chat');
        }
    }

    /**
     * Send message to customer
     */
    public function sendMessage(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'customer_id' => 'required|integer',
                'message' => 'required|string|max:2000'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $customerId = $request->input('customer_id');
            $message = $request->input('message');
            $adminId = auth()->id() ?? 0;

            $result = FirestoreAdminCustomerChatService::sendMessage(
                $customerId,
                $adminId,
                $message,
                'admin'
            );

            if ($result['success']) {
                // Send push notification to customer
                try {
                    CustomerNotificationService::send(
                        $customerId,
                        'New Message from Support',
                        $message,
                        '',
                        'chat',
                        $customerId,
                        ['chat_type' => 'admin_support']
                    );
                } catch (\Exception $notifError) {
                    Log::warning('AdminCustomerChatController: Failed to send notification', [
                        'customer_id' => $customerId,
                        'error' => $notifError->getMessage()
                    ]);
                }

                return CommonHelper::responseSuccessWithData($result['message'], $result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminCustomerChatController: Error sending message', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to send message');
        }
    }

    /**
     * Get messages for a specific customer chat
     */
    public function getMessages(Request $request, $customerId)
    {
        try {
            $limit = $request->input('limit', 50);

            $result = FirestoreAdminCustomerChatService::getMessages((int) $customerId, $limit);

            if ($result['success']) {
                // Also get customer details
                $customer = User::find($customerId);
                $result['data']['customer'] = $customer ? [
                    'id' => $customer->id,
                    'name' => $customer->name,
                    'mobile' => $customer->mobile,
                    'email' => $customer->email
                ] : null;

                return CommonHelper::responseWithData($result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminCustomerChatController: Error getting messages', [
                'customer_id' => $customerId,
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
                'customer_id' => 'required|integer'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $customerId = $request->input('customer_id');

            $result = FirestoreAdminCustomerChatService::markAsRead($customerId);

            if ($result['success']) {
                return CommonHelper::responseSuccess($result['message']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminCustomerChatController: Error marking as read', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to mark as read');
        }
    }

    /**
     * Delete chat for a customer
     */
    public function deleteChat(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'customer_id' => 'required|integer'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $customerId = $request->input('customer_id');

            $result = FirestoreAdminCustomerChatService::deleteChat($customerId);

            if ($result['success']) {
                return CommonHelper::responseSuccess($result['message']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminCustomerChatController: Error deleting chat', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to delete chat');
        }
    }

    /**
     * Customer sends message to admin support
     * Auth guard: api-customers
     * Sends notification to admin with type 'customer_support_screen'
     */
    public function customerSendMessage(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'message' => 'required|string|max:2000'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Get authenticated customer
            $customer = auth()->guard('api-customers')->user();

            if (!$customer) {
                return CommonHelper::responseError('Unauthorized', 401);
            }

            $customerId = $customer->id;
            $message = $request->input('message');
            $customerName = $customer->name ?? 'Customer';

            // Initialize chat if not exists
            FirestoreAdminCustomerChatService::initializeChat($customerId, $customerName);

            // Send the message
            $result = FirestoreAdminCustomerChatService::sendMessage(
                $customerId,
                $customerId,
                $message,
                'customer'
            );

            if ($result['success']) {
                // Send push notification to admin
                try {
                    AdminNotificationService::send(
                        null, // Send to all admins
                        'New Support Message',
                        "New message from {$customerName}: " . (strlen($message) > 50 ? substr($message, 0, 50) . '...' : $message),
                        'customer_support_screen',
                        [
                            'customer_id' => (string) $customerId,
                            'click_action' => url("/users/view/{$customerId}?tab=support")
                        ]
                    );
                } catch (\Exception $notifError) {
                    Log::warning('AdminCustomerChatController: Failed to send admin notification', [
                        'customer_id' => $customerId,
                        'error' => $notifError->getMessage()
                    ]);
                }

                return CommonHelper::responseSuccessWithData($result['message'], $result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminCustomerChatController: Error in customerSendMessage', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to send message');
        }
    }

    /**
     * Customer sends order-related message to admin support
     * Auth guard: api-customers
     * Sends notification to admin with order_id for navigation to order screen chat tab
     */
    public function customerSendOrderMessage(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'message' => 'required|string|max:2000',
                'order_id' => 'required|integer'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $customer = auth()->guard('api-customers')->user();

            if (!$customer) {
                return CommonHelper::responseError('Unauthorized', 401);
            }

            $customerId = $customer->id;
            $message = $request->input('message');
            $orderId = $request->input('order_id');
            $customerName = $customer->name ?? 'Customer';

            // Send push notification to admin with order_id for navigation
            try {
                AdminNotificationService::send(
                    null,
                    'Order #' . $orderId . ' - Customer Support',
                    "Message from {$customerName}: " . (strlen($message) > 50 ? substr($message, 0, 50) . '...' : $message),
                    'chat_message',
                    [
                        'order_id' => (string) $orderId,
                        'customer_id' => (string) $customerId,
                        'sender_type' => 'customer',
                    ]
                );
            } catch (\Exception $notifError) {
                Log::warning('AdminCustomerChatController: Failed to send admin notification', [
                    'customer_id' => $customerId,
                    'order_id' => $orderId,
                    'error' => $notifError->getMessage()
                ]);
            }

            return CommonHelper::responseSuccess('Message sent to admin');
        } catch (\Exception $e) {
            Log::error('AdminCustomerChatController: Error in customerSendOrderMessage', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to send message');
        }
    }

    /**
     * Get messages for customer's own chat with admin
     * Auth guard: api-customers
     */
    public function customerGetMessages(Request $request)
    {
        try {
            // Get authenticated customer
            $customer = auth()->guard('api-customers')->user();

            if (!$customer) {
                return CommonHelper::responseError('Unauthorized', 401);
            }

            $customerId = $customer->id;
            $limit = $request->input('limit', 50);

            $result = FirestoreAdminCustomerChatService::getMessages($customerId, $limit);

            if ($result['success']) {
                return CommonHelper::responseWithData($result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminCustomerChatController: Error in customerGetMessages', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to get messages');
        }
    }
}
