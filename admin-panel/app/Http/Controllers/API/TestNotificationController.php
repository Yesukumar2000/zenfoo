<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\AdminToken;
use App\Models\Admin;
use App\Models\Setting;
use App\Helpers\FCMHelper;
use App\Services\AdminNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class TestNotificationController extends Controller
{
    /**
     * Test notification using AdminNotificationService
     * This saves to panel_notifications AND sends push notification
     */
    public function testAdminNotification(Request $request)
    {
        try {
            $adminId = $request->admin_id ?? null;
            $title = $request->title ?? 'Test Notification';
            $body = $request->body ?? 'This is a test notification from Zenfoo Admin Panel';
            $type = $request->type ?? 'general';

            // Use AdminNotificationService which saves to panel_notifications AND sends push
            $result = AdminNotificationService::send(
                $adminId, // null = all admins, or specific admin ID
                $title,
                $body,
                $type,
                ['click_action' => url('/dashboard')]
            );

            return response()->json($result);

        } catch (\Exception $e) {
            Log::error('Test notification exception: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage()
            ]);
        }
    }

    /**
     * Test new order notification (simulates new order)
     */
    public function testNewOrderNotification(Request $request)
    {
        try {
            $orderId = $request->order_id ?? 999;
            $orderNumber = $request->order_number ?? '#' . $orderId;

            $result = AdminNotificationService::notifyNewOrder($orderId, $orderNumber);

            return response()->json($result);

        } catch (\Exception $e) {
            Log::error('Test order notification exception: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage()
            ]);
        }
    }

    public function listAdminTokens(Request $request)
    {
        $adminId = $request->admin_id ?? null;

        $query = AdminToken::query();

        if ($adminId) {
            $query->where('user_id', $adminId);
        }

        $tokens = $query->get();

        return response()->json([
            'success' => true,
            'count' => $tokens->count(),
            'tokens' => $tokens->map(function($token) {
                return [
                    'id' => $token->id,
                    'user_id' => $token->user_id,
                    'type' => $token->type,
                    'fcm_token' => substr($token->fcm_token, 0, 30) . '...',
                    'created_at' => $token->created_at
                ];
            })
        ]);
    }
}
