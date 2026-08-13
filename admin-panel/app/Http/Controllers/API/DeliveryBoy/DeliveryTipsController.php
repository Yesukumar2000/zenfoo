<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Models\Order;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;

class DeliveryTipsController extends Controller
{
    /**
     * Get delivery tips for delivery boy based on week offset
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getWeeklyTips(Request $request)
    {
        try {
            // Get authenticated user
            $user = Auth::user();
            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Get delivery boy by admin_id
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => false,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            $deliveryBoyId = $deliveryBoy->id;

            // Get week offset from request (0 = current week, -1 = previous, 1 = next)
            $offset = (int) $request->get('offset', 0);

            // Parse date if provided, otherwise use today
            $referenceDate = $request->has('date')
                ? Carbon::parse($request->get('date'))
                : Carbon::now();

            // Get week boundaries based on offset
            $weekStart = $referenceDate->copy()->addWeeks($offset)->startOfWeek();
            $weekEnd = $weekStart->copy()->endOfWeek();

            Log::info('Delivery Tips: Fetching tips for week', [
                'delivery_boy_id' => $deliveryBoyId,
                'offset' => $offset,
                'week_start' => $weekStart->toDateString(),
                'week_end' => $weekEnd->toDateString()
            ]);

            // Get all delivered orders in the week with tips
            // active_status: 5 = picked, 6 = cash collected (both are delivered)
            $orders = Order::where('delivery_boy_id', $deliveryBoyId)
                ->whereDate('created_at', '>=', $weekStart->toDateString())
                ->whereDate('created_at', '<=', $weekEnd->toDateString())
                ->whereIn('active_status', [5, 6])
                ->orderBy('created_at', 'desc')
                ->get();

            // Extract tip data from each order
            $tipsData = [];
            $totalTips = 0;
            $totalOrders = 0;
            $daysWithTips = [];

            foreach ($orders as $order) {
                $tip = $this->extractTipFromOrder($order);

                if ($tip > 0) {
                    $totalTips += $tip;
                    $totalOrders++;

                    $orderDate = Carbon::parse($order->created_at)->toDateString();
                    if (!isset($daysWithTips[$orderDate])) {
                        $daysWithTips[$orderDate] = 0;
                    }
                    $daysWithTips[$orderDate] += $tip;

                    $tipsData[] = [
                        'order_id' => $order->id,
                        'tip_amount' => (float) $tip,
                        'order_amount' => (float) ($order->total_amount ?? 0),
                        'delivery_charge' => $this->extractDeliveryCharge($order),
                        'customer_name' => $order->user_name ?? 'N/A',
                        'customer_phone' => $order->user_phone ?? 'N/A',
                        'delivery_address' => $order->delivery_address ?? 'N/A',
                        'order_items_count' => count($this->extractOrderItems($order)),
                        'payment_method' => $order->payment_method ?? 'N/A',
                        'order_status' => $order->status,
                        'order_date' => Carbon::parse($order->created_at)->toDateString(),
                        'order_time' => Carbon::parse($order->created_at)->format('H:i:s'),
                        'delivery_time' => Carbon::parse($order->updated_at)->format('H:i:s'),
                        'restaurant_name' => $order->seller_name ?? 'N/A',
                        'restaurant_address' => $order->seller_address ?? 'N/A',
                        'delivery_distance_km' => (float) ($order->delivery_distance_km ?? 0),
                        'created_at' => $order->created_at->toIso8601String(),
                        'updated_at' => $order->updated_at->toIso8601String(),
                    ];
                }
            }

            // Calculate statistics
            $averageTip = $totalOrders > 0 ? round($totalTips / $totalOrders, 2) : 0;
            $maxTip = count($tipsData) > 0 ? max(array_column($tipsData, 'tip_amount')) : 0;
            $minTip = count($tipsData) > 0 ? min(array_column($tipsData, 'tip_amount')) : 0;

            // Get navigation dates
            $navigation = $this->getWeekNavigation($referenceDate, $offset);

            return response()->json([
                'status' => true,
                'message' => 'Delivery tips retrieved successfully',
                'data' => [
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
                        'total_tips' => (float) round($totalTips, 2),
                        'total_orders_with_tips' => $totalOrders,
                        'average_tip_per_order' => (float) $averageTip,
                        'max_tip' => (float) $maxTip,
                        'min_tip' => (float) $minTip,
                        'total_orders_count' => count($orders),
                        'days_with_tips' => array_map(function ($amount) {
                            return ['total_tips' => (float) round($amount, 2)];
                        }, $daysWithTips)
                    ],
                    'tips_list' => $tipsData,
                    'navigation' => $navigation
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Delivery Tips: Error fetching tips', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'Error fetching delivery tips: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get daily tips breakdown for a specific day
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getDailyTips(Request $request)
    {
        try {
            // Get authenticated user
            $user = Auth::user();
            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Get delivery boy by admin_id
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => false,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            $deliveryBoyId = $deliveryBoy->id;

            // Get date from request
            $date = $request->has('date')
                ? Carbon::parse($request->get('date'))->toDateString()
                : Carbon::today()->toDateString();

            Log::info('Delivery Tips: Fetching daily tips', [
                'delivery_boy_id' => $deliveryBoyId,
                'date' => $date
            ]);

            // Get all delivered orders for the day
            // active_status: 5 = picked, 6 = cash collected (both are delivered)
            $orders = Order::where('delivery_boy_id', $deliveryBoyId)
                ->whereDate('created_at', $date)
                ->whereIn('active_status', [5, 6])
                ->orderBy('created_at', 'desc')
                ->get();

            $tipsData = [];
            $totalTips = 0;
            $hourlyTips = [];

            foreach ($orders as $order) {
                $tip = $this->extractTipFromOrder($order);

                if ($tip > 0) {
                    $totalTips += $tip;

                    $hour = Carbon::parse($order->created_at)->format('H:00');
                    if (!isset($hourlyTips[$hour])) {
                        $hourlyTips[$hour] = 0;
                    }
                    $hourlyTips[$hour] += $tip;

                    $tipsData[] = [
                        'order_id' => $order->id,
                        'tip_amount' => (float) $tip,
                        'order_amount' => (float) ($order->total_amount ?? 0),
                        'delivery_charge' => $this->extractDeliveryCharge($order),
                        'customer_name' => $order->user_name ?? 'N/A',
                        'customer_phone' => $order->user_phone ?? 'N/A',
                        'delivery_address' => $order->delivery_address ?? 'N/A',
                        'order_items_count' => count($this->extractOrderItems($order)),
                        'payment_method' => $order->payment_method ?? 'N/A',
                        'order_time' => Carbon::parse($order->created_at)->format('H:i:s'),
                        'delivery_time' => Carbon::parse($order->updated_at)->format('H:i:s'),
                        'restaurant_name' => $order->seller_name ?? 'N/A',
                        'restaurant_address' => $order->seller_address ?? 'N/A',
                        'delivery_distance_km' => (float) ($order->delivery_distance_km ?? 0),
                        'created_at' => $order->created_at->toIso8601String(),
                        'updated_at' => $order->updated_at->toIso8601String(),
                    ];
                }
            }

            $averageTip = count($tipsData) > 0 ? round($totalTips / count($tipsData), 2) : 0;

            return response()->json([
                'status' => true,
                'message' => 'Daily tips retrieved successfully',
                'data' => [
                    'delivery_boy' => [
                        'id' => $deliveryBoy->id,
                        'name' => $deliveryBoy->name,
                        'phone' => $deliveryBoy->phone,
                        'current_balance' => (float) $deliveryBoy->balance
                    ],
                    'day_summary' => [
                        'date' => $date,
                        'day_of_week' => Carbon::parse($date)->format('l'),
                        'total_tips' => (float) round($totalTips, 2),
                        'total_orders_with_tips' => count($tipsData),
                        'average_tip_per_order' => (float) $averageTip,
                        'total_delivered_orders' => count($orders),
                        'hourly_breakdown' => array_map(function ($hour, $amount) {
                            return [
                                'hour' => $hour,
                                'total_tips' => (float) round($amount, 2)
                            ];
                        }, array_keys($hourlyTips), array_values($hourlyTips))
                    ],
                    'tips_list' => $tipsData
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Delivery Tips: Error fetching daily tips', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'Error fetching daily tips: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get tips for a custom date range
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getRangeTips(Request $request)
    {
        try {
            // Get authenticated user
            $user = Auth::user();
            if (!$user) {
                return response()->json([
                    'status' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Validate date range
            if (!$request->has('from_date') || !$request->has('to_date')) {
                return response()->json([
                    'status' => false,
                    'message' => 'from_date and to_date are required'
                ], 422);
            }

            $fromDate = Carbon::parse($request->get('from_date'))->startOfDay();
            $toDate = Carbon::parse($request->get('to_date'))->endOfDay();

            if ($fromDate->gt($toDate)) {
                return response()->json([
                    'status' => false,
                    'message' => 'from_date must be less than or equal to to_date'
                ], 422);
            }

            // Get delivery boy by admin_id
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => false,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            $deliveryBoyId = $deliveryBoy->id;

            Log::info('Delivery Tips: Fetching range tips', [
                'delivery_boy_id' => $deliveryBoyId,
                'from_date' => $fromDate->toDateString(),
                'to_date' => $toDate->toDateString()
            ]);

            // Get all delivered orders in the range
            // active_status: 5 = picked, 6 = cash collected (both are delivered)
            $orders = Order::where('delivery_boy_id', $deliveryBoyId)
                ->whereBetween('created_at', [$fromDate, $toDate])
                ->whereIn('active_status', [5, 6])
                ->orderBy('created_at', 'desc')
                ->get();

            $tipsData = [];
            $totalTips = 0;
            $dailyTips = [];

            foreach ($orders as $order) {
                $tip = $this->extractTipFromOrder($order);

                if ($tip > 0) {
                    $totalTips += $tip;

                    $orderDate = Carbon::parse($order->created_at)->toDateString();
                    if (!isset($dailyTips[$orderDate])) {
                        $dailyTips[$orderDate] = 0;
                    }
                    $dailyTips[$orderDate] += $tip;

                    $tipsData[] = [
                        'order_id' => $order->id,
                        'tip_amount' => (float) $tip,
                        'order_amount' => (float) ($order->total_amount ?? 0),
                        'delivery_charge' => $this->extractDeliveryCharge($order),
                        'customer_name' => $order->user_name ?? 'N/A',
                        'customer_phone' => $order->user_phone ?? 'N/A',
                        'delivery_address' => $order->delivery_address ?? 'N/A',
                        'order_items_count' => count($this->extractOrderItems($order)),
                        'payment_method' => $order->payment_method ?? 'N/A',
                        'order_date' => Carbon::parse($order->created_at)->toDateString(),
                        'order_time' => Carbon::parse($order->created_at)->format('H:i:s'),
                        'delivery_time' => Carbon::parse($order->updated_at)->format('H:i:s'),
                        'restaurant_name' => $order->seller_name ?? 'N/A',
                        'restaurant_address' => $order->seller_address ?? 'N/A',
                        'delivery_distance_km' => (float) ($order->delivery_distance_km ?? 0),
                        'created_at' => $order->created_at->toIso8601String(),
                        'updated_at' => $order->updated_at->toIso8601String(),
                    ];
                }
            }

            $averageTip = count($tipsData) > 0 ? round($totalTips / count($tipsData), 2) : 0;
            $maxTip = count($tipsData) > 0 ? max(array_column($tipsData, 'tip_amount')) : 0;
            $minTip = count($tipsData) > 0 ? min(array_column($tipsData, 'tip_amount')) : 0;

            return response()->json([
                'status' => true,
                'message' => 'Range tips retrieved successfully',
                'data' => [
                    'delivery_boy' => [
                        'id' => $deliveryBoy->id,
                        'name' => $deliveryBoy->name,
                        'phone' => $deliveryBoy->phone,
                        'current_balance' => (float) $deliveryBoy->balance
                    ],
                    'range_summary' => [
                        'from_date' => $fromDate->toDateString(),
                        'to_date' => $toDate->toDateString(),
                        'date_range' => $fromDate->format('M d') . ' - ' . $toDate->format('M d, Y'),
                        'days_count' => $fromDate->diffInDays($toDate) + 1,
                        'total_tips' => (float) round($totalTips, 2),
                        'total_orders_with_tips' => count($tipsData),
                        'average_tip_per_order' => (float) $averageTip,
                        'max_tip' => (float) $maxTip,
                        'min_tip' => (float) $minTip,
                        'daily_breakdown' => array_map(function ($date, $amount) {
                            return [
                                'date' => $date,
                                'day_of_week' => Carbon::parse($date)->format('l'),
                                'total_tips' => (float) round($amount, 2)
                            ];
                        }, array_keys($dailyTips), array_values($dailyTips))
                    ],
                    'tips_list' => $tipsData
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Delivery Tips: Error fetching range tips', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'Error fetching range tips: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Extract tip from order's cart_metadata
     *
     * @param Order $order
     * @return float
     */
    private function extractTipFromOrder(Order $order): float
    {
        try {
            if (!$order->cart_metadata) {
                return 0;
            }

            $cartMetadata = is_array($order->cart_metadata)
                ? $order->cart_metadata
                : json_decode($order->cart_metadata, true);

            if (!$cartMetadata || !is_array($cartMetadata)) {
                return 0;
            }

            // Try to get tip from cart_info.delivery_tip
            $tip = $cartMetadata['cart_info']['delivery_tip'] ?? null;

            if ($tip !== null) {
                return (float) $tip;
            }

            // Fallback: try to get from top level
            $tip = $cartMetadata['delivery_tip'] ?? 0;

            return (float) $tip;

        } catch (\Exception $e) {
            Log::warning('Delivery Tips: Error extracting tip from order', [
                'order_id' => $order->id,
                'error' => $e->getMessage()
            ]);
            return 0;
        }
    }

