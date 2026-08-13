<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Services\FirestoreChatService;
use App\Models\Notification;
use App\Helpers\CommonHelper;
use Illuminate\Support\Facades\DB;

class OrderChattingController extends Controller
{
    /**
     * Send a chat message between customer and driver for an order
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function send(Request $request)
    {
        $request->validate([
            'order_id' => 'required|integer',
            'customer_id' => 'required|integer',
            'driver_id' => 'required|integer',
            'message' => 'required|string',
            'sender_type' => 'required|in:customer,driver'
        ]);

        $orderId = $request->input('order_id');
        $customerId = $request->input('customer_id');
        $driverId = $request->input('driver_id');
        $message = $request->input('message');
        $senderType = $request->input('sender_type');

        // Determine sender_id based on sender_type
        $senderId = $senderType === 'customer' ? $customerId : $driverId;

        // Initialize chat if not exists, then send message
        FirestoreChatService::initializeChat($orderId, $customerId, $driverId);

        // Send the message
        $result = FirestoreChatService::sendMessage(
            $orderId,
            $senderId,
            $senderType,
            $message
        );

        if ($result['success']) {
            return response()->json([
                'status' => 1,
                'message' => 'Message sent successfully',
                'data' => $result['data']
            ]);
        }

        return response()->json([
            'status' => 0,
            'message' => $result['message']
        ], 500);
    }

    /**
     * Get notifications for seller
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getSellerNotifications(Request $request)
    {
        $limit = ($request->limit) ?? 10;
        $offset = ($request->offset) ?? 0;
        $sort = ($request->sort) ?? 'id';
        $order = ($request->order) ?? 'DESC';
        $where = '';

        if (isset($request->search) && $request->search != '') {
            $search = $request->search;
            $where = " `id` like '%" . $search . "%' OR `title` like '%" . $search . "%' OR `message` like '%" . $search . "%' OR `image` like '%" . $search . "%' OR `date_sent` like '%" . $search . "%' ";
        }

        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return CommonHelper::responseError("Invalid token or unauthorized access.");
        }

        $seller = DB::table('sellers')->where('admin_id', $admin->id)->first();

        if ($seller) {
            $user_id = $seller->id;
            // Get notifications for this specific seller OR broadcast notifications (no user_id)
            $sql = Notification::where(function ($query) use ($user_id) {
                $query->where(function ($q) use ($user_id) {
                    $q->where('user_id', $user_id)
                      ->where('role_name', 'seller');
                })->orWhereNull('user_id');
            });
        } else {
            return CommonHelper::responseError("Seller not found.");
        }

        if ($where != "") {
            $sql = $sql->whereRaw($where);
        }

        $total = $sql->count();
        $notifications = $sql->orderBy($sort, $order)->skip($offset)->take($limit)->get();

        if (!empty($notifications) && $notifications->count() > 0) {
            $rows = array();
            foreach ($notifications as $row) {
                $tempRow = array();
                $tempRow['id'] = $row->id;
                $tempRow['title'] = $row->title;
                $tempRow['message'] = $row->message;
                $tempRow['type'] = $row->type;
                $tempRow['type_id'] = $row->type_id;
                $tempRow['image_url'] = CommonHelper::getImage($row->image);
                $tempRow['link_url'] = $row->type_link;
                $tempRow['date_sent'] = $row->date_sent;
                $rows[] = $tempRow;
            }
            return CommonHelper::responseWithData($rows, $total);
        } else {
            return CommonHelper::responseError(__('no_notification_found'));
        }
    }
}
