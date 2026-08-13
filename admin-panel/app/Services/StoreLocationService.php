<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

class StoreLocationService
{
    /**
     * Get the store location ID for a Zenfoo store based on order's city
     *
     * @param int $orderId
     * @return int|null Returns the store_location_id or null if not found
     */
    public static function getStoreLocationIdByOrderId(int $orderId): ?int
    {
        // Get order with city_id from user_addresses
        $order = DB::table('orders')
            ->leftJoin('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
            ->where('orders.id', $orderId)
            ->select('orders.*', 'user_addresses.city_id')
            ->first();

        if (!$order || !$order->city_id) {
            return null;
        }

        // Get Zenfoo store details from store_locations table based on order's city
        $storeLocation = DB::table('store_locations')
            ->where('city_id', $order->city_id)
            ->where('status', 1)
            ->first();

        if (!$storeLocation) {
            return null;
        }

        return (int) $storeLocation->id;
    }

    /**
     * Get the full store location details for a Zenfoo store based on order's city
     *
     * @param int $orderId
     * @return object|null Returns the store_location record or null if not found
     */
    public static function getStoreLocationByOrderId(int $orderId): ?object
    {
        // Get order with city_id from user_addresses
        $order = DB::table('orders')
            ->leftJoin('user_addresses', 'orders.address_id', '=', 'user_addresses.id')
            ->where('orders.id', $orderId)
            ->select('orders.*', 'user_addresses.city_id')
            ->first();

        if (!$order || !$order->city_id) {
            return null;
        }

        // Get Zenfoo store details from store_locations table based on order's city
        return DB::table('store_locations')
            ->where('city_id', $order->city_id)
            ->where('status', 1)
            ->first();
    }
}
