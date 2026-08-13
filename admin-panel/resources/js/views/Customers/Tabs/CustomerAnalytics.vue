<template>
    <div>
        <div v-if="isLoading" class="text-center py-5">
            <b-spinner></b-spinner>
            <p>{{ __('loading') }}...</p>
        </div>

        <div v-else-if="analytics">
            <!-- Order Statistics Cards -->
            <div class="row mb-4">
                <div class="col-md-4 col-sm-6 mb-3">
                    <div class="stat-card bg-primary text-white">
                        <div class="stat-icon">
                            <i class="fa fa-shopping-cart"></i>
                        </div>
                        <div class="stat-content">
                            <h3>{{ analytics.order_statistics.total_orders }}</h3>
                            <p>Total Orders</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-4 col-sm-6 mb-3">
                    <div class="stat-card bg-success text-white">
                        <div class="stat-icon">
                            <i class="fa fa-check-circle"></i>
                        </div>
                        <div class="stat-content">
                            <h3>{{ analytics.order_statistics.delivered_orders }}</h3>
                            <p>Delivered Orders</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-4 col-sm-6 mb-3">
                    <div class="stat-card bg-info text-white">
                        <div class="stat-icon">
                            <i class="fa fa-money"></i>
                        </div>
                        <div class="stat-content">
                            <h3>{{ $currency }}{{ analytics.order_statistics.total_spent }}</h3>
                            <p>Total Spent</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-4 col-sm-6 mb-3">
                    <div class="stat-card bg-warning text-dark">
                        <div class="stat-icon">
                            <i class="fa fa-bar-chart"></i>
                        </div>
                        <div class="stat-content">
                            <h3>{{ $currency }}{{ analytics.order_statistics.avg_order_value }}</h3>
                            <p>Avg Order Value</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-4 col-sm-6 mb-3">
                    <div class="stat-card bg-danger text-white">
                        <div class="stat-icon">
                            <i class="fa fa-times-circle"></i>
                        </div>
                        <div class="stat-content">
                            <h3>{{ analytics.order_statistics.cancelled_orders }}</h3>
                            <p>Cancelled Orders</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-4 col-sm-6 mb-3">
                    <div class="stat-card bg-secondary text-white">
                        <div class="stat-icon">
                            <i class="fa fa-undo"></i>
                        </div>
                        <div class="stat-content">
                            <h3>{{ analytics.order_statistics.returned_orders }}</h3>
                            <p>Returned Orders</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Customer Timeline -->
            <div class="row mb-4" v-if="analytics.first_order_date || analytics.last_order_date">
                <div class="col-12">
                    <div class="card analytics-card timeline-card">
                        <div class="card-body py-3">
                            <div class="d-flex justify-content-between align-items-center flex-wrap">
                                <div v-if="analytics.first_order_date">
                                    <small class="text-muted">First Order</small>
                                    <p class="mb-0 fw-bold">{{ analytics.first_order_date }}</p>
                                </div>
                                <div class="text-center d-none d-md-block">
                                    <i class="fa fa-arrow-right fa-2x text-muted"></i>
                                </div>
                                <div v-if="analytics.last_order_date" class="text-end">
                                    <small class="text-muted">Last Order</small>
                                    <p class="mb-0 fw-bold">{{ analytics.last_order_date }}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Orders by Status -->
            <div class="row mb-4">
                <div class="col-md-6 mb-3 mb-md-0">
                    <div class="card analytics-card h-100">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h6 class="mb-0"><i class="fa fa-pie-chart me-2"></i>Orders by Status</h6>
                            <span class="badge bg-secondary">{{ analytics.order_statistics.total_orders }} Total</span>
                        </div>
                        <div class="card-body">
                            <div v-if="analytics.orders_by_status.length === 0" class="text-center text-muted py-3">
                                <i class="fa fa-inbox fa-2x mb-2"></i>
                                <p class="mb-0">No orders found</p>
                            </div>
                            <div v-else>
                                <div v-for="item in analytics.orders_by_status" :key="item.status" class="status-row mb-3">
                                    <div class="d-flex justify-content-between align-items-center mb-1">
                                        <div class="d-flex align-items-center">
                                            <span class="status-icon me-2" :class="'status-icon-' + item.status">
                                                <i :class="getStatusIcon(item.status)"></i>
                                            </span>
                                            <span class="status-name">{{ item.status_name }}</span>
                                        </div>
                                        <div class="d-flex align-items-center">
                                            <span class="status-percentage me-2">{{ getPercentage(item.count) }}%</span>
                                            <span class="status-count">{{ item.count }}</span>
                                        </div>
                                    </div>
                                    <div class="progress" style="height: 6px;">
                                        <div class="progress-bar" :class="getProgressBarClass(item.status)"
                                             :style="{ width: getPercentage(item.count) + '%' }"></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Monthly Trends -->
                <div class="col-md-6">
                    <div class="card analytics-card h-100">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h6 class="mb-0"><i class="fa fa-line-chart me-2"></i>Monthly Trends</h6>
                            <span class="badge bg-info">Last 6 Months</span>
                        </div>
                        <div class="card-body p-0">
                            <div v-if="analytics.monthly_trends.length === 0" class="text-center text-muted py-4">
                                <i class="fa fa-calendar-o fa-2x mb-2"></i>
                                <p class="mb-0">No data available</p>
                            </div>
                            <div v-else class="trends-list">
                                <div v-for="(trend, index) in analytics.monthly_trends" :key="trend.month"
                                     class="trend-item" :class="{ 'border-bottom': index < analytics.monthly_trends.length - 1 }">
                                    <div class="d-flex justify-content-between align-items-center">
                                        <div class="trend-month">
                                            <i class="fa fa-calendar me-2 text-muted"></i>
                                            <span>{{ trend.month }}</span>
                                        </div>
                                        <div class="trend-stats d-flex">
                                            <div class="trend-orders me-4 text-center">
                                                <div class="trend-value">{{ trend.order_count }}</div>
                                                <div class="trend-label">Orders</div>
                                            </div>
                                            <div class="trend-spent text-end">
                                                <div class="trend-value text-success">{{ $currency }}{{ trend.total_spent }}</div>
                                                <div class="trend-label">Spent</div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div v-else class="text-center py-5">
            <i class="fa fa-exclamation-circle fa-3x text-muted mb-3"></i>
            <p class="text-muted">Failed to load analytics data</p>
            <button class="btn btn-primary btn-sm" @click="loadAnalytics">
                <i class="fa fa-refresh"></i> Retry
            </button>
        </div>
    </div>
