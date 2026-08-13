<template>
    <div class="delivery-boy-analytics-container">
        <!-- Header -->
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h4 class="mb-0"><i class="fa fa-motorcycle text-primary me-2"></i>Delivery Boy Analytics</h4>
            <div class="d-flex gap-2">
                <button class="btn btn-sm btn-outline-success" @click="exportExcel">
                    <i class="fa fa-file-excel me-1"></i>Export Excel
                </button>
                <button class="btn btn-sm btn-outline-danger" @click="exportPdf">
                    <i class="fa fa-file-pdf me-1"></i>Export PDF
                </button>
            </div>
        </div>

        <!-- Filters -->
        <div class="card mb-4">
            <div class="card-body">
                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label fw-bold">Time Period</label>
                        <div class="btn-group w-100" role="group">
                            <button type="button" class="btn btn-sm" :class="filter === 'daily' ? 'btn-primary' : 'btn-outline-primary'" @click="setFilter('daily')">Daily</button>
                            <button type="button" class="btn btn-sm" :class="filter === 'weekly' ? 'btn-primary' : 'btn-outline-primary'" @click="setFilter('weekly')">Weekly</button>
                            <button type="button" class="btn btn-sm" :class="filter === 'monthly' ? 'btn-primary' : 'btn-outline-primary'" @click="setFilter('monthly')">Monthly</button>
                            <button type="button" class="btn btn-sm" :class="filter === 'custom' ? 'btn-primary' : 'btn-outline-primary'" @click="setFilter('custom')">Custom</button>
                        </div>
                    </div>
                    <div class="col-md-3" v-if="filter === 'custom'">
                        <label class="form-label fw-bold">Start Date</label>
                        <input type="date" class="form-control form-control-sm" v-model="startDate" />
                    </div>
                    <div class="col-md-3" v-if="filter === 'custom'">
                        <label class="form-label fw-bold">End Date</label>
                        <input type="date" class="form-control form-control-sm" v-model="endDate" />
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-bold">Zone</label>
                        <select class="form-select form-select-sm" v-model="selectedCityId" @change="fetchAnalytics">
                            <option value="">All Zones</option>
                            <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
                        </select>
                    </div>
                    <div class="col-md-3" v-if="filter === 'custom'">
                        <label class="form-label fw-bold">&nbsp;</label>
                        <button class="btn btn-sm btn-primary w-100" @click="fetchAnalytics">Apply</button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Loading State -->
        <div v-if="loading" class="text-center py-5">
            <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">Loading...</span>
            </div>
            <p class="mt-2 text-muted">Loading analytics data...</p>
        </div>

        <!-- Analytics Content -->
        <div v-else-if="analyticsData">
            <!-- Summary Cards -->
            <div class="row mb-4">
                <div class="col-md-3 mb-3">
                    <div class="card h-100 border-0 shadow-sm">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-start">
                                <div>
                                    <p class="text-muted mb-1 small">Total Delivery Boys</p>
                                    <h3 class="mb-0 fw-bold">{{ summary.total_delivery_boys }}</h3>
                                </div>
                                <div class="bg-primary bg-opacity-10 rounded p-2">
                                    <i class="fa fa-motorcycle text-primary fa-lg"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 mb-3">
                    <div class="card h-100 border-0 shadow-sm">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-start">
                                <div>
                                    <p class="text-muted mb-1 small">Active Delivery Boys</p>
                                    <h3 class="mb-0 fw-bold text-success">{{ summary.active_delivery_boys }}</h3>
                                </div>
                                <div class="bg-success bg-opacity-10 rounded p-2">
                                    <i class="fa fa-check-circle text-success fa-lg"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 mb-3">
                    <div class="card h-100 border-0 shadow-sm">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-start">
                                <div>
                                    <p class="text-muted mb-1 small">Total Deliveries</p>
                                    <h3 class="mb-0 fw-bold">{{ formatNumber(summary.total_deliveries) }}</h3>
                                </div>
                                <div class="bg-info bg-opacity-10 rounded p-2">
                                    <i class="fa fa-box text-info fa-lg"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 mb-3">
                    <div class="card h-100 border-0 shadow-sm">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-start">
                                <div>
                                    <p class="text-muted mb-1 small">Total Earnings</p>
                                    <h3 class="mb-0 fw-bold text-success">&#8377;{{ formatNumber(summary.total_earnings) }}</h3>
                                </div>
                                <div class="bg-success bg-opacity-10 rounded p-2">
                                    <i class="fa fa-rupee-sign text-success fa-lg"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Row 1: Deliveries Trend + Earnings Trend -->
            <div class="row mb-4">
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Deliveries Trend</h5></div>
                        <div class="card-body">
                            <apexchart
                                v-if="deliveriesTrend.values.length > 0"
                                type="line"
                                height="300"
                                :options="deliveriesTrendOptions"
                                :series="deliveriesTrendSeries"
                            ></apexchart>
                            <p v-else class="text-muted mt-5">No data</p>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Earnings Trend</h5></div>
                        <div class="card-body">
                            <apexchart
                                v-if="earningsTrend.values.length > 0"
                                type="area"
                                height="300"
                                :options="earningsTrendOptions"
                                :series="earningsTrendSeries"
                            ></apexchart>
                            <p v-else class="text-muted mt-5">No data</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Row 2: Activity + Status Distribution -->
            <div class="row mb-4">
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Delivery Boy Activity</h5></div>
                        <div class="card-body d-flex justify-content-center">
                            <apexchart
                                v-if="deliveryBoyActivity.values.length > 0"
                                type="donut"
                                height="320"
                                :options="deliveryBoyActivityOptions"
                                :series="deliveryBoyActivity.values"
                            ></apexchart>
                            <p v-else class="text-muted mt-5">No data</p>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Delivery Status Distribution</h5></div>
                        <div class="card-body d-flex justify-content-center">
                            <apexchart
                                v-if="statusDistribution.values.length > 0"
                                type="pie"
                                height="320"
                                :options="statusDistributionOptions"
                                :series="statusDistribution.values"
                            ></apexchart>
                            <p v-else class="text-muted mt-5">No data</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Row 3: Top Delivery Boys -->
            <div class="row mb-4">
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Top 10 by Deliveries</h5></div>
                        <div class="card-body">
                            <apexchart
                                v-if="topByDeliveries.length > 0"
                                type="bar"
                                height="350"
                                :options="topByDeliveriesOptions"
                                :series="topByDeliveriesSeries"
                            ></apexchart>
                            <p v-else class="text-muted mt-5">No data</p>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Top 10 by Earnings</h5></div>
                        <div class="card-body">
                            <apexchart
                                v-if="topByEarnings.length > 0"
                                type="bar"
                                height="350"
                                :options="topByEarningsOptions"
                                :series="topByEarningsSeries"
                            ></apexchart>
                            <p v-else class="text-muted mt-5">No data</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Row 4: Delivery Boys by Zone -->
            <div class="row mb-4">
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h5 class="mb-0">Delivery Boys by Zone</h5></div>
                        <div class="card-body d-flex justify-content-center">
                            <apexchart
                                v-if="deliveryBoysByZone.values.length > 0"
                                type="bar"
                                height="320"
                                :options="deliveryBoysByZoneOptions"
                                :series="deliveryBoysByZoneSeries"
                            ></apexchart>
                            <p v-else class="text-muted mt-5">No data</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Top Delivery Boys Table -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header"><h5 class="mb-0">Top Delivery Boys Details</h5></div>
                        <div class="card-body">
                            <table class="table table-hover table-sm">
                                <thead class="thead-light">
                                    <tr>
                                        <th>#</th>
                                        <th>Name</th>
                                        <th>Mobile</th>
                                        <th class="text-center">Deliveries</th>
                                        <th class="text-right">Earnings</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="(boy, index) in topByDeliveries" :key="boy.delivery_boy_id">
                                        <td>{{ index + 1 }}</td>
                                        <td>
                                            <router-link :to="'/delivery_boys/view/' + boy.delivery_boy_id" class="text-decoration-none">
                                                <span class="font-weight-bold">{{ boy.name }}</span>
                                            </router-link>
                                        </td>
                                        <td>{{ boy.mobile }}</td>
                                        <td class="text-center">{{ boy.delivery_count }}</td>
                                        <td class="text-right text-success font-weight-bold">&#8377;{{ formatNumber(boy.total_earnings) }}</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import axios from 'axios';
