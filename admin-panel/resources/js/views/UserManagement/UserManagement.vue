<template>
    <div class="user-management">
        <div class="page-heading">
            <!-- Header -->
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3 class="mb-0">User Management</h3>
                        <p class="text-subtitle text-muted mb-0">Manage admin users, roles, permissions and access control.</p>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">Dashboard</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">User Management</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <!-- Toolbar -->
            <div class="d-flex flex-wrap justify-content-end align-items-end um-gap mb-3">
                <div>
                    <label class="small text-muted d-block mb-1">From</label>
                    <input type="date" v-model="fromDate" class="form-control form-control-sm" />
                </div>
                <div>
                    <label class="small text-muted d-block mb-1">To</label>
                    <input type="date" v-model="toDate" class="form-control form-control-sm" />
                </div>
                <button class="btn btn-sm btn-outline-secondary" @click="loadOverview"><i class="fa fa-filter me-1"></i> Apply</button>
                <a class="btn btn-sm btn-outline-primary" :href="exportUrl" target="_blank"><i class="fa fa-download me-1"></i> Export Report</a>
            </div>

            <!-- Stat cards -->
            <div class="row um-stats">
                <div class="col-6 col-md-4 col-xl-2" v-for="card in statCards" :key="card.key">
                    <div class="card stat-card">
                        <div class="card-body">
                            <span class="stat-icon" :style="{ background: card.bg, color: card.color }"><i :class="'fa ' + card.icon"></i></span>
                            <div class="stat-label">{{ card.label }}</div>
                            <div class="stat-value">{{ stats[card.key] }}</div>
                            <div class="stat-sub" :style="{ color: card.color }">{{ subFor(card.key) }}</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tabs -->
            <ul class="nav nav-tabs um-tabs mt-2 mb-3 flex-nowrap overflow-auto">
                <li class="nav-item" v-for="t in tabs" :key="t.key">
                    <a class="nav-link" :class="{ active: activeTab === t.key }" href="javascript:void(0)" @click="switchTab(t.key)">{{ t.label }}</a>
                </li>
            </ul>

            <!-- ================= USER OVERVIEW ================= -->
            <div v-show="activeTab === 'overview'">
                <div class="row">
                    <!-- Users by Role -->
                    <div class="col-12 col-xl-4">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Users by Role</h5></div>
                            <div class="card-body">
                                <div class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                    <div class="donut-wrap">
                                        <apexchart v-if="roleChart.series.length" type="donut" height="185"
                                                   :options="roleChart.options" :series="roleChart.series"></apexchart>
                                        <p v-else class="text-muted text-center my-5">No data</p>
                                    </div>
                                    <ul class="legend-list">
                                        <li v-for="(r,i) in roleLegend" :key="i">
                                            <span class="dot" :style="{ background: colorAt(i) }"></span>
                                            <span class="lg-name">{{ r.name }}</span>
                                            <span class="lg-val">{{ r.count }} <small>({{ r.percentage }}%)</small></span>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- Users by Status -->
                    <div class="col-12 col-xl-4">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Users by Status</h5></div>
                            <div class="card-body">
                                <div class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                    <div class="donut-wrap">
                                        <apexchart v-if="statusChart.series.length" type="donut" height="185"
                                                   :options="statusChart.options" :series="statusChart.series"></apexchart>
                                        <p v-else class="text-muted text-center my-5">No data</p>
                                    </div>
                                    <ul class="legend-list">
                                        <li v-for="(s,i) in statusLegend" :key="i">
                                            <span class="dot" :style="{ background: s.color }"></span>
                                            <span class="lg-name">{{ s.name }}</span>
                                            <span class="lg-val">{{ s.count }} <small>({{ s.percentage }}%)</small></span>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- Users by Department -->
                    <div class="col-12 col-xl-4">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Users by Department</h5></div>
                            <div class="card-body">
                                <div v-if="overview.users_by_department && overview.users_by_department.length" class="dept-list">
                                    <div class="dept-row" v-for="(d,i) in overview.users_by_department" :key="i">
                                        <span class="dept-name">{{ d.name }}</span>
                                        <span class="dept-track"><span class="dept-fill" :style="{ width: barWidth(d.count) + '%', background: d.color || colorAt(i) }"></span></span>
                                        <span class="dept-val">{{ d.count }} <small>({{ d.percentage }}%)</small></span>
                                    </div>
                                </div>
                                <p v-else class="text-muted text-center my-5">No department data</p>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row mt-2">
                    <!-- Recent Users -->
                    <div class="col-12">
                        <div class="card">
                            <div class="card-header"><h5 class="mb-0">Recent Users</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>User</th><th>Email</th><th>Role</th><th>Dept.</th><th>Status</th></tr></thead>
                                    <tbody>
                                        <tr v-for="u in overview.recent_users" :key="u.id">
                                            <td class="fw-medium">{{ u.name }}</td>
                                            <td class="small text-muted">{{ u.email }}</td>
                                            <td>{{ u.role }}</td>
                                            <td>{{ u.department || '-' }}</td>
                                            <td><span class="badge" :class="statusClass(u.status)">{{ u.status }}</span></td>
                                        </tr>
                                        <tr v-if="!overview.recent_users || !overview.recent_users.length"><td colspan="5" class="text-center text-muted">No users</td></tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                    <!-- Top Active Users -->
                    <div class="col-12">
                        <div class="card">
                            <div class="card-header"><h5 class="mb-0">Top Active Users</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>User</th><th>Role</th><th>Logins</th><th>Last Login</th><th>Status</th></tr></thead>
                                    <tbody>
                                        <tr v-for="u in overview.top_active_users" :key="u.id">
                                            <td class="fw-medium">{{ u.name }}</td>
                                            <td>{{ u.role }}</td>
                                            <td><span class="badge bg-light text-dark">{{ u.logins }}</span></td>
                                            <td class="small text-muted">{{ u.last_login | dt }}</td>
                                            <td><span class="badge" :class="statusClass(u.status)">{{ u.status }}</span></td>
                                        </tr>
                                        <tr v-if="!overview.top_active_users || !overview.top_active_users.length"><td colspan="5" class="text-center text-muted">No data</td></tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <!-- Role & Permission Summary -->
                    <div class="col-12">
                        <div class="card">
                            <div class="card-header"><h5 class="mb-0">Role &amp; Permission Summary</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-2">
                                    <thead><tr><th>Role</th><th>Users</th><th>Description</th><th>Permissions</th></tr></thead>
                                    <tbody>
                                        <tr v-for="(r,i) in overview.role_permission_summary" :key="i">
                                            <td class="fw-medium">{{ r.role }}</td>
                                            <td>{{ r.users }}</td>
                                            <td class="small text-muted">{{ r.description }}</td>
                                            <td><span class="badge bg-light text-dark">{{ r.permissions }}</span></td>
                                        </tr>
                                    </tbody>
                                </table>
                                <router-link to="/role" class="small fw-medium">Manage Roles &amp; Permissions →</router-link>
                            </div>
                        </div>
                    </div>
                    <!-- Login Activity -->
                    <div class="col-12 col-lg-8">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Login Activity (Last 7 Days)</h5></div>
                            <div class="card-body">
                                <apexchart v-if="loginChart.series.length" type="line" height="240"
                                           :options="loginChart.options" :series="loginChart.series"></apexchart>
                            </div>
                        </div>
                    </div>
                    <!-- Security Overview -->
                    <div class="col-12 col-lg-4">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Security Overview</h5></div>
                            <div class="card-body">
                                <ul class="security-list mb-0">
                                    <li><i class="fa fa-shield-alt sec-ic text-success"></i><span>Two-Factor Auth</span><b>{{ security.two_factor_enabled }} users</b></li>
                                    <li><i class="fa fa-key sec-ic text-primary"></i><span>Password Policy</span><b>{{ security.password_policy }}</b></li>
                                    <li><i class="fa fa-clock sec-ic text-info"></i><span>Session Timeout</span><b>{{ security.session_timeout }}</b></li>
                                    <li><i class="fa fa-exclamation-triangle sec-ic text-warning"></i><span>Suspicious (7d)</span><b class="text-warning">{{ security.suspicious_activities }}</b></li>
                                    <li><i class="fa fa-user-clock sec-ic text-secondary"></i><span>Password Expired</span><b>{{ security.password_expired_users }}</b></li>
                                    <li><i class="fa fa-lock sec-ic text-danger"></i><span>Account Lockouts</span><b class="text-danger">{{ security.account_lockouts }}</b></li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ================= USERS ================= -->
            <div v-show="activeTab === 'users'">
                <div class="card">
                    <div class="card-header d-flex flex-wrap um-gap align-items-center">
                        <h5 class="mb-0 me-auto">Users</h5>
                        <input v-model="userFilters.search" type="search" class="form-control form-control-sm w-auto" placeholder="Search..." @keyup.enter="loadUsers" />
                        <select v-model="userFilters.role_id" class="form-select form-select-sm w-auto" @change="loadUsers">
                            <option value="">All Roles</option>
                            <option v-for="r in roles" :key="r.id" :value="r.id">{{ r.name }}</option>
                        </select>
                        <select v-model="userFilters.department_id" class="form-select form-select-sm w-auto" @change="loadUsers">
                            <option value="">All Departments</option>
                            <option v-for="d in departments" :key="d.id" :value="d.id">{{ d.name }}</option>
                        </select>
                        <select v-model="userFilters.status" class="form-select form-select-sm w-auto" @change="loadUsers">
                            <option value="">All Status</option>
                            <option value="active">Active</option>
                            <option value="inactive">Inactive</option>
                            <option value="blocked">Blocked</option>
                        </select>
                    </div>
                    <div class="card-body table-responsive">
                        <table class="table align-middle">
                            <thead><tr><th>Code</th><th>Name</th><th>Email</th><th>Role</th><th>Dept.</th><th>Status</th><th>Logins</th><th>Actions</th></tr></thead>
                            <tbody>
                                <tr v-for="u in users" :key="u.id">
                                    <td>{{ u.user_code }}</td>
                                    <td class="fw-medium">{{ u.name }}</td>
                                    <td class="small text-muted">{{ u.email }}</td>
                                    <td>{{ u.role }}</td>
                                    <td>{{ u.department || '-' }}</td>
                                    <td><span class="badge" :class="statusClass(u.status)">{{ u.status }}</span></td>
                                    <td>{{ u.login_count }}</td>
                                    <td>
                                        <template v-if="u.role !== 'Super Admin'">
                                            <button class="btn btn-sm btn-primary" @click="openUserModal(u)"><i class="fa fa-pencil-alt"></i></button>
                                            <button class="btn btn-sm" :class="u.is_blocked ? 'btn-success' : 'btn-warning'" @click="toggleBlock(u)"><i class="fa" :class="u.is_blocked ? 'fa-unlock' : 'fa-ban'"></i></button>
                                            <button class="btn btn-sm btn-danger" @click="deleteUser(u)"><i class="fa fa-trash"></i></button>
                                        </template>
                                        <span v-else class="text-muted small"><i class="fa fa-shield-alt"></i> Protected</span>
                                    </td>
                                </tr>
                                <tr v-if="!users.length"><td colspan="8" class="text-center text-muted">No users found</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- ================= ROLES & PERMISSIONS ================= -->
            <div v-show="activeTab === 'roles'">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">Roles &amp; Permissions</h5>
                        <router-link to="/role" class="btn btn-sm btn-primary">Open Role Manager</router-link>
                    </div>
                    <div class="card-body table-responsive">
                        <table class="table align-middle">
                            <thead><tr><th>Role</th><th>Users</th><th>Description</th><th>Permissions</th></tr></thead>
                            <tbody>
                                <tr v-for="(r,i) in overview.role_permission_summary" :key="i">
                                    <td class="fw-medium">{{ r.role }}</td><td>{{ r.users }}</td>
                                    <td class="small text-muted">{{ r.description }}</td>
                                    <td><span class="badge bg-light text-dark">{{ r.permissions }}</span></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- ================= DEPARTMENTS ================= -->
            <div v-show="activeTab === 'departments'">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">Departments</h5>
                        <button class="btn btn-sm btn-primary" @click="openDeptModal()"><i class="fa fa-plus me-1"></i> Add Department</button>
                    </div>
                    <div class="card-body table-responsive">
                        <table class="table align-middle">
                            <thead><tr><th>Name</th><th>Users</th><th>Description</th><th>Status</th><th>Actions</th></tr></thead>
                            <tbody>
                                <tr v-for="d in departmentRecords" :key="d.id">
                                    <td><span class="dept-dot" :style="{ background: d.color || '#888' }"></span> {{ d.name }}</td>
                                    <td>{{ d.admins_count }}</td>
                                    <td class="small text-muted">{{ d.description || '-' }}</td>
                                    <td><span class="badge" :class="d.status ? 'bg-success' : 'bg-secondary'">{{ d.status ? 'Active' : 'Inactive' }}</span></td>
                                    <td>
                                        <button class="btn btn-sm btn-primary" @click="openDeptModal(d)"><i class="fa fa-pencil-alt"></i></button>
                                        <button class="btn btn-sm btn-danger" @click="deleteDept(d)"><i class="fa fa-trash"></i></button>
                                    </td>
                                </tr>
                                <tr v-if="!departmentRecords.length"><td colspan="5" class="text-center text-muted">No departments</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- ================= ACTIVITY LOGS ================= -->
            <div v-show="activeTab === 'activity'">
                <div class="card">
                    <div class="card-header"><h5 class="mb-0">Activity Logs</h5></div>
                    <div class="card-body table-responsive">
                        <table class="table table-sm align-middle">
                            <thead><tr><th>User</th><th>Role</th><th>Action</th><th>IP</th><th>Device</th><th>Time</th></tr></thead>
                            <tbody>
                                <tr v-for="a in activityLogs" :key="a.id">
                                    <td class="fw-medium">{{ a.user }}</td><td>{{ a.role }}</td>
                                    <td><span :class="a.success ? 'text-success' : 'text-danger'">{{ a.action }}</span></td>
                                    <td class="small text-muted">{{ a.ip }}</td><td class="small text-muted">{{ a.device }}</td>
                                    <td class="small text-muted">{{ a.time | dt }}</td>
                                </tr>
                                <tr v-if="!activityLogs.length"><td colspan="6" class="text-center text-muted">No activity</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- ================= LOGIN HISTORY ================= -->
            <div v-show="activeTab === 'login'">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">Login History</h5>
                        <select v-model="loginStatus" class="form-select form-select-sm w-auto" @change="loadLoginHistory">
                            <option value="">All</option><option value="success">Success</option><option value="failed">Failed</option>
                        </select>
                    </div>
                    <div class="card-body table-responsive">
                        <table class="table table-sm align-middle">
                            <thead><tr><th>User</th><th>Email</th><th>IP</th><th>Device</th><th>Location</th><th>Status</th><th>Time</th></tr></thead>
                            <tbody>
                                <tr v-for="l in loginHistory" :key="l.id">
                                    <td class="fw-medium">{{ l.user }}</td><td class="small text-muted">{{ l.email }}</td><td class="small text-muted">{{ l.ip }}</td>
                                    <td class="small text-muted">{{ l.device }}</td><td class="small text-muted">{{ l.location }}</td>
                                    <td><span class="badge" :class="l.status === 'Success' ? 'bg-success' : 'bg-danger'">{{ l.status }}</span></td>
                                    <td class="small text-muted">{{ l.time | dt }}</td>
                                </tr>
                                <tr v-if="!loginHistory.length"><td colspan="7" class="text-center text-muted">No login history</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- ================= SESSION MANAGEMENT ================= -->
            <div v-show="activeTab === 'sessions'">
                <div class="card">
                    <div class="card-header"><h5 class="mb-0">Session Management</h5></div>
                    <div class="card-body table-responsive">
                        <table class="table table-sm align-middle">
                            <thead><tr><th>User</th><th>Role</th><th>IP</th><th>Device</th><th>Platform</th><th>Location</th><th>Last Activity</th><th>Actions</th></tr></thead>
                            <tbody>
                                <tr v-for="s in sessions" :key="s.id">
                                    <td class="fw-medium">{{ s.user }} <span v-if="s.is_current" class="badge bg-info ms-1">Current</span></td>
                                    <td>{{ s.role }}</td><td class="small text-muted">{{ s.ip }}</td><td class="small text-muted">{{ s.device }}</td>
                                    <td class="small text-muted">{{ s.platform }}</td><td class="small text-muted">{{ s.location }}</td>
                                    <td class="small text-muted">{{ s.last_activity | dt }}</td>
                                    <td><button class="btn btn-sm btn-danger" :disabled="s.is_current" @click="revokeSession(s)">Revoke</button></td>
                                </tr>
                                <tr v-if="!sessions.length"><td colspan="8" class="text-center text-muted">No active sessions</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- ================= KYC MANAGEMENT ================= -->
            <div v-show="activeTab === 'kyc'">
                <div class="row mb-2">
                    <div class="col-4"><div class="card text-center"><div class="card-body py-2"><small class="text-muted d-block">Pending</small><b class="text-warning fs-5">{{ kycCounts.pending }}</b></div></div></div>
                    <div class="col-4"><div class="card text-center"><div class="card-body py-2"><small class="text-muted d-block">Approved</small><b class="text-success fs-5">{{ kycCounts.approved }}</b></div></div></div>
                    <div class="col-4"><div class="card text-center"><div class="card-body py-2"><small class="text-muted d-block">Rejected</small><b class="text-danger fs-5">{{ kycCounts.rejected }}</b></div></div></div>
                </div>
                <div class="card">
                    <div class="card-header"><h5 class="mb-0">KYC Management</h5></div>
                    <div class="card-body table-responsive">
                        <table class="table table-sm align-middle">
                            <thead><tr><th>User</th><th>Role</th><th>Document</th><th>Number</th><th>Status</th><th>Submitted</th><th>Actions</th></tr></thead>
                            <tbody>
                                <tr v-for="k in kycRecords" :key="k.id">
                                    <td class="fw-medium">{{ k.user }}</td><td>{{ k.role }}</td><td>{{ k.document_type }}</td><td class="small text-muted">{{ k.document_number }}</td>
                                    <td><span class="badge" :class="kycClass(k.status)">{{ k.status }}</span></td>
                                    <td class="small text-muted">{{ k.submitted_at | dt }}</td>
                                    <td>
                                        <button class="btn btn-sm btn-success" :disabled="k.status==='approved'" @click="setKyc(k,'approved')">Approve</button>
                                        <button class="btn btn-sm btn-danger" :disabled="k.status==='rejected'" @click="setKyc(k,'rejected')">Reject</button>
                                    </td>
                                </tr>
                                <tr v-if="!kycRecords.length"><td colspan="7" class="text-center text-muted">No KYC records</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- ===== Edit User Modal ===== -->
            <b-modal v-model="userModal.show" title="Edit User" hide-footer>
                <b-form @submit.prevent="saveUser">
                    <b-form-group label="Name *"><b-form-input v-model="userModal.form.username" required></b-form-input></b-form-group>
                    <b-form-group label="Email *"><b-form-input v-model="userModal.form.email" type="email" required></b-form-input></b-form-group>
                    <b-form-group label="Mobile"><b-form-input v-model="userModal.form.mobile"></b-form-input></b-form-group>
                    <b-form-group label="Role *"><b-form-select v-model="userModal.form.role_id" :options="roleOptions" required></b-form-select></b-form-group>
                    <b-form-group label="Department"><b-form-select v-model="userModal.form.department_id" :options="deptOptions"></b-form-select></b-form-group>
                    <b-form-group label="Status"><b-form-select v-model="userModal.form.status" :options="[{value:1,text:'Active'},{value:0,text:'Inactive'}]"></b-form-select></b-form-group>
                    <b-form-group label="New Password (optional)"><b-form-input v-model="userModal.form.password" type="password"></b-form-input></b-form-group>
                    <b-form-group label="Confirm Password"><b-form-input v-model="userModal.form.confirm_password" type="password"></b-form-input></b-form-group>
                    <div class="text-end"><b-button variant="secondary" @click="userModal.show=false">Cancel</b-button> <b-button variant="primary" type="submit">Save</b-button></div>
                </b-form>
            </b-modal>

            <!-- ===== Add/Edit Department Modal ===== -->
            <b-modal v-model="deptModal.show" :title="deptModal.form.id ? 'Edit Department' : 'Add Department'" hide-footer>
                <b-form @submit.prevent="saveDept">
                    <b-form-group label="Name *"><b-form-input v-model="deptModal.form.name" required></b-form-input></b-form-group>
                    <b-form-group label="Color"><b-form-input v-model="deptModal.form.color" type="color"></b-form-input></b-form-group>
                    <b-form-group label="Description"><b-form-textarea v-model="deptModal.form.description"></b-form-textarea></b-form-group>
                    <b-form-group label="Status"><b-form-select v-model="deptModal.form.status" :options="[{value:1,text:'Active'},{value:0,text:'Inactive'}]"></b-form-select></b-form-group>
                    <div class="text-end"><b-button variant="secondary" @click="deptModal.show=false">Cancel</b-button> <b-button variant="primary" type="submit">Save</b-button></div>
                </b-form>
            </b-modal>
        </div>
    </div>
