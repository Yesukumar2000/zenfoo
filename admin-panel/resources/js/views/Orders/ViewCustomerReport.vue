<template>
    <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
            <h4 class="mb-0"><i class="fas fa-exclamation-triangle me-2"></i>Report Details #{{ reportId }}</h4>
            <button class="btn btn-secondary btn-sm" @click="goBack">
                <i class="fa fa-arrow-left me-2"></i>Back to Reports
            </button>
        </div>

        <div class="card-body" v-if="isLoading">
            <div class="text-center py-5">
                <b-spinner class="align-middle"></b-spinner>
                <p class="mt-2">Loading report details...</p>
            </div>
        </div>

        <div class="card-body" v-else-if="report">
            <!-- Report Summary Card -->
            <div class="card mb-3">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h4 class="card-title mb-0">Report Summary</h4>
                    <div>
                        <span :class="getStatusBadgeClass(report.status)" class="badge me-2">{{ report.status_name }}</span>
                        <span :class="getReportTypeBadgeClass(report.report_type)" class="badge">{{ report.report_type === 'missing' ? 'Item Missing' : report.report_type === 'wrong' ? 'Wrong Item' : 'Return Item' }}</span>
                    </div>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-3">
                            <p class="text-muted mb-1">Report ID</p>
                            <p class="fw-bold">#{{ report.id }}</p>
                        </div>
                        <div class="col-md-3">
                            <p class="text-muted mb-1">Order ID</p>
                            <p class="fw-bold">#{{ report.order_id }}</p>
                        </div>
                        <div class="col-md-3">
                            <p class="text-muted mb-1">Created At</p>
                            <p class="fw-bold">{{ formatDate(report.created_at) }}</p>
                        </div>
                        <div class="col-md-3">
                            <p class="text-muted mb-1">Refund Requested</p>
                            <p>
                                <span v-if="report.is_refund_requested" class="badge bg-primary">Yes</span>
                                <span v-else class="badge bg-secondary">No</span>
                            </p>
                        </div>
                    </div>
                    <div class="row mt-3" v-if="report.description">
                        <div class="col-12">
                            <p class="text-muted mb-1">Description</p>
                            <p>{{ report.description }}</p>
                        </div>
                    </div>
                    <div class="row mt-3" v-if="report.admin_remarks">
                        <div class="col-12">
                            <p class="text-muted mb-1">Admin Remarks</p>
                            <p class="text-info">{{ report.admin_remarks }}</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Customer Details Card -->
            <div class="card mb-3">
                <div class="card-header">
                    <h4 class="card-title mb-0">Customer Details</h4>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-4">
                            <p class="text-muted mb-1">Customer Name</p>
                            <p class="fw-bold">{{ report.customer_name || 'N/A' }}</p>
                        </div>
                        <div class="col-md-4">
                            <p class="text-muted mb-1">Mobile</p>
                            <p class="fw-bold">{{ report.customer_mobile || 'N/A' }}</p>
                        </div>
                        <div class="col-md-4">
                            <p class="text-muted mb-1">Email</p>
                            <p class="fw-bold">{{ report.customer_email || 'N/A' }}</p>
                        </div>
                    </div>
                    <div class="row mt-3" v-if="report.customer_address">
                        <div class="col-12">
                            <p class="text-muted mb-1"><i class="fas fa-map-marker-alt me-1"></i>Delivery Address</p>
                            <p class="fw-bold mb-0">
                                {{ report.customer_address.full_address || report.customer_address.address || 'N/A' }}
                            </p>
                            <small class="text-muted" v-if="report.customer_address.landmark">
                                Landmark: {{ report.customer_address.landmark }}
                            </small>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Order Details Card -->
            <div class="card mb-3" v-if="report.order_details">
                <div class="card-header">
                    <h4 class="card-title mb-0">Order Details</h4>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-4" v-if="report.order_details.delivery_partner">
                            <p class="text-muted mb-1">Delivery Partner</p>
                            <p class="fw-bold">{{ report.order_details.delivery_partner.name }}</p>
                        </div>
                        <div class="col-md-4" v-if="report.order_details.delivery_date">
                            <p class="text-muted mb-1">Delivery Date</p>
                            <p class="fw-bold">{{ report.order_details.delivery_date }}</p>
                        </div>
                        <div class="col-md-4">
                            <p class="text-muted mb-1">Has Zenfoo Items</p>
                            <p>
                                <span v-if="report.order_details.has_zenfoo" class="badge bg-success">Yes</span>
                                <span v-else class="badge bg-secondary">No</span>
                            </p>
                        </div>
                    </div>

                    <!-- Stores and Vendors -->
                    <div class="row mt-4" v-if="report.order_details.stores_and_vendors && report.order_details.stores_and_vendors.length">
                        <div class="col-12">
                            <p class="text-muted mb-2">Stores & Vendors</p>
                            <div class="d-flex flex-wrap gap-2">
                                <span v-for="(item, index) in report.order_details.stores_and_vendors" :key="index"
                                      :class="getStoreTypeBadgeClass(item.type)" class="badge">
                                    <template v-if="item.type === 'zenfoo'">
                                        {{ item.store_name }}
                                    </template>
                                    <template v-else-if="item.type === 'vendor'">
                                        {{ item.store_name }} (Vendor)
                                    </template>
                                    <template v-else-if="item.type === 'combo'">
                                        {{ item.combo_name }} (Combo)
                                    </template>
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Reported Items Card -->
            <div class="card mb-3" v-if="report.selected_items && report.selected_items.length">
                <div class="card-header">
                    <h4 class="card-title mb-0">Reported Items</h4>
                </div>
                <div class="card-body">
                    <!-- For Missing Items -->
                    <div v-if="report.report_type === 'missing'">
                        <div v-for="(storeItem, storeIndex) in report.selected_items" :key="'store-' + storeIndex" class="mb-4 store-item-card">
                            <div class="d-flex justify-content-between align-items-start mb-2">
                                <div>
                                    <h6 class="text-primary mb-1">{{ storeItem.store_name || 'Store #' + storeItem.store_id }}</h6>
                                    <p class="text-muted small mb-0" v-if="storeItem.description">{{ storeItem.description }}</p>
                                </div>
                                <div class="seller-info text-end" v-if="storeItem.seller_name">
                                    <span class="badge bg-info">Packed by: {{ storeItem.seller_name }}</span>
                                    <small class="d-block text-muted" v-if="storeItem.seller_store_name">{{ storeItem.seller_store_name }}</small>
                                    <small class="d-block text-muted" v-if="storeItem.seller_mobile">
                                        <i class="fas fa-phone-alt me-1"></i>{{ storeItem.seller_mobile }}
                                    </small>
                                    <small class="d-block text-muted" v-if="storeItem.seller_address">
                                        <i class="fas fa-map-marker-alt me-1"></i>{{ storeItem.seller_address }}
                                    </small>
                                    <small class="d-block" v-if="storeItem.packing_status">
                                        <span :class="getPackingStatusBadgeClass(storeItem.packing_status)">{{ formatPackingStatus(storeItem.packing_status) }}</span>
                                    </small>
                                </div>
                                <div class="seller-info text-end" v-else>
                                    <span class="badge bg-secondary">No seller assigned</span>
                                </div>
                            </div>
                            <b-table
                                :items="storeItem.items || []"
                                :fields="itemFields"
                                :bordered="true"
                                small
                                responsive>
                                <template #cell(price)="row">
                                    <i class="fas fa-rupee-sign"></i> {{ row.item.price }}
                                </template>
                                <template #cell(sub_total)="row">
                                    <i class="fas fa-rupee-sign"></i> {{ row.item.sub_total }}
                                </template>
                            </b-table>
                        </div>
                    </div>

                    <!-- For Wrong Items (with images) -->
                    <div v-else>
                        <div v-for="(storeItem, storeIndex) in report.selected_items" :key="'store-' + storeIndex" class="mb-4 store-item-card">
                            <div class="d-flex justify-content-between align-items-start mb-2">
                                <div>
                                    <h6 class="text-primary mb-1">{{ storeItem.store_name || 'Store #' + storeItem.store_id }}</h6>
                                    <p class="text-muted small mb-0" v-if="storeItem.description">{{ storeItem.description }}</p>
                                </div>
                                <div class="seller-info text-end" v-if="storeItem.seller_name">
                                    <span class="badge bg-info">Packed by: {{ storeItem.seller_name }}</span>
                                    <small class="d-block text-muted" v-if="storeItem.seller_store_name">{{ storeItem.seller_store_name }}</small>
                                    <small class="d-block text-muted" v-if="storeItem.seller_mobile">
                                        <i class="fas fa-phone-alt me-1"></i>{{ storeItem.seller_mobile }}
                                    </small>
                                    <small class="d-block text-muted" v-if="storeItem.seller_address">
                                        <i class="fas fa-map-marker-alt me-1"></i>{{ storeItem.seller_address }}
                                    </small>
                                </div>
                                <div class="seller-info text-end" v-else>
                                    <span class="badge bg-secondary">No seller assigned</span>
                                </div>
                            </div>
                            <div class="row" v-if="storeItem.image_urls && storeItem.image_urls.length">
                                <div class="col-md-3 col-6 mb-3" v-for="(image, imgIndex) in storeItem.image_urls" :key="imgIndex">
                                    <img :src="image" class="img-thumbnail" alt="Wrong item image" @click="openImageModal(image)">
                                </div>
                            </div>
                            <p v-else class="text-muted">No images uploaded</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Reported Combo Items Card -->
            <div class="card mb-3" v-if="report.selected_combo_items && report.selected_combo_items.length">
                <div class="card-header">
                    <h4 class="card-title mb-0">Reported Combo Items</h4>
                </div>
                <div class="card-body">
                    <!-- For Missing Combo Items -->
                    <div v-if="report.report_type === 'missing'">
                        <div v-for="(combo, comboIndex) in report.selected_combo_items" :key="'combo-' + comboIndex" class="mb-4 store-item-card">
                            <div class="mb-2">
                                <h6 class="text-info mb-1">{{ combo.combo_name || 'Combo #' + combo.id }}</h6>
                                <p class="text-muted small mb-0" v-if="combo.description">{{ combo.description }}</p>
                            </div>
                            <div class="row mb-2">
                                <div class="col-md-3">
                                    <small class="text-muted">Quantity:</small> {{ combo.combo_quantity || 1 }}
                                </div>
                                <div class="col-md-3">
                                    <small class="text-muted">Sub Total:</small> <i class="fas fa-rupee-sign"></i> {{ combo.sub_total }}
                                </div>
                                <div class="col-md-3">
                                    <small class="text-muted">Discount:</small> {{ combo.discount_percentage }}%
                                </div>
                            </div>
                            <b-table
                                v-if="combo.products && combo.products.length"
                                :items="combo.products"
                                :fields="comboProductFields"
                                :bordered="true"
                                small
                                responsive>
                                <template #cell(price)="row">
                                    <i class="fas fa-rupee-sign"></i> {{ row.item.price }}
                                </template>
                                <template #cell(sub_total)="row">
                                    <i class="fas fa-rupee-sign"></i> {{ row.item.sub_total }}
                                </template>
                                <template #cell(packer_name)="row">
                                    <span v-if="row.item.packer_name" class="badge bg-info">{{ row.item.packer_name }}</span>
                                    <span v-else class="badge bg-secondary">N/A</span>
                                </template>
                            </b-table>
                        </div>
                    </div>

                    <!-- For Wrong Combo Items (with images) -->
                    <div v-else>
                        <div v-for="(combo, comboIndex) in report.selected_combo_items" :key="'combo-' + comboIndex" class="mb-4 store-item-card">
                            <div class="d-flex justify-content-between align-items-start mb-2">
                                <div>
                                    <h6 class="text-info mb-1">{{ combo.combo_name || 'Combo #' + combo.combo_id }}</h6>
                                    <p class="text-muted small mb-0" v-if="combo.description">{{ combo.description }}</p>
                                </div>
                                <div class="seller-info text-end" v-if="combo.sellers && combo.sellers.length">
                                    <div v-for="(seller, sellerIndex) in combo.sellers" :key="'seller-' + sellerIndex" class="mb-1">
                                        <span class="badge bg-info">Packed by: {{ seller.seller_name }}</span>
                                        <small class="d-block text-muted" v-if="seller.seller_store_name">{{ seller.seller_store_name }}</small>
                                        <small class="d-block text-muted" v-if="seller.seller_mobile">
                                            <i class="fas fa-phone-alt me-1"></i>{{ seller.seller_mobile }}
                                        </small>
                                    </div>
                                </div>
                                <div class="seller-info text-end" v-else>
                                    <span class="badge bg-secondary">No seller assigned</span>
                                </div>
                            </div>
                            <div class="row" v-if="combo.image_urls && combo.image_urls.length">
                                <div class="col-md-3 col-6 mb-3" v-for="(image, imgIndex) in combo.image_urls" :key="imgIndex">
                                    <img :src="image" class="img-thumbnail" alt="Wrong combo item image" @click="openImageModal(image)">
                                </div>
                            </div>
                            <p v-else class="text-muted">No images uploaded</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Delivery Images Card -->
            <div class="card mb-3" v-if="hasDeliveryImages">
                <div class="card-header">
                    <h4 class="card-title mb-0">Delivery Images</h4>
                </div>
                <div class="card-body">
                    <!-- Driver Pickup Images -->
                    <div v-if="report.order_details && report.order_details.driver_pickup_images && report.order_details.driver_pickup_images.length" class="mb-4">
                        <h6 class="text-primary mb-3">Driver Captured Images (When Marked as Pickup)</h6>
                        <div class="row">
                            <div class="col-md-3 col-6 mb-3" v-for="(image, index) in report.order_details.driver_pickup_images" :key="'pickup-' + index">
                                <img :src="image" class="img-thumbnail" alt="Driver pickup image" @click="openImageModal(image)">
                            </div>
                        </div>
                    </div>

                    <!-- Delivery Before Images -->
                    <div v-if="report.order_details && report.order_details.delivery_before_images && report.order_details.delivery_before_images.length">
                        <h6 class="text-primary mb-3">Delivery Time Before Images</h6>
                        <div class="row">
                            <div class="col-md-3 col-6 mb-3" v-for="(image, index) in report.order_details.delivery_before_images" :key="'delivery-' + index">
                                <img :src="image" class="img-thumbnail" alt="Delivery before image" @click="openImageModal(image)">
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Zenfoo Store Returns Card -->
            <div class="card mb-3" v-if="hasZenfooReturn">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h4 class="card-title mb-0"><i class="fas fa-store me-2"></i>Zenfoo Store Return Items</h4>
                    <div>
                        <span v-if="zenfooReturnRecord.is_return_accepted === 1" class="badge bg-success">
                            <i class="fas fa-check me-1"></i>Return Accepted
                        </span>
                        <span v-else class="badge bg-warning">
                            <i class="fas fa-clock me-1"></i>Pending Return
                        </span>
                    </div>
                </div>
                <div class="card-body">
                    <div class="row mb-3">
                        <div class="col-md-4">
                            <p class="text-muted mb-1">Return ID</p>
                            <p class="fw-bold">#{{ zenfooReturnRecord.id }}</p>
                        </div>
                        <div class="col-md-4">
                            <p class="text-muted mb-1">Date</p>
                            <p class="fw-bold">{{ zenfooReturnRecord.date }}</p>
                        </div>
                        <div class="col-md-4">
                            <p class="text-muted mb-1">Refundable Amount</p>
                            <p class="fw-bold text-success">
                                <i class="fas fa-rupee-sign"></i> {{ zenfooReturnRecord.refundable_amount }}
                            </p>
                        </div>
                    </div>

                    <!-- Products Table -->
                    <h6 class="text-primary mb-3">Products to be Returned</h6>
                    <b-table
                        :items="zenfooReturnProducts"
                        :fields="zenfooReturnFields"
                        :bordered="true"
                        small
                        responsive>
                        <template #cell(price)="row">
                            <i class="fas fa-rupee-sign"></i> {{ row.item.price }}
                        </template>
                        <template #cell(sub_total)="row">
                            <i class="fas fa-rupee-sign"></i> {{ row.item.sub_total }}
                        </template>
                    </b-table>

                    <!-- Return Action Button -->
                    <div class="mt-4 p-3 bg-light rounded" v-if="zenfooReturnRecord.is_return_accepted !== 1">
                        <div class="d-flex align-items-center justify-content-between">
                            <div>
                                <p class="mb-1 fw-bold"><i class="fas fa-info-circle me-2 text-info"></i>Return Confirmation</p>
                                <p class="text-muted mb-0 small">When the driver delivers the return items to Zenfoo store, click the button to confirm receipt.</p>
                            </div>
                            <button class="btn btn-success" @click="confirmZenfooReturn" :disabled="isUpdatingZenfooReturn">
                                <span v-if="isUpdatingZenfooReturn">
                                    <b-spinner small></b-spinner> Processing...
                                </span>
                                <span v-else>
                                    <i class="fas fa-check-circle me-2"></i>Return Items Received
                                </span>
                            </button>
                        </div>
                    </div>
                    <div class="mt-4 p-3 bg-success bg-opacity-10 rounded" v-else>
                        <p class="mb-0 text-success fw-bold">
                            <i class="fas fa-check-circle me-2"></i>Return items have been received and accepted for Zenfoo store.
                        </p>
                    </div>
                </div>
            </div>

            <!-- Update Status Card - Hide when status is Resolved (2) -->
            <div class="card mb-3" v-if="report.status !== 2">
                <div class="card-header">
                    <h4 class="card-title mb-0">Update Status</h4>
                </div>
                <div class="card-body">
                    <div class="row">
                        <div class="col-md-4">
                            <b-form-group label="Status">
                                <div class="status-select-wrapper">
                                    <select v-model="updateForm.status" class="form-select status-dropdown" :class="getStatusSelectClass(updateForm.status)">
                                        <option v-for="option in filteredStatusOptions" :key="option.value" :value="option.value">
                                            {{ option.text }}
                                        </option>
                                    </select>
                                </div>
                            </b-form-group>
                        </div>
                        <div class="col-md-8">
                            <b-form-group>
                                <template #label>
                                    Admin Remarks <span class="text-danger">*</span>
                                </template>
                                <b-form-textarea v-model="updateForm.admin_remarks" rows="3" placeholder="Enter admin remarks..." required></b-form-textarea>
                            </b-form-group>
                        </div>
                    </div>
                    <div class="row mt-3">
                        <div class="col-12">
                            <button class="btn btn-primary" @click="updateReport" :disabled="isUpdating">
                                <span v-if="isUpdating">
                                    <b-spinner small></b-spinner> Updating...
                                </span>
                                <span v-else>Update Report</span>
                            </button>
                            <button class="btn btn-secondary ms-2" @click="goBack">Back to Reports</button>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Back Button when status is Resolved -->
            <div class="mb-3" v-else>
                <button class="btn btn-secondary" @click="goBack">
                    <i class="fas fa-arrow-left me-2"></i>Back to Reports
                </button>
            </div>

            <!-- Status Change History Card -->
            <div class="card" v-if="report.status_change_history && report.status_change_history.length">
                <div class="card-header">
                    <h4 class="card-title mb-0">Status Change History</h4>
                </div>
                <div class="card-body">
                    <div class="timeline">
                        <div class="timeline-item" v-for="(change, index) in report.status_change_history" :key="index">
                            <div class="timeline-marker" :class="getTimelineMarkerClass(change.to_status)"></div>
                            <div class="timeline-content">
                                <div class="d-flex justify-content-between align-items-start mb-2">
                                    <div>
                                        <span :class="getStatusBadgeClass(change.to_status)" class="badge me-2">{{ change.status_name }}</span>
                                        <span v-if="change.refund_amount > 0" class="badge bg-success">
                                            Refund: <i class="fas fa-rupee-sign"></i> {{ change.refund_amount }}
                                        </span>
                                    </div>
                                    <small class="text-muted">{{ formatDate(change.changed_at) }}</small>
                                </div>
                                <p class="mb-0 customer-message">{{ change.message }}</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="card-body" v-else>
            <div class="text-center py-5">
                <i class="fa fa-exclamation-triangle fa-3x text-warning mb-3"></i>
                <p>Report not found or failed to load.</p>
                <button class="btn btn-primary" @click="goBack">Back to Reports</button>
            </div>
        </div>

        <!-- Image Modal -->
        <b-modal v-model="showImageModal" size="lg" hide-footer title="Image Preview">
            <img :src="selectedImage" class="img-fluid w-100" alt="Preview">
        </b-modal>
    </div>
