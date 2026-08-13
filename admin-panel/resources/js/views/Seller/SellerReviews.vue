<template>
    <div>
        <div v-if="isLoading && orders.length === 0" class="text-center py-5">
            <b-spinner variant="primary" label="Loading..."></b-spinner>
            <p class="mt-2">Loading reviews...</p>
        </div>
        <div v-else>
            <!-- Average Rating & Star Distribution -->
            <div class="row mb-4" v-if="averageRating > 0">
                <div class="col-md-3">
                    <div class="card">
                        <div class="card-body text-center">
                            <h2 class="mb-1">{{ averageRating }}</h2>
                            <div class="star-rating mb-2">
                                <i v-for="star in 5" :key="star"
                                   class="fa fa-star"
                                   :class="star <= Math.round(averageRating) ? 'text-warning' : 'text-muted'">
                                </i>
                            </div>
                            <p class="mb-0">Average Rating ({{ totalProductRatings }} ratings)</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card">
                        <div class="card-body">
                            <div v-for="star in [5,4,3,2,1]" :key="star" class="d-flex align-items-center mb-1">
                                <span class="me-2" style="width: 50px;">{{ star }} Star</span>
                                <b-progress :max="totalProductRatings" style="flex: 1; height: 10px;" class="me-2">
                                    <b-progress-bar :value="starCounts[star + '_star'] || 0" variant="warning"></b-progress-bar>
                                </b-progress>
                                <span style="width: 30px;">{{ starCounts[star + '_star'] || 0 }}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Refresh -->
            <b-row class="mb-3">
                <b-col md="2">
                    <button type="button" class="btn btn-primary" v-b-tooltip.hover :title="__('refresh')" @click="getReviews()">
                        <i class="fa fa-refresh" aria-hidden="true"></i>
                    </button>
                </b-col>
            </b-row>

            <!-- Order-wise Cards -->
            <div v-for="order in orders" :key="order.order_id" class="card mb-3">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <div>
                        <strong>Order #{{ order.order_id }}</strong>
                        <span class="ms-3 text-muted" v-if="order.created_at">{{ formatDate(order.created_at) }}</span>
                    </div>
                </div>
                <div class="card-body">
                    <!-- Customer Info -->
                    <div class="d-flex align-items-center mb-3">
                        <img v-if="order.customer.profile"
                             :src="order.customer.profile"
                             class="rounded-circle me-2"
                             style="width: 40px; height: 40px; object-fit: cover;">
                        <div v-else class="customer-initial-avatar me-2">
                            {{ order.customer.name ? order.customer.name.charAt(0).toUpperCase() : 'C' }}
                        </div>
                        <div>
                            <strong>{{ order.customer.name || '-' }}</strong>
                            <small class="d-block text-muted">Customer ID: {{ order.customer.id }}</small>
                        </div>
                    </div>

                    <!-- Seller Review -->
                    <div class="mb-3" v-if="order.seller_review">
                        <h6>Seller Review</h6>
                        <div class="p-2 rounded" style="background: rgba(255,193,7,0.1); border-left: 3px solid #ffc107;">
                            <i class="fa fa-quote-left text-muted me-1"></i>
                            {{ order.seller_review }}
                        </div>
                    </div>

                    <!-- Product Ratings -->
                    <div v-if="order.product_ratings && order.product_ratings.length > 0">
                        <h6>Product Ratings</h6>
                        <div class="table-responsive">
                            <table class="table table-sm table-bordered mb-0">
                                <thead>
                                    <tr>
                                        <th class="text-center">Product</th>
                                        <th class="text-center">Rating</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-for="pr in order.product_ratings" :key="pr.product_id">
                                        <td class="text-center">{{ pr.product_name || '-' }}</td>
                                        <td class="text-center">
                                            <span class="star-rating">
                                                <i v-for="star in 5" :key="star"
                                                   class="fa fa-star"
                                                   :class="star <= pr.rating ? 'text-warning' : 'text-muted'">
                                                </i>
                                                <span class="ms-1">({{ pr.rating }})</span>
                                            </span>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Pagination -->
            <b-row>
                <b-col md="4" class="my-1" offset-md="8">
                    <label>Total Orders: {{ totalOrders }}</label>
                    <b-pagination
                        v-model="currentPage"
                        :total-rows="totalOrders"
                        :per-page="perPage"
                        align="fill"
                        size="sm"
                        class="my-0"
                    ></b-pagination>
                </b-col>
            </b-row>

            <!-- Empty State -->
            <div v-if="!isLoading && orders.length === 0" class="text-center py-5">
                <i class="fa fa-star fa-3x text-muted mb-3"></i>
                <p class="text-muted">No ratings or reviews found for this seller.</p>
            </div>
        </div>
    </div>
</template>

<script>
import axios from "axios";
import moment from "moment";

export default {
    name: 'SellerReviews',
    props: {
        sellerId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            orders: [],
            totalOrders: 0,
            totalProductRatings: 0,
            averageRating: 0,
            starCounts: {},
            currentPage: 1,
            perPage: 5,
            isLoading: false,
        }
    },
    created() {
        this.getReviews();
    },
    watch: {
        currentPage() {
            this.getReviews();
        },
    },
    methods: {
        getReviews() {
            this.isLoading = true;
            let params = {
                page: this.currentPage,
                per_page: this.perPage,
            };

            axios.get(this.$apiUrl + '/sellers/view/' + this.sellerId + '/reviews', { params: params })
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status === 1) {
                        const data = response.data.data;
                        this.orders = data.orders;
                        this.totalOrders = data.total_orders;
                        this.totalProductRatings = data.total_product_ratings;
                        this.averageRating = data.average_rating || 0;
                        this.starCounts = data.star_counts || {};
                    }
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error fetching reviews:', error);
                });
        },
        formatDate(date) {
            if (!date) return '-';
            return moment(date).format('DD-MM-YYYY');
        },
    }
};
</script>

<style scoped>
.star-rating .fa-star {
    font-size: 14px;
}

.star-rating .text-warning {
    color: #ffc107 !important;
}

.star-rating .text-muted {
    color: #dee2e6 !important;
}

.card-header {
    background-color: transparent;
}

.customer-initial-avatar {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: linear-gradient(135deg, #9AC444 0%, #7a9c36 100%);
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 600;
    font-size: 1rem;
    flex-shrink: 0;
}
</style>