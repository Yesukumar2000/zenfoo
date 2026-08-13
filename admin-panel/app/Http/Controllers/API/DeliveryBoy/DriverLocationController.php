<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyLocationHistory;
use App\Models\Order;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

class DriverLocationController extends Controller
{
    /**
     * Get driver location history for a specific order
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getOrderLocationHistory(Request $request)
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

            // Validate order ID
            if (!$request->has('order_id')) {
                return response()->json([
                    'status' => false,
                    'message' => 'order_id is required'
                ], 422);
            }

            $orderId = $request->get('order_id');

            // Get order
            $order = Order::find($orderId);
            if (!$order) {
                return response()->json([
                    'status' => false,
                    'message' => 'Order not found'
                ], 404);
            }

            // Check if order is delivered
            if (!in_array($order->active_status, [5, 6])) {
                return response()->json([
                    'status' => false,
                    'message' => 'Order is not yet delivered. Tracking available only for delivered orders.'
                ], 422);
            }

            // Get delivery boy
            $deliveryBoy = DeliveryBoy::find($order->delivery_boy_id);
            if (!$deliveryBoy) {
                return response()->json([
                    'status' => false,
                    'message' => 'Delivery boy not found'
                ], 404);
            }

            Log::info('Driver Location: Fetching location history for order', [
                'order_id' => $orderId,
                'delivery_boy_id' => $deliveryBoy->id
            ]);

            // Get delivery address from order
            $deliveryAddress = $this->extractDeliveryAddress($order);

            // Find location history for this order
            // Location history is tracked via sessions, so we need to find locations
            // for the delivery boy during the order delivery period
            $locationHistory = $this->getLocationHistoryForOrder($deliveryBoy, $order);

            // Calculate route statistics
            $stats = $this->calculateLocationStats($locationHistory);

            return response()->json([
                'status' => true,
                'message' => 'Driver location history retrieved successfully',
                'data' => [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'order' => [
                        'id' => $order->id,
                        'order_number' => $order->order_number ?? $order->id,
                        'status' => $order->active_status,
                        'latitude' => $order->latitude ? (float) $order->latitude : null,
                        'longitude' => $order->longitude ? (float) $order->longitude : null,
                        'created_at' => $order->created_at->toIso8601String(),
                        'updated_at' => $order->updated_at->toIso8601String()
                    ],
                    'delivery_boy' => [
                        'id' => $deliveryBoy->id,
                        'name' => $deliveryBoy->name,
                        'phone' => $deliveryBoy->phone,
                        'latitude' => (float) $deliveryBoy->latitude,
                        'longitude' => (float) $deliveryBoy->longitude,
                        'current_location' => [
                            'latitude' => (float) $deliveryBoy->latitude,
                            'longitude' => (float) $deliveryBoy->longitude
                        ]
                    ],
                    'delivery_address' => $deliveryAddress,
                    'location_history' => $locationHistory,
                    'route_statistics' => $stats
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Driver Location: Error fetching location history', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'Error fetching location history: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Extract delivery address from order
     *
     * @param Order $order
     * @return array
     */
    private function extractDeliveryAddress(Order $order)
    {
        return [
            'address' => $order->delivery_address ?? '',
            'latitude' => $order->latitude ? (float) $order->latitude : null,
            'longitude' => $order->longitude ? (float) $order->longitude : null,
            'area' => $order->area ?? '',
            'zip_code' => $order->zip_code ?? ''
        ];
    }

    /**
     * Get location history for the delivery boy during order delivery
     *
     * @param DeliveryBoy $deliveryBoy
     * @param Order $order
     * @return array
     */
    private function getLocationHistoryForOrder(DeliveryBoy $deliveryBoy, Order $order)
    {
        // Get the start time (when order was assigned/picked up)
        // and end time (when order was delivered)
        $startTime = $order->created_at;
        $endTime = $order->updated_at;

        // Get location history for delivery boy during this period
        // Also include a buffer (2 hours before order creation for pickup time)
        $bufferStartTime = $startTime->copy()->subHours(2);

        $locations = DeliveryBoyLocationHistory::where('delivery_boy_id', $deliveryBoy->id)
            ->where('tracked_at', '>=', $bufferStartTime)
            ->where('tracked_at', '<=', $endTime)
            ->orderBy('tracked_at', 'asc')
            ->get();

        // Format location details
        return $locations->map(function ($location) {
            return [
                'latitude' => (float) $location->latitude,
                'longitude' => (float) $location->longitude,
                'distance_from_last_km' => (float) $location->distance_from_last_km,
                'tracked_at' => $location->tracked_at->toDateString(),
                'tracked_time' => $location->tracked_at->format('H:i:s'),
                'timestamp' => $location->tracked_at->toIso8601String()
            ];
        })->values()->toArray();
    }

    /**
     * Calculate route statistics
     *
     * @param array $locationHistory
     * @return array
     */
    private function calculateLocationStats($locationHistory)
    {
        if (empty($locationHistory)) {
            return [
                'total_distance_km' => 0,
                'total_locations_tracked' => 0,
                'tracking_duration_minutes' => 0,
                'average_time_between_points_minutes' => 0
            ];
        }

        // Calculate total distance
        $totalDistance = 0;
        foreach ($locationHistory as $location) {
            $totalDistance += $location['distance_from_last_km'];
        }

        // Calculate tracking duration
        if (count($locationHistory) > 1) {
            $firstTime = Carbon::parse($locationHistory[0]['timestamp']);
            $lastTime = Carbon::parse($locationHistory[count($locationHistory) - 1]['timestamp']);
            $durationMinutes = $firstTime->diffInMinutes($lastTime);
            $avgTimePerPoint = count($locationHistory) > 1
                ? round($durationMinutes / (count($locationHistory) - 1), 2)
                : 0;
        } else {
            $durationMinutes = 0;
            $avgTimePerPoint = 0;
        }

        return [
            'total_distance_km' => round($totalDistance, 2),
            'total_locations_tracked' => count($locationHistory),
            'tracking_duration_minutes' => $durationMinutes,
            'average_time_between_points_minutes' => $avgTimePerPoint
        ];
    }
}
