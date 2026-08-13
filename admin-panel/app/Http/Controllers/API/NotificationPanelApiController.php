<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\PanelNotification;
use Illuminate\Http\Request;
use \App\Models\Admin;

class NotificationPanelApiController extends Controller
{
    public function getNotifications(Request $request)
    {
        \Log::info('🔵 NotificationPanel API called');
        \Log::info('🔵 Request params:', $request->all());
        \Log::info('🔵 Auth user ID: ' . (auth()->user()->id ?? 'NOT AUTHENTICATED'));

        $limit = $request->input('per_page');
        $page = $request->input('page', 1);
        $offset = ($page - 1) * $limit;

        // Only get admin notifications for the current user
        $notifications = PanelNotification::where('notifiable_type', Admin::class)
            ->where('notifiable_id', auth()->user()->id)
            ->orderBy('created_at', 'DESC');

        \Log::info('🔵 Query: ' . $notifications->toSql());
        \Log::info('🔵 Query bindings:', $notifications->getBindings());

        $total = $notifications->count();
        \Log::info('🔵 Total notifications found: ' . $total);

        if ($limit) {
            $notifications = $notifications->limit($limit)->offset($offset);
        }

        $notifications = $notifications->get();
        \Log::info('🔵 Notifications retrieved: ' . $notifications->count());
        \Log::info('🔵 Notifications data:', $notifications->toArray());

        return CommonHelper::responseWithData($notifications, $total);
    }

}
