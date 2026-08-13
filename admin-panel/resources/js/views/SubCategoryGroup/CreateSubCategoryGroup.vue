<template>
    <div>
        <!-- Page Heading -->
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>{{ page_title }}</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item">
                                <router-link to="/manage_sub_category_group">Subcategory Groups</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                {{ page_title }}
                            </li>
                        </ol>
                    </nav>
                </div>
            </div>
        </div>

        <div class="row mb-3">
            <div class="col-12">
                <router-link to="/manage_sub_category_group" class="btn btn-secondary btn-sm">
                    <i class="fa fa-arrow-left me-1"></i> Back to List
                </router-link>
            </div>
        </div>

        <!-- Form Card -->
        <div class="card">
            <div class="card-header">
                <h4>{{ page_title }}</h4>
                <router-link to="/manage_sub_category_group" class="btn btn-secondary float-end">
                    <i class="fa fa-arrow-left"></i> {{ __('back') }}
                </router-link>
            </div>

            <div class="card-body">
                <form ref="my-form" @submit.prevent="saveGroup">
                    <div class="row">

                        <!-- Category Group Dropdown -->
                        <div class="form-group col-md-6">
                            <label>Category Group</label>
                            <i class="text-danger">*</i>
                            <select class="form-control form-select" v-model="category_group_id" required>
                                <option value="">Select Category Group</option>
                                <option v-for="cat in categoryGroups" :key="cat.id" :value="cat.id">
                                    {{ cat.name }}
                                </option>
                            </select>
                        </div>

                        <div class="form-group col-md-6">
                            <label>Group Name</label>
                            <i class="text-danger">*</i>
                            <input
                                type="text"
                                class="form-control"
                                v-model="name"
                                required
                                placeholder="Enter group name"
                            >
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
                                >
                                <label class="custom-control-label" for="childrenAllowedSwitch">
                                    {{ is_children_allowed == 1 ? 'Yes' : 'No' }}
                                </label>
                            </div>
                        </div>

                        <div class="form-group col-12 mt-3">
                            <label>Is Group</label><br>
                            <div class="form-check form-check-inline">
                                <input
                                    class="form-check-input"
                                    type="radio"
                                    name="is_group"
                                    value="1"
                                    v-model="is_group"
                                    id="is-group-yes"
                                >
                                <label class="form-check-label" for="is-group-yes">Yes</label>
                            </div>
                            <div class="form-check form-check-inline">
                                <input
                                    class="form-check-input"
                                    type="radio"
                                    name="is_group"
                                    value="0"
                                    v-model="is_group"
                                    id="is-group-no"
                                >
                                <label class="form-check-label" for="is-group-no">No</label>
                            </div>
                        </div>

                        <div class="form-group col-md-6">
                            <label>Image</label>
                            <input
                                type="file"
                                accept="image/png, image/jpeg, image/jpg, image/webp"
                                @change="onFileChange"
                                ref="fileInput"
                                class="form-control"
                            >
                            <small class="form-text text-muted">
                                Pick an image (at least 300 × 300 px), then crop it to a square in the next step.
                                <span v-if="id">Leave empty to keep current image.</span>
                            </small>
                        </div>

                        <!-- Image Preview -->
                        <div class="form-group col-md-12" v-if="preview_image_url || existing_image_url">
                            <label>Image Preview (1:1 — exactly how it appears in the app)</label>
                            <div>
                                <img
                                    :src="preview_image_url || existing_image_url"
                                    alt="Subcategory Group Image"
                                    style="width: 200px; height: 200px; object-fit: cover; border: 1px solid #ddd; padding: 5px; border-radius: 4px;"
                                >
                            </div>
                        </div>

                        <!-- Cropper Modal (teleported to <body> via JS to escape transformed ancestors) -->
                        <div
                            v-if="showCropper"
                            ref="cropperBackdrop"
                            class="cropper-modal-backdrop"
                            @click.self="cancelCrop"
                        >
                            <div class="cropper-modal">
                                <div class="cropper-modal-header">
                                    <h5 class="m-0">
                                        <i class="fa fa-crop me-2"></i>
                                        Crop Image to Square
                                    </h5>
                                    <button type="button" class="cropper-close-btn" @click="cancelCrop" aria-label="Close">&times;</button>
                                </div>
                                <div class="cropper-modal-body">
                                    <div class="cropper-instructions">
                                        <strong>How to use:</strong>
                                        <ul>
                                            <li><b>Drag the square</b> to choose what part of the image to keep</li>
                                            <li><b>Drag the corners/edges</b> to resize it (min 200 × 200 to keep it sharp)</li>
                                            <li>The square is locked to 1:1 — what's inside it becomes your final image</li>
                                        </ul>
                                    </div>
                                    <div v-if="cropperError" class="cropper-error">
                                        <i class="fa fa-exclamation-triangle"></i>
                                        {{ cropperError }}
                                    </div>
                                    <div class="cropper-wrapper">
                                        <img ref="cropperImage" :src="cropperSrc" alt="To crop">
                                    </div>
                                </div>
                                <div class="cropper-modal-footer">
                                    <button type="button" class="btn cropper-btn-cancel" @click="cancelCrop">
                                        <i class="fa fa-times"></i> Cancel
                                    </button>
                                    <button type="button" class="btn cropper-btn-apply" @click="applyCrop" :disabled="!cropperReady">
                                        <i class="fa fa-check"></i> Apply Crop
                                    </button>
                                </div>
                            </div>
                        </div>

                        <div class="form-group col-12 mt-3">
                            <label>Select Subcategories</label>
                            <div class="border rounded p-3" style="max-height: 300px; overflow-y: auto;">
                                <div
                                    v-for="sub in subcategories"
                                    :key="sub.id"
                                    class="form-check mb-2"
                                >
                                    <input
                                        type="checkbox"
                                        :id="`sub-${sub.id}`"
                                        :value="sub.id"
                                        v-model="selectedSubcategories"
                                        class="form-check-input"
                                    />
                                    <label class="form-check-label" :for="`sub-${sub.id}`">
                                        {{ sub.name }}
                                    </label>
                                </div>
                                <div v-if="subcategories.length === 0" class="text-muted">
                                    No subcategories available
                                </div>
                            </div>
                        </div>

                    </div>

                    <!-- Form Actions -->
                    <div class="row mt-4">
                        <div class="col-12 text-end">
                            <router-link to="/manage_sub_category_group" class="btn btn-secondary me-2">
                                <i class="fa fa-times"></i> Cancel
                            </router-link>
                            <button type="submit" class="btn btn-primary" :disabled="isLoading">
                                <i class="fa fa-save"></i>
                                {{ isLoading ? 'Saving...' : (id ? 'Update' : 'Save') }}
                                <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</template>

