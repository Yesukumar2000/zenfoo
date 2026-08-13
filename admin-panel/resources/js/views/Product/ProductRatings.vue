<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>{{ __('product_ratings') }}</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">{{ __('product_ratings') }}</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/dashboard" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to Dashboard
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12 col-md-12 order-md-1 order-last">
                    <div class="card">
                        <div class="card-header">
                            <h4>{{ __('product_ratings_list') }}</h4>
                        </div>
                        <div class="card-body">
                            <b-row class="mb-3">
                                <b-col md="3">
                                    <h6 class="box-title">Filter by Zone</h6>
                                    <select @change="onZoneChange()" v-model="city_id" class="form-control form-select">
                                        <option value="">All Zones</option>
                                        <option v-for="city in cities" :key="city.id" :value="city.id">
                                            {{ city.name }}
                                        </option>
                                        <option value="other">Other</option>
                                    </select>
                                </b-col>
                                <b-col md="3">
                                    <h6 class="box-title">Filter by Store</h6>
                                    <select @change="onStoreChange()" v-model="store_id" class="form-control form-select">
                                        <option value="">All Stores</option>
                                        <option v-for="store in stores" :key="store.id" :value="store.id">
                                            {{ store.name }}
                                        </option>
                                    </select>
                                </b-col>
                                <b-col md="3">
                                    <h6 class="box-title">Filter by Seller</h6>
                                    <select @change="onSellerChange()" v-model="seller_id" class="form-control form-select">
                                        <option value="">All Sellers</option>
                                        <option v-for="seller in filteredSellers" :key="seller.id" :value="seller.id">
                                            {{ seller.name }}
                                        </option>
                                    </select>
                                </b-col>
                                <b-col md="1" class="d-flex align-items-end">
                                    <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getRecords()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i>
                                    </button>
                                </b-col>
                            </b-row>

                            <b-table
                                :items="ratings"
                                :fields="fields"
                                :bordered="true"
                                :busy="isLoading"
                                stacked="md"
                                show-empty
                                small>

                                <template #cell(avg_rating)="row">
                                    {{ renderStarRating(Math.round(row.item.avg_rating)) }} ({{ row.item.avg_rating }})
                                </template>

                                <template #cell(seller_name)="row">
                                    {{ row.item.seller_name || 'Zenfoo' }}
                                </template>

                                <template #cell(store_name)="row">
                                    {{ row.item.store_name || '-' }}
                                </template>

                                <template #table-busy>
                                    <div class="text-center text-black my-2">
                                        <b-spinner class="align-middle"></b-spinner>
                                        <strong>{{ __('loading') }}...</strong>
                                    </div>
                                </template>

                            </b-table>

                            <b-row>
                                <b-col md="2" class="my-1">
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
                                            @change="onPerPageChange()"
                                        ></b-form-select>
                                    </b-form-group>
                                </b-col>
                                <b-col md="4" class="my-1" offset-md="6">
                                    <label>Total Products: {{ totalRows }}</label>
                                    <b-pagination
                                        v-model="currentPage"
                                        :total-rows="totalRows"
                                        :per-page="perPage"
                                        align="fill"
                                        size="sm"
                                        class="my-0"
                                        @change="onPageChange"
                                    ></b-pagination>
                                </b-col>
                            </b-row>

                            <template v-if="ratings.length == 0 && !isLoading">
                                <span>No ratings found</span>
                            </template>

                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import axios from "axios";

export default {
    data: function () {
        return {
            fields: [
                { key: 'product_id', label: 'Product ID', class: 'text-center' },
                { key: 'product_name', label: 'Product Name', class: 'text-center' },
                { key: 'seller_name', label: 'Seller', class: 'text-center' },
                { key: 'store_name', label: 'Store', class: 'text-center' },
                { key: 'avg_rating', label: 'Avg Rating', class: 'text-center' },
                { key: 'total_ratings', label: 'Total Ratings', class: 'text-center' },
                { key: 'five_star', label: '5 Star', class: 'text-center' },
                { key: 'four_star', label: '4 Star', class: 'text-center' },
                { key: 'three_star', label: '3 Star', class: 'text-center' },
                { key: 'two_star', label: '2 Star', class: 'text-center' },
                { key: 'one_star', label: '1 Star', class: 'text-center' },
            ],
            totalRows: 0,
            currentPage: 1,
            perPage: 10,
            pageOptions: [10, 25, 50, 100],
            ratings: [],
            isLoading: false,
            stores: [],
            sellers: [],
            store_id: "",
            seller_id: "",
            city_id: "",
            cities: [],
        }
    },
    computed: {
        filteredSellers() {
            if (!this.store_id) {
                return this.sellers;
            }
            return this.sellers.filter(s => s.store_id == this.store_id);
        }
    },
    created: function () {
        this.getCities();
        this.getStores();
        this.getSellers();
        this.getRecords();
    },
    methods: {
        renderStarRating(rate) {
            const filledStars = rate;
            const blankStars = 5 - filledStars;
            const starIconFilled = '\u2B50\uFE0F';
            const starIconBlank = '\u2606';
            return starIconFilled.repeat(filledStars) + starIconBlank.repeat(blankStars);
        },

        onZoneChange() {
            this.seller_id = "";
            this.currentPage = 1;
            this.getSellers();
            this.getRecords();
        },

        onStoreChange() {
            this.seller_id = "";
            this.currentPage = 1;
            this.getRecords();
        },

        onSellerChange() {
            this.currentPage = 1;
            this.getRecords();
        },

        onPerPageChange() {
            this.currentPage = 1;
            this.getRecords();
        },

        onPageChange(page) {
            this.currentPage = page;
            this.getRecords();
        },

        getStores() {
            axios.get(this.$apiUrl + '/stores')
                .then((response) => {
                    if (response.data.status === 1) {
                        this.stores = response.data.data;
                    }
                });
        },

        getCities() {
            axios.get(this.$apiUrl + '/cities')
                .then((response) => {
                    this.cities = response.data.data;
                });
        },

        getSellers() {
            const params = {};
            if (this.city_id !== '') params.city_id = this.city_id;
            axios.get(this.$apiUrl + '/sellers', { params })
                .then((response) => {
                    this.sellers = response.data.data;
                });
        },

        getRecords() {
            this.isLoading = true;
            let params = {
                page: this.currentPage,
                per_page: this.perPage,
            };
            if (this.city_id) {
                params.city_id = this.city_id;
            }
            if (this.store_id) {
                params.store_id = this.store_id;
            }
            if (this.seller_id) {
                params.seller_id = this.seller_id;
            }

            axios.get(this.$apiUrl + '/products/ratings_list', {
                params: params
            }).then((response) => {
                this.isLoading = false;
                const data = response.data.data;
                this.ratings = data.ratings;
                this.totalRows = data.pagination.total;
            }).catch(() => {
                this.isLoading = false;
                this.ratings = [];
                this.totalRows = 0;
            });
        },
    }
};
</script>
