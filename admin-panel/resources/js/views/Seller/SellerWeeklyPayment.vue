<template>
    <div>
        <!-- Week Navigation -->
        <div class="d-flex justify-content-center align-items-center mb-4">
            <button class="btn btn-outline-secondary" @click="previousWeek">
                <i class="fa fa-chevron-left"></i>
            </button>
            <div class="mx-4 text-center">
                <h5 class="mb-0">{{ weekStartFormatted }} - {{ weekEndFormatted }}</h5>
                <small class="text-muted">{{ weekLabel }}</small>
            </div>
            <button class="btn btn-outline-secondary" @click="nextWeek" :disabled="isCurrentWeek">
                <i class="fa fa-chevron-right"></i>
            </button>
        </div>

        <!-- Loading Spinner -->
        <div v-if="loading" class="text-center py-5">
            <b-spinner variant="primary" label="Loading..."></b-spinner>
        </div>

        <template v-else>
            <!-- Weekly Summary Cards -->
            <b-row class="justify-content-center mb-4">
                <b-col md="3">
                    <b-card class="text-center bg-primary text-white">
                        <h6>Orders Count</h6>
                        <h3>{{ weekData.orders_count }}</h3>
                    </b-card>
                </b-col>
                <b-col md="3">
                    <b-card class="text-center bg-success text-white">
                        <h6>Paid Amount</h6>
                        <h3>{{ currencySymbol }}{{ weekData.paid_amount.toFixed(2) }}</h3>
                    </b-card>
                </b-col>
                <b-col md="3">
                    <b-card class="text-center bg-warning text-dark">
                        <h6>Need to Pay</h6>
                        <h3>{{ currencySymbol }}{{ weekData.need_to_pay.toFixed(2) }}</h3>
                    </b-card>
                </b-col>
            </b-row>

            <!-- Pay Button -->
            <div class="text-center mb-4" v-if="weekData.need_to_pay > 0">
                <button class="btn btn-success btn-lg" @click="openPayModal">
                    <i class="fa fa-money me-2"></i> Pay {{ currencySymbol }}{{ weekData.need_to_pay.toFixed(2) }} to Seller
                </button>
            </div>

            <!-- Transactions Table -->
            <b-table
                :items="transactions"
                :fields="fields"
                striped
                hover
                responsive
                show-empty
                empty-text="No transactions found for this week"
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
                    <span class="badge" :class="data.item.is_paid_to_seller == 1 ? 'bg-success' : 'bg-warning'">
                        {{ data.item.is_paid_to_seller == 1 ? 'Paid' : 'Pending' }}
                    </span>
                </template>

                <template #cell(created_at)="data">
                    {{ formatDate(data.item.created_at) }}
                </template>
            </b-table>

            <!-- Pagination -->
            <b-row v-if="totalRows > 0">
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
        </template>

        <!-- Product Details Modal -->
        <b-modal v-model="showProductModal" title="Order Items Details" size="lg" centered hide-footer>
            <div v-if="selectedProduct">
                <div class="mb-3">
                    <strong>Order ID:</strong>
                    <router-link :to="'/orders/view/' + selectedProduct.order_id" v-if="selectedProduct.order_id">
                        #{{ selectedProduct.order_id }}
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
                            <tr v-for="(product, index) in selectedProduct.products_json" :key="index">
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
                                <td class="text-end">{{ currencySymbol }}{{ calculateProductTotal('total_amount').toFixed(2) }}</td>
                                <td class="text-end text-danger">-{{ currencySymbol }}{{ calculateProductTotal('commission').toFixed(2) }}</td>
                                <td class="text-end text-danger">-{{ currencySymbol }}{{ calculateProductTotal('gst').toFixed(2) }}</td>
                                <td class="text-end text-success">{{ currencySymbol }}{{ calculateProductTotal('seller_amount').toFixed(2) }}</td>
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
                                <td class="text-end text-success">{{ netPayout.toFixed(2) }}</td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>
        </b-modal>

        <!-- Pay Modal -->
        <b-modal v-model="showPayModal" size="lg" centered :hide-header-close="isProcessingPayout">
            <template #modal-title>
                Pay Weekly Settlement ({{ weekStartFormatted }} - {{ weekEndFormatted }})
            </template>

            <!-- Bank Details Section -->
            <div class="mb-4" v-if="bankDetails">
                <h6 class="mb-3"><i class="fa fa-bank me-2"></i>Bank Account Details</h6>
                <div class="row">
                    <div class="col-md-6">
                        <ul class="list-unstyled">
                            <li><b>Bank Name:</b> {{ bankDetails.bank_name }}</li>
                            <li><b>Account Number:</b> {{ bankDetails.account_number_masked }}</li>
                        </ul>
                    </div>
                    <div class="col-md-6">
                        <ul class="list-unstyled">
                            <li><b>Account Holder:</b> {{ bankDetails.account_holder_name }}</li>
                            <li><b>IFSC Code:</b> {{ bankDetails.ifsc_code }}</li>
                        </ul>
                    </div>
                </div>
                <hr>
            </div>

            <!-- Bank Details Loading -->
            <div class="text-center py-3 mb-3" v-else-if="isLoadingBankDetails">
                <b-spinner small class="me-2"></b-spinner>
                <span>Loading bank details...</span>
            </div>

            <!-- Bank Details Error -->
            <div class="alert alert-danger mb-3" v-else-if="bankDetailsError">
                <i class="fa fa-exclamation-triangle me-2"></i>
                {{ bankDetailsError }}
            </div>

            <!-- Unpaid Transactions Summary -->
            <div class="table-responsive" v-if="unpaidTransactions.length > 0">
                <h6 class="mb-3">Unpaid Transactions for this Week</h6>
                <table class="table table-bordered table-sm">
                    <thead>
                        <tr>
                            <th class="text-center">Order ID</th>
                            <th class="text-center">Item</th>
                            <th class="text-center">Amount to Settle</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="item in unpaidTransactions" :key="item.id">
                            <td class="text-center">#{{ item.order_id || '-' }}</td>
                            <td class="text-center">{{ item.item_name || '-' }}</td>
                            <td class="text-center text-success fw-bold">{{ currencySymbol }}{{ parseFloat(item.amount || 0).toFixed(2) }}</td>
                        </tr>
                    </tbody>
                    <tfoot>
                        <tr class="table-warning">
                            <th colspan="2" class="text-center">Total</th>
                            <th class="text-center text-success fw-bold">{{ currencySymbol }}{{ weekData.need_to_pay.toFixed(2) }}</th>
                        </tr>
                    </tfoot>
                </table>
            </div>

            <!-- Payout Success Message -->
            <div class="alert alert-success mt-3" v-if="payoutSuccess">
                <i class="fa fa-check-circle me-2"></i>
                {{ payoutSuccess }}
            </div>

            <!-- Payout Error Message -->
            <div class="alert alert-danger mt-3" v-if="payoutError">
                <i class="fa fa-exclamation-circle me-2"></i>
                {{ payoutError }}
            </div>

            <template #modal-footer>
                <button class="btn btn-secondary" @click="closePayModal" :disabled="isProcessingPayout">
                    {{ payoutSuccess ? 'Close' : 'Cancel' }}
                </button>
                <button
                    v-if="!payoutSuccess"
                    class="btn btn-success"
                    :disabled="!bankDetails || isProcessingPayout || bankDetailsError || unpaidTransactions.length === 0"
                    @click="processSettlement">
                    <b-spinner small class="me-1" v-if="isProcessingPayout"></b-spinner>
                    <i class="fa fa-money me-1" v-else></i>
                    {{ isProcessingPayout ? 'Processing...' : 'Pay ' + currencySymbol + weekData.need_to_pay.toFixed(2) }}
                </button>
            </template>
        </b-modal>
    </div>
