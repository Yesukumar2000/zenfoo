<template>
    <div>
        <div class="page-heading">
            <div class="row">
            <div class="col-12 col-md-6 order-md-1 order-last">
                <h3>Manage Marts</h3>
            </div>
            <div class="col-12 col-md-6 order-md-2 order-first">
                <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                    <ol class="breadcrumb">
                        <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                        <li class="breadcrumb-item active" aria-current="page">Manage Marts</li>
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

        <!-- Zone / City Filter -->
        <div class="mb-3">
            <select v-model="city_id" @change="getRecords()" class="form-control form-select city-zone-select">
                <option value="">All Zones</option>
                <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
                <option value="other">Other</option>
            </select>
        </div>

            <div class="row">
                <div class="col-12 col-md-12 order-md-1 order-last">
                    <div class="card">
                        <div class="card-header">
                            <h4>Marts (Super Mart Sellers)</h4>
                        </div>
                        <div class="card-body">

                            <b-row>
                                <b-col md="3">
                                    <div class="form-group">
                                        <h6 for="filterStatus">Filter by Status</h6>
                                        <select id="filterStatus" name="filterStatus" v-model="filterStatus" @change="getRecords()" class="form-control form-select">
                                            <option value=""> {{ __('all') }}</option>
                                            <option value="1"> {{ __('approve') }}</option>
                                            <option value="3"> {{ __('deactivate') }}</option>
                                        </select>
                                    </div>
                                </b-col>
                                <b-col md="3" offset-md="5">
                                    <h6 class="box-title">{{ __('search') }}</h6>
                                    <b-form-input
                                        id="filter-input"
                                        v-model="filter"
                                        type="search"
                                        placeholder="Search"
                                    ></b-form-input>
                                </b-col>
                                <b-col md="1" class="text-center">
                                    <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getRecords()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i>
                                    </button>
                                </b-col>
                            </b-row>
                            <b-row class="table-responsive">
                            <b-table
                                :items="records"
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

                                <template #cell(name)="row">
                                    {{ row.item.name || '-' }}
                                </template>
                                <template #cell(store_name)="row">
                                    {{ row.item.store_name || '-' }}
                                </template>
                                <template #cell(email)="row">
                                    <span v-if="row.item.email">{{ row.item.email | emailMask }}</span>
                                    <span v-else>-</span>
                                </template>
                                <template #cell(mobile)="row">
                                    <span v-if="row.item.mobile">{{ row.item.mobile | mobileMask }}</span>
                                    <span v-else>-</span>
                                </template>
                                <template #cell(commission)="row">
                                    {{ row.item.commission || '-' }}
                                </template>

                                <template #cell(logo)="row">
                                    <span v-if="!row.item.logo">-</span>
                                    <img v-else :src="$mediaUrl(row.item.logo)" height="50" />
                                </template>

                                <template #cell(status)="row">
                                    <label v-if="row.item.status == 0" class='badge bg-primary'>{{ __('registered') }}</label>
                                    <label v-else-if="row.item.status == 1" class='badge bg-success'>{{ __('approved') }}</label>
                                    <label v-else-if="row.item.status == 2" class='badge bg-warning'>{{ __('not_approved') }}</label>
                                    <label v-else-if="row.item.status == 3" class='badge bg-danger'> {{ __('deactive') }}</label>
                                    <label v-else-if="row.item.status == 7" class='badge bg-danger'> {{ __('removed') }}</label>
                                </template>

                                <template #cell(availability)="row">
                                    <span v-if="$can('seller_update')" @click="updateStatusMart(row.index, row.item.id, row.item.status)" style="cursor: pointer;">
                                        <span v-if="row.item.status == 1" class="text-success">
                                            <i class="fa fa-toggle-on fa-2x"></i>
                                        </span>
                                        <span v-else class="text-danger">
                                            <i class="fa fa-toggle-off fa-2x"></i>
                                        </span>
                                    </span>
                                    <span v-else>-</span>
                                </template>

                                <template #cell(actions)="row">
                                    <router-link :to="{ name: 'SellerView', params: { id: row.item.id }}" class="btn btn-secondary btn-sm" v-b-tooltip.hover title="View Details">
                                        <i class="fa fa-eye"></i>
                                    </router-link>
                                    <!-- <router-link :to="{ name: 'SellerProductsList', query: { seller_id: row.item.id }}" class="btn btn-info btn-sm" v-b-tooltip.hover :title="__('products')">
                                        <i class="fa fa-box"></i>
                                    </router-link> -->
                                    <router-link :to="{ name: 'EditSeller', params: { id: row.item.id, record: row.item }}" v-b-tooltip.hover title="Edit" class="btn btn-primary btn-sm">
                                        <i class="fa fa-pencil-alt"></i>
                                    </router-link>
                                    <button class="btn btn-sm btn-danger" @click="deleteMart(row.index, row.item.id)" v-b-tooltip.hover :title="__('delete')">
                                        <i class="fa fa-trash"></i>
                                    </button>
                                </template>

                            </b-table>
                            </b-row>

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
                                    <label>{{ __('total_records') }} :- {{ totalRows }} </label>
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
    </div>
