<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Message;
use App\Models\Seller;
use App\Models\DeliveryBoy;
use App\Models\Order;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class SellerDeliveryMessagesApiController extends Controller
{
    /**
     * Get authenticated user info (seller or delivery boy)
     */
    private function getAuthenticatedUser()
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return ['error' => 'Invalid token or unauthorized access.'];
        }

        // Check if user is a seller
        $seller = DB::table('sellers')->where('admin_id', $admin->id)->first();
        if ($seller) {
            return [
                'type' => 'seller',
                'id' => $seller->id,
                'admin_id' => $admin->id,
                'user' => $seller
            ];
        }

        // Check if user is a delivery boy
        $deliveryBoy = DB::table('delivery_boys')->where('admin_id', $admin->id)->first();
        if ($deliveryBoy) {
            return [
                'type' => 'delivery_boy',
                'id' => $deliveryBoy->id,
                'admin_id' => $admin->id,
                'user' => $deliveryBoy
            ];
        }

        return ['error' => 'User is neither a seller nor a delivery boy.'];
    }

    /**
     * Get conversation messages between seller and delivery boy
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getConversation(Request $request)
    {
        try {
            $authUser = $this->getAuthenticatedUser();
            if (isset($authUser['error'])) {
                return CommonHelper::responseError($authUser['error']);
            }

            $validator = Validator::make($request->all(), [
                'delivery_boy_id' => 'required_if:user_type,seller|numeric',
                'seller_id' => 'required_if:user_type,delivery_boy|numeric',
                'order_id' => 'nullable|numeric',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Determine seller_id and delivery_boy_id based on authenticated user
            if ($authUser['type'] === 'seller') {
                $sellerId = $authUser['id'];
                $deliveryBoyId = $request->delivery_boy_id;
            } else {
                $sellerId = $request->seller_id;
                $deliveryBoyId = $authUser['id'];
            }

            $perPage = $request->get('per_page', 20);
            $page = $request->get('page', 1);

            $query = Message::where('conversation_type', 'seller_delivery')
                ->where('seller_id', $sellerId)
                ->where('participant_id', $deliveryBoyId);

            // Filter by order_id if provided
            if ($request->has('order_id') && $request->order_id != '') {
                $query->where('order_id', $request->order_id);
            }

            $query->orderBy('created_at', 'asc');

            $total = $query->count();
            $messages = $query->paginate($perPage, ['*'], 'page', $page);

            // Get participant details
            $seller = Seller::select('id', 'name')->find($sellerId);
            $deliveryBoy = DeliveryBoy::select('id', 'name')->find($deliveryBoyId);

            // Get order details if order_id is provided
            $order = null;
            if ($request->has('order_id') && $request->order_id != '') {
                $order = Order::select('id', 'mobile', 'total', 'final_total', 'address')->find($request->order_id);
            }

            $data = [
                'seller' => $seller,
                'delivery_boy' => $deliveryBoy,
                'order' => $order,
                'messages' => $messages->items(),
                'pagination' => [
                    'current_page' => $messages->currentPage(),
                    'per_page' => $messages->perPage(),
                    'total' => $messages->total(),
                    'last_page' => $messages->lastPage(),
                ]
            ];

            return CommonHelper::responseWithData($data, $total);

        } catch (\Exception $e) {
            Log::error('SellerDeliveryMessagesApiController@getConversation: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to fetch conversation. ' . $e->getMessage());
        }
    }

    /**
     * Get all conversations list for a seller (grouped by delivery boy)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getSellerConversationsList(Request $request)
    {
        try {
            $authUser = $this->getAuthenticatedUser();
            if (isset($authUser['error'])) {
                return CommonHelper::responseError($authUser['error']);
            }

            if ($authUser['type'] !== 'seller') {
                return CommonHelper::responseError('Only sellers can access this endpoint.');
            }

            $sellerId = $authUser['id'];
            $perPage = $request->get('per_page', 15);
            $page = $request->get('page', 1);

            $query = Message::selectRaw('
                    seller_id,
                    participant_id as delivery_boy_id,
                    MAX(id) as last_message_id,
                    MAX(created_at) as last_message_at,
                    SUM(CASE WHEN read_at IS NULL AND sender_type = "delivery_boy" THEN 1 ELSE 0 END) as unread_count
                ')
                ->where('conversation_type', 'seller_delivery')
                ->where('seller_id', $sellerId)
                ->groupBy('seller_id', 'participant_id')
                ->orderBy('last_message_at', 'desc');

            $total = $query->get()->count();
            $conversations = $query->paginate($perPage, ['*'], 'page', $page);

            // Load delivery boy details and last message
            $conversations->getCollection()->transform(function ($conversation) {
                $conversation->delivery_boy = DeliveryBoy::select('id', 'name')->find($conversation->delivery_boy_id);
                $conversation->last_message = Message::select('id', 'message', 'sender_type', 'created_at')->find($conversation->last_message_id);
                return $conversation;
            });

            $data = [
                'conversations' => $conversations->items(),
                'pagination' => [
                    'current_page' => $conversations->currentPage(),
                    'per_page' => $conversations->perPage(),
                    'total' => $conversations->total(),
                    'last_page' => $conversations->lastPage(),
                ]
            ];

            return CommonHelper::responseWithData($data, $total);

        } catch (\Exception $e) {
            Log::error('SellerDeliveryMessagesApiController@getSellerConversationsList: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to fetch conversations list. ' . $e->getMessage());
        }
    }

    /**
     * Get all conversations list for a delivery boy (grouped by seller)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getDeliveryBoyConversationsList(Request $request)
    {
        try {
            $authUser = $this->getAuthenticatedUser();
            if (isset($authUser['error'])) {
                return CommonHelper::responseError($authUser['error']);
            }

            if ($authUser['type'] !== 'delivery_boy') {
                return CommonHelper::responseError('Only delivery boys can access this endpoint.');
            }

            $deliveryBoyId = $authUser['id'];
            $perPage = $request->get('per_page', 15);
            $page = $request->get('page', 1);

            $query = Message::selectRaw('
                    seller_id,
                    participant_id as delivery_boy_id,
                    MAX(id) as last_message_id,
                    MAX(created_at) as last_message_at,
                    SUM(CASE WHEN read_at IS NULL AND sender_type = "seller" THEN 1 ELSE 0 END) as unread_count
                ')
                ->where('conversation_type', 'seller_delivery')
                ->where('participant_id', $deliveryBoyId)
                ->groupBy('seller_id', 'participant_id')
                ->orderBy('last_message_at', 'desc');

            $total = $query->get()->count();
            $conversations = $query->paginate($perPage, ['*'], 'page', $page);

            // Load seller details and last message
            $conversations->getCollection()->transform(function ($conversation) {
                $conversation->seller = Seller::select('id', 'name')->find($conversation->seller_id);
                $conversation->last_message = Message::select('id', 'message', 'sender_type', 'created_at')->find($conversation->last_message_id);
                return $conversation;
            });

            $data = [
                'conversations' => $conversations->items(),
                'pagination' => [
                    'current_page' => $conversations->currentPage(),
                    'per_page' => $conversations->perPage(),
                    'total' => $conversations->total(),
                    'last_page' => $conversations->lastPage(),
                ]
            ];

            return CommonHelper::responseWithData($data, $total);

        } catch (\Exception $e) {
            Log::error('SellerDeliveryMessagesApiController@getDeliveryBoyConversationsList: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to fetch conversations list. ' . $e->getMessage());
        }
    }

    /**
     * Send a message between seller and delivery boy
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function send(Request $request)
    {
        try {
            $authUser = $this->getAuthenticatedUser();
            if (isset($authUser['error'])) {
                return CommonHelper::responseError($authUser['error']);
            }

            $validator = Validator::make($request->all(), [
                'delivery_boy_id' => 'required_if:sender_is,seller|numeric',
                'seller_id' => 'required_if:sender_is,delivery_boy|numeric',
                'order_id' => 'nullable|numeric',
                'message' => 'required|string|max:5000',
                'attachment' => 'nullable|file|mimes:jpeg,jpg,png,gif,pdf,doc,docx|max:5120',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Determine seller_id, delivery_boy_id and sender_type based on authenticated user
            if ($authUser['type'] === 'seller') {
                $sellerId = $authUser['id'];
                $deliveryBoyId = $request->delivery_boy_id;
                $senderType = 'seller';
                $senderId = $sellerId;

                // Validate delivery boy exists
                $deliveryBoy = DeliveryBoy::find($deliveryBoyId);
                if (!$deliveryBoy) {
                    return CommonHelper::responseError('Delivery boy not found.');
                }
            } else {
                $sellerId = $request->seller_id;
                $deliveryBoyId = $authUser['id'];
                $senderType = 'delivery_boy';
                $senderId = $deliveryBoyId;

                // Validate seller exists
                $seller = Seller::find($sellerId);
                if (!$seller) {
                    return CommonHelper::responseError('Seller not found.');
                }
            }

            // Validate order exists if provided
            if ($request->has('order_id') && $request->order_id != '') {
                $order = Order::find($request->order_id);
                if (!$order) {
                    return CommonHelper::responseError('Order not found.');
                }
            }

            // Handle attachment upload
            $attachmentPath = null;
            if ($request->hasFile('attachment')) {
                $attachmentPath = MediaUploadService::uploadMessageAttachment(
                    $request->file('attachment'),
                    'messages'
                );
            }

            // Create message
            $message = new Message();
            $message->conversation_type = 'seller_delivery';
            $message->participant_id = $deliveryBoyId;
            $message->seller_id = $sellerId;
            $message->order_id = $request->order_id ?? null;
            $message->sender_type = $senderType;
            $message->sender_id = $senderId;
            $message->message = $request->message;
            $message->attachment = $attachmentPath;
            $message->save();

            // Load relationships for response
            $message->seller = Seller::select('id', 'name')->find($message->seller_id);
            $message->delivery_boy = DeliveryBoy::select('id', 'name')->find($message->participant_id);
            if ($message->order_id) {
                $message->order = Order::select('id', 'mobile', 'total', 'final_total')->find($message->order_id);
            }

            return CommonHelper::responseSuccessWithData('Message sent successfully!', $message);

        } catch (\Exception $e) {
            Log::error('SellerDeliveryMessagesApiController@send: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to send message. ' . $e->getMessage());
        }
    }

    /**
     * Mark conversation as read
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function markConversationAsRead(Request $request)
    {
        try {
            $authUser = $this->getAuthenticatedUser();
            if (isset($authUser['error'])) {
                return CommonHelper::responseError($authUser['error']);
            }

            $validator = Validator::make($request->all(), [
                'delivery_boy_id' => 'required_if:user_type,seller|numeric',
                'seller_id' => 'required_if:user_type,delivery_boy|numeric',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Determine seller_id, delivery_boy_id and reader_type based on authenticated user
            if ($authUser['type'] === 'seller') {
                $sellerId = $authUser['id'];
                $deliveryBoyId = $request->delivery_boy_id;
                $senderType = 'delivery_boy'; // Mark messages from delivery boy as read
            } else {
                $sellerId = $request->seller_id;
                $deliveryBoyId = $authUser['id'];
                $senderType = 'seller'; // Mark messages from seller as read
            }

            // Mark all unread messages from the other party as read
            Message::where('conversation_type', 'seller_delivery')
                ->where('seller_id', $sellerId)
                ->where('participant_id', $deliveryBoyId)
                ->where('sender_type', $senderType)
                ->whereNull('read_at')
                ->update(['read_at' => now()]);

            return CommonHelper::responseSuccess('Conversation marked as read successfully!');

        } catch (\Exception $e) {
            Log::error('SellerDeliveryMessagesApiController@markConversationAsRead: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to mark conversation as read. ' . $e->getMessage());
        }
    }

    /**
     * Get unread messages count (works for both seller and delivery boy)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getUnreadCount(Request $request)
    {
        try {
            $authUser = $this->getAuthenticatedUser();
            if (isset($authUser['error'])) {
                return CommonHelper::responseError($authUser['error']);
            }

            if ($authUser['type'] === 'seller') {
                $count = Message::where('conversation_type', 'seller_delivery')
                    ->where('seller_id', $authUser['id'])
                    ->where('sender_type', 'delivery_boy')
                    ->whereNull('read_at')
                    ->count();
            } else {
                $count = Message::where('conversation_type', 'seller_delivery')
                    ->where('participant_id', $authUser['id'])
                    ->where('sender_type', 'seller')
                    ->whereNull('read_at')
                    ->count();
            }

            $data = [
                'unread_count' => $count,
                'user_type' => $authUser['type']
            ];

            return CommonHelper::responseWithData($data);

        } catch (\Exception $e) {
            Log::error('SellerDeliveryMessagesApiController@getUnreadCount: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to get unread count. ' . $e->getMessage());
        }
    }

    /**
     * Delete a message
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function delete(Request $request)
    {
        try {
            $authUser = $this->getAuthenticatedUser();
            if (isset($authUser['error'])) {
                return CommonHelper::responseError($authUser['error']);
            }

            $validator = Validator::make($request->all(), [
                'id' => 'required|numeric',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Build query based on user type to ensure they can only delete their own messages
            $query = Message::where('id', $request->id)
                ->where('conversation_type', 'seller_delivery');

            if ($authUser['type'] === 'seller') {
                $query->where('seller_id', $authUser['id']);
            } else {
                $query->where('participant_id', $authUser['id']);
            }

            $message = $query->first();

            if (!$message) {
                return CommonHelper::responseError('Message not found or you do not have permission to delete it.');
            }

            // Delete attachment if exists
            if ($message->attachment) {
                MediaUploadService::deleteFile($message->attachment);
            }

            $message->delete();

            return CommonHelper::responseSuccess('Message deleted successfully!');

        } catch (\Exception $e) {
            Log::error('SellerDeliveryMessagesApiController@delete: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to delete message. ' . $e->getMessage());
        }
    }
}
