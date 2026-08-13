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
                        <h3>{{ $currency }}{{ weekData.paid_amount.toFixed(2) }}</h3>
                    </b-card>
                </b-col>
                <b-col md="3">
                    <b-card class="text-center bg-warning text-dark">
                        <h6>Need to Pay</h6>
                        <h3>{{ $currency }}{{ weekData.need_to_pay.toFixed(2) }}</h3>
                    </b-card>
                </b-col>
            </b-row>

            <!-- Pay Button -->
            <div class="text-center mb-4" v-if="weekData.need_to_pay > 0">
                <button class="btn btn-success btn-lg" @click="openPayModal">
                    <i class="fa fa-money me-2"></i> Pay {{ $currency }}{{ weekData.need_to_pay.toFixed(2) }} to Delivery Boy
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

                <template #cell(type)="data">
                    <span class="badge" :class="'bg-' + getTypeVariant(data.item.type)">
                        {{ formatType(data.item.type) }}
                    </span>
                </template>

                <template #cell(driver_earnings)="data">
                    <span class="text-success fw-bold">
                        {{ $currency }}{{ parseFloat(data.item.driver_earnings || 0).toFixed(2) }}
                    </span>
                </template>

                <template #cell(is_paid_to_delivery_boy)="data">
                    <span class="badge" :class="data.item.settled_with_admin == 1 ? 'bg-success' : 'bg-warning'">
                        {{ data.item.settled_with_admin == 1 ? 'Paid' : 'Pending' }}
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
                            <th class="text-center">Type</th>
                            <th class="text-center">Amount to Settle</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="item in unpaidTransactions" :key="item.id">
                            <td class="text-center">#{{ item.order_id || '-' }}</td>
                            <td class="text-center">{{ formatType(item.type) }}</td>
                            <td class="text-center text-success fw-bold">{{ $currency }}{{ parseFloat(item.driver_earnings || item.amount || 0).toFixed(2) }}</td>
                        </tr>
                    </tbody>
                    <tfoot>
                        <tr class="table-warning">
                            <th colspan="2" class="text-center">Total</th>
                            <th class="text-center text-success fw-bold">{{ $currency }}{{ weekData.need_to_pay.toFixed(2) }}</th>
                        </tr>
                        <tr v-if="showHandCash" class="table-info">
                            <th colspan="2" class="text-center">
                                <i class="fa fa-minus-circle me-1"></i>Hand Cash to Deduct
                                <button
                                    class="btn btn-sm btn-info ms-2"
                                    @click="showHandCashModal = true"
                                    style="padding: 2px 8px; font-size: 0.75rem;">
                                    <i class="fa fa-list"></i>
                                </button>
                            </th>
                            <th class="text-center text-danger fw-bold">- {{ $currency }}{{ selectedHandCashAmount.toFixed(2) }}</th>
                        </tr>
                        <tr v-if="showHandCash" class="table-success">
                            <th colspan="2" class="text-center">Subtotal after Hand Cash</th>
                            <th class="text-center text-success fw-bold">{{ $currency }}{{ (weekData.need_to_pay - selectedHandCashAmount).toFixed(2) }}</th>
                        </tr>
                        <tr v-if="showIncentives" class="table-primary">
                            <th colspan="2" class="text-center">
                                <i class="fa fa-plus-circle me-1"></i>Incentive to Add
                                <button
                                    class="btn btn-sm btn-primary ms-2"
                                    @click="showIncentiveModal = true"
                                    style="padding: 2px 8px; font-size: 0.75rem;">
                                    <i class="fa fa-list"></i>
                                </button>
                            </th>
                            <th class="text-center text-success fw-bold">+ {{ $currency }}{{ selectedIncentiveAmount.toFixed(2) }}</th>
                        </tr>
                        <tr v-if="showHandCash || showIncentives" class="table-success">
                            <th colspan="2" class="text-center">Final Amount to Pay</th>
                            <th class="text-center text-success fw-bold">{{ $currency }}{{ finalAmountToPay.toFixed(2) }}</th>
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
                    {{ isProcessingPayout ? 'Processing...' : 'Pay ' + $currency + finalAmountToPay.toFixed(2) }}
                </button>
            </template>
        </b-modal>

        <!-- Hand Cash Orders Modal -->
        <b-modal v-model="showHandCashModal" size="md" centered title="Select Hand Cash Orders to Deduct">
            <div v-if="handCashPendingOrders.length > 0">
                <p class="text-muted mb-3">Select the hand cash orders you want to deduct from the payout:</p>
                <div class="table-responsive">
                    <table class="table table-sm table-bordered">
                        <thead>
                            <tr>
                                <th style="width: 40px;" class="text-center">
                                    <b-form-checkbox
                                        v-model="selectAllHandCash"
                                        @change="toggleSelectAllHandCash"
                                    ></b-form-checkbox>
                                </th>
                                <th class="text-center">Order ID</th>
                                <th class="text-center">Amount</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="order in handCashPendingOrders" :key="order.id">
                                <td class="text-center">
                                    <b-form-checkbox
                                        v-model="order.selected"
                                        @change="updateSelectedHandCash"
                                    ></b-form-checkbox>
                                </td>
                                <td class="text-center">#{{ order.order_id || '-' }}</td>
                                <td class="text-center">{{ $currency }}{{ parseFloat(order.admin_cash || 0).toFixed(2) }}</td>
                            </tr>
                        </tbody>
                        <tfoot>
                            <tr class="table-info">
                                <th colspan="2" class="text-center">Selected Total</th>
                                <th class="text-center">{{ $currency }}{{ selectedHandCashAmount.toFixed(2) }}</th>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>
            <div v-else>
                <p class="text-muted">No hand cash orders available.</p>
            </div>

            <template #modal-footer>
                <button class="btn btn-secondary" @click="showHandCashModal = false">
                    Close
                </button>
                <button class="btn btn-primary" @click="showHandCashModal = false">
                    <i class="fa fa-check me-1"></i>
                    Apply Selection
                </button>
            </template>
        </b-modal>

        <!-- Incentive Selection Modal -->
        <b-modal v-model="showIncentiveModal" size="md" centered title="Select Incentives to Include">
            <div v-if="incentivePendingTransactions.length > 0">
                <p class="text-muted mb-3">Select the incentives you want to include in the payout:</p>
                <div class="table-responsive">
                    <table class="table table-sm table-bordered">
                        <thead>
                            <tr>
                                <th style="width: 40px;" class="text-center">
                                    <b-form-checkbox
                                        v-model="selectAllIncentives"
                                        @change="toggleSelectAllIncentives"
                                    ></b-form-checkbox>
                                </th>
                                <th class="text-center">Description</th>
                                <th class="text-center">Amount</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="item in incentivePendingTransactions" :key="item.id">
                                <td class="text-center">
                                    <b-form-checkbox
                                        v-model="item.selected"
                                        @change="updateSelectedIncentives"
                                    ></b-form-checkbox>
                                </td>
                                <td class="text-center">{{ item.message || 'Incentive' }}</td>
                                <td class="text-center">{{ $currency }}{{ parseFloat(item.amount || 0).toFixed(2) }}</td>
                            </tr>
                        </tbody>
                        <tfoot>
                            <tr class="table-primary">
                                <th colspan="2" class="text-center">Selected Total</th>
                                <th class="text-center">{{ $currency }}{{ selectedIncentiveAmount.toFixed(2) }}</th>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>
            <div v-else>
                <p class="text-muted">No pending incentives available.</p>
            </div>

            <template #modal-footer>
                <button class="btn btn-secondary" @click="showIncentiveModal = false">
                    Close
                </button>
                <button class="btn btn-primary" @click="showIncentiveModal = false">
                    <i class="fa fa-check me-1"></i>
                    Apply Selection
                </button>
            </template>
        </b-modal>
    </div>
