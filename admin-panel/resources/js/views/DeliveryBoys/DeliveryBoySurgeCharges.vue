<template>
    <div class="p-3">
        <h5>Surge Charges</h5>
        <p class="text-muted">View rain surcharge earnings for this delivery boy.</p>
        <hr>

        <!-- Loading State -->
        <div class="text-center py-4" v-if="isLoading">
            <b-spinner class="align-middle"></b-spinner>
            <strong class="ms-2">Loading surge charges...</strong>
        </div>

        <!-- Content -->
        <div v-else-if="transactions.length > 0">
            <!-- Summary Cards -->
            <div class="row mb-4">
                <div class="col-md-4 col-sm-6 mb-2">
                    <div class="card bg-info text-white">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Total Surge Earnings</h6>
                            <h4 class="mb-0">{{ $currency }} {{ totalSurgeEarnings }}</h4>
                        </div>
                    </div>
                </div>
                <div class="col-md-4 col-sm-6 mb-2">
                    <div class="card bg-warning text-dark">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Total Orders with Surge</h6>
                            <h4 class="mb-0">{{ transactions.length }}</h4>
                        </div>
                    </div>
                </div>
                <div class="col-md-4 col-sm-6 mb-2">
                    <div class="card bg-success text-white">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Avg Surge Per Order</h6>
                            <h4 class="mb-0">{{ $currency }} {{ avgSurgePerOrder }}</h4>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Transactions Table -->
            <div class="table-responsive">
                <b-table
                    :items="transactions"
                    :fields="tableFields"
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

                    <template #cell(rain_surcharge)="row">
                        <span class="text-success fw-bold">{{ $currency }} {{ parseFloat(row.item.rain_surcharge || 0).toFixed(2) }}</span>
                    </template>

                    <template #cell(delivery_charge)="row">
                        {{ $currency }} {{ parseFloat(row.item.delivery_charge || 0).toFixed(2) }}
                    </template>

                    <template #cell(amount)="row">
                        {{ $currency }} {{ parseFloat(row.item.amount || 0).toFixed(2) }}
                    </template>
                </b-table>
            </div>

            <!-- Pagination -->
            <b-row class="mt-3">
                <b-col md="2" class="my-1">
                    <b-form-group
                        label="Per page"
                        label-for="surge-per-page"
                        label-size="sm"
                        class="mb-0">
                        <b-form-select
                            id="surge-per-page"
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

        <!-- No Data -->
        <div class="text-center py-4" v-else>
            <i class="fa fa-cloud-rain fa-3x text-muted mb-3"></i>
            <p>No surge charge transactions found for this delivery boy.</p>
        </div>
    </div>
</template>

<script>
export default {
    name: 'DeliveryBoySurgeCharges',
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
            tableFields: [
                { key: 'order_id', label: 'Order ID', sortable: true, class: 'text-center' },
                { key: 'transaction_date', label: 'Date', sortable: true, class: 'text-center' },
                { key: 'rain_surcharge', label: 'Surge Amount', sortable: true, class: 'text-center' },
                { key: 'delivery_charge', label: 'Delivery Charge', sortable: true, class: 'text-center' },
                { key: 'amount', label: 'Order Total', sortable: true, class: 'text-center' }
            ]
        };
    },
    computed: {
        totalSurgeEarnings() {
            let total = 0;
            this.transactions.forEach(t => {
                total += parseFloat(t.rain_surcharge || 0);
            });
            return total.toFixed(2);
        },
        avgSurgePerOrder() {
            if (this.transactions.length === 0) return '0.00';
            return (parseFloat(this.totalSurgeEarnings) / this.transactions.length).toFixed(2);
        }
    },
    mounted() {
        this.loadTransactions();
    },
    methods: {
        loadTransactions() {
            if (this.isLoaded) return;

            this.isLoading = true;

            axios.get(this.$apiUrl + '/delivery_boys/' + this.deliveryBoyId + '/surge-charges')
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