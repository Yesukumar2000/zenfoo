<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>All Notifications</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">Dashboard</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">Notifications</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <!-- Stats Cards -->
            <div class="row mb-4">
                <div class="col-md-3">
                    <div class="card stats-card" :class="{ 'active': activeTab === 'all' }" @click="setActiveTab('all')">
                        <div class="card-body text-center">
                            <h6 class="text-muted">Total Notifications</h6>
                            <h3 class="text-primary">{{ stats.total_notifications }}</h3>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card stats-card" :class="{ 'active': activeTab === 'customer' }" @click="setActiveTab('customer')">
                        <div class="card-body text-center">
                            <h6 class="text-muted">Customer Notifications</h6>
                            <h3 class="text-success">{{ stats.customer_notifications }}</h3>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card stats-card" :class="{ 'active': activeTab === 'seller' }" @click="setActiveTab('seller')">
                        <div class="card-body text-center">
                            <h6 class="text-muted">Seller Notifications</h6>
                            <h3 class="text-info">{{ stats.seller_notifications }}</h3>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card stats-card" :class="{ 'active': activeTab === 'driver' }" @click="setActiveTab('driver')">
                        <div class="card-body text-center">
                            <h6 class="text-muted">Driver Notifications</h6>
                            <h3 class="text-warning">{{ stats.driver_notifications }}</h3>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Tabs Navigation -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card">
                        <div class="card-body p-0">
                            <ul class="nav nav-tabs nav-tabs-custom" role="tablist">
                                <li class="nav-item">
                                    <a class="nav-link" :class="{ 'active': activeTab === 'customer' }" @click.prevent="setActiveTab('customer')" href="#">
                                        <i class="fa fa-users me-2"></i>
                                        Customer
                                        <span class="badge bg-success ms-2">{{ stats.customer_notifications }}</span>
                                    </a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link" :class="{ 'active': activeTab === 'seller' }" @click.prevent="setActiveTab('seller')" href="#">
                                        <i class="fa fa-store me-2"></i>
                                        Seller
                                        <span class="badge bg-info ms-2">{{ stats.seller_notifications }}</span>
                                    </a>
                                </li>
                                <li class="nav-item">
                                    <a class="nav-link" :class="{ 'active': activeTab === 'driver' }" @click.prevent="setActiveTab('driver')" href="#">
                                        <i class="fa fa-truck me-2"></i>
                                        Driver
                                        <span class="badge bg-warning ms-2">{{ stats.driver_notifications }}</span>
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Notification Table -->
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h4 class="card-title mb-0">
                                <span v-if="activeTab === 'customer'">Customer Notifications</span>
                                <span v-else-if="activeTab === 'seller'">Seller Notifications</span>
                                <span v-else-if="activeTab === 'driver'">Driver Notifications</span>
                                <span v-else>All Notifications</span>
                            </h4>
                            <button class="btn btn-sm btn-primary" @click="fetchNotifications" :disabled="isLoading">
                                <i class="fa fa-refresh" :class="{ 'fa-spin': isLoading }"></i>
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

                            <!-- Customer/Seller Table -->
                            <div v-else-if="activeTab === 'customer' || activeTab === 'seller'" class="table-responsive">
                                <table class="table table-striped table-hover">
                                    <thead>
                                        <tr>
                                            <th>ID</th>
                                            <th>User</th>
                                            <th>Title</th>
                                            <th>Message</th>
                                            <th>Type</th>
                                            <th>Sent At</th>
                                            <th>Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="notification in notifications" :key="notification.id">
                                            <td>{{ notification.id }}</td>
                                            <td>
                                                <span v-if="notification.user">{{ notification.user.name || notification.user.email || 'User #' + notification.user_id }}</span>
                                                <span v-else class="text-muted">User #{{ notification.user_id }}</span>
                                            </td>
                                            <td>
                                                <div class="d-flex align-items-center">
                                                    <img v-if="notification.image" :src="$mediaUrl(notification.image)" class="me-2 rounded" style="width: 40px; height: 40px; object-fit: cover;">
                                                    <span>{{ notification.title }}</span>
                                                </div>
                                            </td>
                                            <td>
                                                <span :title="notification.message">{{ truncate(notification.message, 40) }}</span>
                                            </td>
                                            <td>
                                                <span class="badge" :class="getNotificationTypeBadge(notification.type)">
                                                    {{ formatNotificationType(notification.type) }}
                                                </span>
                                            </td>
                                            <td>{{ formatDate(notification.date_sent) }}</td>
                                            <td>
                                                <button class="btn btn-sm btn-info me-1" @click="viewNotification(notification)">
                                                    <i class="fa fa-eye"></i>
                                                </button>
                                                <button class="btn btn-sm btn-danger" @click="deleteNotification(notification.id, activeTab)" :disabled="isDeleting === notification.id">
                                                    <i class="fa fa-trash"></i>
                                                </button>
                                            </td>
                                        </tr>
                                        <tr v-if="notifications.length === 0">
                                            <td colspan="7" class="text-center py-4">
                                                <p class="text-muted mb-0">No notifications found</p>
                                            </td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>

                            <!-- Driver Table -->
                            <div v-else-if="activeTab === 'driver'" class="table-responsive">
                                <table class="table table-striped table-hover">
                                    <thead>
                                        <tr>
                                            <th>ID</th>
                                            <th>Driver</th>
                                            <th>Title</th>
                                            <th>Message</th>
                                            <th>Type</th>
                                            <th>Order Item</th>
                                            <th>Sent At</th>
                                            <th>Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <tr v-for="notification in notifications" :key="notification.id">
                                            <td>{{ notification.id }}</td>
                                            <td>
                                                <span v-if="notification.delivery_boy">{{ notification.delivery_boy.name || 'Driver #' + notification.delivery_boy_id }}</span>
                                                <span v-else class="text-muted">Driver #{{ notification.delivery_boy_id }}</span>
                                            </td>
                                            <td>{{ notification.title }}</td>
                                            <td>
                                                <span :title="notification.message">{{ truncate(notification.message, 40) }}</span>
                                            </td>
                                            <td>
                                                <span class="badge" :class="getDriverTypeBadge(notification.type)">
                                                    {{ formatDriverType(notification.type) }}
                                                </span>
                                            </td>
                                            <td>
                                                <span v-if="notification.order_item_id">#{{ notification.order_item_id }}</span>
                                                <span v-else class="text-muted">-</span>
                                            </td>
                                            <td>{{ formatDate(notification.created_at) }}</td>
                                            <td>
                                                <button class="btn btn-sm btn-info me-1" @click="viewNotification(notification)">
                                                    <i class="fa fa-eye"></i>
                                                </button>
                                                <button class="btn btn-sm btn-danger" @click="deleteNotification(notification.id, 'driver')" :disabled="isDeleting === notification.id">
                                                    <i class="fa fa-trash"></i>
                                                </button>
                                            </td>
                                        </tr>
                                        <tr v-if="notifications.length === 0">
                                            <td colspan="8" class="text-center py-4">
                                                <p class="text-muted mb-0">No driver notifications found</p>
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

        <!-- View Modal -->
        <b-modal v-model="showViewModal" title="Notification Details" size="lg" hide-footer>
            <div v-if="selectedNotification">
                <div class="mb-3">
                    <strong>Title:</strong>
                    <p>{{ selectedNotification.title }}</p>
                </div>
                <div class="mb-3">
                    <strong>Message:</strong>
                    <p>{{ selectedNotification.message }}</p>
                </div>
                <div class="mb-3">
                    <strong>Type:</strong>
                    <span class="badge ms-2" :class="activeTab === 'driver' ? getDriverTypeBadge(selectedNotification.type) : getNotificationTypeBadge(selectedNotification.type)">
                        {{ activeTab === 'driver' ? formatDriverType(selectedNotification.type) : formatNotificationType(selectedNotification.type) }}
                    </span>
                </div>
                <div class="mb-3" v-if="selectedNotification.user">
                    <strong>User:</strong>
                    <p>{{ selectedNotification.user.name || selectedNotification.user.email }}</p>
                </div>
                <div class="mb-3" v-if="selectedNotification.delivery_boy">
                    <strong>Driver:</strong>
                    <p>{{ selectedNotification.delivery_boy.name }}</p>
                </div>
                <div class="mb-3">
                    <strong>Sent At:</strong>
                    <p>{{ formatDate(selectedNotification.date_sent || selectedNotification.created_at) }}</p>
                </div>
                <div v-if="selectedNotification.image" class="mb-3">
                    <strong>Image:</strong>
                    <div class="mt-2">
                        <img :src="$mediaUrl(selectedNotification.image)" class="img-fluid rounded" style="max-height: 200px;">
                    </div>
                </div>
                <div v-if="selectedNotification.data" class="mb-3">
                    <strong>Additional Data:</strong>
                    <pre class="bg-light p-2 rounded mt-2" style="max-height: 200px; overflow: auto;">{{ formatJson(selectedNotification.data) }}</pre>
                </div>
            </div>
        </b-modal>
    </div>
