<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>Pre Order Items</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">Pre Order Items</li>
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

            <!-- Products Section -->
            <section class="section">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h4 class="card-title mb-0">Pre-Order Items ({{ selectedCount }})</h4>
                        <button class="btn btn-primary" @click="goToAddItems">
                            <i class="fa fa-plus me-1"></i>
                            Add Items
                        </button>
                    </div>
                    <div class="card-body">
                        <div v-if="isLoading" class="text-center py-5">
                            <b-spinner></b-spinner>
                            <p class="mt-2">Loading products...</p>
                        </div>

                        <div v-else-if="preOrderProductsList.length > 0">
                            <!-- Products Table -->
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <thead>
                                        <tr>
                                            <th width="50">#</th>
                                            <th>Image</th>
                                            <th>Product Name</th>
                                            <th>Store</th>
                                            <th>Category</th>
                                            <th width="100">Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="(p, index) in paginatedPreOrderProducts" :key="p.id">
                                            <td>{{ (currentPage - 1) * perPage + index + 1 }}</td>
                                            <td>
                                                <img :src="p.image_url" width="40" height="40" class="rounded" style="object-fit: cover;" />
                                            </td>
                                            <td>{{ p.name }}</td>
                                            <td>{{ getStoreName(p.store_id) }}</td>
                                            <td>{{ p.category_name || 'N/A' }}</td>
                                            <td>
                                                <button class="btn btn-sm btn-danger" @click="removePreOrderItem(p.id)" :disabled="isSaving">
                                                    <i class="fa fa-trash"></i>
                                                </button>
                                            </td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>

                            <!-- Pagination -->
                            <div class="d-flex justify-content-between align-items-center mt-3">
                                <div>
                                    <small>Showing {{ startIndex + 1 }} - {{ endIndex }} of {{ preOrderProductsList.length }}</small>
                                </div>
                                <b-pagination
                                    v-model="currentPage"
                                    :total-rows="preOrderProductsList.length"
                                    :per-page="perPage"
                                    aria-controls="products-table"
                                    class="mb-0"
                                ></b-pagination>
                            </div>
                        </div>

                        <div v-else class="text-center py-5">
                            <i class="fa fa-inbox fa-3x mb-3 text-muted"></i>
                            <p class="text-muted">No pre-order items found.</p>
                            <button class="btn btn-primary mt-2" @click="goToAddItems">
                                <i class="fa fa-plus me-1"></i>
                                Add Items
                            </button>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    </div>
</template>

<script>
import axios from 'axios';

export default {
    name: 'PreOrderItems',
    data() {
        return {
            store_id: '',
            stores: [],
            products: [],
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
            return this.stores.filter((store) => store.managed_by_admin === true);
        },
        preOrderProductsList() {
            // Return only products that are marked as pre-order items
            return this.products.filter(p => p.is_pre_order_item == 1);
        },
        paginatedPreOrderProducts() {
            const start = (this.currentPage - 1) * this.perPage;
            const end = start + this.perPage;
            this.startIndex = start;
            this.endIndex = Math.min(end, this.preOrderProductsList.length);
            return this.preOrderProductsList.slice(start, end);
        },
        selectedCount() {
            return this.preOrderProductsList.length;
        }
    },
    mounted() {
        this.loadStores();
        this.loadAllPreOrderItems();
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

        loadAllPreOrderItems() {
            this.isLoading = true;

            axios.get(`${this.$apiUrl}/pre-order-items/all`)
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
                })
                .catch((err) => {
                    console.error('Failed to load pre-order items:', err);
                    this.showMessage('error', 'Failed to load pre-order items');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        },

        goToAddItems() {
            this.$router.push('/preorder-items/add');
        },

        async removePreOrderItem(productId) {
            const confirm = await this.$swal.fire({
                title: 'Remove from Pre-Order?',
                text: 'This product will no longer be a pre-order item.',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#d33',
                cancelButtonColor: '#3085d6',
                confirmButtonText: 'Yes, remove it',
                cancelButtonText: 'Cancel'
            });

            if (!confirm.isConfirmed) return;

            this.isSaving = true;

            // Find the product to get its store_id
            const product = this.products.find(p => p.id === productId);
            if (!product) {
                this.showMessage('error', 'Product not found');
                this.isSaving = false;
                return;
            }

            // Get all pre-order product IDs from the same store, excluding the one to remove
            const remainingProductIds = this.products
                .filter(p => p.is_pre_order_item == 1 && p.store_id === product.store_id && p.id !== productId)
                .map(p => p.id);

            const payload = {
                product_ids: remainingProductIds,
                store_ids: [product.store_id]
            };

            axios.post(`${this.$apiUrl}/pre-order-items/save`, payload)
                .then((res) => {
                    if (res.data.status === 1) {
                        this.showMessage('success', 'Product removed from pre-order items');
                        this.loadAllPreOrderItems();
                    } else {
                        this.showMessage('error', res.data.message || 'Failed to remove item');
                    }
                })
                .catch((err) => {
                    console.error('Error removing item:', err);
                    this.showMessage('error', 'Error removing item');
                })
                .finally(() => {
                    this.isSaving = false;
                });
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

.table-success {
    background-color: rgba(40, 167, 69, 0.1);
}
</style>
