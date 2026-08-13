<?php

namespace App\Services;
use Illuminate\Support\Facades\DB;


class StoreDistanceService
{
    /**
     * Haversine distance (KM)
     */
    public static function haversine($lat1, $lon1, $lat2, $lon2)
    {
        $R = 6371;

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat/2) * sin($dLat/2)
           + cos(deg2rad($lat1)) * cos(deg2rad($lat2))
           * sin($dLon/2) * sin($dLon/2);

        return $R * (2 * atan2(sqrt($a), sqrt(1 - $a)));
    }

    /**
     * Estimate travel time (no API)
     */
    public static function estimateTravelTimeMinutes($distanceKm)
    {
        $speedKmh = 25;
        $tortuosity = 1.25;
        $intersections = 3.5;
        $delay = 12;
        $congestion = 1.1;

        $routeKm = $distanceKm * $tortuosity;
        
        $baseMin = ($routeKm / $speedKmh) * 60;
        $delayMin = ($intersections * $routeKm * $delay) / 60;

        return round(($baseMin + $delayMin) * $congestion, 2);
    }

    /**
     * Google API Distance (fixed, safe)
     */
    public static function googleMapsDistance($lat1, $lon1, $lat2, $lon2)
    {
        // $apiKey = env("GOOGLE_MAPS_API_KEY");
        $apiKey = DB::table('settings')->where("variable","googleMapApiKey")->value("value");


        if (!$apiKey) {
            return null;
        }

        // Remove spaces
        $lat2 = trim($lat2);
        $lon2 = trim($lon2);

        $url = "https://maps.googleapis.com/maps/api/distancematrix/json?"
             . "origins={$lat1},{$lon1}"
             . "&destinations={$lat2},{$lon2}"
             . "&key={$apiKey}";

        // Use CURL instead of file_get_contents
        $ch = curl_init();

        curl_setopt_array($ch, [
            CURLOPT_URL => $url,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_SSL_VERIFYPEER => false,
            CURLOPT_SSL_VERIFYHOST => false,
        ]);

        $response = curl_exec($ch);
        curl_close($ch);

        if (!$response) {
            return null;
        }

        $json = json_decode($response, true);

        if (
            !isset($json["rows"][0]["elements"][0]["status"]) ||
            $json["rows"][0]["elements"][0]["status"] !== "OK"
        ) {
            return null;
        }

        return [
            "distance_km" => $json["rows"][0]["elements"][0]["distance"]["value"] / 1000,
            "time_min" => $json["rows"][0]["elements"][0]["duration"]["value"] / 60,
        ];
    }

    /**
     * Customer-facing distance. One decimal is all that is meaningful on a
     * store card — "2.53 km" implies a precision the estimate doesn't have.
     */
    public static function formatDistance($km)
    {
        if ($km === null) {
            return null;
        }

        $km = (float) $km;

        if ($km < 1) {
            return round($km * 1000) . " m"; // meters
        }
        return round($km, 1) . " km"; // kilometers
    }

    /**
     * Customer-facing ETA. Always whole minutes — decimals ("7.52 min") and
     * sub-minute values ("48 sec") both read as broken on a store card, so
     * anything under a minute is floored to "1 min".
     */
    public static function formatTime($minutes)
    {
        if ($minutes === null) {
            return null;
        }

        $minutes = max(1, (int) round((float) $minutes));

        if ($minutes < 60) {
            return $minutes . " min";
        }

        $hours = intdiv($minutes, 60);
        $mins  = $minutes % 60;

        return $mins === 0 ? $hours . " hr" : $hours . " hr " . $mins . " min";
    }

}
