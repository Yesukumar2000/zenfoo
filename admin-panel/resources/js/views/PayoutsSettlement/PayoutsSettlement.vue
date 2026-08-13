<template>
    <div class="payouts-settlement">
        <div class="page-heading">
            <!-- Header -->
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3 class="mb-0">Payouts &amp; Settlement</h3>
                        <p class="text-subtitle text-muted mb-0">Manage rider payouts, merchant settlements and all disbursements.</p>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">Dashboard</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">Payouts &amp; Settlement</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <!-- Toolbar -->
            <div class="d-flex flex-wrap justify-content-end align-items-end ps-gap mb-3">
                <div>
                    <label class="small text-muted d-block mb-1">From</label>
                    <input type="date" v-model="fromDate" class="form-control form-control-sm" />
                </div>
                <div>
                    <label class="small text-muted d-block mb-1">To</label>
                    <input type="date" v-model="toDate" class="form-control form-control-sm" />
                </div>
                <button class="btn btn-sm ps-apply" @click="applyFilter"><i class="fa fa-filter me-1"></i> Apply</button>
                <a class="btn btn-sm btn-outline-secondary" :href="exportUrl" target="_blank"><i class="fa fa-download me-1"></i> Export Report</a>
            </div>

            <!-- Stat cards -->
            <div class="row g-3 ps-stats mb-1">
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
            <ul class="nav nav-tabs ps-tabs mt-2 mb-3 flex-nowrap overflow-auto">
                <li class="nav-item" v-for="t in tabs" :key="t.key">
                    <a class="nav-link" :class="{ active: activeTab === t.key }" href="javascript:void(0)" @click="switchTab(t.key)">{{ t.label }}</a>
                </li>
            </ul>

            <!-- ================= OVERVIEW ================= -->
            <div v-show="activeTab === 'overview'">
                <div class="row g-3 mb-3">
                    <!-- Payouts Trend -->
                    <div class="col-12 col-xl-6">
                        <div class="card h-100">
                            <div class="card-header d-flex align-items-center">
                                <h5 class="mb-0 me-auto">Payouts Trend</h5>
                                <select v-model="trendGroup" class="form-select form-select-sm w-auto" @change="loadOverview">
                                    <option value="daily">Daily</option>
                                    <option value="weekly">Weekly</option>
                                </select>
                            </div>
                            <div class="card-body">
                                <apexchart v-if="trendChart.series.length" type="area" height="270"
                                           :options="trendChart.options" :series="trendChart.series"></apexchart>
                                <p v-else class="text-muted text-center my-5">No data in this period</p>
                            </div>
                        </div>
                    </div>
                    <!-- Disbursement by Type -->
                    <div class="col-12 col-md-6 col-xl-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Disbursement by Type</h5></div>
                            <div class="card-body">
                                <div class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                    <div class="donut-wrap">
                                        <apexchart v-if="typeChart.series.length" type="donut" height="200"
                                                   :options="typeChart.options" :series="typeChart.series"></apexchart>
                                        <p v-else class="text-muted text-center my-5">No data</p>
                                    </div>
                                    <ul class="legend-list">
                                        <li v-for="(s,i) in disbursementByType" :key="i">
                                            <span class="dot" :style="{ background: colorAt(i) }"></span>
                                            <span class="lg-name">{{ s.name }}</span>
                                            <span class="lg-val">{{ inr(s.amount) }}</span>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- Payout Status -->
                    <div class="col-12 col-md-6 col-xl-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Payout Status</h5></div>
                            <div class="card-body">
                                <div class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                    <div class="donut-wrap">
                                        <apexchart v-if="statusChart.series.length" type="donut" height="200"
                                                   :options="statusChart.options" :series="statusChart.series"></apexchart>
                                        <p v-else class="text-muted text-center my-5">No data</p>
                                    </div>
                                    <ul class="legend-list">
                                        <li><span class="dot" style="background:#22c55e"></span><span class="lg-name">Success</span><span class="lg-val">{{ formatNum(payoutStatus.success) }}</span></li>
                                        <li><span class="dot" style="background:#ef4444"></span><span class="lg-name">Failed</span><span class="lg-val">{{ formatNum(payoutStatus.failed) }}</span></li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-3">
                    <!-- Recent Rider Payouts -->
                    <div class="col-12">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Recent Rider Payouts</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>Rider</th><th>Rider ID</th><th>Deliveries</th><th>Earnings</th><th>Payout</th><th>Method</th><th>Status</th><th>Date</th></tr></thead>
                                    <tbody>
                                        <tr v-for="r in recentRiderPayouts" :key="r.id">
                                            <td class="fw-medium">{{ r.name }}</td>
                                            <td class="small text-muted">{{ r.rider_id }}</td>
                                            <td>{{ formatNum(r.deliveries) }}</td>
                                            <td>{{ inr(r.earnings) }}</td>
                                            <td class="fw-medium">{{ inr(r.payout) }}</td>
                                            <td class="small">{{ r.method || '-' }}</td>
                                            <td><span class="badge" :class="statusClass(r.status)">{{ r.status }}</span></td>
                                            <td class="small text-muted">{{ r.date | dt }}</td>
                                        </tr>
                                        <tr v-if="!recentRiderPayouts.length"><td colspan="8" class="text-center text-muted">No rider payouts</td></tr>
                                    </tbody>
                                </table>
                            </div>
                            <div class="card-footer view-all-footer">
                                <a href="javascript:void(0)" class="view-all" @click="switchTab('riders')">View All Rider Payouts <i class="fa fa-arrow-right ms-1"></i></a>
                            </div>
                        </div>
                    </div>
                    <!-- Recent Merchant Settlements -->
                    <div class="col-12">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Recent Merchant Settlements</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>Merchant</th><th>Merchant ID</th><th>Orders</th><th>Sales</th><th>Commission</th><th>Settlement</th><th>Status</th><th>Date</th></tr></thead>
                                    <tbody>
                                        <tr v-for="m in recentMerchantSettlements" :key="m.id">
                                            <td class="fw-medium">{{ m.name }}</td>
                                            <td class="small text-muted">{{ m.merchant_id }}</td>
                                            <td>{{ formatNum(m.orders) }}</td>
                                            <td>{{ inr(m.sales) }}</td>
                                            <td>{{ inr(m.commission) }}</td>
                                            <td class="fw-medium">{{ inr(m.settlement) }}</td>
                                            <td><span class="badge" :class="statusClass(m.status)">{{ m.status }}</span></td>
                                            <td class="small text-muted">{{ m.date | dt }}</td>
                                        </tr>
                                        <tr v-if="!recentMerchantSettlements.length"><td colspan="8" class="text-center text-muted">No settlements</td></tr>
                                    </tbody>
                                </table>
                            </div>
                            <div class="card-footer view-all-footer">
                                <a href="javascript:void(0)" class="view-all" @click="switchTab('merchants')">View All Merchant Settlements <i class="fa fa-arrow-right ms-1"></i></a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-3">
                    <!-- Payout Requests -->
                    <div class="col-12 col-xl-5" v-if="payoutRequests.length || requestCounts">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Payout Requests</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>User</th><th>Name</th><th>Amount</th><th>Method</th><th>Status</th><th>Date</th></tr></thead>
                                    <tbody>
                                        <tr v-for="r in payoutRequests" :key="r.id">
                                            <td class="small">{{ r.user_type }}</td>
                                            <td class="fw-medium">{{ r.name }}</td>
                                            <td>{{ inr(r.amount) }}</td>
                                            <td class="small">{{ r.method || '-' }}</td>
                                            <td><span class="badge" :class="statusClass(r.status)">{{ r.status }}</span></td>
                                            <td class="small text-muted">{{ r.date | dt }}</td>
                                        </tr>
                                        <tr v-if="!payoutRequests.length"><td colspan="6" class="text-center text-muted">No payout requests</td></tr>
                                    </tbody>
                                </table>
                            </div>
                            <div class="card-footer view-all-footer">
                                <a href="javascript:void(0)" class="view-all" @click="switchTab('requests')">View All Payout Requests <i class="fa fa-arrow-right ms-1"></i></a>
                            </div>
                        </div>
                    </div>
                    <!-- Payout Methods Summary -->
                    <div class="col-12" :class="(payoutRequests.length || requestCounts) ? 'col-xl-4' : 'col-xl-7'" v-if="paymentMethods.length">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Payout Methods Summary</h5></div>
                            <div class="card-body table-responsive">
                                <table class="table table-sm align-middle mb-0">
                                    <thead><tr><th>Method</th><th>Txns</th><th>Amount</th><th>%</th></tr></thead>
                                    <tbody>
                                        <tr v-for="(m,i) in paymentMethods" :key="i">
                                            <td class="fw-medium">{{ m.method }}</td>
                                            <td>{{ formatNum(m.transactions) }}</td>
                                            <td>{{ inr(m.amount) }}</td>
                                            <td class="small text-muted">{{ m.pct }}%</td>
                                        </tr>
                                    </tbody>
                                    <tfoot v-if="methodTotals">
                                        <tr class="fw-medium"><td>Total</td><td>{{ formatNum(methodTotals.transactions) }}</td><td>{{ inr(methodTotals.amount) }}</td><td>100%</td></tr>
                                    </tfoot>
                                </table>
                            </div>
                        </div>
                    </div>
                    <!-- Payout Insights -->
                    <div class="col-12 col-xl-3" v-if="insights.length">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Payout Insights</h5></div>
                            <div class="card-body">
                                <ul class="insight-list mb-0">
                                    <li v-for="(t,i) in insights" :key="i"><i class="fa fa-lightbulb sec-ic text-warning"></i><span v-html="t"></span></li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ================= RIDER PAYOUTS ================= -->
            <div v-show="activeTab === 'riders'">
                <div class="card">
                    <div class="card-header d-flex flex-wrap ps-gap align-items-center">
                        <h5 class="mb-0 me-auto">Rider Payouts</h5>
                        <input v-model="riderFilters.search" type="search" class="form-control form-control-sm w-auto" placeholder="Search..." @keyup.enter="loadRiders" />
                    </div>
                    <div class="card-body table-responsive">
                        <table class="table align-middle">
                            <thead><tr><th>Rider</th><th>Rider ID</th><th>Deliveries</th><th>Earnings</th><th>Payout</th><th>Method</th><th>Status</th><th>Date</th></tr></thead>
                            <tbody>
                                <tr v-for="r in riders" :key="r.id">
                                    <td class="fw-medium">{{ r.name }}</td>
                                    <td class="small text-muted">{{ r.rider_id }}</td>
                                    <td>{{ formatNum(r.deliveries) }}</td>
                                    <td>{{ inr(r.earnings) }}</td>
                                    <td class="fw-medium">{{ inr(r.payout) }}</td>
                                    <td class="small">{{ r.method || '-' }}</td>
                                    <td><span class="badge" :class="statusClass(r.status)">{{ r.status }}</span></td>
                                    <td class="small text-muted">{{ r.date | dt }}</td>
                                </tr>
                                <tr v-if="!riders.length"><td colspan="8" class="text-center text-muted">No rider payouts found</td></tr>
                            </tbody>
                        </table>
                        <div v-if="riderMeta.last_page > 1" class="d-flex justify-content-end align-items-center ps-gap pt-2">
                            <button class="btn btn-sm btn-outline-secondary" :disabled="riderMeta.current_page <= 1" @click="pageRiders(riderMeta.current_page - 1)">Prev</button>
                            <span class="small text-muted">Page {{ riderMeta.current_page }} / {{ riderMeta.last_page }}</span>
                            <button class="btn btn-sm btn-outline-secondary" :disabled="riderMeta.current_page >= riderMeta.last_page" @click="pageRiders(riderMeta.current_page + 1)">Next</button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ================= MERCHANT SETTLEMENTS ================= -->
            <div v-show="activeTab === 'merchants'">
                <div class="card">
                    <div class="card-header d-flex flex-wrap ps-gap align-items-center">
                        <h5 class="mb-0 me-auto">Merchant Settlements</h5>
                        <input v-model="merchantFilters.search" type="search" class="form-control form-control-sm w-auto" placeholder="Search..." @keyup.enter="loadMerchants" />
                    </div>
                    <div class="card-body table-responsive">
                        <table class="table align-middle">
                            <thead><tr><th>Merchant</th><th>Merchant ID</th><th>Orders</th><th>Sales</th><th>Commission</th><th>Settlement</th><th>Status</th><th>Date</th></tr></thead>
                            <tbody>
                                <tr v-for="m in merchants" :key="m.id">
                                    <td class="fw-medium">{{ m.name }}</td>
                                    <td class="small text-muted">{{ m.merchant_id }}</td>
                                    <td>{{ formatNum(m.orders) }}</td>
                                    <td>{{ inr(m.sales) }}</td>
                                    <td>{{ inr(m.commission) }}</td>
                                    <td class="fw-medium">{{ inr(m.settlement) }}</td>
                                    <td><span class="badge" :class="statusClass(m.status)">{{ m.status }}</span></td>
                                    <td class="small text-muted">{{ m.date | dt }}</td>
                                </tr>
                                <tr v-if="!merchants.length"><td colspan="8" class="text-center text-muted">No settlements found</td></tr>
                            </tbody>
                        </table>
                        <div v-if="merchantMeta.last_page > 1" class="d-flex justify-content-end align-items-center ps-gap pt-2">
                            <button class="btn btn-sm btn-outline-secondary" :disabled="merchantMeta.current_page <= 1" @click="pageMerchants(merchantMeta.current_page - 1)">Prev</button>
                            <span class="small text-muted">Page {{ merchantMeta.current_page }} / {{ merchantMeta.last_page }}</span>
                            <button class="btn btn-sm btn-outline-secondary" :disabled="merchantMeta.current_page >= merchantMeta.last_page" @click="pageMerchants(merchantMeta.current_page + 1)">Next</button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- ================= PAYOUT REQUESTS ================= -->
            <div v-show="activeTab === 'requests'">
                <div class="card">
                    <div class="card-header d-flex flex-wrap ps-gap align-items-center">
                        <h5 class="mb-0 me-auto">Payout Requests</h5>
                        <select v-model="requestFilters.status" class="form-select form-select-sm w-auto" @change="loadRequests">
                            <option value="">All Status</option>
                            <option v-for="s in requestStatuses" :key="s" :value="s">{{ s }}</option>
                        </select>
                    </div>
                    <div class="card-body table-responsive">
                        <table class="table align-middle">
                            <thead><tr><th>User Type</th><th>Name</th><th>Amount</th><th>Request Date</th><th>Method</th><th>Status</th></tr></thead>
                            <tbody>
                                <tr v-for="r in requests" :key="r.id">
                                    <td class="small">{{ r.user_type }}</td>
                                    <td class="fw-medium">{{ r.name }}</td>
                                    <td>{{ inr(r.amount) }}</td>
                                    <td class="small text-muted">{{ r.date | dt }}</td>
                                    <td class="small">{{ r.method || '-' }}</td>
                                    <td><span class="badge" :class="statusClass(r.status)">{{ r.status }}</span></td>
                                </tr>
                                <tr v-if="!requests.length"><td colspan="6" class="text-center text-muted">No payout requests found</td></tr>
                            </tbody>
                        </table>
                        <div v-if="requestMeta.last_page > 1" class="d-flex justify-content-end align-items-center ps-gap pt-2">
                            <button class="btn btn-sm btn-outline-secondary" :disabled="requestMeta.current_page <= 1" @click="pageRequests(requestMeta.current_page - 1)">Prev</button>
                            <span class="small text-muted">Page {{ requestMeta.current_page }} / {{ requestMeta.last_page }}</span>
                            <button class="btn btn-sm btn-outline-secondary" :disabled="requestMeta.current_page >= requestMeta.last_page" @click="pageRequests(requestMeta.current_page + 1)">Next</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    name: 'PayoutsSettlement',
    filters: {
        dt(v) {
            if (!v) return '-';
            const d = new Date(v);
            return isNaN(d) ? v : d.toLocaleDateString();
        },
    },
    data() {
        return {
            activeTab: 'overview',
            loadedTabs: {},
            fromDate: '',
            toDate: '',
            trendGroup: 'daily',
            palette: ['#22c55e', '#3b82f6', '#7c5cfc', '#f59e0b', '#ef4444', '#14b8a6', '#a855f7', '#0ea5e9'],
            tabs: [
                { key: 'overview', label: 'Overview' },
                { key: 'riders', label: 'Rider Payouts' },
                { key: 'merchants', label: 'Merchant Settlements' },
                { key: 'requests', label: 'Payout Requests' },
            ],
            statCards: [
                { key: 'total_disbursed', label: 'Total Amount Disbursed', icon: 'fa-money-check-alt', bg: '#e7f8ef', color: '#22c55e', sub: 'in selected period', money: true },
                { key: 'rider_payouts', label: 'Rider Payouts', icon: 'fa-motorcycle', bg: '#efeaff', color: '#7c5cfc', sub: 'paid to riders', money: true },
                { key: 'merchant_settlements', label: 'Merchant Settlements', icon: 'fa-store', bg: '#fff4e5', color: '#f59e0b', sub: 'settled to sellers', money: true },
                { key: 'pending_amount', label: 'Pending Amount', icon: 'fa-clock', bg: '#e8f1ff', color: '#3b82f6', sub: 'awaiting payout', money: true },
                { key: 'successful_txn', label: 'Successful Transactions', icon: 'fa-check-circle', bg: '#e7f8ef', color: '#22c55e', sub: 'completed' },
                { key: 'failed_txn', label: 'Failed Transactions', icon: 'fa-times-circle', bg: '#fdeaea', color: '#ef4444', sub: 'failed' },
            ],
            stats: { total_disbursed: 0, rider_payouts: 0, merchant_settlements: 0, pending_amount: 0, successful_txn: 0, failed_txn: 0 },

            trendChart: { options: {}, series: [] },
            typeChart: { options: {}, series: [] },
            statusChart: { options: {}, series: [] },

            disbursementByType: [],
            payoutStatus: { success: 0, failed: 0 },
            recentRiderPayouts: [],
            recentMerchantSettlements: [],
            payoutRequests: [],
            requestCounts: null,
            paymentMethods: [],
            methodTotals: null,
            insights: [],

            riders: [],
            riderFilters: { search: '' },
            riderMeta: { current_page: 1, last_page: 1 },

            merchants: [],
            merchantFilters: { search: '' },
            merchantMeta: { current_page: 1, last_page: 1 },

            requests: [],
            requestFilters: { status: '' },
            requestMeta: { current_page: 1, last_page: 1 },
            requestStatuses: ['Pending', 'Approved', 'Rejected'],
        };
    },
    computed: {
        exportUrl() {
            let u = this.$apiUrl + '/payout-settlement-analytics/export';
            const p = [];
            if (this.fromDate) p.push('from_date=' + this.fromDate);
            if (this.toDate) p.push('to_date=' + this.toDate);
            return p.length ? u + '?' + p.join('&') : u;
        },
    },
    created() {
        this.loadOverview();
    },
    methods: {
        colorAt(i) { return this.palette[i % this.palette.length]; },
        formatNum(n) { return (n === null || n === undefined) ? '—' : Number(n).toLocaleString('en-IN'); },
        inr(n) { return (n === null || n === undefined) ? '—' : '₹' + Number(n).toLocaleString('en-IN', { maximumFractionDigits: 2 }); },
        shortInr(v) {
            v = Number(v) || 0;
            if (v >= 10000000) return '₹' + (v / 10000000).toFixed(1) + 'Cr';
            if (v >= 100000) return '₹' + (v / 100000).toFixed(1) + 'L';
            if (v >= 1000) return '₹' + (v / 1000).toFixed(1) + 'K';
            return '₹' + v;
        },
        statusClass(s) {
            const v = (s || '').toLowerCase();
            if (v.indexOf('success') >= 0 || v.indexOf('approv') >= 0 || v.indexOf('paid') >= 0 || v.indexOf('complet') >= 0) return 'bg-success';
            if (v.indexOf('pending') >= 0 || v.indexOf('review') >= 0) return 'bg-warning';
            if (v.indexOf('fail') >= 0 || v.indexOf('reject') >= 0) return 'bg-danger';
            return 'bg-light text-dark';
        },
        dateParams() {
            const p = {};
            if (this.fromDate) p.from_date = this.fromDate;
            if (this.toDate) p.to_date = this.toDate;
            return p;
        },
        switchTab(key) {
            this.activeTab = key;
            if (this.loadedTabs[key]) return;
            this.loadedTabs[key] = true;
            const map = { riders: this.loadRiders, merchants: this.loadMerchants, requests: this.loadRequests };
            if (map[key]) map[key]();
        },
        applyFilter() {
            this.loadOverview();
            if (this.activeTab === 'riders') this.loadRiders();
            else if (this.activeTab === 'merchants') this.loadMerchants();
            else if (this.activeTab === 'requests') this.loadRequests();
        },
        loadOverview() {
            const params = Object.assign({ group: this.trendGroup }, this.dateParams());
            axios.get(this.$apiUrl + '/payout-settlement-analytics/overview', { params }).then(res => {
                const d = res.data.data;
                this.stats = d.stats;
                this.disbursementByType = d.disbursement_by_type || [];
                this.payoutStatus = d.payout_status || { success: 0, failed: 0 };
                this.recentRiderPayouts = d.recent_rider_payouts || [];
                this.recentMerchantSettlements = d.recent_merchant_settlements || [];
                this.payoutRequests = d.payout_requests || [];
                this.requestCounts = d.request_counts || null;
                this.paymentMethods = d.payment_methods || [];
                this.methodTotals = d.method_totals || null;
                this.insights = d.insights || [];
                if (d.request_statuses) this.requestStatuses = d.request_statuses;
                this.buildCharts(d);
            }).catch(e => this.showMessage && this.showMessage('error', this.errMsg(e)));
        },
        buildCharts(d) {
            const t = d.payout_trend || { labels: [], rider: [], merchant: [] };
            this.trendChart = {
                series: [
                    { name: 'Rider Payouts', data: t.rider },
                    { name: 'Merchant Settlements', data: t.merchant },
                ],
                options: {
                    chart: { toolbar: { show: false } },
                    stroke: { curve: 'smooth', width: 2 },
                    colors: ['#22c55e', '#3b82f6'],
                    fill: { type: 'gradient', gradient: { opacityFrom: 0.25, opacityTo: 0.03 } },
                    dataLabels: { enabled: false },
                    xaxis: { categories: t.labels, tickAmount: 8, labels: { rotate: 0, style: { fontSize: '10px' } } },
                    yaxis: { labels: { formatter: (v) => this.shortInr(v) } },
                    legend: { position: 'top' },
                    grid: { borderColor: '#f0f0f0' },
                },
            };

            const donutBase = (label, fmt) => ({
                labels: [], legend: { show: false }, dataLabels: { enabled: false }, stroke: { width: 2 },
                plotOptions: { pie: { donut: { size: '70%', labels: { show: true, name: { show: true }, value: { show: true, fontSize: '17px', fontWeight: 700 }, total: { show: true, label: label, fontSize: '11px', color: '#888', formatter: fmt } } } } },
            });

            if (this.disbursementByType.length) {
                const to = donutBase('Total Disbursed', (w) => this.shortInr(w.globals.seriesTotals.reduce((a, b) => a + b, 0)));
                to.labels = this.disbursementByType.map(s => s.name);
                to.colors = this.disbursementByType.map((s, i) => this.colorAt(i));
                this.typeChart = { series: this.disbursementByType.map(s => s.amount), options: to };
            } else { this.typeChart = { series: [], options: {} }; }

            const s = this.payoutStatus || { success: 0, failed: 0 };
            if (s.success || s.failed) {
                const so = donutBase('Total Txns', (w) => this.formatNum(w.globals.seriesTotals.reduce((a, b) => a + b, 0)));
                so.labels = ['Success', 'Failed'];
                so.colors = ['#22c55e', '#ef4444'];
                this.statusChart = { series: [s.success, s.failed], options: so };
            } else { this.statusChart = { series: [], options: {} }; }
        },
        loadRiders() { this.fetchRiders(Object.assign({ search: this.riderFilters.search, page: 1 }, this.dateParams())); },
        pageRiders(page) { this.fetchRiders(Object.assign({ search: this.riderFilters.search, page }, this.dateParams())); },
        fetchRiders(params) {
            axios.get(this.$apiUrl + '/payout-settlement-analytics/rider-payouts', { params }).then(res => {
                const p = res.data.data;
                this.riders = p.data || [];
                this.riderMeta = { current_page: p.current_page, last_page: p.last_page };
            }).catch(e => this.showMessage && this.showMessage('error', this.errMsg(e)));
        },
        loadMerchants() { this.fetchMerchants(Object.assign({ search: this.merchantFilters.search, page: 1 }, this.dateParams())); },
        pageMerchants(page) { this.fetchMerchants(Object.assign({ search: this.merchantFilters.search, page }, this.dateParams())); },
        fetchMerchants(params) {
            axios.get(this.$apiUrl + '/payout-settlement-analytics/merchant-settlements', { params }).then(res => {
                const p = res.data.data;
                this.merchants = p.data || [];
                this.merchantMeta = { current_page: p.current_page, last_page: p.last_page };
            }).catch(e => this.showMessage && this.showMessage('error', this.errMsg(e)));
        },
        loadRequests() { this.fetchRequests(Object.assign({ status: this.requestFilters.status, page: 1 }, this.dateParams())); },
        pageRequests(page) { this.fetchRequests(Object.assign({ status: this.requestFilters.status, page }, this.dateParams())); },
        fetchRequests(params) {
            axios.get(this.$apiUrl + '/payout-settlement-analytics/payout-requests', { params }).then(res => {
                const p = res.data.data;
                this.requests = p.data || [];
                this.requestMeta = { current_page: p.current_page, last_page: p.last_page };
            }).catch(e => this.showMessage && this.showMessage('error', this.errMsg(e)));
        },
        errMsg(e) { return (e && e.response && e.response.data && e.response.data.message) || 'Something went wrong'; },
    },
};
</script>

