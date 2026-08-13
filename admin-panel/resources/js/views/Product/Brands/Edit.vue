<template>
    <b-modal ref="my-modal" :title="modal_title" @hidden="$emit('modalClose')" scrollable no-close-on-backdrop no-fade static size="lg">
        <div slot="modal-footer">
            <b-button variant="primary" @click="$refs['dummy_submit'].click()" :disabled="isLoading">{{ __('save') }}
                <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
            </b-button>
            <b-button variant="secondary" @click="hideModal">{{ __('cancel') }}</b-button>
        </div>
        <form ref="my-form" @submit.prevent="saveRecord">
            <div class="row">
                <div class="col-md-12">
                    <div class="form-group">
                        <label>{{ __('name') }}</label>
                        <input type="text" class="form-control" required v-model="name" :placeholder="__('enter_name')">
                    </div>
                </div>

                <!-- Store Selection -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label>{{ __('store') }}</label>
                        <select v-model="selectedStore" @change="onStoreChange" class="form-control form-select">
                            <option value="">{{ __('select_store') }}</option>
                            <option v-for="store in stores" :key="store.id" :value="store.id">
                                {{ store.name }}
                            </option>
                        </select>
                    </div>
                </div>

                <!-- Category Group Selection -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label>{{ __('category_group') }}</label>
                        <select v-model="selectedCategoryGroup" @change="onCategoryGroupChange" class="form-control form-select" :disabled="!selectedStore">
                            <option value="">{{ __('select_category_group') }}</option>
                            <option v-for="cg in categoryGroups" :key="cg.id" :value="cg.id">
                                {{ cg.name }}
                            </option>
                        </select>
                    </div>
                </div>

                <!-- Sub Category Group Selection -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label>{{ __('sub_category_group') }}</label>
                        <select v-model="selectedSubCategoryGroup" @change="onSubCategoryGroupChange" class="form-control form-select" :disabled="!selectedCategoryGroup">
                            <option value="">{{ __('select_sub_category_group') }}</option>
                            <option v-for="scg in subCategoryGroups" :key="scg.id" :value="scg.id">
                                {{ scg.name }}
                            </option>
                        </select>
                    </div>
                </div>

                <!-- Categories Multi-Select -->
                <div class="col-md-6">
                    <div class="form-group">
                        <label>{{ __('categories') }}</label>
                        <div class="dropdown w-100">
                            <button class="btn btn-outline-secondary dropdown-toggle w-100 text-left" type="button" id="categoryDropdown" data-bs-toggle="dropdown" aria-expanded="false" :disabled="!selectedSubCategoryGroup">
                                {{ selectedCategoriesText }}
                            </button>
                            <ul class="dropdown-menu w-100 p-3" aria-labelledby="categoryDropdown" style="max-height: 350px; overflow-y: auto;">
                                <li class="mb-3">
                                    <input
                                        type="text"
                                        class="form-control"
                                        v-model="categorySearch"
                                        placeholder="Search categories..."
                                        @click.stop
                                    >
                                </li>
                                <li v-if="filteredCategories.length === 0" class="text-muted text-center">
                                    No categories found
                                </li>
                                <li v-for="category in filteredCategories" :key="category.id" class="mb-2">
                                    <div class="form-check">
                                        <input
                                            class="form-check-input"
                                            type="checkbox"
                                            :value="category.id"
                                            :id="'category_' + category.id"
                                            v-model="selected_categories"
                                        >
                                        <label class="form-check-label" :for="'category_' + category.id">
                                            {{ category.name }}
                                        </label>
                                    </div>
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>

                <div class="col-md-12">
                    <div class="form-group">
                        <label for="image">{{ __('image') }}</label>
                        <p class="text-muted">Please choose square image of larger than 350px*350px &amp; smaller than 550px*550px.</p>
                        <span v-if="error" class="error">{{ error }}</span>
                        <input type="file" name="image" id="image" accept="image/*" v-on:change="handleFileUpload" ref="file_image" :required="!id" class="file-input">
                        <div class="file-input-div bg-gray-100" @click="$refs.file_image.click()" @drop="dropFile" @dragover="$dragoverFile" @dragleave="$dragleaveFile">
                            <template v-if="image && image.name !== ''">
                                <label>Selected file name:- {{ image.name }}</label>
                            </template>
                            <template v-else>
                                <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                                <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                            </template>
                        </div>
                        <div class="row" v-if="image_url">
                            <div class="col-md-4">
                                <img class="custom-image" :src="image_url" title='Store Logo' alt='Category Image'/>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-md-12" v-if="id">
                    <div class="form-group">
                        <label>{{ __('status') }}</label>
                        <div class="col-md-9 text-left mt-1">
                            <b-form-radio-group
                                v-model="status"
                                :options="[
                                    { text: ' Deactivated', 'value': 0 },
                                    { text: ' Activated', 'value': 1 },
                                ]"
                                buttons
                                button-variant="outline-primary"
                                required
                            ></b-form-radio-group>
                        </div>
                    </div>
                </div>
            </div>
            <button ref="dummy_submit" style="display:none;"></button>
        </form>
    </b-modal>
