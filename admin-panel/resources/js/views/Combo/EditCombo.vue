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
                <router-link to="/manage_combos">{{ __('manage_combos') }}</router-link>
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
                  <label>{{ __('name') }}</label>
                  <input
                    type="text"
                    class="form-control"
                    v-model="name"
                    required
                    :placeholder="__('enter_combo_name')"
                  />
                </div>

                <!-- Price -->
                <!-- <div class="form-group col-md-6">
                  <label>{{ __('price') }}</label>
                  <input
                    type="number"
                    class="form-control"
                    step="0.01"
                    required
                    v-model="price"
                    :placeholder="__('enter_price')"
                  />
                </div> -->

                <div class="form-group col-md-6">
                  <label>Sub Heading<span class="text-danger">*</span></label>

                  <div class="d-flex">
                    <select class="form-control form-select" v-model="type_id" required>
                      <option value="">Select Sub Heading</option>
                      <option
                        v-for="row in comboTypes"
                        :key="row.id"
                        :value="row.id"
                      >
                        {{ row.name_of_type }}
                      </option>
                    </select>

                    <!-- Pencil Icon -->
                    <button
                      type="button"
                      class="btn btn-outline-secondary ms-2"
                      @click="openEditTypePopup"
                    >
                      <i class="fa fa-pencil-alt"></i>
                    </button>
                  </div>
                </div>

                <div class="form-group col-md-6">
                  <label>Group <span class="text-danger">*</span></label>

                  <div class="d-flex">
                    <select class="form-control form-select" v-model="category_id" required>
                      <option value="">Select Group</option>
                      <option
                        v-for="row in comboCategories"
                        :key="row.id"
                        :value="row.id"
                      >
                        {{ row.name }}
                      </option>
                    </select>

                    <!-- Pencil Icon -->
                    <button
                      type="button"
                      class="btn btn-outline-secondary ms-2"
                      @click="openEditCategoryPopup"
                    >
                      <i class="fa fa-pencil-alt"></i>
                    </button>
                  </div>
                </div>

                <div class="form-group col-md-6">
                  <label>Stores<span class="text-danger">*</span></label>

                  <div class="border rounded p-2" style="max-height:180px; overflow-y:auto">
                    <div
                      v-for="store in filteredStores"
                      :key="store.id"
                      class="form-check"
                    >
                      <input
                        class="form-check-input"
                        type="checkbox"
                        :value="store.id"
                        :checked="store_ids.includes(store.id)"
                        @change="handleStoreChange(store, $event)"
                        :id="'store_' + store.id"
                      />

                      <label
                        class="form-check-label"
                        :for="'store_' + store.id"
                      >
                        {{ store.name }}
                      </label>
                    </div>
                  </div>
                </div>

                <!-- CASCADING CATEGORY DROPDOWNS -->
                <div class="col-12 mt-3">
                  <div class="card mb-3 p-3">
                    <h6 class="mb-3">Filter Products by Category</h6>
                    <div class="row">
                      <!-- CATEGORY GROUP -->
                      <div class="col-md-4">
                        <label>Category Group</label>
                        <select v-model="selectedCategoryGroup" @change="onCategoryGroupChange" class="form-control form-select">
                          <option value="">All Category Groups</option>
                          <option v-for="c in categoryGroups" :key="c.id" :value="c.id">
                            {{ c.name }}
                          </option>
                        </select>
                      </div>

                      <!-- SUB CATEGORY GROUP -->
                      <div class="col-md-4">
                        <label>Sub Category Group</label>
                        <select v-model="selectedSubCategoryGroup" @change="onSubCategoryGroupChange" class="form-control form-select">
                          <option value="">All Sub Category Groups</option>
                          <option v-for="sub in subCategoryGroups" :key="sub.id" :value="sub.id">
                            {{ sub.name }}
                          </option>
                        </select>
                      </div>

                      <!-- CATEGORY -->
                      <div class="col-md-4">
                        <label>Category</label>
                        <select v-model="selectedCategory" @change="onCategoryChange" class="form-control form-select">
                          <option value="">All Categories</option>
                          <option v-for="cat in categories" :key="cat.id" :value="cat.id">
                            {{ cat.name }}
                          </option>
                        </select>
                      </div>
                    </div>
                  </div>
                </div>
                <!-- END CASCADING CATEGORY DROPDOWNS -->



                <!-- Description -->
                <div class="form-group col-md-12">
                  <label>{{ __('description') }}</label>
                  <textarea
                    class="form-control"
                    rows="3"
                    v-model="description"
                    :placeholder="__('enter_description')"
                  ></textarea>
                </div>

                <!-- IMAGE UPLOAD -->
                <div class="form-group col-md-6">
                  <label>{{ __('image') }}</label>
                  <p class="text-muted">Please choose square image between 350×350 and 550×550 pixels.</p>
                  <span v-if="error" class="text-danger">{{ error }}</span>

                  <input
                    type="file"
                    accept="image/*"
                    ref="file_image"
                    class="file-input"
                    @change="handleFileUpload"
                  />
                  <div
                    class="file-input-div bg-gray-100"
                    @click="$refs.file_image.click()"
                    @drop="dropFile"
                    @dragover.prevent
                    @dragleave.prevent
                  >
                    <template v-if="image && image.name !== ''">
                      <label>Selected file: {{ image.name }}</label>
                    </template>
                    <template v-else>
                      <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                      <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                    </template>
                  </div>

                  <div class="row" v-if="image_url">
                    <div class="col-md-4 mt-2">
                      <img class="custom-image" :src="image_url" height="70" />
                    </div>
                  </div>
                </div>

                <!-- VIDEO UPLOAD -->
                <div class="form-group col-md-6">
                  <label>{{ __('banner_video') }} Video (Optional)</label>
                  <p class="text-muted">Maximum file size: 20MB. Accepted formats: MP4, AVI, MOV, WMV</p>
                  <span v-if="videoError" class="text-danger">{{ videoError }}</span>

                  <input
                    type="file"
                    accept="video/mp4,video/avi,video/mov,video/x-ms-wmv"
                    ref="file_video"
                    class="file-input"
                    @change="handleVideoUpload"
                  />
                  <div
                    class="file-input-div bg-gray-100"
                    @click="$refs.file_video.click()"
                    @drop="dropVideoFile"
                    @dragover.prevent
                    @dragleave.prevent
                  >
                    <template v-if="video && video.name !== ''">
                      <label>Selected file: {{ video.name }}</label>
                    </template>
                    <template v-else>
                      <label><i class="fa fa-video fa-2x"></i></label>
                      <label>{{ __('drop_video_here_or_click_to_upload') }}</label>
                    </template>
                  </div>

                  <div class="row" v-if="video_url">
                    <div class="col-md-8 mt-2">
                      <video class="custom-video" :src="video_url" height="100" controls></video>
                    </div>
                  </div>
                </div>

                <!-- SELECTED PRODUCTS SECTION -->
                <div class="col-md-12 mt-4" v-if="product_ids.length > 0">
                  <div class="card border-success">
                    <div class="card-header bg-success text-white d-flex justify-content-between align-items-center">
                      <h6 class="mb-0">
                        <i class="fa fa-check-circle me-2"></i>
                        Selected Products ({{ product_ids.length }})
                      </h6>
                      <button type="button" class="btn btn-sm btn-outline-light" @click="clearAllSelections">
                        Clear All
                      </button>
                    </div>
                    <div class="card-body" style="max-height: 300px; overflow-y: auto;">
                      <div
                        v-for="pid in product_ids"
                        :key="'selected_' + pid"
                        class="d-flex align-items-center mb-2 p-2 rounded selected-product-row"
                      >
                        <img
                          :src="getSelectedProductData(pid, 'image_url')"
                          width="40"
                          height="40"
                          class="me-2 rounded"
                        />

                        <!-- Product Name -->
                        <div style="flex: 1; color: cadetblue; font-weight: 500;">
                          {{ getSelectedProductData(pid, 'name') }}
                        </div>

                        <!-- VARIANT SELECT for selected product (centered) -->
                        <div style="flex: 1;" class="text-center">
                          <div v-if="getSelectedProductVariants(pid).length > 1">
                            <select
                              class="form-select form-select-sm"
                              v-model="selectedVariants[pid]"
                              style="width: 200px; display: inline-block;"
                            >
                              <option
                                v-for="v in getSelectedProductVariants(pid)"
                                :key="v.id"
                                :value="v.id"
                              >
                                {{ v.measurement }} {{ v.unit.short_code }} -
                                Rs. {{ v.discounted_price || v.price }}
                              </option>
                            </select>
                          </div>

                          <!-- Single variant display -->
                          <div v-else-if="getSelectedProductVariants(pid).length === 1">
                            <small class="text-muted">
                              {{ getSelectedProductVariants(pid)[0].measurement }}
                              {{ getSelectedProductVariants(pid)[0].unit.short_code }}
                              - Rs. {{ getSelectedProductVariants(pid)[0].discounted_price || getSelectedProductVariants(pid)[0].price }}
                            </small>
                          </div>
                        </div>

                        <!-- Quantity Input -->
                        <input
                          type="number"
                          v-model.number="quantities[pid]"
                          min="1"
                          class="form-control ms-2"
                          style="width: 80px;"
                          placeholder="Qty"
                        />

                        <!-- Remove button -->
                        <button
                          type="button"
                          class="btn btn-sm btn-outline-danger ms-2"
                          @click="removeSelectedProduct(pid)"
                        >
                          <i class="fa fa-times"></i>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
                <!-- END SELECTED PRODUCTS SECTION -->

                <!-- BROWSE & ADD PRODUCTS SECTION -->
                <div class="col-md-12 mt-4 mb-4">
                  <div class="card">
                    <div class="card-header bg-primary text-white">
                      <h6 class="mb-0">
                        <i class="fa fa-search me-2"></i>
                        Browse & Add Products
                      </h6>
                    </div>
                    <div class="card-body">
                      <!-- SEARCH BAR -->
                      <div class="mt-2 mb-3">
                        <input
                          type="text"
                          v-model="search"
                          class="form-control"
                          placeholder="Search products..."
                        />
                      </div>

                      <!-- PRODUCT LIST (WITH VARIANTS) -->
                      <div style="max-height: 400px; overflow-y: auto;">
                        <div
                          v-for="p in paginatedProducts"
                          :key="p.id"
                          class="d-flex align-items-center mb-3 border-bottom pb-2"
                          :class="{ 'bg-light-success': product_ids.includes(p.id) }"
                        >
                          <input
                            type="checkbox"
                            :value="p.id"
                            :checked="product_ids.includes(p.id)"
                            @change="toggleProductSelection(p, $event)"
                            class="me-2"
                          />

                          <img
                            :src="p.image_url"
                            width="40"
                            height="40"
                            class="me-2 rounded"
                          />

                          <div class="flex-grow-1">
                            <div style="color: cadetblue;">
                              {{ p.name }}
                              <span v-if="product_ids.includes(p.id)" class="badge bg-success ms-2">Selected</span>
                            </div>

                            <!-- VARIANT SELECT -->
                            <div v-if="p.variants && p.variants.length > 1">
                              <select
                                class="form-select form-select-sm mt-1"
                                v-model="selectedVariants[p.id]"
                                :disabled="!product_ids.includes(p.id)"
                              >
                                <option
                                  v-for="v in p.variants"
                                  :key="v.id"
                                  :value="v.id"
                                >
                                  {{ v.measurement }} {{ v.unit.short_code }} -
                                  Rs. {{ v.discounted_price || v.price }}
                                </option>
                              </select>
                            </div>

                            <!-- Single variant display -->
                            <div v-else-if="p.variants && p.variants.length === 1">
                              <small>
                                {{ p.variants[0].measurement }} {{ p.variants[0].unit.short_code }}
                                - Rs. {{ p.variants[0].discounted_price || p.variants[0].price }}
                              </small>
                            </div>
                          </div>

                          <!-- Quantity Input -->
                          <input
                            type="number"
                            v-model.number="quantities[p.id]"
                            min="1"
                            class="form-control w-25 ms-2"
                            placeholder="Qty"
                            :disabled="!product_ids.includes(p.id)"
                          />
                        </div>

                        <div v-if="filteredProducts.length === 0" class="text-center text-muted py-4">
                          No products found. Try changing the filters or search term.
                        </div>
                      </div>

                      <!-- Pagination controls -->
                      <div class="d-flex justify-content-between align-items-center mt-3" v-if="filteredProducts.length > 0">
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
                  </div>
                </div>
                <!-- END BROWSE & ADD PRODUCTS SECTION -->

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



    <!-- Edit Combo Type Popup -->
    <div class="modal fade" id="editTypeModal" tabindex="-1">
      <div class="modal-dialog">
        <div class="modal-content">

          <div class="modal-header">
            <h5 class="modal-title">Edit Combo Types</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>

          <div class="modal-body">

            <!-- List of types -->
            <div v-for="row in comboTypes" :key="row.id" class="d-flex mb-2">

              <input
                type="text"
                v-model="row.name_of_type"
                class="form-control"
              />

              <button
                class="btn btn-primary ms-2"
                @click="editSingleType(row)"
              >
                <i class="fa fa-save"></i>
              </button>

              <button
                class="btn btn-danger ms-2"
                @click="deleteComboType(row.id)"
              >
                <i class="fa fa-trash"></i>
              </button>

            </div>

            <!-- Add New Type -->
            <hr>
            <h6>Add New Type</h6>

            <input
              type="text"
              class="form-control"
              v-model="typeName"
              placeholder="Enter type"
            >

            <button
              class="btn btn-success mt-2"
              @click="addOrEditComboType"
            >
              Add
            </button>

          </div>

        </div>
      </div>
    </div>

    <!-- Edit Combo Category Popup -->
    <div class="modal fade" id="editCategoryModal" tabindex="-1">
      <div class="modal-dialog">
        <div class="modal-content">

          <div class="modal-header">
            <h5 class="modal-title">Edit Combo Categories</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>

          <div class="modal-body">

            <!-- List of categories -->
            <div v-for="row in comboCategories" :key="row.id" class="d-flex mb-2">

              <input
                type="text"
                v-model="row.name"
                class="form-control"
              />

              <button
                class="btn btn-primary ms-2"
                @click="editSingleCategory(row)"
              >
                <i class="fa fa-save"></i>
              </button>

              <button
                class="btn btn-danger ms-2"
                @click="deleteComboCategory(row.id)"
              >
                <i class="fa fa-trash"></i>
              </button>

            </div>

            <!-- Add New Category -->
            <hr>
            <h6>Add New Category</h6>

            <input
              type="text"
              class="form-control"
              v-model="categoryName"
              placeholder="Enter category"
            >

            <button
              class="btn btn-success mt-2"
              @click="addOrEditComboCategory"
            >
              Add
            </button>

          </div>

        </div>
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
      isPrefilling: false,
      type_id: "",
      category_id: "",
      store_ids: [],
      status: 1,
      image: null,
      image_url: null,
      error: null,
      video: null,
      video_url: null,
      videoError: null,
      isLoading: false,
      products: [],
      product_ids: [],
      quantities: {},
      selectedVariants: {},
      currentPage: 1,
      pageSize: 10,

      comboTypes: [],
      comboCategories: [],
      stores: [],

      typeName: "",
      editTypeId: null,

      categoryName: "",
      editCategoryId: null,

      comboData: null, // Temporary storage for combo data during edit mode

      // Cascading category filter dropdowns
      categoryGroups: [],
      subCategoryGroups: [],
      categories: [],
      selectedCategoryGroup: "",
      selectedSubCategoryGroup: "",
      selectedCategory: "",

      // Store full product data for selected products (persists across filter changes)
      selectedProductsData: {},

    };
  },
  computed: {
    isEdit() {
      return !!this.id;
    },
    filteredStores() {
      return this.stores.filter((store) => store.managed_by_admin === true);
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

  mounted() {
    this.loadComboTypes();
    this.loadComboCategories();
    this.loadStores();
  },

  watch: {
    // Watcher removed - store changes now handled by handleStoreChange method
  },
  methods: {
    goBack() {
      this.$router.push({ path: "/manage_combos" });
    },

    // Handle store checkbox change with confirmation for deselection
    async handleStoreChange(store, event) {
      const isChecked = event.target.checked;
      const storeId = store.id;
      const storeName = store.name;

      if (isChecked) {
        // Adding a store - no confirmation needed
        this.store_ids.push(storeId);
        this.refreshStoreData();
      } else {
        // Deselecting a store - check if there are products from this store
        const productsFromStore = this.product_ids.filter(pid => {
          const productData = this.selectedProductsData[pid];
          return productData && productData.store_id == storeId;
        });

        if (productsFromStore.length > 0) {
          // Show confirmation popup
          const result = await this.$swal.fire({
            title: 'Deselect Store?',
            html: `If you deselect <strong>"${storeName}"</strong>, the following <strong>${productsFromStore.length} product(s)</strong> selected from this store will be removed from your selection.`,
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#d33',
            cancelButtonColor: '#3085d6',
            confirmButtonText: 'Yes, deselect store',
            cancelButtonText: 'Cancel'
          });

          if (result.isConfirmed) {
            // Remove products from this store
            productsFromStore.forEach(pid => {
              this.removeSelectedProduct(pid);
            });

            // Remove store from selection
            const index = this.store_ids.indexOf(storeId);
            if (index > -1) {
              this.store_ids.splice(index, 1);
            }

            this.refreshStoreData();

            this.$swal.fire({
              title: 'Store Deselected',
              text: `${productsFromStore.length} product(s) have been removed from your selection.`,
              icon: 'success',
              timer: 2000,
              showConfirmButton: false
            });
          } else {
            // User cancelled - revert checkbox state
            event.target.checked = true;
          }
        } else {
          // No products from this store - just remove it
          const index = this.store_ids.indexOf(storeId);
          if (index > -1) {
            this.store_ids.splice(index, 1);
          }
          this.refreshStoreData();
        }
      }
    },

    // Refresh category groups and products after store change
    refreshStoreData() {
      // Reset cascading dropdowns
      this.categoryGroups = [];
      this.subCategoryGroups = [];
      this.categories = [];
      this.selectedCategoryGroup = "";
      this.selectedSubCategoryGroup = "";
      this.selectedCategory = "";

      if (!this.store_ids.length) {
        this.products = [];
        return;
      }

      const storeIdsString = this.store_ids.join(",");

      // Load category groups for selected stores
      this.loadCategoryGroupsForStores(storeIdsString);

      // Load products
      this.loadProductsByStores(storeIdsString);
    },

    fetchProducts() {
      if (!this.id) {
        axios.get(`${this.$apiUrl}/combos/products`)
          .then((res) => {
            const products = res.data.data ?? res.data.products ?? [];
            this.products = products;

            this.products.forEach((p) => {
              this.quantities[p.id] = 0;
              // Use image_url from API if already set, otherwise construct it
              if (!p.image_url) {
                if (p.image) {
                  // Check if image is already a full URL
                  p.image_url = p.image.startsWith('http') ? p.image : `${this.$baseUrl}/storage/${p.image}`;
                } else {
                  p.image_url = "/images/no-image.png";
                }
              }
            });
          });

        return;
      }

      // ✅ EDIT MODE
      axios.get(`${this.$apiUrl}/combos/${this.id}/edit`)
        .then((res) => {
          const combo = res.data.combo;

          this.name = combo.name || "";
          this.description = combo.description || "";
          this.price = combo.price || "";
          this.type_id = combo.type_id || "";
          this.category_id = combo.category_type || "";
          this.status = combo.status ?? 1;
          this.image_url = combo.image_url || null;
          this.video_url = combo.video_url || null;

          // ✅ prevent watcher overwrite
          this.isPrefilling = true;

          this.store_ids = combo.store_id
            ? combo.store_id.split(",").map(i => parseInt(i))
            : [];

          this.comboData = combo;

          // ✅ Load category groups for the stores (since watcher is disabled during prefilling)
          if (this.store_ids.length > 0) {
            this.loadCategoryGroupsForStores(this.store_ids.join(","));
          }

          // ✅ Load products then prefill
          this.loadProductsByStores(this.store_ids.join(","), true);
        });
    },


    loadComboTypes() {
      axios
        .get(`${this.$apiUrl}/get-all-combo-types`)
        .then((res) => {
          if (res.data.status) {
            this.comboTypes = res.data.data;
          }
        })
        .catch((err) => {
          console.error("Failed to load combo types:", err);
        });
    },

    loadStores() {
      axios
        .get(`${this.$apiUrl}/get-all-stores-data`)
        .then((res) => {
          this.stores = res.data || [];
        })
        .catch((err) => {
          console.error("Failed to load stores:", err);
        });
    },

    // Load category groups for selected stores
    loadCategoryGroupsForStores(storeIds) {
      axios.get(`${this.$apiUrl}/get-all-four-dropdowns`, {
        params: { store_id: storeIds }
      }).then((res) => {
        const d = res.data.store_data;
        this.categoryGroups = d.categories_data || [];
      }).catch((err) => {
        console.error("Failed to load category groups:", err);
      });
    },

    // When category group changes
    onCategoryGroupChange() {
      this.subCategoryGroups = [];
      this.categories = [];
      this.selectedSubCategoryGroup = "";
      this.selectedCategory = "";

      if (!this.selectedCategoryGroup) {
        // If cleared, reload all products for selected stores
        this.loadProductsByStores(this.store_ids.join(","));
        return;
      }

      axios.get(`${this.$apiUrl}/get-all-four-dropdowns`, {
        params: {
          store_id: this.store_ids.join(","),
          category_group_id: this.selectedCategoryGroup
        }
      }).then((res) => {
        const d = res.data.store_data;
        this.subCategoryGroups = d.sub_category_groups_data || [];

        // Reload products with category group filter
        this.loadProductsByStores(this.store_ids.join(","));
      });
    },

    // When sub category group changes
    onSubCategoryGroupChange() {
      this.categories = [];
      this.selectedCategory = "";

      if (!this.selectedSubCategoryGroup) {
        // If cleared, reload products with current filters
        this.loadProductsByStores(this.store_ids.join(","));
        return;
      }

      axios.get(`${this.$apiUrl}/get-all-four-dropdowns`, {
        params: {
          store_id: this.store_ids.join(","),
          category_group_id: this.selectedCategoryGroup,
          sub_category_group_id: this.selectedSubCategoryGroup
        }
      }).then((res) => {
        const d = res.data.store_data;
        this.categories = d.categories || [];

        // Reload products with sub category group filter
        this.loadProductsByStores(this.store_ids.join(","));
      });
    },

    // When category changes
    onCategoryChange() {
      // Reload products with category filter
      this.loadProductsByStores(this.store_ids.join(","));
    },

    loadProductsByStores(storeIds, isEditMode = false) {
      const params = { store_ids: storeIds };

      // Add category filters if selected
      if (this.selectedCategoryGroup) {
        params.category_group_id = this.selectedCategoryGroup;
      }
      if (this.selectedSubCategoryGroup) {
        params.sub_category_group_id = this.selectedSubCategoryGroup;
      }
      if (this.selectedCategory) {
        params.category_id = this.selectedCategory;
      }

      axios.get(`${this.$apiUrl}/combos/products`, {
        params: params
      }).then((res) => {

        this.products = res.data.products || res.data.data || [];

        this.products.forEach((p) => {
          // Use image_url from API if already set, otherwise construct it
          if (!p.image_url) {
            if (p.image) {
              // Check if image is already a full URL
              p.image_url = p.image.startsWith('http') ? p.image : `${this.$baseUrl}/storage/${p.image}`;
            } else {
              p.image_url = "/images/no-image.png";
            }
          }
        });

        if (isEditMode && this.comboData) {
          const combo = this.comboData;

          this.product_ids = [];
          this.selectedVariants = {};
          this.quantities = {};
          this.selectedProductsData = {};

          combo.products.forEach((cp) => {
            const pid = cp.id;

            this.product_ids.push(pid);
            this.selectedVariants[pid] = cp.pivot.variant_id;
            this.quantities[pid] = cp.pivot.quantity;

            // Store product data for selected products
            // Use image_url from API if already set, otherwise construct it
            if (!cp.image_url) {
              if (cp.image) {
                // Check if image is already a full URL
                cp.image_url = cp.image.startsWith('http') ? cp.image : `${this.$baseUrl}/storage/${cp.image}`;
              } else {
                cp.image_url = "/images/no-image.png";
              }
            }
            this.$set(this.selectedProductsData, pid, cp);
          });

          this.comboData = null;
          this.isPrefilling = false;
        }
        // Don't reset selections when filtering - keep them persistent
      });
    },

    // Toggle product selection (add or remove)
    toggleProductSelection(product, event) {
      const pid = product.id;
      const isChecked = event.target.checked;

      if (isChecked) {
        // Add product
        if (!this.product_ids.includes(pid)) {
          this.product_ids.push(pid);
          this.$set(this.quantities, pid, 1);
          if (product.variants && product.variants.length > 0) {
            this.$set(this.selectedVariants, pid, product.variants[0].id);
          }
          // Store product data
          this.$set(this.selectedProductsData, pid, { ...product });
        }
      } else {
        // Remove product
        this.removeSelectedProduct(pid);
      }
    },

    // Remove a selected product
    removeSelectedProduct(pid) {
      const index = this.product_ids.indexOf(pid);
      if (index > -1) {
        this.product_ids.splice(index, 1);
      }
      this.$delete(this.quantities, pid);
      this.$delete(this.selectedVariants, pid);
      this.$delete(this.selectedProductsData, pid);
    },

    // Clear all selections
    clearAllSelections() {
      this.product_ids = [];
      this.quantities = {};
      this.selectedVariants = {};
      this.selectedProductsData = {};
    },

    // Get data for a selected product
    getSelectedProductData(pid, field) {
      const product = this.selectedProductsData[pid];
      if (product) {
        return product[field] || '';
      }
      // Fallback: try to find in current products list
      const p = this.products.find(prod => prod.id === pid);
      if (p) {
        return p[field] || '';
      }
      return '';
    },

    // Get variants for a selected product
    getSelectedProductVariants(pid) {
      const product = this.selectedProductsData[pid];
      if (product && product.variants) {
        return product.variants;
      }
      // Fallback: try to find in current products list
      const p = this.products.find(prod => prod.id === pid);
      if (p && p.variants) {
        return p.variants;
      }
      return [];
    },

    openEditTypePopup() {
      let modal = new bootstrap.Modal(document.getElementById("editTypeModal"));
      modal.show();
    },

    async editSingleType(row) {
      try {
        const payload = {
          name_of_type: row.name_of_type,
          type_id: row.id,
        };

        const response = await fetch(`${this.$apiUrl}/create-or-update-combo-type`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });

        const res = await response.json();

        if (res.status) {
          this.$swal.fire("Success", "Type updated", "success");
          this.loadComboTypes();
        }
      } catch (error) {
        console.error(error);
        this.$swal.fire("Error", "Failed to update type", "error");
      }
    },


    async deleteComboType(id) {
      const confirm = await this.$swal.fire({
        title: "Are you sure?",
        text: "This combo type will be permanently deleted.",
        icon: "warning",
        showCancelButton: true,
        confirmButtonText: "Yes, delete it!",
      });

      if (!confirm.isConfirmed) {
        return;
      }

      try {
        const response = await fetch(`${this.$apiUrl}/delete-the-combo-type`, {
          method: "DELETE",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ type_id: id }),
        });

        const res = await response.json();

        if (res.status) {
          this.$swal.fire("Deleted!", "Combo type removed.", "success");
          this.loadComboTypes();
        } else {
          this.$swal.fire("Error", "Failed to delete type", "error");
        }
      } catch (error) {
        console.error("Delete error:", error);
        this.$swal.fire("Error", "Server error", "error");
      }
    },


    async addOrEditComboType() {
      try {
        const payload = {
          name_of_type: this.typeName,
          type_id: this.editTypeId ?? null,
        };

        const response = await fetch(`${this.$apiUrl}/create-or-update-combo-type`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });

        const res = await response.json();

        if (res.status) {
          this.$swal.fire("Success", "Type saved successfully", "success");
          this.loadComboTypes();
          this.typeName = "";
          this.editTypeId = null;
        } else {
          this.$swal.fire("Error", res.message, "error");
        }
      } catch (error) {
        console.error("Failed to save type:", error);
        this.$swal.fire("Error", "Server error", "error");
      }
    },


    loadComboCategories() {
      axios
        .get(`${this.$apiUrl}/get-all-combo-categories`)
        .then((res) => {
          if (res.data.status) {
            this.comboCategories = res.data.data;
          }
        })
        .catch((err) => {
          console.error("Failed to load combo categories:", err);
        });
    },

    openEditCategoryPopup() {
      let modal = new bootstrap.Modal(document.getElementById("editCategoryModal"));
      modal.show();
    },

    async editSingleCategory(row) {
      try {
        const payload = {
          name_of_category: row.name,
          type_id: row.id,
        };

        const response = await fetch(`${this.$apiUrl}/create-or-update-combo-category`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });

        const res = await response.json();

        if (res.status) {
          this.$swal.fire("Success", "Category updated", "success");
          this.loadComboCategories();
        }
      } catch (error) {
        console.error(error);
        this.$swal.fire("Error", "Failed to update category", "error");
      }
    },

    async deleteComboCategory(id) {
      const confirm = await this.$swal.fire({
        title: "Are you sure?",
        text: "This combo category will be permanently deleted.",
        icon: "warning",
        showCancelButton: true,
        confirmButtonText: "Yes, delete it!",
      });

      if (!confirm.isConfirmed) {
        return;
      }

      try {
        const response = await fetch(`${this.$apiUrl}/delete-the-combo-category`, {
          method: "DELETE",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ type_id: id }),
        });

        const res = await response.json();

        if (res.status) {
          this.$swal.fire("Deleted!", "Combo category removed.", "success");
          this.loadComboCategories();
        } else {
          this.$swal.fire("Error", "Failed to delete category", "error");
        }
      } catch (error) {
        console.error("Delete error:", error);
        this.$swal.fire("Error", "Server error", "error");
      }
    },

    async addOrEditComboCategory() {
      try {
        const payload = {
          name_of_category: this.categoryName,
          type_id: this.editCategoryId ?? null,
        };

        const response = await fetch(`${this.$apiUrl}/create-or-update-combo-category`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        });

        const res = await response.json();

        if (res.status) {
          this.$swal.fire("Success", "Category saved successfully", "success");
          this.loadComboCategories();
          this.categoryName = "";
          this.editCategoryId = null;
        } else {
          this.$swal.fire("Error", res.message, "error");
        }
      } catch (error) {
        console.error("Failed to save category:", error);
        this.$swal.fire("Error", "Server error", "error");
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

    dropVideoFile(event) {
      event.preventDefault();
      this.$refs.file_video.files = event.dataTransfer.files;
      this.handleVideoUpload();
    },

    handleVideoUpload() {
      const file = this.$refs.file_video.files[0];
      this.videoError = null;
      if (!file) return;

      const validTypes = [
        "video/mp4",
        "video/avi",
        "video/quicktime",
        "video/x-ms-wmv",
      ];
      if (!validTypes.includes(file.type)) {
        this.videoError = "Invalid video file type. Please upload MP4, AVI, MOV, or WMV.";
        return;
      }

      const maxSize = 20 * 1024 * 1024; // 20MB
      if (file.size > maxSize) {
        this.videoError = "Video file size exceeds 20MB.";
        return;
      }

      this.video = file;
      this.video_url = URL.createObjectURL(file);
    },

    saveCombo() {
      // Frontend validation
      if (!this.type_id) {
        this.$swal.fire("Validation Error", "Please select a combo type", "error");
        return;
      }

      if (!this.store_ids.length) {
        this.$swal.fire("Validation Error", "Please select at least one store", "error");
        return;
      }


      if (!this.product_ids || this.product_ids.length === 0) {
        this.$swal.fire("Validation Error", "Please select at least one product", "error");
        return;
      }

      this.isLoading = true;
      const formData = new FormData();

      if (this.id) formData.append("id", this.id);
      formData.append("name", this.name);
      formData.append("description", this.description);
      formData.append("price", this.price);
      formData.append("type_id", this.type_id);
      formData.append("category_id", this.category_id);
      
      // formData.append("store_id", this.store_id);

      formData.append("store_ids", this.store_ids.join(","));

      formData.append("status", this.status);

      if (this.image) formData.append("image", this.image);
      if (this.video) formData.append("banner_video", this.video);

      // this.product_ids.forEach((id) => {
      //   formData.append("product_ids[]", id);

      //   // variant_id (if any)
      //   const variantId =
      //     this.selectedVariants[id] ||
      //     (this.products.find((p) => p.id === id)?.variants?.[0]?.id ?? null);

      //   if (variantId) formData.append(`variant_ids[${id}]`, variantId);
      //   formData.append(`quantities[${id}]`, this.quantities[id] || 1);
      // });

      this.product_ids.forEach((id) => {
        formData.append("product_ids[]", id);

        // Look for variant in selectedVariants, then in selectedProductsData, then in current products
        let variantId = this.selectedVariants[id];
        if (!variantId) {
          const selectedProduct = this.selectedProductsData[id];
          if (selectedProduct && selectedProduct.variants && selectedProduct.variants.length > 0) {
            variantId = selectedProduct.variants[0].id;
          } else {
            const currentProduct = this.products.find((p) => p.id === id);
            if (currentProduct && currentProduct.variants && currentProduct.variants.length > 0) {
              variantId = currentProduct.variants[0].id;
            }
          }
        }

        formData.append(`variant_ids[${id}]`, variantId || '');
        formData.append(`quantities[${id}]`, this.quantities[id] || 1);
      });


      const url = this.isEdit
        ? `${this.$apiUrl}/combos/${this.id}`
        : `${this.$apiUrl}/combos/save`;

      axios
        .post(url, formData)
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
.custom-video {
  border-radius: 5px;
  border: 1px solid #ddd;
  max-width: 100%;
}
.file-input-div {
  padding: 20px;
  border: 2px dashed #ccc;
  text-align: center;
  cursor: pointer;
}
.file-input {
  display: none;
}
.bg-light-success {
  background-color: rgba(40, 167, 69, 0.1) !important;
  border-left: 3px solid #28a745 !important;
}
/* Selected product row - light mode */
.selected-product-row {
  background-color: #f8f9fa;
  border: 1px solid #dee2e6;
}
</style>

<!-- Non-scoped styles for dark mode support -->
<style>
/* Dark theme support for EditCombo */
.theme-dark .selected-product-row {
  background-color: #2d2d2d !important;
  border: 1px solid #444 !important;
}

.theme-dark .selected-product-row div {
  color: #e0e0e0 !important;
}

.theme-dark .border-success .card-body {
  background-color: #1e1e1e;
}

.theme-dark .border-primary .card-body {
  background-color: #1e1e1e;
}

.theme-dark .file-input-div {
  background-color: #2d2d2d !important;
  border-color: #444 !important;
}

.theme-dark .file-input-div label {
  color: #e0e0e0 !important;
}
</style>
