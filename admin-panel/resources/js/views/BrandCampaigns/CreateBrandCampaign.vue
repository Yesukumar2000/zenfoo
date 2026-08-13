<template>
  <div>
    <div class="page-heading">
      <div class="row">
        <div class="col-12 col-md-6">
          <h3>Create Brand Campaign</h3>
        </div>
        <div class="col-12 col-md-6">
          <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
            <ol class="breadcrumb">
              <li class="breadcrumb-item">
                <router-link to="/dashboard">Dashboard</router-link>
              </li>
              <li class="breadcrumb-item">
                <router-link to="/brand-campaigns">Campaigns</router-link>
              </li>
              <li class="breadcrumb-item active">Create</li>
            </ol>
          </nav>
        </div>
      </div>
    </div>

    <div class="mb-3">
      <router-link to="/brand-campaigns" class="btn btn-secondary btn-sm">
        <i class="fa fa-arrow-left me-1"></i> Back to List
      </router-link>
    </div>

    <div class="card">
      <div class="card-body">
        <form @submit.prevent="submitForm">
          <!-- Basic Info -->
          <div class="row">
            <div class="col-md-12 mb-3">
              <label>Campaign Name *</label>
              <input v-model="form.name" type="text" class="form-control" required>
            </div>

            <div class="col-md-12 mb-3">
              <label>Description</label>
              <textarea v-model="form.description" class="form-control" rows="3"></textarea>
            </div>

            <div class="col-md-12 mb-3">
              <label>Theme Color</label>
              <input v-model="form.theme_color" type="color" class="form-control">
            </div>
          </div>

          <!-- Store Selection -->
          <div class="row mb-3">
            <div class="col-12">
              <label>Store *</label>
              <select v-model="selectedStoreId" @change="onStoreChange" class="form-control" required>
                <option value="">Select Store</option>
                <option v-for="store in stores" :key="store.id" :value="store.id">
                  {{ store.name }}
                </option>
              </select>
            </div>
          </div>

          <!-- Brand Selection -->
          <div class="row mb-3" v-if="selectedStoreId">
            <div class="col-12">
              <label>Brand *</label>
              <select v-model="form.brand_id" class="form-control" required>
                <option value="">Select Brand</option>
                <option v-for="brand in brands" :key="brand.id" :value="brand.id">
                  {{ brand.name }}
                </option>
              </select>
              <small class="text-info">Products will be added separately after creating the campaign</small>
            </div>
          </div>

          <!-- Images -->
          <div class="row mb-3">
            <div class="col-md-6">
              <label>Primary Image * (Max 5MB)</label>
              <input
                type="file"
                ref="primaryImage"
                @change="onPrimaryImageChange"
                accept="image/*"
                class="form-control"
                required
              >
              <img v-if="primaryPreview" :src="primaryPreview" class="mt-2" height="100">
            </div>

            <div class="col-md-6">
              <label>Secondary Image (Max 5MB)</label>
              <input
                type="file"
                ref="secondaryImage"
                @change="onSecondaryImageChange"
                accept="image/*"
                class="form-control"
              >
              <img v-if="secondaryPreview" :src="secondaryPreview" class="mt-2" height="100">
            </div>
          </div>

          <!-- Banners -->
          <div class="row mb-3">
            <div class="col-12">
              <label>Banners (Unlimited, each max 100MB)</label>
              <input
                type="file"
                ref="banners"
                @change="onBannersChange"
                accept="image/*,video/*"
                multiple
                class="form-control"
              >
              <small class="text-muted">You can select multiple images or videos</small>
              <div v-if="bannerPreviews.length > 0" class="mt-2">
                <div v-for="(preview, index) in bannerPreviews" :key="index" class="d-inline-block me-2 mb-2">
                  <img v-if="preview.type === 'image'" :src="preview.url" height="80" class="rounded">
                  <video v-else :src="preview.url" height="80" class="rounded"></video>
                </div>
              </div>
            </div>
          </div>

          <!-- Dates -->
          <div class="row mb-3">
            <div class="col-md-6">
              <label>Start Date *</label>
              <input v-model="form.start_date" type="datetime-local" class="form-control" required>
            </div>

            <div class="col-md-6">
              <label>End Date *</label>
              <input v-model="form.end_date" type="datetime-local" class="form-control" required>
            </div>
          </div>

          <!-- Campaign Type & Status -->
          <div class="row mb-3">
            <!-- Campaign Type - Commented out, default to brand_promotion -->
            <!-- <div class="col-md-6">
              <label>Campaign Type *</label>
              <select v-model="form.campaign_type" class="form-control" required>
                <option value="brand_promotion">Brand Promotion</option>
                <option value="seasonal">Seasonal</option>
                <option value="flash_sale">Flash Sale</option>
                <option value="bundle_offer">Bundle Offer</option>
              </select>
            </div> -->

            <div class="col-md-12">
              <label>Status *</label>
              <select v-model="form.status" class="form-control" required>
                <option :value="1">Active</option>
                <option :value="0">Inactive</option>
              </select>
            </div>
          </div>

          <!-- Submit -->
          <div class="row">
            <div class="col-12 text-end">
              <router-link to="/brand-campaigns" class="btn btn-secondary me-2">Cancel</router-link>
              <button type="submit" class="btn btn-primary" :disabled="isSubmitting">
                {{ isSubmitting ? 'Creating...' : 'Create Campaign' }}
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
  name: 'CreateBrandCampaign',
  data() {
    return {
      form: {
        name: '',
        description: '',
        brand_id: '',
        start_date: '',
        end_date: '',
        status: 1,
        campaign_type: 'brand_promotion', // Default to brand_promotion
        theme_color: '#000000'
      },
      stores: [],
      brands: [],
      selectedStoreId: '',
      primaryPreview: null,
      secondaryPreview: null,
      bannerPreviews: [],
      isSubmitting: false
    };
  },
  mounted() {
    this.loadStores();
  },
  methods: {
    async loadStores() {
      try {
        const res = await axios.get(this.$apiUrl + '/get-all-stores-data');
        this.stores = res.data || [];
      } catch (error) {
        console.error('Failed to load stores:', error);
      }
    },

    async onStoreChange() {
      this.brands = [];
      this.form.brand_id = '';

      if (!this.selectedStoreId) return;

      try {
        const res = await axios.get(this.$apiUrl + '/get-all-four-dropdowns', {
          params: { store_id: this.selectedStoreId }
        });
        this.brands = res.data.store_data.brands || [];
      } catch (error) {
        console.error('Failed to load brands:', error);
      }
    },

    onPrimaryImageChange(e) {
      const file = e.target.files[0];
      if (file) {
        this.primaryPreview = URL.createObjectURL(file);
      }
    },

    onSecondaryImageChange(e) {
      const file = e.target.files[0];
      if (file) {
        this.secondaryPreview = URL.createObjectURL(file);
      }
    },

    onBannersChange(e) {
      const files = Array.from(e.target.files);
      this.bannerPreviews = files.map(file => ({
        type: file.type.startsWith('video/') ? 'video' : 'image',
        url: URL.createObjectURL(file)
      }));
    },

    async submitForm() {
      if (!this.selectedStoreId) {
        this.showMessage('error', 'Please select a store');
        return;
      }

      if (!this.form.brand_id) {
        this.showMessage('error', 'Please select a brand');
        return;
      }

      if (!this.$refs.primaryImage.files[0]) {
        this.showMessage('error', 'Primary image is required');
        return;
      }

      this.isSubmitting = true;

      const formData = new FormData();
      formData.append('name', this.form.name);
      formData.append('description', this.form.description || '');
      formData.append('brand_id', this.form.brand_id);
      formData.append('start_date', this.form.start_date);
      formData.append('end_date', this.form.end_date);
      formData.append('status', this.form.status);
      formData.append('campaign_type', this.form.campaign_type); // Always brand_promotion
      formData.append('theme_color', this.form.theme_color || '');

      // Add images
      if (this.$refs.primaryImage.files[0]) {
        formData.append('primary_image', this.$refs.primaryImage.files[0]);
      }

      if (this.$refs.secondaryImage.files[0]) {
        formData.append('secondary_image', this.$refs.secondaryImage.files[0]);
      }

      if (this.$refs.banners.files.length > 0) {
        Array.from(this.$refs.banners.files).forEach(file => {
          formData.append('banners[]', file);
        });
      }

      try {
        const res = await axios.post(this.$apiUrl + '/admin/brand-campaigns', formData, {
          headers: { 'Content-Type': 'multipart/form-data' }
        });

        if (res.data.status === 1) {
          this.showMessage('success', 'Campaign created successfully. You can now add products to this campaign.');
          this.$router.push('/brand-campaign-products');
        } else {
          this.showMessage('error', res.data.message || 'Failed to create campaign');
        }
      } catch (error) {
        console.error('Error:', error);
        const message = error.response?.data?.message || 'Failed to create campaign';
        this.showMessage('error', message);
      } finally {
        this.isSubmitting = false;
      }
    }
  }
};
</script>