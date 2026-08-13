<template>
    <div>

        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Subcategory Groups</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                            <li class="breadcrumb-item active" aria-current="page">Subcategory Groups</li>
                        </ol>
                    </nav>
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
                            <h4>Subcategory Groups</h4>
                            <span class="pull-right">
                                <button class="btn btn-primary"  @click="openCreateModal()">Add New Group</button>
                            </span>
                        </div>

                        <div class="card-body">
                            <b-row class="mb-2">
                                <b-col md="3" offset-md="8">
                                    <h6 class="box-title">{{ __('search') }}</h6>
                                    <b-form-input
                                        id="filter-input"
                                        v-model="filter"
                                        type="search"
                                        :placeholder="__('search')"
                                    ></b-form-input>
                                </b-col>
                                <b-col md="1" class="text-center">
                                    <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getGroups()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i>
                                    </button>
                                </b-col>
                            </b-row>

                            <b-table
                                :items="groups"
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

                                <template #cell(actions)="row">
                                    <button class="btn btn-sm btn-primary" @click="openEditModal(row.item)" v-b-tooltip.hover :title="__('edit')">
                                        <i class="fa fa-pencil-alt"></i>
                                    </button>
                                    <button class="btn btn-sm btn-danger" @click="deleteGroup(row.index,row.item.id)" v-b-tooltip.hover :title="__('delete')">
                                        <i class="fa fa-trash"></i>
                                    </button>
                                </template>

                                <template #cell(subcategories)="row">
                                    <span v-if="row.item.subcategory_ids">
                                        {{ row.item.subcategory_ids.split(',').map(id => getSubcategoryName(id)).join(', ') }}
                                    </span>
                                </template>

                            </b-table>

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
                                    <label>{{__('total_records')}} :- {{ totalRows }} </label>
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
        </div>

        <!-- Add / Edit -->
        <subcategory-group-modal
            v-if="create_new || edit_record"
            :record="edit_record"
            @modalClose="hideModal()"
            @groupSaved="onGroupSaved"
        ></subcategory-group-modal>

    </div>
</template>

<script>
import SubcategoryGroupModal from './EditSubCategory.vue';

export default {
    components: {
        'subcategory-group-modal': SubcategoryGroupModal
    },
    data() {
        return {
            groups: [],
            subcategories: [],
            isLoading: false,
            edit_record: null,
            create_new: false,
            fields: [
                { key: 'id', label: __('id'), sortable: true },
                { key: 'name', label: __('name'), sortable: true },
                { key: 'subcategories', label: __('subcategories') },
                // { key: 'status', label: __('status') },
                { key: 'actions', label: __('actions') }
            ],
            totalRows: 1,
            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            sortBy: '',
            sortDesc: false,
            sortDirection: 'asc',
            filter: null,
            filterOn: ['name'],
        }
    },
    created() {
        this.getGroups();
        this.fetchAllSubcategories();
    },
    methods: {
        getGroups() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/group-sub-category?is_super_mart=1')
                .then(response => {
                    this.groups = response.data.data;
                    this.totalRows = this.groups.length;
                    this.isLoading = false;
                    console.log("Working :", this.groups);
                    
                }).catch(() => { this.isLoading = false; });
        },
        fetchAllSubcategories() {
            axios.get(this.$apiUrl + '/subcategories/all?is_super_mart=1')
                .then(res => {
                    this.subcategories = res.data.data;
                })
                .catch(() => {
                    this.subcategories = [];
                });
        },
        getSubcategoryName(id) {
            let sub = this.subcategories.find(s => s.id == id);
            return sub ? sub.name : id;
        },
        openCreateModal() {
            this.create_new = true;
            this.edit_record = null;
        },
        openEditModal(record) {
            this.edit_record = record;
            this.create_new = false;
        },
        hideModal() {
            this.create_new = false;
            this.edit_record = null;
        },
        onGroupSaved(message) {
            this.getGroups();
            this.hideModal();
            this.showMessage('success', message);
        },
        deleteGroup(index, id) {
            this.$swal.fire({
                title: "Are you Sure?",
                text: "You won't be able to revert this!",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: "Yes, delete it!",
                cancelButtonText: "Cancel",
                confirmButtonColor: '#3085d6',
                cancelButtonColor: '#d33'
            }).then(result => {
                if (result.isConfirmed) {
                    this.isLoading = true;
                    axios.post(this.$apiUrl + '/group-sub-category/delete', { id })
                        .then(res => {
                            if(res.data.status === 1){
                                this.groups.splice(index, 1);
                                this.showMessage('success', res.data.message);
                            } else {
                                this.showMessage('error', res.data.message);
                            }
                            this.isLoading = false;
                        }).catch(() => { this.isLoading = false; });
                }
            });
        },
        showMessage(type, message) {
            this.$swal.fire({
                icon: type,
                title: message,
                timer: 1500,
                showConfirmButton: false
            });
        } 
    }
};
</script>
