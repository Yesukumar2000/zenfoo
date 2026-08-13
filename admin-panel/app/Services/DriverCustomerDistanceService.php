<?php

namespace App\Services;

use App\Models\Setting;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class DriverCustomerDistanceService
{
    /**
     * Maximum allowed distance in meters for driver to be considered "arrived"
     */
    const MAX_ARRIVAL_DISTANCE_METERS = 5000000;

    /**
     * Get Google Maps API key from settings
     *
     * @return string|null
     */
    private static function getGoogleMapsApiKey(): ?string
    {
        // Try different possible setting keys
        $apiKey = Setting::get_value('google_map_api_key');

        if (empty($apiKey)) {
            $apiKey = Setting::get_value('googleMapApiKey');
        }

        if (empty($apiKey)) {
            $apiKey = Setting::get_value('google_place_api_key');
        }

        return $apiKey ?: null;
    }

    /**
     * Calculate distance using Google Maps Distance Matrix API
     *
     * @param float $lat1 - Origin latitude
     * @param float $lon1 - Origin longitude
     * @param float $lat2 - Destination latitude
     * @param float $lon2 - Destination longitude
     * @return array|null - Returns ['distance_meters' => float, 'distance_text' => string] or null on failure
     */
    public static function calculateDistanceUsingGoogleMaps(float $lat1, float $lon1, float $lat2, float $lon2): ?array
    {
        try {
            $apiKey = self::getGoogleMapsApiKey();

            if (empty($apiKey)) {
                Log::warning("DriverCustomerDistanceService: Google Maps API key not found in settings");
                return null;
            }

            $origin = "{$lat1},{$lon1}";
            $destination = "{$lat2},{$lon2}";

            $url = "https://maps.googleapis.com/maps/api/distancematrix/json";

            $response = Http::timeout(10)->get($url, [
                'origins' => $origin,
                'destinations' => $destination,
                'mode' => 'driving',
                'key' => $apiKey
            ]);

            if (!$response->successful()) {
                Log::error("DriverCustomerDistanceService: Google Maps API request failed", [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);
                return null;
            }

            $data = $response->json();

            if ($data['status'] !== 'OK') {
                Log::error("DriverCustomerDistanceService: Google Maps API returned error status", [
                    'status' => $data['status'],
                    'error_message' => $data['error_message'] ?? 'Unknown error'
                ]);
                return null;
            }

            $element = $data['rows'][0]['elements'][0] ?? null;

            if (!$element || $element['status'] !== 'OK') {
                Log::error("DriverCustomerDistanceService: Google Maps API element status not OK", [
                    'element_status' => $element['status'] ?? 'No element'
                ]);
                return null;
            }

            $distanceMeters = $element['distance']['value']; // Distance in meters
            $distanceText = $element['distance']['text']; // Human readable distance

            Log::info("DriverCustomerDistanceService: Google Maps distance calculated", [
                'origin' => $origin,
                'destination' => $destination,
                'distance_meters' => $distanceMeters,
                'distance_text' => $distanceText
            ]);

            return [
                'distance_meters' => (float) $distanceMeters,
                'distance_text' => $distanceText,
                'source' => 'google_maps'
            ];

        } catch (\Exception $e) {
            Log::error("DriverCustomerDistanceService: Google Maps API exception", [
                'error' => $e->getMessage()
            ]);
            return null;
        }
    }

    /**
     * Calculate distance between two coordinates using Haversine formula (fallback)
     *
     * @param float $lat1 - First latitude
     * @param float $lon1 - First longitude
     * @param float $lat2 - Second latitude
     * @param float $lon2 - Second longitude
     * @return float - Distance in meters
     */
    public static function calculateDistanceUsingHaversine(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371000; // Earth's radius in meters

        $latDiff = deg2rad($lat2 - $lat1);
        $lonDiff = deg2rad($lon2 - $lon1);

        $a = sin($latDiff / 2) * sin($latDiff / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($lonDiff / 2) * sin($lonDiff / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }

    /**
     * Calculate distance in meters - tries Google Maps first, falls back to Haversine
     *
     * @param float $lat1 - First latitude
     * @param float $lon1 - First longitude
     * @param float $lat2 - Second latitude
     * @param float $lon2 - Second longitude
     * @return array - Returns ['distance_meters' => float, 'source' => string]
     */
    public static function calculateDistanceInMeters(float $lat1, float $lon1, float $lat2, float $lon2): array
    {
        // Try Google Maps first
        $googleResult = self::calculateDistanceUsingGoogleMaps($lat1, $lon1, $lat2, $lon2);

        if ($googleResult !== null) {
            return [
                'distance_meters' => $googleResult['distance_meters'],
                'distance_text' => $googleResult['distance_text'],
                'source' => 'google_maps'
            ];
        }

        // Fallback to Haversine formula
        Log::info("DriverCustomerDistanceService: Falling back to Haversine formula");

        $distanceMeters = self::calculateDistanceUsingHaversine($lat1, $lon1, $lat2, $lon2);
        $distanceKm = round($distanceMeters / 1000, 2);

        return [
            'distance_meters' => $distanceMeters,
            'distance_text' => "{$distanceKm} km",
            'source' => 'haversine'
        ];
    }

    /**
     * Calculate distance in kilometers
     *
     * @param float $lat1
     * @param float $lon1
     * @param float $lat2
     * @param float $lon2
     * @return float - Distance in kilometers
     */
    public static function calculateDistanceInKm(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $result = self::calculateDistanceInMeters($lat1, $lon1, $lat2, $lon2);
        return $result['distance_meters'] / 1000;
    }

    /**
     * Check if driver is within allowed distance from customer location
     *
     * @param float $driverLat - Driver's latitude
     * @param float $driverLon - Driver's longitude
     * @param float $customerLat - Customer's latitude
     * @param float $customerLon - Customer's longitude
     * @param float|null $maxDistanceMeters - Maximum allowed distance in meters (default: 500m)
     * @return array - Result with 'allowed' boolean, 'distance_meters', and 'message'
     */
    public static function isDriverWithinRange(
        float $driverLat,
        float $driverLon,
        float $customerLat,
        float $customerLon,
        ?float $maxDistanceMeters = null
    ): array {
        $maxDistance = $maxDistanceMeters ?? self::MAX_ARRIVAL_DISTANCE_METERS;

        $distanceResult = self::calculateDistanceInMeters($driverLat, $driverLon, $customerLat, $customerLon);
        $distanceMeters = $distanceResult['distance_meters'];
        $distanceKm = round($distanceMeters / 1000, 2);
        $source = $distanceResult['source'];

        Log::info("DriverCustomerDistanceService: Distance calculated", [
            'driver_lat' => $driverLat,
            'driver_lon' => $driverLon,
            'customer_lat' => $customerLat,
            'customer_lon' => $customerLon,
            'distance_meters' => round($distanceMeters, 2),
            'max_allowed_meters' => $maxDistance,
            'calculation_source' => $source
        ]);

        if ($distanceMeters <= $maxDistance) {
            return [
                'allowed' => true,
                'distance_meters' => round($distanceMeters, 2),
                'distance_km' => $distanceKm,
                'source' => $source,
                'message' => 'Driver is within range'
            ];
        }

        return [
            'allowed' => false,
            'distance_meters' => round($distanceMeters, 2),
            'distance_km' => $distanceKm,
            'source' => $source,
            'message' => "You are {$distanceKm} km away from the customer location. Please move closer (within " . ($maxDistance / 1000) . " km) to notify the customer."
        ];
    }

    /**
     * Validate coordinates are valid
     *
     * @param float|null $lat
     * @param float|null $lon
     * @return bool
     */
    public static function areCoordinatesValid(?float $lat, ?float $lon): bool
    {
        if ($lat === null || $lon === null) {
            return false;
        }

        // Valid latitude range: -90 to 90
        // Valid longitude range: -180 to 180
        return $lat >= -90 && $lat <= 90 && $lon >= -180 && $lon <= 180;
    }
}
