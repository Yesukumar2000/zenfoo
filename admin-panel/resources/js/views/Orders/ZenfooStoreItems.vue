<template>
    <div class="zenfoo-store-items">
        <div v-if="isLoading" class="text-center py-5">
            <b-spinner label="Loading..."></b-spinner>
            <p class="mt-2">Loading Zenfoo store data...</p>
        </div>

        <div v-else-if="!hasData" class="text-center py-5">
            <i class="fas fa-box-open fa-3x text-muted mb-3"></i>
            <p class="text-muted">No Zenfoo store data found for this order.</p>
        </div>

        <div v-else>
            <!-- Customer Delivery Instructions -->
            <div class="alert alert-info d-flex align-items-start mb-4" v-if="deliveryInstructions">
                <i class="fas fa-comment-dots me-2 mt-1"></i>
                <div>
                    <strong>Customer Instructions:</strong>
                    <div>{{ deliveryInstructions }}</div>
                </div>
            </div>

            <!-- Tracking Status Card -->
            <div class="card mb-4" v-if="trackingData.length > 0">
                <div class="card-header">
                    <div class="d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">
                            <i class="fas fa-truck me-2"></i>
                            Order Tracking Status
                        </h5>
                    </div>
                </div>

                <div class="card-body pt-4">
                    <div v-for="tracking in trackingData" :key="tracking.id" class="mb-3">
                        <!-- Flex layout for tracking info -->
                        <div class="d-flex flex-wrap align-items-center gap-4">
                            <!-- Status -->
                            <div class="d-flex align-items-center gap-2">
                                <strong>Status:</strong>
                                <span class="badge bg-info">{{ tracking.status_label }}</span>
                                <span v-if="tracking.prep_time" class="text-success">
                                    <i class="fas fa-utensils me-1"></i>Order preparing
                                </span>
                                <span v-else class="text-warning">
                                    <i class="fas fa-clock me-1"></i>Give preparation time
                                </span>
                            </div>

                            <!-- Seller Info -->
                            <div class="d-flex align-items-center gap-2" v-if="tracking.seller_name">
                                <strong>Seller:</strong>
                                <span>{{ tracking.seller_name }}</span>
                                <small v-if="tracking.seller_mobile" class="text-muted">
                                    <i class="fas fa-phone me-1"></i>{{ tracking.seller_mobile }}
                                </small>
                            </div>

                            <!-- Location -->
                            <div class="d-flex align-items-center gap-2" v-if="tracking.location_name">
                                <strong>Location:</strong>
                                <span>{{ tracking.location_name }}</span>
                            </div>

                            <!-- Driver Picked -->
                            <div class="d-flex align-items-center gap-2">
                                <strong>Driver Picked:</strong>
                                <span :class="tracking.is_driver_picked ? 'text-success' : 'text-muted'">
                                    {{ tracking.is_driver_picked ? 'Yes' : 'No' }}
                                </span>
                            </div>

                            <!-- OTP - Commented out -->
                            <!-- <div class="d-flex align-items-center gap-2" v-if="tracking.otp">
                                <strong>OTP:</strong>
                                <span class="badge bg-warning text-dark">{{ tracking.otp }}</span>
                            </div> -->
                        </div>

                        <!-- Prep Time Section - Only show when status is assigned_to_seller -->
                        <div class="row mt-3" v-if="tracking.status === 'assigned_to_seller'">
                            <div class="col-12">
                                <div class="d-flex align-items-center gap-3">
                                    <strong>Preparation Time:</strong>

                                    <!-- Show current prep time if exists -->
                                    <span v-if="tracking.prep_time" class="badge bg-success">
                                        {{ tracking.prep_time[0] }} min (Set at {{ tracking.prep_time[1] }})
                                    </span>
                                    <span v-else class="text-muted">Not set</span>

                                    <!-- Prep time selector -->
                                    <select
                                        v-model="selectedPrepTime[tracking.id]"
                                        class="form-select form-select-sm"
                                        style="width: 120px;">
                                        <option value="">Select</option>
                                        <option value="10">10 min</option>
                                        <option value="15">15 min</option>
                                        <option value="20">20 min</option>
                                        <option value="25">25 min</option>
                                        <option value="30">30 min</option>
                                        <option value="45">45 min</option>
                                        <option value="60">60 min</option>
                                    </select>

                                    <!-- Update button -->
                                    <button
                                        class="btn btn-primary btn-sm"
                                        @click="updatePrepTime(tracking)"
                                        :disabled="!selectedPrepTime[tracking.id] || isUpdatingPrepTime[tracking.id]">
                                        <span v-if="isUpdatingPrepTime[tracking.id]">
                                            <b-spinner small></b-spinner> Updating...
                                        </span>
                                        <span v-else>
                                            <i class="fas fa-clock me-1"></i>
                                            {{ tracking.prep_time ? 'Update' : 'Set' }} Time
                                        </span>
                                    </button>
                                </div>
                            </div>
                        </div>

                        <!-- Delayed Time -->
                        <div class="row mt-2" v-if="tracking.delayed_time_in_min">
                            <div class="col-12">
                                <small class="text-danger">
                                    <i class="fas fa-exclamation-triangle me-1"></i>
                                    <strong>Delayed:</strong> {{ tracking.delayed_time_in_min }} minutes
                                </small>
                            </div>
                        </div>

                        <!-- Packed by Seller Section - Only show when prep_time exists -->
                        <div class="row mt-3" v-if="tracking.prep_time && tracking.status !== 'packed_by_seller' && tracking.status !== 'given_to_delivery_partner'">
                            <div class="col-12">
                                <div class="packed-section p-3 border rounded bg-light">
                                    <div class="d-flex align-items-center justify-content-between">
                                        <div>
                                            <i class="fas fa-box me-2 text-primary"></i>
                                            <span>If preparation is complete, mark the order as packed</span>
                                        </div>
                                        <button
                                            class="btn btn-success btn-sm"
                                            @click="markAsPacked(tracking)"
                                            :disabled="isMarkingPacked[tracking.id]">
                                            <span v-if="isMarkingPacked[tracking.id]">
                                                <b-spinner small></b-spinner> Processing...
                                            </span>
                                            <span v-else>
                                                <i class="fas fa-check-circle me-1"></i>
                                                Order Packed
                                            </span>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Already Packed Status with OTP Verification -->
                        <div class="row mt-3" v-if="tracking.status === 'packed_by_seller'">
                            <div class="col-12">
                                <div class="packed-section p-3 border rounded bg-success bg-opacity-10 mb-3">
                                    <div class="d-flex align-items-center">
                                        <i class="fas fa-check-circle me-2 text-success"></i>
                                        <span class="text-success"><strong>Order has been packed</strong></span>
                                    </div>
                                </div>

                                <!-- OTP Verification Section -->
                                <div class="otp-section p-3 border rounded bg-light">
                                    <div class="d-flex flex-column gap-3">
                                        <div class="d-flex align-items-center">
                                            <i class="fas fa-key me-2 text-warning"></i>
                                            <span><strong>Verify Delivery Driver</strong></span>
                                        </div>
                                        <p class="text-muted mb-2">
                                            <i class="fas fa-info-circle me-1"></i>
                                            Delivery boy will tell the OTP. Enter the 4-digit OTP to verify and hand over the order.
                                        </p>
                                        <div class="d-flex align-items-center gap-3">
                                            <div class="otp-input-group d-flex gap-2">
                                                <input
                                                    type="text"
                                                    class="form-control otp-input text-center"
                                                    v-model="otpDigits[tracking.id][0]"
                                                    maxlength="1"
                                                    @input="handleOtpInput(tracking.id, 0, $event)"
                                                    @keydown="handleOtpKeydown(tracking.id, 0, $event)"
                                                    :ref="'otp-' + tracking.id + '-0'"
                                                    placeholder="-"
                                                >
                                                <input
                                                    type="text"
                                                    class="form-control otp-input text-center"
                                                    v-model="otpDigits[tracking.id][1]"
                                                    maxlength="1"
                                                    @input="handleOtpInput(tracking.id, 1, $event)"
                                                    @keydown="handleOtpKeydown(tracking.id, 1, $event)"
                                                    :ref="'otp-' + tracking.id + '-1'"
                                                    placeholder="-"
                                                >
                                                <input
                                                    type="text"
                                                    class="form-control otp-input text-center"
                                                    v-model="otpDigits[tracking.id][2]"
                                                    maxlength="1"
                                                    @input="handleOtpInput(tracking.id, 2, $event)"
                                                    @keydown="handleOtpKeydown(tracking.id, 2, $event)"
                                                    :ref="'otp-' + tracking.id + '-2'"
                                                    placeholder="-"
                                                >
                                                <input
                                                    type="text"
                                                    class="form-control otp-input text-center"
                                                    v-model="otpDigits[tracking.id][3]"
                                                    maxlength="1"
                                                    @input="handleOtpInput(tracking.id, 3, $event)"
                                                    @keydown="handleOtpKeydown(tracking.id, 3, $event)"
                                                    :ref="'otp-' + tracking.id + '-3'"
                                                    placeholder="-"
                                                >
                                            </div>
                                            <button
                                                class="btn btn-primary btn-sm"
                                                @click="verifyOtp(tracking)"
                                                :disabled="!isOtpComplete(tracking.id) || isVerifyingOtp[tracking.id]">
                                                <span v-if="isVerifyingOtp[tracking.id]">
                                                    <b-spinner small></b-spinner> Verifying...
                                                </span>
                                                <span v-else>
                                                    <i class="fas fa-shield-alt me-1"></i>
                                                    Verify & Handover
                                                </span>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Given to Delivery Partner Status -->
                        <div class="row mt-3" v-if="tracking.status === 'given_to_delivery_partner'">
                            <div class="col-12">
                                <div class="packed-section p-3 border rounded bg-primary bg-opacity-10">
                                    <div class="d-flex align-items-center">
                                        <i class="fas fa-truck me-2 text-primary"></i>
                                        <span class="text-primary"><strong>Order handed over to delivery partner</strong></span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Driver Captured Images -->
                        <div class="row mt-2" v-if="tracking.driver_captured_images && tracking.driver_captured_images.length > 0">
                            <div class="col-12">
                                <p class="mb-1"><strong>Pickup Images:</strong></p>
                                <div class="d-flex flex-wrap gap-2">
                                    <img v-for="(img, idx) in tracking.driver_captured_images"
                                         :key="idx"
                                         :src="img"
                                         class="img-thumbnail"
                                         style="width: 80px; height: 80px; object-fit: cover; cursor: pointer;"
                                         @click="openImageModal(img)"
                                         alt="Pickup Image">
                                </div>
                            </div>
                        </div>

                        <!-- Timestamps - Commented out -->
                        <!-- <div class="row mt-2">
                            <div class="col-6">
                                <small class="text-muted">
                                    <i class="fas fa-calendar me-1"></i>
                                    Created: {{ formatDateTime(tracking.created_at) }}
                                </small>
                            </div>
                            <div class="col-6">
                                <small class="text-muted">
                                    <i class="fas fa-clock me-1"></i>
                                    Updated: {{ formatDateTime(tracking.updated_at) }}
                                </small>
                            </div>
                        </div> -->

                        <hr v-if="trackingData.length > 1" class="my-3">
                    </div>
                </div>
            </div>

            <!-- Order Items Table -->
            <div class="card">
                <div class="card-header">
                    <div class="d-flex justify-content-between align-items-center">
                        <h5 class="mb-0">
                            <i class="fas fa-shopping-basket me-2"></i>
                            Zenfoo Store Items
                        </h5>
                        <span class="badge bg-success">
                            {{ summary.total_items }} item(s) | <i class="fas fa-rupee-sign"></i> {{ summary.total_amount }}
                        </span>
                    </div>
                </div>

                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-bordered table-hover mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th width="50">#</th>
                                    <th>Product</th>
                                    <th width="120">Variant</th>
                                    <th width="80" class="text-center">Qty</th>
                                    <th width="100" class="text-end">Price</th>
                                    <th width="100" class="text-end">Discounted</th>
                                    <!-- <th width="100" class="text-end">Tax</th> -->
                                    <th width="120" class="text-end">Subtotal</th>
                                    <!-- <th width="100" class="text-center">Actions</th> -->
                                </tr>
                            </thead>
                            <tbody>
                                <tr v-for="(item, index) in orderItems" :key="item.id">
                                    <td>{{ index + 1 }}</td>
                                    <td>
                                        <div class="d-flex align-items-center">
                                            <img v-if="item.product_image"
                                                 :src="item.product_image"
                                                 class="me-2"
                                                 style="width: 40px; height: 40px; object-fit: cover; border-radius: 4px;"
                                                 alt="Product">
                                            <div>
                                                <strong>{{ item.product_name }}</strong>
                                                <br>
                                                <small class="text-muted">ID: #{{ item.product_id }}</small>
                                            </div>
                                        </div>
                                    </td>
                                    <td>
                                        {{ item.variant_measurement || '-' }}
                                        <span v-if="item.variant_unit_id">
                                            {{ getUnitLabel(item.variant_unit_id) }}
                                        </span>
                                    </td>
                                    <td class="text-center">
                                        <span class="badge bg-primary">{{ item.quantity }}</span>
                                    </td>
                                    <td class="text-end">
                                        <i class="fas fa-rupee-sign"></i> {{ item.price }}
                                    </td>
                                    <td class="text-end">
                                        <span v-if="item.discounted_price && item.discounted_price != item.price">
                                            <i class="fas fa-rupee-sign"></i> {{ item.discounted_price }}
                                        </span>
                                        <span v-else class="text-muted">-</span>
                                    </td>
                                    <!-- <td class="text-end">
                                        <span v-if="item.tax_amount > 0">
                                            <i class="fas fa-rupee-sign"></i> {{ item.tax_amount }}
                                            <br>
                                            <small class="text-muted">({{ item.tax_percentage }}%)</small>
                                        </span>
                                        <span v-else class="text-muted">-</span>
                                    </td> -->
                                    <td class="text-end">
                                        <strong>
                                            <i class="fas fa-rupee-sign"></i> {{ item.sub_total }}
                                        </strong>
                                    </td>
                                    <!-- <td class="text-center">
                                        <router-link
                                            :to="getProductRoute(item.product_id)"
                                            class="btn btn-secondary btn-sm"
                                            v-b-tooltip.hover
                                            title="View Product">
                                            <i class="fas fa-eye"></i>
                                        </router-link>
                                    </td> -->
                                </tr>
                            </tbody>
                            <tfoot class="table-light">
                                <tr>
                                    <td colspan="6" class="text-end"><strong>Total:</strong></td>
                                    <td class="text-end">
                                        <strong>
                                            <i class="fas fa-rupee-sign"></i> {{ summary.total_amount }}
                                        </strong>
                                    </td>
                                    <!-- <td></td> -->
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <!-- Image Modal -->
        <b-modal v-model="showImageModal" title="Pickup Image" size="lg" hide-footer centered>
            <div class="text-center">
                <img :src="selectedImage" class="img-fluid" alt="Pickup Image">
            </div>
        </b-modal>
    </div>
