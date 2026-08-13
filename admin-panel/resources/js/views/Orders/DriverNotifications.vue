<template>
    <div class="driver-notifications">
        <!-- Loading State -->
        <div v-if="isLoading" class="text-center py-5">
            <b-spinner variant="primary" label="Loading..."></b-spinner>
            <p class="mt-2 text-muted">Loading notification history...</p>
        </div>

        <!-- Main Content -->
        <div v-else>
            <!-- Summary Cards -->
            <div class="row mb-4">
                <div class="col-md-3">
                    <div class="card bg-primary text-white">
                        <div class="card-body py-3">
                            <div class="d-flex justify-content-between align-items-center">
                                <div>
                                    <h6 class="mb-0">Total Attempts</h6>
                                    <h3 class="mb-0">{{ notificationData.total_attempts || 0 }}</h3>
                                </div>
                                <i class="fas fa-redo fa-2x opacity-50"></i>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-success text-white">
                        <div class="card-body py-3">
                            <div class="d-flex justify-content-between align-items-center">
                                <div>
                                    <h6 class="mb-0">Drivers Notified</h6>
                                    <h3 class="mb-0">{{ notificationData.total_drivers_notified || 0 }}</h3>
                                </div>
                                <i class="fas fa-bell fa-2x opacity-50"></i>
                            </div>
                        </div>
                    </div>
                </div>
                <!-- <div class="col-md-3">
                    <div class="card" :class="getStatusCardClass(notificationData.latest_notification_status)">
                        <div class="card-body py-3">
                            <div class="d-flex justify-content-between align-items-center">
                                <div>
                                    <h6 class="mb-0">Latest Status</h6>
                                    <h5 class="mb-0">{{ formatStatus(notificationData.latest_notification_status) || 'N/A' }}</h5>
                                </div>
                                <i class="fas fa-info-circle fa-2x opacity-50"></i>
                            </div>
                        </div>
                    </div>
                </div> -->
                <div class="col-md-3">
                    <div class="card" :class="notificationData.delivery_boy_assigned ? 'bg-success text-white' : 'bg-warning text-dark'">
                        <div class="card-body py-3">
                            <div class="d-flex justify-content-between align-items-center">
                                <div>
                                    <h6 class="mb-0">Delivery Boy</h6>
                                    <h6 class="mb-0">
                                        {{ notificationData.delivery_boy_assigned ? notificationData.delivery_boy_name : 'Not Assigned' }}
                                    </h6>
                                </div>
                                <i class="fas fa-motorcycle fa-2x opacity-50"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Pending Assignment Alert -->
            <div v-if="notificationData.pending_assignment && notificationData.pending_assignment.status === 'pending'" class="alert alert-warning d-flex align-items-center mb-4">
                <i class="fas fa-exclamation-triangle me-3 fa-lg"></i>
                <div class="flex-grow-1">
                    <strong>Pending Assignment</strong>
                    <p class="mb-0">
                        This order is waiting for driver assignment.
                        Attempts: {{ notificationData.pending_assignment.attempts }}.
                        Last tried: {{ notificationData.pending_assignment.last_attempted_at || 'N/A' }}
                    </p>
                    <small v-if="notificationData.pending_assignment.last_error" class="text-danger">
                        Error: {{ notificationData.pending_assignment.last_error }}
                    </small>
                </div>
            </div>

            <!-- Retry Button -->
            <div class="mb-4">
                <button
                    class="btn btn-primary"
                    @click="retryNotification"
                    :disabled="isRetrying || notificationData.delivery_boy_assigned">
                    <template v-if="isRetrying">
                        <b-spinner small label="Retrying..."></b-spinner> Sending...
                    </template>
                    <template v-else>
                        <i class="fas fa-paper-plane me-2"></i> Send Notification to Drivers
                    </template>
                </button>
                <small v-if="notificationData.delivery_boy_assigned" class="text-muted ms-2">
                    (Delivery boy already assigned)
                </small>
            </div>

            <!-- Notification History -->
            <div class="card">
                <div class="card-header">
                    <h5 class="mb-0"><i class="fas fa-history me-2"></i>Notification History</h5>
                </div>
                <div class="card-body p-0">
                    <div v-if="!notificationData.notifications || notificationData.notifications.length === 0" class="text-center py-5">
                        <i class="fas fa-inbox fa-3x text-muted mb-3"></i>
                        <p class="text-muted">No notifications have been sent yet</p>
                    </div>

                    <div v-else>
                        <table class="table table-bordered table-hover mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th style="width: 80px;">Attempt</th>
                                    <th>Notified Drivers</th>
                                    <th>On Ride (Skipped)</th>
                                    <th style="width: 100px;">Status</th>
                                    <th>Accepted By</th>
                                    <th>Notified At</th>
                                    <th>Error</th>
                                    <th>Skip Reasons</th>
                                </tr>
                            </thead>
                            <tbody>
                                <template v-for="notification in notificationData.notifications">
                                    <tr :key="'row-' + notification.id">
                                        <td class="text-center">
                                            <span class="badge bg-secondary">{{ notification.attempt_number }}</span>
                                        </td>
                                        <td>
                                            <span class="badge bg-success me-1">{{ notification.drivers_notified_count }}</span>
                                            <button
                                                v-if="notification.notified_drivers && notification.notified_drivers.length > 0"
                                                class="btn btn-link btn-sm p-0"
                                                @click="toggleDriverList(notification.id, 'notified')">
                                                <i :class="expandedNotified === notification.id ? 'fas fa-chevron-up' : 'fas fa-chevron-down'"></i>
                                            </button>
                                            <!-- Expanded driver list -->
                                            <div v-if="expandedNotified === notification.id && notification.notified_drivers" class="mt-2">
                                                <small v-for="driver in notification.notified_drivers" :key="driver.id" class="d-block text-muted">
                                                    <i class="fas fa-user me-1"></i> {{ driver.name }} (ID: {{ driver.id }})
                                                </small>
                                            </div>
                                        </td>
                                        <td>
                                            <span class="badge bg-warning text-dark me-1">{{ notification.on_ride_count }}</span>
                                            <button
                                                v-if="notification.on_ride_drivers && notification.on_ride_drivers.length > 0"
                                                class="btn btn-link btn-sm p-0"
                                                @click="toggleDriverList(notification.id, 'onride')">
                                                <i :class="expandedOnRide === notification.id ? 'fas fa-chevron-up' : 'fas fa-chevron-down'"></i>
                                            </button>
                                            <!-- Expanded on-ride driver list -->
                                            <div v-if="expandedOnRide === notification.id && notification.on_ride_drivers" class="mt-2">
                                                <small v-for="driver in notification.on_ride_drivers" :key="driver.id" class="d-block text-muted">
                                                    <i class="fas fa-motorcycle me-1"></i> {{ driver.name }} (ID: {{ driver.id }})
                                                </small>
                                            </div>
                                        </td>
                                        <td>
                                            <span class="badge" :class="getStatusBadgeClass(notification.status)">
                                                {{ notification.status_label }}
                                            </span>
                                        </td>
                                        <td>
                                            <template v-if="notification.accepted_by">
                                                <span class="text-success">
                                                    <i class="fas fa-check-circle me-1"></i>
                                                    {{ notification.accepted_by_name }}
                                                </span>
                                                <br>
                                                <small class="text-muted">{{ notification.accepted_at }}</small>
                                            </template>
                                            <span v-else class="text-muted">-</span>
                                        </td>
                                        <td>
                                            <small>{{ notification.notified_at || '-' }}</small>
                                        </td>
                                        <td>
                                            <small v-if="notification.error_message" class="text-danger">
                                                {{ notification.error_message }}
                                            </small>
                                            <span v-else class="text-muted">-</span>
                                        </td>
                                        <td>
                                            <template v-if="notification.skip_reasons">
                                                <span class="badge bg-info text-dark me-1">
                                                    {{ funnelLabel(notification.skip_reasons) }}
                                                </span>
                                                <button
                                                    class="btn btn-link btn-sm p-0"
                                                    @click="toggleSkipReasons(notification.id)">
                                                    <i :class="expandedSkipReasons === notification.id ? 'fas fa-chevron-up' : 'fas fa-chevron-down'"></i>
                                                </button>
                                            </template>
                                            <span v-else class="text-muted">-</span>
                                        </td>
                                    </tr>
                                    <!-- Skip Reasons expanded row -->
                                    <tr :key="'skip-' + notification.id" v-if="expandedSkipReasons === notification.id && notification.skip_reasons">
                                        <td colspan="8" class="p-0">
                                            <div class="skip-reasons-panel p-3">
                                                <h6 class="mb-3 text-primary">
                                                    <i class="fas fa-filter me-1"></i>
                                                    Driver Filter Funnel — Attempt #{{ notification.attempt_number }}
                                                </h6>

                                                <!-- Funnel Summary (new format) -->
                                                <div v-if="notification.skip_reasons.funnel_summary" class="funnel-summary mb-3">
                                                    <div class="funnel-row">
                                                        <span class="badge bg-success funnel-badge">{{ notification.skip_reasons.funnel_summary.online }}</span>
                                                        <span class="funnel-label">
                                                            Online
                                                            <small class="text-muted ms-1">({{ notification.skip_reasons.funnel_summary.offline }} offline)</small>
                                                        </span>
                                                    </div>
                                                    <div class="funnel-arrow">↓</div>
                                                    <div class="funnel-row">
                                                        <span class="badge bg-primary funnel-badge">{{ notification.skip_reasons.funnel_summary.within_radius }}</span>
                                                        <span class="funnel-label">
                                                            Within 5km of seller
                                                            <small class="text-muted ms-1">
                                                                ({{ notification.skip_reasons.funnel_summary.no_location }} no location,
                                                                {{ notification.skip_reasons.funnel_summary.out_of_radius }} out of range)
                                                            </small>
                                                        </span>
                                                    </div>
                                                    <template v-if="notification.skip_reasons.funnel_summary.final_notified !== undefined">
                                                        <div class="funnel-arrow">↓</div>
                                                        <div class="funnel-row">
                                                            <span class="badge bg-success funnel-badge">{{ notification.skip_reasons.funnel_summary.final_notified }}</span>
                                                            <span class="funnel-label">
                                                                Notified (sent to driver app)
                                                                <small class="text-muted ms-1">
                                                                    ({{ notification.skip_reasons.funnel_summary.hand_cash_excluded || 0 }} hand cash,
                                                                    {{ notification.skip_reasons.funnel_summary.on_ride || 0 }} on active ride excluded)
                                                                </small>
                                                            </span>
                                                        </div>
                                                    </template>
                                                </div>

                                                <!-- Individual skip groups (order_priority, no_active_gig_booking) -->
                                                <div v-if="notification.skip_reasons.individual_groups && notification.skip_reasons.individual_groups.length > 0">
                                                    <p class="mb-2 text-muted"><small><strong>Skipped within radius:</strong></small></p>
                                                    <div v-for="skipGroup in notification.skip_reasons.individual_groups" :key="skipGroup.reason" class="skip-reason-group mb-3">
                                                        <div class="skip-reason-header d-flex align-items-center mb-1">
                                                            <span class="badge skip-reason-badge me-2" :class="getSkipReasonBadgeClass(skipGroup.reason)">
                                                                {{ skipGroup.count }}
                                                            </span>
                                                            <strong class="skip-reason-label">{{ skipGroup.label }}</strong>
                                                        </div>
                                                        <div class="skip-reason-drivers ps-4">
                                                            <small v-for="driver in skipGroup.drivers" :key="driver.id" class="d-block text-muted mb-1">
                                                                <i class="fas fa-user-times me-1 text-danger"></i>
                                                                <strong>{{ driver.name }}</strong> (ID: {{ driver.id }})
                                                                <span v-if="skipGroup.reason === 'order_priority'"> — priority: admin-only orders</span>
                                                            </small>
                                                        </div>
                                                    </div>
                                                </div>

                                                <!-- Legacy format fallback (old records without funnel_summary) -->
                                                <div v-if="!notification.skip_reasons.funnel_summary && Array.isArray(notification.skip_reasons)">
                                                    <div v-for="skipGroup in notification.skip_reasons" :key="skipGroup.reason" class="skip-reason-group mb-3">
                                                        <div class="skip-reason-header d-flex align-items-center mb-1">
                                                            <span class="badge skip-reason-badge me-2" :class="getSkipReasonBadgeClass(skipGroup.reason)">
                                                                {{ skipGroup.count }}
                                                            </span>
                                                            <strong class="skip-reason-label">{{ skipGroup.label }}</strong>
                                                        </div>
                                                        <div class="skip-reason-drivers ps-4">
                                                            <small v-for="driver in skipGroup.drivers" :key="driver.id" class="d-block text-muted mb-1">
                                                                <i class="fas fa-user-times me-1 text-danger"></i>
                                                                <strong>{{ driver.name }}</strong> (ID: {{ driver.id }})
                                                            </small>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </td>
                                    </tr>
                                </template>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import axios from "axios";

