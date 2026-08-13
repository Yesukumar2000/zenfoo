<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class AddStoreLocationPermissions extends Migration
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

        // Insert new permission category
        DB::table($tableNames['permission_categories'])->insert([
            'name' => 'store_locations',
            'guard_name' => 'web',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        // Get the category ID
        $categoryId = DB::table($tableNames['permission_categories'])
            ->where('name', 'store_locations')
            ->value('id');

        // Insert permissions
        $permissions = [
            ['name' => 'store_location_list', 'guard_name' => 'web', 'category_id' => $categoryId, 'created_at' => $now, 'updated_at' => $now],
            ['name' => 'store_location_edit', 'guard_name' => 'web', 'category_id' => $categoryId, 'created_at' => $now, 'updated_at' => $now],
        ];

        DB::table($tableNames['permissions'])->insert($permissions);

        // Assign permissions to role_id 1 (Super Admin) and role_id 2 (Admin)
        $permissionNames = [
            'store_location_list',
            'store_location_edit',
        ];

        $permissionIds = DB::table($tableNames['permissions'])
            ->whereIn('name', $permissionNames)
            ->pluck('id');

        $rolePermissions = [];
        foreach ($permissionIds as $permissionId) {
            $rolePermissions[] = ['permission_id' => $permissionId, 'role_id' => 1];
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
            'store_location_list',
            'store_location_edit',
        ];

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

        // Delete category
        DB::table($tableNames['permission_categories'])
            ->where('name', 'store_locations')
            ->delete();

        // Clear permission cache
        app('cache')->forget(config('permission.cache.key'));
    }
}
