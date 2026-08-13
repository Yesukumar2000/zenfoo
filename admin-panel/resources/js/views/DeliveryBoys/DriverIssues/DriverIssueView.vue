<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>Issue Details #{{ issueId }}</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item"><router-link to="/delivery-boys/issues">Driver Issues</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">View Issue</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/delivery-boys/issues" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <section class="section">
                <!-- Loading State -->
                <div v-if="isLoading" class="text-center py-5">
                    <b-spinner></b-spinner>
                    <p class="mt-2">Loading issue details...</p>
                </div>

                <!-- Error State -->
                <div v-else-if="!issue" class="text-center py-5">
                    <i class="fa fa-exclamation-circle fa-3x text-muted mb-3"></i>
                    <p class="text-muted">Issue not found</p>
                    <router-link to="/delivery-boys/issues" class="btn btn-primary">
                        <i class="fa fa-arrow-left me-1"></i> Back to Issues
                    </router-link>
                </div>

                <!-- Issue Details -->
                <div v-else>
                    <div class="row">
                        <!-- Left Column - Issue Info -->
                        <div class="col-lg-8">
                            <!-- Basic Info Card -->
                            <div class="card mb-4">
                                <div class="card-header d-flex justify-content-between align-items-center">
                                    <h5 class="mb-0">
                                        <i class="fa fa-info-circle me-2"></i>Issue Information
                                    </h5>
                                    <span class="badge" :class="getStatusBadgeClass(issue.status)">
                                        {{ issue.status }}
                                    </span>
                                </div>
                                <div class="card-body">
                                    <div class="row">
                                        <div class="col-md-6 mb-3">
                                            <label class="text-muted small">Issue Type</label>
                                            <p class="mb-0 fw-bold">
                                                <span class="badge bg-secondary">{{ formatIssueType(issue.issue_type) }}</span>
                                            </p>
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label class="text-muted small">Submitted On</label>
                                            <p class="mb-0">{{ formatDate(issue.created_at) }}</p>
                                        </div>
                                    </div>

                                    <!-- Extra Floating Deposited specific fields -->
                                    <div v-if="issue.issue_type === 'extra_floating_deposited' || issue.issue_type === 'cash_deposit_issue'" class="row">
                                        <div class="col-md-6 mb-3">
                                            <label class="text-muted small">Amount</label>
                                            <p class="mb-0 fw-bold text-success" v-if="issue.amount">
                                                {{ $currency }}{{ issue.amount }}
                                            </p>
                                            <p class="mb-0 text-muted" v-else>-</p>
                                        </div>
                                        <div class="col-md-6 mb-3">
                                            <label class="text-muted small">Payment Type</label>
                                            <p class="mb-0" v-if="issue.pay_type">
                                                <span class="badge" :class="issue.pay_type === 'upi' ? 'bg-info' : 'bg-primary'">
                                                    {{ issue.pay_type.toUpperCase() }}
                                                </span>
                                            </p>
                                            <p class="mb-0 text-muted" v-else>-</p>
                                        </div>
                                    </div>

                                    <div v-if="issue.description" class="mb-3">
                                        <label class="text-muted small">Description</label>
                                        <p class="mb-0">{{ issue.description }}</p>
                                    </div>

                                    <!-- Order IDs (for order_earning, multi_order, pocketing_issue) -->
                                    <div v-if="hasOrderIds && issue.issue_ids && issue.issue_ids.length" class="mb-3">
                                        <label class="text-muted small">Related Orders</label>
                                        <div>
                                            <router-link
                                                v-for="orderId in issue.issue_ids"
                                                :key="orderId"
                                                :to="'/orders/view/' + orderId"
                                                class="badge bg-primary me-1 mb-1 text-decoration-none">
                                                #{{ orderId }}
                                            </router-link>
                                        </div>
                                    </div>

                                    <!-- Attachments -->
                                    <div v-if="issue.attachments && issue.attachments.length" class="mb-3">
                                        <label class="text-muted small">Attachments</label>
                                        <div class="d-flex flex-wrap gap-2 mt-1">
                                            <a v-for="(attachment, index) in issue.attachments"
                                               :key="index"
                                               :href="attachment"
                                               target="_blank"
                                               class="attachment-thumb">
                                                <img :src="attachment" alt="Attachment" class="img-thumbnail" style="max-width: 120px; max-height: 120px;">
                                            </a>
                                        </div>
                                    </div>

                                    <!-- Admin Message (if responded) -->
                                    <div v-if="issue.admin_message" class="mt-3 p-3 admin-response-box rounded">
                                        <label class="text-muted small">Admin Response</label>
                                        <p class="mb-0">{{ issue.admin_message }}</p>
                                    </div>
                                </div>
                            </div>

                            <!-- Transaction Details Card (for incorrect_payout, incentive) -->
                            <div v-if="hasTransactionDetails && issue.issue_ids && issue.issue_ids.length" class="card mb-4">
                                <div class="card-header">
                                    <h5 class="mb-0">
                                        <i class="fa fa-money me-2"></i>Transaction Details
                                    </h5>
                                </div>
                                <div class="card-body">
                                    <div v-if="isLoadingTransactions" class="text-center py-3">
                                        <b-spinner small></b-spinner>
                                        <span class="ms-2">Loading transactions...</span>
                                    </div>
                                    <div v-else-if="transactions.length" class="table-responsive">
                                        <table class="table table-sm table-bordered mb-0">
                                            <thead class="table-light">
                                                <tr>
                                                    <th>ID</th>
                                                    <th>Order</th>
                                                    <th>Type</th>
                                                    <th>Amount</th>
                                                    <th>Delivery Charge</th>
                                                    <th>Delivery Tip</th>
                                                    <!-- <th>Bonus</th> -->
                                                    <th>Driver Earnings</th>
                                                    <th>Admin Cash</th>
                                                    <th>Status</th>
                                                    <th>Hand Cash</th>
                                                    <th>Payout Ref</th>
                                                    <th>Settled At</th>
                                                    <th>Transaction Date</th>
                                                    <th>Message</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <tr v-for="txn in transactions" :key="txn.id">
                                                    <td>#{{ txn.id }}</td>
                                                    <td>
                                                        <router-link v-if="txn.order_id" :to="'/orders/view/' + txn.order_id" class="text-primary">
                                                            #{{ txn.order_id }}
                                                        </router-link>
                                                        <span v-else class="text-muted">-</span>
                                                    </td>
                                                    <td><span class="badge bg-secondary">{{ txn.type }}</span></td>
                                                    <td>{{ $currency }}{{ txn.amount }}</td>
                                                    <td>{{ $currency }}{{ txn.delivery_charge }}</td>
                                                    <td>{{ $currency }}{{ txn.delivery_tip }}</td>
                                                    <!-- <td>{{ $currency }}{{ txn.bonus_amount }}</td> -->
                                                    <td>{{ $currency }}{{ txn.driver_earnings }}</td>
                                                    <td>{{ $currency }}{{ txn.admin_cash }}</td>
                                                    <td>
                                                        <span class="badge" :class="txn.status === 'success' ? 'bg-success' : 'bg-warning text-dark'">
                                                            {{ txn.status }}
                                                        </span>
                                                    </td>
                                                    <td>
                                                        <span class="badge" :class="txn.is_hand_cash ? 'bg-info' : 'bg-secondary'">
                                                            {{ txn.is_hand_cash ? 'Yes' : 'No' }}
                                                        </span>
                                                    </td>
                                                    <td>{{ txn.payout_reference || '-' }}</td>
                                                    <td>{{ txn.settled_at ? formatDate(txn.settled_at) : '-' }}</td>
                                                    <td>{{ formatDate(txn.transaction_date || txn.created_at) }}</td>
                                                    <td>{{ txn.message || '-' }}</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                    <div v-else class="text-muted text-center py-3">
                                        No transaction details found
                                    </div>
                                </div>
                            </div>

                            <!-- Respond Card - Only show when issue is not resolved -->
                            <div class="card" v-if="issue.status !== 'resolved'">
                                <div class="card-header">
                                    <h5 class="mb-0">
                                        <i class="fa fa-reply me-2"></i>Respond to Issue
                                    </h5>
                                </div>
                                <div class="card-body">
                                    <div class="row">
                                        <div class="col-md-4 mb-3">
                                            <label class="form-label">Status</label>
                                            <select v-model="respondForm.status" class="form-control form-select">
                                                <option value="pending">Pending</option>
                                                <option value="resolved">Resolved</option>
                                                <option value="rejected">Rejected</option>
                                            </select>
                                        </div>
                                        <div class="col-md-8 mb-3">
                                            <label class="form-label">Admin Message</label>
                                            <textarea v-model="respondForm.admin_message" class="form-control dark-textarea" rows="3" placeholder="Enter your response message..."></textarea>
                                        </div>
                                    </div>
                                    <div class="d-flex gap-2">
                                        <button class="btn btn-primary" @click="submitResponse" :disabled="isSubmitting">
                                            <span v-if="isSubmitting"><i class="fa fa-spinner fa-spin me-1"></i> Saving...</span>
                                            <span v-else><i class="fa fa-save me-1"></i> Save Response</span>
                                        </button>
                                        <router-link to="/delivery-boys/issues" class="btn btn-secondary">
                                            <i class="fa fa-arrow-left me-1"></i> Back
                                        </router-link>
                                    </div>
                                </div>
                            </div>

                            <!-- Back Button - Only show when issue is resolved -->
                            <div v-else class="d-flex">
                                <router-link to="/delivery-boys/issues" class="btn btn-secondary">
                                    <i class="fa fa-arrow-left me-1"></i> Back
                                </router-link>
                            </div>
                        </div>

                        <!-- Right Column - Driver Info -->
                        <div class="col-lg-4">
                            <div class="card mb-4">
                                <div class="card-header">
                                    <h5 class="mb-0">
                                        <i class="fa fa-user me-2"></i>Driver Information
                                    </h5>
                                </div>
                                <div class="card-body" v-if="issue.delivery_boy">
                                    <div class="text-center mb-3">
                                        <img v-if="issue.delivery_boy.profile_image_url"
                                             :src="issue.delivery_boy.profile_image_url"
                                             alt="Driver"
                                             class="rounded-circle mb-2"
                                             style="width: 80px; height: 80px; object-fit: cover;">
                                        <div v-else class="rounded-circle bg-secondary d-inline-flex align-items-center justify-content-center mb-2" style="width: 80px; height: 80px;">
                                            <i class="fa fa-user fa-2x text-white"></i>
                                        </div>
                                        <h5 class="mb-0">{{ issue.delivery_boy.name }}</h5>
                                        <small class="text-muted">Driver ID: #{{ issue.delivery_boy.id }}</small>
                                    </div>

                                    <hr>

                                    <div class="mb-3">
                                        <label class="text-muted small">Mobile</label>
                                        <p class="mb-0">
                                            <a :href="'tel:' + issue.delivery_boy.mobile" class="text-primary">
                                                <i class="fa fa-phone me-1"></i>{{ issue.delivery_boy.mobile }}
                                            </a>
                                        </p>
                                    </div>

                                    <div v-if="issue.delivery_boy.city" class="mb-3">
                                        <label class="text-muted small">City</label>
                                        <p class="mb-0">{{ issue.delivery_boy.city.name }}</p>
                                    </div>

                                    <div v-if="issue.delivery_boy.email" class="mb-3">
                                        <label class="text-muted small">Email</label>
                                        <p class="mb-0">{{ issue.delivery_boy.email }}</p>
                                    </div>

                                    <hr>

                                    <!-- Contact Actions -->
                                    <div class="d-grid gap-2">
                                        <!-- <a :href="'tel:' + issue.delivery_boy.mobile" class="btn btn-outline-primary">
                                            <i class="fa fa-phone me-1"></i> Call Driver
                                        </a> -->
                                        <a :href="'https://wa.me/91' + issue.delivery_boy.mobile.replace(/^0+/, '')"
                                           target="_blank"
                                           class="btn btn-outline-success">
                                            <i class="fab fa-whatsapp me-1"></i> WhatsApp
                                        </a>
                                        <router-link :to="'/delivery_boys/view/' + issue.delivery_boy.id" class="btn btn-outline-secondary">
                                            <i class="fa fa-eye me-1"></i> View Profile
                                        </router-link>
                                    </div>
                                </div>
                                <div v-else class="card-body text-center text-muted">
                                    Driver information not available
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    </div>
</template>

