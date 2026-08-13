<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3 class="mb-1">Merchant Analytics</h3>
                    <p class="text-muted mb-0 small">Track and analyze merchant performance, revenue, commissions and payouts</p>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">Dashboard</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                Merchant Analytics
                            </li>
                        </ol>
                    </nav>
                </div>
            </div>
            <div class="d-flex justify-content-end align-items-center flex-wrap mt-3">
                <div class="d-flex align-items-center gap-2 flex-wrap">
                    <!-- Filter Buttons -->
                    <div class="btn-group mr-2">
                        <button
                            v-for="f in filterOptions"
                            :key="f.value"
                            class="btn btn-sm"
                            :class="filter === f.value ? 'btn-success' : 'btn-outline-secondary'"
                            @click="setFilter(f.value)"
                        >
                            {{ f.label }}
                        </button>
                    </div>
                    <!-- Zone Filter -->
                    <select class="form-control form-control-sm mr-2" v-model="city_id" @change="fetchAnalytics()" style="width:auto; min-width:120px;">
                        <option value="">All Zones</option>
                        <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
                    </select>
                    <!-- Date Range Picker for Custom -->
                    <div v-if="filter === 'custom'" class="d-flex align-items-center">
                        <input type="date" class="form-control form-control-sm mr-1" v-model="customStart" />
                        <span class="mx-1">to</span>
                        <input type="date" class="form-control form-control-sm ml-1" v-model="customEnd" />
                        <button class="btn btn-sm btn-success ml-2" @click="fetchAnalytics">Apply</button>
                    </div>
                    <!-- Export Report -->
                    <b-dropdown v-if="analyticsData" size="sm" variant="outline-success" right>
                        <template #button-content>
                            <i class="fa fa-download mr-1"></i> Export Report
                        </template>
                        <b-dropdown-header>Excel Download</b-dropdown-header>
                        <b-dropdown-item @click="downloadExcel('all')">All Data</b-dropdown-item>
                        <b-dropdown-item @click="downloadExcel('summary')">Summary &amp; Trend</b-dropdown-item>
                        <b-dropdown-item @click="downloadExcel('merchants')">Top Merchants</b-dropdown-item>
                        <b-dropdown-item @click="downloadExcel('payouts')">Commission &amp; Payouts</b-dropdown-item>
                        <b-dropdown-item @click="downloadExcel('registrations')">Registrations</b-dropdown-item>
                        <b-dropdown-divider></b-dropdown-divider>
                        <b-dropdown-header>PDF Download</b-dropdown-header>
                        <b-dropdown-item @click="downloadPdf('all')">Full Report</b-dropdown-item>
                        <b-dropdown-item @click="downloadPdf('summary')">Summary Report</b-dropdown-item>
                        <b-dropdown-item @click="downloadPdf('merchants')">Top Merchants</b-dropdown-item>
                        <b-dropdown-item @click="downloadPdf('payouts')">Commission &amp; Payouts</b-dropdown-item>
                    </b-dropdown>
                </div>
            </div>

            <!-- Selected period vs comparison period -->
            <div v-if="analyticsData" class="d-flex align-items-center flex-wrap gap-2 mt-3">
                <span class="period-chip">
                    <span class="text-muted small d-block">Current</span>
                    <strong>{{ analyticsData.current_period }}</strong>
                </span>
                <span class="period-chip period-chip-compare">
                    <span class="text-muted small d-block">Compare</span>
                    <strong>{{ analyticsData.previous_period }}</strong>
                </span>
            </div>
        </div>

        <div class="page-content">
            <div v-if="loading" class="text-center py-5">
                <b-spinner variant="success" label="Loading..."></b-spinner>
                <p class="mt-2">Loading analytics...</p>
            </div>

            <template v-else-if="analyticsData">
                <!-- Row 1: Summary Cards -->
                <div class="row ma-stats">
                    <div class="col-6 col-md-4 col-xl-2" v-for="card in summaryCards" :key="card.label">
                        <div class="card stat-card">
                            <div class="card-body">
                                <span class="stat-icon" :style="{ background: card.bg, color: card.color }"><i :class="'fa ' + card.icon"></i></span>
                                <div class="stat-label">{{ card.label }}</div>
                                <!-- Money is abbreviated (K/L/Cr) so a crore-scale
                                     figure still fits the tile; the exact amount is
                                     on hover and in the tables below. -->
                                <div class="stat-value" :title="statTitle(card)">{{ statDisplay(card) }}</div>
                                <span
                                    v-if="cardTrend(card)"
                                    class="stat-sub"
                                    :class="cardTrend(card).is_positive ? 'text-success' : 'text-danger'"
                                >
                                    <i :class="cardTrend(card).is_positive ? 'fa fa-arrow-up' : 'fa fa-arrow-down'"></i>
                                    {{ cardTrend(card).abs_percent }}%
                                    <span class="text-muted">vs prev</span>
                                </span>
                                <!-- Pending payouts is a running balance, not a period
                                     metric, so it carries a scope note instead of a
                                     comparison arrow. -->
                                <span v-else-if="card.note" class="stat-sub text-muted">{{ card.note }}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 2: Performance Trend -->
                <div class="row mb-4">
                    <div class="col-12 mb-3">
                        <div class="card h-100">
                            <div class="card-header d-flex justify-content-between align-items-center flex-wrap">
                                <h5 class="mb-0">Merchant Performance Trend</h5>
                                <span class="text-muted small">{{ analyticsData.current_period }}</span>
                            </div>
                            <div class="card-body">
                                <apexchart
                                    v-if="performanceTrend.labels.length > 0"
                                    type="line"
                                    height="320"
                                    :options="performanceTrendOptions"
                                    :series="performanceTrendSeries"
                                ></apexchart>
                                <p v-else class="text-muted text-center mt-5">No data for this period</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 3: Top Merchants | Commission by Type -->
                <div class="row mb-4">
                    <div class="col-12 col-xl-7 mb-3">
                        <div class="card h-100">
                            <div class="card-header d-flex justify-content-between align-items-center">
                                <h5 class="mb-0">Top Merchants by Revenue</h5>
                                <router-link to="/sellers" class="small">View All</router-link>
                            </div>
                            <div class="card-body">
                                <div class="table-responsive" v-if="topMerchants.length > 0">
                                    <table class="table table-sm mb-0">
                                        <thead>
                                            <tr>
                                                <th>Merchant</th>
                                                <th>Type</th>
                                                <th class="text-right">Revenue (₹)</th>
                                                <th class="text-right">Orders</th>
                                                <th class="text-right">Commission (₹)</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="m in topMerchants" :key="m.seller_id">
                                                <td>
                                                    <router-link :to="'/sellers/view/' + m.seller_id">{{ m.name }}</router-link>
                                                </td>
                                                <td><span class="badge" :class="typeBadgeClass(m.type)">{{ m.type }}</span></td>
                                                <td class="text-right">{{ formatNumber(m.revenue) }}</td>
                                                <td class="text-right">{{ formatNumber(m.orders) }}</td>
                                                <td class="text-right">{{ formatNumber(m.commission) }}</td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                                <p v-else class="text-muted text-center mt-5">No data for this period</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-xl-5 mb-3">
                        <div class="card h-100">
                            <div class="card-header">
                                <h5 class="mb-0">Commission by Type</h5>
                            </div>
                            <div class="card-body">
                                <div v-if="commissionByType.total > 0" class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                    <div class="donut-wrap">
                                        <apexchart type="donut" height="200" :options="commissionByTypeOptions" :series="commissionByTypeSeries"></apexchart>
                                    </div>
                                    <ul class="legend-list">
                                        <li v-for="(l,i) in donutLegend(commissionByType, true)" :key="i">
                                            <span class="dot" :style="{ background: l.color }"></span>
                                            <span class="lg-name">{{ l.name }}</span>
                                            <span class="lg-val">{{ l.display }} <small>({{ l.percentage }}%)</small></span>
                                        </li>
                                    </ul>
                                </div>
                                <p v-else class="text-muted text-center mt-5">No commission recorded for this period</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 4: Status | Revenue by Type | Top Categories -->
                <div class="row mb-4">
                    <div class="col-12 col-md-6 col-xl-4 mb-3">
                        <div class="card h-100">
                            <div class="card-header">
                                <h5 class="mb-0">Merchants by Status</h5>
                            </div>
                            <div class="card-body">
                                <div v-if="merchantsByStatus.total > 0" class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                    <div class="donut-wrap">
                                        <apexchart type="donut" height="200" :options="merchantsByStatusOptions" :series="merchantsByStatusSeries"></apexchart>
                                    </div>
                                    <ul class="legend-list">
                                        <li v-for="(l,i) in donutLegend(merchantsByStatus, false, ['#9AC444','#546E7A','#FEB019','#FF4560'])" :key="i">
                                            <span class="dot" :style="{ background: l.color }"></span>
                                            <span class="lg-name">{{ l.name }}</span>
                                            <span class="lg-val">{{ l.display }} <small>({{ l.percentage }}%)</small></span>
                                        </li>
                                    </ul>
                                </div>
                                <p v-else class="text-muted text-center mt-5">No merchants found</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-md-6 col-xl-4 mb-3">
                        <div class="card h-100">
                            <div class="card-header">
                                <h5 class="mb-0">Revenue by Merchant Type</h5>
                            </div>
                            <div class="card-body">
                                <div v-if="revenueByType.total > 0" class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                    <div class="donut-wrap">
                                        <apexchart type="donut" height="200" :options="revenueByTypeOptions" :series="revenueByTypeSeries"></apexchart>
                                    </div>
                                    <ul class="legend-list">
                                        <li v-for="(l,i) in donutLegend(revenueByType, true)" :key="i">
                                            <span class="dot" :style="{ background: l.color }"></span>
                                            <span class="lg-name">{{ l.name }}</span>
                                            <span class="lg-val">{{ l.display }} <small>({{ l.percentage }}%)</small></span>
                                        </li>
                                    </ul>
                                </div>
                                <p v-else class="text-muted text-center mt-5">No data for this period</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-md-12 col-xl-4 mb-3">
                        <div class="card h-100">
                            <div class="card-header d-flex justify-content-between align-items-center">
                                <h5 class="mb-0">Top Categories by Sales</h5>
                                <router-link to="/categories" class="small">View All</router-link>
                            </div>
                            <div class="card-body">
                                <div v-if="topCategories.length > 0">
                                    <div
                                        v-for="c in topCategories"
                                        :key="c.name"
                                        class="d-flex align-items-center justify-content-between mb-3"
                                    >
                                        <span class="small category-label" :title="c.name">{{ c.name }}</span>
                                        <div class="d-flex align-items-center flex-grow-1 ml-2">
                                            <div class="category-bar-track flex-grow-1">
                                                <div
                                                    class="category-bar-fill"
                                                    :style="{ width: categoryBarWidth(c.revenue) + '%' }"
                                                ></div>
                                            </div>
                                            <span class="small ml-2 text-nowrap">{{ formatNumber(c.revenue) }}</span>
                                        </div>
                                    </div>
                                </div>
                                <p v-else class="text-muted text-center mt-5">No data for this period</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 5: Payout Summary | Recent Registrations | Insights -->
                <div class="row mb-4">
                    <!-- Six money columns, so this stays full width until xl
                         rather than being squeezed into a scrolling stub. -->
                    <div class="col-12 col-xl-5 mb-3">
                        <div class="card h-100">
                            <div class="card-header">
                                <h5 class="mb-0">Merchant Commission &amp; Payout Summary</h5>
                            </div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-sm mb-0">
                                        <thead>
                                            <tr>
                                                <th>Type</th>
                                                <th class="text-right">Merchants</th>
                                                <th class="text-right">Revenue (₹)</th>
                                                <th class="text-right">Commission (₹)</th>
                                                <th class="text-right">Paid (₹)</th>
                                                <th class="text-right">Pending (₹)</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="row in payoutSummary.rows" :key="row.type">
                                                <td>{{ row.type }}</td>
                                                <td class="text-right">{{ formatNumber(row.merchants) }}</td>
                                                <td class="text-right">{{ formatNumber(row.revenue) }}</td>
                                                <td class="text-right">{{ formatNumber(row.commission) }}</td>
                                                <td class="text-right">{{ formatNumber(row.paid) }}</td>
                                                <td class="text-right">{{ formatNumber(row.pending) }}</td>
                                            </tr>
                                        </tbody>
                                        <tfoot v-if="payoutSummary.total">
                                            <tr class="font-weight-bold">
                                                <td>{{ payoutSummary.total.type }}</td>
                                                <td class="text-right">{{ formatNumber(payoutSummary.total.merchants) }}</td>
                                                <td class="text-right">{{ formatNumber(payoutSummary.total.revenue) }}</td>
                                                <td class="text-right">{{ formatNumber(payoutSummary.total.commission) }}</td>
                                                <td class="text-right">{{ formatNumber(payoutSummary.total.paid) }}</td>
                                                <td class="text-right">{{ formatNumber(payoutSummary.total.pending) }}</td>
                                            </tr>
                                        </tfoot>
                                    </table>
                                </div>
                                <p class="text-muted small mb-0 mt-2">
                                    Revenue and commission are for the selected period. Paid and pending are running balances across all time.
                                </p>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-md-6 col-xl-4 mb-3">
                        <div class="card h-100">
                            <div class="card-header d-flex justify-content-between align-items-center">
                                <h5 class="mb-0">Recent Merchant Registrations</h5>
                                <router-link to="/registered_sellers" class="small">View All</router-link>
                            </div>
                            <div class="card-body">
                                <div class="table-responsive" v-if="recentRegistrations.length > 0">
                                    <table class="table table-sm mb-0">
                                        <thead>
                                            <tr>
                                                <th>Merchant</th>
                                                <th>Type</th>
                                                <th>Registered</th>
                                                <th>Status</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="r in recentRegistrations" :key="r.seller_id">
                                                <td>
                                                    <router-link :to="'/sellers/view/' + r.seller_id">{{ r.name }}</router-link>
                                                </td>
                                                <td class="small">{{ r.type }}</td>
                                                <td class="small">{{ r.registered_on }}</td>
                                                <td><span class="badge" :class="statusBadgeClass(r.status)">{{ r.status }}</span></td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                                <p v-else class="text-muted text-center mt-5">No registrations found</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-md-6 col-xl-3 mb-3">
                        <div class="card h-100">
                            <div class="card-header">
                                <h5 class="mb-0">Merchant Insights</h5>
                            </div>
                            <div class="card-body">
                                <div
                                    v-for="(insight, index) in insights"
                                    :key="index"
                                    class="d-flex align-items-start mb-3"
                                >
                                    <span class="insight-icon mr-2" :class="'insight-' + insight.type">
                                        <i class="fa" :class="insightIcon(insight.icon)"></i>
                                    </span>
                                    <span class="small">{{ insight.text }}</span>
                                </div>
                                <p v-if="insights.length === 0" class="text-muted text-center mt-5">No insights available</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- How these numbers are calculated -->
                <div class="row mb-4" v-if="notes.length > 0">
                    <div class="col-12">
                        <div class="card">
                            <div class="card-body py-3">
                                <h6 class="mb-2"><i class="fa fa-info-circle text-muted mr-1"></i> How these numbers are calculated</h6>
                                <ul class="mb-0 small text-muted pl-3">
                                    <li v-for="(note, index) in notes" :key="index">{{ note }}</li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            </template>

            <div v-else class="text-center py-5">
                <p class="text-muted">No analytics data available.</p>
            </div>
        </div>
    </div>
