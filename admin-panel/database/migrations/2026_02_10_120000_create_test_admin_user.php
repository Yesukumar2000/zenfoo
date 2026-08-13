<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class CreateTestAdminUser extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // Find the admin with ID = 1
        $existingAdmin = DB::table('admins')
            ->where('id', 1)
            ->first();

        if (!$existingAdmin) {
            echo "Warning: Admin with ID=1 not found in database.\n";
            return;
        }

        // Check if test admin already exists
        $testAdminExists = DB::table('admins')
            ->where('email', 'testing@gmail.com')
            ->exists();

        if ($testAdminExists) {
            echo "Test admin already exists, skipping creation.\n";
            return;
        }

        // Create new test admin with same properties
        $testAdminId = DB::table('admins')->insertGetId([
            'username' => 'testadmin',
            'email' => 'testing@gmail.com',
            'password' => Hash::make('Test@123456'), // Changed password for testing
            'role_id' => $existingAdmin->role_id,
            'created_by' => $existingAdmin->id, // Set the original admin as creator
            'forgot_password_code' => null,
            'fcm_id' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Copy role assignments from model_has_roles table if any
        $roleAssignments = DB::table('model_has_roles')
            ->where('model_type', 'App\Models\Admin')
            ->where('model_id', $existingAdmin->id)
            ->get();

        foreach ($roleAssignments as $roleAssignment) {
            DB::table('model_has_roles')->insert([
                'role_id' => $roleAssignment->role_id,
                'model_type' => 'App\Models\Admin',
                'model_id' => $testAdminId,
            ]);
        }

        // Copy direct permission assignments from model_has_permissions table if any
        $permissionAssignments = DB::table('model_has_permissions')
            ->where('model_type', 'App\Models\Admin')
            ->where('model_id', $existingAdmin->id)
            ->get();

        foreach ($permissionAssignments as $permissionAssignment) {
            DB::table('model_has_permissions')->insert([
                'permission_id' => $permissionAssignment->permission_id,
                'model_type' => 'App\Models\Admin',
                'model_id' => $testAdminId,
            ]);
        }

        echo "Test admin created successfully!\n";
        echo "Email: testing@gmail.com\n";
        echo "Password: Test@123456\n";
        echo "Admin ID: {$testAdminId}\n";
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // Remove the test admin user
        $testAdmin = DB::table('admins')
            ->where('email', 'testing@gmail.com')
            ->first();

        if ($testAdmin) {
            // Remove role assignments
            DB::table('model_has_roles')
                ->where('model_type', 'App\Models\Admin')
                ->where('model_id', $testAdmin->id)
                ->delete();

            // Remove permission assignments
            DB::table('model_has_permissions')
                ->where('model_type', 'App\Models\Admin')
                ->where('model_id', $testAdmin->id)
                ->delete();

            // Remove the admin
            DB::table('admins')
                ->where('id', $testAdmin->id)
                ->delete();

            echo "Test admin removed successfully.\n";
        }
    }
}
