<template>
    <div class="p-3">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <div>
                <h5>Payout</h5>
                <p class="text-muted mb-0">View payout history and pending payouts.</p>
            </div>
            <div class="d-flex gap-3" v-if="!isLoading">
                <!-- Incentive Pending Card -->
                <div v-if="incentivePendingTransactions.length > 0">
                    <div class="card bg-success text-white" style="min-width: 250px;">
                        <div class="card-body text-center py-2 px-3">
                            <h6 class="mb-1" style="font-size: 0.85rem;">Incentive Pending</h6>
                            <h4 class="mb-0">{{ $currency }} {{ parseFloat(incentivePendingAmount).toFixed(2) }}</h4>
                            <small style="font-size: 0.75rem;">{{ incentivePendingTransactions.length }} pending {{ incentivePendingTransactions.length === 1 ? 'incentive' : 'incentives' }}</small>
                        </div>
                    </div>
                </div>
                <!-- Hand Cash Pending Card -->
                <div v-if="handCashPendingOrders.length > 0">
                    <div class="card bg-warning text-dark" style="min-width: 250px;">
                        <div class="card-body text-center py-2 px-3">
                            <h6 class="mb-1" style="font-size: 0.85rem;">Hand Cash Pending</h6>
                            <h4 class="mb-0">{{ $currency }} {{ parseFloat(handCashPendingAmount).toFixed(2) }}</h4>
                            <small style="font-size: 0.75rem;">{{ handCashPendingOrders.length }} pending {{ handCashPendingOrders.length === 1 ? 'order' : 'orders' }}</small>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Loading State -->
        <div class="text-center py-4" v-if="isLoading">
            <b-spinner class="align-middle"></b-spinner>
            <strong class="ms-2">Loading payouts...</strong>
        </div>

        <!-- Tabs -->
        <div v-else>
            <b-tabs content-class="mt-3" v-model="activeTab">
                <!-- Settled Tab -->
                <b-tab title="Settled" active>
                    <div v-if="settledTransactions.length > 0">
                        <!-- Summary Card -->
                        <div class="row mb-4">
                            <div class="col-md-12">
                                <div class="card bg-success text-white">
                                    <div class="card-body text-center py-3">
                                        <h6 class="mb-1">Total Settled Amount</h6>
                                        <h4 class="mb-0">{{ $currency }} {{ parseFloat(settledAmount).toFixed(2) }}</h4>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Settled Transactions Table -->
                        <div class="table-responsive">
                            <b-table
                                :items="settledTransactions"
                                :fields="settledFields"
                                :per-page="settledPerPage"
                                :current-page="settledCurrentPage"
                                :bordered="true"
                                stacked="md"
                                show-empty
                                small>

                                <template #cell(order_id)="row">
                                    <router-link v-if="row.item.order_id" :to="{ name: 'ViewOrder', params: { id: row.item.order_id }}">
                                        #{{ row.item.order_id }}
                                    </router-link>
                                    <span v-else>-</span>
                                </template>

                                <template #cell(transaction_date)="row">
                                    {{ formatDateTime(row.item.transaction_date) }}
                                </template>

                                <template #cell(driver_earnings)="row">
                                    <span class="text-success fw-bold">
                                        {{ $currency }} {{ getDisplayAmount(row.item) }}
                                    </span>
                                </template>

                                <template #cell(type)="row">
                                    <span class="badge" :class="getTypeBadgeClass(row.item.type)">
                                        {{ formatType(row.item.type) }}
                                    </span>
                                </template>

                                <template #cell(settled_at)="row">
                                    <span v-if="row.item.settled_at">{{ formatDateTime(row.item.settled_at) }}</span>
                                    <span v-else>-</span>
                                </template>
                            </b-table>
                        </div>

                        <!-- Pagination -->
                        <b-row class="mt-3">
                            <b-col md="2" class="my-1">
                                <b-form-group
                                    label="Per page"
                                    label-for="settled-per-page"
                                    label-size="sm"
                                    class="mb-0">
                                    <b-form-select
                                        id="settled-per-page"
                                        v-model="settledPerPage"
                                        :options="[10, 25, 50, 100]"
                                        size="sm"
                                        class="form-select"
                                    ></b-form-select>
                                </b-form-group>
                            </b-col>
                            <b-col md="4" class="my-1" offset-md="6">
                                <b-pagination
                                    v-model="settledCurrentPage"
                                    :total-rows="settledTransactions.length"
                                    :per-page="settledPerPage"
                                    align="fill"
                                    size="sm"
                                    class="my-0"
                                ></b-pagination>
                            </b-col>
                        </b-row>
                    </div>

                    <!-- No Settled Transactions -->
                    <div class="text-center py-4" v-else>
                        <i class="fa fa-check-circle fa-3x text-muted mb-3"></i>
                        <p>No settled transactions found.</p>
                    </div>
                </b-tab>

                <!-- Not Settled Tab -->
                <b-tab title="Not Settled">
                    <div v-if="unsettledTransactions.length > 0">
                        <!-- Summary Card with Settle Button -->
                        <div class="row mb-4">
                            <div class="col-md-8">
                                <div class="card bg-warning text-dark">
                                    <div class="card-body text-center py-3">
                                        <h6 class="mb-1">Pending Settlement</h6>
                                        <h4 class="mb-0">{{ $currency }} {{ parseFloat(unsettledAmount).toFixed(2) }}</h4>
                                        <small>{{ unsettledTransactions.length }} pending transactions</small>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4 d-flex align-items-center">
                                <button
                                    class="btn btn-success btn-lg w-100"
                                    :disabled="selectedUnsettledItems.length === 0"
                                    @click="openSettleModal">
                                    <i class="fa fa-money-bill me-2"></i>
                                    Settle Selected ({{ selectedUnsettledItems.length }})
                                </button>
                            </div>
                        </div>

                        <!-- Unsettled Transactions Table -->
                        <div class="table-responsive">
                            <b-table
                                :items="unsettledTransactions"
                                :fields="unsettledFields"
                                :per-page="unsettledPerPage"
                                :current-page="unsettledCurrentPage"
                                :bordered="true"
                                stacked="md"
                                show-empty
                                small>

                                <template #head(selected)>
                                    <b-form-checkbox
                                        v-model="selectAllUnsettled"
                                        @change="toggleSelectAllUnsettled"
                                    ></b-form-checkbox>
                                </template>

                                <template #cell(selected)="row">
                                    <b-form-checkbox
                                        v-model="row.item.selected"
                                        @change="toggleUnsettledSelection(row.item)"
                                    ></b-form-checkbox>
                                </template>

                                <template #cell(order_id)="row">
                                    <router-link v-if="row.item.order_id" :to="{ name: 'ViewOrder', params: { id: row.item.order_id }}">
                                        #{{ row.item.order_id }}
                                    </router-link>
                                    <span v-else>-</span>
                                </template>

                                <template #cell(transaction_date)="row">
                                    {{ formatDateTime(row.item.transaction_date) }}
                                </template>

                                <template #cell(driver_earnings)="row">
                                    <span class="text-warning fw-bold">
                                        {{ $currency }} {{ getDisplayAmount(row.item) }}
                                    </span>
                                </template>

                                <template #cell(type)="row">
                                    <span class="badge" :class="getTypeBadgeClass(row.item.type)">
                                        {{ formatType(row.item.type) }}
                                    </span>
                                </template>

                                <template #cell(status)="row">
                                    <span class="badge bg-warning text-dark">Pending</span>
                                </template>
                            </b-table>
                        </div>

                        <!-- Pagination -->
                        <b-row class="mt-3">
                            <b-col md="2" class="my-1">
                                <b-form-group
                                    label="Per page"
                                    label-for="unsettled-per-page"
                                    label-size="sm"
                                    class="mb-0">
                                    <b-form-select
                                        id="unsettled-per-page"
                                        v-model="unsettledPerPage"
                                        :options="[10, 25, 50, 100]"
                                        size="sm"
                                        class="form-select"
                                    ></b-form-select>
                                </b-form-group>
                            </b-col>
                            <b-col md="4" class="my-1" offset-md="6">
                                <b-pagination
                                    v-model="unsettledCurrentPage"
                                    :total-rows="unsettledTransactions.length"
                                    :per-page="unsettledPerPage"
                                    align="fill"
                                    size="sm"
                                    class="my-0"
                                ></b-pagination>
                            </b-col>
                        </b-row>
                    </div>

                    <!-- No Unsettled Transactions -->
                    <div class="text-center py-4" v-else>
                        <i class="fa fa-check-circle fa-3x text-success mb-3"></i>
                        <p>No pending transactions found. All payments have been settled.</p>
                    </div>
                </b-tab>

                <!-- Weekly Payout Tab -->
                <b-tab title="Weekly Payout">
                    <DeliveryBoyWeeklyPayment :delivery-boy-id="deliveryBoyId" />
                </b-tab>
            </b-tabs>
        </div>

        <!-- Settle Modal -->
        <b-modal v-model="showSettleModal" size="lg" centered :hide-header-close="isProcessingPayout">
            <template #modal-title>
                Settle Selected Payouts
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

            <!-- Selected Transactions Summary -->
            <div class="table-responsive" v-if="selectedUnsettledItems.length > 0">
                <h6 class="mb-3">Selected Transactions</h6>
                <table class="table table-bordered table-sm">
                    <thead>
                        <tr>
                            <th class="text-center">Order ID</th>
                            <th class="text-center">Type</th>
                            <th class="text-center">Amount to Settle</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="item in selectedUnsettledItems" :key="item.id">
                            <td class="text-center">#{{ item.order_id || '-' }}</td>
                            <td class="text-center">{{ formatType(item.type) }}</td>
                            <td class="text-center text-success fw-bold">{{ $currency }} {{ parseFloat(item.driver_earnings || 0).toFixed(2) }}</td>
                        </tr>
                    </tbody>
                    <tfoot>
                        <tr class="table-warning">
                            <th colspan="2" class="text-center">Total</th>
                            <th class="text-center text-success fw-bold">{{ $currency }} {{ selectedTotalAmount }}</th>
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
                <button class="btn btn-secondary" @click="closeSettleModal" :disabled="isProcessingPayout">
                    {{ payoutSuccess ? 'Close' : 'Cancel' }}
                </button>
                <button
                    v-if="!payoutSuccess"
                    class="btn btn-success"
                    :disabled="!bankDetails || isProcessingPayout || bankDetailsError || selectedUnsettledItems.length === 0"
                    @click="processSettlement">
                    <b-spinner small class="me-1" v-if="isProcessingPayout"></b-spinner>
                    <i class="fa fa-money-bill me-1" v-else></i>
                    {{ isProcessingPayout ? 'Processing...' : 'Pay ' + $currency + selectedTotalAmount }}
                </button>
            </template>
        </b-modal>
    </div>
