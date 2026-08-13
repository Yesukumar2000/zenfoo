<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>{{ __('delivery_boys') }}</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page"> {{ __('delivery_boys') }}</li>
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
                <select v-model="city_id" @change="getDeliveryBoys()" class="form-control form-select city-zone-select">
                    <option value="">All Zones</option>
                    <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
                    <option value="other">Other</option>
                </select>
            </div>

            <section class="section">
                <div class="card">
                    <div class="card-header">
                        <h4 class="card-title"> {{ __('delivery_boys') }}</h4>
                        <span class="pull-right">
                            <router-link to="/delivery_boys/create" class="btn btn-primary" v-b-tooltip.hover  title="Add New Seller" v-if="$can('delivery_boy_create')">Add Delivery boys{{ __('add_delivery_boys') }}</router-link>

                        </span>
                    </div>
                    <div class="card-body">

                        <b-row class="mb-2">
                            <b-col md="3">

                                <div class="form-group">
                                    <h6 for="filterStatus"> {{ __('filter_delivery_boy_by_status') }}</h6>
                                    <select id="filterStatus" name="filterStatus" v-model="filterStatus" @change="getDeliveryBoys()" class="form-control form-select">
                                        <option value="">{{ __('all') }}</option>
                                        <option value="0">{{ __('registered') }}</option>
                                        <option value="1">{{ __('approved') }}</option>
                                        <option value="2">{{ __('not_approved') }}</option>
                                        <option value="3">{{ __('deactivate') }}</option>
                                        <option value="7">{{ __('removed') }}</option>
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
                                <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getDeliveryBoys()">
                                    <i class="fa fa-refresh" aria-hidden="true"></i>
                                </button>
                            </b-col>
                        </b-row>
                        <div class="table-responsive">
                        <b-table
                            :items="deliveryBoys"
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
                            <template #head(balance)="row">
                                {{ __('balance') }}{{' ('+$currency+')' }}
                            </template>
                            <template #head(cash_received)="row">
                               {{ __('cash_received') }} {{'('+$currency+')' }}
                            </template>

                            <template #cell(name)="row">
                                {{ row.item.name || '-' }}
                            </template>

                            <template #cell(mobile)="row">
                                {{ row.item.mobile || '-' }}
                            </template>

                            <template #cell(address)="row">
                                {{ row.item.address || '-' }}
                            </template>

                            <template #cell(balance)="row">
                                {{ row.item.balance || '0' }}
                            </template>

                            <template #cell(cash_received)="row">
                                {{ row.item.cash_received || '0' }}
                            </template>

                            <template #cell(bonus_percentage)="row">
                                <small :id="'bonus'+row.item.id" class="d-inline-flex mb-3 px-2 py-1 text-muted bg-secondary bg-opacity-10 border border-secondary border-opacity-10 rounded-2">
                                    <i class="fa fa-info-circle"></i>
                                </small>
                                <b-popover :target="'bonus'+row.item.id" triggers="hover" placement="left">
                                    <template #title>
                                        {{ __('bonus_details') }}
                                    </template>
                                    <table class="table table-borderless">
                                        <tr>
                                            <th>{{ __('bonus_type') }}</th>
                                            <td class="text-end">{{ row.item.bonus_type === 1 ? "Commission" : (row.item.bonus_type === 0 ? "Fixed/Salaried" : "-") }}</td>
                                        </tr>
                                       <tr v-if="row.item.bonus_type === 1">
                                            <th>{{ __('commission') }}</th>
                                            <td class="text-end">{{ row.item.bonus_percentage || '-' }}</td>
                                        </tr>
                                        <tr>
                                            <th>{{ __('min_amount') }} ({{ $currency }})</th>
                                            <td class="text-end">{{ row.item.bonus_min_amount || '-' }}</td>
                                        </tr>
                                        <tr>
                                            <th>{{ __('max_amount') }} ({{ $currency }})</th>
                                            <td class="text-end">{{ row.item.bonus_max_amount || '-' }}</td>
                                        </tr>
                                    </table>
                                </b-popover>

                            </template>

                            <template #cell(status)="row">
                                <span
                                    @click="openStatusModal(row.item.id, row.item.status, row.index)"
                                    style="cursor: pointer;"
                                    v-b-tooltip.hover
                                    :title="__('click_to_change_status')"
                                    :class="{
                                        'badge bg-primary': row.item.status == 0,
                                        'badge bg-success': row.item.status == 1,
                                        'badge bg-warning text-dark': row.item.status == 2,
                                        'badge bg-danger': row.item.status == 3 || row.item.status == 7
                                    }">
                                    <span v-if="row.item.status == 0">{{ __('registered') }}</span>
                                    <span v-else-if="row.item.status == 1">{{ __('approved') }}</span>
                                    <span v-else-if="row.item.status == 2">{{ __('not_approved') }}</span>
                                    <span v-else-if="row.item.status == 3">{{ __('deactivate') }}</span>
                                    <span v-else-if="row.item.status == 7">{{ __('removed') }}</span>
                                </span>
                            </template>

                            <template #cell(is_available)="row">
                                <span v-if="row.item.status == 1" class="badge bg-success">{{ __('yes') }}</span>
                                <span v-else class="badge bg-danger">{{ __('no') }}</span>
                            </template>

                            <template #cell(actions)="row">
                                <router-link :to="{ name: 'ViewDeliveryBoy', params: { id: row.item.id }}" v-b-tooltip.hover :title="__('view')" class="btn btn-info btn-sm me-1">
                                    <i class="fa fa-eye"></i>
                                </router-link>
                                <router-link :to="{ name: 'EditDeliveryBoy',params: { id: row.item.id, record : row.item }}" class="btn btn-primary btn-sm" v-b-tooltip.hover :title="__('edit')">
                                    <i class="fa fa-pencil-alt"></i>
                                </router-link>

                                <button class="btn btn-sm btn-danger" @click="deleteDeliveryBoys(row.index,row.item.id)" v-b-tooltip.hover :title="__('delete')"><i class="fa fa-trash"></i></button>

                                <button v-if="!row.item.is_problematic"
                                        class="btn btn-sm btn-warning ms-1"
                                        @click="holdDriver(row.item)"
                                        v-b-tooltip.hover title="Hold - stop new orders">
                                    <i class="fa fa-pause"></i>
                                </button>
                                <button v-else
                                        class="btn btn-sm btn-success ms-1"
                                        @click="releaseDriver(row.item)"
                                        v-b-tooltip.hover title="On hold - click to release">
                                    <i class="fa fa-play"></i>
                                </button>
                            </template>

                        </b-table>
                        </div>
                        <b-row>
                            <b-col  md="2" class="my-1">
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
                            <b-col  md="4" class="my-1" offset-md="6">
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
        <!-- Add / Edit -->
        <app-edit-record
            v-if="create_new || edit_record"
            :record="edit_record"
            @modalClose="hideModal()"
        ></app-edit-record>

        <!-- Status Change Modal -->
        <b-modal v-model="showStatusModal" title="Change Status" hide-footer centered>
            <div class="form-group">
                <label for="newStatus">Select New Status</label>
                <select id="newStatus" v-model="selectedNewStatus" class="form-control form-select">
                    <option value="" disabled>Select Status</option>
                    <option value="0">{{ __('registered') }}</option>
                    <option value="1">{{ __('approved') }}</option>
                    <option value="2">{{ __('not_approved') }}</option>
                    <option value="3">{{ __('deactivate') }}</option>
                    <option value="7">{{ __('removed') }}</option>
                </select>
            </div>
            <div class="form-group mt-3" v-if="selectedNewStatus == 3 || selectedNewStatus == 7">
                <label for="statusRemarks">Remarks <span class="text-danger">*</span></label>
                <textarea id="statusRemarks" v-model="statusRemarks" class="form-control" rows="3" placeholder="Type your remarks here..."></textarea>
            </div>
            <div class="mt-3 text-end">
                <button class="btn btn-secondary me-2" @click="closeStatusModal">Cancel</button>
                <button class="btn btn-primary" @click="submitStatusChange" :disabled="isUpdatingStatus">
                    <span v-if="isUpdatingStatus">Updating...</span>
                    <span v-else>Update Status</span>
                </button>
            </div>
        </b-modal>
    </div>
