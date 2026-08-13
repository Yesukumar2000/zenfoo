<template>
    <div class="rider-analytics">
        <div class="page-heading">
            <!-- Header -->
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3 class="mb-0">Rider Analytics</h3>
                        <p class="text-subtitle text-muted mb-0">Track and analyze rider performance, earnings, deliveries and activity.</p>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">Dashboard</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">Rider Analytics</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <!-- Toolbar -->
            <div class="d-flex flex-wrap justify-content-end align-items-end ra-gap mb-3">
                <div>
                    <label class="small text-muted d-block mb-1">From</label>
                    <input type="date" v-model="fromDate" class="form-control form-control-sm" />
                </div>
                <div>
                    <label class="small text-muted d-block mb-1">To</label>
                    <input type="date" v-model="toDate" class="form-control form-control-sm" />
                </div>
                <button class="btn btn-sm btn-outline-secondary" @click="load"><i class="fa fa-filter me-1"></i> Apply</button>
                <span v-if="range.compare_from" class="small text-muted ms-1 mb-1">
                    Compare: {{ range.compare_from }} → {{ range.compare_to }}
                </span>
            </div>

            <!-- Stat cards -->
            <div class="row ra-stats">
                <div class="col-6 col-md-4 col-xl-2" v-for="c in statCards" :key="c.key">
                    <div class="card stat-card">
                        <div class="card-body">
                            <span class="stat-icon" :style="{ background: c.bg, color: c.color }"><i :class="'fa ' + c.icon"></i></span>
                            <div class="stat-label">{{ c.label }}</div>
                            <div class="stat-value">{{ formatStat(c) }}</div>
                            <div class="stat-sub" :class="deltaClass(c.key)">
                                <i class="fa" :class="deltaIcon(c.key)"></i>
                                {{ deltaPct(c.key) }}% <span class="text-muted">vs prev</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Row: Deliveries Trend | Deliveries by Type | Rider Status -->
            <div class="row mt-2">
                <div class="col-12 col-xl-5">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Deliveries Trend</h5></div>
                        <div class="card-body">
                            <apexchart v-if="trendChart.series.length" type="line" height="260"
                                       :options="trendChart.options" :series="trendChart.series"></apexchart>
                            <p v-else class="text-muted text-center my-5">No data</p>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-xl-4">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Deliveries by Type</h5></div>
                        <div class="card-body">
                            <div class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                <div class="donut-wrap">
                                    <apexchart v-if="typeChart.series.length" type="donut" height="185"
                                               :options="typeChart.options" :series="typeChart.series"></apexchart>
                                    <p v-else class="text-muted text-center my-5">No data</p>
                                </div>
                                <ul class="legend-list">
                                    <li v-for="(t,i) in overview.deliveries_by_type" :key="i">
                                        <span class="dot" :style="{ background: colorAt(i) }"></span>
                                        <span class="lg-name">{{ t.name }}</span>
                                        <span class="lg-val">{{ t.percentage }}% <small>({{ t.count }})</small></span>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-xl-3">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Rider Status</h5></div>
                        <div class="card-body">
                            <div class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                <div class="donut-wrap">
                                    <apexchart v-if="statusChart.series.length" type="donut" height="185"
                                               :options="statusChart.options" :series="statusChart.series"></apexchart>
                                </div>
                                <ul class="legend-list">
                                    <li v-for="(s,i) in riderStatusItems" :key="i">
                                        <span class="dot" :style="{ background: statusColors[i] }"></span>
                                        <span class="lg-name">{{ s.name }}</span>
                                        <span class="lg-val">{{ s.count }} <small>({{ s.percentage }}%)</small></span>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Row: Earnings Overview | Performance Summary -->
            <div class="row mt-2">
                <div class="col-12 col-xl-7">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Earnings Overview</h5></div>
                        <div class="card-body">
                            <apexchart v-if="earningsChart.series.length" type="line" height="260"
                                       :options="earningsChart.options" :series="earningsChart.series"></apexchart>
                            <p v-else class="text-muted text-center my-5">No data</p>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-xl-5">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Rider Performance Summary</h5></div>
                        <div class="card-body">
                            <div class="row perf-grid">
                                <div class="col-6" v-for="p in perfCards" :key="p.key">
                                    <div class="perf-box">
                                        <div class="perf-label">{{ p.label }}</div>
                                        <div class="perf-value">{{ perfValue(p.key) }}%</div>
                                        <div class="perf-delta" :class="perfDeltaClass(p.key)">
                                            <i class="fa" :class="perfDeltaIcon(p.key)"></i> {{ perfDeltaPct(p.key) }}%
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Row: Earnings Breakdown | Top Riders by Deliveries -->
            <div class="row mt-2">
                <div class="col-12 col-xl-5">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Rider Earnings Breakdown</h5></div>
                        <div class="card-body">
                            <div class="d-flex align-items-center flex-wrap justify-content-center chart-flex">
                                <div class="donut-wrap">
                                    <apexchart v-if="breakdownChart.series.length" type="donut" height="185"
                                               :options="breakdownChart.options" :series="breakdownChart.series"></apexchart>
                                    <p v-else class="text-muted text-center my-5">No data</p>
                                </div>
                                <ul class="legend-list">
                                    <li v-for="(b,i) in breakdownItems" :key="i">
                                        <span class="dot" :style="{ background: colorAt(i) }"></span>
                                        <span class="lg-name">{{ b.name }}</span>
                                        <span class="lg-val">{{ money(b.value) }} <small>({{ b.percentage }}%)</small></span>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-xl-7">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Top Riders by Deliveries</h5></div>
                        <div class="card-body table-responsive">
                            <table class="table table-sm align-middle mb-0">
                                <thead><tr><th>Rider Name</th><th>Deliveries</th><th>Earnings (₹)</th><th>Rating</th></tr></thead>
                                <tbody>
                                    <tr v-for="r in overview.top_by_deliveries" :key="r.id">
                                        <td class="fw-medium">{{ r.name }}</td>
                                        <td>{{ r.deliveries }}</td>
                                        <td>{{ money(r.earnings) }}</td>
                                        <td><span v-if="r.rating">{{ r.rating }} <i class="fa fa-star text-warning"></i></span><span v-else class="text-muted">-</span></td>
                                    </tr>
                                    <tr v-if="!overview.top_by_deliveries || !overview.top_by_deliveries.length"><td colspan="4" class="text-center text-muted">No data</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Row: Top Riders by Earnings (full width) -->
            <div class="row mt-2">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header"><h5 class="mb-0">Top Riders by Earnings</h5></div>
                        <div class="card-body table-responsive">
                            <table class="table table-sm align-middle mb-0">
                                <thead><tr><th>Rider Name</th><th>Earnings (₹)</th><th>Deliveries</th><th>Rating</th></tr></thead>
                                <tbody>
                                    <tr v-for="r in overview.top_by_earnings" :key="r.id">
                                        <td class="fw-medium">{{ r.name }}</td>
                                        <td>{{ money(r.earnings) }}</td>
                                        <td>{{ r.deliveries }}</td>
                                        <td><span v-if="r.rating">{{ r.rating }} <i class="fa fa-star text-warning"></i></span><span v-else class="text-muted">-</span></td>
                                    </tr>
                                    <tr v-if="!overview.top_by_earnings || !overview.top_by_earnings.length"><td colspan="4" class="text-center text-muted">No data</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Row: Availability Heatmap (full width) -->
            <div class="row mt-2">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header"><h5 class="mb-0">Rider Availability Heatmap</h5></div>
                        <div class="card-body">
                            <div class="heatmap-scroll">
                                <div class="heat-head">
                                    <span class="heat-day"></span>
                                    <span v-for="h in 24" :key="'h'+h" class="heat-cell heat-lbl">{{ hourLabel(h-1) }}</span>
                                </div>
                                <div class="heat-row" v-for="row in heatRows" :key="row.day">
                                    <span class="heat-day">{{ row.day }}</span>
                                    <span v-for="c in row.cells" :key="row.day + '-' + c.hour"
                                          class="heat-cell" :style="{ background: heatColor(c.value) }"
                                          :title="row.day + ' ' + hourLabel(c.hour) + ': ' + c.value + ' riders'"></span>
                                </div>
                            </div>
                            <div class="d-flex align-items-center justify-content-end mt-2 small text-muted">
                                <span class="me-2">Low Availability</span>
                                <span class="heat-legend"></span>
                                <span class="ms-2">High Availability</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Row: Payout Summary | Insights -->
            <div class="row mt-2">
                <div class="col-12 col-xl-8">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Rider Payout Summary</h5></div>
                        <div class="card-body table-responsive">
                            <table class="table table-sm align-middle mb-0">
                                <thead><tr><th>Payment Status</th><th>Riders</th><th>Total Payout (₹)</th><th>This Month (₹)</th><th>Last Month (₹)</th><th>Pending (₹)</th></tr></thead>
                                <tbody>
                                    <tr v-for="(p,i) in payoutRows" :key="i">
                                        <td><span class="badge" :class="payoutClass(p.status)">{{ p.status }}</span></td>
                                        <td>{{ p.riders }}</td><td>{{ money(p.total) }}</td>
                                        <td>{{ money(p.this_month) }}</td><td>{{ money(p.last_month) }}</td><td>{{ money(p.pending) }}</td>
                                    </tr>
                                    <tr v-if="payoutTotal" class="fw-medium total-row">
                                        <td>Total</td><td>{{ payoutTotal.riders }}</td><td>{{ money(payoutTotal.total) }}</td>
                                        <td>{{ money(payoutTotal.this_month) }}</td><td>{{ money(payoutTotal.last_month) }}</td><td>{{ money(payoutTotal.pending) }}</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-xl-4">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Rider Insights</h5></div>
                        <div class="card-body">
                            <ul class="insight-list mb-0">
                                <li v-for="(ins,i) in overview.insights" :key="i">
                                    <span class="ins-ic" :class="'ins-' + ins.type"><i class="fa" :class="insIcon(ins.icon)"></i></span>
                                    <span>{{ ins.text }}</span>
                                </li>
                                <li v-if="!overview.insights || !overview.insights.length" class="text-muted">No insights</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    name: 'RiderAnalytics',
    data() {
        return {
            fromDate: '',
            toDate: '',
            range: {},
            overview: { deliveries_by_type: [], top_by_deliveries: [], top_by_earnings: [], insights: [] },
            stats: {},
            palette: ['#22c55e', '#3b82f6', '#f59e0b', '#7c5cfc', '#ef4444', '#14b8a6'],
            statusColors: ['#22c55e', '#f59e0b', '#ef4444', '#7c5cfc'],
            statCards: [
                { key: 'total_riders', label: 'Total Riders', icon: 'fa-users', bg: '#efeaff', color: '#7c5cfc', fmt: 'num' },
                { key: 'active_riders', label: 'Active Riders', icon: 'fa-check-circle', bg: '#e7f8ef', color: '#22c55e', fmt: 'num' },
                { key: 'total_deliveries', label: 'Total Deliveries', icon: 'fa-box', bg: '#e8f1ff', color: '#3b82f6', fmt: 'num' },
                { key: 'total_earnings', label: 'Total Earnings', icon: 'fa-wallet', bg: '#fff4e5', color: '#f59e0b', fmt: 'money' },
                { key: 'avg_earnings_per_rider', label: 'Avg. Earnings/Rider', icon: 'fa-chart-line', bg: '#efeaff', color: '#7c5cfc', fmt: 'money' },
                { key: 'avg_delivery_time', label: 'Avg. Delivery Time', icon: 'fa-clock', bg: '#fdeaea', color: '#ef4444', fmt: 'mins' },
            ],
            perfCards: [
                { key: 'on_time_rate', label: 'On-time Delivery' },
                { key: 'acceptance_rate', label: 'Acceptance Rate' },
                { key: 'cancellation_rate', label: 'Cancellation Rate' },
                { key: 'completion_rate', label: 'Completion Rate' },
            ],
            trendChart: { options: {}, series: [] },
            typeChart: { options: {}, series: [] },
            statusChart: { options: {}, series: [] },
            earningsChart: { options: {}, series: [] },
            breakdownChart: { options: {}, series: [] },
        };
    },
    computed: {
        riderStatusItems() { return (this.overview.rider_status && this.overview.rider_status.items) || []; },
        breakdownItems() { return (this.overview.earnings_breakdown && this.overview.earnings_breakdown.items) || []; },
        heatRows() { return (this.overview.availability_heatmap && this.overview.availability_heatmap.rows) || []; },
        heatMax() { return (this.overview.availability_heatmap && this.overview.availability_heatmap.max) || 0; },
        payoutRows() { return (this.overview.payout_summary && this.overview.payout_summary.rows) || []; },
        payoutTotal() { return this.overview.payout_summary && this.overview.payout_summary.total; },
    },
    created() { this.load(); },
    methods: {
        colorAt(i) { return this.palette[i % this.palette.length]; },
        money(v) {
            const n = Number(v || 0);
            return '₹' + n.toLocaleString('en-IN', { maximumFractionDigits: 0 });
        },
        num(v) { return Number(v || 0).toLocaleString('en-IN'); },
        hourLabel(h) {
            if (h === 0) return '12 AM';
            if (h === 12) return '12 PM';
            return (h % 12) + (h < 12 ? ' AM' : ' PM');
        },
        formatStat(c) {
            const s = this.stats[c.key];
            if (!s) return '-';
            if (c.fmt === 'money') return this.money(s.value);
            if (c.fmt === 'mins') return Math.round(s.value || 0) + ' mins';
            return this.num(s.value);
        },
        deltaPct(key) { const s = this.stats[key]; return s && s.delta ? Math.abs(s.delta.change_percent) : 0; },
        deltaClass(key) { const s = this.stats[key]; return s && s.delta && s.delta.is_positive ? 'text-success' : 'text-danger'; },
        deltaIcon(key) { const s = this.stats[key]; return s && s.delta && s.delta.is_positive ? 'fa-arrow-up' : 'fa-arrow-down'; },
        perfValue(key) { const p = this.overview.performance_summary; return p && p[key] ? p[key].value : 0; },
        perfDeltaPct(key) { const p = this.overview.performance_summary; return p && p[key] ? Math.abs(p[key].delta.change_percent) : 0; },
        perfDeltaClass(key) { const p = this.overview.performance_summary; return p && p[key] && p[key].delta.is_positive ? 'text-success' : 'text-danger'; },
        perfDeltaIcon(key) { const p = this.overview.performance_summary; return p && p[key] && p[key].delta.is_positive ? 'fa-arrow-up' : 'fa-arrow-down'; },
        payoutClass(s) { return s === 'Paid' ? 'bg-success' : (s === 'Failed' ? 'bg-danger' : 'bg-warning'); },
        insIcon(i) {
            return { chart: 'fa-chart-line', clock: 'fa-clock', check: 'fa-check-circle', alert: 'fa-exclamation-triangle' }[i] || 'fa-info-circle';
        },
        heatColor(v) {
            if (!this.heatMax || !v) return '#f1f5f4';
            const t = v / this.heatMax;
            // light -> dark green
            const a = 0.12 + t * 0.88;
            return 'rgba(34,197,94,' + a.toFixed(2) + ')';
        },
        load() {
            const params = {};
            if (this.fromDate) params.from_date = this.fromDate;
            if (this.toDate) params.to_date = this.toDate;
            axios.get(this.$apiUrl + '/rider-analytics/overview', { params }).then(res => {
                const d = res.data.data;
                this.overview = d;
                this.stats = d.stats || {};
                this.range = d.range || {};
                this.buildCharts(d);
            }).catch(() => { this.showMessage && this.showMessage('error', 'Failed to load rider analytics'); });
        },
        buildCharts(d) {
            // Deliveries trend
            this.trendChart = {
                series: [
                    { name: 'Deliveries', data: (d.deliveries_trend || []).map(x => x.deliveries) },
                    { name: 'Active Riders', data: (d.deliveries_trend || []).map(x => x.riders) },
                ],
                options: {
                    chart: { toolbar: { show: false } },
                    stroke: { curve: 'smooth', width: 2 },
                    markers: { size: 2 },
                    colors: ['#22c55e', '#3b82f6'],
                    xaxis: { categories: (d.deliveries_trend || []).map(x => x.date), tickAmount: 7 },
                    legend: { position: 'top' },
                    grid: { borderColor: '#f0f0f0' },
                },
            };
            // Donut base
            const donut = (labels, colors, label) => ({
                labels, colors,
                legend: { show: false },
                dataLabels: { enabled: false },
                stroke: { width: 2 },
                plotOptions: { pie: { donut: { size: '70%', labels: { show: true, value: { show: true, fontSize: '20px', fontWeight: 700 }, total: { show: true, label: label, fontSize: '11px', color: '#888', formatter: (w) => w.globals.seriesTotals.reduce((a, b) => a + b, 0) } } } } },
            });
            // Deliveries by type
            const types = d.deliveries_by_type || [];
            this.typeChart = {
                series: types.map(t => t.count),
                options: donut(types.map(t => t.name), types.map((t, i) => this.colorAt(i)), 'Total Deliveries'),
            };
            // Rider status
            const st = (d.rider_status && d.rider_status.items) || [];
            this.statusChart = {
                series: st.map(s => s.count),
                options: donut(st.map(s => s.name), this.statusColors, 'Total Riders'),
            };
            // Earnings overview
            this.earningsChart = {
                series: [
                    { name: 'Total Earnings (₹)', type: 'column', data: (d.earnings_overview || []).map(x => x.earnings) },
                    { name: 'Avg. per Rider (₹)', type: 'line', data: (d.earnings_overview || []).map(x => x.avg_per_rider) },
                ],
                options: {
                    chart: { toolbar: { show: false } },
                    stroke: { width: [0, 2], curve: 'smooth' },
                    colors: ['#22c55e', '#3b82f6'],
                    xaxis: { categories: (d.earnings_overview || []).map(x => x.date), tickAmount: 7 },
                    yaxis: [{ title: { text: 'Total (₹)' } }, { opposite: true, title: { text: 'Avg (₹)' } }],
                    legend: { position: 'top' },
                    grid: { borderColor: '#f0f0f0' },
                },
            };
            // Earnings breakdown
            const bd = (d.earnings_breakdown && d.earnings_breakdown.items) || [];
            this.breakdownChart = {
                series: bd.map(b => b.value),
                options: donut(bd.map(b => b.name), bd.map((b, i) => this.colorAt(i)), 'Total Earnings'),
            };
        },
    },
};
</script>

