<template>
    <div>
        <div v-if="isLoading && brands.length === 0" class="text-center py-5">
            <b-spinner variant="primary" label="Loading..."></b-spinner>
            <p class="mt-2">Loading brands...</p>
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
                    <h6 class="box-title">Status</h6>
                    <b-form-select
                        v-model="selectedStatus"
                        :options="statusOptions"
                        class="form-control form-select"
                        @change="onStatusChange"
                    ></b-form-select>
                </b-col>
                <b-col md="2" class="d-flex align-items-end">
                    <button type="button" class="btn btn-primary" v-b-tooltip.hover :title="__('refresh')" @click="getRecords()">
                        <i class="fa fa-refresh" aria-hidden="true"></i>
                    </button>
                </b-col>
            </b-row>

            <!-- Brands Table -->
            <div class="table-responsive">
                <b-table
                    :items="brands"
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
                        <img v-if="row.item.image_url" :src="row.item.image_url" @click="openLightbox(row.item.image_url)" alt="Brand Image" height="50" style="cursor: pointer;" />
                        <span v-else class="text-muted">No image</span>
                    </template>

                    <!-- Image Lightbox Modal -->
                    <b-modal v-model="showLightbox" hide-footer centered size="lg" title="Image Preview">
                        <div class="text-center">
                            <img :src="lightboxImage" alt="Preview" style="max-width: 100%; max-height: 80vh;" />
                        </div>
                    </b-modal>

                    <template #cell(category_ids)="row">
                        <span v-if="row.item.categories && row.item.categories.length > 0">
                            <span v-for="(cat, index) in row.item.categories" :key="cat.id" class="badge bg-light-primary me-1">
                                {{ cat.name }}
                            </span>
                        </span>
                        <span v-else class="text-muted">-</span>
                    </template>

                    <template #cell(status)="row">
                        <span class="badge bg-success" v-if="row.item.status == 1">Active</span>
                        <span class="badge bg-danger" v-else>Inactive</span>
                    </template>

                    <template #cell(created_at)="row">
                        {{ formatDate(row.item.created_at) }}
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
            <div v-if="!isLoading && brands.length === 0" class="text-center py-5">
                <i class="fa fa-tag fa-3x text-muted mb-3"></i>
                <p class="text-muted">No brands found for this seller.</p>
            </div>
        </div>
    </div>
</template>

<script>
import axios from "axios";

export default {
    name: 'SellerBrands',
    props: {
        sellerId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            fields: [
                { key: 'id', label: 'ID', sortable: true, class: 'text-center' },
                { key: 'name', label: 'Name', sortable: true, class: 'text-center' },
                { key: 'image', label: 'Image', class: 'text-center' },
                { key: 'category_ids', label: 'Categories', class: 'text-center' },
                { key: 'status', label: 'Status', class: 'text-center' },
                { key: 'created_at', label: 'Created At', class: 'text-center' },
            ],
            brands: [],
            totalRows: 0,
            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            filter: '',
            selectedStatus: null,
            isLoading: false,
            showLightbox: false,
            lightboxImage: '',
            debounceTimer: null,
            statusOptions: [
                { value: null, text: 'All' },
                { value: 1, text: 'Active' },
                { value: 0, text: 'Inactive' }
            ]
        }
    },
    created() {
        this.getRecords();
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
                page: this.currentPage,
                per_page: this.perPage,
                search: this.filter,
            };
            if (this.selectedStatus !== null) {
                params.status = this.selectedStatus;
            }

            axios.get(this.$apiUrl + '/sellers/view/' + this.sellerId + '/brands', { params: params })
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status === 1) {
                        this.brands = response.data.data.brands;
                        this.totalRows = response.data.data.total;
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
        onStatusChange() {
            this.currentPage = 1;
            this.getRecords();
        },
        openLightbox(image) {
            this.lightboxImage = image;
            this.showLightbox = true;
        },
        formatDate(date) {
            if (!date) return '-';
            return new Date(date).toLocaleDateString('en-IN', {
                year: 'numeric',
                month: 'short',
                day: 'numeric'
            });
        }
    }
};
</script>
