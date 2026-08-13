<template>
    <div>
        <!-- Filters -->
        <div class="row mb-3">
            <b-col md="3">
                <h6 class="box-title">From Date</h6>
                <input type="date" v-model="filters.from_date" @change="fetchTransactions" class="form-control">
            </b-col>
            <b-col md="3">
                <h6 class="box-title">To Date</h6>
                <input type="date" v-model="filters.to_date" @change="fetchTransactions" class="form-control">
            </b-col>
            <!-- <b-col md="3">
                <h6 class="box-title">Type</h6>
                <select v-model="filters.type" @change="fetchTransactions" class="form-control form-select">
                    <option value="">All</option>
                    <option value="order_commission">Order Earning</option>
                    <option value="withdrawal">Withdrawal</option>
                    <option value="credit">Credit</option>
                    <option value="debit">Debit</option>
                    <option value="refund">Refund</option>
                </select>
            </b-col> -->
            <b-col md="3">
                <h6 class="box-title">Payment Status</h6>
                <select v-model="filters.payment_status" @change="fetchTransactions" class="form-control form-select">
                    <option value="">All</option>
                    <option value="paid">Paid</option>
                    <option value="unpaid">Unpaid</option>
                </select>
            </b-col>
            <b-col md="1" class="text-center">
                <button class="btn btn-primary btn_refresh" v-b-tooltip.hover title="Refresh" @click="fetchTransactions()">
                    <i class="fa fa-refresh" aria-hidden="true"></i>
                </button>
            </b-col>
        </div>

        <!-- Summary Cards -->
        <b-row class="mb-4">
            <b-col md="3">
                <b-card class="text-center bg-success text-white">
                    <h6>Total Earnings</h6>
                    <h4>{{ currencySymbol }}{{ summary.total_earnings.toFixed(2) }}</h4>
                </b-card>
            </b-col>
            <b-col md="3">
                <b-card class="text-center bg-info text-white">
                    <h6>Paid Amount</h6>
                    <h4>{{ currencySymbol }}{{ summary.paid_amount.toFixed(2) }}</h4>
                </b-card>
            </b-col>
            <b-col md="3">
                <b-card class="text-center bg-warning text-white">
                    <h6>Pending Amount</h6>
                    <h4>{{ currencySymbol }}{{ summary.pending_amount.toFixed(2) }}</h4>
                </b-card>
            </b-col>
            <b-col md="3">
                <b-card class="text-center bg-secondary text-white">
                    <h6>Total Commission</h6>
                    <h4>{{ currencySymbol }}{{ summary.total_commission.toFixed(2) }}</h4>
                </b-card>
            </b-col>
        </b-row>

        <!-- Loading Spinner -->
        <div v-if="loading" class="text-center py-5">
            <b-spinner variant="primary" label="Loading..."></b-spinner>
        </div>

        <!-- Transactions Table -->
        <b-table
            v-else
            :items="transactions"
            :fields="fields"
            striped
            hover
            responsive
            show-empty
            empty-text="No transactions found"
        >
            <template #cell(order_id)="data">
                <router-link :to="'/orders/view/' + data.item.order_id" v-if="data.item.order_id">
                    #{{ data.item.order_id }}
                </router-link>
                <span v-else>-</span>
            </template>

            <template #cell(item_name)="data">
                <div class="d-flex align-items-center gap-2">
                    <span>{{ data.item.item_name || '-' }}</span>
                    <button
                        v-if="data.item.products_json && data.item.products_json.length > 0"
                        class="btn btn-sm btn-outline-primary"
                        @click="viewProductDetails(data.item)"
                        v-b-tooltip.hover
                        title="View all items">
                        <i class="fa fa-eye"></i>
                    </button>
                </div>
            </template>

            <template #cell(type)="data">
                <span class="badge" :class="'bg-' + getTypeVariant(data.item.type)">
                    {{ formatType(data.item.type) }}
                </span>
            </template>

            <template #cell(amount)="data">
                <span :class="isCreditType(data.item.type) ? 'text-success' : 'text-danger'">
                    {{ isCreditType(data.item.type) ? '+' : '-' }}{{ currencySymbol }}{{ parseFloat(data.item.amount).toFixed(2) }}
                </span>
            </template>

            <template #cell(admin_commission)="data">
                {{ currencySymbol }}{{ parseFloat(data.item.admin_commission || 0).toFixed(2) }}
            </template>

            <template #cell(gst_percentage)="data">
                <span class="badge bg-info">
                    {{ parseFloat(data.item.gst_percentage || 0).toFixed(2) }}%
                </span>
            </template>

            <template #cell(payment_gateway_fees)="data">
                {{ currencySymbol }}{{ parseFloat(data.item.payment_gateway_fees || 0).toFixed(2) }}
            </template>

            <template #cell(is_paid_to_seller)="data">
                <span class="badge" :class="data.item.is_paid_to_seller ? 'bg-success' : 'bg-warning'">
                    {{ data.item.is_paid_to_seller ? 'Paid' : 'Pending' }}
                </span>
            </template>

            <template #cell(paid_at)="data">
                {{ data.item.paid_at ? formatDate(data.item.paid_at) : '-' }}
            </template>

            <template #cell(created_at)="data">
                {{ formatDate(data.item.created_at) }}
            </template>
        </b-table>

        <!-- Pagination -->
        <b-row v-if="!loading && totalRows > 0">
            <b-col md="6">
                <p class="text-muted">Showing {{ (currentPage - 1) * perPage + 1 }} to {{ Math.min(currentPage * perPage, totalRows) }} of {{ totalRows }} entries</p>
            </b-col>
            <b-col md="6">
                <b-pagination
                    v-model="currentPage"
                    :total-rows="totalRows"
                    :per-page="perPage"
                    align="right"
                    @change="onPageChange"
                ></b-pagination>
            </b-col>
        </b-row>

        <!-- Product Details Modal -->
        <b-modal v-model="showProductModal" title="Order Items Details" size="lg" centered hide-footer>
            <div v-if="selectedTransaction">
                <div class="mb-3">
                    <strong>Order ID:</strong>
                    <router-link :to="'/orders/view/' + selectedTransaction.order_id" v-if="selectedTransaction.order_id">
                        #{{ selectedTransaction.order_id }}
                    </router-link>
                    <span v-else>-</span>
                </div>

                <div class="table-responsive">
                    <table class="table table-sm table-bordered">
                        <thead class="table-light">
                            <tr>
                                <th>Product Name</th>
                                <th class="text-center">Qty</th>
                                <th class="text-end">Unit Price</th>
                                <th class="text-end">Total</th>
                                <th class="text-end">Commission</th>
                                <th class="text-end">GST</th>
                                <th class="text-end">You Get</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="(product, index) in selectedTransaction.products_json" :key="index">
                                <td>
                                    {{ product.product_name }}
                                    <small v-if="product.source === 'combo_item'" class="text-muted d-block">
                                        (from {{ product.combo_name }})
                                    </small>
                                </td>
                                <td class="text-center">{{ product.quantity }}</td>
                                <td class="text-end">{{ currencySymbol }}{{ parseFloat(product.amount).toFixed(2) }}</td>
                                <td class="text-end">{{ currencySymbol }}{{ parseFloat(product.total_amount).toFixed(2) }}</td>
                                <td class="text-end text-danger">-{{ currencySymbol }}{{ parseFloat(product.commission).toFixed(2) }}</td>
                                <td class="text-end text-danger">-{{ currencySymbol }}{{ parseFloat(product.gst || 0).toFixed(2) }}</td>
                                <td class="text-end text-success fw-bold">{{ currencySymbol }}{{ parseFloat(product.seller_amount).toFixed(2) }}</td>
                            </tr>
                        </tbody>
                        <tfoot class="table-light fw-bold">
                            <tr>
                                <td colspan="3" class="text-end">Total:</td>
                                <td class="text-end">{{ currencySymbol }}{{ calculateTotal('total_amount').toFixed(2) }}</td>
                                <td class="text-end text-danger">-{{ currencySymbol }}{{ calculateTotal('commission').toFixed(2) }}</td>
                                <td class="text-end text-danger">-{{ currencySymbol }}{{ calculateTotal('gst').toFixed(2) }}</td>
                                <td class="text-end text-success">{{ currencySymbol }}{{ calculateTotal('seller_amount').toFixed(2) }}</td>
                            </tr>
                            <tr v-if="parseFloat(selectedTransaction.vendor_wait_charge || 0) > 0">
                                <td colspan="6" class="text-end fw-normal">
                                    Waiting charge deducted
                                    <small class="text-muted">(paid to driver for vendor delay)</small>
                                </td>
                                <td class="text-end text-danger">-{{ currencySymbol }}{{ parseFloat(selectedTransaction.vendor_wait_charge).toFixed(2) }}</td>
                            </tr>
                            <tr v-if="parseFloat(selectedTransaction.payment_gateway_fees || 0) > 0">
                                <td colspan="6" class="text-end fw-normal">Payment gateway fees</td>
                                <td class="text-end text-danger">-{{ currencySymbol }}{{ parseFloat(selectedTransaction.payment_gateway_fees).toFixed(2) }}</td>
                            </tr>
                            <tr class="table-success">
                                <td colspan="6" class="text-end">Net payout:</td>
                                <td class="text-end text-success">{{ currencySymbol }}{{ netPayout.toFixed(2) }}</td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>
        </b-modal>
    </div>
