<?php

namespace App\Services;

use App\Models\Setting;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class WeatherService
{
    // Google Weather API rain-related condition types
    const GOOGLE_RAIN_CONDITIONS = [
        'RAIN',
        'HEAVY_RAIN',
        'LIGHT_RAIN',
        'RAIN_SHOWERS',
        'HEAVY_RAIN_SHOWERS',
        'LIGHT_RAIN_SHOWERS',
        'DRIZZLE',
        'THUNDERSTORM',
        'THUNDERSTORM_WITH_RAIN',
        'SCATTERED_SHOWERS',
    ];

    // OpenWeatherMap rain-related condition types
    const OWM_RAIN_CONDITIONS = ['rain', 'drizzle', 'thunderstorm'];

    /**
     * Get Google Maps API key from settings
     */
    private static function getGoogleApiKey(): ?string
    {
        $apiKey = Setting::get_value('google_map_api_key');

        if (empty($apiKey)) {
            $apiKey = Setting::get_value('googleMapApiKey');
        }

        if (empty($apiKey)) {
            $apiKey = Setting::get_value('google_place_api_key');
        }

        return !empty($apiKey) ? $apiKey : null;
    }

    /**
     * Get OpenWeatherMap API key from settings
     */
    private static function getOpenWeatherMapApiKey(): ?string
    {
        $apiKey = Setting::get_value('openweathermap_api_key');
        return !empty($apiKey) ? $apiKey : null;
    }

    /**
     * Check if rain is coming in the driver's zone
     *
     * Tries Google Weather API first, falls back to OpenWeatherMap if Google fails
     *
     * @param float $lat
     * @param float $lon
     * @return array
     */
    public static function checkRainStatus(float $lat, float $lon): array
    {
        // Test mode: skip weather API calls and return raining = true
        $testMode = Setting::get_value('is_test_rain_mode_activated');
        if ($testMode == '1') {
            Log::info("WeatherService: Test rain mode is ON, skipping API calls");
            return [
                'success' => true,
                'is_raining_now' => true,
                'rain_expected' => true,
                'current_rain' => [
                    'condition' => 'Rain',
                    'description' => 'Test mode - simulated rain',
                    'precipitation_mm' => 5.0,
                ],
                'upcoming_rain' => [],
                'current_weather' => [
                    'temperature' => null,
                    'feels_like' => null,
                    'humidity' => null,
                    'wind_speed' => null,
                    'condition' => 'Rain',
                    'description' => 'Test mode - simulated rain',
                    'icon' => null,
                ],
                'location' => ['lat' => $lat, 'lon' => $lon],
                'source' => 'test_mode',
            ];
        }

        // Cache key based on rounded lat/lon (2 decimal places ≈ ~1km area)
        $cacheKey = 'weather_rain_' . round($lat, 2) . '_' . round($lon, 2);

        return Cache::remember($cacheKey, 300, function () use ($lat, $lon) {
            // Try Google Weather API first
            $result = self::checkRainViaGoogle($lat, $lon);

            if ($result['success']) {
                $result['source'] = 'google';
                return $result;
            }

            Log::info("WeatherService: Google Weather API failed, falling back to OpenWeatherMap");

            // Fallback to OpenWeatherMap
            $result = self::checkRainViaOpenWeatherMap($lat, $lon);

            if ($result['success']) {
                $result['source'] = 'openweathermap';
                return $result;
            }

            return [
                'success' => false,
                'message' => 'Unable to fetch weather data from both Google and OpenWeatherMap APIs',
            ];
        });
    }

    // ==========================================
    // GOOGLE WEATHER API
    // ==========================================

    private static function checkRainViaGoogle(float $lat, float $lon): array
    {
        try {
            $apiKey = self::getGoogleApiKey();

            if (empty($apiKey)) {
                return ['success' => false, 'message' => 'Google Maps API key not configured'];
            }

            Log::info("WeatherService: Using Google API key", ['key' => $apiKey]);

            $currentConditions = self::googleGetCurrentConditions($lat, $lon, $apiKey);
            $forecast = self::googleGetHourlyForecast($lat, $lon, $apiKey);

            if ($currentConditions === null && $forecast === null) {
                return ['success' => false, 'message' => 'Google Weather API returned no data'];
            }

            $isRainingNow = false;
            $rainExpected = false;
            $currentRainInfo = null;
            $upcomingRain = [];

            if ($currentConditions) {
                $condition = $currentConditions['weatherCondition'] ?? '';
                $isRainingNow = in_array($condition, self::GOOGLE_RAIN_CONDITIONS);

                if ($isRainingNow) {
                    $currentRainInfo = [
                        'condition' => $condition,
                        'description' => $currentConditions['description'] ?? 'Rain',
                        'precipitation_mm' => $currentConditions['precipitation']['quantity']['value'] ?? null,
                    ];
                }
            }

            if ($forecast && isset($forecast['forecastHours'])) {
                foreach ($forecast['forecastHours'] as $hour) {
                    $condition = $hour['weatherCondition'] ?? '';
                    if (in_array($condition, self::GOOGLE_RAIN_CONDITIONS)) {
                        $rainExpected = true;
                        $upcomingRain[] = [
                            'time' => $hour['interval']['startTime'] ?? null,
                            'condition' => $condition,
                            'description' => $hour['description'] ?? 'Rain',
                            'precipitation_mm' => $hour['precipitation']['quantity']['value'] ?? null,
                            'precipitation_probability' => $hour['precipitation']['probability']['value'] ?? null,
                        ];
                    }
                }
            }

            return [
                'success' => true,
                'is_raining_now' => $isRainingNow,
                'rain_expected' => $rainExpected,
                'current_rain' => $currentRainInfo,
                'upcoming_rain' => $upcomingRain,
                'current_weather' => $currentConditions ? [
                    'temperature' => $currentConditions['temperature']['degrees'] ?? null,
                    'feels_like' => $currentConditions['feelsLikeTemperature']['degrees'] ?? null,
                    'humidity' => $currentConditions['relativeHumidity'] ?? null,
                    'wind_speed' => $currentConditions['wind']['speed']['value'] ?? null,
                    'condition' => $currentConditions['weatherCondition'] ?? null,
                    'description' => $currentConditions['description'] ?? null,
                    'icon' => $currentConditions['iconUri'] ?? null,
                ] : null,
                'location' => ['lat' => $lat, 'lon' => $lon],
            ];

        } catch (\Exception $e) {
            Log::error("WeatherService: Google exception", ['error' => $e->getMessage()]);
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    private static function googleGetCurrentConditions(float $lat, float $lon, string $apiKey): ?array
    {
        try {
            $url = "https://weather.googleapis.com/v1/currentConditions:lookup?key={$apiKey}";

            $response = Http::timeout(10)
                ->withoutVerifying()
                ->withHeaders(['Content-Type' => 'application/json'])
                ->post($url, [
                    'location' => ['latitude' => $lat, 'longitude' => $lon],
                ]);

            if ($response->successful()) {
                return $response->json();
            }

            Log::error("WeatherService: Google current conditions failed", [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            return null;

        } catch (\Exception $e) {
            Log::error("WeatherService: Google current conditions exception", ['error' => $e->getMessage()]);
            return null;
        }
    }

    private static function googleGetHourlyForecast(float $lat, float $lon, string $apiKey): ?array
    {
        try {
            $url = "https://weather.googleapis.com/v1/forecast/hours:lookup?key={$apiKey}";

            $response = Http::timeout(10)
                ->withoutVerifying()
                ->withHeaders(['Content-Type' => 'application/json'])
                ->post($url, [
                    'location' => ['latitude' => $lat, 'longitude' => $lon],
                    'hours' => 6,
                ]);

            if ($response->successful()) {
                return $response->json();
            }

            Log::error("WeatherService: Google hourly forecast failed", [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            return null;

        } catch (\Exception $e) {
            Log::error("WeatherService: Google hourly forecast exception", ['error' => $e->getMessage()]);
            return null;
        }
    }

    // ==========================================
    // OPENWEATHERMAP API (FREE FALLBACK)
    // ==========================================

    private static function checkRainViaOpenWeatherMap(float $lat, float $lon): array
    {
        try {
            $apiKey = self::getOpenWeatherMapApiKey();

            if (empty($apiKey)) {
                return ['success' => false, 'message' => 'OpenWeatherMap API key not configured'];
            }

            $currentWeather = self::owmGetCurrentWeather($lat, $lon, $apiKey);
            $forecast = self::owmGetForecast($lat, $lon, $apiKey);

            if ($currentWeather === null && $forecast === null) {
                return ['success' => false, 'message' => 'OpenWeatherMap API returned no data'];
            }

            $isRainingNow = false;
            $rainExpected = false;
            $currentRainInfo = null;
            $upcomingRain = [];

            if ($currentWeather) {
                $isRainingNow = self::owmIsRaining($currentWeather);
                if ($isRainingNow) {
                    $currentRainInfo = [
                        'condition' => $currentWeather['weather'][0]['main'] ?? 'Rain',
                        'description' => $currentWeather['weather'][0]['description'] ?? 'Rain',
                        'precipitation_mm' => $currentWeather['rain']['1h'] ?? $currentWeather['rain']['3h'] ?? null,
                    ];
                }
            }

            if ($forecast && isset($forecast['list'])) {
                $now = time();
                $sixHoursLater = $now + (6 * 3600);

                foreach ($forecast['list'] as $item) {
                    $forecastTime = $item['dt'];
                    if ($forecastTime > $sixHoursLater) break;

                    if (self::owmIsRaining($item)) {
                        $rainExpected = true;
                        $upcomingRain[] = [
                            'time' => date('Y-m-d H:i:s', $forecastTime),
                            'condition' => $item['weather'][0]['main'] ?? 'Rain',
                            'description' => $item['weather'][0]['description'] ?? 'Rain',
                            'precipitation_mm' => $item['rain']['3h'] ?? null,
                            'precipitation_probability' => isset($item['pop']) ? round($item['pop'] * 100) : null,
                        ];
                    }
                }
            }

            return [
                'success' => true,
                'is_raining_now' => $isRainingNow,
                'rain_expected' => $rainExpected,
                'current_rain' => $currentRainInfo,
                'upcoming_rain' => $upcomingRain,
                'current_weather' => $currentWeather ? [
                    'temperature' => isset($currentWeather['main']['temp']) ? round($currentWeather['main']['temp'] - 273.15, 1) : null,
                    'feels_like' => isset($currentWeather['main']['feels_like']) ? round($currentWeather['main']['feels_like'] - 273.15, 1) : null,
                    'humidity' => $currentWeather['main']['humidity'] ?? null,
                    'wind_speed' => $currentWeather['wind']['speed'] ?? null,
                    'condition' => $currentWeather['weather'][0]['main'] ?? null,
                    'description' => $currentWeather['weather'][0]['description'] ?? null,
                    'icon' => isset($currentWeather['weather'][0]['icon']) ? "https://openweathermap.org/img/wn/{$currentWeather['weather'][0]['icon']}@2x.png" : null,
                ] : null,
                'location' => [
                    'lat' => $lat,
                    'lon' => $lon,
                    'city' => $currentWeather['name'] ?? null,
                ],
            ];

        } catch (\Exception $e) {
            Log::error("WeatherService: OpenWeatherMap exception", ['error' => $e->getMessage()]);
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    private static function owmGetCurrentWeather(float $lat, float $lon, string $apiKey): ?array
    {
        try {
            $response = Http::timeout(10)
                ->withoutVerifying()
                ->get('https://api.openweathermap.org/data/2.5/weather', [
                    'lat' => $lat,
                    'lon' => $lon,
                    'appid' => $apiKey,
                ]);

            if ($response->successful()) {
                return $response->json();
            }

            Log::error("WeatherService: OWM current weather failed", [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            return null;

        } catch (\Exception $e) {
            Log::error("WeatherService: OWM current weather exception", ['error' => $e->getMessage()]);
            return null;
        }
    }

    private static function owmGetForecast(float $lat, float $lon, string $apiKey): ?array
    {
        try {
            $response = Http::timeout(10)
                ->withoutVerifying()
                ->get('https://api.openweathermap.org/data/2.5/forecast', [
                    'lat' => $lat,
                    'lon' => $lon,
                    'appid' => $apiKey,
                    'cnt' => 3,
                ]);

            if ($response->successful()) {
                return $response->json();
            }

            Log::error("WeatherService: OWM forecast failed", [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            return null;

        } catch (\Exception $e) {
            Log::error("WeatherService: OWM forecast exception", ['error' => $e->getMessage()]);
            return null;
        }
    }

    private static function owmIsRaining(array $weatherData): bool
    {
        if (isset($weatherData['weather'])) {
            foreach ($weatherData['weather'] as $condition) {
                if (in_array(strtolower($condition['main'] ?? ''), self::OWM_RAIN_CONDITIONS)) {
                    return true;
                }
            }
        }

        if (isset($weatherData['rain']) && !empty($weatherData['rain'])) {
            return true;
        }

        return false;
    }

    // ==========================================
    // RAIN SURCHARGE CALCULATION
    // ==========================================


    
    /**
     * Calculate rain surcharge for delivery charge
     *
     * @param float $lat Customer/delivery latitude
     * @param float $lon Customer/delivery longitude
     * @param float $deliveryCharge Base delivery charge amount
     * @return array
     */
    public static function getRainSurcharge(float $lat, float $lon, float $deliveryCharge = 0): array
    {
        try {
            $enabled = Setting::get_value('rain_surcharge_enabled');

            if ($enabled != '1') {
                return [
                    'applicable' => false,
                    'surcharge' => 0,
                    'label' => null,
                    'reason' => 'Rain surcharge is disabled',
                ];
            }

            $rainStatus = self::checkRainStatus($lat, $lon);

            Log::info('WeatherService: getRainSurcharge check', [
                'lat' => $lat,
                'lon' => $lon,
                'source' => $rainStatus['source'] ?? 'unknown',
                'is_raining_now' => $rainStatus['is_raining_now'] ?? false,
                'rain_expected' => $rainStatus['rain_expected'] ?? false,
                'success' => $rainStatus['success'] ?? false,
            ]);

            if (!$rainStatus['success']) {
                return [
                    'applicable' => false,
                    'surcharge' => 0,
                    'label' => null,
                    'reason' => 'Could not fetch weather data',
                ];
            }

            // Only apply surcharge when it's ACTUALLY raining now, not based on forecast
            $isRainy = $rainStatus['is_raining_now'];

            if (!$isRainy) {
                return [
                    'applicable' => false,
                    'surcharge' => 0,
                    'label' => null,
                    'reason' => 'No rain detected',
                    'weather' => $rainStatus['current_weather'] ?? null,
                ];
            }

            $type = Setting::get_value('rain_surcharge_type') ?: 'fixed';
            $amount = floatval(Setting::get_value('rain_surcharge_amount') ?: 0);
            $label = Setting::get_value('rain_surcharge_label') ?: 'Rain Surcharge';

            $surcharge = 0;
            if ($type === 'percentage' && $deliveryCharge > 0) {
                $surcharge = round(($amount / 100) * $deliveryCharge, 2);
            } else {
                $surcharge = round($amount, 2);
            }

            return [
                'applicable' => true,
                'surcharge' => $surcharge,
                'surcharge_type' => $type,
                'surcharge_value' => $amount,
                'label' => $label,
                'is_raining_now' => $rainStatus['is_raining_now'],
                'rain_expected' => $rainStatus['rain_expected'],
                'weather' => $rainStatus['current_weather'] ?? null,
            ];

        } catch (\Exception $e) {
            Log::error("WeatherService: Rain surcharge exception", ['error' => $e->getMessage()]);
            return [
                'applicable' => false,
                'surcharge' => 0,
                'label' => null,
                'reason' => 'Error calculating surcharge',
            ];
        }
    }
}
