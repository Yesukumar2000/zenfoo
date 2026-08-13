<?php

namespace App\Jobs;

use App\Helpers\CommonHelper;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Seller;
use App\Models\AdminToken;
use App\Models\OrderStatusList;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class SendSellerOrderNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $orderId;

    /**
     * Create a new job instance.
     *
     * @param  int  $orderId
     * @return void
     */
    public function __construct($orderId)
    {
        $this->orderId = $orderId;
    }

    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle()
    {
        try {
            $order = Order::with('items')->find($this->orderId);

            if (!$order) {
                Log::error("SendSellerOrderNotification: Order not found", ['order_id' => $this->orderId]);
                return;
            }

            // Get order status
            $orderStatusList = OrderStatusList::where('id', $order->active_status)->first();
            $status_name = $orderStatusList ? $orderStatusList->status : 'received';

            // Determine notification type and title
            if ($order->active_status == OrderStatusList::$received) {
                $type = 'new_order';
                $titleTemplate = "You have %s new order #%d";
            } else {
                $type = '';
                $titleTemplate = "Order #%d has been %s";
            }

            $sellerIds = [];

            // For pre-orders, check order_seller_status_tracking table first
            if ($order->is_preorder == 1) {
                $trackingSellers = DB::table('order_seller_status_tracking')
                    ->where('order_id', $this->orderId)
                    ->whereNotNull('seller_id')
                    ->where('seller_id', '!=', 0)
                    ->distinct()
                    ->pluck('seller_id')
                    ->toArray();

                if (!empty($trackingSellers)) {
                    $sellerIds = $trackingSellers;
                    Log::info("SendSellerOrderNotification: Found sellers from tracking table", [
                        'order_id' => $this->orderId,
                        'seller_ids' => $sellerIds
                    ]);
                }
            }

            // If no sellers found from tracking (or not a preorder), get from order items
            if (empty($sellerIds)) {
                $sellerIds = $order->items()
                    ->whereNotNull('seller_id')
                    ->where('seller_id', '!=', 0)
                    ->distinct()
                    ->pluck('seller_id')
                    ->toArray();

                Log::info("SendSellerOrderNotification: Found sellers from order items", [
                    'order_id' => $this->orderId,
                    'seller_ids' => $sellerIds
                ]);
            }

            if (empty($sellerIds)) {
                Log::info("SendSellerOrderNotification: No sellers to notify for order", ['order_id' => $this->orderId]);
                return;
            }

            // Send notification to each seller
            foreach ($sellerIds as $sellerId) {
                $this->sendNotificationToSeller($sellerId, $order->id, $status_name, $type, $titleTemplate);
            }

            Log::info("SendSellerOrderNotification: Notifications sent successfully", [
                'order_id' => $this->orderId,
                'sellers_notified' => count($sellerIds)
            ]);

        } catch (\Exception $e) {
            Log::error("SendSellerOrderNotification: Failed to send notifications", [
                'order_id' => $this->orderId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            throw $e;
        }
    }

    /**
     * Send notification to a specific seller
     *
     * @param int $sellerId
     * @param int $orderId
     * @param string $statusName
     * @param string $type
     * @param string $titleTemplate
     * @return void
     */
    protected function sendNotificationToSeller($sellerId, $orderId, $statusName, $type, $titleTemplate)
    {
        try {
            // Get seller details
            $seller = Seller::select("sellers.*", "admins.email", "admins.role_id")
                ->join('admins', 'sellers.admin_id', 'admins.id')
                ->where('sellers.id', $sellerId)
                ->first();

            if (!$seller) {
                Log::warning("SendSellerOrderNotification: Seller not found", ['seller_id' => $sellerId]);
                return;
            }

            // Get seller's FCM tokens
            $sellerTokens = AdminToken::where('user_id', $sellerId)
                ->where('type', 'Seller')
                ->get()
                ->pluck('fcm_token', 'platform')
                ->toArray();

            if (empty($sellerTokens)) {
                Log::info("SendSellerOrderNotification: No FCM tokens found for seller", [
                    'seller_id' => $sellerId,
                    'order_id' => $orderId
                ]);
                return;
            }

            // Prepare notification content
            $title = sprintf($titleTemplate, $statusName, $orderId);
            $message = $this->buildNotificationMessage($seller, $orderId, $statusName);

            // Send notification
            CommonHelper::sendNotification($sellerTokens, $title, $message, $type);

            Log::info("SendSellerOrderNotification: Notification sent to seller", [
                'seller_id' => $sellerId,
                'order_id' => $orderId,
                'tokens_count' => count($sellerTokens),
                'title' => $title
            ]);

        } catch (\Exception $e) {
            Log::error("SendSellerOrderNotification: Failed to notify seller", [
                'seller_id' => $sellerId,
                'order_id' => $orderId,
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * Build notification message for seller
     *
     * @param Seller $seller
     * @param int $orderId
     * @param string $statusName
     * @return string
     */
    protected function buildNotificationMessage($seller, $orderId, $statusName)
    {
        $order = Order::find($orderId);

        if (!$order) {
            return "Order #{$orderId} has been {$statusName}.";
        }

        // For pre-orders, send simple notification
        if ($order->is_preorder == 1) {
            if ($statusName == 'received' || $statusName == 'Received') {
                return "You have a new preorder #{$orderId}. Please check the app for details.";
            }
            return "Preorder #{$orderId} status updated to {$statusName}.";
        }

        // For regular orders, calculate item count only
        $sellerItems = OrderItem::where('order_id', $orderId)
            ->where('seller_id', $seller->id)
            ->get();

        $itemCount = $sellerItems->count();

        if ($statusName == 'received' || $statusName == 'Received') {
            return "New order with {$itemCount} item(s).";
        }

        return "Order #{$orderId} status updated to {$statusName}.";
    }

    /**
     * The job failed to process.
     *
     * @param  \Exception  $exception
     * @return void
     */
    public function failed(\Exception $exception)
    {
        Log::error("SendSellerOrderNotification: Job failed permanently", [
            'order_id' => $this->orderId,
            'error' => $exception->getMessage(),
            'trace' => $exception->getTraceAsString()
        ]);
    }
}
