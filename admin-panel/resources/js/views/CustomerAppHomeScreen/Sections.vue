<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Customer App Home Screen - Sections</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item"><router-link to="/dashboard">Dashboard</router-link></li>
                            <li class="breadcrumb-item active" aria-current="page">Sections</li>
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
            <div class="col-12 col-md-12 order-md-1 order-last">
                <div class="card">
                    <div class="card-header">
                        <h4>Manage Sections</h4>
                        <span class="pull-right">
                            <button class="btn btn-primary" @click="edit_record=true">Add Section</button>
                        </span>
                    </div>
                    <div class="card-body">
                        <b-row class="mb-2">
                            <b-col md="3" offset-md="8">
                                <h6 class="box-title">Search</h6>
                                <b-form-input
                                    id="filter-input"
                                    v-model="filter"
                                    type="search"
                                    placeholder="Search..."
                                    @input="getRecords()"
                                ></b-form-input>
                            </b-col>
                            <b-col md="1" class="text-center">
                                <button class="btn btn-primary btn_refresh" v-b-tooltip.hover title="Refresh" @click="getRecords()">
                                    <i class="fa fa-refresh" aria-hidden="true"></i>
                                </button>
                            </b-col>
                        </b-row>
                        <b-table
                            :items="sections"
                            :fields="fields"
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
                                    <strong>Loading...</strong>
                                </div>
                            </template>

                            <template #cell(id)="row">
                                {{ row.item.id }}
                            </template>

                            <template #cell(name)="row">
                                {{ row.item.name }}
                            </template>

                            <template #cell(order)="row">
                                {{ row.item.order }}
                            </template>

                            <template #cell(actions)="row">
                                <button class="btn btn-sm btn-primary" @click="edit_record = row.item" v-b-tooltip.hover title="Edit">
                                    <i class="fa fa-pencil-alt"></i>
                                </button>
                                <button class="btn btn-sm btn-danger" @click="deleteRecord(row.index, row.item.id)" v-b-tooltip.hover title="Delete">
                                    <i class="fa fa-trash"></i>
                                </button>
                            </template>
                        </b-table>
                        <b-row>
                            <b-col md="2" class="my-1">
                                <b-form-group
                                    label="Per Page"
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
                                <label>Total Records: {{ totalRows }} </label>
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
            </div>
        </div>

        <!-- Add / Edit -->
        <app-edit-record
            v-if="edit_record"
            :record="edit_record"
            @modalClose="edit_record = null"
            @recordSaved="getRecords()"
        ></app-edit-record>
    </div>
</template>

<script>
import EditRecord from './EditSection.vue';

export default {
    components: {
        'app-edit-record': EditRecord,
    },
    data() {
        return {
            sections: [],
            fields: [
                { key: 'id', label: 'ID', sortable: true },
                { key: 'name', label: 'Name', sortable: true },
                { key: 'order', label: 'Order', sortable: true },
                { key: 'actions', label: 'Actions' }
            ],
            filter: '',
            filterOn: ['name'],
            sortBy: 'order',
            sortDesc: false,
            sortDirection: 'asc',
            currentPage: 1,
            perPage: 10,
            pageOptions: [10, 25, 50, 100],
            totalRows: 0,
            isLoading: false,
            edit_record: null
        }
    },
    mounted() {
        this.getRecords();
    },
    watch: {
        currentPage: function(val) {
            this.getRecords();
        },
        perPage: function(val) {
            this.getRecords();
        }
    },
    methods: {
        getRecords() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/products/customer-app-sections', {
                params: {
                    page: this.currentPage,
                    per_page: this.perPage,
                    filter: this.filter
                }
            }).then((response) => {
                this.sections = response.data.data;
                this.totalRows = response.data.total;
                this.isLoading = false;
            }).catch((error) => {
                console.error('Error fetching sections:', error);
                this.isLoading = false;
                this.showMessage('error', 'Failed to load sections');
            });
        },
        deleteRecord(index, id) {
            this.$swal.fire({
                title: 'Are you sure?',
                text: "You won't be able to revert this!",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
                confirmButtonText: 'Yes, delete it!'
            }).then((result) => {
                if (result.value) {
                    this.isLoading = true;
                    axios.post(this.$apiUrl + '/products/customer-app-sections/delete', { id: id })
                        .then((response) => {
                            if (response.data.status === 1) {
                                this.showMessage('success', response.data.message);
                                this.sections.splice(index, 1);
                                this.getRecords();
                            } else {
                                this.showMessage('error', response.data.message);
                            }
                            this.isLoading = false;
                        })
                        .catch((error) => {
                            console.error('Error deleting section:', error);
                            this.showMessage('error', 'Failed to delete section');
                            this.isLoading = false;
                        });
                }
            });
        }
    }
}
</script>

<style scoped>
.btn_refresh {
    margin-top: 25px;
}
.pull-right {
    float: right;
}
</style>