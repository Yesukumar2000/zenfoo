<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Seller Details</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                            <li class="breadcrumb-item"><router-link to="/sellers">{{ __('sellers') }}</router-link></li>
                            <li class="breadcrumb-item active" aria-current="page">Seller Details</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/sellers" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-body">
                            <!-- Tabs Navigation -->
                            <ul class="nav nav-tabs" id="sellerTabs" role="tablist">
                                <li class="nav-item" role="presentation">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'overview' }"
                                        @click="activeTab = 'overview'"
                                        type="button">
                                        <i class="fa fa-user me-1"></i> Overview
                                    </button>
                                </li>
                                <li class="nav-item" role="presentation">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'orders' }"
                                        @click="activeTab = 'orders'"
                                        type="button">
                                        <i class="fa fa-shopping-cart me-1"></i> Orders
                                    </button>
                                </li>
                                <li class="nav-item" role="presentation">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'products' }"
                                        @click="activeTab = 'products'"
                                        type="button">
                                        <i class="fa fa-box me-1"></i> Products
                                    </button>
                                </li>
                                <li class="nav-item" role="presentation">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'reviews' }"
                                        @click="activeTab = 'reviews'"
                                        type="button">
                                        <i class="fa fa-star me-1"></i> Reviews
                                    </button>
                                </li>
                                <li class="nav-item" role="presentation">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'transactions' }"
                                        @click="activeTab = 'transactions'"
                                        type="button">
                                        <i class="fa fa-credit-card me-1"></i> Transactions
                                    </button>
                                </li>
                                <li class="nav-item" role="presentation" v-if="isSupermart">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'brands' }"
                                        @click="activeTab = 'brands'"
                                        type="button">
                                        <i class="fa fa-tag me-1"></i> Brands
                                    </button>
                                </li>
                                <li class="nav-item" role="presentation" v-if="showManageCategories">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'manage-categories' }"
                                        @click="activeTab = 'manage-categories'"
                                        type="button">
                                        <i class="fa fa-tags me-1"></i> Manage Categories
                                    </button>
                                </li>
                                <!-- <li class="nav-item" role="presentation">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'analytics' }"
                                        @click="activeTab = 'analytics'"
                                        type="button">
                                        <i class="fa fa-chart-bar me-1"></i> Analytics
                                    </button>
                                </li> -->
                                <li class="nav-item" role="presentation">
                                    <button
                                        class="nav-link"
                                        :class="{ 'active': activeTab === 'support' }"
                                        @click="activeTab = 'support'"
                                        type="button">
                                        <i class="fa fa-headset me-1"></i> Support
                                    </button>
                                </li>
                            </ul>

                            <!-- Tab Content -->
                            <div class="tab-content mt-4" id="sellerTabsContent">
                                <!-- Overview Tab -->
                                <div v-if="activeTab === 'overview'" class="tab-pane fade show active">
                                    <seller-overview :seller-id="sellerId"></seller-overview>
                                </div>

                                <!-- Orders Tab -->
                                <div v-if="activeTab === 'orders'" class="tab-pane fade show active">
                                    <seller-orders :seller-id="sellerId"></seller-orders>
                                </div>

                                <!-- Products Tab -->
                                <div v-if="activeTab === 'products'" class="tab-pane fade show active">
                                    <seller-products :seller-id="sellerId"></seller-products>
                                </div>

                                <!-- Reviews Tab -->
                                <div v-if="activeTab === 'reviews'" class="tab-pane fade show active">
                                    <seller-reviews :seller-id="sellerId"></seller-reviews>
                                </div>

                                <!-- Transactions Tab -->
                                <div v-if="activeTab === 'transactions'" class="tab-pane fade show active">
                                    <seller-transactions :seller-id="sellerId"></seller-transactions>
                                </div>

                                <!-- Conversations Tab -->
                                <!-- <div v-if="activeTab === 'conversations'" class="tab-pane fade show active">
                                    <seller-conversations :seller-id="sellerId"></seller-conversations>
                                </div> -->

                                <!-- Brands Tab -->
                                <div v-if="activeTab === 'brands' && isSupermart" class="tab-pane fade show active">
                                    <seller-brands :seller-id="sellerId"></seller-brands>
                                </div>

                                <!-- Manage Categories Tab -->
                                <div v-if="activeTab === 'manage-categories' && showManageCategories" class="tab-pane fade show active">
                                    <seller-manage-categories-supermart v-if="isSupermart" :seller-id="sellerId"></seller-manage-categories-supermart>
                                    <seller-manage-categories v-else :seller-id="sellerId"></seller-manage-categories>
                                </div>

                                <!-- Analytics Tab -->
                                <!-- <div v-if="activeTab === 'analytics'" class="tab-pane fade show active">
                                    <seller-analytics :seller-id="sellerId"></seller-analytics>
                                </div> -->

                                <!-- Support Tab -->
                                <div v-if="activeTab === 'support'" class="tab-pane fade show active">
                                    <seller-support-tab :seller-id="sellerId"></seller-support-tab>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    name: 'SellerView',
    components: {
        'seller-overview': () => import('./SellerOverview.vue'),
        'seller-orders': () => import('./SellerOrders.vue'),
        'seller-products': () => import('./SellerProducts.vue'),
        'seller-reviews': () => import('./SellerReviews.vue'),
        'seller-transactions': () => import('./SellerTransactions.vue'),
        // 'seller-conversations': () => import('./SellerConversations.vue'),
        'seller-manage-categories': () => import('./SellerManageCategories.vue'),
        'seller-manage-categories-supermart': () => import('./SellerManageCategoriesSupermart.vue'),
        'seller-analytics': () => import('./Tabs/SellerAnalytics.vue'),
        'seller-brands': () => import('./SellerBrands.vue'),
        'seller-support-tab': () => import('./SellerSupportTab.vue')
    },
    data() {
        return {
            sellerId: null,
            activeTab: 'overview',
            seller: null
        }
    },
    computed: {
        showManageCategories() {
            return this.seller && this.seller.store && this.seller.store.managed_by_admin == 0;
        },
        isSupermart() {
            return this.seller && this.seller.store && this.seller.store.is_super_mart == 1;
        }
    },
    created() {
        this.sellerId = this.$route.params.id;
        this.fetchSellerBasicInfo();

        // Check if tab query parameter is set (e.g., from notification navigation)
        if (this.$route.query.tab) {
            this.activeTab = this.$route.query.tab;
        }
    },
    methods: {
        fetchSellerBasicInfo() {
            axios.get(this.$apiUrl + '/sellers/view/' + this.sellerId + '/overview')
                .then((response) => {
                    if (response.data.status === 1) {
                        this.seller = response.data.data;
                    }
                })
                .catch((error) => {
                    console.error('Error fetching seller info:', error);
                });
        }
    }
}
</script>

<style scoped>
.nav-tabs .nav-link {
    color: #6c757d;
    border: none;
    border-bottom: 2px solid transparent;
    padding: 0.75rem 1.25rem;
    font-weight: 500;
}

.nav-tabs .nav-link:hover {
    color: #9AC444;
    border-bottom: 2px solid #9AC444;
}

.nav-tabs .nav-link.active {
    color: #9AC444;
    background-color: transparent;
    border-bottom: 2px solid #9AC444;
}

.tab-content {
    min-height: 300px;
}

/* Statistics Cards */
.stat-card {
    display: flex;
    align-items: center;
    padding: 20px;
    border-radius: 10px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.stat-icon {
    font-size: 2.5rem;
    margin-right: 15px;
    opacity: 0.8;
}

.stat-details h3 {
    margin: 0;
    font-size: 1.5rem;
    font-weight: 600;
}

.stat-details p {
    margin: 0;
    font-size: 0.875rem;
    opacity: 0.9;
}

.card-header h5 {
    font-weight: 600;
}

.table-borderless td {
    padding: 8px 0;
}
</style>