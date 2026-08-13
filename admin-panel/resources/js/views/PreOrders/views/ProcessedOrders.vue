<template>
    <div>
        <StoreAnalytics
            :store-data="storeWiseData"
            :loading="loadingAnalytics"
            @refresh="fetchStoreAnalytics"
            @view-store="viewStoreOrders"
            @print-pdf="handleStorePrintPDF"
            @print-invoice="handleStorePrintInvoice"
        />

        <section class="section">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <div>
                        <h4 class="card-title mb-0">Processed Pre Orders</h4>
                        <p class="text-muted small mb-0">Orders that have been processed and converted to regular orders</p>
                    </div>
                    <div class="d-flex gap-2">
                        <button class="btn btn-sm btn-success" @click="downloadExcel()">
                            <i class="fa fa-file-excel"></i> Export Excel
                        </button>
                        <button class="btn btn-sm btn-danger" @click="downloadPDF()">
                            <i class="fa fa-file-pdf"></i> Export PDF
                        </button>
                        <button class="btn btn-sm btn-primary" @click="bulkPrintAll()">
                            <i class="fa fa-print"></i> Print All
                        </button>
                    </div>
                </div>
                <div class="card-body">
                    <!-- Filters -->
                    <div class="row mb-3">
                        <b-col md="3">
                            <h6 class="box-title">Date Range</h6>
                            <div class="d-flex align-items-center">
                                <date-range-picker
                                    :autoApply=false
                                    :showDropdowns=true
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
                            <select v-model="store_id" @change="handleFilterChange()" class="form-control form-select">
                                <option value="">All Stores</option>
                                <option v-for="store in stores" :key="store.id" :value="store.id">
                                    {{ store.name }}
                                </option>
                            </select>
                        </b-col>

                        <b-col md="3">
                            <h6 class="box-title">Search</h6>
                            <b-form-input
                                v-model="search"
                                type="search"
                                placeholder="Search by ID, customer, mobile..."
                                @input="handleFilterChange()"
                            ></b-form-input>
                        </b-col>

                        <b-col md="1" class="text-center">
                            <h6 class="box-title">&nbsp;</h6>
                            <button class="btn btn-primary" @click="fetchOrders()">
                                <i class="fa fa-refresh"></i>
                            </button>
                        </b-col>
                    </div>

                    <!-- Stats Badge -->
                    <div class="alert alert-success d-flex justify-content-between align-items-center mb-3">
                        <div>
                            <i class="fa fa-check-circle fa-2x me-3"></i>
                            <span><strong>{{ totalOrderRows }}</strong> processed preorders</span>
                        </div>
                        <div>
                            <span class="text-muted">Total Amount: </span>
                            <strong class="fs-5">₹{{ totalAmount.toFixed(2) }}</strong>
                        </div>
                    </div>

                    <!-- Orders Table -->
                    <OrdersTable
                        :orders="orders"
                        :loading="isLoading"
                        :current-page="currentPage"
                        :per-page="perPage"
                        :total-rows="totalOrderRows"
                        @print-thermal="printThermalInvoice"
                        @print-usb="printDirectUSB"
                        @download-pdf="downloadOrderPDF"
                        @page-change="handlePageChange"
                    />
                </div>
            </div>
        </section>
    </div>
</template>

<script>
import moment from 'moment';
import axios from 'axios';
import DateRangePicker from 'vue2-daterange-picker';
import 'vue2-daterange-picker/dist/vue2-daterange-picker.css';

import StoreAnalytics from '../components/StoreAnalytics.vue';
import OrdersTable from '../components/OrdersTable.vue';
import preorderMixin from '../mixins/preorderMixin';

