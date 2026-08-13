<template>
    <div>
        <!-- Filters -->
        <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap">
            <h5 class="mb-0">Performance Analytics</h5>
            <div class="d-flex align-items-center gap-2 flex-wrap">
                <div class="btn-group">
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
                <div v-if="filter === 'custom'" class="d-flex align-items-center">
                    <input type="date" class="form-control form-control-sm mr-1" v-model="customStart" />
                    <span class="mx-1">to</span>
                    <input type="date" class="form-control form-control-sm ml-1" v-model="customEnd" />
                    <button class="btn btn-sm btn-success ml-2" @click="fetchAnalytics">Apply</button>
                </div>
            </div>
        </div>

        <!-- Loading -->
        <div v-if="loading" class="text-center py-5">
            <b-spinner variant="success"></b-spinner>
            <p class="mt-2">Loading analytics...</p>
        </div>

        <template v-else-if="analyticsData">
            <!-- Summary Cards -->
            <div class="row mb-4">
                <div class="col-6 col-lg-3 col-md-4 mb-3" v-for="card in summaryCards" :key="card.label">
                    <div class="card h-100 summary-card" :style="{ borderLeft: '4px solid ' + card.color }">
                        <div class="card-body py-3">
                            <span class="text-muted small text-uppercase">{{ card.label }}</span>
                            <h4 class="mb-0 mt-1 font-weight-bold">{{ card.prefix }}{{ formatNumber(card.value) }}{{ card.suffix }}</h4>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Deliveries & Earnings Trends -->
            <div class="row mb-4">
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h6 class="mb-0">Deliveries Over Time</h6></div>
                        <div class="card-body">
                            <apexchart
                                type="bar"
                                height="280"
                                :options="deliveriesOverTimeOptions"
                                :series="deliveriesOverTimeSeries"
                            ></apexchart>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h6 class="mb-0">Earnings Over Time</h6></div>
                        <div class="card-body">
                            <apexchart
                                type="area"
                                height="280"
                                :options="earningsOverTimeOptions"
                                :series="earningsOverTimeSeries"
                            ></apexchart>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Status & Earnings Breakdown -->
            <div class="row mb-4">
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h6 class="mb-0">Delivery Status</h6></div>
                        <div class="card-body d-flex justify-content-center">
                            <apexchart
                                v-if="statusBreakdown.values.length > 0"
                                type="donut"
                                height="280"
                                :options="statusBreakdownOptions"
                                :series="statusBreakdown.values"
                            ></apexchart>
                            <p v-else class="text-muted mt-5">No data</p>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h6 class="mb-0">Earnings Breakdown</h6></div>
                        <div class="card-body d-flex justify-content-center">
                            <apexchart
                                v-if="earningsBreakdown.values.some(v => v > 0)"
                                type="pie"
                                height="280"
                                :options="earningsBreakdownOptions"
                                :series="earningsBreakdown.values"
                            ></apexchart>
                            <p v-else class="text-muted mt-5">No data</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Peak Hours & Zone Distribution -->
            <div class="row mb-4">
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h6 class="mb-0">Peak Hours Analysis</h6></div>
                        <div class="card-body">
                            <apexchart
                                type="bar"
                                height="320"
                                :options="peakHoursOptions"
                                :series="peakHoursSeries"
                            ></apexchart>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h6 class="mb-0">Deliveries by Zone</h6></div>
                        <div class="card-body">
                            <apexchart
                                v-if="zoneDistribution.values.length > 0"
                                type="bar"
                                height="320"
                                :options="zoneDistributionOptions"
                                :series="zoneDistributionSeries"
                            ></apexchart>
                            <p v-else class="text-muted text-center mt-5">No data</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Performance Comparison -->
            <div class="row mb-4" v-if="performanceComparison">
                <div class="col-12 mb-3">
                    <div class="card">
                        <div class="card-header"><h6 class="mb-0">Performance Comparison</h6></div>
                        <div class="card-body">
                            <p class="text-muted small">{{ performanceComparison.current_period }} vs {{ performanceComparison.previous_period }}</p>
                            <div class="row">
                                <div class="col-md-4 mb-2" v-for="(metric, key) in performanceComparison.metrics" :key="key">
                                    <div class="p-3 rounded" :class="metric.is_positive ? 'bg-light-success' : 'bg-light-danger'">
                                        <small class="text-muted text-uppercase">{{ getMetricLabel(key) }}</small>
                                        <h5 class="mb-0 mt-1" :class="metric.is_positive ? 'text-success' : 'text-danger'">
                                            {{ metric.is_positive ? '+' : '' }}{{ metric.change_percent }}%
                                        </h5>
                                        <small>
                                            {{ formatNumber(metric.current) }} <span class="text-muted">vs</span> {{ formatNumber(metric.previous) }}
                                        </small>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Recent Deliveries Table -->
            <div class="row mb-4" v-if="recentDeliveries && recentDeliveries.length > 0">
                <div class="col-12 mb-3">
                    <div class="card">
                        <div class="card-header"><h6 class="mb-0">Recent Deliveries</h6></div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-bordered table-sm table-hover">
                                    <thead class="thead-light">
                                        <tr>
                                            <th>Order ID</th>
                                            <th>Customer</th>
                                            <th>Zone</th>
                                            <th class="text-right">Earnings</th>
                                            <th class="text-right">Tip</th>
                                            <th>Status</th>
                                            <th class="text-center">Rating</th>
                                            <th>Date</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="delivery in recentDeliveries" :key="delivery.order_id">
                                            <td>
                                                <router-link :to="'/orders/view/' + delivery.order_id" class="text-decoration-none">
                                                    #{{ delivery.unique_order_id }}
                                                </router-link>
                                            </td>
                                            <td>{{ delivery.customer_name }}</td>
                                            <td>{{ delivery.zone }}</td>
                                            <td class="text-right font-weight-bold text-success">&#8377;{{ formatNumber(delivery.earnings) }}</td>
                                            <td class="text-right">&#8377;{{ formatNumber(delivery.tip) }}</td>
                                            <td><span class="badge badge-info">{{ delivery.status }}</span></td>
                                            <td class="text-center">
                                                <span v-if="delivery.rating !== '-'" class="badge badge-warning">{{ delivery.rating }}/5</span>
                                                <span v-else>-</span>
                                            </td>
                                            <td>{{ delivery.created_at }}</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </template>
    </div>
