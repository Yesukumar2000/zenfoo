<?php

namespace App\Services;

use App\Models\Store;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class OrderStoreSegregationService
{
    /**
     * Get stores associated with an order from order_seller_status_tracking table
     *
     * @param int $orderId
     * @return array List of store IDs for this order
     */
    public static function getStoresByOrderId(int $orderId): array
    {
        return DB::table('order_seller_status_tracking')
            ->where('order_id', $orderId)
            ->whereNotNull('store_id')
            ->distinct()
            ->pluck('store_id')
            ->toArray();
    }

    /**
     * Get tracking records for an order
     *
     * @param int $orderId
     * @return \Illuminate\Support\Collection
     */
    public static function getTrackingRecordsByOrderId(int $orderId)
    {
        return DB::table('order_seller_status_tracking')
            ->where('order_id', $orderId)
            ->get();
    }

    /**
     * Check if a store is managed by admin
     *
     * @param int $storeId
     * @return bool
     */
    public static function isStoreManagedByAdmin(int $storeId): bool
    {
        $store = Store::find($storeId);

        if (!$store) {
            return false;
        }

        return (bool) $store->managed_by_admin;
    }

    /**
     * Segregate an order based on whether its stores are managed by admin or not
     *
     * @param int $orderId
     * @return array Contains 'admin_managed' and 'non_admin_managed' arrays with store details
     */
    public static function segregateOrderByAdminManagedStores(int $orderId): array
    {
        $result = [
            'admin_managed' => [],
            'non_admin_managed' => [],
            'has_admin_managed_items' => false,
            'has_non_admin_managed_items' => false,
        ];

        // Get all tracking records for this order
        $trackingRecords = self::getTrackingRecordsByOrderId($orderId);

        if ($trackingRecords->isEmpty()) {
            Log::info("OrderStoreSegregationService: No tracking records found for order_id: {$orderId}");
            return $result;
        }

        // Get unique store IDs from tracking records
        $storeIds = $trackingRecords->pluck('store_id')->filter()->unique()->toArray();

        if (empty($storeIds)) {
            Log::info("OrderStoreSegregationService: No store IDs found in tracking records for order_id: {$orderId}");
            return $result;
        }

        // Get store details with managed_by_admin status
        $stores = Store::whereIn('id', $storeIds)->get();

        foreach ($stores as $store) {
            $storeData = [
                'store_id' => $store->id,
                'store_name' => $store->name,
                'managed_by_admin' => $store->managed_by_admin,
            ];

            // Get tracking records for this store
            $storeTrackingRecords = $trackingRecords->where('store_id', $store->id);
            $storeData['tracking_records'] = $storeTrackingRecords->map(function ($record) {
                return [
                    'id' => $record->id,
                    'order_id' => $record->order_id,
                    'seller_id' => $record->seller_id,
                    'store_id' => $record->store_id,
                    'status' => $record->status,
                ];
            })->values()->toArray();

            if ($store->managed_by_admin) {
                $result['admin_managed'][] = $storeData;
                $result['has_admin_managed_items'] = true;
            } else {
                $result['non_admin_managed'][] = $storeData;
                $result['has_non_admin_managed_items'] = true;
            }
        }

        Log::info("OrderStoreSegregationService: Segregated order_id: {$orderId}", [
            'admin_managed_count' => count($result['admin_managed']),
            'non_admin_managed_count' => count($result['non_admin_managed']),
        ]);

        return $result;
    }

    /**
     * Check if an order has any admin-managed store items
     *
     * @param int $orderId
     * @return bool
     */
    public static function orderHasAdminManagedItems(int $orderId): bool
    {
        $storeIds = self::getStoresByOrderId($orderId);

        if (empty($storeIds)) {
            return false;
        }

        return Store::whereIn('id', $storeIds)
            ->where('managed_by_admin', true)
            ->exists();
    }

    /**
     * Check if an order has any non-admin-managed store items
     *
     * @param int $orderId
     * @return bool
     */
    public static function orderHasNonAdminManagedItems(int $orderId): bool
    {
        $storeIds = self::getStoresByOrderId($orderId);

        // dd($storeIds);


        if (empty($storeIds)) {
            return false;
        }

        return Store::whereIn('id', $storeIds)
            ->where('managed_by_admin', false)
            ->exists();
    }

    /**
     * Get a summary of order store segregation
     *
     * @param int $orderId
     * @return array
     */
    public static function getOrderStoreSummary(int $orderId): array
    {
        $segregation = self::segregateOrderByAdminManagedStores($orderId);

        return [
            'order_id' => $orderId,
            'total_stores' => count($segregation['admin_managed']) + count($segregation['non_admin_managed']),
            'admin_managed_stores_count' => count($segregation['admin_managed']),
            'non_admin_managed_stores_count' => count($segregation['non_admin_managed']),
            'has_admin_managed_items' => $segregation['has_admin_managed_items'],
            'has_non_admin_managed_items' => $segregation['has_non_admin_managed_items'],
            'is_mixed_order' => $segregation['has_admin_managed_items'] && $segregation['has_non_admin_managed_items'],
        ];
    }
}