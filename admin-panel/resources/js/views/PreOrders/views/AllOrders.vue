<template>
    <div>
        <!-- City / Zone Filter -->
        <div class="city-zone-bar mb-3">
            <select v-model="city_id" @change="handleFilterChange()" class="form-control form-select city-zone-select">
                <option value="">All Cities / Zones</option>
                <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
            </select>
        </div>

        <!-- Week Navigation -->
        <section class="section mb-3">
            <div class="card">
                <div class="card-body">
                    <div class="d-flex justify-content-center align-items-center gap-3 flex-wrap">
                        <button class="btn btn-outline-primary" @click="previousWeek()">
                            <i class="fa fa-chevron-left"></i>
                        </button>

                        <div class="week-range-display">
                            <h5 class="mb-0">{{ currentWeekLabel }}</h5>
                        </div>

                        <button class="btn btn-outline-primary" @click="nextWeek()" :disabled="isNextWeekDisabled">
                            <i class="fa fa-chevron-right"></i>
                        </button>
                    </div>
                </div>
            </div>
        </section>

        <!-- Store Analytics -->
        <StoreAnalytics
            :store-data="storeWiseData"
            :loading="loadingAnalytics"
            @refresh="fetchStoreAnalytics"
            @view-store="viewStoreOrders"
            @print-pdf="handleStorePrintPDF"
            @print-invoice="handleStorePrintInvoice"
        />


        <!-- <section class="section">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h4 class="card-title mb-0">All Pre Orders</h4>
                    <div class="d-flex gap-2">
                        <button class="btn btn-sm btn-success" @click="downloadExcel()">
                            <i class="fa fa-file-excel"></i> Download Excel
                        </button>
                        <button class="btn btn-sm btn-danger" @click="downloadPDF()">
                            <i class="fa fa-file-pdf"></i> Download PDF
                        </button>
                        <div class="btn-group">
                            <button type="button" class="btn btn-sm btn-primary dropdown-toggle" data-bs-toggle="dropdown">
                                <i class="fa fa-print"></i> Bulk Print
                            </button>
                            <ul class="dropdown-menu">
                                <li><a class="dropdown-item" href="#" @click.prevent="bulkPrintAllOrders()">Print All Orders</a></li>
                                <li><hr class="dropdown-divider"></li>
                                <li v-for="store in stores" :key="'print-' + store.id">
                                    <a class="dropdown-item" href="#" @click.prevent="bulkPrintByStore(store.id, store.name)">
                                        Print {{ store.name }}
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
                <div class="card-body">
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

                        <b-col md="2">
                            <h6 class="box-title">Status</h6>
                            <select v-model="status" @change="handleFilterChange()" class="form-control form-select">
                                <option value="">All Status</option>
                                <option value="12">Preorder Pending</option>
                                <option value="2">Processed (Received)</option>
                                <option value="3">In Progress</option>
                                <option value="5">Out For Delivery</option>
                                <option value="6">Delivered</option>
                            </select>
                        </b-col>

                        <b-col md="2">
                            <h6 class="box-title">Search</h6>
                            <b-form-input
                                v-model="search"
                                type="search"
                                placeholder="Search..."
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
        </section> -->
    
    </div>
</template>

<script>
import moment from 'moment';
import axios from 'axios';
import DateRangePicker from 'vue2-daterange-picker';
import 'vue2-daterange-picker/dist/vue2-daterange-picker.css';

import StatsCards from '../components/StatsCards.vue';
import StoreAnalytics from '../components/StoreAnalytics.vue';
import OrdersTable from '../components/OrdersTable.vue';
import preorderMixin from '../mixins/preorderMixin';

