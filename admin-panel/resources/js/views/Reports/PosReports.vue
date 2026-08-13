<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>POS Orders Report</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">POS Orders Report</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>
            <section class="section">
                <div class="card">
                    <div class="card-header">
                        <h4 class="card-title">POS Orders Report</h4>
                    </div>
                    <div class="card-body">
                        <b-row class="mb-2">
                            <b-col md="3">
                                <h6 class="box-title">From & To Date</h6>
                                <div class="d-flex justify-content-center align-items-center">
                                    <date-range-picker
                                        :autoApply=false
                                        :showDropdowns=true
                                        v-model="dateRange"
                                        :maxDate="maxDate"
                                        @update="getPosOrders"
                                    ></date-range-picker>
                                    <button class="btn btn-sm btn-danger ml-1" @click="dateRange.startDate = null, dateRange.endDate = null, getPosOrders()">
                                        {{ __('clear') }}
                                    </button>
                                </div>
                            </b-col>
                            <b-col md="3">
                                <h6 class="box-title">Store</h6>
                                <b-form-select class="form-select"
                                    v-model="selectedStore"
                                    :options="storeOptions"
                                    @change="getPosOrders"
                                ></b-form-select>
                            </b-col>
                            <b-col md="3">
                                <h6 class="box-title">Payment Method</h6>
                                <b-form-select class="form-select"
                                    v-model="selectedPaymentMethod"
                                    :options="paymentMethodOptions"
                                    @change="getPosOrders"
                                ></b-form-select>
                            </b-col>
                            <b-col md="2">
                                <h6 class="box-title">{{ __('search') }}</h6>
                                <b-form-input
                                    id="filter-input"
                                    v-model="filter"
                                    type="search"
                                    :placeholder="__('search')"
                                    @input="onFilterChanged"
                                ></b-form-input>
                            </b-col>
                            <b-col md="1">
                                <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getPosOrders()">
                                    <i class="fa fa-refresh" aria-hidden="true"></i>
                                </button>
                            </b-col>
                        </b-row>

                        <div class="table-responsive">
                            <table class="table table-bordered">
                                <thead>
                                    <tr class="bg-light">
                                        <th class="text-center">Order ID</th>
                                        <th class="text-center">Store</th>
                                        <th class="text-center">Customer</th>
                                        <th class="text-center">Mobile Number</th>
                                        <th class="text-center">Date</th>
                                        <th class="text-center">Total Amount</th>
                                        <th class="text-center">Payment Method</th>
                                        <th class="text-center">Invoice</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-if="isLoading">
                                        <td colspan="8" class="text-center text-black my-2">
                                            <b-spinner class="align-middle"></b-spinner>
                                            <strong>{{ __('loading') }}...</strong>
                                        </td>
                                    </tr>
                                    <tr v-else-if="filteredItems.length === 0">
                                        <td colspan="8" class="text-center">No records found</td>
                                    </tr>
                                    <template v-else>
                                        <tr v-for="item in paginatedItems" :key="item.id">
                                            <td class="text-center">{{ item.id }}</td>
                                            <td class="text-center">{{ item.store_name || '-' }}</td>
                                            <td class="text-center">{{ item.customer_name }}</td>
                                            <td class="text-center">{{ item.customer_mobile || '-' }}</td>
                                            <td class="text-center">{{ formatDate(item.created_at) }}</td>
                                            <td class="text-center">{{ $currency }} {{ item.total_amount }}</td>
                                            <td class="text-center">{{ item.payment_method }}</td>
                                            <td class="text-center">
                                                <button class="btn btn-sm btn-primary" @click="viewInvoice(item.id)">
                                                    <i class="fa fa-receipt" aria-hidden="true"></i>
                                                </button>
                                            </td>
                                        </tr>
                                    </template>
                                </tbody>
                                <tfoot>
                                    <tr class="bg-light font-weight-bold">
                                        <td class="text-center">Total</td>
                                        <td></td>
                                        <td></td>
                                        <td></td>
                                        <td></td>
                                        <td class="text-center">{{ $currency }} {{ footerTotal }}</td>
                                        <td></td>
                                        <td></td>
                                    </tr>
                                </tfoot>
                            </table>
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
                                        @change="onPerPageChange"
                                    ></b-form-select>
                                </b-form-group>
                            </b-col>
                            <b-col md="4" class="my-1 d-flex align-items-center justify-content-center">
                                <div class="total-amount-display">
                                    <strong>{{ __('total_amount') }}:</strong> {{ $currency }} {{ totalAmount }}
                                </div>
                            </b-col>
                            <b-col md="6" class="my-1">
                                <b-pagination
                                    v-model="currentPage"
                                    :total-rows="totalRows"
                                    :per-page="perPage"
                                    align="fill"
                                    size="sm"
                                    class="my-0"
                                    @change="onPageChange"
                                ></b-pagination>
                            </b-col>
                        </b-row>
                    </div>
                </div>
            </section>
        </div>

        <!-- Invoice Modal -->
        <b-modal id="invoice-modal" size="xl" title="POS Invoice" hide-footer>
            <div class="invoice-container">
                <iframe :src="invoiceUrl" frameborder="0" style="width: 100%; height: 80vh;"></iframe>
            </div>
            <div class="text-center mt-3">
                <button class="btn btn-secondary" @click="$bvModal.hide('invoice-modal')">Close</button>
                <button class="btn btn-primary ml-2" @click="printInvoice">Print</button>
            </div>
        </b-modal>
    </div>
