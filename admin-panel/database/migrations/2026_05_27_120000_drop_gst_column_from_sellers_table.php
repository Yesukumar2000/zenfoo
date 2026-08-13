<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class DropGstColumnFromSellersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * Removes the legacy `gst` column on the sellers table. Its role
     * (per-seller GST rate / fallback when the store has no category
     * flag) is now served by `vendor_gst_percent` which is auto-set at
     * registration time from the admin's Vendor GST Configurations.
     *
     * Before dropping we copy any non-zero gst value into
     * vendor_gst_percent so existing admin overrides survive.
     */
    public function up()
    {
        if (!Schema::hasColumn('sellers', 'gst')) {
            return;
        }

        if (Schema::hasColumn('sellers', 'vendor_gst_percent')) {
            DB::statement('
                UPDATE sellers
                SET vendor_gst_percent = gst
                WHERE vendor_gst_percent IS NULL
                  AND gst IS NOT NULL
                  AND gst > 0
            ');
        }

        Schema::table('sellers', function (Blueprint $table) {
            $table->dropColumn('gst');
        });
    }

    /**
     * Reverse the migrations.
     *
     * Recreates the column as nullable decimal so a rollback restores
     * the schema shape. Values from before the drop are lost.
     */
    public function down()
    {
        if (Schema::hasColumn('sellers', 'gst')) {
            return;
        }

        Schema::table('sellers', function (Blueprint $table) {
            $table->decimal('gst', 5, 2)->nullable()->default(0)
                ->comment('LEGACY - replaced by vendor_gst_percent.');
        });
    }
}
