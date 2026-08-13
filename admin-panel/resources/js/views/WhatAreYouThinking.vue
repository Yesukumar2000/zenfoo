<template>
    <div class="container-fluid">
        <!-- Page Heading with Breadcrumbs -->
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>What are you thinking?</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">Dashboard</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                What are you thinking?
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

        <div class="row">
            <div class="col-12">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <div>
                            <h4 class="card-title mb-0">What are you thinking?</h4>
                            <p class="text-muted mb-0">Manage your thinking items</p>
                        </div>
                        <div>
                            <button class="btn btn-warning me-2" @click="openTitleModal">
                                <i class="fa fa-pencil me-2"></i>Change the Title
                            </button>
                            <router-link to="/what-are-you-thinking/create" class="btn btn-primary">
                                <i class="fa fa-plus me-2"></i>Add New Item
                            </router-link>
                        </div>
                    </div>
                    <div class="card-body">
                        <!-- Loading State -->
                        <div v-if="loading" class="text-center py-5">
                            <b-spinner variant="primary" label="Loading..."></b-spinner>
                            <p class="mt-2">Loading items...</p>
                        </div>

                        <!-- Data Table -->
                        <div v-else class="table-responsive">
                            <table class="table table-striped table-hover">
                                <thead class="table-light">
                                    <tr>
                                        <th>#</th>
                                        <th>Image</th>
                                        <th>Name</th>
                                        <th>Category</th>
                                        <th>Status</th>
                                        <th>Created Date</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr v-if="thinkingItems.length === 0">
                                        <td colspan="7" class="text-center py-4">
                                            <i class="fa fa-inbox fa-3x text-muted mb-3 d-block"></i>
                                            <p class="text-muted">No items found. Add your first thinking item!</p>
                                        </td>
                                    </tr>
                                    <tr v-for="(item, index) in thinkingItems" :key="item.id">
                                        <td>{{ index + 1 }}</td>
                                        <td>
                                            <img
                                                :src="item.img_url || item.category?.image || '/images/placeholder.png'"
                                                alt="Item Image"
                                                class="img-thumbnail"
                                                style="width: 60px; height: 60px; object-fit: cover;"
                                            >
                                        </td>
                                        <td>
                                            <strong>{{ item.name }}</strong>
                                        </td>
                                        <td>
                                            <div class="d-flex align-items-center">
                                                <!-- <img
                                                    v-if="item.category?.image"
                                                    :src="item.category.image"
                                                    alt="Category"
                                                    class="me-2"
                                                    style="width: 30px; height: 30px; object-fit: cover; border-radius: 4px;"
                                                > -->
                                                <span>{{ item.category?.name || 'N/A' }}</span>
                                            </div>
                                        </td>
                                        <td>
                                            <div class="form-check form-switch">
                                                <input
                                                    class="form-check-input"
                                                    type="checkbox"
                                                    :checked="item.status == 1"
                                                    @change="toggleStatus(item)"
                                                    :id="'status-' + item.id"
                                                >
                                                <label class="form-check-label" :for="'status-' + item.id">
                                                    <span :class="item.status == 1 ? 'badge bg-success' : 'badge bg-danger'">
                                                        {{ item.status == 1 ? 'Active' : 'Inactive' }}
                                                    </span>
                                                </label>
                                            </div>
                                        </td>
                                        <td>{{ formatDate(item.created_at) }}</td>
                                        <td>
                                            <router-link
                                                :to="'/what-are-you-thinking/edit/' + item.id"
                                                class="btn btn-sm btn-info me-2"
                                                title="Edit"
                                            >
                                                <i class="fa fa-edit"></i>
                                            </router-link>
                                            <button
                                                @click="confirmDelete(item)"
                                                class="btn btn-sm btn-danger"
                                                title="Delete"
                                            >
                                                <i class="fa fa-trash"></i>
                                            </button>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <!-- Change Title Modal -->
        <b-modal
            v-model="showTitleModal"
            title="Change the Title"
            @ok="updateTitle"
            ok-title="Update"
            :ok-disabled="titleSaving"
        >
            <div class="form-group">
                <label for="titleInput" class="form-label">Title</label>
                <input
                    type="text"
                    id="titleInput"
                    class="form-control"
                    v-model="titleValue"
                    placeholder="Enter the title"
                >
            </div>
        </b-modal>
    </div>
