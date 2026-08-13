<template>
    <div>
        <div class="page-heading">
            <h3>{{ __('dashboard') }}</h3>
        </div>
        <div class="page-content">
            <section class="row">
                <div class="row">
                    <div class="col-12 col-xxl-6">
                        <div class="row">
                            <div class="col-6 col-lg-3 col-md-3 col-sm-6">
                                <div class="card stats-card">
                                    <router-link to="/orders">
                                        <div class="card-body">
                                            <div class="d-flex flex-column align-items-center text-center">
                                                <div class="stats-icon-big blue">
                                                    <i class="fa fa-shopping-bag"></i>
                                                </div>
                                                <h3>{{ record.order_count }}</h3>
                                                <h5>{{ __('orders') }}</h5>
                                            </div>
                                        </div>
                                    </router-link>
                                </div>
                            </div>
                            <!-- <div class="col-6 col-lg-3 col-md-3 col-sm-6">
                                <div class="card stats-card">
                                    <router-link to="/manage_products">
                                        <div class="card-body">
                                            <div class="d-flex flex-column align-items-center text-center">
                                                <div class="stats-icon-big orange">
                                                    <i class="fa fa-cube"></i>
                                                </div>
                                                <h3>{{ record.product_count }}</h3>
                                                <h5>{{ __('products') }}</h5>
                                            </div>
                                        </div>
                                    </router-link>
                                </div>
                            </div> -->
                            <div class="col-6 col-lg-3 col-md-3">
                                <div class="card stats-card">
                                    <router-link to="/users">
                                        <div class="card-body">
                                            <div class="d-flex flex-column align-items-center text-center">
                                                <div class="stats-icon-big sky">
                                                    <i class="fa fa-users"></i>
                                                </div>
                                                <h3>{{ record.customer_count }}</h3>
                                                <h5>{{__('customers')}}</h5>
                                            </div>
                                        </div>
                                    </router-link>
                                </div>
                            </div>
                            <div class="col-6 col-lg-3 col-md-3">
                                <div class="card stats-card">
                                    <router-link to="/sellers">
                                        <div class="card-body">
                                            <div class="d-flex flex-column align-items-center text-center">
                                                <div class="stats-icon-big lightgreen">
                                                    <i class="fa fa-store"></i>
                                                </div>
                                                <h3>{{ record.seller_count }}</h3>
                                                <h5>{{__('sellers')}}</h5>
                                            </div>
                                        </div>
                                    </router-link>
                                </div>
                            </div>

                            <div class="col-6 col-lg-3 col-md-3">
                                <div class="card stats-card">
                                    <router-link to="/manage_categories">
                                        <div class="card-body">
                                            <div class="d-flex flex-column align-items-center text-center">
                                                <div class="stats-icon-big purple">
                                                    <i class="fa fa-th-large"></i>
                                                </div>
                                                <h3>{{ record.category_count }}</h3>
                                                <h5>{{ __('categories') }}</h5>
                                            </div>
                                        </div>
                                    </router-link>
                                </div>
                            </div>
                            <!-- <div class="col-6 col-lg-3 col-md-3">
                                <div class="card stats-card">
                                    <router-link to="/brands">
                                        <div class="card-body">
                                            <div class="d-flex flex-column align-items-center text-center">
                                                <div class="stats-icon-big orange">
                                                    <i class="fa fa-certificate"></i>
                                                </div>
                                                <h3>{{ record.brand_count }}</h3>
                                                <h5>{{ __('brands') }}</h5>
                                            </div>
                                        </div>
                                    </router-link>
                                </div>
                            </div> -->
                            <div class="col-6 col-lg-3 col-md-3">
                                <div class="card stats-card">
                                    <router-link to="/cities">
                                        <div class="card-body">
                                            <div class="d-flex flex-column align-items-center text-center">
                                                <div class="stats-icon-big blue">
                                                    <i class="fa fa-map-marker-alt"></i>
                                                </div>
                                                <h3>{{ record.city_count }}</h3>
                                                <h5>{{ __('city') }}</h5>
                                            </div>
                                        </div>
                                    </router-link>
                                </div>
                            </div>
                        </div>

                    </div>

                </div>

                <!-- <div class="row">

                    <div class="col-12 col-lg-6 col-md-12">
                        <div class="card chart-card h-90">
                            <div class="card-header d-flex justify-content-between align-items-center">
                                <div>
                                    <h4 class="card-title me-1 mb-0">Order Sales (Monthly)</h4>
                                </div>
                                <div>
                                    <select class="form-select form-select-sm" v-model="salesPeriod" @change="barChart()">
                                        <option value="daily">{{__('daily')}}</option>
                                        <option value="weekly">{{__('weekly')}}</option>
                                        <option value="monthly">{{__('monthly')}}</option>
                                        <option value="yearly">{{__('yearly')}}</option>
                                        <option value="all">{{__('all_time')}}</option>
                                    </select>
                                </div>
                            </div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <apexchart width="100%" height="260" :options="options" :series="series"
                                               ref="apexBarChart"></apexchart>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="col-12 col-lg-6 col-md-12">
                        <div class="card chart-card h-90">
                            <div class="card-header d-flex justify-content-between align-items-center">
                                <div>
                                    <h4 class="card-title me-1 mb-0">Returned Orders (Monthly)</h4>
                                </div>
                                <div>
                                    <select class="form-select form-select-sm" v-model="returnsPeriod" @change="returnsChart()">
                                        <option value="daily">{{__('daily')}}</option>
                                        <option value="weekly">{{__('weekly')}}</option>
                                        <option value="monthly">{{__('monthly')}}</option>
                                        <option value="yearly">{{__('yearly')}}</option>
                                        <option value="all">{{__('all_time')}}</option>
                                    </select>
                                </div>
                            </div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <apexchart width="100%" height="260" :options="returnsOptions" :series="returnsSeries"
                                               ref="apexReturnsChart"></apexchart>
                                </div>
                            </div>
                        </div>
                    </div> -->

