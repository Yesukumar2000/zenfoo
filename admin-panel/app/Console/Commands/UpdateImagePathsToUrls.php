<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class UpdateImagePathsToUrls extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'images:update-to-urls';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Convert all existing image paths to full URLs in database';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $this->info('Starting image path to URL conversion...');
        $this->newLine();

        $totalUpdated = 0;

        // Define all tables and their image columns
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

            // Web Settings (stored as JSON in settings table)
            // We'll handle this separately
        ];

        foreach ($updates as $update) {
            $table = $update['table'];
            $columns = $update['columns'];

            $this->info("Processing table: {$table}");

            // Check if table exists
            if (!DB::getSchemaBuilder()->hasTable($table)) {
                $this->warn("  ⚠ Table {$table} does not exist, skipping...");
                continue;
            }

            foreach ($columns as $column) {
                // Check if column exists
                if (!DB::getSchemaBuilder()->hasColumn($table, $column)) {
                    $this->warn("  ⚠ Column {$column} does not exist in {$table}, skipping...");
                    continue;
                }

                $updated = $this->updateColumn($table, $column);
                $totalUpdated += $updated;

                if ($updated > 0) {
                    $this->line("  ✓ Updated {$updated} records in {$table}.{$column}");
                }
            }
        }

        $this->newLine();
        $this->info("✅ Conversion complete! Total records updated: {$totalUpdated}");

        return 0;
    }

    /**
     * Update a specific column in a table
     */
    private function updateColumn($table, $column)
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

            // Convert path to full URL
            $newUrl = Storage::disk('public')->url($oldPath);

            // Ensure full URL with domain
            if (!str_starts_with($newUrl, 'http')) {
                $appUrl = config('app.url') ?: 'http://localhost';
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
}
