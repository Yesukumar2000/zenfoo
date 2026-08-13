<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

class AddDriverManagementPermissions extends Migration
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
            ['name' => 'driver_performance', 'guard_name' => 'web', 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'driver_training', 'guard_name' => 'web', 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'driver_support', 'guard_name' => 'web', 'created_at' => $now, 'updated_at' => $now],
        ];

        DB::table($tableNames['permission_categories'])->insert($categories);

        // Get the category IDs
        $driverPerformanceCategoryId = DB::table($tableNames['permission_categories'])
            ->where('name', 'driver_performance')->value('id');
        $driverTrainingCategoryId = DB::table($tableNames['permission_categories'])
            ->where('name', 'driver_training')->value('id');
        $driverSupportCategoryId = DB::table($tableNames['permission_categories'])
            ->where('name', 'driver_support')->value('id');

        // Step 2: Insert new permissions (only 6 permissions for 6 sidebars)
        $permissions = [
            // Driver Performance permissions (3 sidebars)
            ['name' => 'driver_performance_view', 'guard_name' => 'web', 'category_id' => $driverPerformanceCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'driver_leaderboard_view', 'guard_name' => 'web', 'category_id' => $driverPerformanceCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'driver_ratings_view', 'guard_name' => 'web', 'category_id' => $driverPerformanceCategoryId, 'created_at' => $now, 'updated_at' => $now],

            // Driver Training permissions (1 sidebar)
            ['name' => 'driver_training_manage', 'guard_name' => 'web', 'category_id' => $driverTrainingCategoryId, 'created_at' => $now, 'updated_at' => $now],

            // Driver Support permissions (2 sidebars)
            ['name' => 'driver_issues_view', 'guard_name' => 'web', 'category_id' => $driverSupportCategoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'driver_notifications_manage', 'guard_name' => 'web', 'category_id' => $driverSupportCategoryId, 'created_at' => $now, 'updated_at' => $now],
        ];

        DB::table($tableNames['permissions'])->insert($permissions);

        // Step 3: Assign permissions to role_id 1 (Super Admin) and role_id 2 (Admin)
        $permissionNames = [
            'driver_performance_view',
            'driver_leaderboard_view',
            'driver_ratings_view',
            'driver_training_manage',
            'driver_issues_view',
            'driver_notifications_manage',
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
            'driver_performance_view',
            'driver_leaderboard_view',
            'driver_ratings_view',
            'driver_training_manage',
            'driver_issues_view',
            'driver_notifications_manage',
        ];

        $categoryNames = ['driver_performance', 'driver_training', 'driver_support'];

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
