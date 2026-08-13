<template>
    <div>
        <b-row class="mb-2">
            <b-col md="3">
                <button class="btn btn-success" @click="openCreateModal()">
                    <i class="fa fa-plus me-1"></i> Add Category
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
            :items="categories"
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
                    <strong>{{ __('loading') }}...</strong>
                </div>
            </template>

            <template #cell(image)="row">
                <img :src="row.item.image_url" height="50" v-if="row.item.image_url" />
                <span v-else>-</span>
            </template>

            <template #cell(status)="row">
                <span class="badge bg-success" v-if="row.item.status == 1">Activated</span>
                <span class="badge bg-danger" v-if="row.item.status == 0">Deactivated</span>
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
                    @change="getRecords"
                ></b-pagination>
            </b-col>
        </b-row>

        <!-- Edit Modal -->
        <b-modal
            v-model="showEditModal"
            :title="isEditMode ? 'Edit Category' : 'Add Category'"
            hide-footer
            centered
            size="lg">
            <form @submit.prevent="saveRecord">
                <div class="row">
                    <div class="form-group col-md-6 mb-3">
                        <label>{{ __('category_name') }} <i class="text-danger">*</i></label>
                        <input type="text" class="form-control" required v-model="editForm.name" :placeholder="__('enter_category_name')">
                    </div>
                    <div class="form-group col-md-6 mb-3">
                        <label>{{ __('category_subtitle') }} <i class="text-danger">*</i></label>
                        <input type="text" class="form-control" required v-model="editForm.subtitle" :placeholder="__('enter_category_subtitle')">
                    </div>
                    <div class="form-group col-md-12 mb-3">
                        <label>{{ __('image') }}</label>
                        <p class="text-muted small">Please choose square image of larger than 350px*350px & smaller than 550px*550px.</p>
                        <input type="file" name="category_image" accept="image/*" @change="handleFileUpload" ref="file_image" class="form-control">
                        <div class="row mt-3" v-if="editForm.image_url">
                            <div class="col-md-4">
                                <img class="img-thumbnail" :src="editForm.image_url" style="max-width: 150px;" />
                            </div>
                        </div>
                    </div>
                    <div class="form-group col-md-6 mb-3">
                        <label>{{ __('status') }}</label>
                        <div class="mt-1">
                            <b-form-radio-group
                                v-model="editForm.status"
                                :options="[
                                    { text: 'Deactivated', value: 0 },
                                    { text: 'Activated', value: 1 }
                                ]"
                                buttons
                                button-variant="outline-primary"
                            ></b-form-radio-group>
                        </div>
                    </div>

                    <!-- Add New Types -->
                    <div class="form-group col-md-12 mb-3">
                        <label>Types</label>
                        <div class="d-flex">
                            <input type="text"
                                v-model="tempType"
                                class="form-control"
                                placeholder="Enter type name and click Add" />
                            <button type="button"
                                    class="btn btn-primary ml-2"
                                    @click="addType">
                                Add
                            </button>
                        </div>
                        <!-- Show added types -->
                        <div class="mt-2">
                            <span v-for="(t, index) in types" :key="index" class="badge text-primary badge-info mr-1">
                                {{ t }}
                                <i class="fa fa-times ml-1 text-danger" @click="removeType(index)" style="cursor:pointer"></i>
                            </span>
                        </div>
                    </div>

                    <!-- Existing Types -->
                    <div class="form-group col-md-12 mb-3" v-if="fetchedTypes && fetchedTypes.length">
                        <label>Existing Types</label>
                        <ul class="list-group">
                            <li class="list-group-item"
                                v-for="type in fetchedTypes"
                                :key="type.id">
                                <div class="d-flex justify-content-between align-items-center">
                                    <!-- Edit Mode -->
                                    <div v-if="editingTypeId === type.id" class="flex-grow-1 mr-2">
                                        <input type="text"
                                            v-model="editingTypeName"
                                            class="form-control"
                                            placeholder="Enter new name" />
                                    </div>
                                    <!-- Normal Mode -->
                                    <div v-else class="flex-grow-1">
                                        {{ type.name }}
                                    </div>
                                    <!-- Buttons -->
                                    <div>
                                        <button type="button"
                                                v-if="editingTypeId === type.id"
                                                class="btn btn-success btn-sm mr-2"
                                                @click="updateType(type.id)">
                                            <i class="fa fa-check"></i>
                                        </button>
                                        <button type="button"
                                                v-if="editingTypeId !== type.id"
                                                class="btn btn-primary btn-sm mr-2"
                                                @click="startEditType(type)">
                                            <i class="fa fa-edit"></i>
                                        </button>
                                        <button type="button"
                                                v-if="editingTypeId === type.id"
                                                class="btn btn-secondary btn-sm mr-2"
                                                @click="cancelEditType">
                                            <i class="fa fa-times"></i>
                                        </button>
                                        <button type="button"
                                                class="btn btn-danger btn-sm"
                                                @click="deleteType(type.id)">
                                            <i class="fa fa-trash"></i>
                                        </button>
                                    </div>
                                </div>
                            </li>
                        </ul>
                    </div>
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
    name: 'SellerCategories',
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
            categories: [],
            showEditModal: false,
            isEditMode: false,
            editForm: {
                id: null,
                name: '',
                subtitle: '',
                image: null,
                image_url: null,
                status: 1
            },
            // Types data
            types: [],
            tempType: '',
            fetchedTypes: [],
            editingTypeId: null,
            editingTypeName: '',
            fields: [
                { key: 'id', label: __('id'), class: 'text-center', sortable: true, sortDirection: 'asc' },
                { key: 'name', label: __('name'), class: 'text-center', sortable: true },
                { key: 'subtitle', label: __('subtitle'), class: 'text-center', sortable: true },
                { key: 'image', label: __('image'), class: 'text-center' },
                { key: 'status', label: __('status'), class: 'text-center' },
                { key: 'actions', label: __('actions'), class: 'text-center' }
            ],
            totalRows: 0,
            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            sortBy: 'id',
            sortDesc: true,
            sortDirection: 'asc',
            filter: null,
            filterOn: ['name', 'subtitle']
        }
    },
    watch: {
        currentPage() {
            this.getRecords();
        },
        perPage() {
            this.getRecords();
        },
        filter() {
            this.currentPage = 1;
            this.getRecords();
        }
    },
    created() {
        this.getRecords();
    },
    methods: {
        getRecords() {
            this.isLoading = true;
            const params = {
                offset: this.currentPage,
                limit: this.perPage,
                filter: this.filter,
                seller_id: this.sellerId
            };
            axios.get(this.$apiUrl + '/categories', { params })
            .then(response => {
                this.isLoading = false;
                let data = response.data;
                this.categories = data.data || [];
                this.totalRows = data.total || this.categories.length;
            })
            .catch(() => {
                this.isLoading = false;
            });
        },
        openCreateModal() {
            this.isEditMode = false;
            this.editForm = {
                id: null,
                name: '',
                subtitle: '',
                image: null,
                image_url: null,
                status: 1
            };
            this.types = [];
            this.tempType = '';
            this.fetchedTypes = [];
            this.editingTypeId = null;
            this.editingTypeName = '';
            this.showEditModal = true;
        },
        openEditModal(record) {
            this.isEditMode = true;
            this.editForm = {
                id: record.id,
                name: record.name,
                subtitle: record.subtitle,
                image: null,
                image_url: record.image_url,
                status: record.status
            };
            // Reset types data
            this.types = [];
            this.tempType = '';
            this.fetchedTypes = [];
            this.editingTypeId = null;
            this.editingTypeName = '';
            // Fetch existing types for this category
            this.getCategoryTypes(record.id);
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
            this.isSaving = true;
            let formData = new FormData();
            formData.append('name', this.editForm.name);
            formData.append('subtitle', this.editForm.subtitle);
            if (this.editForm.image) {
                formData.append('image', this.editForm.image);
            }
            formData.append('status', this.editForm.status);
            formData.append('seller_id', this.sellerId);

            // Append new types
            this.types.forEach(t => {
                formData.append('types[]', t);
            });

            let url = this.$apiUrl + '/categories/store-seller-category';
            if (this.isEditMode) {
                formData.append('id', this.editForm.id);
                url = this.$apiUrl + '/categories/update';
            }

            axios.post(url, formData, {
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
                if (error.response && error.response.data && error.response.data.errors) {
                    const errors = error.response.data.errors;
                    const firstError = Object.values(errors)[0][0];
                    this.showMessage('error', firstError);
                } else if (error.response && error.response.data && error.response.data.message) {
                    this.showMessage('error', error.response.data.message);
                } else {
                    this.showMessage('error', 'Something went wrong');
                }
            });
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
                    axios.post(this.$apiUrl + '/categories/delete', { id })
                    .then(res => {
                        this.isLoading = false;
                        if (res.data.status === 1) {
                            this.categories.splice(index, 1);
                            this.totalRows = this.categories.length;
                            this.showMessage('success', res.data.message);
                        } else {
                            this.showMessage('error', res.data.message);
                        }
                    })
                    .catch(() => {
                        this.isLoading = false;
                    });
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
        },

        // Types methods
        getCategoryTypes(categoryId) {
            axios.get(this.$apiUrl + '/category-types', {
                params: { category_id: categoryId }
            })
            .then(res => {
                if (res.data.success === true) {
                    this.fetchedTypes = res.data.data.data || [];
                }
            })
            .catch(err => {
                console.error("Error fetching category types", err);
            });
        },

        addType() {
            if (this.tempType.trim() !== "") {
                this.types.push(this.tempType.trim());
                this.tempType = "";
            }
        },

        removeType(index) {
            this.types.splice(index, 1);
        },

        startEditType(type) {
            this.editingTypeId = type.id;
            this.editingTypeName = type.name;
        },

        cancelEditType() {
            this.editingTypeId = null;
            this.editingTypeName = "";
        },

        updateType(id) {
            if (!this.editingTypeName.trim()) {
                this.showMessage('error', "Type name cannot be empty");
                return;
            }

            axios.put(this.$apiUrl + '/category-types/' + id, {
                name: this.editingTypeName,
                category_id: this.editForm.id
            })
            .then(res => {
                if (res.data.status === 1) {
                    this.getCategoryTypes(this.editForm.id);
                    this.cancelEditType();
                    this.showMessage('success', 'Type updated successfully');
                } else {
                    this.showMessage('error', res.data.message);
                }
            })
            .catch(err => {
                this.showMessage('error', "Update failed");
                console.error(err);
            });
        },

        deleteType(id) {
            this.$swal.fire({
                title: "Are you sure?",
                text: "You want to delete this type?",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: "Yes, delete it!",
                cancelButtonText: "Cancel",
                confirmButtonColor: '#d33',
                cancelButtonColor: '#3085d6'
            }).then(result => {
                if (result.isConfirmed) {
                    axios.delete(this.$apiUrl + '/category-types/' + id)
                    .then(res => {
                        if (res.data.status === 1) {
                            this.getCategoryTypes(this.editForm.id);
                            this.showMessage('success', 'Type deleted successfully');
                        } else {
                            this.showMessage('error', res.data.message);
                        }
                    })
                    .catch(err => {
                        this.showMessage('error', "Delete failed");
                        console.error(err);
                    });
                }
            });
        }
    }
};
</script>
