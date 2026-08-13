<template>
  <div>
    <!-- PAGE HEADING -->
    <div class="page-heading">
      <div class="row">
        <div class="col-12 col-md-6 order-md-1 order-last">
          <h3>
            <template v-if="id">{{ __('edit') }}</template>
            <template v-else>{{ __('create') }}</template>
            {{ __('combo') }}
          </h3>
        </div>

        <div class="col-12 col-md-6 order-md-2 order-first">
          <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
            <ol class="breadcrumb">
              <li class="breadcrumb-item">
                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
              </li>
              <li class="breadcrumb-item">
                <router-link to="/manage_combos">{{ __('manage_special_item') }}</router-link>
              </li>
              <li class="breadcrumb-item active" aria-current="page">
                <template v-if="id">{{ __('edit') }}</template>
                <template v-else>{{ __('create') }}</template>
                {{ __('combo') }}
              </li>
            </ol>
          </nav>
        </div>
      </div>
    </div>

    <div class="mb-3">
      <router-link to="/manage_combos" class="btn btn-secondary btn-sm">
        <i class="fa fa-arrow-left me-1"></i> Back to List
      </router-link>
    </div>

    <!-- COMBO FORM -->
    <div class="row">
      <div class="col-12">
        <form @submit.prevent="saveCombo" enctype="multipart/form-data">
          <div class="card">
            <div class="card-body">
              <div class="row">
                <!-- Name -->
                <div class="form-group col-md-6">
                  <label>{{ __('title') }}</label>
                  <input
                    type="text"
                    class="form-control"
                    v-model="name"
                    required
                    :placeholder="__('enter_special_title')"
                  />
                </div>

                <!-- PRODUCT LIST (PAGINATED) -->
                <div class="col-md-12 mt-3">
                  <div
                    v-for="p in paginatedProducts"
                    :key="p.id"
                    class="d-flex align-items-center mb-2 border-bottom pb-1"
                  >
                    <input type="checkbox" :value="p.id" v-model="product_ids" class="me-2" />
                    <img :src="p.image_url" width="40" height="40" class="me-2 rounded" />
                    <span class="flex-grow-1">{{ p.name }}</span>
                    <input
                      type="number"
                      v-model.number="quantities[p.id]"
                      min="1"
                      class="form-control w-25"
                      placeholder="Qty"
                      :disabled="!product_ids.includes(p.id)"
                    />
                  </div>

                  <!-- Pagination controls -->
                  <div class="d-flex justify-content-between align-items-center mt-3">
                    <div>
                      <small>Showing {{ startIndex + 1 }} - {{ endIndex }} of {{ filteredProducts.length }}</small>
                    </div>
                    <div>
                      <button
                        class="btn btn-sm btn-outline-primary me-1"
                        :disabled="currentPage === 1"
                        @click="currentPage--"
                        type="button"
                      >
                        Prev
                      </button>
                      <button
                        class="btn btn-sm btn-outline-primary"
                        :disabled="currentPage * pageSize >= filteredProducts.length"
                        @click="currentPage++"
                        type="button"
                      >
                        Next
                      </button>
                    </div>
                  </div>
                </div>

                <!-- STATUS -->
                <div class="form-group col-md-12 mt-4" v-if="id">
                  <label>{{ __('status') }}</label>
                  <b-form-radio-group
                    v-model="status"
                    :options="[
                      { text: 'Deactivated', value: 0 },
                      { text: 'Activated', value: 1 },
                    ]"
                    buttons
                    button-variant="outline-primary"
                  ></b-form-radio-group>
                </div>

                <!-- ACTION BUTTONS -->
                <div class="text-end mt-4">
                  <button type="submit" class="btn btn-primary" :disabled="isLoading">
                    {{ isEdit ? __('update') : __('save') }}
                    <b-spinner v-if="isLoading" small label="Saving..." class="ms-1"></b-spinner>
                  </button>

                  <button type="button" class="btn btn-secondary ms-2" @click="goBack">
                    {{ __('cancel') }}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import axios from "axios";

