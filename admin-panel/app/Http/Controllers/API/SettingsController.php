<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Setting;
use App\Services\MediaUploadService;
use App\Services\FirestoreSettingsService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class SettingsController extends Controller
{
    /**
     * Get all settings
     * GET /api/settings
     */
    public function index()
    {
        try {
            $settings = DB::table('settings')
                ->select('id', 'variable', 'value')
                ->get();

            // Convert to key-value format for easier frontend use
            $settingsKeyValue = [];
            foreach ($settings as $setting) {
                $settingsKeyValue[$setting->variable] = $setting->value;
            }

            // Get store hours from Firestore
            $storeHours = FirestoreSettingsService::getStoreHours();
            $settingsKeyValue['store_opening_time'] = $storeHours['store_opening_time'];
            $settingsKeyValue['store_closing_time'] = $storeHours['store_closing_time'];

            return response()->json([
                'status' => 1,
                'message' => 'Settings retrieved successfully',
                'data' => [
                    'settings' => $settings,
                    'settings_map' => $settingsKeyValue
                ]
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update a setting
     * POST /api/settings/update
     */
    public function update(Request $request)
    {
        try {
            $variable = $request->input('variable');
            $value = $request->input('value');

            if (empty($variable)) {
                return CommonHelper::responseError('Variable name is required');
            }

            DB::table('settings')
                ->updateOrInsert(
                    ['variable' => $variable],
                    ['value' => $value ?? '']
                );

            return response()->json([
                'status' => 1,
                'message' => 'Setting updated successfully'
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Update multiple settings at once
     * POST /api/settings/bulk-update
     */
    public function bulkUpdate(Request $request)
    {
        try {
            $settings = $request->input('settings');

            if (empty($settings) || !is_array($settings)) {
                return CommonHelper::responseError('Settings array is required');
            }

            // Separate Firestore settings from MySQL settings
            $firestoreSettings = [];
            $mysqlSettings = [];

            foreach ($settings as $variable => $value) {
                if (in_array($variable, ['store_opening_time', 'store_closing_time'])) {
                    $firestoreSettings[$variable] = $value;
                } else {
                    $mysqlSettings[$variable] = $value;
                }
            }

            // Update MySQL settings. `value` is NOT NULL, so a blank field
            // arriving as null would abort the loop mid-way -- leaving the
            // settings already written committed and the rest silently skipped.
            foreach ($mysqlSettings as $variable => $value) {
                DB::table('settings')
                    ->updateOrInsert(
                        ['variable' => $variable],
                        ['value' => $value ?? '']
                    );
            }

            // Update Firestore settings (store hours)
            if (!empty($firestoreSettings)) {
                $openingTime = $firestoreSettings['store_opening_time'] ?? null;
                $closingTime = $firestoreSettings['store_closing_time'] ?? null;

                $firestoreResult = FirestoreSettingsService::updateStoreHours($openingTime, $closingTime);

                if (!$firestoreResult['success']) {
                    return CommonHelper::responseError($firestoreResult['message']);
                }
            }

            return response()->json([
                'status' => 1,
                'message' => 'Settings updated successfully'
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Test AWS S3 connection by uploading a small test file
     * POST /api/settings/test-s3
     */
    public function testS3()
    {
        try {
            // Configure S3 from settings and upload a small test file
            $testContent = 'S3 connection test - ' . now()->toDateTimeString();
            $testPath = 'test/s3_test_' . time() . '.txt';

            // Read AWS settings from DB
            $awsSettings = DB::table('settings')
                ->whereIn('variable', ['aws_access_key_id', 'aws_secret_access_key', 'aws_default_region', 'aws_bucket'])
                ->pluck('value', 'variable');

            $key = $awsSettings['aws_access_key_id'] ?? '';
            $secret = $awsSettings['aws_secret_access_key'] ?? '';
            $region = $awsSettings['aws_default_region'] ?? '';
            $bucket = $awsSettings['aws_bucket'] ?? '';

            if (empty($key) || empty($secret) || empty($bucket)) {
                return CommonHelper::responseError('AWS S3 credentials are not configured. Go to Store Settings and fill in AWS S3 fields.');
            }

            // Create S3 client directly (bypasses Flysystem config issues)
            $s3Config = [
                'version' => 'latest',
                'region' => $region,
                'credentials' => [
                    'key' => $key,
                    'secret' => $secret,
                ],
            ];

            // Disable SSL verification on localhost
            if (app()->environment('local')) {
                $s3Config['http'] = ['verify' => false];
            }

            $s3Client = new \Aws\S3\S3Client($s3Config);

            // Try uploading
            $s3Client->putObject([
                'Bucket' => $bucket,
                'Key' => $testPath,
                'Body' => $testContent,
            ]);

            $url = $s3Client->getObjectUrl($bucket, $testPath);

            // Clean up test file
            $s3Client->deleteObject([
                'Bucket' => $bucket,
                'Key' => $testPath,
            ]);

            return response()->json([
                'status' => 1,
                'message' => 'S3 connection successful! Upload and delete both working.',
                'data' => [
                    'test_url' => $url,
                    'bucket' => $bucket,
                    'region' => $region,
                ]
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError('S3 test failed: ' . $e->getMessage());
        }
    }

    /**
     * Get support contacts (Public - No Auth Required)
     * GET /api/support-contacts?app=customer|seller|driver
     *
     * Returns the app-specific contact when one is configured, otherwise the
     * global one. Omitting ?app always yields the global pair, so older app
     * builds keep working unchanged.
     */
    public function supportContacts(Request $request)
    {
        try {
            $app = $request->query('app');
            $scoped = in_array($app, Setting::$supportApps, true);

            $variables = ['support_number', 'support_email'];
            if ($scoped) {
                $variables[] = 'support_number_' . $app;
                $variables[] = 'support_email_' . $app;
            }

            $settings = DB::table('settings')
                ->whereIn('variable', $variables)
                ->pluck('value', 'variable');

            $resolve = function ($key) use ($settings, $scoped, $app) {
                if ($scoped) {
                    $value = trim((string) ($settings[$key . '_' . $app] ?? ''));
                    if ($value !== '') return $value;
                }

                $value = trim((string) ($settings[$key] ?? ''));
                return $value !== '' ? $value : null;
            };

            return response()->json([
                'status' => 1,
                'message' => 'Support contacts retrieved successfully',
                'data' => [
                    'phone' => $resolve('support_number'),
                    'email' => $resolve('support_email')
                ]
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get emergency contacts (Public - No Auth Required)
     * GET /api/emergency-contacts
     */
    public function emergencyContacts()
    {
        try {
            $settings = DB::table('settings')
                ->whereIn('variable', [
                    'emergency_zenfoo_phone',
                    'emergency_zenfoo_email',
                    'emergency_police_phone',
                    'emergency_ambulance_phone'
                ])
                ->pluck('value', 'variable');

            return response()->json([
                'status' => 1,
                'message' => 'Emergency contacts retrieved successfully',
                'data' => [
                    'zenfoo_phone' => $settings['emergency_zenfoo_phone'] ?? null,
                    'zenfoo_email' => $settings['emergency_zenfoo_email'] ?? null,
                    'police_phone' => $settings['emergency_police_phone'] ?? null,
                    'ambulance_phone' => $settings['emergency_ambulance_phone'] ?? null
                ]
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Upload video for settings using MediaUploadService
     * POST /api/settings/upload-video
     * Cloud storage ready (AWS S3)
     */
    public function uploadVideo(Request $request)
    {
        try {
            if (!$request->hasFile('file')) {
                return CommonHelper::responseError('No file uploaded');
            }

            $file = $request->file('file');
            $type = $request->input('type', 'settings_video');

            // Use MediaUploadService for upload (validates automatically)
            // This service is cloud-storage ready and handles validation automatically
            $url = MediaUploadService::uploadWithFullUrl($file, 'settings_videos');

            return response()->json([
                'status' => 1,
                'message' => 'Video uploaded successfully',
                'data' => [
                    'url' => $url
                ]
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Upload image for settings using MediaUploadService
     * POST /api/settings/upload-image
     * Cloud storage ready (AWS S3)
     */
    public function uploadImage(Request $request)
    {
        try {
            if (!$request->hasFile('file')) {
                return CommonHelper::responseError('No file uploaded');
            }

            $file = $request->file('file');
            $type = $request->input('type', 'settings_image');

            // Use MediaUploadService for upload (validates automatically)
            // This service is cloud-storage ready and handles validation automatically
            $url = MediaUploadService::uploadWithFullUrl($file, 'settings_images');

            return response()->json([
                'status' => 1,
                'message' => 'Image uploaded successfully',
                'data' => [
                    'url' => $url
                ]
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Upload media file (images, videos, or GIFs) using MediaUploadService
     * Used for flexible uploads like explore logo
     * Cloud storage ready (AWS S3)
     */
    public function uploadMedia(Request $request)
    {
        try {
            if (!$request->hasFile('file')) {
                return CommonHelper::responseError('No file uploaded');
            }

            $file = $request->file('file');
            $type = $request->input('type', 'settings_media');

            // Determine folder based on file type
            $isVideo = strpos($file->getMimeType(), 'video') !== false;
            $folder = $isVideo ? 'settings_videos' : 'settings_images';

            // Use MediaUploadService for upload (supports both images and videos)
            // This service is cloud-storage ready and handles validation automatically
            $url = MediaUploadService::uploadWithFullUrl($file, $folder);

            return response()->json([
                'status' => 1,
                'message' => 'Media uploaded successfully',
                'data' => [
                    'url' => $url,
                    'type' => $isVideo ? 'video' : 'image'
                ]
            ]);
        } catch (\Exception $e) {
            return CommonHelper::responseError($e->getMessage());
        }
    }

    /**
     * Get seller app login background (public, no auth)
     * GET /api/seller/login-bg
     */
    public function getSellerLoginBg()
    {
        $value = \App\Models\Setting::get_value('seller_app_login_bg');

        return response()->json([
            'status' => 1,
            'data' => [
                'seller_app_login_bg' => $value ?: null
            ]
        ]);
    }
}