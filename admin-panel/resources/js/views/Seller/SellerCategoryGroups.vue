<template>
    <div>
        <b-row class="mb-2">
            <b-col md="3">
                <button class="btn btn-success" @click="openCreateModal()">
                    <i class="fa fa-plus me-1"></i> Add Category Group
                </button>
            </b-col>
            <b-col md="3" offset-md="5">
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

            <template #cell(image)="row">
                <img :src="row.item.image_url || row.item.image" height="50" v-if="row.item.image_url || row.item.image" />
                <span v-else>-</span>
            </template>

            <template #cell(status)="row">
                <span class="badge bg-success" v-if="row.item.status == 1 || row.item.status === 'active'">Active</span>
                <span class="badge bg-danger" v-else>Inactive</span>
            </template>

            <template #cell(actions)="row">
                <button class="btn btn-sm btn-primary" @click="openEditModal(row.item)" v-b-tooltip.hover :title="__('edit')">
                    <i class="fa fa-pencil-alt"></i>
                </button>
                <button class="btn btn-sm btn-danger" @click="deleteRecord(row.index, row.item.id)" v-b-tooltip.hover :title="__('delete')">
                    <i class="fa fa-trash"></i>
                </button>
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
                <label>{{ __('total_records') }} :- {{ totalRows }}</label>
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

        <!-- Create/Edit Modal -->
        <b-modal
            v-model="showEditModal"
            :title="isEditMode ? 'Edit Category Group' : 'Add Category Group'"
            hide-footer
            centered
            size="lg"
            scrollable>
            <form @submit.prevent="saveRecord">
                <div class="form-group mb-3">
                    <label>{{ __('name') }} <i class="text-danger">*</i></label>
                    <input type="text" class="form-control" v-model="editForm.name" required>
                </div>
                <div class="form-group mb-3">
                    <label>{{ __('image') }}</label>
                    <input type="file" accept="image/*" @change="handleFileUpload" class="form-control">
                    <div class="mt-2" v-if="editForm.image_url">
                        <img :src="editForm.image_url" class="img-thumbnail" style="max-width: 150px;" />
                    </div>
                </div>
                <div class="form-group mb-3" v-if="!isEditMode">
                    <label>Select Sub Category Groups <i class="text-danger">*</i></label>
                    <div class="border rounded p-3" :class="{ 'border-danger': showGroupError }" style="max-height: 300px; overflow-y: auto;">
                        <div v-for="sg in sellerSubCategoryGroups" :key="sg.id" class="form-check mb-2">
                            <input
                                type="checkbox"
                                :id="'sg_' + sg.id"
                                :value="sg.id"
                                v-model="editForm.group_ids"
                                class="form-check-input"
                                @change="showGroupError = false"
                            >
                            <label :for="'sg_' + sg.id" class="form-check-label">{{ sg.name }}</label>
                        </div>
                        <div v-if="sellerSubCategoryGroups.length === 0" class="text-muted">
                            No sub category groups found for this seller
                        </div>
                    </div>
                    <small v-if="showGroupError" class="text-danger">Please select at least one sub category group</small>
                </div>
                <div class="form-group mb-3" v-if="isEditMode">
                    <label>{{ __('status') }}</label>
                    <b-form-radio-group
                        v-model="editForm.status"
                        :options="[
                            { text: 'Inactive', value: 0 },
                            { text: 'Active', value: 1 }
                        ]"
                        buttons
                        button-variant="outline-primary"
                    ></b-form-radio-group>
                </div>
                <div class="d-flex justify-content-end">
                    <button type="button" class="btn btn-secondary me-2" @click="showEditModal = false">{{ __('cancel') }}</button>
                    <button type="submit" class="btn btn-primary" :disabled="isSaving">
                        {{ __('save') }}
                        <b-spinner v-if="isSaving" small></b-spinner>
                    </button>
                </div>
            </form>
        </b-modal>
    </div>
</template>

