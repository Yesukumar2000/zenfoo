<template>
<b-modal ref="my-modal" :title="modal_title" @hidden="$emit('modalClose')" size="xl" scrollable no-close-on-backdrop no-fade static>
    <template #modal-header="{ close }">
        <h5>{{ modal_title }}</h5>
        <button type="button" aria-label="Close" class="close" @click="close()">×</button>
    </template>

    <form @submit.prevent="saveGroup">
        <div class="row">

            <!-- Category Group Dropdown -->
            <div class="form-group col-md-6">
                <label>Category Group</label><i class="text-danger">*</i>
                <select class="form-control" v-model="category_group_id" required>
                    <option value="">Select Category Group</option>
                    <option v-for="cat in categoryGroups" :key="cat.id" :value="cat.id">
                        {{ cat.name }}
                    </option>
                </select>
            </div>

            <div class="form-group col-md-6">
                <label>Group Name</label><i class="text-danger">*</i>
                <input type="text" class="form-control" v-model="name" placeholder="Enter group name">
            </div>

            <div class="form-group col-12 mt-3">
                <label>Is Children Allowed</label><br>

                <div class="custom-control custom-switch">
                    <input
                        type="checkbox"
                        class="custom-control-input"
                        id="childrenAllowedSwitch"
                        v-model="is_children_allowed"
                        :true-value="1"
                        :false-value="0"
                        @change="onChildrenAllowedChange"
                    >
                    <label class="custom-control-label" for="childrenAllowedSwitch">
                        {{ is_children_allowed == 1 ? 'Yes' : 'No' }}
                    </label>
                </div>
            </div>

            <div class="form-group col-12 mt-3">
                <label>Is Group</label><br>
                <div class="form-check form-check-inline">
                    <input class="form-check-input" type="radio" name="is_group" value="1" v-model="is_group">
                    <label class="form-check-label">Yes</label>
                </div>
                <div class="form-check form-check-inline">
                    <input class="form-check-input" type="radio" name="is_group" value="0" v-model="is_group">
                    <label class="form-check-label">No</label>
                </div>
            </div>


            <div class="form-group col-md-6">
                <label>Image</label>
                <input type="file" @change="onFileChange" class="form-control">
                <div v-if="preview_image_url || existing_image_url" class="mt-2">
                    <img :src="preview_image_url || existing_image_url" alt="Current Image" style="max-width: 150px; max-height: 100px; border-radius: 5px;">
                </div>
            </div>


            <!-- <div class="form-group col-12 mt-3">
                <label>Status</label><br>
                <div class="form-check form-check-inline">
                    <input class="form-check-input" type="radio" name="status" value="1" v-model="status">
                    <label class="form-check-label">Active</label>
                </div>
                <div class="form-check form-check-inline">
                    <input class="form-check-input" type="radio" name="status" value="0" v-model="status">
                    <label class="form-check-label">Inactive</label>
                </div>
            </div> -->

            <div class="form-group col-12 mt-3">
                <label>Select Subcategories</label>
                <div
                    v-for="sub in subcategories"
                    :key="sub.id"
                    class="form-check mb-1"
                >
                    <input type="checkbox" :value="sub.id" v-model="selectedSubcategories" class="me-2" />
                    <span class="flex-grow-1">{{ sub.name }}</span>
                </div>
            </div>

        </div>
        <button type="submit" ref="dummy_submit" style="display:none;"></button>
    </form>

    <template #modal-footer>
        <b-button variant="primary" @click="$refs['dummy_submit'].click()" :disabled="isLoading">
            Save
            <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
        </b-button>
        <b-button variant="secondary" @click="hideModal">Cancel</b-button>
    </template>
</b-modal>
</template>

<script>
export default {
    props: ['record'],
    data() {
        return {
            id: this.record ? this.record.id : null,
            name: this.record ? this.record.name : '',
            is_group: this.record ? this.record.is_group : 1,
            // status: this.record ? this.record.status : 1,
            subcategories: [],
            image: null,
            existing_image_url: this.record ? this.record.image_url : null,
            preview_image_url: null,
            is_children_allowed: this.record ? this.record.is_children_allowed : 1,
            selectedSubcategories: [],
            isLoading: false,
            categoryGroups: [],
            category_group_id: this.record ? this.record.category_group_id : '', // new field
        }
    },
    computed: {
        modal_title() {
            return this.id ? 'Edit Subcategory Group' : 'Add Subcategory Group';
        }
    },
    created() {
        this.fetchSubcategories();
        this.fetchCategoryGroups();
        if (this.record && this.record.subcategory_ids) {
            this.selectedSubcategories = this.record.subcategory_ids.split(',');
        }
    },
    methods: {
         onFileChange(event) {
            this.image = event.target.files[0];
            if (this.image) {
                this.preview_image_url = URL.createObjectURL(this.image);
            }
        },
        onChildrenAllowedChange() {
            console.log('Is Children Allowed changed to:', this.is_children_allowed);
        },
        fetchSubcategories() {
            axios.get(this.$apiUrl + '/subcategories/all')
                .then(res => {
                    this.subcategories = res.data.data;
                });
        },
        fetchCategoryGroups() {
            axios.get(this.$apiUrl + '/group-category')
                .then(res => {
                    this.categoryGroups = res.data.data;
                });
        },
        hideModal() {
            this.$refs['my-modal'].hide();
        },
        saveGroup() {
            this.isLoading = true;
            const formData = new FormData();
            if (this.id) formData.append('id', this.id);
            formData.append('name', this.name);
            formData.append('is_group', this.is_group);
            formData.append('is_children_allowed', this.is_children_allowed);
            // formData.append('status', this.status);
            formData.append('status', 1); // default status
            
            if(this.image) formData.append('image', this.image);
            formData.append('subcategory_ids', this.selectedSubcategories.join(','));
            formData.append('category_group_id', this.category_group_id); // added here

            let url = this.id ? this.$apiUrl + '/group-sub-category/update' : this.$apiUrl + '/group-sub-category/save';

            axios.post(url, formData)
                .then(res => {
                    if (res.data.status === 1) {
                        this.$emit('groupSaved', res.data.message);
                        this.hideModal();
                    } else {
                        alert(res.data.message);
                    }
                    this.isLoading = false;
                })
                .catch(() => {
                    this.isLoading = false;
                    alert("Something went wrong!");
                });
        }
    },
    mounted() {
        this.$refs['my-modal'].show();
    }
};
</script>