</template>

<script>
import axios from "axios";

export default {
    name: 'ViewCustomerReport',
    props: {
        reportId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            report: null,
            isLoading: false,
            isUpdating: false,
            isUpdatingZenfooReturn: false,
            showImageModal: false,
            selectedImage: '',
            updateForm: {
                status: 0,
                admin_remarks: ''
            },
            statusOptions: [
                { value: 0, text: 'Pending' },
                { value: 4, text: 'Driver Assigned' },
                { value: 3, text: 'Rejected' }
            ],
            zenfooReturnFields: [
                { key: 'product_name', label: 'Product', sortable: false },
                { key: 'variant_measurement', label: 'Variant', sortable: false },
                { key: 'quantity', label: 'Qty', sortable: false, class: 'text-center' },
                { key: 'price', label: 'Price', sortable: false, class: 'text-end' },
                { key: 'sub_total', label: 'Total', sortable: false, class: 'text-end' }
            ],
            itemFields: [
                { key: 'product_name', label: 'Product', sortable: false },
                { key: 'variant_measurement', label: 'Variant', sortable: false },
                { key: 'quantity', label: 'Qty', sortable: false, class: 'text-center' },
                { key: 'price', label: 'Price', sortable: false, class: 'text-end' },
                { key: 'sub_total', label: 'Total', sortable: false, class: 'text-end' }
            ],
            comboProductFields: [
                { key: 'product_name', label: 'Product', sortable: false },
                { key: 'variant_measurement', label: 'Variant', sortable: false },
                { key: 'quantity', label: 'Qty', sortable: false, class: 'text-center' },
                { key: 'price', label: 'Price', sortable: false, class: 'text-end' },
                { key: 'sub_total', label: 'Total', sortable: false, class: 'text-end' },
                { key: 'packer_name', label: 'Packed by', sortable: false, class: 'text-center' }
            ]
        }
    },
    computed: {
        hasDeliveryImages() {
            if (!this.report || !this.report.order_details) return false;
            const pickupImages = this.report.order_details.driver_pickup_images || [];
            const deliveryImages = this.report.order_details.delivery_before_images || [];
            return pickupImages.length > 0 || deliveryImages.length > 0;
        },
        zenfooReturnRecord() {
            if (!this.report || !this.report.return_records) return null;
            return this.report.return_records.find(record => record.is_zenfoo_store === 1);
        },
        hasZenfooReturn() {
            return this.zenfooReturnRecord !== null && this.zenfooReturnRecord !== undefined;
        },
        zenfooReturnProducts() {
            if (!this.zenfooReturnRecord || !this.zenfooReturnRecord.products_json) return [];
            const products = this.zenfooReturnRecord.products_json;
            return typeof products === 'string' ? JSON.parse(products) : products;
        },
        hasDriverAssignedInHistory() {
            if (!this.report || !this.report.status_change_history) return false;
            // Check if status 4 (Driver Assigned) exists in status_change_history
            return this.report.status_change_history.some(change => change.to_status === 4);
        },
        filteredStatusOptions() {
            // If driver was assigned before, don't show Resolved option
            if (this.hasDriverAssignedInHistory) {
                return this.statusOptions;
            }
            // If driver was never assigned, show Resolved option as well
            return [
                { value: 0, text: 'Pending' },
                { value: 4, text: 'Driver Assigned' },
                { value: 2, text: 'Resolved' },
                { value: 3, text: 'Rejected' }
            ];
        }
    },
    created() {
        this.fetchReport();
    },
    methods: {
        fetchReport() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/customer_issue_reports/show', {
                params: { id: this.reportId }
            })
            .then((response) => {
                if (response.data.status === 1) {
                    this.report = response.data.data;
                    this.updateForm.status = this.report.status;
                    this.updateForm.admin_remarks = this.report.admin_remarks || '';
                } else {
                    this.showError(response.data.message || 'Failed to fetch report');
                }
                this.isLoading = false;
            })
            .catch((error) => {
                console.error('Error fetching report:', error);
                this.showError('Failed to fetch report details');
                this.isLoading = false;
            });
        },
        updateReport() {
            if (!this.updateForm.admin_remarks || this.updateForm.admin_remarks.trim() === '') {
                this.showError('Admin remarks is required when updating the report.');
                return;
            }

            this.isUpdating = true;
            axios.post(this.$apiUrl + '/customer_issue_reports/update', {
                id: this.reportId,
                status: this.updateForm.status,
                admin_remarks: this.updateForm.admin_remarks
            })
            .then((response) => {
                if (response.data.status === 1) {
                    this.showSuccess('Report updated successfully');
                    this.fetchReport();
                } else {
                    this.showError(response.data.message || 'Failed to update report');
                }
                this.isUpdating = false;
            })
            .catch((error) => {
                console.error('Error updating report:', error);
                this.showError('Failed to update report');
                this.isUpdating = false;
            });
        },
        confirmZenfooReturn() {
            if (!this.zenfooReturnRecord) {
                this.showError('Zenfoo return record not found');
                return;
            }

            if (!confirm('Are you sure the return items have been received at Zenfoo store? This action cannot be undone.')) {
                return;
            }

            this.isUpdatingZenfooReturn = true;
            axios.post(this.$apiUrl + '/customer_issue_reports/update_zenfoo_return', {
                return_id: this.zenfooReturnRecord.id
            })
            .then((response) => {
                if (response.data.status === 1) {
                    this.showSuccess(response.data.message || 'Zenfoo store return confirmed successfully');
                    this.fetchReport();
                } else {
                    this.showError(response.data.message || 'Failed to confirm Zenfoo return');
                }
                this.isUpdatingZenfooReturn = false;
            })
            .catch((error) => {
                console.error('Error confirming Zenfoo return:', error);
                this.showError('Failed to confirm Zenfoo return');
                this.isUpdatingZenfooReturn = false;
            });
        },
        goBack() {
            this.$emit('back');
        },
        openImageModal(imageUrl) {
            this.selectedImage = imageUrl;
            this.showImageModal = true;
        },
        formatDate(dateString) {
            if (!dateString) return '';
            const date = new Date(dateString);
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
        },
        getStatusBadgeClass(status) {
            const classes = {
                0: 'bg-warning',
                1: 'bg-info',
                2: 'bg-success',
                3: 'bg-danger',
                4: 'bg-purple',
                5: 'bg-orange',
                6: 'bg-teal'
            };
            return classes[status] || 'bg-secondary';
        },
        getReportTypeBadgeClass(type) {
            if (type === 'missing') return 'bg-primary';
            if (type === 'return') return 'bg-info';
            return 'bg-warning';
        },
        getStoreTypeBadgeClass(type) {
            const classes = {
                'zenfoo': 'bg-success',
                'vendor': 'bg-info',
                'combo': 'bg-warning'
            };
            return classes[type] || 'bg-secondary';
        },
        getPackingStatusBadgeClass(status) {
            const classes = {
                'assigned_to_seller': 'badge bg-info',
                'preparing': 'badge bg-warning',
                'ready_for_pickup': 'badge bg-success',
                'picked_up': 'badge bg-primary',
                'delivered': 'badge bg-success'
            };
            return classes[status] || 'badge bg-secondary';
        },
        formatPackingStatus(status) {
            const labels = {
                'assigned_to_seller': 'Assigned',
                'preparing': 'Preparing',
                'ready_for_pickup': 'Ready',
                'picked_up': 'Picked Up',
                'delivered': 'Delivered'
            };
            return labels[status] || status;
        },
        getStatusSelectClass(status) {
            const classes = {
                0: 'status-pending',
                1: 'status-in-progress',
                2: 'status-resolved',
                3: 'status-rejected',
                4: 'status-driver-assigned',
                5: 'status-driver-took',
                6: 'status-driver-returned'
            };
            return classes[status] || '';
        },
        getTimelineMarkerClass(status) {
            const classes = {
                0: 'marker-pending',
                1: 'marker-in-progress',
                2: 'marker-resolved',
                3: 'marker-rejected',
                4: 'marker-driver-assigned',
                5: 'marker-driver-took',
                6: 'marker-driver-returned'
            };
            return classes[status] || '';
        },
        showError(message) {
            if (this.$toast) {
                this.$toast.error(message);
            } else {
                console.error(message);
            }
        },
        showSuccess(message) {
            if (this.$toast) {
                this.$toast.success(message);
            } else {
                console.log(message);
            }
        }
    }
}
</script>

