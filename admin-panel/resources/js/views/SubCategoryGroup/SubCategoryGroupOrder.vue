<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Sub Category Group Order</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                            <li class="breadcrumb-item active" aria-current="page">Sub Category Group Order</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/manage_sub_category_group" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12 col-md-12 order-md-1 order-last">
                    <div class="card">
                        <div class="card-header">
                            <h4>Sub Category Group Order List</h4>
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
                            </div>

                            <b-row>
                                <b-col md="6">
                                    <div class="mb-2 d-flex justify-content-between align-items-center">
                                        <div class="form-check form-switch">
                                            <label> <input type="checkbox" v-model="editable" class="form-check-input">
                                                {{ __('enable_drag_and_drop') }}</label>
                                        </div>
                                    </div>
                                </b-col>
                            </b-row>
                            <b-row>
                                <b-col md="6" style="overflow-y:scroll;height:600px;">
                                    <div v-if="!category_group_id" class="alert alert-info">
                                        Please select Store and Category Group to view Sub Category Groups.
                                    </div>
                                    <ul v-else id="sortable-row" class="list-group">
                                        <draggable class="list-group" tag="ul" v-model="list" v-bind="dragOptions" :move="onMove" animation="200"
                                                   @start="isDragging=true" @end="isDragging=false" @change="updateSubCategoryGroupOrder()">
                                            <li v-for="(item, index) in list" :key="item.id" class="list-group-item d-flex justify-content-between align-items-center">
                                                <span>
                                                    <span class="text-left mr-2">{{ index + 1 }}</span>
                                                    <span class="text-left mr-2">-</span>
                                                    <span class="text-left mr-2">{{ item.id }}</span>
                                                    <span class="text-left mr-2"><img :src="item.image_url" height="30" v-if="item.image_url"></span>
                                                    <span class="text-left mr-2">{{ item.name }}</span>
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
                // Reset dependent dropdown
                this.category_group_id = "";
                this.list = [];
            } else {
                this.categoryGroupOptions = "<option value=''>--Select Category Group--</option>";
                this.category_group_id = "";
                this.list = [];
            }
        },
        category_group_id(newVal) {
            if (newVal) {
                this.getSubCategoryGroups();
            } else {
                this.list = [];
            }
        },
    },
    mounted() {

    },
    created: function() {
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

        onMove({ relatedContext, draggedContext }) {
            const relatedElement = relatedContext.element;
            const draggedElement = draggedContext.element;
            return (
                (!relatedElement || !relatedElement.fixed) && !draggedElement.fixed
            );
        },
        updateList(){
            this.list.map((item, index) => {
                item.row_order = index + 1;
            });
        },
        getSubCategoryGroups(){
            if (!this.category_group_id) {
                this.list = [];
                return;
            }

            this.isLoading = true;
            axios.get(this.$apiUrl + '/group-sub-category/row_order', {
                params: { category_group_id: this.category_group_id }
            })
                .then((response) => {
                    this.isLoading = false;
                    let data = response.data;
                    this.list = data.data.map((item, index) => {
                        return {
                            id: item.id,
                            name: item.name,
                            row_order: item.row_order || index + 1,
                            image_url: item.image_url,
                            fixed: false
                        };
                    })
                })
                .catch(error => {
                    this.isLoading = false;
                    console.error("Failed to load sub category groups", error);
                });
        },
        updateSubCategoryGroupOrder(){
            this.updateList();

            this.isLoading = true;
            let formData = {
                sub_category_groups: this.list,
                category_group_id: this.category_group_id
            };
            let url = this.$apiUrl + '/group-sub-category/updateOrder';
            axios.post(url, formData).then(res => {
                let data = res.data;
                if (data.status === 1) {
                    this.showMessage("success", data.message);
                    this.isLoading = false;
                    this.getSubCategoryGroups();
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
