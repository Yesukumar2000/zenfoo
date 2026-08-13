<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>{{ __('products') }} - {{ sellerName }}</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item">
                                <router-link to="/sellers">{{ __('sellers') }}</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">{{ __('products') }}</li>
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
                <div class="col-12 col-md-12 order-md-1 order-last">
                    <div class="card">
                        <div class="card-header">
                            <h4>{{ __('products') }}</h4>
                            <router-link to="/sellers" class="btn btn-secondary btn-sm float-end">
                                <i class="fa fa-arrow-left"></i> {{ __('back') }}
                            </router-link>
                        </div>

                        <div class="card-body">
                            <b-row class="mb-3">
                                <b-col md="4">
                                    <h6 class="box-title">{{ __('search') }}</h6>
                                    <b-form-input
                                        id="filter-input"
                                        v-model="filter"
                                        type="search"
                                        :placeholder="__('search')"
                                        @input="debounceSearch"
                                    ></b-form-input>
                                </b-col>
                                <b-col md="2" class="d-flex align-items-end">
                                    <button type="button" class="btn btn-primary" v-b-tooltip.hover :title="__('refresh')" @click="getRecords()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i>
                                    </button>
                                </b-col>
                            </b-row>

                            <div class="table-responsive">
                                <b-table
                                    :items="products"
                                    :fields="fields"
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

                                    <template #cell(image)="row">
                                        <img :src="$mediaUrl(row.item.image)" @click="openLightbox($mediaUrl(row.item.image))" alt="Image" height="50" style="cursor: pointer;" />
                                        <FsLightbox :toggler="toggler" :sources="lightboxSources" :onClose="handleClose"></FsLightbox>
                                    </template>

                                    <template #cell(price)="row">
                                        {{ $currency }} {{ row.item.price }}
                                    </template>

                                    <template #cell(discounted_price)="row">
                                        {{ $currency }} {{ row.item.discounted_price }}
                                    </template>

                                    <template #cell(measurement)="row">
                                        {{ row.item.measurement }} <span v-if="row.item.stock_unit">{{ row.item.stock_unit }}</span>
                                    </template>

                                    <template #cell(status)="row">
                                        <span class='badge bg-success' v-if="row.item.status == 1">Active</span>
                                        <span class='badge bg-danger' v-else>Inactive</span>
                                    </template>

                                    <template #cell(is_approved)="row">
                                        <span class='badge bg-success' v-if="row.item.is_approved == 1">Approved</span>
                                        <span class='badge bg-danger' v-else>Not Approved</span>
                                    </template>

                                    <template #cell(indicator)="row">
                                        <span class='badge bg-info' v-if="row.item.indicator == 0">None</span>
                                        <span class='badge bg-success' v-if="row.item.indicator == 1">Veg</span>
                                        <span class='badge bg-danger' v-if="row.item.indicator == 2">Non-Veg</span>
                                    </template>

                                    <template #cell(actions)="row">
                                        <router-link
                                            :to="{ name: 'ViewProduct', params: { id: row.item.product_id }}"
                                            class="btn btn-primary btn-sm"
                                            v-b-tooltip.hover
                                            :title="__('view')">
                                            <i class="fa fa-eye"></i>
                                        </router-link>
                                        <router-link
                                            :to="{ name: 'EditSellerProduct', params: { id: row.item.product_id }, query: { seller_id: sellerId }}"
                                            class="btn btn-success btn-sm ms-1"
                                            v-b-tooltip.hover
                                            :title="__('edit')">
                                            <i class="fa fa-pencil-alt"></i>
                                        </router-link>
                                    </template>

                                </b-table>
                            </div>

                            <b-row>
                                <b-col md="2">
                                    <label>
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
                                    </label>
                                </b-col>
                                <b-col md="4" offset-md="6">
                                    <label>{{ __('total_records') }} :- {{ totalRows }} </label>
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
                </div>
            </div>
        </div>

    </div>
</template>

<script>
import axios from "axios";
import FsLightbox from "fslightbox-vue";

export default {
    components: {
        FsLightbox,
    },
    data: function () {
        return {
            fields: [
                { key: 'product_variant_id', label: 'ID', visible: true, sortable: true, class: 'text-center' },
                { key: 'name', label: 'Name', visible: true, sortable: true, class: 'text-center' },
                { key: 'image', label: 'Image', visible: true, class: 'text-center' },
                { key: 'category_name', label: 'Category', visible: true, class: 'text-center' },
                { key: 'price', label: 'Price', visible: true, class: 'text-center' },
                { key: 'discounted_price', label: 'D.Price', visible: true, class: 'text-center' },
                { key: 'measurement', label: 'Measurement', visible: true, class: 'text-center' },
                { key: 'stock', label: 'Stock', visible: true, class: 'text-center' },
                { key: 'status', label: 'Status', visible: true, class: 'text-center' },
                { key: 'is_approved', label: 'Approved', visible: true, class: 'text-center' },
                { key: 'actions', label: 'Actions', visible: true, class: 'text-center' }
            ],
            products: [],
            totalRows: 0,
            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            filter: '',
            isLoading: false,
            sellerId: null,
            sellerName: '',
            toggler: false,
            lightboxSources: [],
            debounceTimer: null,
        }
    },
    created: function () {
        this.sellerId = this.$route.query.seller_id;
        if (this.sellerId) {
            this.getRecords();
        } else {
            this.$router.push('/sellers');
        }
    },
    watch: {
        currentPage() {
            this.getRecords();
        },
        perPage() {
            this.currentPage = 1;
            this.getRecords();
        },
    },
    methods: {
        debounceSearch() {
            clearTimeout(this.debounceTimer);
            this.debounceTimer = setTimeout(() => {
                this.currentPage = 1;
                this.getRecords();
            }, 500);
        },
        getRecords() {
            this.isLoading = true;
            let params = {
                seller_id: this.sellerId,
                page: this.currentPage,
                per_page: this.perPage,
                search: this.filter
            };

            axios.get(this.$apiUrl + '/products/by_seller', { params: params })
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status === 1) {
                        this.products = response.data.data.products;
                        this.totalRows = response.data.total;
                        if (response.data.data.seller) {
                            this.sellerName = response.data.data.seller.name || response.data.data.seller.store_name;
                        }
                    } else {
                        this.showError(response.data.message);
                    }
                })
                .catch((error) => {
                    this.isLoading = false;
                    if (error.response && error.response.data && error.response.data.message) {
                        this.showError(error.response.data.message);
                    } else {
                        this.showError("Something went wrong!");
                    }
                });
        },
        openLightbox(image) {
            this.lightboxSources = [image];
            this.toggler = !this.toggler;
        },
        handleClose() {
            this.lightboxSources = null;
            this.toggler = false;
        },
    }
};
</script>

<style scoped>
.th-width {
    width: 150px;
    background-color: #f8f9fa;
    font-weight: 600;
}
</style>
