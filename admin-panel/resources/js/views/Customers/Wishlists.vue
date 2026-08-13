<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>{{ __('wishlists_list') }}</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">{{ __('wishlists_list') }}</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/dashboard" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to Dashboard
                    </router-link>
                </div>
            </div>

            <section class="section">
                <div class="card">
                    <div class="card-header">
                        <h4 class="card-title">{{ __('wishlists') }}</h4>
                    </div>
                    <div class="card-body">

                        <b-row class="mb-3">
                            <b-col md="3">
                                <h6 class="box-title">{{ __('filter_by_type') }}</h6>
                                <b-form-select v-model="selectedType" :options="typeOptions" class="form-control"></b-form-select>
                            </b-col>
                            <b-col md="5">
                                <h6 class="box-title">{{ __('statistics') }}</h6>
                                <div>
                                    <span class="badge bg-secondary me-1">Total: {{ stats.total_bookmarks }}</span>
                                    <span class="badge bg-primary me-1">Products: {{ stats.products_count }}</span>
                                    <span class="badge bg-success me-1">Sellers: {{ stats.sellers_count }}</span>
                                    <span class="badge bg-warning">Combos: {{ stats.combos_count }}</span>
                                </div>
                            </b-col>
                            <b-col md="3">
                                <h6 class="box-title">{{ __('search') }}</h6>
                                <b-form-input
                                    id="filter-input"
                                    v-model="filter"
                                    type="search"
                                    placeholder="Search"
                                ></b-form-input>
                            </b-col>
                            <b-col md="1" class="text-center">
                                <h6 class="box-title">&nbsp;</h6>
                                <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getWishlists()">
                                    <i class="fa fa-refresh" aria-hidden="true"></i>
                                </button>
                            </b-col>
                        </b-row>
                        <div class="table-responsive">
                            <b-table
                                :items="wishlists"
                                :fields="fields"
                                :current-page="currentPage"
                                :per-page="perPage"
                                :filter="filter"
                                :filter-included-fields="filterOn"
                                :sort-by.sync="sortBy"
                                :sort-desc.sync="sortDesc"
                                :sort-direction="sortDirection"
                                :bordered="true"
                                :busy="isLoading"
                                stacked="md"
                                show-empty
                                small>
                                <template #table-busy>
                                    <div class="text-center text-black my-2">
                                        <b-spinner class="align-middle"></b-spinner>
                                        <strong>{{ __('loading') }}...</strong>
                                    </div>
                                </template>

                                <template #cell(type)="row">
                                    <span class="badge" :class="{
                                        'bg-primary': row.item.type === 'product',
                                        'bg-success': row.item.type === 'seller',
                                        'bg-warning': row.item.type === 'combo'
                                    }">
                                        {{ row.item.type.toUpperCase() }}
                                    </span>
                                </template>
                                <template #cell(item_name)="row">
                                    <div class="d-flex align-items-center">
                                        <img v-if="row.item.item_image" :src="row.item.item_image" alt="Item" style="width: 40px; height: 40px; object-fit: cover; border-radius: 4px; margin-right: 10px;">
                                        <span>{{ row.item.item_name }}</span>
                                    </div>
                                </template>
                                <template #cell(created_at)="row">
                                    {{ new Date(row.item.created_at).toLocaleString()  }}
                                </template>
                                <template #cell(seller_name)="row">
                                    {{ row.item.seller_name || 'N/A' }}
                                </template>
                                <template #cell(actions)="row">
                                    <router-link v-if="row.item.type === 'product' && row.item.bookmarkable_id" :to="'manage_products/view/' + row.item.bookmarkable_id"  class="btn btn-sm btn-primary" v-b-tooltip.hover :title="__('view')">
                                        <i class="fa fa-eye"></i>
                                    </router-link>
                                    <button class="btn btn-sm btn-info ms-1" @click="sendWishlistNotification(row.item)" v-b-tooltip.hover :title="__('send_notification')" :disabled="sendingNotificationId === row.item.id">
                                        <i class="fa fa-bell" :class="{ 'fa-spin': sendingNotificationId === row.item.id }"></i>
                                    </button>
                                </template>

                            </b-table>
                        </div>
                        <b-row>
                            <b-col  md="2" class="my-1">
                                <b-form-group
                                    :label="__('per_page')"
                                    label-for="per-page-select"
                                    label-align-sm="right"
                                    label-size="sm"
                                    class="mb-0">
                                    <b-form-select
                                        id="per-page-select"
                                        v-model="perPage"
                                        :options="pageOptions"
                                        size="sm"
                                        class="form-control form-select"
                                    ></b-form-select>
                                </b-form-group>
                            </b-col>
                            <b-col  md="4" class="my-1" offset-md="6">
                                <b-pagination
                                    v-model="currentPage"
                                    :total-rows="totalRows"
                                    :per-page="perPage"
                                    align="fill"
                                    size="sm"
                                    class="my-0"
                                ></b-pagination>
                            </b-col>
                        </b-row>

                    </div>
                </div>
            </section>
        </div>
    </div>