</template>

<script>
import axios from 'axios';

export default {
    name: 'SellerWeeklyPayment',
    props: {
        sellerId: {
            type: [Number, String],
            required: true
        }
    },
    data() {
        return {
            currencySymbol: window.currencySymbol || 'Rs.',
            loading: false,
            currentWeekOffset: 0,
            weekData: {
                orders_count: 0,
                paid_amount: 0,
                need_to_pay: 0
            },
            weekStart: null,
            weekEnd: null,
            transactions: [],
            unpaidTransactions: [],
            currentPage: 1,
            perPage: 15,
            totalRows: 0,
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
                { key: 'created_at', label: 'Date', sortable: true }
            ],
            // Pay Modal
            showPayModal: false,
            bankDetails: null,
            isLoadingBankDetails: false,
            bankDetailsError: null,
            isProcessingPayout: false,
            payoutSuccess: null,
            payoutError: null,
            // Product Details Modal
            showProductModal: false,
            selectedProduct: null
        };
    },
    computed: {
        weekStartFormatted() {
            if (!this.weekStart) return '';
            return this.formatDisplayDate(new Date(this.weekStart));
        },
        weekEndFormatted() {
            if (!this.weekEnd) return '';
            return this.formatDisplayDate(new Date(this.weekEnd));
        },
        weekLabel() {
            if (this.currentWeekOffset === 0) return 'Current Week';
            if (this.currentWeekOffset === -1) return 'Previous Week';
            return `${Math.abs(this.currentWeekOffset)} weeks ago`;
        },
        isCurrentWeek() {
            return this.currentWeekOffset === 0;
        },
        netPayout() {
            if (!this.selectedTransaction) return 0;
            const gross = this.calculateProductTotal('seller_amount');
            const wait = parseFloat(this.selectedTransaction.vendor_wait_charge || 0);
            const gateway = parseFloat(this.selectedTransaction.payment_gateway_fees || 0);
            return gross - wait - gateway;
        }
    },
    mounted() {
        this.fetchWeeklyData();
    },
    methods: {
        formatDisplayDate(date) {
            const options = { month: 'short', day: 'numeric', year: 'numeric' };
            return date.toLocaleDateString('en-US', options);
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
        previousWeek() {
            this.currentWeekOffset--;
            this.currentPage = 1;
            this.fetchWeeklyData();
        },
        nextWeek() {
            if (!this.isCurrentWeek) {
                this.currentWeekOffset++;
                this.currentPage = 1;
                this.fetchWeeklyData();
            }
        },
        onPageChange(page) {
            this.currentPage = page;
            this.fetchWeeklyData();
        },
        async fetchWeeklyData() {
            this.loading = true;
            try {
                const baseUrl = window.baseUrl || '';
                const response = await axios.get(`${baseUrl}/api/seller/${this.sellerId}/transactions/weekly`, {
                    params: {
                        week_offset: this.currentWeekOffset,
                        page: this.currentPage,
                        per_page: this.perPage
                    }
                });

                if (response.data.success) {
                    this.weekData = {
                        orders_count: response.data.data.orders_count,
                        paid_amount: response.data.data.paid_amount,
                        need_to_pay: response.data.data.need_to_pay
                    };
                    this.weekStart = response.data.data.week_start;
                    this.weekEnd = response.data.data.week_end;

                    // Transactions data
                    this.transactions = response.data.transactions.data;
                    this.totalRows = response.data.transactions.total;
                    this.currentPage = response.data.transactions.current_page;

                    // Filter unpaid transactions for the modal
                    this.unpaidTransactions = response.data.unpaid_transactions || [];
                }
            } catch (error) {
                console.error('Error fetching weekly data:', error);
                this.$bvToast.toast('Failed to fetch weekly payment data', {
                    title: 'Error',
                    variant: 'danger',
                    solid: true
                });
            } finally {
                this.loading = false;
            }
        },
        openPayModal() {
            this.showPayModal = true;
            this.payoutSuccess = null;
            this.payoutError = null;
            this.loadBankDetails();
        },
        closePayModal() {
            if (this.payoutSuccess) {
                this.fetchWeeklyData();
            }
            this.showPayModal = false;
            this.bankDetails = null;
            this.bankDetailsError = null;
            this.payoutSuccess = null;
            this.payoutError = null;
        },
        async loadBankDetails() {
            this.isLoadingBankDetails = true;
            this.bankDetails = null;
            this.bankDetailsError = null;

            try {
                const baseUrl = window.baseUrl || '';
                const response = await axios.get(`${baseUrl}/api/seller/${this.sellerId}/bank-details`);

                if (response.data.success) {
                    this.bankDetails = response.data.data;
                } else {
                    this.bankDetailsError = response.data.message || 'Failed to load bank details';
                }
            } catch (error) {
                this.bankDetailsError = error.response?.data?.message || 'Failed to load bank details. Please ensure seller has added bank account.';
            } finally {
                this.isLoadingBankDetails = false;
            }
        },
        async processSettlement() {
            this.isProcessingPayout = true;
            this.payoutError = null;
            this.payoutSuccess = null;

            try {
                const transactionIds = this.unpaidTransactions.map(t => t.id);
                const totalAmount = this.weekData.need_to_pay;
                const baseUrl = window.baseUrl || '';

                const response = await axios.post(`${baseUrl}/api/seller/${this.sellerId}/settle-payouts`, {
                    transaction_ids: transactionIds,
                    total_amount: totalAmount
                });

                if (response.data.success) {
                    this.payoutSuccess = 'Payout initiated successfully! Transaction ID: ' +
                        (response.data.data.payout_transaction_id || 'N/A');
                } else {
                    this.payoutError = response.data.message || 'Failed to process payout';
                }
            } catch (error) {
                this.payoutError = error.response?.data?.message || 'Failed to process payout. Please try again.';
            } finally {
                this.isProcessingPayout = false;
            }
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
            this.selectedProduct = transaction;
            this.showProductModal = true;
        },
        calculateProductTotal(field) {
            if (!this.selectedProduct || !this.selectedProduct.products_json) return 0;
            return this.selectedProduct.products_json.reduce((sum, product) => {
                return sum + parseFloat(product[field] || 0);
            }, 0);
        }
    },
    watch: {
        sellerId: {
            handler() {
                this.currentWeekOffset = 0;
                this.currentPage = 1;
                this.fetchWeeklyData();
            },
            immediate: false
        }
    }
};
</script>

<style scoped>
.btn-outline-secondary {
    border-radius: 50%;
    width: 40px;
    height: 40px;
    padding: 0;
}

:deep(.badge) {
    font-weight: 600;
    padding: 0.35em 0.65em;
    font-size: 0.85em;
}
:deep(.bg-success) {
    background-color: #28a745 !important;
    color: #fff !important;
}
:deep(.bg-warning) {
    background-color: #ffc107 !important;
    color: #212529 !important;
}
:deep(.bg-info) {
    background-color: #17a2b8 !important;
    color: #fff !important;
}
:deep(.bg-danger) {
    background-color: #dc3545 !important;
    color: #fff !important;
}
:deep(.bg-secondary) {
    background-color: #6c757d !important;
    color: #fff !important;
}
</style>
