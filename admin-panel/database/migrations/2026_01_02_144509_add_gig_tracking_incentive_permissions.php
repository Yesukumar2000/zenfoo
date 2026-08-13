<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class AddGigTrackingIncentivePermissions extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        $tableNames = config('permission.table_names');
        $now = now();

        // Step 1: Insert new permission categories
        $categories = [
            ['name' => 'gig_management', 'guard_name' => 'web', 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'gig_booking', 'guard_name' => 'web', 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'delivery_tracking', 'guard_name' => 'web', 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'incentive_offers', 'guard_name' => 'web', 'created_at' => $now, 'updated_at' => $now],
        ];

        DB::table($tableNames['permission_categories'])->insert($categories);

        // Get the category IDs
        $gigManagementCategoryId = DB::table($tableNames['permission_categories'])
            ->where('name', 'gig_management')->value('id');
        $gigBookingCategoryId = DB::table($tableNames['permission_categories'])
            ->where('name', 'gig_booking')->value('id');
        $deliveryTrackingCategoryId = DB::table($tableNames['permission_categories'])
            ->where('name', 'delivery_tracking')->value('id');
        $incentiveOffersCategoryId = DB::table($tableNames['permission_categories'])
            ->where('name', 'incentive_offers')->value('id');

        // Step 2: Insert new permissions
        $permissions = [
            // Gig Management permissions
            ['name' => 'gig_list', 'guard_name' => 'web', 'category_id' => $gigManagementCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'gig_create', 'guard_name' => 'web', 'category_id' => $gigManagementCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'gig_update', 'guard_name' => 'web', 'category_id' => $gigManagementCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'gig_delete', 'guard_name' => 'web', 'category_id' => $gigManagementCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'gig_calendar_view', 'guard_name' => 'web', 'category_id' => $gigManagementCategoryId, 'created_at' => $now, 'updated_at' => $now],

            // Gig Booking permissions
            ['name' => 'gig_booking_list', 'guard_name' => 'web', 'category_id' => $gigBookingCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'gig_booking_update', 'guard_name' => 'web', 'category_id' => $gigBookingCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'gig_booking_delete', 'guard_name' => 'web', 'category_id' => $gigBookingCategoryId, 'created_at' => $now, 'updated_at' => $now],

            // Delivery Tracking permissions
            ['name' => 'live_tracking_view', 'guard_name' => 'web', 'category_id' => $deliveryTrackingCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'session_history_list', 'guard_name' => 'web', 'category_id' => $deliveryTrackingCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'daily_reports_view', 'guard_name' => 'web', 'category_id' => $deliveryTrackingCategoryId, 'created_at' => $now, 'updated_at' => $now],

            // Incentive Offers permissions
            ['name' => 'offer_list', 'guard_name' => 'web', 'category_id' => $incentiveOffersCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'offer_create', 'guard_name' => 'web', 'category_id' => $incentiveOffersCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'offer_update', 'guard_name' => 'web', 'category_id' => $incentiveOffersCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'offer_delete', 'guard_name' => 'web', 'category_id' => $incentiveOffersCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'active_offers_view', 'guard_name' => 'web', 'category_id' => $incentiveOffersCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'partner_progress_view', 'guard_name' => 'web', 'category_id' => $incentiveOffersCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'payout_management', 'guard_name' => 'web', 'category_id' => $incentiveOffersCategoryId, 'created_at' => $now, 'updated_at' => $now],
        ];

        DB::table($tableNames['permissions'])->insert($permissions);

        // Step 3: Assign permissions to role_id 1 (Super Admin) and role_id 2 (Admin)
        $permissionNames = [
            'gig_list', 'gig_create', 'gig_update', 'gig_delete', 'gig_calendar_view',
            'gig_booking_list', 'gig_booking_update', 'gig_booking_delete',
            'live_tracking_view', 'session_history_list', 'daily_reports_view',
            'offer_list', 'offer_create', 'offer_update', 'offer_delete',
            'active_offers_view', 'partner_progress_view', 'payout_management',
        ];

        $permissionIds = DB::table($tableNames['permissions'])
            ->whereIn('name', $permissionNames)
            ->pluck('id');

        $rolePermissions = [];
        foreach ($permissionIds as $permissionId) {
            // For role_id 1 (Super Admin)
            $rolePermissions[] = ['permission_id' => $permissionId, 'role_id' => 1];
            // For role_id 2 (Admin)
            $rolePermissions[] = ['permission_id' => $permissionId, 'role_id' => 2];
        }

        DB::table($tableNames['role_has_permissions'])->insert($rolePermissions);

        // Clear permission cache
        app('cache')->forget(config('permission.cache.key'));
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        $tableNames = config('permission.table_names');

        $permissionNames = [
            'gig_list', 'gig_create', 'gig_update', 'gig_delete', 'gig_calendar_view',
            'gig_booking_list', 'gig_booking_update', 'gig_booking_delete',
            'live_tracking_view', 'session_history_list', 'daily_reports_view',
            'offer_list', 'offer_create', 'offer_update', 'offer_delete',
            'active_offers_view', 'partner_progress_view', 'payout_management',
        ];

        $categoryNames = ['gig_management', 'gig_booking', 'delivery_tracking', 'incentive_offers'];

        // Get permission IDs before deleting
        $permissionIds = DB::table($tableNames['permissions'])
            ->whereIn('name', $permissionNames)
            ->pluck('id');

        // Delete from role_has_permissions
        DB::table($tableNames['role_has_permissions'])
            ->whereIn('permission_id', $permissionIds)
            ->delete();

        // Delete permissions
        DB::table($tableNames['permissions'])
            ->whereIn('name', $permissionNames)
            ->delete();

        // Delete categories
        DB::table($tableNames['permission_categories'])
            ->whereIn('name', $categoryNames)
            ->delete();

        // Clear permission cache
        app('cache')->forget(config('permission.cache.key'));
    }
}
