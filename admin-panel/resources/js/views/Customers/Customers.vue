<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>{{ __('customers_list') }}</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">{{ __('customers_list') }}</li>
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

            <!-- Zone / City Filter -->
            <div class="mb-3">
                <select v-model="city_id" @change="getCustomers()" class="form-control form-select city-zone-select">
                    <option value="">All Zones</option>
                    <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
                    <option value="other">Other</option>
                </select>
            </div>

            <section class="section">
                <div class="card">
                    <div class="card-header">
                        <h4 class="card-title">{{ __('customers') }}</h4>
                    </div>
                    <div class="card-body">

                        <b-row class="mb-2">
                            <b-col md="3">
                                <div class="form-group">
                                    <h6 for="filterStatus">Filter by Account Status</h6>
                                    <select id="filterStatus" name="filterStatus" v-model="showDeleted" @change="getCustomers()" class="form-control form-select">
                                        <option value="">Active Customers</option>
                                        <option value="true">Deleted Customers</option>
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
                                    @click="addFilter()"
                                ></b-form-input>
                            </b-col>
                            <b-col md="1" class="text-center">
                                <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')"
                                        @click="getCustomers()">
                                    <i class="fa fa-refresh" aria-hidden="true"></i>
                                </button>
                            </b-col>
                        </b-row>
                        <div class="table-responsive">

                        <b-table
                            :items="customers"
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

                            <template #cell(sno)="row">
                                {{ (currentPage - 1) * perPage + row.index + 1 }}
                            </template>

                            <template #cell(name)="row">
                                {{ row.item.name || '-' }}
                            </template>

                            <template #cell(email)="row">
                                {{ row.item.email ? (row.item.email | emailMask) : '-' }}
                            </template>

                            <template #cell(mobile)="row">
                                {{ row.item.mobile ? row.item.mobile : '-' }}
                            </template>

                            <template #cell(orders_count)="row">
                                {{ row.item.orders_count || 0 }}
                            </template>

                            <template #cell(balance)="row">
                                {{ row.item.balance !== null && row.item.balance !== undefined ? row.item.balance : '-' }}
                            </template>

                            <template #cell(type)="row">
                                <img :src="$baseUrl + '/images/phone.svg'" height="40" alt="phone" v-if="row.item.type == 'phone'"/>
                                <img :src="$baseUrl + '/images/google.svg'" height="40" alt="google" v-else-if="row.item.type == 'google'"/>
                                <img :src="$baseUrl + '/images/apple.svg'" height="40" alt="apple" v-else-if="row.item.type == 'apple'"/>
                                <span v-else>-</span>
                            </template>

                            <template #cell(status)="row">
                                <span v-if="row.item.deleted_at" class="badge bg-danger">Deleted</span>
                                <span v-else-if="row.item.status == 1" class="badge bg-success">{{ __('active') }}</span>
                                <span v-else class="badge bg-danger">{{ __('deactive') }}</span>
                            </template>

                            <template #cell(created_at)="row">
                                {{ row.item.created_at ? new Date(row.item.created_at).toLocaleString() : '-' }}
                            </template>
                            <template #cell(actions)="row">
                                <router-link :to="'/users/view/' + row.item.id" class="btn btn-sm btn-primary me-1">
                                    <i class="fa fa-eye"></i>
                                </router-link>
                                <a class="btn btn-sm" @click="updateStatusCustomer(row.index,row.item.id)">
                                    <span class="primary-toggal" v-if="row.item.status == 1"><i class="fa fa-toggle-on fa-2x"></i></span>
                                    <span class="text-danger" v-else><i class="fa fa-toggle-off fa-2x"></i></span>
                                </a>
                            </template>

                        </b-table>
                        </div>
                        <b-row>
                            <b-col  md="2" class="my-1">
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
                                        @change = "addFilter"
                                        :options="pageOptions"
                                        size="sm"
                                        class="form-control form-select"
                                    ></b-form-select>
                                </b-form-group>
                                </label>
                            </b-col>
                            <b-col  md="4" class="my-1" offset-md="6">
                                <label>{{__('total_records')}}:- {{ totalRows }}</label>
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


    </div>
</template>
<script>

export default {
    data: function() {
        return {
            isLoading: false,
            fields: [
                { key: 'sno', label: __('sno'), sortable: false },
                { key: 'name', label: __('name'), sortable: true, class: 'text-center' },
                // { key: 'email', label: __('email'), sortable: true, class: 'text-center' },
                { key: 'mobile', label: __('mobile_no'), sortable: true, class: 'text-center' },
                { key: 'orders_count', label: __('orders'), sortable: true, class: 'text-center' },

                // { key: 'balance', label: __('balance'), sortable: true, class: 'text-center' },

                { key: 'status', label: __('status'), sortable: true, class: 'text-center' },
                // { key: 'type', label: __('type'), sortable: true, class: 'text-center' },
                // { key: 'created_at', label: 'Date & Time', sortable: true, class: 'text-center' },
                { key: 'actions', label: __('actions') }
            ],
            totalRows: 1,
            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,

            sortBy: 'orders_count',
            sortDesc: true,
            sortDirection: 'desc',
            filter: null,
            filterOn: [],
            customers: [],
            city_id: '',
            cities: [],
            showDeleted: '',
        }
    },
    computed: {
        sortOptions() {
            // Create an options list from our fields
            return this.fields
                .filter(f => f.sortable)
                .map(f => {
                    return { text: f.label, value: f.key }
                })
        }
    },
    mounted() {
        // Set the initial number of items
        this.totalRows = this.customers.length
    },
    created: function() {
        this.$eventBus.$on('customersSaved', (message) => {
            this.showMessage("success", message);
            this.getCustomers();
            this.create_new = null;
        });
        this.getCities();
        this.getCustomers();
    },
    methods: {
        getCities() {
            axios.get(this.$apiUrl + '/cities')
                .then((response) => {
                    this.cities = response.data.data || response.data;
                })
                .catch(() => {});
        },
        fixMobile(mobile) {
            let num = Number(mobile);
            if (num < 0) {
                num = num + 4294967296;
            }
            return String(num);
        },
        addFilter(){
            this.customers = [];
            this.totalRows = 1;
            this.currentPage = 1;
            this.offset = 0;
            this.getCustomers();
        },
        getCustomers(){
            let vm = this;
            this.isLoading = true;
            axios.get(this.$apiUrl + '/customers', {
                params: {
                    city_id: this.city_id,
                    show_deleted: this.showDeleted
                }
            })
                .then((response) => {
                    this.isLoading = false;
                    vm.isLoading = false;

                    this.customers = response.data.data;

                    this.totalRows = response.data.total;

                }).catch(error => {

                    vm.isLoading = false;
                    if (error.request?.statusText) {
                        this.showError(error.request?.statusText);
                    }else if (error.message) {
                        this.showError(error.message);
                    } else {
                        this.showError(__('something_went_wrong'));
                    }
            });

        },
        updateStatusCustomer(index, id){
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
                    this.isLoading = true
                    let postData = {
                        id : id
                    }
                    axios.post(this.$apiUrl + '/customers/change',postData)
                        .then((response) => {
                            this.isLoading = false
                            this.getCustomers();
                            this.showMessage("success", response.data.message);
                        });
                }
            });
        },

    }
};
</script>
<style scoped>
.city-zone-select {
    max-width: 220px;
}
</style>