<!-- <div class="col-12 col-lg-5 col-md-12 products_sold">
                        <div class="row">
                            <div class="col-12 col-lg-6 col-md-6">
                                <div class="card">
                                    <div class="card-header text-center">
                                        <h6> {{ __('packet_products') }} </h6>
                                    </div>
                                    <div class="card-body">
                                        <h2 class="text-center">{{ record.packet_products }}</h2>

                                        <router-link :to="{ name: 'ProductInfo',params: { type: 'packet_products' }}"
                                                    class="btn btn-block btn-light-primary btn-lg btn_product_count">{{ __('more_info')}}
                                        </router-link>
                                    </div>

                                </div>
                            </div>
                            <div class="col-12 col-lg-6 col-md-6">
                                <div class="card">
                                    <div class="card-header text-center">
                                        <h6> {{ __('loose_products') }} </h6>
                                    </div>
                                    <div class="card-body">
                                        <h2 class="text-center">{{ record.loose_products }}</h2>
                                        <router-link :to="{ name: 'ProductInfo',params: { type: 'loose_products' }}" class="btn btn-lg btn-block btn-light-primary btn-lg btn_product_count">
                                            {{ __('more_info') }}
                                        </router-link>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="row">
                            <div class="col-12 col-lg-6 col-md-6">
                                <div class="card">
                                    <div class="card-header text-center">
                                        <h6> {{ __('products_sold_out') }} </h6>
                                    </div>
                                    <div class="card-body">
                                        <h2 class="text-center">{{ record.sold_out_count }}</h2>

                                        <router-link :to="{ name: 'ProductInfo',params: { type: 'sold_out' }}"
                                                    class="btn btn-block btn-light-primary btn-lg btn_product_count">{{ __('more_info')}}
                                        </router-link>
                                    </div>

                                </div>
                            </div>
                            <div class="col-12 col-lg-6 col-md-6">
                                <div class="card">
                                    <div class="card-header text-center">
                                        <h6> {{ __('products_in_low_stock') }} </h6>
                                    </div>
                                    <div class="card-body">
                                        <h2 class="text-center">{{ record.low_stock_count }}</h2>
                                        <router-link :to="{ name: 'ProductInfo',params: { type: 'low_stock' }}" class="btn btn-lg btn-block btn-light-primary btn-lg btn_product_count">
                                            {{ __('more_info') }}
                                        </router-link>
                                    </div>
                                </div>
                            </div>
                        </div>

                    </div> -->


