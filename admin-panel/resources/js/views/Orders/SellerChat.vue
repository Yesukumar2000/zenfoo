<template>
    <div class="seller-chat">
        <!-- Loading State -->
        <div v-if="isLoading" class="text-center py-5">
            <b-spinner variant="success" label="Loading..."></b-spinner>
            <p class="mt-2 text-muted">Loading sellers...</p>
        </div>

        <!-- No Sellers Found -->
        <div v-else-if="sellers.length === 0" class="text-center py-5">
            <div class="empty-icon">
                <i class="fas fa-store"></i>
            </div>
            <p class="mt-3 text-muted">No sellers found for this order.</p>
        </div>

        <!-- Seller Tabs and Chat -->
        <div v-else>
            <!-- Seller Tabs -->
            <div class="seller-tabs mb-3">
                <ul class="nav nav-pills">
                    <li class="nav-item" v-for="seller in sellers" :key="seller.id">
                        <a
                            class="nav-link"
                            :class="{ active: activeSellerId === seller.id }"
                            href="#"
                            @click.prevent="selectSeller(seller)"
                        >
                            <i class="fas fa-store me-1"></i>
                            {{ seller.name }}
                            <span v-if="sellerUnreadCounts[seller.chat_type] > 0" class="badge bg-danger ms-1">
                                {{ sellerUnreadCounts[seller.chat_type] }}
                            </span>
                        </a>
                    </li>
                </ul>
            </div>

            <!-- Chat Box for Selected Seller -->
            <div v-if="activeSeller">
                <ChatBox
                    :key="activeSeller.chat_type"
                    :orderId="orderId"
                    :chatType="activeSeller.chat_type"
                    :title="activeSeller.name + ' Support'"
                    headerIcon="fas fa-store"
                    headerColor="#9AC444"
                />
            </div>
        </div>
    </div>
</template>

<script>
import axios from "axios";
import ChatBox from './ChatBox.vue';

export default {
    name: 'SellerChat',
    components: {
        ChatBox
    },
    props: {
        orderId: {
            type: [String, Number],
            required: true
        },
        initialSellerId: {
            type: [String, Number],
            default: null
        }
    },
    data() {
        return {
            isLoading: false,
            sellers: [],
            activeSellerId: null,
            sellerUnreadCounts: {}
        };
    },
    computed: {
        activeSeller() {
            return this.sellers.find(s => s.id === this.activeSellerId) || null;
        }
    },
    watch: {
        orderId: {
            immediate: true,
            handler() {
                this.fetchOrderSellers();
            }
        }
    },
    methods: {
        fetchOrderSellers() {
            this.isLoading = true;
            this.sellers = [];
            this.activeSellerId = null;

            axios.get(this.$apiUrl + '/order-chat/order-sellers', {
                params: {
                    order_id: this.orderId
                }
            }).then((response) => {
                this.isLoading = false;
                if (response.data.status === 1) {
                    this.sellers = response.data.data || [];

                    // Auto-select seller based on initialSellerId or first seller
                    if (this.sellers.length > 0) {
                        if (this.initialSellerId) {
                            // Find seller matching initialSellerId
                            const targetSeller = this.sellers.find(s => s.id == this.initialSellerId);
                            this.activeSellerId = targetSeller ? targetSeller.id : this.sellers[0].id;
                        } else {
                            this.activeSellerId = this.sellers[0].id;
                        }
                    }

                    // Fetch unread counts for all sellers
                    this.fetchSellerUnreadCounts();
                }
            }).catch((error) => {
                this.isLoading = false;
                console.error('Error fetching order sellers:', error);
            });
        },

        fetchSellerUnreadCounts() {
            this.sellers.forEach(seller => {
                axios.get(this.$apiUrl + '/order-chat/unread-count', {
                    params: {
                        order_id: this.orderId,
                        chat_type: seller.chat_type
                    }
                }).then((response) => {
                    if (response.data.status === 1) {
                        this.$set(this.sellerUnreadCounts, seller.chat_type, response.data.data.unread_count || 0);
                    }
                }).catch((error) => {
                    console.error('Error fetching unread count for seller:', error);
                });
            });
        },

        selectSeller(seller) {
            this.activeSellerId = seller.id;
            // Clear unread count when selecting a seller
            this.$set(this.sellerUnreadCounts, seller.chat_type, 0);
        }
    }
};
</script>

<style>
.seller-chat {
    height: 100%;
}

.empty-icon {
    width: 80px;
    height: 80px;
    border-radius: 50%;
    background-color: #dee2e6;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto;
}

.empty-icon i {
    font-size: 36px;
    color: #adb5bd;
}

.seller-tabs .nav-pills {
    flex-wrap: wrap;
    gap: 4px;
}

.seller-tabs .nav-pills .nav-item {
    flex: 0 0 auto;
}

.seller-tabs .nav-pills .nav-link {
    color: #435971;
    background-color: #fff;
    border: 1px solid #dee2e6;
    border-radius: 20px;
    font-size: 13px;
    padding: 8px 16px;
    white-space: nowrap;
}

.seller-tabs .nav-pills .nav-link.active {
    background-color: #9AC444;
    border-color: #9AC444;
    color: #fff;
}

.seller-tabs .nav-pills .nav-link:hover:not(.active) {
    background-color: #f8f9fa;
}

.seller-tabs .nav-pills .nav-link .badge {
    font-size: 10px;
    padding: 3px 6px;
}

/* Dark theme support */
.theme-dark .empty-icon {
    background-color: #333;
}

.theme-dark .empty-icon i {
    color: #666;
}

.theme-dark .seller-tabs .nav-pills .nav-link {
    color: #e0e0e0;
    background-color: #2d2d2d;
    border-color: #444;
}

.theme-dark .seller-tabs .nav-pills .nav-link.active {
    background-color: #9AC444;
    border-color: #9AC444;
    color: #fff;
}

.theme-dark .seller-tabs .nav-pills .nav-link:hover:not(.active) {
    background-color: #3d3d3d;
}
</style>
