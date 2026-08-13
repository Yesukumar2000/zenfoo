<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Seller Pending Payouts</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                            <li class="breadcrumb-item active" aria-current="page">Seller Pending Payouts</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/dashboard" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to Dashboard
                    </router-link>
                </div>
            </div>

            <!-- Filters -->
            <div class="row mb-4">
                <div class="col-12 col-md-3">
                    <div class="form-group">
                        <label for="zoneFilter" class="form-label">Select Zone</label>
                        <select
                            id="zoneFilter"
                            v-model="city_id"
                            @change="getSellers()"
                            class="form-control form-select">
                            <option value="">All Zones</option>
                            <option v-for="city in cities" :key="city.id" :value="city.id">
                                {{ city.name }}
                            </option>
                            <option value="other">Other</option>
                        </select>
                    </div>
                </div>
                <div class="col-12 col-md-3">
                    <div class="form-group">
                        <label for="sellerSearch" class="form-label">Search Seller</label>
                        <input
                            id="sellerSearch"
                            v-model="searchQuery"
                            type="text"
                            class="form-control"
                            placeholder="Search by name, email, mobile...">
                    </div>
                </div>
                <div class="col-12 col-md-3">
                    <div class="form-group">
                        <label for="needToPayFilter" class="form-label">Filter</label>
                        <select
                            id="needToPayFilter"
                            v-model="showNeedToPayOnly"
                            class="form-control form-select">
                            <option :value="false">All Sellers</option>
                            <option :value="true">Need to Pay Only</option>
                        </select>
                    </div>
                </div>
            </div>

            <!-- Sellers List -->
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h4 class="mb-0">Sellers ({{ filteredSellers.length }})</h4>
                            <button class="btn btn-sm btn-primary" @click="getSellers()" v-b-tooltip.hover title="Refresh">
                                <i class="fa fa-refresh"></i>
                            </button>
                        </div>
                        <div class="card-body">
                            <!-- Loading State -->
                            <div v-if="isLoading" class="text-center py-5">
                                <b-spinner variant="primary" label="Loading..."></b-spinner>
                                <p class="mt-2 text-muted">Loading sellers...</p>
                            </div>

                            <!-- Empty State -->
                            <div v-else-if="filteredSellers.length === 0" class="text-center py-5">
                                <i class="fa fa-inbox fa-3x text-muted mb-3"></i>
                                <p class="text-muted">No sellers found for the selected zone.</p>
                            </div>

                            <!-- Sellers List -->
                            <div v-else class="sellers-list">
                                <div
                                    v-for="seller in filteredSellers"
                                    :key="seller.id"
                                    class="seller-row"
                                    :class="{ 'expanded': expandedSellerId === seller.id }">

                                    <!-- Seller Header -->
                                    <div class="seller-header" @click="toggleSellerDetails(seller.id)">
                                        <div class="seller-info">
                                            <div class="seller-logo">
                                                <img
                                                    v-if="seller.logo"
                                                    :src="$mediaUrl(seller.logo)"
                                                    :alt="seller.name"
                                                    class="rounded-circle"
                                                />
                                                <div v-else class="seller-initials">
                                                    {{ getInitials(seller.name) }}
                                                </div>
                                            </div>
                                            <div class="seller-details">
                                                <h5 class="seller-name mb-1">{{ seller.name }}</h5>
                                                <span class="seller-store text-muted">
                                                    <i class="fa fa-store me-1"></i>
                                                    {{ seller.store_name || 'N/A' }}
                                                </span>
                                            </div>
                                        </div>
                                        <div class="seller-actions">
                                            <template v-if="sellerPayoutCache[seller.id]">
                                                <span v-if="sellerPayoutCache[seller.id].total_pending > 0" class="badge bg-danger me-2">
                                                    ₹{{ sellerPayoutCache[seller.id].total_pending.toFixed(2) }} Pending
                                                </span>
                                                <span v-else class="badge bg-success me-2">All Settled</span>
                                            </template>
                                            <b-spinner v-else-if="preloadingPayouts" small class="me-2"></b-spinner>
                                            <i class="fa" :class="expandedSellerId === seller.id ? 'fa-chevron-up' : 'fa-chevron-down'"></i>
                                        </div>
                                    </div>

                                    <!-- Seller Expanded Details -->
                                    <transition name="slide-fade">
                                        <div v-if="expandedSellerId === seller.id" class="seller-expanded-details">
                                            <div class="details-grid">
                                                <div class="detail-item">
                                                    <label class="detail-label">Email:</label>
                                                    <span class="detail-value">{{ seller.email || '-' }}</span>
                                                </div>
                                                <div class="detail-item">
                                                    <label class="detail-label">Mobile:</label>
                                                    <span class="detail-value">{{ seller.mobile || '-' }}</span>
                                                </div>
                                                <div class="detail-item">
                                                    <label class="detail-label">Seller Code:</label>
                                                    <span class="detail-value">
                                                        <span class="badge bg-info">{{ seller.seller_code || seller.id }}</span>
                                                    </span>
                                                </div>
                                                <div class="detail-item">
                                                    <label class="detail-label">Zone:</label>
                                                    <span class="detail-value">{{ seller.city_name || 'Other' }}</span>
                                                </div>
                                            </div>

                                            <!-- Pending Payouts Section -->
                                            <div class="pending-payouts-section mt-3">
                                                <!-- Loading Payouts -->
                                                <div v-if="payoutsLoading" class="text-center py-4">
                                                    <b-spinner small variant="primary"></b-spinner>
                                                    <span class="ms-2 text-muted">Loading pending payouts...</span>
                                                </div>

                                                <!-- Payouts Data -->
                                                <div v-else-if="payoutData">
                                                    <!-- Summary Cards -->
                                                    <div class="row mb-3">
                                                        <div class="col-md-4">
                                                            <div class="payout-summary-card bg-warning">
                                                                <h6>Total Pending</h6>
                                                                <h3>₹{{ payoutData.total_pending.toFixed(2) }}</h3>
                                                                <small v-if="payoutData.refund_deduction > 0" class="text-muted">
                                                                    (After ₹{{ payoutData.refund_deduction.toFixed(2) }} refund deduction)
                                                                </small>
                                                            </div>
                                                        </div>
                                                        <div class="col-md-4">
                                                            <div class="payout-summary-card bg-info">
                                                                <h6>Transactions</h6>
                                                                <h3>{{ payoutData.transactions_count }}</h3>
                                                            </div>
                                                        </div>
                                                        <div class="col-md-4">
                                                            <div class="payout-summary-card bg-success">
                                                                <button
                                                                    v-if="payoutData.total_pending > 0"
                                                                    class="btn btn-light btn-block"
                                                                    @click="openPaymentModal()">
                                                                    <i class="fa fa-money me-2"></i>
                                                                    Pay Now
                                                                </button>
                                                                <span v-else class="text-white">
                                                                    <i class="fa fa-check-circle me-2"></i>
                                                                    All Settled
                                                                </span>
                                                            </div>
                                                        </div>
                                                    </div>

                                                    <!-- Transactions Table -->
                                                    <div v-if="payoutData.transactions && payoutData.transactions.length > 0" class="transactions-table-wrapper">
                                                        <h6 class="mb-3"><i class="fa fa-list me-2"></i>Unpaid Transactions</h6>
                                                        <b-table
                                                            :items="payoutData.transactions"
                                                            :fields="transactionFields"
                                                            small
                                                            striped
                                                            responsive
                                                            show-empty
                                                            class="transactions-table">
                                                            <template #cell(order_id)="data">
                                                                <router-link v-if="data.item.order_id" :to="'/orders/view/' + data.item.order_id" target="_blank">
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
                                                                <span class="badge" :class="getTypeBadgeClass(data.item.type)">
                                                                    {{ formatType(data.item.type) }}
                                                                </span>
                                                            </template>
                                                            <template #cell(amount)="data">
                                                                <span class="text-success fw-bold">
                                                                    ₹{{ data.item.amount.toFixed(2) }}
                                                                </span>
                                                                <small v-if="data.item.is_refunded_to_customer" class="d-block text-muted">
                                                                    (Refund: ₹{{ data.item.refundable_amount.toFixed(2) }})
                                                                </small>
                                                            </template>
                                                            <template #cell(admin_commission)="data">
                                                                ₹{{ parseFloat(data.item.admin_commission || 0).toFixed(2) }}
                                                            </template>
                                                            <template #cell(gst_percentage)="data">
                                                                <span class="badge bg-info">
                                                                    {{ parseFloat(data.item.gst_percentage || 0).toFixed(2) }}%
                                                                </span>
                                                            </template>
                                                            <template #cell(payment_gateway_fees)="data">
                                                                ₹{{ parseFloat(data.item.payment_gateway_fees || 0).toFixed(2) }}
                                                            </template>
                                                            <template #cell(created_at)="data">
                                                                {{ formatDate(data.item.created_at) }}
                                                            </template>
                                                        </b-table>
                                                    </div>
                                                </div>

                                                <!-- No Payouts -->
                                                <div v-else class="text-center py-4">
                                                    <i class="fa fa-check-circle fa-2x text-success mb-2"></i>
                                                    <p class="text-muted mb-0">No pending payouts for this seller</p>
                                                </div>
                                            </div>
                                        </div>
                                    </transition>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

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
                                <th class="text-end">Seller Gets</th>
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
                                <td class="text-end">₹{{ parseFloat(product.amount).toFixed(2) }}</td>
                                <td class="text-end">₹{{ parseFloat(product.total_amount).toFixed(2) }}</td>
                                <td class="text-end text-danger">-₹{{ parseFloat(product.commission).toFixed(2) }}</td>
                                <td class="text-end text-danger">-₹{{ parseFloat(product.gst || 0).toFixed(2) }}</td>
                                <td class="text-end text-success fw-bold">₹{{ parseFloat(product.seller_amount).toFixed(2) }}</td>
                            </tr>
                        </tbody>
                        <tfoot class="table-light fw-bold">
                            <tr>
                                <td colspan="3" class="text-end">Total:</td>
                                <td class="text-end">₹{{ calculateTotal('total_amount').toFixed(2) }}</td>
                                <td class="text-end text-danger">-₹{{ calculateTotal('commission').toFixed(2) }}</td>
                                <td class="text-end text-danger">-₹{{ calculateTotal('gst').toFixed(2) }}</td>
                                <td class="text-end text-success">₹{{ calculateTotal('seller_amount').toFixed(2) }}</td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>
        </b-modal>

        <!-- Payment Modal -->
        <b-modal v-model="showPaymentModal" size="lg" title="Settle Pending Payouts" :hide-header-close="isProcessingPayment">
            <!-- Bank Details -->
            <div v-if="payoutData && payoutData.bank_details" class="bank-details-section mb-4">
                <h6 class="mb-3"><i class="fa fa-bank me-2"></i>Bank Account Details</h6>
                <div class="row">
                    <div class="col-md-6">
                        <ul class="list-unstyled">
                            <li><strong>Bank Name:</strong> {{ payoutData.bank_details.bank_name }}</li>
                            <li><strong>Account Number:</strong> {{ payoutData.bank_details.account_number_masked }}</li>
                        </ul>
                    </div>
                    <div class="col-md-6">
                        <ul class="list-unstyled">
                            <li><strong>Account Holder:</strong> {{ payoutData.bank_details.account_holder_name }}</li>
                            <li><strong>IFSC Code:</strong> {{ payoutData.bank_details.ifsc_code }}</li>
                        </ul>
                    </div>
                </div>
                <hr>
            </div>

            <!-- Bank Details Loading -->
            <div v-else-if="!payoutData" class="text-center py-3 mb-3">
                <b-spinner small class="me-2"></b-spinner>
                <span>Loading payout details...</span>
            </div>

            <!-- Bank Details Missing Warning -->
            <div v-else-if="payoutData && !payoutData.bank_details" class="alert alert-warning mb-3">
                <i class="fa fa-exclamation-triangle me-2"></i>
                <strong>Bank Details Not Available</strong>
                <p class="mb-0 mt-2">This seller has not added their bank account details yet. Please ask the seller to add bank details in their app before processing the payout.</p>
            </div>

            <!-- Payment Summary -->
            <div v-if="payoutData" class="alert alert-info mb-3">
                <div class="d-flex justify-content-between align-items-center">
                    <span><strong>Total Amount to Pay:</strong></span>
                    <h4 class="mb-0">₹{{ payoutData.total_pending.toFixed(2) }}</h4>
                </div>
                <small v-if="payoutData.refund_deduction > 0" class="d-block mt-2 text-muted">
                    Original: ₹{{ payoutData.original_pending.toFixed(2) }} - Refunds: ₹{{ payoutData.refund_deduction.toFixed(2) }}
                </small>
                <div class="mt-2">
                    <strong>Transactions Count:</strong> {{ payoutData.transactions_count }}
                </div>
            </div>

            <!-- Refund Details -->
            <div v-if="payoutData && payoutData.refund_details && payoutData.refund_details.length > 0" class="refund-details mb-3">
                <h6 class="mb-2"><i class="fa fa-info-circle me-2"></i>Refund Deductions</h6>
                <ul class="list-unstyled mb-0">
                    <li v-for="refund in payoutData.refund_details" :key="refund.return_id" class="small text-muted">
                        • Return #{{ refund.return_id }}: ₹{{ refund.refundable_amount.toFixed(2) }}
                    </li>
                </ul>
                <hr>
            </div>

            <!-- Manual Transaction ID Input -->
            <div class="form-group mb-3">
                <label for="manualTransactionId" class="form-label">
                    <strong>Transaction ID / UTR Number *</strong>
                </label>
                <input
                    id="manualTransactionId"
                    v-model="manualTransactionId"
                    type="text"
                    class="form-control"
                    placeholder="Enter bank transaction ID or UTR number"
                    :disabled="isProcessingPayment"
                    required>
                <small class="form-text text-muted">
                    Enter the transaction ID from your manual bank transfer
                </small>
            </div>

            <!-- Success Message -->
            <div v-if="paymentSuccess" class="alert alert-success">
                <i class="fa fa-check-circle me-2"></i>
                {{ paymentSuccess }}
            </div>

            <!-- Error Message -->
            <div v-if="paymentError" class="alert alert-danger">
                <i class="fa fa-exclamation-circle me-2"></i>
                {{ paymentError }}
            </div>

            <!-- Modal Footer -->
            <template #modal-footer>
                <button class="btn btn-secondary" @click="closePaymentModal" :disabled="isProcessingPayment">
                    {{ paymentSuccess ? 'Close' : 'Cancel' }}
                </button>
                <button
                    v-if="!paymentSuccess"
                    class="btn btn-success"
                    :disabled="!manualTransactionId || isProcessingPayment || !payoutData || !payoutData.bank_details"
                    @click="processPayment">
                    <b-spinner v-if="isProcessingPayment" small class="me-1"></b-spinner>
                    <i v-else class="fa fa-check me-1"></i>
                    {{ isProcessingPayment ? 'Processing...' : 'Confirm Payment' }}
                </button>
            </template>
        </b-modal>
    </div>