<!-- <div class="row mt-4">
                    <div class="col-12 mb-4">
                        <h5 class="section-heading"> {{ __('order_out_lines') }} </h5>
                    </div>
                    <div class="col-6 col-sm-6 col-md-4 col-lg-3 col-xl-2 mb-3" v-for="status in record.status_order_count" :key="status.status">
                        <div class="card order-status-card h-100">
                            <div class="card-body text-center">
                                <div class="d-flex flex-column align-items-center">
                                    <div class="mb-3">
                                        <div v-if="status.status == $pending" class="stats-icon payment_pending">
                                            <img :src="$baseUrl + '/assets/images/dashboard/Payment_Pending.svg'" class="img-fluid">
                                        </div>
                                        <div v-else-if="status.status == $received" class="stats-icon received">
                                            <img :src="$baseUrl + '/assets/images/dashboard/Received.svg'" class="img-fluid">
                                        </div>
                                        <div v-else-if="status.status == $processed" class="stats-icon processed">
                                            <img :src="$baseUrl + '/assets/images/dashboard/Processed.svg'" class="img-fluid">
                                        </div>
                                        <div v-else-if="status.status == $shipped" class="stats-icon shipped">
                                            <img :src="$baseUrl + '/assets/images/dashboard/Shipped.svg'" class="img-fluid">
                                        </div>
                                        <div v-else-if="status.status == $outForDelivery" class="stats-icon outForDelivery">
                                            <img :src="$baseUrl + '/assets/images/dashboard/Out_For_Delivery.svg'" class="img-fluid">
                                        </div>
                                        <div v-else-if="status.status == $delivered" class="stats-icon delivered">
                                            <img :src="$baseUrl + '/assets/images/dashboard/Delivered.svg'" class="img-fluid">
                                        </div>
                                        <div v-else-if="status.status == $cancelled" class="stats-icon cancelled">
                                            <img :src="$baseUrl + '/assets/images/dashboard/Cancelled.svg'" class="img-fluid">
                                        </div>
                                        <div v-else-if="status.status == $returned" class="stats-icon returned">
                                            <img :src="$baseUrl + '/assets/images/dashboard/Returned.svg'" class="img-fluid">
                                        </div>
                                        <div v-else-if="status.status == 'Pending'" class="stats-icon payment_pending">
                                            <img :src="$baseUrl + '/assets/images/dashboard/Payment_Pending.svg'" class="img-fluid" />
                                        </div>
                                        <div v-else-if="status.status == 'Ready for Pickup'" class="stats-icon processed">
                                            <img :src="$baseUrl + '/assets/images/dashboard/Processed.svg'" class="img-fluid" />
                                        </div>
                                        <div v-else-if="status.status == 'Picked Up'" class="stats-icon delivered">
                                            <img :src="$baseUrl + '/assets/images/dashboard/Delivered.svg'" class="img-fluid" />
                                        </div>
                                        <div v-else class="stats-icon purple">
                                            <i class="iconly-boldBag"></i>
                                        </div>
                                    </div>
                                    <div class="order-status-text">
                                        <h3 class="status-count mb-2">{{ status.order_count }}</h3>
                                        <h6 v-if="status.status == $pending" class="status-label">{{ __('payment_pending') }}</h6>
                                        <h6 v-else-if="status.status == $received" class="status-label">{{ __('received') }}</h6>
                                        <h6 v-else-if="status.status == $processed" class="status-label">{{ __('processed') }}</h6>
                                        <h6 v-else-if="status.status == $shipped" class="status-label">{{ __('shipped') }}</h6>
                                        <h6 v-else-if="status.status == $outForDelivery" class="status-label">{{ __('outForDelivery') }}</h6>
                                        <h6 v-else-if="status.status == $delivered" class="status-label">{{ __('delivered') }}</h6>
                                        <h6 v-else-if="status.status == $cancelled" class="status-label">{{ __('cancelled') }}</h6>
                                        <h6 v-else-if="status.status == $returned" class="status-label">{{ __('returned') }}</h6>
                                        <h6 v-else-if="status.status == 'Pending'" class="status-label">{{ __('pending') }}</h6>
                                        <h6 v-else-if="status.status == 'Ready for Pickup'" class="status-label">{{ __('ready_for_pickup') }}</h6>
                                        <h6 v-else-if="status.status == 'Picked Up'" class="status-label">{{ __('picked_up') }}</h6>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div> -->


                <div class="row mt-4">

                    <!-- <div class="col-12" v-if="$can('order_list')">
                        <div class="card chart-card">
                            <div class="card-header">
                                <h4 class="card-title">{{__('latest_orders')}}</h4>
                            </div>
                            <div class="card-body">

                                <b-row class="mb-2">
                                    <b-col md="3">
                                        <h6 class="box-title">{{ __('from_and_to_date') }}</h6>
                                        <div class="d-flex justify-content-center align-items-center">
                                            <date-range-picker
                                                :autoApply=false
                                                :showDropdowns = true
                                                v-model="dateRange"
                                                :maxDate="maxDate"
                                                @update="getLatestOrders"
                                                :ranges="customRanges"
                                            ></date-range-picker>
                                            <button class="btn btn-sm btn-danger ml-1" @click="dateRange.startDate = null, dateRange.endDate = null, getLatestOrders()">
                                                {{ __('clear') }}
                                            </button>
                                        </div>
                                    </b-col>
                                    <b-col md="2">
                                        <div class="form-group">
                                            <h6 class="box-title" for="status">{{__('status')}}</h6>
                                            <select id="status" name="status" v-model="status"
                                                    @change="getLatestOrders()" class="form-control form-select">
                                                <option value="">{{__('all_orders')}}</option>
                                                <option v-for="status in statuses" :value='status.id'>{{ status.status }}</option>
                                            </select>
                                        </div>
                                    </b-col>
                                    <b-col md="2">
                                        <div class="form-group">
                                            <h6 class="box-title" for="seller">{{__('seller')}}</h6>
                                            <select name="seller" id="seller" v-model="seller"
                                                    @change="getLatestOrders()" class="form-control form-select">
                                                <option value="">{{__('select_seller')}}</option>
                                                <option v-for="seller in filterSellers" :value="seller.id">{{ seller.name }}</option>
                                            </select>
                                        </div>
                                    </b-col>
                                    <b-col md="3">
                                        <h6 class="box-title">{{ __('from_and_to_delivery_date') }}</h6>
                                        <div class="d-flex justify-content-center align-items-center">
                                            <date-range-picker
                                                :autoApply=false
                                                :showDropdowns = true
                                                v-model="deliveryDateRange"
                                                :maxDate="maxDate"
                                                @update="getLatestOrders"
                                                :ranges="customRanges"
                                            ></date-range-picker>
                                            <button class="btn btn-sm btn-danger ml-1" @click="deliveryDateRange.startDate = null, deliveryDateRange.endDate = null, getLatestOrders()">
                                                {{ __('clear') }}
                                            </button>
                                        </div>
                                    </b-col>

                                    <b-col md="1" class="text-center">
                                        <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getLatestOrders()">
                                            <i class="fa fa-refresh" aria-hidden="true"></i>
                                        </button>
                                    </b-col>

                                </b-row>

                                <div class="table-responsive">
                                    <b-table
                                        :items="orders"
                                        :fields="orderFields"
                                        :current-page="orderCurrentPage"
                                        :per-page="orderPerPage"
                                        :filter="orderFilter"
                                        :filter-included-fields="filterOn"
                                        :sort-by.sync="sortBy"
                                        :sort-desc.sync="sortDesc"
                                        :sort-direction="sortDirection"
                                        :bordered="true"
                                        :busy="isLoading"
                                        stacked="md"
                                        show-empty
                                        small>
                                        <template #table-busy>
                                            <div class="text-center text-black my-2">
                                                <b-spinner class="align-middle"></b-spinner>
                                                <strong>{{__('loading')}}</strong>
                                            </div>
                                        </template>

                                        <template #head(total)="row">
                                            {{ __('total') +' ('+$currency+')' }}
                                        </template>
                                        <template #head(delivery_charge)="row">
                                            {{ __('dcharges')+' ('+$currency+')' }}
                                        </template>
                                        <template #head(tax)="row">
                                            {{ __('tax')+' ('+$currency+') (%)' }}
                                        </template>
                                        <template #head(discount)="row">
                                            {{ __('disc')+' ('+$currency+') (%)' }}
                                        </template>
                                        <template #head(promo_discount)="row">
                                            {{ __('promo_disc')+' ('+$currency+')' }}
                                        </template>
                                        <template #head(wallet_balance)="row">
                                            {{ __('wallet_used')+' ('+$currency+')' }}
                                        </template>
                                        <template #head(remaining_final)="row">
                                            {{ __('ftotal')+' ('+$currency+')' }}
                                        </template>


                                        <template #cell(mobile)="row">
                                            {{ row.item.mobile | mobileMask }}
                                        </template>

                                        <template #cell(actions)="row" v-if="$can('order_update')">
                                            <router-link
                                                :to="{ name: 'ViewOrder',params: { id: row.item.id, record : row.item }}"
                                                v-b-tooltip.hover title="View" class="btn btn-primary btn-sm"><i
                                                class="fa fa-eye"></i></router-link>
                                            <button class="btn btn-danger btn-sm" v-b-tooltip.hover :title="__('delete')" v-if="$can('order_delete')"
                                                    @click="deleteOrder(row.index,row.item.id)"><i
                                                class="fa fa-trash"></i></button>
                                        </template>
                                    </b-table>
                                </div>
                                <b-row>
                                    <b-col md="2" class="my-1">
                                        <b-form-group
                                            :label="__('per_page')"
                                            label-for="per-page-select"
                                            label-align-sm="right"
                                            label-size="sm"
                                            class="mb-0">
                                            <b-form-select
                                                id="per-page-select"
                                                v-model="orderPerPage"
                                                :options="pageOptions"
                                                size="sm"
                                                class="form-control form-select"
                                            ></b-form-select>
                                        </b-form-group>
                                    </b-col>
                                    <b-col md="4" class="my-1" offset-md="6">
                                        <b-pagination
                                            v-model="orderCurrentPage"
                                            :total-rows="orderTotalRows"
                                            :per-page="orderPerPage"
                                            align="fill"
                                            size="sm"
                                            class="my-0"
                                        ></b-pagination>
                                    </b-col>
                                </b-row>
                            </div>
                        </div>
                    </div> -->

                        <div class="col-12">
                            <div class="card chart-card">
                                <div class="card-header d-flex justify-content-between align-items-center">
                                    <div>
                                        <h4 class="card-title mb-0">{{__('top_sellers')}}</h4>
                                        <small class="text-muted">({{__('month')}}: {{ currentMonth }})</small>
                                    </div>
                                    <div class="d-flex align-items-center">
                                        <select class="form-select form-select-sm me-2" v-model="sellersPeriod" @change="getRecord()">
                                            <option value="daily">{{__('daily')}}</option>
                                            <option value="weekly">{{__('weekly')}}</option>
                                            <option value="monthly">{{__('monthly')}}</option>
                                            <option value="yearly">{{__('yearly')}}</option>
                                            <option value="all">{{__('all_time')}}</option>
                                        </select>
                                        <div class="badge bg-primary">
                                            <i class="fa fa-trophy"></i>
                                        </div>
                                    </div>
                                </div>
                                <div class="card-body">

                                    <div class="table-responsive">
                                        <b-table
                                            :items="sellers"
                                            :fields="sellerFields"
                                            :current-page="currentPage"
                                            :per-page="perPage"
                                            :filter="sellerFilter"
                                            :filter-included-fields="filterOn"
                                            :sort-by.sync="sortBy"
                                            :sort-desc.sync="sortDesc"
                                            :sort-direction="sortDirection"
                                            :bordered="true"
                                            stacked="md"
                                            show-empty
                                            small>
                                            <template #head(total_revenue)="row">
                                                {{ __('total_revenue')+'('+$currency+')' }}
                                            </template>
                                            <template #cell(actions)="row">
                                                <router-link to="/sellers" v-b-tooltip.hover :title="__('view')"
                                                            class="btn btn-primary btn-sm"><i class="fa fa-eye"></i>
                                                </router-link>
                                            </template>
                                        </b-table>
                                    </div>
                                    <b-row>
                                        <b-col md="2" class="my-1">
                                            <b-form-group
                                                :label="__('per_page')"
                                                label-for="per-page-select"
                                                label-align-sm="right"
                                                label-size="sm"
                                                class="mb-0">
                                                <b-form-select
                                                    id="per-page-select"
                                                    v-model="perPage"
                                                    :options="pageOptions"
                                                    size="sm"
                                                    class="form-control form-select"
                                                ></b-form-select>
                                            </b-form-group>
                                        </b-col>
                                        <b-col md="4" class="my-1" offset-md="6">
                                            <b-pagination
                                                v-model="currentPage"
                                                :total-rows="totalRows"
                                                :per-page="perPage"
                                                align="fill"
                                                size="sm"
                                                class="my-0"
                                            ></b-pagination>
                                        </b-col>
                                    </b-row>
                                </div>
                            </div>
                        </div>

                        <div class="col-12">
                            <div class="card chart-card">
                                <div class="card-header d-flex justify-content-between align-items-center">
                                    <div>
                                        <h4 class="card-title mb-0">{{__('top_drivers_in')}} {{ currentMonth }}</h4>
                                        <small class="text-muted">({{__('month')}}: {{ currentMonth }})</small>
                                    </div>
                                    <div class="d-flex align-items-center">
                                        <select class="form-select form-select-sm me-2" v-model="driversPeriod" @change="getRecord()">
                                            <option value="daily">{{__('daily')}}</option>
                                            <option value="weekly">{{__('weekly')}}</option>
                                            <option value="monthly">{{__('monthly')}}</option>
                                            <option value="yearly">{{__('yearly')}}</option>
                                            <option value="all">{{__('all_time')}}</option>
                                        </select>
                                        <div class="badge bg-info">
                                            <i class="fa fa-truck"></i>
                                        </div>
                                    </div>
                                </div>
                                <div class="card-body">

                                    <div class="table-responsive">
                                        <b-table
                                            :items="drivers"
                                            :fields="driverFields"
                                            :current-page="driverCurrentPage"
                                            :per-page="driverPerPage"
                                            :filter="driverFilter"
                                            :filter-included-fields="filterOn"
                                            :sort-by.sync="sortBy"
                                            :sort-desc.sync="sortDesc"
                                            :sort-direction="sortDirection"
                                            :bordered="true"
                                            stacked="md"
                                            show-empty
                                            small>
                                            <template #head(driver_earning)="row">
                                                {{ __('driver_earning')+'('+$currency+')' }}
                                            </template>
                                            <template #cell(index)="row">
                                                {{ row.index + 1 }}
                                            </template>
                                        </b-table>
                                    </div>
                                    <b-row>
                                        <b-col md="2" class="my-1">
                                            <b-form-group
                                                :label="__('per_page')"
                                                label-for="per-page-select"
                                                label-align-sm="right"
                                                label-size="sm"
                                                class="mb-0">
                                                <b-form-select
                                                    id="per-page-select"
                                                    v-model="driverPerPage"
                                                    :options="pageOptions"
                                                    size="sm"
                                                    class="form-control form-select"
                                                ></b-form-select>
                                            </b-form-group>
                                        </b-col>
                                        <b-col md="4" class="my-1" offset-md="6">
                                            <b-pagination
                                                v-model="driverCurrentPage"
                                                :total-rows="driverTotalRows"
                                                :per-page="driverPerPage"
                                                align="fill"
                                                size="sm"
                                                class="my-0"
                                            ></b-pagination>
                                        </b-col>
                                    </b-row>
                                </div>
                            </div>
                        </div>

                        <div class="col-12">
                            <div class="card chart-card">
                                <div class="card-header d-flex justify-content-between align-items-center">
                                    <div>
                                        <h4 class="card-title mb-0">{{__('top_categories')}}</h4>
                                        <small class="text-muted">({{__('month')}}: {{ currentMonth }})</small>
                                    </div>
                                    <div class="d-flex align-items-center">
                                        <select class="form-select form-select-sm me-2" v-model="categoriesPeriod" @change="getRecord()">
                                            <option value="daily">{{__('daily')}}</option>
                                            <option value="weekly">{{__('weekly')}}</option>
                                            <option value="monthly">{{__('monthly')}}</option>
                                            <option value="yearly">{{__('yearly')}}</option>
                                            <option value="all">{{__('all_time')}}</option>
                                        </select>
                                        <div class="badge bg-success">
                                            <i class="fa fa-star"></i>
                                        </div>
                                    </div>
                                </div>
                                <div class="card-body">

                                    <div class="table-responsive">
                                        <b-table
                                            :items="categories"
                                            :fields="categoryFields"
                                            :current-page="categoryCurrentPage"
                                            :per-page="categoryPerPage"
                                            :filter="categoryFilter"
                                            :filter-included-fields="filterOn"
                                            :sort-by.sync="sortBy"
                                            :sort-desc.sync="sortDesc"
                                            :sort-direction="sortDirection"
                                            :bordered="true"
                                            stacked="md"
                                            show-empty
                                            small>
                                            <template #head(total_revenue)="row">
                                                {{ __('total_revenue') + ' ('+$currency+')' }}
                                            </template>
                                            <template #cell(index)="row">
                                                {{ row.index + 1 }}
                                            </template>
                                        </b-table>
                                    </div>
                                    <b-row>
                                        <b-col md="2" class="my-1">
                                            <b-form-group
                                                :label="__('per_page')"
                                                label-for="per-page-select"
                                                label-align-sm="right"
                                                label-size="sm"
                                                class="mb-0">
                                                <b-form-select
                                                    id="per-page-select"
                                                    v-model="categoryPerPage"
                                                    :options="pageOptions"
                                                    size="sm"
                                                    class="form-control form-select"
                                                ></b-form-select>
                                            </b-form-group>
                                        </b-col>
                                        <b-col md="4" class="my-1" offset-md="6">
                                            <b-pagination
                                                v-model="categoryCurrentPage"
                                                :total-rows="categoryTotalRows"
                                                :per-page="categoryPerPage"
                                                align="fill"
                                                size="sm"
                                                class="my-0"
                                            ></b-pagination>
                                        </b-col>
                                    </b-row>
                                </div>
                            </div>
                        </div>

                        <div class="col-12">
                            <div class="card chart-card">
                                <div class="card-header d-flex justify-content-between align-items-center">
                                    <div>
                                        <h4 class="card-title mb-0">{{__('top_category_groups')}}</h4>
                                    </div>
                                    <div class="d-flex align-items-center">
                                        <select class="form-select form-select-sm me-2" v-model="categoryGroupsPeriod" @change="getRecord()">
                                            <option value="daily">{{__('daily')}}</option>
                                            <option value="weekly">{{__('weekly')}}</option>
                                            <option value="monthly">{{__('monthly')}}</option>
                                            <option value="yearly">{{__('yearly')}}</option>
                                            <option value="all">{{__('all_time')}}</option>
                                        </select>
                                        <div class="badge bg-warning">
                                            <i class="fa fa-layer-group"></i>
                                        </div>
                                    </div>
                                </div>
                                <div class="card-body">

                                    <div class="table-responsive">
                                        <b-table
                                            :items="categoryGroups"
                                            :fields="categoryGroupFields"
                                            :current-page="categoryGroupCurrentPage"
                                            :per-page="categoryGroupPerPage"
                                            :filter="categoryGroupFilter"
                                            :filter-included-fields="filterOn"
                                            :sort-by.sync="sortBy"
                                            :sort-desc.sync="sortDesc"
                                            :sort-direction="sortDirection"
                                            :bordered="true"
                                            stacked="md"
                                            show-empty
                                            small>
                                            <template #head(total_revenue)="row">
                                                {{ __('total_revenue') + ' ('+$currency+')' }}
                                            </template>
                                            <template #cell(index)="row">
                                                {{ row.index + 1 }}
                                            </template>
                                        </b-table>
                                    </div>
                                    <b-row>
                                        <b-col md="2" class="my-1">
                                            <b-form-group
                                                :label="__('per_page')"
                                                label-for="per-page-select"
                                                label-align-sm="right"
                                                label-size="sm"
                                                class="mb-0">
                                                <b-form-select
                                                    id="per-page-select"
                                                    v-model="categoryGroupPerPage"
                                                    :options="pageOptions"
                                                    size="sm"
                                                    class="form-control form-select"
                                                ></b-form-select>
                                            </b-form-group>
                                        </b-col>
                                        <b-col md="4" class="my-1" offset-md="6">
                                            <b-pagination
                                                v-model="categoryGroupCurrentPage"
                                                :total-rows="categoryGroupTotalRows"
                                                :per-page="categoryGroupPerPage"
                                                align="fill"
                                                size="sm"
                                                class="my-0"
                                            ></b-pagination>
                                        </b-col>
                                    </b-row>
                                </div>
                            </div>
                        </div>

                        <div class="col-12">
                            <div class="card chart-card">
                                <div class="card-header d-flex justify-content-between align-items-center">
                                    <div>
                                        <h4 class="card-title mb-0">{{__('top_sub_category_groups')}}</h4>
                                    </div>
                                    <div class="d-flex align-items-center">
                                        <select class="form-select form-select-sm me-2" v-model="subCategoryGroupsPeriod" @change="getRecord()">
                                            <option value="daily">{{__('daily')}}</option>
                                            <option value="weekly">{{__('weekly')}}</option>
                                            <option value="monthly">{{__('monthly')}}</option>
                                            <option value="yearly">{{__('yearly')}}</option>
                                            <option value="all">{{__('all_time')}}</option>
                                        </select>
                                        <div class="badge bg-secondary">
                                            <i class="fa fa-sitemap"></i>
                                        </div>
                                    </div>
                                </div>
                                <div class="card-body">

                                    <div class="table-responsive">
                                        <b-table
                                            :items="subCategoryGroups"
                                            :fields="subCategoryGroupFields"
                                            :current-page="subCategoryGroupCurrentPage"
                                            :per-page="subCategoryGroupPerPage"
                                            :filter="subCategoryGroupFilter"
                                            :filter-included-fields="filterOn"
                                            :sort-by.sync="sortBy"
                                            :sort-desc.sync="sortDesc"
                                            :sort-direction="sortDirection"
                                            :bordered="true"
                                            stacked="md"
                                            show-empty
                                            small>
                                            <template #head(total_revenue)="row">
                                                {{ __('total_revenue') + ' ('+$currency+')' }}
                                            </template>
                                            <template #cell(index)="row">
                                                {{ row.index + 1 }}
                                            </template>
                                        </b-table>
                                    </div>
                                    <b-row>
                                        <b-col md="2" class="my-1">
                                            <b-form-group
                                                :label="__('per_page')"
                                                label-for="per-page-select"
                                                label-align-sm="right"
                                                label-size="sm"
                                                class="mb-0">
                                                <b-form-select
                                                    id="per-page-select"
                                                    v-model="subCategoryGroupPerPage"
                                                    :options="pageOptions"
                                                    size="sm"
                                                    class="form-control form-select"
                                                ></b-form-select>
                                            </b-form-group>
                                        </b-col>
                                        <b-col md="4" class="my-1" offset-md="6">
                                            <b-pagination
                                                v-model="subCategoryGroupCurrentPage"
                                                :total-rows="subCategoryGroupTotalRows"
                                                :per-page="subCategoryGroupPerPage"
                                                align="fill"
                                                size="sm"
                                                class="my-0"
                                            ></b-pagination>
                                        </b-col>
                                    </b-row>
                                </div>
                            </div>
                        </div>

                        <!-- Categorywise Product Count - Moved to bottom -->
                        <div class="col-12">
                            <div class="card chart-card">
                                <div class="card-header d-flex justify-content-between align-items-center">
                                    <div>
                                        <h4 class="card-title mb-0">{{__('product_category_count')}}</h4>
                                    </div>
                                    <div class="badge bg-purple">
                                        <i class="fa fa-th-large"></i>
                                    </div>
                                </div>
                                <div class="card-body">
                                    <div class="table-responsive">
                                        <b-table
                                            :items="productCategoryCount"
                                            :fields="productCategoryCountFields"
                                            :current-page="productCategoryCountCurrentPage"
                                            :per-page="productCategoryCountPerPage"
                                            :filter="productCategoryCountFilter"
                                            :filter-included-fields="filterOn"
                                            :sort-by.sync="sortBy"
                                            :sort-desc.sync="sortDesc"
                                            :sort-direction="sortDirection"
                                            :bordered="true"
                                            stacked="md"
                                            show-empty
                                            small>
                                            <template #cell(index)="row">
                                                {{ row.index + 1 }}
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
                                                    v-model="productCategoryCountPerPage"
                                                    :options="pageOptions"
                                                    size="sm"
                                                    class="form-control form-select"
                                                ></b-form-select>
                                            </b-form-group>
                                        </b-col>
                                        <b-col md="6" class="my-1" offset-md="2">
                                            <b-pagination
                                                v-model="productCategoryCountCurrentPage"
                                                :total-rows="productCategoryCountTotalRows"
                                                :per-page="productCategoryCountPerPage"
                                                align="fill"
                                                size="sm"
                                                class="my-0"
                                            ></b-pagination>
                                        </b-col>
                                    </b-row>
                                </div>
                            </div>
                        </div>

                </div>
            </section>
        </div>
    </div>
