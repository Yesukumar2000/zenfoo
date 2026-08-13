<template>
    <div class="page-heading">
        <div class="row">
            <div class="col-12 col-md-6 order-md-1 order-last">
                <h3>{{ page_title }}</h3>
            </div>
            <div class="col-12 col-md-6 order-md-2 order-first">
                <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                    <ol class="breadcrumb">
                        <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                        <li class="breadcrumb-item"><router-link to="/manage_categories">{{ __('manage_categories') }}</router-link></li>
                        <li class="breadcrumb-item active" aria-current="page">{{ page_title }}</li>
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
            <div class="col-12">
                <div class="card">
                    <div class="card-header">
                        <h4>{{ page_title }}</h4>
                        <router-link to="/manage_categories" class="btn btn-secondary float-end">
                            <i class="fa fa-arrow-left"></i> {{ __('back') }}
                        </router-link>
                    </div>
                    <div class="card-body">
                        <form ref="my-form" @submit.prevent="saveRecord">
                            <div class="row">
                                <div class="form-group col-md-6">
                                    <label>{{ __("parent_category") }}</label>
                                    <select v-model="parent_id" class="form-control form-select" v-html="parent_categories"></select>
                                    <span class="text-danger" v-if="id">{{ __('parent_category_note') }}</span>
                                </div>
                                <div class="form-group col-md-6">
                                    <label>{{ __('category_name') }}</label>
                                    <i class="text-danger">*</i>
                                    <input type="text" class="form-control" required v-model="name" :placeholder="__('enter_category_name')"  v-on:keyup="createSlug">
                                </div>
                                <div class="form-group col-md-6">
                                    <label>{{ __('slug') }}</label>
                                    <i class="text-danger">*</i>
                                    <input type="text" class="form-control" :placeholder="__('enter_category_slug')" v-model="slug">
                                </div>
                                <div class="form-group col-md-6">
                                    <label>{{ __('category_subtitle') }}</label><i class="text-danger">*</i>
                                    <input type="text" class="form-control" required v-model="subtitle" :placeholder="__('enter_category_subtitle')">
                                </div>
                                <div class="form-group col-md-12">
                                    <label>{{ __('image') }}</label><i class="text-danger">*</i>
                                    <p class="text-muted">Please choose square image of larger than 350px*350px &amp; smaller than 550px*550px.</p>
                                    <span v-if="error" class="error">{{ error }}</span>

                                    <input type="file" name="category_image" accept="image/*" v-on:change="handleFileUpload" ref="file_image" class="file-input">
                                    <div class="file-input-div bg-gray-100" @click="$refs.file_image.click()" @drop="dropFile" @dragover="$dragoverFile" @dragleave="$dragleaveFile">

                                        <template v-if="image && image.name !== ''">
                                            <label>Selected file name:- {{ image.name }}</label>
                                        </template>
                                        <template v-else>
                                            <label><i class="fa fa-cloud-upload-alt fa-2x"></i></label>
                                            <label>{{ __('drop_files_here_or_click_to_upload') }}</label>
                                        </template>

                                    </div>
                                    <div class="row mt-3" v-if="image_url">
                                        <div class="col-md-4">
                                            <img class="custom-image" :src="image_url" title='Category Image' alt='Category Image'/>
                                        </div>
                                    </div>
                                </div>

                                <div class="form-group col-md-6">
                                    <label>{{ __('meta_title') }} </label>
                                    <input type="text" class="form-control" v-model="meta_title" :placeholder="__('enter_meta_title')">
                                </div>
                                <div class="form-group col-md-6">
                                    <label>{{ __('meta_keywords') }} </label>
                                    <input type="text" class="form-control" v-model="meta_keywords" :placeholder="__('enter_meta_keywords')">
                                </div>
                                <div class="form-group col-md-12">
                                    <label>{{ __('schema_markup') }} <small :id="'schema_markup'" class="d-inline-flex mb-3 px-2 py-1 text-muted bg-secondary bg-opacity-10 border border-secondary border-opacity-10 rounded-2">
                                                    <i class="fa fa-info-circle"></i>
                                                </small>
                                                <b-popover :target="'schema_markup'" triggers="hover" placement="left">
                                                   <p>Schema markup, also known as structured data, is the language search engines use to read and understand the content on your pages. By language, we mean a semantic vocabulary (code) that helps search engines characterize and categorize the content of web pages. Learn more about schema markup and generate it for your website using the <a href="https://www.rankranger.com/schema-markup-generator" target="_blank">Rank Ranger Schema Markup Generator</a></p>
                                                </b-popover></label>
                                    <input type="text" class="form-control" v-model="schema_markup" :placeholder="__('enter_schema_markup')">
                                </div>

                                <div class="form-group col-md-12">
                                    <label>{{ __('meta_description') }} </label>
                                    <textarea type="text" class="form-control" v-model="meta_description" :placeholder="__('enter_meta_description')" rows="4"></textarea>
                                </div>
                                <div class="form-group col-md-6" v-if="id">
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

                            <div class="form-group">
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

                                <!-- show added types -->
                                <div class="mt-2">
                                    <span v-for="(t, index) in types" :key="index" class="badge badge-info mr-1">
                                        {{ t }}
                                        <i class="fa fa-times ml-1 text-danger" @click="removeType(index)" style="cursor:pointer"></i>
                                    </span>
                                </div>
                            </div>

                            <div class="form-group" v-if="id && fetchedTypes.length">
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
                                                        @click="startEdit(type)">
                                                    <i class="fa fa-edit"></i>
                                                </button>

                                                <button type="button"
                                                        v-if="editingTypeId === type.id"
                                                        class="btn btn-secondary btn-sm mr-2"
                                                        @click="cancelEdit">
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

                            <div class="form-group mt-4">
                                <button type="submit" class="btn btn-primary" :disabled="isLoading">
                                    {{ __('save') }}
                                    <b-spinner v-if="isLoading" small label="Spinning"></b-spinner>
                                </button>
                                <router-link to="/manage_categories" class="btn btn-secondary ml-2">{{ __('cancel') }}</router-link>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import axios from 'axios';

