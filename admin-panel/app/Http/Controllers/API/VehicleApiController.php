<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Vehicle;
use App\Services\MediaUploadService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class VehicleApiController extends Controller
{
    /**
     * Get all vehicles
     *
     * GET /api/vehicles
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index()
    {
        try {
            $query = Vehicle::query();


            $vehicles = $query->orderBy('created_at', 'desc')->get();

            $formattedVehicles = $vehicles->map(function ($vehicle) {
                return [
                    'id' => $vehicle->id,
                    'name' => $vehicle->name,
                    'image' => $vehicle->image,
                    'image_url' => $vehicle->image_url,
                    'status' => $vehicle->status,
                    'delivery_boys_count' => $vehicle->deliveryBoys()->count(),
                    'created_at' => $vehicle->created_at ? $vehicle->created_at->toIso8601String() : null,
                    'updated_at' => $vehicle->updated_at ? $vehicle->updated_at->toIso8601String() : null,
                ];
            });

            return CommonHelper::responseWithData($formattedVehicles, $formattedVehicles->count());

        } catch (\Exception $e) {
            Log::error('Failed to get vehicles', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to retrieve vehicles');
        }
    }

    /**
     * Create a new vehicle
     *
     * POST /api/vehicles/save
     * Body (multipart/form-data): {
     *   "name": "Bike",
     *   "image": File (image),
     *   "status": 1
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function save(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'image' => 'nullable|image|mimes:jpeg,jpg,png,gif,svg|max:5120',
                'status' => 'nullable|in:0,1'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $vehicle = new Vehicle();
            $vehicle->name = $request->name;
            $vehicle->status = $request->has('status') ? $request->status : 1;

            // Handle image upload using MediaUploadService
            if ($request->hasFile('image')) {
                $vehicle->image = MediaUploadService::upload(
                    $request->file('image'),
                    'vehicles'
                );
            }

            $vehicle->save();

            Log::info('Vehicle created', [
                'vehicle_id' => $vehicle->id,
                'name' => $vehicle->name
            ]);

            return CommonHelper::responseWithData([
                'vehicle' => [
                    'id' => $vehicle->id,
                    'name' => $vehicle->name,
                    'image' => $vehicle->image,
                    'image_url' => $vehicle->image_url,
                    'status' => $vehicle->status,
                ],
                'message' => 'Vehicle created successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to create vehicle', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update a vehicle
     *
     * POST /api/vehicles/update
     * Body (multipart/form-data): {
     *   "id": 1,
     *   "name": "Bike",
     *   "image": File (image),
     *   "status": 1
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'id' => 'required|exists:vehicles,id',
                'name' => 'required|string|max:255',
                'image' => 'nullable|image|mimes:jpeg,jpg,png,gif,svg|max:5120',
                'status' => 'nullable|in:0,1'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $vehicle = Vehicle::find($request->id);

            if (!$vehicle) {
                return CommonHelper::responseError('Vehicle not found!');
            }

            $vehicle->name = $request->name;

            if ($request->has('status')) {
                $vehicle->status = $request->status;
            }

            // Handle image upload using MediaUploadService
            if ($request->hasFile('image')) {
                $vehicle->image = MediaUploadService::upload(
                    $request->file('image'),
                    'vehicles',
                    'public',
                    $vehicle->image // Pass old URL for deletion
                );
            }

            $vehicle->save();

            Log::info('Vehicle updated', [
                'vehicle_id' => $vehicle->id,
                'name' => $vehicle->name
            ]);

            return CommonHelper::responseWithData([
                'vehicle' => [
                    'id' => $vehicle->id,
                    'name' => $vehicle->name,
                    'image' => $vehicle->image,
                    'image_url' => $vehicle->image_url,
                    'status' => $vehicle->status,
                ],
                'message' => 'Vehicle updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update vehicle', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Delete a vehicle
     *
     * POST /api/vehicles/delete
     * Body: {
     *   "id": 1
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function delete(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'id' => 'required|exists:vehicles,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $vehicle = Vehicle::find($request->id);

            if (!$vehicle) {
                return CommonHelper::responseError('Vehicle not found!');
            }

            // Check if any delivery boys are using this vehicle
            $deliveryBoysCount = $vehicle->deliveryBoys()->count();
            if ($deliveryBoysCount > 0) {
                return CommonHelper::responseError("Cannot delete vehicle. {$deliveryBoysCount} delivery boy(s) are currently using this vehicle.");
            }

            // Delete image using MediaUploadService
            if ($vehicle->image) {
                MediaUploadService::deleteByUrl($vehicle->image);
            }

            $vehicle->delete();

            Log::info('Vehicle deleted', [
                'vehicle_id' => $request->id
            ]);

            return CommonHelper::responseWithData([
                'message' => 'Vehicle deleted successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to delete vehicle', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update vehicle status
     *
     * POST /api/vehicles/update-status
     * Body: {
     *   "id": 1,
     *   "status": 1
     * }
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateStatus(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'id' => 'required|exists:vehicles,id',
                'status' => 'required|in:0,1'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $vehicle = Vehicle::find($request->id);

            if (!$vehicle) {
                return CommonHelper::responseError('Vehicle not found!');
            }

            $vehicle->status = $request->status;
            $vehicle->save();

            Log::info('Vehicle status updated', [
                'vehicle_id' => $vehicle->id,
                'status' => $vehicle->status
            ]);

            return CommonHelper::responseWithData([
                'vehicle' => [
                    'id' => $vehicle->id,
                    'name' => $vehicle->name,
                    'status' => $vehicle->status,
                ],
                'message' => 'Vehicle status updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update vehicle status', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }
}