</template>
<script>
export default {
    data: function() {
        return {
            fields: [
                { key: 'id', label: __('id'), sortable: true, sortDirection: 'desc' },
                { key: 'user_name', label: __('customer'), sortable: true, class: 'text-center' },
                { key: 'type', label: __('type'), sortable: true, class: 'text-center' },
                { key: 'item_name', label: __('item'), sortable: true, class: 'text-center' },
                { key: 'seller_name', label: __('seller'), sortable: true, class: 'text-center' },
                { key: 'created_at', label: __('added_on'), sortable: true, class: 'text-center' },
                { key: 'actions', label: __('actions') }
            ],
            totalRows: 1,
            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            sortBy: '',
            sortDesc: false,
            sortDirection: 'asc',
            filter: null,
            filterOn: [],
            page: 1,

            isLoading: false,
            sectionStyle : 'style_1',
            max_visible_units : 12,
            max_col_in_single_row : 3,
            wishlists: [],
            allWishlists: [], // Store all wishlists before filtering

            // Filter
            selectedType: 'all',
            typeOptions: [
                { value: 'all', text: 'All Types' },
                { value: 'product', text: 'Products' },
                { value: 'seller', text: 'Sellers' },
                { value: 'combo', text: 'Combos' }
            ],

            // Stats
            stats: {
                total_bookmarks: 0,
                products_count: 0,
                sellers_count: 0,
                combos_count: 0
            },

            // Notification
            sendingNotificationId: null,
            wishlistMessages: [
                "👋 Hey! {product} misses you badly!",
                "🐶 {product} is waiting like puppy!",
                "📰 Breaking! {product} spotted in wishlist!",
                "🚨 Alert! {product} might escape soon!",
                "📞 {product} called, it misses you!",
                "😎 Cool people buy {product} now!",
                "⚡ {product} used charm, super effective!",
                "💝 {product} is waiting for you!",
                "🎵 {product} wants to come home!",
                "👀 {product} is checking on you!",
                "🏆 Claim your prize, grab {product}!",
                "🏋️ Lighten wishlist, buy {product} today!",
                "😢 {product} feels lonely without you!",
                "✨ Legend says buy {product} now!",
                "🤖 Robots recommend buying {product} immediately!",
                "💰 Jackpot! {product} is a winner!",
                "💪 Be a hero, buy {product}!",
                "🔬 Science proves {product} is best!",
                "🎁 Treat yourself! Get {product} now!",
                "🌈 Make dreams true, get {product}!",
                "🍕 {product} is delicious like pizza!",
                "🍿 {product} coming to your doorstep!",
                "💍 {product} is precious, grab it!",
                "☕ {product} and chill sounds perfect!",
                "🎯 Bulls-eye! {product} is perfect pick!",
                "🚀 Mission {product}: Add to cart!",
                "🎟️ {product} show is starting soon!",
                "🛒 Your cart is calling {product}!",
                "🎸 {product} wants to rock you!",
                "🦋 {product} ready to bloom beautifully!"
            ]
        }
    },
    computed: {
        sortOptions() {
            // Create an options list from our fields
            return this.fields
                .filter(f => f.sortable)
                .map(f => {
                    return { text: f.label, value: f.key }
                })
        }
    },
    watch: {
        selectedType(newType) {
            this.filterWishlistsByType(newType);
        }
    },
    mounted() {
        // Set the initial number of items
        this.totalRows = this.wishlists.length
    },
    created: function() {
        this.getWishlists();
    },
    methods: {
        getWishlists(){
            this.isLoading = true
            axios.get(this.$apiUrl + '/wishlists')
                .then((response) => {
                    this.isLoading = false
                    // Handle new response structure with wishlists array
                    if (response.data.data && response.data.data.wishlists) {
                        this.allWishlists = response.data.data.wishlists;
                        this.stats = response.data.data.stats || {
                            total_bookmarks: 0,
                            products_count: 0,
                            sellers_count: 0,
                            combos_count: 0
                        };
                    } else if (response.data.data) {
                        this.allWishlists = response.data.data;
                        this.stats = {
                            total_bookmarks: this.allWishlists.length,
                            products_count: 0,
                            sellers_count: 0,
                            combos_count: 0
                        };
                    } else {
                        this.allWishlists = [];
                        this.stats = {
                            total_bookmarks: 0,
                            products_count: 0,
                            sellers_count: 0,
                            combos_count: 0
                        };
                    }

                    // Apply current filter
                    this.filterWishlistsByType(this.selectedType);
                })
                .catch((error) => {
                    this.isLoading = false
                    console.error('Error fetching wishlists:', error);
                    this.allWishlists = [];
                    this.wishlists = [];
                });
        },
        filterWishlistsByType(type) {
            if (type === 'all') {
                this.wishlists = this.allWishlists;
            } else {
                this.wishlists = this.allWishlists.filter(item => item.type === type);
            }
            this.totalRows = this.wishlists.length;
        },
        getRandomMessage(productName) {
            const randomIndex = Math.floor(Math.random() * this.wishlistMessages.length);
            return this.wishlistMessages[randomIndex].replace('{product}', productName);
        },
        sendWishlistNotification(wishlist) {
            this.sendingNotificationId = wishlist.id;

            const itemName = wishlist.item_name || 'this item';
            const message = this.getRandomMessage(itemName);

            // Determine page navigation based on type
            let pageNavigation = wishlist.type; // 'product', 'seller', or 'combo'
            let navigationId = wishlist.bookmarkable_id;

            // If type is combo, navigate to product (as app might not support direct combo navigation)
            if (wishlist.type === 'combo') {
                pageNavigation = 'home'; // Navigate to home for combos
            }

            let postData = {
                customer_id: wishlist.user_id,
                title: '💝 Wishlist Reminder!',
                message: message,
                image_url: wishlist.item_image || '',
                page_navigation: pageNavigation,
                navigation_id: navigationId
            };

            axios.post(this.$apiUrl + '/customer-notifications/send', postData)
                .then((response) => {
                    this.sendingNotificationId = null;
                    this.showMessage('success', response.data.message || __('notification_sent_successfully'));
                })
                .catch((error) => {
                    this.sendingNotificationId = null;
                    this.showMessage('error', error.response?.data?.message || __('something_went_wrong'));
                });
        },
    }
};
</script>
