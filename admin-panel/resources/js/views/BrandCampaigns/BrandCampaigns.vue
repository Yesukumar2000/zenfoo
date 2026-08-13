<template>
  <div>
    <!-- Page Heading -->
    <div class="page-heading">
      <div class="row">
        <div class="col-12 col-md-6 order-md-1 order-last">
          <h3>Brand Campaigns</h3>
        </div>
        <div class="col-12 col-md-6 order-md-2 order-first">
          <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
            <ol class="breadcrumb">
              <li class="breadcrumb-item">
                <router-link to="/dashboard">Dashboard</router-link>
              </li>
              <li class="breadcrumb-item active" aria-current="page">
                Brand Campaigns
              </li>
            </ol>
          </nav>
        </div>
      </div>
    </div>

    <!-- Campaigns Card -->
    <div class="card">
      <div class="card-header d-flex justify-content-between align-items-center">
        <h4>Manage Brand Campaigns</h4>
        <router-link to="/brand-campaigns/create" class="btn btn-primary" v-b-tooltip.hover title="Add New Campaign">
          <i class="fa fa-plus"></i> Add Campaign
        </router-link>
      </div>

      <div class="card-body">
        <!-- Filters Row -->
        <b-row class="mb-3">
          <b-col md="3">
            <h6>Status</h6>
            <b-form-select v-model="statusFilter" @change="getCampaigns" class="form-control form-select">
              <option value="">All Status</option>
              <option value="1">Active</option>
              <option value="0">Inactive</option>
            </b-form-select>
          </b-col>
          <!-- <b-col md="3">
            <h6>Campaign Type</h6>
            <b-form-select v-model="typeFilter" @change="getCampaigns" class="form-control form-select">
              <option value="">All Types</option>
              <option value="brand_promotion">Brand Promotion</option>
              <option value="seasonal">Seasonal</option>
              <option value="flash_sale">Flash Sale</option>
              <option value="bundle_offer">Bundle Offer</option>
            </b-form-select>
          </b-col> -->
          <b-col md="3" offset-md="5">
            <h6>Search</h6>
            <b-form-input
              v-model="filter"
              type="search"
              placeholder="Search campaigns..."
            ></b-form-input>
          </b-col>
          <b-col md="1" class="text-center">
            <button
              class="btn btn-primary btn_refresh"
              v-b-tooltip.hover
              title="Refresh"
              @click="getCampaigns"
              style="margin-top: 24px;"
            >
              <i class="fa fa-refresh" aria-hidden="true"></i>
            </button>
          </b-col>
        </b-row>

        <!-- Table -->
        <b-table
          :items="campaigns"
          :fields="fields"
          :filter="filter"
          :bordered="true"
          :busy="isLoading"
          stacked="md"
          show-empty
          small
        >
          <template #table-busy>
            <div class="text-center text-black my-2">
              <b-spinner class="align-middle"></b-spinner>
              <strong>Loading...</strong>
            </div>
          </template>

          <template #cell(primary_image_url)="row">
            <img :src="row.item.primary_image_url" height="50" style="object-fit: cover;" />
          </template>

          <template #cell(status)="row">
            <span v-if="row.item.status === 1" class="badge bg-success">Active</span>
            <span v-else class="badge bg-secondary">Inactive</span>
          </template>

          <!-- <template #cell(campaign_type)="row">
            <span class="badge bg-info">{{ formatCampaignType(row.item.campaign_type) }}</span>
          </template> -->

          <template #cell(start_date)="row">
            {{ formatDate(row.item.start_date) }}
          </template>

          <template #cell(end_date)="row">
            {{ formatDate(row.item.end_date) }}
          </template>

          <template #cell(is_active)="row">
            <span v-if="row.item.is_active" class="badge bg-success">Running</span>
            <span v-else-if="row.item.is_expired" class="badge bg-danger">Expired</span>
            <span v-else class="badge bg-warning">Scheduled</span>
          </template>

          <template #cell(actions)="row">
            <!-- Edit Button -->
            <router-link
              class="btn btn-sm btn-primary me-2"
              :to="{ name: 'Edit Brand Campaign', params: { id: row.item.id } }"
              v-b-tooltip.hover
              title="Edit"
            >
              <i class="fa fa-pencil-alt"></i>
            </router-link>

            <!-- Delete Button -->
            <button
              class="btn btn-sm btn-danger"
              @click="deleteCampaign(row.index, row.item.id)"
              v-b-tooltip.hover
              title="Delete"
            >
              <i class="fa fa-trash"></i>
            </button>
          </template>
        </b-table>

        <!-- Pagination -->
        <b-row>
          <b-col md="2" class="my-1">
            <b-form-group
              label="Per Page"
              label-for="per-page-select"
              label-align-sm="right"
              label-size="sm"
              class="mb-0"
            >
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
            <label>Total Records: {{ totalRows }}</label>
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
</template>

