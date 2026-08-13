<template>
  <div>
    <div class="page-heading">
      <div class="row">
        <div class="col-12 col-md-6 order-md-1 order-last">
          <h3>{{ __('Seller Registration Helper') }}</h3>
        </div>
        <div class="col-12 col-md-6 order-md-2 order-first">
          <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
            <ol class="breadcrumb">
              <li class="breadcrumb-item">
                  <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
              </li>
              <li class="breadcrumb-item active" aria-current="page">{{ __('Seller Registration Helper') }}</li>
            </ol>
          </nav>
        </div>
      </div>

      <div class="row mb-3">
        <div class="col-12">
          <router-link to="/dashboard" class="btn btn-secondary btn-sm">
            <i class="fa fa-arrow-left me-1"></i> Back to Dashboard
          </router-link>
        </div>
      </div>

      <div class="row">
        <div class="col-12 col-md-12 order-md-1 order-last">
          <div class="card">
            <div class="card-header">
              <h4>{{ __('Seller Registration Helper') }}</h4>
              <span class="pull-right">
                <button class="btn btn-primary" @click="create_new=true" v-if="$can('order_list')">{{ __('add') }}</button>
              </span>
            </div>

            <div class="card-body">
              <b-row class="mb-2">
                <b-col md="3" offset-md="8">
                    <h6 class="box-title">{{ __('search') }}</h6>
                  <b-form-input
                    id="filter-input"
                    v-model="filter"
                    type="search"
                    placeholder="Search"
                  ></b-form-input>
                </b-col>
                  <b-col md="1" class="text-center">
                      <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getHelpers()" >
                          <i class="fa fa-refresh" aria-hidden="true"></i>
                      </button>
                  </b-col>
              </b-row>
              <template>
                <div class="table-responsive">
                  <b-table
                    :items="helpers"
                    :fields="fields"
                    :current-page="currentPage"
                    :per-page="perPage"
                    :filter="filter"
                    :filter-included-fields="filterOn"
                    :sort-by.sync="sortBy"
                    :sort-desc.sync="sortDesc"
                    :sort-direction="sortDirection"
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

                  <template #cell(img)="row">
                      <img v-if="row.item.image_url" :src="row.item.image_url" height="50" />
                      <span v-else>{{ __('no_image') }}</span>
                  </template>

                  <template #cell(description)="row">
                      <span>{{ row.item.description ? row.item.description.substring(0, 50) + '...' : '-' }}</span>
                  </template>

                  <template #cell(categories)="row">
                      <span v-if="row.item.categories && row.item.categories.length">{{ row.item.categories.length }} {{ __('categories') }}</span>
                      <span v-else>-</span>
                  </template>

                <template #cell(actions)="row">
                  <button class="btn btn-sm btn-primary" @click="edit_record = row.item" v-if="$can('order_list')" v-b-tooltip.hover :title="__('edit')"><i class="fa fa-pencil-alt"></i></button>
                  <button class="btn btn-sm btn-danger" @click="deleteHelper(row.index, row.item.id)" v-if="$can('order_list')" v-b-tooltip.hover :title="__('delete')"><i class="fa fa-trash"></i></button>
                </template>
              </b-table>
            </div>
          </template>
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
                    ></b-form-select>
                  </b-form-group>
                </b-col>
                <b-col md="4" class="my-1" offset-md="6">
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
      </div>
    </div>

    <!-- Add / Edit -->
      <app-edit-record
          v-if="create_new || edit_record"
          :record="edit_record"
          @modalClose="hideModal()"
      ></app-edit-record>

  </div>
</template>

<script>
import EditRecord from "./Edit.vue";

export default {
  components: {
    "app-edit-record": EditRecord,
  },
  data: function () {
    return {
      fields: [
        { key: "id", label: __("id"), sortable: true, headAttr: { width: '80px', textAlign: 'center' }, sortDirection: "desc" },
        { key: "name", label: __('name'), sortable: true, class: "text-center" },
        { key: "description", label: __('description'), sortable: false, class: "text-center" },
        { key: "img", label: __('image'), sortable: false, class: "text-center" },
        { key: "stores", label: __('store'), sortable: true, class: "text-center" },
        { key: "categories", label: __('categories'), sortable: false, class: "text-center" },
        { key: "actions", label: __('actions'), class: "text-center"},
      ],
      totalRows: 1,
      currentPage: 1,
      perPage: this.$perPage,
      pageOptions: this.$pageOptions,
      sortBy: "",
      sortDesc: false,
      sortDirection: "asc",
      filter: null,
      filterOn: [],
      page: 1,

      helpers: [],
      isLoading: false,
      create_new: false,
      edit_record: null,
    };
  },
  computed: {
    sortOptions() {
      return this.fields
        .filter((f) => f.sortable)
        .map((f) => {
          return { text: f.label, value: f.key };
        });
    },
  },
  mounted() {
    this.totalRows = this.helpers.length;
  },
  watch: {
    $route(to, from) {
      this.showCreateModal();
    }
  },
  created: function () {
    this.showCreateModal();
    this.$eventBus.$on("SellerRegistrationHelperSaved", (message) => {
      this.showMessage("success", message);
      this.getHelpers();
    });
    this.getHelpers();
  },
  methods: {
    getHelpers() {
      this.isLoading = true;
      axios.get(this.$apiUrl + "/seller_registration_helper").then((response) => {
        this.isLoading = false;
        let data = response.data;
        this.helpers = data.data;
        this.totalRows = this.helpers.length;
      });
    },

    deleteHelper(index, id) {
      this.$swal
        .fire({
          title: "Are you Sure?",
          text: "You won't be able to revert this",
          confirmButtonText: "Yes, Sure",
          cancelButtonText: "Cancel",
          icon: "warning",
          showCancelButton: true,
          confirmButtonColor: "#9AC444",
          cancelButtonColor: "#d33",
        })
        .then((result) => {
          if (result.value) {
            this.isLoading = true;
            let postData = {
              id: id,
            };
            axios
              .post(this.$apiUrl + "/seller_registration_helper/delete/" + id, postData)
              .then((response) => {
                this.isLoading = false;
                let data = response.data;
                this.helpers.splice(index, 1);
                this.showMessage("success", data.message);
              })
              .catch((error) => {
                this.isLoading = false;
                if (error.request.statusText) {
                  this.showMessage("error", error.request.statusText);
                } else if (error.message) {
                  this.showMessage("error", error.message);
                } else {
                  this.showMessage("error", __("something_went_wrong"));
                }
              });
          }
        });
    },

    showCreateModal() {
      if (this.$route.query.create == "true") {
        this.create_new = true;
      }
    },

    hideModal() {
      this.create_new = false;
      this.edit_record = null;
      let query = Object.assign({}, this.$route.query);
      delete query.create;
      this.$router.replace({ query });
    },
  },
};
</script>

<style scoped>
.btn_refresh {
    margin-top: 28px;
}
</style>
