<?php

namespace App\Http\Controllers\API\Customer;

use App\Http\Controllers\Controller;
use App\Models\StoreLocation;
use App\Services\CityZoneService;
use Illuminate\Http\Request;

class NearestStoreController extends Controller
{
    /**
     * Find the nearest active Zenfoo store to the given lat/lon using the
     * Haversine formula. First checks if the customer falls inside any
     * city's service zone (boundary_points). If not, returns a
     * "not available in your area" message.
     */
    public function findNearest(Request $request)
    {
        $validated = $request->validate([
            'latitude'  => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ]);

        $userLat = (float) $validated['latitude'];
        $userLon = (float) $validated['longitude'];

        // Check if the customer is within any city's service zone
        $city = CityZoneService::detectCity($userLat, $userLon);

        if (!$city) {
            return response()->json([
                'status'  => false,
                'message' => 'Sorry, we are not available in your area.',
            ], 200);
        }

        // Pick the nearest active store within that city
        $stores = StoreLocation::active()->byCity($city->id)->get();

        if ($stores->isEmpty()) {
            return response()->json([
                'status'  => false,
                'message' => 'Sorry, we are not available in your area.',
            ], 200);
        }

        $nearestStore = null;
        $shortestDistance = null;

        foreach ($stores as $store) {
            $distance = $this->haversineDistance(
                $userLat,
                $userLon,
                (float) $store->latitude,
                (float) $store->longitude
            );

            if ($shortestDistance === null || $distance < $shortestDistance) {
                $shortestDistance = $distance;
                $nearestStore = $store;
            }
        }

        // Estimate travel time assuming an average city speed of 20 km/h
        // (accounts for traffic, signals, and typical urban congestion)
        $averageSpeedKmh = 20;
        $travelTimeMinutes = (int) round(($shortestDistance / $averageSpeedKmh) * 60);

        return response()->json([
            'status'  => true,
            'message' => $nearestStore->name . ' is ' . $travelTimeMinutes . ' min away from you',
            'data'    => [
                'store_id'            => $nearestStore->id,
                'store_name'          => $nearestStore->name,
                'address'             => $nearestStore->address,
                'latitude'            => (float) $nearestStore->latitude,
                'longitude'           => (float) $nearestStore->longitude,
                'distance_km'         => round($shortestDistance, 2),
                'travel_time_minutes' => $travelTimeMinutes,
                'city'                => [
                    'id'   => $city->id,
                    'name' => $city->name,
                ],
            ],
        ], 200);
    }

    /**
     * Calculate the distance between two coordinates in kilometers using
     * the Haversine formula.
     */
    private function haversineDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadiusKm = 6371;

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadiusKm * $c;
    }
}