</template>

<script>
import axios from 'axios';

export default {
    name: 'SellerAllTransactions',
    props: {
        sellerId: {
            type: [Number, String],
            required: true
        }
    },
    data() {
        return {
            loading: false,
            transactions: [],
            currentPage: 1,
            perPage: 15,
            totalRows: 0,
            currencySymbol: window.currencySymbol || 'Rs.',
            filters: {
                from_date: '',
                to_date: '',
                type: '',
                payment_status: ''
            },
            summary: {
                total_earnings: 0,
                paid_amount: 0,
                pending_amount: 0,
                total_commission: 0
            },
            fields: [
                { key: 'id', label: 'ID', sortable: true },
                { key: 'order_id', label: 'Order', sortable: true },
                { key: 'item_name', label: 'Item', sortable: false },
                { key: 'type', label: 'Type', sortable: true },
                { key: 'amount', label: 'Amount', sortable: true },
                { key: 'admin_commission', label: 'Commission', sortable: true },
                { key: 'gst_percentage', label: 'GST %', sortable: true },
                { key: 'payment_gateway_fees', label: 'Gateway Fees', sortable: true },
                { key: 'message', label: 'Description', sortable: false },
                { key: 'is_paid_to_seller', label: 'Status', sortable: true },
                { key: 'paid_at', label: 'Paid On', sortable: true },
                { key: 'created_at', label: 'Date', sortable: true }
            ],
            showProductModal: false,
            selectedTransaction: null
        };
    },
    mounted() {
        this.fetchTransactions();
    },
    computed: {
        netPayout() {
            if (!this.selectedTransaction) return 0;
            const gross = this.calculateTotal('seller_amount');
            const wait = parseFloat(this.selectedTransaction.vendor_wait_charge || 0);
            const gateway = parseFloat(this.selectedTransaction.payment_gateway_fees || 0);
            return gross - wait - gateway;
        }
    },
    methods: {
        async fetchTransactions() {
            this.loading = true;
            try {
                const params = {
                    page: this.currentPage,
                    per_page: this.perPage,
                    ...this.filters
                };

                const baseUrl = window.baseUrl || '';
                const response = await axios.get(`${baseUrl}/api/seller/${this.sellerId}/transactions`, { params });

                if (response.data.success) {
                    this.transactions = response.data.data.data;
                    this.totalRows = response.data.data.total;
                    this.currentPage = response.data.data.current_page;
                    this.summary = response.data.summary;
                }
            } catch (error) {
                console.error('Error fetching transactions:', error);
                this.$bvToast.toast('Failed to fetch transactions', {
                    title: 'Error',
                    variant: 'danger',
                    solid: true
                });
            } finally {
                this.loading = false;
            }
        },
        onPageChange(page) {
            this.currentPage = page;
            this.fetchTransactions();
        },
        formatDate(dateString) {
            if (!dateString) return '-';
            const date = new Date(dateString);
            return date.toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        },
        isCreditType(type) {
            const creditTypes = ['order_commission', 'credit', 'refund', 'order_item'];
            return creditTypes.includes(type);
        },
        getTypeVariant(type) {
            const variants = {
                'order_commission': 'success',
                'credit': 'success',
                'refund': 'info',
                'withdrawal': 'warning',
                'debit': 'danger',
                'order_item': 'success'
            };
            return variants[type] || 'secondary';
        },
        formatType(type) {
            const labels = {
                'order_commission': 'Order Earning',
                'credit': 'Credit',
                'refund': 'Refund',
                'withdrawal': 'Withdrawal',
                'debit': 'Debit',
                'order_item': 'Order Item'
            };
            return labels[type] || type;
        },
        viewProductDetails(transaction) {
            this.selectedTransaction = transaction;
            this.showProductModal = true;
        },
        calculateTotal(field) {
            if (!this.selectedTransaction || !this.selectedTransaction.products_json) return 0;
            return this.selectedTransaction.products_json.reduce((sum, product) => {
                return sum + parseFloat(product[field] || 0);
            }, 0);
        }
    },
    watch: {
        sellerId: {
            handler() {
                this.currentPage = 1;
                this.fetchTransactions();
            },
            immediate: false
        }
    }
};
</script>

<style scoped>
/* Ensure badge text is visible in light mode */
:deep(.badge) {
    font-weight: 600;
    padding: 0.35em 0.65em;
    font-size: 0.85em;
}
:deep(.badge-success), :deep(.bg-success), :deep(.badge.bg-success) {
    background-color: #28a745 !important;
    color: #fff !important;
}
:deep(.badge-warning), :deep(.bg-warning), :deep(.badge.bg-warning) {
    background-color: #ffc107 !important;
    color: #212529 !important;
}
:deep(.badge-info), :deep(.bg-info), :deep(.badge.bg-info) {
    background-color: #17a2b8 !important;
    color: #fff !important;
}
:deep(.badge-danger), :deep(.bg-danger), :deep(.badge.bg-danger) {
    background-color: #dc3545 !important;
    color: #fff !important;
}
:deep(.badge-secondary), :deep(.bg-secondary), :deep(.badge.bg-secondary) {
    background-color: #6c757d !important;
    color: #fff !important;
}
:deep(.badge-primary), :deep(.bg-primary), :deep(.badge.bg-primary) {
    background-color: #007bff !important;
    color: #fff !important;
}
</style>