</template>

<script>
import axios from 'axios';

export default {
    props: ['record'],
    data: function () {
        return {
            isLoading: false,
            image: "" ,
            id: this.record ? this.record.id : null,
            name: this.record ? this.record.name : null,
            image_url: this.record ? this.record.image_url : "" ,
            status: this.record ? this.record.status : null,
            error: null,

            // Cascading dropdown data
            stores: [],
            categoryGroups: [],
            subCategoryGroups: [],
            categories: [],

            // Selected values
            selectedStore: "",
            selectedCategoryGroup: "",
            selectedSubCategoryGroup: "",
            selected_categories: [],
            categorySearch: '',
        };
    },
    computed: {
        modal_title: function () {
            let title = this.id ? __('edit_brand') : __('add_brand');
            return title;
        },
        selectedCategoriesText: function () {
            if (this.selected_categories.length === 0) {
                return 'Select Categories';
            } else if (this.selected_categories.length === 1) {
                const cat = this.categories.find(c => c.id === this.selected_categories[0]);
                return cat ? cat.name : 'Select Categories';
            } else {
                return `${this.selected_categories.length} categories selected`;
            }
        },
        filteredCategories: function () {
            if (!this.categorySearch) {
                return this.categories;
            }
            const search = this.categorySearch.toLowerCase();
            return this.categories.filter(category =>
                category.name.toLowerCase().includes(search)
            );
        },
    },
    created: function () {
        this.fetchStores();

        // If editing, load existing data
        if (this.record) {
            if (this.record.store_id) {
                this.selectedStore = this.record.store_id;
            }
            if (this.record.category_group_id) {
                this.selectedCategoryGroup = this.record.category_group_id;
            }
            if (this.record.sub_category_group_id) {
                this.selectedSubCategoryGroup = this.record.sub_category_group_id;
            }
            if (this.record.category_ids) {
                this.selected_categories = this.record.category_ids.split(',').map(id => parseInt(id));
            }

            // Load cascading data for edit mode
            this.loadEditModeData();
        }
    },
    methods: {
        fetchStores() {
            axios.get(this.$apiUrl + '/stores')
                .then(response => {
                    if (response.data && response.data.data) {
                        this.stores = response.data.data;
                    }
                })
                .catch(error => {
                    console.error('Error fetching stores:', error);
                });
        },

        loadEditModeData() {
            // Load cascading data for edit mode
            if (this.selectedStore) {
                axios.get(`${this.$apiUrl}/get-all-four-dropdowns`, {
                    params: { store_id: this.selectedStore }
                }).then((res) => {
                    const d = res.data.store_data;
                    this.categoryGroups = d.categories_data || [];

                    if (this.selectedCategoryGroup) {
                        this.loadSubCategoryGroupsForEdit();
                    }
                }).catch((err) => {
                    console.error("Failed to load category groups:", err);
                });
            }
        },

        loadSubCategoryGroupsForEdit() {
            axios.get(`${this.$apiUrl}/get-all-four-dropdowns`, {
                params: {
                    store_id: this.selectedStore,
                    category_group_id: this.selectedCategoryGroup
                }
            }).then((res) => {
                const d = res.data.store_data;
                this.subCategoryGroups = d.sub_category_groups_data || [];

                if (this.selectedSubCategoryGroup) {
                    this.loadCategoriesForEdit();
                }
            }).catch((err) => {
                console.error("Failed to load sub category groups:", err);
            });
        },

        loadCategoriesForEdit() {
            axios.get(`${this.$apiUrl}/get-all-four-dropdowns`, {
                params: {
                    store_id: this.selectedStore,
                    category_group_id: this.selectedCategoryGroup,
                    sub_category_group_id: this.selectedSubCategoryGroup
                }
            }).then((res) => {
                const d = res.data.store_data;
                this.categories = d.categories || [];
            }).catch((err) => {
                console.error("Failed to load categories:", err);
            });
        },

        onStoreChange() {
            // Reset dependent dropdowns
            this.categoryGroups = [];
            this.subCategoryGroups = [];
            this.categories = [];
            this.selectedCategoryGroup = "";
            this.selectedSubCategoryGroup = "";
            this.selected_categories = [];

            if (!this.selectedStore) {
                return;
            }

            // Load category groups for selected store
            axios.get(`${this.$apiUrl}/get-all-four-dropdowns`, {
                params: { store_id: this.selectedStore }
            }).then((res) => {
                const d = res.data.store_data;
                this.categoryGroups = d.categories_data || [];
            }).catch((err) => {
                console.error("Failed to load category groups:", err);
            });
        },

        onCategoryGroupChange() {
            // Reset dependent dropdowns
            this.subCategoryGroups = [];
            this.categories = [];
            this.selectedSubCategoryGroup = "";
            this.selected_categories = [];

            if (!this.selectedCategoryGroup) {
                return;
            }

            // Load sub category groups for selected category group
            axios.get(`${this.$apiUrl}/get-all-four-dropdowns`, {
                params: {
                    store_id: this.selectedStore,
                    category_group_id: this.selectedCategoryGroup
                }
            }).then((res) => {
                const d = res.data.store_data;
                this.subCategoryGroups = d.sub_category_groups_data || [];
            }).catch((err) => {
                console.error("Failed to load sub category groups:", err);
            });
        },

        onSubCategoryGroupChange() {
            // Reset categories
            this.categories = [];
            this.selected_categories = [];

            if (!this.selectedSubCategoryGroup) {
                return;
            }

            // Load categories for selected sub category group
            axios.get(`${this.$apiUrl}/get-all-four-dropdowns`, {
                params: {
                    store_id: this.selectedStore,
                    category_group_id: this.selectedCategoryGroup,
                    sub_category_group_id: this.selectedSubCategoryGroup
                }
            }).then((res) => {
                const d = res.data.store_data;
                this.categories = d.categories || [];
            }).catch((err) => {
                console.error("Failed to load categories:", err);
            });
        },

        showModal() {
            this.$refs['my-modal'].show()
        },
        hideModal() {
            this.$refs['my-modal'].hide()
        },
        dropFile(event) {
            event.preventDefault();
            this.$refs.file_image.files = event.dataTransfer.files;
            this.handleFileUpload(); // Trigger the onChange event manually
            // Clean up
            event.currentTarget.classList.add('bg-gray-100');
            event.currentTarget.classList.remove('bg-green-300');
        },
        handleFileUpload() {
            const file = this.$refs.file_image.files[0];

            // Reset previous error message
            this.error = null;

            // Check if a file was selected
            if (!file) return;

            // Perform image validation
            const validTypes = ["image/jpeg", "image/png", "image/jpg", "image/gif", "image/webp"];
            if (!validTypes.includes(file.type)) {
                this.error = "Invalid file type. Please upload a JPEG, PNG, JPG,  GIF or WEBP image.";
                return;
            }

            const maxSize = 2 * 1024 * 1024; // 2MB
            if (file.size > maxSize) {
                this.error = "File size exceeds the maximum allowed limit (2MB).";
                return;
            }

            // Create a URL for the uploaded image and display it
            this.imageUrl = URL.createObjectURL(file);
            this.image = this.$refs.file_image.files[0];
            this.image_url = URL.createObjectURL(this.image);
        },
        saveRecord: function () {
            let vm = this;
            this.isLoading = true;

            let formData = new FormData();
            if (this.id) {
                formData.append('id', this.id);
            }
            formData.append('name', this.name);
            formData.append('image', this.image);
            formData.append('status', this.status);

            // Add cascading dropdown values
            if (this.selectedStore) {
                formData.append('store_id', this.selectedStore);
            }
            if (this.selectedCategoryGroup) {
                formData.append('category_group_id', this.selectedCategoryGroup);
            }
            if (this.selectedSubCategoryGroup) {
                formData.append('sub_category_group_id', this.selectedSubCategoryGroup);
            }
            if (this.selected_categories.length > 0) {
                this.selected_categories.forEach(catId => {
                    formData.append('category_ids[]', catId);
                });
            }

            let url = this.$apiUrl + '/products/brands/save';
            if (this.id) {
                url = this.$apiUrl + '/products/brands/update';
            }

            axios.post(url, formData).then(res => {
                let data = res.data;
                if (data.status === 1) {
                    this.$eventBus.$emit('recordSaved', data.message);
                    this.hideModal();
                } else {
                    vm.showError(data.message);
                    vm.isLoading = false;
                }
            }).catch(error => {
                vm.isLoading = false;
                if (error.request.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError("Something went wrong!");
                }
            });
        }
    },
    mounted() {
        this.showModal();
    }
}
</script>

<style scoped>

.image_preview {
    margin-top: 5px;
}

.dropdown-menu {
    width: 100%;
}

.dropdown-menu li {
    list-style: none;
}

.form-check-label {
    cursor: pointer;
    user-select: none;
}
</style>
