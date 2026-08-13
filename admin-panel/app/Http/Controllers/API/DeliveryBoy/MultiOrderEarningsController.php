<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyTransaction;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class MultiOrderEarningsController extends Controller
{
    /**
     * Get multi-order earnings by period (daily/weekly/monthly)
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getMultiOrderEarnings(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => false,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            $period = $request->get('period', 'daily'); // daily, weekly, monthly
            $date = $request->get('date');
            $offset = (int) $request->get('offset', 0);

            // Apply offset to date if provided
            if ($offset !== 0) {
                $baseDate = $date ? Carbon::parse($date) : Carbon::today();

                if ($period === 'daily') {
                    $date = $baseDate->addDays($offset)->toDateString();
                } elseif ($period === 'weekly') {
                    $date = $baseDate->addWeeks($offset)->toDateString();
                } elseif ($period === 'monthly') {
                    $date = $baseDate->addMonths($offset)->toDateString();
                }
            }

            $data = match ($period) {
                'daily' => $this->getDailyMultiOrder($deliveryBoy, $date, $offset),
                'weekly' => $this->getWeeklyMultiOrder($deliveryBoy, $date, $offset),
                'monthly' => $this->getMonthlyMultiOrder($deliveryBoy, $date, $offset),
                default => $this->getDailyMultiOrder($deliveryBoy, $date, $offset)
            };

            return response()->json([
                'status' => true,
                'message' => ucfirst($period) . ' multi-order earnings retrieved successfully',
                'data' => $data
            ], 200);

        } catch (\Exception $e) {
            Log::error('Multi-Order Earnings: Error fetching earnings', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'Error fetching multi-order earnings: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get daily multi-order earnings with order details
     *
     * @param DeliveryBoy $deliveryBoy
     * @param string $dateStr
     * @param int $offset
     * @return array
     */
    private function getDailyMultiOrder(DeliveryBoy $deliveryBoy, $dateStr = null, $offset = 0)
    {
        $date = $dateStr ? Carbon::parse($dateStr) : Carbon::today();

        Log::info('Multi-Order Earnings: Fetching daily earnings', [
            'delivery_boy_id' => $deliveryBoy->id,
            'date' => $date->toDateString(),
            'offset' => $offset
        ]);

        // Get all multi-order transactions for the day
        $transactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
            ->where('bonus_amount', '>', 0)
            ->whereDate('transaction_date', $date->toDateString())
            ->orderBy('transaction_date', 'desc')
            ->get();

        $totalEarnings = (float) $transactions->sum('bonus_amount');
        $transactionCount = $transactions->count();
        $averagePerTransaction = $transactionCount > 0 ? round($totalEarnings / $transactionCount, 2) : 0;
        $maxTransaction = $transactions->max('bonus_amount') ?? 0;
        $minTransaction = $transactions->min('bonus_amount') ?? 0;

        // Group by hour
        $hourlyEarnings = [];
        foreach ($transactions as $transaction) {
            $transDate = \is_string($transaction->transaction_date)
                ? Carbon::parse($transaction->transaction_date)
                : $transaction->transaction_date;
            $hour = $transDate->format('H:00');
            if (!isset($hourlyEarnings[$hour])) {
                $hourlyEarnings[$hour] = 0;
            }
            $hourlyEarnings[$hour] += $transaction->bonus_amount;
        }

        // Format transaction details
        $transactionDetails = $transactions->map(function ($transaction) {
            return [
                'transaction_id' => $transaction->id,
                'bonus_amount' => (float) $transaction->bonus_amount,
                'order_id' => $transaction->order_id,
                'message' => $transaction->message,
                'status' => $transaction->status,
                'transaction_date' => $transaction->transaction_date->toDateString(),
                'transaction_time' => $transaction->transaction_date->format('H:i:s'),
                'timestamp' => $transaction->transaction_date->toIso8601String(),
                'created_at' => $transaction->created_at->toIso8601String(),
                'updated_at' => $transaction->updated_at->toIso8601String()
            ];
        })->values();

        // Get navigation
        $navigation = $this->getDateNavigation($date, 'daily');

        return [
            'period_type' => 'daily',
            'delivery_boy' => [
                'id' => $deliveryBoy->id,
                'name' => $deliveryBoy->name,
                'phone' => $deliveryBoy->phone,
                'current_balance' => (float) $deliveryBoy->balance
            ],
            'day_summary' => [
                'date' => $date->toDateString(),
                'day_of_week' => $date->format('l'),
                'total_earnings' => (float) round($totalEarnings, 2),
                'total_transactions' => $transactionCount,
                'average_per_transaction' => (float) $averagePerTransaction,
                'max_transaction' => (float) $maxTransaction,
                'min_transaction' => (float) $minTransaction,
                'hourly_breakdown' => array_map(function ($hour, $amount) {
                    return [
                        'hour' => $hour,
                        'total_earnings' => (float) round($amount, 2)
                    ];
                }, array_keys($hourlyEarnings), array_values($hourlyEarnings))
            ],
            'transactions' => $transactionDetails,
            'navigation' => $navigation
        ];
    }

    /**
     * Get weekly multi-order earnings with daily breakdown
     *
     * @param DeliveryBoy $deliveryBoy
     * @param string $dateStr
     * @param int $offset
     * @return array
     */
    private function getWeeklyMultiOrder(DeliveryBoy $deliveryBoy, $dateStr = null, $offset = 0)
    {
        $referenceDate = $dateStr ? Carbon::parse($dateStr) : Carbon::today();
        $weekStart = $referenceDate->copy()->startOfWeek();
        $weekEnd = $weekStart->copy()->endOfWeek();

        Log::info('Multi-Order Earnings: Fetching weekly earnings', [
            'delivery_boy_id' => $deliveryBoy->id,
            'week_start' => $weekStart->toDateString(),
            'week_end' => $weekEnd->toDateString(),
            'offset' => $offset
        ]);

        // Get all multi-order transactions for the week
        $transactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
            ->where('bonus_amount', '>', 0)
            ->whereDate('transaction_date', '>=', $weekStart->toDateString())
            ->whereDate('transaction_date', '<=', $weekEnd->toDateString())
            ->orderBy('transaction_date', 'desc')
            ->get();

        $totalEarnings = (float) $transactions->sum('bonus_amount');
        $transactionCount = $transactions->count();
        $averagePerTransaction = $transactionCount > 0 ? round($totalEarnings / $transactionCount, 2) : 0;
        $maxTransaction = $transactions->max('bonus_amount') ?? 0;
        $minTransaction = $transactions->min('bonus_amount') ?? 0;

        // Group by day
        $dailyEarnings = [];
        foreach ($transactions as $transaction) {
            $transDate = \is_string($transaction->transaction_date)
                ? Carbon::parse($transaction->transaction_date)
                : $transaction->transaction_date;
            $date = $transDate->toDateString();
            if (!isset($dailyEarnings[$date])) {
                $dailyEarnings[$date] = 0;
            }
            $dailyEarnings[$date] += $transaction->bonus_amount;
        }

        // Format transaction details
        $transactionDetails = $transactions->map(function ($transaction) {
            $transDate = \is_string($transaction->transaction_date)
                ? Carbon::parse($transaction->transaction_date)
                : $transaction->transaction_date;
            return [
                'transaction_id' => $transaction->id,
                'bonus_amount' => (float) $transaction->bonus_amount,
                'order_id' => $transaction->order_id,
                'message' => $transaction->message,
                'status' => $transaction->status,
                'transaction_date' => $transDate->toDateString(),
                'transaction_time' => $transDate->format('H:i:s'),
                'timestamp' => $transDate->toIso8601String(),
                'created_at' => $transaction->created_at->toIso8601String(),
                'updated_at' => $transaction->updated_at->toIso8601String()
            ];
        })->values();

        // Get navigation
        $navigation = $this->getDateNavigation($weekStart, 'weekly');

        return [
            'period_type' => 'weekly',
            'delivery_boy' => [
                'id' => $deliveryBoy->id,
                'name' => $deliveryBoy->name,
                'phone' => $deliveryBoy->phone,
                'current_balance' => (float) $deliveryBoy->balance
            ],
            'week_summary' => [
                'week_start' => $weekStart->toDateString(),
                'week_end' => $weekEnd->toDateString(),
                'week_range' => $weekStart->format('M d') . ' - ' . $weekEnd->format('M d, Y'),
                'total_earnings' => (float) round($totalEarnings, 2),
                'total_transactions' => $transactionCount,
                'average_per_transaction' => (float) $averagePerTransaction,
                'max_transaction' => (float) $maxTransaction,
                'min_transaction' => (float) $minTransaction,
                'daily_breakdown' => array_map(function ($date, $amount) {
                    return [
                        'date' => $date,
                        'day_of_week' => Carbon::parse($date)->format('l'),
                        'total_earnings' => (float) round($amount, 2)
                    ];
                }, array_keys($dailyEarnings), array_values($dailyEarnings))
            ],
            'transactions' => $transactionDetails,
            'navigation' => $navigation
        ];
    }

    /**
     * Get monthly multi-order earnings with daily breakdown
     *
     * @param DeliveryBoy $deliveryBoy
     * @param string $dateStr
     * @param int $offset
     * @return array
     */
    private function getMonthlyMultiOrder(DeliveryBoy $deliveryBoy, $dateStr = null, $offset = 0)
    {
        $referenceDate = $dateStr ? Carbon::parse($dateStr) : Carbon::today();
        $monthStart = $referenceDate->copy()->startOfMonth();
        $monthEnd = $monthStart->copy()->endOfMonth();

        Log::info('Multi-Order Earnings: Fetching monthly earnings', [
            'delivery_boy_id' => $deliveryBoy->id,
            'month' => $monthStart->format('Y-m'),
            'offset' => $offset
        ]);

        // Get all multi-order transactions for the month
        $transactions = DeliveryBoyTransaction::where('delivery_boy_id', $deliveryBoy->id)
            ->where('bonus_amount', '>', 0)
            ->whereDate('transaction_date', '>=', $monthStart->toDateString())
            ->whereDate('transaction_date', '<=', $monthEnd->toDateString())
            ->orderBy('transaction_date', 'desc')
            ->get();

        $totalEarnings = (float) $transactions->sum('bonus_amount');
        $transactionCount = $transactions->count();
        $averagePerTransaction = $transactionCount > 0 ? round($totalEarnings / $transactionCount, 2) : 0;
        $maxTransaction = $transactions->max('bonus_amount') ?? 0;
        $minTransaction = $transactions->min('bonus_amount') ?? 0;

        // Group by day
        $dailyEarnings = [];
        foreach ($transactions as $transaction) {
            $transDate = \is_string($transaction->transaction_date)
                ? Carbon::parse($transaction->transaction_date)
                : $transaction->transaction_date;
            $date = $transDate->toDateString();
            if (!isset($dailyEarnings[$date])) {
                $dailyEarnings[$date] = 0;
            }
            $dailyEarnings[$date] += $transaction->bonus_amount;
        }

        // Format transaction details
        $transactionDetails = $transactions->map(function ($transaction) {
            $transDate = \is_string($transaction->transaction_date)
                ? Carbon::parse($transaction->transaction_date)
                : $transaction->transaction_date;
            return [
                'transaction_id' => $transaction->id,
                'bonus_amount' => (float) $transaction->bonus_amount,
                'order_id' => $transaction->order_id,
                'message' => $transaction->message,
                'status' => $transaction->status,
                'transaction_date' => $transDate->toDateString(),
                'transaction_time' => $transDate->format('H:i:s'),
                'timestamp' => $transDate->toIso8601String(),
                'created_at' => $transaction->created_at->toIso8601String(),
                'updated_at' => $transaction->updated_at->toIso8601String()
            ];
        })->values();

        // Get navigation
        $navigation = $this->getDateNavigation($monthStart, 'monthly');

        return [
            'period_type' => 'monthly',
            'delivery_boy' => [
                'id' => $deliveryBoy->id,
                'name' => $deliveryBoy->name,
                'phone' => $deliveryBoy->phone,
                'current_balance' => (float) $deliveryBoy->balance
            ],
            'month_summary' => [
                'month' => $monthStart->format('Y-m'),
                'month_range' => $monthStart->format('F Y'),
                'total_days' => $monthEnd->day,
                'total_earnings' => (float) round($totalEarnings, 2),
                'total_transactions' => $transactionCount,
                'average_per_transaction' => (float) $averagePerTransaction,
                'max_transaction' => (float) $maxTransaction,
                'min_transaction' => (float) $minTransaction,
                'daily_breakdown' => array_map(function ($date, $amount) {
                    return [
                        'date' => $date,
                        'day_of_week' => Carbon::parse($date)->format('l'),
                        'total_earnings' => (float) round($amount, 2)
                    ];
                }, array_keys($dailyEarnings), array_values($dailyEarnings))
            ],
            'transactions' => $transactionDetails,
            'navigation' => $navigation
        ];
    }

    /**
     * Get date navigation for period
     *
     * @param Carbon $referenceDate
     * @param string $period
     * @return array
     */
    private function getDateNavigation(Carbon $referenceDate, $period)
    {
        if ($period === 'daily') {
            $current = $referenceDate->toDateString();
            $previous = $referenceDate->copy()->subDay()->toDateString();
            $next = $referenceDate->copy()->addDay()->toDateString();
        } elseif ($period === 'weekly') {
            $current = $referenceDate->startOfWeek()->toDateString();
            $previous = $referenceDate->copy()->subWeeks(1)->startOfWeek()->toDateString();
            $next = $referenceDate->copy()->addWeeks(1)->startOfWeek()->toDateString();
        } else { // monthly
            $current = $referenceDate->startOfMonth()->format('Y-m-01');
            $previous = $referenceDate->copy()->subMonths(1)->startOfMonth()->format('Y-m-01');
            $next = $referenceDate->copy()->addMonths(1)->startOfMonth()->format('Y-m-01');
        }

        return [
            'current' => $current,
            'previous' => $previous,
            'next' => $next,
            'period' => $period,
            'offset' => [
                'current' => 0,
                'previous' => -1,
                'next' => 1
            ]
        ];
    }
}