</template>

<script>
import VueApexCharts from 'vue-apexcharts';

export default {
    name: 'MerchantAnalytics',
    components: {
        apexchart: VueApexCharts,
    },
    data() {
        return {
            loading: false,
            filter: 'monthly',
            customStart: '',
            customEnd: '',
            city_id: '',
            cities: [],
            analyticsData: null,
            filterOptions: [
                { label: 'Today', value: 'daily' },
                { label: 'This Week', value: 'weekly' },
                { label: 'This Month', value: 'monthly' },
                { label: 'Custom', value: 'custom' },
            ],
            chartColors: ['#9AC444', '#008FFB', '#FEB019', '#FF4560', '#775DD0', '#00E396', '#F86624', '#546E7A'],
            // Fixed colour per merchant type so the three type charts stay
            // readable against each other.
            typeColors: {
                Restaurant: '#9AC444',
                Grocery: '#008FFB',
                'Combo (Both)': '#FEB019',
                Others: '#775DD0',
            },
        };
    },
    created() {
        this.getCities();
        this.fetchAnalytics();
    },
    computed: {
        summary() {
            return this.analyticsData?.summary || {};
        },
        performanceTrend() {
            return this.analyticsData?.performance_trend || { labels: [], revenue: [], commission: [] };
        },
        topMerchants() {
            return this.analyticsData?.top_merchants || [];
        },
        commissionByType() {
            return this.analyticsData?.commission_by_type || { total: 0, items: [] };
        },
        merchantsByStatus() {
            return this.analyticsData?.merchants_by_status || { total: 0, items: [] };
        },
        revenueByType() {
            return this.analyticsData?.revenue_by_type || { total: 0, items: [] };
        },
        topCategories() {
            return this.analyticsData?.top_categories || [];
        },
        payoutSummary() {
            return this.analyticsData?.payout_summary || { rows: [], total: null };
        },
        recentRegistrations() {
            return this.analyticsData?.recent_registrations || [];
        },
        insights() {
            return this.analyticsData?.insights || [];
        },
        notes() {
            return this.analyticsData?.notes || [];
        },
        summaryCards() {
            const s = this.summary;
            return [
                {
                    label: 'Total Merchants',
                    value: s.total_merchants?.current || 0,
                    prefix: '',
                    color: '#7c5cfc',
                    bg: '#efeaff',
                    icon: 'fa-store',
                    compareKey: 'total_merchants',
                },
                {
                    label: 'Active Merchants',
                    value: s.active_merchants?.current || 0,
                    prefix: '',
                    color: '#22c55e',
                    bg: '#e7f8ef',
                    icon: 'fa-check-circle',
                    compareKey: 'active_merchants',
                },
                {
                    label: 'New Merchants',
                    value: s.new_merchants?.current || 0,
                    prefix: '',
                    color: '#3b82f6',
                    bg: '#e8f1ff',
                    icon: 'fa-plus-circle',
                    compareKey: 'new_merchants',
                },
                {
                    label: 'Merchant Revenue',
                    value: s.total_revenue?.current || 0,
                    prefix: '₹',
                    color: '#0ea5e9',
                    bg: '#e0f2fe',
                    icon: 'fa-rupee-sign',
                    compareKey: 'total_revenue',
                },
                {
                    label: 'Commission Earned',
                    value: s.total_commission?.current || 0,
                    prefix: '₹',
                    color: '#f59e0b',
                    bg: '#fff4e5',
                    icon: 'fa-percent',
                    compareKey: 'total_commission',
                },
                {
                    label: 'Pending Payouts',
                    value: s.pending_payouts?.current || 0,
                    prefix: '₹',
                    color: '#ef4444',
                    bg: '#fdeaea',
                    icon: 'fa-hourglass-half',
                    compareKey: null,
                    note: 'All time · ' + (s.pending_payouts?.merchants || 0) + ' merchants',
                },
            ];
        },
        performanceTrendOptions() {
            return {
                chart: { type: 'line', toolbar: { show: true } },
                colors: ['#9AC444', '#008FFB'],
                xaxis: { categories: this.performanceTrend.labels },
                yaxis: {
                    title: { text: 'Amount (₹)' },
                    labels: { formatter: (v) => '₹' + this.formatNumber(v) },
                },
                stroke: { curve: 'smooth', width: 2 },
                markers: { size: 3 },
                legend: { position: 'top' },
                dataLabels: { enabled: false },
                tooltip: { y: { formatter: (v) => '₹' + this.formatNumber(v) } },
            };
        },
        performanceTrendSeries() {
            return [
                { name: 'Revenue (₹)', data: this.performanceTrend.revenue },
                { name: 'Commission (₹)', data: this.performanceTrend.commission },
            ];
        },
        commissionByTypeOptions() {
            return this.typeDonutOptions(this.commissionByType.items, this.commissionByType.total, true);
        },
        commissionByTypeSeries() {
            return this.commissionByType.items.map((i) => i.value);
        },
        revenueByTypeOptions() {
            return this.typeDonutOptions(this.revenueByType.items, this.revenueByType.total, true);
        },
        revenueByTypeSeries() {
            return this.revenueByType.items.map((i) => i.value);
        },
        merchantsByStatusOptions() {
            return {
                chart: { type: 'donut' },
                labels: this.merchantsByStatus.items.map((i) => i.name),
                colors: ['#9AC444', '#546E7A', '#FEB019', '#FF4560'],
                legend: { show: false },
                dataLabels: { enabled: false },
                stroke: { width: 2 },
                plotOptions: {
                    pie: {
                        donut: {
                            size: '70%',
                            labels: {
                                show: true,
                                total: {
                                    show: true,
                                    label: 'Total Merchants',
                                    formatter: () => this.formatNumber(this.merchantsByStatus.total),
                                },
                            },
                        },
                    },
                },
                responsive: [{ breakpoint: 480, options: { chart: { width: 300 }, legend: { position: 'bottom' } } }],
            };
        },
        merchantsByStatusSeries() {
            return this.merchantsByStatus.items.map((i) => i.count);
        },
    },
    methods: {
        setFilter(f) {
            this.filter = f;
            if (f !== 'custom') {
                this.fetchAnalytics();
            }
        },
        getCities() {
            axios.get(this.$apiUrl + '/public/cities')
                .then((response) => {
                    this.cities = response.data.data || response.data;
                })
                .catch(() => {});
        },
        fetchAnalytics() {
            this.loading = true;

            let params = { filter: this.filter };
            if (this.filter === 'custom') {
                params.start_date = this.customStart;
                params.end_date = this.customEnd;
            }
            if (this.city_id) {
                params.city_id = this.city_id;
            }

            axios.get(this.$apiUrl + '/merchant-analytics/overview', { params })
                .then((response) => {
                    if (response.data.status === 1) {
                        this.analyticsData = response.data.data;
                    }
                })
                .catch((error) => {
                    console.error('Error fetching merchant analytics:', error);
                })
                .finally(() => {
                    this.loading = false;
                });
        },
        getExportParams(section) {
            let params = { filter: this.filter, section: section };
            if (this.filter === 'custom') {
                params.start_date = this.customStart;
                params.end_date = this.customEnd;
            }
            if (this.city_id) {
                params.city_id = this.city_id;
            }
            return params;
        },
        downloadExcel(section) {
            const params = this.getExportParams(section);
            axios.get(this.$apiUrl + '/merchant-analytics/export-excel', { params, responseType: 'blob' })
                .then((response) => {
                    this.saveBlob(response.data, 'merchant_analytics_' + section + '.xlsx');
                })
                .catch((error) => console.error('Excel download failed:', error));
        },
        downloadPdf(section) {
            const params = this.getExportParams(section);
            axios.get(this.$apiUrl + '/merchant-analytics/export-pdf', { params, responseType: 'blob' })
                .then((response) => {
                    this.saveBlob(response.data, 'merchant_analytics_' + section + '.pdf', 'application/pdf');
                })
                .catch((error) => console.error('PDF download failed:', error));
        },
        saveBlob(data, filename, type) {
            const blob = type ? new Blob([data], { type }) : new Blob([data]);
            const url = window.URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.setAttribute('download', filename);
            document.body.appendChild(link);
            link.click();
            link.remove();
            window.URL.revokeObjectURL(url);
        },
        // Shared donut config for the two merchant-type charts, so commission
        // and revenue use the same colour per type.
        // Build a side-legend (name, value, %, colour) for a donut card.
        donutLegend(obj, isMoney, colors) {
            const total = obj.total || 0;
            return (obj.items || []).map((it, i) => {
                const val = it.value != null ? it.value : (it.count || 0);
                const pct = total > 0 ? Math.round((val / total) * 1000) / 10 : 0;
                return {
                    name: it.name,
                    display: (isMoney ? '₹' : '') + this.formatNumber(val),
                    percentage: pct,
                    color: colors ? colors[i % colors.length] : (this.typeColors[it.name] || '#546E7A'),
                };
            });
        },
        typeDonutOptions(items, total, isMoney) {
            return {
                chart: { type: 'donut' },
                labels: items.map((i) => i.name),
                colors: items.map((i) => this.typeColors[i.name] || '#546E7A'),
                legend: { show: false },
                dataLabels: { enabled: false },
                stroke: { width: 2 },
                plotOptions: {
                    pie: {
                        donut: {
                            size: '70%',
                            labels: {
                                show: true,
                                total: {
                                    show: true,
                                    label: 'Total',
                                    formatter: () => (isMoney ? '₹' : '') + this.formatNumber(total),
                                },
                            },
                        },
                    },
                },
                tooltip: {
                    y: { formatter: (v) => (isMoney ? '₹' : '') + this.formatNumber(v) },
                },
                responsive: [{ breakpoint: 480, options: { chart: { width: 300 }, legend: { position: 'bottom' } } }],
            };
        },
        // Scales a category bar relative to the top category so the leader fills
        // the track and the rest are proportional to it.
        categoryBarWidth(revenue) {
            const max = Math.max(...this.topCategories.map((c) => c.revenue), 1);
            return max > 0 ? Math.round((revenue / max) * 100) : 0;
        },
        typeBadgeClass(type) {
            switch (type) {
                case 'Restaurant':
                    return 'bg-success';
                case 'Grocery':
                    return 'bg-primary';
                case 'Combo (Both)':
                    return 'bg-warning';
                default:
                    return 'bg-secondary';
            }
        },
        statusBadgeClass(status) {
            switch (status) {
                case 'Active':
                    return 'bg-success';
                case 'Pending':
                    return 'bg-warning';
                case 'Rejected':
                    return 'bg-danger';
                case 'Inactive':
                    return 'bg-secondary';
                default:
                    return 'bg-secondary';
            }
        },
        insightIcon(icon) {
            const map = {
                star: 'fa-star',
                chart: 'fa-chart-line',
                'user-plus': 'fa-user-plus',
                alert: 'fa-exclamation-circle',
                clock: 'fa-clock',
            };
            return map[icon] || 'fa-info-circle';
        },
        formatNumber(value) {
            if (value === undefined || value === null) return '0';
            const num = parseFloat(value);
            if (isNaN(num)) return '0';
            if (Number.isInteger(num)) return num.toLocaleString('en-IN');
            return num.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        },
        // Abbreviates on the Indian scale (Thousand / Lakh / Crore) so a value
        // like 28675400 reads "2.87Cr" instead of overflowing the tile.
        formatCompact(value) {
            const num = parseFloat(value);
            if (isNaN(num)) return '0';
            const abs = Math.abs(num);
            if (abs >= 10000000) return (num / 10000000).toFixed(2).replace(/\.00$/, '') + 'Cr';
            if (abs >= 100000) return (num / 100000).toFixed(2).replace(/\.00$/, '') + 'L';
            if (abs >= 1000) return (num / 1000).toFixed(1).replace(/\.0$/, '') + 'K';
            return this.formatNumber(num);
        },
        // Tiles abbreviate money only; counts are small and shown in full.
        statDisplay(card) {
            const compact = card.prefix === '₹' ? this.formatCompact(card.value) : this.formatNumber(card.value);
            return card.prefix + compact;
        },
        statTitle(card) {
            return card.prefix + this.formatNumber(card.value);
        },
        // Returns the comparison block for a card, or null when the card has no
        // comparison (pending payouts is a running balance).
        cardTrend(card) {
            if (!card.compareKey) return null;
            const m = this.summary[card.compareKey];
            if (!m || m.change_percent === undefined) return null;
            return Object.assign({}, m, { abs_percent: Math.abs(m.change_percent) });
        },
    },
};
</script>

