<template>
    <div>
        <div v-if="isLoading && ratings.length === 0" class="text-center py-5">
            <b-spinner variant="primary" label="Loading..."></b-spinner>
            <p class="mt-2">Loading ratings...</p>
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
                            <p class="mb-0">Average Rating ({{ totalRatings }} ratings)</p>
                        </div>
                    </div>
                </div>
                <div class="col-md-4">
                    <div class="card">
                        <div class="card-body">
                            <div v-for="star in [5,4,3,2,1]" :key="star" class="d-flex align-items-center mb-1">
                                <span class="me-2" style="width: 50px;">{{ star }} Star</span>
                                <b-progress :max="totalRatings" style="flex: 1; height: 10px;" class="me-2">
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
                    <button type="button" class="btn btn-primary" v-b-tooltip.hover :title="__('refresh')" @click="getRatings()">
                        <i class="fa fa-refresh" aria-hidden="true"></i>
                    </button>
                </b-col>
            </b-row>

            <!-- Rating Cards -->
            <div v-for="item in ratings" :key="item.id" class="card mb-3">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <div>
                        <strong>Order #{{ item.order_id }}</strong>
                        <span class="ms-3 text-muted" v-if="item.created_at">{{ formatDate(item.created_at) }}</span>
                    </div>
                    <div class="star-rating">
                        <i v-for="star in 5" :key="star"
                           class="fa fa-star"
                           :class="star <= item.rating ? 'text-warning' : 'text-muted'">
                        </i>
                        <span class="ms-1">({{ item.rating }})</span>
                    </div>
                </div>
                <div class="card-body">
                    <!-- Customer Info -->
                    <div class="d-flex align-items-center mb-3">
                        <img v-if="item.customer_profile"
                             :src="item.customer_profile"
                             class="rounded-circle me-2"
                             style="width: 40px; height: 40px; object-fit: cover;">
                        <div v-else class="customer-initial-avatar me-2">
                            {{ item.customer_name ? item.customer_name.charAt(0).toUpperCase() : 'C' }}
                        </div>
                        <div>
                            <strong>{{ item.customer_name || '-' }}</strong>
                            <small class="d-block text-muted">Customer ID: {{ item.customer_id }}</small>
                        </div>
                    </div>

                    <!-- Review -->
                    <div v-if="item.review">
                        <div class="p-2 rounded" style="background: rgba(255,193,7,0.1); border-left: 3px solid #ffc107;">
                            <i class="fa fa-quote-left text-muted me-1"></i>
                            {{ item.review }}
                        </div>
                    </div>
                    <div v-else class="text-muted">
                        <em>No review provided</em>
                    </div>
                </div>
            </div>

            <!-- Pagination -->
            <b-row>
                <b-col md="4" class="my-1" offset-md="8">
                    <label>Total Ratings: {{ totalRatings }}</label>
                    <b-pagination
                        v-model="currentPage"
                        :total-rows="totalRatings"
                        :per-page="perPage"
                        align="fill"
                        size="sm"
                        class="my-0"
                    ></b-pagination>
                </b-col>
            </b-row>

            <!-- Empty State -->
            <div v-if="!isLoading && ratings.length === 0" class="text-center py-5">
                <i class="fa fa-star fa-3x text-muted mb-3"></i>
                <p class="text-muted">No ratings or reviews found for this delivery boy.</p>
            </div>
        </div>
    </div>
</template>

<script>
import axios from "axios";
import moment from "moment";

export default {
    name: 'DriverRatings',
    props: {
        deliveryBoyId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            ratings: [],
            totalRatings: 0,
            averageRating: 0,
            starCounts: {},
            currentPage: 1,
            perPage: 10,
            isLoading: false,
        }
    },
    created() {
        this.getRatings();
    },
    watch: {
        currentPage() {
            this.getRatings();
        },
    },
    methods: {
        getRatings() {
            this.isLoading = true;
            let params = {
                page: this.currentPage,
                per_page: this.perPage,
            };

            axios.get(this.$apiUrl + '/delivery_boys/' + this.deliveryBoyId + '/ratings', { params: params })
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status === 1) {
                        const data = response.data.data;
                        this.ratings = data.ratings;
                        this.totalRatings = data.total_ratings;
                        this.averageRating = data.avg_rating || 0;
                        this.starCounts = data.star_counts || {};
                    }
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error('Error fetching ratings:', error);
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