<?php

namespace App\Services;

use App\Helpers\CommonHelper;
use App\Models\City;
use App\Models\Seller;
use App\Services\StoreDistanceService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class CityZoneService
{
    /**
     * Check if city zone filtering is enabled in settings.
     *
     * @return bool
     */
    public static function isZoneFilterEnabled(): bool
    {
        $value = DB::table('settings')
            ->where('variable', 'city_zone_filter_enabled')
            ->value('value');

        return $value === '1' || $value === 'true';
    }

    /**
     * Get list of available zones/cities that have boundary_points defined.
     *
     * @return array
     */
    public static function getAvailableZones(): array
    {
        return City::whereNotNull('boundary_points')
            ->where('boundary_points', '!=', '')
            ->get(['id', 'name', 'state', 'geolocation_type'])
            ->map(function ($city) {
                return [
                    'id' => $city->id,
                    'name' => $city->name,
                    'state' => $city->state,
                ];
            })
            ->toArray();
    }

    /**
     * Detect which city a customer is in based on lat/lon.
     * Checks if the point is within any city's boundary_points (polygon/circle).
     *
     * @param float $lat
     * @param float $lon
     * @return object|null City record or null
     */
    public static function detectCity(float $lat, float $lon): ?object
    {
        try {
            $cities = City::whereNotNull('boundary_points')
                ->where('boundary_points', '!=', '')
                ->get();

            if ($cities->isEmpty()) {
                Log::info('CityZoneService::detectCity - No cities with boundary_points found');
                return null;
            }

            // Check if point is within any city's boundary_points
            foreach ($cities as $city) {
                if (self::isPointInCityZone($lat, $lon, $city)) {
                    Log::info('CityZoneService::detectCity - Matched city', [
                        'city_id' => $city->id,
                        'city_name' => $city->name,
                        'lat' => $lat,
                        'lon' => $lon,
                    ]);
                    return $city;
                }
            }

            Log::info('CityZoneService::detectCity - No city matched', [
                'lat' => $lat,
                'lon' => $lon,
            ]);
            return null;

        } catch (\Exception $e) {
            Log::error('CityZoneService::detectCity failed', [
                'lat' => $lat,
                'lon' => $lon,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Check if a lat/lon point falls within a city's boundary_points zone.
     *
     * @param float $lat
     * @param float $lon
     * @param object $city City record with geolocation_type, boundary_points, radius
     * @return bool
     */
    public static function isPointInCityZone(float $lat, float $lon, object $city): bool
    {
        $point = ['lat' => $lat, 'lng' => $lon];
        $boundaryPoints = json_decode($city->boundary_points, true);

        if (!is_array($boundaryPoints) || empty($boundaryPoints)) {
            return false;
        }

        if ($city->geolocation_type === 'polygon') {
            return CommonHelper::isPointInPolygon($point, $boundaryPoints);
        }

        if ($city->geolocation_type === 'circle') {
            $center = $boundaryPoints[0] ?? null;
            $radius = $city->radius;
            if ($center && $radius) {
                return CommonHelper::isPointInCircle($point, $center, $radius);
            }
        }

        return false;
    }

    /**
     * Filter sellers by checking if their lat_long is inside the given city's zone.
     * Sellers outside all zones are included if within 15km of customer.
     *
     * @param array $sellerIds
     * @param object $city City record
     * @param float $customerLat Customer latitude
     * @param float $customerLon Customer longitude
     * @return array Filtered seller IDs
     */
    public static function filterSellersByZone(array $sellerIds, object $city, float $customerLat, float $customerLon): array
    {
        if (empty($sellerIds)) {
            return [];
        }

        $sellers = Seller::whereIn('id', $sellerIds)
            ->whereNotNull('lat_long')
            ->where('lat_long', '!=', '')
            ->get(['id', 'lat_long', 'store_name']);

        // Get all cities with boundary_points for zone checking
        $allCities = City::whereNotNull('boundary_points')
            ->where('boundary_points', '!=', '')
            ->get();

        $filtered = [];
        $sellersOutsideZones = [];
        $sellersInZone = [];

        foreach ($sellers as $seller) {
            $latLong = self::parseLatLong($seller->lat_long);
            if (!$latLong) {
                continue;
            }

            // Check if seller is in the same zone as customer
            if (self::isPointInCityZone($latLong['lat'], $latLong['lon'], $city)) {
                $filtered[] = $seller->id;
                $sellersInZone[] = $seller->id;
                continue;
            }

            // Check if seller is in ANY zone
            $sellerInAnyZone = false;
            foreach ($allCities as $otherCity) {
                if (self::isPointInCityZone($latLong['lat'], $latLong['lon'], $otherCity)) {
                    $sellerInAnyZone = true;
                    break;
                }
            }

            // If seller is NOT in any zone, check distance from customer
            if (!$sellerInAnyZone) {
                $distance = StoreDistanceService::haversine(
                    $customerLat,
                    $customerLon,
                    $latLong['lat'],
                    $latLong['lon']
                );

                // Include if within 15km
                if ($distance <= 15) {
                    $filtered[] = $seller->id;
                    $sellersOutsideZones[] = [
                        'id' => $seller->id,
                        'distance' => round($distance, 2)
                    ];
                }
            }
        }

        Log::info('CityZoneService::filterSellersByZone', [
            'city_id' => $city->id,
            'city_name' => $city->name,
            'total_sellers' => count($sellerIds),
            'sellers_in_zone' => count($sellersInZone),
            'sellers_outside_zones_within_15km' => count($sellersOutsideZones),
            'total_filtered' => count($filtered),
            'filtered_ids' => $filtered,
            'outside_zone_details' => $sellersOutsideZones,
        ]);

        return $filtered;
    }

    /**
     * Filter sellers by distance only (for customers outside all zones).
     * Returns sellers within 15km regardless of zone.
     *
     * @param array $sellerIds
     * @param float $customerLat Customer latitude
     * @param float $customerLon Customer longitude
     * @return array Filtered seller IDs
     */
    public static function filterSellersByDistance(array $sellerIds, float $customerLat, float $customerLon): array
    {
        if (empty($sellerIds)) {
            return [];
        }

        $sellers = Seller::whereIn('id', $sellerIds)
            ->whereNotNull('lat_long')
            ->where('lat_long', '!=', '')
            ->get(['id', 'lat_long', 'store_name']);

        $filtered = [];
        $sellerDistances = [];

        foreach ($sellers as $seller) {
            $latLong = self::parseLatLong($seller->lat_long);
            if (!$latLong) {
                continue;
            }

            $distance = StoreDistanceService::haversine(
                $customerLat,
                $customerLon,
                $latLong['lat'],
                $latLong['lon']
            );

            // Include if within 15km
            if ($distance <= 15) {
                $filtered[] = $seller->id;
                $sellerDistances[] = [
                    'id' => $seller->id,
                    'distance' => round($distance, 2),
                    'store_name' => $seller->store_name
                ];
            }
        }

        Log::info('CityZoneService::filterSellersByDistance', [
            'customer_lat' => $customerLat,
            'customer_lon' => $customerLon,
            'total_sellers' => count($sellerIds),
            'sellers_within_15km' => count($filtered),
            'filtered_ids' => $filtered,
            'seller_details' => $sellerDistances,
        ]);

        return $filtered;
    }

    /**
     * Reverse geocode lat/lon to city name using Google Maps Geocoding API.
     *
     * @param float $lat
     * @param float $lon
     * @return string|null City name or null
     */
    public static function reverseGeocode(float $lat, float $lon): ?string
    {
        try {
            $apiKey = DB::table('settings')
                ->where('variable', 'googleMapApiKey')
                ->value('value');

            if (empty($apiKey)) {
                Log::info('CityZoneService::reverseGeocode - No Google Maps API key found');
                return null;
            }

            $url = "https://maps.googleapis.com/maps/api/geocode/json?"
                . "latlng={$lat},{$lon}"
                . "&key={$apiKey}";

            $ch = curl_init();
            curl_setopt_array($ch, [
                CURLOPT_URL => $url,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_SSL_VERIFYPEER => false,
                CURLOPT_SSL_VERIFYHOST => false,
                CURLOPT_TIMEOUT => 10,
            ]);

            $response = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if (!$response || $httpCode !== 200) {
                Log::warning('CityZoneService::reverseGeocode - API request failed', [
                    'http_code' => $httpCode,
                ]);
                return null;
            }

            $json = json_decode($response, true);

            if (!isset($json['status']) || $json['status'] !== 'OK' || empty($json['results'])) {
                Log::warning('CityZoneService::reverseGeocode - No results from API');
                return null;
            }

            // Extract city/locality from address_components
            foreach ($json['results'][0]['address_components'] as $component) {
                if (in_array('locality', $component['types'])) {
                    Log::info('CityZoneService::reverseGeocode - Found city', [
                        'city' => $component['long_name'],
                    ]);
                    return $component['long_name'];
                }
            }

            // Fallback: try administrative_area_level_2
            foreach ($json['results'][0]['address_components'] as $component) {
                if (in_array('administrative_area_level_2', $component['types'])) {
                    return $component['long_name'];
                }
            }

            return null;

        } catch (\Exception $e) {
            Log::error('CityZoneService::reverseGeocode failed', [
                'lat' => $lat,
                'lon' => $lon,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Parse "lat,lon" string into array.
     *
     * @param string|null $latLong
     * @return array|null ['lat' => float, 'lon' => float]
     */
    private static function parseLatLong(?string $latLong): ?array
    {
        if (empty($latLong)) {
            return null;
        }

        $parts = explode(',', $latLong);
        if (count($parts) !== 2) {
            return null;
        }

        $lat = trim($parts[0]);
        $lon = trim($parts[1]);

        if (!is_numeric($lat) || !is_numeric($lon)) {
            return null;
        }

        return ['lat' => (float) $lat, 'lon' => (float) $lon];
    }
}
