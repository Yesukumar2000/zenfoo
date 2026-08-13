<template>
    <div>
        <!-- Page Heading -->
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>{{ page_title }}</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item">
                                <router-link to="/manage_category_group">Category Groups</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                {{ page_title }}
                            </li>
                        </ol>
                    </nav>
                </div>
            </div>
        </div>

        <div class="row mb-3">
            <div class="col-12">
                <router-link to="/manage_category_group" class="btn btn-secondary btn-sm">
                    <i class="fa fa-arrow-left me-1"></i> Back to List
                </router-link>
            </div>
        </div>

        <!-- Form Card -->
        <div class="card">
            <div class="card-header">
                <h4>{{ page_title }}</h4>
                <router-link to="/manage_category_group" class="btn btn-secondary float-end">
                    <i class="fa fa-arrow-left"></i> {{ __('back') }}
                </router-link>
            </div>

            <div class="card-body">
                <form ref="my-form" @submit.prevent="saveGroup">
                    <div class="row">

                        <div class="form-group col-md-6">
                            <label>Group Name</label>
                            <i class="text-danger">*</i>
                            <input
                                type="text"
                                class="form-control"
                                v-model="name"
                                required
                                placeholder="Enter group name"
                            >
                        </div>

                        <div class="form-group col-md-6">
                            <label>Image</label>
                            <i class="text-danger">*</i>
                            <input
                                type="file"
                                @change="onFileChange"
                                class="form-control"
                                :required="!id"
                            >
                            <small class="form-text text-muted" v-if="id">Leave empty to keep current image</small>
                        </div>

                        <!-- Image Preview -->
                        <div class="form-group col-md-12" v-if="imagePreview">
                            <label>Image Preview</label>
                            <div>
                                <img
                                    :src="imagePreview"
                                    alt="Category Group Image"
                                    style="max-width: 200px; max-height: 200px; object-fit: contain; border: 1px solid #ddd; padding: 5px; border-radius: 4px;"
                                >
                            </div>
                        </div>

                        <div class="form-group col-12">
                            <label>Status</label><br>
                            <div class="form-check form-check-inline">
                                <input
                                    class="form-check-input"
                                    type="radio"
                                    name="status"
                                    value="1"
                                    v-model="status"
                                    id="status-active"
                                >
                                <label class="form-check-label" for="status-active">Active</label>
                            </div>
                            <div class="form-check form-check-inline">
                                <input
                                    class="form-check-input"
                                    type="radio"
                                    name="status"
                                    value="0"
                                    v-model="status"
                                    id="status-inactive"
                                >
                                <label class="form-check-label" for="status-inactive">Inactive</label>
                            </div>
                        </div>

                    </div>

                    <!-- Form Actions -->
                    <div class="row mt-4">
                        <div class="col-12 text-end">
                            <router-link to="/manage_category_group" class="btn btn-secondary me-2">
                                <i class="fa fa-times"></i> Cancel
                            </router-link>
                            <button type="submit" class="btn btn-primary" :disabled="isLoading">
                                <i class="fa fa-save"></i>
                                {{ isLoading ? 'Saving...' : (id ? 'Update' : 'Save') }}
                                <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</template>

<script>
import axios from 'axios';

export default {
    name: 'CreateCategoryGroup',
    props: ['id'],
    data() {
        return {
            name: '',
            image: null,
            imagePreview: null,
            status: 1,
            isLoading: false
        }
    },
    computed: {
        page_title() {
            return this.id ? 'Edit Category Group' : 'Add Category Group';
        }
    },
    created() {
        // If editing, load the category group data
        if (this.id) {
            this.loadCategoryGroup();
        }
    },
    methods: {
        loadCategoryGroup() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/group-category/' + this.id + '/edit')
                .then(response => {
                    if (response.data.status === 1) {
                        const data = response.data.data;
                        this.name = data.name;
                        this.status = data.status;
                        this.imagePreview = data.image_url;
                    }
                    this.isLoading = false;
                })
                .catch(err => {
                    this.isLoading = false;
                    this.showMessage('error', err.message || "Failed to load category group");
                });
        },
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
        saveGroup() {
            this.isLoading = true;
            let formData = new FormData();
            formData.append('name', this.name);
            formData.append('status', this.status);
            if (this.image) formData.append('image', this.image);

            let url = this.id
                ? this.$apiUrl + '/group-category/update/' + this.id
                : this.$apiUrl + '/group-category/save';

            axios.post(url, formData)
                .then(res => {
                    if (res.data.status === 1) {
                        this.showMessage('success', res.data.message);
                        this.$router.push({ path: '/manage_category_group' });
                    } else {
                        this.showMessage('error', res.data.message);
                    }
                    this.isLoading = false;
                })
                .catch(err => {
                    this.isLoading = false;
                    this.showMessage('error', err.message || "Something went wrong!");
                });
        },
        showMessage(type, message) {
            this.$swal.fire({
                icon: type,
                title: message,
                timer: 1500,
                showConfirmButton: false
            });
        }
    }
}
</script>

<style scoped>
.form-check-inline {
    margin-right: 20px;
}
</style>
