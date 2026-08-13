<template>
    <div>
        <div class="page-heading view_order">


            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>View Order</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item" v-if="isSellerRoute">
                                <router-link to="/seller/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item" v-else-if="isDeliveryBoyRoute">
                                <router-link to="/delivery_boy/">{{ __('dashboard') }}</router-link>
                            </li>
                            <!-- <li class="breadcrumb-item" v-else>
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li> -->
                            <!-- <li class="breadcrumb-item" v-if="isSellerRoute">
                                <router-link to="/seller/orders">View Order</router-link>
                            </li>
                            <li class="breadcrumb-item" v-else-if="isDeliveryBoyRoute">
                                <router-link to="/delivery_boy/orders">View Order</router-link>
                            </li> -->
                            <li class="breadcrumb-item" v-else>
                                <router-link to="/orders">Back</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                Order Details
                            </li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link v-if="isSellerRoute" to="/seller/orders" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                    <router-link v-else-if="isDeliveryBoyRoute" to="/delivery_boy/orders" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                    <router-link v-else to="/orders" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <!-- Tabs Navigation -->
            <div class="row mb-3">
                <div class="col-12">
                    <ul class="nav nav-tabs">
                        <li class="nav-item">
                            <a class="nav-link" :class="{ active: activeTab === 'order-details' }" href="#" @click.prevent="activeTab = 'order-details'">
                                <i class="fas fa-shopping-cart me-2"></i>Order Details
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" :class="{ active: activeTab === 'invoice-details' }" href="#" @click.prevent="activeTab = 'invoice-details'">
                                <i class="fas fa-file-invoice me-2"></i>Invoice Details
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" :class="{ active: activeTab === 'driver-notifications' }" href="#" @click.prevent="activeTab = 'driver-notifications'">
                                <i class="fas fa-bell me-2"></i>Driver Notifications
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" :class="{ active: activeTab === 'zenfoo-store-items' }" href="#" @click.prevent="activeTab = 'zenfoo-store-items'">
                                <i class="fas fa-leaf me-2" style="color: #9AC444;"></i>Zenfoo Store Items
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" :class="{ active: activeTab === 'customer-reports' }" href="#" @click.prevent="activeTab = 'customer-reports'">
                                <i class="fas fa-exclamation-triangle me-2"></i>Customer Reports
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" :class="{ active: activeTab === 'support-management' }" href="#" @click.prevent="activeTab = 'support-management'">
                                <i class="fas fa-headset me-2"></i>Support Management
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" :class="{ active: activeTab === 'driver-track' }" href="#" @click.prevent="activeTab = 'driver-track'">
                                <i class="fas fa-map-marker-alt me-2"></i>Track
                            </a>
                        </li>
                    </ul>
                </div>
            </div>

            <!-- Tab Content: Invoice Details -->
            <div v-if="activeTab === 'invoice-details'" class="row">
                <div class="col-12">
                    <InvoiceDetails :orderId="id" />
                </div>
            </div>

            <!-- Tab Content: Driver Notifications -->
            <div v-if="activeTab === 'driver-notifications'" class="row">
                <div class="col-12">
                    <DriverNotifications :orderId="id" />
                </div>
            </div>

            <!-- Tab Content: Zenfoo Store Items -->
            <div v-if="activeTab === 'zenfoo-store-items'" class="row">
                <div class="col-12">
                    <ZenfooStoreItems :orderId="id" />
                </div>
            </div>

            <!-- Tab Content: Customer Reports -->
            <div v-if="activeTab === 'customer-reports'" class="row">
                <div class="col-12">
                    <CustomerReports :orderId="id" />
                </div>
            </div>

            <!-- Tab Content: Support Management -->
            <div v-if="activeTab === 'support-management'" class="row">
                <div class="col-12">
                    <SupportManagement
                        :orderId="id"
                        :initialChatType="$route.query.chat_type"
                        :initialSellerId="$route.query.seller_id"
                    />
                </div>
            </div>

            <!-- Tab Content: Driver Track -->
            <div v-if="activeTab === 'driver-track'" class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-body">
                            <div v-if="!order || !order.delivery_boy_id || order.delivery_boy_id == 0" class="text-center py-5">
                                <i class="fas fa-user-slash fa-3x text-muted mb-3"></i>
                                <h5>No Driver Assigned</h5>
                                <p class="text-muted">A driver has not been assigned to this order yet. Tracking will be available once a driver is assigned.</p>
                            </div>
                            <div v-else-if="[6,7,8].includes(order.active_status)" class="text-center py-5">
                                <i class="fas fa-check-circle fa-3x text-success mb-3"></i>
                                <h5>Order Already Completed</h5>
                                <p class="text-muted">No tracking available for completed orders.</p>
                            </div>
                            <DeliveryBoyTrack v-else :delivery-boy-id="String(order.delivery_boy_id)" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tab Content: Order Details (existing content) -->
            <div v-if="activeTab === 'order-details' && order" class="row">
                <div class="col-md-12">
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h4 class="mb-0">Order Details</h4>
                            <span v-if="totalStoresCount === 1" class="badge bg-success">Single Store</span>
                            <span v-else-if="totalStoresCount > 1" class="badge bg-primary">Multi Store</span>
                        </div>
                        <div class="card-body">
                            <table class="table table-bordered">
                                <tbody>
                                    <tr>
                                        <th class="th-width">Order Id</th>
                                        <td>{{ order.order_number || order.order_id || 'N/A' }}</td>
                                    </tr>
                                    <tr>
                                        <th class="th-width">Email</th>
                                        <td>{{ order.user_email  || 'N/A' }}</td>
                                    </tr>
                                    <!-- <tr>
                                        <th class="th-width">O. Note</th>
                                        <td>{{ order.order_note  || '-' }}</td>
                                    </tr> -->
                                    <tr>
                                        <th class="th-width">Status</th>
                                        <td>
                                            {{ order.status_name }}
                                        </td>
                                    </tr>
                                    <tr>
                                        <th class="th-width">Name</th>
                                        <td>{{ order.user_name  || 'N/A' }}</td>
                                    </tr>
                                    <tr>
                                        <th class="th-width">Contact</th>
                                        <td>{{ order.user_mobile ? order.user_mobile : 'N/A' }}</td>
                                    </tr>
                                    <tr>
                                        <th class="th-width">Area</th>
                                        <td>{{ order.address || 'N/A' }}</td>
                                    </tr>
                                    <tr>
                                        <th class="th-width">Pincode</th>
                                        <td>{{ order.pincode || 'N/A' }}</td>
                                    </tr>

                                    <tr>
                                        <th class="th-width">Delivery Boy</th>
                                        <td>
                                            <template v-if="order.delivery_boy_name">
                                                {{ order.delivery_boy_name }}
                                            </template>
                                            <template v-else>
                                                Not Assign
                                            </template>
                                        </td>
                                    </tr>

                                    <!-- Previously Assigned Drivers -->
                                    <tr v-if="previousDriversDetails && previousDriversDetails.length > 0">
                                        <th class="th-width">Previously Assigned Drivers</th>
                                        <td>
                                            <div class="d-flex flex-wrap gap-2">
                                                <span
                                                    v-for="(driver, index) in previousDriversDetails"
                                                    :key="driver.id"
                                                    class="badge bg-secondary"
                                                    :title="'Assigned #' + (index + 1)"
                                                >
                                                    {{ index + 1 }}. {{ driver.name || 'Driver ID: ' + driver.id }}
                                                </span>
                                            </div>
                                            <small class="text-muted">Drivers assigned to this order before current driver</small>
                                        </td>
                                    </tr>

                                    <tr v-if="this.$roleDeliveryBoy !== this.login_user.role.name">
                                        <th class="th-width">Assign Delivery Boy</th>
                                        <td>
                                            <div class="row g-3 align-items-center">
                                                <div class="col-auto">
                                                    <select id="delivery_boy_id" name="status" class="form-control form-select" v-model="delivery_boy_id" :disabled="order.active_status == 6 || order.delivery_boy_id > 0">
                                                        <option value="">Select Delivery Boy</option>
                                                        <option v-for="boy in deliveryBoys" :key="boy.id" :value="boy.id">{{ boy.name }}</option>
                                                    </select>
                                                </div>
                                                <div class="col-auto">
                                                    <button type="button" class="btn btn-primary" @click="assignDeliveryBoy" :disabled="!delivery_boy_id || isLoadingDboy || order.active_status == 6 || order.delivery_boy_id > 0">
                                                        <template v-if="isLoadingDboy"><b-spinner small label="Spinning"></b-spinner></template>
                                                        Assign Driver
                                                    </button>
                                                </div>
                                            </div>
                                        </td>
                                    </tr>

                                    <!-- Emergency Driver Change Button (only when driver is already assigned) -->
                                    <tr v-if="this.$roleDeliveryBoy !== this.login_user.role.name && order.delivery_boy_id > 0 && order.active_status < 6">
                                        <th class="th-width">Emergency Driver Change</th>
                                        <td>
                                            <button type="button" class="btn btn-warning" @click="openEmergencyDriverModal">
                                                <i class="fas fa-exclamation-triangle me-1"></i>
                                                Change Driver (Emergency)
                                            </button>
                                        </td>
                                    </tr>

                                    <!-- Any order that is not delivered (6) and not already cancelled (7).
                                         After handover to the driver the API only allows reason = driver issue. -->
                                    <tr v-if="order.active_status < 6">
                                        <th class="th-width">Cancel Order</th>
                                        <td>
                                            <button type="button" class="btn btn-danger" @click="updateStatus" :disabled="isLoadingUstatus">
                                                <template v-if="isLoadingUstatus"><b-spinner small label="Spinning"></b-spinner></template>
                                                Cancel Order
                                            </button>
                                        </td>
                                    </tr>

                                    <!-- Cancelled order: the store may have already cooked the food, so Zenfoo still pays them -->
                                    <tr v-if="order.active_status == 7">
                                        <th class="th-width">Pay Store (Cancelled Order)</th>
                                        <td>
                                            <div v-if="cancelledStores && cancelledStores.length">
                                                <div v-for="store in cancelledStores" :key="store.seller_id" class="mb-2 d-flex align-items-center gap-2">
                                                    <b>{{ store.store_name || ('Seller #' + store.seller_id) }}</b>
                                                    <span v-if="store.already_paid" class="badge bg-success">Paid {{ store.paid_amount }}</span>
                                                    <button v-else type="button" class="btn btn-sm btn-primary" @click="payStoreForCancelledOrder(store)">
                                                        Pay Store
                                                    </button>
                                                </div>
                                            </div>
                                            <small v-else class="text-muted">No store records found for this cancelled order.</small>
                                        </td>
                                    </tr>


                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                                <!-- Customer Info Card -->
                <div class="col-md-12 mt-4" v-if="customer">
                    <div class="card">
                        <div class="card-header">
                            <h4>Customer Information</h4>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-2 text-center">
                                    <template v-if="customer.profile && customer.profile !== ''">
                                        <img :src="customer.profile"
                                             alt="Customer Profile"
                                             class="rounded-circle mb-2"
                                             style="width: 80px; height: 80px; object-fit: cover;"
                                             @error="customer.profile = null">
                                    </template>
                                    <template v-else>
                                        <div class="rounded-circle mb-2 d-flex align-items-center justify-content-center bg-light mx-auto"
                                             style="width: 80px; height: 80px; border: 1px solid #eee;">
                                            <i class="fas fa-user-circle fa-4x text-secondary"></i>
                                        </div>
                                    </template>
                                </div>
                                <div class="col-md-10">
                                    <div class="row">
                                        <div class="col-md-4">
                                            <p class="mb-1"><strong>Name:</strong> {{ customer.name || 'N/A' }}</p>
                                        </div>
                                        <div class="col-md-4">
                                            <p class="mb-1"><strong>Email:</strong> {{ customer.email || 'N/A' }}</p>
                                        </div>
                                        <div class="col-md-4">
                                            <p class="mb-1"><strong>Mobile:</strong> {{ customer.mobile ? customer.mobile : 'N/A' }}</p>
                                        </div>
                                        <div class="col-md-4">
                                            <p class="mb-1"><strong>Wallet Balance:</strong> {{ $currency }}{{ customer.balance || 0 }}</p>
                                        </div>
                                        <!-- <div class="col-md-4">
                                            <p class="mb-1"><strong>Referral Code:</strong> {{ customer.referral_code || '-' }}</p>
                                        </div> -->

                                        
                                        <div class="col-md-4">
                                            <p class="mb-1"><strong>Status:</strong>
                                                <span :class="customer.status == 1 ? 'badge bg-success' : 'badge bg-danger'">
                                                    {{ customer.status == 1 ? 'Active' : 'Inactive' }}
                                                </span>
                                            </p>
                                        </div>
                                        <div class="col-md-4">
                                            <p class="mb-1"><strong>Member Since:</strong> {{ formatDate(customer.created_at) }}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>


                <!-- Billing Summary -->
                <div class="col-md-12 mt-4" v-if="billingSummaryItems.length > 0">
                    <div class="card">
                        <div class="card-header">
                            <h4>Billing Summary</h4>
                        </div>
                        <div class="card-body">
                            <table class="table table-bordered">
                                <tbody>
                                    <tr v-for="(item, index) in billingSummaryItems" :key="index"
                                        :class="{ 'table-active': item.bold }">
                                        <th class="th-width">
                                            <strong v-if="item.bold">{{ item.label }}</strong>
                                            <template v-else>{{ item.label }}</template>
                                        </th>
                                        <td>
                                            <strong v-if="item.bold">{{ item.value }}</strong>
                                            <template v-else>{{ item.value }}</template>
                                        </td>
                                    </tr>
                                    <tr>
                                        <th class="th-width">Payment Method</th>
                                        <td>{{ order.payment_method || 'N/A' }}</td>
                                    </tr>
                                    <tr v-if="paytmTransaction">
                                        <th class="th-width">Paytm Txn ID</th>
                                        <td>{{ paytmTransaction.paytm_txn_id }}</td>
                                    </tr>
                                    <tr v-if="paytmTransaction">
                                        <th class="th-width">Txn Status</th>
                                        <td>
                                            <span class="badge" :class="paytmTransaction.status === 'success' ? 'bg-success' : 'bg-warning'">
                                                {{ paytmTransaction.status }}
                                            </span>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

            <!-- Zenfoo Order Section (store_id 12, 13, 14) -->
            <div class="col-12 col-md-12 mt-4" v-if="zenfooStoreItems.length > 0">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center" >
                        <h4 class="mb-0" style="color: #9AC444;">Zenfoo Order</h4>
                    </div>

                    <div class="card-body">

                        <div v-for="store in zenfooStoreItems" :key="store.store_id" class="mb-4">

                            <div class="card mb-3">
                                <div class="card-header">
                                    <div class="row align-items-center">
                                        <div class="col-md-12 d-flex align-items-center">
                                            <h6 class="mb-0">{{ store.store_name || 'Unknown Store' }}</h6>
                                            <small class="text-muted ms-auto">{{ store.items.length }} item(s)</small>
                                        </div>
                                    </div>
                                </div>

                                <div class="card-body p-0">
                                    <div class="table-responsive">
                                        <table class="table table-bordered mb-0">
                                            <thead>
                                                <tr>
                                                    <th>#</th>
                                                    <th>Product</th>
                                                    <th>Qty</th>
                                                    <th>Variant</th>
                                                    <th>Subtotal</th>
                                                    <th class="text-center">Actions</th>
                                                </tr>
                                            </thead>

                                            <tbody>
                                                <tr v-for="(item, index) in store.items" :key="item.id">
                                                    <td>{{ index + 1 }}</td>
                                                    <td>
                                                        {{ item.product_name }}
                                                        <br>
                                                        <small class="text-muted">ID: #{{ item.product_id }}</small>
                                                    </td>
                                                    <td>{{ item.quantity }}</td>
                                                    <td>{{ item.variant_name }}</td>
                                                    <td>
                                                        <i class="fas fa-rupee-sign"></i> {{ item.sub_total }}
                                                    </td>
                                                    <td class="text-center">
                                                        <button
                                                            class="btn btn-info btn-sm me-1"
                                                            @click="toggleItemDetails(item.id)">
                                                            <i :class="expandedItems.includes(item.id) ? 'fas fa-chevron-up' : 'fas fa-chevron-down'"></i>
                                                        </button>
                                                        <router-link
                                                            :to="getProductRoute(item.product_id)"
                                                            class="btn btn-primary btn-sm">
                                                            <i class="fas fa-eye"></i>
                                                        </router-link>
                                                    </td>
                                                </tr>

                                                <tr v-for="item in store.items"
                                                    v-if="expandedItems.includes(item.id)"
                                                    :key="'details-' + item.id">
                                                    <td colspan="6">
                                                        <div class="row">
                                                            <div class="col-md-3">
                                                                <b>Product ID:</b> {{ item.product_id }}
                                                            </div>
                                                            <div class="col-md-3">
                                                                <b>Variant ID:</b> {{ item.product_variant_id }}
                                                            </div>
                                                            <div class="col-md-3">
                                                                <b>Price:</b> ₹{{ item.price }}
                                                            </div>
                                                            <div class="col-md-3">
                                                                <b>Discounted:</b> ₹{{ item.discounted_price }}
                                                            </div>
                                                            <!-- <div class="col-md-3 mt-2">
                                                                <b>Tax Amount:</b> ₹{{ item.tax_amount }}
                                                            </div>
                                                            <div class="col-md-3 mt-2">
                                                                <b>Tax %:</b> {{ item.tax_percentage }}%
                                                            </div> -->
                                                            <div class="col-md-3 mt-2" v-if="item.seller_name">
                                                                <b>Seller:</b> {{ item.seller_name }}
                                                            </div>
                                                        </div>
                                                    </td>
                                                </tr>

                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>

                        </div>

                    </div>
                </div>
            </div>

            <!-- Other Stores Section (non-Zenfoo stores) -->
            <div class="col-12 col-md-12 mt-4" v-if="nonZenfooStoreItems.length > 0">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h4 class="mb-0">Order Items by Store</h4>
                    </div>

                    <div class="card-body">

                        <div v-for="store in nonZenfooStoreItems" :key="store.store_id" class="mb-4">

                            <div class="card mb-3">
                                <div class="card-header">
                                    <div class="row align-items-center">
                                        <div class="col-md-12 d-flex align-items-center">
                                            <h6 class="mb-0">{{ store.store_name || 'Unknown Store' }}</h6>
                                            <small class="text-muted ms-auto">{{ store.items.length }} item(s)</small>
                                        </div>
                                    </div>
                                </div>

                                <div class="card-body p-0">
                                    <div class="table-responsive">
                                        <table class="table table-bordered mb-0">
                                            <thead>
                                                <tr>
                                                    <th>#</th>
                                                    <th>Product</th>
                                                    <th>Qty</th>
                                                    <th>Variant</th>
                                                    <th>Subtotal</th>
                                                    <th class="text-center">Actions</th>
                                                </tr>
                                            </thead>

                                            <tbody>
                                                <tr v-for="(item, index) in store.items" :key="item.id">
                                                    <td>{{ index + 1 }}</td>
                                                    <td>
                                                        {{ item.product_name }}
                                                        <br>
                                                        <small class="text-muted">ID: #{{ item.product_id }}</small>
                                                    </td>
                                                    <td>{{ item.quantity }}</td>
                                                    <td>{{ item.variant_name }}</td>
                                                    <td>
                                                        <i class="fas fa-rupee-sign"></i> {{ item.sub_total }}
                                                    </td>
                                                    <td class="text-center">
                                                        <button
                                                            class="btn btn-info btn-sm me-1"
                                                            @click="toggleItemDetails(item.id)">
                                                            <i :class="expandedItems.includes(item.id) ? 'fas fa-chevron-up' : 'fas fa-chevron-down'"></i>
                                                        </button>
                                                        <router-link
                                                            :to="getProductRoute(item.product_id)"
                                                            class="btn btn-primary btn-sm">
                                                            <i class="fas fa-eye"></i>
                                                        </router-link>
                                                    </td>
                                                </tr>

                                                <tr v-for="item in store.items"
                                                    v-if="expandedItems.includes(item.id)"
                                                    :key="'details-' + item.id">
                                                    <td colspan="6">
                                                        <div class="row">
                                                            <div class="col-md-3">
                                                                <b>Product ID:</b> {{ item.product_id }}
                                                            </div>
                                                            <div class="col-md-3">
                                                                <b>Variant ID:</b> {{ item.product_variant_id }}
                                                            </div>
                                                            <div class="col-md-3">
                                                                <b>Price:</b> ₹{{ item.price }}
                                                            </div>
                                                            <div class="col-md-3">
                                                                <b>Discounted:</b> ₹{{ item.discounted_price }}
                                                            </div>
                                                            <!-- <div class="col-md-3 mt-2">
                                                                <b>Tax Amount:</b> ₹{{ item.tax_amount }}
                                                            </div>
                                                            <div class="col-md-3 mt-2">
                                                                <b>Tax %:</b> {{ item.tax_percentage }}%
                                                            </div> -->
                                                            <div class="col-md-3 mt-2" v-if="item.seller_name">
                                                                <b>Seller:</b> {{ item.seller_name }}
                                                            </div>
                                                        </div>
                                                    </td>
                                                </tr>

                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>

                        </div>

                    </div>
                </div>
            </div>

            <!-- Combo Items Section -->
            <div class="col-12 col-md-12 mt-4" v-if="combo_items && combo_items.length > 0">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h4 class="mb-0">Combo Items</h4>
                    </div>

                    <div class="card-body">
                        <div v-for="(combo, comboIndex) in combo_items" :key="combo.id" class="mb-4">
                            <div class="card mb-3 border-primary">
                                <div class="card-header" style="background-color: #2a3f54;">
                                    <div class="d-flex justify-content-between align-items-center">
                                        <div>
                                            <h6 class="mb-0 text-white">
                                                <i class="fas fa-box-open me-2"></i>
                                                {{ combo.combo_name || 'Combo Pack' }}
                                            </h6>
                                            <small class="text-light">{{ combo.products_count || combo.products.length }} product(s) in combo</small>
                                        </div>
                                        <div class="text-end">
                                            <span class="badge bg-primary me-2">Qty: {{ combo.combo_quantity || 1 }}</span>
                                            <span class="badge bg-warning text-dark me-2" v-if="combo.discount_percentage > 0">
                                                {{ combo.discount_percentage }}% OFF
                                            </span>
                                            <span class="badge bg-success">
                                                <i class="fas fa-rupee-sign"></i> {{ combo.sub_total || combo.combo_sub_total || combo.combo_price }}
                                            </span>
                                        </div>
                                    </div>
                                    <div class="row mt-2" v-if="combo.combo_description">
                                        <div class="col-12">
                                            <small class="text-light">{{ combo.combo_description }}</small>
                                        </div>
                                    </div>
                                    <div class="row mt-2">
                                        <div class="col-12">
                                            <small class="me-3 text-white">
                                                <strong>Actual Price:</strong>
                                                <span class="text-decoration-line-through" style="color: #adb5bd;">
                                                    <i class="fas fa-rupee-sign"></i>{{ combo.total_actual_price }}
                                                </span>
                                            </small>
                                            <small class="text-white">
                                                <strong>Subtotal:</strong>
                                                <span class="text-success fw-bold">
                                                    <i class="fas fa-rupee-sign"></i>{{ combo.sub_total }}
                                                </span>
                                            </small>
                                        </div>
                                    </div>
                                </div>

                                <div class="card-body p-0">
                                    <!-- Show products grouped by store if available -->
                                    <div v-if="combo.store_wise_products && combo.store_wise_products.length > 0">
                                        <div v-for="(storeGroup, storeIndex) in combo.store_wise_products" :key="storeIndex" class="mb-2">
                                            <div class="px-3 py-2" style="background-color: #435971;">
                                                <small class="text-white"><strong>{{ storeGroup.store_name || 'Unknown Store' }}</strong> ({{ storeGroup.products.length }} product(s))</small>
                                            </div>
                                            <div class="table-responsive">
                                                <table class="table table-bordered mb-0">
                                                    <thead class="table-light">
                                                        <tr>
                                                            <th>#</th>
                                                            <th>Product</th>
                                                            <th>Variant</th>
                                                            <th>Qty</th>
                                                            <th>Price</th>
                                                            <th>Subtotal</th>
                                                            <th class="text-center">Actions</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        <tr v-for="(product, productIndex) in storeGroup.products" :key="productIndex">
                                                            <td>{{ productIndex + 1 }}</td>
                                                            <td>
                                                                {{ product.product_name }}
                                                                <br>
                                                                <small class="text-muted">ID: #{{ product.product_id }}</small>
                                                            </td>
                                                            <td>
                                                                {{ product.variant_measurement }}
                                                                <span v-if="product.variant_stock_unit_id == 1">kg</span>
                                                                <span v-else-if="product.variant_stock_unit_id == 2">g</span>
                                                                <span v-else-if="product.variant_stock_unit_id == 3">L</span>
                                                                <span v-else-if="product.variant_stock_unit_id == 4">ml</span>
                                                                <span v-else>units</span>
                                                            </td>
                                                            <td>{{ product.quantity }}</td>
                                                            <td>
                                                                <span class="text-decoration-line-through text-muted me-1" v-if="product.actual_price != product.price">
                                                                    <i class="fas fa-rupee-sign"></i>{{ product.actual_price }}
                                                                </span>
                                                                <span class="text-success">
                                                                    <i class="fas fa-rupee-sign"></i>{{ product.price }}
                                                                </span>
                                                            </td>
                                                            <td>
                                                                <i class="fas fa-rupee-sign"></i> {{ product.sub_total }}
                                                            </td>
                                                            <td class="text-center">
                                                                <router-link
                                                                    :to="getProductRoute(product.product_id)"
                                                                    class="btn btn-primary btn-sm">
                                                                    <i class="fas fa-eye"></i>
                                                                </router-link>
                                                            </td>
                                                        </tr>
                                                    </tbody>
                                                </table>
                                            </div>
                                        </div>
                                    </div>
                                    <!-- Fallback to flat products list -->
                                    <div v-else class="table-responsive">
                                        <table class="table table-bordered mb-0">
                                            <thead class="table-light">
                                                <tr>
                                                    <th>#</th>
                                                    <th>Product</th>
                                                    <th>Variant</th>
                                                    <th>Qty</th>
                                                    <th>Price</th>
                                                    <th>Subtotal</th>
                                                    <th class="text-center">Actions</th>
                                                </tr>
                                            </thead>

                                            <tbody>
                                                <tr v-for="(product, productIndex) in combo.products" :key="productIndex">
                                                    <td>{{ productIndex + 1 }}</td>
                                                    <td>
                                                        {{ product.product_name }}
                                                        <br>
                                                        <small class="text-muted">ID: #{{ product.product_id }}</small>
                                                    </td>
                                                    <td>
                                                        {{ product.variant_measurement }}
                                                        <span v-if="product.variant_stock_unit_id == 1">kg</span>
                                                        <span v-else-if="product.variant_stock_unit_id == 2">g</span>
                                                        <span v-else-if="product.variant_stock_unit_id == 3">L</span>
                                                        <span v-else-if="product.variant_stock_unit_id == 4">ml</span>
                                                        <span v-else>units</span>
                                                    </td>
                                                    <td>{{ product.quantity }}</td>
                                                    <td>
                                                        <span class="text-decoration-line-through text-muted me-1" v-if="product.actual_price != product.price">
                                                            <i class="fas fa-rupee-sign"></i>{{ product.actual_price }}
                                                        </span>
                                                        <span class="text-success">
                                                            <i class="fas fa-rupee-sign"></i>{{ product.price }}
                                                        </span>
                                                    </td>
                                                    <td>
                                                        <i class="fas fa-rupee-sign"></i> {{ product.sub_total }}
                                                    </td>
                                                    <td class="text-center">
                                                        <router-link
                                                            :to="getProductRoute(product.product_id)"
                                                            class="btn btn-primary btn-sm">
                                                            <i class="fas fa-eye"></i>
                                                        </router-link>
                                                    </td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Seller Assignments Section at Bottom -->
            <div class="col-12 col-md-12 mt-4" v-if="seller_assignments && seller_assignments.length > 0">
                <div class="card">
                    <div class="card-header">
                        <h4 class="mb-0"><i class="fas fa-user-tag me-2"></i>Seller Assignments</h4>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div v-for="(assignment, index) in seller_assignments"
                                 :key="assignment.store_id"
                                 class="col-md-6 mb-3"
                                 v-if="assignment.seller_type !== 'none'">
                                <div class="card h-100">
                                    <div class="card-header py-2" style="background-color: #435971;">
                                        <strong class="text-white">{{ assignment.store_name }}</strong>
                                    </div>
                                    <div class="card-body py-3">
                                        <!-- Fixed seller (store_id 15, 17) - Just show seller name -->
                                        <div v-if="assignment.seller_type === 'fixed'">
                                            <div v-if="assignment.assigned_seller">
                                                <p class="mb-1">
                                                    <strong>Assigned Seller:</strong>
                                                    <span class="text-success">{{ assignment.assigned_seller.seller_name || assignment.assigned_seller.store_name }}</span>
                                                </p>
                                                <p class="mb-1" v-if="assignment.assigned_seller.mobile">
                                                    <strong>Mobile:</strong>
                                                    <a :href="'tel:' + assignment.assigned_seller.mobile">{{ assignment.assigned_seller.mobile }}</a>
                                                </p>
                                                <p class="mb-1" v-if="assignment.assigned_seller.email">
                                                    <strong>Email:</strong>
                                                    <a :href="'mailto:' + assignment.assigned_seller.email">{{ assignment.assigned_seller.email }}</a>
                                                </p>
                                                <p class="mb-0" v-if="order.active_status == 6">
                                                    <strong>Status:</strong>
                                                    <span class="badge bg-success">Delivered</span>
                                                </p>
                                                <p class="mb-0" v-else-if="assignment.assigned_seller.status">
                                                    <strong>Status:</strong>
                                                    <span class="badge" :class="{
                                                        'bg-info': assignment.assigned_seller.status === 'assigned_to_seller',
                                                        'bg-warning': assignment.assigned_seller.status === 'packed_by_seller',
                                                        'bg-success': assignment.assigned_seller.status === 'given_to_delivery_partner'
                                                    }">
                                                        {{ formatSellerStatus(assignment.assigned_seller.status) }}
                                                    </span>
                                                </p>
                                            </div>
                                            <div v-else>
                                                <span class="text-muted">No seller assigned</span>
                                            </div>
                                        </div>

                                        <!-- Dropdown seller (store_id 13, 14) -->
                                        <div v-else-if="assignment.seller_type === 'dropdown'">
                                            <!-- Show assigned seller info if already assigned -->
                                            <div v-if="assignment.assigned_seller">
                                                <p class="mb-1">
                                                    <strong>Assigned Seller:</strong>
                                                    <span class="text-success">{{ assignment.assigned_seller.seller_name || assignment.assigned_seller.store_name }}</span>
                                                </p>
                                                <p class="mb-1" v-if="assignment.assigned_seller.mobile">
                                                    <strong>Mobile:</strong>
                                                    <a :href="'tel:' + assignment.assigned_seller.mobile">{{ assignment.assigned_seller.mobile }}</a>
                                                </p>
                                                <p class="mb-1" v-if="assignment.assigned_seller.email">
                                                    <strong>Email:</strong>
                                                    <a :href="'mailto:' + assignment.assigned_seller.email">{{ assignment.assigned_seller.email }}</a>
                                                </p>
                                                <p class="mb-0" v-if="order.active_status == 6">
                                                    <strong>Status:</strong>
                                                    <span class="badge bg-success">Delivered</span>
                                                </p>
                                                <p class="mb-0" v-else-if="assignment.assigned_seller.status">
                                                    <strong>Status:</strong>
                                                    <span class="badge" :class="{
                                                        'bg-info': assignment.assigned_seller.status === 'assigned_to_seller',
                                                        'bg-warning': assignment.assigned_seller.status === 'packed_by_seller',
                                                        'bg-success': assignment.assigned_seller.status === 'given_to_delivery_partner'
                                                    }">
                                                        {{ formatSellerStatus(assignment.assigned_seller.status) }}
                                                    </span>
                                                </p>
                                            </div>

                                            <!-- Show dropdown only if no seller assigned -->
                                            <div v-else>
                                                <div v-if="assignment.eligible_sellers && assignment.eligible_sellers.length > 0">
                                                    <label class="form-label"><strong>Select Seller:</strong></label>
                                                    <div class="d-flex">
                                                        <select class="form-control form-select"
                                                                style="max-width: 250px"
                                                                v-model="assignment.selectedSeller">
                                                            <option value="">Select Seller</option>
                                                            <option v-for="seller in assignment.eligible_sellers"
                                                                    :key="seller.seller_id"
                                                                    :value="seller.seller_id">
                                                                {{ seller.seller_name || seller.store_name }}
                                                            </option>
                                                        </select>
                                                        <button class="btn btn-success btn-sm ms-2"
                                                                v-if="assignment.selectedSeller"
                                                                @click="assignSellerFromBottom(assignment)">
                                                            Assign
                                                        </button>
                                                    </div>
                                                </div>
                                                <div v-else>
                                                    <span class="text-muted">No eligible sellers available</span>
                                                </div>
                                            </div>
                                        </div>

                                        <!-- Seller and Combo Notes -->
                                        <!-- <div class="mt-3 border-top pt-2">
                                            <div class="mb-2">
                                                <small class="text-muted d-block mb-1"><strong><i class="fas fa-sticky-note me-1"></i>Seller Notes:</strong></small>
                                                <div v-if="assignment.store_seller_notes && assignment.store_seller_notes.length > 0">
                                                    <div v-for="(note, nIdx) in assignment.store_seller_notes" :key="'sn-'+assignment.store_id+'-'+nIdx" class="alert alert-light border py-1 px-2 mb-1" style="font-size: 0.85rem; background-color: #f8f9fa;">
                                                        {{ note }}
                                                    </div>
                                                </div>
                                                <div v-else class="text-muted ms-2" style="font-size: 0.85rem;">N/A</div>
                                            </div>
                                            <div>
                                                <small class="text-muted d-block mb-1"><strong><i class="fas fa-box me-1"></i>Combo Notes:</strong></small>
                                                <div v-if="assignment.store_combo_notes && assignment.store_combo_notes.length > 0">
                                                    <div v-for="(cN, cnIdx) in assignment.store_combo_notes" :key="'cn-'+assignment.store_id+'-'+cnIdx" class="alert alert-light border py-1 px-2 mb-1" style="font-size: 0.85rem; background-color: #e3f2fd; border-color: #bbdefb !important;">
                                                        <span class="text-primary fw-bold">{{ cN.combo_name || 'Combo' }}:</span> {{ cN.note }}
                                                    </div>
                                                </div>
                                                <div v-else class="text-muted ms-2" style="font-size: 0.85rem;">N/A</div>
                                            </div>
                                        </div> -->
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            </div> <!-- End of Order Details Tab Content -->

        </div>

        <!-- Emergency Driver Change Modal -->
        <div class="modal fade" id="emergencyDriverModal" tabindex="-1" aria-labelledby="emergencyDriverModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content">
                    <div class="modal-header bg-warning text-dark">
                        <h5 class="modal-title" id="emergencyDriverModalLabel">
                            <i class="fas fa-exclamation-triangle me-2"></i>Emergency Driver Change
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <p class="mb-3"><strong>Current Driver:</strong> {{ order.delivery_boy_name || 'Not Assigned' }}</p>
                        <hr>

                        <!-- Option 1: Phone Number Search -->
                        <div class="mb-3">
                            <label for="driverPhoneSearch" class="form-label">
                                <i class="fas fa-phone me-1"></i>
                                <strong>Option 1:</strong> Search by Phone Number
                            </label>
                            <div class="input-group">
                                <input
                                    type="text"
                                    class="form-control"
                                    id="driverPhoneSearch"
                                    v-model="emergencyDriverPhone"
                                    placeholder="Enter phone number"
                                    @keyup.enter="searchDriverByPhone"
                                >
                                <button
                                    class="btn btn-primary"
                                    type="button"
                                    @click="searchDriverByPhone"
                                    :disabled="isSearchingDriver || !emergencyDriverPhone"
                                >
                                    <b-spinner small v-if="isSearchingDriver"></b-spinner>
                                    <i class="fas fa-search" v-else></i>
                                    Search
                                </button>
                            </div>
                        </div>

                        <div class="text-center mb-3">
                            <span class="badge bg-secondary">OR</span>
                        </div>

                        <!-- Option 2: Find Nearby Drivers -->
                        <div class="mb-3">
                            <label class="form-label">
                                <i class="fas fa-map-marker-alt me-1"></i>
                                <strong>Option 2:</strong> Find Nearby Drivers
                            </label>

                            <!-- Distance Input -->
                            <div class="input-group mb-2">
                                <span class="input-group-text">
                                    <i class="fas fa-ruler"></i>
                                </span>
                                <input
                                    type="number"
                                    class="form-control"
                                    v-model.number="searchRadiusKm"
                                    min="0.1"
                                    max="50"
                                    step="0.5"
                                    placeholder="Distance in km">
                                <span class="input-group-text">km</span>
                            </div>

                            <!-- Quick Select Buttons -->
                            <div class="btn-group btn-group-sm w-100 mb-2" role="group">
                                <button
                                    type="button"
                                    class="btn btn-outline-secondary"
                                    :class="{ 'active': searchRadiusKm === 0.5 }"
                                    @click="searchRadiusKm = 0.5">
                                    500m
                                </button>
                                <button
                                    type="button"
                                    class="btn btn-outline-secondary"
                                    :class="{ 'active': searchRadiusKm === 1 }"
                                    @click="searchRadiusKm = 1">
                                    1km
                                </button>
                                <button
                                    type="button"
                                    class="btn btn-outline-secondary"
                                    :class="{ 'active': searchRadiusKm === 2 }"
                                    @click="searchRadiusKm = 2">
                                    2km
                                </button>
                                <button
                                    type="button"
                                    class="btn btn-outline-secondary"
                                    :class="{ 'active': searchRadiusKm === 3 }"
                                    @click="searchRadiusKm = 3">
                                    3km
                                </button>
                                <button
                                    type="button"
                                    class="btn btn-outline-secondary"
                                    :class="{ 'active': searchRadiusKm === 5 }"
                                    @click="searchRadiusKm = 5">
                                    5km
                                </button>
                            </div>

                            <!-- Search Button -->
                            <button
                                type="button"
                                class="btn btn-info w-100"
                                @click="openNearbyDriversModal"
                                :disabled="isLoadingNearbyDrivers || !searchRadiusKm || searchRadiusKm <= 0">
                                <b-spinner small v-if="isLoadingNearbyDrivers"></b-spinner>
                                <i class="fas fa-location-arrow" v-else></i>
                                Show Nearby Drivers ({{ searchRadiusKm }}km radius)
                            </button>

                            <small class="text-muted d-block mt-1">
                                <i class="fas fa-info-circle"></i>
                                Enter distance or use quick select buttons
                            </small>
                        </div>

                        <!-- Driver Details (shown after search) -->
                        <div v-if="foundDriver" class="alert alert-info">
                            <h6 class="mb-2"><i class="fas fa-user-circle"></i> Driver Found</h6>
                            <p class="mb-1"><strong>Name:</strong> {{ foundDriver.name }}</p>
                            <p class="mb-1"><strong>Phone:</strong> {{ foundDriver.phone }}</p>
                            <p class="mb-1"><strong>Status:</strong>
                                <span :class="foundDriver.status == 1 ? 'badge bg-success' : 'badge bg-danger'">
                                    {{ foundDriver.status == 1 ? 'Active' : 'Inactive' }}
                                </span>
                            </p>
                            <p class="mb-1"><strong>Available:</strong>
                                <span :class="foundDriver.is_available == 1 ? 'badge bg-success' : 'badge bg-warning'">
                                    {{ foundDriver.is_available == 1 ? 'Available' : 'Not Available' }}
                                </span>
                            </p>
                            <p class="mb-0"><strong>Current Orders:</strong> {{ foundDriver.current_orders_count }}</p>
                        </div>

                        <!-- Error Message -->
                        <div v-if="driverSearchError" class="alert alert-danger">
                            {{ driverSearchError }}
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" @click="resetEmergencyDriverModal">Close</button>
                        <button
                            type="button"
                            class="btn btn-warning"
                            @click="confirmDriverChange"
                            :disabled="!foundDriver || isChangingDriver"
                            v-if="foundDriver"
                        >
                            <b-spinner small v-if="isChangingDriver"></b-spinner>
                            <i class="fas fa-exchange-alt" v-else></i>
                            Confirm Driver Change
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Nearby Drivers Modal -->
        <div class="modal fade" id="nearbyDriversModal" tabindex="-1" aria-labelledby="nearbyDriversModalLabel" aria-hidden="true">
            <div class="modal-dialog modal-lg modal-dialog-scrollable">
                <div class="modal-content">
                    <div class="modal-header bg-info text-white">
                        <h5 class="modal-title" id="nearbyDriversModalLabel">
                            <i class="fas fa-map-marker-alt me-2"></i>
                            Nearby Drivers to {{ order.delivery_boy_name }}
                        </h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>

                    <div class="modal-body">
                        <!-- Current Driver Location Info -->
                        <div class="alert alert-info mb-3" v-if="currentDriverLocation">
                            <div class="row align-items-center">
                                <div class="col-md-8">
                                    <strong>
                                        <i class="fas fa-map-marker-alt text-white"></i>
                                        Current Driver Location:
                                    </strong>
                                    {{ currentDriverLocationName || 'Loading...' }}
                                </div>
                                <div class="col-md-4 text-end">
                                    <span class="badge bg-primary">
                                        Search Radius: {{ activeSearchRadiusKm }} km
                                    </span>
                                </div>
                            </div>
                        </div>

                        <!-- Editable Radius with Refresh -->
                        <div class="input-group mb-3">
                            <span class="input-group-text">
                                <i class="fas fa-bullseye"></i>
                            </span>
                            <input
                                type="number"
                                class="form-control"
                                v-model.number="searchRadiusKm"
                                min="0.1"
                                max="50"
                                step="0.5"
                                placeholder="Distance in km">
                            <span class="input-group-text">km</span>
                            <button
                                class="btn btn-primary"
                                type="button"
                                @click="fetchNearbyDrivers"
                                :disabled="isLoadingNearbyDrivers || !searchRadiusKm || searchRadiusKm <= 0">
                                <b-spinner small v-if="isLoadingNearbyDrivers"></b-spinner>
                                <i class="fas fa-sync-alt" v-else></i>
                                Refresh Search
                            </button>
                        </div>

                        <!-- Found Count -->
                        <div class="mb-3">
                            <span class="badge bg-success" v-if="nearbyDrivers.length > 0">
                                <i class="fas fa-check-circle"></i>
                                {{ nearbyDrivers.length }} driver(s) found within {{ activeSearchRadiusKm }}km
                            </span>
                            <span class="badge bg-warning" v-else-if="!isLoadingNearbyDrivers">
                                <i class="fas fa-exclamation-triangle"></i>
                                No drivers found within {{ activeSearchRadiusKm }}km
                            </span>
                        </div>

                        <!-- Loading State -->
                        <div v-if="isLoadingNearbyDrivers" class="text-center py-5">
                            <b-spinner class="align-middle"></b-spinner>
                            <p class="mt-2">Searching for drivers within {{ activeSearchRadiusKm }}km...</p>
                        </div>

                        <!-- No Drivers Found -->
                        <div v-else-if="nearbyDrivers.length === 0" class="alert alert-warning">
                            <i class="fas fa-exclamation-triangle"></i>
                            No eligible drivers found within {{ activeSearchRadiusKm }}km radius.
                            <div class="mt-2">
                                <small>Try increasing the search radius above and click "Refresh Search"</small>
                            </div>
                        </div>

                        <!-- Driver Cards -->
                        <div v-else>
                            <div
                                v-for="driver in nearbyDrivers"
                                :key="driver.id"
                                class="card mb-3 shadow-sm"
                                style="border-left: 4px solid #17a2b8; cursor: pointer; transition: all 0.3s;"
                                @mouseover="$event.currentTarget.style.boxShadow = '0 4px 8px rgba(0,0,0,0.2)'"
                                @mouseleave="$event.currentTarget.style.boxShadow = '0 1px 3px rgba(0,0,0,0.12)'">
                                <div class="card-body">
                                    <div class="row align-items-center">
                                        <div class="col-md-7">
                                            <h6 class="mb-1">
                                                <i class="fas fa-user-circle me-2 text-info"></i>
                                                <strong>{{ driver.name }}</strong>
                                            </h6>
                                            <small class="text-muted d-block">
                                                <i class="fas fa-phone me-1"></i>Phone: {{ driver.phone }}
                                            </small>
                                            <small class="text-muted d-block">
                                                <i class="fas fa-signal me-1"></i>Status:
                                                <span class="badge bg-success">{{ driver.status }}</span>
                                                | Active Orders: <strong>{{ driver.current_orders_count }}</strong>
                                            </small>
                                        </div>
                                        <div class="col-md-3 text-center">
                                            <h5 class="text-info mb-0">
                                                <i class="fas fa-car"></i>
                                                {{ driver.distance_display }}
                                            </h5>
                                            <small class="text-muted">{{ driver.distance_km }} km</small>
                                        </div>
                                        <div class="col-md-2">
                                            <button
                                                type="button"
                                                class="btn btn-primary btn-sm w-100"
                                                @click="selectNearbyDriver(driver)">
                                                <i class="fas fa-check-circle"></i>
                                                Select
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal" @click="closeNearbyDriversModal">
                            <i class="fas fa-times"></i> Close
                        </button>
                    </div>
                </div>
            </div>
        </div>

    </div>