</template>

<script>
import DeliveryBoyWeeklyPayment from './DeliveryBoyWeeklyPayment.vue';

export default {
    name: 'DeliveryBoyPayout',
    components: {
        DeliveryBoyWeeklyPayment
    },
    props: {
        deliveryBoyId: {
            type: [Number, String],
            required: true
        }
    },
    data() {
        return {
            settledTransactions: [],
            unsettledTransactions: [],
            unsettledAmount: 0,
            settledAmount: 0,
            isLoading: false,
            isLoaded: false,
            activeTab: 0,
            // Hand cash data
            handCashTransactions: [],
            handCashPendingAmount: 0,
            handCashPendingOrders: [],
            // Incentive data
            incentivePendingTransactions: [],
            incentivePendingAmount: 0,
            // Settled tab pagination
            settledCurrentPage: 1,
            settledPerPage: 10,
            settledFields: [
                { key: 'order_id', label: 'Order ID', sortable: true, class: 'text-center' },
                { key: 'transaction_date', label: 'Date', sortable: true, class: 'text-center' },
                { key: 'type', label: 'Type', sortable: true, class: 'text-center' },
                { key: 'driver_earnings', label: 'Amount Paid', sortable: true, class: 'text-center' },
                { key: 'settled_at', label: 'Settled At', sortable: true, class: 'text-center' }
            ],
            // Unsettled tab pagination and selection
            unsettledCurrentPage: 1,
            unsettledPerPage: 10,
            unsettledFields: [
                { key: 'selected', label: '', class: 'text-center', thStyle: { width: '50px' } },
                { key: 'order_id', label: 'Order ID', sortable: true, class: 'text-center' },
                { key: 'transaction_date', label: 'Date', sortable: true, class: 'text-center' },
                { key: 'type', label: 'Type', sortable: true, class: 'text-center' },
                { key: 'driver_earnings', label: 'Amount Pending', sortable: true, class: 'text-center' },
                { key: 'status', label: 'Status', sortable: false, class: 'text-center' }
            ],
            // Selection
            selectedUnsettledItems: [],
            selectAllUnsettled: false,
            // Settlement modal
            showSettleModal: false,
            bankDetails: null,
            isLoadingBankDetails: false,
            bankDetailsError: null,
            isProcessingPayout: false,
            payoutSuccess: null,
            payoutError: null
        };
    },
    computed: {
        selectedTotalAmount() {
            let total = 0;
            this.selectedUnsettledItems.forEach(item => {
                total += parseFloat(item.driver_earnings || 0);
            });
            return total.toFixed(2);
        }
    },
    watch: {
        // Update selectAll checkbox state when individual items change
        selectedUnsettledItems: {
            handler() {
                if (this.unsettledTransactions.length > 0) {
                    this.selectAllUnsettled = this.selectedUnsettledItems.length === this.unsettledTransactions.length;
                }
            },
            deep: true
        }
    },
    mounted() {
        this.loadPayouts();
        this.loadHandCash();
        this.loadIncentives();
    },
    methods: {
        loadPayouts() {
            if (this.isLoaded) return;

            this.isLoading = true;

            axios.get(this.$apiUrl + '/delivery_boys/' + this.deliveryBoyId + '/payouts')
                .then((response) => {
                    this.isLoading = false;
                    this.isLoaded = true;
                    if (response.data.status === 1) {
                        this.settledTransactions = response.data.data.settled_transactions || [];
                        // Add selected property to unsettled transactions
                        this.unsettledTransactions = (response.data.data.unsettled_transactions || []).map(t => ({
                            ...t,
                            selected: false
                        }));
                        this.unsettledAmount = response.data.data.unsettled_amount || 0;
                        this.settledAmount = response.data.data.settled_amount || 0;
                    } else {
                        this.settledTransactions = [];
                        this.unsettledTransactions = [];
                        this.unsettledAmount = 0;
                        this.settledAmount = 0;
                    }
                })
                .catch(() => {
                    this.isLoading = false;
                    this.isLoaded = true;
                    this.settledTransactions = [];
                    this.unsettledTransactions = [];
                    this.unsettledAmount = 0;
                    this.settledAmount = 0;
                });
        },
        loadHandCash() {
            axios.get(this.$apiUrl + '/delivery_boys/' + this.deliveryBoyId + '/hand-cash')
                .then((response) => {
                    if (response.data.status === 1) {
                        this.handCashTransactions = response.data.data || [];
                        // Calculate pending amount and filter pending orders
                        this.handCashPendingOrders = this.handCashTransactions.filter(t => !t.settled_with_admin);
                        this.handCashPendingAmount = this.handCashPendingOrders.reduce((total, t) => {
                            return total + parseFloat(t.admin_cash || 0);
                        }, 0);
                    } else {
                        this.handCashTransactions = [];
                        this.handCashPendingOrders = [];
                        this.handCashPendingAmount = 0;
                    }
                })
                .catch(() => {
                    this.handCashTransactions = [];
                    this.handCashPendingOrders = [];
                    this.handCashPendingAmount = 0;
                });
        },
        loadIncentives() {
            axios.get(this.$apiUrl + '/delivery_boys/' + this.deliveryBoyId + '/pending-incentives')
                .then((response) => {
                    if (response.data.status === 1) {
                        this.incentivePendingTransactions = response.data.data.transactions || [];
                        this.incentivePendingAmount = response.data.data.total_amount || 0;
                    } else {
                        this.incentivePendingTransactions = [];
                        this.incentivePendingAmount = 0;
                    }
                })
                .catch(() => {
                    this.incentivePendingTransactions = [];
                    this.incentivePendingAmount = 0;
                });
        },
        toggleSelectAllUnsettled() {
            if (this.selectAllUnsettled) {
                // Select all transactions
                this.unsettledTransactions.forEach(item => {
                    item.selected = true;
                });
                this.selectedUnsettledItems = [...this.unsettledTransactions];
            } else {
                // Deselect all transactions
                this.unsettledTransactions.forEach(item => {
                    item.selected = false;
                });
                this.selectedUnsettledItems = [];
            }
        },
        toggleUnsettledSelection(item) {
            if (item.selected) {
                // Add to selected items
                if (!this.selectedUnsettledItems.find(i => i.id === item.id)) {
                    this.selectedUnsettledItems.push(item);
                }
            } else {
                // Remove from selected items
                this.selectedUnsettledItems = this.selectedUnsettledItems.filter(i => i.id !== item.id);
            }
        },
        openSettleModal() {
            if (this.selectedUnsettledItems.length > 0) {
                this.showSettleModal = true;
                this.payoutSuccess = null;
                this.payoutError = null;
                this.loadBankDetails();
            }
        },
        closeSettleModal() {
            if (this.payoutSuccess) {
                // Reload the data after successful payout
                this.isLoaded = false;
                this.loadPayouts();
                this.selectedUnsettledItems = [];
                this.selectAllUnsettled = false;
            }
            this.showSettleModal = false;
            this.bankDetails = null;
            this.bankDetailsError = null;
            this.payoutSuccess = null;
            this.payoutError = null;
        },
        loadBankDetails() {
            this.isLoadingBankDetails = true;
            this.bankDetails = null;
            this.bankDetailsError = null;

            axios.get(this.$apiUrl + '/delivery_boys/' + this.deliveryBoyId + '/bank-details')
                .then((response) => {
                    this.isLoadingBankDetails = false;
                    if (response.data.status === 1) {
                        this.bankDetails = response.data.data;
                    } else {
                        this.bankDetailsError = response.data.message || 'Failed to load bank details';
                    }
                })
                .catch((error) => {
                    this.isLoadingBankDetails = false;
                    this.bankDetailsError = error.response?.data?.message || 'Failed to load bank details. Please ensure delivery boy has added bank account.';
                });
        },
        processSettlement() {
            this.isProcessingPayout = true;
            this.payoutError = null;
            this.payoutSuccess = null;

            const transactionIds = this.selectedUnsettledItems.map(item => item.id);
            const totalAmount = parseFloat(this.selectedTotalAmount);

            axios.post(this.$apiUrl + '/delivery_boys/' + this.deliveryBoyId + '/settle-payouts', {
                transaction_ids: transactionIds,
                total_amount: totalAmount
            })
                .then((response) => {
                    this.isProcessingPayout = false;
                    if (response.data.status === 1) {
                        this.payoutSuccess = 'Payout initiated successfully! Transaction ID: ' +
                            (response.data.data.payout_transaction_id || 'N/A');
                    } else {
                        this.payoutError = response.data.message || 'Failed to process payout';
                    }
                })
                .catch((error) => {
                    this.isProcessingPayout = false;
                    this.payoutError = error.response?.data?.message || 'Failed to process payout. Please try again.';
                });
        },
        formatDateTime(dateString) {
            if (!dateString) return '-';
            const date = new Date(dateString);
            return date.toLocaleDateString('en-GB') + ' ' + date.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
        },
        formatType(type) {
            if (!type) return '-';
            // Capitalize first letter
            return type.charAt(0).toUpperCase() + type.slice(1);
        },
        getTypeBadgeClass(type) {
            if (!type) return 'bg-secondary';
            const typeLower = type.toLowerCase();
            if (typeLower === 'incentive') return 'bg-success';
            if (typeLower === 'order') return 'bg-primary';
            if (typeLower === 'delivery') return 'bg-info';
            return 'bg-secondary';
        },
        getDisplayAmount(item) {
            // All transactions use 'driver_earnings' column (incentives are excluded)
            return parseFloat(item.driver_earnings || 0).toFixed(2);
        }
    }
};
</script>

<style scoped>
.fw-bold {
    font-weight: bold;
}
</style>