export default {
    name: "DriverNotifications",
    props: {
        orderId: {
            type: [Number, String],
            required: true
        }
    },
    data() {
        return {
            isLoading: false,
            isRetrying: false,
            notificationData: {
                order_id: null,
                order_status: null,
                delivery_boy_assigned: false,
                delivery_boy_name: null,
                total_attempts: 0,
                total_drivers_notified: 0,
                latest_notification_status: null,
                pending_assignment: null,
                notifications: []
            },
            expandedNotified: null,
            expandedOnRide: null,
            expandedSkipReasons: null
        };
    },
    computed: {},
    mounted() {
        this.fetchNotifications();
    },
    methods: {
        fetchNotifications() {
            this.isLoading = true;
            axios.get(this.$apiUrl + `/orders/${this.orderId}/driver-notifications`)
                .then(response => {
                    if (response.data.status === 1) {
                        this.notificationData = response.data.data;
                    } else {
                        this.showError(response.data.message || "Failed to load notifications");
                    }
                })
                .catch(error => {
                    console.error("Error fetching notifications:", error);
                    this.showError("Failed to load notification history");
                })
                .finally(() => {
                    this.isLoading = false;
                });
        },

        retryNotification() {
            this.$swal.fire({
                title: "Send Notification",
                text: "Send notification to available delivery boys near the seller locations?",
                icon: "question",
                showCancelButton: true,
                confirmButtonText: "Yes, Send",
                cancelButtonText: "Cancel",
                confirmButtonColor: "#9AC444"
            }).then(result => {
                if (result.value) {
                    this.isRetrying = true;
                    axios.post(this.$apiUrl + `/orders/${this.orderId}/retry-driver-notification`)
                        .then(response => {
                            if (response.data.status === 1) {
                                this.showMessage("success", response.data.message);
                                this.fetchNotifications(); // Refresh data
                            } else {
                                this.showMessage("warning", response.data.message);
                                this.fetchNotifications(); // Refresh to show new attempt
                            }
                        })
                        .catch(error => {
                            console.error("Error retrying notification:", error);
                            this.showError("Failed to send notification");
                        })
                        .finally(() => {
                            this.isRetrying = false;
                        });
                }
            });
        },

        toggleDriverList(notificationId, type) {
            if (type === 'notified') {
                this.expandedNotified = this.expandedNotified === notificationId ? null : notificationId;
            } else {
                this.expandedOnRide = this.expandedOnRide === notificationId ? null : notificationId;
            }
        },

        toggleSkipReasons(notificationId) {
            this.expandedSkipReasons = this.expandedSkipReasons === notificationId ? null : notificationId;
        },

        totalSkipped(skipReasons) {
            if (!skipReasons) return 0;
            // New format: {funnel_summary, individual_groups}
            if (skipReasons.individual_groups) {
                return skipReasons.individual_groups.reduce((sum, g) => sum + (g.count || 0), 0);
            }
            // Old format: array of groups
            if (Array.isArray(skipReasons)) {
                return skipReasons.reduce((sum, g) => sum + (g.count || 0), 0);
            }
            return 0;
        },

        funnelLabel(skipReasons) {
            if (!skipReasons) return '';
            if (skipReasons.funnel_summary) {
                const f = skipReasons.funnel_summary;
                if (f.final_notified !== undefined) {
                    return `${f.online || 0} online → ${f.within_radius || 0} in range → ${f.final_notified} notified`;
                }
                return `${f.online || 0} online → ${f.within_radius || 0} in range`;
            }
            // Old format fallback
            const total = this.totalSkipped(skipReasons);
            return `${total} skipped`;
        },

        closestSellerDistance(distances) {
            if (!distances || distances.length === 0) return 'N/A';
            const sorted = [...distances].sort((a, b) => (a.distance_km || Infinity) - (b.distance_km || Infinity));
            const closest = sorted[0];
            return closest.distance_km != null ? `${closest.distance_km} km` : 'N/A';
        },

        getSkipReasonBadgeClass(reason) {
            const classes = {
                order_priority:         'bg-purple',           // [1]
                no_location:            'bg-warning text-dark', // [2]
                out_of_customer_radius: 'bg-danger',           // [3]
                no_active_session:      'bg-dark',             // [4]
                no_active_gig_booking:  'bg-secondary',        // [5]
                hand_cash_exceeded:     'bg-danger',           // [6]
                on_ride:                'bg-warning text-dark', // [7]
            };
            return classes[reason] || 'bg-secondary';
        },

        formatStatus(status) {
            if (!status) return 'N/A';
            const labels = {
                'sent': 'Sent',
                'accepted': 'Accepted',
                'expired': 'Expired',
                'failed': 'Failed'
            };
            return labels[status] || status;
        },

        getStatusBadgeClass(status) {
            const classes = {
                'sent': 'bg-info',
                'accepted': 'bg-success',
                'expired': 'bg-secondary',
                'failed': 'bg-danger'
            };
            return classes[status] || 'bg-secondary';
        },

        getStatusCardClass(status) {
            const classes = {
                'sent': 'bg-info text-white',
                'accepted': 'bg-success text-white',
                'expired': 'bg-secondary text-white',
                'failed': 'bg-danger text-white'
            };
            return classes[status] || 'bg-light';
        }
    }
};
</script>

