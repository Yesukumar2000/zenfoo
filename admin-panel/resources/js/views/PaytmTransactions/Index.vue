<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>{{ __('paytm_transactions') }}</h3>
                        <p class="text-subtitle text-muted">{{ __('manage_paytm_payment_transactions') }}</p>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item">
                                    <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                                </li>
                                <li class="breadcrumb-item active" aria-current="page">{{ __('paytm_transactions') }}</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <!-- Statistics Cards -->
            <div class="row mb-4" v-if="statistics">
                <div class="col-md-3 col-sm-6 mb-3">
                    <div class="card">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <h6 class="text-muted mb-2">Total Transactions</h6>
                                    <h4 class="mb-0">{{ statistics.total_transactions }}</h4>
                                </div>
                                <div class="avatar bg-light-primary p-3">
                                    <i class="fa fa-list text-primary fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 col-sm-6 mb-3">
                    <div class="card">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <h6 class="text-muted mb-2">Total Amount</h6>
                                    <h4 class="mb-0">{{ $currency }}{{ formatNumber(statistics.total_amount) }}</h4>
                                </div>
                                <div class="avatar bg-light-success p-3">
                                    <i class="fa fa-money text-success fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 col-sm-6 mb-3">
                    <div class="card">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <h6 class="text-muted mb-2">Successful</h6>
                                    <h4 class="mb-0 text-success">{{ statistics.successful_count }}</h4>
                                </div>
                                <div class="avatar bg-light-success p-3">
                                    <i class="fa fa-check-circle text-success fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 col-sm-6 mb-3">
                    <div class="card">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <h6 class="text-muted mb-2">Success Rate</h6>
                                    <h4 class="mb-0">{{ statistics.success_rate }}%</h4>
                                </div>
                                <div class="avatar bg-light-info p-3">
                                    <i class="fa fa-chart-line text-info fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Filters -->
            <div class="card mb-4">
                <div class="card-header">
                    <h5 class="card-title mb-0">
                        <i class="fa fa-filter me-2"></i>Filters
                    </h5>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-3 mb-3">
                            <label>Search</label>
                            <input type="text" class="form-control" v-model="filters.search" placeholder="Transaction ID, Bank ID..." @input="debouncedSearch">
                        </div>
                        <div class="col-md-2 mb-3">
                            <label>Status</label>
                            <select class="form-select" v-model="filters.status" @change="loadTransactions">
                                <option value="">All</option>
                                <option value="success">Success</option>
                                <option value="failed">Failed</option>
                                <option value="pending">Pending</option>
                            </select>
                        </div>
                        <div class="col-md-2 mb-3">
                            <label>Type</label>
                            <select class="form-select" v-model="filters.type_of_payment" @change="loadTransactions">
                                <option value="">All</option>
                                <option value="order_placing">Order Placing</option>
                                <option value="wallet_topup">Wallet Topup</option>
                            </select>
                        </div>
                        <div class="col-md-2 mb-3">
                            <label>Captured</label>
                            <select class="form-select" v-model="filters.is_captured" @change="loadTransactions">
                                <option value="">All</option>
                                <option value="1">Yes</option>
                                <option value="0">No</option>
                            </select>
                        </div>
                        <div class="col-md-3 mb-3">
                            <label>Start Date</label>
                            <input type="date" class="form-control" v-model="filters.start_date" @change="loadTransactions">
                        </div>
                        <div class="col-md-3 mb-3">
                            <label>End Date</label>
                            <input type="date" class="form-control" v-model="filters.end_date" @change="loadTransactions">
                        </div>
                        <div class="col-md-3 mb-3 d-flex align-items-end">
                            <button class="btn btn-secondary me-2" @click="clearFilters">
                                <i class="fa fa-times me-1"></i>Clear Filters
                            </button>
                            <button class="btn btn-success" @click="exportTransactions">
                                <i class="fa fa-download me-1"></i>Export CSV
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Transactions Table -->
            <section class="section">
                <div class="card">
                    <div class="card-body">
                        <div v-if="loading" class="text-center py-5">
                            <b-spinner class="align-middle"></b-spinner>
                            <strong class="ms-2">Loading transactions...</strong>
                        </div>

                        <div v-else>
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <thead>
                                        <tr>
                                            <th>ID</th>
                                            <th>Transaction ID</th>
                                            <th>Customer</th>
                                            <th>Amount</th>
                                            <th>Payment Mode</th>
                                            <th>Status</th>
                                            <th>Type</th>
                                            <th>Captured</th>
                                            <th>Date</th>
                                            <th>Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-if="transactions.length === 0">
                                            <td colspan="10" class="text-center py-4">
                                                <i class="fa fa-inbox fa-3x text-muted mb-3"></i>
                                                <p class="text-muted">No transactions found</p>
                                            </td>
                                        </tr>
                                        <tr v-for="transaction in transactions" :key="transaction.id">
                                            <td>{{ transaction.id }}</td>
                                            <td>
                                                <small class="text-muted">{{ transaction.txn_id }}</small><br>
                                                <small v-if="transaction.paytm_txn_id" class="badge bg-light-secondary">
                                                    Paytm: {{ transaction.paytm_txn_id }}
                                                </small>
                                            </td>
                                            <td>
                                                <div v-if="transaction.user">
                                                    <strong>{{ transaction.user.name }}</strong><br>
                                                    <small class="text-muted">{{ transaction.user.email }}</small>
                                                </div>
                                                <span v-else class="text-muted">N/A</span>
                                            </td>
                                            <td>
                                                <strong>{{ $currency }}{{ formatNumber(transaction.amount) }}</strong>
                                            </td>
                                            <td>
                                                <span class="badge bg-light-info">{{ transaction.payment_mode || 'N/A' }}</span>
                                                <br><small class="text-muted">{{ transaction.bank_name || '' }}</small>
                                            </td>
                                            <td>
                                                <span :class="getStatusBadgeClass(transaction.status)">
                                                    {{ transaction.status }}
                                                </span>
                                            </td>
                                            <td>
                                                <span class="badge" :class="transaction.type_of_payment === 'order_placing' ? 'bg-primary' : 'bg-warning'">
                                                    {{ transaction.type_of_payment }}
                                                </span>
                                            </td>
                                            <td>
                                                <span v-if="transaction.is_captured" class="badge bg-success">
                                                    <i class="fa fa-check"></i> Yes
                                                </span>
                                                <span v-else class="badge bg-danger">
                                                    <i class="fa fa-times"></i> No
                                                </span>
                                            </td>
                                            <td>
                                                <small>{{ formatDate(transaction.transaction_date) }}</small>
                                            </td>
                                            <td>
                                                <button class="btn btn-sm btn-info" @click="viewDetails(transaction)">
                                                    <i class="fa fa-eye"></i>
                                                </button>
                                            </td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>

                            <!-- Pagination -->
                            <div class="d-flex justify-content-between align-items-center mt-3" v-if="pagination.total > 0">
                                <div>
                                    <span class="text-muted">
                                        Showing {{ pagination.from }} to {{ pagination.to }} of {{ pagination.total }} entries
                                    </span>
                                </div>
                                <nav>
                                    <ul class="pagination mb-0">
                                        <li class="page-item" :class="{ disabled: pagination.current_page === 1 }">
                                            <a class="page-link" href="#" @click.prevent="changePage(pagination.current_page - 1)">Previous</a>
                                        </li>
                                        <li class="page-item" v-for="page in paginationPages" :key="page" :class="{ active: page === pagination.current_page }">
                                            <a class="page-link" href="#" @click.prevent="changePage(page)">{{ page }}</a>
                                        </li>
                                        <li class="page-item" :class="{ disabled: pagination.current_page === pagination.last_page }">
                                            <a class="page-link" href="#" @click.prevent="changePage(pagination.current_page + 1)">Next</a>
                                        </li>
                                    </ul>
                                </nav>
                            </div>
                        </div>
                    </div>
                </div>
            </section>
        </div>

        <!-- Transaction Details Modal -->
        <b-modal v-model="showDetailsModal" title="Transaction Details" size="lg" hide-footer>
            <div v-if="selectedTransaction">
                <div class="row mb-3">
                    <div class="col-md-6">
                        <h6 class="text-muted mb-2">Transaction Information</h6>
                        <table class="table table-sm">
                            <tr>
                                <th>ID:</th>
                                <td>{{ selectedTransaction.id }}</td>
                            </tr>
                            <tr>
                                <th>Our Txn ID:</th>
                                <td><code>{{ selectedTransaction.txn_id }}</code></td>
                            </tr>
                            <tr>
                                <th>Paytm Txn ID:</th>
                                <td><code>{{ selectedTransaction.paytm_txn_id }}</code></td>
                            </tr>
                            <tr>
                                <th>Bank Txn ID:</th>
                                <td><code>{{ selectedTransaction.bank_txn_id }}</code></td>
                            </tr>
                            <tr>
                                <th>Status:</th>
                                <td><span :class="getStatusBadgeClass(selectedTransaction.status)">{{ selectedTransaction.status }}</span></td>
                            </tr>
                            <tr>
                                <th>Response Code:</th>
                                <td>{{ selectedTransaction.response_code }}</td>
                            </tr>
                            <tr>
                                <th>Response Msg:</th>
                                <td>{{ selectedTransaction.response_msg }}</td>
                            </tr>
                        </table>
                    </div>
                    <div class="col-md-6">
                        <h6 class="text-muted mb-2">Payment Details</h6>
                        <table class="table table-sm">
                            <tr>
                                <th>Amount:</th>
                                <td><strong>{{ $currency }}{{ formatNumber(selectedTransaction.amount) }}</strong></td>
                            </tr>
                            <tr>
                                <th>Payment Mode:</th>
                                <td>{{ selectedTransaction.payment_mode }}</td>
                            </tr>
                            <tr>
                                <th>Bank Name:</th>
                                <td>{{ selectedTransaction.bank_name }}</td>
                            </tr>
                            <tr>
                                <th>Gateway:</th>
                                <td>{{ selectedTransaction.gateway_name }}</td>
                            </tr>
                            <tr>
                                <th>Captured:</th>
                                <td>
                                    <span v-if="selectedTransaction.is_captured" class="badge bg-success">Yes</span>
                                    <span v-else class="badge bg-danger">No</span>
                                </td>
                            </tr>
                            <tr>
                                <th>Type:</th>
                                <td><span class="badge bg-primary">{{ selectedTransaction.type_of_payment }}</span></td>
                            </tr>
                            <tr>
                                <th>Transaction Date:</th>
                                <td>{{ formatDate(selectedTransaction.transaction_date) }}</td>
                            </tr>
                        </table>
                    </div>
                </div>
                <div class="row" v-if="selectedTransaction.user">
                    <div class="col-12">
                        <h6 class="text-muted mb-2">Customer Information</h6>
                        <table class="table table-sm">
                            <tr>
                                <th>Name:</th>
                                <td>{{ selectedTransaction.user.name }}</td>
                            </tr>
                            <tr>
                                <th>Email:</th>
                                <td>{{ selectedTransaction.user.email }}</td>
                            </tr>
                            <tr>
                                <th>Mobile:</th>
                                <td>{{ selectedTransaction.user.mobile }}</td>
                            </tr>
                        </table>
                    </div>
                </div>
            </div>
        </b-modal>
    </div>
