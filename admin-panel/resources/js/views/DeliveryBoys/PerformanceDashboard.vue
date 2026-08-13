<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>{{ __('performance_dashboard') }}</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">Dashboard</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                Performance Dashboard
                            </li>
                        </ol>
                    </nav>
                </div>
            </div>
        </div>

        <!-- Zone / City Filter -->
        <div class="mb-3">
            <select v-model="city_id" @change="loadDashboardData()" class="form-control form-select city-zone-select">
                <option value="">All Zones</option>
                <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
                <option value="other">Other</option>
            </select>
        </div>

        <div class="page-content">
            <section class="row">
                <!-- Filters - COMMENTED OUT
                <div class="col-12">
                    <div class="card">
                        <div class="card-body">
                            <div class="row align-items-end">
                                <div class="col-md-3">
                                    <div class="form-group">
                                        <label>{{ __('period') }}</label>
                                        <select v-model="selectedPeriod" @change="loadDashboardData" class="form-control form-select">
                                            <option value="daily">{{ __('daily') }}</option>
                                            <option value="weekly">{{ __('weekly') }}</option>
                                            <option value="monthly">{{ __('monthly') }}</option>
                                            <option value="yearly">{{ __('yearly') }}</option>
                                        </select>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="form-group">
                                        <label>{{ __('date_range') }}</label>
                                        <date-range-picker
                                            :autoApply="false"
                                            :showDropdowns="true"
                                            v-model="dateRange"
                                            :maxDate="maxDate"
                                            @update="loadDashboardData"
                                            :ranges="customRanges"
                                        ></date-range-picker>
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <div class="form-group">
                                        <label>{{ __('driver') }}</label>
                                        <select v-model="selectedDriver" @change="loadDashboardData" class="form-control form-select">
                                            <option value="">{{ __('all_drivers') }}</option>
                                            <option v-for="driver in driversList" :key="driver.id" :value="driver.id">
                                                {{ driver.name }} ({{ driver.mobile }})
                                            </option>
                                        </select>
                                    </div>
                                </div>
                                <div class="col-md-2">
                                    <button class="btn btn-primary w-100" @click="loadDashboardData">
                                        <i class="fa fa-refresh"></i> {{ __('refresh') }}
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                -->

                <!-- Top Drivers Table -->
                <div class="col-12">
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <div>
                                <h4 class="card-title mb-0">{{ __('top_drivers') }}</h4>
                                <small class="text-muted">({{ currentMonth }})</small>
                            </div>
                            <div class="badge bg-success">
                                <i class="fa fa-trophy"></i>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <b-table
                                    :items="topDrivers"
                                    :fields="topDriversFields"
                                    :current-page="topDriversCurrentPage"
                                    :per-page="topDriversPerPage"
                                    :bordered="true"
                                    stacked="md"
                                    show-empty
                                    small>
                                    <template #cell(index)="row">
                                        <span class="badge" :class="getRankBadgeClass(row.index + 1)">
                                            {{ row.index + 1 }}
                                        </span>
                                    </template>
                                    <template #head(total_earnings)="row">
                                        {{ __('total_earnings') + ' (' + $currency + ')' }}
                                    </template>
                                    <template #cell(driver_name)="row">
                                        <div class="d-flex align-items-center">
                                            <div>
                                                <strong>{{ row.item.driver_name }}</strong>
                                                <br>
                                                <small class="text-muted">{{ row.item.mobile }}</small>
                                            </div>
                                        </div>
                                    </template>
                                    <template #cell(actions)="row">
                                        <button class="btn btn-sm btn-primary" @click="viewDriverPerformance(row.item.delivery_boy_id)">
                                            <i class="fa fa-eye"></i>
                                        </button>
                                    </template>
                                </b-table>
                            </div>
                            <b-row>
                                <b-col md="4" class="my-1">
                                    <b-form-group
                                        :label="__('per_page')"
                                        label-for="per-page-select"
                                        label-align-sm="right"
                                        label-size="sm"
                                        class="mb-0">
                                        <b-form-select
                                            id="per-page-select"
                                            v-model="topDriversPerPage"
                                            :options="pageOptions"
                                            size="sm"
                                            class="form-control form-select"
                                        ></b-form-select>
                                    </b-form-group>
                                </b-col>
                                <b-col md="6" class="my-1" offset-md="2">
                                    <b-pagination
                                        v-model="topDriversCurrentPage"
                                        :total-rows="topDriversTotalRows"
                                        :per-page="topDriversPerPage"
                                        align="fill"
                                        size="sm"
                                        class="my-0"
                                    ></b-pagination>
                                </b-col>
                            </b-row>
                        </div>
                    </div>
                </div>

                <!-- Overview Stats Cards - COMMENTED OUT
                <div class="col-12">
                    <div class="row g-3">
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card stat-card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="stats-icon bg-primary">
                                            <i class="fa fa-money"></i>
                                        </div>
                                        <div class="ms-3">
                                            <h6 class="text-muted mb-1">{{ __('total_earnings') }}</h6>
                                            <h4 class="mb-0">{{ $currency }}{{ overview.total_earnings }}</h4>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card stat-card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="stats-icon bg-success">
                                            <i class="fa fa-shopping-cart"></i>
                                        </div>
                                        <div class="ms-3">
                                            <h6 class="text-muted mb-1">{{ __('total_orders') }}</h6>
                                            <h4 class="mb-0">{{ overview.total_orders }}</h4>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card stat-card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="stats-icon bg-info">
                                            <i class="fa fa-check-circle"></i>
                                        </div>
                                        <div class="ms-3">
                                            <h6 class="text-muted mb-1">{{ __('delivered_orders') }}</h6>
                                            <h4 class="mb-0">{{ overview.delivered_orders }}</h4>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card stat-card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="stats-icon bg-warning">
                                            <i class="fa fa-users"></i>
                                        </div>
                                        <div class="ms-3">
                                            <h6 class="text-muted mb-1">{{ __('active_drivers') }}</h6>
                                            <h4 class="mb-0">{{ overview.active_drivers }} / {{ overview.total_drivers }}</h4>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card stat-card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="stats-icon bg-secondary">
                                            <i class="fa fa-truck"></i>
                                        </div>
                                        <div class="ms-3">
                                            <h6 class="text-muted mb-1">{{ __('unique_drivers') }}</h6>
                                            <h4 class="mb-0">{{ overview.unique_drivers }}</h4>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card stat-card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="stats-icon bg-danger">
                                            <i class="fa fa-line-chart"></i>
                                        </div>
                                        <div class="ms-3">
                                            <h6 class="text-muted mb-1">{{ __('avg_per_order') }}</h6>
                                            <h4 class="mb-0">{{ $currency }}{{ overview.avg_earnings_per_order }}</h4>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="col-12 col-sm-6 col-md-4 col-lg-3">
                            <div class="card stat-card">
                                <div class="card-body">
                                    <div class="d-flex align-items-center">
                                        <div class="stats-icon" style="background-color: #6f42c1;">
                                            <i class="fa fa-bar-chart"></i>
                                        </div>
                                        <div class="ms-3">
                                            <h6 class="text-muted mb-1">{{ __('avg_orders_driver') }}</h6>
                                            <h4 class="mb-0">{{ overview.avg_orders_per_driver }}</h4>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                -->

                <!-- Charts Row -->
                <div class="col-12 col-xl-8">
                    <div class="card chart-card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <div>
                                <div style="color: #435ebe; font-size: 18px; font-weight: bold;">{{ __('earnings_trend') }}</div>
                                <small style="color: #435ebe; opacity: 0.7;">{{ currentMonth }}</small>
                            </div>
                            <div class="badge bg-primary">
                                <i class="fa fa-line-chart"></i>
                            </div>
                        </div>
                        <div class="card-body">
                            <apexchart
                                ref="earningsChart"
                                type="area"
                                height="350"
                                :options="earningsChartOptions"
                                :series="earningsSeries"
                            ></apexchart>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-xl-4">
                    <div class="card chart-card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <div>
                                <div style="color: #28a745; font-size: 18px; font-weight: bold;">{{ __('driver_distribution') }}</div>
                            </div>
                            <div class="badge bg-success">
                                <i class="fa fa-pie-chart"></i>
                            </div>
                        </div>
                        <div class="card-body">
                            <apexchart
                                ref="distributionChart"
                                type="donut"
                                height="320"
                                :options="distributionChartOptions"
                                :series="distributionSeries"
                            ></apexchart>
                        </div>
                    </div>
                </div>

                <!-- Orders Chart -->
                <div class="col-12 col-xl-8">
                    <div class="card chart-card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <div>
                                <div style="color: #17a2b8; font-size: 18px; font-weight: bold;">{{ __('orders_overview') }}</div>
                                <small style="color: #17a2b8; opacity: 0.7;">{{ __('delivered_vs_cancelled_vs_returned') }}</small>
                            </div>
                            <div class="badge bg-info">
                                <i class="fa fa-bar-chart"></i>
                            </div>
                        </div>
                        <div class="card-body">
                            <apexchart
                                ref="ordersChart"
                                type="bar"
                                height="350"
                                :options="ordersChartOptions"
                                :series="ordersSeries"
                            ></apexchart>
                        </div>
                    </div>
                </div>

                <!-- Performance by Day - COMMENTED OUT
                <div class="col-12 col-xl-4">
                    <div class="card chart-card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <div>
                                <h4 class="card-title mb-0">{{ __('performance_by_day') }}</h4>
                            </div>
                            <div class="badge bg-warning">
                                <i class="fa fa-calendar"></i>
                            </div>
                        </div>
                        <div class="card-body">
                            <apexchart
                                ref="dayChart"
                                type="radar"
                                height="320"
                                :options="dayChartOptions"
                                :series="daySeries"
                            ></apexchart>
                        </div>
                    </div>
                </div>
                -->

            </section>
        </div>

        <!-- Driver Performance Modal -->
        <b-modal ref="driverModal" :title="selectedDriverData.name + ' - Performance'" size="xl" scrollable>
            <div v-if="loadingDriverData" class="text-center py-5">
                <b-spinner></b-spinner>
                <p>{{ __('loading') }}...</p>
            </div>
            <div v-else>
                <div class="row mb-4">
                    <div class="col-md-3">
                        <div class="card bg-light">
                            <div class="card-body text-center">
                                <h6 class="text-muted">{{ __('total_earnings') }}</h6>
                                <h4>{{ $currency }}{{ selectedDriverData.stats && selectedDriverData.stats.total_earnings ? selectedDriverData.stats.total_earnings : 0 }}</h4>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="card bg-light">
                            <div class="card-body text-center">
                                <h6 class="text-muted">{{ __('total_orders') }}</h6>
                                <h4>{{ selectedDriverData.stats && selectedDriverData.stats.total_orders ? selectedDriverData.stats.total_orders : 0 }}</h4>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="card bg-light">
                            <div class="card-body text-center">
                                <h6 class="text-muted">{{ __('delivered_orders') }}</h6>
                                <h4>{{ selectedDriverData.stats && selectedDriverData.stats.delivered_orders ? selectedDriverData.stats.delivered_orders : 0 }}</h4>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="card bg-light">
                            <div class="card-body text-center">
                                <h6 class="text-muted">{{ __('avg_per_order') }}</h6>
                                <h4>{{ $currency }}{{ selectedDriverData.stats && selectedDriverData.stats.avg_earnings_per_order ? selectedDriverData.stats.avg_earnings_per_order : 0 }}</h4>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row">
                    <div class="col-12">
                        <h6>{{ __('recent_transactions') }}</h6>
                        <div class="table-responsive">
                            <table class="table table-sm table-bordered">
                                <thead>
                                    <tr>
                                        <th>{{ __('order_id') }}</th>
                                        <th>{{ __('type') }}</th>
                                        <th>{{ __('earnings') }} ({{ $currency }})</th>
                                        <th>{{ __('date') }}</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="tx in selectedDriverData.recent_transactions" :key="tx.id">
                                        <td>#{{ tx.order_id }}</td>
                                        <td>{{ tx.type }}</td>
                                        <td>{{ tx.driver_earnings }}</td>
                                        <td>{{ formatDate(tx.created_at) }}</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
            <template #modal-footer>
                <b-button variant="secondary" @click="$refs.driverModal.hide()">{{ __('close') }}</b-button>
            </template>
        </b-modal>
    </div>
