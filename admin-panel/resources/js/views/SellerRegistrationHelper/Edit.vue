<template>
  <b-modal ref="my-modal" :title="modal_title" @hidden="$emit('modalClose')" size="lg" scrollable no-close-on-backdrop no-fade static>
    <div slot="modal-footer">
      <b-button variant="primary" @click="$refs['dummy_submit'].click()" :disabled="isLoading">
        {{ __('save') }}
        <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
      </b-button>
      <b-button variant="secondary" @click="hideModal">{{ __('cancel') }}</b-button>
    </div>
    <form ref="my-form" @submit.prevent="saveRecord">
      <div class="row">
        <label><span class="text-danger text-xs">*</span> {{__('required_fields')}}</label>

        <div class="form-group col-md-12">
          <label> {{ __('name') }}<i class="text-danger">*</i></label>
          <input type="text" class="form-control" v-model="name" :placeholder="__('enter_name')" required />
        </div>

        <div class="form-group col-md-12">
          <label> {{ __('description') }}</label>
          <textarea class="form-control" v-model="description" :placeholder="__('enter_product_description')" rows="4"></textarea>
        </div>

        <div class="form-group col-md-6">
          <label>{{ __('store') }}<i class="text-danger">*</i></label>
          <div class="store-dropdown">
            <div class="dropdown-header" @click="showStoreDropdown = !showStoreDropdown">
              <span v-if="!selectedStore" class="text-muted">Select Store</span>
              <span v-else>{{ storesList.find(s => s.id === selectedStore) ? storesList.find(s => s.id === selectedStore).name : selectedStore }}</span>
              <i class="fa fa-chevron-down float-end"></i>
            </div>
            <div class="dropdown-menu-custom" v-if="showStoreDropdown">
              <div v-for="store in storesList" :key="store.id" class="custom-select-item" @click="selectStore(store.id)">
                <input type="radio" :checked="selectedStore === store.id" />
                {{ store.name }}
              </div>
              <div v-if="storesList.length === 0" class="text-center p-3">
                <span>{{ __('loading') }}...</span>
              </div>
            </div>
          </div>
        </div>

        <div class="form-group col-md-6">
          <label> {{ __('categories') }}</label>
          <b-form-tags
            v-model="categories"
            separator=","
            :placeholder="__('add_category')"
            remove-on-delete
            class="mb-2"
          ></b-form-tags>
          <small class="text-muted">Type and Press Enter to add category</small>
        </div>

        <div class="form-group col-md-12">
          <label>{{ __('image') }}</label>
          <span v-if="error" class="error d-block">{{ error }}</span>
          <input type="file" accept="image/*" name="image" v-on:change="handleFileUpload" ref="file_image" class="file-input">
          <div class="file-input-div bg-gray-100" @click="$refs.file_image.click()" @drop="dropFile" @dragover="$dragoverFile" @dragleave="$dragleaveFile">
            <template v-if="image && image.name !== ''">
              <label>{{ __('selected_file_name') }} {{ image.name }}</label>
            </template>
            <template v-else>
              <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
              <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
            </template>
          </div>
          <div class="row mt-3" v-if="image_url">
            <div class="col-md-4">
              <img class="custom-image img-fluid" :src="image_url" :title="__('image')" :alt="__('image')" style="max-height: 200px;"/>
            </div>
          </div>
        </div>

      </div>
      <button ref="dummy_submit" style="display:none;"></button>
    </form>
  </b-modal>
</template>

<script>
import axios from "axios";