<script>
import axios from 'axios';

export default {
    name: 'CreateSubCategoryGroup',
    props: ['id'],
    data() {
        return {
            name: '',
            is_group: 1,
            is_children_allowed: 1,
            category_group_id: '',
            subcategories: [],
            categoryGroups: [],
            image: null,
            existing_image_url: null,
            preview_image_url: null,
            selectedSubcategories: [],
            isLoading: false,
            // cropper state
            showCropper: false,
            cropperSrc: '',
            cropperInstance: null,
            cropperReady: false,
            cropperError: '',
            originalFileName: 'image.png'
        }
    },
    computed: {
        page_title() {
            return this.id ? 'Edit Subcategory Group' : 'Add Subcategory Group';
        }
    },
    watch: {
        showCropper(val) {
            if (val) {
                // Teleport the modal to <body> so position:fixed works correctly
                // even if some ancestor in the admin layout has a `transform`
                // (transformed ancestors break position:fixed positioning).
                this.$nextTick(() => {
                    if (this.$refs.cropperBackdrop && this.$refs.cropperBackdrop.parentNode !== document.body) {
                        document.body.appendChild(this.$refs.cropperBackdrop);
                    }
                    // Lock background scroll while the modal is open
                    document.body.style.overflow = 'hidden';
                    // Initialize the cropper after the image is in the DOM
                    this.initCropper();
                });
            } else {
                document.body.style.overflow = '';
            }
        }
    },
    created() {
        this.fetchSubcategories();
        this.fetchCategoryGroups();
        this.loadCropperAssets();

        // If editing, load the subcategory group data
        if (this.id) {
            this.loadSubCategoryGroup();
        }
    },
    beforeDestroy() {
        this.destroyCropper();
        if (this.preview_image_url) {
            URL.revokeObjectURL(this.preview_image_url);
        }
        // Always restore body scroll in case the component is destroyed while the modal is open
        document.body.style.overflow = '';
        // If we teleported the backdrop to body, clean it up
        if (this.$refs.cropperBackdrop && this.$refs.cropperBackdrop.parentNode === document.body) {
            document.body.removeChild(this.$refs.cropperBackdrop);
        }
    },
    methods: {
        loadCropperAssets() {
            // Load Cropper.js CSS
            if (!document.getElementById('cropperjs-css')) {
                const link = document.createElement('link');
                link.id = 'cropperjs-css';
                link.rel = 'stylesheet';
                link.href = 'https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.1/cropper.min.css';
                document.head.appendChild(link);
            }
            // Load Cropper.js JS
            if (!window.Cropper && !document.getElementById('cropperjs-js')) {
                const script = document.createElement('script');
                script.id = 'cropperjs-js';
                script.src = 'https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.6.1/cropper.min.js';
                document.head.appendChild(script);
            }
        },
        destroyCropper() {
            if (this.cropperInstance) {
                this.cropperInstance.destroy();
                this.cropperInstance = null;
            }
            this.cropperReady = false;
        },
        cancelCrop() {
            this.destroyCropper();
            this.showCropper = false;
            this.cropperSrc = '';
            this.cropperError = '';
            // clear the file input so the same file can be reselected if needed
            if (this.$refs.fileInput) {
                this.$refs.fileInput.value = '';
            }
        },
        applyCrop() {
            if (!this.cropperInstance) return;

            // Enforce a minimum source-pixel crop size of 200 × 200 so the
            // final output stays reasonably sharp after resizing.
            const data = this.cropperInstance.getData(true); // rounded source-pixel coordinates
            if (data.width < 200 || data.height < 200) {
                this.cropperError =
                    'Crop area is too small. Please select at least 200 × 200 (current: ' +
                    Math.round(data.width) + ' × ' + Math.round(data.height) + ').';
                return;
            }
            // Clear any previous inline error
            this.cropperError = '';

            // Output a 600x600 square. We use PNG so transparency from the
            // source image is preserved (JPEG would fill transparent areas
            // with black, which would break category icons in the app).
            // `fillColor: 'transparent'` keeps the canvas alpha channel intact.
            const canvas = this.cropperInstance.getCroppedCanvas({
                width: 600,
                height: 600,
                fillColor: 'transparent',
                imageSmoothingEnabled: true,
                imageSmoothingQuality: 'high'
            });

            if (!canvas) {
                this.showMessage('error', 'Crop failed, please try again.');
                return;
            }

            canvas.toBlob((blob) => {
                if (!blob) {
                    this.showMessage('error', 'Crop failed, please try again.');
                    return;
                }
                // revoke previous preview to avoid leaks
                if (this.preview_image_url) {
                    URL.revokeObjectURL(this.preview_image_url);
                }
                // wrap blob into a File so the backend sees a proper filename
                const cleanName = (this.originalFileName || 'image').replace(/\.[^.]+$/, '') + '.png';
                this.image = new File([blob], cleanName, { type: 'image/png' });
                this.preview_image_url = URL.createObjectURL(this.image);

                this.destroyCropper();
                this.showCropper = false;
                this.cropperSrc = '';
            }, 'image/png');
        },
        fetchSubcategories() {
            axios.get(this.$apiUrl + '/subcategories/all')
                .then(res => {
                    this.subcategories = res.data.data;
                })
                .catch(() => {
                    this.subcategories = [];
                });
        },
        fetchCategoryGroups() {
            axios.get(this.$apiUrl + '/group-category')
                .then(res => {
                    this.categoryGroups = res.data.data;
                })
                .catch(() => {
                    this.categoryGroups = [];
                });
        },
        loadSubCategoryGroup() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/group-sub-category/' + this.id + '/edit')
                .then(response => {
                    if (response.data.status === 1) {
                        const data = response.data.data;
                        this.name = data.name;
                        this.is_group = data.is_group;
                        this.is_children_allowed = data.is_children_allowed;
                        this.category_group_id = data.category_group_id;
                        this.existing_image_url = data.image_url;

                        if (data.subcategory_ids) {
                            this.selectedSubcategories = data.subcategory_ids.split(',');
                        }
                    }
                    this.isLoading = false;
                })
                .catch(err => {
                    this.isLoading = false;
                    this.showMessage('error', err.message || "Failed to load subcategory group");
                });
        },
        onFileChange(event) {
            const file = event.target.files[0];
            if (!file) return;

            // Validate type
            const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
            if (!allowed.includes(file.type)) {
                this.showMessage('error', 'Only JPG, PNG or WebP images are allowed.');
                event.target.value = '';
                return;
            }

            // Validate size (max 5 MB before crop)
            if (file.size > 5 * 1024 * 1024) {
                this.showMessage('error', 'Image must be smaller than 5 MB.');
                event.target.value = '';
                return;
            }

            this.originalFileName = file.name;

            // Read as data URL, check dimensions, then open the cropper
            const reader = new FileReader();
            reader.onload = (e) => {
                const dataUrl = e.target.result;

                // Pre-check the image dimensions before opening the cropper.
                // We need at least 300 × 300 source pixels so the 200 × 200
                // minimum crop area actually works.
                const probe = new Image();
                probe.onload = () => {
                    if (probe.naturalWidth < 300 || probe.naturalHeight < 300) {
                        this.showMessage(
                            'error',
                            'Image is too small (' + probe.naturalWidth + ' × ' + probe.naturalHeight +
                            '). Please upload an image at least 300 × 300 pixels.'
                        );
                        if (this.$refs.fileInput) {
                            this.$refs.fileInput.value = '';
                        }
                        return;
                    }
                    this.cropperSrc = dataUrl;
                    // The `showCropper` watcher takes care of teleporting and initialising Cropper
                    this.showCropper = true;
                };
                probe.onerror = () => {
                    this.showMessage('error', 'Could not read image. Please try a different file.');
                    if (this.$refs.fileInput) {
                        this.$refs.fileInput.value = '';
                    }
                };
                probe.src = dataUrl;
            };
            reader.readAsDataURL(file);
        },
        initCropper() {
            if (!window.Cropper) {
                // Cropper.js still loading from CDN — retry in a moment
                setTimeout(() => this.initCropper(), 150);
                return;
            }
            const imgEl = this.$refs.cropperImage;
            if (!imgEl) {
                setTimeout(() => this.initCropper(), 100);
                return;
            }
            this.destroyCropper();
            this.cropperInstance = new window.Cropper(imgEl, {
                aspectRatio: 1,           // lock to 1:1 square
                viewMode: 2,              // image is always fully contained in the box (no overflow / no bottom cut-off)
                dragMode: 'none',         // dragging inside the box does nothing — only the crop box itself is interactive
                autoCropArea: 0.85,       // start with the crop box at 85% of the image
                background: true,
                responsive: true,
                modal: true,
                guides: true,
                center: true,
                highlight: true,
                cropBoxMovable: true,
                cropBoxResizable: true,
                movable: false,           // image stays put — user only adjusts the crop box
                zoomable: false,          // no accidental wheel-zoom
                scalable: false,
                rotatable: false,
                toggleDragModeOnDblclick: false,
                minContainerWidth: 200,
                minContainerHeight: 200,
                ready: () => {
                    this.cropperReady = true;
                }
            });
        },
        saveGroup() {
            this.isLoading = true;
            const formData = new FormData();

            if (this.id) formData.append('id', this.id);
            formData.append('name', this.name);
            formData.append('is_group', this.is_group);
            formData.append('is_children_allowed', this.is_children_allowed);
            formData.append('status', 1);
            formData.append('category_group_id', this.category_group_id);
            formData.append('subcategory_ids', this.selectedSubcategories.join(','));

            if (this.image) formData.append('image', this.image);

            let url = this.id
                ? this.$apiUrl + '/group-sub-category/update'
                : this.$apiUrl + '/group-sub-category/save';

            axios.post(url, formData)
                .then(res => {
                    if (res.data.status === 1) {
                        this.showMessage('success', res.data.message);
                        this.$router.push({ path: '/manage_sub_category_group' });
                    } else {
                        this.showMessage('error', res.data.message);
                    }
                    this.isLoading = false;
                })
                .catch(err => {
                    this.isLoading = false;
                    this.showMessage('error', err.message || "Something went wrong!");
                });
        },
        showMessage(type, message) {
            // Errors stay visible until the user dismisses them.
            // Success messages auto-close so they don't block the flow.
            if (type === 'error') {
                this.$swal.fire({
                    icon: 'error',
                    title: 'Oops...',
                    text: message,
                    confirmButtonText: 'OK',
                    confirmButtonColor: '#d33'
                });
            } else {
                this.$swal.fire({
                    icon: type,
                    title: message,
                    timer: 1800,
                    showConfirmButton: false
                });
            }
        }
    }
}
</script>

