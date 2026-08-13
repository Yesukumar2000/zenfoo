<template>
    <div class="notif-analytics">
        <div class="page-heading">
            <!-- Header -->
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3 class="mb-0">Notification Analytics</h3>
                        <p class="text-subtitle text-muted mb-0">Sent, reach, failures and engagement across alerts &amp; notifications.</p>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">Dashboard</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">Notification Analytics</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <!-- Toolbar -->
            <div class="d-flex flex-wrap justify-content-end align-items-end na-gap mb-3">
                <div>
                    <label class="small text-muted d-block mb-1">From</label>
                    <input type="date" v-model="fromDate" class="form-control form-control-sm" />
                </div>
                <div>
                    <label class="small text-muted d-block mb-1">To</label>
                    <input type="date" v-model="toDate" class="form-control form-control-sm" />
                </div>
                <button class="btn btn-sm btn-outline-secondary" @click="loadOverview"><i class="fa fa-filter me-1"></i> Apply</button>
                <router-link to="/notifications-all/create" class="btn btn-sm btn-success"><i class="fa fa-plus me-1"></i> Create Notification</router-link>
            </div>

            <!-- Stat cards -->
            <div class="row g-3 na-stats mb-1">
                <div class="col-6 col-sm-4 col-xl-2" v-for="card in statCards" :key="card.key">
                    <div class="card stat-card">
                        <div class="card-body">
                            <span class="stat-icon" :style="{ background: card.bg, color: card.color }"><i :class="'fa ' + card.icon"></i></span>
                            <div class="stat-label">{{ card.label }}</div>
                            <div class="stat-value">{{ formatNum(stats[card.key]) }}</div>
                            <div class="stat-sub" :style="{ color: card.color }">{{ card.sub }}</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tabs -->
            <ul class="nav nav-tabs na-tabs mt-2 mb-3 flex-nowrap overflow-auto">
                <li class="nav-item" v-for="t in tabs" :key="t.key">
                    <a class="nav-link" :class="{ active: activeTab === t.key }" href="javascript:void(0)" @click="switchTab(t.key)">
                        {{ t.label }}
                        <span v-if="t.soon" class="soon-pill">soon</span>
                    </a>
                </li>
            </ul>

            <!-- ================= OVERVIEW ================= -->
            <div v-show="activeTab === 'overview'">
                <!-- Quick Actions -->
                <div class="card mb-3">
                    <div class="card-header"><h5 class="mb-0">Quick Actions</h5></div>
                    <div class="card-body">
                        <div class="qa-grid">
                            <a v-for="a in quickActions" :key="a.label" href="javascript:void(0)"
                               class="qa-tile" :class="{ disabled: a.soon }" @click="doAction(a)">
                                <span class="qa-ic" :style="{ background: a.bg, color: a.color }"><i :class="'fa ' + a.icon"></i></span>
                                <span class="qa-label">{{ a.label }}<small v-if="a.soon" class="qa-soon">soon</small></span>
                            </a>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-3">
                    <!-- Notification Trend -->
                    <div class="col-12 col-lg-8">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Notification Trend (Sent)</h5></div>
                            <div class="card-body">
                                <apexchart v-if="trendChart.series.length" type="area" height="260"
                                           :options="trendChart.options" :series="trendChart.series"></apexchart>
                                <p v-else class="text-muted text-center my-5">No data in this period</p>
                            </div>
                        </div>
                    </div>
                    <!-- Delivery Status -->
                    <div class="col-12 col-lg-4">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Delivery Status</h5></div>
                            <div class="card-body">
                                <div class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                    <div class="donut-wrap">
                                        <apexchart v-if="statusChart.series.length" type="donut" height="185"
                                                   :options="statusChart.options" :series="statusChart.series"></apexchart>
                                        <p v-else class="text-muted text-center my-5">No data</p>
                                    </div>
                                    <ul class="legend-list">
                                        <li><span class="dot" style="background:#22c55e"></span><span class="lg-name">Reached</span><span class="lg-val">{{ formatNum(stats.reached) }}</span></li>
                                        <li><span class="dot" style="background:#ef4444"></span><span class="lg-name">Failed</span><span class="lg-val">{{ formatNum(stats.failed) }}</span></li>
                                    </ul>
                                </div>
                                <p class="tiny-note mb-0">“Reached” = FCM accepted the message at send time. True device delivery receipts are not tracked yet.</p>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-3">
                    <!-- By Audience -->
                    <div class="col-12 col-md-6 col-xl-4">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">By Audience</h5></div>
                            <div class="card-body">
                                <div class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                    <div class="donut-wrap">
                                        <apexchart v-if="audienceChart.series.length && audienceTotal" type="donut" height="185"
                                                   :options="audienceChart.options" :series="audienceChart.series"></apexchart>
                                        <p v-else class="text-muted text-center my-5">No data</p>
                                    </div>
                                    <ul class="legend-list">
                                        <li v-for="(a,i) in byAudience" :key="i">
                                            <span class="dot" :style="{ background: colorAt(i) }"></span>
                                            <span class="lg-name">{{ a.name }}</span>
                                            <span class="lg-val">{{ formatNum(a.count) }} <small>({{ pct(a.count, audienceTotal) }}%)</small></span>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- By Type -->
                    <div class="col-12 col-md-6 col-xl-4">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">By Type</h5></div>
                            <div class="card-body">
                                <div v-if="byType.length" class="dept-list">
                                    <div class="dept-row" v-for="(d,i) in byType" :key="i">
                                        <span class="dept-name" :title="d.name">{{ d.name }}</span>
                                        <span class="dept-track"><span class="dept-fill" :style="{ width: barWidth(d.count) + '%', background: colorAt(i) }"></span></span>
                                        <span class="dept-val">{{ formatNum(d.count) }}</span>
                                    </div>
                                </div>
                                <p v-else class="text-muted text-center my-5">No type data</p>
                            </div>
                        </div>
                    </div>
                    <!-- Channel availability (honest) -->
                    <div class="col-12 col-md-6 col-xl-4">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Channels &amp; Tracking</h5></div>
                            <div class="card-body">
                                <ul class="avail-list mb-0">
                                    <li><span>Push (FCM)</span><b class="text-success"><i class="fa fa-check-circle"></i> Live</b></li>
                                    <li><span>SMS / Email</span><b class="text-muted">Transactional only</b></li>
                                    <li><span>WhatsApp / In-App</span><b class="text-muted">Not wired</b></li>
                                    <li><span>Delivered receipts</span><b :class="availability.delivered ? 'text-success' : 'text-muted'">{{ availability.delivered ? 'Live' : 'Not tracked' }}</b></li>
                                    <li><span>Read / Opened (users)</span><b :class="availability.read_customer ? 'text-success' : 'text-muted'">{{ availability.read_customer ? 'Live' : 'Not tracked' }}</b></li>
                                    <li><span>Read (admin panel)</span><b class="text-success">{{ stats.admin_read_rate }}%</b></li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row g-3">
                    <!-- Recent Notifications -->
                    <div class="col-12">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Recent Notifications</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>Title</th><th>Type</th><th>Audience</th><th>Channel</th><th>Sent</th></tr></thead>
                                    <tbody>
                                        <tr v-for="n in recentNotifications" :key="n.id">
                                            <td class="fw-medium text-truncate" style="max-width:180px" :title="n.title">{{ n.title }}</td>
                                            <td class="small text-muted">{{ n.type || '-' }}</td>
                                            <td><span class="badge bg-light text-dark">{{ n.audience }}</span></td>
                                            <td class="small">{{ n.channel }}</td>
                                            <td class="small text-muted">{{ n.sent_at | dt }}</td>
                                        </tr>
                                        <tr v-if="!recentNotifications.length"><td colspan="5" class="text-center text-muted">No notifications</td></tr>
                                    </tbody>
                                </table>
                            </div>
                            <div class="card-footer view-all-footer">
                                <a href="javascript:void(0)" class="view-all" @click="switchTab('notifications')">View All Notifications <i class="fa fa-arrow-right ms-1"></i></a>
                            </div>
                        </div>
                    </div>
                    <!-- Recent Broadcasts -->
                    <div class="col-12">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Recent Broadcasts</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>Title</th><th>Target</th><th>Sent</th><th>Failed</th><th>When</th></tr></thead>
                                    <tbody>
                                        <tr v-for="b in recentBroadcasts" :key="b.id">
                                            <td class="fw-medium text-truncate" style="max-width:170px" :title="b.title">{{ b.title }}</td>
                                            <td><span class="badge bg-light text-dark">{{ b.target }}</span></td>
                                            <td><span class="text-success fw-medium">{{ formatNum(b.sent) }}</span></td>
                                            <td><span :class="b.failed ? 'text-danger fw-medium' : 'text-muted'">{{ formatNum(b.failed) }}</span></td>
                                            <td class="small text-muted">{{ b.created_at | dt }}</td>
                                        </tr>
                                        <tr v-if="!recentBroadcasts.length"><td colspan="5" class="text-center text-muted">No broadcasts</td></tr>
                                    </tbody>
                                </table>
                            </div>
                            <div class="card-footer view-all-footer">
                                <a href="javascript:void(0)" class="view-all" @click="switchTab('delivery')">View All Delivery Logs <i class="fa fa-arrow-right ms-1"></i></a>
                            </div>
                        </div>
                    </div>
                    <!-- Top Templates -->
                    <div class="col-12">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Top Templates</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>Channel</th><th>Title</th><th>Type</th></tr></thead>
                                    <tbody>
                                        <tr v-for="t in topTemplates" :key="t.channel + t.id">
                                            <td><span class="badge" :class="t.channel === 'SMS' ? 'bg-info' : 'bg-primary'">{{ t.channel }}</span></td>
                                            <td class="fw-medium text-truncate" style="max-width:320px" :title="t.title">{{ t.title }}</td>
                                            <td class="small text-muted">{{ t.type }}</td>
                                        </tr>
                                        <tr v-if="!topTemplates.length"><td colspan="3" class="text-center text-muted">No templates</td></tr>
                                    </tbody>
                                </table>
                            </div>
                            <div class="card-footer view-all-footer">
                                <a href="javascript:void(0)" class="view-all" @click="switchTab('templates')">View All Templates <i class="fa fa-arrow-right ms-1"></i></a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ================= NOTIFICATIONS ================= -->
            <div v-show="activeTab === 'notifications'">
                <div class="card">
                    <div class="card-header d-flex flex-wrap na-gap align-items-center">
                        <h5 class="mb-0 me-auto">Notifications</h5>
                        <input v-model="notifFilters.search" type="search" class="form-control form-control-sm w-auto" placeholder="Search..." @keyup.enter="loadNotifications" />
                        <select v-model="notifFilters.audience" class="form-select form-select-sm w-auto" @change="loadNotifications">
                            <option value="customer">Customer</option>
                            <option value="seller">Seller</option>
                            <option value="driver">Driver</option>
                        </select>
                    </div>
                    <div class="card-body table-responsive">
                        <table class="table align-middle">
                            <thead><tr><th>Title</th><th>Message</th><th>Type</th><th>Audience</th><th>Channel</th><th>Sent</th></tr></thead>
                            <tbody>
                                <tr v-for="n in notifications" :key="n.audience + n.id">
                                    <td class="fw-medium text-truncate" style="max-width:180px" :title="n.title">{{ n.title }}</td>
                                    <td class="small text-muted text-truncate" style="max-width:260px" :title="n.message">{{ n.message }}</td>
                                    <td class="small">{{ n.type || '-' }}</td>
                                    <td><span class="badge bg-light text-dark">{{ n.audience }}</span></td>
                                    <td class="small">{{ n.channel }}</td>
                                    <td class="small text-muted">{{ n.sent_at | dt }}</td>
                                </tr>
                                <tr v-if="!notifications.length"><td colspan="6" class="text-center text-muted">No notifications found</td></tr>
                            </tbody>
                        </table>
                        <div v-if="notifMeta.last_page > 1" class="d-flex justify-content-end align-items-center na-gap pt-2">
                            <button class="btn btn-sm btn-outline-secondary" :disabled="notifMeta.current_page <= 1" @click="pageNotifications(notifMeta.current_page - 1)">Prev</button>
                            <span class="small text-muted">Page {{ notifMeta.current_page }} / {{ notifMeta.last_page }}</span>
                            <button class="btn btn-sm btn-outline-secondary" :disabled="notifMeta.current_page >= notifMeta.last_page" @click="pageNotifications(notifMeta.current_page + 1)">Next</button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ================= TEMPLATES ================= -->
            <div v-show="activeTab === 'templates'">
                <div class="card">
                    <div class="card-header"><h5 class="mb-0">Templates</h5></div>
                    <div class="card-body table-responsive">
                        <table class="table align-middle">
                            <thead><tr><th>Channel</th><th>Title</th><th>Type</th><th>Message</th></tr></thead>
                            <tbody>
                                <tr v-for="t in templates" :key="t.channel + t.id">
                                    <td><span class="badge" :class="t.channel === 'SMS' ? 'bg-info' : 'bg-primary'">{{ t.channel }}</span></td>
                                    <td class="fw-medium text-truncate" style="max-width:240px" :title="t.title">{{ t.title }}</td>
                                    <td class="small text-muted">{{ t.type }}</td>
                                    <td class="small text-muted text-truncate" style="max-width:320px" :title="t.message">{{ t.message }}</td>
                                </tr>
                                <tr v-if="!templates.length"><td colspan="4" class="text-center text-muted">No templates</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- ================= DELIVERY LOGS ================= -->
            <div v-show="activeTab === 'delivery'">
                <div class="card">
                    <div class="card-header"><h5 class="mb-0">Delivery Logs (Broadcast History)</h5></div>
                    <div class="card-body table-responsive">
                        <table class="table table-sm align-middle">
                            <thead><tr><th>ID</th><th>Title</th><th>Channel</th><th>Target</th><th>Sent</th><th>Failed</th><th>Status</th><th>When</th></tr></thead>
                            <tbody>
                                <tr v-for="l in deliveryLogs" :key="l.id">
                                    <td class="small text-muted">{{ l.id }}</td>
                                    <td class="fw-medium text-truncate" style="max-width:200px" :title="l.title">{{ l.title }}</td>
                                    <td class="small">{{ l.channel }}</td>
                                    <td><span class="badge bg-light text-dark">{{ l.target }}</span></td>
                                    <td><span class="text-success fw-medium">{{ formatNum(l.sent) }}</span></td>
                                    <td><span :class="l.failed ? 'text-danger fw-medium' : 'text-muted'">{{ formatNum(l.failed) }}</span></td>
                                    <td><span class="badge" :class="logStatusClass(l.status)">{{ l.status }}</span></td>
                                    <td class="small text-muted">{{ l.time | dt }}</td>
                                </tr>
                                <tr v-if="!deliveryLogs.length"><td colspan="8" class="text-center text-muted">No delivery logs</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <!-- ================= SUBSCRIBERS ================= -->
            <div v-show="activeTab === 'subscribers'">
                <div class="row g-3">
                    <div class="col-12 col-lg-5">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Reachable Devices by Audience</h5></div>
                            <div class="card-body">
                                <div v-if="subsByType.length" class="dept-list">
                                    <div class="dept-row" v-for="(d,i) in subsByType" :key="i">
                                        <span class="dept-name">{{ d.name }}</span>
                                        <span class="dept-track"><span class="dept-fill" :style="{ width: subsBarWidth(d.count) + '%', background: colorAt(i) }"></span></span>
                                        <span class="dept-val">{{ formatNum(d.count) }}</span>
                                    </div>
                                </div>
                                <p v-else class="text-muted text-center my-5">No registered devices</p>
                                <p class="tiny-note mb-0">Counted from registered FCM tokens (<code>user_tokens</code> + <code>admin_tokens</code>).</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-lg-7">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Devices by Platform</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>Audience</th><th>Platform</th><th>Devices</th></tr></thead>
                                    <tbody>
                                        <tr v-for="(p,i) in subsByPlatform" :key="i">
                                            <td class="fw-medium">{{ p.type }}</td>
                                            <td>{{ p.platform }}</td>
                                            <td>{{ formatNum(p.count) }}</td>
                                        </tr>
                                        <tr v-if="!subsByPlatform.length"><td colspan="3" class="text-center text-muted">No devices</td></tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ================= ROADMAP TABS (Alert Rules / Preferences / Escalation) =================
                 Coming soon — commented out until the backing tracking exists (Phase 3+).
            <div v-show="roadmapTabs.includes(activeTab)">
                <div class="card">
                    <div class="card-body text-center py-5">
                        <div class="roadmap-icon"><i :class="'fa ' + (currentRoadmap.icon || 'fa-road')"></i></div>
                        <h5 class="mb-2">{{ currentRoadmap.label }}</h5>
                        <p class="text-muted mb-3" style="max-width:560px;margin:0 auto">{{ currentRoadmap.desc }}</p>
                        <span class="badge bg-light text-dark"><i class="fa fa-hammer me-1"></i> Requires new tracking — {{ currentRoadmap.phase }}</span>
                    </div>
                </div>
            </div>
            -->
        </div>
    </div>
