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
        <div class="divider mt-0"><div class="divider-text">Offer Details</div></div>

        <div class="form-group col-md-12">
          <label>Title<i class="text-danger">*</i></label>
          <input type="text" class="form-control" v-model="title" placeholder="Enter offer title" required />
        </div>

        <div class="form-group col-md-12">
          <label>Description<i class="text-danger">*</i></label>
          <textarea class="form-control" v-model="description" placeholder="Enter offer description" rows="3" required></textarea>
        </div>

        <div class="form-group col-md-6">
          <label>Order Count<i class="text-danger">*</i></label>
          <input type="number" class="form-control" v-model="order_count" placeholder="Enter order count" min="0" required />
        </div>

        <div class="form-group col-md-6">
          <label>Amount<i class="text-danger">*</i></label>
          <input type="number" step="0.01" class="form-control" v-model="amount" placeholder="Enter amount" min="0" required />
        </div>

        <div class="form-group col-md-6">
          <label>Start Date<i class="text-danger">*</i></label>
          <input type="date" class="form-control" v-model="start_date" @input="validateStartDate" required />
          <span v-if="validationStartDateError" class="text-danger">{{ validationStartDateError }}</span>
        </div>

        <div class="form-group col-md-6">
          <label>End Date<i class="text-danger">*</i></label>
          <input type="date" class="form-control" v-model="end_date" @input="validateEndDate" required />
          <span v-if="validationEndDateError" class="text-danger">{{ validationEndDateError }}</span>
        </div>

        <div class="form-group col-md-12">
          <label>Image<i class="text-danger">*</i></label>
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
                  <img class="custom-image" :src="image_url" title='Offer image' alt='Offer image' style="max-height: 150px;"/>
              </div>
          </div>
        </div>

        <!-- <div class="form-group col-md-12" v-if="id">
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
        </div> -->
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
      description: this.record ? this.record.description : "",
      order_count: this.record ? this.record.order_count : 0,
      amount: this.record ? this.record.amount : 0,
      start_date: this.record ? this.record.start_date : "",
      end_date: this.record ? this.record.end_date : "",
      status: this.record ? this.record.status : 1,
      image: "",
      image_url: this.record ? this.record.img_url : "",
      validationEndDateError: null,
      validationStartDateError: null,
      error: null,
      imageRequired: false,
    };
  },
  computed: {
    modal_title: function () {
      let title = this.id ? "Edit" : "Add";
      title += " Offer";
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
    validateStartDate() {
        if (this.end_date && this.start_date > this.end_date) {
            this.validationStartDateError = "Start date cannot be after the end date.";
            this.start_date = "";
        } else {
            this.validationStartDateError = null;
        }
    },
    validateEndDate() {
        if (this.start_date && this.end_date < this.start_date) {
            this.validationEndDateError = "End date must be equal or greater than start date.";
            this.end_date = "";
        } else {
            this.validationEndDateError = null;
        }
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
      formData.append("title", this.title);
      formData.append("description", this.description);
      formData.append("order_count", this.order_count);
      formData.append("amount", this.amount);
      formData.append("start_date", this.start_date);
      formData.append("end_date", this.end_date);
      formData.append("status", this.status);

      if (this.image) {
        formData.append("image", this.image);
      }

      let url = this.$apiUrl + "/zenfoo_offers/save";
      if (this.id) {
        url = this.$apiUrl + "/zenfoo_offers/update";
      }

      axios.post(url, formData, {
          headers: {
            "Content-Type": "multipart/form-data",
          },
        })
        .then((res) => {
          let data = res.data;

          if (data.status === 1) {
            this.$eventBus.$emit("OfferSaved", data.message);
            this.hideModal();
          } else {
            vm.showError(data.message);
            vm.isLoading = false;
          }
        }).catch((error) => {
          vm.isLoading = false;
          if (error.request.statusText) {
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