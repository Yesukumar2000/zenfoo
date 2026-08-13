<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Models\City;
use App\Models\DeliveryBoy;
use App\Models\DeliveryBoyDocument;
use App\Models\DeliveryBoyIncentiveProgress;
use App\Models\IncentiveOffer;
use App\Models\Order;
use App\Models\Role;
use App\Models\Setting;
use App\Services\MediaUploadService;
use App\Services\OrderRatingService;
use App\Services\PhonePePayoutService;
use App\Services\DriverNotificationService;
use App\Models\DriverIssueZenfoo;
use App\Services\AdminNotificationService;
use Carbon\Carbon;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\ValidationException;

class DeliveryBoysApiController extends Controller
{
    /**
     * Get list of delivery boys with optional filters
     */
    public function getDeliveryBoy(Request $request)
    {
        try {
            $deliveryBoy = DeliveryBoy::with(['admin', 'city', 'vehicle', 'storeLocations', 'documents']);

            if (isset($request->filterStatus) && $request->filterStatus != "") {
                $deliveryBoy = $deliveryBoy->where("status", $request->filterStatus);
            }

            // Filter by zone using delivery_boys.city_id column
            if ($request->filled('city_id')) {
                $allCityIds = City::pluck('id');

                if ($request->city_id === 'other') {
                    // "Other" = no city_id set, city_id = 0, or city_id not matching any known city
                    $deliveryBoy = $deliveryBoy->where(function ($q) use ($allCityIds) {
                        $q->whereNull('city_id')
                          ->orWhere('city_id', 0)
                          ->orWhere('city_id', '')
                          ->orWhereNotIn('city_id', $allCityIds);
                    });
                } else {
                    $deliveryBoy = $deliveryBoy->where('city_id', $request->city_id);
                }
            }

            $deliveryBoys = $deliveryBoy->orderBy('id', 'DESC')->get();

            return CommonHelper::responseWithData($deliveryBoys);
        } catch (Exception $e) {
            Log::error("Get Delivery Boys Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch delivery boys.");
        }
    }

