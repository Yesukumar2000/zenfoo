<?php

namespace App\Helpers;

use Carbon\Carbon;
use App\Models\Setting;

class PreorderHelper
{
    /**
     * Check if preorder is enabled in settings
     */
    public static function isPreorderEnabled()
    {
        $setting = Setting::where('variable', 'preorder_enabled')->first();
        return $setting && $setting->value == '1';
    }

    /**
     * Check if current time is within preorder window
     * Preorders allowed: Saturday 1:00 AM to configured cutoff day/time
     * Preorders NOT allowed: After cutoff time until Saturday 1:00 AM (order processing time)
     */
    public static function isPreorderTimeWindow()
    {
        $now = Carbon::now('Asia/Kolkata');
        $dayOfWeek = $now->dayOfWeek; // 0=Sunday, 6=Saturday
        $time = $now->format('H:i');

        // Get cutoff settings from database (default: Friday 6:30 AM)
        $cutoffDaySetting = Setting::where('variable', 'preorder_cutoff_day')->first();
        $cutoffTimeSetting = Setting::where('variable', 'preorder_cutoff_time')->first();

        $cutoffDay = $cutoffDaySetting ? intval($cutoffDaySetting->value) : 5; // Default: Friday (5)
        $cutoffTime = $cutoffTimeSetting ? $cutoffTimeSetting->value : '06:30'; // Default: 6:30 AM

        // Cutoff day onwards from cutoff time until midnight - NOT allowed
        if ($dayOfWeek == $cutoffDay && $time >= $cutoffTime) {
            return false;
        }

        // Saturday before 1:00 AM - NOT allowed
        if ($dayOfWeek == Carbon::SATURDAY && $time < '01:00') {
            return false;
        }

        // Days after cutoff day (but not Saturday >= 1:00 AM) - NOT allowed
        if ($dayOfWeek > $cutoffDay && !($dayOfWeek == Carbon::SATURDAY && $time >= '01:00')) {
            return false;
        }

        // All other times - allowed
        return true;
    }

    /**
     * Get next preorder process date (fixed at Friday 6:30 AM)
     * Note: This is separate from cutoff settings - process date is always Friday 6:30 AM
     */
    public static function getNextProcessDate()
    {
        $now = Carbon::now('Asia/Kolkata');

        // Process date is fixed at Friday 6:30 AM (not configurable)
        $processDay = 5; // Friday
        $processTime = '06:30';

        // Parse process time
        list($hour, $minute) = explode(':', $processTime);

        // If it's currently Friday before 6:30 AM, return today at 6:30 AM
        if ($now->dayOfWeek == $processDay && $now->format('H:i') < $processTime) {
            return $now->copy()->setTime(intval($hour), intval($minute), 0);
        }

        // Otherwise, get the next Friday at 6:30 AM
        return $now->copy()->next($processDay)->setTime(intval($hour), intval($minute), 0);
    }

    /**
     * Validate that all cart items are from admin-managed stores
     * Required for preorders
     */
    public static function validatePreorderCart($cartItems, $customComboCarts)
    {
        // Check regular cart items
        if (!$cartItems->isEmpty()) {
            $nonAdminItems = $cartItems->filter(function ($item) {
                return $item->managed_by_admin != 1;
            });

            if ($nonAdminItems->isNotEmpty()) {
                return [
                    'valid' => false,
                    'message' => 'Preorders can only contain items from Zenfoo stores'
                ];
            }
        }

        // Check custom combo items
        if (!$customComboCarts->isEmpty()) {
            foreach ($customComboCarts as $customCart) {
                $customProducts = \DB::table('combo_custom_products')
                    ->where('combo_custom_id', $customCart->id)
                    ->get();

                foreach ($customProducts as $customProduct) {
                    $product = \App\Models\Product::with('store')->find($customProduct->product_id);
                    if ($product && $product->store && $product->store->managed_by_admin != 1) {
                        return [
                            'valid' => false,
                            'message' => 'Preorders can only contain items from Zenfoo stores'
                        ];
                    }
                }
            }
        }

        return ['valid' => true];
    }

    /**
     * Get preorder availability status for customer app
     * Returns 1 if preorder is available, 0 otherwise
     */
    public static function getPreorderStatus()
    {
        // Check if preorder is enabled in settings
        if (!self::isPreorderEnabled()) {
            return [
                'status' => 0,
                'message' => 'Preorder is currently disabled',
                'reason' => 'disabled'
            ];
        }

        // Check if within time window
        if (!self::isPreorderTimeWindow()) {
            // Get cutoff settings for error message
            $cutoffDaySetting = Setting::where('variable', 'preorder_cutoff_day')->first();
            $cutoffTimeSetting = Setting::where('variable', 'preorder_cutoff_time')->first();

            $cutoffDay = $cutoffDaySetting ? intval($cutoffDaySetting->value) : 5;
            $cutoffTime = $cutoffTimeSetting ? $cutoffTimeSetting->value : '06:30';

            $dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
            $dayName = $dayNames[$cutoffDay] ?? 'Friday';

            return [
                'status' => 0,
                'message' => "Preorders can only be placed from Saturday 1:00 AM to {$dayName} {$cutoffTime}",
                'reason' => 'outside_time_window'
            ];
        }

        // Both conditions met
        return [
            'status' => 1,
            'message' => 'Preorder is available',
            'reason' => 'available',
            'next_process_date' => self::getNextProcessDate()->format('Y-m-d H:i:s')
        ];
    }
}