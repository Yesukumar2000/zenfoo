<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>Unsettled Payouts</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">Dashboard</router-link></li>
                                <li class="breadcrumb-item"><router-link to="/delivery_boys">Delivery Boys</router-link></li>
                                <li class="breadcrumb-item">
                                    <router-link :to="{ name: 'ViewDeliveryBoy', params: { id: $route.params.id }}">View</router-link>
                                </li>
                                <li class="breadcrumb-item active" aria-current="page">Unsettled Payouts</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link :to="{ name: 'ViewDeliveryBoy', params: { id: $route.params.id }}" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <section class="section">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h4 class="card-title mb-0">Unsettled Payout Orders</h4>
                        <div>
                            <button
                                class="btn btn-primary"
                                :disabled="selectedItems.length === 0"
                                @click="openSettleModal">
                                <i class="fa fa-money-bill me-1"></i>
                                Settle Selected
                            </button>
                        </div>
                    </div>
                    <div class="card-body">
                        <!-- Loading State -->
                        <div class="text-center py-5" v-if="isLoading">
                            <b-spinner class="align-middle"></b-spinner>
                            <strong class="ms-2">Loading unsettled payouts...</strong>
                        </div>

                        <!-- Transactions Content -->
                        <div v-else-if="transactions.length > 0">
                            <!-- Summary -->
                            <div class="alert alert-warning mb-4">
                                <div class="d-flex justify-content-between align-items-center">
                                    <div>
                                        <strong>Total Unsettled Amount:</strong>
                                        {{ $currency }} {{ parseFloat(totalUnsettledAmount).toFixed(2) }}
                                    </div>
                                    <div>
                                        <strong>{{ transactions.length }}</strong> pending transactions
                                    </div>
                                </div>
                            </div>

                            <!-- Transactions Table -->
                            <div class="table-responsive">
                                <b-table
                                    :items="transactions"
                                    :fields="transactionFields"
                                    :per-page="perPage"
                                    :current-page="currentPage"
                                    :bordered="true"
                                    stacked="md"
                                    show-empty
                                    small>

                                    <template #head(selected)>
                                        <b-form-checkbox
                                            v-model="selectAll"
                                            @change="toggleSelectAll"
                                        ></b-form-checkbox>
                                    </template>

                                    <template #cell(selected)="row">
                                        <b-form-checkbox
                                            v-model="row.item.selected"
                                            @change="toggleSelection(row.item)"
                                        ></b-form-checkbox>
                                    </template>

                                    <template #cell(order_id)="row">
                                        <router-link v-if="row.item.order_id" :to="{ name: 'ViewOrder', params: { id: row.item.order_id }}">
                                            #{{ row.item.order_id }}
                                        </router-link>
                                        <span v-else>-</span>
                                    </template>

                                    <template #cell(type)="row">
                                        <span class="badge" :class="getTypeBadgeClass(row.item.type)">
                                            {{ formatType(row.item.type) }}
                                        </span>
                                    </template>

                                    <template #cell(driver_earnings)="row">
                                        <span class="text-success fw-bold">{{ $currency }} {{ parseFloat(row.item.driver_earnings || 0).toFixed(2) }}</span>
                                    </template>

                                    <template #cell(transaction_date)="row">
                                        {{ formatDateTime(row.item.transaction_date) }}
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
                                            v-model="perPage"
                                            :options="[10, 25, 50, 100]"
                                            size="sm"
                                            class="form-select"
                                        ></b-form-select>
                                    </b-form-group>
                                </b-col>
                                <b-col md="4" class="my-1" offset-md="6">
                                    <b-pagination
                                        v-model="currentPage"
                                        :total-rows="transactions.length"
                                        :per-page="perPage"
                                        align="fill"
                                        size="sm"
                                        class="my-0"
                                    ></b-pagination>
                                </b-col>
                            </b-row>
                        </div>

                        <!-- No Transactions -->
                        <div class="text-center py-4" v-else>
                            <i class="fa fa-check-circle fa-3x text-success mb-3"></i>
                            <p>No unsettled payouts found. All payments have been settled.</p>
                            <router-link :to="{ name: 'ViewDeliveryBoy', params: { id: $route.params.id }}" class="btn btn-primary">
                                <i class="fa fa-arrow-left me-1"></i>
                                Back to Delivery Boy
                            </router-link>
                        </div>
                    </div>
                </div>
            </section>
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
                        <p class="mb-1"><small class="text-muted">Bank Name:</small></p>
                        <p class="fw-bold">{{ bankDetails.bank_name }}</p>
                    </div>
                    <div class="col-md-6">
                        <p class="mb-1"><small class="text-muted">Account Holder:</small></p>
                        <p class="fw-bold">{{ bankDetails.account_holder_name }}</p>
                    </div>
                    <div class="col-md-6">
                        <p class="mb-1"><small class="text-muted">Account Number:</small></p>
                        <p class="fw-bold">{{ bankDetails.account_number_masked }}</p>
                    </div>
                    <div class="col-md-6">
                        <p class="mb-1"><small class="text-muted">IFSC Code:</small></p>
                        <p class="fw-bold">{{ bankDetails.ifsc_code }}</p>
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

            <div class="table-responsive">
                <table class="table table-bordered table-sm">
                    <thead>
                        <tr>
                            <th class="text-center">Order ID</th>
                            <th class="text-center">Amount to Settle</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr v-for="item in selectedItems" :key="item.id">
                            <td class="text-center">#{{ item.order_id || '-' }}</td>
                            <td class="text-center text-success fw-bold">{{ $currency }} {{ parseFloat(item.driver_earnings || 0).toFixed(2) }}</td>
                        </tr>
                    </tbody>
                    <tfoot>
                        <tr class="table-warning">
                            <th class="text-center">Total</th>
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
                    :disabled="!bankDetails || isProcessingPayout || bankDetailsError"
                    @click="processSettlement">
                    <b-spinner small class="me-1" v-if="isProcessingPayout"></b-spinner>
                    <i class="fa fa-money-bill me-1" v-else></i>
                    {{ isProcessingPayout ? 'Processing...' : 'Pay (' + $currency + ' ' + selectedTotalAmount + ')' }}
                </button>
            </template>
        </b-modal>
    </div>