export default {
  props: ["record"],
  data: function () {
    return {
      isLoading: false,
      id: this.record ? this.record.id : "",
      name: this.record ? this.record.name : "",
      description: this.record ? this.record.description : "",
      selectedStore: this.record && this.record.stores ? parseInt(this.record.stores.split(',')[0]) : null,
      categories: this.record && this.record.categories ? this.record.categories : [],
      image: "",
      image_url: this.record && this.record.image_url ? this.record.image_url : "",
      error: null,
      storesList: [],
      showStoreDropdown: false,
    };
  },
  computed: {
    modal_title() {
      return this.record ? 'Edit Seller Registration Helper' : 'Add Seller Registration Helper';
    },
  },
  mounted() {
    this.$refs["my-modal"].show();
    this.getStores();
    // Add click outside listener
    document.addEventListener('click', this.handleClickOutside);
  },
  beforeDestroy() {
    // Remove click outside listener
    document.removeEventListener('click', this.handleClickOutside);
  },
  methods: {
    handleClickOutside(event) {
      const dropdown = this.$el.querySelector('.store-dropdown');
      if (dropdown && !dropdown.contains(event.target)) {
        this.showStoreDropdown = false;
      }
    },
    hideModal() {
      this.$refs["my-modal"].hide();
    },

    handleFileUpload(event) {
      this.image = event.target.files[0];
      if (this.image) {
        this.image_url = URL.createObjectURL(this.image);
      }
    },

    dropFile(event) {
      event.preventDefault();
      event.stopPropagation();
      const files = event.dataTransfer.files;
      if (files.length > 0) {
        this.image = files[0];
        this.image_url = URL.createObjectURL(this.image);
      }
      event.target.classList.remove('drag-over');
    },

    getStores() {
      axios.get(this.$apiUrl + '/get-all-stores-data').then((response) => {
        this.storesList = response.data || [];
      }).catch((error) => {
        console.error('Error fetching stores:', error);
      });
    },

    selectStore(storeId) {
      this.selectedStore = storeId;
      this.showStoreDropdown = false;
    },

    saveRecord() {
      this.error = null;

      if (!this.selectedStore) {
        this.error = 'Please select a store.';
        return;
      }

      this.isLoading = true;

      const formData = new FormData();
      formData.append("name", this.name);
      formData.append("description", this.description || "");
      formData.append("stores", String(this.selectedStore));
      formData.append("categories", JSON.stringify(this.categories));

      if (this.image && typeof this.image !== 'string') {
        formData.append("image", this.image);
      }

      let url = this.$apiUrl + "/seller_registration_helper/save";
      let method = "post";

      if (this.id) {
        url = this.$apiUrl + "/seller_registration_helper/update/" + this.id;
        formData.append("id", this.id);
      }

      axios({
        method: method,
        url: url,
        data: formData,
        headers: {
          "Content-Type": "multipart/form-data",
        },
      })
        .then((response) => {
          this.isLoading = false;
          let data = response.data;
          this.$eventBus.$emit("SellerRegistrationHelperSaved", data.message);
          this.hideModal();
        })
        .catch((error) => {
          this.isLoading = false;
          if (error.response && error.response.data && error.response.data.message) {
            this.error = error.response.data.message;
          } else if (error.request && error.request.statusText) {
            this.error = error.request.statusText;
          } else if (error.message) {
            this.error = error.message;
          } else {
            this.error = __("something_went_wrong");
          }
        });
    },
  },
};
</script>

<style scoped>
.file-input {
  display: none;
}

.file-input-div {
  border: 2px dashed #ccc;
  border-radius: 8px;
  padding: 40px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
}

.file-input-div:hover {
  border-color: #9AC444;
  background-color: #f8f9fa;
}

.file-input-div.drag-over {
  border-color: #9AC444;
  background-color: #e9ecef;
}

.file-input-div label {
  display: block;
  margin: 5px 0;
  cursor: pointer;
  color: #666;
}

.file-input-div i {
  color: #9AC444;
}

.custom-image {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 5px;
}

.error {
  color: red;
  font-size: 12px;
}

.store-dropdown {
  position: relative;
}

.dropdown-header {
  border: 1px solid var(--bs-border-color);
  border-radius: 4px;
  padding: 10px 15px;
  background: var(--bs-body-bg);
  color: var(--bs-body-color);
  cursor: pointer;
  transition: border-color 0.3s;
}

.dropdown-header:hover {
  border-color: #9AC444;
}

.dropdown-menu-custom {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  max-height: 250px;
  overflow-y: auto;
  background: var(--bs-body-bg);
  border: 1px solid var(--bs-border-color);
  border-radius: 4px;
  box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  z-index: 1000;
  margin-top: 5px;
}

.custom-select-item {
  padding: 10px 15px;
  cursor: pointer;
  transition: background-color 0.2s;
  display: flex;
  align-items: center;
  gap: 10px;
  color: var(--bs-body-color);
}

.custom-select-item:hover {
  background-color: var(--bs-tertiary-bg);
}

.custom-select-item input[type="radio"] {
  cursor: pointer;
  pointer-events: none;
}
</style>
