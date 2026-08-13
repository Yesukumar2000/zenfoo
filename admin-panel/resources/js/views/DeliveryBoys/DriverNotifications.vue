<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Delivery Boy Notifications</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">Dashboard</router-link>
                            </li>
                            <li class="breadcrumb-item">
                                <router-link to="/delivery-boys">Delivery Boys</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">Notifications</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/delivery_boys" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <!-- Stats Cards -->
            <div class="row mb-4">
                <div class="col-md-3">
                    <div class="card">
                        <div class="card-body text-center">
                            <h6 class="text-muted">Total Notifications</h6>
                            <h3 class="text-primary">{{ stats.total_notifications }}</h3>
                        </div>
                    </div>
                </div>
                <!-- <div class="col-md-3">
                    <div class="card">
                        <div class="card-body text-center">
                            <h6 class="text-muted">Active Delivery Boys</h6>
                            <h3 class="text-success">{{ stats.total_active_delivery_boys }}</h3>
                        </div>
                    </div>
                </div> -->
                <div class="col-md-3">
                    <div class="card">
                        <div class="card-body text-center">
                            <h6 class="text-muted">Last 30 Days</h6>
                            <h3 class="text-info">{{ stats.notifications_last_30_days }}</h3>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card">
                        <div class="card-body text-center">
                            <h6 class="text-muted">Total Delivered</h6>
                            <h3 class="text-warning">{{ stats.total_successful_deliveries }}</h3>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Send Notification Form -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h4 class="card-title">Send Notification to All Delivery Boys</h4>
                        </div>
                        <div class="card-body">
                            <form @submit.prevent="sendNotification">
                                <div class="row">
                                    <div class="col-md-12">
                                        <div class="mb-3">
                                            <label class="form-label">Title <span class="text-danger">*</span></label>
                                            <input type="text" class="form-control" v-model="form.title" placeholder="Enter notification title" required>
                                        </div>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-md-12">
                                        <div class="mb-3">
                                            <label class="form-label">Message <span class="text-danger">*</span></label>
                                            <textarea class="form-control" v-model="form.message" rows="3" placeholder="Enter notification message" required></textarea>
                                        </div>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="mb-3">
                                            <label class="form-label">Image (Optional)</label>
                                            <input type="file" class="form-control" @change="handleImageUpload" accept="image/*">
                                            <small class="text-muted">Max size: 2MB. Formats: JPG, PNG, GIF</small>
                                        </div>
                                    </div>
                                    <div class="col-md-6" v-if="imagePreview">
                                        <div class="mb-3">
                                            <label class="form-label">Preview</label>
                                            <div>
                                                <img :src="imagePreview" class="img-thumbnail" style="max-height: 100px;">
                                                <button type="button" class="btn btn-sm btn-danger ms-2" @click="removeImage">
                                                    <i class="fa fa-times"></i>
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-12">
                                        <button type="submit" class="btn btn-primary" :disabled="isSending">
                                            <span v-if="isSending">
                                                <i class="fa fa-spinner fa-spin me-1"></i> Sending...
                                            </span>
                                            <span v-else>
                                                <i class="fa fa-paper-plane me-1"></i> Send to All Delivery Boys
                                            </span>
                                        </button>
                                        <button type="button" class="btn btn-secondary ms-2" @click="resetForm">
                                            <i class="fa fa-refresh me-1"></i> Reset
                                        </button>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Notification History -->
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h4 class="card-title mb-0">Notification History</h4>
                            <button class="btn btn-sm btn-primary" @click="fetchNotifications">
                                <i class="fa fa-refresh"></i>
                            </button>
                        </div>
                        <div class="card-body">
                            <!-- Search -->
                            <div class="row mb-3">
                                <div class="col-md-4">
                                    <input type="text" class="form-control" v-model="search" @input="debouncedSearch" placeholder="Search by title or message...">
                                </div>
                            </div>

                            <!-- Loading -->
                            <div v-if="isLoading" class="text-center py-5">
                                <b-spinner variant="primary"></b-spinner>
                                <p class="mt-2">Loading notifications...</p>
                            </div>

                            <!-- Table -->
                            <div v-else class="table-responsive">
                                <table class="table table-striped table-hover">
                                    <thead>
                                        <tr>
                                            <th>ID</th>
                                            <th>Title</th>
                                            <th>Message</th>
                                            <!-- <th>Type</th> -->
                                            <th>Recipients</th>
                                            <!-- <th>Success/Failed</th> -->
                                            <!-- <th>Status</th> -->
                                            <th>Sent At</th>
                                            <th>Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="notification in notifications" :key="notification.id">
                                            <td>{{ notification.id }}</td>
                                            <td>
                                                <div class="d-flex align-items-center">
                                                    <img v-if="notification.image_url" :src="notification.image_url" class="me-2 rounded" style="width: 40px; height: 40px; object-fit: cover;">
                                                    <span>{{ notification.title }}</span>
                                                </div>
                                            </td>
                                            <td>
                                                <span :title="notification.message">{{ truncate(notification.message, 50) }}</span>
                                            </td>
                                            <!-- <td>
                                                <span class="badge" :class="getTypeBadgeClass(notification.type)">
                                                    {{ notification.type }}
                                                </span>
                                            </td> -->
                                            <td>{{ notification.total_delivery_boys }}</td>
                                            <!-- <td>
                                                <span class="text-success">{{ notification.success_count }}</span>
                                                /
                                                <span class="text-danger">{{ notification.failed_count }}</span>
                                            </td> -->
                                            <!-- <td>
                                                <span class="badge" :class="getStatusBadgeClass(notification.status)">
                                                    {{ notification.status }}
                                                </span>
                                            </td> -->
                                            <td>{{ formatDate(notification.sent_at) }}</td>
                                            <td>
                                                <button class="btn btn-sm btn-danger" @click="deleteNotification(notification.id)" :disabled="isDeleting === notification.id">
                                                    <i class="fa fa-trash"></i>
                                                </button>
                                            </td>
                                        </tr>
                                        <tr v-if="notifications.length === 0">
                                            <td colspan="6" class="text-center py-4">
                                                <p class="text-muted mb-0">No notifications found</p>
                                            </td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>

                            <!-- Pagination -->
                            <div class="row mt-3" v-if="totalRows > 0">
                                <div class="col-md-6">
                                    <p class="text-muted">
                                        Showing {{ (currentPage - 1) * perPage + 1 }} to {{ Math.min(currentPage * perPage, totalRows) }} of {{ totalRows }} entries
                                    </p>
                                </div>
                                <div class="col-md-6">
                                    <b-pagination
                                        v-model="currentPage"
                                        :total-rows="totalRows"
                                        :per-page="perPage"
                                        align="right"
                                        @change="onPageChange"
                                    ></b-pagination>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import axios from 'axios';

