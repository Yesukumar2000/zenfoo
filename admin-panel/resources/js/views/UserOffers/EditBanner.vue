<template>
  <b-modal ref="my-modal" :title="modal_title" @hidden="$emit('modalClose')" size="lg" scrollable no-close-on-backdrop no-fade static>
    <div slot="modal-footer">
      <b-button variant="primary" @click="$refs['dummy_submit'].click()" :disabled="isLoading">
        Save
        <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
      </b-button>
      <b-button variant="secondary" @click="hideModal">Cancel</b-button>
    </div>
    <form ref="my-form" @submit.prevent="saveRecord">

      <div class="row">
        <label><span class="text-danger text-xs">*</span> Required fields</label>
        <div class="divider mt-0"><div class="divider-text">Banner Details</div></div>

        <div class="form-group col-md-8">
          <label>Title</label>
          <input type="text" class="form-control" v-model="title" placeholder="Enter banner title (optional)" />
        </div>

        <div class="form-group col-md-4">
          <label>Sort Order</label>
          <input type="number" class="form-control" v-model="sort_order" placeholder="0" min="0" />
        </div>

        <div class="form-group col-md-12">
          <label>Banner Image<i class="text-danger">*</i></label>
          <p class="text-muted">Please choose an image (JPEG, PNG, JPG, GIF, WEBP - Max 5MB)</p>
          <span v-if="error" class="text-danger">{{ error }}</span>
          <span v-if="imageRequired" class="text-danger">Image is required</span>
          <input type="file" accept="image/*" name="image" v-on:change="handleFileUpload" ref="file_image" class="file-input">
          <div class="file-input-div bg-gray-100" @click="$refs.file_image.click()" @drop="dropFile" @dragover="$dragoverFile" @dragleave="$dragleaveFile">
              <template v-if="image && image.name !== ''">
                  <label>Selected file: {{ image.name }}</label>
              </template>
              <template v-else>
                  <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                  <label>Drop files here or click to upload</label>
              </template>
          </div>
          <div class="row mt-2" v-if="image_url">
              <div class="col-md-4">
                  <img class="custom-image" :src="image_url" title='Banner image' alt='Banner image' style="max-height: 150px;"/>
              </div>
          </div>
        </div>

        <div class="form-group col-md-12" v-if="id">
          <label>Status<i class="text-danger">*</i></label>
          <div class="col-md-9 text-left mt-1">
            <b-form-radio-group
              v-model="status"
              :options="[
                { text: 'Inactive', 'value': 0 },
                { text: 'Active', 'value': 1 },
              ]"
              buttons
              button-variant="outline-primary"
              required
            ></b-form-radio-group>
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
      title: this.record ? this.record.title : "",
      sort_order: this.record ? this.record.sort_order : 0,
      status: this.record ? (this.record.status ? 1 : 0) : 1,
      image: "",
      image_url: this.record ? this.record.image_url : "",
      error: null,
      imageRequired: false,
    };
  },
  computed: {
    modal_title: function () {
      let title = this.id ? "Edit" : "Add";
      title += " Offer Banner";
      return title;
    },
  },
  methods: {
    showModal() {
      this.$refs["my-modal"].show();
    },
    hideModal() {
      this.$refs["my-modal"].hide();
    },
    dropFile(event) {
        event.preventDefault();
        this.$refs.file_image.files = event.dataTransfer.files;
        this.handleFileUpload();
        event.currentTarget.classList.add('bg-gray-100');
        event.currentTarget.classList.remove('bg-green-300');
    },
    handleFileUpload() {
      const file = this.$refs.file_image.files[0];

      this.error = null;

      if (!file) return;

      const validTypes = ["image/jpeg", "image/png", "image/jpg", "image/gif", "image/webp"];
      if (!validTypes.includes(file.type)) {
          this.error = "Invalid file type. Please upload a JPEG, PNG, JPG, GIF or WEBP image.";
          return;
      }

      const maxSize = 5 * 1024 * 1024; // 5MB
      if (file.size > maxSize) {
          this.error = "File size exceeds the maximum allowed limit (5MB).";
          return;
      }

      this.image = this.$refs.file_image.files[0];
      this.image_url = URL.createObjectURL(this.image);
    },
    saveRecord: function () {
      let vm = this;

      // Validate image is required (for new records or if no existing image)
      if (!this.id && !this.image) {
        this.imageRequired = true;
        return;
      }
      if (this.id && !this.image && !this.image_url) {
        this.imageRequired = true;
        return;
      }
      this.imageRequired = false;

      this.isLoading = true;
      let formData = new FormData();

      if (this.id) {
        formData.append("id", this.id);
      }
      formData.append("title", this.title || "");
      formData.append("sort_order", this.sort_order || 0);
      formData.append("status", this.status);

      if (this.image) {
        formData.append("image", this.image);
      }

      let url = this.$apiUrl + "/user_offers/banners/save";
      if (this.id) {
        url = this.$apiUrl + "/user_offers/banners/update";
      }

      axios.post(url, formData, {
          headers: {
            "Content-Type": "multipart/form-data",
          },
        })
        .then((res) => {
          let data = res.data;

          if (data.status === 1) {
            this.$eventBus.$emit("OfferBannerSaved", data.message);
            this.hideModal();
          } else {
            vm.showError(data.message);
            vm.isLoading = false;
          }
        }).catch((error) => {
          vm.isLoading = false;
          if (error.request && error.request.statusText) {
            this.showError(error.request.statusText);
          } else if (error.message) {
            this.showError(error.message);
          } else {
            this.showError("Something went wrong");
          }
        });
    },
  },
  mounted() {
    this.showModal();
  },
};
</script>

<style scoped>
.file-input {
  display: none;
}

.file-input-div {
  border: 2px dashed #ccc;
  padding: 20px;
  text-align: center;
  cursor: pointer;
  border-radius: 8px;
}

.file-input-div:hover {
  border-color: #9AC444;
}

.custom-image {
  max-width: 100%;
  border-radius: 8px;
}
</style>
