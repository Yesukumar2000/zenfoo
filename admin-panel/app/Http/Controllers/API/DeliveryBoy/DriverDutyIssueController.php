<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\DeliveryBoy;
use App\Models\DriverDutyIssue;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class DriverDutyIssueController extends Controller
{
    /**
     * Get authenticated delivery boy from token
     *
     * @return array ['success' => bool, 'delivery_boy' => DeliveryBoy|null, 'error' => string|null]
     */
    private function getAuthenticatedDeliveryBoy()
    {
        $driver_data_admin = auth()->guard('api')->user();

        if (!$driver_data_admin) {
            return [
                'success' => false,
                'delivery_boy' => null,
                'error' => 'Unauthorized. Please login again.'
            ];
        }

        $deliveryBoy = DeliveryBoy::where('admin_id', $driver_data_admin->id)->first();

        if (!$deliveryBoy) {
            return [
                'success' => false,
                'delivery_boy' => null,
                'error' => 'Delivery boy not found'
            ];
        }

        return [
            'success' => true,
            'delivery_boy' => $deliveryBoy,
            'error' => null
        ];
    }

    /**
     * Store a new driver duty issue
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request)
    {
        try {
            // Get authenticated delivery boy
            $authResult = $this->getAuthenticatedDeliveryBoy();

            if (!$authResult['success']) {
                return CommonHelper::responseError($authResult['error']);
            }

            $deliveryBoy = $authResult['delivery_boy'];

            // Validate request
            $validator = Validator::make($request->all(), [
                'type' => 'required|in:not_getting_orders,change_zone',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Create driver duty issue
            $driverDutyIssue = DriverDutyIssue::create([
                'type' => $request->type,
                'delivery_boy_id' => $deliveryBoy->id,
                'date_of_issue' => now(),
                'admin_response' => null,
            ]);

            return CommonHelper::responseSuccessWithData('Issue reported successfully.', $driverDutyIssue);

        } catch (Exception $e) {
            Log::error("Driver Duty Issue Store Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to report issue. Please try again.');
        }
    }

    /**
     * Update delivery boy's city
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateCity(Request $request)
    {
        try {
            // Get authenticated delivery boy
            $authResult = $this->getAuthenticatedDeliveryBoy();

            if (!$authResult['success']) {
                return CommonHelper::responseError($authResult['error']);
            }

            $deliveryBoy = $authResult['delivery_boy'];

            // Validate request
            $validator = Validator::make($request->all(), [
                'city_id' => 'required|exists:cities,id',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            // Update delivery boy's city
            $deliveryBoy->city_id = $request->city_id;
            $deliveryBoy->save();

            return CommonHelper::responseSuccess('City updated successfully.');

        } catch (Exception $e) {
            Log::error("Update Delivery Boy City Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to update city. Please try again.');
        }
    }
}