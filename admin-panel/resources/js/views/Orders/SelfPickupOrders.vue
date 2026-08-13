<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>{{ __('self_pickup_orders') }}</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">{{ __('self_pickup_orders') }}</li>
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
                        <h4 class="card-title">{{ __('self_pickup_orders') }}</h4>
                    </div>
                    <div class="card-body">
                        <div class="row mb-2">
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
                            <b-col md="2" v-if="!isSeller">
                                <h6 class="box-title" for="seller">{{ __('seller') }}</h6>
                                <select name="seller" id="seller" v-model="seller" @change="handleFilterChange()" class="form-control form-select">
                                    <option value="">{{ __('all_sellers') }}</option>
                                    <option v-for="seller in sellers" :value="seller.id">{{seller.name}}</option>
                                </select>
                            </b-col>
                            <b-col md="2">
                                <h6 class="box-title" for="status">{{ __('status') }} </h6>
                                <select id="status" name="status" v-model="status" @change="handleFilterChange()" class="form-control form-select">
                                    <option value="">{{ __('all_orders') }}</option>
                                    <option v-for="status in statuses" :value='status.id'>{{ status.status }}</option>
                                </select>
                            </b-col>
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
                                <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getSelfPickupOrders()">
                                    <i class="fa fa-refresh" aria-hidden="true"></i>
                                </button>
                            </b-col>
                        </div>
                        <div class="table-responsive mt-3">
                        <b-table
                            responsive="sm"
                            :items="orders"
                            :fields="filteredOrderFields"
                            :filter="filter"
                            :filter-included-fields="filterOn"
                            :sort-by.sync="sortBy"
                            :sort-desc.sync="sortDesc"
                            :sort-direction="sortDirection"
                            :bordered="true"
                            :busy="isLoading"
                            :foot-clone="true"
                            :no-footer-sorting = "true"
                            :no-border-collapse = "false"
                            stacked="md"
                            show-empty
                            small>

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

                            <template #cell(active_status)="row">
                                <span class="badge" :class="getStatusBadgeClass(row.item.active_status)">{{ getStatusName(row.item.active_status) }}</span>
                            </template>

                            <!-- show the customer facing order number, falling back to
                                 the raw id so a row is never blank -->
                            <template #cell(id)="row">
                                {{ row.item.order_number || ('#' + row.item.id) }}
                            </template>

                            <template #cell(actions)="row">
                                <router-link :to="{ name: 'ViewSelfPickupOrder',params: { id: row.item.id, record : row.item }}" v-b-tooltip.hover title="View" class="btn btn-primary btn-sm"><i class="fa fa-eye"></i></router-link>
                                <button class="btn btn-danger btn-sm" v-b-tooltip.hover title="Delete" @click="deleteOrder(row.index,row.item.id)"  v-if="$can('self_pickup_order_delete') && !isSeller">
                                    <i class="fa fa-trash"></i>
                                </button>
                            </template>

                            <template #foot(total)="data">
                                <span class="text-success">{{ $currency }} {{ total_amount }}</span>
                            </template>
                            <template #foot(additional_charges)="data">
                                <span class="text-success">{{ $currency }} {{ additional_charges_total }}</span>
                            </template>
                            <template #foot(remaining_final)="data">
                                <span class="text-success">{{ $currency }} {{ remaining_final }}</span>
                            </template>

                            <template #foot()="data">

                            </template>

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
import Auth from '../../Auth.js';

