<template>
  <div>
    <div class="page-heading">
      <div class="row">
        <div class="col-12 col-md-6">
          <h3>Manage Campaign Products</h3>
        </div>
        <div class="col-12 col-md-6">
          <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
            <ol class="breadcrumb">
              <li class="breadcrumb-item">
                <router-link to="/dashboard">Dashboard</router-link>
              </li>
              <li class="breadcrumb-item">
                <router-link to="/brand-campaign-products">Campaign Products</router-link>
              </li>
              <li class="breadcrumb-item active">Edit Products</li>
            </ol>
          </nav>
        </div>
      </div>
    </div>

    <div v-if="loading" class="text-center py-5">
      <div class="spinner-border" role="status"></div>
    </div>

    <div v-else>
      <!-- Campaign Info Card -->
      <div class="card mb-3">
        <div class="card-body">
          <div class="row align-items-center">
            <div class="col-md-2">
              <img :src="campaign.primary_image_url" class="img-fluid rounded" style="max-height: 100px;">
            </div>
            <div class="col-md-10">
              <h4>{{ campaign.name }}</h4>
              <p class="mb-1"><strong>Brand:</strong> {{ campaign.brand_name }}</p>
              <p class="mb-0"><strong>Current Products:</strong> {{ currentProducts.length }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Add Products Card -->
      <div class="card mb-3">
        <div class="card-header">
          <h5>Add Products to Campaign</h5>
        </div>
        <div class="card-body">
          <div class="row mb-3">
            <div class="col-12">
              <input v-model="productSearch" type="text" class="form-control mb-2" placeholder="Search available products...">
              <div class="border rounded p-3" style="max-height: 400px; overflow-y: auto;">
                <div v-for="product in filteredAvailableProducts" :key="product.id"
                     class="d-flex align-items-center p-2 mb-2 border rounded hover-product"
                     :class="{'selected-product': selectedProductIds.includes(product.id)}"
                     @click="toggleProduct(product.id)"
                     style="cursor: pointer;">
                  <input
                    type="checkbox"
                    :value="product.id"
                    v-model="selectedProductIds"
                    class="me-3"
                  >
                  <img :src="product.image_url || '/images/no-image.png'" width="50" height="50" class="me-3 rounded">
                  <div>
                    <strong>{{ product.name }}</strong>
                    <br>
                    <small class="text-muted">{{ product.category_name }}</small>
                  </div>
                </div>
                <div v-if="filteredAvailableProducts.length === 0" class="text-center text-muted py-3">
                  <span v-if="loadingProducts">Loading products...</span>
                  <span v-else>No products available to add</span>
                </div>
              </div>
              <small class="text-info mt-2 d-block">{{ selectedProductIds.length }} product(s) selected</small>
            </div>
          </div>
          <div class="row">
            <div class="col-12 text-end">
              <button @click="addSelectedProducts" class="btn btn-success" :disabled="isSubmitting || selectedProductIds.length === 0">
                <i class="fa fa-plus"></i> Add Selected Products ({{ selectedProductIds.length }})
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Current Products Card -->
      <div class="card">
        <div class="card-header d-flex justify-content-between align-items-center">
          <h5>Current Products ({{ currentProducts.length }})</h5>
          <router-link to="/brand-campaign-products" class="btn btn-secondary">
            <i class="fa fa-arrow-left"></i> Back to List
          </router-link>
        </div>
        <div class="card-body">
          <div v-if="currentProducts.length === 0" class="alert alert-info">
            No products added to this campaign yet. Use the form above to add products.
          </div>
          <div v-else class="table-responsive">
            <div class="alert alert-info mb-3">
              <i class="fa fa-info-circle"></i> Drag and drop rows to reorder products
            </div>
            <table class="table table-bordered">
              <thead>
                <tr>
                  <th width="50">Drag</th>
                  <th width="80">Image</th>
                  <th>Product Name</th>
                  <th>Category</th>
                  <th width="100">Order</th>
                  <th width="100">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="(item, index) in currentProducts"
                  :key="item.id"
                  draggable="true"
                  @dragstart="dragStart(index, $event)"
                  @dragover.prevent="dragOver(index, $event)"
                  @dragenter.prevent="dragEnter(index, $event)"
                  @dragleave="dragLeave($event)"
                  @drop="drop(index, $event)"
                  @dragend="dragEnd"
                  :class="{'dragging': draggedIndex === index, 'drag-over': dragOverIndex === index}"
                  class="draggable-row"
                >
                  <td class="text-center" style="cursor: move;">
                    <i class="fa fa-grip-vertical text-muted"></i>
                  </td>
                  <td>
                    <img :src="item.product_image_url || '/images/no-image.png'" width="50" height="50" class="rounded">
                  </td>
                  <td>{{ item.product_name }}</td>
                  <td>{{ item.category_name }}</td>
                  <td>{{ item.display_order }}</td>
                  <td>
                    <button
                      class="btn btn-sm btn-danger"
                      @click="removeProduct(index, item.id, item.product_name)"
                      v-b-tooltip.hover
                      title="Remove"
                    >
                      <i class="fa fa-trash"></i>
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
            <div class="text-end mt-2" v-if="hasOrderChanged">
              <button @click="saveOrder" class="btn btn-success" :disabled="isSavingOrder">
                <i class="fa fa-save"></i> {{ isSavingOrder ? 'Saving...' : 'Save Order' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  name: 'EditCampaignProducts',
  data() {
    return {
      loading: true,
      campaign: {},
      currentProducts: [],
      originalProductsOrder: [],
      availableProducts: [],
      selectedProductIds: [],
      productSearch: '',
      loadingProducts: false,
      isSubmitting: false,
      draggedIndex: null,
      dragOverIndex: null,
      isSavingOrder: false
    };
  },
  computed: {
    campaignId() {
      return this.$route.params.id;
    },
    filteredAvailableProducts() {
      if (!this.productSearch) return this.availableProducts;
      return this.availableProducts.filter(p =>
        p.name.toLowerCase().includes(this.productSearch.toLowerCase())
      );
    },
    hasOrderChanged() {
      if (this.currentProducts.length !== this.originalProductsOrder.length) {
        return true;
      }
      return this.currentProducts.some((product, index) =>
        product.id !== this.originalProductsOrder[index]?.id
      );
    }
  },
  mounted() {
    this.loadCampaign();
    this.loadCurrentProducts();
    this.loadAvailableProducts();
  },
  methods: {
    async loadCampaign() {
      try {
        const res = await axios.get(this.$apiUrl + '/admin/brand-campaigns/' + this.campaignId);
        if (res.data.status === 1) {
          this.campaign = res.data.data.campaign;
        }
      } catch (error) {
        console.error('Failed to load campaign:', error);
        this.showMessage('error', 'Failed to load campaign');
        this.$router.push('/brand-campaign-products');
      } finally {
        this.loading = false;
      }
    },

    async loadCurrentProducts() {
      try {
        const res = await axios.get(this.$apiUrl + '/admin/brand-campaign-products', {
          params: { campaign_id: this.campaignId }
        });
        if (res.data.status === 1) {
          this.currentProducts = res.data.data || [];
          // Store original order for comparison
          this.originalProductsOrder = JSON.parse(JSON.stringify(this.currentProducts));
        }
      } catch (error) {
        console.error('Failed to load current products:', error);
      }
    },

    async loadAvailableProducts() {
      this.loadingProducts = true;
      try {
        const res = await axios.get(this.$apiUrl + '/admin/brand-campaign-products/available-products', {
          params: { campaign_id: this.campaignId }
        });

        if (res.data.status === 1) {
          const allProducts = res.data.data.products || [];
          // Filter out products that are already in the campaign
          const currentProductIds = this.currentProducts.map(p => p.product_id);
          this.availableProducts = allProducts.filter(p => !currentProductIds.includes(p.id));
        }
      } catch (error) {
        console.error('Failed to load available products:', error);
        this.showMessage('error', 'Failed to load available products');
      } finally {
        this.loadingProducts = false;
      }
    },

    toggleProduct(productId) {
      const index = this.selectedProductIds.indexOf(productId);
      if (index > -1) {
        this.selectedProductIds.splice(index, 1);
      } else {
        this.selectedProductIds.push(productId);
      }
    },

    async addSelectedProducts() {
      if (this.selectedProductIds.length === 0) {
        this.showMessage('error', 'Please select at least one product');
        return;
      }

      this.isSubmitting = true;
      let successCount = 0;
      let failureCount = 0;

      try {
        for (const productId of this.selectedProductIds) {
          try {
            const data = {
              brand_campaign_id: this.campaignId,
              product_id: productId,
            };

            const res = await axios.post(this.$apiUrl + '/admin/brand-campaign-products', data);

            if (res.data.status === 1) {
              successCount++;
            } else {
              failureCount++;
            }
          } catch (error) {
            failureCount++;
          }
        }

        // Reload data
        await this.loadCurrentProducts();
        await this.loadAvailableProducts();

        // Clear selection
        this.selectedProductIds = [];
        this.productSearch = '';

        // Show summary message
        if (successCount > 0 && failureCount === 0) {
          this.showMessage('success', `Successfully added ${successCount} product(s)`);
        } else if (successCount > 0 && failureCount > 0) {
          this.showMessage('warning', `Added ${successCount} product(s). Failed to add ${failureCount} product(s).`);
        } else {
          this.showMessage('error', 'Failed to add products');
        }
      } catch (error) {
        console.error('Error:', error);
        this.showMessage('error', 'Failed to add products');
      } finally {
        this.isSubmitting = false;
      }
    },

    removeProduct(index, productId, productName) {
      this.$swal
        .fire({
          title: 'Are you sure?',
          text: `Remove "${productName}" from this campaign?`,
          icon: 'warning',
          showCancelButton: true,
          confirmButtonColor: '#9AC444',
          cancelButtonColor: '#d33',
          confirmButtonText: 'Yes, remove it!',
        })
        .then(async (result) => {
          if (result.isConfirmed) {
            try {
              const res = await axios.delete(this.$apiUrl + '/admin/brand-campaign-products/' + productId);

              if (res.data.status === 1) {
                this.currentProducts.splice(index, 1);
                await this.loadAvailableProducts(); // Refresh available products
                this.showMessage('success', 'Product removed successfully');
              } else {
                this.showMessage('error', res.data.message || 'Failed to remove product');
              }
            } catch (error) {
              console.error('Error:', error);
              this.showMessage('error', 'Failed to remove product');
            }
          }
        });
    },

    // Drag and Drop methods
    dragStart(index, event) {
      this.draggedIndex = index;
      event.dataTransfer.effectAllowed = 'move';
      event.target.style.opacity = '0.5';
    },

    dragOver(index, event) {
      event.dataTransfer.dropEffect = 'move';
    },

    dragEnter(index, event) {
      this.dragOverIndex = index;
    },

    dragLeave(event) {
      // Only clear if we're leaving the entire row
      if (event.target.tagName === 'TR') {
        this.dragOverIndex = null;
      }
    },

    drop(index, event) {
      event.stopPropagation();

      if (this.draggedIndex !== null && this.draggedIndex !== index) {
        // Reorder the array
        const draggedItem = this.currentProducts[this.draggedIndex];
        this.currentProducts.splice(this.draggedIndex, 1);
        this.currentProducts.splice(index, 0, draggedItem);

        // Update display_order for all items
        this.currentProducts.forEach((item, idx) => {
          item.display_order = idx;
        });
      }

      this.dragOverIndex = null;
    },

    dragEnd(event) {
      event.target.style.opacity = '1';
      this.draggedIndex = null;
      this.dragOverIndex = null;
    },

    async saveOrder() {
      this.isSavingOrder = true;

      try {
        const items = this.currentProducts.map((product, index) => ({
          id: product.id,
          display_order: index
        }));

        const res = await axios.post(this.$apiUrl + '/admin/brand-campaign-products/reorder', {
          items: items
        });

        if (res.data.status === 1) {
          this.showMessage('success', 'Product order saved successfully');
          // Update original order after successful save
          this.originalProductsOrder = JSON.parse(JSON.stringify(this.currentProducts));
        } else {
          this.showMessage('error', res.data.message || 'Failed to save order');
        }
      } catch (error) {
        console.error('Error:', error);
        this.showMessage('error', 'Failed to save product order');
      } finally {
        this.isSavingOrder = false;
      }
    }
  }
};
</script>

<style scoped>
.hover-product:hover {
  background-color: rgba(154, 196, 68, 0.1) !important;
  border-color: #9AC444 !important;
}

.selected-product {
  background-color: rgba(154, 196, 68, 0.15);
  border-color: #9AC444 !important;
}

.draggable-row {
  cursor: move;
  transition: all 0.2s;
}

.draggable-row.dragging {
  opacity: 0.5;
}

.draggable-row.drag-over {
  border-top: 3px solid #9AC444;
}

.draggable-row:hover {
  background-color: rgba(154, 196, 68, 0.08);
}
</style>