</template>

<script>
export default {
    props: {
        customerId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            isLoading: false,
            analytics: null
        }
    },
    created() {
        this.loadAnalytics();
    },
    watch: {
        customerId: function() {
            this.loadAnalytics();
        }
    },
    methods: {
        loadAnalytics() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/customers/' + this.customerId + '/analytics')
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status === 1) {
                        this.analytics = response.data.data;
                    } else {
                        this.analytics = null;
                    }
                })
                .catch((error) => {
                    this.isLoading = false;
                    this.analytics = null;
                    console.error('Error loading analytics:', error);
                });
        },
        getStatusBadgeClass(status) {
            const classMap = {
                1: 'bg-warning text-dark',
                2: 'bg-info',
                3: 'bg-primary',
                4: 'bg-secondary',
                5: 'bg-info',
                6: 'bg-success',
                7: 'bg-danger',
                8: 'bg-dark',
                9: 'bg-warning text-dark',
                10: 'bg-primary',
                11: 'bg-success'
            };
            return classMap[status] || 'bg-secondary';
        },
        getStatusIcon(status) {
            const iconMap = {
                1: 'fa fa-clock-o',
                2: 'fa fa-inbox',
                3: 'fa fa-cog',
                4: 'fa fa-truck',
                5: 'fa fa-motorcycle',
                6: 'fa fa-check-circle',
                7: 'fa fa-times-circle',
                8: 'fa fa-undo',
                9: 'fa fa-hourglass-half',
                10: 'fa fa-hand-paper-o',
                11: 'fa fa-shopping-bag'
            };
            return iconMap[status] || 'fa fa-circle';
        },
        getProgressBarClass(status) {
            const classMap = {
                1: 'bg-warning',
                2: 'bg-info',
                3: 'bg-primary',
                4: 'bg-secondary',
                5: 'bg-info',
                6: 'bg-success',
                7: 'bg-danger',
                8: 'bg-dark',
                9: 'bg-warning',
                10: 'bg-primary',
                11: 'bg-success'
            };
            return classMap[status] || 'bg-secondary';
        },
        getPercentage(count) {
            if (!this.analytics || !this.analytics.order_statistics.total_orders) return 0;
            return Math.round((count / this.analytics.order_statistics.total_orders) * 100);
        }
    }
};
</script>