<style scoped>
.img-thumbnail {
    cursor: pointer;
    transition: transform 0.2s;
}
.img-thumbnail:hover {
    transform: scale(1.05);
}
.gap-2 {
    gap: 0.5rem;
}

/* Store item card styling */
.store-item-card {
    padding: 1rem;
    border: 1px solid var(--bs-border-color, #dee2e6);
    border-radius: 0.5rem;
    background-color: var(--bs-body-bg, #fff);
}

.seller-info {
    min-width: 150px;
}

/* Dark mode text visibility fixes */
.card-body p.fw-bold,
.card-body p,
.card-body .row > div > p:not(.text-muted) {
    color: var(--bs-body-color, inherit);
}

.card-body small:not(.text-muted) {
    color: var(--bs-body-color, inherit);
}

/* Ensure table text is visible in dark mode */
:deep(.table) {
    color: var(--bs-body-color, inherit);
}

:deep(.table td),
:deep(.table th) {
    color: var(--bs-body-color, inherit);
}

/* Form labels in dark mode */
:deep(.form-label),
:deep(label) {
    color: var(--bs-body-color, inherit);
}

/* Form inputs in dark mode */
:deep(.form-control),
:deep(.form-select) {
    background-color: var(--bs-body-bg, #fff);
    color: var(--bs-body-color, inherit);
    border-color: var(--bs-border-color, #ced4da);
}

/* Card title visibility */
.card-title {
    color: var(--bs-body-color, inherit);
}

/* Page heading visibility */
h3, h4, h6 {
    color: var(--bs-body-color, inherit);
}

/* Status dropdown styling */
.status-select-wrapper {
    position: relative;
}

.status-dropdown {
    padding: 0.625rem 2.25rem 0.625rem 1rem;
    font-size: 0.95rem;
    font-weight: 500;
    border-radius: 0.5rem;
    border: 2px solid;
    transition: all 0.2s ease-in-out;
    cursor: pointer;
    appearance: none;
    background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3e%3cpath fill='none' stroke='%23343a40' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M2 5l6 6 6-6'/%3e%3c/svg%3e");
    background-repeat: no-repeat;
    background-position: right 0.75rem center;
    background-size: 16px 12px;
}

.status-dropdown:focus {
    box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
    outline: none;
}

.status-dropdown.status-pending {
    background-color: #fff3cd;
    border-color: #ffc107;
    color: #856404;
}

.status-dropdown.status-in-progress {
    background-color: #cce5ff;
    border-color: #17a2b8;
    color: #0c5460;
}

.status-dropdown.status-resolved {
    background-color: #d4edda;
    border-color: #28a745;
    color: #155724;
}

.status-dropdown.status-rejected {
    background-color: #f8d7da;
    border-color: #dc3545;
    color: #721c24;
}

.status-dropdown.status-driver-assigned {
    background-color: #e2d5f1;
    border-color: #6f42c1;
    color: #4a2c7a;
}

.status-dropdown.status-driver-took {
    background-color: #ffe5d0;
    border-color: #fd7e14;
    color: #8a4500;
}

.status-dropdown.status-driver-returned {
    background-color: #d1ecf1;
    border-color: #20c997;
    color: #0c5460;
}

/* Badge colors for new statuses */
.bg-purple {
    background-color: #6f42c1 !important;
}

.bg-orange {
    background-color: #fd7e14 !important;
}

.bg-teal {
    background-color: #20c997 !important;
}

/* Dark mode adjustments for status dropdown */
@media (prefers-color-scheme: dark) {
    .status-dropdown.status-pending {
        background-color: rgba(255, 193, 7, 0.2);
        color: #ffc107;
    }

    .status-dropdown.status-in-progress {
        background-color: rgba(23, 162, 184, 0.2);
        color: #17a2b8;
    }

    .status-dropdown.status-resolved {
        background-color: rgba(40, 167, 69, 0.2);
        color: #28a745;
    }

    .status-dropdown.status-rejected {
        background-color: rgba(220, 53, 69, 0.2);
        color: #dc3545;
    }

    .status-dropdown.status-driver-assigned {
        background-color: rgba(111, 66, 193, 0.2);
        color: #a78bda;
    }

    .status-dropdown.status-driver-took {
        background-color: rgba(253, 126, 20, 0.2);
        color: #fd7e14;
    }

    .status-dropdown.status-driver-returned {
        background-color: rgba(32, 201, 151, 0.2);
        color: #20c997;
    }
}

/* Timeline styles */
.timeline {
    position: relative;
    padding-left: 30px;
}

.timeline::before {
    content: '';
    position: absolute;
    left: 10px;
    top: 0;
    bottom: 0;
    width: 2px;
    background-color: var(--bs-border-color, #dee2e6);
}

.timeline-item {
    position: relative;
    padding-bottom: 1.5rem;
}

.timeline-item:last-child {
    padding-bottom: 0;
}

.timeline-marker {
    position: absolute;
    left: -24px;
    top: 0;
    width: 14px;
    height: 14px;
    border-radius: 50%;
    border: 2px solid #fff;
    box-shadow: 0 0 0 2px var(--bs-border-color, #dee2e6);
}

.timeline-marker.marker-pending {
    background-color: #ffc107;
    box-shadow: 0 0 0 2px #ffc107;
}

.timeline-marker.marker-in-progress {
    background-color: #17a2b8;
    box-shadow: 0 0 0 2px #17a2b8;
}

.timeline-marker.marker-resolved {
    background-color: #28a745;
    box-shadow: 0 0 0 2px #28a745;
}

.timeline-marker.marker-rejected {
    background-color: #dc3545;
    box-shadow: 0 0 0 2px #dc3545;
}

.timeline-marker.marker-driver-assigned {
    background-color: #6f42c1;
    box-shadow: 0 0 0 2px #6f42c1;
}

.timeline-marker.marker-driver-took {
    background-color: #fd7e14;
    box-shadow: 0 0 0 2px #fd7e14;
}

.timeline-marker.marker-driver-returned {
    background-color: #20c997;
    box-shadow: 0 0 0 2px #20c997;
}

.timeline-content {
    background-color: var(--bs-body-bg, #fff);
    border: 1px solid var(--bs-border-color, #dee2e6);
    border-radius: 0.5rem;
    padding: 1rem;
}

.customer-message {
    color: var(--bs-body-color, inherit);
    font-size: 0.95rem;
}
</style>
