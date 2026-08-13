<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddVendorCommissionPercentToSellersTable extends Migration
{
    /**
     * Run the migrations.
     *
     * Persists the per-seller commission snapshot resolved from the
     * admin's Vendor Commission Configurations at registration time.
     * Mirrors sellers.vendor_gst_percent. The existing sellers.commission
     * column stays in place as a per-seller override / fallback.
     */
    public function up()
    {
        Schema::table('sellers', function (Blueprint $table) {
            if (!Schema::hasColumn('sellers', 'vendor_commission_percent')) {
                $table->decimal('vendor_commission_percent', 5, 2)
                    ->nullable()
                    ->after('vendor_gst_percent')
                    ->comment('Snapshot of the admin-configured vendor commission % at the seller\'s store category at registration time.');
            }
        });
    }

    public function down()
    {
        Schema::table('sellers', function (Blueprint $table) {
            if (Schema::hasColumn('sellers', 'vendor_commission_percent')) {
                $table->dropColumn('vendor_commission_percent');
            }
        });
    }
}