</template>

<script>
export default {
    name: 'UserManagement',
    filters: {
        dt(v) {
            if (!v) return '-';
            const d = new Date(v);
            return isNaN(d) ? v : d.toLocaleString();
        },
    },
    data() {
        return {
            activeTab: 'overview',
            loadedTabs: {},
            fromDate: '',
            toDate: '',
            palette: ['#7c5cfc', '#22c55e', '#3b82f6', '#f59e0b', '#ef4444', '#14b8a6', '#a855f7', '#0ea5e9', '#ec4899'],
            tabs: [
                { key: 'overview', label: 'User Overview' },
                { key: 'users', label: 'Users' },
                { key: 'roles', label: 'Roles & Permissions' },
                { key: 'departments', label: 'Departments' },
                { key: 'activity', label: 'Activity Logs' },
                { key: 'login', label: 'Login History' },
                { key: 'sessions', label: 'Session Management' },
                { key: 'kyc', label: 'KYC Management' },
            ],
            statCards: [
                { key: 'total_users', label: 'Total Users', icon: 'fa-users', bg: '#efeaff', color: '#7c5cfc' },
                { key: 'active_users', label: 'Active Users', icon: 'fa-user-check', bg: '#e7f8ef', color: '#22c55e' },
                { key: 'inactive_users', label: 'Inactive Users', icon: 'fa-user-clock', bg: '#fff4e5', color: '#f59e0b' },
                { key: 'blocked_users', label: 'Blocked Users', icon: 'fa-user-slash', bg: '#fdeaea', color: '#ef4444' },
                { key: 'new_users', label: 'New Users', icon: 'fa-user-plus', bg: '#e8f1ff', color: '#3b82f6' },
                { key: 'administrators', label: 'Administrators', icon: 'fa-user-shield', bg: '#efeaff', color: '#7c5cfc' },
            ],
            stats: { total_users: 0, active_users: 0, inactive_users: 0, blocked_users: 0, new_users: 0, administrators: 0 },
            overview: { recent_users: [], top_active_users: [], role_permission_summary: [], users_by_role: [], users_by_department: [] },
            security: {},
            roleChart: { options: {}, series: [] },
            statusChart: { options: {}, series: [] },
            loginChart: { options: {}, series: [] },

            users: [],
            roles: [],
            departments: [],
            userFilters: { search: '', role_id: '', department_id: '', status: '' },

            departmentRecords: [],
            activityLogs: [],
            loginHistory: [],
            loginStatus: '',
            sessions: [],
            kycRecords: [],
            kycCounts: { pending: 0, approved: 0, rejected: 0 },

            userModal: { show: false, form: this.emptyUser() },
            deptModal: { show: false, form: this.emptyDept() },
        };
    },
    computed: {
        exportUrl() { return this.$apiUrl + '/user-management/export'; },
        roleOptions() { return this.roles.map(r => ({ value: r.id, text: r.name })); },
        deptOptions() { return [{ value: null, text: '— None —' }].concat(this.departments.map(d => ({ value: d.id, text: d.name }))); },
        roleLegend() { return this.overview.users_by_role || []; },
        statusLegend() {
            const s = this.overview.users_by_status || { active: 0, inactive: 0, blocked: 0 };
            const total = s.active + s.inactive + s.blocked;
            const pct = (n) => total ? Math.round(n * 1000 / total) / 10 : 0;
            return [
                { name: 'Active', count: s.active, percentage: pct(s.active), color: '#22c55e' },
                { name: 'Inactive', count: s.inactive, percentage: pct(s.inactive), color: '#f59e0b' },
                { name: 'Blocked', count: s.blocked, percentage: pct(s.blocked), color: '#ef4444' },
            ];
        },
        deptMax() {
            const arr = (this.overview.users_by_department || []).map(d => d.count);
            return arr.length ? Math.max.apply(null, arr) : 0;
        },
    },
    created() {
        this.loadOverview();
        this.loadUsers();
    },
    methods: {
        emptyUser() { return { id: null, username: '', email: '', mobile: '', role_id: '', department_id: null, status: 1, password: '', confirm_password: '' }; },
        emptyDept() { return { id: null, name: '', color: '#7c5cfc', description: '', status: 1 }; },
        colorAt(i) { return this.palette[i % this.palette.length]; },
        barWidth(count) { return this.deptMax ? Math.max(4, Math.round(count * 100 / this.deptMax)) : 0; },
        subFor(key) {
            const t = this.stats.total_users || 0;
            const pct = (n) => t ? Math.round(n * 1000 / t) / 10 + '% of total' : '—';
            if (key === 'active_users') return pct(this.stats.active_users);
            if (key === 'inactive_users') return pct(this.stats.inactive_users);
            if (key === 'blocked_users') return pct(this.stats.blocked_users);
            if (key === 'administrators') return pct(this.stats.administrators);
            if (key === 'new_users') return 'in selected period';
            return 'all staff users';
        },
        statusClass(s) { return s === 'Active' ? 'bg-success' : (s === 'Blocked' ? 'bg-danger' : 'bg-secondary'); },
        kycClass(s) { return s === 'approved' ? 'bg-success' : (s === 'rejected' ? 'bg-danger' : 'bg-warning'); },
        switchTab(key) {
            this.activeTab = key;
            if (this.loadedTabs[key]) return;
            this.loadedTabs[key] = true;
            const map = { departments: this.loadDepartments, activity: this.loadActivity, login: this.loadLoginHistory, sessions: this.loadSessions, kyc: this.loadKyc };
            if (map[key]) map[key]();
        },
        loadOverview() {
            const params = {};
            if (this.fromDate) params.from_date = this.fromDate;
            if (this.toDate) params.to_date = this.toDate;
            axios.get(this.$apiUrl + '/user-management/overview', { params }).then(res => {
                const d = res.data.data;
                this.stats = d.stats;
                this.overview = d;
                this.security = d.security_overview || {};
                this.buildCharts(d);
            });
        },
        buildCharts(d) {
            const donutBase = (label) => ({
                labels: [],
                legend: { show: false },
                dataLabels: { enabled: false },
                stroke: { width: 2 },
                plotOptions: { pie: { donut: { size: '70%', labels: { show: true, name: { show: true }, value: { show: true, fontSize: '22px', fontWeight: 700 }, total: { show: true, label: label, fontSize: '12px', color: '#888', formatter: (w) => w.globals.seriesTotals.reduce((a, b) => a + b, 0) } } } } },
            });
            // Role donut
            const ro = donutBase('Total Users');
            ro.labels = d.users_by_role.map(r => r.name);
            ro.colors = d.users_by_role.map((r, i) => this.colorAt(i));
            this.roleChart = { series: d.users_by_role.map(r => r.count), options: ro };
            // Status donut
            const so = donutBase('Total Users');
            so.labels = ['Active', 'Inactive', 'Blocked'];
            so.colors = ['#22c55e', '#f59e0b', '#ef4444'];
            this.statusChart = { series: [d.users_by_status.active, d.users_by_status.inactive, d.users_by_status.blocked], options: so };
            // Login line
            this.loginChart = {
                series: [
                    { name: 'Successful', data: d.login_activity.map(x => x.success) },
                    { name: 'Failed', data: d.login_activity.map(x => x.failed) },
                ],
                options: {
                    chart: { toolbar: { show: false } },
                    stroke: { curve: 'smooth', width: 2 },
                    markers: { size: 3 },
                    colors: ['#22c55e', '#ef4444'],
                    xaxis: { categories: d.login_activity.map(x => x.date) },
                    legend: { position: 'top' },
                    grid: { borderColor: '#f0f0f0' },
                },
            };
        },
        loadUsers() {
            axios.get(this.$apiUrl + '/user-management/users', { params: this.userFilters }).then(res => {
                this.users = res.data.data.records;
                this.roles = res.data.data.roles;
                this.departments = res.data.data.departments;
            });
        },
        openUserModal(u) {
            this.userModal.form = { id: u.id, username: u.name, email: u.email, mobile: u.mobile, role_id: u.role_id, department_id: u.department_id, status: u.status === 'Active' ? 1 : 0, password: '', confirm_password: '' };
            this.userModal.show = true;
        },
        saveUser() {
            const f = this.userModal.form;
            axios.post(this.$apiUrl + '/user-management/users/update', f).then(res => {
                if (res.data.status === 1) { this.showMessage('success', res.data.message); this.userModal.show = false; this.loadUsers(); this.loadOverview(); }
                else this.showMessage('error', res.data.message);
            }).catch(e => this.showMessage('error', (e.response && e.response.data && e.response.data.message) || 'Error'));
        },
        toggleBlock(u) {
            axios.post(this.$apiUrl + '/user-management/users/toggle-block', { id: u.id }).then(res => {
                this.showMessage(res.data.status === 1 ? 'success' : 'error', res.data.message); this.loadUsers(); this.loadOverview();
            });
        },
        deleteUser(u) {
            this.$swal.fire({ title: 'Are you sure?', text: 'Delete this user?', icon: 'warning', showCancelButton: true, confirmButtonText: 'Yes', confirmButtonColor: '#9AC444', cancelButtonColor: '#d33' })
                .then(r => { if (r.value) { axios.post(this.$apiUrl + '/user-management/users/delete', { id: u.id }).then(res => { this.showMessage(res.data.status === 1 ? 'success' : 'error', res.data.message); this.loadUsers(); this.loadOverview(); }); } });
        },
        loadDepartments() { axios.get(this.$apiUrl + '/user-management/departments').then(res => { this.departmentRecords = res.data.data.records; }); },
        openDeptModal(d) { this.deptModal.form = d ? { id: d.id, name: d.name, color: d.color || '#7c5cfc', description: d.description, status: d.status } : this.emptyDept(); this.deptModal.show = true; },
        saveDept() {
            const f = this.deptModal.form;
            const url = f.id ? '/user-management/departments/update' : '/user-management/departments/save';
            axios.post(this.$apiUrl + url, f).then(res => { this.showMessage(res.data.status === 1 ? 'success' : 'error', res.data.message); if (res.data.status === 1) { this.deptModal.show = false; this.loadDepartments(); this.loadUsers(); this.loadOverview(); } });
        },
        deleteDept(d) {
            this.$swal.fire({ title: 'Delete department?', text: 'Users will be detached, not deleted.', icon: 'warning', showCancelButton: true, confirmButtonText: 'Yes', confirmButtonColor: '#9AC444', cancelButtonColor: '#d33' })
                .then(r => { if (r.value) { axios.post(this.$apiUrl + '/user-management/departments/delete', { id: d.id }).then(res => { this.showMessage('success', res.data.message); this.loadDepartments(); this.loadUsers(); this.loadOverview(); }); } });
        },
        loadActivity() { axios.get(this.$apiUrl + '/user-management/activity-logs').then(res => { this.activityLogs = res.data.data.records; }); },
        loadLoginHistory() { axios.get(this.$apiUrl + '/user-management/login-history', { params: { status: this.loginStatus } }).then(res => { this.loginHistory = res.data.data.records; }); },
        loadSessions() { axios.get(this.$apiUrl + '/user-management/sessions').then(res => { this.sessions = res.data.data.records; }); },
        revokeSession(s) { axios.post(this.$apiUrl + '/user-management/sessions/revoke', { id: s.id }).then(res => { this.showMessage(res.data.status === 1 ? 'success' : 'error', res.data.message); this.loadSessions(); }); },
        loadKyc() { axios.get(this.$apiUrl + '/user-management/kyc').then(res => { this.kycRecords = res.data.data.records; this.kycCounts = res.data.data.counts; }); },
        setKyc(k, status) { axios.post(this.$apiUrl + '/user-management/kyc/update-status', { id: k.id, status }).then(res => { this.showMessage(res.data.status === 1 ? 'success' : 'error', res.data.message); this.loadKyc(); }); },
    },
};
</script>

