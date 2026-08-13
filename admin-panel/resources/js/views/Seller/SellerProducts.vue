<template>
    <div>
        <div v-if="isLoading && products.length === 0" class="text-center py-5">
            <b-spinner variant="primary" label="Loading..."></b-spinner>
            <p class="mt-2">Loading products...</p>
        </div>
        <div v-else>
            <!-- Filters -->
            <b-row class="mb-3 align-items-end">
                <b-col md="3">
                    <h6 class="box-title">{{ __('search') }}</h6>
                    <b-form-input
                        id="filter-input"
                        v-model="filter"
                        type="search"
                        :placeholder="__('search')"
                        @input="debounceSearch"
                    ></b-form-input>
                </b-col>
                <b-col md="3">
                    <h6 class="box-title">Category</h6>
                    <b-form-select
                        v-model="selectedCategory"
                        :options="categoryOptions"
                        class="form-control form-select"
                        @change="onCategoryChange"
                    ></b-form-select>
                </b-col>
                <b-col md="2" class="d-flex align-items-end">
                    <button type="button" class="btn btn-primary" v-b-tooltip.hover :title="__('refresh')" @click="getRecords()">
                        <i class="fa fa-refresh" aria-hidden="true"></i>
                    </button>
                </b-col>
                <b-col md="4" class="d-flex align-items-end justify-content-end">
                    <button type="button" class="btn btn-success" @click="showBulkUploadModal = true">
                        <i class="fa fa-upload me-1"></i> Bulk Product Upload
                    </button>
                </b-col>
            </b-row>

            <!-- Bulk Upload Modal -->
            <seller-bulk-upload-modal
                :visible.sync="showBulkUploadModal"
                :seller-id="sellerId"
                @uploaded="getRecords"
            ></seller-bulk-upload-modal>

            <!-- Products Table -->
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
                    </template>

                    <!-- Image Lightbox Modal -->
                    <b-modal v-model="showLightbox" hide-footer centered size="lg" title="Image Preview">
                        <div class="text-center">
                            <img :src="lightboxImage" alt="Preview" style="max-width: 100%; max-height: 80vh;" />
                        </div>
                    </b-modal>

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
                        <a class="btn btn-sm" @click="updateStatusProduct(row.item.product_id)">
                            <span class="primary-toggal" v-if="row.item.status == 1">
                                <i class="fa fa-toggle-on fa-2x"></i>
                            </span>
                            <span class="text-danger" v-else>
                                <i class="fa fa-toggle-off fa-2x"></i>
                            </span>
                        </a>
                    </template>

                    <template #cell(is_approved)="row">
                        <a class="btn btn-sm" @click="updateApproveProduct(row.item.product_id)">
                            <span class="primary-toggal" v-if="row.item.is_approved == 1">
                                <i class="fa fa-toggle-on fa-2x"></i>
                            </span>
                            <span class="text-danger" v-else>
                                <i class="fa fa-toggle-off fa-2x"></i>
                            </span>
                        </a>
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
                            :to="{ name: 'FoodEditProduct', params: { id: row.item.product_id }}"
                            class="btn btn-success btn-sm ms-1"
                            v-b-tooltip.hover
                            :title="__('edit')">
                            <i class="fa fa-pencil-alt"></i>
                        </router-link>
                    </template>

                </b-table>
            </div>

            <!-- Pagination -->
            <b-row>
                <b-col md="2">
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

            <!-- Empty State -->
            <div v-if="!isLoading && products.length === 0" class="text-center py-5">
                <i class="fa fa-box fa-3x text-muted mb-3"></i>
                <p class="text-muted">No products found for this seller.</p>
            </div>
        </div>
    </div>
</template>

<script>
import axios from "axios";
import SellerBulkUploadModal from "./SellerBulkUploadModal.vue";

export default {
    name: 'SellerProducts',
    components: { SellerBulkUploadModal },
    props: {
        sellerId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
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
                { key: 'status', label: 'Available', visible: true, class: 'text-center' },
                { key: 'is_approved', label: 'Approved', visible: true, class: 'text-center' },
                { key: 'actions', label: 'Actions', visible: true, class: 'text-center' }
            ],
            products: [],
            totalRows: 0,
            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            filter: '',
            selectedCategory: null,
            categories: [],
            isLoading: false,
            showLightbox: false,
            lightboxImage: '',
            debounceTimer: null,
            showBulkUploadModal: false,
        }
    },
    computed: {
        categoryOptions() {
            let options = [{ value: null, text: 'All Categories' }];
            this.categories.forEach(cat => {
                options.push({ value: cat.id, text: cat.name });
            });
            return options;
        }
    },
    created() {
        this.getRecords();
        this.fetchSellerCategories();
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
                search: this.filter,
            };
            if (this.selectedCategory) {
                params.category_id = this.selectedCategory;
            }

            axios.get(this.$apiUrl + '/products/by_seller', { params: params })
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status === 1) {
                        this.products = response.data.data.products;
                        this.totalRows = response.data.total;
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
        fetchSellerCategories() {
            axios.get(this.$apiUrl + '/sellers/view/' + this.sellerId + '/categories')
                .then(res => {
                    if (res.data.status === 1) {
                        this.categories = res.data.data || [];
                    }
                })
                .catch(() => {});
        },
        onCategoryChange() {
            this.currentPage = 1;
            this.getRecords();
        },
        openLightbox(image) {
            this.lightboxImage = image;
            this.showLightbox = true;
        },

        updateStatusProduct(id) {
            this.$swal.fire({
                title: 'Are you Sure?',
                text: 'You want to change status.',
                confirmButtonText: 'Yes, Sure',
                cancelButtonText: 'Cancel',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
            }).then(result => {
                if (result.value) {
                    this.isLoading = true;
                    axios.post(this.$apiUrl + '/products/change', { id })
                        .then(res => {
                            this.isLoading = false;
                            this.getRecords();
                            this.showMessage('success', res.data.message);
                        });
                }
            });
        },

        updateApproveProduct(id) {
            this.$swal.fire({
                title: 'Are you Sure?',
                text: 'You want to change approval status.',
                confirmButtonText: 'Yes, Sure',
                cancelButtonText: 'Cancel',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
            }).then(result => {
                if (result.value) {
                    this.isLoading = true;
                    axios.post(this.$apiUrl + '/products/change-approve', { id })
                        .then(res => {
                            this.isLoading = false;
                            this.getRecords();
                            this.showMessage('success', res.data.message);
                        });
                }
            });
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
