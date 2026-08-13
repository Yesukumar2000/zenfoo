<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Customer Details</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                            <li class="breadcrumb-item"><router-link to="/users">{{ __('customers') }}</router-link></li>
                            <li class="breadcrumb-item active" aria-current="page">Customer Details</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/users" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-body">
                            <!-- Account Deleted Alert -->
                            <div v-if="customer && customer.deleted_at" class="alert alert-danger mb-4" role="alert">
                                <div class="d-flex align-items-center justify-content-between">
                                    <div>
                                        <i class="fa fa-trash-alt me-2"></i>
                                        <strong>This customer account has been deleted.</strong>
                                    </div>
                                    <button class="btn btn-success btn-sm" @click="restoreUser" :disabled="isDeleting">
                                        <span v-if="isDeleting"><b-spinner small></b-spinner> Restoring...</span>
                                        <span v-else><i class="fa fa-undo me-1"></i> Restore Account</span>
                                    </button>
                                </div>
                                <div class="mt-2" v-if="customer.delete_reason">
                                    <strong>Reason:</strong> {{ customer.delete_reason }}
                                </div>
                                <div class="mt-1" v-if="customer.delete_requested_at">
                                    <small style="color: #fff; font-weight: bold;">Deleted on {{ formatDate(customer.delete_requested_at) }}</small>
                                </div>
                            </div>

                            <!-- Soft Delete Button (when not deleted) -->
                            <div v-else-if="customer" class="d-flex justify-content-end mb-3">
                                <button class="btn btn-outline-danger btn-sm" @click="softDeleteUser" :disabled="isDeleting">
                                    <span v-if="isDeleting"><b-spinner small></b-spinner> Deleting...</span>
                                    <span v-else><i class="fa fa-trash me-1"></i> Delete Account</span>
                                </button>
                            </div>

                            <!-- Tabs Navigation -->
                            <ul class="nav nav-tabs" id="customerTabs" role="tablist">
                                <li class="nav-item" role="presentation">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'details' }"
                                        @click="activeTab = 'details'"
                                        type="button">
                                        <i class="fa fa-user me-1"></i> Details
                                    </button>
                                </li>
                                <li class="nav-item" role="presentation">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'orders' }"
                                        @click="activeTab = 'orders'"
                                        type="button">
                                        <i class="fa fa-shopping-cart me-1"></i> Orders
                                    </button>
                                </li>
                                <li class="nav-item" role="presentation">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'returned-orders' }"
                                        @click="activeTab = 'returned-orders'"
                                        type="button">
                                        <i class="fa fa-undo me-1"></i> Returned Orders
                                    </button>
                                </li>
                                <li class="nav-item" role="presentation">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'support' }"
                                        @click="activeTab = 'support'"
                                        type="button">
                                        <i class="fa fa-headphones me-1"></i> Customer Support
                                    </button>
                                </li>
                                <li class="nav-item" role="presentation">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'analytics' }"
                                        @click="activeTab = 'analytics'"
                                        type="button">
                                        <i class="fa fa-chart-bar me-1"></i> Analytics
                                    </button>
                                </li>
                                <li class="nav-item" role="presentation">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'transactions' }"
                                        @click="activeTab = 'transactions'"
                                        type="button">
                                        <i class="fa fa-credit-card me-1"></i> Transactions
                                    </button>
                                </li>
                            </ul>

                            <!-- Tab Content -->
                            <div class="tab-content mt-4" id="customerTabsContent">
                                <!-- Details Tab -->
                                <div v-if="activeTab === 'details'" class="tab-pane fade show active">
                                    <customer-details :customer-id="customerId"></customer-details>
                                </div>

                                <!-- Orders Tab -->
                                <div v-if="activeTab === 'orders'" class="tab-pane fade show active">
                                    <customer-orders :customer-id="customerId"></customer-orders>
                                </div>

                                <!-- Returned Orders Tab -->
                                <div v-if="activeTab === 'returned-orders'" class="tab-pane fade show active">
                                    <customer-returned-orders :customer-id="customerId"></customer-returned-orders>
                                </div>

                                <!-- Customer Support Tab -->
                                <div v-if="activeTab === 'support'" class="tab-pane fade show active">
                                    <customer-support-tab :customer-id="customerId"></customer-support-tab>
                                </div>

                                <!-- Analytics Tab -->
                                <div v-if="activeTab === 'analytics'" class="tab-pane fade show active">
                                    <customer-analytics :customer-id="customerId"></customer-analytics>
                                </div>

                                <!-- Transactions Tab -->
                                <div v-if="activeTab === 'transactions'" class="tab-pane fade show active">
                                    <customer-transactions :customer-id="customerId"></customer-transactions>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import CustomerDetails from './Tabs/CustomerDetails.vue';