</template>

<script>
import DateRangePicker from 'vue2-daterange-picker'
import axios from "axios";
import {GChart} from 'vue-google-charts/legacy';
import moment from "moment";
import VueApexCharts from 'vue-apexcharts'
export default {
    name: 'Chart',
    components: {
        GChart,
        apexcharts: VueApexCharts,
        DateRangePicker
    },
    data: function () {
        let startDate = new Date();
        let endDate = new Date();
        startDate.setDate(startDate.getDate() - 30);
        return {
            dateRange: {startDate, endDate},
            deliveryDateRange: { startDate: null, endDate: null },

            customRanges: {
                'Today': this.getTodayRange(),
                'Yesterday': this.getYesterdayRange(),
                'This Week': this.getThisWeekRange(),
                'This Month': this.getThisMonthRange(),
                'This Year': this.getThisYearRange(),
                'Last Month': this.getLastMonthRange(),
            },
            maxDate : new Date(),
            isLoading: false,
            record: [],
            currentMonth: "",

            // Period filters
            salesPeriod: 'monthly',
            returnsPeriod: 'monthly',
            sellersPeriod: 'monthly',
            driversPeriod: 'monthly',
            categoriesPeriod: 'monthly',
            categoryGroupsPeriod: 'monthly',
            subCategoryGroupsPeriod: 'monthly',

            productCategoryCountFields: [
                {key: 'index', label: '#', sortable: false},
                {key: 'name', label: __('category'), sortable: false, class: 'text-center'},
                {key: 'product_count', label: __('product_count'), sortable: false, class: 'text-center'},
            ],

            sellerFields: [
                {key: 'seller_id', label: __('seller_id'), sortable: false, sortDirection: 'desc'},
                {key: 'seller_name', label: __('sellers'), sortable: false, class: 'text-center'},
                {key: 'store_name', label: __('store_name'), sortable: false, class: 'text-center'},
                {key: 'total_revenue', label: __('total_revenue'), sortable: false, class: 'text-center'},
                {key: "actions", label: __('actions')}
            ],

            categoryFields: [
                {key: 'index', label: '#', sortable: false},
                {key: 'category_name', label: __('category'), sortable: false, class: 'text-center'},
                {key: 'total_revenue', label:  __('total_revenue'), sortable: false, class: 'text-center'},
            ],

            driverFields: [
                {key: 'index', label: '#', sortable: false},
                {key: 'driver_name', label: __('driver_name'), sortable: false, class: 'text-center'},
                {key: 'order_count', label: __('order_count'), sortable: false, class: 'text-center'},
                {key: 'driver_earning', label: __('driver_earning'), sortable: false, class: 'text-center'},
            ],

            categoryGroupFields: [
                {key: 'index', label: '#', sortable: false},
                {key: 'category_group_name', label: __('category_group_name'), sortable: false, class: 'text-center'},
                {key: 'total_revenue', label: __('total_revenue'), sortable: false, class: 'text-center'},
            ],

            subCategoryGroupFields: [
                {key: 'index', label: '#', sortable: false},
                {key: 'sub_category_group_name', label: __('sub_category_group_name'), sortable: false, class: 'text-center'},
                {key: 'total_revenue', label: __('total_revenue'), sortable: false, class: 'text-center'},
            ],

            orderFields: [
                {key: 'id', label: __('oid'), sortable: true, sortDirection: 'desc'},
                {key: 'user_name', label: __('user'), sortable: true, class: 'text-center'},
                {key: 'mobile', label: __('mobile'), sortable: true, class: 'text-center'},
                { key: 'total', label: __('total')+'('+ this.$currency +')', sortable: true, class: 'text-center' },
                { key: 'delivery_charge', label: __('dcharges')+'('+ this.$currency +')', sortable: true, class: 'text-center' },

                { key: 'remaining_final', label: __('ftotal')+'('+ this.$currency +')', sortable: true, class: 'text-center' },
                { key: 'payment_method', label: __('p_method'), sortable: true, class: 'text-center' },
                { key: 'delivery_time', label: __('d_time'), sortable: true, class: 'text-center' },
                {key: "actions", label: __('actions')}
            ],

            pageOptions: this.$pageOptions,
            sortBy: '',
            sortDesc: false,
            sortDirection: 'asc',

            orderFilter: null,
            sellerFilter: null,
            categoryFilter: null,

            filterOn: [ ],

            page: 1,

            sectionStyle: 'style_1',
            max_visible_units: 12,
            max_col_in_single_row: 3,

            productCategoryCount: [],
            productCategoryCountTotalRows: 1,
            productCategoryCountCurrentPage: 1,
            productCategoryCountPerPage: 10,
            productCategoryCountFilter: null,

            sellers: [],
            totalRows: 1,
            currentPage: 1,
            perPage: 5,

            categories: [],
            categoryTotalRows: 1,
            categoryCurrentPage: 1,
            categoryPerPage: 5,

            drivers: [],
            driverTotalRows: 1,
            driverCurrentPage: 1,
            driverPerPage: 10,
            driverFilter: null,

            categoryGroups: [],
            categoryGroupTotalRows: 1,
            categoryGroupCurrentPage: 1,
            categoryGroupPerPage: 10,
            categoryGroupFilter: null,

            subCategoryGroups: [],
            subCategoryGroupTotalRows: 1,
            subCategoryGroupCurrentPage: 1,
            subCategoryGroupPerPage: 10,
            subCategoryGroupFilter: null,

            statuses: [],
            orders: [],
            orderTotalRows: 1,
            orderCurrentPage: 1,
            orderPerPage: 5,
            status: "",
            filterSellers: "",
            seller: "",

            graphOrders: [],
            isLoadingColumnChart: false,
            graphCategories: [],

            chartData:[],

            options: {
                chart: {
                    height: 500, 
                    type: 'bar',
                },
                plotOptions: {
                    bar: {
                        borderRadius: 2,
                        dataLabels: {
                            position: 'top', // top, center, bottom
                        },
                    }
                },
                dataLabels: {
                    enabled: true,
                    offsetY: -20,
                    style: {
                        fontSize: '12px',
                        colors: ["#304758"]
                    }
                },

                fill: {
                    colors: ['#25B076']
                },

                xaxis: {
                    categories: [],
                    position: 'top',
                    axisBorder: {
                        show: false
                    },
                    axisTicks: {
                        show: false
                    },
                    crosshairs: {
                        fill: {
                            type: 'gradient',
                            gradient: {
                                colorFrom: '#000',
                                colorTo: '#000',
                                stops: [0, 100],
                                opacityFrom: 0.4,
                                opacityTo: 0.5,
                            }
                        }
                    },
                    tooltip: {
                        enabled: true,
                    }
                },
                yaxis: {
                    axisBorder: {
                        show: false
                    },
                    axisTicks: {
                        show: false,
                    },
                    labels: {
                        show: false,
                    }

                },
                noData: {
                    text: "No Data Found",
                    align: 'center',
                }
            },

            series: [{
                name: 'Total Sale',
                data: []
            }],

            // Returns chart options
            graphReturns: [],
            returnsOptions: {
                chart: {
                    height: 500,
                    type: 'bar',
                },
                plotOptions: {
                    bar: {
                        borderRadius: 2,
                        dataLabels: {
                            position: 'top',
                        },
                    }
                },
                dataLabels: {
                    enabled: true,
                    offsetY: -20,
                    style: {
                        fontSize: '12px',
                        colors: ["#304758"]
                    }
                },
                fill: {
                    colors: ['#dc3545']
                },
                xaxis: {
                    categories: [],
                    position: 'top',
                    axisBorder: {
                        show: false
                    },
                    axisTicks: {
                        show: false
                    },
                    crosshairs: {
                        fill: {
                            type: 'gradient',
                            gradient: {
                                colorFrom: '#000',
                                colorTo: '#000',
                                stops: [0, 100],
                                opacityFrom: 0.4,
                                opacityTo: 0.5,
                            }
                        }
                    },
                    tooltip: {
                        enabled: true,
                    }
                },
                yaxis: {
                    axisBorder: {
                        show: false
                    },
                    axisTicks: {
                        show: false,
                    },
                    labels: {
                        show: false,
                    }
                },
                noData: {
                    text: "No Data Found",
                    align: 'center',
                }
            },
            returnsSeries: [{
                name: 'Total Returns',
                data: []
            }],

            options2: {
                chart: {
                    type: 'pie',
                    height: '200',
                },
                legend: {
                    show: true,
                    position: 'bottom',
                    fontSize: '12px',
                    fontFamily: 'Helvetica, Arial, sans-serif',
                    markers: {
                        width: 8,
                        height: 8,
                        radius: 2
                    }
                },
                labels: [],
                responsive: [{
                    breakpoint: 9999,
                    options: {
                        chart: {
                            height: 450
                        }
                    }
                }]
                    },
            series2: []
        };
    },
    mounted() {
        // Set the initial number of items
        this.totalRows = this.sellers.length
        this.categoryTotalRows = this.categories.length
        this.orderTotalRows = this.orders.length
    },
    created() {
        this.barChart();
        this.returnsChart();
        this.pieChart();

        let months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        let now = new Date();
        this.currentMonth = months[now.getMonth()];
        this.getRecord();
        this.getOrderStatus();
        this.getLatestOrders();
        this.setSellerWalletTransaction();
    },
    methods: {
         getTodayRange() {
      let startDate = new Date();
      startDate.setHours(0, 0, 0, 0); // Start of today

      let endDate = new Date();
      endDate.setHours(23, 59, 59, 999); // End of today
     this.dateRange = { startDate, endDate };
      return [startDate, endDate];
    },
    getYesterdayRange() {
      let endDate = new Date();
      endDate.setDate(endDate.getDate() - 1); // Yesterday

      let startDate = new Date(endDate);
      startDate.setHours(0, 0, 0, 0); // Start of yesterday

      endDate.setHours(23, 59, 59, 999); // End of yesterday

      return [startDate, endDate];
    },
    getThisWeekRange() {
      let startDate = new Date();
      startDate.setDate(startDate.getDate() - startDate.getDay() + 1); // Start of the current week (Sunday as start day)
      startDate.setHours(0, 0, 0, 0); // Start of the day

      let endDate = new Date();
      endDate.setDate(startDate.getDate() + 6); // End of the current week (Saturday as end day)
      endDate.setHours(23, 59, 59, 999); // End of the day

      return [startDate, endDate];
    },
    getThisMonthRange() {
      let startDate = new Date();
      startDate.setDate(1); // Start of the current month
      startDate.setHours(0, 0, 0, 0); // Start of the day

      let endDate = new Date();
      endDate.setMonth(endDate.getMonth() + 1); // Move to next month
      endDate.setDate(0); // Last day of the previous month
      endDate.setHours(23, 59, 59, 999); // End of the day

      return [startDate, endDate];
    },
    getThisYearRange() {
      let startDate = new Date();
      startDate.setMonth(0); // Start of the current year
      startDate.setDate(1); // Start of the day

      let endDate = new Date();
      endDate.setFullYear(endDate.getFullYear() + 1); // Move to next year
      endDate.setMonth(0); // Start of next year
      endDate.setDate(0); // Last day of the previous year
      endDate.setHours(23, 59, 59, 999); // End of the day

      return [startDate, endDate];
    },
    getLastMonthRange() {
      let startDate = new Date();
      startDate.setMonth(startDate.getMonth() - 1); // Move to last month
      startDate.setDate(1); // Start of the last month
      startDate.setHours(0, 0, 0, 0); // Start of the day

      let endDate = new Date();
      endDate.setDate(0); // Last day of the previous month
      endDate.setHours(23, 59, 59, 999); // End of the day

      return [startDate, endDate];
    },
        barChart(){
            if (!this.$refs.apexBarChart) return;
            // Clear previous data
            this.options.xaxis.categories = [];
            this.series[0].data = [];

            axios.get(this.$apiUrl + '/orders/weekly_sales', {
                params: { period: this.salesPeriod }
            }).then((response) => {
                    this.graphOrders = response.data.data;
                    this.graphOrders.forEach((order) => {
                        this.options.xaxis.categories.push(moment(order.order_date).format('DD-MMM'));
                        this.series[0].data.push(order.total_sale);
                    });
                    if (!this.$refs.apexBarChart) return;
                    this.$refs.apexBarChart.updateSeries([{
                        data: this.series[0].data,
                    }], false, true);
                    this.$refs.apexBarChart.updateOptions({
                        xaxis: {
                            categories: this.options.xaxis.categories
                        }
                    });
            })
        },
        returnsChart(){
            if (!this.$refs.apexReturnsChart) return;
            // Clear previous data
            this.returnsOptions.xaxis.categories = [];
            this.returnsSeries[0].data = [];

            axios.get(this.$apiUrl + '/orders/weekly_returns', {
                params: { period: this.returnsPeriod }
            }).then((response) => {
                    this.graphReturns = response.data.data;
                    this.graphReturns.forEach((order) => {
                        this.returnsOptions.xaxis.categories.push(moment(order.order_date).format('DD-MMM'));
                        this.returnsSeries[0].data.push(order.total_return);
                    });
                    if (!this.$refs.apexReturnsChart) return;
                    this.$refs.apexReturnsChart.updateSeries([{
                        data: this.returnsSeries[0].data,
                    }], false, true);
                    this.$refs.apexReturnsChart.updateOptions({
                        xaxis: {
                            categories: this.returnsOptions.xaxis.categories
                        }
                    });
            })
        },
        pieChart(){
            axios.get(this.$apiUrl + '/categories/product_count').then((response) => {
                    this.graphCategories = response.data.data;
                    // Filter categories with product_count > 0 for table
                    this.productCategoryCount = this.graphCategories.filter(category => category.product_count > 0);
                    this.productCategoryCountTotalRows = this.productCategoryCount.length;
            })
        },

        getRecord: function () {
            let vm = this;
            this.isLoading = true;
            axios.get(this.$apiUrl + '/dashboard', {
                params: {
                    sellers_period: this.sellersPeriod,
                    drivers_period: this.driversPeriod,
                    categories_period: this.categoriesPeriod,
                    category_groups_period: this.categoryGroupsPeriod,
                    sub_category_groups_period: this.subCategoryGroupsPeriod
                }
            }).then(res => {
                vm.isLoading = false;
                let data = res.data;
                if (data.status === 1) {
                    this.record = data.data;
                    this.sellers = data.data.top_sellers;
                    this.totalRows = this.sellers.length;
                    this.categories = data.data.top_categories;
                    this.categoryTotalRows = this.categories.length;
                    this.drivers = data.data.top_drivers || [];
                    this.driverTotalRows = this.drivers.length;
                    this.categoryGroups = data.data.top_category_groups || [];
                    this.categoryGroupTotalRows = this.categoryGroups.length;
                    this.subCategoryGroups = data.data.top_sub_category_groups || [];
                    this.subCategoryGroupTotalRows = this.subCategoryGroups.length;
                }
            }).catch(error => {
                vm.isLoading = false;
                if (error.request.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError(__('something_went_wrong'));
                }
            });
        },
        setSellerWalletTransaction: function () {

            let vm = this;
            this.isLoading = true;
            axios.get(this.$apiUrl + '/set_seller_wallet_transaction').then(res => {
                vm.isLoading = false;
                let data = res.data;
                if (data.status === 1) {
                    this.record = data.data;
                    this.sellers = data.data.top_sellers;
                    this.totalRows = this.sellers.length;
                    this.categories = data.data.top_categories;
                    this.categoryTotalRows = this.categories.length;
                    this.drivers = data.data.top_drivers || [];
                    this.driverTotalRows = this.drivers.length;
                    this.categoryGroups = data.data.top_category_groups || [];
                    this.categoryGroupTotalRows = this.categoryGroups.length;
                    this.subCategoryGroups = data.data.top_sub_category_groups || [];
                    this.subCategoryGroupTotalRows = this.subCategoryGroups.length;
                }
            }).catch(error => {
                vm.isLoading = false;
                if (error.request.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError(__('something_went_wrong'));
                }
            });
        },
        getOrderStatus: function () {
            let vm = this;
            axios.get(this.$apiUrl + '/order_statuses').then((response) => {
                this.isLoading = false
                this.statuses = response.data.data;
            }).catch(error => {
                vm.isLoading = false;
                if (error.request.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError(__('something_went_wrong'));
                }
            });
        },
        getLatestOrders: function () {
            this.isLoading = true;
            let vm = this;
            let param = {
                "startDate": (this.dateRange.startDate != null) ? moment(this.dateRange.startDate).format('YYYY-MM-DD'):"",
                "endDate": (this.dateRange.endDate != null) ? moment(this.dateRange.endDate).format('YYYY-MM-DD'):"",
                "seller": this.seller,
                "status": this.status,
                startDeliveryDate: this.deliveryDateRange.startDate ? moment(this.deliveryDateRange.startDate).format('YYYY-MM-DD') : '',
                endDeliveryDate: this.deliveryDateRange.endDate ? moment(this.deliveryDateRange.endDate).format('YYYY-MM-DD') : '',
            }
            axios.get(this.$apiUrl + '/orders', {
                params: param
            }).then((response) => {
                let data = response.data;
                if (data.status === 1) {
                    this.filterSellers = response.data.data.sellers;
                    this.orders = response.data.data.orders;
                    this.orderTotalRows = this.orders.length;
                    this.isLoading = false
                }
            }).catch(error => {
                vm.isLoading = false;
                if (error.request.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError(__('something_went_wrong'));
                }
            });
        },
        deleteOrder(index, id) {
            this.$swal.fire({
                title: "Are you Sure?",
                text: "You want be able to revert this",
                confirmButtonText: "Yes, Sure",
                cancelButtonText: "Cancel",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
            }).then(result => {
                if (result.value) {
                    this.isLoading = true
                    let postData = {
                        id: id
                    }
                    axios.post(this.$apiUrl + '/orders/delete', postData)
                        .then((response) => {
                            this.isLoading = false
                            let data = response.data;
                            this.orders.splice(index, 1)
                            this.showSuccess(data.message)
                        });
                }
            });
        },
    },
};
</script>