<style scoped>
.rider-analytics .ra-gap { gap: .5rem; }

/* Stat cards */
.ra-stats { margin-bottom: .25rem; }
.ra-stats [class*="col-"] { margin-bottom: 1rem; }
.ra-stats .stat-card { border: 1px solid #eef0f4; border-radius: 14px; box-shadow: 0 1px 2px rgba(16,24,40,.04); transition: box-shadow .15s ease; }
.ra-stats .stat-card:hover { box-shadow: 0 4px 14px rgba(16,24,40,.08); }
.ra-stats .stat-card .card-body { position: relative; padding: 16px 16px 14px; }
.ra-stats .stat-icon { position: absolute; top: 20px; right: 14px; width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 15px; }
.ra-stats .stat-label { font-size: .74rem; color: #6b7280; font-weight: 500; line-height: 1.2; padding-right: 46px; height: 2.4em; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.ra-stats .stat-value { font-size: 1.45rem; font-weight: 700; line-height: 1.15; margin: 4px 0 5px; color: #111827; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.ra-stats .stat-sub { font-size: .7rem; font-weight: 600; white-space: nowrap; }

/* Cards */
.rider-analytics .card { border: 1px solid #eef0f4; border-radius: 14px; box-shadow: 0 1px 2px rgba(16,24,40,.03); margin-bottom: 1rem; }
.rider-analytics .card-header { background: transparent; border-bottom: 1px solid #f1f2f6; padding: .9rem 1.1rem; }
.rider-analytics .card-header h5 { font-size: 1rem; font-weight: 600; color: #111827; }
.rider-analytics .card-body { padding: 1.15rem 1.25rem; }

/* Tables */
.rider-analytics .table thead th { text-transform: uppercase; font-size: .68rem; letter-spacing: .4px; color: #9ca3af; font-weight: 600; border-bottom: 1px solid #eef0f4; border-top: 0; padding: .55rem .6rem; white-space: nowrap; }
.rider-analytics .table tbody td { border-top: 1px solid #f4f5f7; padding: .6rem; color: #374151; vertical-align: middle; }
.rider-analytics .table tbody tr:hover { background: #fafbff; }
.rider-analytics .fw-medium { font-weight: 600; color: #111827; }
.rider-analytics .total-row td { border-top: 2px solid #eef0f4; color: #111827; }
.rider-analytics .badge { font-weight: 500; padding: .38em .62em; border-radius: 6px; }

/* Donut + legend */
.chart-flex { gap: .5rem 1rem; }
.donut-wrap { flex: 1 1 150px; max-width: 190px; min-width: 130px; }
.legend-list { list-style: none; margin: 0; padding: 0; flex: 1 1 150px; min-width: 140px; }
.legend-list li { display: flex; align-items: center; padding: 5px 0; font-size: .8rem; }
.legend-list .dot { width: 10px; height: 10px; border-radius: 50%; margin-right: 8px; flex: 0 0 auto; }
.legend-list .lg-name { flex: 1 1 auto; color: #374151; }
.legend-list .lg-val { font-weight: 600; color: #111827; white-space: nowrap; }
.legend-list .lg-val small { color: #9ca3af; font-weight: 400; }

/* Performance boxes */
.perf-grid > [class*="col-"] { margin-bottom: .75rem; }
.perf-box { border: 1px solid #eef0f4; border-radius: 10px; padding: 12px; text-align: center; height: 100%; }
.perf-label { font-size: .72rem; color: #6b7280; margin-bottom: 4px; }
.perf-value { font-size: 1.4rem; font-weight: 700; color: #111827; line-height: 1; }
.perf-delta { font-size: .7rem; font-weight: 600; margin-top: 3px; }

/* Heatmap */
.heatmap-scroll { overflow-x: auto; }
.heat-head, .heat-row { display: flex; align-items: center; min-width: 620px; }
.heat-day { flex: 0 0 42px; font-size: .72rem; color: #6b7280; }
.heat-cell { flex: 1 1 auto; height: 18px; margin: 1px; border-radius: 3px; background: #f1f5f4; }
.heat-lbl { background: transparent; font-size: .6rem; color: #9ca3af; text-align: center; height: auto; overflow: hidden; white-space: nowrap; }
.heat-legend { display: inline-block; width: 120px; height: 8px; border-radius: 4px; background: linear-gradient(90deg, rgba(34,197,94,.12), rgba(34,197,94,1)); }

/* Insights */
.insight-list { list-style: none; margin: 0; padding: 0; }
.insight-list li { display: flex; align-items: flex-start; padding: 9px 0; border-bottom: 1px solid #f4f5f7; font-size: .82rem; color: #4b5563; }
.insight-list li:last-child { border-bottom: 0; }
.insight-list .ins-ic { width: 26px; height: 26px; border-radius: 8px; display: flex; align-items: center; justify-content: center; margin-right: 9px; flex: 0 0 auto; font-size: 11px; }
.insight-list .ins-success { background: #e7f8ef; color: #22c55e; }
.insight-list .ins-warning { background: #fff4e5; color: #f59e0b; }
</style>
