<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>{{ storeName }} - Pre Orders</h3>
                        <p class="text-subtitle text-muted">Order-wise items breakdown</p>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item"><router-link :to="preordersBackLink">Pre Orders</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">{{ storeName }}</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link :to="preordersBackLink" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <section class="section">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h4 class="card-title mb-0">Orders from {{ storeName }}</h4>
                        <div>
                            <button class="btn btn-sm btn-secondary me-2" @click="goBack()">
                                <i class="fa fa-arrow-left"></i> Back
                            </button>
                            <button class="btn btn-sm btn-primary" @click="showPrintModal = true">
                                <i class="fa fa-print"></i> Print
                            </button>
                        </div>
                    </div>

                    <!-- Print Options Modal -->
                    <b-modal v-model="showPrintModal" title="Print Options" size="lg" hide-footer>
                        <div class="print-options-container">
                            <!-- Single Seller Print -->
                            <div v-if="!isZenfooStore && assignedOrdersCount > 0" class="print-option mb-4">
                                <h5 class="mb-3">
                                    <i class="fa fa-user text-info"></i> Print Single Seller
                                </h5>
                                <p class="text-muted mb-3">Print orders for a specific seller</p>
                                <div class="mb-3">
                                    <select v-model="selectedSellerForPrint" class="form-select" style="max-width: 400px;">
                                        <option value="">Select Seller...</option>
                                        <option v-for="seller in uniqueSellers" :key="seller" :value="seller">
                                            {{ seller }}
                                        </option>
                                    </select>
                                </div>
                                <div class="d-flex gap-2">
                                    <button
                                        class="btn btn-info"
                                        :disabled="!selectedSellerForPrint"
                                        @click="printSingleSellerOrders(); showPrintModal = false;">
                                        <i class="fa fa-file-pdf"></i> Browser Print
                                    </button>
                                    <button
                                        class="btn btn-outline-info"
                                        :disabled="!selectedSellerForPrint"
                                        @click="printSingleSellerOrdersDirect(); showPrintModal = false;"
                                        title="Direct print to thermal printer (no driver needed)">
                                        <i class="fa fa-usb"></i> USB Direct Print
                                    </button>
                                </div>
                            </div>

                            <!-- Print All Sellers -->
                            <div v-if="!isZenfooStore && assignedOrdersCount > 0" class="print-option mb-4">
                                <h5 class="mb-3">
                                    <i class="fa fa-users text-success"></i> Print All Sellers
                                </h5>
                                <p class="text-muted mb-3">Print all orders grouped by seller ({{ uniqueSellers.length }} sellers)</p>
                                <div class="d-flex gap-2">
                                    <button class="btn btn-success" @click="printSellerWiseOrders(); showPrintModal = false;">
                                        <i class="fa fa-file-pdf"></i> Browser Print
                                    </button>
                                    <button 
                                        class="btn btn-outline-success" 
                                        @click="printSellerWiseOrdersDirect(); showPrintModal = false;"
                                        title="Direct print to thermal printer (no driver needed)">
                                        <i class="fa fa-usb"></i> USB Direct Print
                                    </button>
                                </div>
                            </div>

                            <!-- Print All Orders -->
                            <div class="print-option">
                                <h5 class="mb-3">
                                    <i class="fa fa-list text-danger"></i> Print All Orders
                                </h5>
                                <p class="text-muted mb-3">Print all orders chronologically ({{ orders.length }} orders)</p>
                                <div class="d-flex gap-2">
                                    <button class="btn btn-danger" @click="printAllOrders(); showPrintModal = false;">
                                        <i class="fa fa-file-pdf"></i> Browser Print
                                    </button>
                                    <button 
                                        class="btn btn-outline-danger" 
                                        @click="printAllOrdersDirect(); showPrintModal = false;"
                                        title="Direct print to thermal printer (no driver needed)">
                                        <i class="fa fa-usb"></i> USB Direct Print
                                    </button>
                                </div>
                            </div>
                        </div>
                    </b-modal>
                    <div class="card-body">
                        <div v-if="isLoading" class="text-center py-5">
                            <b-spinner></b-spinner>
                            <p class="mt-2">Loading store orders...</p>
                        </div>

                        <div v-else-if="orders.length === 0" class="text-center py-5">
                            <i class="fa fa-inbox fa-3x mb-3 text-muted"></i>
                            <p class="text-muted">No orders found for this store</p>
                        </div>

                        <div v-else>
                            <!-- Summary Card -->
                            <div class="card summary-card mb-4">
                                <div class="card-body">
                                    <h5 class="card-title">Summary</h5>
                                    <div class="row">
                                        <div class="col-lg col-md-4 col-sm-6">
                                            <div class="summary-item">
                                                <label>Total Orders</label>
                                                <h4 class="text-primary">{{ orders.length }}</h4>
                                            </div>
                                        </div>
                                        <div class="col-lg col-md-4 col-sm-6">
                                            <div class="summary-item">
                                                <label>Total Items</label>
                                                <h4 class="text-info">{{ totalItems }}</h4>
                                            </div>
                                        </div>
                                        <div class="col-lg col-md-4 col-sm-6">
                                            <div class="summary-item">
                                                <label>Total Amount</label>
                                                <h4 class="text-success">₹{{ totalAmount.toFixed(2) }}</h4>
                                            </div>
                                        </div>
                                        <div class="col-lg col-md-4 col-sm-6">
                                            <div class="summary-item">
                                                <label>Total Weight</label>
                                                <h4 class="text-danger">{{ totalWeight || 'N/A' }}</h4>
                                            </div>
                                        </div>
                                        <div class="col-lg col-md-4 col-sm-6">
                                            <div class="summary-item">
                                                <label>Avg Order Value</label>
                                                <h4 class="text-warning">₹{{ avgOrderValue.toFixed(2) }}</h4>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Filter Tabs (Only show if not Zenfoo store) -->
                            <div v-if="!isZenfooStore" class="order-filter-tabs mb-4">
                                <ul class="nav nav-tabs">
                                    <!-- <li class="nav-item">
                                        <a class="nav-link" :class="{ active: orderFilter === 'all' }" @click="orderFilter = 'all'" href="javascript:void(0)">
                                            <i class="fa fa-list me-1"></i> All Orders ({{ orders.length }})
                                        </a>
                                    </li> -->
                                    <li class="nav-item">
                                        <a class="nav-link" :class="{ active: orderFilter === 'assigned' }" @click="orderFilter = 'assigned'" href="javascript:void(0)">
                                            <i class="fa fa-user-check me-1"></i> Assigned ({{ assignedOrdersCount }})
                                        </a>
                                    </li>
                                    <li class="nav-item">
                                        <a class="nav-link" :class="{ active: orderFilter === 'unassigned' }" @click="orderFilter = 'unassigned'" href="javascript:void(0)">
                                            <i class="fa fa-clock me-1"></i> Unassigned ({{ unassignedOrdersCount }})
                                        </a>
                                    </li>
                                </ul>
                            </div>

                            <!-- Zone-Grouped View -->
                            <div v-for="group in filteredZoneGroups" :key="group.zone_id || 'no_zone'" class="zone-group-block mb-5">
                                <div class="zone-header p-3 bg-light border rounded-top d-flex justify-content-between align-items-center mb-0">
                                    <h5 class="mb-0 text-dark">
                                        <i class="fa fa-map-marker-alt text-danger me-2"></i>
                                        <strong>Zone: {{ group.zone_name }}</strong>
                                        <span class="badge bg-secondary ms-2">{{ group.orders.length }} Order(s)</span>
                                    </h5>
                                </div>

                                <!-- Seller Assignment Section for this Zone (Unassigned only) -->
                                <div v-if="!isZenfooStore && orderFilter === 'unassigned'" class="card seller-assignment-card mb-3 rounded-0 border-top-0 bg-white shadow-sm">
                                    <div class="card-body py-3">
                                        <div class="row align-items-center">
                                            <div class="col-md-2">
                                                <div class="form-check">
                                                    <input
                                                        type="checkbox"
                                                        class="form-check-input"
                                                        :id="'selectAll-' + (group.zone_id || 'no_zone')"
                                                        v-model="zoneSelectAll[group.zone_id || 'no_zone']"
                                                        @change="toggleZoneSelectAll(group.zone_id || 'no_zone')">
                                                    <label class="form-check-label ms-1" :for="'selectAll-' + (group.zone_id || 'no_zone')">
                                                        <strong>Select All</strong>
                                                    </label>
                                                </div>
                                            </div>
                                            <div class="col-md-5">
                                                <div class="d-flex align-items-center">
                                                    <label class="form-label mb-0 me-3 text-nowrap"><small><strong>Assign To:</strong></small></label>
                                                    <select
                                                        class="form-control form-select seller-dropdown py-1"
                                                        v-model="selectedZoneSellerIds[group.zone_id || 'no_zone']"
                                                        style="height: 38px;">
                                                        <option value="">Select Eligible Seller...</option>
                                                        <option v-for="seller in group.eligible_sellers" :key="seller.id" :value="seller.id">
                                                            {{ seller.name }} ({{ seller.store_name }})
                                                        </option>
                                                    </select>
                                                </div>
                                            </div>
                                            <div class="col-md-3">
                                                <button
                                                    class="btn btn-success d-block w-100"
                                                    :disabled="(selectedOrderIdsByZone[group.zone_id || 'no_zone'] || []).length === 0 || !selectedZoneSellerIds[group.zone_id || 'no_zone'] || isAssigningZone[group.zone_id || 'no_zone']"
                                                    @click="assignSellerToZone(group.zone_id || 'no_zone')">
                                                    <template v-if="isAssigningZone[group.zone_id || 'no_zone']">
                                                        <b-spinner small></b-spinner> ...
                                                    </template>
                                                    <template v-else>
                                                        <i class="fa fa-user-plus me-1"></i> Assign {{ (selectedOrderIdsByZone[group.zone_id || 'no_zone'] || []).length || '' }} Orders
                                                    </template>
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Orders in this Zone -->
                                <div v-for="order in group.orders" :key="order.id" class="order-card mb-3" :class="{'order-assigned': order.is_seller_assigned}">
                                    <div class="order-header" style="cursor: pointer;" @click="toggleOrderDetails(order.id)">
                                        <div class="d-flex justify-content-between align-items-center">
                                            <div class="d-flex align-items-center">
                                                <div v-if="!isZenfooStore" class="form-check me-3" @click.stop>
                                                    <input
                                                        type="checkbox"
                                                        class="form-check-input"
                                                        :id="'order-' + order.id"
                                                        :value="order.id"
                                                        v-model="selectedOrderIdsByZone[group.zone_id || 'no_zone']"
                                                        :disabled="order.is_seller_assigned"
                                                        style="cursor: pointer;">
                                                </div>
                                                <button
                                                    class="btn btn-sm btn-link text-decoration-none p-0 me-2"
                                                    @click.stop="toggleOrderDetails(order.id)"
                                                    style="font-size: 18px;">
                                                    <i class="fa" :class="isOrderExpanded(order.id) ? 'fa-chevron-down' : 'fa-chevron-right'"></i>
                                                </button>
                                                <div>
                                                    <h5 class="mb-1">
                                                        Order #{{ order.id }}
                                                        <span v-if="order.is_zenfoo_store" class="badge bg-info ms-2">
                                                            <i class="fa fa-store"></i> Zenfoo Store
                                                        </span>
                                                        <span v-else-if="order.is_seller_assigned" class="badge bg-success ms-2">
                                                            <i class="fa fa-user-check"></i> {{ order.assigned_seller_name }}
                                                        </span>
                                                    </h5>
                                                    <div class="text-muted small">
                                                        <span><i class="fa fa-user"></i> {{ order.user_name || 'Guest' }}</span>
                                                        <span class="ms-3"><i class="fa fa-phone"></i> {{ order.mobile }}</span>
                                                        <span class="ms-3"><i class="fa fa-calendar"></i> {{ order.preorder_placed_at_formatted }}</span>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="text-end">
                                                <span class="badge" :class="getStatusClass(order.active_status)">
                                                    {{ getStatusLabel(order.active_status) }}
                                                </span>
                                                <div class="mt-2">
                                                    <strong class="text-primary">₹{{ parseFloat(order.final_total).toFixed(2) }}</strong>
                                                </div>
                                                <div v-if="calculateOrderTotalWeight(order)" class="mt-1">
                                                    <span class="badge bg-warning text-dark">
                                                        <i class="fa fa-weight"></i> {{ calculateOrderTotalWeight(order) }}
                                                    </span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    <div v-if="isOrderExpanded(order.id)" class="order-items">
                                        <div v-if="(order.items && order.items.length > 0) || (order.combo_items && order.combo_items.length > 0)">
                                            <table class="table table-sm mb-0">
                                                <thead>
                                                    <tr>
                                                        <th>Item</th>
                                                        <th class="text-center">Quantity</th>
                                                        <th class="text-right">Price</th>
                                                        <th class="text-right">Subtotal</th>
                                                    </tr>
                                                </thead>
                                                <tbody>
                                                    <!-- Regular Items -->
                                                    <tr v-for="(item, index) in order.items" :key="'item-' + index">
                                                        <td>{{ item.name || item.product_name }}</td>
                                                        <td class="text-center">{{ item.quantity }}</td>
                                                        <td class="text-right">₹{{ parseFloat(item.price).toFixed(2) }}</td>
                                                        <td class="text-right"><strong>₹{{ parseFloat(item.sub_total).toFixed(2) }}</strong></td>
                                                    </tr>
                                                    <!-- Combo Items -->
                                                    <!-- eslint-disable-next-line vue/valid-v-for -->
                                                    <template v-for="(combo, comboIndex) in order.combo_items">
                                                        <tr class="combo-header-row" :key="'combo-' + order.id + '-' + comboIndex">
                                                            <td colspan="4">
                                                                <div class="d-flex justify-content-between align-items-center">
                                                                    <div>
                                                                        <strong>
                                                                            <i class="fa fa-box-open me-2"></i>
                                                                            {{ combo.combo_name }}
                                                                        </strong>
                                                                        <span class="badge bg-info ms-2">Combo ({{ getComboProductsForStore(combo, storeId).length }} items from this store)</span>
                                                                        <button
                                                                            class="btn btn-sm btn-link ms-2"
                                                                            @click="toggleComboProducts(order.id, comboIndex)"
                                                                            style="text-decoration: none;">
                                                                            <i class="fa" :class="isComboExpanded(order.id, comboIndex) ? 'fa-chevron-up' : 'fa-chevron-down'"></i>
                                                                            {{ isComboExpanded(order.id, comboIndex) ? 'Hide' : 'Show' }} Products
                                                                        </button>
                                                                    </div>
                                                                    <div>
                                                                        <strong class="text-success">₹{{ getComboSubtotalForStore(combo, storeId).toFixed(2) }}</strong>
                                                                    </div>
                                                                </div>
                                                            </td>
                                                        </tr>
                                                        <!-- Expanded products from this store only -->
                                                        <tr v-if="isComboExpanded(order.id, comboIndex)" :key="'combo-products-' + order.id + '-' + comboIndex">
                                                            <td colspan="4" class="p-0">
                                                                <table class="table table-sm mb-0 ms-4 combo-products-table" style="width: calc(100% - 2rem);">
                                                                    <thead>
                                                                        <tr>
                                                                            <th>Product</th>
                                                                            <th class="text-center">Qty</th>
                                                                            <th class="text-right">Price</th>
                                                                            <th class="text-right">Subtotal</th>
                                                                        </tr>
                                                                    </thead>
                                                                    <tbody>
                                                                        <tr v-for="(product, pIndex) in getComboProductsForStore(combo, storeId)" :key="pIndex">
                                                                            <td>
                                                                                {{ product.product_name }}
                                                                                <small class="text-muted d-block">
                                                                                    {{ product.variant_measurement }}
                                                                                    {{ getUnitLabel(product.variant_stock_unit_id) }}
                                                                                </small>
                                                                            </td>
                                                                            <td class="text-center">{{ product.quantity }}</td>
                                                                            <td class="text-right">
                                                                                <span v-if="product.actual_price != product.price" class="text-muted text-decoration-line-through me-1">
                                                                                    ₹{{ parseFloat(product.actual_price).toFixed(2) }}
                                                                                </span>
                                                                                ₹{{ parseFloat(product.price).toFixed(2) }}
                                                                            </td>
                                                                            <td class="text-right">₹{{ parseFloat(product.sub_total).toFixed(2) }}</td>
                                                                        </tr>
                                                                    </tbody>
                                                                </table>
                                                            </td>
                                                        </tr>
                                                    </template>
                                                </tbody>
                                            </table>
                                        </div>
                                        <div v-else class="text-center py-3 text-muted">
                                            <small>No items data available</small>
                                        </div>
                                    </div>

                                    <div v-if="isOrderExpanded(order.id)" class="order-footer">
                                        <div class="row">
                                            <div class="col-md-8">
                                                <small class="text-muted">
                                                    <strong>Payment:</strong> {{ order.payment_method }}
                                                    <span class="ms-3"><strong>Process Date:</strong> {{ order.preorder_process_date_formatted }}</span>
                                                    <span v-if="calculateOrderTotalWeight(order)" class="ms-3">
                                                        <strong>Total Weight:</strong>
                                                        <span class="badge bg-warning text-dark">{{ calculateOrderTotalWeight(order) }}</span>
                                                    </span>
                                                </small>
                                            </div>
                                            <div class="col-md-4 text-end">
                                                <div class="total-breakdown">
                                                    <div><small>Subtotal: ₹{{ parseFloat(order.total || 0).toFixed(2) }}</small></div>
                                                    <div v-if="order.wallet_balance > 0"><small>Wallet: -₹{{ parseFloat(order.wallet_balance).toFixed(2) }}</small></div>
                                                    <div class="mt-1"><strong>Total: ₹{{ parseFloat(order.final_total).toFixed(2) }}</strong></div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <!-- Single block fallback (if filteredZoneGroups is empty but orders exist - e.g. Zenfoo store) -->
                            <div v-if="filteredZoneGroups.length === 0 && orders.length > 0">
                                <div v-for="order in filteredOrders" :key="order.id" class="order-card mb-4" :class="{'order-assigned': order.is_seller_assigned}">
                                    <div class="order-header" style="cursor: pointer;" @click="toggleOrderDetails(order.id)">
                                        <div class="d-flex justify-content-between align-items-center">
                                            <div class="d-flex align-items-center">
                                                <button
                                                    class="btn btn-sm btn-link text-decoration-none p-0 me-2"
                                                    @click.stop="toggleOrderDetails(order.id)"
                                                    style="font-size: 18px;">
                                                    <i class="fa" :class="isOrderExpanded(order.id) ? 'fa-chevron-down' : 'fa-chevron-right'"></i>
                                                </button>
                                                <div>
                                                    <h5 class="mb-1">
                                                        Order #{{ order.id }}
                                                    </h5>
                                                    <div class="text-muted small">
                                                        <span><i class="fa fa-user"></i> {{ order.user_name || 'Guest' }}</span>
                                                        <span class="ms-3"><i class="fa fa-phone"></i> {{ order.mobile }}</span>
                                                        <span class="ms-3"><i class="fa fa-calendar"></i> {{ order.preorder_placed_at_formatted }}</span>
                                                    </div>
                                                </div>
                                            </div>
                                            <div class="text-end">
                                                <span class="badge" :class="getStatusClass(order.active_status)">
                                                    {{ getStatusLabel(order.active_status) }}
                                                </span>
                                                <div class="mt-2">
                                                    <strong class="text-primary">₹{{ parseFloat(order.final_total).toFixed(2) }}</strong>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <!-- ... items and footer (collapsed to keep it simple as this is for Zenfoo store) ... -->
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
import axios from 'axios';
import moment from 'moment';