<style scoped>
.payouts-settlement .ps-gap { gap: .5rem; }

/* Prominent Apply button */
.payouts-settlement .ps-apply { background: #22c55e; border: 1px solid #22c55e; color: #fff; font-weight: 600; padding: .28rem .95rem; box-shadow: 0 2px 6px rgba(34,197,94,.28); transition: background .15s ease, box-shadow .15s ease; }
.payouts-settlement .ps-apply:hover, .payouts-settlement .ps-apply:focus { background: #16a34a; border-color: #16a34a; color: #fff; box-shadow: 0 4px 12px rgba(34,197,94,.4); }

/* Stat cards */
.ps-stats { margin-bottom: .25rem; }
.ps-stats .stat-card { height: 100%; border: 1px solid #eef0f4; border-radius: 14px; box-shadow: 0 1px 2px rgba(16,24,40,.04); transition: box-shadow .15s ease, transform .15s ease; }
.ps-stats .stat-card:hover { transform: translateY(-2px); }
.ps-stats .stat-card .card-body { position: relative; padding: 16px 16px 14px; }
.ps-stats .stat-icon { position: absolute; top: 20px; right: 14px; width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 15px; }
.ps-stats .stat-label { font-size: .78rem; color: #6b7280; font-weight: 500; line-height: 1.25; padding-right: 46px; min-height: 2.4em; display: flex; align-items: center; }
.ps-stats .stat-value { font-size: 1.5rem; font-weight: 700; line-height: 1; margin: 2px 0 5px; color: #111827; }
.ps-stats .stat-sub { font-size: .72rem; font-weight: 500; }

/* Tabs */
.ps-tabs { border-bottom: 1px solid #eef0f4; -ms-overflow-style: none; scrollbar-width: none; }
.ps-tabs::-webkit-scrollbar { display: none; height: 0; }
.ps-tabs .nav-link { cursor: pointer; white-space: nowrap; color: #6b7280; border: 0; border-bottom: 2px solid transparent; padding: .6rem 1rem; }
.ps-tabs .nav-link:hover { color: #22c55e; }
.ps-tabs .nav-link.active { font-weight: 600; color: #16a34a; background: transparent; border-bottom: 2px solid #22c55e; }

/* Cards */
.payouts-settlement .card { border: 1px solid #eef0f4; border-radius: 14px; box-shadow: 0 1px 2px rgba(16,24,40,.03); margin-bottom: 0; transition: box-shadow .15s ease; }
.payouts-settlement .card:hover { box-shadow: 0 4px 14px rgba(16,24,40,.06); }
.payouts-settlement .card-body { padding: 1.15rem 1.25rem; }
.payouts-settlement .card-header { background: transparent; border-bottom: 1px solid #f1f2f6; padding: .9rem 1.1rem; }
.payouts-settlement .card-header h5 { font-size: 1rem; font-weight: 600; color: #111827; }

/* Tables */
.payouts-settlement .table { margin-bottom: 0; }
.payouts-settlement .table thead th { text-transform: uppercase; font-size: .68rem; letter-spacing: .4px; color: #9ca3af; font-weight: 600; border-bottom: 1px solid #eef0f4; border-top: 0; padding: .55rem .6rem; white-space: nowrap; }
.payouts-settlement .table tbody td { border-top: 1px solid #f4f5f7; padding: .6rem .6rem; color: #374151; vertical-align: middle; }
.payouts-settlement .table tfoot td { border-top: 2px solid #eef0f4; padding: .55rem .6rem; color: #111827; }
.payouts-settlement .table tbody tr:hover { background: #f9fdfb; }
.payouts-settlement .table .fw-medium { font-weight: 600; color: #111827; }

/* Badges */
.payouts-settlement .badge { font-weight: 500; padding: .38em .62em; border-radius: 6px; }
.payouts-settlement .badge.bg-light { background: #f3f4f6 !important; }

/* Filters */
.payouts-settlement .form-control-sm, .payouts-settlement .form-select-sm { border-radius: 8px; border-color: #e5e7eb; }

/* Donut + legend */
.chart-flex { gap: .5rem 1rem; }
.donut-wrap { flex: 1 1 150px; max-width: 200px; min-width: 130px; }
.legend-list { list-style: none; margin: 0; padding: 0; flex: 1 1 130px; min-width: 120px; }
.legend-list li { display: flex; align-items: center; padding: 5px 0; font-size: .8rem; }
.legend-list .dot { width: 10px; height: 10px; border-radius: 50%; margin-right: 8px; flex: 0 0 auto; }
.legend-list .lg-name { flex: 1 1 auto; color: #374151; }
.legend-list .lg-val { font-weight: 600; color: #111827; }

/* Insights */
.insight-list { list-style: none; margin: 0; padding: 0; }
.insight-list li { display: flex; align-items: flex-start; padding: 9px 0; border-bottom: 1px solid #f4f5f7; font-size: .84rem; color: #4b5563; }
.insight-list li:last-child { border-bottom: 0; }
.insight-list .sec-ic { width: 20px; text-align: center; margin-right: 8px; margin-top: 2px; flex: 0 0 auto; }

/* View-all footer links */
.payouts-settlement .card-footer.view-all-footer { background: transparent; border-top: 1px solid #f1f2f6; padding: .7rem 1.1rem; text-align: center; }
.payouts-settlement .view-all { font-size: .82rem; font-weight: 600; color: #16a34a; text-decoration: none; display: inline-flex; align-items: center; transition: color .15s ease; }
.payouts-settlement .view-all:hover { color: #128a3e; }
.payouts-settlement .view-all i { transition: transform .15s ease; }
.payouts-settlement .view-all:hover i { transform: translateX(3px); }

@media (max-width: 767.98px) {
    .chart-flex { justify-content: center; }
    .donut-wrap { max-width: 220px; }
    .legend-list { flex: 1 1 100%; min-width: 0; margin-top: .5rem; }
    .payouts-settlement .card-body { padding: 1rem; }
    .ps-stats .stat-value { font-size: 1.3rem; }
}
.payouts-settlement .table-responsive { -webkit-overflow-scrolling: touch; }
.payouts-settlement .table { min-width: 640px; }
@media (min-width: 992px) { .payouts-settlement .table { min-width: 0; } }

.fw-medium { font-weight: 500; }
</style>
