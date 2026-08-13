<template>
    <div class="container-fluid">
        <!-- Page Heading with Breadcrumbs -->
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Edit Thinking Item</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">Dashboard</router-link>
                            </li>
                            <li class="breadcrumb-item">
                                <router-link to="/what-are-you-thinking">What are you thinking?</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                Edit
                            </li>
                        </ol>
                    </nav>
                </div>
            </div>
        </div>

        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <div class="d-flex justify-content-between align-items-center">
                            <h4 class="card-title mb-0">Edit Thinking Item</h4>
                            <router-link to="/what-are-you-thinking" class="btn btn-secondary">
                                <i class="fa fa-arrow-left me-2"></i>Back to List
                            </router-link>
                        </div>
                    </div>
                    <div class="card-body">
                        <!-- Loading State -->
                        <div v-if="loading" class="text-center py-5">
                            <b-spinner variant="primary" label="Loading..."></b-spinner>
                            <p class="mt-2">Loading item details...</p>
                        </div>

                        <!-- Edit Form -->
                        <form v-else @submit.prevent="submitForm">
                            <div class="row">
                                <!-- Store ID (Hidden - Default 15) -->
                                <input type="hidden" v-model="form.store_id" value="15">

                                <!-- Category Selection -->
                                <div class="col-md-6 mb-3">
                                    <label class="form-label">
                                        <strong>Select Category <span class="text-danger">*</span></strong>
                                    </label>
                                    <select
                                        v-model="form.category_id"
                                        @change="onCategoryChange"
                                        class="form-control form-select"
                                        required
                                    >
                                        <option value="">Choose Category...</option>
                                        <option
                                            v-for="category in categories"
                                            :key="category.id"
                                            :value="category.id"
                                        >
                                            {{ category.name }}
                                        </option>
                                    </select>
                                    <small class="text-muted">Select a category from store 15</small>
                                </div>

                                <!-- Name (Auto-filled from Category) -->
                                <div class="col-md-6 mb-3">
                                    <label class="form-label">
                                        <strong>Name <span class="text-danger">*</span></strong>
                                    </label>
                                    <input
                                        type="text"
                                        v-model="form.name"
                                        class="form-control"
                                        placeholder="Auto-filled from category"
                                        readonly
                                        required
                                    >
                                    <small class="text-muted">Name is automatically taken from the selected category</small>
                                </div>

                                <!-- Current Image -->
                                <div class="col-md-12 mb-3">
                                    <label class="form-label">
                                        <strong>Current Image</strong>
                                    </label>
                                    <div>
                                        <img
                                            :src="currentImage || '/images/placeholder.png'"
                                            alt="Current Image"
                                            class="img-thumbnail"
                                            style="max-width: 300px; max-height: 300px;"
                                        >
                                    </div>
                                </div>

                                <!-- Upload New Image -->
                                <div class="col-md-12 mb-3">
                                    <label class="form-label">
                                        <strong>Upload New Image (Optional)</strong>
                                    </label>
                                    <input
                                        type="file"
                                        @change="handleImageUpload"
                                        class="form-control"
                                        accept="image/*"
                                    >
                                    <small class="text-muted">Supported formats: JPG, PNG, GIF. Max size: 2MB. Leave empty to keep current image.</small>

                                    <!-- New Image Preview -->
                                    <div v-if="imagePreview" class="mt-3">
                                        <p class="mb-2"><strong>New Image Preview:</strong></p>
                                        <img :src="imagePreview" alt="Preview" class="img-thumbnail" style="max-width: 300px; max-height: 300px;">
                                    </div>
                                </div>

                                <!-- Selected Category Preview -->
                                <div v-if="selectedCategory" class="col-md-12 mb-3">
                                    <div class="alert alert-info">
                                        <h6 class="mb-2"><strong>Selected Category:</strong></h6>
                                        <div class="d-flex align-items-center">
                                            <!-- <img
                                                v-if="selectedCategory.image"
                                                :src="selectedCategory.image"
                                                alt="Category"
                                                class="me-3"
                                                style="width: 80px; height: 80px; object-fit: cover; border-radius: 8px;"
                                            > -->
                                            <div>
                                                <p class="mb-0"><strong>{{ selectedCategory.name }}</strong></p>
                                                <small class="text-muted">Category ID: {{ selectedCategory.id }}</small>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Submit Button -->
                                <div class="col-md-12">
                                    <div class="d-flex justify-content-end gap-2">
                                        <router-link to="/what-are-you-thinking" class="btn btn-secondary">
                                            Cancel
                                        </router-link>
                                        <button type="submit" class="btn btn-primary" :disabled="isSubmitting">
                                            <b-spinner v-if="isSubmitting" small class="me-2"></b-spinner>
                                            <i v-else class="fa fa-save me-2"></i>
                                            {{ isSubmitting ? 'Updating...' : 'Update Item' }}
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import axios from 'axios';

