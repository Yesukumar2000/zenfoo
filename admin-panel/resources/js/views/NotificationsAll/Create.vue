<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Send Notification</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">Dashboard</router-link>
                            </li>
                            <li class="breadcrumb-item">
                                <router-link to="/notifications-all">Notifications</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">Send</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/notifications-all" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h4 class="card-title">Send New Notification</h4>
                        </div>
                        <div class="card-body">
                            <form @submit.prevent="sendNotification">
                                <!-- Target Type Selection -->
                                <div class="row mb-4">
                                    <div class="col-md-6">
                                        <label class="form-label">Send To <span class="text-danger">*</span></label>
                                        <select class="form-select" v-model="form.target_type" required>
                                            <option value="">Select Target</option>
                                            <option value="customer">All Customers</option>
                                            <option value="seller">All Sellers</option>
                                            <option value="driver">All Drivers</option>
                                            <option value="all">Everyone (Customers + Sellers + Drivers)</option>
                                        </select>
                                        <small class="text-muted">
                                            <span v-if="form.target_type === 'customer'">{{ stats.customer_count }} customers will receive this notification</span>
                                            <span v-else-if="form.target_type === 'seller'">{{ stats.seller_count }} sellers will receive this notification</span>
                                            <span v-else-if="form.target_type === 'driver'">{{ stats.driver_count }} drivers will receive this notification</span>
                                            <span v-else-if="form.target_type === 'all'">{{ stats.total_count }} users will receive this notification</span>
                                        </small>
                                    </div>
                                </div>

                                <!-- Title -->
                                <div class="row mb-4">
                                    <div class="col-md-12">
                                        <label class="form-label">Title <span class="text-danger">*</span></label>
                                        <input
                                            type="text"
                                            class="form-control"
                                            v-model="form.title"
                                            placeholder="Enter notification title"
                                            maxlength="100"
                                            required
                                        >
                                        <small class="text-muted">{{ form.title.length }}/100 characters</small>
                                    </div>
                                </div>

                                <!-- Message -->
                                <div class="row mb-4">
                                    <div class="col-md-12">
                                        <label class="form-label">Message <span class="text-danger">*</span></label>
                                        <textarea
                                            class="form-control"
                                            v-model="form.message"
                                            rows="4"
                                            placeholder="Enter notification message"
                                            maxlength="500"
                                            required
                                        ></textarea>
                                        <small class="text-muted">{{ form.message.length }}/500 characters</small>
                                    </div>
                                </div>

                                <!-- Image Upload -->
                                <div class="row mb-4">
                                    <div class="col-md-6">
                                        <label class="form-label">Image (Optional)</label>
                                        <input
                                            type="file"
                                            class="form-control"
                                            @change="handleImageUpload"
                                            accept="image/*"
                                            ref="imageInput"
                                        >
                                        <small class="text-muted">Max size: 5MB. Formats: JPG, PNG, GIF, WEBP</small>
                                    </div>
                                    <div class="col-md-6" v-if="imagePreview">
                                        <label class="form-label">Preview</label>
                                        <div class="position-relative d-inline-block">
                                            <img :src="imagePreview" class="img-thumbnail" style="max-height: 150px;">
                                            <button
                                                type="button"
                                                class="btn btn-sm btn-danger position-absolute"
                                                style="top: 5px; right: 5px;"
                                                @click="removeImage"
                                            >
                                                <i class="fa fa-times"></i>
                                            </button>
                                        </div>
                                    </div>
                                </div>

                                <!-- Preview Card -->
                                <div class="row mb-4" v-if="form.title || form.message">
                                    <div class="col-md-6">
                                        <label class="form-label">Notification Preview</label>
                                        <div class="notification-preview">
                                            <div class="preview-header">
                                                <img src="/images/favicon.png" class="preview-icon" alt="icon">
                                                <span class="preview-app-name">Zenfoo</span>
                                                <span class="preview-time">now</span>
                                            </div>
                                            <div class="preview-content">
                                                <div class="preview-title">{{ form.title || 'Notification Title' }}</div>
                                                <div class="preview-message">{{ form.message || 'Notification message will appear here...' }}</div>
                                            </div>
                                            <img v-if="imagePreview" :src="imagePreview" class="preview-image" alt="preview">
                                        </div>
                                    </div>
                                </div>

                                <!-- Submit Buttons -->
                                <div class="row">
                                    <div class="col-12">
                                        <button
                                            type="submit"
                                            class="btn btn-primary"
                                            :disabled="isSending || !isFormValid"
                                        >
                                            <span v-if="isSending">
                                                <i class="fa fa-spinner fa-spin me-2"></i> Sending...
                                            </span>
                                            <span v-else>
                                                <i class="fa fa-paper-plane me-2"></i> Send Notification
                                            </span>
                                        </button>
                                        <button type="button" class="btn btn-secondary ms-2" @click="resetForm">
                                            <i class="fa fa-refresh me-2"></i> Reset
                                        </button>
                                        <router-link to="/notifications-all" class="btn btn-outline-secondary ms-2">
                                            <i class="fa fa-arrow-left me-2"></i> Back
                                        </router-link>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Recent Notifications Quick View -->
            <div class="row mt-4">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h4 class="card-title">Recent Broadcast Notifications</h4>
                        </div>
                        <div class="card-body">
                            <div v-if="recentNotifications.length > 0" class="table-responsive">
                                <table class="table table-sm table-striped">
                                    <thead>
                                        <tr>
                                            <th>Title</th>
                                            <th>Target</th>
                                            <th>Sent At</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="notification in recentNotifications" :key="notification.id">
                                            <td>{{ notification.title }}</td>
                                            <td>
                                                <span class="badge" :class="getTargetBadge(notification.target_type)">
                                                    {{ notification.target_type }}
                                                </span>
                                            </td>
                                            <td>{{ formatDate(notification.created_at) }}</td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                            <div v-else class="text-center py-3">
                                <p class="text-muted mb-0">No recent broadcast notifications</p>
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
    name: 'NotificationsAllCreate',
    data() {
        return {
            form: {
                target_type: '',
                title: '',
                message: '',
                image: null
            },
            imagePreview: null,
            isSending: false,
            stats: {
                customer_count: 0,
                seller_count: 0,
                driver_count: 0,
                total_count: 0
            },
            recentNotifications: []
        };
    },
    computed: {
        isFormValid() {
            return this.form.target_type && this.form.title && this.form.message;
        }
    },
    mounted() {
        this.fetchStats();
        this.fetchRecentNotifications();
    },
    methods: {
        async fetchStats() {
            try {
                const baseUrl = window.baseUrl || '';
                const response = await axios.get(`${baseUrl}/api/notifications-all/send-stats`);
                if (response.data.success) {
                    this.stats = response.data.data;
                }
            } catch (error) {
                console.error('Error fetching stats:', error);
            }
        },

        async fetchRecentNotifications() {
            try {
                const baseUrl = window.baseUrl || '';
                const response = await axios.get(`${baseUrl}/api/notifications-all/recent-broadcasts`);
                if (response.data.success) {
                    this.recentNotifications = response.data.data;
                }
            } catch (error) {
                console.error('Error fetching recent notifications:', error);
            }
        },

        handleImageUpload(event) {
            const file = event.target.files[0];
            if (file) {
                // Validate file size (5MB max)
                if (file.size > 5 * 1024 * 1024) {
                    this.$bvToast.toast('Image size must be less than 5MB', {
                        title: 'Error',
                        variant: 'danger',
                        solid: true
                    });
                    event.target.value = '';
                    return;
                }

                // Validate file type
                const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
                if (!allowedTypes.includes(file.type)) {
                    this.$bvToast.toast('Invalid image format. Allowed: JPG, PNG, GIF, WEBP', {
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
            if (this.$refs.imageInput) {
                this.$refs.imageInput.value = '';
            }
        },

        resetForm() {
            this.form = {
                target_type: '',
                title: '',
                message: '',
                image: null
            };
            this.imagePreview = null;
            if (this.$refs.imageInput) {
                this.$refs.imageInput.value = '';
            }
        },

        async sendNotification() {
            if (!this.isFormValid) {
                this.$bvToast.toast('Please fill in all required fields', {
                    title: 'Validation Error',
                    variant: 'warning',
                    solid: true
                });
                return;
            }

            // Confirm before sending
            const targetLabel = {
                'customer': 'all customers',
                'seller': 'all sellers',
                'driver': 'all drivers',
                'all': 'everyone (customers, sellers, and drivers)'
            }[this.form.target_type];

            const result = await this.$swal.fire({
                title: 'Confirm Send',
                html: `Are you sure you want to send this notification to <strong>${targetLabel}</strong>?<br><br>
                       <strong>Title:</strong> ${this.form.title}<br>
                       <strong>Message:</strong> ${this.form.message.substring(0, 100)}${this.form.message.length > 100 ? '...' : ''}`,
                icon: 'question',
                showCancelButton: true,
                confirmButtonColor: '#28a745',
                cancelButtonColor: '#6c757d',
                confirmButtonText: 'Yes, send it!'
            });

            if (!result.isConfirmed) return;

            this.isSending = true;

            try {
                const formData = new FormData();
                formData.append('target_type', this.form.target_type);
                formData.append('title', this.form.title);
                formData.append('message', this.form.message);
                if (this.form.image) {
                    formData.append('image', this.form.image);
                }

                const baseUrl = window.baseUrl || '';
                const response = await axios.post(`${baseUrl}/api/notifications-all/send`, formData, {
                    headers: {
                        'Content-Type': 'multipart/form-data'
                    }
                });

                if (response.data.success) {
                    this.$swal.fire({
                        title: 'Success!',
                        html: response.data.message,
                        icon: 'success',
                        confirmButtonColor: '#28a745'
                    });
                    this.resetForm();
                    this.fetchRecentNotifications();
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

        getTargetBadge(type) {
            const badges = {
                'customer': 'bg-success',
                'seller': 'bg-info',
                'driver': 'bg-warning',
                'all': 'bg-primary'
            };
            return badges[type] || 'bg-secondary';
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

/* Notification Preview Styles */
.notification-preview {
    background: #f8f9fa;
    border: 1px solid #dee2e6;
    border-radius: 12px;
    padding: 12px;
    max-width: 350px;
}
.preview-header {
    display: flex;
    align-items: center;
    margin-bottom: 8px;
}
.preview-icon {
    width: 20px;
    height: 20px;
    border-radius: 4px;
    margin-right: 8px;
}
.preview-app-name {
    font-size: 12px;
    font-weight: 600;
    color: #333;
    flex: 1;
}
.preview-time {
    font-size: 11px;
    color: #999;
}
.preview-content {
    margin-bottom: 8px;
}
.preview-title {
    font-size: 14px;
    font-weight: 600;
    color: #333;
    margin-bottom: 4px;
    word-break: break-word;
}
.preview-message {
    font-size: 13px;
    color: #666;
    line-height: 1.4;
    word-break: break-word;
}
.preview-image {
    width: 100%;
    border-radius: 8px;
    margin-top: 8px;
    max-height: 150px;
    object-fit: cover;
}

/* Badge colors */
.bg-success {
    background-color: #28a745 !important;
    color: #fff !important;
}
.bg-info {
    background-color: #17a2b8 !important;
    color: #fff !important;
}
.bg-warning {
    background-color: #ffc107 !important;
    color: #212529 !important;
}
.bg-primary {
    background-color: #007bff !important;
    color: #fff !important;
}
</style>
