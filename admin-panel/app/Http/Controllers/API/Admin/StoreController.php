<?php

namespace App\Http\Controllers\API\Admin;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Store;
use App\Models\Seller;
use App\Models\City;
use Illuminate\Http\Request;

class StoreController extends Controller
{
    /**
     * Get all stores for order analytics filtering
     */
    public function getAllStores()
    {
        $stores = Store::select('id', 'name')
            ->where('is_active', 1)
            ->orderBy('name', 'asc')
            ->get();

        return CommonHelper::responseWithData($stores);
    }

    /**
     * Get sellers by store ID for order analytics filtering
     * Optionally filters by city/zone using the same logic as Sellers.vue
     */
    public function getSellersByStore(Request $request, $store_id)
    {
        $sellers = Seller::select('id', 'name', 'store_name', 'lat_long')
            ->where('store_id', $store_id)
            ->where('status', 1)
            ->orderBy('name', 'asc')
            ->get();

        // Filter by city/zone using seller lat_long against city boundary
        if($request->filled('city_id')){

            // "other" = sellers with no lat_long OR whose lat_long falls outside all city boundaries
            if($request->city_id === 'other'){
                $allCities = City::all();
                $sellers = $sellers->filter(function($seller) use ($allCities) {
                    return !$this->isInAnyCity($seller, $allCities);
                })->values();

            } else {
                $city = City::find($request->city_id);
                if($city){
                    $sellers = $sellers->filter(function($seller) use ($city) {
                        return $this->isSellerInCity($seller, $city);
                    })->values();
                }
            }
        }

        // Remove lat_long from response (not needed in frontend)
        $sellers = $sellers->map(function($seller) {
            return [
                'id' => $seller->id,
                'name' => $seller->name,
                'store_name' => $seller->store_name
            ];
        });

        return CommonHelper::responseWithData($sellers);
    }

    /**
     * Check if a seller's lat_long falls inside a given city boundary.
     * Returns false if seller has no lat_long.
     */
    private function isSellerInCity($seller, $city): bool
    {
        if (empty($seller->lat_long)) {
            return false;
        }

        $parts = explode(',', $seller->lat_long);
        if (count($parts) < 2) {
            return false;
        }

        $lat = floatval(trim($parts[0]));
        $lng = floatval(trim($parts[1]));

        if ($city->geolocation_type === 'polygon') {
            $polygon = is_string($city->boundary_points)
                ? json_decode($city->boundary_points, true)
                : $city->boundary_points;

            if (empty($polygon) || !is_array($polygon)) {
                return false;
            }

            return $this->isPointInPolygon($lat, $lng, $polygon);

        } elseif ($city->geolocation_type === 'radius') {
            $distance = $this->haversineDistance(
                $lat, $lng,
                floatval($city->latitude),
                floatval($city->longitude)
            );
            return $distance <= floatval($city->radius);
        }

        return false;
    }

    /**
     * Check if a seller belongs to ANY of the given cities.
     * Returns false if seller has no lat_long (they are "Other").
     */
    private function isInAnyCity($seller, $allCities): bool
    {
        if (empty($seller->lat_long)) {
            return false;
        }

        foreach ($allCities as $city) {
            if ($this->isSellerInCity($seller, $city)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Ray Casting algorithm — checks if a lat/lng point lies inside a polygon.
     * Polygon points are expected as array of ['lat' => ..., 'lng' => ...].
     */
    private function isPointInPolygon(float $lat, float $lng, array $polygon): bool
    {
        $count   = count($polygon);
        $inside  = false;
        $j       = $count - 1;

        for($i = 0; $i < $count; $j = $i++){
            $xi = floatval($polygon[$i]['lat']);
            $yi = floatval($polygon[$i]['lng']);
            $xj = floatval($polygon[$j]['lat']);
            $yj = floatval($polygon[$j]['lng']);

            if((($yi > $lng) !== ($yj > $lng)) &&
               ($lat < ($xj - $xi) * ($lng - $yi) / ($yj - $yi) + $xi)){
                $inside = !$inside;
            }
        }

        return $inside;
    }

    /**
     * Haversine formula — returns the great-circle distance in km between two coordinates.
     */
    private function haversineDistance(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $R    = 6371; // Earth radius in km
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a    = sin($dLat / 2) ** 2
              + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;
        return $R * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }
}
