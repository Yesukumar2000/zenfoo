<template>
    <div class="p-3">
        <h5>Orders</h5>
        <p class="text-muted">View all orders assigned to this delivery boy.</p>
        <hr>

        <!-- Loading State -->
        <div class="text-center py-4" v-if="isLoading">
            <b-spinner class="align-middle"></b-spinner>
            <strong class="ms-2">Loading orders...</strong>
        </div>

        <!-- Orders Content -->
        <div v-else-if="orders.length > 0">
            <!-- Orders Summary - At Top -->
            <div class="row mb-4">
                <div class="col-md col-sm-6 mb-2">
                    <div class="card bg-info text-white">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Total Orders</h6>
                            <h4 class="mb-0">{{ orders.length }}</h4>
                        </div>
                    </div>
                </div>
                <div class="col-md col-sm-6 mb-2">
                    <div class="card bg-secondary text-white">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Total Delivery Charges</h6>
                            <h4 class="mb-0">{{ $currency }} {{ totalDeliveryCharges }}</h4>
                        </div>
                    </div>
                </div>
                <div class="col-md col-sm-6 mb-2">
                    <div class="card bg-warning text-dark">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Total Delivery Tips</h6>
                            <h4 class="mb-0">{{ $currency }} {{ totalDeliveryTips }}</h4>
                        </div>
                    </div>
                </div>
                <div class="col-md col-sm-6 mb-2">
                    <div class="card bg-success text-white">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Total Bonus Amount</h6>
                            <h4 class="mb-0">{{ $currency }} {{ totalBonusAmount }}</h4>
                        </div>
                    </div>
                </div>
                <div class="col-md col-sm-6 mb-2">
                    <div class="card text-white" style="background-color: #E07A00;">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Total Wait Bonus</h6>
                            <h4 class="mb-0">{{ $currency }} {{ totalWaitBonus }}</h4>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Total Driver Earnings -->
            <div class="row mb-3">
                <div class="col-12">
                    <div class="card bg-primary text-white">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Total Driver Earnings</h6>
                            <h3 class="mb-0">{{ $currency }} {{ totalDriverEarnings }}</h3>
                            <small class="opacity-75">(Delivery Charges + Tips + Bonus + Wait Bonus)</small>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Orders Table -->
            <div class="table-responsive">
                <b-table
                    :items="orders"
                    :fields="orderFields"
                    :per-page="perPage"
                    :current-page="currentPage"
                    :bordered="true"
                    stacked="md"
                    show-empty
                    small>

                    <template #cell(id)="row">
                        <router-link :to="{ name: 'ViewOrder', params: { id: row.item.id }}">
                            #{{ row.item.id }}
                        </router-link>
                    </template>

                    <template #cell(created_at)="row">
                        {{ formatDateTime(row.item.created_at) }}
                    </template>

                    <template #cell(user_name)="row">
                        {{ row.item.user_name || '-' }}
                    </template>

                    <template #cell(total)="row">
                        {{ $currency }} {{ parseFloat(row.item.total || 0).toFixed(2) }}
                    </template>

                    <template #cell(delivery_charge)="row">
                        {{ $currency }} {{ getDeliveryCharge(row.item) }}
                    </template>

                    <template #cell(delivery_tip)="row">
                        {{ $currency }} {{ getDeliveryTip(row.item) }}
                    </template>

                    <template #cell(delivery_boy_bonus_amount)="row">
                        <span v-if="row.item.delivery_boy_bonus_amount && parseFloat(row.item.delivery_boy_bonus_amount) > 0" class="text-success fw-bold">
                            {{ $currency }} {{ parseFloat(row.item.delivery_boy_bonus_amount).toFixed(2) }}
                            <i class="fa fa-info-circle ms-1"
                               v-if="row.item.delivery_boy_bonus_details"
                               v-b-tooltip.hover
                               :title="getBonusDetailsTooltip(row.item.delivery_boy_bonus_details)"></i>
                        </span>
                        <span v-else>-</span>
                    </template>

                    <template #cell(vendor_wait_charge)="row">
                        <span v-if="row.item.vendor_wait_charge && parseFloat(row.item.vendor_wait_charge) > 0"
                              class="fw-bold" style="color: #E07A00;">
                            +{{ $currency }} {{ parseFloat(row.item.vendor_wait_charge).toFixed(2) }}
                        </span>
                        <span v-else>-</span>
                    </template>

                    <template #cell(payment_method)="row">
                        {{ row.item.payment_method || '-' }}
                    </template>

                    <template #cell(status)="row">
                        <span class="badge" :class="getOrderStatusBadgeClass(row.item.active_status)">
                            {{ getOrderStatusLabel(row.item.active_status) }}
                        </span>
                    </template>

                    <template #cell(actions)="row">
                        <router-link :to="{ name: 'ViewOrder', params: { id: row.item.id }}" class="btn btn-primary btn-sm" v-b-tooltip.hover title="View Order">
                            <i class="fa fa-eye"></i>
                        </router-link>
                    </template>
                </b-table>
            </div>

            <!-- Pagination -->
            <b-row class="mt-3">
                <b-col md="2" class="my-1">
                    <b-form-group
                        label="Per page"
                        label-for="orders-per-page"
                        label-size="sm"
                        class="mb-0">
                        <b-form-select
                            id="orders-per-page"
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
                        :total-rows="orders.length"
                        :per-page="perPage"
                        align="fill"
                        size="sm"
                        class="my-0"
                    ></b-pagination>
                </b-col>
            </b-row>
        </div>

        <!-- No Orders -->
        <div class="text-center py-4" v-else>
            <i class="fa fa-shopping-cart fa-3x text-muted mb-3"></i>
            <p>No orders found for this delivery boy.</p>
        </div>
    </div>
