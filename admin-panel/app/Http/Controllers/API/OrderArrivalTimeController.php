<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Services\OrderArrivalTimeService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

/**
 * Controller for Order Arrival Time calculations
 *
 * Handles API requests for estimating order arrival times.
 * Designed for scalability with input validation and proper error handling.
 */
class OrderArrivalTimeController extends Controller
{
    /**
     * Get order tracking data by order ID
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function getTrackingByOrderId(Request $request): JsonResponse
    {
        try {
            // Validate input
            $validator = Validator::make($request->all(), [
                'order_id' => 'required|integer|min:1'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $orderId = (int) $request->input('order_id');

            // Call service method
            $result = OrderArrivalTimeService::getTrackingByOrderId($orderId);

            if ($result['success']) {
                return response()->json([
                    'status' => 1,
                    'message' => $result['message'],
                    'data' => $result['data']
                ], 200);
            }

            return response()->json([
                'status' => 0,
                'message' => $result['message'],
                'data' => null
            ], 404);

        } catch (\Exception $e) {
            Log::error('OrderArrivalTimeController: Exception in getTrackingByOrderId', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'An error occurred while fetching tracking data',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Calculate arrival time data for an order
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function calculateArrivalTime(Request $request): JsonResponse
    {
        try {
            // Validate input
            $validator = Validator::make($request->all(), [
                'order_id' => 'required|integer|min:1'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 0,
                    'message' => 'Validation failed',
                    'errors' => $validator->errors()
                ], 422);
            }

            $orderId = (int) $request->input('order_id');

            // Call service method
            $result = OrderArrivalTimeService::calculateArrivalTime($orderId);

            if ($result['success']) {
                return response()->json([
                    'status' => 1,
                    'message' => $result['message'],
                    'data' => $result['data']
                ], 200);
            }

            return response()->json([
                'status' => 0,
                'message' => $result['message'],
                'data' => null
            ], 404);

        } catch (\Exception $e) {
            Log::error('OrderArrivalTimeController: Exception in calculateArrivalTime', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'An error occurred while calculating arrival time',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