<style scoped>
@import "../../../node_modules/vue2-daterange-picker/dist/vue2-daterange-picker.css";
.vue-daterange-picker[data-v-1ebd09d2] {
    min-width: 80%;
}
@media only screen and (min-width: 600px) {
    .vue-daterange-picker[data-v-1ebd09d2] {
        min-width: 90%;
    }
}

.btn_product_count{
    margin-bottom: 10px;
}

/* Period filter dropdown width */
.form-select.form-select-sm {
    min-width: 120px;
}
</style>

<style>
/* Dark mode support for Dashboard */
body.theme-dark .stats-card h3,
body.theme-dark .stats-card h5 {
    color: #fff;
}

body.theme-dark .chart-card .card-header p {
    color: #a0aec0;
}

body.theme-dark .chart-card .card-header small.text-muted {
    color: #a0aec0 !important;
}

body.theme-dark .chart-card .card-header .card-title {
    color: #fff;
}

body.theme-dark .products_sold .card h2,
body.theme-dark .products_sold .card h6 {
    color: #fff;
}

body.theme-dark .products_sold .card-header {
    background-color: #2d3748;
}

body.theme-dark .products_sold .card-body {
    background-color: #1e1e1e;
}

body.theme-dark .section-heading {
    color: #fff;
}

body.theme-dark .order-status-card .status-count {
    color: #fff;
}