</template>

<script>
export default {
    name: 'SellerPendingPayouts',
    data() {
        return {
            city_id: '',
            cities: [],
            sellers: [],
            isLoading: false,
            expandedSellerId: null,
            payoutsLoading: false,
            payoutData: null,
            searchQuery: '',
            showNeedToPayOnly: false,
            sellerPayoutCache: {}, // Cache payout data for sellers
            preloadingPayouts: false, // Preloading state for all sellers
            transactionFields: [
                { key: 'id', label: 'ID', sortable: true },
                { key: 'order_id', label: 'Order', sortable: true },
                { key: 'item_name', label: 'Item', sortable: false },
                { key: 'type', label: 'Type', sortable: true },
                { key: 'amount', label: 'Amount', sortable: true },
                { key: 'admin_commission', label: 'Commission', sortable: true },
                { key: 'gst_percentage', label: 'GST %', sortable: true },
                { key: 'payment_gateway_fees', label: 'Gateway Fees', sortable: true },
                { key: 'message', label: 'Description', sortable: false },
                { key: 'created_at', label: 'Date', sortable: true }
            ],
            showPaymentModal: false,
            manualTransactionId: '',
            isProcessingPayment: false,
            paymentSuccess: null,
            paymentError: null,
            showProductModal: false,
            selectedTransaction: null
        };
    },
    computed: {
        filteredSellers() {
            let filtered = this.sellers;

            // Search filter
            if (this.searchQuery) {
                const query = this.searchQuery.toLowerCase();
                filtered = filtered.filter(seller => {
                    return (
                        (seller.name && seller.name.toLowerCase().includes(query)) ||
                        (seller.email && seller.email.toLowerCase().includes(query)) ||
                        (seller.mobile && seller.mobile.toLowerCase().includes(query)) ||
                        (seller.store_name && seller.store_name.toLowerCase().includes(query))
                    );
                });
            }

            // Need to pay filter
            if (this.showNeedToPayOnly) {
                filtered = filtered.filter(seller => {
                    const payoutData = this.sellerPayoutCache[seller.id];
                    return payoutData && payoutData.total_pending > 0;
                });
            }

            return filtered;
        }
    },
    created() {
        this.getCities();
        this.getSellers();
    },
    methods: {
        /**
         * Fetch cities/zones from API
         */
        getCities() {
            axios.get(this.$apiUrl + '/cities')
                .then((response) => {
                    this.cities = response.data.data || response.data;
                })
                .catch((error) => {
                    console.error('Error fetching cities:', error);
                });
        },

        /**
         * Fetch sellers based on selected zone
         */
        getSellers() {
            this.isLoading = true;
            this.expandedSellerId = null; // Collapse all when fetching new data
            this.sellerPayoutCache = {}; // Clear cache on refresh

            axios.get(this.$apiUrl + '/sellers', {
                params: {
                    city_id: this.city_id,
                    filterStatus: '' // Get all active sellers
                }
            })
            .then((response) => {
                this.sellers = response.data.data || [];
                // Preload payout summaries so the "Need to Pay" filter works immediately
                this.preloadAllPayouts();
            })
            .catch((error) => {
                console.error('Error fetching sellers:', error);
                this.showMessage('error', 'Failed to fetch sellers');
            })
            .finally(() => {
                this.isLoading = false;
            });
        },

        /**
         * Preload payout summary for all sellers (enables Need-to-Pay filter)
         * Uses batch API endpoint - much faster than individual calls
         */
        async preloadAllPayouts() {
            if (!this.sellers.length) return;
            this.preloadingPayouts = true;

            try {
                // Single API call to get all sellers' pending payouts
                const response = await axios.get(this.$apiUrl + '/sellers/pending-payouts-batch');

                if (response.data.success) {
                    // Populate cache with batch data
                    const batchData = response.data.data;
                    Object.keys(batchData).forEach(sellerId => {
                        this.$set(this.sellerPayoutCache, sellerId, batchData[sellerId]);
                    });

                    // Set zero for sellers with no pending transactions
                    this.sellers.forEach(seller => {
                        if (!this.sellerPayoutCache[seller.id]) {
                            this.$set(this.sellerPayoutCache, seller.id, {
                                seller_id: seller.id,
                                total_pending: 0,
                                original_pending: 0,
                                refund_deduction: 0,
                                transactions_count: 0
                            });
                        }
                    });
                }
            } catch (error) {
                console.error('Error fetching batch payouts:', error);
                // Don't show error to user - this is background preload
            } finally {
                this.preloadingPayouts = false;
            }
        },

        /**
         * Toggle seller details visibility and fetch payouts
         */
        toggleSellerDetails(sellerId) {
            if (this.expandedSellerId === sellerId) {
                this.expandedSellerId = null; // Collapse if already expanded
                this.payoutData = null;
            } else {
                this.expandedSellerId = sellerId; // Expand this seller
                this.fetchPendingPayouts(sellerId);
            }
        },

        /**
         * Fetch pending payouts for a seller
         */
        fetchPendingPayouts(sellerId) {
            this.payoutsLoading = true;
            this.payoutData = null;

            axios.get(this.$apiUrl + `/seller/${sellerId}/pending-payouts`)
                .then((response) => {
                    if (response.data.success) {
                        this.payoutData = response.data.data;
                        // Cache the payout data for this seller
                        this.$set(this.sellerPayoutCache, sellerId, response.data.data);
                    } else {
                        this.showMessage('error', response.data.message || 'Failed to fetch payouts');
                    }
                })
                .catch((error) => {
                    console.error('Error fetching pending payouts:', error);
                    this.showMessage('error', error.response?.data?.message || 'Failed to fetch pending payouts');
                })
                .finally(() => {
                    this.payoutsLoading = false;
                });
        },

        /**
         * Format transaction type for display
         */
        formatType(type) {
            const typeLabels = {
                'order_commission': 'Order Commission',
                'credit': 'Credit',
                'refund': 'Refund',
                'withdrawal': 'Withdrawal',
                'debit': 'Debit',
                'order_item': 'Order Item'
            };
            return typeLabels[type] || type;
        },

        /**
         * Get badge class for transaction type
         */
        getTypeBadgeClass(type) {
            const badgeClasses = {
                'order_commission': 'bg-success',
                'credit': 'bg-info',
                'refund': 'bg-warning',
                'withdrawal': 'bg-danger',
                'debit': 'bg-danger',
                'order_item': 'bg-primary'
            };
            return badgeClasses[type] || 'bg-secondary';
        },

        /**
         * Open payment modal
         */
        openPaymentModal() {
            this.showPaymentModal = true;
            this.manualTransactionId = '';
            this.paymentSuccess = null;
            this.paymentError = null;
        },

        /**
         * Close payment modal
         */
        closePaymentModal() {
            if (this.paymentSuccess) {
                // Refresh payouts after successful payment
                this.fetchPendingPayouts(this.expandedSellerId);
            }
            this.showPaymentModal = false;
            this.manualTransactionId = '';
            this.paymentSuccess = null;
            this.paymentError = null;
        },

        /**
         * Process payment
         */
        processPayment() {
            if (!this.manualTransactionId) {
                this.paymentError = 'Please enter transaction ID';
                return;
            }

            if (!this.payoutData || this.payoutData.total_pending <= 0) {
                this.paymentError = 'No pending amount to settle';
                return;
            }

            this.isProcessingPayment = true;
            this.paymentError = null;
            this.paymentSuccess = null;

            const transactionIds = this.payoutData.transactions.map(t => t.id);

            axios.post(this.$apiUrl + `/seller/${this.expandedSellerId}/settle-pending-payouts`, {
                transaction_ids: transactionIds,
                manual_transaction_id: this.manualTransactionId,
                total_amount: this.payoutData.total_pending
            })
            .then((response) => {
                if (response.data.success) {
                    this.paymentSuccess = response.data.message || 'Payment settled successfully!';
                    this.showMessage('success', this.paymentSuccess);
                } else {
                    this.paymentError = response.data.message || 'Failed to process payment';
                }
            })
            .catch((error) => {
                console.error('Error processing payment:', error);
                this.paymentError = error.response?.data?.message || 'Failed to process payment. Please try again.';
            })
            .finally(() => {
                this.isProcessingPayment = false;
            });
        },

        /**
         * Format date for display
         */
        formatDate(dateString) {
            if (!dateString) return '-';
            const date = new Date(dateString);
            return date.toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'short',
                day: 'numeric'
            });
        },

        /**
         * Get initials from seller name for avatar
         */
        getInitials(name) {
            if (!name) return '?';
            const words = name.split(' ');
            if (words.length >= 2) {
                return (words[0][0] + words[1][0]).toUpperCase();
            }
            return name.substring(0, 2).toUpperCase();
        },

        /**
         * Show a toast/alert message
         */
        showMessage(type, message) {
            if (this.$bvToast) {
                this.$bvToast.toast(message, {
                    title: type === 'success' ? 'Success' : 'Error',
                    variant: type === 'success' ? 'success' : 'danger',
                    solid: true,
                    autoHideDelay: 4000
                });
            } else {
                console[type === 'error' ? 'error' : 'log'](message);
            }
        },

        /**
         * View product details in modal
         */
        viewProductDetails(transaction) {
            this.selectedTransaction = transaction;
            this.showProductModal = true;
        },

        /**
         * Calculate total for a specific field in products_json
         */
        calculateTotal(field) {
            if (!this.selectedTransaction || !this.selectedTransaction.products_json) return 0;
            return this.selectedTransaction.products_json.reduce((sum, product) => {
                return sum + parseFloat(product[field] || 0);
            }, 0);
        }
    }
};
</script>

