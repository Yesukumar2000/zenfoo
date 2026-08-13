<template>
    <div class="support-management">
        <!-- Loading State -->
        <div v-if="isLoading" class="text-center py-5">
            <b-spinner variant="primary" label="Loading..."></b-spinner>
            <p class="mt-2 text-muted">Loading support info...</p>
        </div>

        <div v-else>
            <!-- Main Tabs Navigation -->
            <div class="row mb-3">
                <div class="col-12">
                    <ul class="nav nav-pills">
                        <li class="nav-item">
                            <a class="nav-link" :class="{ active: activeTab === 'customer' }" href="#" @click.prevent="activeTab = 'customer'">
                                <i class="fas fa-user me-2"></i>Customer
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" :class="{ active: activeTab === 'seller', disabled: !hasSellers }" href="#" @click.prevent="hasSellers && (activeTab = 'seller')">
                                <i class="fas fa-store me-2"></i>Seller
                                <span v-if="!hasSellers" class="badge bg-secondary ms-1">N/A</span>
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" :class="{ active: activeTab === 'driver', disabled: !hasDriver }" href="#" @click.prevent="hasDriver && (activeTab = 'driver')">
                                <i class="fas fa-motorcycle me-2"></i>Driver
                                <span v-if="!hasDriver" class="badge bg-secondary ms-1">N/A</span>
                            </a>
                        </li>
                    </ul>
                </div>
            </div>

            <!-- Tab Content -->
            <div class="row">
                <div class="col-12">
                    <!-- Customer Chat -->
                    <CustomerChat v-if="activeTab === 'customer'" :orderId="orderId" />

                    <!-- Seller Chat -->
                    <div v-if="activeTab === 'seller'">
                        <div v-if="hasSellers">
                            <SellerChat :orderId="orderId" :initialSellerId="initialSellerId" />
                        </div>
                        <div v-else class="not-assigned-card">
                            <div class="not-assigned-icon">
                                <i class="fas fa-store"></i>
                            </div>
                            <h5 class="mt-3">No Sellers Assigned</h5>
                            <p class="text-muted">No sellers are associated with this order yet.</p>
                        </div>
                    </div>

                    <!-- Driver Chat -->
                    <div v-if="activeTab === 'driver'">
                        <div v-if="hasDriver">
                            <DriverChat :orderId="orderId" />
                        </div>
                        <div v-else class="not-assigned-card">
                            <div class="not-assigned-icon">
                                <i class="fas fa-motorcycle"></i>
                            </div>
                            <h5 class="mt-3">Driver Not Assigned</h5>
                            <p class="text-muted">No delivery partner has been assigned to this order yet.</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import axios from "axios";
import CustomerChat from './CustomerChat.vue';
import SellerChat from './SellerChat.vue';
import DriverChat from './DriverChat.vue';

export default {
    name: 'SupportManagement',
    components: {
        CustomerChat,
        SellerChat,
        DriverChat
    },
    props: {
        orderId: {
            type: [String, Number],
            required: true
        },
        initialChatType: {
            type: String,
            default: null
        },
        initialSellerId: {
            type: [String, Number],
            default: null
        }
    },
    data() {
        return {
            isLoading: false,
            activeTab: 'customer',
            hasDriver: false,
            hasSellers: false
        };
    },
    watch: {
        orderId: {
            immediate: true,
            handler() {
                this.fetchOrderInfo();
            }
        }
    },
    created() {
        // Set initial tab based on chat type from notification
        if (this.initialChatType) {
            if (this.initialChatType === 'customer') {
                this.activeTab = 'customer';
            } else if (this.initialChatType === 'driver') {
                this.activeTab = 'driver';
            } else if (this.initialChatType === 'seller') {
                this.activeTab = 'seller';
            }
        }
    },
    methods: {
        fetchOrderInfo() {
            this.isLoading = true;

            // Fetch order details and sellers in parallel
            Promise.all([
                axios.get(this.$apiUrl + '/orders/view/' + this.orderId),
                axios.get(this.$apiUrl + '/order-chat/order-sellers', { params: { order_id: this.orderId } })
            ]).then(([orderResponse, sellersResponse]) => {
                this.isLoading = false;

                // Check if driver is assigned
                if (orderResponse.data.status === 1 && orderResponse.data.data.order) {
                    this.hasDriver = !!orderResponse.data.data.order.delivery_boy_id;
                }

                // Check if sellers exist
                if (sellersResponse.data.status === 1) {
                    this.hasSellers = (sellersResponse.data.data || []).length > 0;
                }

                // If initial tab is set but not available, fallback to customer
                if (this.initialChatType === 'driver' && !this.hasDriver) {
                    this.activeTab = 'customer';
                } else if (this.initialChatType === 'seller' && !this.hasSellers) {
                    this.activeTab = 'customer';
                }
            }).catch((error) => {
                this.isLoading = false;
                console.error('Error fetching order info:', error);
            });
        }
    }
};
</script>

<style>
.support-management .nav-pills .nav-link {
    color: #435971;
    border: 1px solid #dee2e6;
    margin-right: 5px;
}

.support-management .nav-pills .nav-link.active {
    background-color: #9AC444;
    border-color: #9AC444;
    color: #fff;
}

.support-management .nav-pills .nav-link:hover:not(.active):not(.disabled) {
    background-color: #f8f9fa;
}

.support-management .nav-pills .nav-link.disabled {
    color: #adb5bd;
    cursor: not-allowed;
    opacity: 0.6;
}

.not-assigned-card {
    text-align: center;
    padding: 60px 20px;
    background-color: #f8f9fa;
    border: 1px solid #dee2e6;
    border-radius: 10px;
}

.not-assigned-icon {
    width: 80px;
    height: 80px;
    border-radius: 50%;
    background-color: #dee2e6;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto;
}

.not-assigned-icon i {
    font-size: 36px;
    color: #adb5bd;
}

/* Dark theme support */
.theme-dark .support-management .nav-pills .nav-link {
    color: #e0e0e0;
    background-color: #2d2d2d;
    border-color: #444;
}

.theme-dark .support-management .nav-pills .nav-link.active {
    background-color: #9AC444;
    border-color: #9AC444;
    color: #fff;
}

.theme-dark .support-management .nav-pills .nav-link:hover:not(.active):not(.disabled) {
    background-color: #3d3d3d;
}

.theme-dark .support-management .nav-pills .nav-link.disabled {
    color: #666;
    opacity: 0.6;
}

.theme-dark .not-assigned-card {
    background-color: #1e1e1e;
    border-color: #333;
}

.theme-dark .not-assigned-card h5 {
    color: #e0e0e0;
}

.theme-dark .not-assigned-icon {
    background-color: #333;
}

.theme-dark .not-assigned-icon i {
    color: #666;
}
</style>
