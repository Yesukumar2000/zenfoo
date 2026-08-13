<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>Customer Suggestions</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">Customer Suggestions</li>
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
                        <h4 class="card-title">All Customer Suggestions</h4>
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
                                <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="fetchSuggestions()">
                                    <i class="fa fa-refresh" aria-hidden="true"></i>
                                </button>
                            </b-col>
                        </b-row>

                        <!-- Suggestions Table -->
                        <b-table
                            :items="suggestions"
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

                            <template #cell(customer_name)="row">
                                {{ (row.item.customer && row.item.customer.name) ? row.item.customer.name : 'N/A' }}
                            </template>

                            <template #cell(customer_mobile)="row">
                                {{ (row.item.customer && row.item.customer.mobile) ? row.item.customer.mobile : 'N/A' }}
                            </template>

                            <template #cell(suggestion)="row">
                                <div style="max-width: 300px; white-space: normal;">
                                    {{ row.item.suggestion.substring(0, 100) }}{{ row.item.suggestion.length > 100 ? '...' : '' }}
                                </div>
                            </template>

                            <template #cell(admin_response)="row">
                                <span v-if="row.item.admin_response" class="badge bg-success">Responded</span>
                                <span v-else class="badge bg-warning">Pending</span>
                            </template>

                            <template #cell(created_at)="row">
                                {{ formatDate(row.item.created_at) }}
                            </template>

                            <template #cell(actions)="row">
                                <button class="btn btn-sm btn-info me-1" @click="viewSuggestion(row.item)" v-b-tooltip.hover title="View & Respond">
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
                </div>
            </section>
        </div>

        <!-- View/Respond Modal -->
        <b-modal
            id="suggestion-modal"
            v-model="showModal"
            title="Customer Suggestion"
            size="lg"
            hide-footer>
            <div v-if="selectedSuggestion">
                <div class="mb-3">
                    <h6>Customer Details:</h6>
                    <p><strong>Name:</strong> {{ (selectedSuggestion.customer && selectedSuggestion.customer.name) ? selectedSuggestion.customer.name : 'N/A' }}</p>
                    <p><strong>Mobile:</strong> {{ (selectedSuggestion.customer && selectedSuggestion.customer.mobile) ? selectedSuggestion.customer.mobile : 'N/A' }}</p>
                    <p><strong>Email:</strong> {{ (selectedSuggestion.customer && selectedSuggestion.customer.email) ? selectedSuggestion.customer.email : 'N/A' }}</p>
                    <p><strong>Date:</strong> {{ formatDate(selectedSuggestion.created_at) }}</p>
                </div>
                <div class="mb-3">
                    <h6>Suggestion:</h6>
                    <p class="p-3 border rounded">{{ selectedSuggestion.suggestion }}</p>
                </div>
                <div class="mb-3">
                    <h6>Admin Response:</h6>
                    <b-form-textarea
                        v-model="adminResponse"
                        placeholder="Type your response here..."
                        rows="4"
                        max-rows="8"
                        :state="validationErrors.admin_response ? false : null"
                        @input="validationErrors.admin_response = null"
                    ></b-form-textarea>
                    <b-form-invalid-feedback v-if="validationErrors.admin_response">
                        {{ validationErrors.admin_response[0] }}
                    </b-form-invalid-feedback>
                </div>
                <div class="text-end">
                    <button class="btn btn-secondary me-2" @click="closeModal">Cancel</button>
                    <button class="btn btn-primary" @click="submitResponse" :disabled="isSaving">
                        <b-spinner small v-if="isSaving"></b-spinner>
                        {{ isSaving ? 'Saving...' : 'Save Response' }}
                    </button>
                </div>
            </div>
        </b-modal>
    </div>
</template>

<script>
import axios from 'axios';

export default {
    name: 'CustomerSuggestions',
    data() {
        return {
            suggestions: [],
            fields: [
                { key: 'id', label: 'ID', sortable: true },
                { key: 'customer_name', label: 'Customer Name', sortable: true },
                { key: 'customer_mobile', label: 'Mobile', sortable: false },
                { key: 'suggestion', label: 'Suggestion', sortable: false },
                { key: 'admin_response', label: 'Status', sortable: true },
                { key: 'created_at', label: 'Date', sortable: true },
                { key: 'actions', label: 'Actions', sortable: false }
            ],
            currentPage: 1,
            perPage: 10,
            totalRows: 0,
            pageOptions: [5, 10, 15, 25, 50, 100],
            sortBy: 'created_at',
            sortDesc: true,
            sortDirection: 'desc',
            filter: null,
            filterOn: [],
            isLoading: false,
            showModal: false,
            selectedSuggestion: null,
            adminResponse: '',
            isSaving: false,
            validationErrors: {}
        };
    },
    mounted() {
        this.fetchSuggestions();
    },
    methods: {
        async fetchSuggestions() {
            this.isLoading = true;
            try {
                const response = await axios.get(`${this.$baseUrl}/api/admin/customer-suggestions`);
                if (response.data.success) {
                    this.suggestions = response.data.data.map(item => ({
                        ...item,
                        _showDetails: false
                    }));
                    this.totalRows = this.suggestions.length;
                }
            } catch (error) {
                console.error('Error fetching suggestions:', error);
                this.$bvToast.toast('Failed to load customer suggestions', {
                    title: 'Error',
                    variant: 'danger',
                    solid: true
                });
            } finally {
                this.isLoading = false;
            }
        },
        viewSuggestion(suggestion) {
            this.selectedSuggestion = suggestion;
            this.adminResponse = suggestion.admin_response || '';
            this.showModal = true;
        },
        closeModal() {
            this.showModal = false;
            this.selectedSuggestion = null;
            this.adminResponse = '';
            this.validationErrors = {};
        },
        async submitResponse() {
            if (!this.adminResponse.trim()) {
                this.$bvToast.toast('Please enter a response', {
                    title: 'Validation Error',
                    variant: 'warning',
                    solid: true
                });
                return;
            }

            this.isSaving = true;
            try {
                const response = await axios.post(`${this.$baseUrl}/api/admin/customer-suggestions/${this.selectedSuggestion.id}/respond`, {
                    admin_response: this.adminResponse
                });

                if (response.data.success) {
                    this.$bvToast.toast('Response saved successfully', {
                        title: 'Success',
                        variant: 'success',
                        solid: true
                    });
                    this.closeModal();
                    this.fetchSuggestions();
                }
            } catch (error) {
                console.error('Error saving response:', error);
                if (error.response && error.response.status === 422 && error.response.data.errors) {
                    this.validationErrors = error.response.data.errors;
                } else {
                    this.$bvToast.toast('Failed to save response', {
                        title: 'Error',
                        variant: 'danger',
                        solid: true
                    });
                }
            } finally {
                this.isSaving = false;
            }
        },
        formatDate(date) {
            if (!date) return 'N/A';
            return new Date(date).toLocaleString('en-IN', {
                year: 'numeric',
                month: 'short',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        }
    }
};
</script>

<style scoped>
.btn_refresh {
    margin-top: 28px;
}
</style>
