<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Models\AdminKyc;
use App\Models\AdminLoginLog;
use App\Models\AdminSession;
use App\Models\Department;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class UserManagementController extends Controller
{
    /** Roles that are NOT panel/staff users. */
    private $excludedRoles = ['Seller', 'Delivery Boy'];

    /** Base query: staff/admin accounts only (exclude sellers & delivery boys). */
    private function baseQuery()
    {
        return Admin::whereHas('role', function ($q) {
            $q->whereNotIn('name', $this->excludedRoles);
        });
    }

    /** Resolve the from/to date range from the request (defaults to last 30 days). */
    private function range(Request $request)
    {
        $to = $request->filled('to_date') ? Carbon::parse($request->to_date)->endOfDay() : Carbon::now()->endOfDay();
        $from = $request->filled('from_date') ? Carbon::parse($request->from_date)->startOfDay() : Carbon::now()->subDays(30)->startOfDay();
        return [$from, $to];
    }

    // =====================================================================
    //  OVERVIEW  (stat cards + charts + summaries)
    // =====================================================================
    public function overview(Request $request)
    {
        [$from, $to] = $this->range($request);

        $total       = (clone $this->baseQuery())->count();
        $active      = (clone $this->baseQuery())->where('status', 1)->where('is_blocked', 0)->count();
        $inactive    = (clone $this->baseQuery())->where('status', 0)->where('is_blocked', 0)->count();
        $blocked     = (clone $this->baseQuery())->where('is_blocked', 1)->count();
        $newUsers    = (clone $this->baseQuery())->whereBetween('created_at', [$from, $to])->count();
        $admins      = (clone $this->baseQuery())->whereHas('role', function ($q) {
            $q->whereIn('name', ['Super Admin', 'Admin']);
        })->count();

        // Users by role (donut) — grouped by role NAME so duplicate roles
        // (e.g. several "Super Admin" rows) merge into one clean slice.
        $byRole = (clone $this->baseQuery())
            ->join('roles', 'admins.role_id', '=', 'roles.id')
            ->select('roles.name as name', DB::raw('COUNT(*) as total'))
            ->groupBy('roles.name')->get()
            ->map(function ($row) use ($total) {
                return [
                    'name'       => $row->name,
                    'count'      => (int) $row->total,
                    'percentage' => $total ? round($row->total * 100 / $total, 1) : 0,
                ];
            })->sortByDesc('count')->values();

        // Users by department (bars)
        $byDepartment = Department::withCount(['admins'])->get()->map(function ($d) use ($total) {
            return [
                'name'       => $d->name,
                'color'      => $d->color,
                'count'      => (int) $d->admins_count,
                'percentage' => $total ? round($d->admins_count * 100 / $total, 1) : 0,
            ];
        })->sortByDesc('count')->values();

        // Recent users
        $recent = (clone $this->baseQuery())->with(['role', 'department'])
            ->orderBy('id', 'DESC')->limit(5)->get()
            ->map(function ($a) { return $this->userRow($a); });

        // Top active users (by login_count)
        $topActive = (clone $this->baseQuery())->with(['role'])
            ->orderBy('login_count', 'DESC')->limit(5)->get()
            ->map(function ($a) {
                return [
                    'id'         => $a->id,
                    'name'       => $a->username,
                    'role'       => $a->role ? $a->role->name : null,
                    'logins'     => (int) $a->login_count,
                    'last_login' => $a->login_at,
                    'status'     => $this->statusLabel($a),
                ];
            });

        // Role & permission summary — grouped by role NAME (dedupes duplicate roles)
        $totalPerms = Permission::count();
        $descriptions = [
            'Super Admin'   => 'Full access to system and all modules',
            'Admin'         => 'Manage all operations and configurations',
            'Manager'       => 'Manage operations and team activities',
            'Finance'       => 'Access to finance and settlement modules',
            'Support'       => 'Handle customer support and disputes',
            'Other Staff'   => 'Limited access to assigned modules',
            'Testing'       => 'Testing and QA access',
            'sales manager' => 'Sales and campaign management',
        ];
        $roleSummary = Role::whereNotIn('name', $this->excludedRoles)->get()
            ->groupBy('name')
            ->map(function ($group, $name) use ($totalPerms, $descriptions) {
                $roleIds   = $group->pluck('id')->toArray();
                $userCount = Admin::whereIn('role_id', $roleIds)->count();
                $permCount = DB::table('role_has_permissions')->whereIn('role_id', $roleIds)->distinct()->count('permission_id');
                return [
                    'role'             => $name,
                    'users'            => $userCount,
                    'description'      => $descriptions[$name] ?? 'Custom role access',
                    'permissions'      => ($permCount >= $totalPerms && $totalPerms > 0) ? 'All Permissions' : $permCount . ' Permissions',
                    'permission_count' => $permCount,
                ];
            })->sortByDesc('users')->values();

        // Login activity (last 7 days)
        $loginActivity = $this->loginActivitySeries();

        $data = [
            'stats' => [
                'total_users'    => $total,
                'active_users'   => $active,
                'inactive_users' => $inactive,
                'blocked_users'  => $blocked,
                'new_users'      => $newUsers,
                'administrators' => $admins,
            ],
            'users_by_role'          => $byRole,
            'users_by_status'        => ['active' => $active, 'inactive' => $inactive, 'blocked' => $blocked],
            'users_by_department'    => $byDepartment,
            'recent_users'           => $recent,
            'top_active_users'       => $topActive,
            'role_permission_summary' => $roleSummary,
            'login_activity'         => $loginActivity,
            'security_overview'      => $this->securityData(),
            'range'                  => ['from' => $from->toDateString(), 'to' => $to->toDateString()],
        ];

        return CommonHelper::responseWithData($data);
    }

    private function loginActivitySeries()
    {
        $days = collect();
        for ($i = 6; $i >= 0; $i--) {
            $day = Carbon::now()->subDays($i);
            $success = AdminLoginLog::whereDate('created_at', $day->toDateString())->where('is_success', 1)->count();
            $failed  = AdminLoginLog::whereDate('created_at', $day->toDateString())->where('is_success', 0)->count();
            $days->push([
                'date'    => $day->format('M d'),
                'success' => $success,
                'failed'  => $failed,
            ]);
        }
        return $days->values();
    }

    private function statusLabel($admin)
    {
        if ($admin->is_blocked) return 'Blocked';
        return $admin->status ? 'Active' : 'Inactive';
    }

    private function userRow($a)
    {
        return [
            'id'         => $a->id,
            'user_code'  => 'USR' . str_pad($a->id, 4, '0', STR_PAD_LEFT),
            'name'       => $a->username,
            'email'      => $a->email,
            'mobile'     => $a->mobile,
            'role'       => $a->role ? $a->role->name : null,
            'role_id'    => $a->role_id,
            'department' => $a->department ? $a->department->name : null,
            'department_id' => $a->department_id,
            'status'     => $this->statusLabel($a),
            'is_blocked' => (int) $a->is_blocked,
            'login_count' => (int) $a->login_count,
            'joined_on'  => $a->created_at,
            'last_login' => $a->login_at,
        ];
    }

    // =====================================================================
    //  USERS  (list + CRUD)
    // =====================================================================
    public function users(Request $request)
    {
        $query = $this->baseQuery()->with(['role', 'department']);

        if ($request->filled('search')) {
            $s = $request->search;
            $query->where(function ($q) use ($s) {
                $q->where('username', 'like', "%$s%")
                    ->orWhere('email', 'like', "%$s%")
                    ->orWhere('mobile', 'like', "%$s%");
            });
        }
        if ($request->filled('role_id')) {
            $query->where('role_id', $request->role_id);
        }
        if ($request->filled('department_id')) {
            $query->where('department_id', $request->department_id);
        }
        if ($request->filled('status')) {
            if ($request->status === 'blocked') {
                $query->where('is_blocked', 1);
            } elseif ($request->status === 'active') {
                $query->where('status', 1)->where('is_blocked', 0);
            } elseif ($request->status === 'inactive') {
                $query->where('status', 0)->where('is_blocked', 0);
            }
        }

        $records = $query->orderBy('id', 'DESC')->get()->map(function ($a) { return $this->userRow($a); });

        return CommonHelper::responseWithData([
            'records'     => $records,
            'roles'       => Role::whereNotIn('name', $this->excludedRoles)->get(['id', 'name']),
            'departments' => Department::where('status', 1)->get(['id', 'name']),
        ]);
    }

    public function saveUser(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'username'         => 'required',
            'email'            => 'required|email|unique:admins,email',
            'role_id'          => 'required',
            'password'         => 'min:6|required_with:confirm_password|same:confirm_password',
            'confirm_password' => 'min:6',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $admin = new Admin();
        $admin->username      = $request->username;
        $admin->email         = $request->email;
        $admin->mobile        = $request->mobile;
        $admin->password      = bcrypt($request->password);
        $admin->role_id       = $request->role_id;
        $admin->department_id = $request->department_id;
        $admin->created_by    = auth()->user()->id;
        $admin->status        = 1;
        $admin->save();

        return CommonHelper::responseSuccess('User created successfully!');
    }

    public function updateUser(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id'       => 'required',
            'username' => 'required',
            'email'    => 'required|email|unique:admins,email,' . $request->id,
            'role_id'  => 'required',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $admin = Admin::find($request->id);
        if (!$admin) {
            return CommonHelper::responseError('User not found');
        }
        if ($admin->role && $admin->role->name === 'Super Admin') {
            return CommonHelper::responseError('Super Admin accounts are protected and cannot be edited here.');
        }

        $admin->username      = $request->username;
        $admin->email         = $request->email;
        $admin->mobile        = $request->mobile;
        $admin->role_id       = $request->role_id;
        $admin->department_id = $request->department_id;
        if ($request->filled('status')) {
            $admin->status = (int) $request->status;
        }
        if ($request->filled('password')) {
            $admin->password = bcrypt($request->password);
        }
        $admin->save();

        return CommonHelper::responseSuccess('User updated successfully!');
    }

    public function deleteUser(Request $request)
    {
        $admin = Admin::find($request->id);
        if (!$admin) {
            return CommonHelper::responseSuccess('User already deleted!');
        }
        if ($admin->role && $admin->role->name === 'Super Admin') {
            return CommonHelper::responseError('Super Admin accounts are protected and cannot be deleted.');
        }
        $admin->delete();
        return CommonHelper::responseSuccess('User deleted successfully!');
    }

    public function toggleBlock(Request $request)
    {
        $admin = Admin::find($request->id);
        if (!$admin) {
            return CommonHelper::responseError('User not found');
        }
        if ($admin->role && $admin->role->name === 'Super Admin') {
            return CommonHelper::responseError('Super Admin accounts cannot be blocked.');
        }
        $admin->is_blocked = $admin->is_blocked ? 0 : 1;
        $admin->save();
        return CommonHelper::responseSuccess($admin->is_blocked ? 'User blocked.' : 'User unblocked.');
    }

    // =====================================================================
    //  DEPARTMENTS
    // =====================================================================
    public function departments()
    {
        $records = Department::withCount('admins')->orderBy('name')->get();
        return CommonHelper::responseWithData(['records' => $records]);
    }

    public function saveDepartment(Request $request)
    {
        $validator = Validator::make($request->all(), ['name' => 'required|unique:departments,name']);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        Department::create([
            'name'        => $request->name,
            'color'       => $request->color,
            'description' => $request->description,
            'status'      => $request->filled('status') ? (int) $request->status : 1,
        ]);
        return CommonHelper::responseSuccess('Department created successfully!');
    }

    public function updateDepartment(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id'   => 'required',
            'name' => 'required|unique:departments,name,' . $request->id,
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $dept = Department::find($request->id);
        if (!$dept) return CommonHelper::responseError('Department not found');
        $dept->update([
            'name'        => $request->name,
            'color'       => $request->color,
            'description' => $request->description,
            'status'      => $request->filled('status') ? (int) $request->status : $dept->status,
        ]);
        return CommonHelper::responseSuccess('Department updated successfully!');
    }

    public function deleteDepartment(Request $request)
    {
        $dept = Department::find($request->id);
        if (!$dept) return CommonHelper::responseSuccess('Department already deleted!');
        // Detach admins first (keep accounts intact, just clear the department)
        Admin::where('department_id', $dept->id)->update(['department_id' => null]);
        $dept->delete();
        return CommonHelper::responseSuccess('Department deleted successfully!');
    }

    // =====================================================================
    //  ACTIVITY LOGS  (derived from login events)
    // =====================================================================
    public function activityLogs(Request $request)
    {
        $logs = AdminLoginLog::with('admin.role')
            ->orderBy('created_at', 'DESC')->limit(100)->get()
            ->map(function ($log) {
                return [
                    'id'      => $log->id,
                    'user'    => $log->admin ? $log->admin->username : $log->email,
                    'role'    => $log->admin && $log->admin->role ? $log->admin->role->name : null,
                    'action'  => $log->is_success ? 'Logged in' : 'Failed login attempt',
                    'success' => (int) $log->is_success,
                    'ip'      => $log->ip_address,
                    'device'  => $log->device,
                    'time'    => $log->created_at,
                ];
            });
        return CommonHelper::responseWithData(['records' => $logs]);
    }

    // =====================================================================
    //  LOGIN HISTORY
    // =====================================================================
    public function loginHistory(Request $request)
    {
        $query = AdminLoginLog::with('admin');
        if ($request->filled('status')) {
            $query->where('is_success', $request->status === 'success' ? 1 : 0);
        }
        $records = $query->orderBy('created_at', 'DESC')->limit(200)->get()->map(function ($log) {
            return [
                'id'      => $log->id,
                'user'    => $log->admin ? $log->admin->username : $log->email,
                'email'   => $log->email,
                'ip'      => $log->ip_address,
                'device'  => $log->device,
                'location' => $log->location,
                'status'  => $log->is_success ? 'Success' : 'Failed',
                'time'    => $log->created_at,
            ];
        });
        return CommonHelper::responseWithData(['records' => $records]);
    }

    // =====================================================================
    //  SESSION MANAGEMENT
    // =====================================================================
    public function sessions(Request $request)
    {
        $records = AdminSession::with('admin.role')
            ->orderBy('last_activity', 'DESC')->get()
            ->map(function ($s) {
                return [
                    'id'            => $s->id,
                    'user'          => $s->admin ? $s->admin->username : null,
                    'role'          => $s->admin && $s->admin->role ? $s->admin->role->name : null,
                    'ip'            => $s->ip_address,
                    'device'        => $s->device,
                    'platform'      => $s->platform,
                    'location'      => $s->location,
                    'is_current'    => (int) $s->is_current,
                    'last_activity' => $s->last_activity,
                ];
            });
        return CommonHelper::responseWithData(['records' => $records]);
    }

    public function revokeSession(Request $request)
    {
        $session = AdminSession::find($request->id);
        if (!$session) return CommonHelper::responseSuccess('Session already ended.');
        if ($session->is_current) return CommonHelper::responseError('Cannot revoke the current session.');
        $session->delete();
        return CommonHelper::responseSuccess('Session revoked successfully!');
    }

    // =====================================================================
    //  KYC MANAGEMENT
    // =====================================================================
    public function kycList(Request $request)
    {
        $query = AdminKyc::with('admin.role');
        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        $records = $query->orderBy('created_at', 'DESC')->get()->map(function ($k) {
            return [
                'id'              => $k->id,
                'user'            => $k->admin ? $k->admin->username : null,
                'role'            => $k->admin && $k->admin->role ? $k->admin->role->name : null,
                'document_type'   => $k->document_type,
                'document_number' => $k->document_number,
                'document_file'   => $k->document_file,
                'status'          => $k->status,
                'remarks'         => $k->remarks,
                'verified_at'     => $k->verified_at,
                'submitted_at'    => $k->created_at,
            ];
        });
        $counts = [
            'pending'  => AdminKyc::where('status', 'pending')->count(),
            'approved' => AdminKyc::where('status', 'approved')->count(),
            'rejected' => AdminKyc::where('status', 'rejected')->count(),
        ];
        return CommonHelper::responseWithData(['records' => $records, 'counts' => $counts]);
    }

    public function updateKycStatus(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id'     => 'required',
            'status' => 'required|in:pending,approved,rejected',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $kyc = AdminKyc::find($request->id);
        if (!$kyc) return CommonHelper::responseError('KYC record not found');
        $kyc->status      = $request->status;
        $kyc->remarks     = $request->remarks;
        $kyc->verified_by = auth()->user()->id;
        $kyc->verified_at = in_array($request->status, ['approved', 'rejected']) ? Carbon::now() : null;
        $kyc->save();
        return CommonHelper::responseSuccess('KYC status updated successfully!');
    }

    // =====================================================================
    //  SECURITY OVERVIEW
    // =====================================================================
    public function security(Request $request)
    {
        return CommonHelper::responseWithData(['security_overview' => $this->securityData()]);
    }

    private function securityData()
    {
        $twoFactor   = (clone $this->baseQuery())->where('two_factor_enabled', 1)->count();
        $lockouts    = (clone $this->baseQuery())->where('is_blocked', 1)->count();
        $suspicious  = AdminLoginLog::where('is_success', 0)
            ->where('created_at', '>=', Carbon::now()->subDays(7))->count();
        // Password expired = accounts not updated in > 90 days (proxy signal).
        $expired = (clone $this->baseQuery())
            ->where('updated_at', '<', Carbon::now()->subDays(90))->count();

        return [
            'two_factor_enabled'    => $twoFactor,
            'password_policy'       => 'Strong',
            'session_timeout'       => '30 Minutes',
            'suspicious_activities' => $suspicious,
            'password_expired_users' => $expired,
            'account_lockouts'      => $lockouts,
        ];
    }

    // =====================================================================
    //  EXPORT REPORT  (CSV of users)
    // =====================================================================
    public function export(Request $request)
    {
        $rows = $this->baseQuery()->with(['role', 'department'])->orderBy('id', 'DESC')->get();

        $filename = 'user-management-' . date('Ymd-His') . '.csv';
        $headers = [
            'Content-Type'        => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"$filename\"",
        ];

        $callback = function () use ($rows) {
            $out = fopen('php://output', 'w');
            fputcsv($out, ['User Code', 'Name', 'Email', 'Mobile', 'Role', 'Department', 'Status', 'Logins', 'Joined On', 'Last Login']);
            foreach ($rows as $a) {
                fputcsv($out, [
                    'USR' . str_pad($a->id, 4, '0', STR_PAD_LEFT),
                    $a->username,
                    $a->email,
                    $a->mobile,
                    $a->role ? $a->role->name : '',
                    $a->department ? $a->department->name : '',
                    $this->statusLabel($a),
                    $a->login_count,
                    $a->created_at,
                    $a->login_at,
                ]);
            }
            fclose($out);
        };

        return response()->stream($callback, 200, $headers);
    }
}