</template>

<script>
import axios from "axios";
import Auth from '../../Auth.js';

export default {
    name: 'ZenfooStoreItems',
    props: {
        orderId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            login_user: Auth.user,
            isLoading: false,
            trackingData: [],
            deliveryInstructions: null,
            orderItems: [],
            summary: {
                total_items: 0,
                total_amount: 0,
                has_tracking: false
            },
            showImageModal: false,
            selectedImage: '',
            selectedPrepTime: {},
            isUpdatingPrepTime: {},
            isMarkingPacked: {},
            otpDigits: {},
            isVerifyingOtp: {}
        };
    },
    computed: {
        hasData() {
            return this.trackingData.length > 0 || this.orderItems.length > 0;
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
        }
    },
    created() {
        this.fetchZenfooStoreTracking();
    },
    methods: {
        fetchZenfooStoreTracking() {
            this.isLoading = true;

            axios.get(this.$apiUrl + '/orders/' + this.orderId + '/zenfoo-store-tracking')
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status === 1) {
                        this.trackingData = response.data.data.tracking || [];
                        this.deliveryInstructions = response.data.data.delivery_instructions || null;
                        this.orderItems = response.data.data.items || [];
                        this.summary = response.data.data.summary || {
                            total_items: 0,
                            total_amount: 0,
                            has_tracking: false
                        };

                        // Initialize all tracking-related data
                        this.trackingData.forEach(tracking => {
                            this.$set(this.selectedPrepTime, tracking.id, '');
                            this.$set(this.isUpdatingPrepTime, tracking.id, false);
                            this.$set(this.isMarkingPacked, tracking.id, false);
                            this.$set(this.otpDigits, tracking.id, ['', '', '', '']);
                            this.$set(this.isVerifyingOtp, tracking.id, false);
                        });
                    } else {
                        this.showError(response.data.message || 'Failed to fetch data');
                    }
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error fetching Zenfoo store tracking:', error);
                    if (error.response && error.response.data && error.response.data.message) {
                        this.showError(error.response.data.message);
                    } else {
                        this.showError('Failed to fetch Zenfoo store tracking data');
                    }
                });
        },
        updatePrepTime(tracking) {
            const minutes = this.selectedPrepTime[tracking.id];
            if (!minutes) {
                this.showError('Please select a preparation time');
                return;
            }

            this.$set(this.isUpdatingPrepTime, tracking.id, true);

            // Get current time in format "h:mm A"
            const now = new Date();
            const timeString = now.toLocaleTimeString('en-US', {
                hour: 'numeric',
                minute: '2-digit',
                hour12: true
            });

            const prepTimeData = [parseInt(minutes), timeString];

            axios.post(this.$apiUrl + '/orders/' + this.orderId + '/zenfoo-update-prep-time', {
                order_id: this.orderId,
                tracking_id: tracking.id,
                prep_time: JSON.stringify(prepTimeData)
            })
            .then((response) => {
                this.$set(this.isUpdatingPrepTime, tracking.id, false);

                if (response.data.status === 1) {
                    // Update the tracking data locally
                    const index = this.trackingData.findIndex(t => t.id === tracking.id);
                    if (index !== -1) {
                        this.$set(this.trackingData[index], 'prep_time', prepTimeData);
                        this.$set(this.trackingData[index], 'is_seller_started_preparing', response.data.data.is_seller_started_preparing);
                        if (response.data.data.delayed_time_in_min) {
                            this.$set(this.trackingData[index], 'delayed_time_in_min', response.data.data.delayed_time_in_min);
                        }
                    }

                    // Clear the selection
                    this.$set(this.selectedPrepTime, tracking.id, '');

                    this.$swal.fire({
                        icon: 'success',
                        title: 'Success',
                        text: 'Preparation time updated successfully',
                        timer: 2000,
                        showConfirmButton: false
                    });
                } else {
                    this.showError(response.data.message || 'Failed to update prep time');
                }
            })
            .catch((error) => {
                this.$set(this.isUpdatingPrepTime, tracking.id, false);
                console.error('Error updating prep time:', error);
                if (error.response && error.response.data && error.response.data.message) {
                    this.showError(error.response.data.message);
                } else {
                    this.showError('Failed to update preparation time');
                }
            });
        },
        markAsPacked(tracking) {
            this.$set(this.isMarkingPacked, tracking.id, true);

            axios.post(this.$apiUrl + '/orders/' + this.orderId + '/zenfoo-mark-as-packed', {
                order_id: this.orderId,
                tracking_id: tracking.id
            })
            .then((response) => {
                this.$set(this.isMarkingPacked, tracking.id, false);

                if (response.data.status === 1) {
                    // Update the tracking data locally
                    const index = this.trackingData.findIndex(t => t.id === tracking.id);
                    if (index !== -1) {
                        this.$set(this.trackingData[index], 'status', 'packed_by_seller');
                        this.$set(this.trackingData[index], 'status_label', 'Packed by Seller');
                    }

                    this.$swal.fire({
                        icon: 'success',
                        title: 'Success',
                        text: 'Order marked as packed successfully',
                        timer: 2000,
                        showConfirmButton: false
                    });
                } else {
                    this.showError(response.data.message || 'Failed to mark as packed');
                }
            })
            .catch((error) => {
                this.$set(this.isMarkingPacked, tracking.id, false);
                console.error('Error marking as packed:', error);
                if (error.response && error.response.data && error.response.data.message) {
                    this.showError(error.response.data.message);
                } else {
                    this.showError('Failed to mark order as packed');
                }
            });
        },
        // OTP Methods
        handleOtpInput(trackingId, index, event) {
            const value = event.target.value;
            // Only allow digits
            if (!/^\d*$/.test(value)) {
                this.$set(this.otpDigits[trackingId], index, '');
                return;
            }
            // Move to next input if a digit was entered
            if (value && index < 3) {
                const nextRef = this.$refs['otp-' + trackingId + '-' + (index + 1)];
                if (nextRef && nextRef[0]) {
                    nextRef[0].focus();
                }
            }
        },
        handleOtpKeydown(trackingId, index, event) {
            // Handle backspace - move to previous input
            if (event.key === 'Backspace' && !this.otpDigits[trackingId][index] && index > 0) {
                const prevRef = this.$refs['otp-' + trackingId + '-' + (index - 1)];
                if (prevRef && prevRef[0]) {
                    prevRef[0].focus();
                }
            }
        },
        isOtpComplete(trackingId) {
            if (!this.otpDigits[trackingId]) return false;
            return this.otpDigits[trackingId].every(digit => digit !== '');
        },
        getOtpValue(trackingId) {
            if (!this.otpDigits[trackingId]) return '';
            return this.otpDigits[trackingId].join('');
        },
        verifyOtp(tracking) {
            if (!this.isOtpComplete(tracking.id)) {
                this.showError('Please enter the complete 4-digit OTP');
                return;
            }

            this.$set(this.isVerifyingOtp, tracking.id, true);
            const otp = this.getOtpValue(tracking.id);

            axios.post(this.$apiUrl + '/orders/' + this.orderId + '/zenfoo-verify-otp', {
                order_id: this.orderId,
                tracking_id: tracking.id,
                otp: otp
            })
            .then((response) => {
                this.$set(this.isVerifyingOtp, tracking.id, false);

                if (response.data.status === 1) {
                    // Update the tracking data locally
                    const index = this.trackingData.findIndex(t => t.id === tracking.id);
                    if (index !== -1) {
                        this.$set(this.trackingData[index], 'status', 'given_to_delivery_partner');
                        this.$set(this.trackingData[index], 'status_label', 'Given to Delivery Partner');
                    }

                    this.$swal.fire({
                        icon: 'success',
                        title: 'Success',
                        text: 'OTP verified successfully. Order handed over to delivery partner.',
                        timer: 2000,
                        showConfirmButton: false
                    });
                } else {
                    this.showError(response.data.message || 'OTP verification failed');
                    // Clear OTP inputs on failure
                    this.$set(this.otpDigits, tracking.id, ['', '', '', '']);
                }
            })
            .catch((error) => {
                this.$set(this.isVerifyingOtp, tracking.id, false);
                console.error('Error verifying OTP:', error);
                if (error.response && error.response.data && error.response.data.message) {
                    this.showError(error.response.data.message);
                } else {
                    this.showError('Failed to verify OTP');
                }
                // Clear OTP inputs on failure
                this.$set(this.otpDigits, tracking.id, ['', '', '', '']);
            });
        },
        getUnitLabel(unitId) {
            const units = {
                1: 'kg',
                2: 'g',
                3: 'L',
                4: 'ml',
                5: 'pcs'
            };
            return units[unitId] || '';
        },
        formatDateTime(dateTime) {
            if (!dateTime) return '-';
            const date = new Date(dateTime);
            return date.toLocaleString('en-IN', {
                day: '2-digit',
                month: 'short',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        },
        formatPrepTime(prepTime) {
            if (!prepTime) return '-';
            if (Array.isArray(prepTime) && prepTime.length >= 2) {
                return `${prepTime[0]} min (Set at ${prepTime[1]})`;
            }
            if (typeof prepTime === 'object') {
                return JSON.stringify(prepTime);
            }
            return prepTime;
        },
        openImageModal(imageUrl) {
            this.selectedImage = imageUrl;
            this.showImageModal = true;
        },
        showError(message) {
            this.$swal.fire({
                icon: 'error',
                title: 'Error',
                text: message
            });
        }
    }
};
</script>

