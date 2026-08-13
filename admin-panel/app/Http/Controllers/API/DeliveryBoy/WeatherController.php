<?php

namespace App\Http\Controllers\API\DeliveryBoy;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Services\MediaUploadService;
use App\Services\WeatherService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class WeatherController extends Controller
{
    /**
     * Check rain status at driver's location
     * POST /api/delivery-boy/weather/rain-check
     *
     * @param Request $request - { lat: float, lon: float }
     * @return \Illuminate\Http\JsonResponse
     */
    public function checkRain(Request $request)
    {
        try {
            $lat = $request->input('lat');
            $lon = $request->input('lon');

            if ($lat === null || $lon === null) {
                return CommonHelper::responseError('lat and lon are required');
            }

            $lat = (float) $lat;
            $lon = (float) $lon;

            // Validate coordinates
            if ($lat < -90 || $lat > 90 || $lon < -180 || $lon > 180) {
                return CommonHelper::responseError('Invalid coordinates. lat must be between -90 and 90, lon must be between -180 and 180');
            }

            $result = WeatherService::checkRainStatus($lat, $lon);

            if (!$result['success']) {
                return CommonHelper::responseError($result['message']);
            }

            return CommonHelper::responseSuccessWithData('Weather data fetched successfully', $result);

        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Verify rain with photo proof from driver
     * POST /api/delivery-boy/weather/rain-verify
     *
     * @param Request $request - { lat: float, lon: float, rain_image: file }
     * @return \Illuminate\Http\JsonResponse
     */
    public function verifyRain(Request $request)
    {
        try {
            $lat = $request->input('lat');
            $lon = $request->input('lon');

            if ($lat === null || $lon === null) {
                return CommonHelper::responseError('lat and lon are required');
            }

            if (!$request->hasFile('rain_image')) {
                return CommonHelper::responseError('rain_image is required');
            }

            $lat = (float) $lat;
            $lon = (float) $lon;

            if ($lat < -90 || $lat > 90 || $lon < -180 || $lon > 180) {
                return CommonHelper::responseError('Invalid coordinates');
            }

            // Upload rain proof image
            $imageUrl = MediaUploadService::upload(
                $request->file('rain_image'),
                'rain-proofs'
            );

            // Verify rain via weather service
            $result = WeatherService::checkRainStatus($lat, $lon);

            $isRaining = false;
            if ($result['success']) {
                $isRaining = $result['is_raining_now'] || $result['rain_expected'];
            }

            Log::info('WeatherController: Rain verification', [
                'driver_id' => $request->user()->id ?? null,
                'lat' => $lat,
                'lon' => $lon,
                'weather_api_raining' => $isRaining,
                'image_url' => $imageUrl,
            ]);

            if ($isRaining) {
                return CommonHelper::responseSuccessWithData('Rain mode activated', [
                    'rain_verified' => true,
                    'is_raining_now' => $result['is_raining_now'] ?? false,
                    'rain_expected' => $result['rain_expected'] ?? false,
                    'rain_image' => $imageUrl,
                    'weather' => $result['current_weather'] ?? null,
                    'source' => $result['source'] ?? null,
                ]);
            }

            return CommonHelper::responseSuccessWithData('Not raining in your location', [
                'rain_verified' => false,
                'is_raining_now' => false,
                'rain_expected' => false,
                'rain_image' => $imageUrl,
                'weather' => $result['current_weather'] ?? null,
                'source' => $result['source'] ?? null,
            ]);

        } catch (\Exception $e) {
            Log::error('WeatherController: Rain verification failed', ['error' => $e->getMessage()]);
            return CommonHelper::responseError($e->getMessage());
        }
    }
}
