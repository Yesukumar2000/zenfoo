<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Services\ProductOrderPolicyService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ProductOrderPolicyController extends Controller
{
    protected ProductOrderPolicyService $policyService;

    public function __construct(ProductOrderPolicyService $policyService)
    {
        $this->policyService = $policyService;
    }

    /**
     * Check return policy for a product.
     *
     * GET /api/product-policy/return?product_id=15&order_id=41
     */
    public function checkReturn(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'product_id' => 'required|integer',
            'order_id'   => 'nullable|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $result = $this->policyService->checkReturnPolicy(
            (int) $request->product_id,
            $request->order_id ? (int) $request->order_id : null
        );

        return response()->json([
            'status'  => 1,
            'message' => 'Return policy fetched successfully.',
            'data'    => $result,
        ]);
    }

    /**
     * Check cancel policy for a product against the current order status.
     *
     * GET /api/product-policy/cancel?product_id=15&order_active_status=2
     */
    public function checkCancel(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'product_id'          => 'required|integer',
            'order_active_status' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $result = $this->policyService->checkCancelPolicy(
            (int) $request->product_id,
            (int) $request->order_active_status
        );

        return response()->json([
            'status'  => 1,
            'message' => 'Cancel policy fetched successfully.',
            'data'    => $result,
        ]);
    }

    /**
     * Check both return and cancel policy together.
     *
     * GET /api/product-policy/check?product_id=15&order_id=41&order_active_status=2
     */
    public function checkBoth(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'product_id'          => 'required|integer',
            'order_id'            => 'nullable|integer',
            'order_active_status' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $returnPolicy = $this->policyService->checkReturnPolicy(
            (int) $request->product_id,
            $request->order_id ? (int) $request->order_id : null
        );

        $cancelPolicy = $this->policyService->checkCancelPolicy(
            (int) $request->product_id,
            (int) $request->order_active_status
        );

        return response()->json([
            'status'  => 1,
            'message' => 'Product order policy fetched successfully.',
            'data'    => [
                'product_id'    => (int) $request->product_id,
                'product_name'  => $returnPolicy['product_name'] ?? $cancelPolicy['product_name'] ?? null,
                'return_policy' => $returnPolicy,
                'cancel_policy' => $cancelPolicy,
            ],
        ]);
    }
}
