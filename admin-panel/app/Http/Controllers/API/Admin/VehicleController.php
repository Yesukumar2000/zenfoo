<?php

namespace App\Http\Controllers\API\Admin;

use App\Http\Controllers\Controller;
use App\Models\Vehicle;
use App\Services\MediaUploadService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class VehicleController extends Controller
{
    /**
     * Get all vehicles with optional filters.
     *
     * @param Request $request The HTTP request with optional filters:
     *                         - search: Search by vehicle name
     *
     * @return JsonResponse JSON response with vehicles list
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $query = Vehicle::query();

            if ($request->filled('search')) {
                $search = $request->input('search');
                $query->where('name', 'like', "%{$search}%");
            }

            $vehicles = $query->withCount('deliveryBoys')
                ->orderBy('created_at', 'desc')
                ->get();

            $formattedVehicles = $vehicles->map(function ($vehicle) {
                return [
                    'id' => $vehicle->id,
                    'name' => $vehicle->name,
                    'image_url' => $vehicle->image,
                    'delivery_boys_count' => $vehicle->delivery_boys_count,
                    'created_at' => $vehicle->created_at?->toIso8601String(),
                    'updated_at' => $vehicle->updated_at?->toIso8601String(),
                ];
            });

            return response()->json([
                'status' => true,
                'message' => 'Vehicles retrieved successfully',
                'data' => [
                    'vehicles' => $formattedVehicles,
                    'total' => $formattedVehicles->count()
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error fetching vehicles: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'An error occurred while fetching vehicles'
            ], 500);
        }
    }

    /**
     * Get a single vehicle by ID.
     *
     * @param int $id Vehicle ID
     *
     * @return JsonResponse JSON response with vehicle data
     */
    public function show(int $id): JsonResponse
    {
        try {
            $vehicle = Vehicle::withCount('deliveryBoys')->find($id);

            if ($vehicle === null) {
                return response()->json([
                    'status' => false,
                    'message' => 'Vehicle not found'
                ], 404);
            }

            return response()->json([
                'status' => true,
                'message' => 'Vehicle retrieved successfully',
                'data' => [
                    'vehicle' => [
                        'id' => $vehicle->id,
                        'name' => $vehicle->name,
                        'image_url' => $vehicle->image,
                        'delivery_boys_count' => $vehicle->delivery_boys_count,
                        'created_at' => $vehicle->created_at?->toIso8601String(),
                        'updated_at' => $vehicle->updated_at?->toIso8601String(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error fetching vehicle: ' . $e->getMessage(), [
                'vehicle_id' => $id,
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'An error occurred while fetching vehicle'
            ], 500);
        }
    }

    /**
     * Create a new vehicle.
     *
     * @param Request $request The HTTP request with vehicle data:
     *                         - name: Required, vehicle name
     *                         - image: Optional, vehicle image file
     *
     * @return JsonResponse JSON response with created vehicle
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255|unique:vehicles,name',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $vehicleData = [
                'name' => $request->input('name'),
            ];

            if ($request->hasFile('image')) {
                $uploadResult = MediaUploadService::uploadWithFullUrl(
                    $request->file('image'),
                    'vehicles'
                );
                $vehicleData['image'] = $uploadResult;
            }

            $vehicle = Vehicle::create($vehicleData);

            return response()->json([
                'status' => true,
                'message' => 'Vehicle created successfully',
                'data' => [
                    'vehicle' => [
                        'id' => $vehicle->id,
                        'name' => $vehicle->name,
                        'image_url' => $vehicle->image,
                        'created_at' => $vehicle->created_at?->toIso8601String(),
                    ]
                ]
            ], 201);

        } catch (\Exception $e) {
            Log::error('Error creating vehicle: ' . $e->getMessage(), [
                'request_data' => $request->except('image'),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'An error occurred while creating vehicle'
            ], 500);
        }
    }

    /**
     * Update an existing vehicle.
     *
     * @param Request $request The HTTP request with vehicle data:
     *                         - vehicle_id: Required, ID of vehicle to update
     *                         - name: Optional, vehicle name
     *                         - image: Optional, vehicle image file
     *
     * @return JsonResponse JSON response with updated vehicle
     */
    public function update(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'vehicle_id' => 'required|integer|exists:vehicles,id',
            'name' => 'sometimes|required|string|max:255|unique:vehicles,name,' . $request->input('vehicle_id'),
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $vehicle = Vehicle::find($request->input('vehicle_id'));

            $updateData = [];

            if ($request->filled('name')) {
                $updateData['name'] = $request->input('name');
            }

            if ($request->hasFile('image')) {
                $oldImagePath = $vehicle->image ? MediaUploadService::getPathFromUrl($vehicle->image) : null;
                $uploadResult = MediaUploadService::uploadWithFullUrl(
                    $request->file('image'),
                    'vehicles',
                    'public',
                    $oldImagePath
                );
                $updateData['image'] = $uploadResult;
            }

            if (!empty($updateData)) {
                $vehicle->update($updateData);
            }

            $vehicle->refresh();

            return response()->json([
                'status' => true,
                'message' => 'Vehicle updated successfully',
                'data' => [
                    'vehicle' => [
                        'id' => $vehicle->id,
                        'name' => $vehicle->name,
                        'image_url' => $vehicle->image,
                        'updated_at' => $vehicle->updated_at?->toIso8601String(),
                    ]
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error updating vehicle: ' . $e->getMessage(), [
                'vehicle_id' => $request->input('vehicle_id'),
                'request_data' => $request->except('image'),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'An error occurred while updating vehicle'
            ], 500);
        }
    }

    /**
     * Soft delete a vehicle.
     *
     * @param Request $request The HTTP request with:
     *                         - vehicle_id: Required, ID of vehicle to delete
     *
     * @return JsonResponse JSON response confirming deletion
     */
    public function destroy(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'vehicle_id' => 'required|integer|exists:vehicles,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        try {
            $vehicle = Vehicle::withCount('deliveryBoys')->find($request->input('vehicle_id'));

            if ($vehicle->delivery_boys_count > 0) {
                return response()->json([
                    'status' => false,
                    'message' => "Cannot delete vehicle. It is assigned to {$vehicle->delivery_boys_count} delivery boy(s). Please reassign them first."
                ], 400);
            }

            $vehicle->delete();

            return response()->json([
                'status' => true,
                'message' => 'Vehicle deleted successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Error deleting vehicle: ' . $e->getMessage(), [
                'vehicle_id' => $request->input('vehicle_id'),
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'An error occurred while deleting vehicle'
            ], 500);
        }
    }

    /**
     * Get all vehicles for dropdown/select.
     *
     * @return JsonResponse JSON response with vehicles list
     */
    public function getActiveVehicles(): JsonResponse
    {
        try {
            $vehicles = Vehicle::orderBy('name', 'asc')
                ->get(['id', 'name', 'image']);

            $formattedVehicles = $vehicles->map(function ($vehicle) {
                return [
                    'id' => $vehicle->id,
                    'name' => $vehicle->name,
                    'image_url' => $vehicle->image,
                ];
            });

            return response()->json([
                'status' => true,
                'message' => 'Vehicles retrieved successfully',
                'data' => [
                    'vehicles' => $formattedVehicles
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Error fetching vehicles: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString()
            ]);

            return response()->json([
                'status' => false,
                'message' => 'An error occurred while fetching vehicles'
            ], 500);
        }
    }
}