<style scoped>
.form-check-inline {
    margin-right: 20px;
}

.custom-control-switch {
    padding-left: 2.5rem;
}

.custom-control-input {
    width: 3rem;
}

/* Cropper modal */
.cropper-modal-backdrop {
    position: fixed !important;
    top: 0 !important;
    left: 0 !important;
    right: 0 !important;
    bottom: 0 !important;
    width: 100vw !important;
    height: 100vh !important;
    background: rgba(15, 23, 42, 0.75);
    backdrop-filter: blur(4px);
    -webkit-backdrop-filter: blur(4px);
    z-index: 999999 !important;
    padding: 0;
    margin: 0;
    animation: cropperFadeIn 0.2s ease-out;
}

@keyframes cropperFadeIn {
    from { opacity: 0; }
    to   { opacity: 1; }
}

@keyframes cropperSlideUp {
    from { transform: translate(-50%, -45%); opacity: 0; }
    to   { transform: translate(-50%, -50%); opacity: 1; }
}

.cropper-modal {
    /* Bulletproof centering — independent of any parent layout */
    position: fixed !important;
    top: 50% !important;
    left: 50% !important;
    transform: translate(-50%, -50%) !important;
    margin: 0 !important;
    background: #ffffff;
    border-radius: 14px;
    width: calc(100% - 40px);
    max-width: 720px;
    height: 100vh;
    max-height: 100vh;
    display: flex;
    flex-direction: column;
    /* IMPORTANT: header & footer stay fixed in size, body scrolls.
       This is what lets the user reach all content even on short screens. */
    box-shadow: 0 25px 60px rgba(0, 0, 0, 0.45),
                0 0 0 1px rgba(255, 255, 255, 0.1);
    overflow: hidden;
    z-index: 1000000 !important;
    animation: cropperSlideUp 0.25s ease-out;
}