</template>

<script>
import DateRangePicker from 'vue2-daterange-picker';
import VueApexCharts from 'vue-apexcharts';
import axios from 'axios';
import moment from 'moment';

export default {
    name: 'PerformanceDashboard',
    components: {
        DateRangePicker,
        apexchart: VueApexCharts
    },
    data() {
        let startDate = new Date();
        let endDate = new Date();
        startDate.setDate(1); // Start of month

        return {
            isLoading: false,
            loadingDriverData: false,
            selectedPeriod: 'monthly',
            selectedDriver: '',
            dateRange: { startDate, endDate },
            maxDate: new Date(),
            customRanges: {
                'Today': this.getTodayRange(),
                'Yesterday': this.getYesterdayRange(),
                'This Week': this.getThisWeekRange(),
                'This Month': this.getThisMonthRange(),
                'This Year': this.getThisYearRange(),
                'Last Month': this.getLastMonthRange(),
            },

            // Overview data
            overview: {
                total_earnings: 0,
                total_orders: 0,
                delivered_orders: 0,
                unique_drivers: 0,
                active_drivers: 0,
                total_drivers: 0,
                avg_earnings_per_order: 0,
                avg_orders_per_driver: 0,
            },
            currentMonth: '',

            // Zone filter
            city_id: '',
            cities: [],

            // Drivers list for filter
            driversList: [],

            // Top Drivers table
            topDrivers: [],
            topDriversFields: [
                { key: 'index', label: '#', sortable: false },
                { key: 'driver_name', label: __('driver'), sortable: false },
                { key: 'order_count', label: __('orders'), sortable: false, class: 'text-center' },
                { key: 'total_earnings', label: __('earnings'), sortable: false, class: 'text-center' },
                { key: 'actions', label: __('actions'), class: 'text-center' },
            ],
            topDriversCurrentPage: 1,
            topDriversPerPage: 10,
            topDriversTotalRows: 0,
            pageOptions: this.$pageOptions,

            // Selected driver modal data
            selectedDriverData: {
                name: '',
                stats: null,
                recent_transactions: [],
            },

            // Charts
            earningsSeries: [
                { name: 'Earnings', data: [] }
            ],
            earningsChartOptions: {
                chart: {
                    type: 'area',
                    toolbar: { show: true },
                    zoom: { enabled: true }
                },
                colors: ['#28a745'],
                dataLabels: { enabled: false },
                stroke: { curve: 'smooth', width: 2 },
                fill: {
                    type: 'gradient',
                    gradient: {
                        shadeIntensity: 1,
                        opacityFrom: 0.5,
                        opacityTo: 0.1,
                    }
                },
                xaxis: { categories: [] },
                yaxis: {
                    labels: {
                        formatter: (val) => this.$currency + val
                    }
                },
                tooltip: {
                    y: {
                        formatter: (val) => this.$currency + val
                    }
                }
            },

            ordersSeries: [
                { name: 'Delivered', data: [] },
                { name: 'Cancelled', data: [] },
                { name: 'Returned', data: [] },
            ],
            ordersChartOptions: {
                chart: {
                    type: 'bar',
                    toolbar: { show: true },
                    stacked: false,
                },
                colors: ['#28a745', '#dc3545', '#ffc107'],
                plotOptions: {
                    bar: {
                        horizontal: false,
                        columnWidth: '55%',
                    },
                },
                dataLabels: { enabled: false },
                xaxis: { categories: [] },
                legend: { position: 'top' }
            },

            distributionSeries: [],
            distributionChartOptions: {
                chart: { type: 'donut' },
                labels: ['Active', 'Registered', 'Deactivated', 'Rejected'],
                colors: ['#28a745', '#ffc107', '#dc3545', '#6c757d'],
                legend: { position: 'bottom' },
                plotOptions: {
                    pie: {
                        donut: {
                            size: '65%',
                            labels: {
                                show: true,
                                total: {
                                    show: true,
                                    label: 'Total',
                                    formatter: (w) => w.globals.seriesTotals.reduce((a, b) => a + b, 0)
                                }
                            }
                        }
                    }
                }
            },

            daySeries: [
                { name: 'Orders', data: [] }
            ],
            dayChartOptions: {
                chart: { type: 'radar' },
                colors: ['#007bff'],
                xaxis: {
                    categories: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                },
                yaxis: { show: false },
                markers: { size: 4 },
                stroke: { width: 2 }
            }
        };
    },
    created() {
        this.getCities();
        this.loadDriversList();
        this.loadDashboardData();
    },
    methods: {
        getCities() {
            axios.get(this.$apiUrl + '/cities')
                .then((response) => {
                    this.cities = response.data.data || response.data;
                })
                .catch(() => {});
        },

        getTodayRange() {
            let startDate = new Date();
            startDate.setHours(0, 0, 0, 0);
            let endDate = new Date();
            endDate.setHours(23, 59, 59, 999);
            return [startDate, endDate];
        },
        getYesterdayRange() {
            let endDate = new Date();
            endDate.setDate(endDate.getDate() - 1);
            let startDate = new Date(endDate);
            startDate.setHours(0, 0, 0, 0);
            endDate.setHours(23, 59, 59, 999);
            return [startDate, endDate];
        },
        getThisWeekRange() {
            let startDate = new Date();
            startDate.setDate(startDate.getDate() - startDate.getDay() + 1);
            startDate.setHours(0, 0, 0, 0);
            let endDate = new Date();
            endDate.setDate(startDate.getDate() + 6);
            endDate.setHours(23, 59, 59, 999);
            return [startDate, endDate];
        },
        getThisMonthRange() {
            let startDate = new Date();
            startDate.setDate(1);
            startDate.setHours(0, 0, 0, 0);
            let endDate = new Date();
            endDate.setMonth(endDate.getMonth() + 1);
            endDate.setDate(0);
            endDate.setHours(23, 59, 59, 999);
            return [startDate, endDate];
        },
        getThisYearRange() {
            let startDate = new Date();
            startDate.setMonth(0);
            startDate.setDate(1);
            let endDate = new Date();
            endDate.setFullYear(endDate.getFullYear() + 1);
            endDate.setMonth(0);
            endDate.setDate(0);
            endDate.setHours(23, 59, 59, 999);
            return [startDate, endDate];
        },
        getLastMonthRange() {
            let startDate = new Date();
            startDate.setMonth(startDate.getMonth() - 1);
            startDate.setDate(1);
            startDate.setHours(0, 0, 0, 0);
            let endDate = new Date();
            endDate.setDate(0);
            endDate.setHours(23, 59, 59, 999);
            return [startDate, endDate];
        },

        loadDriversList() {
            axios.get(this.$apiUrl + '/admin/driver-performance/drivers-list')
                .then(res => {
                    if (res.data.status === 1) {
                        this.driversList = res.data.data;
                    }
                })
                .catch(err => {
                    console.error('Failed to load drivers list:', err);
                });
        },

        loadDashboardData() {
            this.isLoading = true;

            const params = {
                period: this.selectedPeriod,
                start_date: this.dateRange.startDate ? moment(this.dateRange.startDate).format('YYYY-MM-DD') : '',
                end_date: this.dateRange.endDate ? moment(this.dateRange.endDate).format('YYYY-MM-DD') : '',
                driver_id: this.selectedDriver || '',
                city_id: this.city_id,
            };

            axios.get(this.$apiUrl + '/admin/driver-performance/dashboard', { params })
                .then(res => {
                    this.isLoading = false;
                    if (res.data.status === 1) {
                        const data = res.data.data;

                        // Overview
                        this.overview = data.overview;
                        this.currentMonth = data.current_month;

                        // Top Drivers
                        this.topDrivers = data.top_drivers;
                        this.topDriversTotalRows = this.topDrivers.length;

                        // Earnings Chart
                        this.earningsChartOptions = {
                            ...this.earningsChartOptions,
                            xaxis: { categories: data.earnings_chart.labels }
                        };
                        this.earningsSeries = [
                            { name: 'Earnings', data: data.earnings_chart.earnings }
                        ];

                        // Orders Chart
                        this.ordersChartOptions = {
                            ...this.ordersChartOptions,
                            xaxis: { categories: data.orders_chart.labels }
                        };
                        this.ordersSeries = [
                            { name: 'Delivered', data: data.orders_chart.delivered },
                            { name: 'Cancelled', data: data.orders_chart.cancelled },
                            { name: 'Returned', data: data.orders_chart.returned },
                        ];

                        // Distribution Chart
                        this.distributionSeries = data.driver_distribution.data;

                        // Day Chart
                        this.daySeries = [
                            { name: 'Orders', data: data.performance_by_day.orders }
                        ];
                    }
                })
                .catch(err => {
                    this.isLoading = false;
                    console.error('Failed to load dashboard data:', err);
                    this.showError('Failed to load dashboard data');
                });
        },

        viewDriverPerformance(driverId) {
            this.loadingDriverData = true;
            this.selectedDriverData = { name: '', stats: null, recent_transactions: [] };
            this.$refs.driverModal.show();

            const params = {
                driver_id: driverId,
                period: this.selectedPeriod,
                start_date: this.dateRange.startDate ? moment(this.dateRange.startDate).format('YYYY-MM-DD') : '',
                end_date: this.dateRange.endDate ? moment(this.dateRange.endDate).format('YYYY-MM-DD') : '',
            };

            axios.get(this.$apiUrl + '/admin/driver-performance/driver', { params })
                .then(res => {
                    this.loadingDriverData = false;
                    if (res.data.status === 1) {
                        const data = res.data.data;
                        this.selectedDriverData = {
                            name: data.driver.name,
                            stats: data.stats,
                            recent_transactions: data.recent_transactions,
                        };
                    }
                })
                .catch(err => {
                    this.loadingDriverData = false;
                    console.error('Failed to load driver performance:', err);
                });
        },

        getRankBadgeClass(rank) {
            if (rank === 1) return 'bg-warning text-dark';
            if (rank === 2) return 'bg-secondary';
            if (rank === 3) return 'bg-dark';
            return 'bg-light text-dark';
        },

        formatDate(dateStr) {
            return moment(dateStr).format('DD MMM YYYY, HH:mm');
        }
    }
};
</script>