</template>
<script>
import EditRecord from './Edit';
export default {
    components: {
        'app-edit-record' : EditRecord,
    },
    data: function() {
        return {
            fields: [
                { key: 'id', label:  __('id') , sortable: true, sortDirection: 'desc' },
                { key: 'name', label:  __('name') , sortable: true, class: 'text-center' },
                { key: 'mobile', label: __('mobile'), sortable: true, class: 'text-center' },
                // { key: 'address', label: __('address'), sortable: true,  class: 'text-center' },
                // { key: 'bonus_percentage', label: __('bonus'), sortable: true, class: 'text-center' },
                // { key: 'balance', label: __('balance'), sortable: true,  class: 'text-center' },
                // { key: 'cash_received', label: __('cash_received'), sortable: true,  class: 'text-center' },
                // { key: 'other_payment_information', sortable: true, label: __('other_payment_information'),  class: 'text-center' },
                { key: 'status', label: __('status'), sortable: true, class: 'text-center' },
                // { key: 'is_available', label: __('available'),  class: 'text-center' },
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
            filterOn: [],
            page: 1,

            isLoading: false,
            sectionStyle : 'style_1',
            max_visible_units : 12,
            max_col_in_single_row : 3,
            create_new : null,
            edit_record : null,

            categories: null,
            products: null,

            deliveryBoys: [],

            filterStatus : "",
            city_id: '',
            cities: [],

            // Status modal
            showStatusModal: false,
            selectedNewStatus: "",
            statusRemarks: "",
            currentDeliveryBoyId: null,
            currentDeliveryBoyIndex: null,
            currentOldStatus: null,
            isUpdatingStatus: false
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
        this.totalRows = this.deliveryBoys.length
    },

    created: function() {
        this.$eventBus.$on('deliveryBoysSaved', (message) => {
            this.showMessage("success", message);
            this.getDeliveryBoys();
            this.create_new = null;
        });
        this.getCities();
        this.getDeliveryBoys();
    },
    methods: {
        holdDriver(driver) {
            let vm = this;
            this.$swal.fire({
                title: "Hold this driver?",
                html:
                    `<div style="text-align:left">
                        <p style="font-size:14px"><b>${driver.name || 'This driver'}</b> will receive no new orders and will be set offline, until an admin releases him.</p>
                        <label style="font-size:14px;font-weight:600">Reason (required)</label>
                        <textarea id="hold-reason" class="swal2-textarea" style="width:100%" placeholder="Phone dead / not reachable / not delivering"></textarea>
                    </div>`,
                confirmButtonText: "Yes, Hold Driver",
                cancelButtonText: "Cancel",
                icon: 'warning',
                showCancelButton: true,
                focusConfirm: false,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
                preConfirm: () => {
                    const reason = document.getElementById('hold-reason').value;
                    if (!reason) {
                        vm.$swal.showValidationMessage('Please type a reason');
                        return false;
                    }
                    return reason;
                },
            }).then(result => {
                if (result.value) {
                    axios.post(vm.$apiUrl + '/delivery_boys/mark-problematic', {
                        id: driver.id,
                        reason: result.value,
                    }).then((response) => {
                        let data = response.data;
                        if (data.status === 1) {
                            vm.showMessage("success", data.message);
                            vm.getDeliveryBoys();
                        } else {
                            vm.showError(data.message);
                        }
                    }).catch(() => {
                        vm.showError("Could not hold the driver.");
                    });
                }
            });
        },

        releaseDriver(driver) {
            let vm = this;
            this.$swal.fire({
                title: "Release this driver?",
                html: `<b>${driver.name || 'This driver'}</b> will start receiving orders again.`,
                confirmButtonText: "Yes, Release",
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
                                vm.getDeliveryBoys();
                            } else {
                                vm.showError(data.message);
                            }
                        }).catch(() => {
                            vm.showError("Could not release the driver.");
                        });
                }
            });
        },

        getCities() {
            axios.get(this.$apiUrl + '/cities')
                .then((response) => {
                    this.cities = response.data.data || response.data;
                })
                .catch(() => {});
        },
        getDeliveryBoys(){
            this.isLoading = true

            axios.get(this.$apiUrl + '/delivery_boys',{
                params: {
                    filterStatus: this.filterStatus,
                    city_id: this.city_id
                }
            })
                .then((response) => {
                    this.isLoading = false
                    this.deliveryBoys = response.data.data;
                    this.totalRows = this.deliveryBoys.length
                });
        },
        openStatusModal(id, currentStatus, index) {
            this.currentDeliveryBoyId = id;
            this.currentOldStatus = currentStatus;
            this.currentDeliveryBoyIndex = index;
            this.selectedNewStatus = "";
            this.statusRemarks = "";
            this.showStatusModal = true;
        },
        closeStatusModal() {
            this.showStatusModal = false;
            this.selectedNewStatus = "";
            this.statusRemarks = "";
            this.currentDeliveryBoyId = null;
            this.currentOldStatus = null;
            this.currentDeliveryBoyIndex = null;
        },
        async submitStatusChange() {
            // Validate status selection
            if (!this.selectedNewStatus) {
                this.showError("Please select a status");
                return;
            }

            // Validate remarks for Deactivate and Removed statuses
            if ((this.selectedNewStatus == 3 || this.selectedNewStatus == 7) && !this.statusRemarks.trim()) {
                this.showError("Remarks are required for this status");
                return;
            }

            // Confirm status change
            const confirmResult = await this.$swal.fire({
                title: "Are you Sure?",
                text: "You want to change the status of this delivery boy",
                confirmButtonText: "Yes, Change",
                cancelButtonText: "Cancel",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
            });

            if (!confirmResult.value) {
                return;
            }

            this.isUpdatingStatus = true;
            let postData = {
                id: this.currentDeliveryBoyId,
                status: this.selectedNewStatus,
                remark: this.statusRemarks
            };

            axios.post(this.$apiUrl + '/delivery_boys/update-status', postData)
                .then((response) => {
                    this.isUpdatingStatus = false;
                    let data = response.data;
                    this.showMessage('success', data.message);
                    this.closeStatusModal();
                    this.getDeliveryBoys();
                })
                .catch(error => {
                    this.isUpdatingStatus = false;
                    this.showError("Failed to update status");
                });
        },
        async changeStatus(id, newStatus, index) {
            // Store the old status for rollback if needed
            const oldStatus = this.deliveryBoys[index].status;

            let remarks = "";

            // If changing to "Deactivate" (3) or "Removed" (7), ask for remarks
            if (newStatus == 3 || newStatus == 7) {
                const { value: text } = await this.$swal.fire({
                    title: 'Remarks',
                    input: 'textarea',
                    inputPlaceholder: 'Type your remarks here...',
                    inputAttributes: {
                        'aria-label': 'Type your remarks here'
                    },
                    confirmButtonText: "Submit",
                    cancelButtonText: "Cancel",
                    showCancelButton: true,
                    inputValidator: (value) => {
                        return new Promise((resolve) => {
                            if (value !== '') {
                                resolve();
                            } else {
                                resolve('The Remarks field is required');
                            }
                        });
                    }
                });

                if (!text) {
                    // User cancelled, revert the status
                    this.deliveryBoys[index].status = oldStatus;
                    return;
                }
                remarks = text;
            }

            // Confirm status change
            const confirmResult = await this.$swal.fire({
                title: "Are you Sure?",
                text: "You want to change the status of this delivery boy",
                confirmButtonText: "Yes, Change",
                cancelButtonText: "Cancel",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
            });

            if (!confirmResult.value) {
                // User cancelled, revert the status
                this.deliveryBoys[index].status = oldStatus;
                return;
            }

            this.isLoading = true;
            let postData = {
                id: id,
                status: newStatus,
                remark: remarks
            };

            axios.post(this.$apiUrl + '/delivery_boys/update-status', postData)
                .then((response) => {
                    this.isLoading = false;
                    let data = response.data;
                    this.showMessage('success', data.message);
                    this.getDeliveryBoys();
                })
                .catch(error => {
                    this.isLoading = false;
                    // Revert status on error
                    this.deliveryBoys[index].status = oldStatus;
                    this.showError("Failed to update status");
                });
        },

        deleteDeliveryBoys(index, id){
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
                        id : id
                    }
                    axios.post(this.$apiUrl + '/delivery_boys/delete',postData)
                        .then((response) => {
                            this.isLoading = false
                            this.deliveryBoys.splice(index, 1)
                            this.showMessage('success', response.data.message);
                        });
                }
            });
        },

        hideModal() {
            this.create_new = false
            this.edit_record = false
            this.$router.push({path: '/delivery_boys'});
        },
    }
};
</script>

<style scoped>
.city-zone-select {
    max-width: 220px;
}
</style>
