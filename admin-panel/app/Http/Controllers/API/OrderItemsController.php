<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Services\OrderItemsService;
use Illuminate\Http\Request;

class OrderItemsController extends Controller
{
    /**
     * GET /api/order-items?order_id=343
     *
     * Returns all items (normal + combo) for the given order,
     * each tagged with is_combo_item for easy differentiation.
     */
    public function index(Request $request)
    {
        $request->validate(['order_id' => 'required|integer']);

        $service = new OrderItemsService();
        $data    = $service->getOrderItems((int) $request->order_id);

        return response()->json([
            'status'  => 1,
            'message' => 'Order items fetched successfully.',
            'data'    => $data,
        ]);
    }
}
