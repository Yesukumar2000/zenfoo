<template>
  <div>
    <div class="page-heading">
      <div class="row">
        <div class="col-12 col-md-6 order-md-1 order-last">
          <h3>User Offers</h3>
        </div>
        <div class="col-12 col-md-6 order-md-2 order-first">
          <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
            <ol class="breadcrumb">
              <li class="breadcrumb-item">
                  <router-link to="/dashboard">Dashboard</router-link>
              </li>
              <li class="breadcrumb-item active" aria-current="page">User Offers</li>
            </ol>
          </nav>
        </div>
      </div>

      <!-- Tabs -->
      <b-tabs content-class="mt-3" v-model="activeTab">
        <!-- Order Rewards Tab -->
        <b-tab title="Order Rewards" active>
          <div class="card">
            <div class="card-header">
              <h4>Order Count Rewards</h4>
              <span class="pull-right">
                <button class="btn btn-primary" @click="showRewardModal = true; editReward = null;">Add Reward</button>
              </span>
            </div>
            <div class="card-body">
              <p class="text-muted mb-3">Set reward amounts based on user order count. E.g., Order 5 times = Rs 100 reward</p>

              <b-row class="mb-2">
                <b-col md="1" class="text-center">
                  <button class="btn btn-primary btn_refresh" v-b-tooltip.hover title="Refresh" @click="getOrderRewards()">
                    <i class="fa fa-refresh" aria-hidden="true"></i>
                  </button>
                </b-col>
              </b-row>

              <div class="table-responsive">
                <b-table
                  :items="orderRewards"
                  :fields="rewardFields"
                  :busy="isLoadingRewards"
                  :bordered="true"
                  stacked="md"
                  show-empty
                  small
                >
                  <template #table-busy>
                    <div class="text-center my-2">
                      <b-spinner class="align-middle"></b-spinner>
                      <strong>Loading...</strong>
                    </div>
                  </template>

                  <!-- <template #cell(status)="row">
                    <label v-if="row.item.status === 1 || row.item.status === true" class="badge bg-success">Active</label>
                    <label v-else class="badge bg-danger">Inactive</label>
                  </template> -->

                  <template #cell(actions)="row">
                    <button class="btn btn-sm btn-primary" @click="editRewardItem(row.item)" v-b-tooltip.hover title="Edit">
                      <i class="fa fa-pencil-alt"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" @click="deleteReward(row.index, row.item.id)" v-b-tooltip.hover title="Delete">
                      <i class="fa fa-trash"></i>
                    </button>
                  </template>
                </b-table>
              </div>
            </div>
          </div>
        </b-tab>

        <!-- Offer Banners Tab -->
        <b-tab title="Offer Banners">
          <div class="card">
            <div class="card-header">
              <h4>Offer Banners</h4>
              <span class="pull-right">
                <button class="btn btn-primary" @click="showBannerModal = true; editBanner = null;">Add Banner</button>
              </span>
            </div>
            <div class="card-body">
              <p class="text-muted mb-3">Upload banner images for user offers section</p>

              <b-row class="mb-2">
                <b-col md="1" class="text-center">
                  <button class="btn btn-primary btn_refresh" v-b-tooltip.hover title="Refresh" @click="getOfferBanners()">
                    <i class="fa fa-refresh" aria-hidden="true"></i>
                  </button>
                </b-col>
              </b-row>

              <div class="table-responsive">
                <b-table
                  :items="offerBanners"
                  :fields="bannerFields"
                  :busy="isLoadingBanners"
                  :bordered="true"
                  stacked="md"
                  show-empty
                  small
                >
                  <template #table-busy>
                    <div class="text-center my-2">
                      <b-spinner class="align-middle"></b-spinner>
                      <strong>Loading...</strong>
                    </div>
                  </template>

                  <template #cell(image)="row">
                    <img v-if="row.item.image_url" :src="row.item.image_url" height="50" />
                    <span v-else>-</span>
                  </template>

                  <template #cell(status)="row">
                    <label v-if="row.item.status === 1 || row.item.status === true" class="badge bg-success">Active</label>
                    <label v-else class="badge bg-danger">Inactive</label>
                  </template>

                  <template #cell(actions)="row">
                    <button class="btn btn-sm btn-primary" @click="editBannerItem(row.item)" v-b-tooltip.hover title="Edit">
                      <i class="fa fa-pencil-alt"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" @click="deleteBanner(row.index, row.item.id)" v-b-tooltip.hover title="Delete">
                      <i class="fa fa-trash"></i>
                    </button>
                  </template>
                </b-table>
              </div>
            </div>
          </div>
        </b-tab>
      </b-tabs>

      <!-- Claimed Milestones Section -->
      <div class="card mt-4">
        <div class="card-header">
          <h4>Claimed Milestones</h4>
          <span class="pull-right">
            <button class="btn btn-primary btn_refresh" v-b-tooltip.hover title="Refresh" @click="getClaimedMilestones()">
              <i class="fa fa-refresh" aria-hidden="true"></i>
            </button>
          </span>
        </div>
        <div class="card-body">
          <p class="text-muted mb-3">Users sorted by most milestones used. Click a row to see details.</p>

          <div v-if="isLoadingClaimed" class="text-center my-2">
            <b-spinner class="align-middle"></b-spinner>
            <strong>Loading...</strong>
          </div>

          <div v-else>
            <div v-if="claimedMilestones.length === 0" class="text-center text-muted py-3">No claimed milestones found.</div>

            <div v-for="(user, index) in claimedMilestones" :key="user.customer_id" class="milestone-user-row rounded mb-2">
              <!-- User Row (clickable) -->
              <div
                class="d-flex align-items-center p-3 milestone-user-header"
                :class="{'expanded': expandedUser === index}"
                @click="expandedUser = expandedUser === index ? null : index"
              >
                <div class="me-3">
                  <i class="fa" :class="expandedUser === index ? 'fa-chevron-down' : 'fa-chevron-right'"></i>
                </div>
                <div class="flex-grow-1">
                  <div class="d-flex flex-wrap align-items-center gap-3">
                    <strong>{{ user.customer_name }}</strong>
                    <span class="text-muted">{{ user.customer_mobile }}</span>
                  </div>
                </div>
                <div class="d-flex gap-3 text-center">
                  <div class="px-3">
                    <div class="fw-bold text-warning">{{ user.total_milestones }}</div>
                    <small class="text-muted">Total</small>
                  </div>
                  <div class="px-3">
                    <div class="fw-bold text-success">{{ user.used_count }}</div>
                    <small class="text-muted">Used</small>
                  </div>
                  <div class="px-3">
                    <div class="fw-bold text-warning">{{ user.claimed_count }}</div>
                    <small class="text-muted">Claimed</small>
                  </div>
                  <div class="px-3">
                    <div class="fw-bold text-success">Rs {{ user.total_reward }}</div>
                    <small class="text-muted">Total Reward</small>
                  </div>
                </div>
              </div>

              <!-- Expanded Milestones Dropdown -->
              <div v-if="expandedUser === index" class="milestone-details">
                <div class="table-responsive">
                  <table class="table table-sm table-bordered mb-0">
                    <thead>
                      <tr>
                        <th class="text-center">Milestone (Orders)</th>
                        <th class="text-center">Reward</th>
                        <th class="text-center">Status</th>
                        <th class="text-center">Claimed Date</th>
                        <th class="text-center">Used In Order</th>
                        <th class="text-center">Used Date</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="m in user.milestones" :key="m.id">
                        <td class="text-center">{{ m.milestone_order_count }} Orders</td>
                        <td class="text-center">Rs {{ m.reward_amount }}</td>
                        <td class="text-center">
                          <label v-if="m.status === 'used'" class="badge bg-success mb-0">Used</label>
                          <label v-else class="badge bg-warning mb-0">Claimed</label>
                        </td>
                        <td class="text-center">{{ m.claimed_date }}</td>
                        <td class="text-center">
                          <span v-if="m.used_in_order_id">#{{ m.used_in_order_id }}</span>
                          <span v-else>-</span>
                        </td>
                        <td class="text-center">{{ m.used_date }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>

            <!-- Pagination -->
            <div v-if="claimedPagination.last_page > 1" class="d-flex justify-content-between align-items-center mt-3">
              <small class="text-muted">
                Showing {{ (claimedPagination.current_page - 1) * claimedPagination.per_page + 1 }}
                - {{ Math.min(claimedPagination.current_page * claimedPagination.per_page, claimedPagination.total) }}
                of {{ claimedPagination.total }} users
              </small>
              <b-pagination
                v-model="claimedPage"
                :total-rows="claimedPagination.total"
                :per-page="claimedPagination.per_page"
                @change="onClaimedPageChange"
                size="sm"
                class="mb-0"
              ></b-pagination>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Add/Edit Reward Modal -->
    <app-edit-reward
      v-if="showRewardModal"
      :record="editReward"
      @modalClose="hideRewardModal()"
    ></app-edit-reward>

    <!-- Add/Edit Banner Modal -->
    <app-edit-banner
      v-if="showBannerModal"
      :record="editBanner"
      @modalClose="hideBannerModal()"
    ></app-edit-banner>

  </div>
</template>

<script>
import EditReward from "./EditReward.vue";
import EditBanner from "./EditBanner.vue";

export default {
  components: {
    "app-edit-reward": EditReward,
    "app-edit-banner": EditBanner,
  },
  data: function () {
    return {
      activeTab: 0,

      // Order Rewards
      orderRewards: [],
      isLoadingRewards: false,
      showRewardModal: false,
      editReward: null,
      rewardFields: [
        { key: "order_count", label: "Order Count", sortable: true, class: "text-center" },
        { key: "amount", label: "Amount (Rs)", sortable: true, class: "text-center" },
        // { key: "status", label: "Status", sortable: true, class: "text-center" },
        { key: "actions", label: "Actions", class: "text-center" },
      ],

      // Offer Banners
      offerBanners: [],
      isLoadingBanners: false,
      showBannerModal: false,
      editBanner: null,
      bannerFields: [
        { key: "title", label: "Title", sortable: true, class: "text-center" },
        { key: "image", label: "Image", class: "text-center" },
        { key: "sort_order", label: "Sort Order", sortable: true, class: "text-center" },
        { key: "status", label: "Status", sortable: true, class: "text-center" },
        { key: "actions", label: "Actions", class: "text-center" },
      ],

      // Claimed Milestones
      claimedMilestones: [],
      isLoadingClaimed: false,
      expandedUser: null,
      claimedPage: 1,
      claimedPagination: { current_page: 1, last_page: 1, per_page: 5, total: 0 },
    };
  },
  created: function () {
    this.$eventBus.$on("OrderRewardSaved", (message) => {
      this.showMessage("success", message);
      this.getOrderRewards();
    });
    this.$eventBus.$on("OfferBannerSaved", (message) => {
      this.showMessage("success", message);
      this.getOfferBanners();
    });
    this.getOrderRewards();
    this.getOfferBanners();
    this.getClaimedMilestones();
  },
  methods: {
    // Order Rewards
    getOrderRewards() {
      this.isLoadingRewards = true;
      axios.get(this.$apiUrl + "/user_offers/order_rewards").then((response) => {
        this.isLoadingRewards = false;
        let data = response.data;
        this.orderRewards = data.data;
      }).catch(() => {
        this.isLoadingRewards = false;
      });
    },

    editRewardItem(item) {
      this.editReward = item;
      this.showRewardModal = true;
    },

    deleteReward(index, id) {
      this.$swal
        .fire({
          title: "Are you Sure?",
          text: "You won't be able to revert this",
          confirmButtonText: "Yes, Delete",
          cancelButtonText: "Cancel",
          icon: "warning",
          showCancelButton: true,
          confirmButtonColor: "#9AC444",
          cancelButtonColor: "#d33",
        })
        .then((result) => {
          if (result.value) {
            this.isLoadingRewards = true;
            let postData = { id: id };
            axios
              .post(this.$apiUrl + "/user_offers/order_rewards/delete", postData)
              .then((response) => {
                this.isLoadingRewards = false;
                let data = response.data;
                this.orderRewards.splice(index, 1);
                this.showMessage("success", data.message);
              });
          }
        });
    },

    hideRewardModal() {
      this.showRewardModal = false;
      this.editReward = null;
    },

    // Offer Banners
    getOfferBanners() {
      this.isLoadingBanners = true;
      axios.get(this.$apiUrl + "/user_offers/banners").then((response) => {
        this.isLoadingBanners = false;
        let data = response.data;
        this.offerBanners = data.data;
      }).catch(() => {
        this.isLoadingBanners = false;
      });
    },

    editBannerItem(item) {
      this.editBanner = item;
      this.showBannerModal = true;
    },

    deleteBanner(index, id) {
      this.$swal
        .fire({
          title: "Are you Sure?",
          text: "You won't be able to revert this",
          confirmButtonText: "Yes, Delete",
          cancelButtonText: "Cancel",
          icon: "warning",
          showCancelButton: true,
          confirmButtonColor: "#9AC444",
          cancelButtonColor: "#d33",
        })
        .then((result) => {
          if (result.value) {
            this.isLoadingBanners = true;
            let postData = { id: id };
            axios
              .post(this.$apiUrl + "/user_offers/banners/delete", postData)
              .then((response) => {
                this.isLoadingBanners = false;
                let data = response.data;
                this.offerBanners.splice(index, 1);
                this.showMessage("success", data.message);
              });
          }
        });
    },

    hideBannerModal() {
      this.showBannerModal = false;
      this.editBanner = null;
    },

    // Claimed Milestones
    getClaimedMilestones(page) {
      this.isLoadingClaimed = true;
      this.expandedUser = null;
      let p = page || this.claimedPage;
      axios.get(this.$apiUrl + "/user_offers/claimed_milestones?page=" + p + "&per_page=5").then((response) => {
        this.isLoadingClaimed = false;
        let data = response.data.data;
        this.claimedMilestones = data.rows;
        this.claimedPagination = data.pagination;
      }).catch(() => {
        this.isLoadingClaimed = false;
      });
    },

    onClaimedPageChange(page) {
      this.claimedPage = page;
      this.getClaimedMilestones(page);
    },
  },
};
</script>

<style>
/* Milestone user rows - light mode */
.milestone-user-row {
  border: 1px solid #e9ecef;
}

.milestone-user-header {
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.milestone-user-header:hover {
  background-color: #f8f9fa;
}

.milestone-user-header.expanded {
  background-color: #f8f9fa;
}

.milestone-details {
  border-top: 1px solid #e9ecef;
}

/* Dark mode overrides */
.theme-dark .milestone-user-row {
  border-color: #3d4147;
}

.theme-dark .milestone-user-header:hover,
.theme-dark .milestone-user-header.expanded {
  background-color: #2a2e33;
}

.theme-dark .milestone-details {
  border-top-color: #3d4147;
}
</style>
