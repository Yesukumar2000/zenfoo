<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Seller;
use App\Services\AdminNotificationService;
use App\Services\SellerNotificationService;
use App\Services\FirestoreAdminSellerChatService;
use App\Services\FirestoreOrderChatService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class AdminSellerChatController extends Controller
{
    /**
     * Get all seller chats for admin panel listing
     */
    public function getAllChats(Request $request)
    {
        try {
            $limit = $request->input('limit', 50);

            $result = FirestoreAdminSellerChatService::getAllChats($limit);

            if ($result['success']) {
                return CommonHelper::responseWithData($result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminSellerChatController: Error getting all chats', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to get chats');
        }
    }

    /**
     * Initialize chat for a seller
     */
    public function initializeChat(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'seller_id' => 'required|integer|exists:sellers,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $sellerId = $request->input('seller_id');
            $seller = Seller::find($sellerId);
            $sellerName = $seller ? ($seller->name ?? '') : '';

            $result = FirestoreAdminSellerChatService::initializeChat($sellerId, $sellerName);

            if ($result['success']) {
                return CommonHelper::responseSuccessWithData($result['message'], $result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminSellerChatController: Error initializing chat', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to initialize chat');
        }
    }

    /**
     * Send message to seller
     */
    public function sendMessage(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'seller_id' => 'required|integer',
                'message' => 'required|string|max:2000'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $sellerId = $request->input('seller_id');
            $message = $request->input('message');
            $adminId = auth()->id() ?? 0;

            $result = FirestoreAdminSellerChatService::sendMessage(
                $sellerId,
                $adminId,
                $message,
                'admin'
            );

            if ($result['success']) {
                // Send push notification to seller
                try {
                    SellerNotificationService::send(
                        $sellerId,
                        'New Message from Admin',
                        $message,
                        '',
                        'admin_chat',
                        null,
                        ['chat_type' => 'admin_support']
                    );
                } catch (\Exception $notifError) {
                    Log::warning('AdminSellerChatController: Failed to send notification', [
                        'seller_id' => $sellerId,
                        'error' => $notifError->getMessage()
                    ]);
                }

                return CommonHelper::responseSuccessWithData($result['message'], $result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminSellerChatController: Error sending message', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to send message');
        }
    }

    /**
     * Get messages for a specific seller chat
     */
    public function getMessages(Request $request, $sellerId)
    {
        try {
            $limit = $request->input('limit', 50);

            $result = FirestoreAdminSellerChatService::getMessages((int) $sellerId, $limit);

            if ($result['success']) {
                // Also get seller details
                $seller = Seller::find($sellerId);
                $result['data']['seller'] = $seller ? [
                    'id' => $seller->id,
                    'name' => $seller->name,
                    'mobile' => $seller->mobile,
                    'email' => $seller->email
                ] : null;

                return CommonHelper::responseWithData($result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminSellerChatController: Error getting messages', [
                'seller_id' => $sellerId,
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
                'seller_id' => 'required|integer'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $sellerId = $request->input('seller_id');

            $result = FirestoreAdminSellerChatService::markAsRead($sellerId);

            if ($result['success']) {
                return CommonHelper::responseSuccess($result['message']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminSellerChatController: Error marking as read', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to mark as read');
        }
    }

    /**
     * Delete chat for a seller
     */
    public function deleteChat(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'seller_id' => 'required|integer'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $sellerId = $request->input('seller_id');

            $result = FirestoreAdminSellerChatService::deleteChat($sellerId);

            if ($result['success']) {
                return CommonHelper::responseSuccess($result['message']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminSellerChatController: Error deleting chat', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to delete chat');
        }
    }

    /**
     * Seller sends message to admin support
     * Auth guard: api (uses Admin model, then looks up Seller)
     * Sends notification to admin with type 'seller_support_screen'
     */
    public function sellerSendMessage(Request $request)
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

            // Get seller by admin_id
            $seller = Seller::where('admin_id', $user->id)->first();

            if (!$seller) {
                return CommonHelper::responseError('Seller account not found', 404);
            }

            $sellerId = $seller->id;
            $message = $request->input('message');
            $sellerName = $seller->name ?? 'Seller';

            // Initialize chat if not exists
            FirestoreAdminSellerChatService::initializeChat($sellerId, $sellerName);

            // Send the message
            $result = FirestoreAdminSellerChatService::sendMessage(
                $sellerId,
                $sellerId,
                $message,
                'seller'
            );

            if ($result['success']) {
                // Send push notification to admin
                try {
                    AdminNotificationService::send(
                        null, // Send to all admins
                        'New Support Message from Seller',
                        "New message from {$sellerName}: " . (strlen($message) > 50 ? substr($message, 0, 50) . '...' : $message),
                        'seller_support_screen',
                        [
                            'seller_id' => (string) $sellerId,
                            'click_action' => url("/sellers/view/{$sellerId}?tab=support")
                        ]
                    );
                } catch (\Exception $notifError) {
                    Log::warning('AdminSellerChatController: Failed to send admin notification', [
                        'seller_id' => $sellerId,
                        'error' => $notifError->getMessage()
                    ]);
                }

                return CommonHelper::responseSuccessWithData($result['message'], $result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminSellerChatController: Error in sellerSendMessage', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to send message');
        }
    }

    /**
     * Get messages for seller's own chat with admin
     * Auth guard: api (uses Admin model, then looks up Seller)
     */
    public function sellerGetMessages(Request $request)
    {
        try {
            // Get authenticated user (Admin model)
            $user = auth()->user();

            if (!$user) {
                return CommonHelper::responseError('Unauthorized', 401);
            }

            // Get seller by admin_id
            $seller = Seller::where('admin_id', $user->id)->first();

            if (!$seller) {
                return CommonHelper::responseError('Seller account not found', 404);
            }

            $sellerId = $seller->id;
            $limit = $request->input('limit', 50);

            $result = FirestoreAdminSellerChatService::getMessages($sellerId, $limit);

            if ($result['success']) {
                return CommonHelper::responseWithData($result['data']);
            }

            return CommonHelper::responseError($result['message']);
        } catch (\Exception $e) {
            Log::error('AdminSellerChatController: Error in sellerGetMessages', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to get messages');
        }
    }

    /**
     * Seller sends order-related message to admin support
     * Auth guard: api
     */
    public function sellerSendOrderMessage(Request $request)
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

            $seller = Seller::where('admin_id', $user->id)->first();
            if (!$seller) {
                return CommonHelper::responseError('Seller account not found', 404);
            }

            $sellerId = $seller->id;
            $message = $request->input('message');
            $orderId = $request->input('order_id');
            $sellerName = $seller->store_name ?? $seller->name ?? 'Seller';

            // Send push notification to admin
            try {
                AdminNotificationService::send(
                    null,
                    'Order #' . $orderId . ' - Seller Support',
                    "Message from {$sellerName}: " . (strlen($message) > 50 ? substr($message, 0, 50) . '...' : $message),
                    'chat_message',
                    [
                        'order_id' => (string) $orderId,
                        'seller_id' => (string) $sellerId,
                        'sender_type' => 'seller',
                    ]
                );
            } catch (\Exception $notifError) {
                Log::warning('AdminSellerChatController: Failed to send admin notification', [
                    'seller_id' => $sellerId,
                    'order_id' => $orderId,
                    'error' => $notifError->getMessage()
                ]);
            }

            return CommonHelper::responseSuccess('Message sent to admin');
        } catch (\Exception $e) {
            Log::error('AdminSellerChatController: Error in sellerSendOrderMessage', [
                'error' => $e->getMessage()
            ]);
            return CommonHelper::responseError('Failed to send message');
        }
    }
}