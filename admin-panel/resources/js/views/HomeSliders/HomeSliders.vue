<template>

    <div>

        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3> {{ __('manage_home_slider_images') }}</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">{{ __('manage_home_slider_images') }}</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/dashboard" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to Dashboard
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12 col-md-12 order-md-1 order-last">
                    <div class="card">

                        <div class="card-header">
                            <h4> {{ __('home_slider_images') }}</h4>
                            <span class="pull-right">
                                <button class="btn btn-secondary me-2" @click="showAppLaunchModal = true">App Launch Banner</button>
                                <button class="btn btn-primary" @click="create_new=true">{{ __('add_new') }}</button> <!-- v-if="$can('home_slider_image_create')" -->
                            </span>
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
                                    <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="getSliders()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i>
                                    </button>
                                </b-col>

                            </b-row>
                            <div class="table-responsive">
                            <b-table
                                :items="sliders"
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
                                    <a :href="row.item.image_url" target="_blank" rel="noopener noreferrer">
                                        <span v-if="isVideo(row.item.image_url)" class="badge bg-info"><i class="fa fa-play-circle"></i> Video</span>
                                        <img v-else :src="row.item.image_url" height="50"/>
                                    </a>
                                </template>
                                <template #cell(status)="row">
                                    <span v-if="row.item.status === 1" class="badge bg-success">{{ __('active') }}</span>
                                    <span v-else class="badge bg-danger">{{ __('deactive') }}</span>
                                </template>

                                <template #cell(actions)="row">
                                    <button class="btn btn-sm btn-primary" @click="edit_record = row.item" v-b-tooltip.hover :title="__('edit')"><i class="fa fa-pencil-alt"></i></button> <!-- v-if="$can('home_slider_image_update')" -->
                                    <button class="btn btn-sm btn-danger" @click="deleteSlider(row.index,row.item.id)" v-b-tooltip.hover :title="__('delete')"><i class="fa fa-trash"></i></button> <!-- v-if="$can('home_slider_image_delete')" -->
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
                                    <label>{{__('total_records')}} :- {{ totalRows }} </label>
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
                </div>
            </div>
        </div>

        <!-- Add / Edit -->
        <app-edit-record
            v-if="create_new || edit_record"
            :record="edit_record"
            :categories="categories"
            :products="products"
            :stores="stores"
            @modalClose="hideModal()"
        ></app-edit-record>

        <!-- App Launch Banner Modal -->
        <b-modal v-model="showAppLaunchModal" title="App Launch Banner" hide-footer centered size="lg" @show="getAppLaunchBanner">
            <div class="p-3">
                <div v-if="appLaunchBannerLoading" class="text-center">
                    <b-spinner class="align-middle"></b-spinner>
                    <strong>Loading...</strong>
                </div>
                <div v-else>
                    <!-- Current (saved) banner -->
                    <div v-if="appLaunchBannerUrl" class="d-flex align-items-center gap-2 mb-3">
                        <span class="text-muted small">Current Banner</span>
                        <a :href="appLaunchBannerUrl" target="_blank" class="btn btn-sm btn-outline-secondary">
                            <i class="fa fa-external-link"></i> View
                        </a>
                    </div>

                    <div class="form-group mb-3">
                        <label class="d-block">Orientation</label>
                        <div class="form-check form-check-inline">
                            <input class="form-check-input" type="radio" id="orientationPortrait" value="portrait" v-model="appLaunchBannerOrientation" @change="onOrientationChange" />
                            <label class="form-check-label" for="orientationPortrait">Portrait</label>
                        </div>
                        <div class="form-check form-check-inline">
                            <input class="form-check-input" type="radio" id="orientationLandscape" value="landscape" v-model="appLaunchBannerOrientation" @change="onOrientationChange" />
                            <label class="form-check-label" for="orientationLandscape">Landscape</label>
                        </div>
                        <small class="d-block text-muted">Choose how the banner should fit the screen in the app.</small>
                    </div>
                    <div class="form-group mb-3">
                        <label for="appLaunchBannerRatio">Aspect Ratio</label>
                        <select id="appLaunchBannerRatio" class="form-control form-select" v-model="appLaunchBannerRatio" @change="validateUploadedAssetRatio">
                            <option v-for="opt in ratioOptionsForOrientation" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
                        </select>
                        <small class="d-block text-muted">
                            Supported {{ appLaunchBannerOrientation }} ratios:
                            <span v-for="(opt, idx) in ratioOptionsForOrientation" :key="opt.value">
                                <strong>{{ opt.value }}</strong><span v-if="idx < ratioOptionsForOrientation.length - 1">, </span>
                            </span>.
                            Recommended size for {{ appLaunchBannerRatio }}: <strong>{{ recommendedSizeForRatio }}</strong>.
                        </small>
                    </div>
                    <div class="form-group mb-3">
                        <label for="appLaunchBannerFile">Upload New Banner</label>
                        <input type="file" class="form-control" id="appLaunchBannerFile" ref="appLaunchBannerFileInput" @change="onAppLaunchBannerFileChange" accept="image/*,video/mp4,video/quicktime,video/webm,video/x-msvideo" />
                        <small class="text-muted">Accepted formats: JPEG, JPG, PNG, GIF, WEBP, MP4, MOV, WEBM, AVI</small>
                        <div v-if="uploadedAssetInfo" class="mt-2">
                            <span class="text-muted small">
                                Uploaded file size: <strong>{{ uploadedAssetInfo.width }} &times; {{ uploadedAssetInfo.height }}</strong>
                                (ratio <strong>{{ uploadedAssetInfo.ratioLabel }}</strong>)
                            </span>
                        </div>
                        <div v-if="ratioMismatchWarning" class="mt-2 p-2 rounded" style="background:#fff7e6; border:1px solid #ffd591; color:#ad6800;">
                            <i class="fa fa-exclamation-triangle me-1"></i>
                            {{ ratioMismatchWarning }}
                        </div>
                    </div>
                    <div class="form-group mb-3">
                        <label for="appLaunchBannerColor">Background Color</label>
                        <div class="d-flex align-items-center">
                            <input type="color" class="form-control form-control-color me-2" id="appLaunchBannerColor" v-model="appLaunchBannerColor" style="width: 60px; height: 38px;" />
                            <input type="text" class="form-control" v-model="appLaunchBannerColor" placeholder="#FFFFFF" style="width: 120px;" />
                        </div>
                        <small class="text-muted">Select or enter a color code (e.g., #FFFFFF)</small>
                    </div>

                    <!-- Special Items Section -->
                    <hr class="my-4" />
                    <h5 class="mb-3">Special Items (Sub Category Groups)</h5>

                    <!-- Dropdowns Row -->
                    <div class="row mb-3">
                        <div class="col-md-4">
                            <div class="form-group">
                                <label>{{ __('store') }}</label>
                                <select class="form-control form-select" v-model="specialItemStoreId" @change="onSpecialItemStoreChange">
                                    <option value="">--Select Store--</option>
                                    <option v-for="store in specialItemStores" :key="store.id" :value="store.id">{{ store.name }}</option>
                                </select>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="form-group">
                                <label>Category Group</label>
                                <select class="form-control form-select" v-model="specialItemCategoryGroupId" @change="onSpecialItemCategoryGroupChange" :disabled="!specialItemStoreId">
                                    <option value="">--Select Category Group--</option>
                                    <option v-for="group in specialItemCategoryGroups" :key="group.id" :value="group.id">{{ group.name }}</option>
                                </select>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="form-group">
                                <label>Sub Category Group</label>
                                <select class="form-control form-select" v-model="specialItemSubCategoryGroupId" :disabled="!specialItemCategoryGroupId">
                                    <option value="">--Select Sub Category Group--</option>
                                    <option v-for="subGroup in availableSubCategoryGroups" :key="subGroup.id" :value="subGroup.id">{{ subGroup.name }}</option>
                                </select>
                            </div>
                        </div>
                    </div>

                    <!-- Add Button -->
                    <div class="mb-3">
                        <button class="btn btn-success btn-sm" @click="addSpecialItem" :disabled="!specialItemSubCategoryGroupId">
                            <i class="fa fa-plus"></i> Add to Special Items
                        </button>
                    </div>

                    <!-- Selected Special Items List -->
                    <div class="mb-3">
                        <label>Selected Special Items ({{ selectedSpecialItems.length }})</label>
                        <div v-if="selectedSpecialItems.length === 0" class="text-muted">
                            <small>No special items selected yet.</small>
                        </div>
                        <div v-else class="selected-special-items-list" style="max-height: 200px; overflow-y: auto;">
                            <div v-for="(item, index) in selectedSpecialItems" :key="item.id" class="d-flex align-items-center justify-content-between border rounded p-2 mb-2">
                                <div class="d-flex align-items-center">
                                    <img v-if="item.image_url" :src="item.image_url" height="30" class="me-2" />
                                    <div>
                                        <strong>{{ item.name }}</strong>
                                        <br />
                                        <small class="text-muted">{{ item.store_name }} / {{ item.category_group_name }}</small>
                                    </div>
                                </div>
                                <button class="btn btn-danger btn-sm" @click="removeSpecialItem(index)">
                                    <i class="fa fa-times"></i>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div v-if="appLaunchBannerError" class="mx-3 mb-2 p-2 rounded" style="background:#fff0f0; border:1px solid #f5c2c2; color:#c0392b;">
                <i class="fa fa-exclamation-circle me-1"></i> {{ appLaunchBannerError }}
            </div>
            <div class="text-end p-3">
                <button class="btn btn-secondary me-2" @click="showAppLaunchModal = false">Close</button>
                <button class="btn btn-primary" @click="updateAppLaunchBanner" :disabled="appLaunchBannerUploading">
                    <span v-if="appLaunchBannerUploading"><b-spinner small></b-spinner> Saving...</span>
                    <span v-else>Save</span>
                </button>
            </div>
        </b-modal>
    </div>

</template>
<script>
import {VuejsDatatableFactory} from 'vuejs-datatable';
import EditRecord from './Edit.vue';
import axios from "axios";


export default {
    components: {
        VuejsDatatableFactory,
        'app-edit-record': EditRecord,
    },
    data: function () {
        return {
            create_new: false,
            fields: [
                {key: 'id', label: __('id'), sortable: true, sortDirection: 'desc'},
                {key: 'type', label: __('type'), sortable: true, class: 'text-center'},
                // {key: 'type_name', label: __('name'), sortable: true, class: 'text-center'},
                {key: 'image', label: __('image'), class: 'text-center'},
                {key: 'status', label: __('status'), class: 'text-center'},
                {key: 'actions', label: __('actions')}
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

            sliders: [],
            isLoading: false,
            sectionStyle: 'style_1',
            max_visible_sliders: 12,
            max_col_in_single_row: 3,
            edit_record: null,
            categories: [],
            products: [],
            showAppLaunchModal: false,
            appLaunchBannerUrl: null,
            appLaunchBannerFile: null,
            appLaunchBannerLoading: false,
            appLaunchBannerUploading: false,
            appLaunchBannerColor: '#FFFFFF',
            appLaunchBannerColorOriginal: '#FFFFFF',
            appLaunchBannerOrientation: 'portrait',
            appLaunchBannerOrientationOriginal: 'portrait',
            appLaunchBannerRatio: '9:16',
            appLaunchBannerRatioOriginal: '9:16',
            uploadedAssetInfo: null,
            ratioMismatchWarning: null,
            portraitRatios: [
                { value: '9:16', label: '9:16 — Full screen story', size: '1080 × 1920' },
                { value: '3:4',  label: '3:4 — Classic portrait',   size: '1080 × 1440' },
                { value: '2:3',  label: '2:3 — Photo print',        size: '1080 × 1620' },
                { value: '1:2',  label: '1:2 — Tall banner',        size: '1080 × 2160' },
                { value: '1:1',  label: '1:1 — Square',             size: '633 × 633'  },
            ],
            landscapeRatios: [
                { value: '16:9', label: '16:9 — Widescreen',  size: '1920 × 1080' },
                { value: '4:3',  label: '4:3 — Standard',     size: '1440 × 1080' },
                { value: '3:2',  label: '3:2 — Photo print',  size: '1620 × 1080' },
                { value: '21:9', label: '21:9 — Cinematic',   size: '2520 × 1080' },
                { value: '1:1',  label: '1:1 — Square',       size: '633 × 633'  },
            ],
            appLaunchBannerPreviewUrl: null,
            appLaunchBannerPreviewIsVideo: false,
            appLaunchBannerError: null,
            // Special Items
            specialItemStores: [],
            specialItemStoreId: '',
            specialItemCategoryGroups: [],
            specialItemCategoryGroupId: '',
            specialItemSubCategoryGroups: [],
            specialItemSubCategoryGroupId: '',
            selectedSpecialItems: [],
            originalSpecialItemIds: [],
        }
    },
    computed: {
        sortOptions() {
            // Create an options list from our fields
            return this.fields
                .filter(f => f.sortable)
                .map(f => {
                    return {text: f.label, value: f.key}
                })
        },
        appLaunchBannerColorChanged() {
            return this.appLaunchBannerColor !== this.appLaunchBannerColorOriginal;
        },
        appLaunchBannerOrientationChanged() {
            return this.appLaunchBannerOrientation !== this.appLaunchBannerOrientationOriginal;
        },
        appLaunchBannerRatioChanged() {
            return this.appLaunchBannerRatio !== this.appLaunchBannerRatioOriginal;
        },
        ratioOptionsForOrientation() {
            return this.appLaunchBannerOrientation === 'landscape' ? this.landscapeRatios : this.portraitRatios;
        },
        recommendedSizeForRatio() {
            const opt = this.ratioOptionsForOrientation.find(o => o.value === this.appLaunchBannerRatio);
            return opt ? opt.size : '';
        },
        specialItemsChanged() {
            const currentIds = this.selectedSpecialItems.map(item => item.id).sort().join(',');
            const originalIds = this.originalSpecialItemIds.sort().join(',');
            return currentIds !== originalIds;
        },
        hasAnyChanges() {
            return this.appLaunchBannerFile || this.appLaunchBannerColorChanged || this.appLaunchBannerOrientationChanged || this.appLaunchBannerRatioChanged || this.specialItemsChanged;
        },
        availableSubCategoryGroups() {
            const selectedIds = this.selectedSpecialItems.map(item => item.id);
            return this.specialItemSubCategoryGroups.filter(subGroup => !selectedIds.includes(subGroup.id));
        }
    },
    mounted() {
        // Set the initial number of items
        this.totalRows = this.sliders.length
    },
    watch: {
        $route(to, from) {
            this.showCreateModal();
        }
    },
    created: function () {
        this.showCreateModal();
        this.$eventBus.$on('SliderSaved', (message) => {
            this.showMessage('success', message);
            this.getSliders();
        });
        this.getSliders();
        this.getCategories();
        this.getProducts();
        this.getStores();
    },
    methods: {
        isVideo(url) {
            if (!url) return false;
            const videoExtensions = ['.mp4', '.webm', '.ogg', '.mov', '.avi', '.mkv'];
            const lowerUrl = url.toLowerCase();
            return videoExtensions.some(ext => lowerUrl.includes(ext));
        },
        isVideoUrl(url) {
            return this.isVideo(url);
        },
        getSliders() {
            this.isLoading = true
            axios.get(this.$apiUrl + '/home_slider_images')
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    this.sliders = data.data
                    this.totalRows = this.sliders.length
                });
        },

        getStores() {
            axios
                .get(this.$apiUrl + '/get-all-stores-data')
                .then((res) => {
                this.stores = Array.isArray(res.data) ? res.data : [];
                })
                .catch(() => {
                console.error("Failed to load stores");
                });
        },

        getCategories() {
            this.isLoading = true
            let url = this.$apiUrl + '/categories';
            axios.get(url)
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    this.categories = data.data
                });
        },
        getProducts() {

            this.isLoading = true
            let url = this.$apiUrl + '/products';
            axios.get(url)
                .then((response) => {
                    this.isLoading = false
                    let data = response.data;
                    this.products = data.data.products
                });
        },
        deleteSlider(index, id) {
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
                        id: id
                    }
                    axios.post(this.$apiUrl + '/home_slider_images/delete', postData)
                        .then((response) => {
                            this.isLoading = false
                            let data = response.data;
                            this.sliders.splice(index, 1)
                            this.showMessage("success", data.message);
                        });
                }
            });
        },
        showCreateModal(){
            let create = this.$route.params.create;
            if(create){
                this.create_new = true;
            }
        },
        hideModal() {
            this.create_new = false
            this.edit_record = false
            this.$router.push({path: '/home_sliders'});
        },
        getAppLaunchBanner() {
            this.appLaunchBannerLoading = true;
            this.appLaunchBannerFile = null;
            this.appLaunchBannerError = null;
            if (this.appLaunchBannerPreviewUrl) {
                URL.revokeObjectURL(this.appLaunchBannerPreviewUrl);
                this.appLaunchBannerPreviewUrl = null;
                this.appLaunchBannerPreviewIsVideo = false;
            }
            // Reset special item selections
            this.specialItemStoreId = '';
            this.specialItemCategoryGroupId = '';
            this.specialItemSubCategoryGroupId = '';
            this.specialItemCategoryGroups = [];
            this.specialItemSubCategoryGroups = [];

            // Fetch stores for special items dropdown
            this.getSpecialItemStores();

            // Fetch app launch banner data
            this.uploadedAssetInfo = null;
            this.ratioMismatchWarning = null;

            axios.get(this.$apiUrl + '/home_slider_images/app_launch_banner')
                .then((response) => {
                    let data = response.data;
                    this.appLaunchBannerUrl = data.url;
                    this.appLaunchBannerColor = data.color || '#FFFFFF';
                    this.appLaunchBannerColorOriginal = data.color || '#FFFFFF';
                    this.appLaunchBannerOrientation = data.orientation || 'portrait';
                    this.appLaunchBannerOrientationOriginal = data.orientation || 'portrait';
                    const defaultRatio = this.appLaunchBannerOrientation === 'landscape' ? '16:9' : '9:16';
                    this.appLaunchBannerRatio = data.ratio || defaultRatio;
                    this.appLaunchBannerRatioOriginal = data.ratio || defaultRatio;
                })
                .catch(() => {
                    this.appLaunchBannerUrl = null;
                    this.appLaunchBannerColor = '#FFFFFF';
                    this.appLaunchBannerColorOriginal = '#FFFFFF';
                    this.appLaunchBannerOrientation = 'portrait';
                    this.appLaunchBannerOrientationOriginal = 'portrait';
                    this.appLaunchBannerRatio = '9:16';
                    this.appLaunchBannerRatioOriginal = '9:16';
                });

            // Fetch existing special items
            axios.get(this.$apiUrl + '/home_slider_images/special_items')
                .then((response) => {
                    this.appLaunchBannerLoading = false;
                    if (response.data.status === 1) {
                        this.selectedSpecialItems = response.data.data || [];
                        this.originalSpecialItemIds = this.selectedSpecialItems.map(item => item.id);
                    }
                })
                .catch(() => {
                    this.appLaunchBannerLoading = false;
                    this.selectedSpecialItems = [];
                    this.originalSpecialItemIds = [];
                });
        },
        onAppLaunchBannerFileChange(event) {
            const file = event.target.files[0];
            this.appLaunchBannerError = null;
            this.uploadedAssetInfo = null;
            this.ratioMismatchWarning = null;
            if (!file) {
                this.appLaunchBannerFile = null;
                return;
            }
            this.appLaunchBannerFile = file;
            this.readAssetDimensions(file)
                .then(({ width, height }) => {
                    const ratioLabel = this.simplifyRatio(width, height);
                    this.uploadedAssetInfo = { width, height, ratioLabel };
                    this.validateUploadedAssetRatio();
                })
                .catch(() => {
                    this.uploadedAssetInfo = null;
                });
        },
        readAssetDimensions(file) {
            return new Promise((resolve, reject) => {
                if (file.type && file.type.startsWith('video/')) {
                    const video = document.createElement('video');
                    video.preload = 'metadata';
                    video.onloadedmetadata = () => {
                        const w = video.videoWidth, h = video.videoHeight;
                        URL.revokeObjectURL(video.src);
                        if (w && h) resolve({ width: w, height: h });
                        else reject(new Error('Could not read video dimensions'));
                    };
                    video.onerror = () => {
                        URL.revokeObjectURL(video.src);
                        reject(new Error('Could not load video'));
                    };
                    video.src = URL.createObjectURL(file);
                } else {
                    const img = new Image();
                    img.onload = () => {
                        URL.revokeObjectURL(img.src);
                        resolve({ width: img.naturalWidth, height: img.naturalHeight });
                    };
                    img.onerror = () => {
                        URL.revokeObjectURL(img.src);
                        reject(new Error('Could not load image'));
                    };
                    img.src = URL.createObjectURL(file);
                }
            });
        },
        onOrientationChange() {
            const defaultRatio = this.appLaunchBannerOrientation === 'landscape' ? '16:9' : '9:16';
            const stillValid = this.ratioOptionsForOrientation.some(o => o.value === this.appLaunchBannerRatio);
            if (!stillValid) {
                this.appLaunchBannerRatio = defaultRatio;
            }
            this.validateUploadedAssetRatio();
        },
        parseRatio(ratioStr) {
            if (!ratioStr) return null;
            const [w, h] = ratioStr.split(':').map(Number);
            if (!w || !h) return null;
            return w / h;
        },
        simplifyRatio(w, h) {
            const gcd = (a, b) => b ? gcd(b, a % b) : a;
            const g = gcd(w, h) || 1;
            return `${Math.round(w / g)}:${Math.round(h / g)}`;
        },
        validateUploadedAssetRatio() {
            if (!this.uploadedAssetInfo) {
                this.ratioMismatchWarning = null;
                return;
            }
            const { width, height } = this.uploadedAssetInfo;
            const actualRatio = width / height;
            const isActuallyPortrait = height >= width;
            const expectedPortrait = this.appLaunchBannerOrientation === 'portrait';
            const isSquareSelected = this.appLaunchBannerRatio === '1:1';
            const isActuallySquare = width === height;

            if (!isSquareSelected && !isActuallySquare && isActuallyPortrait !== expectedPortrait) {
                this.ratioMismatchWarning =
                    `Uploaded file is ${isActuallyPortrait ? 'portrait' : 'landscape'} but the selected orientation is ${this.appLaunchBannerOrientation}. ` +
                    `The image may appear blurred or cropped in the app. Please upload a ${this.appLaunchBannerOrientation} asset.`;
                return;
            }

            const targetRatio = this.parseRatio(this.appLaunchBannerRatio);
            if (!targetRatio) {
                this.ratioMismatchWarning = null;
                return;
            }
            const diff = Math.abs(actualRatio - targetRatio) / targetRatio;
            if (diff > 0.03) {
                this.ratioMismatchWarning =
                    `Uploaded file ratio (${this.uploadedAssetInfo.ratioLabel}) doesn't match the selected ${this.appLaunchBannerRatio} ratio. ` +
                    `The asset may appear blurred, stretched, or cropped in the app. Recommended size: ${this.recommendedSizeForRatio}.`;
            } else {
                this.ratioMismatchWarning = null;
            }
        },
        updateAppLaunchBanner() {
            if (!this.appLaunchBannerFile && !this.appLaunchBannerColorChanged && !this.appLaunchBannerOrientationChanged && !this.appLaunchBannerRatioChanged && !this.specialItemsChanged) return;

            this.appLaunchBannerError = null;
            this.appLaunchBannerUploading = true;

            // Array to hold all promises
            let promises = [];

            // Update banner, color, orientation, ratio if changed
            if (this.appLaunchBannerFile || this.appLaunchBannerColorChanged || this.appLaunchBannerOrientationChanged || this.appLaunchBannerRatioChanged) {
                let formData = new FormData();

                if (this.appLaunchBannerFile) {
                    formData.append('image', this.appLaunchBannerFile);
                }

                if (this.appLaunchBannerColorChanged) {
                    formData.append('color', this.appLaunchBannerColor);
                }

                if (this.appLaunchBannerOrientationChanged) {
                    formData.append('orientation', this.appLaunchBannerOrientation);
                }

                if (this.appLaunchBannerRatioChanged) {
                    formData.append('ratio', this.appLaunchBannerRatio);
                }

                promises.push(
                    axios.post(this.$apiUrl + '/home_slider_images/app_launch_banner/update', formData, {
                        headers: {
                            'Content-Type': 'multipart/form-data'
                        }
                    })
                );
            }

            // Update special items if changed
            if (this.specialItemsChanged) {
                const specialItemIds = this.selectedSpecialItems.map(item => item.id);
                promises.push(
                    axios.post(this.$apiUrl + '/home_slider_images/special_items/update', {
                        special_item_ids: specialItemIds
                    })
                );
            }

            Promise.all(promises)
                .then((responses) => {
                    this.appLaunchBannerUploading = false;
                    let hasError = false;

                    // Handle banner response
                    const bannerResponse = responses.find(r => r.data.url !== undefined);
                    if (bannerResponse) {
                        let data = bannerResponse.data;
                        if (data.status === 1) {
                            this.appLaunchBannerUrl = data.url;
                            this.appLaunchBannerColor = data.color || '#FFFFFF';
                            this.appLaunchBannerColorOriginal = data.color || '#FFFFFF';
                            this.appLaunchBannerOrientation = data.orientation || 'portrait';
                            this.appLaunchBannerOrientationOriginal = data.orientation || 'portrait';
                            const defaultRatio = this.appLaunchBannerOrientation === 'landscape' ? '16:9' : '9:16';
                            this.appLaunchBannerRatio = data.ratio || defaultRatio;
                            this.appLaunchBannerRatioOriginal = data.ratio || defaultRatio;
                            this.appLaunchBannerFile = null;
                            this.uploadedAssetInfo = null;
                            this.ratioMismatchWarning = null;
                            if (this.appLaunchBannerPreviewUrl) {
                                URL.revokeObjectURL(this.appLaunchBannerPreviewUrl);
                                this.appLaunchBannerPreviewUrl = null;
                                this.appLaunchBannerPreviewIsVideo = false;
                            }
                        } else {
                            hasError = true;
                            this.appLaunchBannerError = data.message || 'Failed to update banner.';
                        }
                    }

                    if (!hasError) {
                        this.appLaunchBannerError = null;
                        // Update original special item IDs
                        this.originalSpecialItemIds = this.selectedSpecialItems.map(item => item.id);
                        this.showMessage('success', 'App Launch Banner Updated Successfully!');
                        this.showAppLaunchModal = false;
                    }
                })
                .catch((error) => {
                    this.appLaunchBannerUploading = false;
                    this.appLaunchBannerError = error.response?.data?.message || 'Failed to update. Please try again.';
                });
        },
        // Special Items Methods
        getSpecialItemStores() {
            axios.get(this.$apiUrl + '/get-all-stores-data')
                .then((response) => {
                    this.specialItemStores = response.data.filter(store => store.id != 17 && store.id != 15);
                })
                .catch((error) => {
                    console.error("Failed to load stores", error);
                });
        },
        onSpecialItemStoreChange() {
            this.specialItemCategoryGroupId = '';
            this.specialItemSubCategoryGroupId = '';
            this.specialItemCategoryGroups = [];
            this.specialItemSubCategoryGroups = [];

            if (this.specialItemStoreId) {
                this.getSpecialItemCategoryGroups(this.specialItemStoreId);
            }
        },
        getSpecialItemCategoryGroups(storeId) {
            axios.get(this.$apiUrl + '/get-data-based-on-store-selection', {
                params: { store_id: storeId }
            })
            .then((response) => {
                this.specialItemCategoryGroups = response.data.data || [];
            })
            .catch((error) => {
                console.error("Failed to load category groups", error);
            });
        },
        onSpecialItemCategoryGroupChange() {
            this.specialItemSubCategoryGroupId = '';
            this.specialItemSubCategoryGroups = [];

            if (this.specialItemCategoryGroupId) {
                this.getSpecialItemSubCategoryGroups(this.specialItemCategoryGroupId);
            }
        },
        getSpecialItemSubCategoryGroups(categoryGroupId) {
            axios.get(this.$apiUrl + '/group-sub-category/row_order', {
                params: { category_group_id: categoryGroupId }
            })
            .then((response) => {
                this.specialItemSubCategoryGroups = response.data.data || [];
            })
            .catch((error) => {
                console.error("Failed to load sub category groups", error);
            });
        },
        addSpecialItem() {
            if (!this.specialItemSubCategoryGroupId) return;

            // Check if already added
            const exists = this.selectedSpecialItems.find(item => item.id === this.specialItemSubCategoryGroupId);
            if (exists) {
                this.showMessage('warning', 'This item is already added');
                return;
            }

            // Find the selected sub category group
            const subGroup = this.specialItemSubCategoryGroups.find(sg => sg.id === this.specialItemSubCategoryGroupId);
            const store = this.specialItemStores.find(s => s.id === this.specialItemStoreId);
            const categoryGroup = this.specialItemCategoryGroups.find(cg => cg.id === this.specialItemCategoryGroupId);

            if (subGroup) {
                this.selectedSpecialItems.push({
                    id: subGroup.id,
                    name: subGroup.name,
                    image_url: subGroup.image_url,
                    store_id: this.specialItemStoreId,
                    store_name: store ? store.name : 'Unknown',
                    category_group_id: this.specialItemCategoryGroupId,
                    category_group_name: categoryGroup ? categoryGroup.name : 'Unknown',
                });

                // Reset sub category group selection
                this.specialItemSubCategoryGroupId = '';
            }
        },
        removeSpecialItem(index) {
            this.selectedSpecialItems.splice(index, 1);
        },
        getSpecialItems() {
            axios.get(this.$apiUrl + '/home_slider_images/special_items')
                .then((response) => {
                    if (response.data.status === 1) {
                        this.selectedSpecialItems = response.data.data || [];
                        this.originalSpecialItemIds = this.selectedSpecialItems.map(item => item.id);
                    }
                })
                .catch((error) => {
                    console.error("Failed to load special items", error);
                });
        },
        updateSpecialItems() {
            const specialItemIds = this.selectedSpecialItems.map(item => item.id);

            return axios.post(this.$apiUrl + '/home_slider_images/special_items/update', {
                special_item_ids: specialItemIds
            });
        },

    }
};
</script>
