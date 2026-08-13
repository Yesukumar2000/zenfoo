<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>Add Pre Order Items</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item"><router-link to="/preorder-items">Pre Order Items</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">Add Items</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/preorder-items" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <section class="section">
                <div class="card">
                    <div class="card-body">
                        <!-- Filters Row -->
                        <div class="row mb-3">
                            <b-col md="3">
                                <h6 class="box-title">Store</h6>
                                <select v-model="store_id" @change="onStoreChange" class="form-control form-select">
                                    <option value="">Select Store</option>
                                    <option v-for="store in filteredStores" :key="store.id" :value="store.id">
                                        {{ store.name }}
                                    </option>
                                </select>
                            </b-col>

                            <b-col md="3">
                                <h6 class="box-title">Category Group</h6>
                                <select v-model="selectedCategoryGroup" @change="onCategoryGroupChange" class="form-control form-select" :disabled="!store_id">
                                    <option value="">All Category Groups</option>
                                    <option v-for="c in categoryGroups" :key="c.id" :value="c.id">
                                        {{ c.name }}
                                    </option>
                                </select>
                            </b-col>

                            <b-col md="3">
                                <h6 class="box-title">Sub Category Group</h6>
                                <select v-model="selectedSubCategoryGroup" @change="onSubCategoryGroupChange" class="form-control form-select" :disabled="!selectedCategoryGroup">
                                    <option value="">All Sub Category Groups</option>
                                    <option v-for="sub in subCategoryGroups" :key="sub.id" :value="sub.id">
                                        {{ sub.name }}
                                    </option>
                                </select>
                            </b-col>

                            <b-col md="3">
                                <h6 class="box-title">Category</h6>
                                <select v-model="selectedCategory" @change="onCategoryChange" class="form-control form-select" :disabled="!selectedSubCategoryGroup">
                                    <option value="">All Categories</option>
                                    <option v-for="cat in categories" :key="cat.id" :value="cat.id">
                                        {{ cat.name }}
                                    </option>
                                </select>
                            </b-col>
                        </div>

                        <!-- Search and Actions Row -->
                        <div class="row mb-3" v-if="products.length > 0">
                            <b-col md="6">
                                <h6 class="box-title">Search</h6>
                                <b-form-input
                                    v-model="search"
                                    type="search"
                                    placeholder="Search products..."
                                ></b-form-input>
                            </b-col>

                            <b-col md="6" class="text-end">
                                <h6 class="box-title">&nbsp;</h6>
                                <button class="btn btn-success me-2" @click="savePreOrderItems" :disabled="isSaving || !store_id || selectedProducts.length === 0">
                                    <b-spinner v-if="isSaving" small class="me-1"></b-spinner>
                                    <i v-else class="fa fa-save me-1"></i>
                                    Save ({{ selectedProducts.length }})
                                </button>
                                <button class="btn btn-secondary" @click="goBack">
                                    <i class="fa fa-arrow-left me-1"></i>
                                    Back
                                </button>
                            </b-col>
                        </div>
                    </div>
                </div>
            </section>

            <!-- Products Section -->
            <section class="section" v-if="store_id">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h4 class="card-title mb-0">Products ({{ filteredProducts.length }})</h4>
                        <span class="badge bg-primary" v-if="selectedProducts.length > 0">
                            {{ selectedProducts.length }} Selected
                        </span>
                    </div>
                    <div class="card-body">
                        <div v-if="isLoading" class="text-center py-5">
                            <b-spinner></b-spinner>
                            <p class="mt-2">Loading products...</p>
                        </div>

                        <div v-else-if="filteredProducts.length > 0">
                            <!-- Products Table -->
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <thead>
                                        <tr>
                                            <th width="50">
                                                <input
                                                    type="checkbox"
                                                    @change="toggleSelectAll"
                                                    :checked="allSelected"
                                                    class="form-check-input"
                                                />
                                            </th>
                                            <th>Image</th>
                                            <th>Product Name</th>
                                            <th>Store</th>
                                            <th>Category</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="p in paginatedProducts" :key="p.id" :class="{ 'table-primary': selectedProducts.includes(p.id) }">
                                            <td>
                                                <input
                                                    type="checkbox"
                                                    :value="p.id"
                                                    :checked="selectedProducts.includes(p.id)"
                                                    @change="toggleProduct(p.id, $event)"
                                                    class="form-check-input"
                                                />
                                            </td>
                                            <td>
                                                <img :src="p.image_url" width="40" height="40" class="rounded" style="object-fit: cover;" />
                                            </td>
                                            <td>{{ p.name }}</td>
                                            <td>{{ getStoreName(p.store_id) }}</td>
                                            <td>{{ p.category_name || 'N/A' }}</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>

                            <!-- Pagination -->
                            <div class="d-flex justify-content-between align-items-center mt-3">
                                <div>
                                    <small>Showing {{ startIndex + 1 }} - {{ endIndex }} of {{ filteredProducts.length }}</small>
                                </div>
                                <b-pagination
                                    v-model="currentPage"
                                    :total-rows="filteredProducts.length"
                                    :per-page="perPage"
                                    aria-controls="products-table"
                                    class="mb-0"
                                ></b-pagination>
                            </div>
                        </div>

                        <div v-else class="text-center py-5">
                            <i class="fa fa-inbox fa-3x mb-3 text-muted"></i>
                            <p class="text-muted">No products found for the selected filters.</p>
                        </div>
                    </div>
                </div>
            </section>

            <section class="section" v-else>
                <div class="card">
                    <div class="card-body text-center py-5">
                        <i class="fa fa-store fa-3x mb-3 text-muted"></i>
                        <p class="text-muted">Please select a store to view products.</p>
                    </div>
                </div>
            </section>
        </div>
    </div>
