<?php

namespace Database\Seeders;

use App\Models\Language;
use App\Models\SupportedLanguage;
use Illuminate\Database\Seeder;

/**
 * Seeds the Urdu (ur) language for the Seller & Delivery Boy app (system_type = 2).
 *
 * The translation strings live in database/seeders/data/zenfoo_driver_ur.json
 * (the same file shipped as assets/ur.json in the driver app). json_data is
 * stored as a raw JSON string, matching how LanguageApiController persists it.
 *
 * Idempotent: running it again updates the existing row instead of duplicating.
 *
 * Run with:  php artisan db:seed --class=Database\\Seeders\\UrduDriverLanguageSeeder
 */
class UrduDriverLanguageSeeder extends Seeder
{
    public function run()
    {
        $systemType = Language::$systemTypeSellerAndDeliveryBoyApp; // 2

        // 1. Make sure Urdu exists in supported_languages (rtl).
        $supported = SupportedLanguage::firstOrCreate(
            ['code' => 'ur'],
            ['name' => 'Urdu', 'type' => 'rtl']
        );

        // 2. Load the translation map (raw JSON string, as stored by the API).
        $jsonPath = database_path('seeders/data/zenfoo_driver_ur.json');
        if (!file_exists($jsonPath)) {
            $this->command->error("Missing translations file: {$jsonPath}");
            return;
        }
        $jsonData = file_get_contents($jsonPath);
        if (json_decode($jsonData) === null) {
            $this->command->error("zenfoo_driver_ur.json is not valid JSON; aborting.");
            return;
        }

        // 3. Upsert the languages row for system_type = 2 (do not change the
        //    existing default language).
        $language = Language::where('supported_language_id', $supported->id)
            ->where('system_type', $systemType)
            ->first();

        if ($language) {
            $language->json_data = $jsonData;
            $language->display_name = 'اردو';
            $language->status = 1;
            $language->save();
            $this->command->info('Updated existing Urdu language for the driver app (system_type=2).');
        } else {
            $language = new Language();
            $language->system_type = $systemType;
            $language->supported_language_id = $supported->id;
            $language->json_data = $jsonData;
            $language->display_name = 'اردو';
            $language->is_default = 0; // keep the current default untouched
            $language->status = 1;
            $language->save();
            $this->command->info('Created Urdu language for the driver app (system_type=2).');
        }
    }
}