export default {
    data: function () {
        return {
            isLoading: false,
            image: null,

            types: [],
            tempType: "",
            fetchedTypes: [],

            editingTypeId: null,
            editingTypeName: "",

            id: null,
            name: null,
            slug: null,
            subtitle: null,
            image_url: null,
            status: 1,
            parent_id: 0,
            error: null,

            editedCategoryId: null,
            selectedCategories: [],
            parent_categories: null,

            meta_title: null,
            meta_keywords: null,
            schema_markup: null,
            meta_description: null,
        };
    },
    watch: {
        editedCategoryId(newVal) {
            this.selectedParentId = newVal;
        },
    },
    created: function() {
        this.getParentCategories();

        // Check if editing (id in route params)
        if (this.$route.params.id) {
            this.id = this.$route.params.id;
            this.getCategoryDetails();
            this.getCategoryTypes();
        }
    },
    computed: {
        page_title: function () {
            let title = this.id ? __('edit_category') : __('add_category');
            return title;
        },
    },

    methods: {
        getCategoryDetails() {
            axios.get(this.$apiUrl + '/categories/' + this.id)
                .then((response) => {
                    let data = response.data.data;
                    this.name = data.name;
                    this.slug = data.slug;
                    this.subtitle = data.subtitle;
                    this.image_url = data.image_url;
                    this.status = data.status;
                    this.parent_id = data.parent_id;
                    this.meta_title = data.meta_title;
                    this.meta_keywords = data.meta_keywords;
                    this.schema_markup = data.schema_markup;
                    this.meta_description = data.meta_description;
                })
                .catch(error => {
                    this.showError(__('failed_to_load_category_details'));
                });
        },

        createSlug() {
            if (this.name !== "") {
                let slug = this.name.toLowerCase()
                    .replace(/[^\w ]+/g, '')
                    .replace(/ +/g, '-');

                // Check for uniqueness
                axios.get(this.$apiUrl +`/categories/check-slug/${slug}`)
                    .then(response => {
                        if (response.data.unique) {
                            this.slug = slug;
                        } else {
                            this.slug = slug + '-' + response.data.count;
                        }
                    })
                    .catch(error => {
                        console.error('Error checking slug uniqueness: ' + error);
                    });
            }
        },

        updateType(id) {
            if (!this.editingTypeName.trim()) {
                alert("Type name cannot be empty");
                return;
            }

            axios.put(this.$apiUrl + '/category-types/' + id, {
                name: this.editingTypeName,
                category_id: this.id
            })
            .then(res => {
                if (res.data.status === 1) {
                    this.getCategoryTypes();
                    this.cancelEdit();
                } else {
                    alert(res.data.message);
                }
            })
            .catch(err => {
                alert("Update failed");
                console.error(err);
            });
        },

        cancelEdit() {
            this.editingTypeId = null;
            this.editingTypeName = "";
        },

        startEdit(type) {
            this.editingTypeId = type.id;
            this.editingTypeName = type.name;
        },

        deleteType(id) {
            if (!confirm("Are you sure you want to delete this type?")) return;

            axios.delete(this.$apiUrl + '/category-types/' + id)
                .then(res => {
                    if (res.data.status === 1) {
                        this.getCategoryTypes();
                    } else {
                        alert(res.data.message);
                    }
                })
                .catch(err => {
                    alert("Delete failed");
                    console.error(err);
                });
        },

        getCategoryTypes() {
            axios.get(this.$apiUrl + '/category-types', {
                params: { category_id: this.id }
            })
            .then(res => {
                if (res.data.status === 1) {
                    this.fetchedTypes = res.data.data;
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

        getParentCategories() {
            axios.get(this.$apiUrl + '/categories/options', {
                params: {
                    exclude_id: this.id || 0
                }
            })
            .then((response) => {
                this.parent_categories = response.data;
            });
        },

        dropFile(event) {
            event.preventDefault();
            this.$refs.file_image.files = event.dataTransfer.files;
            this.handleFileUpload();
            event.currentTarget.classList.add('bg-gray-100');
            event.currentTarget.classList.remove('bg-green-300');
        },

        handleFileUpload() {
            const file = this.$refs.file_image.files[0];

            this.error = null;

            if (!file) return;

            const validTypes = ["image/jpeg", "image/png", "image/jpg", "image/gif", "image/webp", "image/svg+xml"];
            if (!validTypes.includes(file.type)) {
                this.error = "Invalid file type. Please upload a JPEG, PNG, JPG,  GIF, WEBP or SVG image.";
                return;
            }

            const maxSize = 2 * 1024 * 1024; // 2MB
            if (file.size > maxSize) {
                this.error = "File size exceeds the maximum allowed limit (2MB).";
                return;
            }

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
            formData.append('slug', this.slug);
            formData.append('subtitle', this.subtitle);
            formData.append('image', this.image);
            formData.append('status', this.status);
            formData.append('parent_id', this.parent_id);
            formData.append('meta_title', this.meta_title);
            formData.append('meta_keywords', this.meta_keywords);
            formData.append('schema_markup', this.schema_markup);
            formData.append('meta_description', this.meta_description);
            let url = this.$apiUrl + '/categories/save';

            if (this.id) {
                url = this.$apiUrl + '/categories/update';
            }

            this.types.forEach(t => {
                formData.append('types[]', t);
            });

            axios.post(url, formData, {
                headers: {
                    'Content-Type': 'multipart/form-data'
                }
            }).then(res => {
                let data = res.data;
                if (data.status === 1) {
                    vm.showMessage('success', data.message);
                    vm.$router.push({path: '/manage_categories'});
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
    }
}
</script>

<style scoped>
.custom-image {
    max-width: 100%;
    height: auto;
    border: 1px solid #ddd;
    border-radius: 4px;
    padding: 5px;
}

.file-input {
    display: none;
}

.file-input-div {
    border: 2px dashed #ccc;
    border-radius: 4px;
    padding: 40px;
    text-align: center;
    cursor: pointer;
    transition: all 0.3s ease;
}

.file-input-div:hover {
    border-color: #9AC444;
    background-color: #f8f9fa;
}

.bg-gray-100 {
    background-color: #f8f9fa;
}

.bg-green-300 {
    background-color: #d4edda;
}
</style>