export default {
    name: 'StorePreOrders',
    data() {
        return {
            isLoading: false,
            isAssigning: false,
            storeId: null,
            storeName: '',
            orders: [],
            sellers: [],
            startDate: '',
            endDate: '',
            status: '',
            selectedOrderIds: [],
            selectedSellerId: '',
            selectAll: false,
            expandedCombos: {}, // Track which combos are expanded: { orderId_comboIndex: true }
            expandedOrders: {}, // Track which orders are expanded: { orderId: true }
            orderFilter: 'unassigned', // Filter: 'assigned', 'unassigned'
            selectedSellerForPrint: '', // Selected seller for single seller print
            showPrintModal: false, // Control print options modal visibility
            zoneGroups: [],
            selectedOrderIdsByZone: {}, // zoneKey -> [orderIds]
            selectedZoneSellerIds: {}, // zoneKey -> sellerId
            zoneSelectAll: {}, // zoneKey -> boolean
            isAssigningZone: {} // zoneKey -> boolean
        }
    },
    created() {
        this.storeId = this.$route.params.storeId;
        this.storeName = this.$route.query.storeName || 'Store';
        this.startDate = this.$route.query.startDate || '';
        this.endDate = this.$route.query.endDate || '';
        this.status = this.$route.query.status || '';

        this.fetchStoreOrders();
        this.fetchSellers();
    },
    computed: {
        preordersBackLink() {
            // Preserve the status parameter when navigating back via breadcrumb
            const query = {};
            if (this.$route.query.status) {
                query.status = this.$route.query.status;
            }
            return { path: '/preorders', query };
        },
        filteredOrders() {
            // For Zenfoo stores, show all orders (no filtering needed)
            if (this.isZenfooStore) {
                return this.orders;
            }

            // For other stores, apply filters
            if (this.orderFilter === 'assigned') {
                return this.orders.filter(order => order.is_seller_assigned);
            } else if (this.orderFilter === 'unassigned') {
                return this.orders.filter(order => !order.is_seller_assigned && !order.is_zenfoo_store);
            }
            return this.orders; // 'all'
        },
        totalItems() {
            return this.orders.reduce((sum, order) => {
                const regularItems = order.items ? order.items.length : 0;

                // Count individual products in combos for this store
                let comboProductCount = 0;
                if (order.combo_items && order.combo_items.length > 0) {
                    order.combo_items.forEach(combo => {
                        const storeProducts = this.getComboProductsForStore(combo, this.storeId);
                        comboProductCount += storeProducts.length;
                    });
                }

                return sum + regularItems + comboProductCount;
            }, 0);
        },
        totalAmount() {
            return this.orders.reduce((sum, order) => sum + parseFloat(order.final_total || 0), 0);
        },
        avgOrderValue() {
            return this.orders.length > 0 ? this.totalAmount / this.orders.length : 0;
        },
        totalWeight() {
            // Calculate total weight across all orders
            let totalGrams = 0;

            this.orders.forEach(order => {
                // Process regular items
                if (order.items && order.items.length > 0) {
                    order.items.forEach(item => {
                        const unitId = item.variant_stock_unit_id;
                        const measurement = parseFloat(item.variant_measurement || 0);
                        const quantity = parseFloat(item.quantity || 0);

                        if (unitId === 1) { // kg
                            totalGrams += (measurement * 1000) * quantity;
                        } else if (unitId === 2) { // g
                            totalGrams += measurement * quantity;
                        }
                    });
                }

                // Process combo items
                if (order.combo_items && order.combo_items.length > 0) {
                    order.combo_items.forEach(combo => {
                        const storeProducts = this.getComboProductsForStore(combo, this.storeId);
                        storeProducts.forEach(product => {
                            const unitId = product.variant_stock_unit_id;
                            const measurement = parseFloat(product.variant_measurement || 0);
                            const quantity = parseFloat(product.quantity || 0);

                            if (unitId === 1) {
                                totalGrams += (measurement * 1000) * quantity;
                            } else if (unitId === 2) {
                                totalGrams += measurement * quantity;
                            }
                        });
                    });
                }
            });

            // Convert to kg + gm format
            if (totalGrams === 0) {
                return null;
            }

            const kg = Math.floor(totalGrams / 1000);
            const gm = Math.round(totalGrams % 1000);

            if (kg > 0 && gm > 0) {
                return `${kg}kg + ${gm}gm`;
            } else if (kg > 0) {
                return `${kg}kg`;
            } else {
                return `${gm}gm`;
            }
        },
        unassignedOrdersCount() {
            return this.orders.filter(order => !order.is_seller_assigned && !order.is_zenfoo_store).length;
        },
        assignedOrdersCount() {
            return this.orders.filter(order => order.is_seller_assigned).length;
        },
        isZenfooStore() {
            // Check if any order is marked as Zenfoo store
            return this.orders.length > 0 && this.orders.some(order => order.is_zenfoo_store);
        },
        uniqueSellers() {
            // Get unique list of seller names from assigned orders
            const sellers = new Set();
            this.orders.forEach(order => {
                if (order.is_seller_assigned && order.assigned_seller_name) {
                    sellers.add(order.assigned_seller_name);
                }
            });
            return Array.from(sellers).sort();
        },
        filteredZoneGroups() {
            if (!this.zoneGroups || this.zoneGroups.length === 0) return [];

            return this.zoneGroups.map(group => {
                let filteredOrders = group.orders;
                if (!this.isZenfooStore) {
                    if (this.orderFilter === 'assigned') {
                        filteredOrders = group.orders.filter(o => o.is_seller_assigned);
                    } else if (this.orderFilter === 'unassigned') {
                        filteredOrders = group.orders.filter(o => !o.is_seller_assigned && !o.is_zenfoo_store);
                    }
                }
                return {
                    ...group,
                    orders: filteredOrders
                };
            }).filter(group => group.orders.length > 0);
        }
    },
    watch: {
        selectedOrderIds(newVal) {
            // Update selectAll checkbox state
            this.selectAll = newVal.length === this.orders.length && this.orders.length > 0;
        }
    },
    methods: {
        async fetchStoreOrders() {
            this.isLoading = true;

            const params = {
                store_id: this.storeId,
                per_page: 1000,
                startDate: this.startDate,
                endDate: this.endDate,
                status: this.status
            };

            try {
                const response = await axios.get(this.$apiUrl + '/preorders/store-orders', { params });

                if (response.data.status === 1) {
                    this.orders = response.data.data.orders;
                    this.zoneGroups = response.data.data.zone_groups || [];

                    // Initialize trackers for each zone
                    this.zoneGroups.forEach(group => {
                        const zoneKey = group.zone_id || 'no_zone';
                        if (this.selectedOrderIdsByZone[zoneKey] === undefined) {
                            this.$set(this.selectedOrderIdsByZone, zoneKey, []);
                        }
                        if (this.zoneSelectAll[zoneKey] === undefined) {
                            this.$set(this.zoneSelectAll, zoneKey, false);
                        }
                        if (this.selectedZoneSellerIds[zoneKey] === undefined) {
                            this.$set(this.selectedZoneSellerIds, zoneKey, '');
                        }
                        if (this.isAssigningZone[zoneKey] === undefined) {
                            this.$set(this.isAssigningZone, zoneKey, false);
                        }
                    });
                }
            } catch (error) {
                console.error('Error fetching store orders:', error);
                this.$toast.error('Failed to fetch store orders');
            } finally {
                this.isLoading = false;
            }
        },

        getStatusLabel(status) {
            const labels = {
                12: 'Preorder Pending',
                2: 'Processed',
                3: 'In Progress',
                5: 'Out For Delivery',
                6: 'Delivered'
            };
            return labels[status] || `Status ${status}`;
        },

        getStatusClass(status) {
            const classes = {
                12: 'bg-warning',
                2: 'bg-success',
                3: 'bg-info',
                5: 'bg-primary',
                6: 'bg-success'
            };
            return classes[status] || 'bg-secondary';
        },

        goBack() {
            // Preserve the status parameter when going back
            const query = {};
            if (this.$route.query.status) {
                query.status = this.$route.query.status;
            }
            this.$router.push({ path: '/preorders', query });
        },

        async fetchSellers() {
            try {
                const response = await axios.get(this.$apiUrl + `/admin/sellers/by-store/${this.storeId}`);

                if (response.data.status === 1) {
                    this.sellers = response.data.data;

                    if (this.sellers.length === 0) {
                        this.$toast.warning('No active sellers found for this store');
                    }
                } else {
                    this.$toast.error(response.data.message || 'Failed to fetch sellers');
                }
            } catch (error) {
                console.error('Error fetching sellers:', error);
                this.$toast.error('Failed to load sellers. Please try again.');
            }
        },

        toggleSelectAll() {
            if (this.selectAll) {
                // Only select unassigned orders
                this.selectedOrderIds = this.orders
                    .filter(order => !order.is_seller_assigned)
                    .map(order => order.id);
            } else {
                this.selectedOrderIds = [];
            }
        },

        toggleZoneSelectAll(zoneKey) {
            const group = this.zoneGroups.find(g => (g.zone_id || 'no_zone') === zoneKey);
            if (!group) return;

            if (this.zoneSelectAll[zoneKey]) {
                // Select only unassigned orders in this zone
                this.$set(this.selectedOrderIdsByZone, zoneKey,
                    group.orders
                        .filter(o => !o.is_seller_assigned && !o.is_zenfoo_store)
                        .map(o => o.id)
                );
            } else {
                this.$set(this.selectedOrderIdsByZone, zoneKey, []);
            }
        },

        async assignSellerToZone(zoneKey) {
            const orderIds = this.selectedOrderIdsByZone[zoneKey];
            const sellerId = this.selectedZoneSellerIds[zoneKey];

            if (!orderIds || orderIds.length === 0) {
                this.$toast.warning('Please select at least one order');
                return;
            }

            if (!sellerId) {
                this.$toast.warning('Please select a seller');
                return;
            }

            this.$set(this.isAssigningZone, zoneKey, true);

            try {
                const response = await axios.post(this.$apiUrl + '/admin/preorders/assign-sellers', {
                    order_ids: orderIds,
                    seller_id: sellerId,
                    store_id: this.storeId
                });

                if (response.data.status === 1) {
                    this.$toast.success(response.data.message || 'Sellers assigned successfully');
                    // Reset selections for this zone
                    this.$set(this.selectedOrderIdsByZone, zoneKey, []);
                    this.$set(this.selectedZoneSellerIds, zoneKey, '');
                    this.$set(this.zoneSelectAll, zoneKey, false);
                    // Refresh all orders/groups
                    await this.fetchStoreOrders();
                } else {
                    this.$toast.error(response.data.message || 'Failed to assign sellers');
                }
            } catch (error) {
                console.error('Error assigning sellers:', error);
                this.$toast.error(error.response?.data?.message || 'Failed to assign sellers');
            } finally {
                this.$set(this.isAssigningZone, zoneKey, false);
            }
        },

        async assignSellersToOrders() {
            if (this.selectedOrderIds.length === 0) {
                this.$toast.warning('Please select at least one order');
                return;
            }

            if (!this.selectedSellerId) {
                this.$toast.warning('Please select a seller');
                return;
            }

            this.isAssigning = true;

            try {
                const response = await axios.post(this.$apiUrl + '/admin/preorders/assign-sellers', {
                    order_ids: this.selectedOrderIds,
                    seller_id: this.selectedSellerId,
                    store_id: this.storeId
                });

                if (response.data.status === 1) {
                    this.$toast.success(response.data.message || 'Sellers assigned successfully');
                    // Clear selections
                    this.selectedOrderIds = [];
                    this.selectedSellerId = '';
                    this.selectAll = false;
                    // Refresh orders
                    await this.fetchStoreOrders();
                } else {
                    this.$toast.error(response.data.message || 'Failed to assign sellers');
                }
            } catch (error) {
                console.error('Error assigning sellers:', error);
                this.$toast.error(error.response?.data?.message || 'Failed to assign sellers');
            } finally {
                this.isAssigning = false;
            }
        },

        toggleOrderDetails(orderId) {
            this.$set(this.expandedOrders, orderId, !this.expandedOrders[orderId]);
        },

        isOrderExpanded(orderId) {
            return !!this.expandedOrders[orderId];
        },

        toggleComboProducts(orderId, comboIndex) {
            const key = `${orderId}_${comboIndex}`;
            this.$set(this.expandedCombos, key, !this.expandedCombos[key]);
        },

        isComboExpanded(orderId, comboIndex) {
            const key = `${orderId}_${comboIndex}`;
            return !!this.expandedCombos[key];
        },

        getComboProductsForStore(combo, storeId) {
            try {
                // Parse products if it's a JSON string
                let products = typeof combo.products === 'string'
                    ? JSON.parse(combo.products)
                    : combo.products;

                if (!products || !Array.isArray(products)) {
                    return [];
                }

                // Filter products for this store only
                // First check if we have store_wise_products structure
                if (combo.store_wise_products && Array.isArray(combo.store_wise_products)) {
                    const storeGroup = combo.store_wise_products.find(sg => sg.store_id == storeId);
                    return storeGroup ? storeGroup.products : [];
                }

                // Otherwise filter from flat products array
                // Note: products array doesn't have store_id, so we can't filter by store
                // Return all products for now
                return products;
            } catch (e) {
                console.error('Error parsing combo products:', e);
                return [];
            }
        },

        getUnitLabel(unitId) {
            const units = {
                1: 'kg',
                2: 'g',
                3: 'L',
                4: 'ml'
            };
            return units[unitId] || 'units';
        },

        /**
         * Calculate total weight for an order (in kg + gm format)
         * Only considers weight units (kg and g), ignores liquids (L, ml)
         */
        calculateOrderTotalWeight(order) {
            let totalGrams = 0;

            // Calculate from regular items
            if (order.items && order.items.length > 0) {
                order.items.forEach(item => {
                    const unitId = item.variant_stock_unit_id;
                    const measurement = parseFloat(item.variant_measurement || 0);
                    const quantity = parseFloat(item.quantity || 0);

                    // Only process weight units (kg=1, g=2)
                    if (unitId === 1) {
                        // kg to grams: multiply by 1000
                        totalGrams += (measurement * 1000) * quantity;
                    } else if (unitId === 2) {
                        // already in grams
                        totalGrams += measurement * quantity;
                    }
                });
            }

            // Calculate from combo items products (only from this store)
            if (order.combo_items && order.combo_items.length > 0) {
                order.combo_items.forEach(combo => {
                    const storeProducts = this.getComboProductsForStore(combo, this.storeId);
                    storeProducts.forEach(product => {
                        const unitId = product.variant_stock_unit_id;
                        const measurement = parseFloat(product.variant_measurement || 0);
                        const quantity = parseFloat(product.quantity || 0);

                        if (unitId === 1) {
                            totalGrams += (measurement * 1000) * quantity;
                        } else if (unitId === 2) {
                            totalGrams += measurement * quantity;
                        }
                    });
                });
            }

            // Convert to kg + gm format
            if (totalGrams === 0) {
                return null; // No weight items
            }

            const kg = Math.floor(totalGrams / 1000);
            const gm = Math.round(totalGrams % 1000);

            if (kg > 0 && gm > 0) {
                return `${kg}kg + ${gm}gm`;
            } else if (kg > 0) {
                return `${kg}kg`;
            } else {
                return `${gm}gm`;
            }
        },

        getComboSubtotalForStore(combo, storeId) {
            // Calculate subtotal for products from this store only
            const storeProducts = this.getComboProductsForStore(combo, storeId);
            return storeProducts.reduce((sum, product) => {
                return sum + parseFloat(product.sub_total || 0);
            }, 0);
        },

        printAllOrders() {
            // Generate PDF with all orders and their items
            const printContent = this.generateDetailedPrintContent();
            const printWindow = window.open('', '', 'width=800,height=600');
            printWindow.document.write(printContent);
            printWindow.document.close();
            printWindow.focus();

            setTimeout(() => {
                printWindow.print();
            }, 250);

            this.$toast.info('Print dialog opened - Select "Save as PDF" to download');
        },

        printSellerWiseOrders() {
            // Generate PDF with orders grouped by seller
            const printContent = this.generateSellerWisePrintContent();
            const printWindow = window.open('', '', 'width=800,height=600');
            printWindow.document.write(printContent);
            printWindow.document.close();
            printWindow.focus();

            setTimeout(() => {
                printWindow.print();
            }, 250);

            this.$toast.info('Print dialog opened - Select "Save as PDF" to download');
        },

        printSingleSellerOrders() {
            if (!this.selectedSellerForPrint) {
                this.$toast.warning('Please select a seller first');
                return;
            }

            // Generate PDF for single seller
            const printContent = this.generateSingleSellerPrintContent(this.selectedSellerForPrint);
            const printWindow = window.open('', '', 'width=800,height=600');
            printWindow.document.write(printContent);
            printWindow.document.close();
            printWindow.focus();

            setTimeout(() => {
                printWindow.print();
            }, 250);

            this.$toast.info('Print dialog opened - Select "Save as PDF" to download');
        },

        generateDetailedPrintContent() {
            let ordersHTML = '';
            this.orders.forEach(order => {
                let itemsHTML = '';
                // Add regular items
                if (order.items && order.items.length > 0) {
                    order.items.forEach(item => {
                        itemsHTML += `
                            <tr>
                                <td>${item.name || item.product_name}</td>
                                <td class="text-center">${item.quantity}</td>
                                <td class="text-right">₹${parseFloat(item.price).toFixed(2)}</td>
                                <td class="text-right"><strong>₹${parseFloat(item.sub_total).toFixed(2)}</strong></td>
                            </tr>
                        `;
                    });
                }
                // Add combo items
                if (order.combo_items && order.combo_items.length > 0) {
                    order.combo_items.forEach(combo => {
                        const comboProducts = this.getComboProductsForStore(combo, this.storeId);
                        const comboSubtotal = this.getComboSubtotalForStore(combo, this.storeId);

                        itemsHTML += `
                            <tr style="background-color: #e3f2fd !important; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">
                                <td colspan="4">
                                    <strong>${combo.combo_name}</strong>
                                    <span style="background-color: #0dcaf0 !important; color: white !important; padding: 2px 6px; border-radius: 3px; font-size: 8px; margin-left: 8px; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">COMBO (${comboProducts.length} items from this store)</span>
                                    <span style="float: right;"><strong>₹${comboSubtotal.toFixed(2)}</strong></span>
                                </td>
                            </tr>
                        `;

                        // Add combo products
                        if (comboProducts.length > 0) {
                            comboProducts.forEach(product => {
                                const unitLabel = this.getUnitLabel(product.variant_stock_unit_id);
                                itemsHTML += `
                                    <tr style="background-color: #f8f9fa !important; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">
                                        <td style="padding-left: 30px;">
                                            ${product.product_name}
                                            <br><small style="color: #6c757d;">${product.variant_measurement} ${unitLabel}</small>
                                        </td>
                                        <td class="text-center">${product.quantity}</td>
                                        <td class="text-right">₹${parseFloat(product.price).toFixed(2)}</td>
                                        <td class="text-right">₹${parseFloat(product.sub_total).toFixed(2)}</td>
                                    </tr>
                                `;
                            });
                        }
                    });
                }

                const statusLabel = this.getStatusLabel(order.active_status);
                const statusClass = order.active_status == 12 ? 'status-pending' : 'status-processed';
                const orderWeight = this.calculateOrderTotalWeight(order);

                ordersHTML += `
                    <div class="order-section">
                        <div class="order-header-print">
                            <div style="display: flex; justify-content: space-between; align-items: center;">
                                <div>
                                    <h3>Order #${order.id}</h3>
                                    <p><strong>Customer:</strong> ${order.user_name || 'Guest'} | <strong>Mobile:</strong> ${order.mobile}</p>
                                    <p><strong>Placed:</strong> ${order.preorder_placed_at_formatted} | <strong>Process:</strong> ${order.preorder_process_date_formatted}</p>
                                    ${orderWeight ? `<p><strong>Total Weight:</strong> <span style="background-color: #ffc107; color: #000; padding: 2px 8px; border-radius: 3px; font-size: 11px;">${orderWeight}</span></p>` : ''}
                                </div>
                                <div style="text-align: right;">
                                    <span class="status-badge ${statusClass}">${statusLabel}</span>
                                    <p style="font-size: 16px; margin-top: 5px;"><strong>₹${parseFloat(order.final_total).toFixed(2)}</strong></p>
                                </div>
                            </div>
                        </div>
                        <table class="items-table">
                            <thead>
                                <tr>
                                    <th>Item</th>
                                    <th class="text-center">Qty</th>
                                    <th class="text-right">Price</th>
                                    <th class="text-right">Subtotal</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${itemsHTML || '<tr><td colspan="4" class="text-center">No items</td></tr>'}
                            </tbody>
                        </table>
                        <div class="order-totals">
                            <div style="display: flex; justify-content: space-between;">
                                <span>
                                    <strong>Payment:</strong> ${order.payment_method}
                                    ${orderWeight ? ` | <strong>Weight:</strong> ${orderWeight}` : ''}
                                </span>
                                <div style="text-align: right;">
                                    <div style="font-size: 14px;"><strong>Total: ₹${parseFloat(order.final_total).toFixed(2)}</strong></div>
                                </div>
                            </div>
                        </div>
                    </div>
                `;
            });

            return `
                <!DOCTYPE html>
                <html>
                <head>
                    <title>${this.storeName} - Pre Orders</title>
                    <style>
                        @page { size: A4; margin: 1cm; }
                        * {
                            margin: 0;
                            padding: 0;
                            box-sizing: border-box;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                            color-adjust: exact !important;
                        }
                        html {
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                            color-adjust: exact !important;
                        }
                        body {
                            font-family: Arial, sans-serif;
                            font-size: 11px;
                            color: #333;
                            padding: 20px;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .header { text-align: center; margin-bottom: 30px; padding-bottom: 15px; border-bottom: 3px solid #3498db; }
                        .header h1 { font-size: 24px; color: #2c3e50; margin-bottom: 5px; }
                        .header h2 { font-size: 18px; color: #3498db; margin-bottom: 10px; }
                        .order-section {
                            margin-bottom: 30px;
                            page-break-inside: avoid;
                            border: 2px solid #ddd;
                            border-radius: 5px;
                            padding: 15px;
                            background: #f9f9f9 !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .order-header-print { margin-bottom: 15px; padding-bottom: 10px; border-bottom: 2px solid #e0e0e0; }
                        .order-header-print h3 { font-size: 16px; color: #2c3e50; margin-bottom: 8px; }
                        .order-header-print p { font-size: 10px; margin-bottom: 3px; }
                        .items-table {
                            width: 100%;
                            border-collapse: collapse;
                            margin-bottom: 10px;
                            table-layout: fixed;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .items-table thead {
                            background-color: #34495e !important;
                            color: white !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .items-table thead th {
                            background-color: #34495e !important;
                            color: white !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .items-table th {
                            padding: 8px 5px;
                            text-align: left;
                            font-size: 10px;
                            background-color: #34495e !important;
                            color: white !important;
                        }
                        .items-table th:nth-child(1) { width: 50%; text-align: left; }
                        .items-table th:nth-child(2) { width: 15%; text-align: center; }
                        .items-table th:nth-child(3) { width: 17.5%; text-align: right; }
                        .items-table th:nth-child(4) { width: 17.5%; text-align: right; }
                        .items-table td { padding: 6px 5px; border-bottom: 1px solid #ddd; font-size: 10px; }
                        .items-table td:nth-child(1) { text-align: left; }
                        .items-table td:nth-child(2) { text-align: center; }
                        .items-table td:nth-child(3) { text-align: right; }
                        .items-table td:nth-child(4) { text-align: right; }
                        .items-table tbody tr:nth-child(even) {
                            background-color: #f8f9fa !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .text-center { text-align: center; }
                        .text-right { text-align: right; }
                        .status-badge {
                            display: inline-block;
                            padding: 3px 8px;
                            border-radius: 3px;
                            font-size: 9px;
                            font-weight: bold;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .status-pending {
                            background-color: #fff3cd !important;
                            color: #856404 !important;
                            border: 1px solid #856404;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .status-processed {
                            background-color: #d4edda !important;
                            color: #155724 !important;
                            border: 1px solid #155724;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .order-totals { padding-top: 10px; border-top: 1px solid #ddd; font-size: 10px; }
                        .summary-box {
                            margin-top: 20px;
                            padding: 15px;
                            background-color: #e3f2fd !important;
                            border: 2px solid #2196f3;
                            border-radius: 5px;
                            page-break-inside: avoid;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .summary-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 12px; }
                        .footer { margin-top: 30px; text-align: center; font-size: 9px; color: #7f8c8d; padding-top: 10px; border-top: 1px solid #ddd; }

                        @media print {
                            body {
                                padding: 10px;
                                -webkit-print-color-adjust: exact !important;
                                print-color-adjust: exact !important;
                            }
                            * {
                                -webkit-print-color-adjust: exact !important;
                                print-color-adjust: exact !important;
                                color-adjust: exact !important;
                            }
                            .items-table thead,
                            .items-table thead th {
                                background-color: #34495e !important;
                                color: white !important;
                                -webkit-print-color-adjust: exact !important;
                            }
                            .status-pending {
                                background-color: #fff3cd !important;
                                color: #856404 !important;
                            }
                            .status-processed {
                                background-color: #d4edda !important;
                                color: #155724 !important;
                            }
                            .summary-box {
                                background-color: #e3f2fd !important;
                            }
                            .order-section {
                                background: #f9f9f9 !important;
                            }
                            .items-table tbody tr:nth-child(even) {
                                background-color: #f8f9fa !important;
                            }
                        }
                    </style>
                </head>
                <body>
                    <div class="header" style="display: flex; justify-content: space-between; align-items: start;">
                        <div>
                            <h1>ZENFOO - PRE ORDERS</h1>
                            <h2>${this.storeName}</h2>
                            <p>Order-wise Items Breakdown | Generated on ${moment().format('D MMM YYYY, h:mm A')}</p>
                        </div>
                        ${this.totalWeight ? `<div style="text-align: right; margin-top: 10px;">
                            <h3 style="color: #e67e22; margin: 0;">Total Weight</h3>
                            <h2 style="color: #2c3e50; margin: 5px 0 0 0;">${this.totalWeight}</h2>
                        </div>` : ''}
                    </div>

                    ${ordersHTML}

                    <div class="summary-box">
                        <h3 style="margin-bottom: 10px;">Summary</h3>
                        <div class="summary-row">
                            <span>Total Orders:</span>
                            <strong>${this.orders.length}</strong>
                        </div>
                        <div class="summary-row">
                            <span>Total Items:</span>
                            <strong>${this.totalItems}</strong>
                        </div>
                        ${this.totalWeight ? `<div class="summary-row">
                            <span>Total Weight:</span>
                            <strong>${this.totalWeight}</strong>
                        </div>` : ''}
                        <div class="summary-row">
                            <span>Total Amount:</span>
                            <strong>₹${this.totalAmount.toFixed(2)}</strong>
                        </div>
                    </div>

                    <div class="footer">
                        <p>This is a computer-generated document. No signature is required.</p>
                        <p>&copy; ${new Date().getFullYear()} Zenfoo. All rights reserved.</p>
                    </div>
                </body>
                </html>
            `;
        },

        generateSellerWisePrintContent() {
            // Group orders by seller
            const ordersBySeller = {};
            const assignedOrders = this.orders.filter(order => order.is_seller_assigned);

            assignedOrders.forEach(order => {
                const sellerName = order.assigned_seller_name || 'Unknown Seller';
                if (!ordersBySeller[sellerName]) {
                    ordersBySeller[sellerName] = [];
                }
                ordersBySeller[sellerName].push(order);
            });

            let sellersHTML = '';
            let totalOrders = 0;
            let totalAmount = 0;
            let totalWeightGrams = 0;

            Object.keys(ordersBySeller).sort().forEach(sellerName => {
                const sellerOrders = ordersBySeller[sellerName];
                const sellerTotal = sellerOrders.reduce((sum, order) => sum + parseFloat(order.final_total || 0), 0);
                totalOrders += sellerOrders.length;
                totalAmount += sellerTotal;

                // Calculate total weight for this seller's orders
                sellerOrders.forEach(order => {
                    let orderGrams = 0;
                    if (order.items && order.items.length > 0) {
                        order.items.forEach(item => {
                            const unitId = item.variant_stock_unit_id;
                            const measurement = parseFloat(item.variant_measurement || 0);
                            const quantity = parseFloat(item.quantity || 0);
                            if (unitId === 1) {
                                orderGrams += (measurement * 1000) * quantity;
                            } else if (unitId === 2) {
                                orderGrams += measurement * quantity;
                            }
                        });
                    }
                    totalWeightGrams += orderGrams;
                });

                let ordersHTML = '';
                sellerOrders.forEach(order => {
                    let itemsHTML = '';
                    // Add regular items
                    if (order.items && order.items.length > 0) {
                        order.items.forEach(item => {
                            itemsHTML += `
                                <tr>
                                    <td>${item.name || item.product_name}</td>
                                    <td class="text-center">${item.quantity}</td>
                                    <td class="text-right">₹${parseFloat(item.price).toFixed(2)}</td>
                                    <td class="text-right"><strong>₹${parseFloat(item.sub_total).toFixed(2)}</strong></td>
                                </tr>
                            `;
                        });
                    }
                    // Add combo items
                    if (order.combo_items && order.combo_items.length > 0) {
                        order.combo_items.forEach(combo => {
                            const comboProducts = this.getComboProductsForStore(combo, this.storeId);
                            const comboSubtotal = this.getComboSubtotalForStore(combo, this.storeId);

                            itemsHTML += `
                                <tr style="background-color: #e3f2fd !important; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">
                                    <td colspan="4">
                                        <strong>${combo.combo_name}</strong>
                                        <span style="background-color: #0dcaf0 !important; color: white !important; padding: 2px 6px; border-radius: 3px; font-size: 8px; margin-left: 8px; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">COMBO (${comboProducts.length} items)</span>
                                        <span style="float: right;"><strong>₹${comboSubtotal.toFixed(2)}</strong></span>
                                    </td>
                                </tr>
                            `;

                            if (comboProducts.length > 0) {
                                comboProducts.forEach(product => {
                                    const unitLabel = this.getUnitLabel(product.variant_stock_unit_id);
                                    itemsHTML += `
                                        <tr style="background-color: #f8f9fa !important; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">
                                            <td style="padding-left: 30px;">
                                                ${product.product_name}
                                                <br><small style="color: #6c757d;">${product.variant_measurement} ${unitLabel}</small>
                                            </td>
                                            <td class="text-center">${product.quantity}</td>
                                            <td class="text-right">₹${parseFloat(product.price).toFixed(2)}</td>
                                            <td class="text-right">₹${parseFloat(product.sub_total).toFixed(2)}</td>
                                        </tr>
                                    `;
                                });
                            }
                        });
                    }

                    const statusLabel = this.getStatusLabel(order.active_status);
                    const statusClass = order.active_status == 12 ? 'status-pending' : 'status-processed';
                    const orderWeight = this.calculateOrderTotalWeight(order);

                    ordersHTML += `
                        <div class="order-section">
                            <div class="order-header-print">
                                <div style="display: flex; justify-content: space-between; align-items: center;">
                                    <div>
                                        <h4>Order #${order.id}</h4>
                                        <p><strong>Customer:</strong> ${order.user_name || 'Guest'} | <strong>Mobile:</strong> ${order.mobile}</p>
                                        <p><strong>Placed:</strong> ${order.preorder_placed_at_formatted} | <strong>Process:</strong> ${order.preorder_process_date_formatted}</p>
                                        ${orderWeight ? `<p><strong>Total Weight:</strong> <span style="background-color: #ffc107; color: #000; padding: 2px 8px; border-radius: 3px; font-size: 10px;">${orderWeight}</span></p>` : ''}
                                    </div>
                                    <div style="text-align: right;">
                                        <span class="status-badge ${statusClass}">${statusLabel}</span>
                                        <p style="font-size: 14px; margin-top: 5px;"><strong>₹${parseFloat(order.final_total).toFixed(2)}</strong></p>
                                    </div>
                                </div>
                            </div>
                            <table class="items-table">
                                <thead>
                                    <tr>
                                        <th>Item</th>
                                        <th class="text-center">Qty</th>
                                        <th class="text-right">Price</th>
                                        <th class="text-right">Subtotal</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${itemsHTML || '<tr><td colspan="4" class="text-center">No items</td></tr>'}
                                </tbody>
                            </table>
                            <div class="order-totals">
                                <div style="display: flex; justify-content: space-between;">
                                    <span>
                                        <strong>Payment:</strong> ${order.payment_method}
                                        ${orderWeight ? ` | <strong>Weight:</strong> ${orderWeight}` : ''}
                                    </span>
                                    <div style="text-align: right;">
                                        <div style="font-size: 12px;"><strong>Total: ₹${parseFloat(order.final_total).toFixed(2)}</strong></div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    `;
                });

                sellersHTML += `
                    <div class="seller-section" style="page-break-before: auto; margin-bottom: 40px;">
                        <div class="seller-header">
                            <h2 style="color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; margin-bottom: 20px;">
                                <i class="fa fa-user"></i> ${sellerName}
                                <span style="float: right; font-size: 18px; color: #27ae60;">₹${sellerTotal.toFixed(2)}</span>
                            </h2>
                            <p style="color: #7f8c8d; margin-bottom: 20px; font-size: 12px;">
                                <strong>Orders:</strong> ${sellerOrders.length} |
                                <strong>Total Amount:</strong> ₹${sellerTotal.toFixed(2)}
                            </p>
                        </div>
                        ${ordersHTML}
                    </div>
                `;
            });

            // Format total weight
            let totalWeightFormatted = null;
            if (totalWeightGrams > 0) {
                const kg = Math.floor(totalWeightGrams / 1000);
                const gm = Math.round(totalWeightGrams % 1000);
                if (kg > 0 && gm > 0) {
                    totalWeightFormatted = `${kg}kg + ${gm}gm`;
                } else if (kg > 0) {
                    totalWeightFormatted = `${kg}kg`;
                } else {
                    totalWeightFormatted = `${gm}gm`;
                }
            }

            return `
                <!DOCTYPE html>
                <html>
                <head>
                    <title>${this.storeName} - Seller-wise Pre Orders</title>
                    <style>
                        @page { size: A4; margin: 1cm; }
                        * {
                            margin: 0;
                            padding: 0;
                            box-sizing: border-box;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                            color-adjust: exact !important;
                        }
                        html {
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                            color-adjust: exact !important;
                        }
                        body {
                            font-family: Arial, sans-serif;
                            font-size: 11px;
                            color: #333;
                            padding: 20px;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .header { text-align: center; margin-bottom: 30px; padding-bottom: 15px; border-bottom: 3px solid #3498db; }
                        .header h1 { font-size: 24px; color: #2c3e50; margin-bottom: 5px; }
                        .header h2 { font-size: 18px; color: #3498db; margin-bottom: 10px; }
                        .seller-section { margin-bottom: 40px; }
                        .order-section {
                            margin-bottom: 20px;
                            page-break-inside: avoid;
                            border: 2px solid #ddd;
                            border-radius: 5px;
                            padding: 15px;
                            background: #f9f9f9 !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .order-header-print { margin-bottom: 15px; padding-bottom: 10px; border-bottom: 2px solid #e0e0e0; }
                        .order-header-print h4 { font-size: 14px; color: #2c3e50; margin-bottom: 8px; }
                        .order-header-print p { font-size: 10px; margin-bottom: 3px; }
                        .items-table {
                            width: 100%;
                            border-collapse: collapse;
                            margin-bottom: 10px;
                            table-layout: fixed;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .items-table thead {
                            background-color: #34495e !important;
                            color: white !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .items-table thead th {
                            background-color: #34495e !important;
                            color: white !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .items-table th {
                            padding: 8px 5px;
                            text-align: left;
                            font-size: 10px;
                            background-color: #34495e !important;
                            color: white !important;
                        }
                        .items-table th:nth-child(1) { width: 50%; text-align: left; }
                        .items-table th:nth-child(2) { width: 15%; text-align: center; }
                        .items-table th:nth-child(3) { width: 17.5%; text-align: right; }
                        .items-table th:nth-child(4) { width: 17.5%; text-align: right; }
                        .items-table td { padding: 6px 5px; border-bottom: 1px solid #ddd; font-size: 10px; }
                        .items-table td:nth-child(1) { text-align: left; }
                        .items-table td:nth-child(2) { text-align: center; }
                        .items-table td:nth-child(3) { text-align: right; }
                        .items-table td:nth-child(4) { text-align: right; }
                        .items-table tbody tr:nth-child(even) {
                            background-color: #f8f9fa !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .text-center { text-align: center; }
                        .text-right { text-align: right; }
                        .status-badge {
                            display: inline-block;
                            padding: 3px 8px;
                            border-radius: 3px;
                            font-size: 9px;
                            font-weight: bold;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .status-pending {
                            background-color: #fff3cd !important;
                            color: #856404 !important;
                            border: 1px solid #856404;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .status-processed {
                            background-color: #d4edda !important;
                            color: #155724 !important;
                            border: 1px solid #155724;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .order-totals { padding-top: 10px; border-top: 1px solid #ddd; font-size: 10px; }
                        .summary-box {
                            margin-top: 20px;
                            padding: 15px;
                            background-color: #e3f2fd !important;
                            border: 2px solid #2196f3;
                            border-radius: 5px;
                            page-break-inside: avoid;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .summary-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 12px; }
                        .footer { margin-top: 30px; text-align: center; font-size: 9px; color: #7f8c8d; padding-top: 10px; border-top: 1px solid #ddd; }

                        @media print {
                            body {
                                padding: 10px;
                                -webkit-print-color-adjust: exact !important;
                                print-color-adjust: exact !important;
                            }
                            * {
                                -webkit-print-color-adjust: exact !important;
                                print-color-adjust: exact !important;
                                color-adjust: exact !important;
                            }
                            .items-table thead,
                            .items-table thead th {
                                background-color: #34495e !important;
                                color: white !important;
                                -webkit-print-color-adjust: exact !important;
                            }
                            .status-pending {
                                background-color: #fff3cd !important;
                                color: #856404 !important;
                            }
                            .status-processed {
                                background-color: #d4edda !important;
                                color: #155724 !important;
                            }
                            .summary-box {
                                background-color: #e3f2fd !important;
                            }
                            .order-section {
                                background: #f9f9f9 !important;
                            }
                            .items-table tbody tr:nth-child(even) {
                                background-color: #f8f9fa !important;
                            }
                        }
                    </style>
                </head>
                <body>
                    <div class="header" style="display: flex; justify-content: space-between; align-items: start;">
                        <div>
                            <h1>ZENFOO - SELLER-WISE PRE ORDERS</h1>
                            <h2>${this.storeName}</h2>
                            <p>Seller-wise Orders Breakdown | Generated on ${moment().format('D MMM YYYY, h:mm A')}</p>
                        </div>
                        ${totalWeightFormatted ? `<div style="text-align: right; margin-top: 10px;">
                            <h3 style="color: #e67e22; margin: 0;">Total Weight</h3>
                            <h2 style="color: #2c3e50; margin: 5px 0 0 0;">${totalWeightFormatted}</h2>
                        </div>` : ''}
                    </div>

                    ${sellersHTML}

                    <div class="summary-box">
                        <h3 style="margin-bottom: 10px;">Overall Summary</h3>
                        <div class="summary-row">
                            <span>Total Sellers:</span>
                            <strong>${Object.keys(ordersBySeller).length}</strong>
                        </div>
                        <div class="summary-row">
                            <span>Total Assigned Orders:</span>
                            <strong>${totalOrders}</strong>
                        </div>
                        ${totalWeightFormatted ? `<div class="summary-row">
                            <span>Total Weight:</span>
                            <strong>${totalWeightFormatted}</strong>
                        </div>` : ''}
                        <div class="summary-row">
                            <span>Total Amount:</span>
                            <strong>₹${totalAmount.toFixed(2)}</strong>
                        </div>
                    </div>

                    <div class="footer">
                        <p>This is a computer-generated document. No signature is required.</p>
                        <p>&copy; ${new Date().getFullYear()} Zenfoo. All rights reserved.</p>
                    </div>
                </body>
                </html>
            `;
        },

        generateSingleSellerPrintContent(sellerName) {
            // Filter orders for the selected seller
            const sellerOrders = this.orders.filter(order =>
                order.is_seller_assigned && order.assigned_seller_name === sellerName
            );

            if (sellerOrders.length === 0) {
                return `
                    <!DOCTYPE html>
                    <html>
                    <body>
                        <p>No orders found for seller: ${sellerName}</p>
                    </body>
                    </html>
                `;
            }

            const sellerTotal = sellerOrders.reduce((sum, order) => sum + parseFloat(order.final_total || 0), 0);

            // Calculate total weight for this seller's orders
            let totalWeightGrams = 0;
            sellerOrders.forEach(order => {
                if (order.items && order.items.length > 0) {
                    order.items.forEach(item => {
                        const unitId = item.variant_stock_unit_id;
                        const measurement = parseFloat(item.variant_measurement || 0);
                        const quantity = parseFloat(item.quantity || 0);
                        if (unitId === 1) {
                            totalWeightGrams += (measurement * 1000) * quantity;
                        } else if (unitId === 2) {
                            totalWeightGrams += measurement * quantity;
                        }
                    });
                }
            });

            // Format total weight
            let totalWeightFormatted = null;
            if (totalWeightGrams > 0) {
                const kg = Math.floor(totalWeightGrams / 1000);
                const gm = Math.round(totalWeightGrams % 1000);
                if (kg > 0 && gm > 0) {
                    totalWeightFormatted = `${kg}kg + ${gm}gm`;
                } else if (kg > 0) {
                    totalWeightFormatted = `${kg}kg`;
                } else {
                    totalWeightFormatted = `${gm}gm`;
                }
            }

            let ordersHTML = '';
            sellerOrders.forEach(order => {
                let itemsHTML = '';
                // Add regular items
                if (order.items && order.items.length > 0) {
                    order.items.forEach(item => {
                        itemsHTML += `
                            <tr>
                                <td>${item.name || item.product_name}</td>
                                <td class="text-center">${item.quantity}</td>
                                <td class="text-right">₹${parseFloat(item.price).toFixed(2)}</td>
                                <td class="text-right"><strong>₹${parseFloat(item.sub_total).toFixed(2)}</strong></td>
                            </tr>
                        `;
                    });
                }
                // Add combo items
                if (order.combo_items && order.combo_items.length > 0) {
                    order.combo_items.forEach(combo => {
                        const comboProducts = this.getComboProductsForStore(combo, this.storeId);
                        const comboSubtotal = this.getComboSubtotalForStore(combo, this.storeId);

                        itemsHTML += `
                            <tr style="background-color: #e3f2fd !important; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">
                                <td colspan="4">
                                    <strong>${combo.combo_name}</strong>
                                    <span style="background-color: #0dcaf0 !important; color: white !important; padding: 2px 6px; border-radius: 3px; font-size: 8px; margin-left: 8px; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">COMBO (${comboProducts.length} items)</span>
                                    <span style="float: right;"><strong>₹${comboSubtotal.toFixed(2)}</strong></span>
                                </td>
                            </tr>
                        `;

                        if (comboProducts.length > 0) {
                            comboProducts.forEach(product => {
                                const unitLabel = this.getUnitLabel(product.variant_stock_unit_id);
                                itemsHTML += `
                                    <tr style="background-color: #f8f9fa !important; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important;">
                                        <td style="padding-left: 30px;">
                                            ${product.product_name}
                                            <br><small style="color: #6c757d;">${product.variant_measurement} ${unitLabel}</small>
                                        </td>
                                        <td class="text-center">${product.quantity}</td>
                                        <td class="text-right">₹${parseFloat(product.price).toFixed(2)}</td>
                                        <td class="text-right">₹${parseFloat(product.sub_total).toFixed(2)}</td>
                                    </tr>
                                `;
                            });
                        }
                    });
                }

                const statusLabel = this.getStatusLabel(order.active_status);
                const statusClass = order.active_status == 12 ? 'status-pending' : 'status-processed';
                const orderWeight = this.calculateOrderTotalWeight(order);

                ordersHTML += `
                    <div class="order-section">
                        <div class="order-header-print">
                            <div style="display: flex; justify-content: space-between; align-items: center;">
                                <div>
                                    <h4>Order #${order.id}</h4>
                                    <p><strong>Customer:</strong> ${order.user_name || 'Guest'} | <strong>Mobile:</strong> ${order.mobile}</p>
                                    <p><strong>Placed:</strong> ${order.preorder_placed_at_formatted} | <strong>Process:</strong> ${order.preorder_process_date_formatted}</p>
                                    ${orderWeight ? `<p><strong>Total Weight:</strong> <span style="background-color: #ffc107; color: #000; padding: 2px 8px; border-radius: 3px; font-size: 10px;">${orderWeight}</span></p>` : ''}
                                </div>
                                <div style="text-align: right;">
                                    <span class="status-badge ${statusClass}">${statusLabel}</span>
                                    <p style="font-size: 14px; margin-top: 5px;"><strong>₹${parseFloat(order.final_total).toFixed(2)}</strong></p>
                                </div>
                            </div>
                        </div>
                        <table class="items-table">
                            <thead>
                                <tr>
                                    <th>Item</th>
                                    <th class="text-center">Qty</th>
                                    <th class="text-right">Price</th>
                                    <th class="text-right">Subtotal</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${itemsHTML || '<tr><td colspan="4" class="text-center">No items</td></tr>'}
                            </tbody>
                        </table>
                        <div class="order-totals">
                            <div style="display: flex; justify-content: space-between;">
                                <span>
                                    <strong>Payment:</strong> ${order.payment_method}
                                    ${orderWeight ? ` | <strong>Weight:</strong> ${orderWeight}` : ''}
                                </span>
                                <div style="text-align: right;">
                                    <div style="font-size: 12px;"><strong>Total: ₹${parseFloat(order.final_total).toFixed(2)}</strong></div>
                                </div>
                            </div>
                        </div>
                    </div>
                `;
            });

            return `
                <!DOCTYPE html>
                <html>
                <head>
                    <title>${this.storeName} - ${sellerName} Orders</title>
                    <style>
                        @page { size: A4; margin: 1cm; }
                        * {
                            margin: 0;
                            padding: 0;
                            box-sizing: border-box;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                            color-adjust: exact !important;
                        }
                        html {
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                            color-adjust: exact !important;
                        }
                        body {
                            font-family: Arial, sans-serif;
                            font-size: 11px;
                            color: #333;
                            padding: 20px;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .header { text-align: center; margin-bottom: 30px; padding-bottom: 15px; border-bottom: 3px solid #3498db; }
                        .header h1 { font-size: 24px; color: #2c3e50; margin-bottom: 5px; }
                        .header h2 { font-size: 20px; color: #27ae60; margin-bottom: 5px; }
                        .header h3 { font-size: 16px; color: #3498db; margin-bottom: 10px; }
                        .order-section {
                            margin-bottom: 20px;
                            page-break-inside: avoid;
                            border: 2px solid #ddd;
                            border-radius: 5px;
                            padding: 15px;
                            background: #f9f9f9 !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .order-header-print { margin-bottom: 15px; padding-bottom: 10px; border-bottom: 2px solid #e0e0e0; }
                        .order-header-print h4 { font-size: 14px; color: #2c3e50; margin-bottom: 8px; }
                        .order-header-print p { font-size: 10px; margin-bottom: 3px; }
                        .items-table {
                            width: 100%;
                            border-collapse: collapse;
                            margin-bottom: 10px;
                            table-layout: fixed;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .items-table thead {
                            background-color: #34495e !important;
                            color: white !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .items-table thead th {
                            background-color: #34495e !important;
                            color: white !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .items-table th {
                            padding: 8px 5px;
                            text-align: left;
                            font-size: 10px;
                            background-color: #34495e !important;
                            color: white !important;
                        }
                        .items-table th:nth-child(1) { width: 50%; text-align: left; }
                        .items-table th:nth-child(2) { width: 15%; text-align: center; }
                        .items-table th:nth-child(3) { width: 17.5%; text-align: right; }
                        .items-table th:nth-child(4) { width: 17.5%; text-align: right; }
                        .items-table td { padding: 6px 5px; border-bottom: 1px solid #ddd; font-size: 10px; }
                        .items-table td:nth-child(1) { text-align: left; }
                        .items-table td:nth-child(2) { text-align: center; }
                        .items-table td:nth-child(3) { text-align: right; }
                        .items-table td:nth-child(4) { text-align: right; }
                        .items-table tbody tr:nth-child(even) {
                            background-color: #f8f9fa !important;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .text-center { text-align: center; }
                        .text-right { text-align: right; }
                        .status-badge {
                            display: inline-block;
                            padding: 3px 8px;
                            border-radius: 3px;
                            font-size: 9px;
                            font-weight: bold;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .status-pending {
                            background-color: #fff3cd !important;
                            color: #856404 !important;
                            border: 1px solid #856404;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .status-processed {
                            background-color: #d4edda !important;
                            color: #155724 !important;
                            border: 1px solid #155724;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .order-totals { padding-top: 10px; border-top: 1px solid #ddd; font-size: 10px; }
                        .summary-box {
                            margin-top: 20px;
                            padding: 15px;
                            background-color: #d4edda !important;
                            border: 2px solid #27ae60;
                            border-radius: 5px;
                            page-break-inside: avoid;
                            -webkit-print-color-adjust: exact !important;
                            print-color-adjust: exact !important;
                        }
                        .summary-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 12px; }
                        .footer { margin-top: 30px; text-align: center; font-size: 9px; color: #7f8c8d; padding-top: 10px; border-top: 1px solid #ddd; }

                        @media print {
                            body {
                                padding: 10px;
                                -webkit-print-color-adjust: exact !important;
                                print-color-adjust: exact !important;
                            }
                            * {
                                -webkit-print-color-adjust: exact !important;
                                print-color-adjust: exact !important;
                                color-adjust: exact !important;
                            }
                            .items-table thead,
                            .items-table thead th {
                                background-color: #34495e !important;
                                color: white !important;
                                -webkit-print-color-adjust: exact !important;
                            }
                            .status-pending {
                                background-color: #fff3cd !important;
                                color: #856404 !important;
                            }
                            .status-processed {
                                background-color: #d4edda !important;
                                color: #155724 !important;
                            }
                            .summary-box {
                                background-color: #d4edda !important;
                            }
                            .order-section {
                                background: #f9f9f9 !important;
                            }
                            .items-table tbody tr:nth-child(even) {
                                background-color: #f8f9fa !important;
                            }
                        }
                    </style>
                </head>
                <body>
                    <div class="header" style="display: flex; justify-content: space-between; align-items: start;">
                        <div>
                            <h1>ZENFOO - PRE ORDERS</h1>
                            <h2><i class="fa fa-user"></i> ${sellerName}</h2>
                            <h3>${this.storeName}</h3>
                            <p>Generated on ${moment().format('D MMM YYYY, h:mm A')}</p>
                        </div>
                        ${totalWeightFormatted ? `<div style="text-align: right; margin-top: 10px;">
                            <h3 style="color: #e67e22; margin: 0;">Total Weight</h3>
                            <h2 style="color: #2c3e50; margin: 5px 0 0 0;">${totalWeightFormatted}</h2>
                        </div>` : ''}
                    </div>

                    ${ordersHTML}

                    <div class="summary-box">
                        <h3 style="margin-bottom: 10px; color: #27ae60;">Seller Summary</h3>
                        <div class="summary-row">
                            <span>Seller Name:</span>
                            <strong>${sellerName}</strong>
                        </div>
                        <div class="summary-row">
                            <span>Total Orders:</span>
                            <strong>${sellerOrders.length}</strong>
                        </div>
                        ${totalWeightFormatted ? `<div class="summary-row">
                            <span>Total Weight:</span>
                            <strong>${totalWeightFormatted}</strong>
                        </div>` : ''}
                        <div class="summary-row">
                            <span>Total Amount:</span>
                            <strong>₹${sellerTotal.toFixed(2)}</strong>
                        </div>
                    </div>

                    <div class="footer">
                        <p>This is a computer-generated document. No signature is required.</p>
                        <p>&copy; ${new Date().getFullYear()} Zenfoo. All rights reserved.</p>
                    </div>
                </body>
                </html>
            `;
        },

        // ============================================
        // DIRECT USB THERMAL PRINTER METHODS
        // ============================================

        async printAllOrdersDirect() {
            if (!('serial' in navigator)) {
                alert('Direct USB printing is not supported in this browser. Please use Chrome or Edge.');
                return;
            }

            try {
                const port = await navigator.serial.requestPort();
                await port.open({ baudRate: 9600 });
                const writer = port.writable.getWriter();
                const encoder = new TextEncoder();

                // ESC/POS Commands
                const ESC = '\x1B';
                const GS = '\x1D';
                const INIT = ESC + '@';
                const ALIGN_CENTER = ESC + 'a' + '\x01';
                const ALIGN_LEFT = ESC + 'a' + '\x00';
                const BOLD_ON = ESC + 'E' + '\x01';
                const BOLD_OFF = ESC + 'E' + '\x00';
                const DOUBLE_HEIGHT = GS + '!' + '\x10';
                const NORMAL_SIZE = GS + '!' + '\x00';
                const CUT = GS + 'V' + '\x00';

                const W = 42; // Paper width in characters
                const LINE = '-'.repeat(W) + '\n';
                const DOUBLE_LINE = '='.repeat(W) + '\n';

                // Helper functions
                const padRight = (str, len) => {
                    const s = String(str);
                    return s.length >= len ? s.substring(0, len) : s + ' '.repeat(len - s.length);
                };

                const padLeft = (str, len) => {
                    const s = String(str);
                    return s.length >= len ? s.substring(0, len) : ' '.repeat(len - s.length) + s;
                };

                const formatRow = (label, value) => {
                    const valStr = String(value);
                    const maxLabelLen = W - valStr.length - 1;
                    const truncLabel = label.length > maxLabelLen ? label.substring(0, maxLabelLen) : label;
                    const spaces = W - truncLabel.length - valStr.length;
                    return truncLabel + ' '.repeat(Math.max(1, spaces)) + valStr + '\n';
                };

                const wrapText = (text, maxLen) => {
                    if (!text) return '';
                    const words = text.split(' ');
                    let lines = [];
                    let currentLine = '';
                    
                    words.forEach(word => {
                        if ((currentLine + word).length <= maxLen) {
                            currentLine += (currentLine ? ' ' : '') + word;
                        } else {
                            if (currentLine) lines.push(currentLine);
                            currentLine = word.substring(0, maxLen);
                        }
                    });
                    if (currentLine) lines.push(currentLine);
                    return lines.join('\n') + '\n';
                };

                let output = '';
                output += INIT;
                output += ALIGN_CENTER;
                output += DOUBLE_HEIGHT + BOLD_ON;
                output += 'ZENFOO\n';
                output += NORMAL_SIZE + BOLD_OFF;
                output += 'PRE ORDERS - ALL ORDERS\n';
                output += this.storeName + '\n';
                output += DOUBLE_LINE;
                output += moment().format('D MMM YYYY, h:mm A') + '\n';
                output += DOUBLE_LINE;

                output += ALIGN_LEFT;

                // Print each order
                this.orders.forEach((order, index) => {
                    output += BOLD_ON + `ORDER #${order.id}\n` + BOLD_OFF;
                    output += formatRow('Customer', order.user_name || 'Guest');
                    output += formatRow('Mobile', order.mobile);
                    output += formatRow('Placed', order.preorder_placed_at_formatted);
                    output += formatRow('Process', order.preorder_process_date_formatted);
                    output += formatRow('Status', this.getStatusLabel(order.active_status));

                    if (order.is_seller_assigned) {
                        output += formatRow('Seller', order.assigned_seller_name);
                    }

                    const orderWeight = this.calculateOrderTotalWeight(order);
                    if (orderWeight) {
                        output += formatRow('Total Weight', orderWeight);
                    }

                    output += LINE;

                    // Items
                    if (order.items && order.items.length > 0) {
                        output += BOLD_ON + 'ITEMS:\n' + BOLD_OFF;
                        order.items.forEach(item => {
                            output += `${item.name || item.product_name}\n`;
                            output += formatRow(`  ${item.quantity}x Rs.${parseFloat(item.price).toFixed(2)}`, `Rs.${parseFloat(item.sub_total).toFixed(2)}`);
                        });
                    }

                    // Combo items
                    if (order.combo_items && order.combo_items.length > 0) {
                        order.combo_items.forEach(combo => {
                            const comboProducts = this.getComboProductsForStore(combo, this.storeId);
                            const comboSubtotal = this.getComboSubtotalForStore(combo, this.storeId);
                            output += BOLD_ON + `COMBO: ${combo.combo_name}\n` + BOLD_OFF;
                            comboProducts.forEach(product => {
                                output += `  ${product.product_name}\n`;
                                output += `  ${product.quantity}x Rs.${parseFloat(product.price).toFixed(2)}\n`;
                            });
                            output += formatRow('  Combo Total', `Rs.${comboSubtotal.toFixed(2)}`);
                        });
                    }

                    output += LINE;
                    output += BOLD_ON;
                    output += formatRow('TOTAL', `Rs.${parseFloat(order.final_total).toFixed(2)}`);
                    output += BOLD_OFF;
                    output += DOUBLE_LINE;
                    
                    if (index < this.orders.length - 1) {
                        output += '\n';
                    }
                });

                // Summary
                output += ALIGN_CENTER;
                output += BOLD_ON + 'SUMMARY\n' + BOLD_OFF;
                output += ALIGN_LEFT;
                output += formatRow('Total Orders', this.orders.length);
                output += formatRow('Total Items', this.totalItems);
                output += formatRow('Total Amount', `Rs.${this.totalAmount.toFixed(2)}`);
                output += '\n\n';
                output += ALIGN_CENTER;
                output += 'Thank you!\n';
                output += 'www.zenfoo.in\n';
                output += '\n\n\n';

                await writer.write(encoder.encode(output));
                await writer.write(encoder.encode(CUT));

                writer.releaseLock();
                await port.close();

                this.$toast.success('Print sent to thermal printer successfully!');

            } catch (error) {
                console.error('Print error:', error);
                if (error.name === 'NotFoundError') {
                    alert('No printer selected. Please select your thermal printer.');
                } else {
                    alert('Print failed: ' + error.message);
                }
            }
        },

        async printSellerWiseOrdersDirect() {
            if (!('serial' in navigator)) {
                alert('Direct USB printing is not supported in this browser. Please use Chrome or Edge.');
                return;
            }

            try {
                const port = await navigator.serial.requestPort();
                await port.open({ baudRate: 9600 });
                const writer = port.writable.getWriter();
                const encoder = new TextEncoder();

                const ESC = '\x1B';
                const GS = '\x1D';
                const INIT = ESC + '@';
                const ALIGN_CENTER = ESC + 'a' + '\x01';
                const ALIGN_LEFT = ESC + 'a' + '\x00';
                const BOLD_ON = ESC + 'E' + '\x01';
                const BOLD_OFF = ESC + 'E' + '\x00';
                const DOUBLE_HEIGHT = GS + '!' + '\x10';
                const NORMAL_SIZE = GS + '!' + '\x00';
                const CUT = GS + 'V' + '\x00';

                const W = 42;
                const LINE = '-'.repeat(W) + '\n';
                const DOUBLE_LINE = '='.repeat(W) + '\n';

                const padRight = (str, len) => {
                    const s = String(str);
                    return s.length >= len ? s.substring(0, len) : s + ' '.repeat(len - s.length);
                };

                const padLeft = (str, len) => {
                    const s = String(str);
                    return s.length >= len ? s.substring(0, len) : ' '.repeat(len - s.length) + s;
                };

                const formatRow = (label, value) => {
                    const valStr = String(value);
                    const maxLabelLen = W - valStr.length - 1;
                    const truncLabel = label.length > maxLabelLen ? label.substring(0, maxLabelLen) : label;
                    const spaces = W - truncLabel.length - valStr.length;
                    return truncLabel + ' '.repeat(Math.max(1, spaces)) + valStr + '\n';
                };

                // Group orders by seller
                const ordersBySeller = {};
                const assignedOrders = this.orders.filter(order => order.is_seller_assigned);

                assignedOrders.forEach(order => {
                    const sellerName = order.assigned_seller_name || 'Unknown Seller';
                    if (!ordersBySeller[sellerName]) {
                        ordersBySeller[sellerName] = [];
                    }
                    ordersBySeller[sellerName].push(order);
                });

                let output = '';
                output += INIT;
                output += ALIGN_CENTER;
                output += DOUBLE_HEIGHT + BOLD_ON;
                output += 'ZENFOO\n';
                output += NORMAL_SIZE + BOLD_OFF;
                output += 'PRE ORDERS - SELLER WISE\n';
                output += this.storeName + '\n';
                output += DOUBLE_LINE;
                output += moment().format('D MMM YYYY, h:mm A') + '\n';
                output += DOUBLE_LINE;

                output += ALIGN_LEFT;

                // Print each seller's orders
                Object.keys(ordersBySeller).sort().forEach((sellerName, sellerIndex) => {
                    const sellerOrders = ordersBySeller[sellerName];
                    const sellerTotal = sellerOrders.reduce((sum, order) => sum + parseFloat(order.final_total || 0), 0);

                    output += ALIGN_CENTER;
                    output += DOUBLE_HEIGHT + BOLD_ON;
                    output += sellerName + '\n';
                    output += NORMAL_SIZE + BOLD_OFF;
                    output += ALIGN_LEFT;
                    output += formatRow('Orders', sellerOrders.length);
                    output += formatRow('Total', `Rs.${sellerTotal.toFixed(2)}`);
                    output += DOUBLE_LINE;

                    sellerOrders.forEach((order, orderIndex) => {
                        output += BOLD_ON + `Order #${order.id}\n` + BOLD_OFF;
                        output += formatRow('Customer', order.user_name || 'Guest');
                        output += formatRow('Mobile', order.mobile);
                        output += formatRow('Placed', order.preorder_placed_at_formatted);

                        const orderWeight = this.calculateOrderTotalWeight(order);
                        if (orderWeight) {
                            output += formatRow('Total Weight', orderWeight);
                        }

                        output += LINE;

                        // Items
                        if (order.items && order.items.length > 0) {
                            order.items.forEach(item => {
                                output += `${item.name || item.product_name}\n`;
                                output += formatRow(`  ${item.quantity}x Rs.${parseFloat(item.price).toFixed(2)}`, `Rs.${parseFloat(item.sub_total).toFixed(2)}`);
                            });
                        }

                        // Combo items
                        if (order.combo_items && order.combo_items.length > 0) {
                            order.combo_items.forEach(combo => {
                                const comboProducts = this.getComboProductsForStore(combo, this.storeId);
                                const comboSubtotal = this.getComboSubtotalForStore(combo, this.storeId);
                                output += `COMBO: ${combo.combo_name}\n`;
                                comboProducts.forEach(product => {
                                    output += `  ${product.product_name} x${product.quantity}\n`;
                                });
                                output += formatRow('  Total', `Rs.${comboSubtotal.toFixed(2)}`);
                            });
                        }

                        output += LINE;
                        output += BOLD_ON;
                        output += formatRow('ORDER TOTAL', `Rs.${parseFloat(order.final_total).toFixed(2)}`);
                        output += BOLD_OFF;
                        
                        if (orderIndex < sellerOrders.length - 1) {
                            output += LINE;
                        }
                    });

                    output += DOUBLE_LINE;
                    output += BOLD_ON;
                    output += formatRow('SELLER TOTAL', `Rs.${sellerTotal.toFixed(2)}`);
                    output += BOLD_OFF;
                    output += DOUBLE_LINE;
                    
                    if (sellerIndex < Object.keys(ordersBySeller).length - 1) {
                        output += '\n\n';
                    }
                });

                output += '\n';
                output += ALIGN_CENTER;
                output += 'Thank you!\n';
                output += 'www.zenfoo.in\n';
                output += '\n\n\n';

                await writer.write(encoder.encode(output));
                await writer.write(encoder.encode(CUT));

                writer.releaseLock();
                await port.close();

                this.$toast.success('Print sent to thermal printer successfully!');

            } catch (error) {
                console.error('Print error:', error);
                if (error.name === 'NotFoundError') {
                    alert('No printer selected. Please select your thermal printer.');
                } else {
                    alert('Print failed: ' + error.message);
                }
            }
        },

        async printSingleSellerOrdersDirect() {
            if (!this.selectedSellerForPrint) {
                this.$toast.warning('Please select a seller first');
                return;
            }

            if (!('serial' in navigator)) {
                alert('Direct USB printing is not supported in this browser. Please use Chrome or Edge.');
                return;
            }

            try {
                const port = await navigator.serial.requestPort();
                await port.open({ baudRate: 9600 });
                const writer = port.writable.getWriter();
                const encoder = new TextEncoder();

                const ESC = '\x1B';
                const GS = '\x1D';
                const INIT = ESC + '@';
                const ALIGN_CENTER = ESC + 'a' + '\x01';
                const ALIGN_LEFT = ESC + 'a' + '\x00';
                const BOLD_ON = ESC + 'E' + '\x01';
                const BOLD_OFF = ESC + 'E' + '\x00';
                const DOUBLE_HEIGHT = GS + '!' + '\x10';
                const NORMAL_SIZE = GS + '!' + '\x00';
                const CUT = GS + 'V' + '\x00';

                const W = 42;
                const LINE = '-'.repeat(W) + '\n';
                const DOUBLE_LINE = '='.repeat(W) + '\n';

                const formatRow = (label, value) => {
                    const valStr = String(value);
                    const maxLabelLen = W - valStr.length - 1;
                    const truncLabel = label.length > maxLabelLen ? label.substring(0, maxLabelLen) : label;
                    const spaces = W - truncLabel.length - valStr.length;
                    return truncLabel + ' '.repeat(Math.max(1, spaces)) + valStr + '\n';
                };

                // Filter orders for selected seller
                const sellerOrders = this.orders.filter(order =>
                    order.is_seller_assigned && order.assigned_seller_name === this.selectedSellerForPrint
                );

                if (sellerOrders.length === 0) {
                    this.$toast.warning('No orders found for selected seller');
                    await port.close();
                    return;
                }

                const sellerTotal = sellerOrders.reduce((sum, order) => sum + parseFloat(order.final_total || 0), 0);

                let output = '';
                output += INIT;
                output += ALIGN_CENTER;
                output += DOUBLE_HEIGHT + BOLD_ON;
                output += 'ZENFOO\n';
                output += NORMAL_SIZE + BOLD_OFF;
                output += 'PRE ORDERS\n';
                output += DOUBLE_LINE;
                output += BOLD_ON + this.selectedSellerForPrint + '\n' + BOLD_OFF;
                output += this.storeName + '\n';
                output += DOUBLE_LINE;
                output += moment().format('D MMM YYYY, h:mm A') + '\n';
                output += DOUBLE_LINE;

                output += ALIGN_LEFT;

                // Print each order
                sellerOrders.forEach((order, index) => {
                    output += BOLD_ON + `Order #${order.id}\n` + BOLD_OFF;
                    output += formatRow('Customer', order.user_name || 'Guest');
                    output += formatRow('Mobile', order.mobile);
                    output += formatRow('Placed', order.preorder_placed_at_formatted);
                    output += formatRow('Process', order.preorder_process_date_formatted);

                    const orderWeight = this.calculateOrderTotalWeight(order);
                    if (orderWeight) {
                        output += formatRow('Total Weight', orderWeight);
                    }

                    output += LINE;

                    // Items
                    if (order.items && order.items.length > 0) {
                        output += BOLD_ON + 'ITEMS:\n' + BOLD_OFF;
                        order.items.forEach(item => {
                            output += `${item.name || item.product_name}\n`;
                            output += formatRow(`  ${item.quantity}x Rs.${parseFloat(item.price).toFixed(2)}`, `Rs.${parseFloat(item.sub_total).toFixed(2)}`);
                        });
                    }

                    // Combo items
                    if (order.combo_items && order.combo_items.length > 0) {
                        order.combo_items.forEach(combo => {
                            const comboProducts = this.getComboProductsForStore(combo, this.storeId);
                            const comboSubtotal = this.getComboSubtotalForStore(combo, this.storeId);
                            output += BOLD_ON + `COMBO: ${combo.combo_name}\n` + BOLD_OFF;
                            comboProducts.forEach(product => {
                                output += `  ${product.product_name}\n`;
                                output += `  ${product.quantity}x Rs.${parseFloat(product.price).toFixed(2)}\n`;
                            });
                            output += formatRow('  Combo Total', `Rs.${comboSubtotal.toFixed(2)}`);
                        });
                    }

                    output += LINE;
                    output += BOLD_ON;
                    output += formatRow('ORDER TOTAL', `Rs.${parseFloat(order.final_total).toFixed(2)}`);
                    output += BOLD_OFF;
                    output += DOUBLE_LINE;
                    
                    if (index < sellerOrders.length - 1) {
                        output += '\n';
                    }
                });

                // Seller summary
                output += ALIGN_CENTER;
                output += BOLD_ON + 'SELLER SUMMARY\n' + BOLD_OFF;
                output += ALIGN_LEFT;
                output += formatRow('Seller', this.selectedSellerForPrint);
                output += formatRow('Total Orders', sellerOrders.length);
                output += formatRow('Total Amount', `Rs.${sellerTotal.toFixed(2)}`);
                output += '\n\n';
                output += ALIGN_CENTER;
                output += 'Thank you!\n';
                output += 'www.zenfoo.in\n';
                output += '\n\n\n';

                await writer.write(encoder.encode(output));
                await writer.write(encoder.encode(CUT));

                writer.releaseLock();
                await port.close();

                this.$toast.success('Print sent to thermal printer successfully!');

            } catch (error) {
                console.error('Print error:', error);
                if (error.name === 'NotFoundError') {
                    alert('No printer selected. Please select your thermal printer.');
                } else {
                    alert('Print failed: ' + error.message);
                }
            }
        }
    }
}
</script>

