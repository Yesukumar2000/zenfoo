<template>
  <div>
    <div class="page-heading">
      <div class="row">
        <div class="col-12 col-md-6 order-md-1 order-last">
          <h3>Manage Offers</h3>
        </div>
        <div class="col-12 col-md-6 order-md-2 order-first">
          <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
            <ol class="breadcrumb">
              <li class="breadcrumb-item">
                  <router-link to="/dashboard">Dashboard</router-link>
              </li>
              <li class="breadcrumb-item active" aria-current="page">Manage Offers</li>
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
              <h4>Offers</h4>
              <span class="pull-right">
                <button class="btn btn-primary" @click="create_new=true">Add Offer</button>
              </span>
            </div>

            <div class="card-body">
              <b-row class="mb-2">
                <b-col md="3" offset-md="8">
                    <h6 class="box-title">Search</h6>
                  <b-form-input
                    id="filter-input"
                    v-model="filter"
                    type="search"
                    placeholder="Search"
                  ></b-form-input>
                </b-col>
                  <b-col md="1" class="text-center">
                      <button class="btn btn-primary btn_refresh" v-b-tooltip.hover title="Refresh" @click="getOffers()" >
                          <i class="fa fa-refresh" aria-hidden="true"></i>
                      </button>
                  </b-col>
              </b-row>
              <template>
                <div class="table-responsive">
                  <b-table
                    :items="offers"
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
                          <strong>Loading...</strong>
                      </div>
                  </template>

                  <template #cell(image)="row">
                      <img v-if="row.item.img_url" :src="row.item.img_url" height="50" />
                      <span v-else>-</span>
                  </template>

                  <!-- <template #cell(status)="row">
                      <label v-if="row.item.status === 1" class='badge bg-success'>Active</label>
                      <label v-else class='badge bg-danger'>Inactive</label>
                  </template> -->

                  <template #cell(validity)="row">
                      <label v-if="row.item.is_active === 1" class='badge bg-success'>{{ row.item.validity }}</label>
                      <label v-else class='badge bg-danger'>{{ row.item.validity }}</label>
                  </template>

                <template #cell(actions)="row">
                  <button class="btn btn-sm btn-primary" @click="edit_record = row.item" v-b-tooltip.hover title="Edit"><i class="fa fa-pencil-alt"></i></button>
                  <button class="btn btn-sm btn-danger" @click="deleteOffer(row.index, row.item.id)" v-b-tooltip.hover title="Delete"><i class="fa fa-trash"></i></button>
                </template>
              </b-table>
            </div>
          </template>
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
        // { key: "id", label: "ID", sortable: true, sortDirection: "desc" },
        { key: "title", label: "Title", sortable: true, class: "text-center" },
        { key: "description", label: "Description", sortable: false, class: "text-center" },
        { key: "image", label: "Image", class: "text-center" },
        { key: "order_count", label: "Order Count", sortable: true, class: "text-center" },
        { key: "amount", label: "Amount", sortable: true, class: "text-center" },
        { key: "start_date", label: "Start Date", sortable: true, class: "text-center" },
        { key: "end_date", label: "End Date", sortable: true, class: "text-center" },
        // { key: "status", label: "Status", sortable: true, class: "text-center" },
        { key: "validity", label: "Validity", sortable: false, class: "text-center" },
        { key: "actions", label: "Actions" },
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

      offers: [],
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
    this.totalRows = this.offers.length;
  },
  created: function () {
    this.$eventBus.$on("OfferSaved", (message) => {
      this.showMessage("success", message);
      this.getOffers();
    });
    this.getOffers();
  },
  methods: {
    getOffers() {
      this.isLoading = true;
      axios.get(this.$apiUrl + "/zenfoo_offers").then((response) => {
        this.isLoading = false;
        let data = response.data;
        this.offers = data.data;
        this.totalRows = this.offers.length;
      });
    },

    deleteOffer(index, id) {
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
            this.isLoading = true;
            let postData = {
              id: id,
            };
            axios
              .post(this.$apiUrl + "/zenfoo_offers/delete", postData)
              .then((response) => {
                this.isLoading = false;
                let data = response.data;
                this.offers.splice(index, 1);
                this.showMessage("success", data.message);
              });
          }
        });
    },

    hideModal() {
        this.create_new = false;
        this.edit_record = null;
    },
  },
};
</script>