</template>
<script>
import DateRangePicker from 'vue2-daterange-picker';
import moment from "moment";
export default {
    name: "pos_reports",
    components: {DateRangePicker},
    data: function() {
        return {
            dateRange: {startDate: null, endDate: null},
            maxDate: new Date(),
            invoiceUrl: '',
            fields: [
                { key: 'id', label: 'Order ID', sortable: true, class: 'text-center' },
                { key: 'store_name', label: 'Store', sortable: true, class: 'text-center' },
                { key: 'customer_name', label: 'Customer', sortable: true, class: 'text-center' },
                { key: 'customer_mobile', label: 'Mobile Number', sortable: true, class: 'text-center' },
                { key: 'created_at', label: 'Date', sortable: true, class: 'text-center',formatter: this.formatDate },
                { key: 'total_amount', label: 'Total Amount', sortable: true, class: 'text-center' },
                { key: 'payment_method', label: 'Payment Method', sortable: true, class: 'text-center' },
                { key: 'actions', label: 'Invoice', class: 'text-center', tdClass: 'invoice-action-cell' },
            ],
            tableKey: 0, // Key to force table re-render
            totalRows: 0,
            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            filter: null,
            isLoading: false,
            posOrders: [],
            filteredItems: [],
            selectedPaymentMethod: null,
            selectedStore: null,
            paymentMethodOptions: [
                { value: null, text: 'All Payment Methods' },
                { value: 'cash', text: 'Cash' },
                { value: 'upi', text: 'UPI' },
                { value: 'card', text: 'Card' }
            ],
            storeOptions: [
                { value: null, text: 'All Stores' }
            ],
            footerTotal: '0.00',
            totalAmount: '0.00'
        }
    },
    mounted() {
        this.getStores();
    },
    created: function() {
        this.getPosOrders();
    },
    methods: {
        getStores() {
            // Fetch stores for the dropdown
            axios.get(this.$apiUrl + '/get-stores')
                .then((response) => {
                    if (response.data.status) {
                        // Add stores to the dropdown options
                        const stores = response.data.data.map(store => {
                            return { value: store.id, text: store.name }
                        });
                        
                        // Merge with the default "All Stores" option
                        this.storeOptions = [
                            { value: null, text: 'All Stores' },
                            ...stores
                        ];
                    }
                })
                .catch(error => {
                    console.error('Error fetching stores:', error);
                });
        },
        
        getPosOrders() {
            this.isLoading = true;
            let params = {
                "startDate": (this.dateRange.startDate != null) ? moment(this.dateRange.startDate).format('YYYY-MM-DD') : "",
                "endDate": (this.dateRange.endDate != null) ? moment(this.dateRange.endDate).format('YYYY-MM-DD') : "",
                "payment_method": this.selectedPaymentMethod,
                "store_id": this.selectedStore
            };
            
            axios.get(this.$apiUrl + '/pos-reports', { params })
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status) {
                        this.posOrders = response.data.data;
                        this.filteredItems = [...this.posOrders];
                        this.totalRows = this.filteredItems.length;
                        this.calculateFooterTotal();
                        this.calculateTotalAmount();
                    } else {
                        this.showError(response.data.message);
                    }
                })
                .catch(error => {
                    this.isLoading = false;
                    this.showError("Error fetching POS orders");
                    console.error(error);
                });
        },
        
        formatDate(dateString) {
            return moment(dateString).format('DD/MM/YYYY');
        },
        
        calculateTotalAmount() {
            // Calculate grand total (all orders)
            this.totalAmount = this.posOrders.reduce((total, item) => {
                return total + parseFloat(item.total_amount || 0);
            }, 0).toFixed(2);
        },
        
        calculateFooterTotal() {
            // Calculate total for just the current page
            const start = (this.currentPage - 1) * this.perPage;
            const end = Math.min(start + this.perPage, this.filteredItems.length);
            const currentPageItems = this.filteredItems.slice(start, end);
            
            this.footerTotal = currentPageItems.reduce((total, item) => {
                return total + parseFloat(item.total_amount || 0);
            }, 0).toFixed(2);
            
            // Log for debugging
            console.log(`Items on page ${this.currentPage}:`, currentPageItems.length);
            console.log(`Current page totals:`, currentPageItems.map(i => parseFloat(i.total_amount)));
            console.log(`Footer total: ${this.footerTotal}`);
        },
        
        onFilterChanged() {
            if (this.filter) {
                const filterLC = this.filter.toLowerCase();
                this.filteredItems = this.posOrders.filter(item => {
                    return this.fields.some(field => {
                        const value = item[field.key];
                        return value && String(value).toLowerCase().includes(filterLC);
                    });
                });
            } else {
                this.filteredItems = [...this.posOrders];
            }
            
            this.totalRows = this.filteredItems.length;
            this.currentPage = 1; // Reset to first page when filtering
            this.tableKey++; // Force table re-render
            this.calculateFooterTotal();
        },
        
        onPageChange() {
            this.calculateFooterTotal();
            this.tableKey++; // Force table re-render
        },
        
        onPerPageChange() {
            this.currentPage = 1; // Reset to first page when changing per page
            this.calculateFooterTotal();
            this.tableKey++; // Force table re-render
        },
        
        viewInvoice(orderId) {
            // Set the invoice URL and show modal instead of opening in new tab
            this.invoiceUrl = `/admin/pos/invoice/${orderId}`;
            this.$bvModal.show('invoice-modal');
        },

        printInvoice() {
            const iframe = document.querySelector('#invoice-modal iframe');
            if (iframe) {
                iframe.contentWindow.print();
            }
        }
    },
    computed: {
        paginatedItems() {
            const start = (this.currentPage - 1) * this.perPage;
            const end = Math.min(start + this.perPage, this.filteredItems.length);
            return this.filteredItems.slice(start, end);
        }
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

.order-details-header {
    background-color: #f8f9fa;
    padding: 15px;
    border-radius: 5px;
    margin-bottom: 20px;
}

.total-amount-display {
    font-weight: bold;
    font-size: 1.1rem;
    color: #435ebe;
}

.invoice-action-cell {
    min-width: 100px;
}
</style>
