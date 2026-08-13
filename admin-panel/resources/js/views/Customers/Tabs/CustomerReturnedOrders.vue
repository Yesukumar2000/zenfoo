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
                    <b-col md="1">
                        <button class="btn btn-primary" @click="getOrders()">
                            <i class="fa fa-refresh"></i>
                        </button>
                    </b-col>
                </b-row>

                <div class="table-responsive">
                    <b-table
                        :items="orders"
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

                        <template #empty>
                            <div class="text-center py-4">
                                <i class="fa fa-undo fa-3x text-muted mb-3"></i>
                                <p class="text-muted">No returned orders found</p>
                            </div>
                        </template>

                        <template #cell(sno)="row">
                            {{ (currentPage - 1) * perPage + row.index + 1 }}
                        </template>

                        <template #cell(id)="row">
                            <router-link :to="'/orders/view/' + row.item.id" class="text-primary">
                                #{{ row.item.id }}
                            </router-link>
                        </template>

                        <template #cell(final_total)="row">
                            {{ $currency }}{{ row.item.final_total }}
                        </template>

                        <template #cell(payment_method)="row">
                            <span class="badge" :class="getPaymentBadgeClass(row.item.payment_method)">
                                {{ row.item.payment_method }}
                            </span>
                        </template>

                        <template #cell(active_status)="row">
                            <span class="badge bg-dark">Returned</span>
                        </template>

                        <!-- <template #cell(delivery_time)="row">
                            {{ row.item.delivery_time || '-' }}
                        </template> -->

                        <template #cell(created_at)="row">
                            {{ formatDate(row.item.created_at) }}
                        </template>

                        <template #cell(actions)="row">
                            <router-link :to="'/orders/view/' + row.item.id" class="btn btn-sm btn-primary">
                                <i class="fa fa-eye"></i>
                            </router-link>
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
                                @change="getOrders"
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
            orders: [],
            fields: [
                { key: 'sno', label: '#', sortable: false },
                { key: 'id', label: 'Order ID', sortable: true },
                { key: 'final_total', label: 'Total', sortable: true },
                { key: 'payment_method', label: 'Payment', sortable: true },
                { key: 'active_status', label: 'Status', sortable: true },
                // { key: 'delivery_time', label: 'Delivery Time', sortable: true },
                { key: 'created_at', label: 'Order Date', sortable: true },
                { key: 'actions', label: 'Actions' }
            ],
            totalRows: 0,
            currentPage: 1,
            perPage: 10,
            pageOptions: [5, 10, 20, 50],
            filter: ''
        }
    },
    created() {
        this.getOrders();
    },
    watch: {
        customerId: function() {
            this.getOrders();
        }
    },
    methods: {
        getOrders() {
            this.isLoading = true;
            const params = {
                user_id: this.customerId,
                status: 8, // Returned orders only
                page: this.currentPage,
                per_page: this.perPage,
                search: this.filter
            };

            axios.get(this.$apiUrl + '/orders', { params })
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status === 1) {
                        this.orders = response.data.data.orders;
                        this.totalRows = response.data.data.orders_total;
                    }
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error fetching returned orders:', error);
                    this.showError('Failed to load returned orders');
                });
        },
        onSearch() {
            this.currentPage = 1;
            this.getOrders();
        },
        onPageChange(page) {
            this.currentPage = page;
            this.getOrders();
        },
        formatDate(date) {
            if (!date) return '-';
            return new Date(date).toLocaleString();
        },
        getPaymentBadgeClass(method) {
            if (!method) return 'bg-secondary';
            const m = method.toLowerCase();
            if (m.includes('cod') || m.includes('cash')) return 'bg-warning text-dark';
            if (m.includes('online') || m.includes('card')) return 'bg-success';
            if (m.includes('wallet')) return 'bg-info';
            return 'bg-secondary';
        }
    }
};
</script>