.cropper-modal-header,
.cropper-modal-footer {
    flex: 0 0 auto;     /* fixed — never shrink */
}

.cropper-modal-body {
    flex: 1 1 auto;     /* take remaining space */
    overflow-y: auto;   /* scroll inside the modal if content is taller */
    min-height: 0;      /* required for flex children to actually scroll */
}

.cropper-modal-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 18px 24px;
    background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
    color: #ffffff;
    border-bottom: none;
}

.cropper-modal-header h5 {
    color: #ffffff;
    font-weight: 600;
    font-size: 1.1rem;
    letter-spacing: 0.2px;
}

.cropper-close-btn {
    background: rgba(255, 255, 255, 0.18);
    border: none;
    color: #ffffff;
    width: 32px;
    height: 32px;
    border-radius: 50%;
    font-size: 22px;
    line-height: 1;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background 0.15s ease;
}

.cropper-close-btn:hover {
    background: rgba(255, 255, 255, 0.32);
}

.cropper-modal-body {
    padding: 16px 20px;
    background: #f8fafc;
    display: flex;
    flex-direction: column;
}

.cropper-instructions {
    background: #eef2ff;
    border: 1px solid #c7d2fe;
    color: #3730a3;
    border-radius: 8px;
    padding: 8px 12px;
    margin-bottom: 12px;
    font-size: 0.8rem;
    line-height: 1.45;
}

