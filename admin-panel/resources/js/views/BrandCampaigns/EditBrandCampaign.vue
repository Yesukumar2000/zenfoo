<template>
  <div>
    <div class="page-heading">
      <div class="row">
        <div class="col-12 col-md-6">
          <h3>Edit Brand Campaign</h3>
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
              <li class="breadcrumb-item active">Edit</li>
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

    <div v-if="loading" class="text-center py-5">
      <div class="spinner-border" role="status"></div>
    </div>

    <div v-else class="card">
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

          <!-- Brand Display (Read-only in Edit Mode) -->
          <div class="row mb-3">
            <div class="col-12">
              <label>Brand (Cannot be changed)</label>
              <input
                type="text"
                :value="brandName"
                class="form-control"
                disabled
              >
              <small class="text-muted">The brand cannot be changed after campaign creation</small>
            </div>
          </div>

          <!-- Products Info -->
          <div class="row mb-3">
            <div class="col-12">
              <div class="alert alert-info">
                <strong>Products: {{ productsCount }}</strong>
                <br>
                <router-link to="/brand-campaign-products" class="btn btn-sm btn-primary mt-2">
                  Manage Campaign Products
                </router-link>
              </div>
            </div>
          </div>

          <!-- Images -->
          <div class="row mb-3">
            <div class="col-md-6">
              <label>Primary Image (Max 5MB)</label>
              <input
                type="file"
                ref="primaryImage"
                @change="onPrimaryImageChange"
                accept="image/*"
                class="form-control"
              >
              <img v-if="primaryPreview || form.primary_image_url" :src="primaryPreview || form.primary_image_url" class="mt-2" height="100">
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
              <img v-if="secondaryPreview || form.secondary_image_url" :src="secondaryPreview || form.secondary_image_url" class="mt-2" height="100">
            </div>
          </div>

          <!-- Banners -->
          <div class="row mb-3">
            <div class="col-12">
              <label>Banners (Unlimited, each max 100MB)</label>

              <!-- Existing Banners -->
              <div v-if="form.banners && form.banners.length > 0" class="mb-3">
                <label class="d-block mb-2 text-muted">Current Banners ({{ form.banners.length }})</label>
                <div class="border rounded p-2 bg-light">
                  <div v-for="(banner, index) in form.banners" :key="'existing_' + index" class="d-inline-block me-2 mb-2 position-relative">
                    <img v-if="banner.type === 'image'" :src="banner.url" height="100" class="rounded border">
                    <video v-else :src="banner.url" height="100" class="rounded border" controls style="max-width: 150px;"></video>
                    <button
                      type="button"
                      @click="removeExistingBanner(index)"
                      class="btn btn-sm btn-danger position-absolute top-0 end-0"
                      style="margin: 2px;"
                      title="Remove banner"
                    >
                      <i class="fa fa-times"></i>
                    </button>
                  </div>
                </div>
              </div>

              <!-- Upload New Banners -->
              <label class="d-block mb-2">Upload New Banners</label>
              <input
                type="file"
                ref="banners"
                @change="onBannersChange"
                accept="image/*,video/*"
                multiple
                class="form-control"
              >
              <small class="text-muted">You can select multiple images or videos to add</small>

              <!-- New Banners Preview -->
              <div v-if="bannerPreviews.length > 0" class="mt-2">
                <label class="d-block mb-2 text-success">New Banners to Upload ({{ bannerPreviews.length }})</label>
                <div class="border rounded p-2 bg-light">
                  <div v-for="(preview, index) in bannerPreviews" :key="'new_' + index" class="d-inline-block me-2 mb-2">
                    <img v-if="preview.type === 'image'" :src="preview.url" height="100" class="rounded border border-success">
                    <video v-else :src="preview.url" height="100" class="rounded border border-success" controls style="max-width: 150px;"></video>
                  </div>
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
            <!-- Campaign Type - Commented out, always brand_promotion -->
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
                {{ isSubmitting ? 'Updating...' : 'Update Campaign' }}
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
  name: 'EditBrandCampaign',
  data() {
    return {
      loading: true,
      form: {
        name: '',
        description: '',
        brand_id: '',
        start_date: '',
        end_date: '',
        status: 1,
        campaign_type: 'brand_promotion',
        theme_color: '#000000',
        primary_image_url: '',
        secondary_image_url: '',
        banners: []
      },
      brandName: '',
      productsCount: 0,
      primaryPreview: null,
      secondaryPreview: null,
      bannerPreviews: [],
      isSubmitting: false
    };
  },
  computed: {
    campaignId() {
      return this.$route.params.id;
    }
  },
  mounted() {
    this.loadCampaign();
  },
  methods: {
    async loadCampaign() {
      try {
        const res = await axios.get(this.$apiUrl + '/admin/brand-campaigns/' + this.campaignId);
        if (res.data.status === 1) {
          const campaign = res.data.data.campaign;
          this.form = {
            name: campaign.name || '',
            description: campaign.description || '',
            brand_id: campaign.brand_id,
            start_date: this.formatDateForInput(campaign.start_date),
            end_date: this.formatDateForInput(campaign.end_date),
            status: campaign.status,
            campaign_type: campaign.campaign_type || 'brand_promotion',
            theme_color: campaign.theme_color || '#000000',
            primary_image_url: campaign.primary_image_url || '',
            secondary_image_url: campaign.secondary_image_url || '',
            banners: campaign.banners || []
          };
          this.brandName = campaign.brand_name || 'N/A';
          this.productsCount = campaign.products_count || 0;
        }
      } catch (error) {
        console.error('Failed to load campaign:', error);
        this.showMessage('error', 'Failed to load campaign');
        this.$router.push('/brand-campaigns');
      } finally {
        this.loading = false;
      }
    },

    formatDateForInput(dateString) {
      if (!dateString) return '';
      return dateString.substring(0, 16).replace(' ', 'T');
    },

    removeExistingBanner(index) {
      this.form.banners.splice(index, 1);
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
      this.isSubmitting = true;

      const formData = new FormData();
      formData.append('_method', 'PUT');
      formData.append('name', this.form.name);
      formData.append('description', this.form.description || '');
      formData.append('brand_id', this.form.brand_id);
      formData.append('start_date', this.form.start_date);
      formData.append('end_date', this.form.end_date);
      formData.append('status', this.form.status);
      formData.append('campaign_type', this.form.campaign_type);
      formData.append('theme_color', this.form.theme_color || '');

      // Add images if changed
      if (this.$refs.primaryImage.files[0]) {
        formData.append('primary_image', this.$refs.primaryImage.files[0]);
      }

      if (this.$refs.secondaryImage.files[0]) {
        formData.append('secondary_image', this.$refs.secondaryImage.files[0]);
      }

      // Send existing banners to preserve them
      if (this.form.banners && this.form.banners.length > 0) {
        formData.append('existing_banners', JSON.stringify(this.form.banners));
      }

      // Add new banner files
      if (this.$refs.banners.files.length > 0) {
        Array.from(this.$refs.banners.files).forEach(file => {
          formData.append('banners[]', file);
        });
      }

      try {
        const res = await axios.post(this.$apiUrl + '/admin/brand-campaigns/' + this.campaignId, formData, {
          headers: { 'Content-Type': 'multipart/form-data' }
        });

        if (res.data.status === 1) {
          this.showMessage('success', 'Campaign updated successfully');
          this.$router.push('/brand-campaigns');
        } else {
          this.showMessage('error', res.data.message || 'Failed to update campaign');
        }
      } catch (error) {
        console.error('Error:', error);
        const message = error.response?.data?.message || 'Failed to update campaign';
        this.showMessage('error', message);
      } finally {
        this.isSubmitting = false;
      }
    }
  }
};
</script>