</template>

<script>
import axios from 'axios';

export default {
    name: 'AddPreOrderItems',
    data() {
        return {
            search: '',
            store_id: '',
            stores: [],
            products: [],
            selectedProducts: [],
            existingPreOrderItems: [],
            currentPage: 1,
            perPage: 20,
            isLoading: false,
            isSaving: false,

            categoryGroups: [],
            subCategoryGroups: [],
            categories: [],
            selectedCategoryGroup: '',
            selectedSubCategoryGroup: '',
            selectedCategory: '',

            startIndex: 0,
            endIndex: 0
        }
    },
    computed: {
        filteredStores() {
            return this.stores.filter((store) => store.managed_by_admin === true || store.is_meat === true);
        },
        filteredProducts() {
            let products = this.products;
            if (this.search) {
                products = products.filter((p) =>
                    p.name.toLowerCase().includes(this.search.toLowerCase())
                );
            }
            return products;
        },
        paginatedProducts() {
            const start = (this.currentPage - 1) * this.perPage;
            const end = start + this.perPage;
            this.startIndex = start;
            this.endIndex = Math.min(end, this.filteredProducts.length);
            return this.filteredProducts.slice(start, end);
        },
        allSelected() {
            return this.filteredProducts.length > 0 &&
                   this.filteredProducts.every(p => this.selectedProducts.includes(p.id));
        }
    },
    mounted() {
        this.loadStores();

        // Pre-select store if passed via query parameter
        if (this.$route.query.store_id) {
            this.store_id = this.$route.query.store_id;
            this.onStoreChange();
        }
    },
    methods: {
        loadStores() {
            axios.get(`${this.$apiUrl}/get-all-stores-data`)
                .then((res) => {
                    this.stores = res.data || [];
                })
                .catch((err) => {
                    console.error('Failed to load stores:', err);
                });
        },

        onStoreChange() {
            this.resetFilters();
            if (this.store_id) {
                this.loadCategoryGroups();
                this.loadProducts();
            } else {
                this.products = [];
                this.selectedProducts = [];
            }
        },

        resetFilters() {
            this.categoryGroups = [];
            this.subCategoryGroups = [];
            this.categories = [];
            this.selectedCategoryGroup = '';
            this.selectedSubCategoryGroup = '';
            this.selectedCategory = '';
            this.currentPage = 1;
        },

        loadCategoryGroups() {
            axios.get(`${this.$apiUrl}/get-all-four-dropdowns`, {
                params: { store_id: this.store_id }
            }).then((res) => {
                const d = res.data.store_data;
                this.categoryGroups = d.categories_data || [];
            }).catch((err) => {
                console.error('Failed to load category groups:', err);
            });
        },

        onCategoryGroupChange() {
            this.subCategoryGroups = [];
            this.categories = [];
            this.selectedSubCategoryGroup = '';
            this.selectedCategory = '';

            if (!this.selectedCategoryGroup) {
                this.loadProducts();
                return;
            }

            axios.get(`${this.$apiUrl}/get-all-four-dropdowns`, {
                params: {
                    store_id: this.store_id,
                    category_group_id: this.selectedCategoryGroup
                }
            }).then((res) => {
                const d = res.data.store_data;
                this.subCategoryGroups = d.sub_category_groups_data || [];
                this.loadProducts();
            });
        },

        onSubCategoryGroupChange() {
            this.categories = [];
            this.selectedCategory = '';

            if (!this.selectedSubCategoryGroup) {
                this.loadProducts();
                return;
            }

            axios.get(`${this.$apiUrl}/get-all-four-dropdowns`, {
                params: {
                    store_id: this.store_id,
                    category_group_id: this.selectedCategoryGroup,
                    sub_category_group_id: this.selectedSubCategoryGroup
                }
            }).then((res) => {
                const d = res.data.store_data;
                this.categories = d.categories || [];
                this.loadProducts();
            });
        },

        onCategoryChange() {
            this.loadProducts();
        },

        loadProducts() {
            if (!this.store_id) return;

            this.isLoading = true;
            const params = { store_ids: this.store_id };

            if (this.selectedCategoryGroup) {
                params.category_group_id = this.selectedCategoryGroup;
            }
            if (this.selectedSubCategoryGroup) {
                params.sub_category_group_id = this.selectedSubCategoryGroup;
            }
            if (this.selectedCategory) {
                params.category_id = this.selectedCategory;
            }

            axios.get(`${this.$apiUrl}/pre-order-items/products`, { params })
                .then((res) => {
                    this.products = res.data.products || [];

                    this.products.forEach((p) => {
                        if (!p.image_url) {
                            if (p.image) {
                                p.image_url = p.image.startsWith('http') ? p.image : `${this.$baseUrl}/storage/${p.image}`;
                            } else {
                                p.image_url = '/images/no-image.png';
                            }
                        }
                    });

                    // Store existing pre-order items
                    this.existingPreOrderItems = this.products
                        .filter(p => p.is_pre_order_item == 1)
                        .map(p => p.id);

                    // Pre-select existing pre-order items
                    this.selectedProducts = [...new Set([...this.selectedProducts, ...this.existingPreOrderItems])];
                })
                .catch((err) => {
                    console.error('Failed to load products:', err);
                    this.showMessage('error', 'Failed to load products');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        },

        toggleProduct(productId, event) {
            const isChecked = event.target.checked;

            if (isChecked) {
                if (!this.selectedProducts.includes(productId)) {
                    this.selectedProducts.push(productId);
                }
            } else {
                const index = this.selectedProducts.indexOf(productId);
                if (index > -1) {
                    this.selectedProducts.splice(index, 1);
                }
            }
        },

        toggleSelectAll(event) {
            if (event.target.checked) {
                this.selectedProducts = [...new Set([...this.selectedProducts, ...this.filteredProducts.map(p => p.id)])];
            } else {
                const filteredIds = this.filteredProducts.map(p => p.id);
                this.selectedProducts = this.selectedProducts.filter(id => !filteredIds.includes(id));
            }
        },

        savePreOrderItems() {
            if (!this.store_id) {
                this.showMessage('error', 'Please select a store');
                return;
            }

            if (this.selectedProducts.length === 0) {
                this.showMessage('error', 'Please select at least one product');
                return;
            }

            this.isSaving = true;

            const payload = {
                product_ids: this.selectedProducts,
                store_ids: [this.store_id]
            };

            axios.post(`${this.$apiUrl}/pre-order-items/save`, payload)
                .then((res) => {
                    if (res.data.status === 1) {
                        this.showMessage('success', res.data.message || 'Pre-order items added successfully');
                        this.$router.push('/preorder-items');
                    } else {
                        this.showMessage('error', res.data.message || 'Failed to save pre-order items');
                    }
                })
                .catch((err) => {
                    console.error('Error saving pre-order items:', err);
                    this.showMessage('error', err.response?.data?.message || 'Error saving pre-order items');
                })
                .finally(() => {
                    this.isSaving = false;
                });
        },

        goBack() {
            this.$router.push('/preorder-items');
        },

        getStoreName(storeId) {
            const store = this.stores.find(s => s.id === storeId);
            return store ? store.name : 'Unknown';
        }
    }
}
</script>

<style scoped>
.box-title {
    font-size: 0.875rem;
    font-weight: 600;
    margin-bottom: 0.5rem;
}

.table-primary {
    background-color: rgba(13, 110, 253, 0.1);
}
</style>
