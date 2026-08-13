<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Consolidate all settings permissions into a single "manage_settings" permission
     */
    public function up(): void
    {
        // Old permissions to be removed
        $oldPermissions = [
            'manage_store_settings',
            'manage_time_slots',
            'manage_payment_methods',
            'manage_contact_us',
            'manage_about_us',
        ];

        // Get all roles that have any of these old permissions
        $rolesWithOldPermissions = DB::table('role_has_permissions')
            ->join('permissions', 'role_has_permissions.permission_id', '=', 'permissions.id')
            ->whereIn('permissions.name', $oldPermissions)
            ->distinct()
            ->pluck('role_has_permissions.role_id')
            ->toArray();

        // Check if manage_settings permission already exists
        $existingPermission = DB::table('permissions')
            ->where('name', 'manage_settings')
            ->first();

        if (!$existingPermission) {
            // Get category_id from an existing settings permission, or use a default
            $existingSettingsPerm = DB::table('permissions')
                ->where('name', 'manage_store_settings')
                ->first();

            $categoryId = $existingSettingsPerm ? $existingSettingsPerm->category_id : 1;

            // Create new consolidated permission
            $newPermissionId = DB::table('permissions')->insertGetId([
                'name' => 'manage_settings',
                'guard_name' => 'web',
                'category_id' => $categoryId,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        } else {
            $newPermissionId = $existingPermission->id;
        }

        // Assign new permission to all roles that had any of the old permissions
        foreach ($rolesWithOldPermissions as $roleId) {
            // Check if already assigned
            $exists = DB::table('role_has_permissions')
                ->where('role_id', $roleId)
                ->where('permission_id', $newPermissionId)
                ->exists();

            if (!$exists) {
                DB::table('role_has_permissions')->insert([
                    'role_id' => $roleId,
                    'permission_id' => $newPermissionId,
                ]);
            }
        }

        // Get IDs of old permissions
        $oldPermissionIds = DB::table('permissions')
            ->whereIn('name', $oldPermissions)
            ->pluck('id')
            ->toArray();

        // Remove old permissions from role_has_permissions
        DB::table('role_has_permissions')
            ->whereIn('permission_id', $oldPermissionIds)
            ->delete();

        // Remove old permissions from permissions table
        DB::table('permissions')
            ->whereIn('name', $oldPermissions)
            ->delete();
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Recreate old permissions
        $oldPermissions = [
            'manage_store_settings',
            'manage_time_slots',
            'manage_payment_methods',
            'manage_contact_us',
            'manage_about_us',
        ];

        foreach ($oldPermissions as $permName) {
            $exists = DB::table('permissions')->where('name', $permName)->exists();
            if (!$exists) {
                DB::table('permissions')->insert([
                    'name' => $permName,
                    'guard_name' => 'web',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }
    }
};