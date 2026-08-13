<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

class RemoveDeliveryVehicleAssignPermission extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        $tableNames = config('permission.table_names');

        $permissionName = 'delivery_vehicle_assign';

        // Get permission ID
        $permissionId = DB::table($tableNames['permissions'])
            ->where('name', $permissionName)
            ->value('id');

        if ($permissionId) {
            // Delete from role_has_permissions
            DB::table($tableNames['role_has_permissions'])
                ->where('permission_id', $permissionId)
                ->delete();

            // Delete from model_has_permissions (if any direct user assignments exist)
            DB::table($tableNames['model_has_permissions'])
                ->where('permission_id', $permissionId)
                ->delete();

            // Delete the permission
            DB::table($tableNames['permissions'])
                ->where('id', $permissionId)
                ->delete();
        }

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
        $now = now();

        // Get the delivery_vehicle category ID
        $deliveryVehicleCategoryId = DB::table($tableNames['permission_categories'])
            ->where('name', 'delivery_vehicle')
            ->value('id');

        if ($deliveryVehicleCategoryId) {
            // Re-insert the permission
            DB::table($tableNames['permissions'])->insert([
                'name' => 'delivery_vehicle_assign',
                'guard_name' => 'web',
                'category_id' => $deliveryVehicleCategoryId,
                'created_at' => $now,
                'updated_at' => $now
            ]);

            // Get the new permission ID
            $permissionId = DB::table($tableNames['permissions'])
                ->where('name', 'delivery_vehicle_assign')
                ->value('id');

            // Re-assign to role_id 1 and 2
            if ($permissionId) {
                DB::table($tableNames['role_has_permissions'])->insert([
                    ['permission_id' => $permissionId, 'role_id' => 1],
                    ['permission_id' => $permissionId, 'role_id' => 2],
                ]);
            }
        }

        // Clear permission cache
        app('cache')->forget(config('permission.cache.key'));
    }
}
