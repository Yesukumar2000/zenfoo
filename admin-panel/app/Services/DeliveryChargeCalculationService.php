<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;
use App\Models\City;
use App\Services\WeatherService;

class DeliveryChargeCalculationService
{
    /**
     * Google Maps API Key Settings IDs
     */
    const SETTINGS_DEFAULT_MAP_KEY = 46;
    const SETTINGS_GOOGLE_MAP_API_KEY = 47;
    const SETTINGS_BACKUP_MAP_KEY = 48;

    /**
     * Calculate delivery charge based on seller locations and customer location
     *
     * @param array $sellerLocations Array of seller locations with lat/lon
     * @param float $customerLat Customer latitude
     * @param float $customerLon Customer longitude
     * @param int|null $cityId Optional city ID for charge calculation
     * @param float $subTotal Optional subtotal for free delivery check
     * @return array
     */
    public static function calculateDeliveryCharge(
        array $sellerLocations,
        float $customerLat,
        float $customerLon,
        ?int $cityId = null,
        float $subTotal = 0
    ): array {
        try {
            $totalDistance = 0;
            $totalDuration = 0;
            $distanceDetails = [];
            $method = 'google_maps';

            // Calculate distance from each seller location to customer
            foreach ($sellerLocations as $index => $sellerLocation) {
                $sellerLat = floatval($sellerLocation['lat'] ?? $sellerLocation['latitude'] ?? 0);
                $sellerLon = floatval($sellerLocation['lon'] ?? $sellerLocation['lng'] ?? $sellerLocation['longitude'] ?? 0);

                if ($sellerLat == 0 || $sellerLon == 0) {
                    Log::warning('DeliveryChargeCalculationService: Invalid seller location', [
                        'index' => $index,
                        'location' => $sellerLocation
                    ]);
                    continue;
                }

                // Try Google Maps first
                $result = self::getDistanceWithGoogleMaps($sellerLat, $sellerLon, $customerLat, $customerLon);

                // Fallback to Haversine if Google Maps fails
                if ($result === null) {
                    $method = 'haversine';
                    $distance = self::calculateHaversineDistance($sellerLat, $sellerLon, $customerLat, $customerLon);
                    $duration = self::estimateTravelTime($distance);

                    $result = [
                        'distance_km' => $distance,
                        'duration_min' => $duration,
                        'distance_text' => self::formatDistance($distance),
                        'duration_text' => self::formatDuration($duration)
                    ];
                }

                $distanceDetails[] = [
                    'seller_index' => $index,
                    'seller_lat' => $sellerLat,
                    'seller_lon' => $sellerLon,
                    'distance_km' => $result['distance_km'],
                    'duration_min' => $result['duration_min'],
                    'distance_text' => $result['distance_text'],
                    'duration_text' => $result['duration_text']
                ];

                $totalDistance += $result['distance_km'];
                $totalDuration += $result['duration_min'];
            }

            // If no valid seller locations found
            if (empty($distanceDetails)) {
                return [
                    'error' => true,
                    'message' => 'No valid seller locations provided',
                    'charge' => 0,
                    'distance' => 0,
                    'duration' => 0,
                    'method' => 'none'
                ];
            }

            // Calculate delivery charge based on city configuration
            $chargeResult = self::calculateChargeByCity(
                $totalDistance,
                $cityId,
                $customerLat,
                $customerLon,
                $subTotal
            );

            // Check rain surcharge
            $rainSurcharge = WeatherService::getRainSurcharge($customerLat, $customerLon, $chargeResult['charge']);
            $rainSurchargeAmount = $rainSurcharge['applicable'] ? $rainSurcharge['surcharge'] : 0;
            $totalCharge = round($chargeResult['charge'] + $rainSurchargeAmount, 2);

            return [
                'error' => false,
                'message' => 'Delivery charge calculated successfully',
                'charge' => $totalCharge,
                'base_charge' => $chargeResult['charge'],
                'rain_surcharge' => $rainSurchargeAmount,
                'rain_surcharge_label' => $rainSurcharge['label'] ?? null,
                'rain_surcharge_applicable' => $rainSurcharge['applicable'],
                'distance' => round($totalDistance, 2),
                'distance_text' => self::formatDistance($totalDistance),
                'duration' => round($totalDuration, 2),
                'duration_text' => self::formatDuration($totalDuration),
                'method' => $method,
                'charge_method' => $chargeResult['charge_method'],
                'city_id' => $chargeResult['city_id'],
                'distance_details' => $distanceDetails,
                'free_delivery' => $chargeResult['free_delivery']
            ];
        } catch (\Exception $e) {
            Log::error('DeliveryChargeCalculationService: Error calculating delivery charge', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return [
                'error' => true,
                'message' => 'Error calculating delivery charge: ' . $e->getMessage(),
                'charge' => 0,
                'distance' => 0,
                'duration' => 0,
                'method' => 'error'
            ];
        }
    }

    /**
     * Calculate distance using Google Maps Distance Matrix API
     *
     * @param float $originLat Origin latitude
     * @param float $originLon Origin longitude
     * @param float $destLat Destination latitude
     * @param float $destLon Destination longitude
     * @return array|null
     */
    public static function getDistanceWithGoogleMaps(
        float $originLat,
        float $originLon,
        float $destLat,
        float $destLon
    ): ?array {
        try {
            // Try to get API key from settings (ID 47 first, then 46, then 48)
            $apiKey = self::getGoogleMapsApiKey();

            if (empty($apiKey)) {
                Log::warning('DeliveryChargeCalculationService: Google Maps API key not found');
                return null;
            }

            $origin = trim($originLat) . ',' . trim($originLon);
            $destination = trim($destLat) . ',' . trim($destLon);

            $url = "https://maps.googleapis.com/maps/api/distancematrix/json";

            $response = Http::withOptions(['verify' => false])->get($url, [
                'origins' => $origin,
                'destinations' => $destination,
                'key' => $apiKey,
                'units' => 'metric'
            ]);

            if (!$response->successful()) {
                Log::error('DeliveryChargeCalculationService: Google Maps API request failed', [
                    'status' => $response->status(),
                    'body' => $response->body()
                ]);
                return null;
            }

            $data = $response->json();

            if (!isset($data['status']) || $data['status'] !== 'OK') {
                Log::error('DeliveryChargeCalculationService: Google Maps API returned error', [
                    'status' => $data['status'] ?? 'unknown',
                    'error_message' => $data['error_message'] ?? null
                ]);
                return null;
            }

            $element = $data['rows'][0]['elements'][0] ?? null;

            if (!$element || $element['status'] !== 'OK') {
                Log::warning('DeliveryChargeCalculationService: Google Maps element status not OK', [
                    'element_status' => $element['status'] ?? 'unknown'
                ]);
                return null;
            }

            $distanceKm = $element['distance']['value'] / 1000;
            $durationMin = $element['duration']['value'] / 60;

            return [
                'distance_km' => round($distanceKm, 2),
                'duration_min' => round($durationMin, 2),
                'distance_text' => $element['distance']['text'],
                'duration_text' => $element['duration']['text']
            ];
        } catch (\Exception $e) {
            Log::error('DeliveryChargeCalculationService: Google Maps API exception', [
                'error' => $e->getMessage()
            ]);
            return null;
        }
    }

    /**
     * Get Google Maps API key from settings table
     *
     * @return string|null
     */
    private static function getGoogleMapsApiKey(): ?string
    {
        // Try ID 47 first (primary Google Maps API key)
        $apiKey = DB::table('settings')->where('id', self::SETTINGS_GOOGLE_MAP_API_KEY)->value('value');

        if (!empty($apiKey)) {
            return $apiKey;
        }

        // Try ID 46 (default maps key)
        $apiKey = DB::table('settings')->where('id', self::SETTINGS_DEFAULT_MAP_KEY)->value('value');

        if (!empty($apiKey)) {
            return $apiKey;
        }

        // Try ID 48 (backup key)
        $apiKey = DB::table('settings')->where('id', self::SETTINGS_BACKUP_MAP_KEY)->value('value');

        if (!empty($apiKey)) {
            return $apiKey;
        }

        // Last resort: try by variable name
        $apiKey = DB::table('settings')->where('variable', 'googleMapApiKey')->value('value');

        return $apiKey ?: null;
    }

    /**
     * Calculate distance using Haversine formula (fallback method)
     *
     * @param float $lat1 Origin latitude
     * @param float $lon1 Origin longitude
     * @param float $lat2 Destination latitude
     * @param float $lon2 Destination longitude
     * @return float Distance in kilometers
     */
    public static function calculateHaversineDistance(
        float $lat1,
        float $lon1,
        float $lat2,
        float $lon2
    ): float {
        $earthRadius = 6371; // Earth's radius in kilometers

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2)
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2))
            * sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return round($earthRadius * $c, 2);
    }

    /**
     * Estimate travel time based on distance (when Google Maps fails)
     *
     * @param float $distanceKm Distance in kilometers
     * @return float Estimated time in minutes
     */
    public static function estimateTravelTime(float $distanceKm): float
    {
        // Average speed assumptions for urban delivery
        $speedKmh = 25; // Average speed in km/h
        $tortuosity = 1.25; // Road winding factor
        $intersectionsPerKm = 3.5; // Traffic signals per km
        $delayPerIntersection = 12; // Seconds delay per intersection
        $congestionFactor = 1.1; // Traffic congestion multiplier

        // Calculate route distance with tortuosity
        $routeKm = $distanceKm * $tortuosity;

        // Base travel time
        $baseMinutes = ($routeKm / $speedKmh) * 60;

        // Delay from intersections
        $delayMinutes = ($intersectionsPerKm * $routeKm * $delayPerIntersection) / 60;

        // Total time with congestion
        return round(($baseMinutes + $delayMinutes) * $congestionFactor, 2);
    }

    /**
     * Calculate delivery charge based on city configuration
     *
     * @param float $distanceKm Total distance in kilometers
     * @param int|null $cityId City ID
     * @param float $customerLat Customer latitude
     * @param float $customerLon Customer longitude
     * @param float $subTotal Order subtotal for free delivery check
     * @return array
     */
    private static function calculateChargeByCity(
        float $distanceKm,
        ?int $cityId,
        float $customerLat,
        float $customerLon,
        float $subTotal
    ): array {
        $charge = 0;
        $chargeMethod = 'fixed_charge';
        $freeDelivery = false;

        // Find city by ID or by customer location
        $city = null;

        if ($cityId) {
            $city = City::find($cityId);
        }

        // If no city found by ID, try to find by customer location
        if (!$city) {
            $city = self::findCityByLocation($customerLat, $customerLon);
        }

        if (!$city) {
            Log::warning('DeliveryChargeCalculationService: No city found for charge calculation', [
                'city_id' => $cityId,
                'customer_lat' => $customerLat,
                'customer_lon' => $customerLon
            ]);

            return [
                'charge' => 0,
                'charge_method' => 'default',
                'city_id' => null,
                'free_delivery' => false
            ];
        }

        $chargeMethod = $city->delivery_charge_method ?? 'fixed_charge';
        $minAmountForFreeDelivery = floatval($city->min_amount_for_free_delivery ?? 0);

        // Check for free delivery
        if ($minAmountForFreeDelivery > 0 && $subTotal >= $minAmountForFreeDelivery) {
            return [
                'charge' => 0,
                'charge_method' => $chargeMethod,
                'city_id' => $city->id,
                'free_delivery' => true
            ];
        }

        // Calculate charge based on method
        switch ($chargeMethod) {
            case 'fixed_charge':
                $charge = floatval($city->fixed_charge ?? 0);
                break;

            case 'per_km_charge':
                $perKmCharge = floatval($city->per_km_charge ?? 0);
                $fixedCharge = floatval($city->fixed_charge ?? 0);
                $charge = max($fixedCharge, $perKmCharge * $distanceKm);
                break;

            case 'range_wise_charges':
                $ranges = json_decode($city->range_wise_charges ?? '[]', true);
                $roundedDistance = round($distanceKm);

                if (is_array($ranges)) {
                    foreach ($ranges as $range) {
                        $fromRange = floatval($range['from_range'] ?? $range['min'] ?? 0);
                        $toRange = floatval($range['to_range'] ?? $range['max'] ?? 0);
                        $rangeCharge = floatval($range['price'] ?? $range['charge'] ?? 0);

                        if ($roundedDistance >= $fromRange && $roundedDistance <= $toRange) {
                            $charge = $rangeCharge;
                            break;
                        }
                    }
                }

                // If no range matched, use fixed charge as fallback
                if ($charge == 0) {
                    $charge = floatval($city->fixed_charge ?? 0);
                }
                break;

            default:
                $charge = floatval($city->fixed_charge ?? 0);
                break;
        }

        return [
            'charge' => round($charge, 2),
            'charge_method' => $chargeMethod,
            'city_id' => $city->id,
            'free_delivery' => $freeDelivery
        ];
    }

    /**
     * Find city by customer location using polygon/circle boundary check
     *
     * @param float $lat Customer latitude
     * @param float $lon Customer longitude
     * @return City|null
     */
    private static function findCityByLocation(float $lat, float $lon): ?City
    {
        $cities = City::all();
        $point = ['lat' => $lat, 'lng' => $lon];

        foreach ($cities as $city) {
            if ($city->geolocation_type == 'polygon') {
                $polygon = json_decode($city->boundary_points ?? '[]', true);

                if (is_array($polygon) && !empty($polygon) && self::isPointInPolygon($point, $polygon)) {
                    return $city;
                }
            } elseif ($city->geolocation_type == 'circle') {
                $boundaryPoints = json_decode($city->boundary_points ?? '[]', true);
                $radius = floatval($city->radius ?? 0);

                if (is_array($boundaryPoints) && !empty($boundaryPoints)) {
                    $center = $boundaryPoints[0];
                    if (self::isPointInCircle($point, $center, $radius)) {
                        return $city;
                    }
                }
            }
        }

        // Fallback: Find nearest city by distance
        return City::whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->orderByRaw(
                "6371 * 2 * ASIN(SQRT(POW(SIN(RADIANS((? - latitude) / 2)), 2) + COS(RADIANS(latitude)) * COS(RADIANS(?)) * POW(SIN(RADIANS((? - longitude) / 2)), 2)))",
                [$lat, $lat, $lon]
            )
            ->first();
    }

    /**
     * Check if a point is inside a polygon
     *
     * @param array $point Point with lat and lng
     * @param array $polygon Array of polygon vertices
     * @return bool
     */
    private static function isPointInPolygon(array $point, array $polygon): bool
    {
        $x = $point['lat'];
        $y = $point['lng'];
        $inside = false;
        $n = count($polygon);

        for ($i = 0, $j = $n - 1; $i < $n; $j = $i++) {
            $xi = $polygon[$i]['lat'];
            $yi = $polygon[$i]['lng'];
            $xj = $polygon[$j]['lat'];
            $yj = $polygon[$j]['lng'];

            if ((($yi > $y) != ($yj > $y)) && ($x < ($xj - $xi) * ($y - $yi) / ($yj - $yi) + $xi)) {
                $inside = !$inside;
            }
        }

        return $inside;
    }

    /**
     * Check if a point is inside a circle
     *
     * @param array $point Point with lat and lng
     * @param array $center Center point with lat and lng
     * @param float $radius Radius in meters
     * @return bool
     */
    private static function isPointInCircle(array $point, array $center, float $radius): bool
    {
        $distance = self::calculateHaversineDistance(
            $point['lat'],
            $point['lng'],
            $center['lat'],
            $center['lng']
        ) * 1000; // Convert to meters

        return $distance <= $radius;
    }

    /**
     * Format distance for display
     *
     * @param float $km Distance in kilometers
     * @return string
     */
    public static function formatDistance(float $km): string
    {
        if ($km < 1) {
            return round($km * 1000) . ' m';
        }
        return round($km, 2) . ' km';
    }

    /**
     * Format duration for display
     *
     * @param float $minutes Duration in minutes
     * @return string
     */
    public static function formatDuration(float $minutes): string
    {
        if ($minutes < 1) {
            return round($minutes * 60) . ' sec';
        }
        if ($minutes >= 60) {
            $hours = floor($minutes / 60);
            $mins = round($minutes % 60);
            return $hours . ' hr ' . $mins . ' min';
        }
        return round($minutes) . ' min';
    }

    /**
     * Simple method to get delivery charge with minimal inputs
     *
     * @param float $sellerLat Seller latitude
     * @param float $sellerLon Seller longitude
     * @param float $customerLat Customer latitude
     * @param float $customerLon Customer longitude
     * @param int|null $cityId Optional city ID
     * @return array
     */
    public static function getDeliveryCharge(
        float $sellerLat,
        float $sellerLon,
        float $customerLat,
        float $customerLon,
        ?int $cityId = null
    ): array {
        return self::calculateDeliveryCharge(
            [['lat' => $sellerLat, 'lon' => $sellerLon]],
            $customerLat,
            $customerLon,
            $cityId
        );
    }

    /**
     * Get distance only (without charge calculation)
     *
     * @param float $originLat Origin latitude
     * @param float $originLon Origin longitude
     * @param float $destLat Destination latitude
     * @param float $destLon Destination longitude
     * @return array
     */
    public static function getDistanceOnly(
        float $originLat,
        float $originLon,
        float $destLat,
        float $destLon
    ): array {
        // Try Google Maps first
        $result = self::getDistanceWithGoogleMaps($originLat, $originLon, $destLat, $destLon);

        if ($result !== null) {
            return [
                'error' => false,
                'distance_km' => $result['distance_km'],
                'duration_min' => $result['duration_min'],
                'distance_text' => $result['distance_text'],
                'duration_text' => $result['duration_text'],
                'method' => 'google_maps'
            ];
        }

        // Fallback to Haversine
        $distance = self::calculateHaversineDistance($originLat, $originLon, $destLat, $destLon);
        $duration = self::estimateTravelTime($distance);

        return [
            'error' => false,
            'distance_km' => $distance,
            'duration_min' => $duration,
            'distance_text' => self::formatDistance($distance),
            'duration_text' => self::formatDuration($duration),
            'method' => 'haversine'
        ];
    }
}
