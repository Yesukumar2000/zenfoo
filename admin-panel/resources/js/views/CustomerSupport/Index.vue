<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>Customer Support</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">Customer Support</li>
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
                    <div class="card-header">
                        <!-- Tabs Header -->
                        <ul class="nav nav-tabs card-header-tabs" role="tablist">
                            <li class="nav-item">
                                <a
                                    class="nav-link"
                                    :class="{ active: activeTab === 'item_missing' }"
                                    href="#"
                                    @click.prevent="switchTab('item_missing')"
                                >
                                    Item Missing
                                </a>
                            </li>
                            <li class="nav-item">
                                <a
                                    class="nav-link"
                                    :class="{ active: activeTab === 'wrong_item' }"
                                    href="#"
                                    @click.prevent="switchTab('wrong_item')"
                                >
                                    Wrong Item Received
                                </a>
                            </li>
                        </ul>
                    </div>
                    <div class="card-body">
                        <!-- Search and Refresh -->
                        <b-row class="mb-3">
                            <b-col md="3" offset-md="8">
                                <h6 class="box-title">{{ __('search') }}</h6>
                                <b-form-input id="filter-input" v-model="filter" type="search"
                                              :placeholder="__('search')"></b-form-input>
                            </b-col>
                            <b-col md="1" class="text-center">
                                <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="fetchReports()">
                                    <i class="fa fa-refresh" aria-hidden="true"></i>
                                </button>
                            </b-col>
                        </b-row>

                        <!-- Item Missing Tab Content -->
                        <div v-if="activeTab === 'item_missing'">
                            <b-table
                                :items="missingReports"
                                :fields="fields"
                                :current-page="currentPage"
                                :per-page="perPage"
                                :filter="filter"
                                :filter-included-fields="filterOn"
                                :sort-by.sync="sortBy"
                                :sort-desc.sync="sortDesc"
                                :sort-direction="sortDirection"
                                :bordered="true"
                                :busy="isLoading"
                                stacked="md"
                                show-empty
                                small>

                                <template #table-busy>
                                    <div class="text-center text-black my-2">
                                        <b-spinner class="align-middle"></b-spinner>
                                        <strong>{{ __('loading') }}...</strong>
                                    </div>
                                </template>

                                <template #cell(status)="row">
                                    <span v-if="row.item.status === 0" class="badge bg-warning">Pending</span>
                                    <span v-else-if="row.item.status === 1" class="badge bg-info">In Progress</span>
                                    <span v-else-if="row.item.status === 2" class="badge bg-success">Resolved</span>
                                    <span v-else-if="row.item.status === 3" class="badge bg-danger">Rejected</span>
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
                                    <button class="btn btn-sm btn-info" @click="viewReport(row.item)" v-b-tooltip.hover title="View">
                                        <i class="fa fa-eye"></i>
                                    </button>
                                </template>

                            </b-table>

                            <!-- Pagination -->
                            <b-row>
                                <b-col md="2" class="my-1">
                                    <b-form-group
                                        :label="__('per_page')"
                                        label-for="per-page-select"
                                        label-align-sm="right"
                                        label-size="sm"
                                        class="mb-0">
                                        <b-form-select
                                            id="per-page-select"
                                            v-model="perPage"
                                            :options="pageOptions"
                                            size="sm"
                                            class="form-control form-select"
                                        ></b-form-select>
                                    </b-form-group>
                                </b-col>
                                <b-col md="4" class="my-1" offset-md="6">
                                    <b-pagination
                                        v-model="currentPage"
                                        :total-rows="totalRows"
                                        :per-page="perPage"
                                        align="fill"
                                        size="sm"
                                        class="my-0"
                                    ></b-pagination>
                                </b-col>
                            </b-row>
                        </div>

                        <!-- Wrong Item Tab Content -->
                        <div v-if="activeTab === 'wrong_item'">
                            <b-table
                                :items="wrongItemReports"
                                :fields="fields"
                                :current-page="wrongCurrentPage"
                                :per-page="perPage"
                                :filter="filter"
                                :filter-included-fields="filterOn"
                                :sort-by.sync="sortBy"
                                :sort-desc.sync="sortDesc"
                                :sort-direction="sortDirection"
                                :bordered="true"
                                :busy="isLoading"
                                stacked="md"
                                show-empty
                                small>

                                <template #table-busy>
                                    <div class="text-center text-black my-2">
                                        <b-spinner class="align-middle"></b-spinner>
                                        <strong>{{ __('loading') }}...</strong>
                                    </div>
                                </template>

                                <template #cell(status)="row">
                                    <span v-if="row.item.status === 0" class="badge bg-warning">Pending</span>
                                    <span v-else-if="row.item.status === 1" class="badge bg-info">In Progress</span>
                                    <span v-else-if="row.item.status === 2" class="badge bg-success">Resolved</span>
                                    <span v-else-if="row.item.status === 3" class="badge bg-danger">Rejected</span>
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
                                    <button class="btn btn-sm btn-info" @click="viewReport(row.item)" v-b-tooltip.hover title="View">
                                        <i class="fa fa-eye"></i>
                                    </button>
                                </template>

                            </b-table>

                            <!-- Pagination -->
                            <b-row>
                                <b-col md="2" class="my-1">
                                    <b-form-group
                                        :label="__('per_page')"
                                        label-for="per-page-select-wrong"
                                        label-align-sm="right"
                                        label-size="sm"
                                        class="mb-0">
                                        <b-form-select
                                            id="per-page-select-wrong"
                                            v-model="perPage"
                                            :options="pageOptions"
                                            size="sm"
                                            class="form-control form-select"
                                        ></b-form-select>
                                    </b-form-group>
                                </b-col>
                                <b-col md="4" class="my-1" offset-md="6">
                                    <b-pagination
                                        v-model="wrongCurrentPage"
                                        :total-rows="wrongTotalRows"
                                        :per-page="perPage"
                                        align="fill"
                                        size="sm"
                                        class="my-0"
                                    ></b-pagination>
                                </b-col>
                            </b-row>
                        </div>
                    </div>
                </div>
            </section>
        </div>
    </div>