<style scoped>
@import "../../../../node_modules/vue2-daterange-picker/dist/vue2-daterange-picker.css";

.city-zone-select {
    max-width: 220px;
}

.stat-card {
    border-left: 4px solid #007bff;
    transition: transform 0.2s;
}

.stat-card:hover {
    transform: translateY(-2px);
}

.stats-icon {
    width: 50px;
    height: 50px;
    border-radius: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 20px;
}

.stats-icon.bg-primary { background-color: #007bff; }
.stats-icon.bg-success { background-color: #28a745; }
.stats-icon.bg-info { background-color: #17a2b8; }
.stats-icon.bg-warning { background-color: #ffc107; color: #212529; }
.stats-icon.bg-danger { background-color: #dc3545; }
.stats-icon.bg-secondary { background-color: #6c757d; }

.chart-card {
    box-shadow: 0 2px 10px rgba(0,0,0,0.08);
}

.chart-card .card-header {
    background: transparent;
    border-bottom: 1px solid #eee;
}

</style>

<style>
.theme-dark .stat-card {
    border-left-color: #4dabf7;
}

.theme-dark .chart-card {
    box-shadow: 0 2px 10px rgba(0,0,0,0.3);
}

.theme-dark .chart-card .card-header {
    border-bottom-color: #3d4147;
}

.theme-dark .card-header h4.card-title,
.theme-dark .chart-card h4.card-title {
    color: #c2c2d9 !important;
}

.theme-dark .card-header small.text-muted,
.theme-dark .chart-card .text-muted {
    color: hsl(210, 11%, 71%) !important;
}

.theme-dark .card.bg-light {
    background-color: #2d3748 !important;
}

.theme-dark .card.bg-light .text-muted {
    color: #a0aec0 !important;
}

.theme-dark .card.bg-light h4 {
    color: #e2e8f0 !important;
}
</style>
