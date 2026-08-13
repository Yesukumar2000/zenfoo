<template>

<div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>{{ __('order_list') }}</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">{{ __('order_list') }}</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/dashboard" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to Dashboard
                    </router-link>
                </div>
            </div>

            <section class="section">
                <div class="card">
                    <div class="card-header">
                        <h4 class="card-title">{{ __('latest_orders') }}</h4>
                    </div>
                    <div class="card-body">

                            <div class="row mb-2">
                                                        <b-col md="2">
                                <h6 class="box-title" for="city_id">City / Zone</h6>
                                <select name="city_id" id="city_id" v-model="city_id" @change="handleFilterChange()" class="form-control form-select">
                                    <option value="">All Cities</option>
                                    <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
                                </select>
                            </b-col>

                            <b-col md="3">
                                <h6 class="box-title">{{ __('from_and_to_date') }}</h6>
                                <div class="d-flex justify-content-center align-items-center">
                                    <date-range-picker
                                        :autoApply=false
                                        :showDropdowns = true
                                        v-model="dateRange"
                                        :maxDate="maxDate"
                                        @update="handleFilterChange"
                                        :ranges="customRanges"
                                    ></date-range-picker>
                                    <button class="btn btn-sm btn-danger ml-1" @click="clearDate()">
                                        {{ __('clear') }}
                                    </button>
                                </div>
                            </b-col>
                            <b-col md="2">
                                <h6 class="box-title">Store</h6>
                                <select name="store_id"
                                        id="store_id"
                                        v-model="store_id"
                                        @change="handleFilterChange()"
                                        class="form-control form-select">
                                    <option value="">All Stores</option>
                                    <option v-for="store in stores" :key="store.id" :value="store.id">
                                        {{ store.name }}
                                    </option>
                                </select>
                            </b-col>

                            <b-col md="2">
                                <h6 class="box-title" for="seller">{{ __('seller') }}</h6>
                                <select name="seller" id="seller" v-model="seller" @change="handleFilterChange()" class="form-control form-select" :disabled="!store_id">
                                    <option value="">{{ store_id ? __('all_sellers') : 'Select Store First' }}</option>
                                    <option v-for="sellerItem in sellersList" :key="sellerItem.id" :value="sellerItem.id">{{sellerItem.name}}</option>
                                </select>
                            </b-col>


                            <!-- <b-col md="1">
                                <h6 class="box-title" for="status">{{ __('status') }} </h6>
                                <select id="status" name="status" v-model="status" @change="handleFilterChange()" class="form-control form-select">
                                    <option value="">{{ __('all_orders') }}</option>
                                    <option v-for="status in statuses" :value='status.id'>{{ status.status }}</option>
                                </select>
                            </b-col> -->
                            <!-- <b-col md="3">
                                <h6 class="box-title">{{ __('from_and_to_delivery_date') }}</h6>
                                <div class="d-flex justify-content-center align-items-center">
                                    <date-range-picker
                                        :autoApply=false
                                        :showDropdowns = true
                                        v-model="deliveryDateRange"
                                        :maxDate="maxDate"
                                        @update="handleFilterChange"
                                        :ranges="customRanges"
                                    ></date-range-picker>
                                    <button class="btn btn-sm btn-danger ml-1" @click="clearDeliveryDate()">
                                        {{ __('clear') }}
                                    </button>
                                </div>
                            </b-col> -->
                            <b-col md="2">
                                <h6 class="box-title">{{ __('search') }}</h6>
                                <b-form-input
                                    id="filter-input"
                                    v-model="search"
                                    type="search"
                                    :placeholder="__('search')"
                                    @input="handleFilterChange()"
                                ></b-form-input>
                            </b-col>
                            <b-col md="1" class="text-center">
                                <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getOrders()">
                                    <i class="fa fa-refresh" aria-hidden="true"></i>
                                </button>
                            </b-col>
                        </div>
                        <div class="table-responsive mt-3">
                        <b-table
                            responsive="sm"
                            :items="orders"
                            :fields="orderFields"
                            :filter="filter"
                            :filter-included-fields="filterOn"
                            :sort-by.sync="sortBy"
                            :sort-desc.sync="sortDesc"
                            :sort-direction="sortDirection"
                            :bordered="true"
                            :busy="isLoading"
                            :no-footer-sorting = "true"
                            :no-border-collapse = "false"
                            stacked="md"
                            show-empty
                            small>

                            <!-- :foot-clone="true" -->

                            <!-- show the customer facing order number, falling back to
                                 the raw id so a row is never blank -->
                            <template #cell(id)="row">
                                {{ row.item.order_number || ('#' + row.item.id) }}
                            </template>

                            <template #cell(created_at)="row">
                                <span v-if="row.item.created_at">
                                    {{ formatDateTime(row.item.created_at) }}
                                </span>
                                <span v-else>-</span>
                            </template>

                            <template #cell(user_name)="row">
                                <span v-if="row.item.user_name && row.item.user_name !== ''">
                                    {{ row.item.user_name }}
                                </span>
                                <span v-else>-</span>
                            </template>

                            <template #cell(delivery_boy_name)="row">
                                <span v-if="row.item.delivery_boy_name && row.item.delivery_boy_name !== ''">
                                    {{ row.item.delivery_boy_name }}
                                </span>
                                <span v-else>-</span>
                            </template>

                            <template #cell(minutes_from_now)="row">
                                <span v-if="row.item.minutes_from_now && row.item.minutes_from_now !== ''">
                                    {{ row.item.minutes_from_now }}
                                </span>
                                <span v-else>-</span>
                            </template>

                            <template #cell(status)="row">
                                <span class="badge"
                                    :class="getStatusBadgeClass(row.item.active_status)">
                                    {{ getStatusLabel(row.item.active_status) }}
                                </span>
                            </template>


                            <template #table-busy>
                                <div class="text-center text-black my-2">
                                    <b-spinner class="align-middle"></b-spinner>
                                    <strong>{{ __('loading') }}...</strong>
                                </div>
                            </template>

                            <template #cell(mobile)="row">
                                {{ row.item.mobile | mobileMask }}
                            </template>

                            <template #cell(additional_charges)="row">
                                <div v-if="row.item.additional_charges && row.item.additional_charges.length > 0">
                                    <span>{{ formatAmount(getAdditionalChargesTotal(row.item.additional_charges)) }}</span>
                                    <i class="fa fa-info-circle text-primary ml-1"
                                       v-b-tooltip.hover
                                       :title="getAdditionalChargesTooltip(row.item.additional_charges)"></i>
                                </div>
                                <span v-else>0</span>
                            </template>

                            <template #cell(actions)="row">
                                <router-link :to="{ name: 'ViewOrder',params: { id: row.item.id, record : row.item }}" v-b-tooltip.hover title="View" class="btn btn-primary btn-sm"><i class="fa fa-eye"></i></router-link>
                                <button class="btn btn-danger btn-sm" v-b-tooltip.hover title="Delete" @click="deleteOrder(row.index,row.item.id)"  v-if="$can('order_delete')">
                                    <i class="fa fa-trash"></i>
                                </button>
                            </template>

                            <!-- A custom formatted footer cell for field 'name' -->

                            <!-- <template #foot(total)="data">
                                <span class="text-success">{{ $currency }} {{ total_amount }}</span>
                            </template>
                            <template #foot(delivery_charge)="data">
                                <span class="text-success">{{ $currency }} {{ delivery_charge }}</span>
                            </template>
                            <template #foot(additional_charges)="data">
                                <span class="text-success">{{ $currency }} {{ additional_charges_total }}</span>
                            </template>
                            <template #foot(remaining_final)="data">
                                <span class="text-success">{{ $currency }} {{ remaining_final }}</span>
                            </template>

                            <template #foot()="data">

                            </template> -->

                        </b-table>
                        </div>
                        <b-row>
                            <b-col  md="2" class="my-1">
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
                            <b-col  md="4" class="my-1" offset-md="6">
                                <b-pagination
                                    v-model="currentPage"
                                    :total-rows="totalOrderRows"
                                    :per-page="perPage"
                                    align="fill"
                                    size="sm"
                                    class="my-0"
                                ></b-pagination>
                            </b-col>
                        </b-row>
                    </div>
                </div>
            </section>
        </div>
    </div>
