<template>
    <div>
        <!-- View Report Detail -->
        <ViewCustomerReport
            v-if="selectedReportId"
            :reportId="selectedReportId"
            @back="handleBackToList"
        />

        <!-- Reports List -->
        <div v-else class="card">
            <div class="card-header">
                <h4 class="mb-0"><i class="fas fa-exclamation-triangle me-2"></i>Customer Reports</h4>
            </div>
            <div class="card-body">
                <!-- Loading State -->
                <div v-if="isLoading" class="text-center py-4">
                    <b-spinner label="Loading..."></b-spinner>
                    <p class="mt-2 text-muted">Loading reports...</p>
                </div>

                <!-- No Reports -->
                <div v-else-if="totalCount === 0" class="alert alert-info">
                    <i class="fas fa-info-circle me-2"></i>
                    No customer issue reports found for this order.
                </div>

                <!-- Reports Content -->
                <div v-else>
                <!-- Sub Tabs for Missing, Wrong and Return -->
                <ul class="nav nav-pills mb-3">
                    <li class="nav-item">
                        <a class="nav-link" :class="{ active: activeReportTab === 'missing' }" href="#" @click.prevent="activeReportTab = 'missing'">
                            <i class="fas fa-box-open me-2"></i>Missing Items
                            <span class="badge bg-secondary ms-2">{{ missingCount }}</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" :class="{ active: activeReportTab === 'wrong' }" href="#" @click.prevent="activeReportTab = 'wrong'">
                            <i class="fas fa-exchange-alt me-2"></i>Wrong Items
                            <span class="badge bg-secondary ms-2">{{ wrongCount }}</span>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" :class="{ active: activeReportTab === 'return' }" href="#" @click.prevent="activeReportTab = 'return'">
                            <i class="fas fa-undo-alt me-2"></i>Return Items
                            <span class="badge bg-secondary ms-2">{{ returnCount }}</span>
                        </a>
                    </li>
                </ul>

                <!-- Missing Items Tab Content -->
                <div v-if="activeReportTab === 'missing'">
                    <div v-if="missingReports.length === 0" class="alert alert-light">
                        <i class="fas fa-info-circle me-2"></i>
                        No missing item reports found.
                    </div>
                    <div v-else>
                        <b-table
                            :items="missingReports"
                            :fields="fields"
                            :bordered="true"
                            stacked="md"
                            show-empty
                            small>

                            <template #cell(status)="row">
                                <span v-if="row.item.status === 0" class="badge bg-warning">Pending</span>
                                <span v-else-if="row.item.status === 1" class="badge bg-info">In Progress</span>
                                <span v-else-if="row.item.status === 2" class="badge bg-success">Resolved</span>
                                <span v-else-if="row.item.status === 3" class="badge bg-danger">Rejected</span>
                                <span v-else-if="row.item.status === 4" class="badge bg-primary">Driver Assigned</span>
                                <span v-else-if="row.item.status === 5" class="badge bg-info">Driver Took Item</span>
                                <span v-else-if="row.item.status === 6" class="badge bg-success">Driver Returned Item</span>
                                <span v-else class="badge bg-secondary">Unknown</span>
                            </template>

                            <template #cell(is_refund_requested)="row">
                                <span v-if="row.item.is_refund_requested" class="badge bg-primary">Yes</span>
                                <span v-else class="badge bg-secondary">No</span>
                            </template>

                            <template #cell(created_at)="row">
                                {{ formatDate(row.item.created_at) }}
                            </template>

                            <template #cell(actions)="row">
                                <button class="btn btn-sm btn-info" @click="viewReport(row.item)" v-b-tooltip.hover title="View Report">
                                    <i class="fa fa-eye"></i>
                                </button>
                            </template>

                        </b-table>
                    </div>
                </div>

                <!-- Wrong Items Tab Content -->
                <div v-if="activeReportTab === 'wrong'">
                    <div v-if="wrongReports.length === 0" class="alert alert-light">
                        <i class="fas fa-info-circle me-2"></i>
                        No wrong item reports found.
                    </div>
                    <div v-else>
                        <b-table
                            :items="wrongReports"
                            :fields="fields"
                            :bordered="true"
                            stacked="md"
                            show-empty
                            small>

                            <template #cell(status)="row">
                                <span v-if="row.item.status === 0" class="badge bg-warning">Pending</span>
                                <span v-else-if="row.item.status === 1" class="badge bg-info">In Progress</span>
                                <span v-else-if="row.item.status === 2" class="badge bg-success">Resolved</span>
                                <span v-else-if="row.item.status === 3" class="badge bg-danger">Rejected</span>
                                <span v-else-if="row.item.status === 4" class="badge bg-primary">Driver Assigned</span>
                                <span v-else-if="row.item.status === 5" class="badge bg-info">Driver Took Item</span>
                                <span v-else-if="row.item.status === 6" class="badge bg-success">Driver Returned Item</span>
                                <span v-else class="badge bg-secondary">Unknown</span>
                            </template>

                            <template #cell(is_refund_requested)="row">
                                <span v-if="row.item.is_refund_requested" class="badge bg-primary">Yes</span>
                                <span v-else class="badge bg-secondary">No</span>
                            </template>

                            <template #cell(created_at)="row">
                                {{ formatDate(row.item.created_at) }}
                            </template>

                            <template #cell(actions)="row">
                                <button class="btn btn-sm btn-info" @click="viewReport(row.item)" v-b-tooltip.hover title="View Report">
                                    <i class="fa fa-eye"></i>
                                </button>
                            </template>

                        </b-table>
                    </div>
                </div>

                <!-- Return Items Tab Content -->
                <div v-if="activeReportTab === 'return'">
                    <div v-if="returnReports.length === 0" class="alert alert-light">
                        <i class="fas fa-info-circle me-2"></i>
                        No return item reports found.
                    </div>
                    <div v-else>
                        <b-table
                            :items="returnReports"
                            :fields="fields"
                            :bordered="true"
                            stacked="md"
                            show-empty
                            small>

                            <template #cell(status)="row">
                                <span v-if="row.item.status === 0" class="badge bg-warning">Pending</span>
                                <span v-else-if="row.item.status === 1" class="badge bg-info">In Progress</span>
                                <span v-else-if="row.item.status === 2" class="badge bg-success">Resolved</span>
                                <span v-else-if="row.item.status === 3" class="badge bg-danger">Rejected</span>
                                <span v-else-if="row.item.status === 4" class="badge bg-primary">Driver Assigned</span>
                                <span v-else-if="row.item.status === 5" class="badge bg-info">Driver Took Item</span>
                                <span v-else-if="row.item.status === 6" class="badge bg-success">Driver Returned Item</span>
                                <span v-else class="badge bg-secondary">Unknown</span>
                            </template>

                            <template #cell(is_refund_requested)="row">
                                <span v-if="row.item.is_refund_requested" class="badge bg-primary">Yes</span>
                                <span v-else class="badge bg-secondary">No</span>
                            </template>

                            <template #cell(created_at)="row">
                                {{ formatDate(row.item.created_at) }}
                            </template>

                            <template #cell(actions)="row">
                                <button class="btn btn-sm btn-info" @click="viewReport(row.item)" v-b-tooltip.hover title="View Report">
                                    <i class="fa fa-eye"></i>
                                </button>
                            </template>

                        </b-table>
                    </div>
                </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import axios from "axios";
