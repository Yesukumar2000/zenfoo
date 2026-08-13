<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>Notifications</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">Notifications</li>
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

            <section class="section">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h4 class="mb-0">{{ __('notifications') }}</h4>
                        <div class="d-flex align-items-center gap-2">
                            <b-form-input
                                id="filter-input"
                                v-model="filter"
                                type="search"
                                :placeholder="__('search')"
                                style="width: 200px;"
                                size="sm"
                            ></b-form-input>
                            <button class="btn btn-primary btn-sm" v-b-tooltip.hover :title="__('refresh')" @click="getNotifications()">
                                <i class="fa fa-refresh" aria-hidden="true"></i>
                            </button>
                            <button v-if="hasUnread" class="btn btn-outline-secondary btn-sm" @click="markAllAsRead()">
                                Mark all as read
                            </button>
                        </div>
                    </div>

                    <div class="card-body p-0">
                        <!-- Loading State -->
                        <div v-if="isLoading" class="text-center py-5">
                            <b-spinner class="align-middle"></b-spinner>
                            <p class="mt-2 mb-0 text-muted">{{ __('loading') }}...</p>
                        </div>

                        <!-- Empty State -->
                        <div v-else-if="filteredNotifications.length === 0" class="text-center py-5">
                            <i class="fa fa-bell-slash fa-3x text-muted mb-3"></i>
                            <p class="text-muted mb-0">No notifications found</p>
                        </div>

                        <!-- Notification List -->
                        <div v-else class="notification-list">
                            <div
                                v-for="(notification, index) in filteredNotifications"
                                :key="notification.id"
                                class="notification-item"
                                :class="{ 'unread': notification.read_at === null }"
                                @click="handleNotificationClick(notification)"
                            >
                                <div class="notification-icon">
                                    <i :class="getNotificationIcon(notification.data.type)"></i>
                                </div>
                                <div class="notification-content">
                                    <p class="notification-text mb-1">{{ notification.data.text }}</p>
                                    <div class="notification-meta">
                                        <span class="notification-type">
                                            <i class="fa fa-tag me-1"></i>
                                            {{ formatType(notification.data.type) }}
                                        </span>
                                        <span class="notification-time">
                                            <i class="fa fa-clock-o me-1"></i>
                                            {{ formatTime(notification.created_at) }}
                                        </span>
                                        <span v-if="notification.data.order_id" class="notification-order">
                                            <i class="fa fa-shopping-cart me-1"></i>
                                            Order #{{ notification.data.order_id }}
                                        </span>
                                    </div>
                                </div>
                                <div class="notification-status">
                                    <span v-if="notification.read_at === null" class="badge bg-primary">New</span>
                                    <i class="fa fa-chevron-right text-muted"></i>
                                </div>
                            </div>
                        </div>

                        <!-- Pagination -->
                        <div class="notification-footer d-flex justify-content-between align-items-center p-3 border-top">
                            <div class="d-flex align-items-center">
                                <span class="me-2">{{ __('per_page') }}:</span>
                                <b-form-select
                                    v-model="perPage"
                                    :options="pageOptions"
                                    size="sm"
                                    style="width: 80px;"
                                ></b-form-select>
                            </div>
                            <div class="text-muted">
                                Showing {{ filteredNotifications.length }} of {{ totalRows }} notifications
                            </div>
                            <b-pagination
                                v-model="currentPage"
                                :total-rows="totalRows"
                                :per-page="perPage"
                                size="sm"
                                class="mb-0"
                            ></b-pagination>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    </div>