</template>

<script>
export default {
    name: 'DeliveryBoyOrders',
    props: {
        deliveryBoyId: {
            type: [Number, String],
            required: true
        }
    },
    data() {
        return {
            orders: [],
            isLoading: false,
            isLoaded: false,
            currentPage: 1,
            perPage: 10,
            orderFields: [
                { key: 'id', label: 'Order ID', sortable: true, class: 'text-center' },
                { key: 'created_at', label: 'Order Date', sortable: true, class: 'text-center' },
                { key: 'user_name', label: 'Customer', sortable: true, class: 'text-center' },
                { key: 'total', label: 'Total', sortable: true, class: 'text-center' },
                { key: 'delivery_charge', label: 'Delivery Charge', sortable: true, class: 'text-center' },
                { key: 'delivery_tip', label: 'Delivery Tip', sortable: true, class: 'text-center' },
                { key: 'delivery_boy_bonus_amount', label: 'Bonus', sortable: true, class: 'text-center' },
                { key: 'vendor_wait_charge', label: 'Wait Bonus', sortable: true, class: 'text-center' },
                { key: 'payment_method', label: 'Payment', sortable: true, class: 'text-center' },
                { key: 'status', label: 'Status', sortable: true, class: 'text-center' },
                { key: 'actions', label: 'Actions', class: 'text-center' }
            ]
        };
    },
    computed: {
        totalDeliveryCharges() {
            let total = 0;
            this.orders.forEach(order => {
                total += parseFloat(this.getDeliveryCharge(order));
            });
            return total.toFixed(2);
        },
        totalDeliveryTips() {
            let total = 0;
            this.orders.forEach(order => {
                total += parseFloat(this.getDeliveryTip(order));
            });
            return total.toFixed(2);
        },
        totalBonusAmount() {
            let total = 0;
            this.orders.forEach(order => {
                total += parseFloat(order.delivery_boy_bonus_amount || 0);
            });
            return total.toFixed(2);
        },
        totalWaitBonus() {
            let total = 0;
            this.orders.forEach(order => {
                total += parseFloat(order.vendor_wait_charge || 0);
            });
            return total.toFixed(2);
        },
        totalDriverEarnings() {
            let total = 0;
            this.orders.forEach(order => {
                total += parseFloat(this.getDeliveryCharge(order));
                total += parseFloat(this.getDeliveryTip(order));
                total += parseFloat(order.delivery_boy_bonus_amount || 0);
                total += parseFloat(order.vendor_wait_charge || 0);
            });
            return total.toFixed(2);
        }
    },
    mounted() {
        this.loadOrders();
    },
    methods: {
        loadOrders() {
            if (this.isLoaded) return;

            this.isLoading = true;

            axios.get(this.$apiUrl + '/delivery_boys/' + this.deliveryBoyId + '/orders')
                .then((response) => {
                    this.isLoading = false;
                    this.isLoaded = true;
                    if (response.data.status === 1) {
                        this.orders = response.data.data || [];
                    } else {
                        this.orders = [];
                    }
                })
                .catch(() => {
                    this.isLoading = false;
                    this.isLoaded = true;
                    this.orders = [];
                });
        },
        getDeliveryCharge(order) {
            try {
                if (order.cart_metadata) {
                    const metadata = typeof order.cart_metadata === 'string'
                        ? JSON.parse(order.cart_metadata)
                        : order.cart_metadata;

                    if (metadata.billing_summary && metadata.billing_summary.delivery_charge !== undefined) {
                        return parseFloat(metadata.billing_summary.delivery_charge).toFixed(2);
                    }
                }
                return parseFloat(order.delivery_charge || 0).toFixed(2);
            } catch (e) {
                return parseFloat(order.delivery_charge || 0).toFixed(2);
            }
        },
        getDeliveryTip(order) {
            try {
                if (order.cart_metadata) {
                    const metadata = typeof order.cart_metadata === 'string'
                        ? JSON.parse(order.cart_metadata)
                        : order.cart_metadata;

                    if (metadata.cart_info && metadata.cart_info.delivery_tip !== undefined) {
                        return parseFloat(metadata.cart_info.delivery_tip).toFixed(2);
                    }
                    if (metadata.billing_summary && metadata.billing_summary.delivery_tip !== undefined) {
                        return parseFloat(metadata.billing_summary.delivery_tip).toFixed(2);
                    }
                }
                return '0.00';
            } catch (e) {
                return '0.00';
            }
        },
        getBonusDetailsTooltip(bonusDetails) {
            try {
                if (!bonusDetails) return '';

                const details = typeof bonusDetails === 'string'
                    ? JSON.parse(bonusDetails)
                    : bonusDetails;

                if (typeof details === 'object') {
                    let tooltipParts = [];
                    if (details.reason) tooltipParts.push('Reason: ' + details.reason);
                    if (details.type) tooltipParts.push('Type: ' + details.type);
                    if (details.description) tooltipParts.push(details.description);
                    return tooltipParts.join(' | ') || 'Bonus applied';
                }
                return String(details);
            } catch (e) {
                return String(bonusDetails);
            }
        },
        formatDateTime(dateString) {
            if (!dateString) return '-';
            const date = new Date(dateString);
            return date.toLocaleDateString('en-GB') + ' ' + date.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
        },
        getOrderStatusLabel(id) {
            const map = {
                1: 'Payment Pending',
                2: 'Received',
                3: 'Processed',
                4: 'Shipped',
                5: 'Out For Delivery',
                6: 'Delivered',
                7: 'Cancelled',
                8: 'Returned'
            };
            return map[id] || '-';
        },
        getOrderStatusBadgeClass(id) {
            const map = {
                1: 'bg-warning text-dark',
                2: 'bg-info',
                3: 'bg-primary',
                4: 'bg-secondary',
                5: 'bg-dark',
                6: 'bg-success',
                7: 'bg-danger',
                8: 'bg-danger'
            };
            return map[id] || 'bg-light';
        }
    }
};
</script>

<style scoped>
.fw-bold {
    font-weight: bold;
}
</style>