<style scoped>
/* Zone Filter Styling */
.form-select {
    max-width: 100%;
    font-weight: 500;
}

/* Sellers List */
.sellers-list {
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

/* Seller Row */
.seller-row {
    background: #fff;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    overflow: hidden;
    transition: all 0.3s ease;
}

.seller-row:hover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.seller-row.expanded {
    border-color: #9AC444;
}

/* Seller Header */
.seller-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1.25rem;
    cursor: pointer;
    transition: background-color 0.2s ease;
}

.seller-header:hover {
    background-color: #f8f9fa;
}

.seller-info {
    display: flex;
    align-items: center;
    gap: 1rem;
    flex: 1;
}

.seller-logo {
    width: 50px;
    height: 50px;
    flex-shrink: 0;
}

.seller-logo img {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.seller-initials {
    width: 50px;
    height: 50px;
    border-radius: 50%;
    background: linear-gradient(135deg, #9AC444 0%, #7a9c36 100%);
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 600;
    font-size: 1.1rem;
}

.seller-details {
    flex: 1;
}

.seller-name {
    font-size: 1.1rem;
    font-weight: 600;
    color: #333;
    margin: 0;
}

.seller-store {
    font-size: 0.875rem;
    display: inline-flex;
    align-items: center;
}

.seller-actions {
    display: flex;
    align-items: center;
    gap: 0.5rem;
}

/* Seller Expanded Details */
.seller-expanded-details {
    padding: 1.25rem;
    background-color: #f8f9fa;
    border-top: 1px solid #e0e0e0;
}

.details-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1rem;
    margin-bottom: 1rem;
}

.detail-item {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
}

.detail-label {
    font-size: 0.75rem;
    font-weight: 600;
    color: #6c757d;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin: 0;
}

.detail-value {
    font-size: 0.95rem;
    color: #333;
    font-weight: 500;
}

/* Pending Payouts Section */
.pending-payouts-section {
    border-top: 1px solid #dee2e6;
    padding-top: 1rem;
}

/* Transition Animation */
.slide-fade-enter-active {
    transition: all 0.3s ease;
}

.slide-fade-leave-active {
    transition: all 0.2s ease;
}

.slide-fade-enter,
.slide-fade-leave-to {
    opacity: 0;
    transform: translateY(-10px);
}

/* Responsive */
@media (max-width: 768px) {
    .seller-header {
        padding: 1rem;
    }

    .seller-logo {
        width: 40px;
        height: 40px;
    }

    .seller-initials {
        width: 40px;
        height: 40px;
        font-size: 0.9rem;
    }

    .seller-name {
        font-size: 1rem;
    }

    .details-grid {
        grid-template-columns: 1fr;
        gap: 0.75rem;
    }
}

/* Badge Styling */
.badge {
    font-weight: 600;
    padding: 0.35em 0.65em;
    font-size: 0.85em;
}

.bg-warning {
    background-color: #ffc107 !important;
    color: #212529 !important;
}

.bg-info {
    background-color: #17a2b8 !important;
    color: #fff !important;
}

/* Payout Summary Cards */
.payout-summary-card {
    padding: 1.5rem;
    border-radius: 8px;
    color: white;
    text-align: center;
    height: 100%;
}

.payout-summary-card h6 {
    margin-bottom: 0.5rem;
    font-size: 0.875rem;
    opacity: 0.9;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.payout-summary-card h3 {
    margin: 0;
    font-size: 1.75rem;
    font-weight: 700;
}

.payout-summary-card small {
    font-size: 0.75rem;
    opacity: 0.8;
}

.payout-summary-card .btn-block {
    width: 100%;
    font-weight: 600;
}

/* Transactions Table */
.transactions-table-wrapper {
    margin-top: 1.5rem;
    background: white;
    padding: 1rem;
    border-radius: 8px;
    border: 1px solid #dee2e6;
}

.transactions-table {
    margin-bottom: 0;
    font-size: 0.875rem;
}

.transactions-table td {
    vertical-align: middle;
}

/* Bank Details Section */
.bank-details-section ul {
    margin-bottom: 0;
}

.bank-details-section li {
    margin-bottom: 0.5rem;
}

/* Refund Details */
.refund-details {
    background-color: #fff3cd;
    padding: 1rem;
    border-radius: 6px;
    border: 1px solid #ffeaa7;
}

.refund-details ul li {
    margin-bottom: 0.25rem;
}
</style>

<!-- Dark Mode Styles (unscoped to access body.theme-dark) -->
<style>
.theme-dark .seller-row {
    background: #2a2e33;
    border-color: #3d4147;
}

.theme-dark .seller-row:hover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
}

.theme-dark .seller-row.expanded {
    border-color: #9AC444;
}

.theme-dark .seller-header:hover {
    background-color: #333840;
}

.theme-dark .seller-name {
    color: #c2c2d9;
}

.theme-dark .seller-store {
    color: #adb5bd !important;
}

.theme-dark .seller-expanded-details {
    background-color: #1e2126;
    border-top-color: #3d4147;
}

.theme-dark .detail-label {
    color: #adb5bd;
}

.theme-dark .detail-value {
    color: #c2c2d9;
}

.theme-dark .pending-payouts-section {
    border-top-color: #3d4147;
}

.theme-dark .transactions-table-wrapper {
    background: #2a2e33;
    border-color: #3d4147;
}

.theme-dark .transactions-table-wrapper h6 {
    color: #c2c2d9;
}

.theme-dark .payout-summary-card.bg-warning {
    background-color: #664d03 !important;
    color: #ffda6a !important;
}

.theme-dark .payout-summary-card.bg-warning h6,
.theme-dark .payout-summary-card.bg-warning h3 {
    color: #ffda6a;
}

.theme-dark .payout-summary-card.bg-info {
    background-color: #055160 !important;
    color: #6edff6 !important;
}

.theme-dark .payout-summary-card.bg-info h6,
.theme-dark .payout-summary-card.bg-info h3 {
    color: #6edff6;
}

.theme-dark .payout-summary-card.bg-success {
    background-color: #0f5132 !important;
    color: #75b798 !important;
}

.theme-dark .payout-summary-card.bg-success span {
    color: #75b798 !important;
}

.theme-dark .refund-details {
    background-color: #332701;
    border-color: #664d03;
}

.theme-dark .refund-details h6 {
    color: #ffda6a;
}

.theme-dark .refund-details ul li {
    color: #adb5bd !important;
}

.theme-dark .bank-details-section ul li {
    color: #c2c2d9;
}

.theme-dark .bank-details-section ul li strong {
    color: #adb5bd;
}

.theme-dark .bank-details-section hr {
    border-color: #3d4147;
}
</style>