<style scoped>
/* Order Card Styling */
.order-card {
    border: 1px solid #dee2e6;
    border-radius: 8px;
    overflow: hidden;
    margin-bottom: 1rem;
    transition: box-shadow 0.2s ease;
}

.order-card:hover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.order-card.order-assigned {
    border-left: 4px solid #198754;
}

.order-card.order-assigned .form-check-input:disabled {
    cursor: not-allowed;
    opacity: 0.5;
}

.order-header {
    padding: 15px 20px;
    border-bottom: 1px solid #dee2e6;
    transition: background-color 0.2s ease;
}

.order-header:hover {
    background-color: rgba(0, 0, 0, 0.02);
}

.order-header h5 a {
    text-decoration: none;
    font-weight: 600;
}

.order-header h5 a:hover {
    text-decoration: underline;
}

.order-header .badge {
    font-size: 11px;
    padding: 5px 10px;
}

.order-items {
    padding: 0;
}

.order-items table {
    margin-bottom: 0;
}

.order-items table th,
.order-items table td {
    border: 1px solid;
    padding: 8px;
}

.order-items table thead th {
    border-bottom: 2px solid;
}

.order-footer {
    padding: 15px 20px;
    border-top: 1px solid;
}

.total-breakdown {
    font-size: 12px;
}

