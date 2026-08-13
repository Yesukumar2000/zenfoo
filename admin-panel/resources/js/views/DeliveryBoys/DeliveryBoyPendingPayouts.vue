<template>
    <div class="p-3">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <div>
                <h5>Delivery Boy Pending Payouts</h5>
                <p class="text-muted mb-0">Process pending payments to delivery boys</p>
            </div>
        </div>

        <!-- Summary Cards -->
        <b-row class="mb-4" v-if="!isLoading && summary">
            <b-col md="3">
                <b-card class="text-center bg-primary text-white">
                    <h6>Total Drivers</h6>
                    <h3>{{ summary.total_delivery_boys }}</h3>
                </b-card>
            </b-col>
            <b-col md="3">
                <b-card class="text-center bg-success text-white">
                    <h6>Total Pending</h6>
                    <h3>{{ $currency }}{{ summary.total_pending_amount.toFixed(2) }}</h3>
                </b-card>
            </b-col>
            <b-col md="3">
                <b-card class="text-center bg-warning text-dark">
                    <h6>Incentives</h6>
                    <h3>{{ $currency }}{{ summary.total_incentives.toFixed(2) }}</h3>
                </b-card>
            </b-col>
            <b-col md="3">
                <b-card class="text-center bg-info text-white">
                    <h6>Referrals</h6>
                    <h3>{{ $currency }}{{ summary.total_referrals.toFixed(2) }}</h3>
                </b-card>
            </b-col>
        </b-row>

        <!-- Filters -->
        <b-card class="mb-3">
            <b-row>
                <b-col md="4">
                    <b-form-group label="Search" label-for="search">
                        <b-form-input
                            id="search"
                            v-model="filters.search"
                            placeholder="Search by name, phone, email..."
                            @input="debouncedFetch"
                        ></b-form-input>
                    </b-form-group>
                </b-col>
                <b-col md="4">
                    <b-form-group label="Zone/City" label-for="city">
                        <b-form-select
                            id="city"
                            v-model="filters.city_id"
                            :options="cityOptions"
                            @change="fetchPendingPayouts"
                        ></b-form-select>
                    </b-form-group>
                </b-col>
                <b-col md="4" class="d-flex align-items-end">
                    <b-button variant="secondary" @click="resetFilters" class="w-100">
                        <i class="fa fa-refresh me-1"></i>
                        Reset Filters
                    </b-button>
                </b-col>
            </b-row>
        </b-card>

        <!-- Loading State -->
        <div class="text-center py-5" v-if="isLoading">
            <b-spinner variant="primary" label="Loading..."></b-spinner>
            <p class="mt-2">Loading pending payouts...</p>
        </div>

        <!-- Table -->
        <b-card v-else>
            <b-table
                :items="deliveryBoys"
                :fields="fields"
                :busy="isLoading"
                striped
                hover
                responsive
                show-empty
                empty-text="No pending payouts found"
            >
                <template #cell(delivery_boy)="data">
                    <div class="d-flex align-items-center">
                        <img
                            :src="data.item.profile_image_url || '/images/default-avatar.png'"
                            class="rounded-circle me-2"
                            width="40"
                            height="40"
                            style="object-fit: cover;"
                        />
                        <div>
                            <div class="fw-bold">{{ data.item.name }}</div>
                            <small class="text-muted">{{ data.item.phone }}</small>
                        </div>
                    </div>
                </template>

                <template #cell(city_name)="data">
                    <span class="badge bg-secondary">{{ data.item.city_name }}</span>
                </template>

                <template #cell(breakdown)="data">
                    <div class="small">
                        <div class="text-success">Base: {{ $currency }}{{ data.item.base_pending_amount.toFixed(2) }}</div>
                        <div class="text-danger" v-if="data.item.hand_cash_amount > 0">
                            Hand Cash: -{{ $currency }}{{ data.item.hand_cash_amount.toFixed(2) }}
                        </div>
                        <div class="text-primary" v-if="data.item.incentive_amount > 0">
                            Incentive: +{{ $currency }}{{ data.item.incentive_amount.toFixed(2) }}
                        </div>
                        <div class="text-info" v-if="data.item.referral_amount > 0">
                            Referral: +{{ $currency }}{{ data.item.referral_amount.toFixed(2) }}
                        </div>
                    </div>
                </template>

                <template #cell(total_pending_amount)="data">
                    <span class="fw-bold text-success fs-5">
                        {{ $currency }}{{ data.item.total_pending_amount.toFixed(2) }}
                    </span>
                </template>

                <template #cell(transaction_count)="data">
                    <span class="badge bg-info">{{ data.item.transaction_count }}</span>
                </template>

                <template #cell(actions)="data">
                    <b-button
                        size="sm"
                        variant="success"
                        @click="openPaymentModal(data.item)"
                        :disabled="!data.item.has_bank_details || data.item.total_pending_amount <= 0"
                    >
                        <i class="fa fa-money-bill me-1"></i>
                        Pay
                    </b-button>
                    <b-button
                        size="sm"
                        variant="info"
                        @click="viewDetails(data.item)"
                        class="ms-2"
                    >
                        <i class="fa fa-eye me-1"></i>
                        View
                    </b-button>
                    <div v-if="!data.item.has_bank_details" class="text-danger small mt-1">
                        No bank details
                    </div>
                </template>
            </b-table>

            <!-- Pagination -->
            <b-row v-if="pagination.total > 0">
                <b-col md="6">
                    <p class="text-muted">
                        Showing {{ (pagination.current_page - 1) * pagination.per_page + 1 }} to
                        {{ Math.min(pagination.current_page * pagination.per_page, pagination.total) }}
                        of {{ pagination.total }} entries
                    </p>
                </b-col>
                <b-col md="6">
                    <b-pagination
                        v-model="pagination.current_page"
                        :total-rows="pagination.total"
                        :per-page="pagination.per_page"
                        align="right"
                        @change="onPageChange"
                    ></b-pagination>
                </b-col>
            </b-row>
        </b-card>

        <!-- Payment Modal -->
        <b-modal
            v-model="showPaymentModal"
            size="lg"
            centered
            :hide-header-close="isProcessingPayout"
            title="Process Payment"
        >
            <div v-if="selectedDeliveryBoy">
                <!-- Delivery Boy Info -->
                <div class="text-center mb-4">
                    <img
                        :src="selectedDeliveryBoy.profile_image_url || '/images/default-avatar.png'"
                        class="rounded-circle mb-2"
                        width="80"
                        height="80"
                        style="object-fit: cover;"
                    />
                    <h5 class="mb-1">{{ selectedDeliveryBoy.name }}</h5>
                    <p class="text-muted mb-0">{{ selectedDeliveryBoy.phone }}</p>
                </div>

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

                <!-- Amount Breakdown -->
                <div class="table-responsive mb-3">
                    <table class="table table-bordered">
                        <tbody>
                            <tr class="table-success">
                                <td><strong>Base Pending Amount</strong></td>
                                <td class="text-end">
                                    <strong>{{ $currency }}{{ selectedDeliveryBoy.base_pending_amount.toFixed(2) }}</strong>
                                </td>
                            </tr>
                            <tr v-if="selectedDeliveryBoy.hand_cash_amount > 0" class="table-warning">
                                <td>
                                    <i class="fa fa-minus-circle me-1"></i>
                                    Hand Cash Deduction
                                </td>
                                <td class="text-end text-danger">
                                    - {{ $currency }}{{ selectedDeliveryBoy.hand_cash_amount.toFixed(2) }}
                                </td>
                            </tr>
                            <tr v-if="selectedDeliveryBoy.incentive_amount > 0" class="table-primary">
                                <td>
                                    <i class="fa fa-plus-circle me-1"></i>
                                    Incentive Bonus
                                </td>
                                <td class="text-end text-success">
                                    + {{ $currency }}{{ selectedDeliveryBoy.incentive_amount.toFixed(2) }}
                                </td>
                            </tr>
                            <tr v-if="selectedDeliveryBoy.referral_amount > 0" class="table-info">
                                <td>
                                    <i class="fa fa-plus-circle me-1"></i>
                                    Referral Bonus
                                </td>
                                <td class="text-end text-success">
                                    + {{ $currency }}{{ selectedDeliveryBoy.referral_amount.toFixed(2) }}
                                </td>
                            </tr>
                            <tr class="table-success">
                                <td><strong>Final Amount to Pay</strong></td>
                                <td class="text-end">
                                    <strong class="fs-5 text-success">
                                        {{ $currency }}{{ selectedDeliveryBoy.total_pending_amount.toFixed(2) }}
                                    </strong>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>

                <!-- Manual Transaction ID Input -->
                <div class="mt-3" v-if="!payoutSuccess && !payoutError">
                    <label class="form-label">
                        <strong>Bank Transaction ID <span class="text-danger">*</span></strong>
                    </label>
                    <input
                        type="text"
                        class="form-control"
                        v-model="manualTransactionId"
                        placeholder="Enter bank transfer transaction ID"
                        :disabled="isProcessingPayout"
                    />
                    <small class="text-muted">
                        Enter the transaction ID from your bank after completing the manual transfer
                    </small>
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
            </div>

            <template #modal-footer>
                <button class="btn btn-secondary" @click="closePaymentModal" :disabled="isProcessingPayout">
                    {{ payoutSuccess ? 'Close' : 'Cancel' }}
                </button>
                <button
                    v-if="!payoutSuccess && selectedDeliveryBoy"
                    class="btn btn-success"
                    :disabled="!bankDetails || isProcessingPayout || bankDetailsError || selectedDeliveryBoy.total_pending_amount <= 0 || !manualTransactionId.trim()"
                    @click="processPayment"
                >
                    <b-spinner small class="me-1" v-if="isProcessingPayout"></b-spinner>
                    <i class="fa fa-money-bill me-1" v-else></i>
                    {{ isProcessingPayout ? 'Processing...' : 'Pay ' + $currency + (selectedDeliveryBoy?.total_pending_amount || 0).toFixed(2) }}
                </button>
            </template>
        </b-modal>
    </div>
