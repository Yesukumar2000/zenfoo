<?php

namespace App\Http\Controllers\API\Seller;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Seller;
use App\Services\OrderRatingService;

class RatingController extends Controller
{
    /**
     * Get ratings and reviews received by the authenticated seller
     */
    public function getMyRatings(Request $request)
    {
        $admin = auth()->user();

        if (!$admin) {
            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized'
            ], 401);
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return response()->json([
                'status' => 0,
                'message' => 'Seller not found'
            ], 404);
        }

        $page = (int) $request->input('page', 1);
        $perPage = (int) $request->input('per_page', 15);

        $result = OrderRatingService::getSellerRatings($seller->id, $seller->store_id ? (int) $seller->store_id : null, $page, $perPage);

        if (!$result['success']) {
            return response()->json([
                'status' => 0,
                'message' => $result['message']
            ], $result['code']);
        }

        return response()->json([
            'status' => 1,
            'message' => 'Seller ratings retrieved successfully',
            'data' => $result['data']
        ]);
    }

    /**
     * Get order-wise product ratings for the authenticated seller (with pagination)
     */
    public function getProductRatings(Request $request)
    {
        $admin = auth()->user();

        if (!$admin) {
            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized'
            ], 401);
        }

        $seller = Seller::where('admin_id', $admin->id)->first();

        if (!$seller) {
            return response()->json([
                'status' => 0,
                'message' => 'Seller not found'
            ], 404);
        }

        $page = (int) $request->input('page', 1);
        $perPage = (int) $request->input('per_page', 15);

        $result = OrderRatingService::getSellerProductRatings(
            $seller->id,
            $seller->store_id ? (int) $seller->store_id : null,
            $page,
            $perPage
        );

        if (!$result['success']) {
            return response()->json([
                'status' => 0,
                'message' => $result['message']
            ], $result['code']);
        }

        return response()->json([
            'status' => 1,
            'message' => 'Product ratings retrieved successfully',
            'data' => $result['data']
        ]);
    }
}
