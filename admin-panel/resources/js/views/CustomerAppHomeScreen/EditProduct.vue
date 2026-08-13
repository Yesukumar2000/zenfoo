<template>
    <b-modal ref="my-modal" :title="modal_title" @hidden="$emit('modalClose')" scrollable no-close-on-backdrop no-fade static size="lg">
        <div slot="modal-footer">
            <b-button variant="primary" @click="$refs['dummy_submit'].click()" :disabled="isLoading || selectedProductIds.length === 0">
                {{ isLoading ? 'Adding...' : 'Add Products (' + selectedProductIds.length + ')' }}
                <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
            </b-button>
            <b-button variant="secondary" @click="hideModal">Cancel</b-button>
        </div>
        <form ref="my-form" @submit.prevent="saveRecord">
            <div class="row">
                <!-- Section Selection -->
                <div class="col-md-12">
                    <div class="form-group">
                        <label>Section <span class="text-danger">*</span></label>
                        <select class="form-control form-select" v-model="section_id" required>
                            <option value="">--Select Section--</option>
                            <option v-for="section in sections" :key="section.id" :value="section.id">
                                {{ section.name }}
                            </option>
                        </select>
                    </div>
                </div>

                <!-- Store Selection -->
                <div class="col-md-12">
                    <div class="form-group">
                        <label>Store <span class="text-danger">*</span></label>
                        <select class="form-control form-select" v-model="store_id" @change="onStoreChange" required>
                            <option value="">--Select Store--</option>
                            <option v-for="store in stores" :key="store.id" :value="store.id">
                                {{ store.name }}
                            </option>
                        </select>
                    </div>
                </div>

                <!-- Category Group Selection -->
                <div class="col-md-12" v-if="store_id">
                    <div class="form-group">
                        <label>Sub Category Group</label>
                        <select class="form-control form-select" v-model="category_group_id" @change="onCategoryGroupChange" :disabled="loadingCategoryGroups">
                            <option value="">{{ loadingCategoryGroups ? 'Loading...' : '--Select Sub Category Group--' }}</option>
                            <option v-for="group in categoryGroups" :key="group.id" :value="group.id">
                                {{ group.name }}
                            </option>
                        </select>
                    </div>
                </div>

                <!-- Sub Category Group Selection -->
                <div class="col-md-12" v-if="category_group_id">
                    <div class="form-group">
                        <label>Category Group</label>
                        <select class="form-control form-select" v-model="sub_category_group_id" @change="onSubCategoryGroupChange" :disabled="loadingSubCategoryGroups">
                            <option value="">{{ loadingSubCategoryGroups ? 'Loading...' : '--Select Category Group--' }}</option>
                            <option v-for="subGroup in subCategoryGroups" :key="subGroup.id" :value="subGroup.id">
                                {{ subGroup.name }}
                            </option>
                        </select>
                    </div>
                </div>

                <!-- Category Selection -->
                <div class="col-md-12" v-if="sub_category_group_id">
                    <div class="form-group">
                        <label>Category</label>
                        <select class="form-control form-select" v-model="category_id" @change="onCategoryChange" :disabled="loadingCategories">
                            <option value="">{{ loadingCategories ? 'Loading...' : '--Select Category--' }}</option>
                            <option v-for="cat in categories" :key="cat.id" :value="cat.id">
                                {{ cat.name }}
                            </option>
                        </select>
                    </div>
                </div>

                <!-- Product Selection -->
                <div class="col-md-12" v-if="category_id">
                    <div class="form-group">
                        <label>Products <span class="text-danger">*</span> (Multiple Selection)</label>
                        <input v-model="productSearch" type="text" class="form-control mb-2" placeholder="Search products..." :disabled="loadingProducts">
                        <div class="border rounded p-3" style="max-height: 400px; overflow-y: auto;">
                            <div v-if="loadingProducts" class="text-center py-3">
                                <div class="spinner-border spinner-border-sm" role="status"></div>
                                <span class="ms-2">Loading products...</span>
                            </div>
                            <div v-else-if="filteredProducts.length === 0" class="text-center text-muted py-3">
                                No products found
                            </div>
                            <div v-else v-for="product in filteredProducts" :key="product.id"
                                 class="d-flex align-items-center p-2 mb-2 border rounded hover-product"
                                 :class="{'bg-light': selectedProductIds.includes(product.id)}"
                                 @click="toggleProduct(product.id)"
                                 style="cursor: pointer;">
                                <input
                                    type="checkbox"
                                    :value="product.id"
                                    v-model="selectedProductIds"
                                    class="me-3"
                                >
                                <img v-if="product.image" :src="getProductImageUrl(product.image)" width="50" height="50" class="me-3 rounded">
                                <div v-else class="me-3" style="width: 50px; height: 50px; background: #f0f0f0; border-radius: 4px;"></div>
                                <div>
                                    <strong>{{ product.name }}</strong>
                                </div>
                            </div>
                        </div>
                        <small class="text-info mt-2 d-block">{{ selectedProductIds.length }} product(s) selected</small>
                    </div>
                </div>
            </div>
            <button type="submit" ref="dummy_submit" style="display:none"></button>
        </form>
    </b-modal>