<style scoped>
.zenfoo-store-items {
    padding: 15px 0;
}

.table th {
    background-color: #f8f9fa;
    font-weight: 600;
    font-size: 0.85rem;
}

.table td {
    vertical-align: middle;
    font-size: 0.9rem;
}

.badge {
    font-size: 0.8rem;
}

.btn-sm {
    padding: 0.25rem 0.5rem;
    font-size: 0.75rem;
}

.img-thumbnail:hover {
    transform: scale(1.05);
    transition: transform 0.2s ease;
}

.gap-2 {
    gap: 0.5rem;
}

.gap-3 {
    gap: 1rem;
}

.gap-4 {
    gap: 1.5rem;
}

.form-select-sm {
    padding: 0.25rem 0.5rem;
    font-size: 0.875rem;
}

/* OTP Input Styles */
.otp-input {
    width: 36px !important;
    height: 36px !important;
    min-width: 36px !important;
    max-width: 36px !important;
    padding: 0 !important;
    font-size: 1rem;
    font-weight: 600;
    border: 2px solid #dee2e6;
    border-radius: 6px;
    flex: 0 0 auto;
}

.otp-input:focus {
    border-color: #0d6efd;
    box-shadow: 0 0 0 0.15rem rgba(13, 110, 253, 0.25);
}