</template>
<script>
import DateRangePicker from 'vue2-daterange-picker'
import moment from "moment";
import axios from "axios";
export default {
    name: "range_dates",
    components: {DateRangePicker},
    data: function() {
        return {
            dateRange: {startDate:null, endDate:null},
            deliveryDateRange: { startDate: null, endDate: null },

            stores: [],
            store_id: "",
            cities: [],
            city_id: "",

            customRanges: {
                'Today': this.getTodayRange(),
                'Yesterday': this.getYesterdayRange(),
                'This Week': this.getThisWeekRange(),
                'This Month': this.getThisMonthRange(),
                'This Year': this.getThisYearRange(),
                'Last Month': this.getLastMonthRange(),
            },
            maxDate : new Date(),
            seller:"",
            status:"",
            search:"",
            orderFields: [
                { key: 'id', label:  __('oid'), sortable: false, sortDirection: 'desc', class: 'text-center' },
                { key: 'created_at', label: 'Order Date', sortable: false, class: 'text-center' },
                { key: 'user_name', label: __('user'), sortable: false, class: 'text-center' },
                // { key: 'seller_name', label:  __('seller'), sortable: false, class: 'text-center' },
                { key: 'mobile', label:  __('mobile'), sortable: false, class: 'text-center' },
                { key: 'total', label: __('total')+'('+ this.$currency +')', sortable: false, class: 'text-center' },
                // { key: 'delivery_charge', label: __('dcharges')+'('+ this.$currency +')', sortable: false, class: 'text-center' },
                // { key: 'additional_charges', label: __('a_charges')+'('+ this.$currency +')', sortable: false, class: 'text-center' },
                // { key: 'wallet_balance', label: __('wallet_used')+'('+ this.$currency +')', sortable: false, class: 'text-center' },
                // { key: 'remaining_final', label: __('ftotal')+'('+ this.$currency +')', sortable: false, class: 'text-center' },
                { key: 'payment_method', label: __('p_method'), sortable: false, class: 'text-center' },
                { key: 'delivery_boy_name', label: __('delivery_boy'), sortable: false, class: 'text-center' },
                // { key: 'minutes_from_now', label: __('time_left'), sortable: false, class: 'text-center' },
                { key: 'status', label: __('status'), sortable: false, class: 'text-center' },

                // { key: 'delivery_time', label: __('d_time'), sortable: false, class: 'text-center' },
                { key: "actions", label: __('actions') }
            ],
            footClone: false,


            totalOrderRows:1,

            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            sortBy: '',
            sortDesc: false,
            sortDirection: 'asc',
            filter: null,
            filterOn: [],
            page: 1,

            isLoading: false,
            sectionStyle : 'style_1',
            max_visible_units : 12,
            max_col_in_single_row : 3,
            statuses:[],

            orders: [],
            total_amount:0,
            delivery_charge:0,
            remaining_final:0,
            additional_charges_total: 0,


            sellers:null,
            sellersList: [],
            itemCurrentPage:1,
            itemPerPage:this.$perPage,
            itemPageOptions: this.$pageOptions,
            selectedTab: '',

        }
    },
    computed: {
        sortOptions() {
            // Create an options list from our fields
            return this.orderFields
                .filter(f => f.sortable)
                .map(f => {
                    return { text: f.label, value: f.key }
                })
        },
    },
    mounted() {


    },
    created: function() {
        this.loadFilter();
        this.getOrderStatus();

        this.getStores();
        this.getCities();

        // Set status from URL query param BEFORE calling getOrders
        if (this.$route.query.status_id) {
            this.status = this.$route.query.status_id;
        }

        this.getOrders();
    },
    watch: {
        currentPage() {
            this.getOrders();
        },
        perPage() {
            this.getOrders();
        },

        '$route.query.status_id'(newVal) {
            this.status = newVal || '';
            this.currentPage = 1;
            this.getOrders();
        },
        store_id(newVal) {
            // Clear seller selection when store changes
            this.seller = '';
            this.sellersList = [];
            if (newVal) {
                this.getSellersByStore(newVal);
            }
            this.handleFilterChange();
        }
    },
    methods: {

        getStores() {
            axios.get(this.$apiUrl + '/get-all-stores-data')
                .then((response) => {
                    // Filter out Super Mart (id: 17) from the stores list
                    // this.stores = response.data.filter(store => store.id !== 17);
                    this.stores = response.data;
                })
                .catch(() => {
                    this.showError("Unable to load stores");
                });
        },

        getCities() {
            axios.get(this.$apiUrl + '/cities')
                .then((response) => {
                    this.cities = response.data.data || response.data;
                })
                .catch(() => {
                    this.showError("Unable to load cities");
                });
        },

        getSellersByStore(storeId) {
            axios.get(this.$apiUrl + '/sellers', {
                params: {
                    store_id: storeId,
                    filterStatus: 1  // Only active sellers
                }
            })
            .then((response) => {
                this.sellersList = response.data.data || [];
            })
            .catch(() => {
                this.showError("Unable to load sellers");
            });
        },


        getStatusId(statusString) {
            if (!statusString) return null;

            try {
                const parsed = JSON.parse(statusString); // [[2,"02-12-2025 07:37:08am"]]
                if (Array.isArray(parsed) && parsed.length > 0) {
                    const last = parsed[parsed.length - 1]; // latest status
                    return last[0]; // status id only
                }
                return null;
            } catch (e) {
                console.error('Invalid status format:', statusString);
                return null;
            }
        },

        getStatusLabel(id) {
            const map = {
                1: 'Payment Pending',
                2: 'Received',
                3: 'Processed',
                4: 'Shipped',
                5: 'Out For Delivery',
                6: 'Delivered',
                7: 'Cancelled',
                8: 'Returned'
            };
            return map[id] || '-';
        },

        getStatusBadgeClass(id) {
            const map = {
                1: 'badge-warning',
                2: 'badge-info',
                3: 'badge-primary',
                4: 'badge-secondary',
                5: 'badge-dark',
                6: 'badge-success',
                7: 'badge-danger',
                8: 'badge-danger'
            };
            return map[id] || 'badge-light';
        },

        getTodayRange() {
      let startDate = new Date();
      startDate.setHours(0, 0, 0, 0); // Start of today

      let endDate = new Date();
      endDate.setHours(23, 59, 59, 999); // End of today
     this.dateRange = { startDate, endDate };
      //this.deliveryDateRange = { startDate, endDate };
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
        getOrderStatus: function (tabTitle) {
            let vm = this;
            axios.get(this.$apiUrl + '/order_statuses').then((response) => {
                this.isLoading = false
                this.statuses = response.data.data;
               // const statusesToRemoveIds = (tabTitle === 'Order Items') ? [] : [7, 8];
               // this.statuses = response.data.data.filter(status => !statusesToRemoveIds.includes(status.id));
            }).catch(error => {
                vm.isLoading = false;
                if (error?.request?.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError(__('something_went_wrong'));
                }
            });
        },
        onTabChange(tabTitle) {
            this.selectedTab = tabTitle;
        },
        handleFilterChange() {
            localStorage.setItem('dateRangeStartDateFilter', this.dateRange.startDate);
            localStorage.setItem('dateRangeEndDateFilter', this.dateRange.endDate);
            localStorage.setItem('sellerFilter', this.seller);
            localStorage.setItem('statusFilter', this.status);
            localStorage.setItem('dateRangeStartDeliveryDateFilter', this.deliveryDateRange.startDate);
            localStorage.setItem('dateRangeEndDeliveryDateFilter', this.deliveryDateRange.endDate);
            localStorage.setItem('searchFilter', this.search);
            localStorage.setItem('cityFilter', this.city_id);
            this.getOrders();
        },
        loadFilter() {
            const saveddateRangeStartDateFilter = localStorage.getItem('dateRangeStartDateFilter');
            if (saveddateRangeStartDateFilter && saveddateRangeStartDateFilter != null && moment(saveddateRangeStartDateFilter).isValid()) {
                this.dateRange.startDate = saveddateRangeStartDateFilter;
            }
            const saveddateRangeEndDateFilter = localStorage.getItem('dateRangeEndDateFilter');
            if (saveddateRangeEndDateFilter && saveddateRangeEndDateFilter != null && moment(saveddateRangeEndDateFilter).isValid()) {
                this.dateRange.endDate = saveddateRangeEndDateFilter;
            }
            const savedSeller = localStorage.getItem('sellerFilter');
            if (savedSeller) {
                this.seller = savedSeller;
            }
            // const savedStatus = localStorage.getItem('statusFilter');
            // if (savedStatus) {
            //     this.status = savedStatus;
            // }
            const savedStatus = localStorage.getItem('statusFilter');
            if (!this.$route.query.status_id && savedStatus) {
                this.status = savedStatus;
            }
            const saveddateRangeStartDeliveryDateFilter = localStorage.getItem('dateRangeStartDeliveryDateFilter');
            if (saveddateRangeStartDeliveryDateFilter && moment(saveddateRangeStartDeliveryDateFilter).isValid()) {
                this.deliveryDateRange.startDate = saveddateRangeStartDeliveryDateFilter;
            }
            const saveddateRangeEndDeliveryDateFilter = localStorage.getItem('dateRangeEndDeliveryDateFilter');
            if (saveddateRangeEndDeliveryDateFilter && moment(saveddateRangeEndDeliveryDateFilter).isValid()) {
                this.deliveryDateRange.endDate = saveddateRangeEndDeliveryDateFilter;
            }
            const savedSearchFilter = localStorage.getItem('searchFilter');
            if (savedSearchFilter) {
                this.search = savedSearchFilter;
            }
            const savedCityFilter = localStorage.getItem('cityFilter');
            if (savedCityFilter) {
                this.city_id = savedCityFilter;
            }
        },
        clearDate(){
            this.dateRange.startDate = null,
            this.dateRange.endDate = null,
            localStorage.setItem('dateRangeStartDateFilter', this.dateRange.startDate);
            localStorage.setItem('dateRangeEndDateFilter', this.dateRange.endDate);
            this.getOrders()
        },
        clearDeliveryDate(){
            this.deliveryDateRange.startDate = null,
            this.deliveryDateRange.endDate = null,
            localStorage.setItem('dateRangeStartDeliveryDateFilter', this.deliveryDateRange.startDate);
            localStorage.setItem('dateRangeEndDeliveryDateFilter', this.deliveryDateRange.endDate);
            this.getOrders()
        },
        getOrders(){
            let vm = this;
            this.isLoading = true
            const param = {
                "startDate": (this.dateRange.startDate != null && moment(this.dateRange.startDate).isValid()) ? moment(this.dateRange.startDate).format('YYYY-MM-DD'):"",
                "endDate": (this.dateRange.endDate != null && moment(this.dateRange.endDate).isValid()) ? moment(this.dateRange.endDate).format('YYYY-MM-DD'):"",
                startDeliveryDate: (this.deliveryDateRange.endDate != null && moment(this.deliveryDateRange.endDate).isValid()) ? moment(this.deliveryDateRange.startDate).format('YYYY-MM-DD') : '',
                endDeliveryDate: (this.deliveryDateRange.endDate != null && moment(this.deliveryDateRange.endDate).isValid()) ? moment(this.deliveryDateRange.endDate).format('YYYY-MM-DD') : '',
                "seller":this.seller,
                "status":this.status,
                store_id: this.store_id,
                city_id: this.city_id,
                page: this.currentPage,
                per_page: this.perPage,
                item_page: this.itemCurrentPage,
                item_per_page: this.itemPerPage,
                search: this.search
            }

            axios.get(this.$apiUrl + '/orders',{
                params: param
            }).then((response) => {

                    this.sellers = response.data.data.sellers;
                    this.orders = response.data.data.orders;
                    this.totalOrderRows = response.data.data.orders_total;

                    this.total_amount = this.orders.map(item => Number(item.total)).reduce((prev, curr) => prev + curr, 0).toFixed(2);
                    this.delivery_charge = this.orders.map(item => Number(item.delivery_charge)).reduce((prev, curr) => prev + curr, 0).toFixed(2);
                    this.additional_charges_total = this.orders
                        .map(item => this.getAdditionalChargesTotal(item.additional_charges || []))
                        .reduce((prev, curr) => prev + curr, 0)
                        .toFixed(2);
                    this.remaining_final = this.orders.map(item => Number(item.remaining_final)).reduce((prev, curr) => prev + curr, 0).toFixed(2);

                    this.isLoading = false;

            }).catch(error => {
                vm.isLoading = false;
                if (error?.request?.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError(__('something_went_wrong'));
                }
            });
        },
        deleteOrder(index, id){
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
                        id : id
                    }
                    axios.post(this.$apiUrl + '/orders/delete',postData)
                        .then((response) => {
                            this.isLoading = false
                            let data = response.data;
                            this.orders.splice(index, 1)
                            this.showSuccess(data.message)
                        });
                }
            });
        },
        deleteOrderItem(index, id){
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
                        id : id
                    }
                    axios.post(this.$apiUrl + '/orders/delete_item',postData)
                        .then((response) => {
                            this.isLoading = false
                            let data = response.data;
                            this.order_items.splice(index, 1)
                            this.showSuccess(data.message)
                        });
                }
            });
        },
        getAdditionalChargesTotal(charges) {
            if (!charges || !Array.isArray(charges)) return 0;
            return charges.reduce((total, charge) => total + (parseFloat(charge.amount) || 0), 0);
        },
        getAdditionalChargesTooltip(charges) {
            if (!charges || !Array.isArray(charges) || charges.length === 0) return 'No additional charges';

            return charges.map(charge =>
                `${charge.title}: ${this.$currency}${this.formatAmount(charge.amount)}`
            ).join('\n');
        },
        formatAmount(amount) {
            if (typeof amount !== 'number') amount = parseFloat(amount);
            return Number.isInteger(amount) ? amount : amount.toFixed(2);
        },
        formatDateTime(dateTime) {
            if (!dateTime) return '-';
            return moment(dateTime).format('DD-MM-YYYY hh:mm A');
        },
    }
};
</script>

<style scoped>
@import "../../../../node_modules/vue2-daterange-picker/dist/vue2-daterange-picker.css";
.vue-daterange-picker[data-v-1ebd09d2] {
    min-width: 80%;
}
@media only screen and (min-width: 600px) {
    .vue-daterange-picker[data-v-1ebd09d2] {
        min-width: 90%;
    }
}

.badge {
    padding: 6px 12px;
    border-radius: 14px;
    font-size: 12px;
    font-weight: 600;
    display: inline-block;
}

.badge-warning { background: #ffc107; color: #000; }
.badge-info { background: #17a2b8; color: #fff; }
.badge-primary { background: #0d6efd; color: #fff; }
.badge-secondary { background: #6c757d; color: #fff; }
.badge-dark { background: #343a40; color: #fff; }
.badge-success { background: #28a745; color: #fff; }
.badge-danger { background: #dc3545; color: #fff; }
.badge-light { background: #f8f9fa; color: #000; }

</style>