<style scoped>
.user-management .um-gap { gap: .5rem; }

/* Stat cards */
.um-stats { margin-bottom: .25rem; }
.um-stats [class*="col-"] { margin-bottom: 1rem; }
.um-stats .stat-card { border: 1px solid #eef0f4; border-radius: 14px; box-shadow: 0 1px 2px rgba(16,24,40,.04); transition: box-shadow .15s ease; }
.um-stats .stat-card:hover { box-shadow: 0 4px 14px rgba(16,24,40,.08); }
.um-stats .stat-card .card-body { position: relative; padding: 16px 16px 14px; }
.um-stats .stat-icon { position: absolute; top: 20px; right: 14px; width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 15px; }
.um-stats .stat-label { font-size: .78rem; color: #6b7280; font-weight: 500; line-height: 1.25; padding-right: 46px; min-height: 2.4em; display: flex; align-items: center; }
.um-stats .stat-value { font-size: 1.8rem; font-weight: 700; line-height: 1; margin: 2px 0 5px; color: #111827; }
.um-stats .stat-sub { font-size: .72rem; font-weight: 500; }

/* Tabs */
.um-tabs { border-bottom: 1px solid #eef0f4; -ms-overflow-style: none; scrollbar-width: none; }
.um-tabs::-webkit-scrollbar { display: none; height: 0; }
.um-tabs .nav-link { cursor: pointer; white-space: nowrap; color: #6b7280; border: 0; border-bottom: 2px solid transparent; padding: .6rem 1rem; }
.um-tabs .nav-link:hover { color: #7c5cfc; }
.um-tabs .nav-link.active { font-weight: 600; color: #7c5cfc; background: transparent; border-bottom: 2px solid #7c5cfc; }

/* Cards */
.user-management .card { border: 1px solid #eef0f4; border-radius: 14px; box-shadow: 0 1px 2px rgba(16,24,40,.03); margin-bottom: 1rem; }
.user-management .card-body { padding: 1.15rem 1.25rem; }
.user-management .card-header { background: transparent; border-bottom: 1px solid #f1f2f6; padding: .9rem 1.1rem; }
.user-management .card-header h5 { font-size: 1rem; font-weight: 600; color: #111827; }

/* Tables — consistent across all sections */
.user-management .table { margin-bottom: 0; }
.user-management .table thead th { text-transform: uppercase; font-size: .68rem; letter-spacing: .4px; color: #9ca3af; font-weight: 600; border-bottom: 1px solid #eef0f4; border-top: 0; padding: .55rem .6rem; white-space: nowrap; }
.user-management .table tbody td { border-top: 1px solid #f4f5f7; padding: .6rem .6rem; color: #374151; vertical-align: middle; }
.user-management .table tbody tr:hover { background: #fafbff; }
.user-management .table .fw-medium { font-weight: 600; color: #111827; }

/* Badges */
.user-management .badge { font-weight: 500; padding: .38em .62em; border-radius: 6px; }
.user-management .badge.bg-light { background: #f3f4f6 !important; }

/* Filter controls */
.user-management .form-control-sm, .user-management .form-select-sm { border-radius: 8px; border-color: #e5e7eb; }

/* Action buttons in tables */
.user-management .table .btn-sm { padding: .2rem .45rem; margin: 0 1px; border-radius: 7px; }

/* Donut + legend (responsive: side-by-side when wide, stacked-centered when narrow) */
.chart-flex { gap: .5rem 1rem; }
.donut-wrap { flex: 1 1 150px; max-width: 190px; min-width: 130px; }
.legend-list { list-style: none; margin: 0; padding: 0; flex: 1 1 150px; min-width: 140px; }
.legend-list li { display: flex; align-items: center; padding: 5px 0; font-size: .82rem; }
.legend-list .dot { width: 10px; height: 10px; border-radius: 50%; margin-right: 8px; flex: 0 0 auto; }
.legend-list .lg-name { flex: 1 1 auto; color: #374151; }
.legend-list .lg-val { font-weight: 600; color: #111827; }
.legend-list .lg-val small { color: #9ca3af; font-weight: 400; }

/* Department bars */
.dept-list { padding: .25rem 0; }
.dept-row { display: flex; align-items: center; margin-bottom: 12px; font-size: .82rem; }
.dept-row .dept-name { flex: 0 0 90px; color: #374151; }
.dept-row .dept-track { flex: 1 1 auto; height: 8px; background: #f1f2f6; border-radius: 6px; overflow: hidden; margin: 0 10px; }
.dept-row .dept-fill { display: block; height: 100%; border-radius: 6px; }
.dept-row .dept-val { flex: 0 0 78px; text-align: right; font-weight: 600; color: #111827; }
.dept-row .dept-val small { color: #9ca3af; font-weight: 400; }

/* Security list */
.security-list { list-style: none; margin: 0; padding: 0; }
.security-list li { display: flex; align-items: center; padding: 9px 0; border-bottom: 1px solid #f4f5f7; font-size: .85rem; }
.security-list li:last-child { border-bottom: 0; }
.security-list .sec-ic { width: 20px; text-align: center; margin-right: 8px; }
.security-list span { flex: 1 1 auto; color: #4b5563; }
.security-list b { color: #111827; }

.dept-dot { display: inline-block; width: 10px; height: 10px; border-radius: 50%; margin-right: 6px; }
.fw-medium { font-weight: 500; }
</style>
