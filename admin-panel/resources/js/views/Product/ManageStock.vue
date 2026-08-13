<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>{{ __('stock_management') }}</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                            <li class="breadcrumb-item active" aria-current="page">{{ __('stock_management') }}</li>
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

        <!-- 🔥 FOUR DROPDOWNS HERE -->
        <div class="card mb-3 p-3">
            <div class="row">
                <!-- STORE -->
                <div class="col-md-3">
                    <label>Store</label>
                    <select v-model="selectedStore" @change="onStoreChange" class="form-control">
                        <option value="">Select Store</option>
                        <option v-for="s in stores" :key="s.id" :value="s.id">
                            {{ s.name }}
                        </option>
                    </select>
                </div>

                <!-- CATEGORY GROUP -->
                <div class="col-md-3">
                    <label>Category Group</label>
                    <select v-model="selectedCategoryGroup" @change="onCategoryGroupChange" class="form-control">
                        <option value="">Select Category Group</option>
                        <option v-for="c in categoryGroups" :key="c.id" :value="c.id">
                            {{ c.name }}
                        </option>
                    </select>
                </div>

                <!-- SUB CATEGORY GROUP -->
                <div class="col-md-3">
                    <label>Sub Category Group</label>
                    <select v-model="selectedSubCategoryGroup" @change="onSubCategoryGroupChange" class="form-control">
                        <option value="">Select Sub Category Group</option>
                        <option v-for="sub in subCategoryGroups" :key="sub.id" :value="sub.id">
                            {{ sub.name }}
                        </option>
                    </select>
                </div>

                <!-- CATEGORIES -->
                <div class="col-md-3">
                    <label>Category</label>
                    <select v-model="selectedCategory" @change="getRecords" class="form-control">
                        <option value="">Select Category</option>
                        <option v-for="cat in categories" :key="cat.id" :value="cat.id">
                            {{ cat.name }}
                        </option>
                    </select>
                </div>
            </div>
        </div>
        <!-- 🔥 END FOUR DROPDOWNS -->

        <!-- Image Lightbox Modal -->
        <b-modal v-model="showLightbox" hide-footer centered size="lg" title="Image Preview">
            <div class="text-center">
                <img :src="lightboxImage" alt="Preview" style="max-width: 100%; max-height: 80vh;" />
            </div>
        </b-modal>

        <div class="row">
            <div class="col-12 col-md-12 order-md-1 order-last">
                <div class="card">
                    <div class="card-body">
                        <b-row class="mb-2">
                            <b-col md="3" offset-md="8">
                                <h6 class="box-title">{{ __('search') }}</h6>
                                <b-form-input
                                    id="filter-input"
                                    v-model="filter"
                                    type="search"
                                    :placeholder="__('search')"
                                    @input="getRecords()"
                                ></b-form-input>
                            </b-col>
                            <b-col md="1" class="text-center">
                                <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getRecords()">
                                    <i class="fa fa-refresh" aria-hidden="true"></i>
                                </button>
                            </b-col>
                        </b-row>
                        <b-table
            :items="groupedProducts"
            :fields="fields"
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
            
            <!-- ID column -->
            <template #cell(product_variant_id)="row">
                
                {{ row.item.product_variant_id }}
               
            </template>

            <!-- Product Name column with rowspan -->
            <template #cell(name)="row">
                {{ row.item.name }}
            </template>

            <!-- Variant column -->
            <template #cell(variant)="row">
                
                {{ row.item.measurement }} 
              
            </template>

            <!-- Type column with rowspan for 'loose' type products -->
            <template #cell(type)="row">
                {{ row.item.type }}
            </template>

            <template #cell(image_url)="row">
               <img :src="row.item.image_url" alt="Image" class="img-thumbnail" width="100" @click="openLightbox(row.item.image_url)" style="cursor:pointer;" />
            </template>


            <!-- Stock column -->
            <template #cell(stock)="row">
                
                <div v-if="edit_record && edit_record.product_variant_id === row.item.product_variant_id">
                    <b-form-input
                        v-model="edit_record.stock"
                        type="number"
                        min="0"
                        @keyup.enter="updateStock(row.item.product_variant_id)"
                    ></b-form-input>
                </div>
                <div v-else>
                    {{ row.item.stock }}
                </div>
                
            </template>

            <!-- Status column -->
            <template #cell(pv_status)="row">
               
                <span v-if="row.item.pv_status == 1" class="badge bg-success">Available</span>
                <span v-else class="badge bg-danger">Sold Out</span>
              
            </template>

            <!-- Actions column -->
            <template #cell(actions)="row">
                
                <button v-if="edit_record && edit_record.product_variant_id === row.item.product_variant_id"
                    class="btn btn-sm btn-success" @click="updateStock(row.item.product_variant_id)">
                    <i class="fa fa-check"></i>
                </button>
                <button v-else class="btn btn-sm btn-primary" @click="edit_record = { ...row.item }" v-b-tooltip.hover :title="__('edit')">
                    <i class="fa fa-pencil-alt"></i>
                </button>
               
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
                                    ></b-form-select>
                                </b-form-group>
                            </b-col>
                            <b-col md="4" class="my-1" offset-md="6">
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
</template>