</template>
<script>
export default {
    data: function() {
        return {
            totalRows: 0,
            currentPage: 1,
            perPage: this.$perPage || 10,
            pageOptions: this.$pageOptions || [10, 25, 50, 100],
            filter: '',
            isLoading: false,
            notifications: [],
        }
    },
    computed: {
        filteredNotifications() {
            if (!this.filter) {
                return this.notifications;
            }
            const searchTerm = this.filter.toLowerCase();
            return this.notifications.filter(n => {
                const text = n.data?.text?.toLowerCase() || '';
                const type = n.data?.type?.toLowerCase() || '';
                const orderId = String(n.data?.order_id || '');
                return text.includes(searchTerm) || type.includes(searchTerm) || orderId.includes(searchTerm);
            });
        },
        hasUnread() {
            return this.notifications.some(n => n.read_at === null);
        }
    },
    created: function() {
        this.getNotifications();
    },
    watch: {
        currentPage() {
            this.getNotifications();
        },
        perPage() {
            this.getNotifications();
        },
    },
    methods: {
        getNotifications() {
            this.isLoading = true;
            let param = {
                page: this.currentPage,
                per_page: this.perPage
            };
            console.log('🔵 Fetching notifications with params:', param);
            console.log('🔵 API URL:', this.$apiUrl + '/admin/panel_notification');
            axios.get(this.$apiUrl + '/admin/panel_notification', {
                params: param
            }).then((response) => {
                this.isLoading = false;
                console.log('✅ Full API Response:', response);
                console.log('✅ Response Data:', response.data);
                console.log('✅ Notifications Array:', response.data.data);
                console.log('✅ Total Rows:', response.data.total);
                let data = response.data;
                this.notifications = data.data || [];
                this.totalRows = response.data.total || 0;
                console.log('✅ Component State - notifications:', this.notifications);
                console.log('✅ Component State - totalRows:', this.totalRows);
            }).catch((error) => {
                this.isLoading = false;
                console.error('❌ Failed to fetch notifications', error);
                console.error('❌ Error response:', error.response);
            });
        },

        async handleNotificationClick(notification) {
            // Mark as read if unread
            if (notification.read_at === null) {
                try {
                    await axios.post(this.$apiUrl + '/notification_read', { id: notification.id });
                    notification.read_at = new Date().toISOString();
                } catch (error) {
                    console.error("Failed to mark as read", error);
                }
            }

            // Navigate based on notification type
            const notificationType = notification.data.type;

            // Handle driver created issue notifications
            if (notificationType === 'driver_created_issue' && notification.data.issue_id) {
                this.$router.push('/delivery-boys/issues/view/' + notification.data.issue_id);
                return;
            }

            if (notification.data.report_id) {
                this.$router.push('/customer-support/view/' + notification.data.report_id);
            } else if (notification.data.order_id) {
                this.$router.push('/orders/view/' + notification.data.order_id);
            } else if (notification.data.seller_id) {
                this.$router.push('/sellers/view/' + notification.data.seller_id);
            } else if (notification.data.driver_id) {
                this.$router.push('/delivery_boys/view/' + notification.data.driver_id);
            } else {
                this.$router.push('/dashboard');
            }
        },

        async markAllAsRead() {
            try {
                await axios.post(this.$apiUrl + '/notification_read_all');
                this.notifications.forEach(n => {
                    if (n.read_at === null) {
                        n.read_at = new Date().toISOString();
                    }
                });
                this.$toast ? this.$toast.success('All notifications marked as read') : null;
            } catch (error) {
                console.error("Failed to mark all as read", error);
                this.$toast ? this.$toast.error('Failed to mark notifications as read') : null;
            }
        },

        getNotificationIcon(type) {
            const icons = {
                'new_order': 'fa fa-shopping-bag text-success',
                'order_status': 'fa fa-truck text-info',
                'seller_registration': 'fa fa-store text-warning',
                'driver_document_update': 'fa fa-id-card text-warning',
                'driver_created_issue': 'fa fa-exclamation-circle text-danger',
                'customer_issue_report': 'fa fa-exclamation-triangle text-danger',
                'general': 'fa fa-bell text-primary',
            };
            return icons[type] || 'fa fa-bell text-secondary';
        },

        formatType(type) {
            if (!type) return 'General';
            const types = {
                'new_order': 'New Order',
                'order_status': 'Order Update',
                'seller_registration': 'Seller Registration',
                'driver_document_update': 'Driver Document Update',
                'driver_created_issue': 'Driver Issue Report',
                'customer_issue_report': 'Customer Issue Report',
                'general': 'General',
            };
            return types[type] || type.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
        },

        formatTime(dateString) {
            if (!dateString) return '';
            const date = new Date(dateString);
            const now = new Date();
            const diffMs = now - date;
            const diffMins = Math.floor(diffMs / 60000);
            const diffHours = Math.floor(diffMs / 3600000);
            const diffDays = Math.floor(diffMs / 86400000);

            if (diffMins < 1) return 'Just now';
            if (diffMins < 60) return `${diffMins} min ago`;
            if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
            if (diffDays < 7) return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;

            return date.toLocaleDateString('en-US', {
                month: 'short',
                day: 'numeric',
                year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined
            });
        }
    }
};
</script>

