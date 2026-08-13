<template>
  <div>
    <!-- Page Heading -->
    <div class="page-heading">
      <div class="row">
        <div class="col-12 col-md-6 order-md-1 order-last">
          <h3>{{ __('manage_stores') }}</h3>
        </div>
        <div class="col-12 col-md-6 order-md-2 order-first">
          <nav
            aria-label="breadcrumb"
            class="breadcrumb-header float-start float-lg-end"
          >
            <ol class="breadcrumb">
              <li class="breadcrumb-item">
                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
              </li>
              <li class="breadcrumb-item active" aria-current="page">
                <!-- {{ __('manage_stores') }} -->
                Manage Stores
              </li>
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

    <!-- Combos Card -->
    <div class="card">
      <!-- <div class="card-header d-flex justify-content-between align-items-center">
        <h4>{{ __('store_packages') }}</h4>
       <template>
                                    <router-link to="/manage_store/create" class="btn btn-primary" v-b-tooltip.hover title="Add Store">{{ __('add_store') }}</router-link>
                                </template>
      </div> -->

      <div class="card-body">
        <!-- Search -->
        <b-row class="mb-2">
          <b-col md="3" offset-md="8">
            <h6>{{ __('search') }}</h6>
            <b-form-input
              v-model="filter"
              type="search"
              :placeholder="__('search')"
              @input="getStores"
            ></b-form-input>
          </b-col>
          <b-col md="1" class="text-center">
            <button
              class="btn btn-primary btn_refresh"
              v-b-tooltip.hover
              :title="__('refresh')"
              @click="getStores"
            >
              <i class="fa fa-refresh" aria-hidden="true"></i>
            </button>
          </b-col>
        </b-row>

        <!-- Table -->
        <b-table
          :items="stores"
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
              <strong>{{ __('loading') }}...</strong>
            </div>
          </template>

          <template #cell(image)="row">
            <img :src="row.item.image_url" height="50" />
          </template>

          <template #cell(actions)="row">
          <!-- Edit Button -->
          <router-link
            class="btn btn-sm btn-primary me-2"
            :to="{ name: 'EditStore', params: { id: row.item.id } }"
            v-b-tooltip.hover
            :title="__('edit')"
          >
            <i class="fa fa-pencil-alt"></i>
          </router-link>

          <!-- Delete Button -->
          <!-- <button
            class="btn btn-sm btn-danger"
            @click="deleteStore(row.index, row.item.id)"
            v-b-tooltip.hover
            :title="__('delete')"
          >
            <i class="fa fa-trash"></i>
          </button> -->
        </template>

        </b-table>

        <!-- Pagination -->
        <b-row>
          <b-col md="2" class="my-1">
            <b-form-group
              :label="__('per_page')"
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
                @change="getStores"
              ></b-form-select>
            </b-form-group>
          </b-col>
          <b-col md="4" class="my-1" offset-md="6">
            <label>{{ __('total_records') }}: {{ totalRows }}</label>
            <b-pagination
              v-model="currentPage"
              :total-rows="totalRows"
              :per-page="perPage"
              align="fill"
              size="sm"
              class="my-0"
              @change="getStores"
            ></b-pagination>
          </b-col>
        </b-row>
      </div>
    </div>

    <!-- Combo Modal -->
  </div>
</template>

<script>
import AppEditStore from "./EditStore.vue";

export default {
  name: "StoreList",
  components: { AppEditStore },
  data() {
    return {
      fields: [
        { key: "index", label: "S.No", class: "text-center" },
        { key: "name", label: "Name", class: "text-center" },
        { key: "actions", label: "Actions", class: "text-center" },
      ],
      stores: [],
      totalRows: 0,
      currentPage: 1,
      perPage: 10,
      pageOptions: [10, 25, 50, 100],
      filter: "",
      isLoading: false,
    };
  },
  mounted() {
    this.getStores();
    this.showCreateModal();

    // Listen for save events
    this.$eventBus.$on("StoreSaved", (message) => {
      this.showMessage("success", message);
      this.getStores();
      this.create_new = false;
    });
  },
  methods: {
    getStores() {
        this.isLoading = true;
        const params = {
            page: this.currentPage,
            per_page: this.perPage,
            search: this.filter,
        };

        axios
            .get(this.$apiUrl + "/stores", { params })
            .then((res) => {
            this.isLoading = false;

            const stores = res.data.data ?? res.data; // ✅ FIXED

            this.stores = Array.isArray(stores)
                ? stores.map((store, i) => ({
                    ...store,
                    index: (this.currentPage - 1) * this.perPage + i + 1,
                }))
                : [];

            this.totalRows = this.stores.length;
            })
            .catch(() => (this.isLoading = false));
        },

      showCreateModal() {
            this.create_new = true; // or however you trigger the modal
        },

    deleteStore(index, id) {
      this.$swal
        .fire({
          title: "Are you sure?",
          text: "You won't be able to revert this!",
          icon: "warning",
          showCancelButton: true,
          confirmButtonText: "Yes, delete it!",
          cancelButtonText: "Cancel",
          confirmButtonColor: "#3085d6",
          cancelButtonColor: "#d33",
        })
        .then((result) => {
          if (result.isConfirmed) {
            this.isLoading = true;
            axios
              .post(this.$apiUrl + "/stores/delete", { id })
              .then((res) => {
                if (res.data.status === 1) {
                  this.showMessage("success", res.data.message);
                  this.getStores();
                } else {
                  this.showMessage("error", res.data.message);
                  this.isLoading = false;
                }
              })
              .catch(() => (this.isLoading = false));
          }
        });
    },
  },
};
</script>