</template>

<script>
import axios from 'axios';

export default {
    name: 'NotificationsAllIndex',
    data() {
        return {
            // Active tab
            activeTab: 'customer',

            // Stats
            stats: {
                total_notifications: 0,
                customer_notifications: 0,
                seller_notifications: 0,
                driver_notifications: 0
            },

            // Notifications list
            notifications: [],
            isLoading: false,
            search: '',
            currentPage: 1,
            perPage: 15,
            totalRows: 0,
            isDeleting: null,

            // Modal
            showViewModal: false,
            selectedNotification: null,

            // Debounce timer
            searchTimer: null
        };
    },
    mounted() {
        this.fetchStats();
        this.fetchNotifications();
    },
    methods: {
        setActiveTab(tab) {
            this.activeTab = tab;
            this.currentPage = 1;
            this.search = '';
            this.fetchNotifications();
        },

        async fetchStats() {
            try {
                const baseUrl = window.baseUrl || '';
                const response = await axios.get(`${baseUrl}/api/notifications-all/stats`);
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
                const response = await axios.get(`${baseUrl}/api/notifications-all`, {
                    params: {
                        tab: this.activeTab,
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

        async deleteNotification(id, type) {
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
                const response = await axios.post(`${baseUrl}/api/notifications-all/delete`, { id, type });

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

        viewNotification(notification) {
            this.selectedNotification = notification;
            this.showViewModal = true;
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

        formatJson(data) {
            try {
                if (typeof data === 'string') {
                    data = JSON.parse(data);
                }
                return JSON.stringify(data, null, 2);
            } catch (e) {
                return data;
            }
        },

        // Customer/Seller notification type badges
        getNotificationTypeBadge(type) {
            const badges = {
                'order': 'bg-primary',
                'new_order': 'bg-success',
                'profile': 'bg-info',
                'admin_chat': 'bg-secondary',
                'order_chat': 'bg-warning',
                'default': 'bg-secondary'
            };
            return badges[type] || badges['default'];
        },

        formatNotificationType(type) {
            const types = {
                'order': 'Order',
                'new_order': 'New Order',
                'profile': 'Profile',
                'admin_chat': 'Admin Chat',
                'order_chat': 'Order Chat',
            };
            return types[type] || type;
        },

        // Driver notification type badges
        getDriverTypeBadge(type) {
            const badges = {
                'gig_completed': 'bg-success',
                'gig_assigned': 'bg-primary',
                'order_assigned': 'bg-info',
                'admin_chat': 'bg-secondary',
                'announcement': 'bg-warning',
                'default': 'bg-secondary'
            };
            return badges[type] || badges['default'];
        },

        formatDriverType(type) {
            const types = {
                'gig_completed': 'Gig Completed',
                'gig_assigned': 'Gig Assigned',
                'order_assigned': 'Order Assigned',
                'admin_chat': 'Admin Chat',
                'announcement': 'Announcement',
            };
            return types[type] || type.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
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

/* Stats card hover and active states */
.stats-card {
    cursor: pointer;
    transition: all 0.3s ease;
    border: 2px solid transparent;
}
.stats-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
}
.stats-card.active {
    border-color: #9AC444;
    box-shadow: 0 0.5rem 1rem rgba(154, 196, 68, 0.25);
}

/* Custom nav tabs */
.nav-tabs-custom {
    border-bottom: 2px solid #dee2e6;
}
.nav-tabs-custom .nav-link {
    border: none;
    color: #6c757d;
    padding: 1rem 1.5rem;
    font-weight: 500;
    border-bottom: 3px solid transparent;
    margin-bottom: -2px;
    transition: all 0.3s ease;
}
.nav-tabs-custom .nav-link:hover {
    color: #9AC444;
    border-bottom-color: #dee2e6;
}
.nav-tabs-custom .nav-link.active {
    color: #9AC444;
    background-color: transparent;
    border-bottom-color: #9AC444;
}
.nav-tabs-custom .nav-link .badge {
    font-size: 0.75rem;
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
.bg-secondary {
    background-color: #6c757d !important;
    color: #fff !important;
}
.bg-danger {
    background-color: #dc3545 !important;
    color: #fff !important;
}
</style>