body.theme-dark .order-status-card .status-label {
    color: #a0aec0;
}

body.theme-dark .order-status-card .card-body {
    background-color: #1e1e1e;
}

/* ApexCharts dark mode fixes */
body.theme-dark .apexcharts-text tspan {
    fill: #fff;
}

body.theme-dark .apexcharts-legend-text {
    color: #fff !important;
}

body.theme-dark .apexcharts-datalabels text {
    fill: #fff !important;
}

body.theme-dark .apexcharts-xaxis-label,
body.theme-dark .apexcharts-yaxis-label {
    fill: #a0aec0;
}

body.theme-dark .apexcharts-gridline {
    stroke: #3d3d3d;
}

/* b-table dark mode */
body.theme-dark .table {
    color: #e2e8f0;
}

body.theme-dark .table th {
    background-color: #2d3748;
    color: #fff;
    border-color: #4a5568;
}

body.theme-dark .table td {
    background-color: #1e1e1e;
    border-color: #4a5568;
}

body.theme-dark .table-striped tbody tr:nth-of-type(odd) {
    background-color: #252525;
}

body.theme-dark .page-link {
    background-color: #2d3748;
    border-color: #4a5568;
    color: #fff;
}

body.theme-dark .page-item.active .page-link {
    background-color: #9AC444;
    border-color: #9AC444;
}

body.theme-dark .page-item.disabled .page-link {
    background-color: #1e1e1e;
    border-color: #4a5568;
    color: #6c757d;
}
</style>