export default {
  props: ["id"],
  data() {
    return {
      search: "",
      name: "",
      description: "",
      price: "",
      type: "",
      status: 1,
      image: null,
      image_url: null,
      error: null,
      isLoading: false,
      products: [],
      product_ids: [],
      quantities: {},
      currentPage: 1,
      pageSize: 10,
    };
  },
  computed: {
    isEdit() {
      return !!this.id;
    },
    filteredProducts() {
      if (!this.search) return this.products;
      return this.products.filter((p) =>
        p.name.toLowerCase().includes(this.search.toLowerCase())
      );
    },
    paginatedProducts() {
      const start = (this.currentPage - 1) * this.pageSize;
      const end = start + this.pageSize;
      this.startIndex = start;
      this.endIndex = Math.min(end, this.filteredProducts.length);
      return this.filteredProducts.slice(start, end);
    },
  },
  created() {
    this.fetchProducts();
  },
  watch: {
    product_ids(newIds, oldIds) {
      newIds.forEach((id) => {
        if (!this.quantities[id] || this.quantities[id] === 0) {
          this.$set(this.quantities, id, 1);
        }
      });
      oldIds.forEach((id) => {
        if (!newIds.includes(id)) {
          this.$set(this.quantities, id, 0);
        }
      });
    },
  },
  methods: {
    goBack() {
      this.$router.push({ path: "/manage_combos" });
    },

    fetchProducts() {
      if (this.id) {
        axios
          .get(`${this.$apiUrl}/combos/${this.id}/edit`)
          .then((res) => {
            const combo = res.data.combo;
            const products = res.data.products || [];

            this.products = Array.isArray(products) ? products : [];
            this.name = combo.name || "";
            this.description = combo.description || "";
            this.price = combo.price || "";
            this.type = combo.type || "";
            this.status = combo.status ?? 1;
            this.image_url = combo.image_url || null;
            this.product_ids = combo.products.map((p) => p.id);

            this.quantities = {};
            this.products.forEach((p) => {
              const inCombo = combo.products.find((cp) => cp.id === p.id);
              this.quantities[p.id] = inCombo?.pivot?.quantity ?? 0;
              p.image_url = p.image
                ? `${this.$apiUrl}/storage/${p.image}`
                : "/images/no-image.png";
            });
          })
          .catch(() => this.showError("Failed to load combo details."));
      } else {
        axios
          .get(`${this.$apiUrl}/combos/products`)
          .then((res) => {
            const products = res.data.data ?? res.data.products ?? res.data ?? [];
            this.products = Array.isArray(products) ? products : [];
            this.products.forEach((p) => {
              this.quantities[p.id] = 0;
              p.image_url = p.image
                ? `${this.$apiUrl}/storage/${p.image}`
                : "/images/no-image.png";
            });
          })
          .catch(() => this.showError("Failed to load products."));
      }
    },

    dropFile(event) {
      event.preventDefault();
      this.$refs.file_image.files = event.dataTransfer.files;
      this.handleFileUpload();
    },

    handleFileUpload() {
      const file = this.$refs.file_image.files[0];
      this.error = null;
      if (!file) return;

      const validTypes = [
        "image/jpeg",
        "image/png",
        "image/jpg",
        "image/gif",
        "image/webp",
        "image/svg+xml",
      ];
      if (!validTypes.includes(file.type)) {
        this.error = "Invalid file type.";
        return;
      }

      const maxSize = 2 * 1024 * 1024;
      if (file.size > maxSize) {
        this.error = "File size exceeds 2MB.";
        return;
      }

      this.image = file;
      this.image_url = URL.createObjectURL(file);
    },

    saveCombo() {
      this.isLoading = true;
      const formData = new FormData();
      if (this.id) formData.append("id", this.id);
      formData.append("name", this.name);
      formData.append("description", this.description);
      formData.append("price", this.price);
      formData.append("type", this.type);
      if (this.image) formData.append("image", this.image);
      formData.append("status", this.status);

      this.product_ids.forEach((id) => {
        formData.append("product_ids[]", id);
        formData.append(`quantities[${id}]`, this.quantities[id] || 0);
      });

      const url = this.isEdit
        ? `${this.$apiUrl}/combos/save/${this.id}`
        : `${this.$apiUrl}/combos/save`;

      axios
        .post(url, formData, {
          headers: { "Content-Type": "multipart/form-data" },
        })
        .then((res) => {
          const data = res.data;
          if (data.status === 1) {
            this.$swal.fire("Success", data.message, "success");
            this.$router.push({ path: "/manage_combos" });
          } else {
            this.showError(data.message);
          }
        })
        .catch((error) => {
          this.showError(error.message || __("something_went_wrong"));
        })
        .finally(() => {
          this.isLoading = false;
        });
    },

    showError(message) {
      this.$swal.fire("Error", message, "error");
    },
  },
};
</script>

<style scoped>
.custom-image {
  border-radius: 5px;
  border: 1px solid #ddd;
}
.file-input-div {
  padding: 20px;
  border: 2px dashed #ccc;
  text-align: center;
  cursor: pointer;
}
</style>
