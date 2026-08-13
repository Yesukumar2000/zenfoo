<?php

/*
|--------------------------------------------------------------------------
| Move a driver to a location (testing tool)
|--------------------------------------------------------------------------
|
| Writes one GPS ping exactly the way the driver app does, so backend logic
| that reads the driver's position - the handoff point on an emergency driver
| change, the new driver's route start - sees the driver standing there.
|
| Usage:
|     php set_driver_location.php <delivery_boy_id> <latitude> <longitude>
|     php set_driver_location.php 148 17.4389386 78.3983597
|
| Run it once per point to walk a driver along a route.
|
| Writes MySQL only (delivery_boy_location_history + delivery_boys). It does
| not touch Firestore, so the blue dot in the app will not move - the backend
| reads MySQL for every decision this is meant to test.
|
| Requires an OPEN session for the driver (logout_at IS NULL): the location
| lookup filters history by the active session id, so a ping written without
| one is invisible to it. Put the driver online in the app first.
|
| Disposable dev tool - delete it from the server when the test is done.
|
*/

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

function fail(string $message): void
{
    fwrite(STDERR, "ERROR: {$message}\n");
    exit(1);
}

/** Great-circle distance in km - same formula the routing code uses. */
function haversineKm(float $lat1, float $lon1, float $lat2, float $lon2): float
{
    $earthRadius = 6371;

    $dLat = deg2rad($lat2 - $lat1);
    $dLon = deg2rad($lon2 - $lon1);

    $a = sin($dLat / 2) * sin($dLat / 2)
        + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) * sin($dLon / 2);

    return $earthRadius * 2 * atan2(sqrt($a), sqrt(1 - $a));
}

// ── Arguments ────────────────────────────────────────────────────────────────
if ($argc !== 4) {
    fail("usage: php set_driver_location.php <delivery_boy_id> <latitude> <longitude>");
}

$deliveryBoyId = (int) $argv[1];
$latitude = (float) $argv[2];
$longitude = (float) $argv[3];

if ($deliveryBoyId <= 0) {
    fail("delivery_boy_id must be a positive integer, got '{$argv[1]}'");
}

if ($latitude < -90 || $latitude > 90 || $longitude < -180 || $longitude > 180) {
    fail("coordinates out of range: {$latitude}, {$longitude}");
}

// ── Driver ───────────────────────────────────────────────────────────────────
$driver = DB::table('delivery_boys')->where('id', $deliveryBoyId)->first(['id', 'name']);

if (!$driver) {
    fail("no delivery boy with id {$deliveryBoyId}");
}

// ── Active session ───────────────────────────────────────────────────────────
// getDriverLatestLocation() filters history by the active session, so without
// one this ping would be written and then ignored.
$session = DB::table('delivery_boy_sessions')
    ->where('delivery_boy_id', $deliveryBoyId)
    ->whereNull('logout_at')
    ->orderByDesc('id')
    ->first(['id']);

if (!$session) {
    fail("{$driver->name} (#{$deliveryBoyId}) has no open session - put the driver online in the app first");
}

// ── Distance from the previous ping ──────────────────────────────────────────
$previous = DB::table('delivery_boy_location_history')
    ->where('delivery_boy_id', $deliveryBoyId)
    ->where('session_id', $session->id)
    ->orderByDesc('tracked_at')
    ->first(['latitude', 'longitude', 'tracked_at']);

$distanceFromLast = $previous
    ? haversineKm((float) $previous->latitude, (float) $previous->longitude, $latitude, $longitude)
    : 0;

// ── Write ────────────────────────────────────────────────────────────────────
$now = now();

DB::table('delivery_boy_location_history')->insert([
    'delivery_boy_id' => $deliveryBoyId,
    'session_id' => $session->id,
    'latitude' => $latitude,
    'longitude' => $longitude,
    'distance_from_last_km' => round($distanceFromLast, 2),
    'tracked_at' => $now,
    'created_at' => $now,
    'updated_at' => $now,
]);

// Keep the fallback column in step, so both lookup paths agree.
DB::table('delivery_boys')->where('id', $deliveryBoyId)->update([
    'latitude' => $latitude,
    'longitude' => $longitude,
    'updated_at' => $now,
]);

// ── Report ───────────────────────────────────────────────────────────────────
echo "Driver   : {$driver->name} (#{$deliveryBoyId})\n";
echo "Session  : {$session->id}\n";

if ($previous) {
    echo "Was      : {$previous->latitude}, {$previous->longitude}  (at {$previous->tracked_at})\n";
} else {
    echo "Was      : no previous ping this session\n";
}

echo "Now      : {$latitude}, {$longitude}\n";
echo "Moved    : " . round($distanceFromLast, 2) . " km\n";
echo "Tracked  : {$now}\n";
