<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Message;
use App\Models\User;
use App\Models\Seller;
use App\Models\Admin;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class MessagesApiController extends Controller
{
    /**
     * Get all messages with pagination and filters
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getMessages(Request $request)
    {
        try {
            $perPage = $request->get('per_page', 15);
            $page = $request->get('page', 1);

            $query = Message::query();

            // Filter by conversation type (customer/seller)
            if ($request->has('conversation_type') && $request->conversation_type != '') {
                $query->where('conversation_type', $request->conversation_type);
            }

            // Filter by participant_id
            if ($request->has('participant_id') && $request->participant_id != '') {
                $query->where('participant_id', $request->participant_id);
            }

            // Filter by admin_id
            if ($request->has('admin_id') && $request->admin_id != '') {
                $query->where('admin_id', $request->admin_id);
            }

            // Filter by sender_type
            if ($request->has('sender_type') && $request->sender_type != '') {
                $query->where('sender_type', $request->sender_type);
            }

            // Filter unread messages only
            if ($request->has('unread_only') && $request->unread_only == 'true') {
                $query->whereNull('read_at');
            }

            // Search in message content
            if ($request->has('search') && $request->search != '') {
                $searchTerm = $request->search;
                $query->where('message', 'like', '%' . $searchTerm . '%');
            }

            // Sorting
            $sortBy = $request->get('sort_by', 'created_at');
            $sortDir = $request->get('sort_dir', 'desc');
            $query->orderBy($sortBy, $sortDir);

            // Get total count
            $total = $query->count();

            // Paginate
            $messages = $query->paginate($perPage, ['*'], 'page', $page);

            // Load participant details
            $messages->getCollection()->transform(function ($message) {
                if ($message->conversation_type === 'customer') {
                    $message->participant = User::select('id', 'name', 'email', 'mobile')->find($message->participant_id);
                } else {
                    $message->participant = Seller::select('id', 'name', 'email', 'mobile')->find($message->participant_id);
                }
                $message->admin = Admin::select('id', 'name', 'email')->find($message->admin_id);
                return $message;
            });

            $data = [
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
            Log::error('MessagesApiController@index: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to fetch messages. ' . $e->getMessage());
        }
    }

    /**
     * Get conversation messages between admin and a participant
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getConversation(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'conversation_type' => 'required|in:customer,seller',
                'participant_id' => 'required|numeric',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $perPage = $request->get('per_page', 20);
            $page = $request->get('page', 1);

            $query = Message::where('conversation_type', $request->conversation_type)
                ->where('participant_id', $request->participant_id)
                ->orderBy('created_at', 'asc');

            $total = $query->count();
            $messages = $query->paginate($perPage, ['*'], 'page', $page);

            // Get participant details
            if ($request->conversation_type === 'customer') {
                $participant = User::select('id', 'name', 'email', 'mobile', 'profile_image')->find($request->participant_id);
            } else {
                $participant = Seller::select('id', 'name', 'email', 'mobile', 'logo')->find($request->participant_id);
            }

            $data = [
                'participant' => $participant,
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
            Log::error('MessagesApiController@getConversation: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to fetch conversation. ' . $e->getMessage());
        }
    }

    /**
     * Get all conversations list (grouped by participant)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getConversationsList(Request $request)
    {
        try {
            $conversationType = $request->get('conversation_type', null);
            $perPage = $request->get('per_page', 15);
            $page = $request->get('page', 1);

            $query = Message::selectRaw('
                    conversation_type,
                    participant_id,
                    MAX(id) as last_message_id,
                    MAX(created_at) as last_message_at,
                    SUM(CASE WHEN read_at IS NULL AND sender_type != "admin" THEN 1 ELSE 0 END) as unread_count
                ')
                ->groupBy('conversation_type', 'participant_id')
                ->orderBy('last_message_at', 'desc');

            if ($conversationType) {
                $query->where('conversation_type', $conversationType);
            }

            $total = $query->get()->count();
            $conversations = $query->paginate($perPage, ['*'], 'page', $page);

            // Load participant details and last message
            $conversations->getCollection()->transform(function ($conversation) {
                if ($conversation->conversation_type === 'customer') {
                    $conversation->participant = User::select('id', 'name', 'email', 'mobile', 'profile_image')->find($conversation->participant_id);
                } else {
                    $conversation->participant = Seller::select('id', 'name', 'email', 'mobile', 'logo')->find($conversation->participant_id);
                }
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
            Log::error('MessagesApiController@getConversationsList: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to fetch conversations list. ' . $e->getMessage());
        }
    }

    /**
     * Send a new message
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function send(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'conversation_type' => 'required|in:customer,seller',
                'participant_id' => 'required|numeric',
                'sender_type' => 'required|in:admin,customer,seller',
                'sender_id' => 'required|numeric',
                'message' => 'required|string|max:5000',
                'attachment' => 'nullable|file|mimes:jpeg,jpg,png,gif,pdf,doc,docx|max:5120',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Validate participant exists
            if ($request->conversation_type === 'customer') {
                $participant = User::find($request->participant_id);
                if (!$participant) {
                    return CommonHelper::responseError('Customer not found.');
                }
            } else {
                $participant = Seller::find($request->participant_id);
                if (!$participant) {
                    return CommonHelper::responseError('Seller not found.');
                }
            }

            // Handle attachment upload using MediaUploadService
            $attachmentPath = null;
            if ($request->hasFile('attachment')) {
                $attachmentPath = MediaUploadService::uploadMessageAttachment(
                    $request->file('attachment'),
                    'messages'
                );
            }

            // Create message
            $message = new Message();
            $message->conversation_type = $request->conversation_type;
            $message->participant_id = $request->participant_id;
            $message->admin_id = $request->sender_type === 'admin' ? $request->sender_id : ($request->admin_id ?? null);
            $message->sender_type = $request->sender_type;
            $message->sender_id = $request->sender_id;
            $message->message = $request->message;
            $message->attachment = $attachmentPath;
            $message->save();

            // Load relationships for response
            if ($message->conversation_type === 'customer') {
                $message->participant = User::select('id', 'name', 'email')->find($message->participant_id);
            } else {
                $message->participant = Seller::select('id', 'name', 'email')->find($message->participant_id);
            }

            return CommonHelper::responseSuccessWithData('Message sent successfully!', $message);

        } catch (\Exception $e) {
            Log::error('MessagesApiController@send: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to send message. ' . $e->getMessage());
        }
    }

    /**
     * Get a single message by ID
     *
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function view($id)
    {
        try {
            $message = Message::find($id);

            if (!$message) {
                return CommonHelper::responseError('Message not found.');
            }

            // Load participant details
            if ($message->conversation_type === 'customer') {
                $message->participant = User::select('id', 'name', 'email', 'mobile')->find($message->participant_id);
            } else {
                $message->participant = Seller::select('id', 'name', 'email', 'mobile')->find($message->participant_id);
            }
            $message->admin = Admin::select('id', 'name', 'email')->find($message->admin_id);

            return CommonHelper::responseWithData($message);

        } catch (\Exception $e) {
            Log::error('MessagesApiController@view: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to fetch message. ' . $e->getMessage());
        }
    }

    /**
     * Mark message(s) as read
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function markAsRead(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'id' => 'required_without:ids|numeric',
                'ids' => 'required_without:id|array',
                'ids.*' => 'numeric',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            if ($request->has('id')) {
                // Mark single message as read
                $message = Message::find($request->id);
                if ($message) {
                    $message->markAsRead();
                }
            } else {
                // Mark multiple messages as read
                Message::whereIn('id', $request->ids)
                    ->whereNull('read_at')
                    ->update(['read_at' => now()]);
            }

            return CommonHelper::responseSuccess('Message(s) marked as read successfully!');

        } catch (\Exception $e) {
            Log::error('MessagesApiController@markAsRead: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to mark message(s) as read. ' . $e->getMessage());
        }
    }

    /**
     * Mark all messages in a conversation as read
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function markConversationAsRead(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'conversation_type' => 'required|in:customer,seller',
                'participant_id' => 'required|numeric',
                'reader_type' => 'required|in:admin,customer,seller',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Mark all unread messages from the other party as read
            Message::where('conversation_type', $request->conversation_type)
                ->where('participant_id', $request->participant_id)
                ->where('sender_type', '!=', $request->reader_type)
                ->whereNull('read_at')
                ->update(['read_at' => now()]);

            return CommonHelper::responseSuccess('Conversation marked as read successfully!');

        } catch (\Exception $e) {
            Log::error('MessagesApiController@markConversationAsRead: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to mark conversation as read. ' . $e->getMessage());
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
            $validator = Validator::make($request->all(), [
                'id' => 'required|numeric',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $message = Message::find($request->id);

            if (!$message) {
                return CommonHelper::responseError('Message not found.');
            }

            // Delete attachment if exists using MediaUploadService
            if ($message->attachment) {
                MediaUploadService::deleteFile($message->attachment);
            }

            $message->delete();

            return CommonHelper::responseSuccess('Message deleted successfully!');

        } catch (\Exception $e) {
            Log::error('MessagesApiController@delete: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to delete message. ' . $e->getMessage());
        }
    }

    /**
     * Delete multiple messages
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function deleteMultiple(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'ids' => 'required|array',
                'ids.*' => 'numeric',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $messages = Message::whereIn('id', $request->ids)->get();

            foreach ($messages as $message) {
                // Delete attachment if exists using MediaUploadService
                if ($message->attachment) {
                    MediaUploadService::deleteFile($message->attachment);
                }
                $message->delete();
            }

            return CommonHelper::responseSuccess('Messages deleted successfully!');

        } catch (\Exception $e) {
            Log::error('MessagesApiController@deleteMultiple: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to delete messages. ' . $e->getMessage());
        }
    }

    /**
     * Get unread messages count
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getUnreadCount(Request $request)
    {
        try {
            $query = Message::whereNull('read_at');

            // Filter by conversation type
            if ($request->has('conversation_type') && $request->conversation_type != '') {
                $query->where('conversation_type', $request->conversation_type);
            }

            // Filter by participant_id
            if ($request->has('participant_id') && $request->participant_id != '') {
                $query->where('participant_id', $request->participant_id);
            }

            // Filter by reader type (get messages NOT sent by this type)
            if ($request->has('reader_type') && $request->reader_type != '') {
                $query->where('sender_type', '!=', $request->reader_type);
            }

            $count = $query->count();

            $data = [
                'unread_count' => $count
            ];

            return CommonHelper::responseWithData($data);

        } catch (\Exception $e) {
            Log::error('MessagesApiController@getUnreadCount: ' . $e->getMessage());
            return CommonHelper::responseError('Failed to get unread count. ' . $e->getMessage());
        }
    }
}
