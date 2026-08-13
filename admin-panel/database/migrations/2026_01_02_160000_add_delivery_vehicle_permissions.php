<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class AddDeliveryVehiclePermissions extends Migration
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

        // Step 1: Insert new permission category for delivery vehicles
        DB::table($tableNames['permission_categories'])->insert([
            'name' => 'delivery_vehicle',
            'guard_name' => 'web',
            'created_at' => $now,
            'updated_at' => $now
        ]);

        // Get the category ID
        $deliveryVehicleCategoryId = DB::table($tableNames['permission_categories'])
            ->where('name', 'delivery_vehicle')
            ->value('id');

        // Step 2: Insert new permissions for delivery vehicles
        $permissions = [
            [
                'name' => 'delivery_vehicle_list',
                'guard_name' => 'web',
                'category_id' => $deliveryVehicleCategoryId,
                'created_at' => $now,
                'updated_at' => $now
            ],
            [
                'name' => 'delivery_vehicle_create',
                'guard_name' => 'web',
                'category_id' => $deliveryVehicleCategoryId,
                'created_at' => $now,
                'updated_at' => $now
            ],
            [
                'name' => 'delivery_vehicle_update',
                'guard_name' => 'web',
                'category_id' => $deliveryVehicleCategoryId,
                'created_at' => $now,
                'updated_at' => $now
            ],
            [
                'name' => 'delivery_vehicle_delete',
                'guard_name' => 'web',
                'category_id' => $deliveryVehicleCategoryId,
                'created_at' => $now,
                'updated_at' => $now
            ],
            [
                'name' => 'delivery_vehicle_assign',
                'guard_name' => 'web',
                'category_id' => $deliveryVehicleCategoryId,
                'created_at' => $now,
                'updated_at' => $now
            ],
        ];

        DB::table($tableNames['permissions'])->insert($permissions);

        // Step 3: Assign permissions to role_id 1 (Super Admin) and role_id 2 (Admin)
        $permissionNames = [
            'delivery_vehicle_list',
            'delivery_vehicle_create',
            'delivery_vehicle_update',
            'delivery_vehicle_delete',
            'delivery_vehicle_assign',
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
            'delivery_vehicle_list',
            'delivery_vehicle_create',
            'delivery_vehicle_update',
            'delivery_vehicle_delete',
            'delivery_vehicle_assign',
        ];

        $categoryName = 'delivery_vehicle';

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
            ->where('name', $categoryName)
            ->delete();

        // Clear permission cache
        app('cache')->forget(config('permission.cache.key'));
    }
}