<style scoped>
.notification-list {
    max-height: calc(100vh - 300px);
    overflow-y: auto;
}

.notification-item {
    display: flex;
    align-items: center;
    padding: 15px 20px;
    border-bottom: 1px solid #eee;
    cursor: pointer;
    transition: background-color 0.2s ease;
}

.notification-item:hover {
    background-color: #f8f9fa;
}

.notification-item.unread {
    background-color: #f0f7ff;
    border-left: 3px solid #435ebe;
}

.notification-item.unread:hover {
    background-color: #e3efff;
}

.notification-icon {
    width: 45px;
    height: 45px;
    border-radius: 50%;
    background-color: #f4f4f4;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-right: 15px;
    flex-shrink: 0;
}

.notification-icon i {
    font-size: 18px;
}

.notification-content {
    flex: 1;
    min-width: 0;
}

.notification-text {
    font-size: 14px;
    color: #333;
    margin: 0;
    line-height: 1.4;
}

.notification-item.unread .notification-text {
    font-weight: 600;
}

.notification-meta {
    display: flex;
    flex-wrap: wrap;
    gap: 15px;
    font-size: 12px;
    color: #888;
    margin-top: 5px;
}

.notification-meta span {
    display: flex;
    align-items: center;
}

.notification-status {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-left: 15px;
    flex-shrink: 0;
}

.notification-status .badge {
    font-size: 10px;
    padding: 4px 8px;
}

.notification-footer {
    background-color: #fafafa;
}

/* Scrollbar styling */
.notification-list::-webkit-scrollbar {
    width: 6px;
}

.notification-list::-webkit-scrollbar-track {
    background: #f1f1f1;
}

.notification-list::-webkit-scrollbar-thumb {
    background: #ccc;
    border-radius: 3px;
}

.notification-list::-webkit-scrollbar-thumb:hover {
    background: #aaa;
}

/* Dark theme styles */
:deep(.theme-dark) .notification-item,
.theme-dark .notification-item {
    border-bottom-color: #3a3f44;
    background-color: #1e2329;
}

:deep(.theme-dark) .notification-item:hover,
.theme-dark .notification-item:hover {
    background-color: #2a2f35;
}

:deep(.theme-dark) .notification-item.unread,
.theme-dark .notification-item.unread {
    background-color: #1a2a3a;
    border-left-color: #435ebe;
}

:deep(.theme-dark) .notification-item.unread:hover,
.theme-dark .notification-item.unread:hover {
    background-color: #243448;
}

:deep(.theme-dark) .notification-icon,
.theme-dark .notification-icon {
    background-color: #2a2f35;
}

:deep(.theme-dark) .notification-text,
.theme-dark .notification-text {
    color: #e0e0e0;
}

:deep(.theme-dark) .notification-meta,
.theme-dark .notification-meta {
    color: #9aa0a6;
}

:deep(.theme-dark) .notification-footer,
.theme-dark .notification-footer {
    background-color: #1a1d21;
    border-top-color: #3a3f44;
}

:deep(.theme-dark) .notification-list::-webkit-scrollbar-track,
.theme-dark .notification-list::-webkit-scrollbar-track {
    background: #2a2f35;
}

:deep(.theme-dark) .notification-list::-webkit-scrollbar-thumb,
.theme-dark .notification-list::-webkit-scrollbar-thumb {
    background: #4a4f55;
}

:deep(.theme-dark) .notification-list::-webkit-scrollbar-thumb:hover,
.theme-dark .notification-list::-webkit-scrollbar-thumb:hover {
    background: #5a5f65;
}
</style>