<style scoped>
/* ===== Stat cards (icon pinned top-right, label locked to 2 lines) ===== */
.ma-stats { margin-bottom: .25rem; }
.ma-stats [class*="col-"] { margin-bottom: 1rem; }
.ma-stats .stat-card { border: 1px solid #eef0f4; border-radius: 14px; box-shadow: 0 1px 2px rgba(16,24,40,.04); transition: box-shadow .15s ease; }
.ma-stats .stat-card:hover { box-shadow: 0 4px 14px rgba(16,24,40,.08); }
.ma-stats .stat-card .card-body { position: relative; padding: 16px 16px 14px; }
/* The icon is lifted and sized so its lower edge clears the value line; at
   38px/top:20px it overlapped the value and clipped long amounts. */
.ma-stats .stat-icon { position: absolute; top: 14px; right: 12px; width: 32px; height: 32px; border-radius: 9px; display: flex; align-items: center; justify-content: center; font-size: 13px; }
.ma-stats .stat-label { font-size: .74rem; color: #6b7280; font-weight: 500; line-height: 1.2; padding-right: 40px; height: 2.4em; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.ma-stats .stat-value { font-size: 1.3rem; font-weight: 700; line-height: 1.2; margin: 6px 0 5px; color: #111827; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; cursor: help; }
.ma-stats .stat-sub { font-size: .7rem; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; display: block; }
/* Between md and xl the tiles are narrowest (3-up), so ease the value down. */
@media (min-width: 768px) and (max-width: 1199.98px) {
    .ma-stats .stat-value { font-size: 1.15rem; }
}

/* ===== Cards ===== */
.card { border: 1px solid #eef0f4; border-radius: 14px; box-shadow: 0 1px 2px rgba(16,24,40,.03); margin-bottom: 1rem; }
.card-header { background: transparent; border-bottom: 1px solid #f1f2f6; padding: .9rem 1.1rem; }
.card-header h5 { font-size: 1rem; font-weight: 600; color: #111827; }
.card-body { padding: 1.15rem 1.25rem; }

/* ===== Tables ===== */
.table { margin-bottom: 0; }
.table thead th { text-transform: uppercase; font-size: .68rem; letter-spacing: .4px; color: #9ca3af; font-weight: 600; border-bottom: 1px solid #eef0f4; border-top: 0; padding: .55rem .6rem; white-space: nowrap; }
.table tbody td { border-top: 1px solid #f4f5f7; padding: .6rem; color: #374151; vertical-align: middle; }
.table tbody tr:hover { background: #fafbff; }

/* ===== Badges & controls ===== */
.badge { font-weight: 500; padding: .38em .62em; border-radius: 6px; }
.form-control-sm, .form-select-sm { border-radius: 8px; border-color: #e5e7eb; }

/* ===== Donut + side legend ===== */
.chart-flex { gap: .5rem 1rem; }
.donut-wrap { flex: 1 1 150px; max-width: 200px; min-width: 130px; }
.legend-list { list-style: none; margin: 0; padding: 0; flex: 1 1 150px; min-width: 140px; }
.legend-list li { display: flex; align-items: center; padding: 5px 0; font-size: .8rem; }
.legend-list .dot { width: 10px; height: 10px; border-radius: 50%; margin-right: 8px; flex: 0 0 auto; }
.legend-list .lg-name { flex: 1 1 auto; color: #374151; }
.legend-list .lg-val { font-weight: 600; color: #111827; white-space: nowrap; }
.legend-list .lg-val small { color: #9ca3af; font-weight: 400; }

.gap-2 {
    gap: 0.5rem;
}
.page-heading {
    margin-bottom: 1.5rem;
}
.page-heading h3 {
    margin-bottom: 0;
}
.period-chip {
    display: inline-flex;
    flex-direction: column;
    padding: 0.35rem 0.75rem;
    border: 1px solid #e0e0e0;
    border-radius: 6px;
    background: #f8f9fa;
    line-height: 1.2;
}
.period-chip-compare {
    border-style: dashed;
}
.trend-badge {
    font-weight: 600;
}
.trend-badge .text-muted {
    font-weight: 400;
}
.category-label {
    width: 90px;
    flex-shrink: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}
.category-bar-track {
    height: 8px;
    border-radius: 4px;
    background: #f0f0f0;
    overflow: hidden;
}
.category-bar-fill {
    height: 100%;
    background: #9AC444;
    border-radius: 4px;
}
.insight-icon {
    width: 26px;
    height: 26px;
    border-radius: 50%;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    font-size: 0.75rem;
}
.insight-success {
    background: #eaf4d8;
    color: #6f9c25;
}
.insight-warning {
    background: #fff4e0;
    color: #d68910;
}
</style>