</template>
<script>
export default {
    data: function() {
        return {
            fields: [
                { key: 'id', label: __('id'), sortable: true, sortDirection: 'desc' },
                { key: 'name', label: __('name'), class: 'text-center', sortable: true, sortDirection: 'desc' },
                { key: 'store_name', label: __('store_name'), class: 'text-center', sortable: true, sortDirection: 'desc' },
                { key: 'email', label: __('email'), class: 'text-center', sortable: true, sortDirection: 'desc' },
                { key: 'mobile', label: __('mobile'), class: 'text-center', sortable: true, sortDirection: 'desc' },
                { key: 'commission', label: __('commission'), class: 'text-center', sortable: true, sortDirection: 'desc' },
                { key: 'availability', label: __('availability'), class: 'text-center', sortable: true, sortDirection: 'desc' },
                { key: 'actions', label: __('action') }
            ],
            totalRows: 1,
            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            sortBy: '',
            sortDesc: false,
            sortDirection: 'asc',
            filter: null,
            filterOn: [],
            page: 1,

            isLoading: false,
            records: [],
            filterStatus: "",
            city_id: '',
            cities: []
        }
    },
    created: function() {
        this.getCities();
        this.getRecords();
    },
    methods: {
        getCities() {
            axios.get(this.$apiUrl + '/cities')
                .then((response) => {
                    this.cities = response.data.data || response.data;
                })
                .catch(() => {});
        },
        getRecords() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/marts', {
                params: {
                    filterStatus: this.filterStatus,
                    city_id: this.city_id
                }
            }).then((response) => {
                this.isLoading = false;
                let data = response.data;
                this.records = data.data;
                this.totalRows = this.records.length;
            }).catch((error) => {
                this.isLoading = false;
                this.showError("Failed to load marts");
            });
        },
        updateStatusMart(index, id, status) {
            this.$swal.fire({
                title: "Are you Sure?",
                text: "You want to change status.",
                confirmButtonText: "Yes, Sure",
                cancelButtonText: "Cancel",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
            }).then(result => {
                if (result.value) {
                    this.isLoading = true;
                    let newStatus = status === 1 ? 3 : 1;
                    let postData = {
                        id: id,
                        status: newStatus
                    }
                    axios.post(this.$apiUrl + '/sellers/update_status', postData)
                        .then((response) => {
                            this.isLoading = false;
                            this.getRecords();
                            this.showMessage("success", response.data.message);
                        });
                }
            });
        },
        deleteMart(index, id) {
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
                    this.isLoading = true;
                    let postData = {
                        id: id
                    }
                    axios.post(this.$apiUrl + '/sellers/delete', postData)
                        .then((response) => {
                            this.isLoading = false;
                            let data = response.data;
                            this.records.splice(index, 1);
                            this.showMessage('success', data.message);
                        });
                }
            });
        }
    }
};
</script>

<style scoped>
.city-zone-select {
    max-width: 220px;
}
</style>