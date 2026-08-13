<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Profit / Loss Comparison</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">Dashboard</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                Profit / Loss
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
                    <select class="form-control form-control-sm mr-2" v-model="city_id" @change="fetchData()" style="width:auto; min-width:120px;">
                        <option value="">All Zones</option>
                        <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
                    </select>
                    <!-- Date Range Picker for Custom -->
                    <div v-if="filter === 'custom'" class="d-flex align-items-center">
                        <input type="date" class="form-control form-control-sm mr-1" v-model="customStart" />
                        <span class="mx-1">to</span>
                        <input type="date" class="form-control form-control-sm ml-1" v-model="customEnd" />
                        <button class="btn btn-sm btn-success ml-2" @click="fetchData">Apply</button>
                    </div>
                    <!-- Export Buttons -->
                    <b-dropdown v-if="data" size="sm" variant="outline-success" right>
                        <template #button-content>
                            <i class="fa fa-download mr-1"></i> Export
                        </template>
                        <b-dropdown-item @click="downloadExcel">Excel Download</b-dropdown-item>
                        <b-dropdown-item @click="downloadPdf">PDF Download</b-dropdown-item>
                    </b-dropdown>
                </div>
            </div>
        </div>

        <div class="page-content">
            <!-- Loading -->
            <div v-if="loading" class="text-center py-5">
                <b-spinner variant="success" label="Loading..."></b-spinner>
                <p class="mt-2">Loading comparison data...</p>
            </div>

            <template v-else-if="data">
                <!-- Comparison Metric Cards -->
                <div class="row mb-4">
                    <div class="col-12 col-lg-4 col-md-4 mb-3" v-for="card in metricCards" :key="card.label">
                        <div class="card h-100 comparison-card-soft" :class="card.isPositive ? 'card-positive' : 'card-negative'">
                            <div class="card-body py-3 px-3">
                                <div class="d-flex justify-content-between align-items-start">
                                    <div>
                                        <span class="text-muted small text-uppercase d-block mb-1">{{ card.label }}</span>
                                        <h4 class="mb-0 font-weight-bold card-value">{{ card.prefix }}{{ formatNumber(card.current) }}</h4>
                                    </div>
                                    <span class="badge badge-pill px-2 py-1" :class="card.isPositive ? 'badge-positive' : 'badge-negative'">
                                        <i :class="card.isPositive ? 'fa fa-arrow-up' : 'fa fa-arrow-down'" class="mr-1"></i>
                                        {{ card.changePercent >= 0 ? '+' : '' }}{{ card.changePercent }}%
                                    </span>
                                </div>
                                <div class="mt-2 text-muted small">
                                    Previous: {{ card.prefix }}{{ formatNumber(card.previous) }}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- ============ Platform Profit Analysis ============ -->
                <template v-if="profit && profit.available">
                    <div class="row">
                        <div class="col-12">
                            <h5 class="section-title mb-2">Platform Profit Analysis</h5>
                            <div class="alert profit-note mb-3">
                                <i class="fa fa-info-circle mr-1"></i>
                                <strong>How profit is calculated:</strong>
                                Platform profit = <strong>Commission Income</strong> earned from sellers on delivered orders
                                (admin commission on each item's selling price) minus the <strong>promo discounts</strong> the
                                platform funds. Payment-gateway fees and GST are pass-through and excluded; item cost-price
                                margin and delivery margin are not tracked in this app.
                            </div>
                        </div>
                    </div>

                    <!-- Profit Metric Cards -->
                    <div class="row mb-4">
                        <div class="col-12 col-lg-3 col-md-6 mb-3" v-for="card in profitCards" :key="card.key">
                            <div class="card h-100 comparison-card-soft"
                                 :class="[card.isPositive ? 'card-positive' : 'card-negative', card.isHeadline ? 'card-headline' : '']">
                                <div class="card-body py-3 px-3">
                                    <div class="d-flex justify-content-between align-items-start">
                                        <div>
                                            <span class="text-muted small text-uppercase d-block mb-1">{{ card.label }}</span>
                                            <h4 class="mb-0 font-weight-bold card-value">₹{{ formatNumber(card.current) }}</h4>
                                        </div>
                                        <span class="badge badge-pill px-2 py-1" :class="card.isPositive ? 'badge-positive' : 'badge-negative'">
                                            <i :class="card.isPositive ? 'fa fa-arrow-up' : 'fa fa-arrow-down'" class="mr-1"></i>
                                            {{ card.changePercent >= 0 ? '+' : '' }}{{ card.changePercent }}%
                                        </span>
                                    </div>
                                    <div class="mt-2 text-muted small">
                                        Previous: ₹{{ formatNumber(card.previous) }}
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Profit Trend Chart + side stats -->
                    <div class="row mb-4">
                        <div class="col-12 col-lg-8 mb-3">
                            <div class="card h-100">
                                <div class="card-header">
                                    <h5 class="mb-0">Profit Trend &mdash; {{ profit.current_period }}</h5>
                                </div>
                                <div class="card-body">
                                    <apexchart
                                        type="line"
                                        height="340"
                                        :options="profitChartOptions"
                                        :series="profitChartSeries"
                                    ></apexchart>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-lg-4 mb-3">
                            <div class="card h-100">
                                <div class="card-header">
                                    <h5 class="mb-0">Profit Snapshot</h5>
                                </div>
                                <div class="card-body">
                                    <div class="stat-line d-flex justify-content-between py-2">
                                        <span class="text-muted">Effective Take Rate</span>
                                        <span class="font-weight-bold">{{ profit.take_rate }}%</span>
                                    </div>
                                    <div class="stat-line d-flex justify-content-between py-2">
                                        <span class="text-muted">Avg Profit / Order</span>
                                        <span class="font-weight-bold">₹{{ formatNumber(profit.avg_profit_per_order) }}</span>
                                    </div>
                                    <div class="stat-line d-flex justify-content-between py-2">
                                        <span class="text-muted">Settled Orders</span>
                                        <span class="font-weight-bold">{{ formatNumber(profit.settled_orders) }}</span>
                                    </div>
                                    <div class="stat-line d-flex justify-content-between py-2">
                                        <span class="text-muted">Seller Payout</span>
                                        <span class="font-weight-bold">₹{{ formatNumber(profit.seller_payout) }}</span>
                                    </div>
                                    <p class="text-muted small mb-0 mt-2">
                                        Take rate = commission &divide; settled item value (net of GST).
                                        Only delivered/settled orders contribute.
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </template>

                <!-- Charts Row -->
                <div class="row mb-4">
                    <!-- Revenue, Discounts, Delivery Charges -->
                    <div class="col-12 mb-3">
                        <div class="card h-100">
                            <div class="card-header">
                                <h5 class="mb-0">Revenue Comparison</h5>
                            </div>
                            <div class="card-body">
                                <apexchart
                                    type="bar"
                                    height="320"
                                    :options="comparisonBarOptions"
                                    :series="comparisonBarSeries"
                                ></apexchart>
                            </div>
                        </div>
                    </div>
                    <!-- Orders, Avg Order Value, Promo Discount -->
                    <div class="col-12 mb-3">
                        <div class="card h-100">
                            <div class="card-header">
                                <h5 class="mb-0">Orders & Other Metrics</h5>
                            </div>
                            <div class="card-body">
                                <apexchart
                                    type="bar"
                                    height="320"
                                    :options="smallMetricsBarOptions"
                                    :series="smallMetricsBarSeries"
                                ></apexchart>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Detailed Comparison Table -->
                <div class="row mb-4">
                    <div class="col-12">
                        <div class="card">
                            <div class="card-header">
                                <h5 class="mb-0">Detailed Comparison</h5>
                            </div>
                            <div class="card-body">
                                <table class="table table-bordered table-sm">
                                    <thead class="thead-light">
                                        <tr>
                                            <th>Metric</th>
                                            <th class="text-right">{{ data.current_period }}</th>
                                            <th class="text-right">{{ data.previous_period }}</th>
                                            <th class="text-right">Change</th>
                                            <th class="text-right">Change %</th>
                                            <th class="text-center">Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="row in tableRows" :key="row.label">
                                            <td class="font-weight-bold">{{ row.label }}</td>
                                            <td class="text-right">{{ row.prefix }}{{ formatNumber(row.current) }}</td>
                                            <td class="text-right">{{ row.prefix }}{{ formatNumber(row.previous) }}</td>
                                            <td class="text-right font-weight-bold" :style="{ color: row.changeColor }">
                                                {{ row.change >= 0 ? '+' : '' }}{{ row.prefix }}{{ formatNumber(row.change) }}
                                            </td>
                                            <td class="text-right font-weight-bold" :style="{ color: row.changeColor }">
                                                {{ row.changePercent >= 0 ? '+' : '' }}{{ row.changePercent }}%
                                            </td>
                                            <td class="text-center">
                                                <span class="badge badge-pill px-2 py-1" :class="row.isPositive ? 'badge-positive' : 'badge-negative'">
                                                    <i :class="row.isPositive ? 'fa fa-arrow-up' : 'fa fa-arrow-down'" class="mr-1"></i>
                                                    {{ row.isPositive ? 'UP' : 'DOWN' }}
                                                </span>
                                            </td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </template>
        </div>
    </div>
</template>

<script>
import VueApexCharts from 'vue-apexcharts';
import axios from 'axios';

export default {
    name: "ProfitLossComparison",
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
            data: null,
            profit: null,
            profitMetricLabels: {
                net_profit: 'Net Platform Profit',
                commission_income: 'Commission Income',
                promo_cost: 'Promo Discount (Cost)',
                gateway_fees: 'Gateway Fees',
            },
            filterOptions: [
                { label: 'Today', value: 'daily' },
                { label: 'This Week', value: 'weekly' },
                { label: 'This Month', value: 'monthly' },
                { label: 'Custom', value: 'custom' },
            ],
            metricLabels: {
                revenue: 'Revenue',
                orders: 'Total Orders',
                avg_order_value: 'Avg Order Value',
                total_discount: 'Total Discounts',
                delivery_charges: 'Delivery Charges',
                promo_discount: 'Promo Discount',
            },
        };
    },
    created() {
        this.getCities();
        this.fetchData();
    },
    computed: {
        metrics() {
            return this.data?.metrics || {};
        },
        overallIsProfit() {
            return this.metrics.revenue?.is_positive ?? true;
        },
        overallChangePercent() {
            const p = this.metrics.revenue?.change_percent ?? 0;
            return (p >= 0 ? '+' : '') + p + '%';
        },
        metricCards() {
            if (!this.data) return [];
            const m = this.metrics;
            const keys = Object.keys(this.metricLabels);
            const cards = keys.map(key => {
                const metric = m[key] || {};
                return {
                    label: this.metricLabels[key],
                    current: metric.current || 0,
                    previous: metric.previous || 0,
                    prefix: key === 'orders' ? '' : '\u20B9',
                    changePercent: metric.change_percent || 0,
                    isPositive: metric.is_favorable ?? metric.is_positive,
                };
            });
            // Promo Discount (Cost) and Gateway Fees, moved here from Platform Profit Analysis
            const pm = this.profitMetrics;
            ['promo_cost', 'gateway_fees'].forEach(key => {
                const metric = pm[key];
                if (!metric) return;
                cards.push({
                    label: this.profitMetricLabels[key],
                    current: metric.current || 0,
                    previous: metric.previous || 0,
                    prefix: '\u20B9',
                    changePercent: metric.change_percent || 0,
                    isPositive: metric.is_favorable ?? metric.is_positive,
                });
            });
            return cards;
        },
        tableRows() {
            if (!this.data) return [];
            const m = this.metrics;
            return Object.keys(this.metricLabels).map(key => {
                const metric = m[key] || {};
                const isPositive = metric.is_favorable ?? metric.is_positive;
                return {
                    label: this.metricLabels[key],
                    current: metric.current || 0,
                    previous: metric.previous || 0,
                    change: metric.change || 0,
                    changePercent: metric.change_percent || 0,
                    prefix: key === 'orders' ? '' : '\u20B9',
                    isPositive: isPositive,
                    changeColor: isPositive ? '#4CAF50' : '#FF4560',
                };
            });
        },
        comparisonBarOptions() {
            return {
                chart: { type: 'bar', toolbar: { show: true } },
                colors: ['#9AC444', '#546E7A'],
                plotOptions: { bar: { borderRadius: 4, columnWidth: '55%' } },
                xaxis: { categories: this.data?.chart?.labels || [] },
                yaxis: { labels: { formatter: (v) => v >= 1000 ? '\u20B9' + (v / 1000).toFixed(1) + 'K' : '\u20B9' + v } },
                dataLabels: { enabled: false },
                legend: { position: 'top' },
                tooltip: { y: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
            };
        },
        comparisonBarSeries() {
            if (!this.data) return [];
            return [
                { name: this.data.current_period, data: this.data.chart.current },
                { name: this.data.previous_period, data: this.data.chart.previous },
            ];
        },
        smallMetricsBarOptions() {
            const m = this.metrics;
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                colors: ['#9AC444', '#546E7A'],
                plotOptions: { bar: { borderRadius: 4, columnWidth: '50%' } },
                xaxis: { categories: ['Orders', 'Avg Order Value', 'Promo Discount'] },
                yaxis: { labels: { formatter: (v) => Number.isInteger(v) ? v : '\u20B9' + v.toLocaleString('en-IN') } },
                dataLabels: { enabled: true, style: { fontSize: '10px' }, formatter: (v) => v >= 1000 ? '\u20B9' + (v / 1000).toFixed(1) + 'K' : (v % 1 === 0 ? v : '\u20B9' + v.toFixed(0)) },
                legend: { position: 'top' },
                tooltip: { y: { formatter: (v) => this.formatNumber(v) } },
            };
        },
        smallMetricsBarSeries() {
            if (!this.data) return [];
            const m = this.metrics;
            return [
                { name: this.data.current_period, data: [m.orders?.current || 0, m.avg_order_value?.current || 0, m.promo_discount?.current || 0] },
                { name: this.data.previous_period, data: [m.orders?.previous || 0, m.avg_order_value?.previous || 0, m.promo_discount?.previous || 0] },
            ];
        },
        changePercentOptions() {
            const percentages = Object.keys(this.metricLabels).map(key => this.metrics[key]?.change_percent || 0);
            const colors = Object.keys(this.metricLabels).map(key => {
                const isPositive = this.metrics[key]?.is_favorable ?? this.metrics[key]?.is_positive;
                return isPositive ? '#4CAF50' : '#FF4560';
            });
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                plotOptions: { bar: { horizontal: true, borderRadius: 4, barHeight: '60%', distributed: true } },
                colors: colors,
                xaxis: { categories: Object.values(this.metricLabels), labels: { formatter: (v) => v + '%' } },
                yaxis: { labels: { style: { fontSize: '11px' } } },
                dataLabels: { enabled: true, formatter: (v) => (v >= 0 ? '+' : '') + v + '%', style: { fontSize: '11px' } },
                legend: { show: false },
                tooltip: { y: { formatter: (v) => (v >= 0 ? '+' : '') + v + '%' } },
            };
        },
        changePercentSeries() {
            const percentages = Object.keys(this.metricLabels).map(key => this.metrics[key]?.change_percent || 0);
            return [{ name: 'Change %', data: percentages }];
        },
        profitMetrics() {
            return this.profit?.metrics || {};
        },
        profitCards() {
            if (!this.profit) return [];
            // promo_cost & gateway_fees moved to the top Profit / Loss Comparison cards
            const movedKeys = ['promo_cost', 'gateway_fees'];
            return Object.keys(this.profitMetricLabels).filter(key => !movedKeys.includes(key)).map(key => {
                const metric = this.profitMetrics[key] || {};
                return {
                    key,
                    label: this.profitMetricLabels[key],
                    current: metric.current || 0,
                    previous: metric.previous || 0,
                    changePercent: metric.change_percent || 0,
                    isPositive: metric.is_favorable ?? metric.is_positive,
                    isHeadline: key === 'net_profit',
                };
            });
        },
        profitChartOptions() {
            return {
                chart: { type: 'line', toolbar: { show: true }, stacked: false },
                colors: ['#9AC444', '#FF9800', '#2E7D32'],
                stroke: { width: [0, 0, 3], curve: 'smooth' },
                plotOptions: { bar: { borderRadius: 4, columnWidth: '55%' } },
                xaxis: { categories: this.profit?.chart?.labels || [] },
                yaxis: { labels: { formatter: (v) => v >= 1000 ? '₹' + (v / 1000).toFixed(1) + 'K' : '₹' + Math.round(v) } },
                dataLabels: { enabled: false },
                markers: { size: [0, 0, 4] },
                legend: { position: 'top' },
                tooltip: { shared: true, intersect: false, y: { formatter: (v) => '₹' + this.formatNumber(v) } },
            };
        },
        profitChartSeries() {
            if (!this.profit?.chart) return [];
            return [
                { name: 'Commission Income', type: 'column', data: this.profit.chart.commission || [] },
                { name: 'Promo Cost', type: 'column', data: this.profit.chart.promo || [] },
                { name: 'Net Profit', type: 'line', data: this.profit.chart.net || [] },
            ];
        },
    },
    methods: {
        setFilter(f) {
            this.filter = f;
            if (f !== 'custom') {
                this.fetchData();
            }
        },
        getCities() {
            axios.get(this.$apiUrl + '/public/cities')
                .then((response) => {
                    this.cities = response.data.data || response.data;
                })
                .catch(() => {});
        },
        fetchData() {
            this.loading = true;
            let params = { filter: this.filter };
            if (this.filter === 'custom') {
                params.start_date = this.customStart;
                params.end_date = this.customEnd;
            }
            if (this.city_id) {
                params.city_id = this.city_id;
            }
            axios.get(this.$apiUrl + '/order-analytics', { params })
                .then((response) => {
                    if (response.data.status === 1) {
                        this.data = response.data.data.profit_loss_comparison;
                        this.profit = response.data.data.profit_analysis;
                    }
                })
                .catch((error) => {
                    console.error('Error fetching comparison data:', error);
                })
                .finally(() => {
                    this.loading = false;
                });
        },
        formatNumber(value) {
            if (value === undefined || value === null) return '0';
            const num = parseFloat(value);
            if (isNaN(num)) return '0';
            if (Number.isInteger(num)) return num.toLocaleString('en-IN');
            return num.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        },
        getExportParams() {
            let params = { filter: this.filter, section: 'comparison' };
            if (this.filter === 'custom') {
                params.start_date = this.customStart;
                params.end_date = this.customEnd;
            }
            if (this.city_id) {
                params.city_id = this.city_id;
            }
            return params;
        },
        downloadExcel() {
            const params = this.getExportParams();
            axios.get(this.$apiUrl + '/order-analytics/export-excel', { params, responseType: 'blob' })
                .then((response) => {
                    const url = window.URL.createObjectURL(new Blob([response.data]));
                    const link = document.createElement('a');
                    link.href = url;
                    link.setAttribute('download', 'profit_loss_comparison.xlsx');
                    document.body.appendChild(link);
                    link.click();
                    link.remove();
                    window.URL.revokeObjectURL(url);
                })
                .catch((error) => console.error('Excel download failed:', error));
        },
        downloadPdf() {
            const params = this.getExportParams();
            axios.get(this.$apiUrl + '/order-analytics/export-pdf', { params, responseType: 'blob' })
                .then((response) => {
                    const url = window.URL.createObjectURL(new Blob([response.data], { type: 'application/pdf' }));
                    const link = document.createElement('a');
                    link.href = url;
                    link.setAttribute('download', 'profit_loss_comparison.pdf');
                    document.body.appendChild(link);
                    link.click();
                    link.remove();
                    window.URL.revokeObjectURL(url);
                })
                .catch((error) => console.error('PDF download failed:', error));
        },
    },
};
</script>

