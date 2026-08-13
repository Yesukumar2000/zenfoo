<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Additive-only. All columns are nullable / default-safe so existing admin
 * accounts are NOT modified in any way (auth fields untouched).
 */
class AddUserManagementColumnsToAdminsTable extends Migration
{
    public function up()
    {
        Schema::table('admins', function (Blueprint $table) {
            if (!Schema::hasColumn('admins', 'department_id')) {
                $table->unsignedBigInteger('department_id')->nullable()->after('role_id');
                $table->index('department_id');
            }
            // Distinct "Blocked" state, kept separate from status (1/0) so existing
            // active/inactive logic is unaffected. Default 0 => not blocked.
            if (!Schema::hasColumn('admins', 'is_blocked')) {
                $table->tinyInteger('is_blocked')->default(0)->after('status');
            }
            if (!Schema::hasColumn('admins', 'login_count')) {
                $table->unsignedInteger('login_count')->default(0)->after('is_blocked');
            }
            if (!Schema::hasColumn('admins', 'two_factor_enabled')) {
                $table->tinyInteger('two_factor_enabled')->default(0)->after('login_count');
            }
        });
    }

    public function down()
    {
        Schema::table('admins', function (Blueprint $table) {
            foreach (['department_id', 'is_blocked', 'login_count', 'two_factor_enabled'] as $col) {
                if (Schema::hasColumn('admins', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
}