.otp-input-group {
    width: auto !important;
    flex: 0 0 auto;
}

.otp-section {
    background-color: #f8f9fa;
}
</style>

<!-- Non-scoped styles for dark mode support -->
<style>
/* Dark theme support for Zenfoo Store Items */
.theme-dark .zenfoo-store-items .table th {
    background-color: #2d2d2d;
    color: #e0e0e0;
}

.theme-dark .zenfoo-store-items .table td {
    background-color: #1e1e1e;
    color: #e0e0e0;
}

.theme-dark .zenfoo-store-items .table-light {
    background-color: #2d2d2d !important;
    color: #e0e0e0;
}

.theme-dark .zenfoo-store-items .bg-light {
    background-color: #2d2d2d !important;
    color: #e0e0e0;
}

.theme-dark .zenfoo-store-items .packed-section {
    background-color: #2d2d2d !important;
    border-color: #444 !important;
}

.theme-dark .zenfoo-store-items .packed-section span {
    color: #e0e0e0;
}

.theme-dark .zenfoo-store-items .card {
    background-color: #1e1e1e;
    border-color: #333;
}

.theme-dark .zenfoo-store-items .card-header {
    background-color: #2d2d2d;
    border-color: #333;
    color: #e0e0e0;
}

.theme-dark .zenfoo-store-items .card-body {
    background-color: #1e1e1e;
    color: #e0e0e0;
}

.theme-dark .zenfoo-store-items .border {
    border-color: #444 !important;
}

.theme-dark .zenfoo-store-items .text-muted {
    color: #999 !important;
}

.theme-dark .zenfoo-store-items .bg-success.bg-opacity-10 {
    background-color: rgba(25, 135, 84, 0.2) !important;
}

.theme-dark .zenfoo-store-items .bg-primary.bg-opacity-10 {
    background-color: rgba(13, 110, 253, 0.2) !important;
}

.theme-dark .zenfoo-store-items .otp-section {
    background-color: #2d2d2d !important;
    border-color: #444 !important;
}

.theme-dark .zenfoo-store-items .otp-input {
    background-color: #1e1e1e;
    border-color: #444;
    color: #e0e0e0;
}

.theme-dark .zenfoo-store-items .otp-input:focus {
    border-color: #0d6efd;
    background-color: #1e1e1e;
}
</style>