import VueApexCharts from 'vue-apexcharts';

export default {
    name: 'DeliveryBoyAnalytics',
    components: {
        apexchart: VueApexCharts,
    },
    data() {
        return {
            loading: false,
            filter: 'monthly',
            startDate: '',
            endDate: '',
            selectedCityId: '',
            cities: [],
            analyticsData: null,
            chartColors: ['#9AC444', '#008FFB', '#FEB019', '#FF4560', '#775DD0', '#00E396'],
        };
    },
    mounted() {
        this.fetchCities();
        this.fetchAnalytics();
    },
    computed: {
        summary() {
            return this.analyticsData?.summary || {};
        },
        deliveriesTrend() {
            return this.analyticsData?.deliveries_trend || { labels: [], values: [] };
        },
        earningsTrend() {
            return this.analyticsData?.earnings_trend || { labels: [], values: [] };
        },
        topByDeliveries() {
            return this.analyticsData?.top_by_deliveries || [];
        },
        topByEarnings() {
            return this.analyticsData?.top_by_earnings || [];
        },
        deliveryBoysByZone() {
            return this.analyticsData?.delivery_boys_by_zone || { labels: [], values: [] };
        },
        deliveryBoyActivity() {
            return this.analyticsData?.delivery_boy_activity || { labels: [], values: [] };
        },
        statusDistribution() {
            return this.analyticsData?.status_distribution || { labels: [], values: [] };
        },

        // Chart Options
        deliveriesTrendOptions() {
            return {
                chart: { type: 'line', toolbar: { show: false } },
                stroke: { curve: 'smooth', width: 3 },
                colors: ['#008FFB'],
                xaxis: { categories: this.deliveriesTrend.labels },
                dataLabels: { enabled: false },
            };
        },
        deliveriesTrendSeries() {
            return [{ name: 'Deliveries', data: this.deliveriesTrend.values }];
        },
        earningsTrendOptions() {
            return {
                chart: { type: 'area', toolbar: { show: false } },
                dataLabels: { enabled: false },
                stroke: { curve: 'smooth', width: 2 },
                colors: ['#9AC444'],
                xaxis: { categories: this.earningsTrend.labels },
                yaxis: { labels: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
                fill: { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: 0.7, opacityTo: 0.3 } },
            };
        },
        earningsTrendSeries() {
            return [{ name: 'Earnings', data: this.earningsTrend.values }];
        },
        deliveryBoyActivityOptions() {
            return {
                chart: { type: 'donut' },
                labels: this.deliveryBoyActivity.labels,
                colors: ['#9AC444', '#FF4560'],
                legend: { position: 'bottom' },
            };
        },
        statusDistributionOptions() {
            return {
                chart: { type: 'pie' },
                labels: this.statusDistribution.labels,
                colors: this.chartColors,
                legend: { position: 'bottom' },
            };
        },
        topByDeliveriesOptions() {
            const names = this.topByDeliveries.map(b => {
                const name = b.name || 'Unknown';
                return name.length > 20 ? name.substring(0, 20) + '...' : name;
            });
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                plotOptions: { bar: { horizontal: true, borderRadius: 4, barHeight: '60%' } },
                colors: ['#008FFB'],
                xaxis: { categories: names },
                dataLabels: { enabled: true },
            };
        },
        topByDeliveriesSeries() {
            return [{ name: 'Deliveries', data: this.topByDeliveries.map(b => b.delivery_count) }];
        },
        topByEarningsOptions() {
            const names = this.topByEarnings.map(b => {
                const name = b.name || 'Unknown';
                return name.length > 20 ? name.substring(0, 20) + '...' : name;
            });
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                plotOptions: { bar: { horizontal: true, borderRadius: 4, barHeight: '60%' } },
                colors: ['#9AC444'],
                xaxis: {
                    categories: names,
                    labels: { formatter: (v) => '\u20B9' + this.formatNumber(v) },
                },
                dataLabels: { enabled: true, formatter: (v) => '\u20B9' + this.formatNumber(v) },
            };
        },
        topByEarningsSeries() {
            return [{ name: 'Earnings', data: this.topByEarnings.map(b => b.total_earnings) }];
        },
        deliveryBoysByZoneOptions() {
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                plotOptions: { bar: { borderRadius: 4, columnWidth: '50%' } },
                colors: ['#775DD0'],
                xaxis: { categories: this.deliveryBoysByZone.labels },
                dataLabels: { enabled: true },
            };
        },
        deliveryBoysByZoneSeries() {
            return [{ name: 'Delivery Boys', data: this.deliveryBoysByZone.values }];
        },
    },
    methods: {
        setFilter(f) {
            this.filter = f;
            if (f !== 'custom') {
                this.fetchAnalytics();
            }
        },
        async fetchCities() {
            try {
                const response = await axios.get('/api/cities');
                this.cities = response.data.data || [];
            } catch (error) {
                console.error('Error fetching cities:', error);
            }
        },
        async fetchAnalytics() {
            this.loading = true;
            try {
                const params = {
                    filter: this.filter,
                };
                if (this.filter === 'custom') {
                    params.start_date = this.startDate;
                    params.end_date = this.endDate;
                }
                if (this.selectedCityId) {
                    params.city_id = this.selectedCityId;
                }

                const response = await axios.get('/api/delivery-boy-analytics', { params });
                this.analyticsData = response.data.data;
            } catch (error) {
                console.error('Error fetching analytics:', error);
                this.$toast.error('Failed to load analytics data');
            } finally {
                this.loading = false;
            }
        },
        async exportExcel() {
            this.$toast.info('Excel export feature coming soon!');
        },
        async exportPdf() {
            this.$toast.info('PDF export feature coming soon!');
        },
        formatNumber(num) {
            if (num === null || num === undefined) return '0';
            return parseFloat(num).toLocaleString('en-IN', { maximumFractionDigits: 2 });
        },
    },
};
</script>

<style scoped>
.delivery-boy-analytics-container {
    padding: 20px;
}
.card {
    border-radius: 8px;
}
.card-header {
    background-color: #f8f9fa;
    border-bottom: 1px solid #dee2e6;
    padding: 12px 16px;
}
.card-header h5 {
    font-size: 1rem;
    font-weight: 600;
}
.table th, .table td {
    padding: 0.5rem 0.75rem;
}
</style>
