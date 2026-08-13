<template>
    <div class="p-3">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <div>
                <h5>Driver Manual Payments</h5>
                <p class="text-muted mb-0">Review and approve driver payment submissions</p>
            </div>
        </div>

        <!-- Summary Cards -->
        <b-row class="mb-4" v-if="!isLoading && summary">
            <b-col md="3">
                <b-card class="text-center bg-warning text-dark">
                    <h6>Pending</h6>
                    <h3>{{ summary.pending_count }}</h3>
                    <small>{{ $currency }}{{ summary.pending_amount.toFixed(2) }}</small>
                </b-card>
            </b-col>
            <b-col md="3">
                <b-card class="text-center bg-success text-white">
                    <h6>Approved</h6>
                    <h3>{{ summary.approved_count }}</h3>
                    <small>{{ $currency }}{{ summary.approved_amount.toFixed(2) }}</small>
                </b-card>
            </b-col>
            <b-col md="3">
                <b-card class="text-center bg-danger text-white">
                    <h6>Rejected</h6>
                    <h3>{{ summary.rejected_count }}</h3>
                    <small>{{ $currency }}{{ summary.rejected_amount.toFixed(2) }}</small>
                </b-card>
            </b-col>
            <b-col md="3">
                <b-card class="text-center bg-info text-white">
                    <h6>Total Submitted</h6>
                    <h3>{{ summary.total_count }}</h3>
                    <small>{{ $currency }}{{ summary.total_amount.toFixed(2) }}</small>
                </b-card>
            </b-col>
        </b-row>

        <!-- Filters -->
        <b-card class="mb-3">
            <b-row>
                <b-col md="4">
                    <b-form-group label="Status Filter" label-for="status">
                        <b-form-select
                            id="status"
                            v-model="filters.status"
                            :options="statusOptions"
                            @change="fetchPayments"
                        ></b-form-select>
                    </b-form-group>
                </b-col>
                <b-col md="4">
                    <b-form-group label="Search" label-for="search">
                        <b-form-input
                            id="search"
                            v-model="filters.search"
                            placeholder="Driver name, phone, transaction ID..."
                            @input="debouncedFetch"
                        ></b-form-input>
                    </b-form-group>
                </b-col>
                <b-col md="4" class="d-flex align-items-end">
                    <b-button variant="secondary" @click="resetFilters" class="w-100">
                        <i class="fa fa-refresh me-1"></i>
                        Reset
                    </b-button>
                </b-col>
            </b-row>
        </b-card>

        <!-- Loading State -->
        <div class="text-center py-5" v-if="isLoading">
            <b-spinner variant="primary" label="Loading..."></b-spinner>
            <p class="mt-2">Loading payments...</p>
        </div>

        <!-- Table -->
        <b-card v-else>
            <b-table
                :items="payments"
                :fields="fields"
                :busy="isLoading"
                striped
                hover
                responsive
                show-empty
                empty-text="No manual payments found"
            >
                <template #cell(driver)="data">
                    <div class="d-flex align-items-center">
                        <div>
                            <div class="fw-bold">{{ data.item.delivery_boy.name }}</div>
                            <small class="text-muted">ID: {{ data.item.delivery_boy.id }} | {{ data.item.delivery_boy.mobile }}</small>
                        </div>
                    </div>
                </template>

                <template #cell(amount)="data">
                    <strong class="text-success">{{ $currency }}{{ parseFloat(data.item.amount).toFixed(2) }}</strong>
                </template>

                <template #cell(transaction_id)="data">
                    <code>{{ data.item.transaction_id }}</code>
                </template>

                <template #cell(proof_image)="data">
                    <a v-if="data.item.proof_image" :href="getImageUrl(data.item.proof_image)" target="_blank" class="btn btn-sm btn-outline-primary">
                        <i class="fa fa-image me-1"></i>View Proof
                    </a>
                    <span v-else class="text-muted">N/A</span>
                </template>

                <template #cell(status)="data">
                    <b-badge :variant="getStatusVariant(data.item.status)" class="px-3 py-2">
                        {{ data.item.status.toUpperCase() }}
                    </b-badge>
                </template>

                <template #cell(submitted_at)="data">
                    {{ formatDate(data.item.created_at) }}
                </template>

                <template #cell(actions)="data">
                    <b-button
                        size="sm"
                        variant="info"
                        @click="viewDetail(data.item)"
                        class="me-1"
                    >
                        <i class="fa fa-eye me-1"></i>View
                    </b-button>
                    <!-- <b-button
                        v-if="data.item.status === 'pending'"
                        size="sm"
                        variant="success"
                        @click="quickApprove(data.item)"
                        class="me-1"
                    >
                        <i class="fa fa-check"></i>
                    </b-button>
                    <b-button
                        v-if="data.item.status === 'pending'"
                        size="sm"
                        variant="danger"
                        @click="quickReject(data.item)"
                    >
                        <i class="fa fa-times"></i>
                    </b-button> -->
                </template>
            </b-table>

            <!-- Pagination -->
            <b-row class="mt-3">
                <b-col>
                    <b-pagination
                        v-model="currentPage"
                        :total-rows="totalRows"
                        :per-page="perPage"
                        @change="onPageChange"
                        align="center"
                    ></b-pagination>
                </b-col>
            </b-row>
        </b-card>

        <!-- Detail Modal -->
        <b-modal
            v-model="showDetailModal"
            title="Payment Details"
            size="lg"
            hide-footer
        >
            <div v-if="selectedPayment">
                <h6 class="border-bottom pb-2 mb-3">Driver Information</h6>
                <b-row class="mb-3">
                    <b-col md="6">
                        <p><strong>Name:</strong> {{ selectedPayment.delivery_boy.name || 'N/A' }}</p>
                        <p><strong>Phone:</strong> {{ selectedPayment.delivery_boy.mobile || 'N/A' }}</p>
                    </b-col>
                    <b-col md="6">
                        <p><strong>ID:</strong> {{ selectedPayment.delivery_boy.id || 'N/A' }}</p>
                        <p><strong>Email:</strong> {{ selectedPayment.delivery_boy.email || 'N/A' }}</p>
                    </b-col>
                </b-row>

                <h6 class="border-bottom pb-2 mb-3">Payment Information</h6>
                <b-row class="mb-3">
                    <b-col md="6">
                        <p><strong>Submitted Amount:</strong> <span class="text-success">{{ $currency }}{{ parseFloat(selectedPayment.amount).toFixed(2) }}</span></p>
                        <p><strong>Transaction ID:</strong> <code>{{ selectedPayment.transaction_id }}</code></p>
                        <p><strong>Status:</strong> <b-badge :variant="getStatusVariant(selectedPayment.status)">{{ selectedPayment.status.toUpperCase() }}</b-badge></p>
                    </b-col>
                    <b-col md="6">
                        <p><strong>Unpaid Hand Cash:</strong> <span class="text-danger fw-bold">{{ $currency }}{{ parseFloat(selectedPayment.unpaid_hand_cash || 0).toFixed(2) }}</span></p>
                        <p><strong>Submitted:</strong> {{ formatDate(selectedPayment.created_at) }}</p>
                    </b-col>
                </b-row>

                <h6 class="border-bottom pb-2 mb-3">Proof Image</h6>
                <div class="text-center mb-3">
                    <img v-if="selectedPayment.proof_image" :src="getImageUrl(selectedPayment.proof_image)" class="img-fluid rounded" style="max-height: 400px;">
                    <p v-else class="text-muted">No proof image uploaded</p>
                </div>

                <div v-if="selectedPayment.admin_notes" class="mb-3">
                    <h6 class="border-bottom pb-2 mb-3">Admin Notes</h6>
                    <p class="alert alert-secondary">{{ selectedPayment.admin_notes }}</p>
                </div>

                <div v-if="selectedPayment.status === 'pending'" class="border-top pt-3">
                    <h6 class="mb-3">Actions</h6>
                    <b-form @submit.prevent="approvePayment">
                        <b-form-group label="Amount Received (₹)" label-for="amount-received" description="Enter the actual amount you received from the driver">
                            <b-form-input
                                id="amount-received"
                                v-model.number="amountReceived"
                                type="number"
                                step="0.01"
                                min="0"
                                placeholder="Enter amount received..."
                                required
                            ></b-form-input>
                        </b-form-group>
                        <b-form-group label="Admin Notes (Optional)" label-for="approve-notes">
                            <b-form-textarea
                                id="approve-notes"
                                v-model="approveNotes"
                                rows="3"
                                placeholder="Add notes about this approval..."
                            ></b-form-textarea>
                        </b-form-group>
                        <b-button type="submit" variant="success" class="me-2" :disabled="processing">
                            <i class="fa fa-check me-1"></i>
                            {{ processing ? 'Processing...' : 'Approve Payment' }}
                        </b-button>
                        <b-button variant="danger" @click="showRejectForm = true" :disabled="processing">
                            <i class="fa fa-times me-1"></i>Reject
                        </b-button>
                    </b-form>

                    <b-form v-if="showRejectForm" @submit.prevent="rejectPayment" class="mt-3 border-top pt-3">
                        <b-form-group label="Rejection Reason (Required)" label-for="reject-notes">
                            <b-form-textarea
                                id="reject-notes"
                                v-model="rejectNotes"
                                rows="3"
                                placeholder="Explain why this payment is being rejected..."
                                required
                            ></b-form-textarea>
                        </b-form-group>
                        <b-button type="submit" variant="danger" class="me-2" :disabled="processing">
                            <i class="fa fa-times me-1"></i>
                            {{ processing ? 'Processing...' : 'Confirm Rejection' }}
                        </b-button>
                        <b-button variant="secondary" @click="showRejectForm = false" :disabled="processing">
                            Cancel
                        </b-button>
                    </b-form>
                </div>
            </div>
        </b-modal>
    </div>