</template>

<script>
export default {
    name: 'DeliveryBoyUnsettledPayouts',
    data() {
        return {
            transactions: [],
            totalUnsettledAmount: 0,
            selectedItems: [],
            selectAll: false,
            isLoading: false,
            currentPage: 1,
            perPage: 10,
            showSettleModal: false,
            // Bank details
            bankDetails: null,
            isLoadingBankDetails: false,
            bankDetailsError: null,
            // Payout processing
            isProcessingPayout: false,
            payoutSuccess: null,
            payoutError: null,
            transactionFields: [
                { key: 'selected', label: '', class: 'text-center', thStyle: { width: '50px' } },
                { key: 'order_id', label: 'Order ID', sortable: true, class: 'text-center' },
                { key: 'type', label: 'Type', sortable: true, class: 'text-center' },
                { key: 'driver_earnings', label: 'Amount', sortable: true, class: 'text-center' },
                { key: 'transaction_date', label: 'Date', sortable: true, class: 'text-center' }
            ]
        };
    },
    computed: {
        selectedTotalAmount() {
            let total = 0;
            this.selectedItems.forEach(item => {
                total += parseFloat(item.driver_earnings || 0);
            });
            return total.toFixed(2);
        }
    },
    watch: {
        // Update selectAll checkbox state when individual items change
        selectedItems: {
            handler() {
                if (this.transactions.length > 0) {
                    this.selectAll = this.selectedItems.length === this.transactions.length;
                }
            },
            deep: true
        }
    },
    created() {
        this.loadUnsettledPayouts();
    },
    methods: {
        loadUnsettledPayouts() {
            const id = this.$route.params.id;
            this.isLoading = true;

            axios.get(this.$apiUrl + '/delivery_boys/' + id + '/unsettled-payouts')
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status === 1) {
                        // Add selected property to each transaction
                        this.transactions = (response.data.data.unsettled_transactions || []).map(t => ({
                            ...t,
                            selected: false
                        }));
                        this.totalUnsettledAmount = response.data.data.total_unsettled_amount || 0;
                    } else {
                        this.transactions = [];
                        this.totalUnsettledAmount = 0;
                    }
                })
                .catch(() => {
                    this.isLoading = false;
                    this.transactions = [];
                    this.totalUnsettledAmount = 0;
                });
        },
        toggleSelectAll() {
            if (this.selectAll) {
                // Select all transactions
                this.transactions.forEach(item => {
                    item.selected = true;
                });
                this.selectedItems = [...this.transactions];
            } else {
                // Deselect all transactions
                this.transactions.forEach(item => {
                    item.selected = false;
                });
                this.selectedItems = [];
            }
        },
        toggleSelection(item) {
            if (item.selected) {
                // Add to selected items
                if (!this.selectedItems.find(i => i.id === item.id)) {
                    this.selectedItems.push(item);
                }
            } else {
                // Remove from selected items
                this.selectedItems = this.selectedItems.filter(i => i.id !== item.id);
            }
        },
        openSettleModal() {
            if (this.selectedItems.length > 0) {
                this.showSettleModal = true;
                this.payoutSuccess = null;
                this.payoutError = null;
                this.loadBankDetails();
            }
        },
        closeSettleModal() {
            if (this.payoutSuccess) {
                // Reload the data after successful payout
                this.loadUnsettledPayouts();
                this.selectedItems = [];
                this.selectAll = false;
            }
            this.showSettleModal = false;
            this.bankDetails = null;
            this.bankDetailsError = null;
            this.payoutSuccess = null;
            this.payoutError = null;
        },
        loadBankDetails() {
            const id = this.$route.params.id;
            this.isLoadingBankDetails = true;
            this.bankDetails = null;
            this.bankDetailsError = null;

            axios.get(this.$apiUrl + '/delivery_boys/' + id + '/bank-details')
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
                    this.bankDetailsError = error.response?.data?.message || 'Failed to load bank details';
                });
        },
        processSettlement() {
            const id = this.$route.params.id;
            this.isProcessingPayout = true;
            this.payoutError = null;
            this.payoutSuccess = null;

            const transactionIds = this.selectedItems.map(item => item.id);
            const totalAmount = parseFloat(this.selectedTotalAmount);

            axios.post(this.$apiUrl + '/delivery_boys/' + id + '/settle-payouts', {
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
        }
    }
};
</script>

<style scoped>
.fw-bold {
    font-weight: bold;
}
</style>