<style scoped>
.driver-notifications {
    padding: 20px 0;
}

.opacity-50 {
    opacity: 0.5;
}

.card {
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.table th {
    background-color: #f8f9fa;
    font-weight: 600;
}

.badge {
    font-weight: 500;
}

.skip-reasons-panel {
    background-color: #fff8f8;
    border-top: 2px solid #f8d7da;
}

.skip-reason-group {
    border-left: 3px solid #dee2e6;
    padding-left: 10px;
}

.skip-reason-label {
    font-size: 0.875rem;
    color: #495057;
}

.bg-purple {
    background-color: #6f42c1 !important;
    color: #fff !important;
}

.funnel-summary {
    background: #f0f4ff;
    border-radius: 6px;
    padding: 10px 14px;
    display: inline-block;
    border: 1px solid #d0d9f0;
}

.funnel-row {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 2px;
}

.funnel-badge {
    min-width: 36px;
    text-align: center;
}

.funnel-label {
    font-size: 0.875rem;
    color: #495057;
}

.funnel-arrow {
    color: #6c757d;
    font-size: 1rem;
    margin-left: 14px;
    margin-bottom: 2px;
    line-height: 1;
}

/* ─── Dark mode ─── */
@media (prefers-color-scheme: dark) {
    .table th { background-color: #374151 !important; color: #e5e7eb; }
    .skip-reasons-panel { background-color: #1f1a1a; border-top-color: #7f1d1d; }
    .skip-reason-label, .funnel-label { color: #d1d5db; }
    .funnel-summary { background: #1e2a42; border-color: #2e4a7a; }
    .funnel-arrow { color: #9ca3af; }
    .table .text-muted { color: #9ca3af !important; }
}

.dark-mode .table th,
[data-theme="dark"] .table th,
body.dark .table th {
    background-color: #374151 !important;
    color: #e5e7eb;
}

.dark-mode .skip-reasons-panel,
[data-theme="dark"] .skip-reasons-panel,
body.dark .skip-reasons-panel {
    background-color: #1f1a1a;
    border-top-color: #7f1d1d;
}

.dark-mode .skip-reason-label,
[data-theme="dark"] .skip-reason-label,
body.dark .skip-reason-label,
.dark-mode .funnel-label,
[data-theme="dark"] .funnel-label,
body.dark .funnel-label {
    color: #d1d5db;
}

.dark-mode .funnel-summary,
[data-theme="dark"] .funnel-summary,
body.dark .funnel-summary {
    background: #1e2a42;
    border-color: #2e4a7a;
}

.dark-mode .funnel-arrow,
[data-theme="dark"] .funnel-arrow,
body.dark .funnel-arrow {
    color: #9ca3af;
}

/* Driver name text — make readable on dark table backgrounds */
.dark-mode .table .text-muted,
[data-theme="dark"] .table .text-muted,
body.dark .table .text-muted {
    color: #9ca3af !important;
}

/* Delivery Boy summary card name text */
.dark-mode .card h6,
[data-theme="dark"] .card h6,
body.dark .card h6 {
    color: inherit;
}
</style>