export default {
    name: 'AllOrders',
    components: {
        DateRangePicker,
        StatsCards,
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
            stats: {},
            storeWiseData: [],

            // Filters
            store_id: '',
            status: '',
            search: '',
            city_id: '',
            cities: [],
            dateRange: {
                startDate: null,
                endDate: null
            },
            maxDate: new Date(),
            customRanges: {},

            // Pagination
            currentPage: 1,
            perPage: 10,
            totalOrderRows: 0
        }
    },
    created() {
        // Initialize custom ranges with preorder week logic
        this.customRanges = this.getCustomRanges();

        // Set default to Current Preorder Week
        const currentWeek = this.getCurrentPreorderWeek();
        this.dateRange = {
            startDate: currentWeek.start.toDate(),
            endDate: currentWeek.end.toDate()
        };

        if (this.$route.query.status) {
            this.status = this.$route.query.status;
        }

        this.fetchStats();
        this.fetchOrders();
        this.fetchStoreAnalytics();
        this.fetchCities();
    },
    computed: {
        currentWeekLabel() {
            if (!this.dateRange.startDate || !this.dateRange.endDate) {
                return 'Select Week';
            }
            const start = moment(this.dateRange.startDate).format('ddd, MMM DD, YYYY h:mm A');
            const end = moment(this.dateRange.endDate).format('ddd, MMM DD, YYYY h:mm A');
            return `${start} - ${end}`;
        },
        isNextWeekDisabled() {
            if (!this.dateRange.endDate) return true;
            const currentWeek = this.getCurrentPreorderWeek();
            const selectedEnd = moment(this.dateRange.endDate);
            // Disable if selected week end is >= current week end
            return selectedEnd.isSameOrAfter(currentWeek.end);
        }
    },
    watch: {
        '$route.query.status'(newVal) {
            this.status = newVal || '';
            this.currentPage = 1;
            this.fetchOrders();
            this.fetchStoreAnalytics();
        }
    },
    methods: {
        /**
         * Get current preorder week
         * Week runs from Saturday 1:00 AM to Thursday 11:59:59 PM
         */
        getCurrentPreorderWeek() {
            const now = moment();
            let weekStart;

            // If it's Saturday and before 1 AM, use last Saturday at 1 AM
            if (now.day() === 6 && now.hour() < 1) {
                weekStart = moment().day(-1).hour(1).minute(0).second(0); // Last Saturday 1 AM
            }
            // If it's before Saturday or Saturday after 1 AM, find the most recent Saturday at 1 AM
            else if (now.day() < 6) {
                weekStart = moment().day(-1).hour(1).minute(0).second(0); // Last Saturday 1 AM
            } else {
                // It's Saturday after 1 AM or Sunday onwards
                weekStart = moment().day(6).hour(1).minute(0).second(0); // This Saturday 1 AM
            }

            // End at Thursday 11:59:59 PM - 5 days from Saturday
            const weekEnd = weekStart.clone().add(5, 'days').hour(23).minute(59).second(59);

            return { start: weekStart, end: weekEnd };
        },

        /**
         * Get last preorder week
         */
        getLastPreorderWeek() {
            const currentWeek = this.getCurrentPreorderWeek();
            const lastWeekStart = currentWeek.start.clone().subtract(7, 'days');
            const lastWeekEnd = lastWeekStart.clone().add(5, 'days').hour(23).minute(59).second(59);

            return { start: lastWeekStart, end: lastWeekEnd };
        },

        /**
         * Get custom date ranges including preorder weeks
         */
        getCustomRanges() {
            const currentWeek = this.getCurrentPreorderWeek();
            const lastWeek = this.getLastPreorderWeek();

            return {
                'Current Week (Preorder)': [currentWeek.start.toDate(), currentWeek.end.toDate()],
                'Last Week (Preorder)': [lastWeek.start.toDate(), lastWeek.end.toDate()],
                'Today': [moment().toDate(), moment().toDate()],
                'Yesterday': [moment().subtract(1, 'days').toDate(), moment().subtract(1, 'days').toDate()],
                'This Week': [moment().startOf('week').toDate(), moment().endOf('week').toDate()],
                'Last Week': [moment().subtract(1, 'week').startOf('week').toDate(), moment().subtract(1, 'week').endOf('week').toDate()],
                'This Month': [moment().startOf('month').toDate(), moment().endOf('month').toDate()],
                'Last Month': [moment().subtract(1, 'month').startOf('month').toDate(), moment().subtract(1, 'month').endOf('month').toDate()],
            };
        },

        async fetchCities() {
            try {
                const response = await axios.get(this.$apiUrl + '/cities');
                this.cities = response.data.data || response.data;
            } catch (e) {
                // silently fail
            }
        },

        async fetchStats() {
            const data = await this.fetchPreOrderStats();
            if (data) {
                this.stats = data;
            }
        },

        async fetchOrders() {
            this.isLoading = true;

            const params = {
                page: this.currentPage,
                per_page: this.perPage,
                search: this.search,
                status: this.status,
                store_id: this.store_id,
                city_id: this.city_id,
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
                status: this.status,
                city_id: this.city_id
            };

            const data = await this.fetchStoreWiseAnalytics(params);
            this.storeWiseData = data;
            this.loadingAnalytics = false;
        },

        handleFilterChange() {
            this.currentPage = 1;
            this.fetchOrders();
            this.fetchStats();
            this.fetchStoreAnalytics();
        },

        handlePageChange(page) {
            this.currentPage = page;
            this.fetchOrders();
        },

        handleStatusFilter(status) {
            this.status = status;
            this.handleFilterChange();
        },

        clearDate() {
            this.dateRange = {
                startDate: null,
                endDate: null
            };
            this.handleFilterChange();
        },

        previousWeek() {
            const currentStart = moment(this.dateRange.startDate);
            const previousStart = currentStart.subtract(7, 'days');
            const previousEnd = previousStart.clone().add(5, 'days').hour(23).minute(59).second(59);

            this.dateRange = {
                startDate: previousStart.toDate(),
                endDate: previousEnd.toDate()
            };
            this.handleFilterChange();
        },

        nextWeek() {
            const currentStart = moment(this.dateRange.startDate);
            const nextStart = currentStart.add(7, 'days');
            const nextEnd = nextStart.clone().add(5, 'days').hour(23).minute(59).second(59);

            this.dateRange = {
                startDate: nextStart.toDate(),
                endDate: nextEnd.toDate()
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
                    const { orders, date, totalAmount, totalOrders } = response.data.data;
                    const printContent = this.generateBulkPrintContent(orders, date, totalAmount, totalOrders);

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

        generateBulkPrintContent(orders, date, totalAmount, totalOrders) {
            const statusMap = {
                12: 'Preorder Pending', 2: 'Processed', 3: 'In Progress',
                5: 'Out For Delivery', 6: 'Delivered'
            };

            let rows = '';
            orders.forEach(order => {
                const status = statusMap[order.active_status] || `Status ${order.active_status}`;
                const statusClass = order.active_status == 12 ? 'status-pending' : 'status-processed';
                rows += `
                    <tr>
                        <td><strong>#${order.id}</strong></td>
                        <td>${order.user_name || 'Guest'}</td>
                        <td>${order.mobile}</td>
                        <td class="text-right"><strong>₹${parseFloat(order.final_total).toFixed(2)}</strong></td>
                        <td>${order.payment_method}</td>
                        <td>${order.preorder_placed_at_formatted || 'N/A'}</td>
                        <td>${order.preorder_process_date_formatted || 'N/A'}</td>
                        <td class="text-center"><span class="status-badge ${statusClass}">${status}</span></td>
                    </tr>
                `;
            });

            return `
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Pre Orders - ${date}</title>
                    <style>
                        @page { size: A4 landscape; margin: 1cm; }
                        * { margin: 0; padding: 0; box-sizing: border-box; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; color-adjust: exact !important; }
                        body { font-family: Arial, sans-serif; font-size: 10px; color: #333; padding: 20px; }
                        .header { text-align: center; margin-bottom: 20px; padding-bottom: 10px; border-bottom: 2px solid #333; }
                        .header h1 { font-size: 24px; color: #2c3e50; margin-bottom: 5px; }
                        .header p { font-size: 12px; color: #7f8c8d; }
                        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
                        thead { background-color: #34495e !important; color: white !important; }
                        th { padding: 8px 5px; text-align: left; font-size: 9px; font-weight: bold; background-color: #34495e !important; color: white !important; }
                        td { padding: 6px 5px; border-bottom: 1px solid #ddd; font-size: 9px; }
                        tbody tr:nth-child(even) { background-color: #f8f9fa !important; }
                        .text-right { text-align: right; }
                        .text-center { text-align: center; }
                        .status-badge { padding: 3px 6px; border-radius: 3px; font-size: 8px; font-weight: bold; }
                        .status-pending { background-color: #fff3cd !important; color: #856404 !important; border: 1px solid #856404; }
                        .status-processed { background-color: #d4edda !important; color: #155724 !important; border: 1px solid #155724; }
                        .summary { margin-top: 20px; padding: 15px; background-color: #ecf0f1 !important; border-radius: 5px; }
                        .summary-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 11px; }
                        .footer { margin-top: 20px; text-align: center; font-size: 9px; color: #7f8c8d; padding-top: 10px; border-top: 1px solid #ddd; }
                    </style>
                </head>
                <body>
                    <div class="header">
                        <h1>ZENFOO - PRE ORDERS</h1>
                        <p>Generated on ${date}</p>
                    </div>
                    <table>
                        <thead>
                            <tr><th>Order ID</th><th>Customer</th><th>Mobile</th><th class="text-right">Amount</th><th>Payment</th><th>Placed At</th><th>Process Date</th><th class="text-center">Status</th></tr>
                        </thead>
                        <tbody>${rows}</tbody>
                    </table>
                    <div class="summary">
                        <div class="summary-row"><span>Total Orders:</span><strong>${totalOrders}</strong></div>
                        <div class="summary-row"><span>Total Amount:</span><strong>₹${parseFloat(totalAmount).toFixed(2)}</strong></div>
                        <div class="summary-row"><span>Average Order Value:</span><strong>₹${totalOrders > 0 ? (totalAmount / totalOrders).toFixed(2) : '0.00'}</strong></div>
                    </div>
                    <div class="footer">
                        <p>This is a computer-generated document. No signature is required.</p>
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
                link.setAttribute('download', `preorders-${moment().format('YYYY-MM-DD')}.xlsx`);
                document.body.appendChild(link);
                link.click();
                link.remove();

                this.$toast.success('Excel downloaded successfully');
            } catch (error) {
                console.error('Excel download error:', error);
                this.$toast.error('Failed to download Excel');
            }
        },

        async bulkPrintAllOrders() {
            if (this.orders.length === 0) {
                this.$toast.warning('No orders to print');
                return;
            }

            this.$toast.info(`Preparing to print ${this.orders.length} orders...`);

            for (let i = 0; i < this.orders.length; i++) {
                await this.printThermalInvoice(this.orders[i].id);
                await new Promise(resolve => setTimeout(resolve, 1000));
            }

            this.$toast.success('All orders sent to printer');
        },

        async bulkPrintByStore(storeId, storeName) {
            this.$toast.info(`Fetching orders for ${storeName}...`);

            try {
                const params = {
                    store_id: storeId,
                    per_page: 1000,
                    search: this.search,
                    status: this.status,
                    startDate: (this.dateRange.startDate && moment(this.dateRange.startDate).isValid())
                        ? moment(this.dateRange.startDate).format('YYYY-MM-DD') : '',
                    endDate: (this.dateRange.endDate && moment(this.dateRange.endDate).isValid())
                        ? moment(this.dateRange.endDate).format('YYYY-MM-DD') : ''
                };

                const response = await axios.get(this.$apiUrl + '/preorders', { params });

                if (response.data.status === 1 && response.data.data.orders.length > 0) {
                    const storeOrders = response.data.data.orders;
                    this.$toast.info(`Printing ${storeOrders.length} orders from ${storeName}...`);

                    for (let i = 0; i < storeOrders.length; i++) {
                        await this.printThermalInvoice(storeOrders[i].id);
                        await new Promise(resolve => setTimeout(resolve, 1000));
                    }

                    this.$toast.success(`All orders from ${storeName} sent to printer`);
                } else {
                    this.$toast.warning(`No orders found for ${storeName}`);
                }
            } catch (error) {
                console.error('Bulk print error:', error);
                this.$toast.error('Failed to print store orders');
            }
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
.gap-3 {
    gap: 1rem;
}
.week-range-display {
    min-width: 300px;
    text-align: center;
    padding: 0.5rem 1rem;
    background-color: #f8f9fa;
    border-radius: 0.375rem;
}
.week-range-display h5 {
    font-weight: 600;
    color: #2c3e50;
}
.city-zone-bar {
    display: flex;
    align-items: center;
}
.city-zone-select {
    max-width: 220px;
}
</style>