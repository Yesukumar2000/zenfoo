<template>
    <div class="refunds-disputes">
        <div class="page-heading">
            <!-- Header -->
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3 class="mb-0">Refunds &amp; Disputes</h3>
                        <p class="text-subtitle text-muted mb-0">Track, manage and resolve all refund requests, disputes and chargebacks.</p>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">Dashboard</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">Refunds &amp; Disputes</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <!-- Toolbar -->
            <div class="d-flex flex-wrap justify-content-end align-items-end rd-gap mb-3">
                <div>
                    <label class="small text-muted d-block mb-1">From</label>
                    <input type="date" v-model="fromDate" class="form-control form-control-sm" />
                </div>
                <div>
                    <label class="small text-muted d-block mb-1">To</label>
                    <input type="date" v-model="toDate" class="form-control form-control-sm" />
                </div>
                <button class="btn btn-sm rd-apply" @click="applyFilter"><i class="fa fa-filter me-1"></i> Apply</button>
                <a class="btn btn-sm btn-outline-secondary" :href="exportUrl" target="_blank"><i class="fa fa-download me-1"></i> Export Report</a>
            </div>

            <!-- Stat cards -->
            <div class="row g-3 rd-stats mb-1">
                <div class="col-6 col-sm-4 col-xl-2" v-for="card in statCards" :key="card.key">
                    <div class="card stat-card">
                        <div class="card-body">
                            <span class="stat-icon" :style="{ background: card.bg, color: card.color }"><i :class="'fa ' + card.icon"></i></span>
                            <div class="stat-label">{{ card.label }}</div>
                            <div class="stat-value">{{ card.money ? inr(stats[card.key]) : formatNum(stats[card.key]) }}</div>
                            <div class="stat-sub" :style="{ color: card.color }">{{ card.sub }}</div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tabs -->
            <ul class="nav nav-tabs rd-tabs mt-2 mb-3 flex-nowrap overflow-auto">
                <li class="nav-item" v-for="t in tabs" :key="t.key">
                    <a class="nav-link" :class="{ active: activeTab === t.key }" href="javascript:void(0)" @click="switchTab(t.key)">{{ t.label }}</a>
                </li>
            </ul>

            <!-- ================= OVERVIEW ================= -->
            <div v-show="activeTab === 'overview'">
                <div class="row g-3 mb-3">
                    <!-- Refund Amount Trend -->
                    <div class="col-12 col-xl-5">
                        <div class="card h-100">
                            <div class="card-header d-flex align-items-center">
                                <h5 class="mb-0 me-auto">Refund Amount Trend</h5>
                                <select v-model="trendGroup" class="form-select form-select-sm w-auto" @change="loadOverview">
                                    <option value="daily">Daily</option>
                                    <option value="weekly">Weekly</option>
                                </select>
                            </div>
                            <div class="card-body">
                                <apexchart v-if="trendChart.series.length" type="line" height="270"
                                           :options="trendChart.options" :series="trendChart.series"></apexchart>
                                <p v-else class="text-muted text-center my-5">No data in this period</p>
                            </div>
                        </div>
                    </div>
                    <!-- Refunds by Status -->
                    <div class="col-12 col-md-6 col-xl-4">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Refunds by Status</h5></div>
                            <div class="card-body">
                                <div class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                    <div class="donut-wrap">
                                        <apexchart v-if="statusChart.series.length" type="donut" height="200"
                                                   :options="statusChart.options" :series="statusChart.series"></apexchart>
                                        <p v-else class="text-muted text-center my-5">No data</p>
                                    </div>
                                    <ul class="legend-list">
                                        <li v-for="(s,i) in refundsByStatus" :key="i">
                                            <span class="dot" :style="{ background: statusColor(s.name, i) }"></span>
                                            <span class="lg-name">{{ s.name }}</span>
                                            <span class="lg-val">{{ formatNum(s.count) }} <small>({{ pct(s.count, refundsTotalCount) }}%)</small></span>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- Refunds by Source -->
                    <div class="col-12 col-md-6 col-xl-3" v-if="refundsBySource.length">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Refunds by Source</h5></div>
                            <div class="card-body">
                                <div class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                    <div class="donut-wrap">
                                        <apexchart type="donut" height="200" :options="sourceChart.options" :series="sourceChart.series"></apexchart>
                                    </div>
                                    <ul class="legend-list">
                                        <li v-for="(s,i) in refundsBySource" :key="i">
                                            <span class="dot" :style="{ background: colorAt(i) }"></span>
                                            <span class="lg-name">{{ s.name }}</span>
                                            <span class="lg-val">{{ inr(s.amount) }}</span>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-3">
                    <!-- Refunds by Reason (Top 5) -->
                    <div class="col-12 col-xl-4">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Refunds by Reason (Top 5)</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>Reason</th><th>Refunds</th><th>Amount</th><th>% of Total</th></tr></thead>
                                    <tbody>
                                        <tr v-for="(r,i) in refundsByReason" :key="i">
                                            <td class="fw-medium text-truncate" style="max-width:150px" :title="r.reason">{{ r.reason }}</td>
                                            <td>{{ formatNum(r.count) }}</td>
                                            <td>{{ inr(r.amount) }}</td>
                                            <td class="small text-muted">{{ r.pct }}%</td>
                                        </tr>
                                        <tr v-if="!refundsByReason.length"><td colspan="4" class="text-center text-muted">No reason data</td></tr>
                                    </tbody>
                                </table>
                            </div>
                            <div class="card-footer view-all-footer">
                                <a href="javascript:void(0)" class="view-all" @click="switchTab('reasons')">View All Reasons <i class="fa fa-arrow-right ms-1"></i></a>
                            </div>
                        </div>
                    </div>
                    <!-- Disputes by Status -->
                    <div class="col-12 col-md-6 col-xl-4">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Disputes by Status</h5></div>
                            <div class="card-body">
                                <div class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                    <div class="donut-wrap">
                                        <apexchart v-if="disputeStatusChart.series.length" type="donut" height="200"
                                                   :options="disputeStatusChart.options" :series="disputeStatusChart.series"></apexchart>
                                        <p v-else class="text-muted text-center my-5">No data</p>
                                    </div>
                                    <ul class="legend-list">
                                        <li v-for="(s,i) in disputesByStatus" :key="i">
                                            <span class="dot" :style="{ background: colorAt(i) }"></span>
                                            <span class="lg-name">{{ s.name }}</span>
                                            <span class="lg-val">{{ formatNum(s.count) }} <small>({{ pct(s.count, disputesTotalCount) }}%)</small></span>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- Disputes by Type -->
                    <div class="col-12 col-md-6 col-xl-4">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Disputes by Type</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>Type</th><th>Disputes</th><th>Amount</th><th>% of Total</th></tr></thead>
                                    <tbody>
                                        <tr v-for="(d,i) in disputesByType" :key="i">
                                            <td class="fw-medium text-truncate" style="max-width:150px" :title="d.type">{{ d.type }}</td>
                                            <td>{{ formatNum(d.count) }}</td>
                                            <td>{{ inr(d.amount) }}</td>
                                            <td class="small text-muted">{{ d.pct }}%</td>
                                        </tr>
                                        <tr v-if="!disputesByType.length"><td colspan="4" class="text-center text-muted">No type data</td></tr>
                                    </tbody>
                                </table>
                            </div>
                            <div class="card-footer view-all-footer">
                                <a href="javascript:void(0)" class="view-all" @click="switchTab('disputes')">View All Disputes <i class="fa fa-arrow-right ms-1"></i></a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-3">
                    <!-- Recent Refunds -->
                    <div class="col-12">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Recent Refunds</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>Refund ID</th><th>Order ID</th><th>User</th><th>Type</th><th>Reason</th><th>Amount</th><th>Status</th><th>Date</th></tr></thead>
                                    <tbody>
                                        <tr v-for="r in recentRefunds" :key="r.id">
                                            <td class="small text-muted">{{ r.refund_id }}</td>
                                            <td class="small text-muted">{{ r.order_id }}</td>
                                            <td class="fw-medium">{{ r.user }}</td>
                                            <td class="small">{{ r.type }}</td>
                                            <td class="small text-muted text-truncate" style="max-width:160px" :title="r.reason">{{ r.reason }}</td>
                                            <td>{{ inr(r.amount) }}</td>
                                            <td><span class="badge" :class="refundStatusClass(r.status)">{{ r.status }}</span></td>
                                            <td class="small text-muted">{{ r.date | dt }}</td>
                                        </tr>
                                        <tr v-if="!recentRefunds.length"><td colspan="8" class="text-center text-muted">No refunds</td></tr>
                                    </tbody>
                                </table>
                            </div>
                            <div class="card-footer view-all-footer">
                                <a href="javascript:void(0)" class="view-all" @click="switchTab('refunds')">View All Refunds <i class="fa fa-arrow-right ms-1"></i></a>
                            </div>
                        </div>
                    </div>
                    <!-- Recent Disputes -->
                    <div class="col-12">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Recent Disputes</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>Dispute ID</th><th>Order ID</th><th>User</th><th>Type</th><th>Amount</th><th>Status</th><th>Date</th></tr></thead>
                                    <tbody>
                                        <tr v-for="d in recentDisputes" :key="d.id">
                                            <td class="small text-muted">{{ d.dispute_id }}</td>
                                            <td class="small text-muted">{{ d.order_id }}</td>
                                            <td class="fw-medium">{{ d.user }}</td>
                                            <td class="small text-truncate" style="max-width:150px" :title="d.type">{{ d.type }}</td>
                                            <td>{{ inr(d.amount) }}</td>
                                            <td><span class="badge" :class="disputeStatusClass(d.status)">{{ d.status }}</span></td>
                                            <td class="small text-muted">{{ d.date | dt }}</td>
                                        </tr>
                                        <tr v-if="!recentDisputes.length"><td colspan="7" class="text-center text-muted">No disputes</td></tr>
                                    </tbody>
                                </table>
                            </div>
                            <div class="card-footer view-all-footer">
                                <a href="javascript:void(0)" class="view-all" @click="switchTab('disputes')">View All Disputes <i class="fa fa-arrow-right ms-1"></i></a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-3">
                    <!-- Chargebacks Summary -->
                    <div class="col-12 col-xl-4" v-if="chargebacks">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Chargebacks Summary</h5></div>
                            <div class="card-body">
                                <div class="cb-grid">
                                    <div class="cb-tile"><small>Total</small><b>{{ formatNum(chargebacks.total) }}</b></div>
                                    <div class="cb-tile"><small>Amount</small><b>{{ inr(chargebacks.amount) }}</b></div>
                                    <div class="cb-tile"><small>Won</small><b class="text-success">{{ formatNum(chargebacks.won) }}</b></div>
                                    <div class="cb-tile"><small>Lost</small><b class="text-danger">{{ formatNum(chargebacks.lost) }}</b></div>
                                    <div class="cb-tile"><small>Representment</small><b class="text-warning">{{ formatNum(chargebacks.representment) }}</b></div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- Refund Insights -->
                    <div class="col-12" :class="chargebacks ? 'col-xl-4' : 'col-xl-6'" v-if="refundInsights.length">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Refund Insights</h5></div>
                            <div class="card-body">
                                <ul class="insight-list mb-0">
                                    <li v-for="(t,i) in refundInsights" :key="i"><i class="fa fa-lightbulb sec-ic text-warning"></i><span v-html="t"></span></li>
                                </ul>
                            </div>
                        </div>
                    </div>
                    <!-- Top Merchants by Refund Amount -->
                    <div class="col-12" :class="chargebacks ? 'col-xl-4' : 'col-xl-6'" v-if="topMerchants.length">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Top Merchants by Refund Amount</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>Merchant</th><th>Refunds</th><th>Amount</th></tr></thead>
                                    <tbody>
                                        <tr v-for="(m,i) in topMerchants" :key="i">
                                            <td class="fw-medium text-truncate" style="max-width:150px" :title="m.name">{{ m.name }}</td>
                                            <td>{{ formatNum(m.refunds) }}</td>
                                            <td>{{ inr(m.amount) }}</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ================= REFUNDS ================= -->
            <div v-show="activeTab === 'refunds'">
                <div class="card">
                    <div class="card-header d-flex flex-wrap rd-gap align-items-center">
                        <h5 class="mb-0 me-auto">Refunds</h5>
                        <input v-model="refundFilters.search" type="search" class="form-control form-control-sm w-auto" placeholder="Search..." @keyup.enter="loadRefunds" />
                        <select v-model="refundFilters.status" class="form-select form-select-sm w-auto" @change="loadRefunds">
                            <option value="">All Status</option>
                            <option v-for="s in refundStatuses" :key="s" :value="s">{{ s }}</option>
                        </select>
                    </div>
                    <div class="card-body table-responsive">
                        <table class="table align-middle">
                            <thead><tr><th>Refund ID</th><th>Order ID</th><th>User</th><th>Type</th><th>Reason</th><th>Amount</th><th>Status</th><th>Date</th></tr></thead>
                            <tbody>
                                <tr v-for="r in refunds" :key="r.id">
                                    <td class="small text-muted">{{ r.refund_id }}</td>
                                    <td class="small text-muted">{{ r.order_id }}</td>
                                    <td class="fw-medium">{{ r.user }}</td>
                                    <td class="small">{{ r.type }}</td>
                                    <td class="small text-muted text-truncate" style="max-width:180px" :title="r.reason">{{ r.reason }}</td>
                                    <td>{{ inr(r.amount) }}</td>
                                    <td><span class="badge" :class="refundStatusClass(r.status)">{{ r.status }}</span></td>
                                    <td class="small text-muted">{{ r.date | dt }}</td>
                                </tr>
                                <tr v-if="!refunds.length"><td colspan="8" class="text-center text-muted">No refunds found</td></tr>
                            </tbody>
                        </table>
                        <div v-if="refundMeta.last_page > 1" class="d-flex justify-content-end align-items-center rd-gap pt-2">
                            <button class="btn btn-sm btn-outline-secondary" :disabled="refundMeta.current_page <= 1" @click="pageRefunds(refundMeta.current_page - 1)">Prev</button>
                            <span class="small text-muted">Page {{ refundMeta.current_page }} / {{ refundMeta.last_page }}</span>
                            <button class="btn btn-sm btn-outline-secondary" :disabled="refundMeta.current_page >= refundMeta.last_page" @click="pageRefunds(refundMeta.current_page + 1)">Next</button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ================= DISPUTES ================= -->
            <div v-show="activeTab === 'disputes'">
                <div class="card">
                    <div class="card-header d-flex flex-wrap rd-gap align-items-center">
                        <h5 class="mb-0 me-auto">Disputes</h5>
                        <input v-model="disputeFilters.search" type="search" class="form-control form-control-sm w-auto" placeholder="Search..." @keyup.enter="loadDisputes" />
                        <select v-model="disputeFilters.status" class="form-select form-select-sm w-auto" @change="loadDisputes">
                            <option value="">All Status</option>
                            <option v-for="s in disputeStatuses" :key="s" :value="s">{{ s }}</option>
                        </select>
                    </div>
                    <div class="card-body table-responsive">
                        <table class="table align-middle">
                            <thead><tr><th>Dispute ID</th><th>Order ID</th><th>User</th><th>Type</th><th>Amount</th><th>Status</th><th>Date</th></tr></thead>
                            <tbody>
                                <tr v-for="d in disputes" :key="d.id">
                                    <td class="small text-muted">{{ d.dispute_id }}</td>
                                    <td class="small text-muted">{{ d.order_id }}</td>
                                    <td class="fw-medium">{{ d.user }}</td>
                                    <td class="small text-truncate" style="max-width:180px" :title="d.type">{{ d.type }}</td>
                                    <td>{{ inr(d.amount) }}</td>
                                    <td><span class="badge" :class="disputeStatusClass(d.status)">{{ d.status }}</span></td>
                                    <td class="small text-muted">{{ d.date | dt }}</td>
                                </tr>
                                <tr v-if="!disputes.length"><td colspan="7" class="text-center text-muted">No disputes found</td></tr>
                            </tbody>
                        </table>
                        <div v-if="disputeMeta.last_page > 1" class="d-flex justify-content-end align-items-center rd-gap pt-2">
                            <button class="btn btn-sm btn-outline-secondary" :disabled="disputeMeta.current_page <= 1" @click="pageDisputes(disputeMeta.current_page - 1)">Prev</button>
                            <span class="small text-muted">Page {{ disputeMeta.current_page }} / {{ disputeMeta.last_page }}</span>
                            <button class="btn btn-sm btn-outline-secondary" :disabled="disputeMeta.current_page >= disputeMeta.last_page" @click="pageDisputes(disputeMeta.current_page + 1)">Next</button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ================= REASONS ================= -->
            <div v-show="activeTab === 'reasons'">
                <div class="card">
                    <div class="card-header"><h5 class="mb-0">Refund Reasons &amp; Categories</h5></div>
                    <div class="card-body table-responsive">
                        <table class="table align-middle">
                            <thead><tr><th>Reason</th><th>Refunds</th><th>Amount</th><th>% of Total</th></tr></thead>
                            <tbody>
                                <tr v-for="(r,i) in allReasons" :key="i">
                                    <td class="fw-medium">{{ r.reason }}</td>
                                    <td>{{ formatNum(r.count) }}</td>
                                    <td>{{ inr(r.amount) }}</td>
                                    <td>
                                        <span class="reason-track"><span class="reason-fill" :style="{ width: Math.min(100, r.pct) + '%' }"></span></span>
                                        <span class="small text-muted ms-2">{{ r.pct }}%</span>
                                    </td>
                                </tr>
                                <tr v-if="!allReasons.length"><td colspan="4" class="text-center text-muted">No reasons</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    name: 'RefundsDisputes',
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
            trendGroup: 'daily',
            palette: ['#7c5cfc', '#22c55e', '#3b82f6', '#f59e0b', '#ef4444', '#14b8a6', '#a855f7', '#0ea5e9', '#ec4899'],
            tabs: [
                { key: 'overview', label: 'Overview' },
                { key: 'refunds', label: 'Refunds' },
                { key: 'disputes', label: 'Disputes' },
                { key: 'reasons', label: 'Reasons' },
            ],
            statCards: [
                { key: 'total_refund_amount', label: 'Total Refund Amount', icon: 'fa-rupee-sign', bg: '#fdeaea', color: '#ef4444', sub: 'in selected period', money: true },
                { key: 'total_refunds', label: 'Total Refunds', icon: 'fa-receipt', bg: '#efeaff', color: '#7c5cfc', sub: 'refund records' },
                { key: 'pending_refunds', label: 'Pending Refunds', icon: 'fa-clock', bg: '#fff4e5', color: '#f59e0b', sub: 'awaiting action' },
                { key: 'approved_refunds', label: 'Approved Refunds', icon: 'fa-check-circle', bg: '#e7f8ef', color: '#22c55e', sub: 'approved' },
                { key: 'total_disputes', label: 'Total Disputes', icon: 'fa-gavel', bg: '#e8f1ff', color: '#3b82f6', sub: 'issue reports' },
                { key: 'chargebacks', label: 'Chargebacks', icon: 'fa-credit-card', bg: '#f3f4f6', color: '#9ca3af', sub: 'not tracked' },
            ],
            stats: { total_refund_amount: 0, total_refunds: 0, pending_refunds: 0, approved_refunds: 0, total_disputes: 0, chargebacks: 0 },

            trendChart: { options: {}, series: [] },
            statusChart: { options: {}, series: [] },
            sourceChart: { options: {}, series: [] },
            disputeStatusChart: { options: {}, series: [] },

            refundsByStatus: [],
            refundsBySource: [],
            refundsByReason: [],
            disputesByStatus: [],
            disputesByType: [],
            recentRefunds: [],
            recentDisputes: [],
            chargebacks: null,
            refundInsights: [],
            topMerchants: [],

            refunds: [],
            refundFilters: { search: '', status: '' },
            refundMeta: { current_page: 1, last_page: 1 },
            refundStatuses: ['Pending', 'Approved', 'Rejected'],

            disputes: [],
            disputeFilters: { search: '', status: '' },
            disputeMeta: { current_page: 1, last_page: 1 },
            disputeStatuses: [],

            allReasons: [],
        };
    },
    computed: {
        exportUrl() {
            let u = this.$apiUrl + '/refund-dispute-analytics/export';
            const p = [];
            if (this.fromDate) p.push('from_date=' + this.fromDate);
            if (this.toDate) p.push('to_date=' + this.toDate);
            return p.length ? u + '?' + p.join('&') : u;
        },
        refundsTotalCount() { return this.refundsByStatus.reduce((a, b) => a + (b.count || 0), 0); },
        disputesTotalCount() { return this.disputesByStatus.reduce((a, b) => a + (b.count || 0), 0); },
    },
    created() {
        this.loadOverview();
    },
    methods: {
        colorAt(i) { return this.palette[i % this.palette.length]; },
        formatNum(n) { return (n === null || n === undefined) ? '—' : Number(n).toLocaleString('en-IN'); },
        inr(n) { return (n === null || n === undefined) ? '—' : '₹' + Number(n).toLocaleString('en-IN', { maximumFractionDigits: 2 }); },
        pct(n, total) { return total ? Math.round(n * 1000 / total) / 10 : 0; },
        statusColor(name, i) {
            const m = { Approved: '#22c55e', Pending: '#f59e0b', Rejected: '#ef4444', Cancelled: '#a855f7' };
            return m[name] || this.colorAt(i);
        },
        refundStatusClass(s) {
            const v = (s || '').toLowerCase();
            if (v === 'approved') return 'bg-success';
            if (v === 'pending') return 'bg-warning';
            if (v === 'rejected') return 'bg-danger';
            if (v === 'cancelled') return 'bg-secondary';
            return 'bg-light text-dark';
        },
        disputeStatusClass(s) {
            const v = (s || '').toLowerCase();
            if (v.indexOf('resolv') >= 0) return 'bg-success';
            if (v.indexOf('review') >= 0) return 'bg-info';
            if (v.indexOf('request') >= 0 || v.indexOf('pending') >= 0) return 'bg-warning';
            if (v.indexOf('reject') >= 0) return 'bg-danger';
            if (v.indexOf('escalat') >= 0) return 'bg-dark';
            return 'bg-light text-dark';
        },
        switchTab(key) {
            this.activeTab = key;
            if (this.loadedTabs[key]) return;
            this.loadedTabs[key] = true;
            const map = { refunds: this.loadRefunds, disputes: this.loadDisputes, reasons: this.loadReasons };
            if (map[key]) map[key]();
        },
        applyFilter() {
            // Refresh the overview and whatever list the user is currently viewing.
            this.loadOverview();
            if (this.activeTab === 'refunds') this.loadRefunds();
            else if (this.activeTab === 'disputes') this.loadDisputes();
            else if (this.activeTab === 'reasons') this.loadReasons();
        },
        loadOverview() {
            const params = { group: this.trendGroup };
            if (this.fromDate) params.from_date = this.fromDate;
            if (this.toDate) params.to_date = this.toDate;
            axios.get(this.$apiUrl + '/refund-dispute-analytics/overview', { params }).then(res => {
                const d = res.data.data;
                this.stats = d.stats;
                this.refundsByStatus = d.refunds_by_status || [];
                this.refundsBySource = d.refunds_by_source || [];
                this.refundsByReason = d.refunds_by_reason || [];
                this.disputesByStatus = d.disputes_by_status || [];
                this.disputesByType = d.disputes_by_type || [];
                this.recentRefunds = d.recent_refunds || [];
                this.recentDisputes = d.recent_disputes || [];
                this.chargebacks = d.chargebacks || null;
                this.refundInsights = d.refund_insights || [];
                this.topMerchants = d.top_merchants || [];
                if (d.dispute_statuses) this.disputeStatuses = d.dispute_statuses;
                this.buildCharts(d);
            }).catch(e => this.showMessage && this.showMessage('error', this.errMsg(e)));
        },
        buildCharts(d) {
            const t = d.refund_trend || { labels: [], amount: [], count: [] };
            this.trendChart = {
                series: [
                    { name: 'Refund Amount (₹)', type: 'area', data: t.amount },
                    { name: 'Refund Count', type: 'line', data: t.count },
                ],
                options: {
                    chart: { toolbar: { show: false } },
                    stroke: { curve: 'smooth', width: 2 },
                    colors: ['#22c55e', '#3b82f6'],
                    fill: { type: ['gradient', 'solid'], gradient: { opacityFrom: 0.3, opacityTo: 0.05 } },
                    dataLabels: { enabled: false },
                    xaxis: { categories: t.labels, tickAmount: 8, labels: { rotate: 0, style: { fontSize: '10px' } } },
                    yaxis: [
                        { seriesName: 'Refund Amount (₹)', labels: { formatter: (v) => this.shortInr(v) } },
                        { opposite: true, seriesName: 'Refund Count', labels: { formatter: (v) => Math.round(v) } },
                    ],
                    legend: { position: 'top' },
                    grid: { borderColor: '#f0f0f0' },
                },
            };

            const donutBase = (label, fmtTotal) => ({
                labels: [], legend: { show: false }, dataLabels: { enabled: false }, stroke: { width: 2 },
                plotOptions: { pie: { donut: { size: '68%', labels: { show: true, name: { show: true }, value: { show: true, fontSize: '18px', fontWeight: 700 }, total: { show: true, label: label, fontSize: '11px', color: '#888', formatter: fmtTotal } } } } },
            });

            const so = donutBase('Total Refunds', (w) => this.formatNum(w.globals.seriesTotals.reduce((a, b) => a + b, 0)));
            so.labels = this.refundsByStatus.map(s => s.name);
            so.colors = this.refundsByStatus.map((s, i) => this.statusColor(s.name, i));
            this.statusChart = this.refundsByStatus.length ? { series: this.refundsByStatus.map(s => s.count), options: so } : { series: [], options: so };

            if (this.refundsBySource.length) {
                const src = donutBase('Total Amount', (w) => this.shortInr(w.globals.seriesTotals.reduce((a, b) => a + b, 0)));
                src.labels = this.refundsBySource.map(s => s.name);
                src.colors = this.refundsBySource.map((s, i) => this.colorAt(i));
                this.sourceChart = { series: this.refundsBySource.map(s => s.amount), options: src };
            }

            const dso = donutBase('Total Disputes', (w) => this.formatNum(w.globals.seriesTotals.reduce((a, b) => a + b, 0)));
            dso.labels = this.disputesByStatus.map(s => s.name);
            dso.colors = this.disputesByStatus.map((s, i) => this.colorAt(i));
            this.disputeStatusChart = this.disputesByStatus.length ? { series: this.disputesByStatus.map(s => s.count), options: dso } : { series: [], options: dso };
        },
        shortInr(v) {
            v = Number(v) || 0;
            if (v >= 10000000) return '₹' + (v / 10000000).toFixed(1) + 'Cr';
            if (v >= 100000) return '₹' + (v / 100000).toFixed(1) + 'L';
            if (v >= 1000) return '₹' + (v / 1000).toFixed(1) + 'K';
            return '₹' + v;
        },
        dateParams() {
            const p = {};
            if (this.fromDate) p.from_date = this.fromDate;
            if (this.toDate) p.to_date = this.toDate;
            return p;
        },
        loadRefunds() { this.fetchRefunds(Object.assign({ status: this.refundFilters.status, search: this.refundFilters.search, page: 1 }, this.dateParams())); },
        pageRefunds(page) { this.fetchRefunds(Object.assign({ status: this.refundFilters.status, search: this.refundFilters.search, page }, this.dateParams())); },
        fetchRefunds(params) {
            axios.get(this.$apiUrl + '/refund-dispute-analytics/refunds', { params }).then(res => {
                const p = res.data.data;
                this.refunds = p.data || [];
                this.refundMeta = { current_page: p.current_page, last_page: p.last_page };
            }).catch(e => this.showMessage && this.showMessage('error', this.errMsg(e)));
        },
        loadDisputes() { this.fetchDisputes(Object.assign({ status: this.disputeFilters.status, search: this.disputeFilters.search, page: 1 }, this.dateParams())); },
        pageDisputes(page) { this.fetchDisputes(Object.assign({ status: this.disputeFilters.status, search: this.disputeFilters.search, page }, this.dateParams())); },
        fetchDisputes(params) {
            axios.get(this.$apiUrl + '/refund-dispute-analytics/disputes', { params }).then(res => {
                const p = res.data.data;
                this.disputes = p.data || [];
                this.disputeMeta = { current_page: p.current_page, last_page: p.last_page };
            }).catch(e => this.showMessage && this.showMessage('error', this.errMsg(e)));
        },
        loadReasons() {
            axios.get(this.$apiUrl + '/refund-dispute-analytics/reasons', { params: this.dateParams() }).then(res => {
                this.allReasons = res.data.data.records || [];
            }).catch(e => this.showMessage && this.showMessage('error', this.errMsg(e)));
        },
        errMsg(e) { return (e && e.response && e.response.data && e.response.data.message) || 'Something went wrong'; },
    },
};
</script>