</template>

<script>
import axios from 'axios';
import debounce from 'lodash/debounce';

export default {
    name: 'DeliveryBoyPendingPayouts',
    data() {
        return {
            isLoading: false,
            deliveryBoys: [],
            summary: null,
            pagination: {
                current_page: 1,
                per_page: 20,
                total: 0,
                last_page: 1
            },
            filters: {
                search: '',
                city_id: null
            },
            cityOptions: [
                { value: null, text: 'All Cities' }
            ],
            fields: [
                { key: 'delivery_boy', label: 'Delivery Boy', sortable: false },
                { key: 'city_name', label: 'City', sortable: false },
                { key: 'breakdown', label: 'Breakdown', sortable: false },
                { key: 'total_pending_amount', label: 'Total Pending', sortable: false },
                { key: 'transaction_count', label: 'Transactions', sortable: false },
                { key: 'actions', label: 'Actions', sortable: false }
            ],
            // Payment Modal
            showPaymentModal: false,
            selectedDeliveryBoy: null,
            bankDetails: null,
            isLoadingBankDetails: false,
            bankDetailsError: null,
            isProcessingPayout: false,
            payoutSuccess: null,
            payoutError: null,
            manualTransactionId: ''
        };
    },
    mounted() {
        this.fetchCities();
        this.fetchPendingPayouts();
    },
    methods: {
        async fetchCities() {
            try {
                const response = await axios.get(this.$apiUrl + '/cities');
                if (response.data.data && response.data.data.length > 0) {
                    this.cityOptions = [
                        { value: null, text: 'All Cities' },
                        ...response.data.data.map(city => ({
                            value: city.id,
                            text: city.name
                        }))
                    ];
                }
            } catch (error) {
                console.error('Error fetching cities:', error);
            }
        },
        async fetchPendingPayouts() {
            this.isLoading = true;
            try {
                const params = {
                    page: this.pagination.current_page,
                    per_page: this.pagination.per_page,
                    search: this.filters.search || undefined,
                    city_id: this.filters.city_id || undefined
                };

                const response = await axios.get(this.$apiUrl + '/delivery_boys/pending-payouts', { params });

                if (response.data.success) {
                    this.deliveryBoys = response.data.data.delivery_boys;
                    this.summary = response.data.data.summary;
                    this.pagination = response.data.data.pagination;
                } else {
                    this.$bvToast.toast(response.data.message || 'Failed to fetch pending payouts', {
                        title: 'Error',
                        variant: 'danger',
                        solid: true
                    });
                }
            } catch (error) {
                console.error('Error fetching pending payouts:', error);
                this.$bvToast.toast('Failed to fetch pending payouts', {
                    title: 'Error',
                    variant: 'danger',
                    solid: true
                });
            } finally {
                this.isLoading = false;
            }
        },
        debouncedFetch: debounce(function() {
            this.pagination.current_page = 1;
            this.fetchPendingPayouts();
        }, 500),
        resetFilters() {
            this.filters.search = '';
            this.filters.city_id = null;
            this.pagination.current_page = 1;
            this.fetchPendingPayouts();
        },
        onPageChange(page) {
            this.pagination.current_page = page;
            this.fetchPendingPayouts();
        },
        viewDetails(deliveryBoy) {
            this.$router.push({
                name: 'ViewDeliveryBoy',
                params: { id: deliveryBoy.delivery_boy_id }
            });
        },
        openPaymentModal(deliveryBoy) {
            this.selectedDeliveryBoy = deliveryBoy;
            this.showPaymentModal = true;
            this.payoutSuccess = null;
            this.payoutError = null;
            this.manualTransactionId = '';
            this.loadBankDetails(deliveryBoy.delivery_boy_id);
        },
        closePaymentModal() {
            if (this.payoutSuccess) {
                this.fetchPendingPayouts();
            }
            this.showPaymentModal = false;
            this.selectedDeliveryBoy = null;
            this.bankDetails = null;
            this.bankDetailsError = null;
            this.payoutSuccess = null;
            this.payoutError = null;
            this.manualTransactionId = '';
        },
        async loadBankDetails(deliveryBoyId) {
            this.isLoadingBankDetails = true;
            this.bankDetails = null;
            this.bankDetailsError = null;

            try {
                const response = await axios.get(this.$apiUrl + '/delivery_boys/' + deliveryBoyId + '/bank-details');

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
        async processPayment() {
            this.isProcessingPayout = true;
            this.payoutError = null;
            this.payoutSuccess = null;

            try {
                // Get all unsettled transactions for this delivery boy
                const transactionsResponse = await axios.get(
                    this.$apiUrl + '/delivery_boys/' + this.selectedDeliveryBoy.delivery_boy_id + '/unsettled-payouts'
                );

                if (!transactionsResponse.data.success) {
                    throw new Error('Failed to fetch unsettled transactions');
                }

                const unsettledData = transactionsResponse.data.data;

                // Prepare payload
                const payload = {
                    transaction_ids: unsettledData.base_transactions.map(t => t.id),
                    total_amount: this.selectedDeliveryBoy.total_pending_amount
                };

                // Add hand cash if present
                if (unsettledData.hand_cash_transactions && unsettledData.hand_cash_transactions.length > 0) {
                    payload.hand_cash_order_ids = unsettledData.hand_cash_transactions.map(t => t.id);
                    payload.hand_cash_deducted_amount = this.selectedDeliveryBoy.hand_cash_amount;
                }

                // Add incentives if present
                if (unsettledData.incentive_transactions && unsettledData.incentive_transactions.length > 0) {
                    payload.incentive_transaction_ids = unsettledData.incentive_transactions.map(t => t.id);
                    payload.incentive_amount = this.selectedDeliveryBoy.incentive_amount;
                }

                // Add referral bonus IDs if present
                if (this.selectedDeliveryBoy.referral_amount > 0) {
                    const referralsResponse = await axios.get(
                        this.$apiUrl + '/delivery_boys/' + this.selectedDeliveryBoy.delivery_boy_id + '/pending-referrals'
                    );
                    if (referralsResponse.data.success && referralsResponse.data.data) {
                        payload.referral_ids = referralsResponse.data.data.map(r => r.id);
                        payload.referral_amount = this.selectedDeliveryBoy.referral_amount;
                    }
                }

                // Add manual transaction ID
                payload.manual_transaction_id = this.manualTransactionId.trim();

                const response = await axios.post(
                    this.$apiUrl + '/delivery_boys/' + this.selectedDeliveryBoy.delivery_boy_id + '/settle-payouts',
                    payload
                );

                if (response.data.success || response.data.status === 1) {
                    this.payoutSuccess = 'Payment processed successfully! Transaction ID: ' +
                        (response.data.data?.payout_transaction_id || 'N/A');
                } else {
                    this.payoutError = response.data.message || 'Failed to process payment';
                }
            } catch (error) {
                console.error('Payment error:', error);
                this.payoutError = error.response?.data?.message || 'Failed to process payment. Please try again.';
            } finally {
                this.isProcessingPayout = false;
            }
        }
    }
};
</script>

<style scoped>
.fs-5 {
    font-size: 1.25rem;
}
</style>