/* Summary Card */
.summary-card {
    border: 1px solid !important;
}

.summary-item {
    text-align: center;
    padding: 10px;
}

.summary-item label {
    display: block;
    font-size: 12px;
    margin-bottom: 5px;
    opacity: 0.7;
}

.summary-item h4 {
    margin: 0;
    font-weight: bold;
}

/* Checkbox styling */
.form-check-input {
    width: 20px;
    height: 20px;
    cursor: pointer;
}

.form-check-input:checked {
    background-color: #198754;
    border-color: #198754;
}

/* Order Filter Tabs */
.order-filter-tabs .nav-tabs {
    border-bottom: 2px solid #dee2e6;
}

.order-filter-tabs .nav-link {
    color: #6c757d;
    font-weight: 500;
    padding: 12px 24px;
    cursor: pointer;
    border: none;
    border-bottom: 3px solid transparent;
    transition: all 0.3s ease;
}

.order-filter-tabs .nav-link:hover {
    border-bottom-color: #0dcaf0;
    color: #0dcaf0;
}

.order-filter-tabs .nav-link.active {
    color: #0d6efd;
    border-bottom-color: #0d6efd;
    font-weight: 600;
    background: transparent;
}

/* Combo styling */
.combo-header-row {
    font-weight: 600;
}

