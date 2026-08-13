<template>
  <div>
    <!-- Page Heading -->
    <div class="page-heading">
      <div class="row">
        <div class="col-12 col-md-6 order-md-1 order-last">
          <h3>{{ __('manage_combos') }}</h3>
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
                {{ __('manage_combos') }}
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
      <div class="card-header d-flex justify-content-between align-items-center">
        <h4>{{ __('combo_packages') }}</h4>
       <template>
                                    <router-link to="/manage_combos/create" class="btn btn-primary" v-b-tooltip.hover title="Add Combo">{{ __('add_combo') }}</router-link>
                                </template>
      </div>

      <div class="card-body">
        <!-- Search -->
        <b-row class="mb-2">
          <b-col md="3" offset-md="8">
            <h6>{{ __('search') }}</h6>
            <b-form-input
              v-model="filter"
              type="search"
              :placeholder="__('search')"
              @input="getCombos"
            ></b-form-input>
          </b-col>
          <b-col md="1" class="text-center">
            <button
              class="btn btn-primary btn_refresh"
              v-b-tooltip.hover
              :title="__('refresh')"
              @click="getCombos"
            >
              <i class="fa fa-refresh" aria-hidden="true"></i>
            </button>
          </b-col>
        </b-row>

        <!-- Table -->
        <b-table
          :items="combos"
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
            :to="{ name: 'EditItem', params: { id: row.item.id } }"
            v-b-tooltip.hover
            :title="__('edit')"
          >
            <i class="fa fa-pencil-alt"></i>
          </router-link>

          <!-- Delete Button -->
          <button
            class="btn btn-sm btn-danger"
            @click="deleteCombo(row.index, row.item.id)"
            v-b-tooltip.hover
            :title="__('delete')"
          >
            <i class="fa fa-trash"></i>
          </button>
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
                @change="getCombos"
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
              @change="getCombos"
            ></b-pagination>
          </b-col>
        </b-row>
      </div>
    </div>

    <!-- Combo Modal -->
  </div>
</template>

<script>
import EditItem from "./EditItem.vue";

export default {
  name: "CombosList",
  components: { EditItem },
  data() {
    return {
      fields: [
        { key: "index", label: "S.No", class: "text-center" },
        { key: "Title", label: "Name", class: "text-center" },
      ],
      combos: [],
      totalRows: 0,
      currentPage: 1,
      perPage: 10,
      pageOptions: [10, 25, 50, 100],
      filter: "",
      isLoading: false,
    };
  },
  mounted() {
    this.getCombos();
    this.showCreateModal();

    // Listen for save events
    this.$eventBus.$on("comboSaved", (message) => {
      this.showMessage("success", message);
      this.getCombos();
      this.create_new = false;
    });
  },
  methods: {
    getCombos() {
        this.isLoading = true;
        const params = {
          page: this.currentPage,
          per_page: this.perPage,
          search: this.filter,
        };

        axios
          .get(this.$apiUrl + "/special", { params })
          .then((res) => {
            this.isLoading = false;

            const combos = res.data; // <-- plain array
            this.combos = combos.map((combo, i) => ({
              ...combo,
              index: (this.currentPage - 1) * this.perPage + i + 1,
            }));

            this.totalRows = combos.length; // <-- totalRows is just length for plain array
          })
          .catch(() => (this.isLoading = false));
      },


    deleteCombo(index, id) {
      this.$swal
        .fire({
          title: "Are you sure?",
          text: "You won't be able to revert this!",
          icon: "warning",
          showCancelButton: true,
          confirmButtonText: "Yes, delete it!",
          cancelButtonText: "Cancel",
        })
        .then((result) => {
          if (result.value) {
            axios.post(this.$apiUrl + "/special/delete", { id }).then(() => {
              this.combos.splice(index, 1);
              this.totalRows--;
              this.$swal.fire("Deleted!", "Combo deleted successfully.", "success");
            });
          }
        });
    },
  },
};
</script>