<style scoped>
.refunds-disputes .rd-gap { gap: .5rem; }

/* Prominent Apply button (primary action of the date filter) */
.refunds-disputes .rd-apply { background: #7c5cfc; border: 1px solid #7c5cfc; color: #fff; font-weight: 600; padding: .28rem .95rem; box-shadow: 0 2px 6px rgba(124,92,252,.28); transition: background .15s ease, box-shadow .15s ease; }
.refunds-disputes .rd-apply:hover, .refunds-disputes .rd-apply:focus { background: #6a4be0; border-color: #6a4be0; color: #fff; box-shadow: 0 4px 12px rgba(124,92,252,.4); }

/* Stat cards */
.rd-stats { margin-bottom: .25rem; }
.rd-stats .stat-card { height: 100%; border: 1px solid #eef0f4; border-radius: 14px; box-shadow: 0 1px 2px rgba(16,24,40,.04); transition: box-shadow .15s ease, transform .15s ease; }
.rd-stats .stat-card:hover { transform: translateY(-2px); }
.rd-stats .stat-card .card-body { position: relative; padding: 16px 16px 14px; }
.rd-stats .stat-icon { position: absolute; top: 20px; right: 14px; width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 15px; }
.rd-stats .stat-label { font-size: .78rem; color: #6b7280; font-weight: 500; line-height: 1.25; padding-right: 46px; min-height: 2.4em; display: flex; align-items: center; }
.rd-stats .stat-value { font-size: 1.55rem; font-weight: 700; line-height: 1; margin: 2px 0 5px; color: #111827; }
.rd-stats .stat-sub { font-size: .72rem; font-weight: 500; }

/* Tabs */
.rd-tabs { border-bottom: 1px solid #eef0f4; -ms-overflow-style: none; scrollbar-width: none; }
.rd-tabs::-webkit-scrollbar { display: none; height: 0; }
.rd-tabs .nav-link { cursor: pointer; white-space: nowrap; color: #6b7280; border: 0; border-bottom: 2px solid transparent; padding: .6rem 1rem; }
.rd-tabs .nav-link:hover { color: #7c5cfc; }
.rd-tabs .nav-link.active { font-weight: 600; color: #7c5cfc; background: transparent; border-bottom: 2px solid #7c5cfc; }

/* Cards */
.refunds-disputes .card { border: 1px solid #eef0f4; border-radius: 14px; box-shadow: 0 1px 2px rgba(16,24,40,.03); margin-bottom: 0; transition: box-shadow .15s ease; }
.refunds-disputes .card:hover { box-shadow: 0 4px 14px rgba(16,24,40,.06); }
.refunds-disputes .card-body { padding: 1.15rem 1.25rem; }
.refunds-disputes .card-header { background: transparent; border-bottom: 1px solid #f1f2f6; padding: .9rem 1.1rem; }
.refunds-disputes .card-header h5 { font-size: 1rem; font-weight: 600; color: #111827; }

/* Tables */
.refunds-disputes .table { margin-bottom: 0; }
.refunds-disputes .table thead th { text-transform: uppercase; font-size: .68rem; letter-spacing: .4px; color: #9ca3af; font-weight: 600; border-bottom: 1px solid #eef0f4; border-top: 0; padding: .55rem .6rem; white-space: nowrap; }
.refunds-disputes .table tbody td { border-top: 1px solid #f4f5f7; padding: .6rem .6rem; color: #374151; vertical-align: middle; }
.refunds-disputes .table tbody tr:hover { background: #fafbff; }
.refunds-disputes .table .fw-medium { font-weight: 600; color: #111827; }

/* Badges */
.refunds-disputes .badge { font-weight: 500; padding: .38em .62em; border-radius: 6px; }
.refunds-disputes .badge.bg-light { background: #f3f4f6 !important; }

/* Filters */
.refunds-disputes .form-control-sm, .refunds-disputes .form-select-sm { border-radius: 8px; border-color: #e5e7eb; }

/* Donut + legend */
.chart-flex { gap: .5rem 1rem; }
.donut-wrap { flex: 1 1 150px; max-width: 200px; min-width: 130px; }
.legend-list { list-style: none; margin: 0; padding: 0; flex: 1 1 150px; min-width: 140px; }
.legend-list li { display: flex; align-items: center; padding: 5px 0; font-size: .8rem; }
.legend-list .dot { width: 10px; height: 10px; border-radius: 50%; margin-right: 8px; flex: 0 0 auto; }
.legend-list .lg-name { flex: 1 1 auto; color: #374151; }
.legend-list .lg-val { font-weight: 600; color: #111827; }
.legend-list .lg-val small { color: #9ca3af; font-weight: 400; }

/* Chargebacks tiles */
.cb-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: .6rem; }
.cb-tile { border: 1px solid #eef0f4; border-radius: 10px; padding: .7rem .8rem; text-align: center; }
.cb-tile small { display: block; color: #9ca3af; font-size: .7rem; text-transform: uppercase; letter-spacing: .3px; }
.cb-tile b { font-size: 1.15rem; color: #111827; }
.cb-tile:first-child { grid-column: span 2; }

/* Insights */
.insight-list { list-style: none; margin: 0; padding: 0; }
.insight-list li { display: flex; align-items: flex-start; padding: 9px 0; border-bottom: 1px solid #f4f5f7; font-size: .84rem; color: #4b5563; }
.insight-list li:last-child { border-bottom: 0; }
.insight-list .sec-ic { width: 20px; text-align: center; margin-right: 8px; margin-top: 2px; flex: 0 0 auto; }

/* Reason bars */
.reason-track { display: inline-block; width: 90px; height: 7px; background: #f1f2f6; border-radius: 6px; overflow: hidden; vertical-align: middle; }
.reason-fill { display: block; height: 100%; background: #7c5cfc; border-radius: 6px; }

/* View-all footer links */
.refunds-disputes .card-footer.view-all-footer { background: transparent; border-top: 1px solid #f1f2f6; padding: .7rem 1.1rem; text-align: center; }
.refunds-disputes .view-all { font-size: .82rem; font-weight: 600; color: #7c5cfc; text-decoration: none; display: inline-flex; align-items: center; transition: color .15s ease; }
.refunds-disputes .view-all:hover { color: #5b4bb5; }
.refunds-disputes .view-all i { transition: transform .15s ease; }
.refunds-disputes .view-all:hover i { transform: translateX(3px); }

@media (max-width: 767.98px) {
    .chart-flex { justify-content: center; }
    .donut-wrap { max-width: 220px; }
    .legend-list { flex: 1 1 100%; min-width: 0; margin-top: .5rem; }
    .refunds-disputes .card-body { padding: 1rem; }
    .rd-stats .stat-value { font-size: 1.3rem; }
}
.refunds-disputes .table-responsive { -webkit-overflow-scrolling: touch; }
.refunds-disputes .table { min-width: 560px; }
@media (min-width: 992px) { .refunds-disputes .table { min-width: 0; } }

.fw-medium { font-weight: 500; }
</style>