import ViewCustomerReport from "./ViewCustomerReport.vue";

export default {
    name: 'CustomerReports',
    components: {
        ViewCustomerReport
    },
    props: {
        orderId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            isLoading: false,
            activeReportTab: 'missing',
            missingReports: [],
            wrongReports: [],
            returnReports: [],
            missingCount: 0,
            wrongCount: 0,
            returnCount: 0,
            totalCount: 0,
            selectedReportId: null,
            fields: [
                { key: 'id', label: 'Report ID', sortable: true, class: 'text-center' },
                { key: 'is_refund_requested', label: 'Refund', sortable: true, class: 'text-center' },
                { key: 'status', label: 'Status', sortable: true, class: 'text-center' },
                { key: 'created_at', label: 'Date', sortable: true, class: 'text-center' },
                { key: 'actions', label: 'Action', class: 'text-center' }
            ],
        }
    },
    created() {
        this.fetchReports();
    },
    methods: {
        fetchReports() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/customer_issue_reports/by_order', {
                params: { order_id: this.orderId }
            })
            .then((response) => {
                this.isLoading = false;
                if (response.data.status === 1) {
                    const data = response.data.message;
                    this.missingReports = data.missing_reports || [];
                    this.wrongReports = data.wrong_reports || [];
                    this.returnReports = data.return_reports || [];
                    this.missingCount = data.missing_count || 0;
                    this.wrongCount = data.wrong_count || 0;
                    this.returnCount = data.return_count || 0;
                    this.totalCount = data.total_count || 0;

                    // Set default tab based on which has reports
                    if (this.missingCount === 0 && this.wrongCount > 0) {
                        this.activeReportTab = 'wrong';
                    } else if (this.missingCount === 0 && this.wrongCount === 0 && this.returnCount > 0) {
                        this.activeReportTab = 'return';
                    }
                } else {
                    this.showError(response.data.message || 'Failed to fetch reports');
                }
            })
            .catch((error) => {
                this.isLoading = false;
                console.error('Error fetching reports:', error);
                this.showError('Failed to fetch reports. Please try again.');
            });
        },
        formatDate(dateTime) {
            if (!dateTime) return '-';
            const date = new Date(dateTime);
            const day = date.getDate().toString().padStart(2, '0');
            const month = (date.getMonth() + 1).toString().padStart(2, '0');
            const year = date.getFullYear();
            const hours = date.getHours().toString().padStart(2, '0');
            const minutes = date.getMinutes().toString().padStart(2, '0');
            return `${day}-${month}-${year} ${hours}:${minutes}`;
        },
        viewReport(report) {
            this.selectedReportId = report.id;
        },
        handleBackToList() {
            this.selectedReportId = null;
            this.fetchReports();
        },
        showError(message) {
            if (this.$toast) {
                this.$toast.error(message);
            } else {
                console.error(message);
            }
        },
        showSuccess(message) {
            if (this.$toast) {
                this.$toast.success(message);
            } else {
                console.log(message);
            }
        }
    }
}
</script>

<style scoped>
.nav-pills .nav-link {
    color: #495057;
    background-color: #f8f9fa;
    border: 1px solid #dee2e6;
    margin-right: 5px;
}
.nav-pills .nav-link:hover {
    background-color: #e9ecef;
}
.nav-pills .nav-link.active {
    color: #fff;
    background-color: #17a2b8;
    border-color: #17a2b8;
}
</style>
