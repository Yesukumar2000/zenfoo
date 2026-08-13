<template>

    <div>

        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>{{ __('manage_citys_center_points_latitude_longitude') }}</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">{{ __('manage_cities') }}</li>
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
                            <h4>{{ __('manage_cities') }}</h4>
                            <span class="pull-right">
                                <router-link to="/cities/create" class="btn btn-primary" v-if="$can('city_create')">{{ __('add_new_city') }}</router-link>
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
                                    <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getRecords()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i>
                                    </button>
                                </b-col>
                            </b-row>
                            <div class="table-responsive">



                                <b-table
                                    id="my-table"
                                    ref="table"

                                    head-variant="unset"

                                    :items="cities"
                                    :fields="fields"

                                    :filter="filter"
                                    :filter-included-fields="filterOn"
                                    :sort-by.sync="sortBy"
                                    :sort-desc.sync="sortDesc"
                                    :sort-direction="sortDirection"
                                    @sort-changed="getRecords"
                                    :bordered="true"
                                    :busy="isLoading"

                                    stacked="md"
                                    show-empty
                                    small
                                    empty-text="There are no cities to show"
                                    :key="tableKey"
                                >
                                    <template #table-busy>
                                        <div class="text-center text-black my-2">
                                            <b-spinner class="align-middle"></b-spinner>
                                            <strong>{{ __('loading') }}...</strong>
                                        </div>
                                    </template>
                                    <template #cell(actions)="row">
                                        <div style="width: 120px">
                                            <!-- v-if="$can('city_update')" removed temporarily -->
                                            <router-link
                                                :to="{ name: 'EditCity',params: { id: row.item.id, record : row.item }}"
                                                v-b-tooltip.hover :title="__('edit')" class="btn btn-sm btn-primary">
                                                <i class="fa fa-pencil-alt"></i>
                                            </router-link>
                                            <button class="btn btn-sm btn-danger" v-b-tooltip.hover :title="__('delete')"
                                                    @click="deleteRecord(row.index,row.item.id)"
                                                    v-if="$can('city_delete')">
                                                <i class="fa fa-trash"></i>
                                            </button>
                                        </div>
                                    </template>
                                </b-table>
                            </div>
                            <b-row>
                                <b-col md="2" class="my-1">
                                    <label>
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
                                    </label>
                                </b-col>

                                <b-col md="4" class="my-1" offset-md="6">
                                    <label>{{__('total_records')}}:- {{ totalRows }}</label>,

                                    <b-pagination
                                        v-model="currentPage"
                                        :total-rows="totalRows"
                                        :per-page="perPage"
                                        align="fill"
                                        size="sm"
                                        class="my-0"
                                        @change="getRecords"
                                    ></b-pagination>

                                </b-col>
                            </b-row>
                        </div>
                    </div>
                </div>
            </div>
        </div>

    </div>

</template>
<script>
import {VuejsDatatableFactory} from 'vuejs-datatable';
import axios from "axios";
import moment from "moment";

export default {
    components: {
        VuejsDatatableFactory,
    },
    data: function () {
        return {
            isLoading: false,

            fields: [
                {key: 'id', label: __('id'), sortable: true, sortDirection: 'desc'},
                {key: 'name', label: __('name'), sortable: true, sortDirection: 'desc'},
                {key: 'zone', label: __('zone'), sortable: true, sortDirection: 'desc'},
                {key: 'state', label: __('state'), sortable: true, sortDirection: 'desc'},
                {key: 'latitude', label: __('latitude'), sortable: true, sortDirection: 'desc'},
                {key: 'longitude', label: __('longitude'), sortable: true, sortDirection: 'desc'},
                {key: 'geolocation_type', label: __('geolocation_type'), sortable: true, sortDirection: 'desc'},
                {key: 'actions', label: __('actions')}
            ],

            totalRows: 1,

            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            offset: 0,

            sortBy: 'id',
            sortDesc: true,
            sortDirection: 'desc',

            filter: null,
            filterOn: [],

            cities: [],
            tableKey: 0, // For forcing table re-render

        }
    },
    mounted() {
       

    },
    created: function () {
        this.getRecords();
    },
    watch: {
        currentPage(newPage) {
            this.getRecords();
        },
        perPage(newPerPage) {
            this.getRecords();
        },
        filter(newFilter, oldFilter) {
            this.currentPage = 1;
            this.getRecords();
        }
    },
    methods: {


        getRecords() {
            this.isLoading = true
            let vm = this;

            // Calculate proper offset for CityApiController
            const calculatedOffset = this.perPage * (this.currentPage - 1);

            const params = {
                offset: calculatedOffset,
                limit: this.perPage,
                search: this.filter,
                sort_by: this.sortBy,
                sort_dir: this.sortDirection
            };

            axios.get(this.$apiUrl + '/cities', { params })
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    
                    // Handle the nested response structure from CityApiController
                    this.cities = data.data.cities || [];
                    this.totalRows = data.data.total || 0;
                    
                    // Force table re-render
                    this.tableKey++;

                }).catch(error => {
                vm.isLoading = false;
                
                if (error?.request?.statusText) {
                    this.showError(error?.request?.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError(__('something_went_wrong'));
                }
            });
        },

        deleteRecord(index, id) {
            this.$swal.fire({
                title: "Are you Sure?",
                text: "You want be able to revert this",
                confirmButtonText: "Yes, Sure",
                cancelButtonText: "Cancel",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
            }).then(result => {
                if (result.value) {
                    this.isLoading = true
                    let postData = {
                        id: id
                    }
                    axios.post(this.$apiUrl + '/cities/delete', postData)
                        .then((response) => {
                            this.isLoading = false
                            let data = response.data;
                            this.cities.splice(index, 1)
                            this.showMessage('success', data.message);
                        });
                }
            });
        },
    }
};
</script>
