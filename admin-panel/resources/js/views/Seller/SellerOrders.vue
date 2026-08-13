<template>
    <div>
        <div v-if="isLoading" class="text-center py-5">
            <b-spinner variant="primary" label="Loading..."></b-spinner>
            <p class="mt-2">Loading orders...</p>
        </div>
        <div v-else>
            <!-- Filters -->
            <div class="row mb-3">
                <b-col md="3">
                    <h6 class="box-title">{{ __('from_and_to_date') }}</h6>
                    <div class="d-flex justify-content-center align-items-center">
                        <date-range-picker
                            :autoApply="false"
                            :showDropdowns="true"
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
                    <h6 class="box-title">{{ __('status') }}</h6>
                    <select id="status" name="status" v-model="status" @change="handleFilterChange()" class="form-control form-select">
                        <option value="">{{ __('all_orders') }}</option>
                        <option v-for="statusItem in statuses" :key="statusItem.id" :value="statusItem.id">{{ statusItem.status }}</option>
                    </select>
                </b-col>
                <b-col md="3">
                    <h6 class="box-title">{{ __('search') }}</h6>
                    <b-form-input
                        id="filter-input"
                        v-model="search"
                        type="search"
                        :placeholder="__('search')"
                        @input="debounceSearch()"
                    ></b-form-input>
                </b-col>
                <b-col md="1" class="text-center">
                    <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getOrders()">
                        <i class="fa fa-refresh" aria-hidden="true"></i>
                    </button>
                </b-col>
            </div>

            <!-- Orders Table -->
            <div class="table-responsive mt-3">
                <b-table
                    responsive="sm"
                    :items="orders"
                    :fields="orderFields"
                    :sort-by.sync="sortBy"
                    :sort-desc.sync="sortDesc"
                    :sort-direction="sortDirection"
                    :bordered="true"
                    :busy="isLoading"
                    :no-footer-sorting="true"
                    :no-border-collapse="false"
                    stacked="md"
                    show-empty
                    small>

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

                    <template #cell(status)="row">
                        <span class="badge"
                            :class="getStatusBadgeClass(getStatusId(row.item.status))">
                            {{ getStatusLabel(getStatusId(row.item.status)) }}
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

                    <template #cell(actions)="row">
                        <router-link :to="{ name: 'ViewOrder', params: { id: row.item.id, record: row.item }}" v-b-tooltip.hover title="View" class="btn btn-primary btn-sm">
                            <i class="fa fa-eye"></i>
                        </router-link>
                    </template>

                </b-table>
            </div>

            <!-- Pagination -->
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
                        :total-rows="totalOrderRows"
                        :per-page="perPage"
                        align="fill"
                        size="sm"
                        class="my-0"
                    ></b-pagination>
                </b-col>
            </b-row>

            <!-- Empty State -->
            <div v-if="!isLoading && orders.length === 0" class="text-center py-5">
                <i class="fa fa-shopping-cart fa-3x text-muted mb-3"></i>
                <p class="text-muted">No orders found for this seller.</p>
            </div>
        </div>
    </div>
</template>

<script>
import DateRangePicker from 'vue2-daterange-picker'
import moment from "moment";
import axios from "axios";