</template>

<script>
import VueApexCharts from 'vue-apexcharts';
import axios from 'axios';

export default {
    name: 'DeliveryBoyAnalytics',
    components: {
        apexchart: VueApexCharts,
    },
    props: {
        deliveryBoyId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            loading: false,
            filter: 'monthly',
            customStart: '',
            customEnd: '',
            analyticsData: null,
            filterOptions: [
                { label: 'Today', value: 'daily' },
                { label: 'This Week', value: 'weekly' },
                { label: 'This Month', value: 'monthly' },
                { label: 'Custom', value: 'custom' },
            ],
            chartColors: ['#9AC444', '#008FFB', '#FEB019', '#FF4560', '#775DD0', '#00E396'],
        };
    },
    created() {
        this.fetchAnalytics();
    },
    computed: {
        summary() {
            return this.analyticsData?.summary || {};
        },
        deliveriesOverTime() {
            return this.analyticsData?.deliveries_over_time || { labels: [], values: [] };
        },
        earningsOverTime() {
            return this.analyticsData?.earnings_over_time || { labels: [], base_earnings: [], tips: [], total_earnings: [] };
        },
        statusBreakdown() {
            return this.analyticsData?.status_breakdown || { labels: [], values: [] };
        },
        earningsBreakdown() {
            return this.analyticsData?.earnings_breakdown || { labels: [], values: [] };
        },
        peakHours() {
            return this.analyticsData?.peak_hours || { labels: [], values: [] };
        },
        zoneDistribution() {
            return this.analyticsData?.zone_distribution || { labels: [], values: [] };
        },
        performanceComparison() {
            return this.analyticsData?.performance_comparison || null;
        },
        recentDeliveries() {
            return this.analyticsData?.recent_deliveries || [];
        },

        summaryCards() {
            const s = this.summary;
            return [
                { label: 'Total Deliveries', value: s.total_deliveries, prefix: '', suffix: '', color: '#008FFB' },
                { label: 'Completed', value: s.completed_deliveries, prefix: '', suffix: '', color: '#9AC444' },
                { label: 'Cancelled', value: s.cancelled_deliveries, prefix: '', suffix: '', color: '#FF4560' },
                { label: 'Total Earnings', value: s.combined_earnings, prefix: '\u20B9', suffix: '', color: '#775DD0' },
                { label: 'Avg Rating', value: s.avg_rating, prefix: '', suffix: '/5', color: '#FEB019' },
                { label: 'On-Time Rate', value: s.on_time_rate, prefix: '', suffix: '%', color: '#00E396' },
            ];
        },

        deliveriesOverTimeOptions() {
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                colors: ['#9AC444'],
                xaxis: { categories: this.deliveriesOverTime.labels },
                yaxis: { title: { text: 'Deliveries' } },
                dataLabels: { enabled: true },
                plotOptions: { bar: { borderRadius: 4, columnWidth: '60%' } },
            };
        },
        deliveriesOverTimeSeries() {
            return [{ name: 'Deliveries', data: this.deliveriesOverTime.values }];
        },

        earningsOverTimeOptions() {
            return {
                chart: { type: 'area', stacked: true, toolbar: { show: false } },
                colors: ['#9AC444', '#008FFB', '#FEB019'],
                xaxis: { categories: this.earningsOverTime.labels },
                yaxis: { title: { text: 'Earnings' }, labels: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
                dataLabels: { enabled: false },
                stroke: { curve: 'smooth', width: 2 },
                fill: { type: 'gradient' },
                tooltip: { y: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
            };
        },
        earningsOverTimeSeries() {
            return [
                { name: 'Base Pay', data: this.earningsOverTime.base_earnings },
                { name: 'Tips', data: this.earningsOverTime.tips },
            ];
        },

        statusBreakdownOptions() {
            return {
                chart: { type: 'donut' },
                labels: this.statusBreakdown.labels,
                colors: ['#9AC444', '#FF4560', '#FEB019'],
                legend: { position: 'bottom' },
            };
        },

        earningsBreakdownOptions() {
            return {
                chart: { type: 'pie' },
                labels: this.earningsBreakdown.labels,
                colors: this.chartColors,
                legend: { position: 'bottom' },
            };
        },

        peakHoursOptions() {
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                colors: ['#008FFB'],
                xaxis: { categories: this.peakHours.labels, labels: { rotate: -45 } },
                yaxis: { title: { text: 'Deliveries' } },
                dataLabels: { enabled: false },
                plotOptions: { bar: { borderRadius: 2, columnWidth: '80%' } },
            };
        },
        peakHoursSeries() {
            return [{ name: 'Deliveries', data: this.peakHours.values }];
        },

        zoneDistributionOptions() {
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                colors: ['#775DD0'],
                plotOptions: { bar: { horizontal: true, borderRadius: 4 } },
                xaxis: { categories: this.zoneDistribution.labels },
                dataLabels: { enabled: true },
            };
        },
        zoneDistributionSeries() {
            return [{ name: 'Deliveries', data: this.zoneDistribution.values }];
        },
    },
    methods: {
        setFilter(f) {
            this.filter = f;
            if (f !== 'custom') {
                this.fetchAnalytics();
            }
        },
        fetchAnalytics() {
            this.loading = true;
            let params = { filter: this.filter };
            if (this.filter === 'custom') {
                params.start_date = this.customStart;
                params.end_date = this.customEnd;
            }
            axios.get(this.$apiUrl + '/delivery_boys/' + this.deliveryBoyId + '/analytics', { params })
                .then((response) => {
                    if (response.data.status === 1) {
                        this.analyticsData = response.data.data;
                    }
                })
                .catch((error) => {
                    console.error('Error fetching analytics:', error);
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
        getMetricLabel(key) {
            const labels = {
                deliveries: 'Deliveries',
                earnings: 'Earnings',
                avg_rating: 'Avg Rating',
            };
            return labels[key] || key;
        },
    },
};
</script>

<style scoped>
.summary-card {
    transition: transform 0.2s, box-shadow 0.2s;
}
.summary-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}
.gap-2 {
    gap: 0.5rem;
}
.bg-light-success {
    background-color: #d4edda;
}
.bg-light-danger {
    background-color: #f8d7da;
}
</style>
