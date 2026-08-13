<template>
    <b-modal ref="my-modal" :title="modal_title" @hidden="$emit('modalClose')" scrollable no-close-on-backdrop no-fade static>
        <div slot="modal-footer">
            <b-button variant="primary" @click="$refs['dummy_submit'].click()" :disabled="isLoading">{{ __('save') }}
                <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
            </b-button>
            <b-button variant="secondary" @click="hideModal">{{ __('cancel') }}</b-button>
        </div>
        <form ref="my-form" @submit.prevent="saveRecord">



            <div class="row"> 
                <div class="form-group">
                    <label>{{ __('type') }}</label>
                    <select class="form-control form-select" v-model="type">
                        <!-- <option value="default"> {{ __('default') }}</option> -->
                        <option value="category"> {{ __('category') }}</option>
                        <option value="product"> {{ __('product') }}</option>
                        <option value="store"> {{ __('store') }}</option>
                        <option value="seller"> {{ __('seller') }}</option>
                        <option value="driver"> {{ __('driver') }}</option>
                        <option value="driver_login">Driver Login</option>
                        <option value="order_page">orders page</option>
                        <!-- <option value="promotional">promotional</option> -->
                        <!-- <option value="slider_url"> {{ __('slider_url') }}</option> -->
                    </select>
                </div>
                <!-- Store dropdown for category / product types -->
                <template v-if="type === 'category' || type === 'product'">

                    <div class="form-group">
                        <label>{{ __('store') }} <span class="text-danger">*</span></label>
                        <select class="form-control form-select" v-model="slider_store_id" @change="onSliderStoreChange">
                            <option value="">--Select Store--</option>
                            <option v-for="store in slider_stores" :key="store.id" :value="store.id">{{ store.name }}</option>
                        </select>
                    </div>

                    <div class="form-group" v-if="slider_store_id">
                        <label>Sub Category Group</label>
                        <select class="form-control form-select" v-model="category_group_id" @change="onCategoryGroupChange" :disabled="loadingCategoryGroups">
                            <option value="">{{ loadingCategoryGroups ? 'Loading...' : '--Select Sub Category Group--' }}</option>
                            <option v-for="group in categoryGroups" :key="group.id" :value="group.id">{{ group.name }}</option>
                        </select>
                    </div>

                    <div class="form-group" v-if="category_group_id">
                        <label>Category Group</label>
                        <select class="form-control form-select" v-model="sub_category_group_id" @change="onSubCategoryGroupChange" :disabled="loadingSubCategoryGroups">
                            <option value="">{{ loadingSubCategoryGroups ? 'Loading...' : '--Select Category Group--' }}</option>
                            <option v-for="subGroup in subCategoryGroups" :key="subGroup.id" :value="subGroup.id">{{ subGroup.name }}</option>
                        </select>
                    </div>

                    <div class="form-group" v-if="sub_category_group_id">
                        <label>{{ __('category') }}</label>
                        <select class="form-control form-select" v-model="slider_category_id" @change="onSliderCategoryChange" :disabled="loadingCategories" :required="type === 'category'">
                            <option value="">{{ loadingCategories ? 'Loading...' : '--Select Category--' }}</option>
                            <option v-for="cat in sliderCategories" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
                        </select>
                    </div>

                    <!-- Products (only for product type) -->
                    <div class="form-group" v-if="type === 'product' && slider_category_id">
                        <label>{{ __('products') }}</label>
                        <select class="form-control form-select" v-model="type_id" :disabled="loadingProducts" required>
                            <option value="">{{ loadingProducts ? 'Loading...' : '--Select Product--' }}</option>
                            <option v-for="product in sliderProducts" :key="product.id" :value="product.id">{{ product.name }}</option>
                        </select>
                    </div>

                </template>

                <div class="form-group" v-if="type === 'store'">
                    <label>Store <span class="text-danger">*</span></label>
                    <select class="form-control form-select" v-model="type_id" required>
                        <option value="">Select Store</option>
                        <option v-for="store in stores" :key="store.id" :value="store.id">
                        {{ store.name }}
                        </option>
                    </select>
                </div>
                <div class="form-group" v-if="type=='slider_url'">
                    <label> {{ __('link') }}</label>
                    <input type="url" class="form-control" v-model="slider_url" placeholder="Enter Link" required>
                </div>
                <!-- <div class="form-group">
                    <label> {{ __('image') }}</label>
                    <p class="text-muted"> {{ __('please_choose_square_image_of_larger_than_smaller_than') }}</p>
                    <input type="file" name="slider_image" accept="image/*" v-on:change="handleFileUpload" ref="file_image" class="file-input">
                    <div class="file-input-div bg-gray-100" @click="$refs.file_image.click()" @drop="dropFile" @dragover="$dragoverFile" @dragleave="$dragleaveFile">

                        <template v-if="image && image.name !== ''">
                            <label>{{ __('selected_file_name') }}{{ image.name }}</label>
                        </template>
                        <template v-else>
                            <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                            <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                        </template>

                    </div>
                    <div class="row" v-if="image_url">
                        <div class="col-md-6">
                            <img class="custom-slider-image" :src="image_url" title='Store Logo' alt='Store Logo'/>
                        </div>
                    </div>
                </div> -->
                
                



                <div class="form-group">
                    <label> {{ __('media') }} (Image / Video)</label>
                    <p class="text-muted">
                        Image/GIF max 5MB, Video max 20MB (mp4, webm, mov)
                    </p>

                    <input
                        type="file"
                        name="media"
                        accept="image/*,video/*"
                        ref="file_image"
                        class="file-input"
                        @change="handleFileUpload"
                    />

                    <div
                        class="file-input-div bg-gray-100"
                        @click="$refs.file_image.click()"
                        @drop="dropFile"
                        @dragover.prevent
                        @dragleave.prevent
                    >
                        <template v-if="media && media.name">
                        <label>{{ __('selected_file_name') }} {{ media.name }}</label>
                        </template>
                        <template v-else>
                        <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                        <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                        </template>
                    </div>

                    <!-- ✅ IMAGE PREVIEW -->
                    <div class="row mt-2" v-if="mediaPreview && isImage">
                        <div class="col-md-6">
                        <img class="custom-slider-image" :src="mediaPreview" />
                        </div>
                    </div>

                    <!-- ✅ VIDEO PREVIEW -->
                    <div class="row mt-2" v-if="mediaPreview && isVideo">
                        <div class="col-md-6">
                        <video :src="mediaPreview" controls width="100%"></video>
                        </div>
                    </div>

                    <!-- ✅ Error -->
                    <small class="text-danger" v-if="mediaError">{{ mediaError }}</small>
                </div>

                <!-- <div class="form-group" v-if="type === 'store'">
                    <label>Android Deeplink</label>
                    <input type="text" class="form-control" v-model="android_deeplink" placeholder="e.g. zenfoo://store/15">
                </div>

                <div class="form-group" v-if="type === 'store'">
                    <label>iOS Deeplink</label>
                    <input type="text" class="form-control" v-model="ios_deeplink" placeholder="e.g. zenfoo://store/15">
                </div> -->

                <div class="form-group" v-if="id">
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
            <button ref="dummy_submit" style="display:none;"></button>
        </form>
    </b-modal>
