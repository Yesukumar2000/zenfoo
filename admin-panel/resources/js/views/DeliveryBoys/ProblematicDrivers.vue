<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>Problematic Drivers</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">Problematic Drivers</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <section class="section">
                <div class="card">
                    <div class="card-header">
                        <h4 class="card-title">Drivers on hold</h4>
                        <small class="text-muted">
                            These drivers receive no new orders. Verify the issue, then move them back to the normal list.
                        </small>
                    </div>
                    <div class="card-body">

                        <b-row class="mb-2">
                            <b-col md="3" offset-md="8">
                                <h6 class="box-title">{{ __('search') }}</h6>
                                <b-form-input
                                    id="filter-input"
                                    v-model="filter"
                                    type="search"
                                    placeholder="Search"
                                ></b-form-input>
                            </b-col>
                            <b-col md="1" class="text-center">
                                <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getDrivers()">
                                    <i class="fa fa-refresh" aria-hidden="true"></i>
                                </button>
                            </b-col>
                        </b-row>

                        <div class="table-responsive">
                            <b-table
                                :items="drivers"
                                :fields="fields"
                                :current-page="currentPage"
                                :per-page="perPage"
                                :filter="filter"
                                :bordered="true"
                                :busy="isLoading"
                                stacked="md"
                                show-empty
                                empty-text="No drivers are on hold."
                                small
                                hover>

                                <template #table-busy>
                                    <div class="text-center text-black my-2">
                                        <b-spinner class="align-middle"></b-spinner>
                                        <strong>{{ __('loading') }}...</strong>
                                    </div>
                                </template>

                                <template #cell(name)="row">
                                    {{ row.item.name || '-' }}
                                </template>

                                <template #cell(mobile)="row">
                                    {{ row.item.mobile || '-' }}
                                </template>

                                <template #cell(problematic_order_id)="row">
                                    <router-link v-if="row.item.problematic_order_id"
                                                 :to="'/orders/view/' + row.item.problematic_order_id">
                                        #{{ row.item.problematic_order_id }}
                                    </router-link>
                                    <span v-else>-</span>
                                </template>

                                <template #cell(problematic_reason)="row">
                                    {{ row.item.problematic_reason || '-' }}
                                </template>

                                <template #cell(marked_by_name)="row">
                                    {{ row.item.marked_by_name || '-' }}
                                </template>

                                <template #cell(marked_problematic_at)="row">
                                    {{ formatDate(row.item.marked_problematic_at) }}
                                </template>

                                <template #cell(actions)="row">
                                    <button class="btn btn-sm btn-success"
                                            type="button"
                                            @click="moveToNormal(row.item)">
                                        <i class="fa fa-check me-1"></i> Move to Normal
                                    </button>
                                </template>

                            </b-table>
                        </div>

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
    </div>
</template>

<script>
export default {
    data: function () {
        return {
            fields: [
                { key: 'id', label: __('id'), sortable: true },
                { key: 'name', label: __('name'), sortable: true, class: 'text-center' },
                { key: 'mobile', label: __('mobile'), sortable: true, class: 'text-center' },
                { key: 'problematic_order_id', label: 'Order', class: 'text-center' },
                { key: 'problematic_reason', label: 'Reason' },
                { key: 'marked_by_name', label: 'Marked By', class: 'text-center' },
                { key: 'marked_problematic_at', label: 'Marked On', sortable: true, class: 'text-center' },
                { key: 'actions', label: __('actions'), class: 'text-center' },
            ],
            drivers: [],
            totalRows: 0,
            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            filter: null,
            isLoading: false,
        }
    },
    created: function () {
        this.getDrivers();
    },
    methods: {
        formatDate(value) {
            return value ? new Date(value).toLocaleString('en-GB') : '-';
        },
        getDrivers() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/delivery_boys/problematic')
                .then((response) => {
                    this.isLoading = false;
                    // A failed response still arrives as HTTP 200 with status 0 — surface it
                    // instead of rendering an empty table, which reads as "nothing on hold".
                    if (response.data.status !== 1) {
                        this.drivers = [];
                        this.totalRows = 0;
                        this.showError(response.data.message || "Failed to load problematic drivers.");
                        return;
                    }
                    this.drivers = response.data.data || [];
                    this.totalRows = this.drivers.length;
                })
                .catch(() => {
                    this.isLoading = false;
                    this.showError("Failed to load problematic drivers.");
                });
        },
        moveToNormal(driver) {
            let vm = this;
            this.$swal.fire({
                title: "Move back to normal?",
                html: `<b>${driver.name || 'This driver'}</b> will start receiving orders again once they go online.`,
                confirmButtonText: "Yes, Move",
                cancelButtonText: "Cancel",
                icon: 'question',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
            }).then(result => {
                if (result.value) {
                    axios.post(vm.$apiUrl + '/delivery_boys/unmark-problematic', { id: driver.id })
                        .then((response) => {
                            let data = response.data;
                            if (data.status === 1) {
                                vm.showMessage("success", data.message);
                                vm.getDrivers();
                            } else {
                                vm.showError(data.message);
                            }
                        })
                        .catch(() => {
                            vm.showError("Something went wrong!");
                        });
                }
            });
        },
    }
}
</script>
