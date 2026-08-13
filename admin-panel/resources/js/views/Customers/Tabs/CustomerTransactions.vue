<template>
    <div>
        <div class="row">
            <div class="col-12">
                <b-row class="mb-2">
                    <b-col md="3">
                        <b-form-input
                            v-model="filter"
                            type="search"
                            :placeholder="__('search')"
                            @input="onSearch"
                        ></b-form-input>
                    </b-col>
                    <b-col md="3">
                        <b-form-select
                            v-model="selectedType"
                            :options="typeOptions"
                            class="form-control form-select"
                            @change="onTypeChange"
                        ></b-form-select>
                    </b-col>
                    <b-col md="1">
                        <button class="btn btn-primary" @click="getTransactions()">
                            <i class="fa fa-refresh"></i>
                        </button>
                    </b-col>
                </b-row>

                <div class="table-responsive">
                    <b-table
                        :items="transactions"
                        :fields="fields"
                        :busy="isLoading"
                        :bordered="true"
                        stacked="md"
                        show-empty
                        small>
                        <template #table-busy>
                            <div class="text-center text-black my-2">
                                <b-spinner class="align-middle"></b-spinner>
                                <strong>{{ __('loading') }}...</strong>
                            </div>
                        </template>

                        <template #cell(sno)="row">
                            {{ (currentPage - 1) * perPage + row.index + 1 }}
                        </template>

                        <template #cell(transaction_category)="row">
                            <span class="badge" :class="getCategoryBadgeClass(row.item.transaction_category)">
                                {{ row.item.transaction_category === 'wallet' ? 'Wallet' : 'Payment' }}
                            </span>
                        </template>

                        <template #cell(payment_type)="row">
                            <span class="badge" :class="getPaymentTypeBadgeClass(row.item.payment_type)">
                                {{ formatPaymentType(row.item.payment_type) }}
                            </span>
                        </template>

                        <template #cell(amount)="row">
                            <span :class="getAmountClass(row.item)">
                                {{ $currency }}{{ row.item.amount }}
                            </span>
                        </template>

                        <template #cell(order_id)="row">
                            <router-link v-if="row.item.order_id && row.item.order_id != 0"
                                :to="'/orders/view/' + row.item.order_id"
                                class="text-primary">
                                #{{ row.item.order_id }}
                            </router-link>
                            <span v-else class="text-muted">-</span>
                        </template>

                        <template #cell(status)="row">
                            <span class="badge" :class="getStatusBadgeClass(row.item.status)">
                                {{ row.item.status }}
                            </span>
                        </template>

                        <template #cell(created_at)="row">
                            {{ formatDate(row.item.created_at) }}
                        </template>
                    </b-table>
                </div>

                <b-row>
                    <b-col md="2" class="my-1">
                        <b-form-group
                            :label="__('per_page')"
                            label-for="per-page-select"
                            label-size="sm"
                            class="mb-0">
                            <b-form-select
                                id="per-page-select"
                                v-model="perPage"
                                :options="pageOptions"
                                size="sm"
                                class="form-control form-select"
                                @change="getTransactions"
                            ></b-form-select>
                        </b-form-group>
                    </b-col>
                    <b-col md="4" class="my-1" offset-md="6">
                        <label>{{ __('total_records') }}: {{ totalRows }}</label>
                        <b-pagination
                            v-model="currentPage"
                            :total-rows="totalRows"
                            :per-page="perPage"
                            align="fill"
                            size="sm"
                            class="my-0"
                            @change="onPageChange"
                        ></b-pagination>
                    </b-col>
                </b-row>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: {
        customerId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            isLoading: false,
            transactions: [],
            fields: [
                { key: 'sno', label: '#', sortable: false },
                { key: 'transaction_category', label: 'Type', sortable: false },
                { key: 'payment_type', label: 'Payment Method', sortable: false },
                { key: 'txn_id', label: 'Transaction ID', sortable: false },
                { key: 'amount', label: 'Amount', sortable: false },
                { key: 'order_id', label: 'Order', sortable: false },
                { key: 'status', label: 'Status', sortable: false },
                { key: 'message', label: 'Message', sortable: false },
                { key: 'created_at', label: 'Date', sortable: false }
            ],
            totalRows: 0,
            currentPage: 1,
            perPage: 10,
            pageOptions: [5, 10, 20, 50],
            filter: '',
            selectedType: 'all',
            typeOptions: [
                { value: 'all', text: 'All Transactions' },
                { value: 'payments', text: 'Order Payments' },
                { value: 'wallet', text: 'Wallet Transactions' }
            ]
        }
    },
    created() {
        this.getTransactions();
    },
    watch: {
        customerId: function() {
            this.getTransactions();
        }
    },
    methods: {
        getTransactions() {
            this.isLoading = true;
            const params = {
                page: this.currentPage,
                per_page: this.perPage,
                search: this.filter,
                type: this.selectedType
            };

            axios.get(this.$apiUrl + '/customers/' + this.customerId + '/transactions', { params })
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status === 1) {
                        this.transactions = response.data.data.transactions;
                        this.totalRows = response.data.data.total;
                    }
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error fetching transactions:', error);
                });
        },
        onSearch() {
            this.currentPage = 1;
            this.getTransactions();
        },
        onTypeChange() {
            this.currentPage = 1;
            this.getTransactions();
        },
        onPageChange(page) {
            this.currentPage = page;
            this.getTransactions();
        },
        formatDate(date) {
            if (!date) return '-';
            return new Date(date).toLocaleString();
        },
        formatPaymentType(type) {
            if (!type) return '-';
            // Capitalize first letter
            if (type === 'credit') return 'Credit';
            if (type === 'debit') return 'Debit';
            return type;
        },
        getCategoryBadgeClass(category) {
            return category === 'wallet' ? 'bg-info' : 'bg-primary';
        },
        getPaymentTypeBadgeClass(type) {
            if (!type) return 'bg-secondary';
            const t = type.toLowerCase();
            if (t === 'credit') return 'bg-success';
            if (t === 'debit') return 'bg-danger';
            if (t.includes('cod') || t.includes('cash')) return 'bg-warning text-dark';
            if (t.includes('phonepe')) return 'bg-purple';
            if (t.includes('razorpay')) return 'bg-info';
            if (t.includes('stripe')) return 'bg-primary';
            if (t.includes('wallet')) return 'bg-info';
            if (t.includes('admin')) return 'bg-dark';
            return 'bg-secondary';
        },
        getStatusBadgeClass(status) {
            if (!status) return 'bg-secondary';
            const s = status.toLowerCase();
            if (s === 'success' || s === '1') return 'bg-success';
            if (s === 'failed' || s === '0') return 'bg-danger';
            if (s === 'pending') return 'bg-warning text-dark';
            return 'bg-secondary';
        },
        getAmountClass(item) {
            if (item.transaction_category === 'wallet') {
                return item.payment_type === 'credit' ? 'amount-credit fw-bold' : 'amount-debit fw-bold';
            }
            return 'amount-default fw-bold';
        }
    }
};
</script>

<style scoped>
.bg-purple {
    background-color: #6f42c1 !important;
    color: white;
}

.amount-credit {
    color: #00e676 !important;
}

.amount-debit {
    color: #ff5252 !important;
}

.amount-default {
    color: #6f42c1 !important;
}
</style>
