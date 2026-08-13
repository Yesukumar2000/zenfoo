<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use App\Services\DriverNotificationService;

class HandCashLimitService
{
    /**
     * Get the max hand cash limit for a specific delivery boy.
     * Uses the driver's individual limit from delivery_boys table.
     * Defaults to 1000 if driver not found or limit is null.
     *
     * @param int $deliveryBoyId
     * @return float
     */
    public static function getMaxHandCashLimit(int $deliveryBoyId): float
    {
        $limit = DB::table('delivery_boys')
            ->where('id', $deliveryBoyId)
            ->value('hand_cash_limit');

        return floatval($limit ?? 1000);
    }

    /**
     * Get unsettled hand cash total for a delivery boy.
     * Sums admin_cash from delivery_boy_transactions where is_hand_cash = 1 and settled_with_admin = 0.
     *
     * @param int $deliveryBoyId
     * @return float
     */
    public static function getUnsettledHandCash(int $deliveryBoyId): float
    {
        return (float) DB::table('delivery_boy_transactions')
            ->where('delivery_boy_id', $deliveryBoyId)
            ->where('is_hand_cash', 1)
            ->where('settled_with_admin', 0)
            ->sum('admin_cash');
    }

    /**
     * Check if a delivery boy has exceeded the max hand cash limit.
     *
     * @param int $deliveryBoyId
     * @param float|null $maxLimit Optional override for the limit
     * @return bool True if exceeded (driver should be excluded)
     */
    public static function hasExceededHandCashLimit(int $deliveryBoyId, ?float $maxLimit = null): bool
    {
        $limit = $maxLimit ?? self::getMaxHandCashLimit($deliveryBoyId);
        $unsettled = self::getUnsettledHandCash($deliveryBoyId);

        return $unsettled > $limit;
    }

    /**
     * Filter out delivery boys who have exceeded the hand cash limit.
     * Returns only drivers whose unsettled hand cash is within their individual limit.
     *
     * @param array $drivers Array of drivers with 'id' key
     * @return array Filtered array of drivers within hand cash limit
     */
    public static function filterByHandCashLimit(array $drivers): array
    {
        if (empty($drivers)) {
            return [];
        }

        $driverIds = array_column($drivers, 'id');

        // Batch query: get unsettled hand cash totals for all driver IDs at once
        $unsettledTotals = DB::table('delivery_boy_transactions')
            ->whereIn('delivery_boy_id', $driverIds)
            ->where('is_hand_cash', 1)
            ->where('settled_with_admin', 0)
            ->groupBy('delivery_boy_id')
            ->select('delivery_boy_id', DB::raw('SUM(admin_cash) as total_unsettled'))
            ->pluck('total_unsettled', 'delivery_boy_id');

        // Batch query: get hand cash limits for all drivers at once
        $driverLimits = DB::table('delivery_boys')
            ->whereIn('id', $driverIds)
            ->pluck('hand_cash_limit', 'id');

        $filtered = [];
        $excluded = [];

        foreach ($drivers as $driver) {
            $driverId = $driver['id'];
            $unsettled = (float) ($unsettledTotals[$driverId] ?? 0);
            $maxLimit = (float) ($driverLimits[$driverId] ?? 1000);

            if ($unsettled > $maxLimit) {
                $excluded[] = [
                    'id' => $driverId,
                    'unsettled' => $unsettled,
                    'limit' => $maxLimit
                ];
            } else {
                $filtered[] = $driver;
            }
        }

        if (!empty($excluded)) {
            // Log and notify each excluded driver
            foreach ($excluded as $excludedDriver) {
                $driverId = $excludedDriver['id'];
                $unsettled = $excludedDriver['unsettled'];
                $maxLimit = $excludedDriver['limit'];

                Log::info('Driver excluded due to hand cash limit', [
                    'delivery_boy_id' => $driverId,
                    'unsettled_amount_to_pay_zenfoo' => $unsettled,
                    'max_limit' => $maxLimit,
                ]);

                try {
                    DriverNotificationService::send(
                        $driverId,
                        'Orders Paused - Hand Cash Limit Exceeded',
                        "You're missing orders! Your unsettled hand cash is ₹" . number_format($unsettled, 2) . " which exceeds your limit of ₹" . number_format($maxLimit, 2) . ". Please settle with Zenfoo to start receiving orders again.",
                        '',
                        'hand_cash_limit'
                    );
                } catch (\Exception $e) {
                    Log::error('Failed to send hand cash limit notification', [
                        'delivery_boy_id' => $driverId,
                        'error' => $e->getMessage(),
                    ]);
                }
            }
        }

        return $filtered;
    }
}