<style>
.stat-card {
    border-radius: 8px;
    padding: 20px;
    display: flex;
    align-items: center;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.stat-icon {
    font-size: 2.5rem;
    margin-right: 15px;
    opacity: 0.8;
}

.stat-content h3 {
    margin: 0;
    font-size: 1.5rem;
    font-weight: 700;
}

.stat-content p {
    margin: 0;
    font-size: 0.875rem;
    opacity: 0.9;
}

.analytics-card {
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.analytics-card .card-header {
    background-color: transparent;
    border-bottom: 1px solid #e9ecef;
}

.analytics-card .card-header h6 {
    font-weight: 600;
}

/* Dark mode support */
body.theme-dark .analytics-card {
    background-color: #1e1e1e;
    border-color: #333;
}

body.theme-dark .analytics-card .card-header {
    background-color: #2d2d2d;
    border-color: #333;
}

body.theme-dark .analytics-card .card-header h6 {
    color: #fff;
}

body.theme-dark .analytics-card .card-body {
    background-color: #1e1e1e;
    color: #e0e0e0;
}

body.theme-dark .analytics-card .table {
    color: #e0e0e0;
}

body.theme-dark .analytics-card .table th {
    color: #a0aec0;
}

body.theme-dark .analytics-card .fw-bold {
    color: #fff;
}

body.theme-dark .timeline-card .text-muted {
    color: #a0aec0 !important;
}

body.theme-dark .timeline-card .fw-bold {
    color: #fff;
}

/* Status Row Styles */
.status-row {
    padding: 8px 0;
}

.status-icon {
    width: 28px;
    height: 28px;
    border-radius: 6px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 12px;
    color: #fff;
}

.status-icon-1 { background-color: #ffc107; color: #212529; }
.status-icon-2 { background-color: #0dcaf0; }
.status-icon-3 { background-color: #0d6efd; }
.status-icon-4 { background-color: #6c757d; }
.status-icon-5 { background-color: #0dcaf0; }
.status-icon-6 { background-color: #198754; }
.status-icon-7 { background-color: #dc3545; }
.status-icon-8 { background-color: #212529; }
.status-icon-9 { background-color: #ffc107; color: #212529; }
.status-icon-10 { background-color: #0d6efd; }
.status-icon-11 { background-color: #198754; }

.status-name {
    font-weight: 500;
    font-size: 0.9rem;
}

.status-percentage {
    font-size: 0.85rem;
    color: #6c757d;
    font-weight: 500;
}

.status-count {
    font-weight: 700;
    font-size: 1.1rem;
    min-width: 30px;
    text-align: right;
}

.progress {
    background-color: #e9ecef;
    border-radius: 3px;
}

/* Trends List Styles */
.trends-list {
    max-height: 300px;
    overflow-y: auto;
}

.trend-item {
    padding: 12px 16px;
    transition: background-color 0.2s;
}

.trend-item:hover {
    background-color: rgba(0, 0, 0, 0.02);
}

.trend-month {
    font-weight: 500;
}

.trend-value {
    font-weight: 700;
    font-size: 1rem;
}

.trend-label {
    font-size: 0.7rem;
    text-transform: uppercase;
    color: #6c757d;
    letter-spacing: 0.5px;
}

/* Dark mode for status and trends */
body.theme-dark .status-name {
    color: #e0e0e0;
}

body.theme-dark .status-percentage {
    color: #a0aec0;
}

body.theme-dark .status-count {
    color: #fff;
}

body.theme-dark .progress {
    background-color: #333;
}

body.theme-dark .trend-item {
    border-color: #333 !important;
}

body.theme-dark .trend-item:hover {
    background-color: rgba(255, 255, 255, 0.05);
}

body.theme-dark .trend-month {
    color: #e0e0e0;
}

body.theme-dark .trend-value {
    color: #fff;
}

body.theme-dark .trend-value.text-success {
    color: #4ade80 !important;
}

body.theme-dark .trend-label {
    color: #a0aec0;
}

body.theme-dark .trends-list::-webkit-scrollbar {
    width: 6px;
}

body.theme-dark .trends-list::-webkit-scrollbar-track {
    background: #1e1e1e;
}

body.theme-dark .trends-list::-webkit-scrollbar-thumb {
    background-color: #444;
    border-radius: 3px;
}
</style>