export default {
    name: 'DriverNotifications',
    data() {
        return {
            // Form data
            form: {
                title: '',
                message: '',
                type: 'announcement',
                image: null
            },
            imagePreview: null,
            isSending: false,

            // Stats
            stats: {
                total_notifications: 0,
                total_active_delivery_boys: 0,
                notifications_last_30_days: 0,
                total_successful_deliveries: 0
            },

            // Notifications list
            notifications: [],
            isLoading: false,
            search: '',
            currentPage: 1,
            perPage: 15,
            totalRows: 0,
            isDeleting: null,

            // Debounce timer
            searchTimer: null
        };
    },
    mounted() {
        this.fetchStats();
        this.fetchNotifications();
    },
    methods: {
        async fetchStats() {
            try {
                const baseUrl = window.baseUrl || '';
                const response = await axios.get(`${baseUrl}/api/delivery-boy-broadcast-notifications/stats`);
                if (response.data.success) {
                    this.stats = response.data.data;
                }
            } catch (error) {
                console.error('Error fetching stats:', error);
            }
        },

        async fetchNotifications() {
            this.isLoading = true;
            try {
                const baseUrl = window.baseUrl || '';
                const response = await axios.get(`${baseUrl}/api/delivery-boy-broadcast-notifications`, {
                    params: {
                        page: this.currentPage,
                        per_page: this.perPage,
                        search: this.search
                    }
                });
                if (response.data.success) {
                    this.notifications = response.data.data.data;
                    this.totalRows = response.data.data.total;
                }
            } catch (error) {
                console.error('Error fetching notifications:', error);
                this.$bvToast.toast('Failed to fetch notifications', {
                    title: 'Error',
                    variant: 'danger',
                    solid: true
                });
            } finally {
                this.isLoading = false;
            }
        },

        async sendNotification() {
            if (!this.form.title || !this.form.message) {
                this.$bvToast.toast('Please fill in all required fields', {
                    title: 'Validation Error',
                    variant: 'warning',
                    solid: true
                });
                return;
            }

            this.isSending = true;
            try {
                const formData = new FormData();
                formData.append('title', this.form.title);
                formData.append('message', this.form.message);
                formData.append('type', this.form.type);
                if (this.form.image) {
                    formData.append('image', this.form.image);
                }

                const baseUrl = window.baseUrl || '';
                const response = await axios.post(`${baseUrl}/api/delivery-boy-broadcast-notifications/send`, formData, {
                    headers: {
                        'Content-Type': 'multipart/form-data'
                    }
                });

                if (response.data.success) {
                    this.$swal.fire({
                        title: 'Success!',
                        text: response.data.message,
                        icon: 'success',
                        confirmButtonColor: '#28a745'
                    });
                    this.resetForm();
                    this.fetchStats();
                    this.fetchNotifications();
                } else {
                    this.$swal.fire({
                        title: 'Error!',
                        text: response.data.message,
                        icon: 'error',
                        confirmButtonColor: '#dc3545'
                    });
                }
            } catch (error) {
                console.error('Error sending notification:', error);
                const message = error.response?.data?.message || 'Failed to send notification';
                this.$swal.fire({
                    title: 'Error!',
                    text: message,
                    icon: 'error',
                    confirmButtonColor: '#dc3545'
                });
            } finally {
                this.isSending = false;
            }
        },

        async deleteNotification(id) {
            const result = await this.$swal.fire({
                title: 'Are you sure?',
                text: 'This will delete the notification record.',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#d33',
                cancelButtonColor: '#3085d6',
                confirmButtonText: 'Yes, delete it!'
            });

            if (!result.isConfirmed) return;

            this.isDeleting = id;
            try {
                const baseUrl = window.baseUrl || '';
                const response = await axios.post(`${baseUrl}/api/delivery-boy-broadcast-notifications/delete`, { id });

                if (response.data.success) {
                    this.$bvToast.toast('Notification deleted successfully', {
                        title: 'Success',
                        variant: 'success',
                        solid: true
                    });
                    this.fetchStats();
                    this.fetchNotifications();
                } else {
                    this.$bvToast.toast(response.data.message, {
                        title: 'Error',
                        variant: 'danger',
                        solid: true
                    });
                }
            } catch (error) {
                console.error('Error deleting notification:', error);
                this.$bvToast.toast('Failed to delete notification', {
                    title: 'Error',
                    variant: 'danger',
                    solid: true
                });
            } finally {
                this.isDeleting = null;
            }
        },

        handleImageUpload(event) {
            const file = event.target.files[0];
            if (file) {
                if (file.size > 2 * 1024 * 1024) {
                    this.$bvToast.toast('Image size must be less than 2MB', {
                        title: 'Error',
                        variant: 'danger',
                        solid: true
                    });
                    event.target.value = '';
                    return;
                }
                this.form.image = file;
                this.imagePreview = URL.createObjectURL(file);
            }
        },

        removeImage() {
            this.form.image = null;
            this.imagePreview = null;
        },

        resetForm() {
            this.form = {
                title: '',
                message: '',
                type: 'announcement',
                image: null
            };
            this.imagePreview = null;
        },

        onPageChange(page) {
            this.currentPage = page;
            this.fetchNotifications();
        },

        debouncedSearch() {
            clearTimeout(this.searchTimer);
            this.searchTimer = setTimeout(() => {
                this.currentPage = 1;
                this.fetchNotifications();
            }, 500);
        },

        truncate(text, length) {
            if (!text) return '';
            return text.length > length ? text.substring(0, length) + '...' : text;
        },

        formatDate(dateString) {
            if (!dateString) return '-';
            const date = new Date(dateString);
            return date.toLocaleDateString('en-US', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        },

        getTypeBadgeClass(type) {
            const classes = {
                'general': 'bg-secondary',
                'promo': 'bg-success',
                'announcement': 'bg-primary'
            };
            return classes[type] || 'bg-secondary';
        },

        getStatusBadgeClass(status) {
            const classes = {
                'pending': 'bg-warning',
                'sending': 'bg-info',
                'completed': 'bg-success',
                'failed': 'bg-danger'
            };
            return classes[status] || 'bg-secondary';
        }
    }
};
</script>

<style scoped>
.card {
    box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
}
.card-title {
    margin-bottom: 0;
}
.badge {
    font-weight: 600;
    padding: 0.35em 0.65em;
}
.bg-success {
    background-color: #28a745 !important;
    color: #fff !important;
}
.bg-danger {
    background-color: #dc3545 !important;
    color: #fff !important;
}
.bg-warning {
    background-color: #ffc107 !important;
    color: #212529 !important;
}
.bg-info {
    background-color: #17a2b8 !important;
    color: #fff !important;
}
.bg-primary {
    background-color: #007bff !important;
    color: #fff !important;
}
.bg-secondary {
    background-color: #6c757d !important;
    color: #fff !important;
}
</style>