    /**
     * Extract delivery charge from order
     *
     * @param Order $order
     * @return float
     */
    private function extractDeliveryCharge(Order $order): float
    {
        try {
            if (!$order->cart_metadata) {
                return 0;
            }

            $cartMetadata = is_array($order->cart_metadata)
                ? $order->cart_metadata
                : json_decode($order->cart_metadata, true);

            if (!$cartMetadata || !is_array($cartMetadata)) {
                return 0;
            }

            // Try to get from cart_info.delivery_charge
            $charge = $cartMetadata['cart_info']['delivery_charge'] ?? null;

            if ($charge !== null) {
                return (float) $charge;
            }

            // Try from billing_breakdown[2] (index 2 is usually delivery charge)
            if (isset($cartMetadata['billing_breakdown']) && is_array($cartMetadata['billing_breakdown'])) {
                if (isset($cartMetadata['billing_breakdown'][2])) {
                    return (float) ($cartMetadata['billing_breakdown'][2]['amount'] ?? 0);
                }
            }

            return 0;

        } catch (\Exception $e) {
            Log::warning('Delivery Tips: Error extracting delivery charge from order', [
                'order_id' => $order->id,
                'error' => $e->getMessage()
            ]);
            return 0;
        }
    }

    /**
     * Extract order items from order
     *
     * @param Order $order
     * @return array
     */
    private function extractOrderItems(Order $order): array
    {
        try {
            if (!$order->cart_metadata) {
                return [];
            }

            $cartMetadata = is_array($order->cart_metadata)
                ? $order->cart_metadata
                : json_decode($order->cart_metadata, true);

            if (!$cartMetadata || !is_array($cartMetadata)) {
                return [];
            }

            // Try to get items from cart_info
            $items = $cartMetadata['cart_info']['items'] ?? [];

            if (!empty($items)) {
                return is_array($items) ? $items : [];
            }

            // Fallback: return empty array
            return [];

        } catch (\Exception $e) {
            Log::warning('Delivery Tips: Error extracting items from order', [
                'order_id' => $order->id,
                'error' => $e->getMessage()
            ]);
            return [];
        }
    }

    /**
     * Get week navigation data
     *
     * @param Carbon $referenceDate
     * @param int $offset
     * @return array
     */
    private function getWeekNavigation(Carbon $referenceDate, int $offset): array
    {
        $currentWeekStart = $referenceDate->copy()->addWeeks($offset)->startOfWeek();
        $previousWeekStart = $currentWeekStart->copy()->subWeeks(1);
        $nextWeekStart = $currentWeekStart->copy()->addWeeks(1);

        return [
            'current' => [
                'week_start' => $currentWeekStart->toDateString(),
                'week_end' => $currentWeekStart->copy()->endOfWeek()->toDateString(),
                'offset' => 0
            ],
            'previous' => [
                'week_start' => $previousWeekStart->toDateString(),
                'week_end' => $previousWeekStart->copy()->endOfWeek()->toDateString(),
                'offset' => -1
            ],
            'next' => [
                'week_start' => $nextWeekStart->toDateString(),
                'week_end' => $nextWeekStart->copy()->endOfWeek()->toDateString(),
                'offset' => 1
            ]
        ];
    }
}
