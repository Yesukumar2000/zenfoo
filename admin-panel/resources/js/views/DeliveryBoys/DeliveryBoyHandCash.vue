<template>
    <div class="p-3">
        <h5>Hand Cash</h5>
        <p class="text-muted">View cash collection details for this delivery boy.</p>
        <hr>

        <!-- Loading State -->
        <div class="text-center py-4" v-if="isLoading">
            <b-spinner class="align-middle"></b-spinner>
            <strong class="ms-2">Loading transactions...</strong>
        </div>

        <!-- Transactions Content -->
        <div v-else-if="transactions.length > 0">
            <!-- Summary Cards -->
            <div class="row mb-4">
                <div class="col-md-4 col-sm-6 mb-2">
                    <div class="card bg-info text-white">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Total Admin Cash</h6>
                            <h4 class="mb-0">{{ $currency }} {{ totalAdminCash }}</h4>
                        </div>
                    </div>
                </div>
                <div class="col-md-4 col-sm-6 mb-2">
                    <div class="card bg-warning text-dark">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Pending Settlement</h6>
                            <h4 class="mb-0">{{ $currency }} {{ pendingSettlement }}</h4>
                        </div>
                    </div>
                </div>
                <div class="col-md-4 col-sm-6 mb-2">
                    <div class="card bg-success text-white">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Settled Amount</h6>
                            <h4 class="mb-0">{{ $currency }} {{ settledAmount }}</h4>
                        </div>
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

                    <template #cell(order_id)="row">
                        <router-link v-if="row.item.order_id" :to="{ name: 'ViewOrder', params: { id: row.item.order_id }}">
                            #{{ row.item.order_id }}
                        </router-link>
                        <span v-else>-</span>
                    </template>

                    <template #cell(transaction_date)="row">
                        {{ formatDateTime(row.item.transaction_date) }}
                    </template>

                    <template #cell(admin_cash)="row">
                        <span class="text-danger fw-bold">{{ $currency }} {{ parseFloat(row.item.admin_cash || 0).toFixed(2) }}</span>
                    </template>

                    <template #cell(settled_with_admin)="row">
                        <span v-if="row.item.settled_with_admin" class="badge bg-success">
                            Settled
                        </span>
                        <span v-else class="badge bg-warning text-dark">
                            Pending
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
                        label-for="transactions-per-page"
                        label-size="sm"
                        class="mb-0">
                        <b-form-select
                            id="transactions-per-page"
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
            <i class="fa fa-money-bill-wave fa-3x text-muted mb-3"></i>
            <p>No hand cash transactions found for this delivery boy.</p>
        </div>
    </div>
</template>

<script>
export default {
    name: 'DeliveryBoyHandCash',
    props: {
        deliveryBoyId: {
            type: [Number, String],
            required: true
        }
    },
    data() {
        return {
            transactions: [],
            isLoading: false,
            isLoaded: false,
            currentPage: 1,
            perPage: 10,
            transactionFields: [
                { key: 'order_id', label: 'Order ID', sortable: true, class: 'text-center' },
                { key: 'transaction_date', label: 'Date', sortable: true, class: 'text-center' },
                { key: 'admin_cash', label: 'Admin Cash', sortable: true, class: 'text-center' },
                { key: 'settled_with_admin', label: 'Settled with Admin', sortable: true, class: 'text-center' },
                { key: 'settled_at', label: 'Settled At', sortable: true, class: 'text-center' }
            ]
        };
    },
    computed: {
        totalAdminCash() {
            let total = 0;
            this.transactions.forEach(transaction => {
                total += parseFloat(transaction.admin_cash || 0);
            });
            return total.toFixed(2);
        },
        pendingSettlement() {
            let total = 0;
            this.transactions.forEach(transaction => {
                if (!transaction.settled_with_admin) {
                    total += parseFloat(transaction.admin_cash || 0);
                }
            });
            return total.toFixed(2);
        },
        settledAmount() {
            let total = 0;
            this.transactions.forEach(transaction => {
                if (transaction.settled_with_admin) {
                    total += parseFloat(transaction.admin_cash || 0);
                }
            });
            return total.toFixed(2);
        }
    },
    mounted() {
        this.loadTransactions();
    },
    methods: {
        loadTransactions() {
            if (this.isLoaded) return;

            this.isLoading = true;

            axios.get(this.$apiUrl + '/delivery_boys/' + this.deliveryBoyId + '/hand-cash')
                .then((response) => {
                    this.isLoading = false;
                    this.isLoaded = true;
                    if (response.data.status === 1) {
                        this.transactions = response.data.data || [];
                    } else {
                        this.transactions = [];
                    }
                })
                .catch(() => {
                    this.isLoading = false;
                    this.isLoaded = true;
                    this.transactions = [];
                });
        },
        formatDateTime(dateString) {
            if (!dateString) return '-';
            const date = new Date(dateString);
            return date.toLocaleDateString('en-GB') + ' ' + date.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
        }
    }
};
</script>

<style scoped>
.fw-bold {
    font-weight: bold;
}
</style>