</template>

<script>
export default {
    name: 'PaytmTransactions',
    data() {
        return {
            loading: false,
            transactions: [],
            statistics: null,
            pagination: {
                current_page: 1,
                last_page: 1,
                per_page: 25,
                total: 0,
                from: 0,
                to: 0
            },
            filters: {
                search: '',
                status: '',
                type_of_payment: '',
                is_captured: '',
                start_date: '',
                end_date: '',
                user_id: ''
            },
            selectedTransaction: null,
            showDetailsModal: false,
            searchTimeout: null
        };
    },
    computed: {
        paginationPages() {
            const pages = [];
            const current = this.pagination.current_page;
            const last = this.pagination.last_page;

            let start = Math.max(1, current - 2);
            let end = Math.min(last, current + 2);

            for (let i = start; i <= end; i++) {
                pages.push(i);
            }

            return pages;
        }
    },
    mounted() {
        this.loadTransactions();
    },
    methods: {
        async loadTransactions(page = 1) {
            this.loading = true;
            try {
                const params = {
                    page: page,
                    per_page: this.pagination.per_page,
                    ...this.filters
                };

                const response = await axios.get(this.$apiUrl + '/paytm_transactions', { params });

                if (response.data.status) {
                    const data = response.data.data;
                    this.transactions = data.transactions.data;
                    this.statistics = data.statistics;

                    this.pagination = {
                        current_page: data.transactions.current_page,
                        last_page: data.transactions.last_page,
                        per_page: data.transactions.per_page,
                        total: data.transactions.total,
                        from: data.transactions.from,
                        to: data.transactions.to
                    };
                }
            } catch (error) {
                this.$toast.error('Failed to load transactions');
                console.error(error);
            } finally {
                this.loading = false;
            }
        },

        debouncedSearch() {
            clearTimeout(this.searchTimeout);
            this.searchTimeout = setTimeout(() => {
                this.loadTransactions();
            }, 500);
        },

        changePage(page) {
            if (page >= 1 && page <= this.pagination.last_page) {
                this.loadTransactions(page);
            }
        },

        clearFilters() {
            this.filters = {
                search: '',
                status: '',
                type_of_payment: '',
                is_captured: '',
                start_date: '',
                end_date: '',
                user_id: ''
            };
            this.loadTransactions();
        },

        viewDetails(transaction) {
            this.selectedTransaction = transaction;
            this.showDetailsModal = true;
        },

        async exportTransactions() {
            try {
                const params = new URLSearchParams(this.filters).toString();
                window.open(this.$apiUrl + '/paytm_transactions/export/csv?' + params, '_blank');
            } catch (error) {
                this.$toast.error('Failed to export transactions');
                console.error(error);
            }
        },

        getStatusBadgeClass(status) {
            const statusMap = {
                'success': 'badge bg-success',
                'failed': 'badge bg-danger',
                'pending': 'badge bg-warning'
            };
            return statusMap[status] || 'badge bg-secondary';
        },

        formatNumber(number) {
            return parseFloat(number).toFixed(2);
        },

        formatDate(date) {
            if (!date) return 'N/A';
            return new Date(date).toLocaleString();
        }
    }
};
</script>

<style scoped>
.avatar {
    width: 50px;
    height: 50px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
}

.table th {
    font-weight: 600;
    font-size: 0.85rem;
}

.table-hover tbody tr:hover {
    background-color: rgba(0, 0, 0, 0.02);
}
</style>
