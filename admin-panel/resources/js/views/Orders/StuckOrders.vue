<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>Stuck Orders (No GPS)</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">Stuck Orders</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <section class="section">
                <div class="card">
                    <div class="card-header">
                        <h4 class="card-title">Live orders with no driver location</h4>
                        <small class="text-muted">
                            The driver's phone has stopped sending GPS — dead battery, no network, or app closed.
                            Call the driver and the store, then decide: keep waiting, change driver, or cancel with reason "Driver issue".
                        </small>
                    </div>
                    <div class="card-body">

                        <b-row class="mb-3">
                            <b-col md="3">
                                <h6 class="box-title">No GPS for more than</h6>
                                <select v-model="minutes" @change="getStuckOrders()" class="form-control form-select">
                                    <option :value="5">5 minutes</option>
                                    <option :value="10">10 minutes</option>
                                    <option :value="15">15 minutes</option>
                                    <option :value="30">30 minutes</option>
                                    <option :value="60">60 minutes</option>
                                </select>
                            </b-col>
                            <b-col md="3">
                                <h6 class="box-title">{{ __('search') }}</h6>
                                <b-form-input v-model="filter" type="search" placeholder="Search"></b-form-input>
                            </b-col>
                            <b-col md="3" class="d-flex align-items-end">
                                <b-form-checkbox v-model="autoRefresh">Auto refresh (60s)</b-form-checkbox>
                            </b-col>
                            <b-col md="2" class="d-flex align-items-end">
                                <button class="btn btn-primary" v-b-tooltip.hover :title="__('refresh')" @click="getStuckOrders()">
                                    <i class="fa fa-refresh" aria-hidden="true"></i>
                                </button>
                            </b-col>
                        </b-row>

                        <div class="table-responsive">
                            <b-table
                                :items="orders"
                                :fields="fields"
                                :current-page="currentPage"
                                :per-page="perPage"
                                :filter="filter"
                                :bordered="true"
                                :busy="isLoading"
                                stacked="md"
                                show-empty
                                empty-text="No stuck orders. Every live order has a fresh driver location."
                                small
                                hover>

                                <template #table-busy>
                                    <div class="text-center text-black my-2">
                                        <b-spinner class="align-middle"></b-spinner>
                                        <strong>{{ __('loading') }}...</strong>
                                    </div>
                                </template>

                                <template #cell(order_id)="row">
                                    <router-link :to="'/orders/view/' + row.item.order_id">{{ row.item.order_number || ('#' + row.item.order_id) }}</router-link>
                                </template>

                                <template #cell(customer_name)="row">
                                    {{ row.item.customer_name || '-' }}<br>
                                    <small class="text-muted">{{ row.item.customer_mobile || '' }}</small>
                                </template>

                                <template #cell(driver_name)="row">
                                    {{ row.item.driver_name || '-' }}<br>
                                    <small class="text-muted">{{ row.item.driver_mobile || '' }}</small>
                                    <span v-if="row.item.driver_is_problematic" class="badge bg-danger ms-1">On hold</span>
                                </template>

                                <template #cell(minutes_since_ping)="row">
                                    <span v-if="row.item.minutes_since_ping === null" class="badge bg-danger">No GPS at all</span>
                                    <span v-else :class="row.item.minutes_since_ping >= 30 ? 'badge bg-danger' : 'badge bg-warning'">
                                        {{ row.item.minutes_since_ping }} min ago
                                    </span>
                                </template>

                                <template #cell(payment_method)="row">
                                    {{ row.item.payment_method || '-' }}
                                    <span v-if="row.item.payment_method && row.item.payment_method.toLowerCase() !== 'cod'"
                                          class="badge bg-info">Paid online</span>
                                </template>

                                <template #cell(actions)="row">
                                    <router-link :to="'/orders/view/' + row.item.order_id" class="btn btn-sm btn-primary">
                                        Open Order
                                    </router-link>
                                </template>

                            </b-table>
                        </div>

                        <b-row>
                            <b-col md="2" class="my-1">
                                <b-form-group
                                    :label="__('per_page')"
                                    label-for="per-page-select"
                                    label-align-sm="right"
                                    label-size="sm"
                                    class="mb-0">
                                    <b-form-select
                                        id="per-page-select"
                                        v-model="perPage"
                                        :options="pageOptions"
                                        size="sm"
                                        class="form-control form-select"
                                    ></b-form-select>
                                </b-form-group>
                            </b-col>
                            <b-col md="4" class="my-1" offset-md="6">
                                <b-pagination
                                    v-model="currentPage"
                                    :total-rows="totalRows"
                                    :per-page="perPage"
                                    align="fill"
                                    size="sm"
                                    class="my-0"
                                ></b-pagination>
                            </b-col>
                        </b-row>

                    </div>
                </div>
            </section>
        </div>
    </div>
</template>

<script>
export default {
    data: function () {
        return {
            fields: [
                { key: 'order_id', label: 'Order', sortable: true },
                { key: 'customer_name', label: __('customer') },
                { key: 'driver_name', label: 'Driver' },
                { key: 'minutes_since_ping', label: 'Last GPS', sortable: true, class: 'text-center' },
                { key: 'payment_method', label: __('payment_method'), class: 'text-center' },
                { key: 'total', label: __('total'), class: 'text-center' },
                { key: 'actions', label: __('actions'), class: 'text-center' },
            ],
            orders: [],
            totalRows: 0,
            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            filter: null,
            isLoading: false,
            minutes: 10,
            autoRefresh: true,
            timer: null,
        }
    },
    created: function () {
        this.getStuckOrders();
        this.timer = setInterval(() => {
            if (this.autoRefresh) {
                this.getStuckOrders();
            }
        }, 60000);
    },
    beforeDestroy: function () {
        if (this.timer) {
            clearInterval(this.timer);
        }
    },
    methods: {
        getStuckOrders() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/orders/stuck_orders', { params: { minutes: this.minutes } })
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status !== 1) {
                        this.orders = [];
                        this.totalRows = 0;
                        this.showError(response.data.message || "Failed to load stuck orders.");
                        return;
                    }
                    this.orders = response.data.data || [];
                    this.totalRows = this.orders.length;
                })
                .catch(() => {
                    this.isLoading = false;
                    this.showError("Failed to load stuck orders.");
                });
        },
    }
}
</script>
