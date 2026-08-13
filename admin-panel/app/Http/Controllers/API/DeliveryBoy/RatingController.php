<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\DeliveryBoy;
use App\Services\OrderRatingService;

class RatingController extends Controller
{
    /**
     * Get ratings and reviews received by the authenticated delivery boy
     */
    
    public function getMyRatings(Request $request)
    {
        $admin = auth()->guard('api')->user();

        if (!$admin) {
            return response()->json([
                'status' => 0,
                'message' => 'Unauthorized'
            ], 401);
        }

        $deliveryBoy = DeliveryBoy::where('admin_id', $admin->id)->first();

        if (!$deliveryBoy) {
            return response()->json([
                'status' => 0,
                'message' => 'Delivery boy not found'
            ], 404);
        }

        $page = (int) $request->input('page', 1);
        $perPage = (int) $request->input('per_page', 15);

        $result = OrderRatingService::getDriverRatings($deliveryBoy->id, $page, $perPage);

        if (!$result['success']) {
            return response()->json([
                'status' => 0,
                'message' => $result['message']
            ], $result['code']);
        }

        return response()->json([
            'status' => 1,
            'message' => 'Driver ratings retrieved successfully',
            'data' => $result['data']
        ]);
    }
}