</template>

<script>
import axios from 'axios';

export default {
    name: 'DeliveryBoyWeeklyPayment',
    props: {
        deliveryBoyId: {
            type: [Number, String],
            required: true
        }
    },
    data() {
        return {
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
                { key: 'type', label: 'Type', sortable: true },
                { key: 'driver_earnings', label: 'Amount', sortable: true },
                { key: 'message', label: 'Description', sortable: false },
                { key: 'is_paid_to_delivery_boy', label: 'Status', sortable: true },
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
            // Hand Cash Data
            handCashPendingAmount: 0,
            handCashPendingOrders: [],
            showHandCashModal: false,
            selectAllHandCash: false,
            selectedHandCashOrders: [],
            // Incentive Data
            incentivePendingTransactions: [],
            incentivePendingAmount: 0,
            selectedIncentiveTransactions: [],
            selectAllIncentives: false,
            showIncentiveModal: false
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
        showHandCash() {
            // Only show hand cash if it's less than the total amount
            return this.handCashPendingAmount > 0 && this.handCashPendingAmount < this.weekData.need_to_pay;
        },
        selectedHandCashAmount() {
            return this.selectedHandCashOrders.reduce((total, order) => {
                return total + parseFloat(order.admin_cash || 0);
            }, 0);
        },
        showIncentives() {
            return this.incentivePendingTransactions.length > 0;
        },
        selectedIncentiveAmount() {
            return this.selectedIncentiveTransactions.reduce((total, item) => {
                return total + parseFloat(item.amount || 0);
            }, 0);
        },
        finalAmountToPay() {
            let amount = this.weekData.need_to_pay;
            // Add selected incentives
            amount += this.selectedIncentiveAmount;
            // Deduct hand cash if applicable
            if (this.showHandCash) {
                amount -= this.selectedHandCashAmount;
            }
            return Math.max(0, amount);
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
                const response = await axios.get(`${baseUrl}/api/delivery_boys/${this.deliveryBoyId}/transactions/weekly`, {
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
            this.loadHandCash();
            this.loadIncentives();
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
                const response = await axios.get(`${baseUrl}/api/delivery_boys/${this.deliveryBoyId}/bank-details`);

                if (response.data.success || response.data.status === 1) {
                    this.bankDetails = response.data.data;
                } else {
                    this.bankDetailsError = response.data.message || 'Failed to load bank details';
                }
            } catch (error) {
                this.bankDetailsError = error.response?.data?.message || 'Failed to load bank details. Please ensure delivery boy has added bank account.';
            } finally {
                this.isLoadingBankDetails = false;
            }
        },
        async loadHandCash() {
            try {
                const baseUrl = window.baseUrl || '';
                const response = await axios.get(`${baseUrl}/api/delivery_boys/${this.deliveryBoyId}/hand-cash`);

                if (response.data.status === 1) {
                    const handCashTransactions = response.data.data || [];
                    // Calculate pending amount and filter pending orders
                    this.handCashPendingOrders = handCashTransactions
                        .filter(t => !t.settled_with_admin)
                        .map(t => ({
                            ...t,
                            selected: true // Select all by default
                        }));
                    this.handCashPendingAmount = this.handCashPendingOrders.reduce((total, t) => {
                        return total + parseFloat(t.admin_cash || 0);
                    }, 0);
                    // Initialize selected orders (all selected by default)
                    this.selectedHandCashOrders = [...this.handCashPendingOrders];
                    this.selectAllHandCash = true;
                } else {
                    this.handCashPendingOrders = [];
                    this.handCashPendingAmount = 0;
                    this.selectedHandCashOrders = [];
                }
            } catch (error) {
                console.error('Error loading hand cash:', error);
                this.handCashPendingOrders = [];
                this.handCashPendingAmount = 0;
                this.selectedHandCashOrders = [];
            }
        },
        async loadIncentives() {
            try {
                const baseUrl = window.baseUrl || '';
                const response = await axios.get(`${baseUrl}/api/delivery_boys/${this.deliveryBoyId}/pending-incentives`);

                if (response.data.status === 1) {
                    const incentiveTransactions = response.data.data.transactions || [];
                    // Add selected property and select all by default
                    this.incentivePendingTransactions = incentiveTransactions.map(t => ({
                        ...t,
                        selected: true
                    }));
                    this.incentivePendingAmount = response.data.data.total_amount || 0;
                    // Initialize selected transactions (all selected by default)
                    this.selectedIncentiveTransactions = [...this.incentivePendingTransactions];
                    this.selectAllIncentives = true;
                } else {
                    this.incentivePendingTransactions = [];
                    this.incentivePendingAmount = 0;
                    this.selectedIncentiveTransactions = [];
                }
            } catch (error) {
                console.error('Error loading incentives:', error);
                this.incentivePendingTransactions = [];
                this.incentivePendingAmount = 0;
                this.selectedIncentiveTransactions = [];
            }
        },
        toggleSelectAllIncentives() {
            if (this.selectAllIncentives) {
                this.incentivePendingTransactions.forEach(item => {
                    item.selected = true;
                });
                this.selectedIncentiveTransactions = [...this.incentivePendingTransactions];
            } else {
                this.incentivePendingTransactions.forEach(item => {
                    item.selected = false;
                });
                this.selectedIncentiveTransactions = [];
            }
        },
        updateSelectedIncentives() {
            this.selectedIncentiveTransactions = this.incentivePendingTransactions.filter(item => item.selected);
            this.selectAllIncentives = this.selectedIncentiveTransactions.length === this.incentivePendingTransactions.length;
        },
        toggleSelectAllHandCash() {
            if (this.selectAllHandCash) {
                // Select all orders
                this.handCashPendingOrders.forEach(order => {
                    order.selected = true;
                });
                this.selectedHandCashOrders = [...this.handCashPendingOrders];
            } else {
                // Deselect all orders
                this.handCashPendingOrders.forEach(order => {
                    order.selected = false;
                });
                this.selectedHandCashOrders = [];
            }
        },
        updateSelectedHandCash() {
            // Update selected orders array based on checked items
            this.selectedHandCashOrders = this.handCashPendingOrders.filter(order => order.selected);
            // Update select all checkbox state
            this.selectAllHandCash = this.selectedHandCashOrders.length === this.handCashPendingOrders.length;
        },
        async processSettlement() {
            this.isProcessingPayout = true;
            this.payoutError = null;
            this.payoutSuccess = null;

            try {
                const transactionIds = this.unpaidTransactions.map(t => t.id);
                const totalAmount = this.finalAmountToPay;
                const baseUrl = window.baseUrl || '';

                // Prepare request payload
                const payload = {
                    transaction_ids: transactionIds,
                    total_amount: totalAmount
                };

                // Add hand cash order IDs if hand cash deduction is applicable and items are selected
                if (this.showHandCash && this.selectedHandCashOrders.length > 0) {
                    payload.hand_cash_order_ids = this.selectedHandCashOrders.map(order => order.id);
                    payload.hand_cash_deducted_amount = this.selectedHandCashAmount;
                }

                // Add incentive transaction IDs if any are selected
                if (this.selectedIncentiveTransactions.length > 0) {
                    payload.incentive_transaction_ids = this.selectedIncentiveTransactions.map(item => item.id);
                    payload.incentive_amount = this.selectedIncentiveAmount;
                }

                const response = await axios.post(`${baseUrl}/api/delivery_boys/${this.deliveryBoyId}/settle-payouts`, payload);

                if (response.data.success || response.data.status === 1) {
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
        getTypeVariant(type) {
            const variants = {
                'order': 'primary',
                'delivery': 'info',
                'credit': 'success',
                'debit': 'danger'
            };
            return variants[type] || 'secondary';
        },
        formatType(type) {
            if (!type) return '-';
            const labels = {
                'order': 'Order',
                'delivery': 'Delivery',
                'credit': 'Credit',
                'debit': 'Debit'
            };
            return labels[type] || type.charAt(0).toUpperCase() + type.slice(1);
        }
    },
    watch: {
        deliveryBoyId: {
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

:deep(.bg-primary) {
    background-color: #007bff !important;
    color: #fff !important;
}
</style>
