<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddVendorGstPercentToSellersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * Persists the vendor GST rate that applied to a seller at the
     * time they registered, resolved from the seller's store category
     * (is_meat / is_food / is_super_mart / is_vegetable) against the
     * admin-managed Vendor GST Configurations in `settings`.
     *
     * This is a snapshot column - the live rate continues to drive
     * settlements via SellerOrderSettlementService::resolveVendorGstPercent.
     */
    public function up()
    {
        Schema::table('sellers', function (Blueprint $table) {
            if (!Schema::hasColumn('sellers', 'vendor_gst_percent')) {
                $table->decimal('vendor_gst_percent', 5, 2)
                    ->nullable()
                    ->after('commission')
                    ->comment('Snapshot of the admin-configured vendor GST % at the seller\'s store category at registration time.');
            }
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('sellers', function (Blueprint $table) {
            if (Schema::hasColumn('sellers', 'vendor_gst_percent')) {
                $table->dropColumn('vendor_gst_percent');
            }
        });
    }
}