</template>

<script>
export default {
    name: 'NotificationAnalytics',
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
                { key: 'overview', label: 'Overview' },
                { key: 'notifications', label: 'Notifications' },
                { key: 'templates', label: 'Templates' },
                { key: 'delivery', label: 'Delivery Logs' },
                { key: 'subscribers', label: 'Subscribers' },
                // Coming soon — hidden until the backing data/tracking exists (Phase 3+).
                // { key: 'alert_rules', label: 'Alert Rules', soon: true },
                // { key: 'preferences', label: 'Preferences', soon: true },
                // { key: 'escalation', label: 'Escalation Rules', soon: true },
            ],
            roadmapTabs: ['alert_rules', 'preferences', 'escalation'],
            roadmapMeta: {
                alert_rules: { key: 'alert_rules', label: 'Alert Rules', icon: 'fa-bell', phase: 'Phase 4', desc: 'Threshold-based triggers (e.g. high cancellation rate, payment failures) that auto-fire alerts. No rules engine or alert_rules table exists in the platform today.' },
                preferences: { key: 'preferences', label: 'Delivery Preferences', icon: 'fa-sliders-h', phase: 'Phase 3', desc: 'Per-user / per-channel opt-in and quiet-hours preferences. Not stored today — only raw FCM tokens are kept.' },
                escalation: { key: 'escalation', label: 'Escalation Rules', icon: 'fa-angle-double-up', phase: 'Phase 4', desc: 'Rules that escalate unacknowledged alerts to another channel or role after a timeout. No escalation concept exists in code today.' },
            },
            statCards: [
                { key: 'total_sent', label: 'Total Sent', icon: 'fa-paper-plane', bg: '#efeaff', color: '#7c5cfc', sub: 'in selected period' },
                { key: 'reached', label: 'Reached (FCM)', icon: 'fa-check-circle', bg: '#e7f8ef', color: '#22c55e', sub: 'accepted at send' },
                { key: 'failed', label: 'Failed', icon: 'fa-times-circle', bg: '#fdeaea', color: '#ef4444', sub: 'send-time failures' },
                { key: 'pending', label: 'Pending', icon: 'fa-clock', bg: '#fff4e5', color: '#f59e0b', sub: 'driver broadcasts' },
                { key: 'broadcasts', label: 'Broadcasts', icon: 'fa-broadcast-tower', bg: '#e8f1ff', color: '#3b82f6', sub: 'campaigns sent' },
                { key: 'subscribers', label: 'Subscribers', icon: 'fa-mobile-alt', bg: '#efeaff', color: '#7c5cfc', sub: 'registered devices' },
            ],
            quickActions: [
                { label: 'Create Notification', icon: 'fa-paper-plane', bg: '#efeaff', color: '#7c5cfc', to: '/notifications-all/create' },
                { label: 'Manage Templates', icon: 'fa-file-alt', bg: '#e8f1ff', color: '#3b82f6', tab: 'templates' },
                { label: 'Delivery Logs', icon: 'fa-list', bg: '#e7f8ef', color: '#22c55e', tab: 'delivery' },
                { label: 'Subscribers', icon: 'fa-mobile-alt', bg: '#fff4e5', color: '#f59e0b', tab: 'subscribers' },
                { label: 'Send WhatsApp', icon: 'fa-comment-dots', bg: '#f3f4f6', color: '#9ca3af', soon: true },
                { label: 'Create Alert Rule', icon: 'fa-bell', bg: '#f3f4f6', color: '#9ca3af', soon: true },
            ],
            stats: { total_sent: 0, reached: 0, failed: 0, pending: 0, broadcasts: 0, subscribers: 0, admin_read_rate: 0 },
            availability: {},
            byAudience: [],
            byType: [],
            recentNotifications: [],
            recentBroadcasts: [],
            trendChart: { options: {}, series: [] },
            statusChart: { options: {}, series: [] },
            audienceChart: { options: {}, series: [] },

            notifications: [],
            notifFilters: { search: '', audience: 'customer' },
            notifMeta: { current_page: 1, last_page: 1 },

            templates: [],
            templatesNote: '',
            deliveryLogs: [],
            subsByType: [],
            subsByPlatform: [],
        };
    },
    computed: {
        audienceTotal() { return this.byAudience.reduce((a, b) => a + (b.count || 0), 0); },
        typeMax() { const arr = this.byType.map(d => d.count); return arr.length ? Math.max.apply(null, arr) : 0; },
        subsMax() { const arr = this.subsByType.map(d => d.count); return arr.length ? Math.max.apply(null, arr) : 0; },
        currentRoadmap() { return this.roadmapMeta[this.activeTab] || {}; },
        topTemplates() { return (this.templates || []).slice(0, 6); },
    },
    created() {
        this.loadOverview();
        this.loadTemplates();          // for the "Top Templates" overview card
        this.loadedTabs.templates = true;
    },
    methods: {
        colorAt(i) { return this.palette[i % this.palette.length]; },
        formatNum(n) { return (n === null || n === undefined) ? '—' : Number(n).toLocaleString(); },
        pct(n, total) { return total ? Math.round(n * 1000 / total) / 10 : 0; },
        barWidth(count) { return this.typeMax ? Math.max(4, Math.round(count * 100 / this.typeMax)) : 0; },
        subsBarWidth(count) { return this.subsMax ? Math.max(4, Math.round(count * 100 / this.subsMax)) : 0; },
        logStatusClass(s) {
            const v = (s || '').toLowerCase();
            if (v === 'completed') return 'bg-success';
            if (v === 'partial' || v === 'sending' || v === 'pending') return 'bg-warning';
            if (v === 'failed') return 'bg-danger';
            return 'bg-secondary';
        },
        doAction(a) {
            if (a.soon) return;
            if (a.to) { this.$router.push(a.to); }
            else if (a.tab) { this.switchTab(a.tab); }
        },
        switchTab(key) {
            this.activeTab = key;
            if (this.loadedTabs[key]) return;
            this.loadedTabs[key] = true;
            const map = { notifications: this.loadNotifications, templates: this.loadTemplates, delivery: this.loadDeliveryLogs, subscribers: this.loadSubscribers };
            if (map[key]) map[key]();
        },
        loadOverview() {
            const params = {};
            if (this.fromDate) params.from_date = this.fromDate;
            if (this.toDate) params.to_date = this.toDate;
            axios.get(this.$apiUrl + '/notification-analytics/overview', { params }).then(res => {
                const d = res.data.data;
                this.stats = d.stats;
                this.availability = d.availability || {};
                this.byAudience = d.by_audience || [];
                this.byType = d.by_type || [];
                this.recentNotifications = d.recent_notifications || [];
                this.recentBroadcasts = d.recent_broadcasts || [];
                this.buildCharts(d);
            }).catch(e => this.showMessage && this.showMessage('error', this.errMsg(e)));
        },
        buildCharts(d) {
            const t = d.notification_trend || { labels: [], sent: [] };
            this.trendChart = {
                series: [{ name: 'Sent', data: t.sent }],
                options: {
                    chart: { toolbar: { show: false }, sparkline: { enabled: false } },
                    stroke: { curve: 'smooth', width: 2 },
                    colors: ['#7c5cfc'],
                    fill: { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: 0.35, opacityTo: 0.05 } },
                    dataLabels: { enabled: false },
                    xaxis: { categories: t.labels, tickAmount: 8, labels: { rotate: 0, style: { fontSize: '10px' } } },
                    grid: { borderColor: '#f0f0f0' },
                },
            };

            const donutBase = (label) => ({
                labels: [], legend: { show: false }, dataLabels: { enabled: false }, stroke: { width: 2 },
                plotOptions: { pie: { donut: { size: '70%', labels: { show: true, name: { show: true }, value: { show: true, fontSize: '20px', fontWeight: 700 }, total: { show: true, label: label, fontSize: '12px', color: '#888', formatter: (w) => w.globals.seriesTotals.reduce((a, b) => a + b, 0).toLocaleString() } } } } },
            });

            const so = donutBase('Total');
            so.labels = ['Reached', 'Failed'];
            so.colors = ['#22c55e', '#ef4444'];
            const reached = d.delivery_status ? d.delivery_status.reached : 0;
            const failed = d.delivery_status ? d.delivery_status.failed : 0;
            this.statusChart = (reached || failed) ? { series: [reached, failed], options: so } : { series: [], options: so };

            const ao = donutBase('Sent');
            ao.labels = this.byAudience.map(a => a.name);
            ao.colors = this.byAudience.map((a, i) => this.colorAt(i));
            this.audienceChart = { series: this.byAudience.map(a => a.count), options: ao };
        },
        loadNotifications() {
            const params = { audience: this.notifFilters.audience, search: this.notifFilters.search, page: 1 };
            this.fetchNotifications(params);
        },
        pageNotifications(page) {
            this.fetchNotifications({ audience: this.notifFilters.audience, search: this.notifFilters.search, page });
        },
        fetchNotifications(params) {
            axios.get(this.$apiUrl + '/notification-analytics/notifications', { params }).then(res => {
                const p = res.data.data;
                this.notifications = p.data || [];
                this.notifMeta = { current_page: p.current_page, last_page: p.last_page };
            }).catch(e => this.showMessage && this.showMessage('error', this.errMsg(e)));
        },
        loadTemplates() {
            axios.get(this.$apiUrl + '/notification-analytics/templates').then(res => {
                this.templates = res.data.data.records || [];
                this.templatesNote = res.data.data.note || '';
            }).catch(e => this.showMessage && this.showMessage('error', this.errMsg(e)));
        },
        loadDeliveryLogs() {
            axios.get(this.$apiUrl + '/notification-analytics/delivery-logs').then(res => {
                this.deliveryLogs = res.data.data.records || [];
            }).catch(e => this.showMessage && this.showMessage('error', this.errMsg(e)));
        },
        loadSubscribers() {
            axios.get(this.$apiUrl + '/notification-analytics/subscribers').then(res => {
                this.subsByType = res.data.data.by_type || [];
                this.subsByPlatform = res.data.data.by_platform || [];
            }).catch(e => this.showMessage && this.showMessage('error', this.errMsg(e)));
        },
        errMsg(e) { return (e && e.response && e.response.data && e.response.data.message) || 'Something went wrong'; },
    },
};
</script>

