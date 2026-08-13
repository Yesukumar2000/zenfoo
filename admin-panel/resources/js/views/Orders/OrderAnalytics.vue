<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3 class="mb-1">Order Analytics</h3>
                    <p class="text-muted mb-0 small">Track and analyze orders performance and trends</p>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">Dashboard</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                Order Analytics
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
                    <select class="form-control form-control-sm mr-2" v-model="city_id" @change="onCityChange()" style="width:auto; min-width:120px;">
                        <option value="">All Zones</option>
                        <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
                    </select>
                    <!-- Pre-order Filter -->
                    <select class="form-control form-control-sm mr-2" v-model="custom_filter" @change="fetchAnalytics()" style="width:auto; min-width:150px;">
                        <option value="">All Orders</option>
                        <option value="0">Orders</option>
                        <option value="1">Pre-orders</option>
                        <option value="2">Combo Orders</option>
                    </select>
                    <!-- Store Filter -->
                    <select class="form-control form-control-sm mr-2" v-model="store_id" @change="onStoreChange()" style="width:auto; min-width:150px;">
                        <option value="">All Stores</option>
                        <option v-for="store in stores" :key="store.id" :value="store.id">{{ store.name }}</option>
                    </select>
                    <!-- Seller Filter -->
                    <select class="form-control form-control-sm mr-2" v-model="seller_id" @change="fetchAnalytics()" style="width:auto; min-width:150px;" :disabled="!store_id">
                        <option value="">All Sellers</option>
                        <option v-for="seller in sellers" :key="seller.id" :value="seller.id">{{ seller.name || seller.store_name }}</option>
                    </select>
                    <!-- Date Range Picker for Custom -->
                    <div v-if="filter === 'custom'" class="d-flex align-items-center">
                        <input type="date" class="form-control form-control-sm mr-1" v-model="customStart" />
                        <span class="mx-1">to</span>
                        <input type="date" class="form-control form-control-sm ml-1" v-model="customEnd" />
                        <button class="btn btn-sm btn-success ml-2" @click="fetchAnalytics">Apply</button>
                    </div>
                    <!-- Export Buttons -->
                    <b-dropdown v-if="analyticsData" size="sm" variant="outline-success" right>
                        <template #button-content>
                            <i class="fa fa-download mr-1"></i> Export
                        </template>
                        <b-dropdown-header>Excel Download</b-dropdown-header>
                        <b-dropdown-item @click="downloadExcel('all')">All Data</b-dropdown-item>
                        <b-dropdown-item @click="downloadExcel('summary')">Summary & Revenue</b-dropdown-item>
                        <b-dropdown-item @click="downloadExcel('orders')">Orders List</b-dropdown-item>
                        <b-dropdown-item @click="downloadExcel('coupons')">Coupon Analytics</b-dropdown-item>
                        <b-dropdown-divider></b-dropdown-divider>
                        <b-dropdown-header>PDF Download</b-dropdown-header>
                        <b-dropdown-item @click="downloadPdf('all')">Full Report</b-dropdown-item>
                        <b-dropdown-item @click="downloadPdf('summary')">Summary Report</b-dropdown-item>
                        <b-dropdown-item @click="downloadPdf('orders')">Orders Report</b-dropdown-item>
                        <b-dropdown-item @click="downloadPdf('coupons')">Coupon Report</b-dropdown-item>
                    </b-dropdown>
                </div>
            </div>

            <!-- Selected period vs comparison period -->
            <div v-if="analyticsData" class="d-flex align-items-center flex-wrap gap-2 mt-3">
                <span class="period-chip">
                    <span class="text-muted small d-block">Current</span>
                    <strong>{{ currentPeriodLabel }}</strong>
                </span>
                <span class="period-chip period-chip-compare" v-if="comparePeriodLabel">
                    <span class="text-muted small d-block">Compare</span>
                    <strong>{{ comparePeriodLabel }}</strong>
                </span>
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
                                    <h4 class="mb-0 mt-1 font-weight-bold">{{ card.prefix }}{{ formatNumber(card.value) }}{{ card.suffix || '' }}</h4>
                                    <span
                                        v-if="cardTrend(card)"
                                        class="trend-badge small mt-1"
                                        :class="cardTrend(card).is_favorable ? 'text-success' : 'text-danger'"
                                    >
                                        <i :class="cardTrend(card).is_positive ? 'fa fa-arrow-up' : 'fa fa-arrow-down'"></i>
                                        {{ cardTrend(card).abs_percent }}%
                                        <span class="text-muted">vs prev</span>
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 1b: Multi-series Orders Trend -->
                <div class="row mb-4">
                    <div class="col-12 mb-3">
                        <div class="card h-100">
                            <div class="card-header d-flex justify-content-between align-items-center flex-wrap">
                                <h5 class="mb-0">Orders Trend</h5>
                                <span class="text-muted small">{{ currentPeriodLabel }}</span>
                            </div>
                            <div class="card-body">
                                <apexchart
                                    type="line"
                                    height="320"
                                    :options="ordersTrendOptions"
                                    :series="ordersTrendSeries"
                                ></apexchart>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 1c: Orders by Type + Top Cities -->
                <div class="row mb-4">
                    <div class="col-12 col-lg-5 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Orders by Type</h5></div>
                            <div class="card-body d-flex flex-column align-items-center justify-content-center">
                                <apexchart
                                    v-if="ordersByType.values.length > 0"
                                    type="donut"
                                    height="300"
                                    :options="ordersByTypeOptions"
                                    :series="ordersByType.values"
                                ></apexchart>
                                <p v-else class="text-muted mt-5">No data for this period</p>
                                <small v-if="ordersByType.total_orders > 0" class="text-muted mt-2 text-center">
                                    Classified {{ formatNumber(ordersByType.classified) }} of {{ formatNumber(ordersByType.total_orders) }} orders ({{ ordersByType.coverage_percent }}% coverage)
                                </small>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-lg-7 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Top Cities by Orders</h5></div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-sm table-hover mb-0" v-if="topCities.cities.length > 0">
                                        <thead class="thead-light">
                                            <tr>
                                                <th>#</th>
                                                <th>City</th>
                                                <th class="text-right">Total Orders</th>
                                                <th class="text-right">% of Orders</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="(c, i) in topCities.cities" :key="c.city">
                                                <td>{{ i + 1 }}</td>
                                                <td>{{ c.city }}</td>
                                                <td class="text-right font-weight-bold">{{ formatNumber(c.order_count) }}</td>
                                                <td class="text-right">{{ c.percent }}%</td>
                                            </tr>
                                        </tbody>
                                    </table>
                                    <p v-else class="text-muted text-center mb-0 mt-5">No city data for this period</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 1c2: Orders by Status -->
                <div class="row mb-4">
                    <div class="col-12 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Orders by Status</h5></div>
                            <div class="card-body">
                                <div v-if="ordersByStatus.total > 0" class="row align-items-center">
                                    <div class="col-12 col-md-5 d-flex justify-content-center">
                                        <apexchart
                                            type="donut"
                                            height="300"
                                            :options="ordersByStatusOptions"
                                            :series="ordersByStatus.values"
                                        ></apexchart>
                                    </div>
                                    <div class="col-12 col-md-7">
                                        <div
                                            v-for="seg in ordersByStatus.segments"
                                            :key="seg.label"
                                            class="d-flex align-items-center justify-content-between py-2 status-legend-row"
                                        >
                                            <span class="d-flex align-items-center">
                                                <span class="status-dot mr-2" :style="{ backgroundColor: seg.color }"></span>
                                                <span class="status-legend-label">{{ seg.label }}</span>
                                            </span>
                                            <span class="text-nowrap">
                                                <span class="font-weight-bold mr-3">{{ seg.percent }}%</span>
                                                <span class="text-muted">({{ formatNumber(seg.count) }})</span>
                                            </span>
                                        </div>
                                    </div>
                                </div>
                                <p v-else class="text-muted text-center mb-0 py-4">No data for this period</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 1d: Orders by Day of Week + Time of Day -->
                <div class="row mb-4">
                    <div class="col-12 col-lg-5 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Orders by Day of Week</h5></div>
                            <div class="card-body">
                                <apexchart
                                    type="bar"
                                    height="320"
                                    :options="dayOfWeekOptions"
                                    :series="dayOfWeekSeries"
                                ></apexchart>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-lg-7 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Orders by Time of Day</h5></div>
                            <div class="card-body">
                                <apexchart
                                    type="heatmap"
                                    height="320"
                                    :options="timeOfDayOptions"
                                    :series="timeOfDaySeries"
                                ></apexchart>
                                <p class="text-muted small text-center mb-0 mt-1">All times shown in IST (UTC +05:30)</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 1e: Order Type Performance -->
                <div class="row mb-4">
                    <div class="col-12 mb-3">
                        <div class="card">
                            <div class="card-header"><h5 class="mb-0">Order Type Performance</h5></div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-bordered table-sm table-hover mb-0" v-if="orderTypePerformance.rows.length > 0">
                                        <thead class="thead-light">
                                            <tr>
                                                <th>Order Type</th>
                                                <th class="text-right">Total Orders</th>
                                                <th class="text-right">Completed</th>
                                                <th class="text-right">Cancelled</th>
                                                <th class="text-right">Returned</th>
                                                <th class="text-right">Avg Order Value</th>
                                                <th class="text-right">Completion Rate</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="row in orderTypePerformance.rows" :key="row.type">
                                                <td>{{ row.type }}</td>
                                                <td class="text-right">{{ formatNumber(row.total) }}</td>
                                                <td class="text-right text-success">{{ formatNumber(row.completed) }}</td>
                                                <td class="text-right text-danger">{{ formatNumber(row.cancelled) }}</td>
                                                <td class="text-right">{{ formatNumber(row.returned) }}</td>
                                                <td class="text-right">₹{{ formatNumber(row.avg_order_value) }}</td>
                                                <td class="text-right font-weight-bold">{{ row.completion_rate }}%</td>
                                            </tr>
                                        </tbody>
                                        <tfoot v-if="orderTypePerformance.totals">
                                            <tr class="font-weight-bold thead-light">
                                                <td>Total</td>
                                                <td class="text-right">{{ formatNumber(orderTypePerformance.totals.total) }}</td>
                                                <td class="text-right text-success">{{ formatNumber(orderTypePerformance.totals.completed) }}</td>
                                                <td class="text-right text-danger">{{ formatNumber(orderTypePerformance.totals.cancelled) }}</td>
                                                <td class="text-right">{{ formatNumber(orderTypePerformance.totals.returned) }}</td>
                                                <td class="text-right">₹{{ formatNumber(orderTypePerformance.totals.avg_order_value) }}</td>
                                                <td class="text-right">{{ orderTypePerformance.totals.completion_rate }}%</td>
                                            </tr>
                                        </tfoot>
                                    </table>
                                    <p v-else class="text-muted text-center mb-0">No data for this period</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 2: Orders Over Time + Revenue Over Time -->
                <div class="row mb-4">
                    <div class="col-12 col-lg-6 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Orders Over Time</h5></div>
                            <div class="card-body">
                                <apexchart
                                    type="bar"
                                    height="320"
                                    :options="ordersOverTimeOptions"
                                    :series="ordersOverTimeSeries"
                                ></apexchart>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-lg-6 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Revenue Over Time</h5></div>
                            <div class="card-body">
                                <apexchart
                                    type="area"
                                    height="320"
                                    :options="revenueOverTimeOptions"
                                    :series="revenueOverTimeSeries"
                                ></apexchart>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 3: Status Breakdown + Payment Method -->
                <div class="row mb-4">
                    <div class="col-12 col-lg-6 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Order Status Breakdown</h5></div>
                            <div class="card-body d-flex justify-content-center">
                                <apexchart
                                    v-if="statusBreakdown.values.length > 0"
                                    type="donut"
                                    height="320"
                                    :options="statusBreakdownOptions"
                                    :series="statusBreakdown.values"
                                ></apexchart>
                                <p v-else class="text-muted mt-5">No data for this period</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-lg-6 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Payment Methods</h5></div>
                            <div class="card-body d-flex justify-content-center">
                                <apexchart
                                    v-if="paymentMethodSplit.values.length > 0"
                                    type="pie"
                                    height="320"
                                    :options="paymentMethodOptions"
                                    :series="paymentMethodSplit.values"
                                ></apexchart>
                                <p v-else class="text-muted mt-5">No data for this period</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 4: Revenue Breakdown (Stacked Bar) -->
                <div class="row mb-4">
                    <div class="col-12 mb-3">
                        <div class="card">
                            <div class="card-header"><h5 class="mb-0">Revenue Breakdown</h5></div>
                            <div class="card-body">
                                <apexchart
                                    type="bar"
                                    height="350"
                                    :options="revenueBreakdownOptions"
                                    :series="revenueBreakdownSeries"
                                ></apexchart>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 4b: Combo Performance -->
                <div class="row mb-4">
                    <div class="col-12 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Combo Performance</h5></div>
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-6 col-lg-3 mb-3">
                                        <div class="card h-100 summary-card" :style="{ borderLeft: '4px solid #9AC444' }">
                                            <div class="card-body py-3">
                                                <span class="text-muted small text-uppercase">Combo Orders</span>
                                                <h4 class="mb-0 mt-1 font-weight-bold">{{ formatNumber(comboPerformance.combo_orders) }}</h4>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-6 col-lg-3 mb-3">
                                        <div class="card h-100 summary-card" :style="{ borderLeft: '4px solid #008FFB' }">
                                            <div class="card-body py-3">
                                                <span class="text-muted small text-uppercase">Combos Sold</span>
                                                <h4 class="mb-0 mt-1 font-weight-bold">{{ formatNumber(comboPerformance.combos_sold) }}</h4>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-6 col-lg-3 mb-3">
                                        <div class="card h-100 summary-card" :style="{ borderLeft: '4px solid #00E396' }">
                                            <div class="card-body py-3">
                                                <span class="text-muted small text-uppercase">Combo Revenue</span>
                                                <h4 class="mb-0 mt-1 font-weight-bold">₹{{ formatNumber(comboPerformance.combo_revenue) }}</h4>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-6 col-lg-3 mb-3">
                                        <div class="card h-100 summary-card" :style="{ borderLeft: '4px solid #FEB019' }">
                                            <div class="card-body py-3">
                                                <span class="text-muted small text-uppercase">Combo Savings</span>
                                                <h4 class="mb-0 mt-1 font-weight-bold">₹{{ formatNumber(comboPerformance.combo_savings) }}</h4>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <h6 class="mt-2 mb-2 text-muted">Top Combos</h6>
                                <div class="table-responsive">
                                    <table class="table table-sm table-hover mb-0" v-if="comboPerformance.top_combos && comboPerformance.top_combos.length > 0">
                                        <thead class="thead-light">
                                            <tr>
                                                <th>#</th>
                                                <th>Combo</th>
                                                <th class="text-right">Qty Sold</th>
                                                <th class="text-right">Revenue</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="(c, i) in comboPerformance.top_combos" :key="c.name + i">
                                                <td>{{ i + 1 }}</td>
                                                <td>{{ c.name }}</td>
                                                <td class="text-right font-weight-bold">{{ formatNumber(c.qty) }}</td>
                                                <td class="text-right">₹{{ formatNumber(c.revenue) }}</td>
                                            </tr>
                                        </tbody>
                                    </table>
                                    <p v-else class="text-muted mb-0">No combo orders in this period</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 5: Delivery Trends -->
                <div class="row mb-4">
                    <div class="col-12 col-lg-8 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Delivery Charges & Tips Trend</h5></div>
                            <div class="card-body">
                                <apexchart
                                    type="line"
                                    height="320"
                                    :options="deliveryTrendOptions"
                                    :series="deliveryTrendSeries"
                                ></apexchart>
                            </div>
                        </div>
                    </div>
                    <!-- Top Cancellation Reasons (hidden for now)
                    <div class="col-12 col-lg-4 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Top Cancellation Reasons</h5></div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-sm mb-0" v-if="topCancellationReasons.reasons.length > 0">
                                        <thead class="thead-light">
                                            <tr>
                                                <th>Reason</th>
                                                <th class="text-right">Orders</th>
                                                <th class="text-right">% of Cancelled Orders</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="r in topCancellationReasons.reasons" :key="r.reason">
                                                <td>{{ r.reason }}</td>
                                                <td class="text-right font-weight-bold">{{ formatNumber(r.orders) }}</td>
                                                <td class="text-right">
                                                    <div class="d-flex align-items-center justify-content-end">
                                                        <div class="cancel-bar-track mr-2">
                                                            <div class="cancel-bar-fill" :style="{ width: cancelBarWidth(r.percent) + '%' }"></div>
                                                        </div>
                                                        <span class="text-nowrap">{{ r.percent }}%</span>
                                                    </div>
                                                </td>
                                            </tr>
                                        </tbody>
                                        <tfoot>
                                            <tr class="font-weight-bold thead-light">
                                                <td>Total</td>
                                                <td class="text-right">{{ formatNumber(topCancellationReasons.total) }}</td>
                                                <td class="text-right">100%</td>
                                            </tr>
                                        </tfoot>
                                    </table>
                                    <p v-else class="text-muted text-center mb-0 py-4">No cancellations in this period</p>
                                </div>
                            </div>
                        </div>
                    </div>
                    -->
                </div>

                <!-- Row 6: Promo Usage + Quick Stats Table -->
                <div class="row mb-4">
                    <div class="col-12 col-lg-4 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Promo Code Usage</h5></div>
                            <div class="card-body d-flex justify-content-center">
                                <apexchart
                                    v-if="orderTypeSplit.promo_usage.values.some(v => v > 0)"
                                    type="donut"
                                    height="280"
                                    :options="promoUsageOptions"
                                    :series="orderTypeSplit.promo_usage.values"
                                ></apexchart>
                                <p v-else class="text-muted mt-5">No data for this period</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-lg-8 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Financial Summary</h5></div>
                            <div class="card-body">
                                <table class="table table-bordered table-sm">
                                    <thead class="thead-light">
                                        <tr>
                                            <th>Metric</th>
                                            <th class="text-right">Amount</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="row in financialTableRows" :key="row.label">
                                            <td>
                                                <span :class="row.isCredit ? 'text-danger' : ''">
                                                    {{ row.isCredit ? '(-)' : '' }} {{ row.label }}
                                                </span>
                                            </td>
                                            <td class="text-right font-weight-bold" :class="row.isCredit ? 'text-danger' : 'text-success'">
                                                {{ row.prefix }}{{ formatNumber(row.value) }}
                                            </td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Row 7: Coupon Analytics -->
                <div class="row mb-4" v-if="couponAnalytics">
                    <!-- Coupon Summary Cards -->
                    <div class="col-12 mb-3">
                        <div class="card">
                            <div class="card-header"><h5 class="mb-0">Coupon / Promo Analytics</h5></div>
                            <div class="card-body">
                                <div class="row mb-3">
                                    <div class="col-6 col-lg-2 mb-2" v-for="cs in couponSummaryCards" :key="cs.label">
                                        <div class="text-center p-2 rounded" style="background: #f8f9fa;">
                                            <span class="text-muted small text-uppercase d-block">{{ cs.label }}</span>
                                            <h5 class="mb-0 mt-1 font-weight-bold" :style="{ color: cs.color }">{{ cs.prefix }}{{ formatNumber(cs.value) }}{{ cs.suffix }}</h5>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Top Coupons Bar Chart -->
                    <div class="col-12 col-lg-6 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Top Coupons by Usage</h5></div>
                            <div class="card-body">
                                <apexchart
                                    v-if="couponAnalytics.chart && couponAnalytics.chart.labels.length > 0"
                                    type="bar"
                                    height="320"
                                    :options="topCouponsUsageOptions"
                                    :series="topCouponsUsageSeries"
                                ></apexchart>
                                <p v-else class="text-muted text-center mt-5">No coupon data for this period</p>
                            </div>
                        </div>
                    </div>

                    <!-- Top Coupons by Discount Given -->
                    <div class="col-12 col-lg-6 mb-3">
                        <div class="card h-100">
                            <div class="card-header"><h5 class="mb-0">Top Coupons by Discount Given</h5></div>
                            <div class="card-body">
                                <apexchart
                                    v-if="couponAnalytics.chart && couponAnalytics.chart.labels.length > 0"
                                    type="bar"
                                    height="320"
                                    :options="topCouponsDiscountOptions"
                                    :series="topCouponsDiscountSeries"
                                ></apexchart>
                                <p v-else class="text-muted text-center mt-5">No coupon data for this period</p>
                            </div>
                        </div>
                    </div>

                    <!-- Top Coupons Detail Table -->
                    <div class="col-12 mb-3">
                        <div class="card">
                            <div class="card-header"><h5 class="mb-0">Coupon Details</h5></div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-bordered table-sm table-hover" v-if="couponAnalytics.top_coupons && couponAnalytics.top_coupons.length > 0">
                                        <thead class="thead-light">
                                            <tr>
                                                <th>#</th>
                                                <th>Promo Code</th>
                                                <th>Type</th>
                                                <th>Discount Value</th>
                                                <th>Max Discount</th>
                                                <th>Min Order</th>
                                                <th class="text-center">Times Used</th>
                                                <th class="text-right">Total Discount Given</th>
                                                <th class="text-right">Avg Discount</th>
                                                <th class="text-right">Revenue Generated</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="(coupon, index) in couponAnalytics.top_coupons" :key="coupon.promo_code">
                                                <td>{{ index + 1 }}</td>
                                                <td><span class="badge badge-success" style="background-color:#9AC444;color:#fff;">{{ coupon.promo_code }}</span></td>
                                                <td>{{ coupon.discount_type }}</td>
                                                <td>{{ coupon.discount_type === 'percentage' ? coupon.discount_value + '%' : '\u20B9' + formatNumber(coupon.discount_value) }}</td>
                                                <td>&#8377;{{ formatNumber(coupon.max_discount_amount) }}</td>
                                                <td>&#8377;{{ formatNumber(coupon.min_order_amount) }}</td>
                                                <td class="text-center font-weight-bold">{{ coupon.usage_count }}</td>
                                                <td class="text-right text-danger font-weight-bold">&#8377;{{ formatNumber(coupon.total_discount_given) }}</td>
                                                <td class="text-right">&#8377;{{ formatNumber(coupon.avg_discount) }}</td>
                                                <td class="text-right text-success font-weight-bold">&#8377;{{ formatNumber(coupon.total_revenue) }}</td>
                                            </tr>
                                        </tbody>
                                    </table>
                                    <p v-else class="text-muted text-center">No coupons used in this period</p>
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
    name: "OrderAnalytics",
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
            custom_filter: '',
            store_id: '',
            seller_id: '',
            cities: [],
            stores: [],
            sellers: [],
            analyticsData: null,
            filterOptions: [
                { label: 'Today', value: 'daily' },
                { label: 'This Week', value: 'weekly' },
                { label: 'This Month', value: 'monthly' },
                { label: 'Custom', value: 'custom' },
            ],
            chartColors: ['#9AC444', '#008FFB', '#FEB019', '#FF4560', '#775DD0', '#00E396', '#F86624', '#546E7A'],
            statusColors: {
                'Received': '#008FFB',
                'Processed': '#FEB019',
                'Out for Delivery': '#775DD0',
                'Delivered': '#9AC444',
                'Cancelled': '#FF4560',
                'Returned': '#F86624',
                'Pre-order Pending': '#546E7A',
            },
        };
    },
    created() {
        this.getCities();
        this.getStores();
        this.fetchAnalytics();
    },
    computed: {
        summary() {
            return this.analyticsData?.summary || {};
        },
        ordersOverTime() {
            return this.analyticsData?.orders_over_time || { labels: [], order_counts: [], revenues: [] };
        },
        statusBreakdown() {
            return this.analyticsData?.status_breakdown || { labels: [], values: [] };
        },
        // Groups the raw per-status breakdown into the four headline outcomes
        // (Completed / Cancelled / Returned / Ongoing). "Ongoing" is every order
        // still in the pipeline, i.e. total minus the three terminal outcomes.
        ordersByStatus() {
            const sb = this.statusBreakdown;
            const map = {};
            (sb.labels || []).forEach((label, i) => { map[label] = (map[label] || 0) + (sb.values[i] || 0); });
            const totalAll = (sb.values || []).reduce((a, b) => a + (parseFloat(b) || 0), 0);
            const completed = map['Delivered'] || 0;
            const cancelled = map['Cancelled'] || 0;
            const returned = map['Returned'] || 0;
            const ongoing = Math.max(totalAll - completed - cancelled - returned, 0);
            const segments = [
                { label: 'Completed', count: completed, color: '#9AC444' },
                { label: 'Cancelled', count: cancelled, color: '#FF4560' },
                { label: 'Returned', count: returned, color: '#FEB019' },
                { label: 'Ongoing', count: ongoing, color: '#775DD0' },
            ].map(s => ({ ...s, percent: totalAll > 0 ? Math.round((s.count / totalAll) * 1000) / 10 : 0 }));
            return { total: totalAll, segments, values: segments.map(s => s.count) };
        },
        paymentMethodSplit() {
            return this.analyticsData?.payment_method_split || { labels: [], values: [] };
        },
        topCancellationReasons() {
            return this.analyticsData?.top_cancellation_reasons || { reasons: [], total: 0 };
        },
        revenueBreakdown() {
            return this.analyticsData?.revenue_breakdown || {};
        },
        comboPerformance() {
            return this.analyticsData?.combo_performance || {
                combo_orders: 0,
                combos_sold: 0,
                combo_revenue: 0,
                combo_savings: 0,
                top_combos: [],
            };
        },
        deliveryTrend() {
            return this.analyticsData?.delivery_trend || { labels: [], delivery_charges: [], delivery_tips: [] };
        },
        orderTypeSplit() {
            return this.analyticsData?.order_type_split || {
                delivery_type: { labels: [], values: [] },
                order_mode: { labels: [], values: [] },
                promo_usage: { labels: [], values: [] },
            };
        },
        ordersByType() {
            return this.analyticsData?.orders_by_type || { labels: [], values: [], total_orders: 0, classified: 0, coverage_percent: 0 };
        },
        topCities() {
            return this.analyticsData?.top_cities || { cities: [], total_geolocated: 0 };
        },
        ordersByTime() {
            return this.analyticsData?.orders_by_time || { days: [], day_of_week: [], time_of_day: { blocks: [], matrix: {} } };
        },
        orderTypePerformance() {
            return this.analyticsData?.order_type_performance || { rows: [], totals: null };
        },

        // Comparison block (current vs previous period) already returned by the API.
        comparison() {
            return this.analyticsData?.profit_loss_comparison || null;
        },

        // Order outcome counts derived from the existing status_breakdown payload.
        statusCounts() {
            const map = {};
            const sb = this.statusBreakdown;
            (sb.labels || []).forEach((label, i) => { map[label] = sb.values[i]; });
            const total = parseFloat(this.summary.total_orders) || 0;
            const cancelled = map['Cancelled'] || 0;
            return {
                completed: map['Delivered'] || 0,
                cancelled: cancelled,
                returned: map['Returned'] || 0,
                cancellation_rate: total > 0 ? Math.round((cancelled / total) * 1000) / 10 : 0,
            };
        },

        currentPeriodLabel() {
            if (this.comparison?.current_period) return this.comparison.current_period;
            if (this.analyticsData) {
                return this.formatDate(this.analyticsData.start_date) + ' - ' + this.formatDate(this.analyticsData.end_date);
            }
            return '';
        },
        comparePeriodLabel() {
            return this.comparison?.previous_period || '';
        },

        // Summary cards
        summaryCards() {
            const s = this.summary;
            const sc = this.statusCounts;
            return [
                // Order-outcome cards (counts come from status_breakdown; rate is derived)
                { label: 'Total Orders', value: s.total_orders, prefix: '', color: '#008FFB', compareKey: 'orders' },
                { label: 'Completed Orders', value: sc.completed, prefix: '', color: '#9AC444' },
                { label: 'Cancelled Orders', value: sc.cancelled, prefix: '', color: '#FF4560' },
                { label: 'Returned Orders', value: sc.returned, prefix: '', color: '#F86624' },
                { label: 'Cancellation Rate', value: sc.cancellation_rate, prefix: '', suffix: '%', color: '#775DD0' },
                { label: 'Avg Order Value', value: s.avg_order_value, prefix: '\u20B9', color: '#FEB019', compareKey: 'avg_order_value' },
                // Existing financial cards (preserved)
                { label: 'Total Revenue', value: s.total_revenue, prefix: '\u20B9', color: '#9AC444', compareKey: 'revenue' },
                { label: 'Total MRP', value: s.total_mrp, prefix: '\u20B9', color: '#775DD0' },
                { label: 'Delivery Charges', value: s.total_delivery_charge, prefix: '\u20B9', color: '#00E396', compareKey: 'delivery_charges' },
                { label: 'Delivery Tips', value: s.total_delivery_tips, prefix: '\u20B9', color: '#F86624' },
                { label: 'Promo Discounts', value: s.total_promo_discount, prefix: '\u20B9', color: '#546E7A', compareKey: 'promo_discount' },
            ];
        },

        // Orders Over Time Chart
        ordersOverTimeOptions() {
            return {
                chart: { type: 'bar', toolbar: { show: true } },
                colors: ['#9AC444'],
                xaxis: { categories: this.ordersOverTime.labels },
                yaxis: { title: { text: 'Orders' } },
                dataLabels: { enabled: true },
                plotOptions: { bar: { borderRadius: 4, columnWidth: '50%' } },
            };
        },
        ordersOverTimeSeries() {
            return [{ name: 'Orders', data: this.ordersOverTime.order_counts }];
        },

        // Revenue Over Time Chart
        revenueOverTimeOptions() {
            return {
                chart: { type: 'area', toolbar: { show: true } },
                colors: ['#9AC444', '#008FFB'],
                xaxis: { categories: this.ordersOverTime.labels },
                yaxis: { title: { text: 'Amount (\u20B9)' }, labels: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
                dataLabels: { enabled: false },
                stroke: { curve: 'smooth', width: 2 },
                fill: { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: 0.4, opacityTo: 0.1 } },
                tooltip: { y: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
            };
        },
        revenueOverTimeSeries() {
            return [
                { name: 'Revenue', data: this.ordersOverTime.revenues },
                { name: 'MRP', data: this.ordersOverTime.mrps || [] },
            ];
        },

        // Multi-series Orders Trend (Total / Completed / Cancelled). Granularity
        // is driven by the page filter (Today/Week/Month/Custom), same as the
        // other time-series charts.
        ordersTrendOptions() {
            return {
                chart: { type: 'line', toolbar: { show: true } },
                colors: ['#008FFB', '#9AC444', '#FF4560'],
                xaxis: { categories: this.ordersOverTime.labels },
                yaxis: { title: { text: 'Orders' } },
                stroke: { curve: 'smooth', width: 2 },
                markers: { size: 3 },
                legend: { position: 'top' },
                dataLabels: { enabled: false },
            };
        },
        ordersTrendSeries() {
            return [
                { name: 'Total Orders', data: this.ordersOverTime.order_counts || [] },
                { name: 'Completed Orders', data: this.ordersOverTime.completed_counts || [] },
                { name: 'Cancelled Orders', data: this.ordersOverTime.cancelled_counts || [] },
            ];
        },

        // Orders by Type donut (Restaurant / Grocery / Combo / Uncategorized)
        ordersByTypeOptions() {
            const colorMap = {
                'Restaurant Orders': '#9AC444',
                'Grocery Orders': '#008FFB',
                'Combo Orders': '#FEB019',
                'Uncategorized': '#B0BEC5',
            };
            return {
                chart: { type: 'donut' },
                labels: this.ordersByType.labels,
                colors: this.ordersByType.labels.map(l => colorMap[l] || '#546E7A'),
                legend: { position: 'bottom' },
                dataLabels: { enabled: true },
                responsive: [{ breakpoint: 480, options: { chart: { width: 300 }, legend: { position: 'bottom' } } }],
            };
        },

        // Orders by Day of Week (bar)
        dayOfWeekOptions() {
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                colors: ['#9AC444'],
                plotOptions: { bar: { borderRadius: 4, columnWidth: '55%' } },
                xaxis: { categories: this.ordersByTime.days },
                yaxis: { title: { text: 'Orders' } },
                dataLabels: { enabled: true },
            };
        },
        dayOfWeekSeries() {
            return [{ name: 'Orders', data: this.ordersByTime.day_of_week || [] }];
        },

        // Orders by Time of Day (heatmap: 4-hour blocks x weekday)
        timeOfDayOptions() {
            return {
                chart: { type: 'heatmap', toolbar: { show: false } },
                dataLabels: { enabled: true },
                colors: ['#9AC444'],
                xaxis: { categories: this.ordersByTime.days },
                plotOptions: { heatmap: { shadeIntensity: 0.6, radius: 2, enableShades: true } },
                legend: { show: false },
            };
        },
        timeOfDaySeries() {
            const t = this.ordersByTime.time_of_day || { blocks: [], matrix: {} };
            const days = this.ordersByTime.days || [];
            // ApexCharts stacks heatmap rows bottom-up; reverse so the earliest
            // block (12 AM - 4 AM) renders at the top, matching the design.
            return (t.blocks || []).slice().reverse().map(block => ({
                name: block,
                data: days.map((d, i) => ({ x: d, y: (t.matrix[block] && t.matrix[block][i]) || 0 })),
            }));
        },

        // Status Breakdown Donut
        statusBreakdownOptions() {
            const colors = this.statusBreakdown.labels.map(l => this.statusColors[l] || '#546E7A');
            return {
                chart: { type: 'donut' },
                labels: this.statusBreakdown.labels,
                colors: colors,
                legend: { position: 'bottom' },
                responsive: [{ breakpoint: 480, options: { chart: { width: 300 }, legend: { position: 'bottom' } } }],
            };
        },

        // Orders by Status Donut (total in the centre, custom legend to the side)
        ordersByStatusOptions() {
            const segments = this.ordersByStatus.segments;
            return {
                chart: { type: 'donut' },
                labels: segments.map(s => s.label),
                colors: segments.map(s => s.color),
                legend: { show: false },
                dataLabels: { enabled: false },
                stroke: { width: 2 },
                plotOptions: {
                    pie: {
                        donut: {
                            size: '72%',
                            labels: {
                                show: true,
                                value: {
                                    fontSize: '26px',
                                    fontWeight: 700,
                                    formatter: (v) => this.formatNumber(v),
                                },
                                total: {
                                    show: true,
                                    label: 'Total Orders',
                                    fontSize: '13px',
                                    color: '#8a8a8a',
                                    formatter: () => this.formatNumber(this.ordersByStatus.total),
                                },
                            },
                        },
                    },
                },
                tooltip: { y: { formatter: (v) => this.formatNumber(v) + ' orders' } },
                responsive: [{ breakpoint: 480, options: { chart: { width: 280 } } }],
            };
        },

        // Payment Method Pie
        paymentMethodOptions() {
            return {
                chart: { type: 'pie' },
                labels: this.paymentMethodSplit.labels,
                colors: this.chartColors,
                legend: { position: 'bottom' },
            };
        },

        // Revenue Breakdown Horizontal Bar
        revenueBreakdownOptions() {
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                plotOptions: { bar: { horizontal: true, borderRadius: 4, barHeight: '60%' } },
                colors: ['#9AC444', '#008FFB', '#FF4560', '#FEB019', '#00E396', '#775DD0', '#F86624', '#546E7A', '#3F51B5'],
                xaxis: {
                    categories: ['Items MRP', 'Combo MRP', 'Discount', 'Delivery Charge', 'Delivery Tip', 'Promo Discount', 'Wallet Used', 'Rain Surcharge', 'GST'],
                    labels: { formatter: (v) => '\u20B9' + this.formatNumber(v) },
                },
                dataLabels: { enabled: true, formatter: (v) => '\u20B9' + this.formatNumber(v) },
                tooltip: { y: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
            };
        },
        revenueBreakdownSeries() {
            const rb = this.revenueBreakdown;
            return [{
                name: 'Amount',
                data: [
                    rb.items_mrp || 0,
                    rb.combo_mrp || 0,
                    rb.discount || 0,
                    rb.delivery_charge || 0,
                    rb.delivery_tip || 0,
                    rb.promo_discount || 0,
                    rb.wallet_deduction || 0,
                    rb.rain_surcharge || 0,
                    rb.gst_charges || 0,
                ],
            }];
        },

        // Delivery Trend Line Chart
        deliveryTrendOptions() {
            return {
                chart: { type: 'line', toolbar: { show: true } },
                colors: ['#008FFB', '#9AC444', '#FEB019'],
                xaxis: { categories: this.deliveryTrend.labels },
                yaxis: { title: { text: 'Amount (\u20B9)' }, labels: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
                stroke: { curve: 'smooth', width: 3 },
                markers: { size: 4 },
                tooltip: { y: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
            };
        },
        deliveryTrendSeries() {
            return [
                { name: 'Delivery Charges', data: this.deliveryTrend.delivery_charges },
                { name: 'Delivery Tips', data: this.deliveryTrend.delivery_tips },
                { name: 'Rain Surcharge', data: this.deliveryTrend.rain_surcharges || [] },
            ];
        },

        // Order Type Donuts
        deliveryTypeOptions() {
            return {
                chart: { type: 'donut' },
                labels: this.orderTypeSplit.delivery_type.labels,
                colors: ['#9AC444', '#008FFB'],
                legend: { position: 'bottom', fontSize: '11px' },
                dataLabels: { enabled: true },
            };
        },
        orderModeOptions() {
            return {
                chart: { type: 'donut' },
                labels: this.orderTypeSplit.order_mode.labels,
                colors: ['#008FFB', '#FEB019'],
                legend: { position: 'bottom', fontSize: '11px' },
                dataLabels: { enabled: true },
            };
        },
        promoUsageOptions() {
            return {
                chart: { type: 'donut' },
                labels: this.orderTypeSplit.promo_usage.labels,
                colors: ['#546E7A', '#9AC444'],
                legend: { position: 'bottom' },
            };
        },

        // Coupon Analytics
        couponAnalytics() {
            return this.analyticsData?.coupon_analytics || null;
        },
        couponSummaryCards() {
            const cs = this.couponAnalytics?.summary || {};
            return [
                { label: 'Orders with Promo', value: cs.total_orders_with_promo, prefix: '', suffix: '', color: '#9AC444' },
                { label: 'Promo Usage Rate', value: cs.promo_usage_rate, prefix: '', suffix: '%', color: '#008FFB' },
                { label: 'Unique Coupons Used', value: cs.unique_coupons_used, prefix: '', suffix: '', color: '#775DD0' },
                { label: 'Total Promo Discount', value: cs.total_promo_discount, prefix: '\u20B9', suffix: '', color: '#FF4560' },
                { label: 'Avg Discount/Order', value: cs.avg_promo_discount, prefix: '\u20B9', suffix: '', color: '#FEB019' },
            ];
        },
        topCouponsUsageOptions() {
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                colors: ['#9AC444'],
                plotOptions: { bar: { borderRadius: 4, columnWidth: '60%' } },
                xaxis: { categories: this.couponAnalytics?.chart?.labels || [] },
                yaxis: { title: { text: 'Times Used' } },
                dataLabels: { enabled: true },
            };
        },
        topCouponsUsageSeries() {
            return [{ name: 'Usage Count', data: this.couponAnalytics?.chart?.usage_counts || [] }];
        },
        topCouponsDiscountOptions() {
            return {
                chart: { type: 'bar', toolbar: { show: false } },
                colors: ['#FF4560'],
                plotOptions: { bar: { borderRadius: 4, columnWidth: '60%' } },
                xaxis: { categories: this.couponAnalytics?.chart?.labels || [] },
                yaxis: { title: { text: 'Discount (\u20B9)' }, labels: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
                dataLabels: { enabled: true, formatter: (v) => '\u20B9' + this.formatNumber(v) },
                tooltip: { y: { formatter: (v) => '\u20B9' + this.formatNumber(v) } },
            };
        },
        topCouponsDiscountSeries() {
            return [{ name: 'Discount Given', data: this.couponAnalytics?.chart?.discounts || [] }];
        },

        // Financial Summary Table
        financialTableRows() {
            const rb = this.revenueBreakdown;
            return [
                { label: 'Items MRP', value: rb.items_mrp || 0, prefix: '\u20B9', isCredit: false },
                { label: 'Combo MRP', value: rb.combo_mrp || 0, prefix: '\u20B9', isCredit: false },
                { label: 'Discount', value: rb.discount || 0, prefix: '\u20B9', isCredit: true },
                { label: 'Promo Discount', value: rb.promo_discount || 0, prefix: '\u20B9', isCredit: true },
                { label: 'Wallet Deduction', value: rb.wallet_deduction || 0, prefix: '\u20B9', isCredit: true },
                { label: 'Delivery Charge', value: rb.delivery_charge || 0, prefix: '\u20B9', isCredit: false },
                { label: 'Delivery Tip', value: rb.delivery_tip || 0, prefix: '\u20B9', isCredit: false },
                { label: 'Rain Surcharge', value: rb.rain_surcharge || 0, prefix: '\u20B9', isCredit: false },
                { label: 'Multi Order Charges', value: rb.multi_order_charges || 0, prefix: '\u20B9', isCredit: false },
                { label: 'GST Charges', value: rb.gst_charges || 0, prefix: '\u20B9', isCredit: false },
                { label: 'Net Revenue (To Be Paid)', value: rb.to_be_paid || 0, prefix: '\u20B9', isCredit: false },
            ];
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
        getStores() {
            axios.get(this.$apiUrl + '/stores')
                .then((response) => {
                    if (response.data.status === 1) {
                        this.stores = response.data.data || [];
                    }
                })
                .catch(() => {});
        },
        getSellers(storeId) {
            if (!storeId) {
                this.sellers = [];
                return;
            }

            // Build params with city_id if available
            let params = {};
            if (this.city_id) {
                params.city_id = this.city_id;
            }

            axios.get(this.$apiUrl + '/stores/' + storeId + '/sellers', { params })
                .then((response) => {
                    if (response.data.status === 1) {
                        this.sellers = response.data.data || [];
                    }
                })
                .catch(() => {
                    this.sellers = [];
                });
        },
        onStoreChange() {
            this.seller_id = ''; // Reset seller when store changes
            this.getSellers(this.store_id);
            this.fetchAnalytics();
        },
        onCityChange() {
            // If a store is selected, reload sellers with city filter
            if (this.store_id) {
                this.seller_id = ''; // Reset seller when city changes
                this.getSellers(this.store_id);
            }
            this.fetchAnalytics();
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
            if (this.custom_filter !== '') {
                params.custom_filter = this.custom_filter;
            }
            if (this.store_id) {
                params.store_id = this.store_id;
            }
            if (this.seller_id) {
                params.seller_id = this.seller_id;
            }
            axios.get(this.$apiUrl + '/order-analytics', { params })
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
        // Scales a cancellation-reason bar relative to the largest reason so the
        // top reason fills the track and the rest are proportional to it.
        cancelBarWidth(percent) {
            const max = Math.max(...this.topCancellationReasons.reasons.map(r => r.percent), 1);
            return max > 0 ? Math.round((percent / max) * 100) : 0;
        },
        formatNumber(value) {
            if (value === undefined || value === null) return '0';
            const num = parseFloat(value);
            if (isNaN(num)) return '0';
            if (Number.isInteger(num)) return num.toLocaleString('en-IN');
            return num.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        },
        // Format an ISO date (YYYY-MM-DD) as "01 Jun 2026" for the period display.
        formatDate(value) {
            if (!value) return '';
            const d = new Date(value);
            if (isNaN(d.getTime())) return value;
            return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
        },
        // Returns the comparison metric block for a card, or null if no comparison
        // data exists for it. Arrow direction uses is_positive (raw change);
        // colour uses is_favorable (good/bad for the business).
        cardTrend(card) {
            if (!card.compareKey || !this.comparison) return null;
            const m = this.comparison.metrics ? this.comparison.metrics[card.compareKey] : null;
            if (!m) return null;
            return Object.assign({}, m, { abs_percent: Math.abs(m.change_percent) });
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
            if (this.custom_filter !== '') {
                params.custom_filter = this.custom_filter;
            }
            if (this.store_id) {
                params.store_id = this.store_id;
            }
            if (this.seller_id) {
                params.seller_id = this.seller_id;
            }
            return params;
        },
        downloadExcel(section) {
            const params = this.getExportParams(section);
            axios.get(this.$apiUrl + '/order-analytics/export-excel', { params, responseType: 'blob' })
                .then((response) => {
                    const url = window.URL.createObjectURL(new Blob([response.data]));
                    const link = document.createElement('a');
                    link.href = url;
                    link.setAttribute('download', 'order_analytics_' + section + '.xlsx');
                    document.body.appendChild(link);
                    link.click();
                    link.remove();
                    window.URL.revokeObjectURL(url);
                })
                .catch((error) => console.error('Excel download failed:', error));
        },
        downloadPdf(section) {
            const params = this.getExportParams(section);
            axios.get(this.$apiUrl + '/order-analytics/export-pdf', { params, responseType: 'blob' })
                .then((response) => {
                    const url = window.URL.createObjectURL(new Blob([response.data], { type: 'application/pdf' }));
                    const link = document.createElement('a');
                    link.href = url;
                    link.setAttribute('download', 'order_analytics_' + section + '.pdf');
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
.status-dot {
    display: inline-block;
    width: 11px;
    height: 11px;
    border-radius: 50%;
    flex-shrink: 0;
}
.status-legend-label {
    font-weight: 500;
}
.status-legend-row:not(:last-child) {
    border-bottom: 1px solid #f0f0f0;
}
.cancel-bar-track {
    width: 60px;
    height: 6px;
    border-radius: 4px;
    background: #f0f0f0;
    overflow: hidden;
    flex-shrink: 0;
}
.cancel-bar-fill {
    height: 100%;
    background: #FF4560;
    border-radius: 4px;
}
</style>