</template>

<script>
import axios from 'axios';

export default {
    name: 'WhatAreYouThinking',
    data() {
        return {
            thinkingItems: [],
            loading: true,
            showTitleModal: false,
            titleValue: '',
            titleSaving: false
        };
    },
    mounted() {
        this.fetchItems();
    },
    methods: {
        fetchItems() {
            this.loading = true;
            axios.get(this.$apiUrl + '/thinking-items')
                .then(response => {
                    if (response.data.status === 1) {
                        this.thinkingItems = response.data.data;
                    } else {
                        this.showMessage('error', response.data.message || 'Failed to load items');
                    }
                })
                .catch(error => {
                    console.error('Error fetching thinking items:', error);
                    this.showMessage('error', 'An error occurred while loading items');
                })
                .finally(() => {
                    this.loading = false;
                });
        },

        toggleStatus(item) {
            axios.post(this.$apiUrl + '/thinking-items/toggle-status', {
                id: item.id
            })
            .then(response => {
                if (response.data.status === 1) {
                    // Toggle the status in the UI
                    item.status = item.status == 1 ? 0 : 1;
                    this.showMessage('success', response.data.message);
                } else {
                    this.showMessage('error', response.data.message || 'Failed to update status');
                }
            })
            .catch(error => {
                console.error('Error toggling status:', error);
                this.showMessage('error', 'An error occurred while updating status');
            });
        },

        confirmDelete(item) {
            if (confirm(`Are you sure you want to delete "${item.name}"?`)) {
                this.deleteItem(item.id);
            }
        },

        deleteItem(id) {
            axios.delete(this.$apiUrl + '/thinking-items/' + id)
                .then(response => {
                    if (response.data.status === 1) {
                        this.showMessage('success', response.data.message);
                        this.fetchItems(); // Refresh the list
                    } else {
                        this.showMessage('error', response.data.message || 'Failed to delete item');
                    }
                })
                .catch(error => {
                    console.error('Error deleting item:', error);
                    this.showMessage('error', 'An error occurred while deleting item');
                });
        },

        openTitleModal() {
            this.titleSaving = false;
            axios.get(this.$apiUrl + '/settings')
                .then(response => {
                    if (response.data.status === 1) {
                        this.titleValue = response.data.data.settings_map.what_are_you_thinking || '';
                    }
                })
                .catch(error => {
                    console.error('Error fetching title setting:', error);
                });
            this.showTitleModal = true;
        },

        updateTitle(bvModalEvent) {
            bvModalEvent.preventDefault();
            this.titleSaving = true;
            axios.post(this.$apiUrl + '/settings/update', {
                variable: 'what_are_you_thinking',
                value: this.titleValue
            })
            .then(response => {
                if (response.data.status === 1) {
                    this.showMessage('success', 'Title updated successfully');
                    this.showTitleModal = false;
                } else {
                    this.showMessage('error', response.data.message || 'Failed to update title');
                }
            })
            .catch(error => {
                console.error('Error updating title:', error);
                this.showMessage('error', 'An error occurred while updating the title');
            })
            .finally(() => {
                this.titleSaving = false;
            });
        },

        formatDate(date) {
            if (!date) return 'N/A';
            const options = { year: 'numeric', month: 'short', day: 'numeric' };
            return new Date(date).toLocaleDateString('en-US', options);
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

.text-muted {
    color: #6c757d !important;
}

.table-responsive {
    border-radius: 8px;
    overflow: hidden;
}

.table thead {
    background-color: #f8f9fa;
}

.table-hover tbody tr:hover {
    background-color: #f5f5f5;
}

.btn-primary {
    background-color: #007bff;
    border-color: #007bff;
}

.btn-primary:hover {
    background-color: #0056b3;
    border-color: #0056b3;
}

.img-thumbnail {
    border-radius: 8px;
}

.form-check-input {
    cursor: pointer;
}

.form-check-input:checked {
    background-color: #28a745;
    border-color: #28a745;
}
</style>
