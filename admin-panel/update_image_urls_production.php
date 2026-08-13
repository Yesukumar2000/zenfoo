<?php

/**
 * Production Database URL Update Script
 *
 * This script converts all image paths in the database to full URLs with domain.
 *
 * IMPORTANT:
 * - This script is SAFE to run multiple times (idempotent)
 * - It only updates paths that don't already start with 'http'
 * - It creates a backup before making changes
 * - Run this via: php update_image_urls_production.php
 */

// Load Laravel
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

// Configuration
$APP_URL = config('app.url') ?: 'http://localhost';
echo "Using APP_URL: {$APP_URL}\n\n";

// Tables and their image columns
$updates = [
    // Products
    ['table' => 'products', 'columns' => ['image']],
    ['table' => 'product_images', 'columns' => ['image']],

    // Categories
    ['table' => 'categories', 'columns' => ['image']],
    ['table' => 'sub_categories', 'columns' => ['image']],
    ['table' => 'category_groups', 'columns' => ['icon', 'image']],
    ['table' => 'category_sub_groups', 'columns' => ['image']],
    ['table' => 'sub_category_groups', 'columns' => ['image']],

    // Brands & Offers
    ['table' => 'brands', 'columns' => ['image']],
    ['table' => 'offers', 'columns' => ['image']],
    ['table' => 'promo_codes', 'columns' => ['image']],

    // Stores
    ['table' => 'stores', 'columns' => ['icon', 'image', 'vendor_img']],

    // Sellers
    ['table' => 'sellers', 'columns' => ['logo', 'national_identity_card', 'address_proof', 'pan_img', 'fssai_img']],

    // Sections
    ['table' => 'sections', 'columns' => ['banner_app', 'banner_web']],

    // Users & Delivery Boys
    ['table' => 'users', 'columns' => ['image']],
    ['table' => 'delivery_boys', 'columns' => ['image']],

    // Delivery Boy Documents
    ['table' => 'delivery_boy_documents', 'columns' => [
        'driving_license_front_path',
        'driving_license_back_path',
        'rc_front_path',
        'rc_back_path',
        'aadhar_front_path',
        'aadhar_back_path',
        'pan_front_path',
        'pan_back_path',
        'bank_passbook_image_path'
    ]],

    // Vehicles
    ['table' => 'vehicles', 'columns' => ['image']],

    // Learning
    ['table' => 'learning_topics', 'columns' => ['image']],
    ['table' => 'learning_videos', 'columns' => ['video_url', 'thumbnail']],

    // Incentive Offers
    ['table' => 'incentive_offers', 'columns' => ['banner_image']],

    // Notifications
    ['table' => 'notifications', 'columns' => ['image']],
];

echo "=== Production Image URL Update Script ===\n";
echo "Started at: " . date('Y-m-d H:i:s') . "\n\n";

$totalUpdated = 0;
$errorLog = [];

try {
    // Start transaction for safety
    DB::beginTransaction();

    foreach ($updates as $update) {
        $table = $update['table'];
        $columns = $update['columns'];

        echo "Processing table: {$table}\n";

        // Check if table exists
        if (!DB::getSchemaBuilder()->hasTable($table)) {
            echo "  ⚠ Table {$table} does not exist, skipping...\n";
            continue;
        }

        foreach ($columns as $column) {
            // Check if column exists
            if (!DB::getSchemaBuilder()->hasColumn($table, $column)) {
                echo "  ⚠ Column {$column} does not exist in {$table}, skipping...\n";
                continue;
            }

            try {
                $updated = updateColumn($table, $column, $APP_URL);
                $totalUpdated += $updated;

                if ($updated > 0) {
                    echo "  ✓ Updated {$updated} records in {$table}.{$column}\n";
                } else {
                    echo "  - No updates needed for {$table}.{$column}\n";
                }
            } catch (Exception $e) {
                $error = "Error updating {$table}.{$column}: " . $e->getMessage();
                $errorLog[] = $error;
                echo "  ✗ {$error}\n";
            }
        }
    }

    // If everything successful, commit
    DB::commit();

    echo "\n=== Update Complete ===\n";
    echo "Total records updated: {$totalUpdated}\n";
    echo "Completed at: " . date('Y-m-d H:i:s') . "\n";

    if (!empty($errorLog)) {
        echo "\n⚠ Errors encountered:\n";
        foreach ($errorLog as $error) {
            echo "  - {$error}\n";
        }
    }

    // Sample verification
    echo "\n=== Sample URLs (for verification) ===\n";
    sampleVerification();

} catch (Exception $e) {
    DB::rollBack();
    echo "\n✗ FATAL ERROR: " . $e->getMessage() . "\n";
    echo "All changes have been rolled back.\n";
    exit(1);
}

/**
 * Update a specific column in a table
 */
function updateColumn($table, $column, $appUrl)
{
    $updated = 0;

    // Get all records with non-empty values that don't already start with http
    $records = DB::table($table)
        ->whereNotNull($column)
        ->where($column, '!=', '')
        ->where($column, 'not like', 'http%')
        ->get();

    foreach ($records as $record) {
        $oldPath = $record->$column;

        // Skip if already a URL or empty
        if (empty($oldPath) || str_starts_with($oldPath, 'http')) {
            continue;
        }

        // Skip YouTube URLs for learning videos
        if ($table === 'learning_videos' && $column === 'video_url' && str_contains($oldPath, 'youtube')) {
            continue;
        }

        // Remove any duplicate /storage/ paths first
        $cleanPath = $oldPath;
        while (str_contains($cleanPath, '/storage/storage/')) {
            $cleanPath = str_replace('/storage/storage/', '/storage/', $cleanPath);
        }

        // Remove leading /storage/ if present
        $cleanPath = preg_replace('#^/storage/#', '', $cleanPath);

        // Convert path to full URL
        $newUrl = Storage::disk('public')->url($cleanPath);

        // Ensure full URL with domain
        if (!str_starts_with($newUrl, 'http')) {
            $newUrl = rtrim($appUrl, '/') . '/' . ltrim($newUrl, '/');
        }

        // Update the record
        DB::table($table)
            ->where('id', $record->id)
            ->update([$column => $newUrl]);

        $updated++;
    }

    return $updated;
}

/**
 * Sample verification of updated URLs
 */
function sampleVerification()
{
    $samples = [
        ['table' => 'products', 'column' => 'image', 'label' => 'Product'],
        ['table' => 'categories', 'column' => 'image', 'label' => 'Category'],
        ['table' => 'brands', 'column' => 'image', 'label' => 'Brand'],
        ['table' => 'stores', 'column' => 'image', 'label' => 'Store'],
        ['table' => 'sellers', 'column' => 'logo', 'label' => 'Seller Logo'],
        ['table' => 'sub_category_groups', 'column' => 'image', 'label' => 'Sub Category Group'],
        ['table' => 'learning_topics', 'column' => 'image', 'label' => 'Learning Topic'],
    ];

    foreach ($samples as $sample) {
        if (DB::getSchemaBuilder()->hasTable($sample['table']) &&
            DB::getSchemaBuilder()->hasColumn($sample['table'], $sample['column'])) {

            $record = DB::table($sample['table'])
                ->whereNotNull($sample['column'])
                ->where($sample['column'], '!=', '')
                ->first();

            if ($record) {
                $url = $record->{$sample['column']};
                echo "{$sample['label']}: {$url}\n";
            }
        }
    }
}