.cropper-instructions strong {
    display: block;
    margin-bottom: 2px;
}

.cropper-instructions ul {
    margin: 0;
    padding-left: 18px;
}

.cropper-instructions li {
    margin-bottom: 1px;
}

.cropper-error {
    background: #fef2f2;
    border: 1px solid #fecaca;
    color: #b91c1c;
    border-radius: 8px;
    padding: 10px 14px;
    margin-bottom: 12px;
    font-size: 0.85rem;
    font-weight: 500;
    display: flex;
    align-items: center;
    gap: 8px;
    animation: cropperShake 0.35s ease;
}

@keyframes cropperShake {
    0%, 100% { transform: translateX(0); }
    25%      { transform: translateX(-4px); }
    75%      { transform: translateX(4px); }
}

.cropper-wrapper {
    width: 100%;
    /* Fill remaining vertical space inside the modal body */
    flex: 1 1 auto;
    min-height: 280px;
    background: #1e293b;
    border-radius: 10px;
    overflow: hidden;
    box-shadow: inset 0 2px 8px rgba(0, 0, 0, 0.2);
}

.cropper-wrapper img {
    display: block;
    max-width: 100%;
    /* Cropper.js replaces this img with its own canvas, but it needs a normal block element to start */
}

.cropper-modal-footer {
    display: flex;
    justify-content: flex-end;
    gap: 12px;
    padding: 16px 24px;
    background: #ffffff;
    border-top: 1px solid #e2e8f0;
}

.cropper-btn-cancel {
    background: #f1f5f9;
    color: #475569 !important;
    border: 1px solid #cbd5e1;
    padding: 8px 20px;
    font-weight: 500;
}

.cropper-btn-cancel:hover {
    background: #e2e8f0;
    color: #334155 !important;
}

.cropper-btn-apply {
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    color: #ffffff;
    border: none;
    padding: 8px 22px;
    font-weight: 600;
    box-shadow: 0 4px 12px rgba(16, 185, 129, 0.35);
    transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.cropper-btn-apply:hover:not(:disabled) {
    transform: translateY(-1px);
    box-shadow: 0 6px 16px rgba(16, 185, 129, 0.45);
    color: #ffffff;
}

.cropper-btn-apply:disabled {
    opacity: 0.6;
    cursor: not-allowed;
}
</style>
