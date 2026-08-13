<?php

namespace Database\Seeders;

use App\Models\Admin;
use App\Models\AdminKyc;
use App\Models\AdminLoginLog;
use App\Models\AdminSession;
use App\Models\Department;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use Spatie\Permission\Models\Role;

/**
 * Seeds sample data for the User Management dashboard so every chart / counter
 * is populated (including inactive & blocked states) for a rich UI.
 *
 * SAFETY:
 *  - EXISTING accounts: only the additive columns (department_id, login_count)
 *    are touched. Credentials, email, role_id, status, is_blocked are untouched.
 *  - SAMPLE accounts are brand-new, tagged with the @sample.zenfoo email domain
 *    (easy to identify / purge) and given random un-guessable passwords.
 *  - All inserts are guarded so re-running is safe.
 */
class UserManagementSeeder extends Seeder
{
    public function run()
    {
        // 1) Departments -------------------------------------------------
        $departments = [
            ['name' => 'Operations', 'color' => '#7c5cfc'],
            ['name' => 'Finance',    'color' => '#22c55e'],
            ['name' => 'Support',    'color' => '#3b82f6'],
            ['name' => 'Marketing',  'color' => '#f59e0b'],
            ['name' => 'IT',         'color' => '#ef4444'],
            ['name' => 'Other',      'color' => '#14b8a6'],
        ];
        foreach ($departments as $d) {
            Department::firstOrCreate(['name' => $d['name']], ['color' => $d['color'], 'status' => 1]);
        }
        $deptIds = Department::pluck('id')->toArray();

        // 2) Extra roles for a varied "Users by Role" chart -------------
        foreach (['Manager', 'Finance', 'Support', 'Other Staff'] as $roleName) {
            Role::firstOrCreate(['name' => $roleName, 'guard_name' => 'web']);
        }
        // Role pool for sample users (weighted to resemble the reference UI)
        $rolePool = [];
        foreach (['Admin' => 5, 'Manager' => 5, 'Support' => 4, 'Finance' => 2, 'Other Staff' => 3] as $name => $weight) {
            $role = Role::where('name', $name)->where('guard_name', 'web')->first();
            if ($role) {
                for ($w = 0; $w < $weight; $w++) $rolePool[] = $role->id;
            }
        }

        // 3) Sample users (only if none exist yet) ----------------------
        $firstNames = ['Rajesh', 'Priya', 'Arjun', 'Neha', 'Imran', 'Vikram', 'Ananya', 'Rohit', 'Sneha', 'Karan',
            'Divya', 'Aditya', 'Meera', 'Sameer', 'Pooja', 'Nikhil', 'Kavya', 'Rahul', 'Isha', 'Varun',
            'Tara', 'Manish', 'Ritu', 'Gaurav', 'Shreya', 'Dev', 'Nisha', 'Yash', 'Anjali', 'Sahil',
            'Mohan', 'Reena', 'Amit', 'Swati', 'Kunal', 'Deepa'];
        $lastNames = ['Kumar', 'Singh', 'Mehta', 'Verma', 'Khan', 'Patel', 'Sharma', 'Reddy', 'Nair', 'Iyer',
            'Gupta', 'Bose', 'Das', 'Rao', 'Joshi', 'Malhotra'];

        if (Admin::where('email', 'like', '%@sample.zenfoo')->count() === 0 && !empty($rolePool)) {
            for ($i = 0; $i < 36; $i++) {
                $name = $firstNames[$i % count($firstNames)] . ' ' . $lastNames[$i % count($lastNames)];
                $mod  = $i % 12;
                $status    = ($mod === 9 || $mod === 10) ? 0 : 1;          // ~17% inactive
                $isBlocked = ($mod === 11) ? 1 : 0;                        // ~8% blocked

                Admin::create([
                    'username'           => $name,
                    'email'              => strtolower($firstNames[$i % count($firstNames)]) . ($i + 1) . '@sample.zenfoo',
                    'mobile'             => '90' . str_pad((string) (100000000 + $i * 137), 8, '0', STR_PAD_LEFT),
                    'password'           => bcrypt(Str::random(24)),
                    'role_id'            => $rolePool[$i % count($rolePool)],
                    'department_id'      => $deptIds[$i % count($deptIds)],
                    'created_by'         => 1,
                    'status'             => $status,
                    'is_blocked'         => $isBlocked,
                    'login_count'        => 5 + (($i * 13) % 80),
                    'two_factor_enabled' => ($i % 3 === 0) ? 1 : 0,
                    'login_at'           => Carbon::now()->subHours(($i * 7) % 200),
                ]);
            }
        }

        // Staff admins (existing + samples), excluding sellers & delivery boys
        $staff = Admin::whereHas('role', function ($q) {
            $q->whereNotIn('name', ['Seller', 'Delivery Boy']);
        })->get();

        // 4) Existing accounts: set department + login_count ONLY (additive)
        $i = 0;
        foreach ($staff as $admin) {
            if (Str::endsWith($admin->email, '@sample.zenfoo')) { $i++; continue; }
            $update = [];
            if (empty($admin->department_id) && !empty($deptIds)) {
                $update['department_id'] = $deptIds[$i % count($deptIds)];
            }
            if ((int) $admin->login_count === 0) {
                $update['login_count'] = 15 + (($admin->id * 7) % 45);
            }
            if (!empty($update)) {
                Admin::where('id', $admin->id)->update($update);
            }
            $i++;
        }

        // 5) Login logs (only if empty) ---------------------------------
        if (AdminLoginLog::count() === 0 && $staff->count() > 0) {
            $devices = ['Chrome on Windows', 'Safari on macOS', 'Chrome on Android', 'Edge on Windows'];
            $cities  = ['Hyderabad, IN', 'Bengaluru, IN', 'Mumbai, IN', 'Delhi, IN'];
            $rows = [];
            foreach ($staff as $idx => $admin) {
                for ($d = 0; $d < 7; $d++) {
                    $count = 1 + (($admin->id + $d) % 3);
                    for ($c = 0; $c < $count; $c++) {
                        $rows[] = [
                            'admin_id'   => $admin->id,
                            'email'      => $admin->email,
                            'ip_address' => '103.' . (($admin->id * 3) % 255) . '.' . (($d * 11) % 255) . '.' . (($c * 17) % 255),
                            'user_agent' => 'Mozilla/5.0',
                            'device'     => $devices[($admin->id + $d) % count($devices)],
                            'location'   => $cities[$admin->id % count($cities)],
                            'is_success' => 1,
                            'created_at' => Carbon::now()->subDays($d)->subHours(($c * 3) % 20),
                            'updated_at' => Carbon::now()->subDays($d),
                        ];
                    }
                }
                if ($idx % 3 === 0) {
                    $rows[] = [
                        'admin_id'   => $admin->id,
                        'email'      => $admin->email,
                        'ip_address' => '45.' . (($admin->id * 5) % 255) . '.10.20',
                        'user_agent' => 'Mozilla/5.0',
                        'device'     => $devices[$admin->id % count($devices)],
                        'location'   => $cities[($admin->id + 1) % count($cities)],
                        'is_success' => 0,
                        'created_at' => Carbon::now()->subDays($admin->id % 6)->subHours(2),
                        'updated_at' => Carbon::now(),
                    ];
                }
            }
            foreach (array_chunk($rows, 300) as $chunk) {
                AdminLoginLog::insert($chunk);
            }
        }

        // 6) Sessions (only if empty) -----------------------------------
        if (AdminSession::count() === 0 && $staff->count() > 0) {
            $platforms = ['Windows', 'macOS', 'Android', 'iOS'];
            $devices   = ['Chrome', 'Safari', 'Edge', 'Firefox'];
            $cities    = ['Hyderabad, IN', 'Bengaluru, IN', 'Mumbai, IN', 'Delhi, IN'];
            foreach ($staff as $idx => $admin) {
                $sessCount = 1 + ($admin->id % 2);
                for ($s = 0; $s < $sessCount; $s++) {
                    AdminSession::create([
                        'admin_id'      => $admin->id,
                        'session_id'    => 'sess_' . $admin->id . '_' . $s,
                        'ip_address'    => '103.' . (($admin->id * 4) % 255) . '.5.' . $s,
                        'user_agent'    => 'Mozilla/5.0',
                        'device'        => $devices[($admin->id + $s) % count($devices)],
                        'platform'      => $platforms[($admin->id + $s) % count($platforms)],
                        'location'      => $cities[$admin->id % count($cities)],
                        'is_current'    => ($idx === 0 && $s === 0) ? 1 : 0,
                        'last_activity' => Carbon::now()->subMinutes(($admin->id * 7 + $s * 13) % 240),
                    ]);
                }
            }
        }

        // 7) KYC (only if empty) ----------------------------------------
        if (AdminKyc::count() === 0 && $staff->count() > 0) {
            $types    = ['Aadhaar', 'PAN Card', 'Passport', 'Driving License'];
            $statuses = ['approved', 'pending', 'rejected'];
            foreach ($staff as $idx => $admin) {
                if ($idx % 2 !== 0) continue;
                $status = $statuses[$admin->id % count($statuses)];
                AdminKyc::create([
                    'admin_id'        => $admin->id,
                    'document_type'   => $types[$admin->id % count($types)],
                    'document_number' => 'DOC' . str_pad((string) $admin->id, 6, '0', STR_PAD_LEFT),
                    'status'          => $status,
                    'remarks'         => $status === 'rejected' ? 'Document unclear, please re-upload.' : null,
                    'verified_at'     => $status === 'pending' ? null : Carbon::now()->subDays($admin->id % 20),
                ]);
            }
        }
    }
}
