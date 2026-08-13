<template>
    <b-modal ref="my-modal" :title="modal_title" @hidden="$emit('modalClose')" size="xl" scrollable no-close-on-backdrop no-fade static>
        <div slot="modal-footer">
            <b-button variant="primary" @click="$refs['dummy_submit'].click()" :disabled="isLoading">
                Save
                <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
            </b-button>
            <b-button variant="secondary" @click="hideModal">Cancel</b-button>
        </div>

        <template #modal-header="{ close }">
            <h5 v-if="id" class="modal-title">{{ modal_title }} & Group: <strong>{{ name }}</strong></h5>
            <h5 v-else class="modal-title">{{ modal_title }}</h5>
            <button type="button" aria-label="Close" class="close" @click="close()">×</button>
        </template>

        <form ref="my-form" @submit.prevent="saveGroup">
            <div class="row">

                <div class="form-group col-md-6">
                    <label>Group Name</label>
                    <i class="text-danger">*</i>
                    <input type="text" class="form-control" v-model="name" required placeholder="Enter group name">
                </div>

               

                <div class="form-group col-md-6">
                    <label>Image</label>
                    <input type="file" :required="!id" @change="onFileChange" class="form-control">
                    <small class="form-text text-muted" v-if="id">Leave empty to keep current image</small>
                </div>

                <!-- Image Preview -->
                <div class="form-group col-md-12" v-if="imagePreview">
                    <label>Current Image</label>
                    <div>
                        <img :src="imagePreview" alt="Category Group Image" style="max-width: 200px; max-height: 200px; object-fit: contain; border: 1px solid #ddd; padding: 5px; border-radius: 4px;">
                    </div>
                </div>

                <div class="form-group col-12">
                    <label>Status</label><br>
                    <div class="form-check form-check-inline">
                        <input class="form-check-input" type="radio" name="status" value="1" v-model="status">
                        <label class="form-check-label">Active</label>
                    </div>
                    <div class="form-check form-check-inline">
                        <input class="form-check-input" type="radio" name="status" value="0" v-model="status">
                        <label class="form-check-label">Inactive</label>
                    </div>
                </div>

            </div>
            <button ref="dummy_submit" style="display:none;"></button>
        </form>
    </b-modal>
</template>

<script>
import axios from 'axios';

export default {
    props: ['record'],
    data() {
        return {
            id: this.record ? this.record.id : null,
            name: this.record ? this.record.name : '',
            image: null,
            imagePreview: this.record && this.record.image_url ? this.record.image_url : null,
            status: this.record ? this.record.status : 1,
            isLoading: false
        }
    },
    computed: {
        modal_title() {
            return this.id ? 'Edit Category Group' : 'Add Category Group';
        }
    },
    created() {
    },
    methods: {
        onFileChange(event) {
            this.image = event.target.files[0];
            // Update preview with new image
            if (this.image) {
                const reader = new FileReader();
                reader.onload = (e) => {
                    this.imagePreview = e.target.result;
                };
                reader.readAsDataURL(this.image);
            }
        },
        showModal() {
            this.$refs['my-modal'].show();
        },
        hideModal() {
            this.$refs['my-modal'].hide();
        },
        saveGroup() {
            this.isLoading = true;
            let formData = new FormData();
            // if(this.id) formData.append('id', this.id);
            formData.append('name', this.name);
            formData.append('status', this.status);
            if(this.image) formData.append('image', this.image);

            let url = this.id ? this.$apiUrl + '/group-category/update/'+ this.id : this.$apiUrl + '/group-category/save';

            axios.post(url, formData)
                .then(res => {
                    if(res.data.status === 1) {
                        this.$emit('groupSaved', res.data.message);
                        this.hideModal();
                        this.isLoading = false;
                        this.$router.push({path: '/manage_category_group'});

                    } else {
                        this.showError(res.data.message);
                        this.isLoading = false;
                    }
                })
                .catch(err => {
                    this.isLoading = false;
                    this.showError(err.message || "Something went wrong!");
                });
        },
        showError(message) {
            alert(message); // replace with your toast/notification
        }
    },
    mounted() {
        this.showModal();
    }
}
</script>

<style scoped>
.form-check-inline {
    margin-right: 20px;
}
</style>
