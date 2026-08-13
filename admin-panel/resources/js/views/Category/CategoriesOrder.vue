<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>{{ __('categories_order') }}</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                            <li class="breadcrumb-item active" aria-current="page">{{ __('categories_order') }}</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/manage_categories" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12 col-md-12 order-md-1 order-last">
                    <div class="card">
                        <div class="card-header">
                            <h4>{{ __('main_categories_order_list') }}</h4>
                        </div>
                        <div class="card-body">
                            <!-- Filter Dropdowns -->
                            <div class="row mb-4">
                                <div class="col-md-4">
                                    <div class="form-group">
                                        <label>{{ __('store') }} <i class="text-danger">*</i></label>
                                        <select class="form-control form-select" v-model="store_id" v-html="storeOptions">
                                        </select>
                                    </div>
                                </div>

                                <div class="col-md-4">
                                    <div class="form-group">
                                        <label>Category Group <i class="text-danger">*</i></label>
                                        <select class="form-control form-select" v-model="category_group_id" v-html="categoryGroupOptions">
                                        </select>
                                    </div>
                                </div>

                                <div class="col-md-4">
                                    <div class="form-group">
                                        <label>Sub Category Group <i class="text-danger">*</i></label>
                                        <select class="form-control form-select" v-model="sub_category_group_id" v-html="subCategoryGroupOptions">
                                        </select>
                                    </div>
                                </div>
                            </div>

                            <b-row>
                                <b-col md="6">
                                    <div class="mb-2 d-flex justify-content-between align-items-center">
                                        <div class="form-check form-switch">
                                            <label> <input type="checkbox" v-model="editable" class="form-check-input">
                                                {{ __('enable_drag_and_drop') }}</label>
                                        </div>
                                        <!-- <button type="button" class="btn btn-sm btn-primary" @click="orderList">{{ __('sort_by_original_order') }}</button> -->
                                    </div>
                                </b-col>
                            </b-row>
                            <b-row>
                                <b-col md="6" style="overflow-y:scroll;height:600px;">
                                    <div v-if="!sub_category_group_id" class="alert alert-info">
                                        Please select Store, Category Group, and Sub Category Group to view categories.
                                    </div>
                                    <ul v-else id="sortable-row" class="list-group">
                                        <draggable class="list-group" tag="ul" v-model="list" v-bind="dragOptions" :move="onMove" animation="200"
                                                   @start="isDragging=true" @end="isDragging=false" @change="updateCategoriesOrder()">
                                            <li v-for="category in list" :key="category.row_order" class="list-group-item d-flex justify-content-between align-items-center">
                                                <span>
                                                    <span class="text-left mr-2">{{ category.row_order }}</span>
                                                    <span class="text-left mr-2">-</span>
                                                    <span class="text-left mr-2">{{ category.id }}</span>
                                                    <span class="text-left mr-2"><img :src="category.image_url" height="30"></span>
                                                    <span class="text-left mr-2">{{ category.name }}</span>
                                                    <span v-if="category.all_parents" class="ml-4 all_parents">
                                                        <span class="ml-4" v-for="(parent, index) in getParentsList(category.all_parents)" :key="index">
                                                            <span>
                                                                <span class="fas fa-angle-left mr-2"></span>
                                                                <span class="text-left"><img :src="parent.image_url" height="20" :title="parent.id + '-' + parent.name"></span>
                                                            </span>
                                                        </span>
                                                    </span>
                                                </span>
                                                <span><i class="fas fa-arrows-alt"></i></span>
                                            </li>
                                        </draggable>
                                    </ul>
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
import draggable from 'vuedraggable';
import axios from "axios";
export default {
    components: {
        draggable,
    },
    data: function() {
        return {
            categories: [],
            list: [],
            editable: true,
            isDragging: false,
            onDragEnd: false,
            delayedDragging: false,
            isLoading: false,

            // Filter dropdowns
            stores: [],
            store_id: "",
            storeOptions: "<option value=''>--Select Store--</option>",

            category_group_id: "",
            categoryGroupOptions: "<option value=''>--Select Category Group--</option>",

            sub_category_group_id: "",
            subCategoryGroupOptions: "<option value=''>--Select Sub Category Group--</option>",
        }
    },
    computed: {
        dragOptions() {
            return {
                animation: 0,
                group: "description",
                disabled: !this.editable,
                ghostClass: "ghost"
            };
        },
    },
    watch: {
        isDragging(newValue) {
            if (newValue) {
                this.delayedDragging = true;
                return;
            }
            this.$nextTick(() => {
                this.delayedDragging = false;
            });
        },
        store_id(newVal) {
            if (newVal) {
                this.getCategoryGroups(newVal);
                // Reset dependent dropdowns
                this.category_group_id = "";
                this.sub_category_group_id = "";
                this.list = [];
            } else {
                this.categoryGroupOptions = "<option value=''>--Select Category Group--</option>";
                this.category_group_id = "";
                this.sub_category_group_id = "";
                this.list = [];
            }
        },
        category_group_id(newVal) {
            if (newVal) {
                this.getSubCategoryGroups(newVal);
                // Reset dependent dropdown
                this.sub_category_group_id = "";
                this.list = [];
            } else {
                this.subCategoryGroupOptions = "<option value=''>--Select Sub Category Group--</option>";
                this.sub_category_group_id = "";
                this.list = [];
            }
        },
        sub_category_group_id(newVal) {
            if (newVal) {
                this.getCategories();
            } else {
                this.list = [];
            }
        },
    },
    mounted() {

    },
    created: function() {
        this.$eventBus.$on('categorySaved', (message) => {
            //this.showSuccess(message);
            this.showMessage("success", message);
            this.getCategories();
        });
        this.getStores();
    },
    methods: {
        getStores() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/get-all-stores-data')
                .then((response) => {
                    this.isLoading = false;
                    this.stores = response.data;

                    this.storeOptions = `<option value="">--Select Store--</option>`;
                    this.stores.forEach(store => {
                        // Exclude store with id 17
                        if (store.id != 17) {
                            this.storeOptions += `<option value="${store.id}">${store.name}</option>`;
                        }
                    });
                })
                .catch((error) => {
                    this.isLoading = false;
                    console.error("Store fetch error", error);
                });
        },

        getCategoryGroups(storeId) {
            this.isLoading = true;

            axios.get(this.$apiUrl + '/get-data-based-on-store-selection', {
                params: { store_id: storeId }
            })
            .then((response) => {
                this.isLoading = false;

                let data = response.data.data;

                this.categoryGroupOptions = `<option value="">--Select Category Group--</option>`;

                data.forEach(group => {
                    this.categoryGroupOptions += `<option value="${group.id}">${group.name}</option>`;
                });
            })
            .catch(error => {
                this.isLoading = false;
                console.error("Failed to load category groups", error);
            });
        },

        getSubCategoryGroups(groupId) {
            this.isLoading = true;

            axios.get(this.$apiUrl + '/get-data-based-on-category-selection', {
                params: { category_group_id: groupId }
            })
            .then((response) => {
                this.isLoading = false;

                let data = response.data.data;

                this.subCategoryGroupOptions = `<option value="">--Select Sub Category Group--</option>`;

                data.forEach(group => {
                    this.subCategoryGroupOptions += `<option value="${group.id}">${group.name}</option>`;
                });
            })
            .catch(error => {
                this.isLoading = false;
                console.error("Failed to load sub category groups", error);
            });
        },

        onDragEnd(newValue) {
            if (newValue) {
                this.delayedDragging = true;
                return;
            }
            this.$nextTick(() => {
                this.delayedDragging = false;
            });
        },
        getParentsList(parent) {
            let parents = [];
            while (parent) {
                parents.push(parent);
                parent = parent.all_parents;
            }
            return parents;
        },
        orderList() {
            this.getCategories();
        },
        onMove({ relatedContext, draggedContext }) {
            const relatedElement = relatedContext.element;
            const draggedElement = draggedContext.element;
            return (
                (!relatedElement || !relatedElement.fixed) && !draggedElement.fixed
            );
        },
        updateList(){
            this.list.map((category, index) => {
                    category.row_order = index + 1;
            });
        },
        getCategories(){
            if (!this.sub_category_group_id) {
                this.list = [];
                return;
            }

            this.isLoading = true;
            axios.get(this.$apiUrl + '/categories/row_order', {
                params: { sub_category_group_id: this.sub_category_group_id }
            })
                .then((response) => {
                    this.isLoading = false;
                    let data = response.data;
                    this.list = data.data.map((category, index) => {
                        return {
                            id: category.id,
                            name: category.name,
                            row_order: category.row_order,
                            image_url: category.image_url,
                            all_parents: category.all_parents,
                            fixed: false
                        };
                    })
                })
                .catch(error => {
                    this.isLoading = false;
                    console.error("Failed to load categories", error);
                });
        },
        updateCategoriesOrder(){
            this.updateList();

            this.isLoading = true;
            let formData = {
                categories: this.list,
                sub_category_group_id: this.sub_category_group_id
            };
            let url = this.$apiUrl + '/categories/updateOrder';
            axios.post(url, formData).then(res => {
                let data = res.data;
                if (data.status === 1) {

                    this.showMessage("success", data.message);
                    this.isLoading = false;
                    this.getCategories();
                }else{
                    this.showError(data.message);
                    this.isLoading = false;
                }
            }).catch(error => {
                this.isLoading = false;
                if (error.request.statusText) {
                    this.showError(error.request.statusText);
                }else if (error.message) {
                    this.showError(error.message);
                } else {
                    this.showError(__('something_went_wrong'));
                }
            });

        },
    }
};
</script>
<style scoped>
.flip-list-move {
    transition: transform 0.5s;
}

.no-move {
    transition: transform 0s;
}

.ghost {
    opacity: 0.5;
    background: #c8ebfb;
}

.list-group {
    min-height: 20px;
}

.list-group-item {
    cursor: move;
}

.list-group-item i {
    cursor: pointer;
}
</style>
