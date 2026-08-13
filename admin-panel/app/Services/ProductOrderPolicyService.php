<?php

namespace App\Services;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProductOrderPolicyService
{
    /**
     * Check whether a product is returnable.
     *
     * @param int      $productId
     * @param int|null $orderId   Pass the order ID to also check if the return window has expired.
     * @return array
     */
    public function checkReturnPolicy(int $productId, ?int $orderId = null): array
    {
        Log::info('ProductOrderPolicyService::checkReturnPolicy', [
            'product_id' => $productId,
            'order_id'   => $orderId,
        ]);

        $product = DB::table('products')
            ->where('id', $productId)
            ->select('id', 'name', 'return_status', 'return_days')
            ->first();

        if (!$product) {
            return [
                'product_id'           => $productId,
                'found'                => false,
                'returnable'           => false,
                'return_days'          => null,
                'return_window_expired' => null,
                'days_since_delivery'  => null,
                'reason'               => 'Product not found.',
            ];
        }

        $returnable = (bool) $product->return_status;

        $result = [
            'product_id'           => $productId,
            'product_name'         => $product->name,
            'found'                => true,
            'returnable'           => $returnable,
            'return_days'          => $returnable ? (int) $product->return_days : null,
            'return_window_expired' => null,
            'days_since_delivery'  => null,
            'reason'               => $returnable ? null : 'Return is not allowed for this product.',
        ];

        if (!$returnable || !$orderId) {
            return $result;
        }

        // Check if the return window has expired using the order's delivered_at_time
        $order = DB::table('orders')
            ->where('id', $orderId)
            ->select('id', 'active_status', 'delivered_at_time')
            ->first();

        if (!$order) {
            $result['reason'] = 'Order not found.';
            return $result;
        }

        if (!$order->delivered_at_time) {
            $result['reason'] = 'Order has not been delivered yet.';
            $result['return_window_expired'] = false;
            return $result;
        }

        $deliveredAt          = Carbon::parse($order->delivered_at_time);
        $daysSinceDelivery    = (int) $deliveredAt->diffInDays(now());
        $windowExpired        = $daysSinceDelivery > (int) $product->return_days;

        $result['days_since_delivery']   = $daysSinceDelivery;
        $result['return_window_expired'] = $windowExpired;
        $result['reason']                = $windowExpired
            ? "Return window of {$product->return_days} day(s) has expired. {$daysSinceDelivery} day(s) since delivery."
            : "Return window is open. {$daysSinceDelivery} day(s) since delivery, window closes in " . ((int) $product->return_days - $daysSinceDelivery) . " day(s).";

        Log::info('ProductOrderPolicyService::checkReturnPolicy result', $result);

        return $result;
    }

    /**
     * Check whether a product is cancellable given the current order status.
     *
     * @param int $productId
     * @param int $orderActiveStatus  The current active_status of the order.
     * @return array
     */
    public function checkCancelPolicy(int $productId, int $orderActiveStatus): array
    {
        Log::info('ProductOrderPolicyService::checkCancelPolicy', [
            'product_id'          => $productId,
            'order_active_status' => $orderActiveStatus,
        ]);

        $product = DB::table('products')
            ->where('id', $productId)
            ->select('id', 'name', 'cancelable_status', 'till_status')
            ->first();

        if (!$product) {
            return [
                'product_id'          => $productId,
                'found'               => false,
                'cancellable'         => false,
                'till_status'         => null,
                'current_order_status' => $orderActiveStatus,
                'can_cancel_now'      => false,
                'reason'              => 'Product not found.',
            ];
        }

        $cancellable = (bool) $product->cancelable_status;

        // Normalise till_status — stored as string, may be "null" or null
        $tillStatusRaw = $product->till_status;
        $tillStatus    = ($tillStatusRaw !== null && $tillStatusRaw !== 'null' && $tillStatusRaw !== '')
            ? (int) $tillStatusRaw
            : null;

        // Fetch status names in one query for human-readable messages
        $statusIds = array_filter([$orderActiveStatus, $tillStatus]);
        $statusNames = DB::table('order_status_lists')
            ->whereIn('id', $statusIds)
            ->pluck('status', 'id');

        $currentStatusName = $statusNames[$orderActiveStatus] ?? "Status {$orderActiveStatus}";
        $tillStatusName    = $tillStatus !== null ? ($statusNames[$tillStatus] ?? "Status {$tillStatus}") : null;

        $canCancelNow = false;
        $reason       = null;

        if (!$cancellable) {
            $reason = 'Cancellation is not allowed for this product.';
        } elseif ($tillStatus === null) {
            // No status restriction — always cancellable
            $canCancelNow = true;
            $reason       = 'Product can be cancelled at any order status.';
        } elseif ($orderActiveStatus <= $tillStatus) {
            $canCancelNow = true;
            $reason       = "Order is at \"{$currentStatusName}\", which is within the cancellable window (allowed till \"{$tillStatusName}\").";
        } else {
            $reason = "Order is at \"{$currentStatusName}\", which is past the cancellable window (allowed till \"{$tillStatusName}\").";
        }

        $result = [
            'product_id'           => $productId,
            'product_name'         => $product->name,
            'found'                => true,
            'cancellable'          => $cancellable,
            'till_status'          => $tillStatus,
            'current_order_status' => $orderActiveStatus,
            'can_cancel_now'       => $canCancelNow,
            'reason'               => $reason,
        ];

        Log::info('ProductOrderPolicyService::checkCancelPolicy result', $result);

        return $result;
    }
}