</template>

<script>
import axios from 'axios';

export default {
    props: ['record', 'categories', 'products', 'stores'],
    data: function () {
        return {
            isLoading: false,
            // image: null,
            id: this.record ? this.record.id : null,
            type: this.record ? this.record.type : 'default',
            type_id: this.record ? this.record.type_id : "",
            store_id: this.record ? this.record.store_id : "",
            // image_url: this.record ? this.record.image_url : null,
            media: null,
            mediaPreview: this.record ? this.record.image_url : null,
            mediaError: null,

            slider_url: this.record ? this.record.slider_url : "",
            android_deeplink: this.record ? this.record.android_deeplink : "",
            ios_deeplink: this.record ? this.record.ios_deeplink : "",
            status: this.record ? this.record.status : 1,

            // Cascading dropdowns for category / product types
            slider_stores: [],
            slider_store_id: this.record ? (this.record.store_id || "") : "",
            categoryGroups: [],
            category_group_id: this.record ? (this.record.category_group_id || "") : "",
            subCategoryGroups: [],
            sub_category_group_id: this.record ? (this.record.sub_category_group_id || "") : "",
            sliderCategories: [],
            slider_category_id: this.record ? (this.record.slider_category_id || "") : "",
            sliderProducts: [],
            loadingCategoryGroups: false,
            loadingSubCategoryGroups: false,
            loadingCategories: false,
            loadingProducts: false,
        };
    },
    watch: {
        type() {
            this.type_id = "";
            this.slider_url = "";
            this.store_id = "";

            // Reset cascade
            this.slider_store_id = "";
            this.category_group_id = "";
            this.sub_category_group_id = "";
            this.slider_category_id = "";
            this.categoryGroups = [];
            this.subCategoryGroups = [];
            this.sliderCategories = [];
            this.sliderProducts = [];

            // ✅ Only clear media if NOT editing
            if (!this.id) {
                this.media = null;
                this.mediaPreview = null;
                this.mediaError = null;
            }
        }
    },


    computed: {

        modal_title: function () {
            let title = this.id ? "Edit" : "Add";
            title += " Home Slider Image";
            return title;
        },

        isImage() {
            if (this.media) {
                return this.media.type.startsWith('image');
            }
            // ✅ For EDIT (URL-based detection)
            if (this.mediaPreview) {
                return /\.(jpg|jpeg|png|gif|webp)$/i.test(this.mediaPreview);
            }
            return false;
        },

        isVideo() {
            if (this.media) {
                return this.media.type.startsWith('video');
            }
            // ✅ For EDIT (URL-based detection)
            if (this.mediaPreview) {
                return /\.(mp4|webm|ogg|mov|avi)$/i.test(this.mediaPreview);
            }
            return false;
        },


    },
    methods: {
        showModal() {
            this.$refs['my-modal'].show()
        },
        hideModal() {
            this.$refs['my-modal'].hide()

        },
        // dropFile(event) {
        //     event.preventDefault();
        //     this.$refs.file_image.files = event.dataTransfer.files;
        //     this.handleFileUpload(); // Trigger the onChange event manually
        //     // Clean up
        //     event.currentTarget.classList.add('bg-gray-100');
        //     event.currentTarget.classList.remove('bg-green-300');
        // },

        dropFile(event) {
            event.preventDefault();
            this.$refs.file_image.files = event.dataTransfer.files;
            this.handleFileUpload();
        },

        // handleFileUpload() {
        //     this.image = this.$refs.file_image.files[0];
        //     this.image_url = URL.createObjectURL(this.image);
        // },


        handleFileUpload() {
            this.mediaError = null;
            const file = this.$refs.file_image.files[0];
            if (!file) return;

            const isImage = file.type.startsWith('image/');
            const isVideo = file.type.startsWith('video/');

            const maxImageSize = 5 * 1024 * 1024;   // 5MB
            const maxVideoSize = 20 * 1024 * 1024;  // ✅ 20MB

            if (!isImage && !isVideo) {
                this.mediaError = "Only image or video files are allowed";
                this.$refs.file_image.value = '';
                return;
            }

            if (isImage && file.size > maxImageSize) {
                this.mediaError = "Image must be less than 5MB";
                this.$refs.file_image.value = '';
                return;
            }

            if (isVideo && file.size > maxVideoSize) {
                this.mediaError = "Video must be less than 20MB";
                this.$refs.file_image.value = '';
                return;
            }

            this.media = file;
            this.mediaPreview = URL.createObjectURL(file);

        },

        // ── Cascade helpers ──────────────────────────────────────────────

        // Re-hydrates all cascade dropdown option lists when editing an existing record
        async loadCascadeForEdit() {
            if (!this.slider_store_id) return;
            try {
                // Step 1 – category groups for the saved store
                this.loadingCategoryGroups = true;
                const cgRes = await axios.get(this.$apiUrl + '/get-data-based-on-store-selection', { params: { store_id: this.slider_store_id } });
                this.loadingCategoryGroups = false;
                this.categoryGroups = cgRes.data.data || [];

                if (!this.category_group_id) return;

                // Step 2 – sub category groups for the saved category group
                this.loadingSubCategoryGroups = true;
                const scgRes = await axios.get(this.$apiUrl + '/get-data-based-on-category-selection', { params: { category_group_id: this.category_group_id } });
                this.loadingSubCategoryGroups = false;
                this.subCategoryGroups = scgRes.data.data || [];

                if (!this.sub_category_group_id) return;

                // Step 3 – categories for the saved sub category group
                this.loadingCategories = true;
                const catRes = await axios.get(this.$apiUrl + '/get-data-based-on-sub-category-selection', { params: { sub_category_group_id: this.sub_category_group_id } });
                this.loadingCategories = false;
                this.sliderCategories = catRes.data.data || [];

                if (this.type !== 'product' || !this.slider_category_id) return;

                // Step 4 – products for the saved category (product type only)
                this.loadingProducts = true;
                const prodRes = await axios.get(this.$apiUrl + '/products', { params: { category: this.slider_category_id } });
                this.loadingProducts = false;
                let d = prodRes.data;
                this.sliderProducts = d.data?.products || d.data || [];

            } catch (e) {
                this.loadingCategoryGroups = false;
                this.loadingSubCategoryGroups = false;
                this.loadingCategories = false;
                this.loadingProducts = false;
            }
        },

        getSliderStores() {
            axios.get(this.$apiUrl + '/get-all-stores-data')
                .then(res => { this.slider_stores = Array.isArray(res.data) ? res.data : []; })
                .catch(() => { this.slider_stores = []; });
        },

        onSliderStoreChange() {
            this.category_group_id = "";
            this.sub_category_group_id = "";
            this.slider_category_id = "";
            this.type_id = "";
            this.categoryGroups = [];
            this.subCategoryGroups = [];
            this.sliderCategories = [];
            this.sliderProducts = [];

            if (!this.slider_store_id) return;
            this.loadingCategoryGroups = true;
            axios.get(this.$apiUrl + '/get-data-based-on-store-selection', { params: { store_id: this.slider_store_id } })
                .then(res => {
                    this.loadingCategoryGroups = false;
                    this.categoryGroups = res.data.data || [];
                })
                .catch(() => { this.loadingCategoryGroups = false; });
        },

        onCategoryGroupChange() {
            this.sub_category_group_id = "";
            this.slider_category_id = "";
            this.type_id = "";
            this.subCategoryGroups = [];
            this.sliderCategories = [];
            this.sliderProducts = [];

            if (!this.category_group_id) return;
            this.loadingSubCategoryGroups = true;
            axios.get(this.$apiUrl + '/get-data-based-on-category-selection', { params: { category_group_id: this.category_group_id } })
                .then(res => {
                    this.loadingSubCategoryGroups = false;
                    this.subCategoryGroups = res.data.data || [];
                })
                .catch(() => { this.loadingSubCategoryGroups = false; });
        },

        onSubCategoryGroupChange() {
            this.slider_category_id = "";
            this.type_id = "";
            this.sliderCategories = [];
            this.sliderProducts = [];

            if (!this.sub_category_group_id) return;
            this.loadingCategories = true;
            axios.get(this.$apiUrl + '/get-data-based-on-sub-category-selection', { params: { sub_category_group_id: this.sub_category_group_id } })
                .then(res => {
                    this.loadingCategories = false;
                    this.sliderCategories = res.data.data || [];
                })
                .catch(() => { this.loadingCategories = false; });
        },

        onSliderCategoryChange() {
            // For category type → type_id is the category itself
            if (this.type === 'category') {
                this.type_id = this.slider_category_id;
                return;
            }

            // For product type → load products for this category
            this.type_id = "";
            this.sliderProducts = [];
            if (!this.slider_category_id) return;

            this.loadingProducts = true;
            axios.get(this.$apiUrl + '/products', { params: { category: this.slider_category_id } })
                .then(res => {
                    this.loadingProducts = false;
                    let d = res.data;
                    this.sliderProducts = d.data?.products || d.data || [];
                })
                .catch(() => { this.loadingProducts = false; });
        },
        // ─────────────────────────────────────────────────────────────────

        saveRecord: function () {
            let vm = this;
            this.isLoading = true;
            let formData = new FormData();
            if (this.id) {
                formData.append('id', this.id);
            }
            formData.append('type', this.type);
            formData.append('type_id', this.type_id);
            // formData.append('image', this.image);

            if (this.media) {
                formData.append('media', this.media);
            }

            formData.append('slider_url', this.slider_url);
            // formData.append('android_deeplink', this.android_deeplink || '');
            // formData.append('ios_deeplink', this.ios_deeplink || '');
            formData.append('status', this.status);
            // For category/product types the store comes from the cascade picker
            // For store type the selected store (type_id) is also the store_id
            const storeIdToSend = (this.type === 'category' || this.type === 'product')
                ? this.slider_store_id
                : (this.type === 'store' ? this.type_id : this.store_id);
            formData.append('store_id', storeIdToSend || '');

            // Cascade IDs (for category / product types)
            formData.append('category_group_id', this.category_group_id || '');
            formData.append('sub_category_group_id', this.sub_category_group_id || '');
            formData.append('slider_category_id', this.slider_category_id || '');
            let url = this.$apiUrl + '/home_slider_images/save';
            if (this.id) {
                url = this.$apiUrl + '/home_slider_images/update';
            }
            axios.post(url, formData, {
                headers: {
                    'Content-Type': 'multipart/form-data'
                }
            }).then(res => {
                let data = res.data;
                if (data.status === 1) {
                    this.$eventBus.$emit('SliderSaved', data.message);
                    vm.$router.push({path: '/home_sliders'});
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
                    this.showError(__('something_went_wrong'));
                }
            });
        }
    },
    mounted() {
        this.showModal();
        this.getSliderStores();

        if (this.id) {
            if (this.record?.image_url) {
                this.mediaPreview = this.record.image_url;
            }
            if (this.type === 'category' || this.type === 'product') {
                this.loadCascadeForEdit();
            }
        }
    }
}
</script>

<style scoped>

</style>