<script>
export default {
    data() {
        return {
            fields: [
                { key: 'product_variant_id', label: __('id'), class: 'text-center', sortable: true, sortDirection: 'desc' },
                { key: 'image_url', label: __('image'), class: 'text-center' },
                { key: 'name', label: __('name'), class: 'text-center' },
                { key: 'variant', label: __('variant'), class: 'text-center' },
                { key: 'type', label: __('type'), class: 'text-center' },
                { key: 'stock', label: __('stock'), class: 'text-center' },
                { key: 'pv_status', label: __('status'), class: 'text-center' },
                { key: 'actions', label: __('actions') }
            ],
            totalRows: 0,
            currentPage: 1,
            perPage: this.$perPage || 10,
            pageOptions: this.$pageOptions || [5, 10, 15, 20],
            sortBy: '',
            sortDesc: false,
            sortDirection: 'asc',
            filter: null,
            filterOn: ['name'],
            isLoading: false,
            products: [],
            edit_record: null,
            groupedProducts: [],
            showLightbox: false,
            lightboxImage: '',

            /* Dropdown Data */
            stores: [],
            categoryGroups: [],
            subCategoryGroups: [],
            categories: [],

            selectedStore: "",
            selectedCategoryGroup: "",
            selectedSubCategoryGroup: "",
            selectedCategory: "",


        }
    },

    created() {
        this.$eventBus.$on('recordSaved', (message) => {
            this.showMessage('success', message);
            this.getRecords();
        });
        this.getRecords();

        this.loadDropdownData();

    },
    watch: {
         currentPage() {
            this.getRecords();
        },
        perPage() {
            this.getRecords();
        }
    },
    methods: {
        openLightbox(image) {
            this.lightboxImage = image;
            this.showLightbox = true;
        },

        loadDropdownData() {
            axios
                .get(this.$apiUrl + '/get-all-four-dropdowns')
                .then(res => {
                    const d = res.data.store_data;

                    this.stores = d.stores;
                });
        },

        onStoreChange() {
            this.categoryGroups = [];
            this.subCategoryGroups = [];
            this.categories = [];

            this.selectedCategoryGroup = "";
            this.selectedSubCategoryGroup = "";
            this.selectedCategory = "";

            axios.get(this.$apiUrl + '/get-all-four-dropdowns', {
                params: { store_id: this.selectedStore }
            }).then(res => {
                const d = res.data.store_data;
                this.categoryGroups = d.categories_data;

                this.getRecords(); // 🔥 NEW
            });
        },

        onCategoryGroupChange() {
            this.subCategoryGroups = [];
            this.categories = [];

            this.selectedSubCategoryGroup = "";
            this.selectedCategory = "";

            axios.get(this.$apiUrl + '/get-all-four-dropdowns', {
                params: {
                    store_id: this.selectedStore,
                    category_group_id: this.selectedCategoryGroup
                }
            }).then(res => {
                const d = res.data.store_data;

                this.subCategoryGroups = d.sub_category_groups_data;

                this.getRecords(); // 🔥 NEW
            });
        },


        onSubCategoryGroupChange() {
            this.categories = [];
            this.selectedCategory = "";

            axios.get(this.$apiUrl + '/get-all-four-dropdowns', {
                params: {
                    store_id: this.selectedStore,
                    category_group_id: this.selectedCategoryGroup,
                    sub_category_group_id: this.selectedSubCategoryGroup
                }
            }).then(res => {
                const d = res.data.store_data;

                this.categories = d.categories;

                this.getRecords(); // 🔥 NEW
            });
        },


        getRecords() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/products/get_product_variants', {
                params: {
                    page: this.currentPage,
                    per_page: this.perPage,
                    filter: this.filter,

                    store_id: this.selectedStore,
                    category_group_id: this.selectedCategoryGroup,
                    sub_category_group_id: this.selectedSubCategoryGroup,
                    category_id: this.selectedCategory,

                }
            }).then((response) => {
                this.isLoading = false;
                const data = response.data.data;
                this.groupedProducts = data;
                this.totalRows = response.data.total;
            }).catch(() => {
                this.isLoading = false;
            });
        },
        updateStock(product_variant_id) {
            if (this.edit_record.stock < 0) {
                this.showMessage('error', __('stock_must_be_positive'));
                return;
            }
            this.isLoading = true;
            axios.post(this.$apiUrl + '/products/update_variant_stock', {
                id: product_variant_id,
                stock: this.edit_record.stock
            }).then((response) => {
                this.isLoading = false;
                if (response.data.status === 1) {
                this.showMessage('success', response.data.message);
                this.getRecords(); // Refresh data after updating stock
                }else{
                    this.showMessage('error', response.data.message);
                }
                this.edit_record = null; // Reset edit state
               
            }).catch(() => {
                this.isLoading = false;
                this.showMessage('error', __('update_failed'));
            });
        }
    }
};
</script>
