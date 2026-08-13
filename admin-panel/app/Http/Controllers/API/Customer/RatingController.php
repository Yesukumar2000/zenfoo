<?php

namespace App\Http\Controllers\API\Customer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Services\OrderRatingService;

class RatingController extends Controller
{
    /**
     * Get seller-wise items for a given order (for rating system)
     */
    public function getSellerWiseItems(Request $request)
    {
        $orderId = $request->input('order_id');

        if (empty($orderId)) {
            return response()->json([
                'status' => 0,
                'message' => 'order_id parameter is required'
            ], 400);
        }

        $user = Auth::guard('api-customers')->user();

        $result = OrderRatingService::getSellerWiseItems((int) $orderId, $user->id);

        if (!$result['success']) {
            return response()->json([
                'status' => 0,
                'message' => $result['message']
            ], $result['code']);
        }

        return response()->json([
            'status' => 1,
            'message' => 'Seller wise items retrieved successfully',
            'data' => $result['data']
        ]);
    }

    /**
     * Get order ratings/reviews given by the customer
     */
    public function getOrderRatings(Request $request)
    {
        $orderId = $request->input('order_id');

        if (empty($orderId)) {
            return response()->json([
                'status' => 0,
                'message' => 'order_id parameter is required'
            ], 400);
        }

        $user = Auth::guard('api-customers')->user();

        $result = OrderRatingService::getOrderRatings((int) $orderId, $user->id);

        if (!$result['success']) {
            return response()->json([
                'status' => 0,
                'message' => $result['message']
            ], $result['code']);
        }

        return response()->json([
            'status' => 1,
            'message' => 'Order ratings retrieved successfully',
            'data' => $result['data']
        ]);
    }

    /**
     * Submit rating/review for a product, seller, or driver
     */
    public function submitRating(Request $request)
    {
        $orderId = $request->input('order_id');
        $type = $request->input('type'); // 'product', 'seller', or 'driver'

        if (empty($orderId) || empty($type)) {
            return response()->json([
                'status' => 0,
                'message' => 'order_id and type are required'
            ], 400);
        }

        if (!in_array($type, ['product', 'seller', 'driver'])) {
            return response()->json([
                'status' => 0,
                'message' => 'type must be product, seller or driver'
            ], 400);
        }

        // product: rating required, no review
        if ($type === 'product') {
            if (empty($request->input('product_id')) || empty($request->input('rating'))) {
                return response()->json([
                    'status' => 0,
                    'message' => 'product_id and rating are required for product rating'
                ], 400);
            }
            if ($request->input('rating') < 1 || $request->input('rating') > 5) {
                return response()->json([
                    'status' => 0,
                    'message' => 'rating must be between 1 and 5'
                ], 400);
            }
        }

        // seller: review required, no rating
        if ($type === 'seller') {
            if (empty($request->input('store_id')) || empty($request->input('review'))) {
                return response()->json([
                    'status' => 0,
                    'message' => 'store_id and review are required for seller review'
                ], 400);
            }
        }

        // driver: rating required, review optional
        if ($type === 'driver') {
            if (empty($request->input('rating'))) {
                return response()->json([
                    'status' => 0,
                    'message' => 'rating is required for driver rating'
                ], 400);
            }
            if ($request->input('rating') < 1 || $request->input('rating') > 5) {
                return response()->json([
                    'status' => 0,
                    'message' => 'rating must be between 1 and 5'
                ], 400);
            }
        }

        $user = Auth::guard('api-customers')->user();

        $result = OrderRatingService::submitRating(
            (int) $orderId,
            $user->id,
            $type,
            $request->only(['product_id', 'store_id', 'rating', 'review'])
        );

        if (!$result['success']) {
            return response()->json([
                'status' => 0,
                'message' => $result['message']
            ], $result['code']);
        }

        return response()->json([
            'status' => 1,
            'message' => $result['message']
        ]);
    }
}