import CustomerOrders from './Tabs/CustomerOrders.vue';
import CustomerReturnedOrders from './Tabs/CustomerReturnedOrders.vue';
import CustomerSupportTab from './Tabs/CustomerSupportTab.vue';
import CustomerAnalytics from './Tabs/CustomerAnalytics.vue';
import CustomerTransactions from './Tabs/CustomerTransactions.vue';

export default {
    name: 'CustomerView',
    components: {
        'customer-details': CustomerDetails,
        'customer-orders': CustomerOrders,
        'customer-returned-orders': CustomerReturnedOrders,
        'customer-support-tab': CustomerSupportTab,
        'customer-analytics': CustomerAnalytics,
        'customer-transactions': CustomerTransactions
    },
    data() {
        return {
            customerId: null,
            activeTab: 'details',
            customer: null,
            isDeleting: false
        }
    },
    created() {
        this.customerId = this.$route.params.id;
        this.fetchCustomerBasicInfo();

        // Check if tab query parameter is set (e.g., from notification navigation)
        if (this.$route.query.tab) {
            this.activeTab = this.$route.query.tab;
        }
    },
    methods: {
        fetchCustomerBasicInfo() {
            axios.get(this.$apiUrl + '/customers/' + this.customerId)
                .then((response) => {
                    if (response.data.status === 1) {
                        this.customer = response.data.data;
                    }
                })
                .catch((error) => {
                    console.error('Error fetching customer info:', error);
                });
        },
        softDeleteUser() {
            if (!confirm('Are you sure you want to delete this customer account?')) return;

            this.isDeleting = true;
            axios.post(this.$apiUrl + '/user-account-deletion/soft-delete', {
                user_id: this.customerId
            })
            .then((response) => {
                if (response.data.status === 1) {
                    this.$toast.success(response.data.message);
                    this.fetchCustomerBasicInfo();
                } else {
                    this.$toast.error(response.data.message || 'Failed to delete customer account');
                }
                this.isDeleting = false;
            })
            .catch((error) => {
                console.error('Error deleting customer:', error);
                this.$toast.error('Failed to delete customer account');
                this.isDeleting = false;
            });
        },
        restoreUser() {
            if (!confirm('Are you sure you want to restore this customer account?')) return;

            this.isDeleting = true;
            axios.post(this.$apiUrl + '/user-account-deletion/restore', {
                user_id: this.customerId
            })
            .then((response) => {
                if (response.data.status === 1) {
                    this.$toast.success(response.data.message);
                    this.fetchCustomerBasicInfo();
                } else {
                    this.$toast.error(response.data.message || 'Failed to restore customer account');
                }
                this.isDeleting = false;
            })
            .catch((error) => {
                console.error('Error restoring customer:', error);
                this.$toast.error('Failed to restore customer account');
                this.isDeleting = false;
            });
        },
        formatDate(dateStr) {
            if (!dateStr) return '';
            const date = new Date(dateStr);
            return date.toLocaleDateString('en-IN', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
        }
    }
}
</script>

<style scoped>
.nav-tabs .nav-link {
    color: #6c757d;
    border: none;
    border-bottom: 2px solid transparent;
    padding: 0.75rem 1.25rem;
    font-weight: 500;
}

.nav-tabs .nav-link:hover {
    color: #9AC444;
    border-bottom: 2px solid #9AC444;
}

.nav-tabs .nav-link.active {
    color: #9AC444;
    background-color: transparent;
    border-bottom: 2px solid #9AC444;
}

.tab-content {
    min-height: 300px;
}

/* Statistics Cards */
.stat-card {
    display: flex;
    align-items: center;
    padding: 20px;
    border-radius: 10px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.stat-icon {
    font-size: 2.5rem;
    margin-right: 15px;
    opacity: 0.8;
}

.stat-details h3 {
    margin: 0;
    font-size: 1.5rem;
    font-weight: 600;
}

.stat-details p {
    margin: 0;
    font-size: 0.875rem;
    opacity: 0.9;
}

.card-header h5 {
    font-weight: 600;
}

.table-borderless td {
    padding: 8px 0;
}
</style>