<script>
export default {
    name: 'DriverIssueView',
    data() {
        return {
            issueId: null,
            issue: null,
            isLoading: false,
            transactions: [],
            isLoadingTransactions: false,
            respondForm: {
                status: 'pending',
                admin_message: ''
            },
            isSubmitting: false
        }
    },
    computed: {
        hasOrderIds() {
            return ['order_earning', 'multi_order', 'pocketing_issue'].includes(this.issue?.issue_type);
        },
        hasTransactionDetails() {
            return ['incorrect_payout', 'incentive'].includes(this.issue?.issue_type);
        }
    },
    created() {
        this.issueId = this.$route.params.id;
        this.fetchIssue();
    },
    watch: {
        '$route.params.id': function(newId) {
            this.issueId = newId;
            this.fetchIssue();
        }
    },
    methods: {
        fetchIssue() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/admin/driver-issues-zenfoo/' + this.issueId)
                .then((response) => {
                    if (response.data.status === 1) {
                        this.issue = response.data.data;
                        this.respondForm.status = this.issue.status;
                        this.respondForm.admin_message = this.issue.admin_message || '';

                        // Load transactions for payout/incentive issues
                        if (this.hasTransactionDetails && this.issue.issue_ids?.length) {
                            this.fetchTransactions();
                        }
                    }
                    this.isLoading = false;
                })
                .catch((error) => {
                    console.error('Error fetching issue:', error);
                    this.isLoading = false;
                });
        },
        fetchTransactions() {
            if (!this.issue?.issue_ids?.length) return;
            this.isLoadingTransactions = true;
            axios.post(this.$apiUrl + '/admin/driver-issues-zenfoo/transactions', {
                ids: this.issue.issue_ids.map(id => parseInt(id))
            })
                .then((response) => {
                    if (response.data.status === 1) {
                        this.transactions = response.data.data;
                    }
                    this.isLoadingTransactions = false;
                })
                .catch((error) => {
                    console.error('Error fetching transactions:', error);
                    this.isLoadingTransactions = false;
                });
        },
        submitResponse() {
            this.isSubmitting = true;
            axios.post(this.$apiUrl + '/admin/driver-issues-zenfoo/' + this.issueId + '/respond', this.respondForm)
                .then((response) => {
                    if (response.data.status === 1) {
                        this.$toast.success('Response saved successfully');
                        this.fetchIssue();
                    } else {
                        this.$toast.error(response.data.message || 'Failed to save response');
                    }
                    this.isSubmitting = false;
                })
                .catch((error) => {
                    console.error('Error saving response:', error);
                    this.$toast.error('Failed to save response');
                    this.isSubmitting = false;
                });
        },
        formatDate(dateString) {
            if (!dateString) return '';
            const date = new Date(dateString);
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
        },
        formatIssueType(type) {
            const types = {
                'order_earning': 'Order Earning',
                'incorrect_payout': 'Incorrect Payout',
                'incentive': 'Incentive',
                'multi_order': 'Multi Order',
                'joining_bonus': 'Joining Bonus',
                'pocketing_issue': 'Pocketing Issue',
                'not_getting_order_issue': 'Not Getting Orders',
                'extra_floating_deposited': 'Extra Floating Deposited',
                'cash_deposit_issue': 'Cash Deposit Issue'
            };
            return types[type] || type;
        },
        getStatusBadgeClass(status) {
            const classes = {
                pending: 'bg-warning text-dark',
                resolved: 'bg-success',
                rejected: 'bg-danger'
            };
            return classes[status] || 'bg-secondary';
        }
    }
}
</script>

<style scoped>
.attachment-thumb img {
    transition: transform 0.2s;
}
.attachment-thumb img:hover {
    transform: scale(1.05);
}

/* Admin Response Box - Dark Mode Support */
.admin-response-box {
    background-color: #f8f9fa;
}

.theme-dark .admin-response-box {
    background-color: #2a2e33;
}

/* Textarea Dark Mode Support */
.theme-dark .dark-textarea {
    background-color: #2a2e33;
    border-color: #444;
    color: #e0e0e0;
}

.theme-dark .dark-textarea::placeholder {
    color: #888;
}

.theme-dark .form-select {
    background-color: #2a2e33;
    border-color: #444;
    color: #e0e0e0;
}
</style>
