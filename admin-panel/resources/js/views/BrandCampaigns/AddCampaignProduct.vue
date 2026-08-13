<template>
  <div>
    <div class="page-heading">
      <div class="row">
        <div class="col-12 col-md-6">
          <h3>Add Product to Campaign</h3>
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
              <li class="breadcrumb-item active">Add Product</li>
            </ol>
          </nav>
        </div>
      </div>
    </div>

    <div class="mb-3">
      <router-link to="/brand-campaign-products" class="btn btn-secondary btn-sm">
        <i class="fa fa-arrow-left me-1"></i> Back to List
      </router-link>
    </div>

    <div class="card">
      <div class="card-body">
        <form @submit.prevent="submitForm">
          <!-- Campaign Selection -->
          <div class="row mb-3">
            <div class="col-12">
              <label>Select Campaign *</label>
              <select v-model="selectedCampaignId" @change="onCampaignChange" class="form-control" required>
                <option value="">-- Select Campaign --</option>
                <option v-for="campaign in campaigns" :key="campaign.id" :value="campaign.id">
                  {{ campaign.name }} ({{ campaign.brand_name }})
                </option>
              </select>
            </div>
          </div>

          <!-- Product Selection -->
          <div class="row mb-3" v-if="selectedCampaignId && availableProducts.length > 0">
            <div class="col-12">
              <label>Select Products * (Multiple Selection)</label>
              <input v-model="productSearch" type="text" class="form-control mb-2" placeholder="Search products...">
              <div class="border rounded p-3" style="max-height: 400px; overflow-y: auto;">
                <div v-for="product in filteredProducts" :key="product.id"
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
                  <img :src="product.image_url || '/images/no-image.png'" width="50" height="50" class="me-3 rounded">
                  <div>
                    <strong>{{ product.name }}</strong>
                    <br>
                    <small class="text-muted">{{ product.category_name }}</small>
                  </div>
                </div>
                <div v-if="filteredProducts.length === 0" class="text-center text-muted py-3">
                  No products found
                </div>
              </div>
              <small class="text-info mt-2 d-block">{{ selectedProductIds.length }} product(s) selected</small>
            </div>
          </div>

          <!-- No Products Message -->
          <div class="row mb-3" v-if="selectedCampaignId && availableProducts.length === 0 && !loadingProducts">
            <div class="col-12">
              <div class="alert alert-warning">
                No products available for this campaign's brand. Please ensure the brand has products added.
              </div>
            </div>
          </div>

          <!-- Loading Products -->
          <div class="row mb-3" v-if="loadingProducts">
            <div class="col-12 text-center py-4">
              <div class="spinner-border" role="status"></div>
              <p class="mt-2">Loading products...</p>
            </div>
          </div>

          <!-- Submit -->
          <div class="row">
            <div class="col-12 text-end">
              <router-link to="/brand-campaign-products" class="btn btn-secondary me-2">Cancel</router-link>
              <button type="submit" class="btn btn-primary" :disabled="isSubmitting || selectedProductIds.length === 0">
                {{ isSubmitting ? 'Adding...' : 'Add Products to Campaign (' + selectedProductIds.length + ')' }}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  name: 'AddCampaignProduct',
  data() {
    return {
      campaigns: [],
      availableProducts: [],
      selectedCampaignId: '',
      selectedProductIds: [],
      productSearch: '',
      loadingProducts: false,
      isSubmitting: false
    };
  },
  computed: {
    filteredProducts() {
      if (!this.productSearch) return this.availableProducts;
      return this.availableProducts.filter(p =>
        p.name.toLowerCase().includes(this.productSearch.toLowerCase())
      );
    }
  },
  mounted() {
    this.loadCampaigns();
  },
  methods: {
    async loadCampaigns() {
      try {
        const res = await axios.get(this.$apiUrl + '/admin/brand-campaigns');
        if (res.data.status === 1) {
          this.campaigns = res.data.data || [];
        }
      } catch (error) {
        console.error('Failed to load campaigns:', error);
        this.showMessage('error', 'Failed to load campaigns');
      }
    },

    async onCampaignChange() {
      this.availableProducts = [];
      this.selectedProductIds = [];
      this.productSearch = '';

      if (!this.selectedCampaignId) return;

      this.loadingProducts = true;

      try {
        const res = await axios.get(this.$apiUrl + '/admin/brand-campaign-products/available-products', {
          params: { campaign_id: this.selectedCampaignId }
        });

        if (res.data.status === 1) {
          this.availableProducts = res.data.data.products || [];
        } else {
          this.showMessage('error', res.data.message || 'Failed to load products');
        }
      } catch (error) {
        console.error('Failed to load products:', error);
        this.showMessage('error', 'Failed to load products for this campaign');
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

    async submitForm() {
      if (!this.selectedCampaignId) {
        this.showMessage('error', 'Please select a campaign');
        return;
      }

      if (this.selectedProductIds.length === 0) {
        this.showMessage('error', 'Please select at least one product');
        return;
      }

      this.isSubmitting = true;

      let successCount = 0;
      let failureCount = 0;
      let errorMessages = [];

      try {
        // Add each selected product to the campaign
        for (const productId of this.selectedProductIds) {
          try {
            const data = {
              brand_campaign_id: this.selectedCampaignId,
              product_id: productId,
            };

            const res = await axios.post(this.$apiUrl + '/admin/brand-campaign-products', data);

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
          this.showMessage('success', `Successfully added ${successCount} product(s) to campaign`);
          this.$router.push('/brand-campaign-products');
        } else if (successCount > 0 && failureCount > 0) {
          this.showMessage('warning', `Added ${successCount} product(s). Failed to add ${failureCount} product(s). ${errorMessages[0]}`);
          this.$router.push('/brand-campaign-products');
        } else {
          this.showMessage('error', `Failed to add products. ${errorMessages[0]}`);
        }
      } catch (error) {
        console.error('Error:', error);
        this.showMessage('error', 'Failed to add products to campaign');
      } finally {
        this.isSubmitting = false;
      }
    }
  }
};
</script>

<style scoped>
.hover-product:hover {
  background-color: #f8f9fa !important;
  border-color: #9AC444 !important;
}
</style>