export default {
    name: 'ProcessedOrders',
    components: {
        DateRangePicker,
        StoreAnalytics,
        OrdersTable
    },
    mixins: [preorderMixin],
    data() {
        return {
            isLoading: false,
            loadingAnalytics: false,
            orders: [],
            stores: [],
            storeWiseData: [],
            status: '2', // Fixed to processed status

            // Filters
            store_id: '',
            search: '',
            dateRange: {
                startDate: null,
                endDate: null
            },
            maxDate: new Date(),
            customRanges: {
                'Today': [moment().toDate(), moment().toDate()],
                'Yesterday': [moment().subtract(1, 'days').toDate(), moment().subtract(1, 'days').toDate()],
                'This Week': [moment().startOf('week').toDate(), moment().endOf('week').toDate()],
                'Last Week': [moment().subtract(1, 'week').startOf('week').toDate(), moment().subtract(1, 'week').endOf('week').toDate()],
                'This Month': [moment().startOf('month').toDate(), moment().endOf('month').toDate()],
                'Last Month': [moment().subtract(1, 'month').startOf('month').toDate(), moment().subtract(1, 'month').endOf('month').toDate()],
            },

            // Pagination
            currentPage: 1,
            perPage: 10,
            totalOrderRows: 0
        }
    },
    computed: {
        totalAmount() {
            return this.orders.reduce((sum, order) => sum + parseFloat(order.final_total || 0), 0);
        }
    },
    created() {
        this.fetchOrders();
        this.fetchStoreAnalytics();
    },
    methods: {
        async fetchOrders() {
            this.isLoading = true;

            const params = {
                page: this.currentPage,
                per_page: this.perPage,
                search: this.search,
                status: this.status,
                store_id: this.store_id,
                startDate: (this.dateRange.startDate && moment(this.dateRange.startDate).isValid())
                    ? moment(this.dateRange.startDate).format('YYYY-MM-DD') : '',
                endDate: (this.dateRange.endDate && moment(this.dateRange.endDate).isValid())
                    ? moment(this.dateRange.endDate).format('YYYY-MM-DD') : ''
            };

            const result = await this.fetchPreOrders(params);
            this.orders = result.orders;
            this.totalOrderRows = result.total;
            this.stores = result.stores;
            this.isLoading = false;
        },

        async fetchStoreAnalytics() {
            this.loadingAnalytics = true;

            const params = {
                startDate: (this.dateRange.startDate && moment(this.dateRange.startDate).isValid())
                    ? moment(this.dateRange.startDate).format('YYYY-MM-DD') : '',
                endDate: (this.dateRange.endDate && moment(this.dateRange.endDate).isValid())
                    ? moment(this.dateRange.endDate).format('YYYY-MM-DD') : '',
                status: this.status
            };

            const data = await this.fetchStoreWiseAnalytics(params);
            this.storeWiseData = data;
            this.loadingAnalytics = false;
        },

        handleFilterChange() {
            this.currentPage = 1;
            this.fetchOrders();
            this.fetchStoreAnalytics();
        },

        handlePageChange(page) {
            this.currentPage = page;
            this.fetchOrders();
        },

        clearDate() {
            this.dateRange = {
                startDate: null,
                endDate: null
            };
            this.handleFilterChange();
        },

        viewStoreOrders(store) {
            this.$router.push({
                name: 'StorePreOrders',
                params: { storeId: store.store_id },
                query: {
                    storeName: store.store_name,
                    startDate: (this.dateRange.startDate && moment(this.dateRange.startDate).isValid())
                        ? moment(this.dateRange.startDate).format('YYYY-MM-DD') : '',
                    endDate: (this.dateRange.endDate && moment(this.dateRange.endDate).isValid())
                        ? moment(this.dateRange.endDate).format('YYYY-MM-DD') : '',
                    status: this.status
                }
            });
        },

        handleStorePrintPDF(store) {
            const filters = {
                startDate: (this.dateRange.startDate && moment(this.dateRange.startDate).isValid())
                    ? moment(this.dateRange.startDate).format('YYYY-MM-DD') : '',
                endDate: (this.dateRange.endDate && moment(this.dateRange.endDate).isValid())
                    ? moment(this.dateRange.endDate).format('YYYY-MM-DD') : '',
                status: this.status
            };
            this.printStorePDF(store.store_id, store.store_name, filters);
        },

        handleStorePrintInvoice(store) {
            const filters = {
                startDate: (this.dateRange.startDate && moment(this.dateRange.startDate).isValid())
                    ? moment(this.dateRange.startDate).format('YYYY-MM-DD') : '',
                endDate: (this.dateRange.endDate && moment(this.dateRange.endDate).isValid())
                    ? moment(this.dateRange.endDate).format('YYYY-MM-DD') : '',
                status: this.status,
                search: this.search
            };
            this.printStoreInvoice(store.store_id, store.store_name, filters);
        },

        async downloadPDF() {
            try {
                this.$toast.info('Generating PDF...');

                const params = {
                    search: this.search,
                    status: this.status,
                    store_id: this.store_id,
                    startDate: (this.dateRange.startDate && moment(this.dateRange.startDate).isValid())
                        ? moment(this.dateRange.startDate).format('YYYY-MM-DD') : '',
                    endDate: (this.dateRange.endDate && moment(this.dateRange.endDate).isValid())
                        ? moment(this.dateRange.endDate).format('YYYY-MM-DD') : ''
                };

                const response = await axios.get(this.$apiUrl + '/preorders/export/pdf', { params });

                if (response.data.status === 1) {
                    const { orders, date } = response.data.data;
                    const totalAmount = orders.reduce((sum, order) => sum + parseFloat(order.final_total || 0), 0);
                    const printContent = this.generateProcessedPrintContent(orders, date, totalAmount);

                    const printWindow = window.open('', '', 'width=800,height=600');
                    printWindow.document.write(printContent);
                    printWindow.document.close();
                    printWindow.focus();

                    setTimeout(() => printWindow.print(), 250);
                    this.$toast.info('Print dialog opened - Select "Save as PDF" to download');
                }
            } catch (error) {
                console.error('PDF download error:', error);
                this.$toast.error('Failed to generate PDF');
            }
        },

        generateProcessedPrintContent(orders, date, totalAmount) {
            let rows = '';
            orders.forEach(order => {
                rows += `
                    <tr>
                        <td><strong>#${order.id}</strong></td>
                        <td>${order.user_name || 'Guest'}</td>
                        <td>${order.mobile}</td>
                        <td class="text-right"><strong>₹${parseFloat(order.final_total).toFixed(2)}</strong></td>
                        <td>${order.payment_method}</td>
                        <td>${order.preorder_placed_at_formatted || 'N/A'}</td>
                        <td>${order.preorder_process_date_formatted || 'N/A'}</td>
                    </tr>
                `;
            });

            return `
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Processed Pre Orders - ${date}</title>
                    <style>
                        @page { size: A4 landscape; margin: 1cm; }
                        * { margin: 0; padding: 0; box-sizing: border-box; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; color-adjust: exact !important; }
                        body { font-family: Arial, sans-serif; font-size: 10px; color: #333; padding: 20px; }
                        .header { text-align: center; margin-bottom: 20px; padding-bottom: 10px; border-bottom: 2px solid #27ae60; }
                        .header h1 { font-size: 24px; color: #2c3e50; margin-bottom: 5px; }
                        .header h2 { font-size: 18px; color: #27ae60; margin-bottom: 5px; }
                        .header p { font-size: 12px; color: #7f8c8d; }
                        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
                        thead { background-color: #27ae60 !important; color: white !important; }
                        th { padding: 8px 5px; text-align: left; font-size: 9px; font-weight: bold; background-color: #27ae60 !important; color: white !important; }
                        td { padding: 6px 5px; border-bottom: 1px solid #ddd; font-size: 9px; }
                        tbody tr:nth-child(even) { background-color: #d4edda !important; }
                        .text-right { text-align: right; }
                        .summary { margin-top: 20px; padding: 15px; background-color: #d4edda !important; border: 2px solid #27ae60; border-radius: 5px; }
                        .summary-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 11px; }
                        .footer { margin-top: 20px; text-align: center; font-size: 9px; color: #7f8c8d; padding-top: 10px; border-top: 1px solid #ddd; }
                    </style>
                </head>
                <body>
                    <div class="header">
                        <h1>ZENFOO - PROCESSED PRE ORDERS</h1>
                        <h2>Successfully Processed</h2>
                        <p>Generated on ${date}</p>
                    </div>
                    <table>
                        <thead>
                            <tr><th>Order ID</th><th>Customer</th><th>Mobile</th><th class="text-right">Amount</th><th>Payment</th><th>Placed At</th><th>Process Date</th></tr>
                        </thead>
                        <tbody>${rows}</tbody>
                    </table>
                    <div class="summary">
                        <div class="summary-row"><span>Total Processed Orders:</span><strong>${orders.length}</strong></div>
                        <div class="summary-row"><span>Total Processed Amount:</span><strong>₹${parseFloat(totalAmount).toFixed(2)}</strong></div>
                    </div>
                    <div class="footer">
                        <p>&copy; ${new Date().getFullYear()} Zenfoo. All rights reserved.</p>
                    </div>
                </body>
                </html>
            `;
        },

        async downloadExcel() {
            try {
                this.$toast.info('Generating Excel...');

                const params = {
                    search: this.search,
                    status: this.status,
                    store_id: this.store_id,
                    startDate: (this.dateRange.startDate && moment(this.dateRange.startDate).isValid())
                        ? moment(this.dateRange.startDate).format('YYYY-MM-DD') : '',
                    endDate: (this.dateRange.endDate && moment(this.dateRange.endDate).isValid())
                        ? moment(this.dateRange.endDate).format('YYYY-MM-DD') : ''
                };

                const response = await axios.get(this.$apiUrl + '/preorders/export/excel', {
                    params: params,
                    responseType: 'blob'
                });

                const url = window.URL.createObjectURL(new Blob([response.data]));
                const link = document.createElement('a');
                link.href = url;
                link.setAttribute('download', `processed-preorders-${moment().format('YYYY-MM-DD')}.xlsx`);
                document.body.appendChild(link);
                link.click();
                link.remove();

                this.$toast.success('Excel downloaded successfully');
            } catch (error) {
                console.error('Excel download error:', error);
                this.$toast.error('Failed to download Excel');
            }
        },

        async bulkPrintAll() {
            if (this.orders.length === 0) {
                this.$toast.warning('No processed orders to print');
                return;
            }

            this.$toast.info(`Preparing to print ${this.orders.length} processed orders...`);

            for (let i = 0; i < this.orders.length; i++) {
                await this.printThermalInvoice(this.orders[i].id);
                await new Promise(resolve => setTimeout(resolve, 1000));
            }

            this.$toast.success('All processed orders sent to printer');
        }
    }
}
</script>

<style scoped>
.card {
    box-shadow: 0 0 10px rgba(0,0,0,0.05);
}
.gap-2 > * {
    margin-left: 0.5rem;
}
.gap-2 > *:first-child {
    margin-left: 0;
}
.me-3 {
    margin-right: 1rem;
}
</style>