<script>
import axios from "axios";

export default {
  name: "BrandCampaigns",
  data() {
    return {
      campaigns: [],
      fields: [
        { key: "id", label: "ID", sortable: true },
        { key: "primary_image_url", label: "Image" },
        { key: "name", label: "Campaign Name", sortable: true },
        { key: "brand_name", label: "Brand", sortable: true },
        // { key: "campaign_type", label: "Type", sortable: true },
        { key: "start_date", label: "Start Date", sortable: true },
        { key: "end_date", label: "End Date", sortable: true },
        { key: "is_active", label: "State", sortable: true },
        { key: "status", label: "Status", sortable: true },
        { key: "actions", label: "Actions" }
      ],
      filter: "",
      statusFilter: "",
      typeFilter: "",
      isLoading: false,
      currentPage: 1,
      perPage: 10,
      pageOptions: [10, 25, 50, 100],
      totalRows: 0
    };
  },
  created() {
    this.getCampaigns();
  },
  methods: {
    getCampaigns() {
      this.isLoading = true;

      let params = {};
      if (this.statusFilter !== '') {
        params.status = this.statusFilter;
      }
      if (this.typeFilter !== '') {
        params.campaign_type = this.typeFilter;
      }

      axios
        .get(this.$apiUrl + "/admin/brand-campaigns", { params })
        .then((response) => {
          this.isLoading = false;
          if (response.data.status === 1) {
            this.campaigns = response.data.data || [];
            this.totalRows = this.campaigns.length;
          } else {
            this.showMessage("error", response.data.message);
          }
        })
        .catch((error) => {
          this.isLoading = false;
          console.error("Error fetching campaigns:", error);
          this.showMessage("error", "Failed to fetch campaigns");
        });
    },

    deleteCampaign(index, id) {
      this.$swal
        .fire({
          title: "Are you sure?",
          text: "You won't be able to revert this!",
          icon: "warning",
          showCancelButton: true,
          confirmButtonColor: "#9AC444",
          cancelButtonColor: "#d33",
          confirmButtonText: "Yes, delete it!",
        })
        .then((result) => {
          if (result.isConfirmed) {
            this.isLoading = true;
            axios
              .delete(this.$apiUrl + "/admin/brand-campaigns/" + id)
              .then((response) => {
                this.isLoading = false;
                if (response.data.status === 1) {
                  this.campaigns.splice(index, 1);
                  this.totalRows--;
                  this.showMessage("success", "Campaign deleted successfully");
                } else {
                  this.showMessage("error", response.data.message);
                }
              })
              .catch((error) => {
                this.isLoading = false;
                console.error("Error deleting campaign:", error);
                this.showMessage("error", "Failed to delete campaign");
              });
          }
        });
    },

    formatDate(dateString) {
      if (!dateString) return '-';
      const date = new Date(dateString);
      return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    },

    formatCampaignType(type) {
      const types = {
        'brand_promotion': 'Brand Promotion',
        'seasonal': 'Seasonal',
        'flash_sale': 'Flash Sale',
        'bundle_offer': 'Bundle Offer'
      };
      return types[type] || type;
    }
  }
};
</script>

<style scoped>
.btn_refresh {
  height: 38px;
}
</style>