<style scoped>
.notif-analytics .na-gap { gap: .5rem; }

/* Honesty banner / notes */
.notif-analytics .alert-note { background: #f4f1ff; border: 1px solid #e6e0ff; color: #5b4bb5; border-radius: 10px; padding: .6rem .85rem; font-size: .82rem; display: flex; align-items: flex-start; }
.notif-analytics .tiny-note { font-size: .72rem; color: #9ca3af; margin-top: .6rem; }
.notif-analytics .tiny-note code { color: #6b7280; }

/* Stat cards */
.na-stats { margin-bottom: .25rem; }
.na-stats .stat-card { height: 100%; border: 1px solid #eef0f4; border-radius: 14px; box-shadow: 0 1px 2px rgba(16,24,40,.04); transition: box-shadow .15s ease, transform .15s ease; }
.na-stats .stat-card:hover { transform: translateY(-2px); }
.na-stats .stat-card:hover { box-shadow: 0 4px 14px rgba(16,24,40,.08); }
.na-stats .stat-card .card-body { position: relative; padding: 16px 16px 14px; }
.na-stats .stat-icon { position: absolute; top: 20px; right: 14px; width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 15px; }
.na-stats .stat-label { font-size: .78rem; color: #6b7280; font-weight: 500; line-height: 1.25; padding-right: 46px; min-height: 2.4em; display: flex; align-items: center; }
.na-stats .stat-value { font-size: 1.8rem; font-weight: 700; line-height: 1; margin: 2px 0 5px; color: #111827; }
.na-stats .stat-sub { font-size: .72rem; font-weight: 500; }

/* Tabs */
.na-tabs { border-bottom: 1px solid #eef0f4; -ms-overflow-style: none; scrollbar-width: none; }
.na-tabs::-webkit-scrollbar { display: none; height: 0; }
.na-tabs .nav-link { cursor: pointer; white-space: nowrap; color: #6b7280; border: 0; border-bottom: 2px solid transparent; padding: .6rem 1rem; }
.na-tabs .nav-link:hover { color: #7c5cfc; }
.na-tabs .nav-link.active { font-weight: 600; color: #7c5cfc; background: transparent; border-bottom: 2px solid #7c5cfc; }
.na-tabs .soon-pill { font-size: .58rem; text-transform: uppercase; letter-spacing: .4px; background: #f3f4f6; color: #9ca3af; border-radius: 6px; padding: 1px 5px; margin-left: 5px; vertical-align: middle; }

/* Cards */
.notif-analytics .card { border: 1px solid #eef0f4; border-radius: 14px; box-shadow: 0 1px 2px rgba(16,24,40,.03); margin-bottom: 0; transition: box-shadow .15s ease; }
.notif-analytics .card:hover { box-shadow: 0 4px 14px rgba(16,24,40,.06); }
/* Standalone (non-grid) cards still need bottom spacing between stacked sections */
.notif-analytics > .page-heading > .card { margin-bottom: 1rem; }
.notif-analytics .card-body { padding: 1.15rem 1.25rem; }
.notif-analytics .card-header { background: transparent; border-bottom: 1px solid #f1f2f6; padding: .9rem 1.1rem; }
.notif-analytics .card-header h5 { font-size: 1rem; font-weight: 600; color: #111827; }

/* Tables */
.notif-analytics .table { margin-bottom: 0; }
.notif-analytics .table thead th { text-transform: uppercase; font-size: .68rem; letter-spacing: .4px; color: #9ca3af; font-weight: 600; border-bottom: 1px solid #eef0f4; border-top: 0; padding: .55rem .6rem; white-space: nowrap; }
.notif-analytics .table tbody td { border-top: 1px solid #f4f5f7; padding: .6rem .6rem; color: #374151; vertical-align: middle; }
.notif-analytics .table tbody tr:hover { background: #fafbff; }
.notif-analytics .table .fw-medium { font-weight: 600; color: #111827; }

/* Badges */
.notif-analytics .badge { font-weight: 500; padding: .38em .62em; border-radius: 6px; }
.notif-analytics .badge.bg-light { background: #f3f4f6 !important; }

/* Filter controls */
.notif-analytics .form-control-sm, .notif-analytics .form-select-sm { border-radius: 8px; border-color: #e5e7eb; }

/* Donut + legend */
.chart-flex { gap: .5rem 1rem; }
.donut-wrap { flex: 1 1 150px; max-width: 190px; min-width: 130px; }
.legend-list { list-style: none; margin: 0; padding: 0; flex: 1 1 150px; min-width: 140px; }
.legend-list li { display: flex; align-items: center; padding: 5px 0; font-size: .82rem; }
.legend-list .dot { width: 10px; height: 10px; border-radius: 50%; margin-right: 8px; flex: 0 0 auto; }
.legend-list .lg-name { flex: 1 1 auto; color: #374151; }
.legend-list .lg-val { font-weight: 600; color: #111827; }
.legend-list .lg-val small { color: #9ca3af; font-weight: 400; }

/* Bars (by type / subscribers) */
.dept-list { padding: .25rem 0; }
.dept-row { display: flex; align-items: center; margin-bottom: 12px; font-size: .82rem; }
.dept-row .dept-name { flex: 0 0 120px; color: #374151; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.dept-row .dept-track { flex: 1 1 auto; height: 8px; background: #f1f2f6; border-radius: 6px; overflow: hidden; margin: 0 10px; }
.dept-row .dept-fill { display: block; height: 100%; border-radius: 6px; }
.dept-row .dept-val { flex: 0 0 60px; text-align: right; font-weight: 600; color: #111827; }

/* Availability list */
.avail-list { list-style: none; margin: 0; padding: 0; }
.avail-list li { display: flex; align-items: center; padding: 9px 0; border-bottom: 1px solid #f4f5f7; font-size: .85rem; }
.avail-list li:last-child { border-bottom: 0; }
.avail-list span { flex: 1 1 auto; color: #4b5563; }
.avail-list b { font-weight: 600; }

/* Quick Actions */
.qa-grid { display: grid; grid-template-columns: repeat(6, 1fr); gap: .75rem; }
.qa-tile { display: flex; flex-direction: column; align-items: center; text-align: center; gap: .5rem; padding: .95rem .5rem; border: 1px solid #eef0f4; border-radius: 12px; color: #374151; text-decoration: none; background: #fff; transition: box-shadow .15s ease, transform .15s ease, border-color .15s ease; }
.qa-tile:hover { box-shadow: 0 4px 14px rgba(16,24,40,.08); transform: translateY(-2px); border-color: #e6e0ff; color: #374151; }
.qa-tile.disabled { cursor: default; opacity: .7; }
.qa-tile.disabled:hover { box-shadow: none; transform: none; border-color: #eef0f4; }
.qa-ic { width: 42px; height: 42px; border-radius: 11px; display: flex; align-items: center; justify-content: center; font-size: 17px; }
.qa-label { font-size: .8rem; font-weight: 500; line-height: 1.2; }
.qa-soon { display: block; font-size: .58rem; text-transform: uppercase; letter-spacing: .4px; color: #9ca3af; margin-top: 2px; }
@media (max-width: 991.98px) { .qa-grid { grid-template-columns: repeat(3, 1fr); } }
@media (max-width: 575.98px) { .qa-grid { grid-template-columns: repeat(2, 1fr); } }

/* View-all footer links */
.notif-analytics .card-footer.view-all-footer { background: transparent; border-top: 1px solid #f1f2f6; padding: .7rem 1.1rem; text-align: center; }
.notif-analytics .view-all { font-size: .82rem; font-weight: 600; color: #7c5cfc; text-decoration: none; display: inline-flex; align-items: center; transition: color .15s ease; }
.notif-analytics .view-all:hover { color: #5b4bb5; }
.notif-analytics .view-all i { transition: transform .15s ease; }
.notif-analytics .view-all:hover i { transform: translateX(3px); }

/* Roadmap placeholder */
.roadmap-icon { width: 62px; height: 62px; border-radius: 16px; background: #f4f1ff; color: #7c5cfc; display: flex; align-items: center; justify-content: center; font-size: 26px; margin: 0 auto 14px; }

.fw-medium { font-weight: 500; }

/* Donut charts centre when their column is full-width (mobile / tablet) */
@media (max-width: 767.98px) {
    .chart-flex { justify-content: center; }
    .donut-wrap { max-width: 220px; }
    .legend-list { flex: 1 1 100%; min-width: 0; margin-top: .5rem; }
    .notif-analytics .card-body { padding: 1rem; }
    .na-stats .stat-value { font-size: 1.5rem; }
    .na-stats .stat-label { min-height: 2.2em; }
    .dept-row .dept-name { flex-basis: 90px; }
    /* Keep the toolbar tidy on phones */
    .notif-analytics .na-gap > * { flex: 1 1 auto; }
}

/* Tables never break the layout — scroll inside their card instead */
.notif-analytics .table-responsive { -webkit-overflow-scrolling: touch; }
.notif-analytics .table { min-width: 480px; }
@media (min-width: 992px) {
    .notif-analytics .table { min-width: 0; }
}
</style>