export default {
    name: "self_pickup_orders",
    components: {DateRangePicker},
    data: function() {
        return {
            login_user: Auth.user,
            dateRange: {startDate:null, endDate:null},
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
            seller:"",
            status:"",
            search:"",
            orderFields: [
                { key: 'id', label:  __('oid'), sortable: false, sortDirection: 'desc' },
                { key: 'user_name', label: __('user'), sortable: false, class: 'text-center' },
                { key: 'seller_name', label:  __('seller'), sortable: false, class: 'text-center' },
                { key: 'mobile', label:  __('mobile'), sortable: false, class: 'text-center' },
                { key: 'total', label: __('total')+'('+ this.$currency +')', sortable: false, class: 'text-center' },
                { key: 'additional_charges', label: __('a_charges')+'('+ this.$currency +')', sortable: false, class: 'text-center' },
                { key: 'wallet_balance', label: __('wallet_used')+'('+ this.$currency +')', sortable: false, class: 'text-center' },
                { key: 'remaining_final', label: __('ftotal')+'('+ this.$currency +')', sortable: false, class: 'text-center' },
                { key: 'payment_method', label: __('p_method'), sortable: false, class: 'text-center' },
                { key: 'active_status', label: __('status'), sortable: false, class: 'text-center' },
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
            itemCurrentPage:1,
            itemPerPage:this.$perPage,
            itemPageOptions: this.$pageOptions,
            selectedTab: '',

        }
    },
    computed: {
        sortOptions() {
            return this.orderFields
                .filter(f => f.sortable)
                .map(f => {
                    return { text: f.label, value: f.key }
                })
        },
        isSeller() {
            return this.login_user && this.login_user.role && this.login_user.role.name === 'Seller';
        },
        filteredOrderFields() {
            if (this.isSeller) {
                return this.orderFields.filter(field => field.key !== 'seller_name');
            }
            return this.orderFields;
        }
    },
    mounted() {

    },
    created: function() {
        this.loadFilter();
        this.getSelfPickupOrderStatus();
        this.getSelfPickupOrders();
    },
    watch: {
        currentPage() {
            this.getSelfPickupOrders();
        },
        perPage() {
            this.getSelfPickupOrders();
        },

    },
    methods: {
        getTodayRange() {
      let startDate = new Date();
      startDate.setHours(0, 0, 0, 0); 

      let endDate = new Date();
      endDate.setHours(23, 59, 59, 999); 
      this.dateRange = { startDate, endDate };
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
        getSelfPickupOrderStatus: function (tabTitle) {
            let vm = this;
            axios.get(this.$apiUrl + '/order_statuses/self_pickup').then((response) => {
                this.isLoading = false
                this.statuses = response.data.data;
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
            localStorage.setItem('selfPickupDateRangeStartDateFilter', this.dateRange.startDate);
            localStorage.setItem('selfPickupDateRangeEndDateFilter', this.dateRange.endDate);
            localStorage.setItem('selfPickupSellerFilter', this.seller);
            localStorage.setItem('selfPickupStatusFilter', this.status);
            localStorage.setItem('selfPickupSearchFilter', this.search);
            this.getSelfPickupOrders();
        },
        loadFilter() {
            const saveddateRangeStartDateFilter = localStorage.getItem('selfPickupDateRangeStartDateFilter');
            if (saveddateRangeStartDateFilter && saveddateRangeStartDateFilter != null && moment(saveddateRangeStartDateFilter).isValid()) {
                this.dateRange.startDate = saveddateRangeStartDateFilter;
            }
            const saveddateRangeEndDateFilter = localStorage.getItem('selfPickupDateRangeEndDateFilter');
            if (saveddateRangeEndDateFilter && saveddateRangeEndDateFilter != null && moment(saveddateRangeEndDateFilter).isValid()) {
                this.dateRange.endDate = saveddateRangeEndDateFilter;
            }
            const savedSeller = localStorage.getItem('selfPickupSellerFilter');
            if (savedSeller) {
                this.seller = savedSeller;
            }
            const savedStatus = localStorage.getItem('selfPickupStatusFilter');
            if (savedStatus) {
                this.status = savedStatus;
            }
            const savedSearchFilter = localStorage.getItem('selfPickupSearchFilter');
            if (savedSearchFilter) {
                this.search = savedSearchFilter;
            }
        },
        clearDate(){
            this.dateRange.startDate = null,
            this.dateRange.endDate = null,
            localStorage.setItem('selfPickupDateRangeStartDateFilter', this.dateRange.startDate);
            localStorage.setItem('selfPickupDateRangeEndDateFilter', this.dateRange.endDate);
            this.getSelfPickupOrders()
        },
        getSelfPickupOrders(){
            let vm = this;
            this.isLoading = true
            
            const apiEndpoint = this.isSeller ? '/seller/self_pickup_orders' : '/orders/self_pickup';
            
            const param = {
                "startDate": (this.dateRange.startDate != null && moment(this.dateRange.startDate).isValid()) ? moment(this.dateRange.startDate).format('YYYY-MM-DD'):"",
                "endDate": (this.dateRange.endDate != null && moment(this.dateRange.endDate).isValid()) ? moment(this.dateRange.endDate).format('YYYY-MM-DD'):"",
                "seller":this.seller,
                "status":this.status,
                page: this.currentPage,
                per_page: this.perPage,
                item_page: this.itemCurrentPage,
                item_per_page: this.itemPerPage,
                search: this.search
            }

            axios.get(this.$apiUrl + apiEndpoint,{
                params: param
            }).then((response) => {
                    if (!this.isSeller && response.data.data.sellers) {
                        this.sellers = response.data.data.sellers;
                    }
                    this.orders = response.data.data.orders;
                    this.totalOrderRows = response.data.data.orders_total;

                    this.total_amount = this.orders.map(item => Number(item.total)).reduce((prev, curr) => prev + curr, 0).toFixed(2);
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
        getStatusName(statusId) {
            const status = this.statuses.find(s => s.id == statusId);
            return status ? status.status : 'Unknown';
        },
        getStatusBadgeClass(statusId) {
            switch(parseInt(statusId)) {
                case 1: return 'bg-warning';
                case 9: return 'bg-warning';
                case 10: return 'bg-primary'; 
                case 11: return 'bg-success'; 
                case 7: return 'bg-danger';
                case 8: return 'bg-danger';
                default: return 'bg-secondary'; 
            }
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
</style>