<style scoped>
.bg-profit {
    background: linear-gradient(135deg, #4CAF50 0%, #2E7D32 100%);
}
.bg-loss {
    background: linear-gradient(135deg, #FF4560 0%, #C62828 100%);
}
.text-white-50 {
    color: rgba(255, 255, 255, 0.7);
}
.comparison-card-soft {
    border-radius: 10px;
    border: 1px solid rgba(128, 128, 128, 0.15);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
    transition: transform 0.2s, box-shadow 0.2s;
}
.comparison-card-soft:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
}
.card-value {
    color: inherit;
}
/* Positive card */
.card-positive {
    border-left: 4px solid #4CAF50;
    background-color: rgba(76, 175, 80, 0.08);
}
.badge-positive {
    background-color: rgba(76, 175, 80, 0.15);
    color: #4CAF50;
}
/* Negative card */
.card-negative {
    border-left: 4px solid #FF4560;
    background-color: rgba(255, 69, 96, 0.08);
}
.badge-negative {
    background-color: rgba(255, 69, 96, 0.15);
    color: #FF4560;
}
.gap-2 {
    gap: 0.5rem;
}
.page-heading {
    margin-bottom: 1.5rem;
}
.page-heading h3 {
    margin-bottom: 0;
}
.card-header h5 {
    font-size: 1rem;
    font-weight: 600;
}
.table th, .table td {
    padding: 0.5rem 0.75rem;
}
.section-title {
    font-weight: 600;
    color: #2E7D32;
}
.profit-note {
    background-color: rgba(76, 175, 80, 0.08);
    border: 1px solid rgba(76, 175, 80, 0.25);
    color: #33691E;
    font-size: 0.85rem;
    border-radius: 8px;
}
.card-headline {
    border-left-width: 5px;
    box-shadow: 0 3px 12px rgba(76, 175, 80, 0.18);
}
.card-headline .card-value {
    font-size: 1.6rem;
}
.stat-line + .stat-line {
    border-top: 1px solid rgba(128, 128, 128, 0.12);
}
</style>