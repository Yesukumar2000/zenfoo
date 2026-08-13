<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>User Analytics</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">Dashboard</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                User Analytics
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
                    <!-- Date Range for Custom -->
                    <div v-if="filter === 'custom'" class="d-flex align-items-center">
                        <input type="date" class="form-control form-control-sm mr-1" v-model="customStart" />
                        <span class="mx-1">to</span>
                        <input type="date" class="form-control form-control-sm ml-1" v-model="customEnd" />
                        <button class="btn btn-sm btn-success ml-2" @click="fetchAnalytics">Apply</button>
                    </div>
                    <!-- Export Dropdown -->
                    <b-dropdown v-if="analyticsData" size="sm" variant="outline-success" right>
                        <template #button-content>
                            <i class="fa fa-download mr-1"></i> Export
                        </template>
                        <b-dropdown-header>Excel Download</b-dropdown-header>
                        <b-dropdown-item @click="downloadExcel('all')">All Data</b-dropdown-item>
                        <b-dropdown-item @click="downloadExcel('summary')">Summary</b-dropdown-item>
                        <b-dropdown-item @click="downloadExcel('top-customers')">Top Customers</b-dropdown-item>
                        <b-dropdown-item @click="downloadExcel('new-customers')">New Customers</b-dropdown-item>
                        <b-dropdown-divider></b-dropdown-divider>
                        <b-dropdown-header>PDF Download</b-dropdown-header>
                        <b-dropdown-item @click="downloadPdf('all')">Full Report</b-dropdown-item>
                        <b-dropdown-item @click="downloadPdf('summary')">Summary Report</b-dropdown-item>
                    </b-dropdown>
                </div>
            </div>
        </div>

        <div class="page-content">
            <!-- Loading -->
            <div v-if="loading" class="text-center py-5">
                <b-spinner variant="success" label="Loading..."></b-spinner>
                <p class="mt-2">Loading analytics...</p>
            </div>

            <template v-else-if="analyticsData">
                <!-- Row 1: Summary Cards -->
                <div class="row mb-4">
                    <div class="col-6 col-lg-3 col-md-4 mb-3" v-for="card in summaryCards" :key="card.label">
                        <div class="card h-100 summary-card" :style="{ borderLeft: '4px solid ' + card.color }">
                            <div class="card-body py-3">
                                <div class="d-flex flex-column">
                                    <span class="text-muted small text-uppercase">{{ card.label }}</span>
                                    <h4 class="mb-0 mt-1 font-weight-bold">{{ card.prefix }}{{ formatNumber(card.value) }}{{ card.suffix }}</h4>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 2: Registrations Trend + User Activity -->
                <div class="row mb-4">
                    <div class="col-12 col-lg-6 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">User Registrations Over Time</h5></div>
                            <div class="card-body">
                                <apexchart
                                    type="bar"
                                    height="320"
                                    :options="registrationsTrendOptions"
                                    :series="registrationsTrendSeries"
                                ></apexchart>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-lg-6 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Active vs Inactive Users</h5></div>
                            <div class="card-body d-flex justify-content-center">
                                <apexchart
                                    v-if="userActivity.values.some(v => v > 0)"
                                    type="donut"
                                    height="320"
                                    :options="userActivityOptions"
                                    :series="userActivity.values"
                                ></apexchart>
                                <p v-else class="text-muted mt-5">No data</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 3: User Segmentation + Registration Sources -->
                <!-- <div class="row mb-4">
                    <div class="col-12 col-lg-6 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">User Segmentation by Orders</h5></div>
                            <div class="card-body d-flex justify-content-center">
                                <apexchart
                                    v-if="userSegmentation.values.length > 0"
                                    type="pie"
                                    height="320"
                                    :options="userSegmentationOptions"
                                    :series="userSegmentation.values"
                                ></apexchart>
                                <p v-else class="text-muted mt-5">No data</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-lg-6 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Registration Sources</h5></div>
                            <div class="card-body d-flex justify-content-center">
                                <apexchart
                                    v-if="registrationSources.values.length > 0"
                                    type="donut"
                                    height="320"
                                    :options="registrationSourcesOptions"
                                    :series="registrationSources.values"
                                ></apexchart>
                                <p v-else class="text-muted mt-5">No data</p>
                            </div>
                        </div>
                    </div>
                </div> -->

                <!-- Row 4: Top Customers -->
                <div class="row mb-4">
                    <div class="col-12 col-lg-6 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Top 10 Customers by Revenue</h5></div>
                            <div class="card-body">
                                <apexchart
                                    v-if="topCustomers.by_revenue && topCustomers.by_revenue.length > 0"
                                    type="bar"
                                    height="320"
                                    :options="topCustomersByRevenueOptions"
                                    :series="topCustomersByRevenueSeries"
                                ></apexchart>
                                <p v-else class="text-muted text-center mt-5">No data</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-lg-6 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Top 10 Customers by Orders</h5></div>
                            <div class="card-body">
                                <apexchart
                                    v-if="topCustomers.by_orders && topCustomers.by_orders.length > 0"
                                    type="bar"
                                    height="320"
                                    :options="topCustomersByOrdersOptions"
                                    :series="topCustomersByOrdersSeries"
                                ></apexchart>
                                <p v-else class="text-muted text-center mt-5">No data</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 5: Users by Zone + Customer Behavior -->
                <div class="row mb-4">
                    <div class="col-12 col-lg-6 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Users by Zone</h5></div>
                            <div class="card-body">
                                <apexchart
                                    v-if="usersByZone.values.length > 0"
                                    type="bar"
                                    height="320"
                                    :options="usersByZoneOptions"
                                    :series="usersByZoneSeries"
                                ></apexchart>
                                <p v-else class="text-muted text-center mt-5">No data</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-lg-6 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Payment Method Preferences</h5></div>
                            <div class="card-body d-flex justify-content-center">
                                <apexchart
                                    v-if="customerBehavior.payment_methods.values.length > 0"
                                    type="pie"
                                    height="320"
                                    :options="paymentMethodsOptions"
                                    :series="customerBehavior.payment_methods.values"
                                ></apexchart>
                                <p v-else class="text-muted mt-5">No data</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 6: Delivery Type Preferences + Retention Metrics -->
                <div class="row mb-4">
                    <!-- <div class="col-12 col-lg-4 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Delivery Type Preferences</h5></div>
                            <div class="card-body d-flex justify-content-center">
                                <apexchart
                                    v-if="customerBehavior.delivery_types.values.length > 0"
                                    type="donut"
                                    height="280"
                                    :options="deliveryTypesOptions"
                                    :series="customerBehavior.delivery_types.values"
                                ></apexchart>
                                <p v-else class="text-muted mt-5">No data</p>
                            </div>
                        </div>
                    </div> -->
                    <div class="col-12 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Retention & Behavior Metrics</h5></div>
                            <div class="card-body">
                                <table class="table table-bordered table-sm">
                                    <thead class="thead-light">
                                        <tr>
                                            <th>Metric</th>
                                            <th class="text-right">Value</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr>
                                            <td>Retention Rate</td>
                                            <td class="text-right font-weight-bold text-success">{{ retentionMetrics.retention_rate }}%</td>
                                        </tr>
                                        <tr>
                                            <td>Repeat Customers</td>
                                            <td class="text-right font-weight-bold">{{ retentionMetrics.repeat_customers }}</td>
                                        </tr>
                                        <!-- <tr>
                                            <td>Avg Days Between Orders</td>
                                            <td class="text-right font-weight-bold">{{ retentionMetrics.avg_days_between_orders }} days</td>
                                        </tr> -->
                                        <tr>
                                            <td>Promo Code Usage Rate</td>
                                            <td class="text-right font-weight-bold">{{ customerBehavior.promo_usage_rate }}%</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 7: Top Customers Table -->
                <div class="row mb-4" v-if="topCustomers.by_revenue && topCustomers.by_revenue.length > 0">
                    <div class="col-12 mb-3">
                        <div class="card">
                            <div class="card-header"><h5 class="mb-0">Top Customers Details</h5></div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-bordered table-sm table-hover">
                                        <thead class="thead-light">
                                            <tr>
                                                <th>#</th>
                                                <th>Customer Name</th>
                                                <th>Mobile</th>
                                                <th class="text-center">Total Orders</th>
                                                <th class="text-right">Total Spent</th>
                                                <th class="text-right">Avg Order Value</th>
                                                <th>First Order</th>
                                                <th>Last Order</th>
                                                <th class="text-center">Days Since Last Order</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="(customer, index) in topCustomers.by_revenue" :key="customer.user_id">
                                                <td>{{ index + 1 }}</td>
                                                <td>
                                                    <router-link :to="'/users/view/' + customer.user_id" class="text-decoration-none">
                                                        <span class="font-weight-bold">{{ customer.name || customer.mobile }}</span>
                                                    </router-link>
                                                </td>
                                                <td>{{ customer.mobile }}</td>
                                                <td class="text-center font-weight-bold">{{ customer.order_count }}</td>
                                                <td class="text-right text-success font-weight-bold">&#8377;{{ formatNumber(customer.total_spent) }}</td>
                                                <td class="text-right">&#8377;{{ formatNumber(customer.avg_order_value) }}</td>
                                                <td>{{ customer.first_order_date }}</td>
                                                <td>{{ customer.last_order_date }}</td>
                                                <td class="text-center">{{ customer.days_since_last_order }}</td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 8: New Customers Table -->
                <div class="row mb-4" v-if="newCustomers && newCustomers.length > 0">
                    <div class="col-12 mb-3">
                        <div class="card">
                            <div class="card-header"><h5 class="mb-0">New Customers in Period</h5></div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-bordered table-sm table-hover">
                                        <thead class="thead-light">
                                            <tr>
                                                <th>#</th>
                                                <th>Customer Name</th>
                                                <th>Mobile</th>
                                                <th>Email</th>
                                                <th>Registered Date</th>
                                                <th>First Order Date</th>
                                                <th class="text-center">Total Orders</th>
                                                <th class="text-right">Total Spent</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="(customer, index) in newCustomers" :key="customer.user_id">
                                                <td>{{ index + 1 }}</td>
                                                <td>
                                                    <router-link :to="'/users/view/' + customer.user_id" class="text-decoration-none">
                                                        <span class="font-weight-bold">{{ customer.name || customer.mobile }}</span>
                                                    </router-link>
                                                </td>
                                                <td>{{ customer.mobile }}</td>
                                                <td>{{ customer.email || '-' }}</td>
                                                <td>{{ customer.registered_date }}</td>
                                                <td>{{ customer.first_order_date }}</td>
                                                <td class="text-center">{{ customer.total_orders }}</td>
                                                <td class="text-right text-success font-weight-bold">&#8377;{{ formatNumber(customer.total_spent) }}</td>
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
    </div>