    /**
     * Save a new delivery boy
     */
    public function save(Request $request)
    {
        // Validation
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'nullable|email|max:255',
            'mobile' => 'nullable|string|max:20',
            'dob' => 'nullable|date|before:today',
            'address' => 'required|string',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'city_id' => 'required|exists:cities,id',
            'vehicle_id' => 'nullable|exists:vehicles,id',
            'store_location_ids' => 'nullable|array',
            'store_location_ids.*' => 'exists:store_locations,id',
            'profile_image' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',

            // Driving License
            'driving_license_number' => 'nullable|string|max:50',
            'driving_license_front' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',
            'driving_license_back' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',

            // RC (Registration Certificate)
            'rc_number' => 'nullable|string|max:50',
            'rc_front' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',
            'rc_back' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',

            // Aadhar
            'aadhar_number' => 'nullable|string|max:12',
            'aadhar_front' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',
            'aadhar_back' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',

            // PAN
            'pan_number' => 'nullable|string|max:10',
            'pan_front' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',
            'pan_back' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',

            // Bank Details
            'bank_name' => 'nullable|string|max:100',
            'account_holder_name' => 'nullable|string|max:100',
            'account_number' => 'nullable|string|max:50',
            'ifsc_code' => 'nullable|string|max:11',
            'bank_passbook_image' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',
        ], [
            'city_id.required' => 'The city field is required.',
            'city_id.exists' => 'The selected city is invalid.',
            'vehicle_id.exists' => 'The selected vehicle is invalid.',
            'latitude.between' => 'Latitude must be between -90 and 90.',
            'longitude.between' => 'Longitude must be between -180 and 180.',
            'profile_image.max' => 'Profile image must not exceed 5MB.',
            'driving_license_front.max' => 'Driving license front image must not exceed 5MB.',
            'driving_license_back.max' => 'Driving license back image must not exceed 5MB.',
            'aadhar_front.max' => 'Aadhar front image must not exceed 5MB.',
            'aadhar_back.max' => 'Aadhar back image must not exceed 5MB.',
            'pan_front.max' => 'PAN front image must not exceed 5MB.',
            'pan_back.max' => 'PAN back image must not exceed 5MB.',
            'bank_passbook_image.max' => 'Bank passbook image must not exceed 5MB.',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        DB::beginTransaction();

        try {
            // Create admin user
            $admin = new Admin();
            $admin->username = $request->name;
            $admin->email = $request->email ?? '';
            $admin->password = bcrypt("TempPass" . rand(100000, 999999));
            $admin->role_id = Role::$roleDeliveryBoy;
            $admin->created_by = 0;
            $admin->save();

            // Create delivery boy
            $deliveryBoy = new DeliveryBoy();
            $deliveryBoy->admin_id = $admin->id;
            $deliveryBoy->name = $request->name;
            $deliveryBoy->email = $request->email;
            $deliveryBoy->mobile = $request->mobile;
            $deliveryBoy->dob = $request->dob;
            $deliveryBoy->address = $request->address;
            $deliveryBoy->latitude = $request->latitude;
            $deliveryBoy->longitude = $request->longitude;
            $deliveryBoy->city_id = $request->city_id;
            $deliveryBoy->vehicle_id = $request->vehicle_id;

            // Handle profile image upload
            if ($request->hasFile('profile_image')) {
                $path = MediaUploadService::upload(
                    $request->file('profile_image'),
                    'delivery_boy/profile_images'
                );
                $deliveryBoy->profile_image = MediaUploadService::getFullUrl($path);
            }

            $deliveryBoy->status = DeliveryBoy::$statusRegistered;
            $deliveryBoy->save();

            // Create delivery boy documents record
            $document = new DeliveryBoyDocument();
            $document->delivery_boy_id = $deliveryBoy->id;

            // Driving License
            $document->driving_license_number = $request->driving_license_number;
            $hasDrivingLicense = false;

            if ($request->hasFile('driving_license_front')) {
                $path = MediaUploadService::upload(
                    $request->file('driving_license_front'),
                    'delivery_boy/documents/driving_license'
                );
                $document->driving_license_front_path = MediaUploadService::getFullUrl($path);
                $hasDrivingLicense = true;
            }

            if ($request->hasFile('driving_license_back')) {
                $path = MediaUploadService::upload(
                    $request->file('driving_license_back'),
                    'delivery_boy/documents/driving_license'
                );
                $document->driving_license_back_path = MediaUploadService::getFullUrl($path);
                $hasDrivingLicense = true;
            }

            $document->driving_license_status = $hasDrivingLicense ? 'pending_verification' : 'not_uploaded';

            // RC (Registration Certificate)
            $document->rc_number = $request->rc_number;
            $hasRc = false;

            if ($request->hasFile('rc_front')) {
                $path = MediaUploadService::upload(
                    $request->file('rc_front'),
                    'delivery_boy/documents/rc'
                );
                $document->rc_front_path = MediaUploadService::getFullUrl($path);
                $hasRc = true;
            }

            if ($request->hasFile('rc_back')) {
                $path = MediaUploadService::upload(
                    $request->file('rc_back'),
                    'delivery_boy/documents/rc'
                );
                $document->rc_back_path = MediaUploadService::getFullUrl($path);
                $hasRc = true;
            }

            $document->rc_status = $hasRc ? 'pending_verification' : 'not_uploaded';

            // Aadhar
            $document->aadhar_number = $request->aadhar_number;
            $hasAadhar = false;

            if ($request->hasFile('aadhar_front')) {
                $path = MediaUploadService::upload(
                    $request->file('aadhar_front'),
                    'delivery_boy/documents/aadhar'
                );
                $document->aadhar_front_path = MediaUploadService::getFullUrl($path);
                $hasAadhar = true;
            }

            if ($request->hasFile('aadhar_back')) {
                $path = MediaUploadService::upload(
                    $request->file('aadhar_back'),
                    'delivery_boy/documents/aadhar'
                );
                $document->aadhar_back_path = MediaUploadService::getFullUrl($path);
                $hasAadhar = true;
            }

            $document->aadhar_status = $hasAadhar ? 'pending_verification' : 'not_uploaded';

            // PAN
            $document->pan_number = $request->pan_number;
            $hasPan = false;

            if ($request->hasFile('pan_front')) {
                $path = MediaUploadService::upload(
                    $request->file('pan_front'),
                    'delivery_boy/documents/pan'
                );
                $document->pan_front_path = MediaUploadService::getFullUrl($path);
                $hasPan = true;
            }

            if ($request->hasFile('pan_back')) {
                $path = MediaUploadService::upload(
                    $request->file('pan_back'),
                    'delivery_boy/documents/pan'
                );
                $document->pan_back_path = MediaUploadService::getFullUrl($path);
                $hasPan = true;
            }

            $document->pan_status = $hasPan ? 'pending_verification' : 'not_uploaded';

            // Bank Details
            $document->bank_name = $request->bank_name;
            $document->account_holder_name = $request->account_holder_name;
            $document->account_number = $request->account_number;
            $document->ifsc_code = $request->ifsc_code;

            $hasBankDetails = $request->filled('bank_name') ||
                $request->filled('account_holder_name') ||
                $request->filled('account_number') ||
                $request->filled('ifsc_code') ||
                $request->hasFile('bank_passbook_image');

            if ($request->hasFile('bank_passbook_image')) {
                $path = MediaUploadService::upload(
                    $request->file('bank_passbook_image'),
                    'delivery_boy/documents/bank'
                );
                $document->bank_passbook_image_path = MediaUploadService::getFullUrl($path);
            }

            $document->bank_details_status = $hasBankDetails ? 'pending_verification' : 'not_uploaded';

            $document->save();

            // Sync store locations
            if ($request->has('store_location_ids') && is_array($request->store_location_ids)) {
                $deliveryBoy->storeLocations()->sync($request->store_location_ids);
            }

            DB::commit();

            return CommonHelper::responseSuccess("Delivery Boy Saved Successfully!");
        } catch (ValidationException $e) {
            DB::rollBack();
            Log::warning("Delivery Boy Save Validation Error: ", [
                'errors' => $e->errors(),
                'request' => $request->except(['profile_image', 'driving_license_front', 'driving_license_back', 'rc_front', 'rc_back', 'aadhar_front', 'aadhar_back', 'pan_front', 'pan_back', 'bank_passbook_image'])
            ]);
            return CommonHelper::responseError($e->getMessage());
        } catch (Exception $e) {
            DB::rollBack();
            Log::error("Add Delivery Boy Error: ", [
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to save delivery boy. Please try again.");
        }
    }

    /**
     * Get delivery boy details by ID (for viewing)
     */
    public function show($id)
    {
        try {
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError("Invalid delivery boy ID.");
            }

            $deliveryBoy = DeliveryBoy::with(['admin', 'city', 'vehicle', 'storeLocations', 'documents', 'emergencyContacts'])
                ->where('id', $id)
                ->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            return CommonHelper::responseWithData($deliveryBoy);
        } catch (Exception $e) {
            Log::error("Show Delivery Boy Error: ", [
                'id' => $id,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch delivery boy details.");
        }
    }

    /**
     * Get delivery boy latest location from location history
     */
    public function getLocation($id)
    {
        try {
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError("Invalid delivery boy ID.");
            }

            $deliveryBoy = DeliveryBoy::find($id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            // Get the latest location from location history
            $latestLocation = DB::table('delivery_boy_location_history')
                ->where('delivery_boy_id', $id)
                ->orderBy('id', 'DESC')
                ->first();

            if (!$latestLocation) {
                return CommonHelper::responseError("No location history found for this delivery boy.");
            }

            $locationData = [
                'latitude' => $latestLocation->latitude,
                'longitude' => $latestLocation->longitude,
                'tracked_at' => $latestLocation->tracked_at,
                'status' => 'Available', // You can add logic to determine actual status
                'delivery_boy_id' => $id
            ];

            return CommonHelper::responseWithData($locationData);
        } catch (Exception $e) {
            Log::error("Get Delivery Boy Location Error: ", [
                'id' => $id,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch delivery boy location.");
        }
    }

    /**
     * Get all active delivery boys with their latest location for live tracking
     */
    public function getLiveTrackingData(Request $request)
    {
        try {
            // Get city filter from request
            $cityId = $request->get('city_id');

            // Get all delivery boys (no status filter)
            $query = DB::table('delivery_boys')
                ->select(
                    'delivery_boys.id',
                    'delivery_boys.name',
                    'delivery_boys.mobile as phone',
                    'delivery_boys.is_available',
                    'delivery_boys.city_id'
                );

            // Apply city filter if provided
            if ($cityId) {
                $query->where('delivery_boys.city_id', $cityId);
            }

            $deliveryBoys = $query->get();

            $liveTrackingData = [];

            foreach ($deliveryBoys as $deliveryBoy) {
                // Get latest location from location history
                $latestLocation = DB::table('delivery_boy_location_history')
                    ->where('delivery_boy_id', $deliveryBoy->id)
                    ->orderBy('tracked_at', 'DESC')
                    ->first();

                // Skip if no location history exists
                if (!$latestLocation) {
                    continue;
                }

                // Get active orders count
                $activeOrdersCount = DB::table('orders')
                    ->where('delivery_boy_id', $deliveryBoy->id)
                    ->whereIn('active_status', [2, 3, 4]) // Confirmed, Preparing, Out for Delivery
                    ->count();

                // Get completed orders today
                $completedOrdersToday = DB::table('orders')
                    ->where('delivery_boy_id', $deliveryBoy->id)
                    ->where('active_status', 5) // Delivered
                    ->whereDate('updated_at', today())
                    ->count();

                // Calculate total distance traveled today
                $totalDistanceToday = DB::table('delivery_boy_location_history')
                    ->where('delivery_boy_id', $deliveryBoy->id)
                    ->whereDate('tracked_at', today())
                    ->sum('distance_from_last_km');

                // Determine status based ONLY on is_available
                $isOnline = (bool) $deliveryBoy->is_available;

                if ($deliveryBoy->is_available == 0) {
                    $status = 'Offline';
                } else {
                    $status = $activeOrdersCount > 0 ? 'Delivering' : 'Available';
                }

                // Calculate real speed for available drivers using location history
                // $speed = 0;
                // if ($isOnline) {
                //     // Get last 2 location points to calculate speed
                //     $recentLocations = DB::table('delivery_boy_location_history')
                //         ->where('delivery_boy_id', $deliveryBoy->id)
                //         ->orderBy('tracked_at', 'DESC')
                //         ->limit(2)
                //         ->get();

                //     if ($recentLocations->count() >= 2) {
                //         $latest = $recentLocations[0];
                //         $previous = $recentLocations[1];

                //         // Calculate time difference in hours
                //         $latestTime = \Carbon\Carbon::parse($latest->tracked_at);
                //         $previousTime = \Carbon\Carbon::parse($previous->tracked_at);
                //         $timeDiffHours = $previousTime->diffInMinutes($latestTime) / 60;

                //         // Get distance traveled between these points (in km)
                //         $distanceKm = (float) $latest->distance_from_last_km;

                //         // Calculate speed (km/h) - only if time difference is reasonable
                //         if ($timeDiffHours > 0 && $timeDiffHours < 1 && $distanceKm > 0) {
                //             $speed = round($distanceKm / $timeDiffHours, 0);
                //             // Cap speed at reasonable maximum (e.g., 100 km/h)
                //             $speed = min($speed, 100);
                //         }
                //     }
                // }

                $driverData = [
                    'id' => $deliveryBoy->id,
                    'name' => $deliveryBoy->name,
                    'phone' => $deliveryBoy->phone,
                    'lat' => (float) $latestLocation->latitude,
                    'lng' => (float) $latestLocation->longitude,
                    'status' => $status,
                    // 'speed' => $speed,
                    'completedOrders' => $completedOrdersToday,
                    'totalOrders' => $completedOrdersToday + $activeOrdersCount,
                    'activeOrders' => $activeOrdersCount,
                    'isOnline' => $isOnline,
                    'isAvailable' => (bool) $deliveryBoy->is_available,
                    'distanceTodayKm' => round($totalDistanceToday, 2),
                    'lastTrackedAt' => $latestLocation->tracked_at
                ];

                $liveTrackingData[] = $driverData;
            }

            // Calculate statistics
            $stats = [
                'onlineDrivers' => count(array_filter($liveTrackingData, fn($d) => $d['isOnline'])),
                'offlineDrivers' => count(array_filter($liveTrackingData, fn($d) => !$d['isOnline'])),
                'activeDeliveries' => array_sum(array_column($liveTrackingData, 'activeOrders')),
                'totalDistance' => round(array_sum(array_column($liveTrackingData, 'distanceTodayKm')), 1),
                // 'avgSpeed' => count($liveTrackingData) > 0 ? round(array_sum(array_column($liveTrackingData, 'speed')) / count($liveTrackingData), 0) : 0
            ];

            return CommonHelper::responseWithData([
                'drivers' => $liveTrackingData,
                'stats' => $stats
            ]);

        } catch (Exception $e) {
            Log::error("Get Live Tracking Data Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch live tracking data.");
        }
    }

    /**
     * Get delivery boy details for editing
     */
    public function edit($id)
    {
        try {
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError("Invalid delivery boy ID.");
            }

            $deliveryBoy = DeliveryBoy::with(['admin', 'city', 'vehicle', 'storeLocations', 'documents'])
                ->where('id', $id)
                ->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            return CommonHelper::responseWithData($deliveryBoy);
        } catch (Exception $e) {
            Log::error("Edit Delivery Boy Error: ", [
                'id' => $id,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch delivery boy details.");
        }
    }

    /**
     * Update an existing delivery boy
     */
    public function update(Request $request)
    {
        // Validation
        $validator = Validator::make($request->all(), [
            'id' => 'required|integer|exists:delivery_boys,id',
            'name' => 'required|string|max:255',
            'email' => 'nullable|email|max:255',
            'mobile' => 'nullable|string|max:20',
            'dob' => 'nullable|date|before:today',
            'address' => 'required|string',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'city_id' => 'required|exists:cities,id',
            'vehicle_id' => 'nullable|exists:vehicles,id',
            'store_location_ids' => 'nullable|array',
            'store_location_ids.*' => 'exists:store_locations,id',
            'profile_image' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',

            // Driving License
            'driving_license_number' => 'nullable|string|max:50',
            'driving_license_front' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',
            'driving_license_back' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',

            // RC (Registration Certificate)
            'rc_number' => 'nullable|string|max:50',
            'rc_front' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',
            'rc_back' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',

            // Aadhar
            'aadhar_number' => 'nullable|string|max:12',
            'aadhar_front' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',
            'aadhar_back' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',

            // PAN
            'pan_number' => 'nullable|string|max:10',
            'pan_front' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',
            'pan_back' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',

            // Bank Details
            'bank_name' => 'nullable|string|max:100',
            'account_holder_name' => 'nullable|string|max:100',
            'account_number' => 'nullable|string|max:50',
            'ifsc_code' => 'nullable|string|max:11',
            'bank_passbook_image' => 'nullable|image|mimes:jpeg,jpg,png,gif,webp|max:5120',
        ], [
            'id.required' => 'Delivery boy ID is required.',
            'id.exists' => 'Delivery boy not found.',
            'city_id.required' => 'The city field is required.',
            'city_id.exists' => 'The selected city is invalid.',
            'vehicle_id.exists' => 'The selected vehicle is invalid.',
            'latitude.between' => 'Latitude must be between -90 and 90.',
            'longitude.between' => 'Longitude must be between -180 and 180.',
            'profile_image.max' => 'Profile image must not exceed 5MB.',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $deliveryBoy = DeliveryBoy::find($request->id);

        if (!$deliveryBoy) {
            return CommonHelper::responseError("Delivery Boy not found!");
        }

        DB::beginTransaction();

        try {
            // Update admin user
            if ($deliveryBoy->admin_id) {
                Admin::where('id', $deliveryBoy->admin_id)->update([
                    'username' => $request->name,
                    'email' => $request->email ?? '',
                ]);
            }

            // Update delivery boy fields
            $deliveryBoy->name = $request->name;
            $deliveryBoy->email = $request->email;
            $deliveryBoy->mobile = $request->mobile;
            $deliveryBoy->dob = $request->dob;
            $deliveryBoy->address = $request->address;
            $deliveryBoy->latitude = $request->latitude;
            $deliveryBoy->longitude = $request->longitude;
            $deliveryBoy->city_id = $request->city_id;
            $deliveryBoy->vehicle_id = $request->vehicle_id;

            // Handle profile image upload
            if ($request->hasFile('profile_image')) {
                $oldPath = MediaUploadService::getPathFromUrl($deliveryBoy->profile_image ?? '');
                $path = MediaUploadService::upload(
                    $request->file('profile_image'),
                    'delivery_boy/profile_images',
                    'public',
                    $oldPath
                );
                $deliveryBoy->profile_image = MediaUploadService::getFullUrl($path);
            }

            $deliveryBoy->save();

            // Update or create delivery boy documents record
            $document = DeliveryBoyDocument::firstOrNew(['delivery_boy_id' => $deliveryBoy->id]);

            // Driving License
            if ($request->has('driving_license_number')) {
                $document->driving_license_number = $request->driving_license_number;
            }

            if ($request->hasFile('driving_license_front')) {
                $oldPath = MediaUploadService::getPathFromUrl($document->driving_license_front_path ?? '');
                $path = MediaUploadService::upload(
                    $request->file('driving_license_front'),
                    'delivery_boy/documents/driving_license',
                    'public',
                    $oldPath
                );
                $document->driving_license_front_path = MediaUploadService::getFullUrl($path);
                $document->driving_license_status = 'pending_verification';
            }

            if ($request->hasFile('driving_license_back')) {
                $oldPath = MediaUploadService::getPathFromUrl($document->driving_license_back_path ?? '');
                $path = MediaUploadService::upload(
                    $request->file('driving_license_back'),
                    'delivery_boy/documents/driving_license',
                    'public',
                    $oldPath
                );
                $document->driving_license_back_path = MediaUploadService::getFullUrl($path);
                $document->driving_license_status = 'pending_verification';
            }

            // RC (Registration Certificate)
            if ($request->has('rc_number')) {
                $document->rc_number = $request->rc_number;
            }

            if ($request->hasFile('rc_front')) {
                $oldPath = MediaUploadService::getPathFromUrl($document->rc_front_path ?? '');
                $path = MediaUploadService::upload(
                    $request->file('rc_front'),
                    'delivery_boy/documents/rc',
                    'public',
                    $oldPath
                );
                $document->rc_front_path = MediaUploadService::getFullUrl($path);
                $document->rc_status = 'pending_verification';
            }

            if ($request->hasFile('rc_back')) {
                $oldPath = MediaUploadService::getPathFromUrl($document->rc_back_path ?? '');
                $path = MediaUploadService::upload(
                    $request->file('rc_back'),
                    'delivery_boy/documents/rc',
                    'public',
                    $oldPath
                );
                $document->rc_back_path = MediaUploadService::getFullUrl($path);
                $document->rc_status = 'pending_verification';
            }

            // Aadhar
            if ($request->has('aadhar_number')) {
                $document->aadhar_number = $request->aadhar_number;
            }

            if ($request->hasFile('aadhar_front')) {
                $oldPath = MediaUploadService::getPathFromUrl($document->aadhar_front_path ?? '');
                $path = MediaUploadService::upload(
                    $request->file('aadhar_front'),
                    'delivery_boy/documents/aadhar',
                    'public',
                    $oldPath
                );
                $document->aadhar_front_path = MediaUploadService::getFullUrl($path);
                $document->aadhar_status = 'pending_verification';
            }

            if ($request->hasFile('aadhar_back')) {
                $oldPath = MediaUploadService::getPathFromUrl($document->aadhar_back_path ?? '');
                $path = MediaUploadService::upload(
                    $request->file('aadhar_back'),
                    'delivery_boy/documents/aadhar',
                    'public',
                    $oldPath
                );
                $document->aadhar_back_path = MediaUploadService::getFullUrl($path);
                $document->aadhar_status = 'pending_verification';
            }

            // PAN
            if ($request->has('pan_number')) {
                $document->pan_number = $request->pan_number;
            }

            if ($request->hasFile('pan_front')) {
                $oldPath = MediaUploadService::getPathFromUrl($document->pan_front_path ?? '');
                $path = MediaUploadService::upload(
                    $request->file('pan_front'),
                    'delivery_boy/documents/pan',
                    'public',
                    $oldPath
                );
                $document->pan_front_path = MediaUploadService::getFullUrl($path);
                $document->pan_status = 'pending_verification';
            }

            if ($request->hasFile('pan_back')) {
                $oldPath = MediaUploadService::getPathFromUrl($document->pan_back_path ?? '');
                $path = MediaUploadService::upload(
                    $request->file('pan_back'),
                    'delivery_boy/documents/pan',
                    'public',
                    $oldPath
                );
                $document->pan_back_path = MediaUploadService::getFullUrl($path);
                $document->pan_status = 'pending_verification';
            }

            // Bank Details
            if ($request->has('bank_name')) {
                $document->bank_name = $request->bank_name;
            }

            if ($request->has('account_holder_name')) {
                $document->account_holder_name = $request->account_holder_name;
            }

            if ($request->has('account_number')) {
                $document->account_number = $request->account_number;
            }

            if ($request->has('ifsc_code')) {
                $document->ifsc_code = $request->ifsc_code;
            }

            if ($request->hasFile('bank_passbook_image')) {
                $oldPath = MediaUploadService::getPathFromUrl($document->bank_passbook_image_path ?? '');
                $path = MediaUploadService::upload(
                    $request->file('bank_passbook_image'),
                    'delivery_boy/documents/bank',
                    'public',
                    $oldPath
                );
                $document->bank_passbook_image_path = MediaUploadService::getFullUrl($path);
                $document->bank_details_status = 'pending_verification';
            }

            $document->save();

            // Sync store locations
            if ($request->has('store_location_ids')) {
                $storeLocationIds = is_array($request->store_location_ids) ? $request->store_location_ids : [];
                $deliveryBoy->storeLocations()->sync($storeLocationIds);
            }

            DB::commit();

            return CommonHelper::responseSuccess("Delivery Boy Updated Successfully!");
        } catch (ValidationException $e) {
            DB::rollBack();
            Log::warning("Delivery Boy Update Validation Error: ", [
                'id' => $request->id,
                'errors' => $e->errors()
            ]);
            return CommonHelper::responseError($e->getMessage());
        } catch (Exception $e) {
            DB::rollBack();
            Log::error("Update Delivery Boy Error: ", [
                'id' => $request->id,
                'message' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to update delivery boy. Please try again.");
        }
    }

    /**
     * Delete a delivery boy
     */
    public function delete(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'id' => 'required|integer'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $deliveryBoy = DeliveryBoy::find($request->id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            // Delete associated documents and files
            $document = DeliveryBoyDocument::where('delivery_boy_id', $deliveryBoy->id)->first();

            if ($document) {
                // Delete document files
                $filesToDelete = [
                    $document->driving_license_front_path,
                    $document->driving_license_back_path,
                    $document->rc_front_path,
                    $document->rc_back_path,
                    $document->aadhar_front_path,
                    $document->aadhar_back_path,
                    $document->pan_front_path,
                    $document->pan_back_path,
                    $document->bank_passbook_image_path,
                ];

                foreach ($filesToDelete as $fileUrl) {
                    if ($fileUrl) {
                        MediaUploadService::deleteFileByUrl($fileUrl);
                    }
                }
            }

            // Delete profile image
            if ($deliveryBoy->profile_image) {
                MediaUploadService::deleteFileByUrl($deliveryBoy->profile_image);
            }

            $deliveryBoy->delete();

            return CommonHelper::responseSuccess("Delivery Boy Deleted Successfully!");
        } catch (Exception $e) {
            Log::error("Delete Delivery Boy Error: ", [
                'id' => $request->id ?? null,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to delete delivery boy. Please try again.");
        }
    }

    /**
     * Update delivery boy status
     */
    public function updateStatus(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'id' => 'required|integer|exists:delivery_boys,id',
                'status' => 'required|integer|in:0,1,2,3,7',
                'remark' => 'required_if:status,3,7|nullable|string|max:500'
            ], [
                'status.in' => 'Status must be one of: 0 (Registered), 1 (Approved), 2 (Not Approved), 3 (Deactivate), 7 (Removed).',
                'remark.required_if' => 'Remarks are required when status is Deactivate or Removed.'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $deliveryBoy = DeliveryBoy::find($request->id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            $deliveryBoy->status = $request->status;
            $deliveryBoy->remark = $request->remark;
            $deliveryBoy->save();

            // Map status to text
            $statusTexts = [
                0 => 'Registered',
                1 => 'Approved',
                2 => 'Not Approved',
                3 => 'Deactivated',
                7 => 'Removed'
            ];

            $statusText = $statusTexts[$request->status] ?? 'Updated';

            return CommonHelper::responseSuccess("Delivery Boy status changed to {$statusText} successfully!");
        } catch (Exception $e) {
            Log::error("Update Delivery Boy Status Error: ", [
                'id' => $request->id ?? null,
                'status' => $request->status ?? null,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to update delivery boy status. Please try again.");
        }
    }

    /**
     * Move a driver to the Problematic Drivers list.
     * A problematic driver stays registered but receives no new orders until
     * an admin verifies and moves them back to the normal list.
     */
    public function markProblematic(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'id'       => 'required|integer|exists:delivery_boys,id',
                'reason'   => 'required|string|max:500',
                'order_id' => 'nullable|integer',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $deliveryBoy = DeliveryBoy::find($request->id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            if ($deliveryBoy->is_problematic) {
                return CommonHelper::responseError("This driver is already in the problematic list.");
            }

            $deliveryBoy->is_problematic        = 1;
            $deliveryBoy->problematic_reason    = $request->reason;
            $deliveryBoy->problematic_order_id  = $request->order_id;
            $deliveryBoy->marked_problematic_by = auth()->user()->id ?? null;
            $deliveryBoy->marked_problematic_at = now();
            // Take them offline as well, otherwise the app keeps them in the online pool.
            $deliveryBoy->is_available = 0;
            $deliveryBoy->save();

            Log::info('Driver moved to problematic list', [
                'delivery_boy_id' => $deliveryBoy->id,
                'order_id'        => $request->order_id,
                'reason'          => $request->reason,
                'marked_by'       => $deliveryBoy->marked_problematic_by,
            ]);

            return CommonHelper::responseSuccess("Driver moved to the Problematic Drivers list. They will not receive new orders.");
        } catch (Exception $e) {
            Log::error("Mark Problematic Driver Error: ", [
                'id' => $request->id ?? null,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to update driver. Please try again.");
        }
    }

    /**
     * Move a driver back from the Problematic Drivers list to the normal list.
     */
    public function unmarkProblematic(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'id' => 'required|integer|exists:delivery_boys,id',
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $deliveryBoy = DeliveryBoy::find($request->id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            if (!$deliveryBoy->is_problematic) {
                return CommonHelper::responseError("This driver is not in the problematic list.");
            }

            $deliveryBoy->is_problematic        = 0;
            $deliveryBoy->problematic_reason    = null;
            $deliveryBoy->problematic_order_id  = null;
            $deliveryBoy->marked_problematic_by = null;
            $deliveryBoy->marked_problematic_at = null;

            // Holding the driver set is_available = 0. If his app is still logged in,
            // put him back online — otherwise he stays invisible to dispatch and nobody
            // can tell why, because the hold is already gone.
            $hasOpenSession = DB::table('delivery_boy_sessions')
                ->where('delivery_boy_id', $deliveryBoy->id)
                ->whereNull('logout_at')
                ->exists();

            if ($hasOpenSession) {
                $deliveryBoy->is_available = 1;
            }

            $deliveryBoy->save();

            Log::info('Driver moved back to normal list', [
                'delivery_boy_id'  => $deliveryBoy->id,
                'moved_by'         => auth()->user()->id ?? null,
                'has_open_session' => $hasOpenSession,
                'is_available'     => $deliveryBoy->is_available,
            ]);

            return CommonHelper::responseSuccess(
                $hasOpenSession
                    ? "Driver moved back to the normal list and is online again."
                    : "Driver moved back to the normal list. He will receive orders once he goes online in the app."
            );
        } catch (Exception $e) {
            Log::error("Unmark Problematic Driver Error: ", [
                'id' => $request->id ?? null,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to update driver. Please try again.");
        }
    }

    /**
     * List of drivers currently held back on the Problematic Drivers list.
     */
    public function problematicDrivers(Request $request)
    {
        try {
            $drivers = DB::table('delivery_boys')
                ->leftJoin('admins', 'admins.id', '=', 'delivery_boys.marked_problematic_by')
                ->where('delivery_boys.is_problematic', 1)
                ->select(
                    'delivery_boys.id',
                    'delivery_boys.name',
                    'delivery_boys.mobile',
                    'delivery_boys.city_id',
                    'delivery_boys.status',
                    'delivery_boys.is_available',
                    'delivery_boys.problematic_reason',
                    'delivery_boys.problematic_order_id',
                    'delivery_boys.marked_problematic_at',
                    'admins.username as marked_by_name'
                )
                ->orderBy('delivery_boys.marked_problematic_at', 'DESC')
                ->get();

            return CommonHelper::responseWithData($drivers, $drivers->count());
        } catch (Exception $e) {
            Log::error("Problematic Drivers List Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch problematic drivers.");
        }
    }

    /**
     * Update delivery boy document status
     */
    public function updateDocumentStatus(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'delivery_boy_id' => 'required|integer|exists:delivery_boys,id',
                'field' => 'required|string|in:driving_license_status,rc_status,aadhar_status,pan_status,bank_details_status',
                'status' => 'required|string|in:not_uploaded,pending_verification,verified,rejected'
            ], [
                'delivery_boy_id.required' => 'Delivery boy ID is required.',
                'delivery_boy_id.exists' => 'Delivery boy not found.',
                'field.in' => 'Invalid document field.',
                'status.in' => 'Invalid status value.'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $deliveryBoy = DeliveryBoy::with('documents')->find($request->delivery_boy_id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            // Get or create document record
            $document = $deliveryBoy->documents;
            if (!$document) {
                $document = DeliveryBoyDocument::create([
                    'delivery_boy_id' => $deliveryBoy->id
                ]);
            }

            // Update the specific status field
            $document->{$request->field} = $request->status;
            $document->save();

            // Format field name for response and notification
            $fieldNames = [
                'driving_license_status' => 'Driving License',
                'rc_status' => 'RC',
                'aadhar_status' => 'Aadhar',
                'pan_status' => 'PAN',
                'bank_details_status' => 'Bank Details'
            ];

            $fieldName = $fieldNames[$request->field] ?? 'Document';

            // Send notification to driver about document status change
            try {
                $statusMessages = [
                    'verified' => "Your {$fieldName} has been verified successfully!",
                    'rejected' => "Your {$fieldName} has been rejected. Please upload a valid document.",
                    'pending_verification' => "Your {$fieldName} is under review. We will notify you once verified.",
                    'not_uploaded' => "Please upload your {$fieldName} to complete verification."
                ];

                $notificationTitle = match($request->status) {
                    'verified' => "Document Verified ✓",
                    'rejected' => "Document Rejected",
                    'pending_verification' => "Document Under Review",
                    default => "Document Status Update"
                };

                $notificationMessage = $statusMessages[$request->status] ?? "Your {$fieldName} status has been updated.";

                // Send push notification to driver
                DriverNotificationService::send(
                    $deliveryBoy->id,
                    $notificationTitle,
                    $notificationMessage,
                    '',
                    'document_status',
                    null,
                    [
                        'document_type' => $request->field,
                        'status' => $request->status
                    ]
                );
            } catch (Exception $e) {
                // Log notification error but don't fail the status update
                Log::error("Document Status Notification Error: ", [
                    'delivery_boy_id' => $deliveryBoy->id,
                    'field' => $request->field,
                    'status' => $request->status,
                    'error' => $e->getMessage()
                ]);
            }

            return CommonHelper::responseSuccess("{$fieldName} status updated to {$request->status} successfully!");
        } catch (Exception $e) {
            Log::error("Update Document Status Error: ", [
                'delivery_boy_id' => $request->delivery_boy_id ?? null,
                'field' => $request->field ?? null,
                'status' => $request->status ?? null,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to update document status. Please try again.");
        }
    }

    /**
     * Update delivery boy hand cash limit
     */
    public function updateHandCashLimit(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'delivery_boy_id' => 'required|integer|exists:delivery_boys,id',
                'hand_cash_limit' => 'required|numeric|min:0'
            ], [
                'delivery_boy_id.required' => 'Delivery boy ID is required.',
                'delivery_boy_id.exists' => 'Delivery boy not found.',
                'hand_cash_limit.required' => 'Hand cash limit is required.',
                'hand_cash_limit.numeric' => 'Hand cash limit must be a number.',
                'hand_cash_limit.min' => 'Hand cash limit must be at least 0.'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $deliveryBoy = DeliveryBoy::find($request->delivery_boy_id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            // Update the hand cash limit
            $deliveryBoy->hand_cash_limit = $request->hand_cash_limit;
            $deliveryBoy->save();

            return CommonHelper::responseSuccess("Hand cash limit updated successfully!", $deliveryBoy);
        } catch (Exception $e) {
            Log::error("Update Hand Cash Limit Error: ", [
                'delivery_boy_id' => $request->delivery_boy_id ?? null,
                'hand_cash_limit' => $request->hand_cash_limit ?? null,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to update hand cash limit. Please try again.");
        }
    }

    /**
     * Get orders assigned to a delivery boy
     */
    public function getOrders($id)
    {
        try {
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError("Invalid delivery boy ID.");
            }

            $deliveryBoy = DeliveryBoy::find($id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            $orders = Order::select(
                    'orders.*',
                    'users.name as user_name',
                    'users.mobile as user_mobile'
                )
                ->leftJoin('users', 'orders.user_id', '=', 'users.id')
                ->where('orders.delivery_boy_id', $id)
                ->orderBy('orders.created_at', 'DESC')
                ->get();

            return CommonHelper::responseWithData($orders);
        } catch (Exception $e) {
            Log::error("Get Delivery Boy Orders Error: ", [
                'id' => $id,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch delivery boy orders.");
        }
    }

    /**
     * Get hand cash transactions for a delivery boy
     */
    public function getHandCash($id)
    {
        try {
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError("Invalid delivery boy ID.");
            }

            $deliveryBoy = DeliveryBoy::find($id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            $transactions = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $id)
                ->where('is_hand_cash', 1)
                ->orderBy('transaction_date', 'DESC')
                ->orderBy('created_at', 'DESC')
                ->get();

            return CommonHelper::responseWithData($transactions);
        } catch (Exception $e) {
            Log::error("Get Delivery Boy Hand Cash Error: ", [
                'id' => $id,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch delivery boy hand cash transactions.");
        }
    }

    /**
     * Get surge charge (rain surcharge) transactions for a delivery boy
     */
    public function getSurgeCharges($id)
    {
        try {
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError("Invalid delivery boy ID.");
            }

            $deliveryBoy = DeliveryBoy::find($id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            $transactions = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $id)
                ->where('rain_surcharge', '>', 0)
                ->select('order_id', 'transaction_date', 'rain_surcharge', 'delivery_charge', 'amount')
                ->orderBy('transaction_date', 'DESC')
                ->orderBy('created_at', 'DESC')
                ->get();

            return CommonHelper::responseWithData($transactions);
        } catch (Exception $e) {
            Log::error("Get Delivery Boy Surge Charges Error: ", [
                'id' => $id,
                'message' => $e->getMessage(),
            ]);
            return CommonHelper::responseError("Failed to fetch surge charge transactions.");
        }
    }

    /**
     * Get pending incentive transactions for a delivery boy
     */
    public function getPendingIncentives($id)
    {
        try {
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError("Invalid delivery boy ID.");
            }

            $deliveryBoy = DeliveryBoy::find($id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            // Get pending incentive transactions (type = 'incentive', settled_at = null)
            $transactions = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $id)
                ->where('type', 'incentive')
                ->whereNull('settled_at')
                ->orderBy('transaction_date', 'DESC')
                ->orderBy('created_at', 'DESC')
                ->get();

            // Calculate total pending incentive amount
            $totalAmount = $transactions->sum('amount');

            return CommonHelper::responseWithData([
                'transactions' => $transactions,
                'total_amount' => $totalAmount,
                'count' => $transactions->count()
            ]);
        } catch (Exception $e) {
            Log::error("Get Delivery Boy Pending Incentives Error: ", [
                'id' => $id,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch delivery boy incentive transactions.");
        }
    }

    /**
     * Get payout transactions for a delivery boy (non-hand cash)
     */
    public function getPayouts($id)
    {
        try {
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError("Invalid delivery boy ID.");
            }

            $deliveryBoy = DeliveryBoy::find($id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            // Get settled transactions (is_hand_cash = 0, settled_with_admin = 1, NOT incentive)
            // Incentives are excluded as they have their own dedicated tab
            $settledTransactions = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $id)
                ->where('is_hand_cash', 0)
                ->where('settled_with_admin', 1)
                ->where('type', '!=', 'incentive')
                ->orderBy('settled_at', 'DESC')
                ->orderBy('created_at', 'DESC')
                ->get();

            // Get unsettled transactions (is_hand_cash = 0, settled_with_admin = 0, NOT incentive type)
            $unsettledTransactions = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $id)
                ->where('is_hand_cash', 0)
                ->where('settled_with_admin', 0)
                ->where('type', '!=', 'incentive')
                ->orderBy('transaction_date', 'DESC')
                ->orderBy('created_at', 'DESC')
                ->get();

            // Calculate unsettled amount (is_hand_cash = 0, settled_with_admin = 0, NOT incentive type)
            $unsettledAmount = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $id)
                ->where('is_hand_cash', 0)
                ->where('settled_with_admin', 0)
                ->where('type', '!=', 'incentive')
                ->sum('driver_earnings');

            // Calculate total settled amount (excluding incentives)
            $settledAmount = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $id)
                ->where('is_hand_cash', 0)
                ->where('settled_with_admin', 1)
                ->where('type', '!=', 'incentive')
                ->sum('driver_earnings');

            return CommonHelper::responseWithData([
                'settled_transactions' => $settledTransactions,
                'unsettled_transactions' => $unsettledTransactions,
                'unsettled_amount' => $unsettledAmount ?? 0,
                'settled_amount' => $settledAmount ?? 0
            ]);
        } catch (Exception $e) {
            Log::error("Get Delivery Boy Payouts Error: ", [
                'id' => $id,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch delivery boy payout transactions.");
        }
    }

    /**
     * Get unsettled payout transactions for a delivery boy
     */
    public function getUnsettledPayouts($id)
    {
        try {
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError("Invalid delivery boy ID.");
            }

            $deliveryBoy = DeliveryBoy::find($id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            // Get base unsettled transactions (excluding hand cash, incentives, and referral bonuses)
            $baseTransactions = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $id)
                ->where('is_hand_cash', 0)
                ->where('settled_with_admin', 0)
                ->where('type', '!=', 'incentive')
                ->where('type', '!=', 'referral_bonus')
                ->orderBy('transaction_date', 'DESC')
                ->orderBy('created_at', 'DESC')
                ->get();

            // Get hand cash transactions
            $handCashTransactions = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $id)
                ->where('is_hand_cash', 1)
                ->where('settled_with_admin', 0)
                ->orderBy('transaction_date', 'DESC')
                ->orderBy('created_at', 'DESC')
                ->get();

            // Get unsettled incentive transactions
            $incentiveTransactions = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $id)
                ->where('type', 'incentive')
                ->whereNull('settled_at')
                ->orderBy('created_at', 'DESC')
                ->get();

            // Get unsettled referral bonus transactions
            $referralTransactions = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $id)
                ->where('type', 'referral_bonus')
                ->where('settled_with_admin', 0)
                ->orderBy('created_at', 'DESC')
                ->get();

            // Calculate totals
            $baseAmount = $baseTransactions->sum('driver_earnings');
            $handCashAmount = $handCashTransactions->sum('admin_cash');
            $incentiveAmount = $incentiveTransactions->sum('amount');
            $referralAmount = $referralTransactions->sum('driver_earnings');
            $totalUnsettledAmount = $baseAmount - $handCashAmount + $incentiveAmount + $referralAmount;

            return response()->json([
                'success' => true,
                'message' => 'Unsettled transactions retrieved successfully',
                'data' => [
                    'base_transactions' => $baseTransactions,
                    'hand_cash_transactions' => $handCashTransactions,
                    'incentive_transactions' => $incentiveTransactions,
                    'referral_transactions' => $referralTransactions,
                    'base_amount' => $baseAmount,
                    'hand_cash_amount' => $handCashAmount,
                    'incentive_amount' => $incentiveAmount,
                    'referral_amount' => $referralAmount,
                    'total_unsettled_amount' => max(0, $totalUnsettledAmount),
                    // Keep legacy fields for backward compatibility
                    'unsettled_transactions' => $baseTransactions
                ]
            ]);
        } catch (Exception $e) {
            Log::error("Get Delivery Boy Unsettled Payouts Error: ", [
                'id' => $id,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch delivery boy unsettled payout transactions.");
        }
    }

    /**
     * Process payout settlement for selected transactions
     * Uses PhonePe payout API to transfer funds to delivery boy's bank account
     */
    public function settlePayouts(Request $request, $id)
    {
        try {
            Log::info('Settle Payouts: Request received', [
                'delivery_boy_id' => $id,
                'request_data' => $request->all()
            ]);

            // Validate delivery boy ID
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError("Invalid delivery boy ID.");
            }

            // Validate request
            $validator = Validator::make($request->all(), [
                'transaction_ids' => 'nullable|array',
                'transaction_ids.*' => 'required|integer|exists:delivery_boy_transactions,id',
                'total_amount' => 'required|numeric|min:0.01',
                'hand_cash_order_ids' => 'nullable|array',
                'hand_cash_order_ids.*' => 'required|integer|exists:delivery_boy_transactions,id',
                'hand_cash_deducted_amount' => 'nullable|numeric|min:0',
                'incentive_transaction_ids' => 'nullable|array',
                'incentive_transaction_ids.*' => 'required|integer|exists:delivery_boy_transactions,id',
                'incentive_amount' => 'nullable|numeric|min:0',
                'referral_ids' => 'nullable|array',
                'referral_ids.*' => 'required|integer|exists:delivery_boy_transactions,id',
                'referral_amount' => 'nullable|numeric|min:0',
                'manual_transaction_id' => 'nullable|string'
            ], [
                'transaction_ids.array' => 'Invalid transaction selection.',
                'transaction_ids.min' => 'Please select at least one transaction.',
                'total_amount.required' => 'Total amount is required.',
                'total_amount.min' => 'Amount must be greater than zero.',
                'hand_cash_order_ids.array' => 'Invalid hand cash order selection.',
                'hand_cash_deducted_amount.numeric' => 'Hand cash amount must be numeric.',
                'incentive_transaction_ids.array' => 'Invalid incentive selection.',
                'incentive_amount.numeric' => 'Incentive amount must be numeric.',
                'referral_ids.array' => 'Invalid referral selection.',
                'referral_amount.numeric' => 'Referral amount must be numeric.'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $deliveryBoy = DeliveryBoy::find($id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            $transactionIds = $request->transaction_ids ?? [];
            $totalAmount = (float) $request->total_amount;

            // Extract hand cash data
            $handCashOrderIds = $request->hand_cash_order_ids ?? [];
            $handCashDeductedAmount = (float) ($request->hand_cash_deducted_amount ?? 0);

            // Extract incentive data
            $incentiveTransactionIds = $request->incentive_transaction_ids ?? [];
            $incentiveAmount = (float) ($request->incentive_amount ?? 0);

            // Extract referral data
            $referralIds = $request->referral_ids ?? [];
            $referralAmount = (float) ($request->referral_amount ?? 0);

            // Check if manual transaction ID is provided
            $manualTransactionId = $request->manual_transaction_id;
            $isManualPayment = !empty($manualTransactionId);

            // Verify base transactions belong to this delivery boy and are unsettled (if any provided)
            $validTransactions = collect();
            if (!empty($transactionIds)) {
                $validTransactions = DB::table('delivery_boy_transactions')
                    ->whereIn('id', $transactionIds)
                    ->where('delivery_boy_id', $id)
                    ->where('is_hand_cash', 0)
                    ->where('settled_with_admin', 0)
                    ->where('type', '!=', 'incentive')
                    ->where('type', '!=', 'referral_bonus')  // Base transactions exclude referral bonuses
                    ->get();

                if ($validTransactions->count() !== count($transactionIds)) {
                    Log::warning('Settle Payouts: Invalid transactions detected', [
                        'delivery_boy_id' => $id,
                        'requested_ids' => $transactionIds,
                        'valid_count' => $validTransactions->count()
                    ]);
                    return CommonHelper::responseError("Some transactions are invalid or already settled.");
                }
            }

            // Verify total amount matches (accounting for hand cash deduction, incentives, and referrals)
            $calculatedAmount = $validTransactions->sum('driver_earnings');
            $expectedAmount = $calculatedAmount - $handCashDeductedAmount + $incentiveAmount + $referralAmount;

            if (abs($expectedAmount - $totalAmount) > 0.01) {
                Log::warning('Settle Payouts: Amount mismatch', [
                    'delivery_boy_id' => $id,
                    'calculated_amount' => $calculatedAmount,
                    'hand_cash_deducted' => $handCashDeductedAmount,
                    'incentive_amount' => $incentiveAmount,
                    'expected_amount' => $expectedAmount,
                    'requested_amount' => $totalAmount
                ]);
                return CommonHelper::responseError("Amount mismatch. Please refresh and try again.");
            }

            // Process hand cash settlement if provided
            if (!empty($handCashOrderIds) && $handCashDeductedAmount > 0) {
                // Verify hand cash transactions belong to this delivery boy and are unsettled
                $validHandCashTransactions = DB::table('delivery_boy_transactions')
                    ->whereIn('id', $handCashOrderIds)
                    ->where('delivery_boy_id', $id)
                    ->where('is_hand_cash', 1)
                    ->where('settled_with_admin', 0)
                    ->get();

                if ($validHandCashTransactions->count() !== count($handCashOrderIds)) {
                    Log::warning('Settle Payouts: Invalid hand cash transactions', [
                        'delivery_boy_id' => $id,
                        'requested_hand_cash_ids' => $handCashOrderIds,
                        'valid_count' => $validHandCashTransactions->count()
                    ]);
                    return CommonHelper::responseError("Some hand cash transactions are invalid or already settled.");
                }

                // Verify hand cash amount matches (using admin_cash instead of driver_earnings)
                $calculatedHandCashAmount = $validHandCashTransactions->sum('admin_cash');
                if (abs($calculatedHandCashAmount - $handCashDeductedAmount) > 0.01) {
                    Log::warning('Settle Payouts: Hand cash amount mismatch', [
                        'delivery_boy_id' => $id,
                        'calculated_hand_cash' => $calculatedHandCashAmount,
                        'requested_hand_cash' => $handCashDeductedAmount
                    ]);
                    return CommonHelper::responseError("Hand cash amount mismatch. Please refresh and try again.");
                }

                // Update hand cash transactions as settled
                DB::table('delivery_boy_transactions')
                    ->whereIn('id', $handCashOrderIds)
                    ->where('delivery_boy_id', $id)
                    ->where('is_hand_cash', 1)
                    ->where('settled_with_admin', 0)
                    ->update([
                        'settled_with_admin' => 1,
                        'settled_at' => now()
                    ]);

                Log::info('Settle Payouts: Hand cash transactions settled', [
                    'delivery_boy_id' => $id,
                    'hand_cash_transaction_count' => count($handCashOrderIds),
                    'hand_cash_amount' => $handCashDeductedAmount
                ]);
            }

            // Process incentive transactions if provided
            $validIncentiveTransactions = collect();
            if (!empty($incentiveTransactionIds) && $incentiveAmount > 0) {
                // Verify incentive transactions belong to this delivery boy and are unsettled
                $validIncentiveTransactions = DB::table('delivery_boy_transactions')
                    ->whereIn('id', $incentiveTransactionIds)
                    ->where('delivery_boy_id', $id)
                    ->where('type', 'incentive')
                    ->whereNull('settled_at')
                    ->get();

                if ($validIncentiveTransactions->count() !== count($incentiveTransactionIds)) {
                    Log::warning('Settle Payouts: Invalid incentive transactions', [
                        'delivery_boy_id' => $id,
                        'requested_incentive_ids' => $incentiveTransactionIds,
                        'valid_count' => $validIncentiveTransactions->count()
                    ]);
                    return CommonHelper::responseError("Some incentive transactions are invalid or already settled.");
                }

                // Verify incentive amount matches
                $calculatedIncentiveAmount = $validIncentiveTransactions->sum('amount');
                if (abs($calculatedIncentiveAmount - $incentiveAmount) > 0.01) {
                    Log::warning('Settle Payouts: Incentive amount mismatch', [
                        'delivery_boy_id' => $id,
                        'calculated_incentive' => $calculatedIncentiveAmount,
                        'requested_incentive' => $incentiveAmount
                    ]);
                    return CommonHelper::responseError("Incentive amount mismatch. Please refresh and try again.");
                }

                Log::info('Settle Payouts: Incentive transactions validated', [
                    'delivery_boy_id' => $id,
                    'incentive_transaction_count' => count($incentiveTransactionIds),
                    'incentive_amount' => $incentiveAmount
                ]);
            }

            // Process referral bonus transactions if provided
            $validReferralTransactions = collect();
            if (!empty($referralIds) && $referralAmount > 0) {
                // Verify referral transactions belong to this delivery boy and are unsettled
                $validReferralTransactions = DB::table('delivery_boy_transactions')
                    ->whereIn('id', $referralIds)
                    ->where('delivery_boy_id', $id)
                    ->where('type', 'referral_bonus')
                    ->where('settled_with_admin', 0)
                    ->get();

                if ($validReferralTransactions->count() !== count($referralIds)) {
                    Log::warning('Settle Payouts: Invalid referral transactions', [
                        'delivery_boy_id' => $id,
                        'requested_referral_ids' => $referralIds,
                        'valid_count' => $validReferralTransactions->count()
                    ]);
                    return CommonHelper::responseError("Some referral transactions are invalid or already settled.");
                }

                // Verify referral amount matches
                $calculatedReferralAmount = $validReferralTransactions->sum('driver_earnings');
                if (abs($calculatedReferralAmount - $referralAmount) > 0.01) {
                    Log::warning('Settle Payouts: Referral amount mismatch', [
                        'delivery_boy_id' => $id,
                        'calculated_referral' => $calculatedReferralAmount,
                        'requested_referral' => $referralAmount
                    ]);
                    return CommonHelper::responseError("Referral amount mismatch. Please refresh and try again.");
                }

                Log::info('Settle Payouts: Referral transactions validated', [
                    'delivery_boy_id' => $id,
                    'referral_transaction_count' => count($referralIds),
                    'referral_amount' => $referralAmount
                ]);
            }

            // Process payout based on payment method
            if ($isManualPayment) {
                // Manual bank transfer - skip PhonePe API
                $payoutReference = $manualTransactionId;

                // Get bank account number from delivery_boy_documents table
                $bankDetails = DB::table('delivery_boy_documents')
                    ->where('delivery_boy_id', $id)
                    ->select('account_number')
                    ->first();
                $bankAccNumber = $bankDetails->account_number ?? null;

                // Update base transactions as settled if any provided
                if (!empty($transactionIds)) {
                    DB::table('delivery_boy_transactions')
                        ->whereIn('id', $transactionIds)
                        ->where('delivery_boy_id', $id)
                        ->where('settled_with_admin', 0)
                        ->update([
                            'settled_with_admin' => 1,
                            'settled_at' => now(),
                            'payout_reference' => $payoutReference,
                            'bank_acc_number' => $bankAccNumber
                        ]);
                }

                Log::info('Settle Payouts: Manual payment processed', [
                    'delivery_boy_id' => $id,
                    'amount' => $totalAmount,
                    'transaction_count' => count($transactionIds),
                    'hand_cash_deducted' => $handCashDeductedAmount,
                    'hand_cash_transactions_count' => count($handCashOrderIds),
                    'incentive_amount' => $incentiveAmount,
                    'incentive_transactions_count' => count($incentiveTransactionIds),
                    'referral_amount' => $referralAmount,
                    'referral_transactions_count' => count($referralIds),
                    'original_amount' => $calculatedAmount,
                    'manual_transaction_id' => $manualTransactionId
                ]);
            } else {
                // Automatic PhonePe payout
                $payoutResult = PhonePePayoutService::processPayoutToDeliveryBoy(
                    $id,
                    $transactionIds,
                    $totalAmount
                );

                if (!$payoutResult['success']) {
                    Log::error('Settle Payouts: Payout failed', [
                        'delivery_boy_id' => $id,
                        'error' => $payoutResult['error']
                    ]);
                    return CommonHelper::responseError($payoutResult['error']);
                }

                $payoutReference = $payoutResult['data']['payout_transaction_id'] ?? null;

                Log::info('Settle Payouts: Payout initiated successfully', [
                    'delivery_boy_id' => $id,
                    'amount' => $totalAmount,
                    'transaction_count' => count($transactionIds),
                    'hand_cash_deducted' => $handCashDeductedAmount,
                    'hand_cash_transactions_count' => count($handCashOrderIds),
                    'incentive_amount' => $incentiveAmount,
                    'incentive_transactions_count' => count($incentiveTransactionIds),
                    'referral_amount' => $referralAmount,
                    'referral_transactions_count' => count($referralIds),
                    'original_amount' => $calculatedAmount,
                    'payout_data' => $payoutResult['data'] ?? []
                ]);
            }

            // Get bank account number and payout reference (already set above)
            $bankDetails = DB::table('delivery_boy_documents')
                ->where('delivery_boy_id', $id)
                ->select('account_number')
                ->first();
            $bankAccNumber = $bankDetails->account_number ?? null;

            // Update incentive transactions if any were included
            if (!empty($incentiveTransactionIds) && $validIncentiveTransactions->count() > 0) {
                DB::table('delivery_boy_transactions')
                    ->whereIn('id', $incentiveTransactionIds)
                    ->where('delivery_boy_id', $id)
                    ->where('type', 'incentive')
                    ->whereNull('settled_at')
                    ->update([
                        'status' => 'success',
                        'settled_at' => now(),
                        'payout_reference' => $payoutReference,
                        'bank_acc_number' => $bankAccNumber
                    ]);

                Log::info('Settle Payouts: Incentive transactions updated', [
                    'delivery_boy_id' => $id,
                    'incentive_transaction_count' => count($incentiveTransactionIds),
                    'incentive_amount' => $incentiveAmount,
                    'payout_reference' => $payoutReference,
                    'bank_acc_number' => $bankAccNumber
                ]);
            }

            // Update referral bonus transactions as settled if provided
            if (!empty($referralIds) && $referralAmount > 0) {
                DB::table('delivery_boy_transactions')
                    ->whereIn('id', $referralIds)
                    ->where('delivery_boy_id', $id)
                    ->where('type', 'referral_bonus')
                    ->where('settled_with_admin', 0)
                    ->update([
                        'settled_with_admin' => 1,
                        'settled_at' => now(),
                        'status' => 'success',
                        'payout_reference' => $payoutReference,
                        'bank_acc_number' => $bankAccNumber
                    ]);

                Log::info('Settle Payouts: Referral transactions updated', [
                    'delivery_boy_id' => $id,
                    'referral_transaction_count' => count($referralIds),
                    'referral_amount' => $referralAmount,
                    'payout_reference' => $payoutReference,
                    'bank_acc_number' => $bankAccNumber
                ]);
            }

            // Send notification to delivery boy about the payout settlement
            try {
                $currencySymbol = 'Rs.';
                $notificationTitle = "Payout Settled";

                if ($isManualPayment) {
                    $notificationMessage = "Your payout of {$currencySymbol}" . number_format($totalAmount, 2) . " has been successfully processed and transferred to your bank account.";
                } else {
                    $notificationMessage = "Your payout of {$currencySymbol}" . number_format($totalAmount, 2) . " has been successfully initiated and will be credited to your bank account soon.";
                }

                if ($handCashDeductedAmount > 0) {
                    $notificationMessage .= " Hand cash of {$currencySymbol}" . number_format($handCashDeductedAmount, 2) . " has been deducted from this payout.";
                }

                if ($incentiveAmount > 0) {
                    $notificationMessage .= " Incentive of {$currencySymbol}" . number_format($incentiveAmount, 2) . " has been included in this payout.";
                }

                if ($referralAmount > 0) {
                    $notificationMessage .= " Referral bonus of {$currencySymbol}" . number_format($referralAmount, 2) . " has been included in this payout.";
                }

                $notificationResult = DriverNotificationService::send(
                    $id,
                    $notificationTitle,
                    $notificationMessage,
                    '',
                    'payout',
                    null,
                    [
                        'amount' => $totalAmount,
                        'hand_cash_deducted' => $handCashDeductedAmount,
                        'incentive_amount' => $incentiveAmount,
                        'referral_amount' => $referralAmount,
                        'transaction_count' => count($transactionIds),
                        'payout_transaction_id' => $payoutReference,
                        'is_manual' => $isManualPayment
                    ]
                );

                Log::info('Settle Payouts: Notification sent to delivery boy', [
                    'delivery_boy_id' => $id,
                    'notification_result' => $notificationResult
                ]);
            } catch (Exception $notificationError) {
                // Log notification error but don't fail the payout
                Log::error('Settle Payouts: Failed to send notification to delivery boy', [
                    'delivery_boy_id' => $id,
                    'error' => $notificationError->getMessage()
                ]);
            }

            return CommonHelper::responseWithData([
                'message' => $isManualPayment ? 'Manual payout processed successfully' : 'Payout initiated successfully',
                'payout_transaction_id' => $payoutReference,
                'amount' => $totalAmount,
                'hand_cash_deducted' => $handCashDeductedAmount,
                'hand_cash_transactions_settled' => count($handCashOrderIds),
                'incentive_amount' => $incentiveAmount,
                'incentive_transactions_settled' => count($incentiveTransactionIds),
                'referral_amount' => $referralAmount,
                'referral_transactions_settled' => count($referralIds),
                'status' => $isManualPayment ? 'completed' : 'processing',
                'is_manual' => $isManualPayment
            ]);

        } catch (Exception $e) {
            Log::error("Settle Payouts Error: ", [
                'id' => $id,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to process payout. Please try again.");
        }
    }

    /**
     * Get delivery boy's bank details for payout verification
     */
    public function getBankDetails($id)
    {
        try {
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError("Invalid delivery boy ID.");
            }

            $deliveryBoy = DeliveryBoy::find($id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            $bankDetails = PhonePePayoutService::getDeliveryBoyBankDetails($id);

            if (!$bankDetails['success']) {
                return CommonHelper::responseError($bankDetails['error']);
            }

            // Mask account number for display
            $accountNumber = $bankDetails['data']['account_number'];
            $maskedAccount = str_repeat('*', strlen($accountNumber) - 4) . substr($accountNumber, -4);

            return CommonHelper::responseWithData([
                'bank_name' => $bankDetails['data']['bank_name'],
                'account_holder_name' => $bankDetails['data']['account_holder_name'],
                'account_number_masked' => $maskedAccount,
                'ifsc_code' => $bankDetails['data']['ifsc_code'],
                'is_verified' => true
            ]);

        } catch (Exception $e) {
            Log::error("Get Bank Details Error: ", [
                'id' => $id,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch bank details.");
        }
    }

    /**
     * Check payout status from PhonePe
     */
    public function checkPayoutStatus(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'payout_transaction_id' => 'required|string'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $payoutTransactionId = $request->payout_transaction_id;

            $statusResult = PhonePePayoutService::checkPayoutStatus($payoutTransactionId);

            if (!$statusResult['success']) {
                return CommonHelper::responseError($statusResult['error']);
            }

            return CommonHelper::responseWithData($statusResult);

        } catch (Exception $e) {
            Log::error("Check Payout Status Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to check payout status.");
        }
    }

    /**
     * Get incentive progress for a delivery boy
     */
    public function getIncentives($id)
    {
        try {
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError("Invalid delivery boy ID.");
            }

            $deliveryBoy = DeliveryBoy::find($id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            // Get incentive tier credits with transaction details (left join to include unsettled)
            $incentiveCredits = DB::table('delivery_boy_incentive_tier_credits as tc')
                ->join('incentive_offer_tiers as tier', 'tc.tier_id', '=', 'tier.id')
                ->join('incentive_offers as offer', 'tier.incentive_offer_id', '=', 'offer.id')
                ->join('delivery_boy_incentive_progress as progress', 'tc.delivery_boy_incentive_progress_id', '=', 'progress.id')
                ->leftJoin('delivery_boy_transactions as t', function ($join) {
                    $join->on('tc.transaction_id', '=', 't.id')
                         ->where('t.type', '=', 'incentive');
                })
                ->where('progress.delivery_boy_id', $id)
                ->select([
                    'tc.id as credit_id',
                    't.id as transaction_id',
                    't.amount as transaction_amount',
                    't.message',
                    't.settled_at',
                    't.bank_acc_number',
                    't.created_at as transaction_created_at',
                    'tc.incentive_amount',
                    'tc.credited_at',
                    'tier.id as tier_id',
                    'tier.tier_name',
                    'tier.earnings_target',
                    'tier.order_number',
                    'offer.id as offer_id',
                    'offer.name as offer_name',
                    'offer.description as offer_description',
                    'offer.start_date as offer_start_date',
                    'offer.end_date as offer_end_date'
                ])
                ->orderBy('tc.credited_at', 'DESC')
                ->get();

            // Format the response
            $incentives = $incentiveCredits->map(function ($credit) {
                return [
                    'id' => $credit->credit_id,
                    'transaction_id' => $credit->transaction_id,
                    'offer_id' => $credit->offer_id,
                    'offer_name' => $credit->offer_name,
                    'tier_id' => $credit->tier_id,
                    'tier_name' => $credit->tier_name,
                    'earnings_target' => (float) $credit->earnings_target,
                    'incentive_amount' => (float) $credit->incentive_amount,
                    'credited_at' => $credit->credited_at,
                    'settled_at' => $credit->settled_at,
                    'bank_acc_number' => $credit->bank_acc_number,
                    'message' => $credit->message
                ];
            });

            // Calculate summary
            $totalIncentiveEarned = $incentives->sum('incentive_amount');
            $settledAmount = $incentives->filter(fn($i) => !empty($i['settled_at']))->sum('incentive_amount');
            $pendingAmount = $incentives->filter(fn($i) => empty($i['settled_at']))->sum('incentive_amount');

            return CommonHelper::responseWithData([
                'incentives' => $incentives,
                'total_count' => $incentives->count(),
                'total_incentive_earned' => $totalIncentiveEarned,
                'settled_amount' => $settledAmount,
                'pending_amount' => $pendingAmount
            ]);

        } catch (Exception $e) {
            Log::error("Get Delivery Boy Incentives Error: ", [
                'id' => $id,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch delivery boy incentives.");
        }
    }

    /**
     * Get eligibility status with detailed breakdown
     */
    private function getEligibilityStatus($progress, $offer)
    {
        $issues = [];

        if ($progress->gigs_completed < $offer->min_gigs_required) {
            $remaining = $offer->min_gigs_required - $progress->gigs_completed;
            $issues[] = "Complete {$remaining} more gig(s) (required: {$offer->min_gigs_required})";
        }

        if ($progress->gigs_skipped > $offer->max_gigs_skip) {
            $issues[] = "Too many gigs skipped ({$progress->gigs_skipped}/{$offer->max_gigs_skip} allowed)";
        }

        if ($progress->orders_cancelled > $offer->max_orders_cancel) {
            $issues[] = "Too many orders cancelled ({$progress->orders_cancelled}/{$offer->max_orders_cancel} allowed)";
        }

        if ($offer->login_mandatory && !$progress->login_compliance) {
            $issues[] = "Login compliance not met";
        }

        if (empty($issues)) {
            return [
                'is_eligible' => true,
                'message' => 'Eligible for this offer!',
                'issues' => []
            ];
        }

        return [
            'is_eligible' => false,
            'message' => 'Complete the requirements to become eligible',
            'issues' => $issues
        ];
    }

    /**
     * Get weekly transactions for a delivery boy
     */
    public function getWeeklyTransactions($id, Request $request)
    {
        try {
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError("Invalid delivery boy ID.");
            }

            $deliveryBoy = DeliveryBoy::find($id);

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            // Get week offset (0 = current week, -1 = last week, etc.)
            $weekOffset = $request->input('week_offset', 0);
            $page = $request->input('page', 1);
            $perPage = $request->input('per_page', 15);

            // Calculate week start and end dates
            $now = Carbon::now();
            $weekStart = $now->copy()->addWeeks($weekOffset)->startOfWeek();
            $weekEnd = $now->copy()->addWeeks($weekOffset)->endOfWeek();

            // Get all transactions for this week (non-hand cash, excluding incentives)
            // Incentives are excluded as they have their own dedicated tab
            $allTransactions = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $id)
                ->where('is_hand_cash', 0)
                ->where('type', '!=', 'incentive')
                ->whereBetween('transaction_date', [$weekStart, $weekEnd])
                ->orderBy('transaction_date', 'DESC')
                ->orderBy('created_at', 'DESC')
                ->get();

            // Calculate summary
            $ordersCount = $allTransactions->count();
            
            // Paid amount (settled transactions only, no incentives)
            $paidAmount = $allTransactions->where('settled_with_admin', 1)
                ->sum('driver_earnings');

            // Need to pay (unsettled transactions)
            $needToPay = $allTransactions->where('settled_with_admin', 0)
                ->sum('driver_earnings');

            // Paginate transactions
            $total = $allTransactions->count();
            $offset = ($page - 1) * $perPage;
            $paginatedTransactions = $allTransactions->slice($offset, $perPage)->values();

            // Get unpaid transactions for the modal
            $unpaidTransactions = $allTransactions->where('settled_with_admin', 0)
                ->values();

            return response()->json([
                'success' => true,
                'data' => [
                    'orders_count' => $ordersCount,
                    'paid_amount' => $paidAmount ?? 0,
                    'need_to_pay' => $needToPay ?? 0,
                    'week_start' => $weekStart->toDateString(),
                    'week_end' => $weekEnd->toDateString()
                ],
                'transactions' => [
                    'data' => $paginatedTransactions,
                    'total' => $total,
                    'per_page' => $perPage,
                    'current_page' => $page,
                    'last_page' => ceil($total / $perPage)
                ],
                'unpaid_transactions' => $unpaidTransactions
            ]);

        } catch (Exception $e) {
            Log::error("Get Delivery Boy Weekly Transactions Error: ", [
                'id' => $id,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch weekly transactions.");
        }
    }

    /**
     * Get driver payment status - returns blocking reasons if driver cannot accept orders
     * Checks for unsettled transactions with admin and pending cash deposits
     */
    public function getDriverPaymentStatus(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError("Unauthorized access.");
            }

            // Get the delivery boy associated with this user
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            $deliveryBoyId = $deliveryBoy->id;

            // Get unsettled transactions (settled_with_admin = 0)
            $unsettledTransactions = DB::table('delivery_boy_transactions')
                ->where('status', 'success')
                ->where('settled_with_admin', false)
                ->where('admin_cash', '>', 0)
                ->where('payout_reference', null)
                ->get();

            $totalAdminCash = $unsettledTransactions->sum('admin_cash');
            $isBlocked = false;
            $blockingReasons = [];
            $responseType = 'PAYMENT_AVAILABLE'; // Default type
            $requiredAction = null;

            // Check if there are unsettled transactions
            if ($unsettledTransactions->count() > 0) {
                $isBlocked = true;
                $responseType = 'ADMIN_CASH_PENDING';

                // Add blocking reason with app routing links
                $blockingReasons[] = [
                    'type' => 'ADMIN_CASH_DEPOSIT',
                    'title' => 'Pending Cash Deposit to Zenfoo',
                    'message' => "You have ₹" . number_format($totalAdminCash, 2) . " in admin cash that needs to be deposited to Zenfoo to continue accepting orders.",
                    'amount' => $totalAdminCash,
                    'transaction_count' => $unsettledTransactions->count(),
                    'action' => 'DEPOSIT_CASH',
                    'app_link' => 'zenfoo://payment/deposit_cash',
                    'app_url' => url('app/payment/deposit_cash'),
                    'screen' => 'payment_deposit_screen'
                ];

                $requiredAction = [
                    'type' => 'DEPOSIT_CASH',
                    'title' => 'Deposit Cash to Zenfoo',
                    'description' => 'Please deposit the admin cash collected from orders to Zenfoo to resume accepting orders',
                    'amount' => $totalAdminCash,
                    'transaction_count' => $unsettledTransactions->count(),
                    'app_link' => 'zenfoo://payment/deposit_cash',
                    'app_url' => url('app/payment/deposit_cash'),
                    'screen' => 'payment_deposit_screen'
                ];
            }

            return CommonHelper::responseWithData([
                'is_blocked' => $isBlocked,
                'can_accept_orders' => !$isBlocked,
                'response_type' => $responseType,
                'blocking_reasons' => $blockingReasons,
                'required_action' => $requiredAction,
                'payment_summary' => [
                    'unsettled_admin_cash' => $totalAdminCash,
                    'unsettled_transaction_count' => $unsettledTransactions->count(),
                    'total_settled_amount' => DB::table('delivery_boy_transactions')
                        ->where('status', 'success')
                        ->where('settled_with_admin', true)
                        ->where('admin_cash', '>', 0)
                        ->where('payout_reference', '!=', null)
                        ->sum('admin_cash') ?? 0
                ]
            ]);

        } catch (Exception $e) {
            Log::error("Get Driver Payment Status Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch payment status.");
        }
    }

    /**
     * Get emergency contacts configured by admin
     * Returns Zenfoo support, Police, Ambulance contact details along with driver info
     */
    public function getEmergencyContacts(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError("Unauthorized access.");
            }

            // Get the delivery boy associated with this user
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            // Get emergency contacts from settings
            $zenfooPhone = Setting::get_value('emergency_zenfoo_phone') ?? '';
            $zenfooEmail = Setting::get_value('emergency_zenfoo_email') ?? '';
            $policePhone = Setting::get_value('emergency_police_phone') ?? '';
            $ambulancePhone = Setting::get_value('emergency_ambulance_phone') ?? '';

            // Build emergency contacts response
            $emergencyContacts = [
                [
                    'id' => 'zenfoo',
                    'name' => 'Zenfoo Support',
                    'type' => 'support',
                    'phone' => $zenfooPhone,
                    'email' => $zenfooEmail,
                    'icon' => 'support',
                    'description' => 'Contact Zenfoo support team for assistance',
                    'action_type' => 'CONTACT_SUPPORT',
                    'is_active' => !empty($zenfooPhone) || !empty($zenfooEmail)
                ],
                [
                    'id' => 'police',
                    'name' => 'Police',
                    'type' => 'emergency',
                    'phone' => $policePhone,
                    'icon' => 'police',
                    'description' => 'Emergency police assistance',
                    'action_type' => 'CALL_EMERGENCY',
                    'is_active' => !empty($policePhone)
                ],
                [
                    'id' => 'ambulance',
                    'name' => 'Ambulance',
                    'type' => 'emergency',
                    'phone' => $ambulancePhone,
                    'icon' => 'ambulance',
                    'description' => 'Emergency medical assistance',
                    'action_type' => 'CALL_EMERGENCY',
                    'is_active' => !empty($ambulancePhone)
                ]
            ];

            // Filter out inactive contacts (those without phone/email)
            $activeContacts = array_filter($emergencyContacts, function ($contact) {
                return $contact['is_active'];
            });

            // Get driver info
            $driverInfo = [
                'id' => $deliveryBoy->id,
                'name' => $deliveryBoy->name,
                'email' => $user->email ?? '',
                'phone' => $deliveryBoy->phone_number ?? '',
                'admin_id' => $user->id
            ];

            // Get seller contact info from store locations (sellers the driver delivers for)
            $sellers = [];
            if ($deliveryBoy->storeLocations()->count() > 0) {
                $storeLocations = $deliveryBoy->storeLocations()->with('seller')->get();
                foreach ($storeLocations as $storeLocation) {
                    if ($storeLocation->seller) {
                        $sellers[] = [
                            'id' => $storeLocation->seller->id,
                            'name' => $storeLocation->seller->shop_name ?? $storeLocation->seller->name ?? 'Unknown Seller',
                            'phone' => $storeLocation->seller->mobile_number ?? '',
                            'email' => $storeLocation->seller->email ?? '',
                            'type' => 'seller',
                            'icon' => 'store',
                            'description' => 'Contact seller for order-related queries',
                            'action_type' => 'CONTACT_SELLER'
                        ];
                    }
                }
            }

            return CommonHelper::responseWithData([
                'driver_info' => $driverInfo,
                'emergency_contacts' => array_values($activeContacts),
                'seller_contacts' => array_values($sellers),
                'total_emergency_contacts' => count($activeContacts),
                'total_sellers' => count($sellers),
                'last_updated' => now()->toIso8601String()
            ]);

        } catch (Exception $e) {
            Log::error("Get Emergency Contacts Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch emergency contacts.");
        }
    }

    /**
     * Get driver's transactions by week
     * For authenticated drivers to view their transactions filtered by week
     * Week parameter: 1 = current week, 2 = last week, 3 = 2 weeks ago, 4 = 3 weeks ago
     * Type parameter: payout (default), incentive, multi_order
     */
    public function getDriverTransactionsByWeek(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError("Unauthorized access.");
            }

            // Get the delivery boy associated with this user
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            // Check if week parameter is provided
            $week = $request->input('week');

            // If week is not provided, return list of 10 weeks
            if (!$week) {
                $weeks = [];
                for ($i = 1; $i <= 10; $i++) {
                    $weeksAgo = $i - 1;
                    $weekStart = Carbon::now()->subWeeks($weeksAgo)->startOfWeek();
                    $weekEnd = Carbon::now()->subWeeks($weeksAgo)->endOfWeek();

                    $weeks[] = [
                        'id' => $i,
                        'label' => $weekStart->format('d M') . ' - ' . $weekEnd->format('d M Y'),
                    ];
                }

                return CommonHelper::responseWithData([
                    'weeks' => $weeks,
                    'delivery_boy' => [
                        'id' => $deliveryBoy->id,
                        'name' => $deliveryBoy->name
                    ]
                ]);
            }

            // Validate request parameters when week is provided
            $validator = Validator::make($request->all(), [
                'week' => 'integer|min:1|max:10',
                'type' => 'nullable|in:payout,incentive,multi_order'
            ], [
                'week.integer' => 'Week must be a number.',
                'week.min' => 'Week must be between 1 and 10.',
                'week.max' => 'Week must be between 1 and 10.',
                'type.in' => 'Type must be one of: payout, incentive, multi_order.'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $type = $request->input('type', 'payout'); // Default to payout

            // Calculate the week start and end dates
            // Week 1 = current week, Week 2 = last week, Week 3 = 2 weeks ago, etc.
            $weeksAgo = $week - 1; // Convert to weeks offset

            $weekStart = Carbon::now()->subWeeks($weeksAgo)->startOfWeek();
            $weekEnd = Carbon::now()->subWeeks($weeksAgo)->endOfWeek();

            $totalTransactions = 0;
            $totalDriverEarnings = 0;
            $bankAccounts = [];
            $transactionDetails = [];

            // Handle different types
            switch ($type) {
                case 'incentive':
                    // Get incentive transactions
                    $transactions = DB::table('delivery_boy_transactions')
                        ->where('delivery_boy_id', $deliveryBoy->id)
                        ->where('type', 'incentive')
                        ->whereNotNull('settled_at')
                        ->whereBetween('settled_at', [$weekStart, $weekEnd])
                        ->orderBy('settled_at', 'DESC')
                        ->get();

                    $totalTransactions = $transactions->count();
                    $totalDriverEarnings = $transactions->sum('amount'); // Use amount column for incentives

                    // Get unique bank account numbers
                    $bankAccounts = $transactions
                        ->pluck('bank_acc_number')
                        ->filter()
                        ->unique()
                        ->values()
                        ->toArray();

                    // Get full transaction details
                    $transactionDetails = $transactions->map(function ($transaction) {
                        return [
                            'id' => $transaction->id,
                            'order_id' => $transaction->order_id,
                            'amount' => $transaction->amount,
                            'type' => $transaction->type,
                            'message' => $transaction->message,
                            'bank_acc_number' => $transaction->bank_acc_number,
                            'settled_at' => $transaction->settled_at,
                            'created_at' => $transaction->created_at,
                        ];
                    })->values()->toArray();
                    break;

                case 'multi_order':
                    // Get multi-order bonus from orders table
                    $orders = DB::table('orders')
                        ->where('delivery_boy_id', $deliveryBoy->id)
                        ->where('delivery_boy_bonus_amount', '>', 0)
                        ->whereNotNull('delivery_boy_bonus_amount')
                        ->whereBetween('updated_at', [$weekStart, $weekEnd])
                        ->orderBy('updated_at', 'DESC')
                        ->get();

                    $totalTransactions = $orders->count();
                    $totalDriverEarnings = $orders->sum('delivery_boy_bonus_amount');

                    // For multi-order, get bank accounts from delivery boy's documents
                    $deliveryBoyDocument = DB::table('delivery_boy_documents')
                        ->where('delivery_boy_id', $deliveryBoy->id)
                        ->first();

                    if ($deliveryBoyDocument && !empty($deliveryBoyDocument->account_number)) {
                        $bankAccounts = [$deliveryBoyDocument->account_number];
                    }

                    // Get full order details for multi-order bonus
                    $transactionDetails = $orders->map(function ($order) {
                        return [
                            'id' => $order->id,
                            'order_id' => $order->id,
                            'amount' => $order->delivery_boy_bonus_amount,
                            'type' => 'multi_order',
                            'description' => 'Multi-order bonus',
                            'order_status' => $order->order_status ?? null,
                            'updated_at' => $order->updated_at,
                            'created_at' => $order->created_at,
                        ];
                    })->values()->toArray();
                    break;

                case 'payout':
                default:
                    // Normal payout flow (existing logic) - exclude incentive type
                    $transactions = DB::table('delivery_boy_transactions')
                        ->where('delivery_boy_id', $deliveryBoy->id)
                        ->where('is_hand_cash', 0)
                        ->where('type', '!=', 'incentive')
                        ->whereNotNull('settled_at')
                        ->whereBetween('settled_at', [$weekStart, $weekEnd])
                        ->orderBy('settled_at', 'DESC')
                        ->get();

                    $totalTransactions = $transactions->count();
                    $totalDriverEarnings = $transactions->sum('driver_earnings');

                    // Get unique bank account numbers
                    $bankAccounts = $transactions
                        ->pluck('bank_acc_number')
                        ->filter()
                        ->unique()
                        ->values()
                        ->toArray();

                    // Get full transaction details
                    $transactionDetails = $transactions->map(function ($transaction) {
                        return [
                            'id' => $transaction->id,
                            'order_id' => $transaction->order_id,
                            'driver_earnings' => $transaction->driver_earnings,
                            'amount' => $transaction->amount,
                            'type' => $transaction->type,
                            'message' => $transaction->message,
                            'bank_acc_number' => $transaction->bank_acc_number,
                            'settled_at' => $transaction->settled_at,
                            'created_at' => $transaction->created_at,
                        ];
                    })->values()->toArray();
                    break;
            }

            return CommonHelper::responseWithData([
                'week' => $week,
                'type' => $type,
                'week_start' => $weekStart->toDateString(),
                'week_end' => $weekEnd->toDateString(),
                'week_label' => $this->getWeekLabel($week),
                'summary' => [
                    'total_transactions' => $totalTransactions,
                    'payment_mode' => 'Bank',
                    'paid_bank_number' => $bankAccounts,
                    'total_driver_earnings' => $totalDriverEarnings ?? 0,
                    'transactions' => $transactionDetails
                ],
                'delivery_boy' => [
                    'id' => $deliveryBoy->id,
                    'name' => $deliveryBoy->name
                ]
            ]);

        } catch (Exception $e) {
            Log::error("Get Driver Transactions By Week Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch transactions.");
        }
    }

    /**
     * Get week label based on week number
     */
    private function getWeekLabel($week)
    {
        switch ($week) {
            case 1:
                return 'Current Week';
            case 2:
                return 'Last Week';
            case 3:
                return '2 Weeks Ago';
            case 4:
                return '3 Weeks Ago';
            default:
                return 'Week ' . $week;
        }
    }

    /**
     * Submit a driver issue to Zenfoo
     * Allows drivers to report issues like incorrect_payout, incentive, multi_order, joining_bonus
     */
    public function submitDriverIssue(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return CommonHelper::responseError("Unauthorized access.");
            }

            // Get the delivery boy associated with this user
            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();

            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            // Validate request
            $validator = Validator::make($request->all(), [
                'issue_type' => 'required|in:incorrect_payout,incentive,multi_order,joining_bonus,order_earning,pocketing_issue,not_getting_order_issue,extra_floating_deposited,cash_deposit_issue',
                'issue_ids' => 'nullable|array',
                'issue_ids.*' => 'integer',
                'description' => 'nullable|string|max:5000',
                'attachments' => 'nullable|array|max:5',
                'attachments.*' => 'image|mimes:jpeg,jpg,png,gif,webp|max:5120',
                'amount' => 'nullable|required_if:issue_type,extra_floating_deposited|numeric|min:0',
                'pay_type' => 'nullable|required_if:issue_type,extra_floating_deposited|required_if:issue_type,cash_deposit_issue|in:upi,bank'
            ], [
                'issue_type.required' => 'Issue type is required.',
                'issue_type.in' => 'Invalid issue type. Must be one of: incorrect_payout, incentive, multi_order, joining_bonus, order_earning, pocketing_issue, not_getting_order_issue, extra_floating_deposited, cash_deposit_issue.',
                'description.max' => 'Description must not exceed 5000 characters.',
                'attachments.max' => 'You can upload a maximum of 5 attachments.',
                'attachments.*.image' => 'All attachments must be images.',
                'attachments.*.mimes' => 'Images must be in jpeg, jpg, png, gif, or webp format.',
                'attachments.*.max' => 'Each image must not exceed 5MB.',
                'amount.required_if' => 'Amount is required for extra floating deposited issues.',
                'amount.numeric' => 'Amount must be a number.',
                'amount.min' => 'Amount must be a positive value.',
                'pay_type.required_if' => 'Payment type is required.',
                'pay_type.in' => 'Payment type must be either upi or bank.'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            DB::beginTransaction();

            try {
                // Handle attachment uploads
                $attachmentUrls = [];
                if ($request->hasFile('attachments')) {
                    foreach ($request->file('attachments') as $attachment) {
                        $url = MediaUploadService::upload(
                            $attachment,
                            'driver_issues/attachments'
                        );
                        $attachmentUrls[] = $url;
                    }
                }

                // Create the issue
                $issueId = DB::table('driver_issues_zenfoo')->insertGetId([
                    'driver_id' => $deliveryBoy->id,
                    'issue_type' => $request->issue_type,
                    'issue_ids' => $request->has('issue_ids') ? json_encode($request->issue_ids) : null,
                    'description' => $request->description,
                    'attachments' => !empty($attachmentUrls) ? json_encode($attachmentUrls) : null,
                    'amount' => $request->amount,
                    'pay_type' => $request->pay_type,
                    'status' => 'pending',
                    'created_at' => now(),
                    'updated_at' => now()
                ]);

                DB::commit();

                // Send notification to admin
                AdminNotificationService::notifyDriverCreatedIssue(
                    $issueId,
                    $deliveryBoy->id,
                    $deliveryBoy->name,
                    $request->issue_type
                );

                Log::info('Driver Issue Submitted Successfully', [
                    'driver_id' => $deliveryBoy->id,
                    'issue_id' => $issueId,
                    'issue_type' => $request->issue_type,
                    'description' => $request->description
                ]);

                return CommonHelper::responseSuccess("Issue submitted successfully. Our team will review it soon.");

            } catch (Exception $e) {
                DB::rollBack();
                Log::error("Submit Driver Issue Database Error: ", [
                    'driver_id' => $deliveryBoy->id,
                    'message' => $e->getMessage(),
                    'trace' => $e->getTraceAsString()
                ]);
                return CommonHelper::responseError("Failed to submit issue. Please try again.");
            }

        } catch (Exception $e) {
            Log::error("Submit Driver Issue Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to submit issue. Please try again.");
        }
    }

    /**
     * Get driver's submitted issues with filters and pagination
     *
     * GET /api/delivery-boy/issues
     * Query params: filter (daily|weekly|monthly), issue_type, status, offset, limit
     */
    public function getDriverIssues(Request $request)
    {
        try {
            $user = Auth::user();
            if (!$user) {
                return CommonHelper::responseError("Unauthorized access.");
            }

            $deliveryBoy = DeliveryBoy::where('admin_id', $user->id)->first();
            if (!$deliveryBoy) {
                return CommonHelper::responseError("Delivery Boy not found!");
            }

            $filter = $request->input('filter'); // daily, weekly, monthly
            $offset = (int) $request->input('offset', 0);
            $limit = (int) $request->input('limit', 10);

            $query = DriverIssueZenfoo::where('driver_id', $deliveryBoy->id);

            // Period filter
            if ($filter === 'daily') {
                $query->whereDate('created_at', Carbon::today());
            } elseif ($filter === 'weekly') {
                $query->whereBetween('created_at', [
                    Carbon::now()->startOfWeek(),
                    Carbon::now()->endOfWeek()
                ]);
            } elseif ($filter === 'monthly') {
                $query->whereBetween('created_at', [
                    Carbon::now()->startOfMonth(),
                    Carbon::now()->endOfMonth()
                ]);
            }

            // Filter by issue_type
            if ($request->filled('issue_type')) {
                $query->where('issue_type', $request->issue_type);
            }

            // Filter by status
            if ($request->filled('status')) {
                $query->where('status', $request->status);
            }

            $total = $query->count();

            $issues = $query->orderBy('created_at', 'desc')
                ->skip($offset)
                ->take($limit)
                ->get()
                ->map(function ($issue) {
                    return [
                        'id' => $issue->id,
                        'issue_type' => $issue->issue_type,
                        'issue_ids' => $issue->issue_ids,
                        'description' => $issue->description,
                        'attachments' => $issue->attachments ? collect($issue->attachments)->map(function ($path) {
                            return str_starts_with($path, 'http') ? $path : asset('storage/' . $path);
                        })->values() : [],
                        'amount' => $issue->amount ? (float) $issue->amount : null,
                        'pay_type' => $issue->pay_type,
                        'status' => $issue->status,
                        'admin_message' => $issue->admin_message,
                        'created_at' => $issue->created_at->toIso8601String(),
                        'updated_at' => $issue->updated_at->toIso8601String(),
                    ];
                });

            return response()->json([
                'status' => true,
                'message' => 'Issues retrieved successfully',
                'data' => [
                    'filter' => $filter ?? 'all',
                    'issues' => $issues,
                    'pagination' => [
                        'total' => $total,
                        'offset' => $offset,
                        'limit' => $limit,
                        'has_more' => ($offset + $limit) < $total
                    ]
                ]
            ]);

        } catch (Exception $e) {
            Log::error("Get Driver Issues Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch issues. Please try again.");
        }
    }

    /**
     * Get "Not Getting Orders" help screen data
     * Returns video URL, title, and steps for the Flutter app
     */
    public function getNotGettingOrdersHelp(Request $request)
    {
        try {
            // Get settings from database
            $video = Setting::get_value('not_getting_orders_video') ?? '';
            $title = Setting::get_value('not_getting_orders_title') ?? 'If you\'re not getting orders, you should follow these steps';
            $stepsJson = Setting::get_value('not_getting_orders_steps') ?? '';

            // Parse steps JSON or use default
            $steps = [];
            if (!empty($stepsJson)) {
                $steps = json_decode($stepsJson, true) ?? [];
            }

            // Default steps if not configured
            if (empty($steps)) {
                $steps = [
                    [
                        'step_number' => 1,
                        'title' => 'Make sure you\'re in the right zone'
                    ],
                    [
                        'step_number' => 2,
                        'title' => 'Start your duty and stay online'
                    ],
                    [
                        'step_number' => 3,
                        'title' => 'Move closer to high-demand food stores and zenfoo stores'
                    ]
                ];
            }

            return CommonHelper::responseWithData([
                'video_url' => $video,
                'title' => $title,
                'steps' => $steps
            ]);

        } catch (Exception $e) {
            Log::error("Get Not Getting Orders Help Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch help data.");
        }
    }

    /**
     * Save "Not Getting Orders" help screen data
     * For admin/postman to update the settings
     */
    public function saveNotGettingOrdersHelp(Request $request)
    {
        try {
            // Validate request
            $validator = Validator::make($request->all(), [
                'video' => 'nullable|mimes:mp4,webm,ogg,avi,mov|max:102400', // 100MB max
                'title' => 'nullable|string|max:500',
                'steps' => 'nullable|array',
                'steps.*.step_number' => 'required_with:steps|integer',
                'steps.*.title' => 'required_with:steps|string|max:500'
            ], [
                'video.mimes' => 'Video must be in mp4, webm, ogg, avi, or mov format.',
                'video.max' => 'Video must not exceed 100MB.'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            DB::beginTransaction();

            try {
                // Handle video upload using MediaUploadService
                if ($request->hasFile('video')) {
                    // Get old video URL to delete
                    $oldVideo = Setting::get_value('not_getting_orders_video');

                    // Upload new video and get full URL
                    $videoUrl = MediaUploadService::upload(
                        $request->file('video'),
                        'not_getting_orders',
                        'public',
                        $oldVideo ?: null
                    );

                    $this->upsertSetting('not_getting_orders_video', $videoUrl);
                }

                // Save title
                if ($request->has('title')) {
                    $this->upsertSetting('not_getting_orders_title', $request->title ?? '');
                }

                // Save steps as JSON
                if ($request->has('steps')) {
                    $this->upsertSetting('not_getting_orders_steps', json_encode($request->steps ?? []));
                }

                DB::commit();

                return CommonHelper::responseSuccess("Not getting orders help data saved successfully.");

            } catch (Exception $e) {
                DB::rollBack();
                Log::error("Save Not Getting Orders Help Database Error: ", [
                    'message' => $e->getMessage(),
                    'trace' => $e->getTraceAsString()
                ]);
                return CommonHelper::responseError("Failed to save help data.");
            }

        } catch (Exception $e) {
            Log::error("Save Not Getting Orders Help Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to save help data.");
        }
    }

    /**
     * Helper method to insert or update a setting
     */
    private function upsertSetting($variable, $value)
    {
        $setting = Setting::where('variable', $variable)->first();
        if ($setting) {
            $setting->value = $value;
            $setting->save();
        } else {
            Setting::create([
                'variable' => $variable,
                'value' => $value
            ]);
        }
    }

    public function getRatings(Request $request, $id)
    {
        $deliveryBoy = DeliveryBoy::find($id);

        if (!$deliveryBoy) {
            return CommonHelper::responseError('Delivery boy not found');
        }

        $page = (int) $request->input('page', 1);
        $perPage = (int) $request->input('per_page', 10);

        $result = OrderRatingService::getDriverRatings($deliveryBoy->id, $page, $perPage);

        if (!$result['success']) {
            return CommonHelper::responseError($result['message']);
        }

        return CommonHelper::responseWithData($result['data']);
    }

    /**
     * Get all delivery boys with pending payouts (Admin view)
     * Includes hand cash, incentives, and referral bonuses
     */
    public function getAllPendingPayouts(Request $request)
    {
        try {
            $search = $request->input('search', '');
            $cityId = $request->input('city_id');
            $page = $request->input('page', 1);
            $perPage = $request->input('per_page', 20);

            // Base query for delivery boys
            $query = DeliveryBoy::with(['city', 'documents'])
                ->where('status', 1); // Only active delivery boys

            // Apply search filter
            if ($search) {
                $query->where(function($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('mobile', 'like', "%{$search}%")
                      ->orWhere('email', 'like', "%{$search}%");
                });
            }

            // Apply city/zone filter
            if ($cityId) {
                $query->where('city_id', $cityId);
            }

            // Get all delivery boys matching filters
            $deliveryBoys = $query->get();

            Log::info("Pending Payouts - Initial Query", [
                'total_active_delivery_boys_fetched' => $deliveryBoys->count(),
                'filters' => [
                    'search' => $search ?: 'none',
                    'city_id' => $cityId ?: 'all cities'
                ]
            ]);

            // Calculate pending amounts for each delivery boy
            $pendingPayoutsData = [];

            foreach ($deliveryBoys as $deliveryBoy) {
                // 1. Get unsettled base transactions (driver earnings) - excluding incentives and referral bonuses
                $basePendingAmount = DB::table('delivery_boy_transactions')
                    ->where('delivery_boy_id', $deliveryBoy->id)
                    ->where('is_hand_cash', 0)
                    ->where('type', '!=', 'incentive')
                    ->where('type', '!=', 'referral_bonus')
                    ->where('settled_with_admin', 0)
                    ->sum('driver_earnings');

                // 2. Get hand cash to deduct
                $handCashAmount = DB::table('delivery_boy_transactions')
                    ->where('delivery_boy_id', $deliveryBoy->id)
                    ->where('is_hand_cash', 1)
                    ->where('settled_with_admin', 0)
                    ->sum('admin_cash');

                // 3. Get pending incentives to add
                $incentiveAmount = DB::table('delivery_boy_transactions')
                    ->where('delivery_boy_id', $deliveryBoy->id)
                    ->where('type', 'incentive')
                    ->where('settled_with_admin', 0)
                    ->sum('amount');

                // 4. Get referral bonuses from transactions table (already paid bonuses)
                $referralAmount = DB::table('delivery_boy_transactions')
                    ->where('delivery_boy_id', $deliveryBoy->id)
                    ->where('type', 'referral_bonus')
                    ->where('settled_with_admin', 0)
                    ->sum('driver_earnings');

                // Calculate total pending amount (base - hand_cash + incentives + referrals)
                $totalPendingAmount = $basePendingAmount - $handCashAmount + $incentiveAmount + $referralAmount;

                Log::info("Delivery Boy #{$deliveryBoy->id} Payout Calculation", [
                    'name' => $deliveryBoy->name,
                    'base_pending_amount' => $basePendingAmount,
                    'hand_cash_amount' => $handCashAmount,
                    'incentive_amount' => $incentiveAmount,
                    'referral_amount' => $referralAmount,
                    'total_pending_amount' => $totalPendingAmount,
                    'will_include' => ($totalPendingAmount > 0 || $basePendingAmount > 0) ? 'YES' : 'NO'
                ]);

                // Only include if there's something to pay
                if ($totalPendingAmount > 0 || $basePendingAmount > 0) {
                    // Count transactions
                    $transactionCount = DB::table('delivery_boy_transactions')
                        ->where('delivery_boy_id', $deliveryBoy->id)
                        ->where('is_hand_cash', 0)
                        ->where('type', '!=', 'incentive')
                        ->where('settled_with_admin', 0)
                        ->count();

                    $pendingPayoutsData[] = [
                        'delivery_boy_id' => $deliveryBoy->id,
                        'name' => $deliveryBoy->name,
                        'phone' => $deliveryBoy->phone,
                        'email' => $deliveryBoy->email,
                        'profile_image_url' => $deliveryBoy->profile_image ? (str_starts_with($deliveryBoy->profile_image, 'http') ? $deliveryBoy->profile_image : asset('storage/' . $deliveryBoy->profile_image)) : null,
                        'city_name' => $deliveryBoy->city->name ?? 'N/A',
                        'city_id' => $deliveryBoy->city_id,
                        'base_pending_amount' => (float) $basePendingAmount,
                        'hand_cash_amount' => (float) $handCashAmount,
                        'incentive_amount' => (float) $incentiveAmount,
                        'referral_amount' => (float) $referralAmount,
                        'total_pending_amount' => (float) max(0, $totalPendingAmount),
                        'transaction_count' => (int) $transactionCount,
                        'has_bank_details' => $deliveryBoy->documents &&
                                             !empty($deliveryBoy->documents->bank_name) &&
                                             !empty($deliveryBoy->documents->account_number)
                    ];
                }
            }

            // Sort by total pending amount descending
            usort($pendingPayoutsData, function($a, $b) {
                return $b['total_pending_amount'] <=> $a['total_pending_amount'];
            });

            // Paginate manually
            $total = count($pendingPayoutsData);
            $offset = ($page - 1) * $perPage;
            $paginatedData = array_slice($pendingPayoutsData, $offset, $perPage);

            // Calculate summary stats
            $totalBasePending = array_sum(array_column($pendingPayoutsData, 'base_pending_amount'));
            $totalHandCash = array_sum(array_column($pendingPayoutsData, 'hand_cash_amount'));
            $totalIncentives = array_sum(array_column($pendingPayoutsData, 'incentive_amount'));
            $totalReferrals = array_sum(array_column($pendingPayoutsData, 'referral_amount'));
            $totalPending = array_sum(array_column($pendingPayoutsData, 'total_pending_amount'));

            Log::info("Pending Payouts API Final Summary", [
                'total_delivery_boys_matched' => count($pendingPayoutsData),
                'filters' => [
                    'search' => $search,
                    'city_id' => $cityId
                ],
                'summary' => [
                    'total_base_pending' => $totalBasePending,
                    'total_hand_cash' => $totalHandCash,
                    'total_incentives' => $totalIncentives,
                    'total_referrals' => $totalReferrals,
                    'total_pending' => $totalPending
                ]
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Pending payouts retrieved successfully',
                'data' => [
                    'delivery_boys' => $paginatedData,
                    'summary' => [
                        'total_delivery_boys' => $total,
                        'total_base_pending' => (float) $totalBasePending,
                        'total_hand_cash_deduction' => (float) $totalHandCash,
                        'total_incentives' => (float) $totalIncentives,
                        'total_referrals' => (float) $totalReferrals,
                        'total_pending_amount' => (float) $totalPending
                    ],
                    'pagination' => [
                        'current_page' => (int) $page,
                        'per_page' => (int) $perPage,
                        'total' => $total,
                        'last_page' => ceil($total / $perPage)
                    ]
                ]
            ]);

        } catch (Exception $e) {
            Log::error("Get All Pending Payouts Error: ", [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch pending payouts.");
        }
    }

    /**
     * Get pending referral bonuses for a delivery boy (unsettled referral_bonus transactions)
     */
    public function getPendingReferrals($id)
    {
        try {
            if (!is_numeric($id) || $id <= 0) {
                return CommonHelper::responseError("Invalid delivery boy ID.");
            }

            // Get unsettled referral bonus transactions
            $referralTransactions = DB::table('delivery_boy_transactions')
                ->where('delivery_boy_id', $id)
                ->where('type', 'referral_bonus')
                ->where('settled_with_admin', 0)
                ->select('id', 'driver_earnings as amount', 'created_at', 'message')
                ->get();

            return response()->json([
                'success' => true,
                'message' => 'Pending referrals retrieved successfully',
                'data' => $referralTransactions
            ]);

        } catch (Exception $e) {
            Log::error("Get Pending Referrals Error: ", [
                'delivery_boy_id' => $id,
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError("Failed to fetch pending referrals.");
        }
    }

}