export default {
    name: 'SellerOrders',
    components: { DateRangePicker },
    props: {
        sellerId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            isLoading: false,
            orders: [],
            totalOrderRows: 0,

            // Filters
            dateRange: { startDate: null, endDate: null },
            status: "",
            search: "",
            maxDate: new Date(),
            customRanges: {
                'Today': this.getTodayRange(),
                'Yesterday': this.getYesterdayRange(),
                'This Week': this.getThisWeekRange(),
                'This Month': this.getThisMonthRange(),
                'This Year': this.getThisYearRange(),
                'Last Month': this.getLastMonthRange(),
            },
            statuses: [],

            // Table config
            orderFields: [
                { key: 'id', label: __('oid'), sortable: false, sortDirection: 'desc', class: 'text-center' },
                { key: 'created_at', label: 'Order Date', sortable: false, class: 'text-center' },
                { key: 'user_name', label: __('user'), sortable: false, class: 'text-center' },
                { key: 'mobile', label: __('mobile'), sortable: false, class: 'text-center' },
                { key: 'total', label: __('total') + '(' + this.$currency + ')', sortable: false, class: 'text-center' },
                { key: 'vendor_wait_charge', label: 'Wait Chrg (' + this.$currency + ')', sortable: false, class: 'text-center' },
                { key: 'payment_method', label: __('p_method'), sortable: false, class: 'text-center' },
                { key: 'delivery_boy_name', label: __('delivery_boy'), sortable: false, class: 'text-center' },
                { key: 'status', label: __('status'), sortable: false, class: 'text-center' },
                { key: "actions", label: __('actions') }
            ],

            // Pagination
            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            sortBy: '',
            sortDesc: false,
            sortDirection: 'asc',
            debounceTimer: null,
        }
    },
    created() {
        this.getOrderStatus();
        this.getOrders();
    },
    watch: {
        currentPage() {
            this.getOrders();
        },
        perPage() {
            this.getOrders();
        }
    },
    methods: {
        getOrders() {
            this.isLoading = true;
            const param = {
                startDate: (this.dateRange.startDate != null && moment(this.dateRange.startDate).isValid()) ? moment(this.dateRange.startDate).format('YYYY-MM-DD') : "",
                endDate: (this.dateRange.endDate != null && moment(this.dateRange.endDate).isValid()) ? moment(this.dateRange.endDate).format('YYYY-MM-DD') : "",
                startDeliveryDate: "",
                endDeliveryDate: "",
                seller: this.sellerId,
                status: this.status,
                store_id: "",
                page: this.currentPage,
                per_page: this.perPage,
                item_page: 1,
                item_per_page: 5,
                search: this.search
            };

            axios.get(this.$apiUrl + '/orders', { params: param })
                .then((response) => {
                    this.orders = response.data.data.orders;
                    this.totalOrderRows = response.data.data.orders_total;
                    this.isLoading = false;
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error fetching orders:', error);
                    if (error?.request?.statusText) {
                        this.showError(error.request.statusText);
                    } else if (error.message) {
                        this.showError(error.message);
                    } else {
                        this.showError(__('something_went_wrong'));
                    }
                });
        },

        getOrderStatus() {
            axios.get(this.$apiUrl + '/order_statuses')
                .then((response) => {
                    this.statuses = response.data.data;
                })
                .catch((error) => {
                    console.error('Error fetching order statuses:', error);
                });
        },

        handleFilterChange() {
            this.currentPage = 1;
            this.getOrders();
        },

        debounceSearch() {
            clearTimeout(this.debounceTimer);
            this.debounceTimer = setTimeout(() => {
                this.currentPage = 1;
                this.getOrders();
            }, 500);
        },

        clearDate() {
            this.dateRange.startDate = null;
            this.dateRange.endDate = null;
            this.getOrders();
        },

        getStatusId(statusString) {
            if (!statusString) return null;
            try {
                const parsed = JSON.parse(statusString);
                if (Array.isArray(parsed) && parsed.length > 0) {
                    const last = parsed[parsed.length - 1];
                    return last[0];
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

        formatDateTime(dateTime) {
            if (!dateTime) return '-';
            return moment(dateTime).format('DD-MM-YYYY hh:mm A');
        },

        // Date Range Methods
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
        }
    }
}
</script>

<style scoped>
@import "~vue2-daterange-picker/dist/vue2-daterange-picker.css";

.vue-daterange-picker {
    min-width: 80%;
}

@media only screen and (min-width: 600px) {
    .vue-daterange-picker {
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

.btn_refresh {
    margin-top: 24px;
}
</style>