</template>

<script>
import VueApexCharts from 'vue-apexcharts';
import axios from 'axios';

export default {
    name: "UserAnalytics",
    components: {
        apexchart: VueApexCharts,
    },
    data() {
        return {
            loading: false,
            filter: 'daily',
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
        registrationsTrend() {
            return this.analyticsData?.registrations_trend || { labels: [], values: [] };
        },
        userActivity() {
            return this.analyticsData?.user_activity || { labels: [], values: [] };
        },
        // userSegmentation() {
        //     return this.analyticsData?.user_segmentation || { labels: [], values: [] };
        // },
        // registrationSources() {
        //     return this.analyticsData?.registration_sources || { labels: [], values: [] };
        // },
        topCustomers() {
            return this.analyticsData?.top_customers || { by_revenue: [], by_orders: [] };
        },
        usersByZone() {
            return this.analyticsData?.users_by_zone || { labels: [], values: [] };
        },
        customerBehavior() {
            return this.analyticsData?.customer_behavior || {
                payment_methods: { labels: [], values: [] },
                delivery_types: { labels: [], values: [] },
                promo_usage_rate: 0,
            };
        },
        newCustomers() {
            return this.analyticsData?.new_customers || [];
        },
        retentionMetrics() {
            return this.analyticsData?.retention_metrics || {
                retention_rate: 0,
                repeat_customers: 0,
                total_active_users: 0,
                avg_days_between_orders: 0,
            };
        },

        // Summary cards
        summaryCards() {
            const s = this.summary;
            const r = this.retentionMetrics;
            return [
                { label: 'Total Users', value: s.total_users, prefix: '', suffix: '', color: '#008FFB' },
                { label: 'New Registrations', value: s.new_registrations, prefix: '', suffix: '', color: '#9AC444' },
                { label: 'Active Users', value: s.active_users, prefix: '', suffix: '', color: '#00E396' },
                { label: 'Inactive Users', value: s.inactive_users, prefix: '', suffix: '', color: '#FF4560' },
                { label: 'Avg Orders/User', value: s.avg_orders_per_user, prefix: '', suffix: '', color: '#FEB019' },
                // { label: 'Avg Revenue/User', value: s.avg_revenue_per_user, prefix: '\u20B9', suffix: '', color: '#775DD0' },
                { label: 'Retention Rate', value: r.retention_rate, prefix: '', suffix: '%', color: '#9AC444' },
            ];
        },

        // Registrations Trend Chart
        registrationsTrendOptions() {
            return {
                chart: { type: 'bar', toolbar: { show: true } },
                colors: ['#9AC444'],
                xaxis: { categories: this.registrationsTrend.labels },
                yaxis: { title: { text: 'Registrations' } },
                dataLabels: { enabled: true },
                plotOptions: { bar: { borderRadius: 4, columnWidth: '50%' } },
            };
        },
        registrationsTrendSeries() {
            return [{ name: 'Registrations', data: this.registrationsTrend.values }];
        },

        // User Activity Donut
        userActivityOptions() {
            return {
                chart: { type: 'donut' },
                labels: this.userActivity.labels,
                colors: ['#9AC444', '#FF4560'],
                legend: { position: 'bottom' },
            };
        },

        // User Segmentation Pie
        // userSegmentationOptions() {
        //     return {
        //         chart: { type: 'pie' },
        //         labels: this.userSegmentation.labels,
        //         colors: this.chartColors,
        //         legend: { position: 'bottom' },
        //     };
        // },

        // Registration Sources Donut
        // registrationSourcesOptions() {
        //     return {
        //         chart: { type: 'donut' },
        //         labels: this.registrationSources.labels,
        //         colors: ['#008FFB', '#FEB019', '#546E7A'],
        //         legend: { position: 'bottom' },
        //     };
        // },

        // Top Customers by Revenue
        topCustomersByRevenueOptions() {
            const names = this.topCustomers.by_revenue.map(c => {
                const name = c.name || c.mobile || 'Unknown';
                return name.length > 15 ? name.substring(0, 15) + '...' : name;
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
                tooltip: { y: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
            };
        },
        topCustomersByRevenueSeries() {
            return [{ name: 'Total Spent', data: this.topCustomers.by_revenue.map(c => c.total_spent) }];
        },

        // Top Customers by Orders
        topCustomersByOrdersOptions() {
            const names = this.topCustomers.by_orders.map(c => {
                const name = c.name || c.mobile || 'Unknown';
                return name.length > 15 ? name.substring(0, 15) + '...' : name;
            });
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                plotOptions: { bar: { horizontal: true, borderRadius: 4, barHeight: '60%' } },
                colors: ['#008FFB'],
                xaxis: { categories: names },
                dataLabels: { enabled: true },
            };
        },
        topCustomersByOrdersSeries() {
            return [{ name: 'Order Count', data: this.topCustomers.by_orders.map(c => c.order_count) }];
        },

        // Users by Zone
        usersByZoneOptions() {
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                colors: ['#775DD0'],
                plotOptions: { bar: { borderRadius: 4, columnWidth: '60%' } },
                xaxis: { categories: this.usersByZone.labels },
                yaxis: { title: { text: 'Users' } },
                dataLabels: { enabled: true },
            };
        },
        usersByZoneSeries() {
            return [{ name: 'User Count', data: this.usersByZone.values }];
        },

        // Payment Methods Pie
        paymentMethodsOptions() {
            return {
                chart: { type: 'pie' },
                labels: this.customerBehavior.payment_methods.labels,
                colors: this.chartColors,
                legend: { position: 'bottom' },
            };
        },

        // Delivery Types Donut
        // deliveryTypesOptions() {
        //     return {
        //         chart: { type: 'donut' },
        //         labels: this.customerBehavior.delivery_types.labels,
        //         colors: ['#9AC444', '#008FFB'],
        //         legend: { position: 'bottom' },
        //     };
        // },
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
            axios.get(this.$apiUrl + '/user-analytics', { params })
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
            axios.get(this.$apiUrl + '/user-analytics/export-excel', { params, responseType: 'blob' })
                .then((response) => {
                    const url = window.URL.createObjectURL(new Blob([response.data]));
                    const link = document.createElement('a');
                    link.href = url;
                    link.setAttribute('download', 'user_analytics_' + section + '.xlsx');
                    document.body.appendChild(link);
                    link.click();
                    link.remove();
                    window.URL.revokeObjectURL(url);
                })
                .catch((error) => console.error('Excel download failed:', error));
        },
        downloadPdf(section) {
            const params = this.getExportParams(section);
            axios.get(this.$apiUrl + '/user-analytics/export-pdf', { params, responseType: 'blob' })
                .then((response) => {
                    const url = window.URL.createObjectURL(new Blob([response.data], { type: 'application/pdf' }));
                    const link = document.createElement('a');
                    link.href = url;
                    link.setAttribute('download', 'user_analytics_' + section + '.pdf');
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
</style>