export default {
    name: 'EditThinkingItem',
    data() {
        return {
            form: {
                id: null,
                store_id: 15,
                category_id: '',
                name: '',
                image: null
            },
            categories: [],
            selectedCategory: null,
            currentImage: null,
            imagePreview: null,
            loading: true,
            isSubmitting: false
        };
    },
    mounted() {
        this.fetchCategories();
        this.fetchItem();
    },
    methods: {
        fetchCategories() {
            axios.get(this.$apiUrl + '/thinking-items/categories')
                .then(response => {
                    if (response.data.status === 1) {
                        this.categories = response.data.data;
                    } else {
                        this.showMessage('error', 'Failed to load categories');
                    }
                })
                .catch(error => {
                    console.error('Error fetching categories:', error);
                    this.showMessage('error', 'An error occurred while loading categories');
                });
        },

        fetchItem() {
            const itemId = this.$route.params.id;
            axios.get(this.$apiUrl + '/thinking-items/' + itemId)
                .then(response => {
                    if (response.data.status === 1) {
                        const item = response.data.data;
                        this.form.id = item.id;
                        this.form.category_id = item.category_id;
                        this.form.name = item.name;
                        this.currentImage = item.img_url;

                        // Set selected category
                        if (item.category) {
                            this.selectedCategory = item.category;
                        }
                    } else {
                        this.showMessage('error', 'Failed to load item');
                        this.$router.push('/what-are-you-thinking');
                    }
                })
                .catch(error => {
                    console.error('Error fetching item:', error);
                    this.showMessage('error', 'An error occurred while loading item');
                    this.$router.push('/what-are-you-thinking');
                })
                .finally(() => {
                    this.loading = false;
                });
        },

        onCategoryChange() {
            const category = this.categories.find(c => c.id == this.form.category_id);
            if (category) {
                this.selectedCategory = category;
                this.form.name = category.name;
            } else {
                this.selectedCategory = null;
                this.form.name = '';
            }
        },

        handleImageUpload(event) {
            const file = event.target.files[0];
            if (file) {
                // Validate file size (2MB max)
                if (file.size > 2 * 1024 * 1024) {
                    this.showMessage('error', 'Image size should not exceed 2MB');
                    event.target.value = '';
                    return;
                }

                // Validate file type
                if (!file.type.startsWith('image/')) {
                    this.showMessage('error', 'Please select a valid image file');
                    event.target.value = '';
                    return;
                }

                this.form.image = file;

                // Create preview
                const reader = new FileReader();
                reader.onload = (e) => {
                    this.imagePreview = e.target.result;
                };
                reader.readAsDataURL(file);
            }
        },

        submitForm() {
            // Validation
            if (!this.form.category_id) {
                this.showMessage('error', 'Please select a category');
                return;
            }

            this.isSubmitting = true;

            // Create FormData for file upload
            const formData = new FormData();
            formData.append('id', this.form.id);
            formData.append('category_id', this.form.category_id);

            // Only append image if a new one is selected
            if (this.form.image) {
                formData.append('image', this.form.image);
            }

            axios.post(this.$apiUrl + '/thinking-items/update', formData, {
                headers: {
                    'Content-Type': 'multipart/form-data'
                }
            })
            .then(response => {
                if (response.data.status === 1) {
                    this.showMessage('success', response.data.message);
                    // Redirect to list page after 1 second
                    setTimeout(() => {
                        this.$router.push('/what-are-you-thinking');
                    }, 1000);
                } else {
                    this.showMessage('error', response.data.message || 'Failed to update item');
                }
            })
            .catch(error => {
                console.error('Error updating item:', error);
                this.showMessage('error', error.response?.data?.message || 'An error occurred while updating');
            })
            .finally(() => {
                this.isSubmitting = false;
            });
        }
    }
};
</script>

<style scoped>
.card {
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.card-title {
    color: #2c3e50;
    font-weight: 600;
}

.form-label {
    color: #495057;
    margin-bottom: 0.5rem;
}

.form-control:focus,
.form-select:focus {
    border-color: #007bff;
    box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
}

.text-danger {
    color: #dc3545 !important;
}

.img-thumbnail {
    border-radius: 8px;
    border: 2px solid #dee2e6;
}

.alert-info {
    background-color: #e7f3ff;
    border-color: #b3d7ff;
    color: #004085;
}

.gap-2 {
    gap: 0.5rem;
}

.btn-primary {
    background-color: #007bff;
    border-color: #007bff;
}

.btn-primary:hover:not(:disabled) {
    background-color: #0056b3;
    border-color: #0056b3;
}

.btn-primary:disabled {
    opacity: 0.65;
    cursor: not-allowed;
}

.btn-secondary {
    background-color: #6c757d;
    border-color: #6c757d;
}

.btn-secondary:hover {
    background-color: #545b62;
    border-color: #545b62;
}
</style>
