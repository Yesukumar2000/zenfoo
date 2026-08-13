<template>
    <div>
        <!-- Filters -->
        <b-row class="mb-3">
            <b-col md="3">
                <label class="form-label">Filter by Status</label>
                <select v-model="filterStatus" @change="fetchIssues()" class="form-control form-select">
                    <option value="">All Status</option>
                    <option value="pending">Pending</option>
                    <option value="resolved">Resolved</option>
                    <option value="rejected">Rejected</option>
                </select>
            </b-col>
            <b-col md="3" offset-md="5">
                <label class="form-label">{{ __('search') }}</label>
                <b-form-input v-model="filter" type="search" :placeholder="__('search')"></b-form-input>
            </b-col>
            <b-col md="1" class="d-flex align-items-end">
                <button class="btn btn-primary" @click="fetchIssues()">
                    <i class="fa fa-refresh"></i>
                </button>
            </b-col>
        </b-row>

        <!-- Table -->
        <b-table
            :items="issues"
            :fields="fields"
            :filter="filter"
            :busy="isLoading"
            :per-page="perPage"
            :current-page="currentPage"
            bordered
            hover
            show-empty
            responsive>

            <template #table-busy>
                <div class="text-center my-2">
                    <b-spinner class="align-middle"></b-spinner>
                    <strong class="ms-2">{{ __('loading') }}...</strong>
                </div>
            </template>

            <template #cell(driver)="row">
                <div v-if="row.item.delivery_boy">
                    <strong>{{ row.item.delivery_boy.name }}</strong>
                </div>
                <span v-else class="text-muted">N/A</span>
            </template>

            <template #cell(mobile)="row">
                <div v-if="row.item.delivery_boy && row.item.delivery_boy.mobile">
                    <a :href="'tel:' + row.item.delivery_boy.mobile" class="text-primary">
                        <i class="fa fa-phone me-1"></i>{{ row.item.delivery_boy.mobile }}
                    </a>
                </div>
                <span v-else class="text-muted">N/A</span>
            </template>

            <template #cell(city)="row">
                <span v-if="row.item.delivery_boy && row.item.delivery_boy.city">
                    {{ row.item.delivery_boy.city.name }}
                </span>
                <span v-else class="text-muted">N/A</span>
            </template>

            <template #cell(issue_ids)="row">
                <span v-if="row.item.issue_ids && row.item.issue_ids.length">
                    {{ row.item.issue_ids.join(', ') }}
                </span>
                <span v-else class="text-muted">-</span>
            </template>

            <template #cell(description)="row">
                <span v-if="row.item.description">
                    {{ row.item.description.length > 50 ? row.item.description.substring(0, 50) + '...' : row.item.description }}
                </span>
                <span v-else class="text-muted">-</span>
            </template>

            <template #cell(attachments)="row">
                <span v-if="row.item.attachments && row.item.attachments.length" class="badge bg-info">
                    {{ row.item.attachments.length }} file(s)
                </span>
                <span v-else class="text-muted">-</span>
            </template>

            <template #cell(status)="row">
                <span class="badge" :class="getStatusBadgeClass(row.item.status)">
                    {{ row.item.status }}
                </span>
            </template>

            <template #cell(created_at)="row">
                {{ formatDate(row.item.created_at) }}
            </template>

            <template #cell(actions)="row">
                <router-link :to="'/delivery-boys/issues/view/' + row.item.id" class="btn btn-sm btn-info">
                    <i class="fa fa-eye"></i>
                </router-link>
            </template>
        </b-table>

        <!-- Pagination -->
        <b-row>
            <b-col md="2">
                <b-form-group :label="__('per_page')" label-size="sm" class="mb-0">
                    <b-form-select v-model="perPage" :options="pageOptions" size="sm" class="form-select"></b-form-select>
                </b-form-group>
            </b-col>
            <b-col md="4" offset-md="6">
                <b-pagination v-model="currentPage" :total-rows="totalRows" :per-page="perPage" align="right" size="sm"></b-pagination>
            </b-col>
        </b-row>
    </div>
</template>

<script>
export default {
    name: 'OrderEarningIssues',
    props: {
        cityId: {
            type: [String, Number],
            default: ''
        }
    },
    data() {
        return {
            issueType: 'order_earning',
            isLoading: false,
            issues: [],
            filter: '',
            filterStatus: '',
            currentPage: 1,
            perPage: 10,
            pageOptions: [5, 10, 15, 20, 50],
            fields: [
                { key: 'id', label: 'ID', sortable: true },
                { key: 'driver', label: 'Driver', sortable: false },
                { key: 'mobile', label: 'Mobile', sortable: false },
                { key: 'city', label: 'City', sortable: false },
                { key: 'issue_ids', label: 'Order IDs', sortable: false },
                { key: 'description', label: 'Description', sortable: false },
                { key: 'attachments', label: 'Attachments', sortable: false },
                { key: 'status', label: 'Status', sortable: true },
                { key: 'created_at', label: 'Submitted On', sortable: true },
                { key: 'actions', label: 'Actions', sortable: false }
            ]
        }
    },
    computed: {
        totalRows() {
            return this.issues.length;
        }
    },
    watch: {
        cityId() {
            this.fetchIssues();
        }
    },
    created() {
        this.fetchIssues();
    },
    methods: {
        fetchIssues() {
            this.isLoading = true;
            const params = { issue_type: this.issueType };
            if (this.filterStatus) params.status = this.filterStatus;
            if (this.cityId) params.city_id = this.cityId;

            axios.get(this.$apiUrl + '/admin/driver-issues-zenfoo', { params })
                .then((response) => {
                    if (response.data.status === 1) {
                        this.issues = response.data.data;
                    }
                    this.isLoading = false;
                })
                .catch((error) => {
                    console.error('Error fetching issues:', error);
                    this.isLoading = false;
                });
        },
        formatDate(dateString) {
            if (!dateString) return '';
            const date = new Date(dateString);
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
        },
        getStatusBadgeClass(status) {
            const classes = {
                pending: 'bg-warning text-dark',
                resolved: 'bg-success',
                rejected: 'bg-danger'
            };
            return classes[status] || 'bg-secondary';
        }
    }
}
</script>
