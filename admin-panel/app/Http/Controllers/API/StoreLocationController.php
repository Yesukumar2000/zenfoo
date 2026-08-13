<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\StoreLocation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class StoreLocationController extends Controller
{
    /**
     * Get all store locations
     *
     * GET /api/store-locations
     * Query Parameters:
     *   - city_id (optional): Filter by city
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        try {
            $query = StoreLocation::with('city');

            // Filter by city if provided
            if ($request->has('city_id') && !empty($request->city_id)) {
                $query->where('city_id', $request->city_id);
            }

            $storeLocations = $query->orderBy('created_at', 'desc')->get();

            $formattedLocations = $storeLocations->map(function ($location) {
                return [
                    'id' => $location->id,
                    'name' => $location->name,
                    'address' => $location->address,
                    'latitude' => $location->latitude,
                    'longitude' => $location->longitude,
                    'phone' => $location->phone,
                    'email' => $location->email,
                    'city_id' => $location->city_id,
                    'city_name' => $location->city ? $location->city->name : '',
                    'status' => $location->status,
                    'delivery_boys_count' => $location->deliveryBoys()->count(),
                    'created_at' => $location->created_at ? $location->created_at->toIso8601String() : null,
                    'updated_at' => $location->updated_at ? $location->updated_at->toIso8601String() : null,
                ];
            });

            return CommonHelper::responseWithData($formattedLocations, $formattedLocations->count());

        } catch (\Exception $e) {
            Log::error('Failed to get store locations', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to retrieve store locations');
        }
    }

    /**
     * Public listing of active store locations for customer app map.
     *
     * GET /customer/store-locations
     * Returns minimal fields needed to plot markers.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function publicList()
    {
        try {
            $storeLocations = StoreLocation::where('status', 1)
                ->whereNotNull('latitude')
                ->whereNotNull('longitude')
                ->get(['id', 'name', 'address', 'latitude', 'longitude', 'city_id']);

            $formatted = $storeLocations->map(function ($location) {
                return [
                    'id' => $location->id,
                    'name' => $location->name,
                    'address' => $location->address,
                    'latitude' => (float) $location->latitude,
                    'longitude' => (float) $location->longitude,
                    'city_id' => $location->city_id,
                ];
            });

            return CommonHelper::responseWithData($formatted, $formatted->count());
        } catch (\Exception $e) {
            Log::error('Failed to get public store locations', [
                'error' => $e->getMessage(),
            ]);
            return CommonHelper::responseError('Failed to retrieve store locations');
        }
    }

    /**
     * Create a new store location
     *
     * POST /api/store-locations/save
     * Body: {
     *   "name": "Zenfoo Store - Madhapur",
     *   "address": "Madhapur, Hyderabad, Telangana",
     *   "latitude": "17.4486",
     *   "longitude": "78.3908",
     *   "phone": "+91 1234567890",
     *   "email": "madhapur@zenfoo.com",
     *   "city_id": 5,
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
                'address' => 'required|string',
                'latitude' => 'required|numeric|between:-90,90',
                'longitude' => 'required|numeric|between:-180,180',
                'phone' => 'nullable|string|max:20',
                'email' => 'nullable|email|max:255',
                'city_id' => 'required|exists:cities,id',
                'status' => 'nullable|in:0,1'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $storeLocation = new StoreLocation();
            $storeLocation->name = $request->name;
            $storeLocation->address = $request->address;
            $storeLocation->latitude = $request->latitude;
            $storeLocation->longitude = $request->longitude;
            $storeLocation->phone = $request->phone;
            $storeLocation->email = $request->email;
            $storeLocation->city_id = $request->city_id;
            $storeLocation->status = $request->has('status') ? $request->status : 1;
            $storeLocation->save();

            // Load city relationship
            $storeLocation->load('city');

            Log::info('Store location created', [
                'store_location_id' => $storeLocation->id,
                'name' => $storeLocation->name
            ]);

            return CommonHelper::responseWithData([
                'store_location' => [
                    'id' => $storeLocation->id,
                    'name' => $storeLocation->name,
                    'address' => $storeLocation->address,
                    'latitude' => $storeLocation->latitude,
                    'longitude' => $storeLocation->longitude,
                    'phone' => $storeLocation->phone,
                    'email' => $storeLocation->email,
                    'city_id' => $storeLocation->city_id,
                    'city_name' => $storeLocation->city ? $storeLocation->city->name : '',
                    'status' => $storeLocation->status,
                ],
                'message' => 'Store location created successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to create store location', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get a single store location for editing
     *
     * GET /api/store-locations/edit/{id}
     *
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function edit($id)
    {
        try {
            $storeLocation = StoreLocation::with('city')->find($id);

            if (!$storeLocation) {
                return CommonHelper::responseError('Store location not found!');
            }

            return CommonHelper::responseWithData([
                'id' => $storeLocation->id,
                'name' => $storeLocation->name,
                'address' => $storeLocation->address,
                'latitude' => $storeLocation->latitude,
                'longitude' => $storeLocation->longitude,
                'phone' => $storeLocation->phone,
                'email' => $storeLocation->email,
                'city_id' => $storeLocation->city_id,
                'city_name' => $storeLocation->city ? $storeLocation->city->name : '',
                'status' => $storeLocation->status,
                'created_at' => $storeLocation->created_at ? $storeLocation->created_at->toIso8601String() : null,
                'updated_at' => $storeLocation->updated_at ? $storeLocation->updated_at->toIso8601String() : null,
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get store location', [
                'id' => $id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to retrieve store location');
        }
    }

    /**
     * Update a store location
     *
     * POST /api/store-locations/update
     * Body: {
     *   "id": 1,
     *   "name": "Zenfoo Store - Madhapur",
     *   "address": "Madhapur, Hyderabad, Telangana",
     *   "latitude": "17.4486",
     *   "longitude": "78.3908",
     *   "phone": "+91 1234567890",
     *   "email": "madhapur@zenfoo.com",
     *   "city_id": 5,
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
                'id' => 'required|exists:store_locations,id',
                'name' => 'required|string|max:255',
                'address' => 'required|string',
                'latitude' => 'required|numeric|between:-90,90',
                'longitude' => 'required|numeric|between:-180,180',
                'phone' => 'nullable|string|max:20',
                'email' => 'nullable|email|max:255',
                'city_id' => 'required|exists:cities,id',
                'status' => 'nullable|in:0,1'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $storeLocation = StoreLocation::find($request->id);

            if (!$storeLocation) {
                return CommonHelper::responseError('Store location not found!');
            }

            $storeLocation->name = $request->name;
            $storeLocation->address = $request->address;
            $storeLocation->latitude = $request->latitude;
            $storeLocation->longitude = $request->longitude;
            $storeLocation->phone = $request->phone;
            $storeLocation->email = $request->email;
            $storeLocation->city_id = $request->city_id;

            if ($request->has('status')) {
                $storeLocation->status = $request->status;
            }

            $storeLocation->save();

            // Load city relationship
            $storeLocation->load('city');

            Log::info('Store location updated', [
                'store_location_id' => $storeLocation->id,
                'name' => $storeLocation->name
            ]);

            return CommonHelper::responseWithData([
                'store_location' => [
                    'id' => $storeLocation->id,
                    'name' => $storeLocation->name,
                    'address' => $storeLocation->address,
                    'latitude' => $storeLocation->latitude,
                    'longitude' => $storeLocation->longitude,
                    'phone' => $storeLocation->phone,
                    'email' => $storeLocation->email,
                    'city_id' => $storeLocation->city_id,
                    'city_name' => $storeLocation->city ? $storeLocation->city->name : '',
                    'status' => $storeLocation->status,
                ],
                'message' => 'Store location updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update store location', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Delete a store location
     *
     * POST /api/store-locations/delete
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
                'id' => 'required|exists:store_locations,id'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $storeLocation = StoreLocation::find($request->id);

            if (!$storeLocation) {
                return CommonHelper::responseError('Store location not found!');
            }

            // Check if any delivery boys are assigned to this store location
            $deliveryBoysCount = $storeLocation->deliveryBoys()->count();
            if ($deliveryBoysCount > 0) {
                return CommonHelper::responseError("Cannot delete store location. {$deliveryBoysCount} delivery boy(s) are currently assigned to this location.");
            }

            $storeLocation->delete();

            Log::info('Store location deleted', [
                'store_location_id' => $request->id
            ]);

            return CommonHelper::responseWithData([
                'message' => 'Store location deleted successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to delete store location', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update store location status
     *
     * POST /api/store-locations/update-status
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
                'id' => 'required|exists:store_locations,id',
                'status' => 'required|in:0,1'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $storeLocation = StoreLocation::find($request->id);

            if (!$storeLocation) {
                return CommonHelper::responseError('Store location not found!');
            }

            $storeLocation->status = $request->status;
            $storeLocation->save();

            Log::info('Store location status updated', [
                'store_location_id' => $storeLocation->id,
                'status' => $storeLocation->status
            ]);

            return CommonHelper::responseWithData([
                'store_location' => [
                    'id' => $storeLocation->id,
                    'name' => $storeLocation->name,
                    'status' => $storeLocation->status,
                ],
                'message' => 'Store location status updated successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update store location status', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError($e->getMessage());
        }
    }
}