</template>

<script>
export default {
    name: 'CustomerSupport',
    data() {
        return {
            activeTab: 'item_missing',
            isLoading: false,
            filter: null,
            filterOn: [],

            // Table fields
            fields: [
                { key: 'id', label: 'ID', sortable: true, sortDirection: 'desc' },
                { key: 'customer_name', label: 'Customer', sortable: true, class: 'text-center' },
                { key: 'customer_mobile', label: 'Mobile', sortable: true, class: 'text-center' },
                { key: 'order_id', label: 'Order ID', sortable: true, class: 'text-center' },
                { key: 'is_refund_requested', label: 'Refund', sortable: true, class: 'text-center' },
                { key: 'status', label: 'Status', sortable: true, class: 'text-center' },
                { key: 'created_at', label: 'Date', sortable: true, class: 'text-center' },
                { key: 'actions', label: 'Action', class: 'text-center' }
            ],

            // Missing reports
            missingReports: [],
            totalRows: 0,
            currentPage: 1,

            // Wrong item reports
            wrongItemReports: [],
            wrongTotalRows: 0,
            wrongCurrentPage: 1,

            // Pagination
            perPage: this.$perPage || 10,
            pageOptions: this.$pageOptions || [5, 10, 15, 20, 50],
            sortBy: 'id',
            sortDesc: true,
            sortDirection: 'desc',
        }
    },
    created() {
        this.fetchReports();
    },
    methods: {
        switchTab(tab) {
            this.activeTab = tab;
            this.fetchReports();
        },
        fetchReports() {
            this.isLoading = true;
            const reportType = this.activeTab === 'item_missing' ? 'missing' : 'wrong';

            axios.get(this.$apiUrl + '/customer_issue_reports', {
                params: {
                    report_type: reportType
                }
            })
            .then((response) => {
                if (response.data.status === 1) {
                    if (this.activeTab === 'item_missing') {
                        this.missingReports = response.data.data;
                        this.totalRows = this.missingReports.length;
                    } else {
                        this.wrongItemReports = response.data.data;
                        this.wrongTotalRows = this.wrongItemReports.length;
                    }
                }
                this.isLoading = false;
            })
            .catch((error) => {
                console.error('Error fetching reports:', error);
                this.isLoading = false;
            });
        },
        viewReport(report) {
            this.$router.push('/customer-support/view/' + report.id);
        },
        formatDate(dateString) {
            if (!dateString) return '';
            const date = new Date(dateString);
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
        }
    }
}
</script>

<style scoped>
.nav-tabs .nav-link {
    cursor: pointer;
    color: #495057;
    border: 1px solid transparent;
    border-top-left-radius: 0.25rem;
    border-top-right-radius: 0.25rem;
}

.nav-tabs .nav-link:hover {
    border-color: #e9ecef #e9ecef #dee2e6;
}

.nav-tabs .nav-link.active {
    color: #495057;
    background-color: #fff;
    border-color: #dee2e6 #dee2e6 #fff;
    font-weight: 600;
}

.btn_refresh {
    margin-top: 24px;
}
</style>