.combo-header-row td {
    padding: 15px 20px !important;
    border: 1px solid !important;
    border-radius: 8px;
    background: var(--bs-table-bg, transparent);
    opacity: 0.95;
}

.combo-header-row .badge {
    font-size: 11px;
    padding: 5px 10px;
}

.combo-header-row strong {
    font-size: 14px;
}

/* Combo products nested table */
.combo-products-table thead {
    opacity: 0.9;
}

.combo-products-table thead th {
    font-weight: 600;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    padding: 10px 8px;
}

/* Seller Assignment Card - Same as Summary Card */
.seller-assignment-card {
    border: 1px solid !important;
}

.seller-assignment-card .card-title {
    font-size: 18px;
    font-weight: 600;
    margin-bottom: 1rem;
}

/* Print Options Modal */
.print-options-container {
    padding: 10px;
}

.print-option {
    padding: 20px;
    border: 1px solid #dee2e6;
    border-radius: 8px;
    background: #f8f9fa;
    transition: box-shadow 0.2s ease;
}

.print-option:hover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.print-option h5 {
    font-weight: 600;
    margin-bottom: 10px;
}

.print-option h5 i {
    margin-right: 8px;
}

.print-option p {
    font-size: 14px;
}

.print-option .btn {
    min-width: 200px;
}

/* Gap utility for button groups */
.gap-2 {
    gap: 0.5rem;
}


/* Dark Mode Styles */
@media (prefers-color-scheme: dark) {
    .print-option {
        background: #2d3748;
        border-color: #4a5568;
    }

    .print-option:hover {
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
        background: #374151;
    }

    .print-option h5 {
        color: #f7fafc;
    }

    .print-option p {
        color: #cbd5e0;
    }
}

/* Dark mode class-based (if using class toggle) */
.dark-mode .print-option,
[data-theme="dark"] .print-option,
body.dark .print-option {
    background: #2d3748;
    border-color: #4a5568;
}

.dark-mode .print-option:hover,
[data-theme="dark"] .print-option:hover,
body.dark .print-option:hover {
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
    background: #374151;
}

.dark-mode .print-option h5,
[data-theme="dark"] .print-option h5,
body.dark .print-option h5 {
    color: #f7fafc;
}

.dark-mode .print-option p,
[data-theme="dark"] .print-option p,
body.dark .print-option p {
    color: #cbd5e0;
}
</style>