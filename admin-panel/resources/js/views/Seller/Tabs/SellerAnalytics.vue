<template>
    <div>
        <!-- Filters -->
        <div class="d-flex justify-content-between align-items-center mb-3 flex-wrap">
            <h5 class="mb-0">Analytics</h5>
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

            <!-- Orders & Revenue Trends -->
            <div class="row mb-4">
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h6 class="mb-0">Orders Over Time</h6></div>
                        <div class="card-body">
                            <apexchart
                                type="bar"
                                height="280"
                                :options="ordersOverTimeOptions"
                                :series="ordersOverTimeSeries"
                            ></apexchart>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h6 class="mb-0">Revenue Over Time</h6></div>
                        <div class="card-body">
                            <apexchart
                                type="area"
                                height="280"
                                :options="revenueOverTimeOptions"
                                :series="revenueOverTimeSeries"
                            ></apexchart>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Status & Payment -->
            <div class="row mb-4">
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h6 class="mb-0">Order Status Breakdown</h6></div>
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
                        <div class="card-header"><h6 class="mb-0">Payment Methods</h6></div>
                        <div class="card-body d-flex justify-content-center">
                            <apexchart
                                v-if="paymentMethods.values.length > 0"
                                type="pie"
                                height="280"
                                :options="paymentMethodsOptions"
                                :series="paymentMethods.values"
                            ></apexchart>
                            <p v-else class="text-muted mt-5">No data</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Top Products -->
            <div class="row mb-4">
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h6 class="mb-0">Top 10 Products by Orders</h6></div>
                        <div class="card-body">
                            <apexchart
                                v-if="topProducts.by_orders && topProducts.by_orders.length > 0"
                                type="bar"
                                height="320"
                                :options="topProductsByOrdersOptions"
                                :series="topProductsByOrdersSeries"
                            ></apexchart>
                            <p v-else class="text-muted text-center mt-5">No data</p>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h6 class="mb-0">Top 10 Products by Revenue</h6></div>
                        <div class="card-body">
                            <apexchart
                                v-if="topProducts.by_revenue && topProducts.by_revenue.length > 0"
                                type="bar"
                                height="320"
                                :options="topProductsByRevenueOptions"
                                :series="topProductsByRevenueSeries"
                            ></apexchart>
                            <p v-else class="text-muted text-center mt-5">No data</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Order Type Split -->
            <div class="row mb-4">
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h6 class="mb-0">Delivery Type</h6></div>
                        <div class="card-body d-flex justify-content-center">
                            <apexchart
                                v-if="orderTypeSplit.delivery_type.values.length > 0"
                                type="donut"
                                height="250"
                                :options="deliveryTypeOptions"
                                :series="orderTypeSplit.delivery_type.values"
                            ></apexchart>
                            <p v-else class="text-muted mt-5">No data</p>
                        </div>
                    </div>
                </div>
                <div class="col-12 col-lg-6 mb-3">
                    <div class="card h-100">
                        <div class="card-header"><h6 class="mb-0">Order Mode</h6></div>
                        <div class="card-body d-flex justify-content-center">
                            <apexchart
                                v-if="orderTypeSplit.order_mode.values.some(v => v > 0)"
                                type="donut"
                                height="250"
                                :options="orderModeOptions"
                                :series="orderTypeSplit.order_mode.values"
                            ></apexchart>
                            <p v-else class="text-muted mt-5">No data</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Monthly Comparison -->
            <div class="row mb-4" v-if="monthlyComparison">
                <div class="col-12 mb-3">
                    <div class="card">
                        <div class="card-header"><h6 class="mb-0">Period Comparison</h6></div>
                        <div class="card-body">
                            <p class="text-muted small">{{ monthlyComparison.current_period }} vs {{ monthlyComparison.previous_period }}</p>
                            <div class="row">
                                <div class="col-md-4 mb-2" v-for="(metric, key) in monthlyComparison.metrics" :key="key">
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

            <!-- Recent Orders Table -->
            <div class="row mb-4" v-if="recentOrders && recentOrders.length > 0">
                <div class="col-12 mb-3">
                    <div class="card">
                        <div class="card-header"><h6 class="mb-0">Recent Orders</h6></div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-bordered table-sm table-hover">
                                    <thead class="thead-light">
                                        <tr>
                                            <th>Order ID</th>
                                            <th>Customer</th>
                                            <th class="text-right">Amount</th>
                                            <th>Status</th>
                                            <th>Payment</th>
                                            <th>Date</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="order in recentOrders" :key="order.order_id">
                                            <td>
                                                <router-link :to="'/orders/view/' + order.order_id" class="text-decoration-none">
                                                    #{{ order.unique_order_id }}
                                                </router-link>
                                            </td>
                                            <td>{{ order.customer_name }}</td>
                                            <td class="text-right font-weight-bold text-success">&#8377;{{ formatNumber(order.amount) }}</td>
                                            <td><span class="badge badge-info">{{ order.status }}</span></td>
                                            <td>{{ order.payment_method }}</td>
                                            <td>{{ order.created_at }}</td>
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
    name: 'SellerAnalytics',
    components: {
        apexchart: VueApexCharts,
    },
    props: {
        sellerId: {
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
            chartColors: ['#9AC444', '#008FFB', '#FEB019', '#FF4560', '#775DD0', '#00E396', '#F86624', '#546E7A'],
        };
    },
    created() {
        this.fetchAnalytics();
    },
    computed: {
        summary() {
            return this.analyticsData?.summary || {};
        },
        ordersOverTime() {
            return this.analyticsData?.orders_over_time || { labels: [], values: [] };
        },
        revenueOverTime() {
            return this.analyticsData?.revenue_over_time || { labels: [], values: [] };
        },
        statusBreakdown() {
            return this.analyticsData?.status_breakdown || { labels: [], values: [] };
        },
        paymentMethods() {
            return this.analyticsData?.payment_methods || { labels: [], values: [] };
        },
        topProducts() {
            return this.analyticsData?.top_products || { by_orders: [], by_revenue: [] };
        },
        orderTypeSplit() {
            return this.analyticsData?.order_type_split || {
                delivery_type: { labels: [], values: [] },
                order_mode: { labels: [], values: [] },
            };
        },
        monthlyComparison() {
            return this.analyticsData?.monthly_comparison || null;
        },
        recentOrders() {
            return this.analyticsData?.recent_orders || [];
        },

        summaryCards() {
            const s = this.summary;
            return [
                { label: 'Total Orders', value: s.total_orders, prefix: '', suffix: '', color: '#008FFB' },
                { label: 'Total Revenue', value: s.total_revenue, prefix: '\u20B9', suffix: '', color: '#9AC444' },
                { label: 'Avg Order Value', value: s.avg_order_value, prefix: '\u20B9', suffix: '', color: '#FEB019' },
                { label: 'Total Products', value: s.total_products, prefix: '', suffix: '', color: '#775DD0' },
                { label: 'Active Products', value: s.active_products, prefix: '', suffix: '', color: '#00E396' },
                { label: 'Avg Rating', value: s.avg_rating, prefix: '', suffix: '/5', color: '#FF4560' },
                { label: 'Commission Earned', value: s.commission_earned, prefix: '\u20B9', suffix: '', color: '#546E7A' },
            ];
        },

        ordersOverTimeOptions() {
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                colors: ['#9AC444'],
                xaxis: { categories: this.ordersOverTime.labels },
                yaxis: { title: { text: 'Orders' } },
                dataLabels: { enabled: true },
                plotOptions: { bar: { borderRadius: 4, columnWidth: '60%' } },
            };
        },
        ordersOverTimeSeries() {
            return [{ name: 'Orders', data: this.ordersOverTime.values }];
        },

        revenueOverTimeOptions() {
            return {
                chart: { type: 'area', toolbar: { show: false } },
                colors: ['#9AC444'],
                xaxis: { categories: this.revenueOverTime.labels },
                yaxis: { title: { text: 'Revenue' }, labels: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
                dataLabels: { enabled: false },
                stroke: { curve: 'smooth', width: 2 },
                fill: { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: 0.4, opacityTo: 0.1 } },
                tooltip: { y: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
            };
        },
        revenueOverTimeSeries() {
            return [{ name: 'Revenue', data: this.revenueOverTime.values }];
        },

        statusBreakdownOptions() {
            return {
                chart: { type: 'donut' },
                labels: this.statusBreakdown.labels,
                colors: this.chartColors,
                legend: { position: 'bottom' },
            };
        },

        paymentMethodsOptions() {
            return {
                chart: { type: 'pie' },
                labels: this.paymentMethods.labels,
                colors: this.chartColors,
                legend: { position: 'bottom' },
            };
        },

        topProductsByOrdersOptions() {
            const names = this.topProducts.by_orders.map(p => p.product_name.length > 20 ? p.product_name.substring(0, 20) + '...' : p.product_name);
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                plotOptions: { bar: { horizontal: true, borderRadius: 4 } },
                colors: ['#008FFB'],
                xaxis: { categories: names },
                dataLabels: { enabled: true },
            };
        },
        topProductsByOrdersSeries() {
            return [{ name: 'Orders', data: this.topProducts.by_orders.map(p => p.order_count) }];
        },

        topProductsByRevenueOptions() {
            const names = this.topProducts.by_revenue.map(p => p.product_name.length > 20 ? p.product_name.substring(0, 20) + '...' : p.product_name);
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                plotOptions: { bar: { horizontal: true, borderRadius: 4 } },
                colors: ['#9AC444'],
                xaxis: {
                    categories: names,
                    labels: { formatter: (v) => '\u20B9' + this.formatNumber(v) }
                },
                dataLabels: { enabled: true, formatter: (v) => '\u20B9' + this.formatNumber(v) },
                tooltip: { y: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
            };
        },
        topProductsByRevenueSeries() {
            return [{ name: 'Revenue', data: this.topProducts.by_revenue.map(p => p.total_revenue) }];
        },

        deliveryTypeOptions() {
            return {
                chart: { type: 'donut' },
                labels: this.orderTypeSplit.delivery_type.labels,
                colors: ['#9AC444', '#008FFB'],
                legend: { position: 'bottom' },
            };
        },

        orderModeOptions() {
            return {
                chart: { type: 'donut' },
                labels: this.orderTypeSplit.order_mode.labels,
                colors: ['#008FFB', '#FEB019'],
                legend: { position: 'bottom' },
            };
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
            axios.get(this.$apiUrl + '/sellers/' + this.sellerId + '/analytics', { params })
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
                orders: 'Orders',
                revenue: 'Revenue',
                avg_order_value: 'Avg Order Value',
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