</template>
<script>
import axios from "axios";
import Auth from '../../Auth.js';
import DriverNotifications from './DriverNotifications.vue';
import InvoiceDetails from './InvoiceDetails.vue';
import ZenfooStoreItems from './ZenfooStoreItems.vue';
import CustomerReports from './CustomerReports.vue';
import SupportManagement from './SupportManagement.vue';
import DeliveryBoyTrack from '../DeliveryBoys/DeliveryBoyTrack.vue';

export default {
    components: {
        DriverNotifications,
        InvoiceDetails,
        ZenfooStoreItems,
        CustomerReports,
        SupportManagement,
        DeliveryBoyTrack
    },
    data: function () {
        return {
            login_user: Auth.user,

            isLoading:false,
            isLoadingDboy: false,
            isLoadingUstatus: false,

            // Emergency Driver Change
            emergencyDriverPhone: '',
            foundDriver: null,
            isSearchingDriver: false,
            isChangingDriver: false,
            driverSearchError: null,
            previousDriversDetails: [],

            // Nearby Drivers Feature
            showNearbyDriversModal: false,
            nearbyDrivers: [],
            isLoadingNearbyDrivers: false,
            searchRadiusKm: 0.5, // Default 500 meters (editable input)
            activeSearchRadiusKm: 0.5, // Actually searched radius (for display only)
            currentDriverLocation: null,
            currentDriverLocationName: null,

            id: null,
            order: [],
            order_items: [],
            store_wise_items: [],
            combo_items: [],
            seller_assignments: [],
            customer: null,
            paytmTransaction: null,

            discount_in_rupees: 0,
            whatsapp_message:"",

            selectedItems: [],
            select: '',
            all_select: false,

            status_id:'',

            deliveryBoys:[],
            delivery_boy_id:'',
            expandedItems: [],
            activeTab: 'order-details',
            cancelledStores: [],
        }

    },
    computed: {
    isSellerRoute() {
      // Use this.$route to access the current route
      return this.$route.path.startsWith('/seller/');
    },
    isDeliveryBoyRoute() {
      // Use this.$route to access the current route
      return this.$route.path.startsWith('/delivery_boy/');
    },
    invoiceRoute() {
      // Define route configurations based on user roles
      let routeConfig = null;
      switch (this.login_user.role.name) {
        case 'Seller':
          routeConfig = {
            name: 'SellerInvoiceOrder',
            params: { id: this.order.order_id },
          };
          break;
        case 'Delivery Boy':
          routeConfig = {
            name: 'DeliveryBoyInvoiceOrder',
            params: { id: this.order.order_id },
          };
          break;
        case 'Admin':
         routeConfig = {
            name: 'InvoiceOrder',
            params: { id: this.order.order_id },
          };
          break;
        case 'Super Admin':
          routeConfig = {
            name: 'InvoiceOrder',
            params: { id: this.order.order_id },
          };
          break;
        default:
          // Handle any other roles or cases
          break;
      }

      return routeConfig;
    },
    viewProductRoute() {
      // Define route configurations based on user roles
      let routeConfig = null;
      switch (this.login_user.role.name) {
        case 'Seller':
          routeConfig = {
            name: 'SellerViewProduct',
            params: { id: this.item.product_id },
          };
          break;
        case 'Delivery Boy':
          routeConfig = {
            name: 'DeliveryBoyViewProduct',
            params: { id: this.item.product_id },
          };
          break;
        case 'Admin':
         routeConfig = {
            name: 'ViewProduct',
            params: { id: this.item.product_id},
          };
          break;
        case 'Super Admin':
          routeConfig = {
            name: 'ViewProduct',
            params: { id: this.item.product_id },
          };
          break;
        default:
          // Handle any other roles or cases
          break;
      }

      return routeConfig;
    },
    getProductRoute() {
      return (productId) => {
        let routeConfig = null;
        switch (this.login_user.role.name) {
          case 'Seller':
            routeConfig = {
              name: 'SellerViewProduct',
              params: { id: productId },
            };
            break;
          case 'Delivery Boy':
            routeConfig = {
              name: 'DeliveryBoyViewProduct',
              params: { id: productId },
            };
            break;
          case 'Admin':
          case 'Super Admin':
            routeConfig = {
              name: 'ViewProduct',
              params: { id: productId },
            };
            break;
          default:
            break;
        }
        return routeConfig;
      };
    },
    zenfooStoreItems() {
      return this.store_wise_items.filter(store => [12, 13, 14].includes(store.store_id));
    },
    nonZenfooStoreItems() {
      return this.store_wise_items.filter(store => ![12, 13, 14].includes(store.store_id));
    },
    totalStoresCount() {
      // Check if store_id 15 exists along with other stores
      const hasStore15 = this.store_wise_items.some(store => store.store_id === 15);
      const hasOtherStores = this.store_wise_items.some(store => store.store_id !== 15);

      // Multi store only if store 15 exists AND there are other stores
      if (hasStore15 && hasOtherStores) {
        return 2; // Multi store
      }
      return 1; // Single store
    },
    billingSummaryItems() {
      if (!this.order || !this.order.cart_metadata) return [];

      let meta = this.order.cart_metadata;
      if (typeof meta === 'string') {
        try { meta = JSON.parse(meta); } catch(e) { return []; }
      }

      let summary = meta && meta.billing_summary ? meta.billing_summary : null;
      if (!summary) return [];

      // Keys to skip (non-display values)
      const skipKeys = ['currency', 'rain_surcharge_applicable', 'promo_code'];

      // Hide "Free Delivery Order Amount" when free delivery isn't actually applied
      const isFreeDelivery = !!summary.is_free_delivery && summary.is_free_delivery !== 'false';
      if (!isFreeDelivery) {
        skipKeys.push('free_delivery_order_amount');
      }

      // Human-readable labels
      const labelMap = {
        'items_mrp': 'Items MRP',
        'combo_mrp': 'Combo MRP',
        'discount': 'Discount',
        'delivery_charge': 'Delivery Charge',
        'delivery_tip': 'Delivery Tip',
        'gst_charges': 'GST Charges',
        'customer_gst_percent': 'Customer GST %',
        'payment_gateway_fees': 'Payment Gateway Fees',
        'payment_gateway_fees_percent': 'Payment Gateway Fees %',
        'additional_charges': 'Additional Charges',
        'promocode_discount': 'Promocode Discount',
        'wallet_deduction': 'Wallet Deduction',
        'claimable_milestone_amount': 'Milestone Amount',
        'total_savings': 'Total Savings',
        'rain_surcharge': 'Rain Surcharge',
        'multi_order_charge': 'Multi Order Charge',
        'multi_order_charges': 'Multi Order Charge',
        'to_be_paid': 'To Be Paid',
        'is_free_delivery': 'Is Free Delivery',
        'free_delivery_order_amount': 'Free Delivery Order Amount',
      };

      // Keys whose value is a percentage (display "X%" with no currency prefix)
      const percentKeys = ['customer_gst_percent', 'payment_gateway_fees_percent'];
      // Keys whose value is a boolean (display "Yes" / "No" with no currency prefix)
      const booleanKeys = ['is_free_delivery'];

      let currency = summary.currency || this.$currency || '₹';
      let items = [];

      for (let key in summary) {
        if (skipKeys.includes(key)) continue;

        let val = summary[key];

        // Skip null/empty (booleans are always shown if present; zero amounts hidden except to_be_paid)
        if (val === null || val === undefined || val === '') continue;
        if (!booleanKeys.includes(key) && key !== 'to_be_paid' && parseFloat(val) === 0) continue;

        let label = labelMap[key] || key.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
        let displayVal;
        if (booleanKeys.includes(key)) {
          const truthy = val === true || val === 1 || val === '1' || val === 'true';
          displayVal = truthy ? 'Yes' : 'No';
        } else if (percentKeys.includes(key)) {
          displayVal = `${val}%`;
        } else {
          displayVal = currency + val;
        }

        items.push({
          label: label,
          value: displayVal,
          bold: key === 'to_be_paid',
        });
      }

      return items;
    },
  },
    created: function () {
        this.id = this.$route.params.id;
        //this.record = this.$route.params.record;
        if (this.id) {
            this.getOrder();
        }
        if (this.order.discount > 0) {
            let discounted_amount = this.order.total * this.order.discount / 100;
            let remaining_final = this.order.total - discounted_amount;
            this.discount_in_rupees = this.order.total - remaining_final;
        }

        // Handle tab query parameter (for notification navigation)
        if (this.$route.query.tab === 'support') {
            this.activeTab = 'support-management';
        }
    },
    methods: {
        formatDate(dateTime) {
            const date = new Date(dateTime);
            const day = date.getDate().toString().padStart(2, '0');
            const month = (date.getMonth() + 1).toString().padStart(2, '0'); // Month is 0-based
            const year = date.getFullYear();

            return `${day}-${month}-${year}`;
        },
        getOrder() {
            this.isLoading = true
            axios.get(this.$apiUrl + '/orders/view/' + this.id)
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    if (data.status === 1) {
                        this.order = response.data.data.order;
                        this.order_items = response.data.data.order_items || [];
                        // this.store_wise_items = response.data.data.store_wise_items || [];


                        this.store_wise_items = (response.data.data.store_wise_items || []).map(store => {
                            return {
                                ...store,
                                selectedSeller:
                                    store.eligible_sellers && store.eligible_sellers.length
                                        ? store.eligible_sellers[0].seller_id
                                        : ''
                            };
                        });

                        this.deliveryBoys = response.data.data.deliveryBoys;
                        this.customer = response.data.data.customer || null;

                        this.combo_items = response.data.data.combo_items || [];

                        // Handle seller_assignments with prefilled values
                        this.seller_assignments = (response.data.data.seller_assignments || []).map(assignment => {
                            return {
                                ...assignment,
                                selectedSeller: assignment.assigned_seller
                                    ? assignment.assigned_seller.seller_id
                                    : (assignment.eligible_sellers && assignment.eligible_sellers.length
                                        ? assignment.eligible_sellers[0].seller_id
                                        : '')
                            };
                        });

                        this.delivery_boy_id = (this.order.delivery_boy_id != 0 && this.order.delivery_boy_id != "") ? this.order.delivery_boy_id:"";

                        // Load previous drivers details from API response
                        this.previousDriversDetails = response.data.data.previous_drivers_details || [];

                        // Paytm transaction details (if paid via QR)
                        this.paytmTransaction = response.data.data.paytm_transaction || null;

                        // Cancelled order: load the stores that still have to be paid
                        if (this.order.active_status == 7) {
                            this.getCancelledOrderStores();
                        }

                    } else {
                        this.showError(data.message);
                        setTimeout(() => {
                            this.$router.back();
                        }, 1000);
                    }
                }).catch(error => {
                this.isLoading = false;
                if (error.request.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError("Something went wrong!");
                }
            });
        },

        toggleItemDetails(itemId) {
            const index = this.expandedItems.indexOf(itemId);
            if (index > -1) {
                this.expandedItems.splice(index, 1);
            } else {
                this.expandedItems.push(itemId);
            }
        },

        // assignSeller(store) {
        //     this.$swal.fire({
        //         title: "Assign Seller",
        //         text: `Do you want to assign this seller to ${store.store_name}?`,
        //         icon: 'question',
        //         showCancelButton: true,
        //         confirmButtonColor: '#9AC444',
        //         cancelButtonColor: '#d33',
        //         confirmButtonText: 'Yes, Assign!',
        //         cancelButtonText: 'Cancel'
        //     }).then(result => {
        //         if (result.value) {
        //             // TODO: Make API call here to assign seller
        //             console.log('Assigning seller:', store.selectedSeller, 'to store:', store.store_id);
        //             this.showMessage("success", "Seller assigned successfully!");
        //         }
        //     });
        // },

        assignSeller(store) {
            this.$swal.fire({
            title: "Assign Seller",
            text: `Assign this seller to ${store.store_name}?`,
            icon: "question",
            showCancelButton: true,
            confirmButtonText: "Yes",
            cancelButtonText: "Cancel",
            }).then(result => {
                if (result.value) {

                    let postData = {
                        order_id: this.order.order_id,
                        store_id: store.store_id,
                        seller_id: store.selectedSeller,
                        cus_id: this.order.user_id,
                        items: store.items.map(item => ({
                            product_id: item.product_id,
                            variant_id: item.product_variant_id
                        }))
                    };

                    axios.post(this.$apiUrl + "/orders/assign-seller", postData)
                        .then((response) => {
                            if (response.data.status === 1) {
                                this.showMessage("success", response.data.message);
                            } else {
                                this.showMessage("error", response.data.message);
                            }
                        })
                        .catch(() => {
                            this.showError("Something went wrong!");
                        });
                }
            });
        },

        assignComboSeller(combo) {
            this.$swal.fire({
                title: "Assign Seller",
                text: `Assign this seller to combo "${combo.combo_name || 'Combo Pack'}"?`,
                icon: "question",
                showCancelButton: true,
                confirmButtonText: "Yes",
                cancelButtonText: "Cancel",
            }).then(result => {
                if (result.value) {
                    let postData = {
                        order_id: this.order.order_id,
                        store_id: combo.store_id,
                        seller_id: combo.selectedSeller,
                        cus_id: this.order.user_id,
                        combo_id: combo.combo_id,
                        combo_order_item_id: combo.id,
                        items: combo.products.map(product => ({
                            product_id: product.product_id,
                            variant_id: product.product_variant_id
                        }))
                    };

                    axios.post(this.$apiUrl + "/orders/assign-seller", postData)
                        .then((response) => {
                            if (response.data.status === 1) {
                                this.showMessage("success", response.data.message);
                            } else {
                                this.showMessage("error", response.data.message);
                            }
                        })
                        .catch(() => {
                            this.showError("Something went wrong!");
                        });
                }
            });
        },

        assignSellerFromBottom(assignment) {
            this.$swal.fire({
                title: "Assign Seller",
                text: `Assign seller to "${assignment.store_name}"?`,
                icon: "question",
                showCancelButton: true,
                confirmButtonText: "Yes",
                cancelButtonText: "Cancel",
            }).then(result => {
                if (result.value) {
                    let postData = {
                        order_id: this.order.order_id,
                        store_id: assignment.store_id,
                        seller_id: assignment.selectedSeller,
                        cus_id: this.order.user_id
                    };

                    axios.post(this.$apiUrl + "/orders/assign-seller", postData)
                        .then((response) => {
                            if (response.data.status === 1) {
                                this.showMessage("success", response.data.message);
                                this.getOrder(); // Refresh data
                            } else {
                                this.showMessage("error", response.data.message);
                            }
                        })
                        .catch(() => {
                            this.showError("Something went wrong!");
                        });
                }
            });
        },

        formatSellerStatus(status) {
            const statusMap = {
                'assigned_to_seller': 'Assigned to Seller',
                'packed_by_seller': 'Packed by Seller',
                'given_to_delivery_partner': 'Given to Delivery Partner'
            };
            return statusMap[status] || status;
        },


        whatsappMessageLink(country_code,mobile,user_name,order_id, item_id){
            return "https://api.whatsapp.com/send?phone=+"+country_code+" "+mobile+"&text=Hello "+user_name+" ,Your order with ID :"+order_id+" is  "+item_id+". Please take a note of it. If you have further queries feel free to contact us. Thank you.";
        },
        updateStatus(){
            let vm = this;

            // Collect all product_ids already loaded on this page
            const productIdSet = new Set();

            // From normal store items
            (this.store_wise_items || []).forEach(store => {
                (store.items || []).forEach(item => {
                    if (item.product_id) productIdSet.add(item.product_id);
                });
            });

            // From combo items (store_wise_products or flat products list)
            (this.combo_items || []).forEach(combo => {
                if (combo.store_wise_products && combo.store_wise_products.length > 0) {
                    combo.store_wise_products.forEach(storeGroup => {
                        (storeGroup.products || []).forEach(product => {
                            if (product.product_id) productIdSet.add(product.product_id);
                        });
                    });
                } else {
                    (combo.products || []).forEach(product => {
                        if (product.product_id) productIdSet.add(product.product_id);
                    });
                }
            });

            const productIds = Array.from(productIdSet);
            // Captured before cancelling — the order is refetched afterwards.
            const cancelledDriverId = (this.order && this.order.delivery_boy_id) ? this.order.delivery_boy_id : null;

            // A reason is mandatory — it decides whether the order can still be cancelled
            // after handover to the driver, and whether the money goes back to the wallet.
            axios.get(this.$apiUrl + '/orders/cancel_reasons').then((reasonResponse) => {
                const reasons = (reasonResponse.data && reasonResponse.data.data) ? reasonResponse.data.data : [];
                const options = reasons.map(r => `<option value="${r.value}">${r.label}</option>`).join('');
                const walletReasons = reasons.filter(r => r.refund_to_wallet).map(r => r.label);

                vm.$swal.fire({
                    title: "Cancel this order?",
                    html:
                        `<div style="text-align:left">
                            <label style="font-size:14px;font-weight:600">Reason (required)</label>
                            <select id="cancel-reason" class="swal2-select" style="width:100%;margin:6px 0 12px 0">
                                <option value="">-- Select a reason --</option>
                                ${options}
                            </select>
                            <label style="font-size:14px;font-weight:600">Note (optional)</label>
                            <textarea id="cancel-note" class="swal2-textarea" style="width:100%;margin:6px 0" placeholder="What happened?"></textarea>
                            ${walletReasons.length ? `<div style="font-size:12px;color:#8a6d3b;background:#fcf8e3;padding:8px;border-radius:4px">
                                For <b>${walletReasons.join(', ')}</b> the full amount is credited to the customer wallet. No bank/UPI refund is sent.
                            </div>` : ''}
                        </div>`,
                    confirmButtonText: "Cancel Order",
                    cancelButtonText: "Close",
                    icon: 'warning',
                    showCancelButton: true,
                    focusConfirm: false,
                    confirmButtonColor: '#9AC444',
                    cancelButtonColor: '#d33',
                    preConfirm: () => {
                        const reason = document.getElementById('cancel-reason').value;
                        if (!reason) {
                            vm.$swal.showValidationMessage('Please select a reason');
                            return false;
                        }
                        return { reason: reason, note: document.getElementById('cancel-note').value };
                    },
                }).then(result => {
                    if (result.value) {
                        vm.isLoadingUstatus = true
                        axios.post(vm.$apiUrl + '/orders/admin_cancel_order', {
                            order_id: vm.id,
                            product_ids: productIds,
                            reason: result.value.reason,
                            reason_note: result.value.note,
                        }).then((response) => {
                            vm.isLoadingUstatus = false
                            let data = response.data;
                            if (data.status === 1) {
                                vm.getOrder();
                                vm.showMessage("success", data.message);
                                setTimeout(
                                    function () {
                                        vm.$swal.close();
                                        // Driver issue: offer to hold the driver back from new orders.
                                        if (result.value.reason === 'driver_issue' && cancelledDriverId) {
                                            vm.askMarkDriverProblematic(cancelledDriverId, result.value.note);
                                        }
                                    }, 2000);
                            } else {
                                vm.showError(data.message);
                                vm.isLoadingUstatus = false;
                            }
                        }).catch(error => {
                            vm.isLoadingUstatus = false;
                            vm.showError("Something went wrong!");
                        });
                    }
                });
            }).catch(error => {
                vm.showError("Could not load cancellation reasons.");
            });
        },

        getCancelledOrderStores(){
            axios.post(this.$apiUrl + '/orders/cancelled_order_stores', { order_id: this.id })
                .then((response) => {
                    this.cancelledStores = response.data.data || [];
                })
                .catch(() => {
                    this.cancelledStores = [];
                });
        },

        payStoreForCancelledOrder(store){
            let vm = this;
            this.$swal.fire({
                title: "Pay store",
                html:
                    `<div style="text-align:left">
                        <p style="font-size:14px">Zenfoo pays <b>${store.store_name || ('Seller #' + store.seller_id)}</b> for the food already prepared on cancelled order #${vm.id}.</p>
                        <label style="font-size:14px;font-weight:600">Amount</label>
                        <input id="pay-store-amount" type="number" min="0.01" step="0.01" class="swal2-input" style="width:100%;margin:6px 0" placeholder="0.00">
                        <label style="font-size:14px;font-weight:600">Note (optional)</label>
                        <textarea id="pay-store-note" class="swal2-textarea" style="width:100%;margin:6px 0" placeholder="Why this amount?"></textarea>
                    </div>`,
                confirmButtonText: "Pay Store",
                cancelButtonText: "Cancel",
                icon: 'question',
                showCancelButton: true,
                focusConfirm: false,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
                preConfirm: () => {
                    const amount = parseFloat(document.getElementById('pay-store-amount').value);
                    if (!amount || amount <= 0) {
                        vm.$swal.showValidationMessage('Please type a valid amount');
                        return false;
                    }
                    return { amount: amount, note: document.getElementById('pay-store-note').value };
                },
            }).then(result => {
                if (result.value) {
                    axios.post(vm.$apiUrl + '/orders/pay_store_for_cancelled_order', {
                        order_id: vm.id,
                        seller_id: store.seller_id,
                        amount: result.value.amount,
                        note: result.value.note,
                    }).then((response) => {
                        let data = response.data;
                        if (data.status === 1) {
                            vm.showMessage("success", data.message);
                            vm.getCancelledOrderStores();
                        } else {
                            vm.showError(data.message);
                        }
                    }).catch(error => {
                        vm.showError("Something went wrong!");
                    });
                }
            });
        },

        askMarkDriverProblematic(driverId, note){
            let vm = this;
            this.$swal.fire({
                title: "Hold this driver?",
                html:
                    `<div style="text-align:left">
                        <p style="font-size:14px">The driver will receive no new orders until an admin moves them back to the normal list.</p>
                        <label style="font-size:14px;font-weight:600">Reason</label>
                        <textarea id="problematic-reason" class="swal2-textarea" style="width:100%">${note ? note : 'Driver issue on order #' + vm.id}</textarea>
                    </div>`,
                confirmButtonText: "Yes, Hold Driver",
                cancelButtonText: "No, Leave Active",
                icon: 'warning',
                showCancelButton: true,
                focusConfirm: false,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
                preConfirm: () => {
                    const reason = document.getElementById('problematic-reason').value;
                    if (!reason) {
                        vm.$swal.showValidationMessage('Please type a reason');
                        return false;
                    }
                    return reason;
                },
            }).then(result => {
                if (result.value) {
                    axios.post(vm.$apiUrl + '/delivery_boys/mark-problematic', {
                        id: driverId,
                        reason: result.value,
                        order_id: vm.id,
                    }).then((response) => {
                        let data = response.data;
                        if (data.status === 1) {
                            vm.showMessage("success", data.message);
                        } else {
                            vm.showError(data.message);
                        }
                    }).catch(error => {
                        vm.showError("Could not update the driver.");
                    });
                }
            });
        },

        assignDeliveryBoy(){
            console.log('assignDeliveryBoy called');
            console.log('order_id:', this.id);
            console.log('delivery_boy_id:', this.delivery_boy_id);

            this.isLoadingDboy = true
            let postData = {
                order_id: this.id,
                delivery_boy_id: this.delivery_boy_id
            }
            console.log('postData:', postData);
            console.log('API URL:', this.$apiUrl + '/orders/admin_assign_delivery_boy');

            // Use the new admin assign API which also sets driver_accepted_at_time
            axios.post(this.$apiUrl + '/orders/admin_assign_delivery_boy', postData).then((response) => {
                console.log('API response:', response);
                this.isLoadingDboy = false
                let data = response.data;
                if (data.status === 1) {

                    this.delivery_boy_id = '';
                    this.getOrder();
                    this.showMessage("success", data.message);
                    setTimeout(
                        function () {
                            vm.$swal.close();
                        }, 2000);
                } else {
                    this.showMessage("error", data.message);
                    this.isLoadingDboy = false;
                }
            }).catch(error => {
                this.isLoadingDboy = false;
                this.showError("Something went wrong!");
            });
        },

        downloadInvoice(){
            this.isLoading = true;
            let postData = {
                order_id: this.id,
            }
            axios({
                url: this.$apiUrl + '/orders/invoice_download',
                method: 'post',
                responseType: 'blob',

                data: postData
            }).then((response) => {
                var fileURL = window.URL.createObjectURL(new Blob([response.data]));
                var fileLink = document.createElement('a');
                fileLink.href = fileURL;
                fileLink.setAttribute('download', 'Invoice-No:#'+this.id+'.pdf');
                document.body.appendChild(fileLink);
                fileLink.click();
                this.isLoading = false;
            }).catch(error => {
                if (error.request.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError("Something went wrong!");
                }
                this.isLoading = false;
            });
        },


        allSelectCheckBox() {
            if (this.all_select == false) {
                this.all_select = true
                this.order_items.forEach(item => {
                    this.selectedItems.push(item.id)
                });
            } else {
                this.all_select = false
                this.selectedItems = []
            }
        },
        selectCheckBox() {
            let uniqueSelectedItems = [...new Set(this.selectedItems)];
            if (this.order_items.length === uniqueSelectedItems.length) {
                this.all_select = true
            } else {
                this.all_select = false
            }
        },
        updateItemsStatus(){
            let vm = this;
            let uniqueSelectedItems =  [...new Set(this.selectedItems)];
            if (uniqueSelectedItems.length !== 0) {
                this.$swal.fire({
                    title: "Are you Sure?",
                    text: "You want be able to revert this",
                    confirmButtonText: "Yes, Sure",
                    cancelButtonText: "Cancel",
                    icon: 'warning',
                    showCancelButton: true,
                    confirmButtonColor: '#9AC444',
                    cancelButtonColor: '#d33',
                }).then(result => {
                    if (result.value) {
                        let ids = uniqueSelectedItems.toString();
                        this.isLoading = true
                        let postData = {
                            ids: ids,
                            status_id:this.status_id
                        }
                        axios.post(this.$apiUrl + '/orders/update_items_status', postData).then((response) => {
                            this.isLoading = false
                            let data = response.data;
                            if (data.status === 1) {

                                this.getOrder();
                                this.status_id = '';
                                this.selectedItems = [];
                                this.all_select = false;
                                this.showMessage("success", data.message);
                                setTimeout(
                                    function () {
                                        vm.$swal.close();
                                    }, 2000);
                            } else {
                                vm.showError(data.message);
                                vm.isLoading = false;
                            }
                        }).catch(error => {
                            vm.isLoading = false;
                            this.showError("Something went wrong!");
                        });
                    }
                });
            } else {
                this.showWarning("Select at least one record!");
            }
        },
        getAdditionalChargesTotal(charges) {
            if (!charges || !Array.isArray(charges)) return 0;
            return charges.reduce((total, charge) => total + (parseFloat(charge.amount) || 0), 0).toFixed(2);
        },
        isZenfooStore(storeId) {
            return [12, 13, 14].includes(storeId);
        },
        openEmergencyDriverModal() {
            // Reset modal state
            this.resetEmergencyDriverModal();
            // Open the emergency driver change modal using Bootstrap 5 modal
            const modalElement = document.getElementById('emergencyDriverModal');
            const modal = new bootstrap.Modal(modalElement);
            modal.show();
        },
        searchDriverByPhone() {
            if (!this.emergencyDriverPhone || this.emergencyDriverPhone.trim() === '') {
                this.showWarning('Please enter a phone number');
                return;
            }

            this.isSearchingDriver = true;
            this.driverSearchError = null;
            this.foundDriver = null;

            axios.post('/api/orders/search_driver_by_phone', {
                phone: this.emergencyDriverPhone.trim()
            })
            .then(response => {
                this.isSearchingDriver = false;

                if (response.data.status === 1) {
                    this.foundDriver = response.data.data;
                    this.showMessage('success', 'Driver found!');
                } else {
                    this.driverSearchError = response.data.message || 'Driver not found';
                }
            })
            .catch(error => {
                this.isSearchingDriver = false;
                console.error('Search driver error:', error);
                this.driverSearchError = error.response?.data?.message || 'Failed to search driver. Please try again.';
            });
        },
        confirmDriverChange() {
            if (!this.foundDriver) {
                this.showWarning('No driver selected');
                return;
            }

            if (!this.order.delivery_boy_id) {
                this.showWarning('No current driver assigned to this order');
                return;
            }

            // Show confirmation dialog
            this.$swal.fire({
                title: 'Confirm Driver Change?',
                html: `
                    <p><strong>Current Driver:</strong> ${this.order.delivery_boy_name || 'Not Assigned'}</p>
                    <p><strong>New Driver:</strong> ${this.foundDriver.name}</p>
                    <p class="text-danger mt-3">This action cannot be undone. The current driver will be removed from this order.</p>
                `,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#f0ad4e',
                cancelButtonColor: '#6c757d',
                confirmButtonText: 'Yes, Change Driver',
                cancelButtonText: 'Cancel'
            }).then((result) => {
                if (result.isConfirmed) {
                    this.performDriverChange();
                }
            });
        },
        performDriverChange() {
            this.isChangingDriver = true;

            axios.post('/api/orders/emergency_change_driver', {
                order_id: this.id,
                new_delivery_boy_id: this.foundDriver.id
            })
            .then(response => {
                this.isChangingDriver = false;

                if (response.data.status === 1) {
                    this.showMessage('success', response.data.message || 'Driver changed successfully!');

                    // Close modal
                    const modalElement = document.getElementById('emergencyDriverModal');
                    const modal = bootstrap.Modal.getInstance(modalElement);
                    if (modal) {
                        modal.hide();
                    }

                    // Reset modal state
                    this.resetEmergencyDriverModal();

                    // Reload order details
                    this.getOrder();
                } else {
                    this.showError(response.data.message || 'Failed to change driver');
                }
            })
            .catch(error => {
                this.isChangingDriver = false;
                console.error('Change driver error:', error);
                this.showError(error.response?.data?.message || 'Failed to change driver. Please try again.');
            });
        },
        resetEmergencyDriverModal() {
            this.emergencyDriverPhone = '';
            this.foundDriver = null;
            this.driverSearchError = null;
            this.isSearchingDriver = false;
            this.isChangingDriver = false;
        },

        // Nearby Drivers Methods
        openNearbyDriversModal() {
            if (!this.order.delivery_boy_id) {
                this.showWarning('No driver currently assigned to this order');
                return;
            }

            // Fetch nearby drivers
            this.fetchNearbyDrivers();

            // Open the modal
            const modalElement = document.getElementById('nearbyDriversModal');
            const modal = new bootstrap.Modal(modalElement);
            modal.show();
        },

        fetchNearbyDrivers() {
            if (!this.searchRadiusKm || this.searchRadiusKm <= 0) {
                this.showWarning('Please enter a valid search radius');
                return;
            }

            this.isLoadingNearbyDrivers = true;
            this.nearbyDrivers = [];
            this.currentDriverLocation = null;
            this.currentDriverLocationName = null;

            // Store the active search radius (won't change when user types in input)
            this.activeSearchRadiusKm = this.searchRadiusKm;

            axios.post('/api/orders/find_nearby_drivers', {
                order_id: this.id,
                current_driver_id: this.order.delivery_boy_id,
                radius_km: this.searchRadiusKm
            })
            .then(response => {
                this.isLoadingNearbyDrivers = false;

                if (response.data.status === 1) {
                    const data = response.data.data;

                    // Store current driver location
                    this.currentDriverLocation = data.current_driver;
                    this.currentDriverLocationName = data.current_driver.location_name;

                    // Store nearby drivers
                    this.nearbyDrivers = data.nearby_drivers || [];

                    // Show success message
                    if (this.nearbyDrivers.length > 0) {
                        this.showMessage('success', data.total_found + ' driver(s) found within ' + this.activeSearchRadiusKm + 'km');
                    } else {
                        this.showWarning('No eligible drivers found within ' + this.activeSearchRadiusKm + 'km radius');
                    }
                } else {
                    this.showError(response.data.message || 'Failed to find nearby drivers');
                }
            })
            .catch(error => {
                this.isLoadingNearbyDrivers = false;
                console.error('Find nearby drivers error:', error);
                this.showError(error.response?.data?.message || 'Failed to find nearby drivers. Please try again.');
            });
        },

        selectNearbyDriver(driver) {
            // Set the found driver (same as phone search flow)
            this.foundDriver = driver;

            // Close nearby drivers modal
            const nearbyModal = document.getElementById('nearbyDriversModal');
            const modal = bootstrap.Modal.getInstance(nearbyModal);
            if (modal) {
                modal.hide();
            }

            // Show confirmation (same as phone search flow)
            this.confirmDriverChange();
        },

        closeNearbyDriversModal() {
            this.nearbyDrivers = [];
            this.currentDriverLocation = null;
            this.currentDriverLocationName = null;
            this.isLoadingNearbyDrivers = false;
        }
    }
};
</script>
<style scoped>
    .th-width {
        width: auto;
        background: #f7f7f7;
    }

</style>
