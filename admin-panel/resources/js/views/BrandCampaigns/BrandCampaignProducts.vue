<template>
  <div>
    <!-- Page Heading -->
    <div class="page-heading">
      <div class="row">
        <div class="col-12 col-md-6 order-md-1 order-last">
          <h3>Campaign Products</h3>
        </div>
        <div class="col-12 col-md-6 order-md-2 order-first">
          <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
            <ol class="breadcrumb">
              <li class="breadcrumb-item">
                <router-link to="/dashboard">Dashboard</router-link>
              </li>
              <li class="breadcrumb-item active" aria-current="page">
                Campaign Products
              </li>
            </ol>
          </nav>
        </div>
      </div>
    </div>

    <!-- Products Card -->
    <div class="card">
      <div class="card-header d-flex justify-content-between align-items-center">
        <h4>Manage Campaign Products</h4>
        <div>
          <router-link to="/brand-campaign-products/add" class="btn btn-success me-2" v-b-tooltip.hover title="Add Products to Campaign">
            <i class="fa fa-plus"></i> Add Products
          </router-link>
        </div>
      </div>

      <div class="card-body">
        <!-- Filters Row -->
        <b-row class="mb-3">
          <b-col md="4">
            <h6>Search</h6>
            <b-form-input
              v-model="filter"
              type="search"
              placeholder="Search campaigns..."
            ></b-form-input>
          </b-col>
          <b-col md="1" offset-md="7" class="text-center">
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

          <template #cell(products_count)="row">
            <span class="badge bg-primary">{{ row.item.products_count }} Products</span>
          </template>

          <template #cell(status)="row">
            <b-form-checkbox
              v-model="row.item.status"
              :value="1"
              :unchecked-value="0"
              @change="toggleStatus(row.item.id, row.item.status)"
              switch
              size="lg"
            >
            </b-form-checkbox>
          </template>

          <template #cell(actions)="row">
            <!-- Edit Products Button -->
            <router-link
              class="btn btn-sm btn-primary me-2"
              :to="{ name: 'Edit Campaign Products', params: { id: row.item.id } }"
              v-b-tooltip.hover
              title="Manage Products"
            >
              <i class="fa fa-edit"></i>
            </router-link>

            <!-- Delete All Products Button -->
            <button
              class="btn btn-sm btn-danger"
              @click="deleteAllProducts(row.index, row.item.id, row.item.name)"
              v-b-tooltip.hover
              title="Remove All Products"
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
            <label>Total Campaigns: {{ totalRows }}</label>
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
  name: "BrandCampaignProducts",
  data() {
    return {
      campaigns: [],
      fields: [
        { key: "id", label: "ID", sortable: true },
        { key: "primary_image_url", label: "Image" },
        { key: "name", label: "Campaign Name", sortable: true },
        { key: "brand_name", label: "Brand", sortable: true },
        { key: "products_count", label: "Products", sortable: true },
        { key: "status", label: "Status", sortable: false },
        { key: "actions", label: "Actions" }
      ],
      filter: "",
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

      axios
        .get(this.$apiUrl + "/admin/brand-campaigns")
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

    toggleStatus(campaignId, newStatus) {
      axios
        .put(this.$apiUrl + "/admin/brand-campaigns/" + campaignId, {
          status: newStatus,
          _method: 'PUT'
        })
        .then((response) => {
          if (response.data.status === 1) {
            this.showMessage("success", "Campaign status updated successfully");
          } else {
            this.showMessage("error", response.data.message);
            this.getCampaigns(); // Reload to revert the toggle
          }
        })
        .catch((error) => {
          console.error("Error updating status:", error);
          this.showMessage("error", "Failed to update campaign status");
          this.getCampaigns(); // Reload to revert the toggle
        });
    },

    deleteAllProducts(index, campaignId, campaignName) {
      this.$swal
        .fire({
          title: "Are you sure?",
          text: `Remove all products from "${campaignName}" campaign?`,
          icon: "warning",
          showCancelButton: true,
          confirmButtonColor: "#9AC444",
          cancelButtonColor: "#d33",
          confirmButtonText: "Yes, remove all!",
        })
        .then((result) => {
          if (result.isConfirmed) {
            this.isLoading = true;
            axios
              .delete(this.$apiUrl + "/admin/brand-campaign-products/delete-all/" + campaignId)
              .then((response) => {
                this.isLoading = false;
                if (response.data.status === 1) {
                  // Update the products_count to 0 for this campaign
                  this.campaigns[index].products_count = 0;
                  this.showMessage("success", "All products removed from campaign successfully");
                } else {
                  this.showMessage("error", response.data.message);
                }
              })
              .catch((error) => {
                this.isLoading = false;
                console.error("Error removing products:", error);
                this.showMessage("error", "Failed to remove products from campaign");
              });
          }
        });
    }
  }
};
</script>

<style scoped>
.btn_refresh {
  height: 38px;
}
</style>