</template>

<script>
import _ from 'lodash';

export default {
    name: 'ManualPayments',
    data() {
        return {
            isLoading: true,
            processing: false,
            payments: [],
            summary: {
                pending_count: 0,
                pending_amount: 0,
                approved_count: 0,
                approved_amount: 0,
                rejected_count: 0,
                rejected_amount: 0,
                total_count: 0,
                total_amount: 0,
            },
            filters: {
                status: 'all',
                search: '',
            },
            statusOptions: [
                { value: 'all', text: 'All Payments' },
                { value: 'pending', text: 'Pending Only' },
                { value: 'approved', text: 'Approved Only' },
                { value: 'rejected', text: 'Rejected Only' },
            ],
            fields: [
                { key: 'id', label: 'ID', sortable: true },
                { key: 'driver', label: 'Driver', sortable: false },
                { key: 'amount', label: 'Amount', sortable: true },
                { key: 'transaction_id', label: 'Transaction ID', sortable: false },
                { key: 'proof_image', label: 'Proof', sortable: false },
                { key: 'status', label: 'Status', sortable: true },
                { key: 'submitted_at', label: 'Submitted', sortable: true },
                { key: 'actions', label: 'Actions' },
            ],
            currentPage: 1,
            perPage: 20,
            totalRows: 0,
            showDetailModal: false,
            selectedPayment: null,
            approveNotes: '',
            rejectNotes: '',
            amountReceived: 0,
            showRejectForm: false,
        };
    },
    mounted() {
        this.fetchPayments();
        this.debouncedFetch = _.debounce(this.fetchPayments, 500);
    },
    methods: {
        async fetchPayments() {
            this.isLoading = true;
            try {
                const params = {
                    status: this.filters.status,
                    search: this.filters.search,
                    page: this.currentPage,
                };

                const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/manual-payments', { params });

                if (response.data.success) {
                    this.payments = response.data.data.data;
                    this.totalRows = response.data.data.total;
                    this.currentPage = response.data.data.current_page;
                    this.calculateSummary();
                }
            } catch (error) {
                this.$toast.error('Failed to load payments');
                console.error(error);
            } finally {
                this.isLoading = false;
            }
        },
        calculateSummary() {
            // Calculate summary from current data
            this.summary = this.payments.reduce((acc, payment) => {
                const amount = parseFloat(payment.amount);
                acc.total_count++;
                acc.total_amount += amount;

                if (payment.status === 'pending') {
                    acc.pending_count++;
                    acc.pending_amount += amount;
                } else if (payment.status === 'approved') {
                    acc.approved_count++;
                    acc.approved_amount += amount;
                } else if (payment.status === 'rejected') {
                    acc.rejected_count++;
                    acc.rejected_amount += amount;
                }

                return acc;
            }, {
                pending_count: 0,
                pending_amount: 0,
                approved_count: 0,
                approved_amount: 0,
                rejected_count: 0,
                rejected_amount: 0,
                total_count: 0,
                total_amount: 0,
            });
        },
        resetFilters() {
            this.filters.status = 'all';
            this.filters.search = '';
            this.currentPage = 1;
            this.fetchPayments();
        },
        onPageChange(page) {
            this.currentPage = page;
            this.fetchPayments();
        },
        viewDetail(payment) {
            this.selectedPayment = payment;
            this.showDetailModal = true;
            this.showRejectForm = false;
            this.approveNotes = '';
            this.rejectNotes = '';
            this.amountReceived = parseFloat(payment.amount); // Initialize with submitted amount
        },
        async quickApprove(payment) {
            const amount = prompt(`Enter amount received from ${payment.delivery_boy.name}:`, payment.amount);
            if (!amount || amount === null || parseFloat(amount) <= 0) {
                return;
            }

            try {
                const response = await axios.post(
                    this.$apiUrl + `/admin/delivery-boys/manual-payments/${payment.id}/approve`,
                    {
                        admin_notes: '',
                        amount_received: parseFloat(amount)
                    }
                );

                if (response.data.success) {
                    this.$toast.success(response.data.message + ` | Settled: ${this.$currency}${response.data.settled_amount}`);
                    this.fetchPayments();
                }
            } catch (error) {
                this.$toast.error('Failed to approve payment');
                console.error(error);
            }
        },
        async quickReject(payment) {
            const reason = prompt(`Enter rejection reason for ${payment.delivery_boy.name}'s payment:`);
            if (!reason || reason.trim() === '') {
                return;
            }

            try {
                const response = await axios.post(
                    this.$apiUrl + `/admin/delivery-boys/manual-payments/${payment.id}/reject`,
                    { admin_notes: reason }
                );

                if (response.data.success) {
                    this.$toast.success(response.data.message);
                    this.fetchPayments();
                }
            } catch (error) {
                this.$toast.error('Failed to reject payment');
                console.error(error);
            }
        },
        async approvePayment() {
            if (!this.amountReceived || this.amountReceived <= 0) {
                this.$toast.error('Please enter a valid amount received');
                return;
            }

            this.processing = true;
            try {
                const response = await axios.post(
                    this.$apiUrl + `/admin/delivery-boys/manual-payments/${this.selectedPayment.id}/approve`,
                    {
                        admin_notes: this.approveNotes,
                        amount_received: this.amountReceived
                    }
                );

                if (response.data.success) {
                    this.$toast.success(response.data.message + ` | Settled: ${this.$currency}${response.data.settled_amount}`);
                    this.showDetailModal = false;
                    this.fetchPayments();
                }
            } catch (error) {
                this.$toast.error('Failed to approve payment');
                console.error(error);
            } finally {
                this.processing = false;
            }
        },
        async rejectPayment() {
            if (!this.rejectNotes || this.rejectNotes.trim() === '') {
                this.$toast.error('Rejection reason is required');
                return;
            }

            this.processing = true;
            try {
                const response = await axios.post(
                    this.$apiUrl + `/admin/delivery-boys/manual-payments/${this.selectedPayment.id}/reject`,
                    { admin_notes: this.rejectNotes }
                );

                if (response.data.success) {
                    this.$toast.success(response.data.message);
                    this.showDetailModal = false;
                    this.fetchPayments();
                }
            } catch (error) {
                this.$toast.error('Failed to reject payment');
                console.error(error);
            } finally {
                this.processing = false;
            }
        },
        getStatusVariant(status) {
            const variants = {
                pending: 'primary',
                approved: 'success',
                rejected: 'danger',
            };
            return variants[status] || 'secondary';
        },
        getImageUrl(path) {
            if (path.startsWith('http')) {
                return path;
            }
            return this.$apiUrl.replace('/api', '') + '/storage/' + path;
        },
        formatDate(dateString) {
            return new Date(dateString).toLocaleString();
        },
    },
};
</script>

<style scoped>
.fw-bold {
    font-weight: 600;
}

/* Custom styling for PENDING status badge */
.badge-primary {
    background-color: #ffffff !important;
    color: #28a745 !important;
    border: 1px solid #28a745 !important;
}

/* Custom styling for APPROVED status badge */
.badge-success {
    background-color: #ffffff !important;
    color: #28a745 !important;
    border: 1px solid #28a745 !important;
}

/* Custom styling for REJECTED status badge */
.badge-danger {
    background-color: #ffffff !important;
    color: #dc3545 !important;
    border: 1px solid #dc3545 !important;
}
</style>

<!-- Dark Mode Styles (unscoped to access body.theme-dark) -->
<style>
.theme-dark code {
    color: #e685b5;
    background-color: rgba(230, 133, 181, 0.1);
}
</style>