</template>

<script>
export default {
    props: ['record'],
    data() {
        return {
            modal_title: 'Add Products to Section',
            id: null,
            section_id: '',
            selectedProductIds: [],
            productSearch: '',

            // Cascading dropdown data
            sections: [],
            stores: [],
            store_id: '',
            categoryGroups: [],
            category_group_id: '',
            subCategoryGroups: [],
            sub_category_group_id: '',
            categories: [],
            category_id: '',
            products: [],

            // Loading states
            loadingCategoryGroups: false,
            loadingSubCategoryGroups: false,
            loadingCategories: false,
            loadingProducts: false,
            isLoading: false,
        }
    },
    computed: {
        filteredProducts() {
            if (!this.productSearch) return this.products;
            return this.products.filter(p =>
                p.name.toLowerCase().includes(this.productSearch.toLowerCase())
            );
        }
    },
    mounted() {
        this.$refs['my-modal'].show();
        this.getSections();
        this.getStores();
    },
    methods: {
        hideModal() {
            this.$refs['my-modal'].hide();
        },

        getSections() {
            axios.get(this.$apiUrl + '/products/customer-app-sections', {
                params: { per_page: 1000 }
            }).then((response) => {
                this.sections = response.data.data;
            }).catch(() => {
                console.error('Failed to fetch sections');
            });
        },

        getStores() {
            axios.get(this.$apiUrl + '/get-all-stores-data')
                .then(res => {
                    this.stores = Array.isArray(res.data) ? res.data : [];
                })
                .catch(() => {
                    this.stores = [];
                });
        },

        onStoreChange() {
            this.category_group_id = '';
            this.sub_category_group_id = '';
            this.category_id = '';
            this.selectedProductIds = [];
            this.productSearch = '';
            this.categoryGroups = [];
            this.subCategoryGroups = [];
            this.categories = [];
            this.products = [];

            if (!this.store_id) return;
            this.loadCategoryGroups();
        },

        loadCategoryGroups() {
            this.loadingCategoryGroups = true;
            return axios.get(this.$apiUrl + '/get-data-based-on-store-selection', {
                params: { store_id: this.store_id }
            }).then(res => {
                this.loadingCategoryGroups = false;
                this.categoryGroups = res.data.data || [];
            }).catch(() => {
                this.loadingCategoryGroups = false;
            });
        },

        onCategoryGroupChange() {
            this.sub_category_group_id = '';
            this.category_id = '';
            this.selectedProductIds = [];
            this.productSearch = '';
            this.subCategoryGroups = [];
            this.categories = [];
            this.products = [];

            if (!this.category_group_id) return;
            this.loadSubCategoryGroups();
        },

        loadSubCategoryGroups() {
            this.loadingSubCategoryGroups = true;
            return axios.get(this.$apiUrl + '/get-data-based-on-category-selection', {
                params: { category_group_id: this.category_group_id }
            }).then(res => {
                this.loadingSubCategoryGroups = false;
                this.subCategoryGroups = res.data.data || [];
            }).catch(() => {
                this.loadingSubCategoryGroups = false;
            });
        },

        onSubCategoryGroupChange() {
            this.category_id = '';
            this.selectedProductIds = [];
            this.productSearch = '';
            this.categories = [];
            this.products = [];

            if (!this.sub_category_group_id) return;
            this.loadCategories();
        },

        loadCategories() {
            this.loadingCategories = true;
            return axios.get(this.$apiUrl + '/get-data-based-on-sub-category-selection', {
                params: { sub_category_group_id: this.sub_category_group_id }
            }).then(res => {
                this.loadingCategories = false;
                this.categories = res.data.data || [];
            }).catch(() => {
                this.loadingCategories = false;
            });
        },

        onCategoryChange() {
            this.selectedProductIds = [];
            this.productSearch = '';
            this.products = [];

            if (!this.category_id) return;
            this.loadProducts();
        },

        toggleProduct(productId) {
            const index = this.selectedProductIds.indexOf(productId);
            if (index > -1) {
                this.selectedProductIds.splice(index, 1);
            } else {
                this.selectedProductIds.push(productId);
            }
        },

        getProductImageUrl(image) {
            if (!image) return null;
            if (image.startsWith('http')) return image;
            return this.$apiUrl.replace('/api', '') + '/storage/' + image;
        },

        loadProducts() {
            this.loadingProducts = true;
            return axios.get(this.$apiUrl + '/products', {
                params: {
                    category: this.category_id,
                    section_id: this.section_id
                }
            }).then(res => {
                this.loadingProducts = false;
                let d = res.data;
                this.products = d.data?.products || d.data || [];
            }).catch(() => {
                this.loadingProducts = false;
            });
        },

        async saveRecord() {
            if (!this.section_id) {
                this.showMessage('error', 'Please select a section');
                return;
            }

            if (this.selectedProductIds.length === 0) {
                this.showMessage('error', 'Please select at least one product');
                return;
            }

            this.isLoading = true;

            let successCount = 0;
            let failureCount = 0;
            let errorMessages = [];

            try {
                // Add each selected product to the section
                for (const productId of this.selectedProductIds) {
                    try {
                        const data = {
                            product_id: productId,
                            section_id: this.section_id,
                        };

                        const res = await axios.post(this.$apiUrl + '/products/customer-app-section-products/save', data);

                        if (res.data.status === 1) {
                            successCount++;
                        } else {
                            failureCount++;
                            errorMessages.push(res.data.message || 'Failed to add product');
                        }
                    } catch (error) {
                        failureCount++;
                        const message = error.response?.data?.message || 'Failed to add product';
                        errorMessages.push(message);
                    }
                }

                // Show summary message
                if (successCount > 0 && failureCount === 0) {
                    this.showMessage('success', `Successfully added ${successCount} product(s) to section`);
                    this.$emit('recordSaved');
                    this.hideModal();
                } else if (successCount > 0 && failureCount > 0) {
                    this.showMessage('warning', `Added ${successCount} product(s). Failed to add ${failureCount} product(s). ${errorMessages[0]}`);
                    this.$emit('recordSaved');
                    this.hideModal();
                } else {
                    this.showMessage('error', `Failed to add products. ${errorMessages[0]}`);
                }
            } catch (error) {
                console.error('Error:', error);
                this.showMessage('error', 'Failed to add products to section');
            } finally {
                this.isLoading = false;
            }
        }
    }
}
</script>

<style scoped>
.form-group {
    margin-bottom: 1rem;
}

.hover-product:hover {
    background-color: #f8f9fa !important;
    border-color: #9AC444 !important;
}
</style>