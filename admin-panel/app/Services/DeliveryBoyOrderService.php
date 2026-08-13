<?php

namespace App\Services;

use App\Models\Order;
use App\Models\DeliveryBoy;
use App\Models\OrderDeliveryBoyNotification;
use App\Models\PendingDeliveryAssignment;
use App\Jobs\RetryDeliveryBoyAssignmentJob;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class DeliveryBoyOrderService
{
    /**
     * Order active status constants
     */
    const STATUS_RECEIVED = 2;
    const STATUS_PROCESSED = 3;
    const STATUS_SHIPPED = 4;
    const STATUS_OUT_FOR_DELIVERY = 5;
    const STATUS_DELIVERED = 6;
    const STATUS_CANCELLED = 7;
    const STATUS_RETURNED = 8;

    /**
     * Accept an order by delivery boy
     *
     * @param int $orderId The order ID to accept
     * @param int $deliveryBoyId The delivery boy ID accepting the order
     * @return array Result with success status and message
     */
    public static function acceptOrder(int $orderId, int $deliveryBoyId): array
    {
        try {
            DB::beginTransaction();

            // Validate order exists and is available for acceptance
            $validation = self::validateOrderForAcceptance($orderId, $deliveryBoyId);
            if (!$validation['valid']) {
                return [
                    'success' => false,
                    'message' => $validation['message']
                ];
            }

            $order = $validation['order'];

            // 1. Update orders table - assign delivery boy
            $order->delivery_boy_id = $deliveryBoyId;
            // $order->delivery_boy_accepted_at = now();
            $order->save();

            // 2. Mark notification as accepted
            FirestoreDeliveryBoyService::markNotificationAccepted($orderId, $deliveryBoyId);

            // 3. Remove from pending delivery assignments if exists
            FirestoreDeliveryBoyService::removePendingDeliveryAssignment($orderId);

            // 4. Log the acceptance
            Log::info('Order accepted by delivery boy', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoyId,
                'accepted_at' => now()->toDateTimeString()
            ]);

            DB::commit();

            // 5. Withdraw the offer from everyone else.
            // Done after commit so the losing drivers can never be cleared for an
            // acceptance that then rolls back, and so Firestore/queue latency
            // never holds the row lock open.
            self::withdrawOfferFromOtherDeliveryBoys($orderId);

            return [
                'success' => true,
                'message' => 'Order accepted successfully',
                'data' => [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoyId,
                    'accepted_at' => now()->toDateTimeString()
                ]
            ];

        } catch (\Exception $e) {
            DB::rollBack();

            Log::error('Order acceptance failed', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Order acceptance failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Admin assigns a delivery boy to an order (bypasses notification check)
     *
     * Two distinct cases, and they must not be treated the same:
     *
     *  - FRESH ASSIGN (order has no driver): plain assignment, the caller then
     *    writes the full route to the new driver's Firestore document.
     *
     *  - REASSIGN (order already has a different driver): delegated to
     *    emergencyChangeDriver(), which is the only path that clears the old
     *    driver, keeps already-picked stops off the new driver's route, adds the
     *    handoff stop and records the earnings split. Rebuilding the full route
     *    here instead would send the new driver back to restaurants the previous
     *    driver had already collected from - harmless on a single-stop order,
     *    visibly wrong on a multi-stop one.
     *
     * The returned 'firestore_synced' flag tells the caller whether the driver's
     * Firestore document has already been written, so it does not overwrite the
     * handoff route with a full-stops route.
     *
     * @param int $orderId The order ID to assign
     * @param int $deliveryBoyId The delivery boy ID to assign
     * @return array Result with success status and message
     */
    public static function adminAssignOrder(int $orderId, int $deliveryBoyId): array
    {
        try {
            // Check if order exists
            $order = Order::find($orderId);
            if (!$order) {
                return [
                    'success' => false,
                    'message' => 'Order not found'
                ];
            }

            // Check if order is already assigned to this delivery boy
            if ($order->delivery_boy_id == $deliveryBoyId) {
                return [
                    'success' => false,
                    'message' => 'This delivery boy is already assigned to this order'
                ];
            }

            // Check if order is delivered or cancelled
            if ($order->active_status == self::STATUS_DELIVERED) {
                return [
                    'success' => false,
                    'message' => 'Order is already delivered. Cannot reassign delivery boy.'
                ];
            }

            if ($order->active_status == self::STATUS_CANCELLED) {
                return [
                    'success' => false,
                    'message' => 'Order is cancelled. Cannot assign delivery boy.'
                ];
            }

            // Check if delivery boy exists
            $deliveryBoy = DeliveryBoy::find($deliveryBoyId);
            if (!$deliveryBoy) {
                return [
                    'success' => false,
                    'message' => 'Delivery boy not found'
                ];
            }

            $previousDeliveryBoyId = $order->delivery_boy_id ? (int) $order->delivery_boy_id : null;

            // ── Reassignment: hand the order over properly ───────────────────
            if ($previousDeliveryBoyId !== null) {
                return self::reassignOrderToDeliveryBoy(
                    $orderId,
                    $previousDeliveryBoyId,
                    $deliveryBoyId,
                    $deliveryBoy->name
                );
            }

            DB::beginTransaction();

            // 1. Update orders table - assign delivery boy
            $order->delivery_boy_id = $deliveryBoyId;
            $order->driver_accepted_at_time = now();
            $order->save();

            // 2. Mark notification as accepted (if exists)
            FirestoreDeliveryBoyService::markNotificationAccepted($orderId, $deliveryBoyId);

            // 3. Remove from pending delivery assignments if exists
            FirestoreDeliveryBoyService::removePendingDeliveryAssignment($orderId);

            // 4. Log the assignment
            Log::info('Admin assigned delivery boy to order', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoyId,
                'assigned_at' => now()->toDateTimeString(),
                'assigned_by' => 'admin'
            ]);

            DB::commit();

            // 5. Withdraw the offer from every driver still holding the popup
            self::withdrawOfferFromOtherDeliveryBoys($orderId);

            return [
                'success' => true,
                'message' => 'Delivery boy assigned successfully',
                'reassigned' => false,
                // Caller still has to write the route to Firestore.
                'firestore_synced' => false,
                'data' => [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoyId,
                    'delivery_boy_name' => $deliveryBoy->name,
                    'accepted_at' => now()->toDateTimeString()
                ]
            ];

        } catch (\Exception $e) {
            DB::rollBack();

            Log::error('Admin assign delivery boy failed', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to assign delivery boy: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Move an in-flight order from one driver to another.
     *
     * Delegates the hard part to emergencyChangeDriver(), which inside one
     * transaction: records the old driver in previous_drivers_allocated, computes
     * their billable distance so they still get paid for the leg they rode,
     * clears current_order on the old driver (the app watches that field and
     * leaves the delivery screen when it goes null), and writes the new driver a
     * route containing ONLY the stops that are still unpicked, preceded by a
     * handoff stop at the old driver's location so the bags actually change hands.
     *
     * @param int    $orderId
     * @param int    $previousDeliveryBoyId Driver losing the order
     * @param int    $newDeliveryBoyId      Driver gaining the order
     * @param string $newDeliveryBoyName
     * @return array
     */
    protected static function reassignOrderToDeliveryBoy(
        int $orderId,
        int $previousDeliveryBoyId,
        int $newDeliveryBoyId,
        string $newDeliveryBoyName
    ): array {
        Log::info('Admin reassigning order to a different delivery boy', [
            'order_id' => $orderId,
            'previous_delivery_boy_id' => $previousDeliveryBoyId,
            'new_delivery_boy_id' => $newDeliveryBoyId,
        ]);

        $result = FirestoreDeliveryBoyService::emergencyChangeDriver(
            $orderId,
            $previousDeliveryBoyId,
            $newDeliveryBoyId
        );

        if (!$result['success']) {
            Log::error('Admin reassignment failed', [
                'order_id' => $orderId,
                'previous_delivery_boy_id' => $previousDeliveryBoyId,
                'new_delivery_boy_id' => $newDeliveryBoyId,
                'message' => $result['message'] ?? null,
            ]);

            return $result;
        }

        // Stamp the acceptance time so downstream reporting treats the new driver
        // as having taken the order now, not when the original driver did.
        try {
            DB::table('orders')
                ->where('id', $orderId)
                ->update(['driver_accepted_at_time' => now()]);
        } catch (\Exception $e) {
            Log::error('Failed to stamp driver_accepted_at_time on reassignment', [
                'order_id' => $orderId,
                'error' => $e->getMessage()
            ]);
        }

        // A reassigned order must not still be sitting in anyone's offer list.
        self::withdrawOfferFromOtherDeliveryBoys($orderId);

        // Tell the driver who lost the order why it disappeared, so the app's
        // force-exit is explained rather than mysterious.
        try {
            DriverNotificationService::send(
                $previousDeliveryBoyId,
                'Order Reassigned',
                "Order #{$orderId} has been reassigned to another delivery partner by support. "
                    . "You have been paid for the distance you covered. "
                    . "Please take a rest - contact support if you have any questions.",
                '',
                'order',
                null,
                ['order_id' => $orderId, 'reassigned' => true]
            );
        } catch (\Exception $e) {
            Log::error('Failed to notify previous driver about reassignment', [
                'order_id' => $orderId,
                'previous_delivery_boy_id' => $previousDeliveryBoyId,
                'error' => $e->getMessage()
            ]);
        }

        return [
            'success' => true,
            'message' => 'Order reassigned successfully',
            'reassigned' => true,
            // emergencyChangeDriver already wrote both drivers' documents.
            'firestore_synced' => true,
            'data' => [
                'order_id' => $orderId,
                'delivery_boy_id' => $newDeliveryBoyId,
                'delivery_boy_name' => $newDeliveryBoyName,
                'previous_delivery_boy_id' => $previousDeliveryBoyId,
                'accepted_at' => now()->toDateTimeString()
            ]
        ];
    }

    /**
     * Withdraw an order that has just been assigned from every other driver.
     *
     * The driver app drives its incoming-order popup off the Firestore document
     * `delivery_boys/{id}.orders`, so an order left in that map keeps the popup
     * open on the phones that lost the race. This deletes the order key from all
     * notified drivers and kills the retry chain so the order is not re-offered.
     *
     * Never throws: a cleanup failure must not fail an acceptance that already
     * committed.
     *
     * @param int $orderId The order that is no longer on offer
     * @return void
     */
    protected static function withdrawOfferFromOtherDeliveryBoys(int $orderId): void
    {
        // Stop the expanding-radius chain first, otherwise an in-flight retry can
        // re-write the order into drivers' documents right after we clear it.
        try {
            RetryDeliveryBoyAssignmentJob::cancelExistingForOrder($orderId);
        } catch (\Exception $e) {
            Log::error('Failed to cancel retry chain after assignment', [
                'order_id' => $orderId,
                'error' => $e->getMessage()
            ]);
        }

        try {
            $result = FirestoreDeliveryBoyService::clearOrderOfferFromOtherDeliveryBoys($orderId);

            Log::info('Order offer withdrawn from other delivery boys', [
                'order_id' => $orderId,
                'cleared_count' => $result['cleared_count'] ?? 0,
                'failed_count' => $result['failed_count'] ?? 0,
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to withdraw order offer from other delivery boys', [
                'order_id' => $orderId,
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * Validate if order can be accepted by delivery boy
     *
     * @param int $orderId The order ID
     * @param int $deliveryBoyId The delivery boy ID
     * @return array Validation result with 'valid' boolean and 'message'
     */
    public static function validateOrderForAcceptance(int $orderId, int $deliveryBoyId): array
    {
        // Check if order exists
        $order = Order::find($orderId);
        if (!$order) {
            return [
                'valid' => false,
                'message' => 'Order not found'
            ];
        }

        // Check if order is already assigned to another delivery boy
        if ($order->delivery_boy_id && $order->delivery_boy_id != $deliveryBoyId) {
            return [
                'valid' => false,
                'message' => 'Order is already assigned to another delivery boy'
            ];
        }

        // Check if order is already assigned to this delivery boy
        if ($order->delivery_boy_id == $deliveryBoyId) {
            return [
                'valid' => false,
                'message' => 'Order is already assigned to you'
            ];
        }

        // Check if order status allows acceptance (should be in early stages)
        $acceptableStatuses = [self::STATUS_RECEIVED, self::STATUS_PROCESSED];
        if (!in_array($order->active_status, $acceptableStatuses)) {
            return [
                'valid' => false,
                'message' => 'Order cannot be accepted in current status'
            ];
        }

        // Check if delivery boy exists and is available
        $deliveryBoy = DeliveryBoy::find($deliveryBoyId);
        if (!$deliveryBoy) {
            return [
                'valid' => false,
                'message' => 'Delivery boy not found'
            ];
        }

        if (!$deliveryBoy->is_available) {
            return [
                'valid' => false,
                'message' => 'Delivery boy is not available'
            ];
        }

        // Held back by admin — cannot take new orders until moved back to the normal list.
        if ($deliveryBoy->is_problematic) {
            return [
                'valid' => false,
                'message' => 'Your account is on hold. Please contact support.'
            ];
        }

        // Check if this delivery boy was notified for this order
        $wasNotified = self::wasDeliveryBoyNotified($orderId, $deliveryBoyId);
        if (!$wasNotified) {
            return [
                'valid' => false,
                'message' => 'Delivery boy was not notified for this order'
            ];
        }

        return [
            'valid' => true,
            'message' => 'Order can be accepted',
            'order' => $order
        ];
    }

    /**
     * Check if delivery boy was notified for this order
     *
     * @param int $orderId The order ID
     * @param int $deliveryBoyId The delivery boy ID
     * @return bool
     */
    public static function wasDeliveryBoyNotified(int $orderId, int $deliveryBoyId): bool
    {
        $notifications = OrderDeliveryBoyNotification::where('order_id', $orderId)
            ->where('status', OrderDeliveryBoyNotification::STATUS_SENT)
            ->get();

        foreach ($notifications as $notification) {
            $notifiedIds = $notification->delivery_boy_ids ?? [];
            if (in_array($deliveryBoyId, $notifiedIds)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Reject an order by delivery boy
     *
     * @param int $orderId The order ID to reject
     * @param int $deliveryBoyId The delivery boy ID rejecting the order
     * @param string|null $reason Reason for rejection
     * @return array Result with success status and message
     */
    public static function rejectOrder(int $orderId, int $deliveryBoyId, ?string $reason = null): array
    {
        try {
            // Validate order exists
            $order = Order::find($orderId);
            if (!$order) {
                return [
                    'success' => false,
                    'message' => 'Order not found'
                ];
            }

            // Check if delivery boy was notified
            if (!self::wasDeliveryBoyNotified($orderId, $deliveryBoyId)) {
                return [
                    'success' => false,
                    'message' => 'Delivery boy was not notified for this order'
                ];
            }

            // Log the rejection
            Log::info('Order rejected by delivery boy', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoyId,
                'reason' => $reason,
                'rejected_at' => now()->toDateTimeString()
            ]);

            return [
                'success' => true,
                'message' => 'Order rejected successfully',
                'data' => [
                    'order_id' => $orderId,
                    'delivery_boy_id' => $deliveryBoyId,
                    'rejected_at' => now()->toDateTimeString()
                ]
            ];

        } catch (\Exception $e) {
            Log::error('Order rejection failed', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Order rejection failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Get all active orders for a delivery boy
     *
     * @param int $deliveryBoyId The delivery boy ID
     * @return array
     */
    public static function getActiveOrders(int $deliveryBoyId): array
    {
        $completedStatuses = [self::STATUS_DELIVERED, self::STATUS_CANCELLED, self::STATUS_RETURNED];

        $orders = Order::where('delivery_boy_id', $deliveryBoyId)
            ->whereNotIn('active_status', $completedStatuses)
            ->with(['user', 'items'])
            ->orderBy('created_at', 'desc')
            ->get();

        return [
            'success' => true,
            'count' => $orders->count(),
            'orders' => $orders
        ];
    }

    /**
     * Get order history for a delivery boy
     *
     * @param int $deliveryBoyId The delivery boy ID
     * @param int $limit Number of orders to return
     * @return array
     */
    public static function getOrderHistory(int $deliveryBoyId, int $limit = 20): array
    {
        $completedStatuses = [self::STATUS_DELIVERED, self::STATUS_CANCELLED, self::STATUS_RETURNED];

        $orders = Order::where('delivery_boy_id', $deliveryBoyId)
            ->whereIn('active_status', $completedStatuses)
            ->with(['user'])
            ->orderBy('updated_at', 'desc')
            ->limit($limit)
            ->get();

        return [
            'success' => true,
            'count' => $orders->count(),
            'orders' => $orders
        ];
    }

    /**
     * Update order status by delivery boy
     *
     * @param int $orderId The order ID
     * @param int $deliveryBoyId The delivery boy ID
     * @param int $newStatus The new status
     * @return array
     */
    public static function updateOrderStatus(int $orderId, int $deliveryBoyId, int $newStatus): array
    {
        try {
            $order = Order::find($orderId);

            if (!$order) {
                return [
                    'success' => false,
                    'message' => 'Order not found'
                ];
            }

            // Verify this order belongs to the delivery boy
            if ($order->delivery_boy_id != $deliveryBoyId) {
                return [
                    'success' => false,
                    'message' => 'Order is not assigned to you'
                ];
            }

            // Validate status transition
            $validTransition = self::isValidStatusTransition($order->active_status, $newStatus);
            if (!$validTransition) {
                return [
                    'success' => false,
                    'message' => 'Invalid status transition'
                ];
            }

            $oldStatus = $order->active_status;
            $order->active_status = $newStatus;
            $order->save();

            Log::info('Order status updated by delivery boy', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoyId,
                'old_status' => $oldStatus,
                'new_status' => $newStatus
            ]);

            return [
                'success' => true,
                'message' => 'Order status updated successfully',
                'data' => [
                    'order_id' => $orderId,
                    'old_status' => $oldStatus,
                    'new_status' => $newStatus
                ]
            ];

        } catch (\Exception $e) {
            Log::error('Order status update failed', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Status update failed: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Check if status transition is valid for delivery boy
     *
     * @param int $currentStatus Current order status
     * @param int $newStatus New status to transition to
     * @return bool
     */
    public static function isValidStatusTransition(int $currentStatus, int $newStatus): bool
    {
        // Define allowed transitions for delivery boy
        $allowedTransitions = [
            self::STATUS_PROCESSED => [self::STATUS_SHIPPED, self::STATUS_OUT_FOR_DELIVERY],
            self::STATUS_SHIPPED => [self::STATUS_OUT_FOR_DELIVERY],
            self::STATUS_OUT_FOR_DELIVERY => [self::STATUS_DELIVERED],
        ];

        if (!isset($allowedTransitions[$currentStatus])) {
            return false;
        }

        return in_array($newStatus, $allowedTransitions[$currentStatus]);
    }

    /**
     * Mark order as picked up from seller
     *
     * @param int $orderId The order ID
     * @param int $deliveryBoyId The delivery boy ID
     * @param int $sellerId The seller ID from whom the order was picked
     * @return array
     */
    public static function markPickedFromSeller(int $orderId, int $deliveryBoyId, int $sellerId): array
    {
        try {
            $order = Order::find($orderId);

            if (!$order) {
                return [
                    'success' => false,
                    'message' => 'Order not found'
                ];
            }

            if ($order->delivery_boy_id != $deliveryBoyId) {
                return [
                    'success' => false,
                    'message' => 'Order is not assigned to you'
                ];
            }

            // Update order_seller_status_tracking
            DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->where('seller_id', $sellerId)
                ->update([
                    'picked_at' => now(),
                    'picked_by' => $deliveryBoyId
                ]);

            Log::info('Order picked from seller', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoyId,
                'seller_id' => $sellerId,
                'picked_at' => now()->toDateTimeString()
            ]);

            return [
                'success' => true,
                'message' => 'Order marked as picked from seller',
                'data' => [
                    'order_id' => $orderId,
                    'seller_id' => $sellerId,
                    'picked_at' => now()->toDateTimeString()
                ]
            ];

        } catch (\Exception $e) {
            Log::error('Mark picked from seller failed', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoyId,
                'seller_id' => $sellerId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to mark as picked: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Mark order as delivered
     *
     * @param int $orderId The order ID
     * @param int $deliveryBoyId The delivery boy ID
     * @param string|null $deliveryProof OTP or signature proof
     * @return array
     */
    public static function markDelivered(int $orderId, int $deliveryBoyId, ?string $deliveryProof = null): array
    {
        try {
            DB::beginTransaction();

            $order = Order::find($orderId);

            if (!$order) {
                return [
                    'success' => false,
                    'message' => 'Order not found'
                ];
            }

            if ($order->delivery_boy_id != $deliveryBoyId) {
                return [
                    'success' => false,
                    'message' => 'Order is not assigned to you'
                ];
            }

            if ($order->active_status != self::STATUS_OUT_FOR_DELIVERY) {
                return [
                    'success' => false,
                    'message' => 'Order must be out for delivery to mark as delivered'
                ];
            }

            // Update order status
            $order->active_status = self::STATUS_DELIVERED;
            $order->delivered_at = now();
            $order->delivery_proof = $deliveryProof;
            $order->save();

            Log::info('Order marked as delivered', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoyId,
                'delivered_at' => now()->toDateTimeString()
            ]);

            DB::commit();

            return [
                'success' => true,
                'message' => 'Order delivered successfully',
                'data' => [
                    'order_id' => $orderId,
                    'delivered_at' => now()->toDateTimeString()
                ]
            ];

        } catch (\Exception $e) {
            DB::rollBack();

            Log::error('Mark delivered failed', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoyId,
                'error' => $e->getMessage()
            ]);

            return [
                'success' => false,
                'message' => 'Failed to mark as delivered: ' . $e->getMessage()
            ];
        }
    }

    /**
     * Get pending orders available for a delivery boy
     * (Orders that were notified to this delivery boy but not yet accepted)
     *
     * @param int $deliveryBoyId The delivery boy ID
     * @return array
     */
    public static function getPendingOrdersForDeliveryBoy(int $deliveryBoyId): array
    {
        $pendingOrders = [];

        // Get all sent notifications that include this delivery boy
        $notifications = OrderDeliveryBoyNotification::where('status', OrderDeliveryBoyNotification::STATUS_SENT)
            ->get();

        foreach ($notifications as $notification) {
            $notifiedIds = $notification->delivery_boy_ids ?? [];

            if (in_array($deliveryBoyId, $notifiedIds)) {
                // Check if order is still unassigned
                $order = Order::where('id', $notification->order_id)
                    ->whereNull('delivery_boy_id')
                    ->first();

                if ($order) {
                    $pendingOrders[] = [
                        'order_id' => $order->id,
                        'notification_id' => $notification->id,
                        'notified_at' => $notification->notified_at,
                        'order' => $order
                    ];
                }
            }
        }

        return [
            'success' => true,
            'count' => count($pendingOrders),
            'orders' => $pendingOrders
        ];
    }
}