<script>
export default {
    name: 'SellerCategoryGroups',
    props: {
        sellerId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            isLoading: false,
            isSaving: false,
            groups: [],
            sellerSubCategoryGroups: [],
            showEditModal: false,
            isEditMode: false,
            showGroupError: false,
            editForm: {
                id: null,
                name: '',
                image: null,
                image_url: null,
                status: 1,
                group_ids: []
            },
            fields: [
                { key: 'id', label: __('id'), sortable: true, sortDirection: 'desc', class: 'text-center' },
                { key: 'name', label: __('name'), sortable: true, class: 'text-center' },
                { key: 'image', label: __('image'), class: 'text-center' },
                { key: 'status', label: __('status'), class: 'text-center' },
                { key: 'actions', label: __('actions'), class: 'text-center' }
            ],
            totalRows: 0,
            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            sortBy: '',
            sortDesc: false,
            sortDirection: 'asc',
            filter: null,
            filterOn: ['name']
        }
    },
    created() {
        this.getRecords();
    },
    methods: {
        getRecords() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/group-category', {
                params: { seller_id: this.sellerId }
            })
            .then(response => {
                this.groups = response.data.data || [];
                this.totalRows = this.groups.length;
                this.isLoading = false;
            })
            .catch(() => {
                this.isLoading = false;
            });
        },
        fetchSellerSubCategoryGroups() {
            axios.get(this.$apiUrl + '/group-sub-category', {
                params: { seller_id: this.sellerId }
            })
            .then(res => {
                this.sellerSubCategoryGroups = res.data.data || [];
            })
            .catch(() => {
                this.sellerSubCategoryGroups = [];
            });
        },
        openCreateModal() {
            this.isEditMode = false;
            this.showGroupError = false;
            this.editForm = {
                id: null,
                name: '',
                image: null,
                image_url: null,
                status: 1,
                group_ids: []
            };
            this.fetchSellerSubCategoryGroups();
            this.showEditModal = true;
        },
        openEditModal(record) {
            this.isEditMode = true;
            this.showGroupError = false;
            this.editForm = {
                id: record.id,
                name: record.name,
                image: null,
                image_url: record.image_url || record.image,
                status: record.status == 1 || record.status === 'active' ? 1 : 0,
                group_ids: []
            };
            this.showEditModal = true;
        },
        handleFileUpload(event) {
            const file = event.target.files[0];
            if (file) {
                this.editForm.image = file;
                this.editForm.image_url = URL.createObjectURL(file);
            }
        },
        saveRecord() {
            if (!this.isEditMode && this.editForm.group_ids.length === 0) {
                this.showGroupError = true;
                return;
            }

            this.isSaving = true;

            if (this.isEditMode) {
                let formData = new FormData();
                formData.append('name', this.editForm.name);
                formData.append('status', this.editForm.status);
                formData.append('seller_id', this.sellerId);
                if (this.editForm.image) {
                    formData.append('image', this.editForm.image);
                }
                axios.post(this.$apiUrl + '/group-category/update/' + this.editForm.id, formData, {
                    headers: { 'Content-Type': 'multipart/form-data' }
                })
                .then(res => {
                    if (res.data.status === 1) {
                        this.showMessage('success', res.data.message);
                        this.showEditModal = false;
                        this.getRecords();
                    } else {
                        this.showMessage('error', res.data.message);
                    }
                    this.isSaving = false;
                })
                .catch((error) => {
                    this.isSaving = false;
                    this.handleError(error);
                });
            } else {
                let formData = new FormData();
                formData.append('name', this.editForm.name);
                formData.append('seller_id', this.sellerId);
                if (this.editForm.image) {
                    formData.append('image', this.editForm.image);
                }
                this.editForm.group_ids.forEach(id => {
                    formData.append('group_ids[]', id);
                });
                axios.post(this.$apiUrl + '/sellers/view/store-category-group', formData, {
                    headers: { 'Content-Type': 'multipart/form-data' }
                })
                .then(res => {
                    if (res.data.status === 1) {
                        this.showMessage('success', res.data.message);
                        this.showEditModal = false;
                        this.getRecords();
                    } else {
                        this.showMessage('error', res.data.message);
                    }
                    this.isSaving = false;
                })
                .catch((error) => {
                    this.isSaving = false;
                    this.handleError(error);
                });
            }
        },
        deleteRecord(index, id) {
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
                    axios.post(this.$apiUrl + '/group-category/delete', { id })
                    .then(res => {
                        if (res.data.status === 1) {
                            this.groups.splice(index, 1);
                            this.totalRows = this.groups.length;
                            this.showMessage('success', res.data.message);
                        } else {
                            this.showMessage('error', res.data.message);
                        }
                        this.isLoading = false;
                    })
                    .catch(() => {
                        this.isLoading = false;
                    });
                }
            });
        },
        handleError(error) {
            if (error.response && error.response.data && error.response.data.errors) {
                const errors = error.response.data.errors;
                const firstError = Object.values(errors)[0][0];
                this.showMessage('error', firstError);
            } else if (error.response && error.response.data && error.response.data.message) {
                this.showMessage('error', error.response.data.message);
            } else {
                this.showMessage('error', 'Something went wrong');
            }
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
