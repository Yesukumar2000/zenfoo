<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>Training Modules</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">Training Modules</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/dashboard" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to Dashboard
                    </router-link>
                </div>
            </div>

            <section class="section">
                <div class="card">
                    <div class="card-header mb-3">
                        <!-- Tabs Header -->
                        <ul class="nav nav-tabs card-header-tabs" role="tablist">
                            <li class="nav-item">
                                <a
                                    class="nav-link"
                                    :class="{ active: activeTab === 'topics' }"
                                    href="#"
                                    @click.prevent="switchTab('topics')"
                                >
                                    Topics
                                </a>
                            </li>
                            <li class="nav-item">
                                <a
                                    class="nav-link"
                                    :class="{ active: activeTab === 'videos' }"
                                    href="#"
                                    @click.prevent="switchTab('videos')"
                                >
                                    Videos
                                </a>
                            </li>
                        </ul>
                    </div>
                    <div class="card-body">
                        <!-- Topics Tab Content -->
                        <div v-if="activeTab === 'topics'">
                            <div class="d-flex justify-content-between align-items-center mb-3">
                                <h5 class="mb-0">Learning Topics</h5>
                                <button class="btn btn-primary" @click="openTopicModal(null)">
                                    <i class="fa fa-plus me-1"></i> Add Topic
                                </button>
                            </div>

                            <!-- Filters and Search -->
                            <b-row class="mb-3">
                                <b-col md="3">
                                    <h6 class="box-title">Filter by Status</h6>
                                    <select v-model="topicFilterStatus" @change="fetchTopics()" class="form-control form-select">
                                        <option value="">All Status</option>
                                        <option value="1">Active</option>
                                        <option value="0">Inactive</option>
                                    </select>
                                </b-col>
                                <b-col md="3" offset-md="5">
                                    <h6 class="box-title">{{ __('search') }}</h6>
                                    <b-form-input id="topic-filter-input" v-model="topicFilter" type="search"
                                                  :placeholder="__('search')"></b-form-input>
                                </b-col>
                                <b-col md="1" class="text-center">
                                    <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="fetchTopics()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i>
                                    </button>
                                </b-col>
                            </b-row>

                            <b-table
                                :items="topics"
                                :fields="topicFields"
                                :current-page="topicCurrentPage"
                                :per-page="perPage"
                                :filter="topicFilter"
                                :filter-included-fields="['name', 'description']"
                                :sort-by.sync="topicSortBy"
                                :sort-desc.sync="topicSortDesc"
                                :bordered="true"
                                :busy="isLoadingTopics"
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
                                    <img v-if="row.item.image_url" :src="row.item.image_url" alt="Topic Image" class="rounded" style="width: 50px; height: 50px; object-fit: cover;">
                                    <span v-else class="text-muted">No Image</span>
                                </template>

                                <template #cell(status)="row">
                                    <b-form-checkbox
                                        v-model="row.item.status"
                                        :value="1"
                                        :unchecked-value="0"
                                        switch
                                        @change="updateTopicStatus(row.item)"
                                    ></b-form-checkbox>
                                </template>

                                <template #cell(videos_count)="row">
                                    <span class="badge bg-info">{{ row.item.videos_count || 0 }} videos</span>
                                </template>

                                <template #cell(actions)="row">
                                    <button class="btn btn-sm btn-primary me-1" @click="openTopicModal(row.item)" v-b-tooltip.hover title="Edit">
                                        <i class="fa fa-pencil-alt"></i>
                                    </button>
                                    <button class="btn btn-sm btn-danger" @click="deleteTopic(row.item)" v-b-tooltip.hover title="Delete">
                                        <i class="fa fa-trash"></i>
                                    </button>
                                </template>
                            </b-table>

                            <!-- Pagination -->
                            <b-row>
                                <b-col md="2" class="my-1">
                                    <b-form-group
                                        :label="__('per_page')"
                                        label-for="topic-per-page-select"
                                        label-align-sm="right"
                                        label-size="sm"
                                        class="mb-0">
                                        <b-form-select
                                            id="topic-per-page-select"
                                            v-model="perPage"
                                            :options="pageOptions"
                                            size="sm"
                                            class="form-control form-select"
                                        ></b-form-select>
                                    </b-form-group>
                                </b-col>
                                <b-col md="4" class="my-1" offset-md="6">
                                    <b-pagination
                                        v-model="topicCurrentPage"
                                        :total-rows="topicTotalRows"
                                        :per-page="perPage"
                                        align="fill"
                                        size="sm"
                                        class="my-0"
                                    ></b-pagination>
                                </b-col>
                            </b-row>
                        </div>

                        <!-- Videos Tab Content -->
                        <div v-if="activeTab === 'videos'">
                            <div class="d-flex justify-content-between align-items-center mb-3">
                                <h5 class="mb-0">Learning Videos</h5>
                                <button class="btn btn-primary" @click="openVideoModal(null)">
                                    <i class="fa fa-plus me-1"></i> Add Video
                                </button>
                            </div>

                            <!-- Filters and Search -->
                            <b-row class="mb-3">
                                <b-col md="3">
                                    <h6 class="box-title">Filter by Topic</h6>
                                    <select v-model="videoFilterTopic" @change="fetchVideos()" class="form-control form-select">
                                        <option value="">All Topics</option>
                                        <option v-for="topic in topics" :key="topic.id" :value="topic.id">{{ topic.name }}</option>
                                    </select>
                                </b-col>
                                <b-col md="2">
                                    <h6 class="box-title">Filter by Status</h6>
                                    <select v-model="videoFilterStatus" @change="fetchVideos()" class="form-control form-select">
                                        <option value="">All Status</option>
                                        <option value="1">Active</option>
                                        <option value="0">Inactive</option>
                                    </select>
                                </b-col>
                                <b-col md="3" offset-md="3">
                                    <h6 class="box-title">{{ __('search') }}</h6>
                                    <b-form-input id="video-filter-input" v-model="videoFilter" type="search"
                                                  :placeholder="__('search')"></b-form-input>
                                </b-col>
                                <b-col md="1" class="text-center">
                                    <button class="btn btn-primary btn_refresh" v-b-tooltip.hover :title="__('refresh')" @click="fetchVideos()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i>
                                    </button>
                                </b-col>
                            </b-row>

                            <b-table
                                :items="videos"
                                :fields="videoFields"
                                :current-page="videoCurrentPage"
                                :per-page="perPage"
                                :filter="videoFilter"
                                :filter-included-fields="['title', 'description', 'topic_name']"
                                :sort-by.sync="videoSortBy"
                                :sort-desc.sync="videoSortDesc"
                                :bordered="true"
                                :busy="isLoadingVideos"
                                stacked="md"
                                show-empty
                                small>

                                <template #table-busy>
                                    <div class="text-center text-black my-2">
                                        <b-spinner class="align-middle"></b-spinner>
                                        <strong>{{ __('loading') }}...</strong>
                                    </div>
                                </template>

                                <template #cell(thumbnail)="row">
                                    <img v-if="row.item.thumbnail_url" :src="row.item.thumbnail_url" alt="Thumbnail" class="rounded" style="width: 80px; height: 50px; object-fit: cover;">
                                    <span v-else class="text-muted">No Thumbnail</span>
                                </template>

                                <template #cell(video_type)="row">
                                    <span class="badge" :class="getVideoTypeBadgeClass(row.item.video_type)">
                                        {{ row.item.video_type }}
                                    </span>
                                </template>

                                <template #cell(duration)="row">
                                    <span v-if="row.item.formatted_duration">{{ row.item.formatted_duration }}</span>
                                    <span v-else class="text-muted">-</span>
                                </template>

                                <template #cell(status)="row">
                                    <b-form-checkbox
                                        v-model="row.item.status"
                                        :value="1"
                                        :unchecked-value="0"
                                        switch
                                        @change="updateVideoStatus(row.item)"
                                    ></b-form-checkbox>
                                </template>

                                <template #cell(actions)="row">
                                    <button class="btn btn-sm btn-info me-1" @click="previewVideo(row.item)" v-b-tooltip.hover title="Preview">
                                        <i class="fa fa-play"></i>
                                    </button>
                                    <button class="btn btn-sm btn-primary me-1" @click="openVideoModal(row.item)" v-b-tooltip.hover title="Edit">
                                        <i class="fa fa-pencil-alt"></i>
                                    </button>
                                    <button class="btn btn-sm btn-danger" @click="deleteVideo(row.item)" v-b-tooltip.hover title="Delete">
                                        <i class="fa fa-trash"></i>
                                    </button>
                                </template>
                            </b-table>

                            <!-- Pagination -->
                            <b-row>
                                <b-col md="2" class="my-1">
                                    <b-form-group
                                        :label="__('per_page')"
                                        label-for="video-per-page-select"
                                        label-align-sm="right"
                                        label-size="sm"
                                        class="mb-0">
                                        <b-form-select
                                            id="video-per-page-select"
                                            v-model="perPage"
                                            :options="pageOptions"
                                            size="sm"
                                            class="form-control form-select"
                                        ></b-form-select>
                                    </b-form-group>
                                </b-col>
                                <b-col md="4" class="my-1" offset-md="6">
                                    <b-pagination
                                        v-model="videoCurrentPage"
                                        :total-rows="videoTotalRows"
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
            </section>
        </div>

        <!-- Topic Modal -->
        <b-modal
            id="topic-modal"
            v-model="showTopicModal"
            :title="editingTopic ? 'Edit Topic' : 'Add Topic'"
            @hidden="resetTopicForm"
            no-close-on-backdrop
        >
            <form @submit.prevent="saveTopic">
                <div class="mb-3">
                    <label class="form-label">Name <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" v-model="topicForm.name" required placeholder="Enter topic name">
                </div>
                <div class="mb-3">
                    <label class="form-label">Description</label>
                    <textarea class="form-control" v-model="topicForm.description" rows="3" placeholder="Enter description"></textarea>
                </div>
                <div class="mb-3">
                    <label class="form-label">Image</label>
                    <input type="file" class="form-control" @change="handleTopicImage" accept="image/*">
                    <div v-if="topicForm.existingImage" class="mt-2">
                        <img :src="topicForm.existingImage" alt="Current Image" class="rounded" style="width: 100px; height: 100px; object-fit: cover;">
                        <small class="d-block text-muted">Current image</small>
                    </div>
                </div>
                <div class="mb-3">
                    <label class="form-label">Sort Order</label>
                    <input type="number" class="form-control" v-model="topicForm.sort_order" min="0" placeholder="0">
                </div>
                <div class="mb-3">
                    <label class="form-label">Status</label>
                    <select class="form-control form-select" v-model="topicForm.status">
                        <option value="1">Active</option>
                        <option value="0">Inactive</option>
                    </select>
                </div>
            </form>
            <template #modal-footer>
                <b-button variant="secondary" @click="showTopicModal = false">Cancel</b-button>
                <b-button variant="primary" @click="saveTopic" :disabled="isSavingTopic">
                    {{ isSavingTopic ? 'Saving...' : 'Save' }}
                    <b-spinner v-if="isSavingTopic" small></b-spinner>
                </b-button>
            </template>
        </b-modal>

        <!-- Video Modal -->
        <b-modal
            id="video-modal"
            v-model="showVideoModal"
            :title="editingVideo ? 'Edit Video' : 'Add Video'"
            @hidden="resetVideoForm"
            no-close-on-backdrop
            size="lg"
        >
            <form @submit.prevent="saveVideo">
                <div class="mb-3">
                    <label class="form-label">Topic <span class="text-danger">*</span></label>
                    <select class="form-control form-select" v-model="videoForm.topic_id" required>
                        <option value="">Select Topic</option>
                        <option v-for="topic in topics" :key="topic.id" :value="topic.id">{{ topic.name }}</option>
                    </select>
                </div>
                <div class="mb-3">
                    <label class="form-label">Title <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" v-model="videoForm.title" required placeholder="Enter video title">
                </div>
                <div class="mb-3">
                    <label class="form-label">Description</label>
                    <textarea class="form-control" v-model="videoForm.description" rows="2" placeholder="Enter description"></textarea>
                </div>
                <div class="mb-3">
                    <label class="form-label">Video File <span class="text-danger" v-if="!editingVideo">*</span></label>
                    <input type="file" class="form-control" @change="handleVideoFile" accept="video/*">
                    <small class="text-muted">Max file size: 100MB. Supported formats: mp4, mov, avi, wmv, flv, mkv</small>
                    <div v-if="videoForm.existingVideo" class="mt-2">
                        <small class="text-success"><i class="fa fa-check-circle me-1"></i>Video already uploaded</small>
                    </div>
                </div>
                <div class="mb-3">
                    <label class="form-label">Thumbnail</label>
                    <input type="file" class="form-control" @change="handleVideoThumbnail" accept="image/*">
                    <div v-if="videoForm.existingThumbnail" class="mt-2">
                        <img :src="videoForm.existingThumbnail" alt="Current Thumbnail" class="rounded" style="width: 120px; height: 70px; object-fit: cover;">
                        <small class="d-block text-muted">Current thumbnail</small>
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Sort Order</label>
                        <input type="number" class="form-control" v-model="videoForm.sort_order" min="0" placeholder="0">
                    </div>
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Status</label>
                        <select class="form-control form-select" v-model="videoForm.status">
                            <option value="1">Active</option>
                            <option value="0">Inactive</option>
                        </select>
                    </div>
                </div>
            </form>
            <template #modal-footer>
                <b-button variant="secondary" @click="showVideoModal = false">Cancel</b-button>
                <b-button variant="primary" @click="saveVideo" :disabled="isSavingVideo">
                    {{ isSavingVideo ? 'Saving...' : 'Save' }}
                    <b-spinner v-if="isSavingVideo" small></b-spinner>
                </b-button>
            </template>
        </b-modal>

        <!-- Video Preview Modal -->
        <b-modal
            id="video-preview-modal"
            v-model="showPreviewModal"
            :title="previewVideoData ? previewVideoData.title : 'Video Preview'"
            size="lg"
            hide-footer
            @hidden="closePreview"
        >
            <div v-if="previewVideoData" class="text-center">
                <div v-if="previewVideoData.video_type === 'youtube'" class="ratio ratio-16x9">
                    <iframe :src="getYoutubeEmbedUrl(previewVideoData.video_url)" allowfullscreen></iframe>
                </div>
                <div v-else-if="previewVideoData.video_type === 'vimeo'" class="ratio ratio-16x9">
                    <iframe :src="getVimeoEmbedUrl(previewVideoData.video_url)" allowfullscreen></iframe>
                </div>
                <div v-else>
                    <video :src="previewVideoData.video_url" controls class="w-100" style="max-height: 400px;"></video>
                </div>
                <p class="mt-3 text-muted" v-if="previewVideoData.description">{{ previewVideoData.description }}</p>
            </div>
        </b-modal>
    </div>
</template>

<script>
export default {
    name: 'TrainingModules',
    data() {
        return {
            activeTab: 'topics',

            // Topics
            topics: [],
            isLoadingTopics: false,
            topicFilter: null,
            topicFilterStatus: '',
            topicCurrentPage: 1,
            topicTotalRows: 0,
            topicSortBy: 'sort_order',
            topicSortDesc: false,
            topicFields: [
                { key: 'id', label: 'ID', sortable: true },
                { key: 'image', label: 'Image', sortable: false },
                { key: 'name', label: 'Name', sortable: true },
                { key: 'description', label: 'Description', sortable: false },
                { key: 'videos_count', label: 'Videos', sortable: true, class: 'text-center' },
                { key: 'sort_order', label: 'Order', sortable: true, class: 'text-center' },
                { key: 'status', label: 'Status', sortable: true, class: 'text-center' },
                { key: 'actions', label: 'Actions', class: 'text-center' }
            ],

            // Videos
            videos: [],
            isLoadingVideos: false,
            videoFilter: null,
            videoFilterTopic: '',
            videoFilterStatus: '',
            videoCurrentPage: 1,
            videoTotalRows: 0,
            videoSortBy: 'sort_order',
            videoSortDesc: false,
            videoFields: [
                { key: 'id', label: 'ID', sortable: true },
                { key: 'thumbnail', label: 'Thumbnail', sortable: false },
                { key: 'title', label: 'Title', sortable: true },
                { key: 'topic_name', label: 'Topic', sortable: true },
                { key: 'video_type', label: 'Type', sortable: true, class: 'text-center' },
                { key: 'duration', label: 'Duration', sortable: true, class: 'text-center' },
                { key: 'sort_order', label: 'Order', sortable: true, class: 'text-center' },
                { key: 'status', label: 'Status', sortable: true, class: 'text-center' },
                { key: 'actions', label: 'Actions', class: 'text-center' }
            ],

            // Pagination
            perPage: this.$perPage || 10,
            pageOptions: this.$pageOptions || [5, 10, 15, 20, 50],

            // Topic Modal
            showTopicModal: false,
            editingTopic: null,
            isSavingTopic: false,
            topicForm: {
                id: null,
                name: '',
                description: '',
                image: null,
                existingImage: null,
                sort_order: 0,
                status: 1
            },

            // Video Modal
            showVideoModal: false,
            editingVideo: null,
            isSavingVideo: false,
            videoForm: {
                id: null,
                topic_id: '',
                title: '',
                description: '',
                video_type: 'upload',
                video: null,
                video_url: '',
                existingVideo: null,
                thumbnail: null,
                existingThumbnail: null,
                duration: null,
                sort_order: 0,
                status: 1
            },

            // Preview Modal
            showPreviewModal: false,
            previewVideoData: null
        }
    },
    created() {
        this.fetchTopics();
    },
    methods: {
        switchTab(tab) {
            this.activeTab = tab;
            if (tab === 'topics') {
                this.fetchTopics();
            } else if (tab === 'videos') {
                this.fetchVideos();
            }
        },

        // Topics Methods
        fetchTopics() {
            this.isLoadingTopics = true;
            let params = {};
            if (this.topicFilterStatus !== '') {
                params.status = this.topicFilterStatus;
            }

            axios.get(this.$apiUrl + '/learning_topics', { params })
                .then((response) => {
                    if (response.data.status === 1) {
                        this.topics = response.data.data;
                        this.topicTotalRows = this.topics.length;
                    }
                    this.isLoadingTopics = false;
                })
                .catch((error) => {
                    console.error('Error fetching topics:', error);
                    this.isLoadingTopics = false;
                    this.showError('Failed to fetch topics');
                });
        },

        openTopicModal(topic) {
            if (topic) {
                this.editingTopic = topic;
                this.topicForm = {
                    id: topic.id,
                    name: topic.name,
                    description: topic.description || '',
                    image: null,
                    existingImage: topic.image_url,
                    sort_order: topic.sort_order,
                    status: topic.status
                };
            } else {
                this.editingTopic = null;
                this.resetTopicForm();
            }
            this.showTopicModal = true;
        },

        resetTopicForm() {
            this.topicForm = {
                id: null,
                name: '',
                description: '',
                image: null,
                existingImage: null,
                sort_order: 0,
                status: 1
            };
            this.editingTopic = null;
        },

        handleTopicImage(event) {
            this.topicForm.image = event.target.files[0];
        },

        saveTopic() {
            if (!this.topicForm.name) {
                this.showError('Please enter topic name');
                return;
            }

            this.isSavingTopic = true;
            let formData = new FormData();
            formData.append('name', this.topicForm.name);
            formData.append('description', this.topicForm.description || '');
            formData.append('sort_order', this.topicForm.sort_order);
            formData.append('status', this.topicForm.status);

            if (this.topicForm.image) {
                formData.append('image', this.topicForm.image);
            }

            let url = this.$apiUrl + '/learning_topics/save';
            if (this.topicForm.id) {
                formData.append('id', this.topicForm.id);
                url = this.$apiUrl + '/learning_topics/update';
            }

            axios.post(url, formData, {
                headers: { 'Content-Type': 'multipart/form-data' }
            })
                .then((response) => {
                    if (response.data.status === 1) {
                        this.showMessage('success', response.data.data.message || 'Topic saved successfully');
                        this.showTopicModal = false;
                        this.fetchTopics();
                    } else {
                        this.showError(response.data.message || 'Failed to save topic');
                    }
                    this.isSavingTopic = false;
                })
                .catch((error) => {
                    console.error('Error saving topic:', error);
                    this.showError('Failed to save topic');
                    this.isSavingTopic = false;
                });
        },

        updateTopicStatus(topic) {
            axios.post(this.$apiUrl + '/learning_topics/update-status', {
                id: topic.id,
                status: topic.status
            })
                .then((response) => {
                    if (response.data.status === 1) {
                        this.showMessage('success', 'Status updated successfully');
                    } else {
                        this.showError(response.data.message || 'Failed to update status');
                        this.fetchTopics();
                    }
                })
                .catch((error) => {
                    console.error('Error updating status:', error);
                    this.showError('Failed to update status');
                    this.fetchTopics();
                });
        },

        deleteTopic(topic) {
            this.$swal.fire({
                title: 'Are you sure?',
                text: 'This will delete the topic and all associated videos. This action cannot be undone.',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#d33',
                cancelButtonColor: '#3085d6',
                confirmButtonText: 'Yes, delete it!'
            }).then((result) => {
                if (result.isConfirmed) {
                    axios.post(this.$apiUrl + '/learning_topics/delete', { id: topic.id })
                        .then((response) => {
                            if (response.data.status === 1) {
                                this.showMessage('success', 'Topic deleted successfully');
                                this.fetchTopics();
                            } else {
                                this.showError(response.data.message || 'Failed to delete topic');
                            }
                        })
                        .catch((error) => {
                            console.error('Error deleting topic:', error);
                            this.showError('Failed to delete topic');
                        });
                }
            });
        },

        // Videos Methods
        fetchVideos() {
            this.isLoadingVideos = true;
            let params = {};
            if (this.videoFilterTopic) {
                params.topic_id = this.videoFilterTopic;
            }
            if (this.videoFilterStatus !== '') {
                params.status = this.videoFilterStatus;
            }

            axios.get(this.$apiUrl + '/learning_videos', { params })
                .then((response) => {
                    if (response.data.status === 1) {
                        this.videos = response.data.data;
                        this.videoTotalRows = this.videos.length;
                    }
                    this.isLoadingVideos = false;
                })
                .catch((error) => {
                    console.error('Error fetching videos:', error);
                    this.isLoadingVideos = false;
                    this.showError('Failed to fetch videos');
                });
        },

        openVideoModal(video) {
            if (video) {
                this.editingVideo = video;
                this.videoForm = {
                    id: video.id,
                    topic_id: video.topic_id,
                    title: video.title,
                    description: video.description || '',
                    video_type: video.video_type,
                    video: null,
                    video_url: video.video_type !== 'upload' ? video.video_url : '',
                    existingVideo: video.video_type === 'upload' ? video.video_url : null,
                    thumbnail: null,
                    existingThumbnail: video.thumbnail_url,
                    duration: video.duration,
                    sort_order: video.sort_order,
                    status: video.status
                };
            } else {
                this.editingVideo = null;
                this.resetVideoForm();
            }
            this.showVideoModal = true;
        },

        resetVideoForm() {
            this.videoForm = {
                id: null,
                topic_id: '',
                title: '',
                description: '',
                video_type: 'upload',
                video: null,
                video_url: '',
                existingVideo: null,
                thumbnail: null,
                existingThumbnail: null,
                duration: null,
                sort_order: 0,
                status: 1
            };
            this.editingVideo = null;
        },

        handleVideoFile(event) {
            this.videoForm.video = event.target.files[0];
        },

        handleVideoThumbnail(event) {
            this.videoForm.thumbnail = event.target.files[0];
        },

        saveVideo() {
            if (!this.videoForm.topic_id) {
                this.showError('Please select a topic');
                return;
            }
            if (!this.videoForm.title) {
                this.showError('Please enter video title');
                return;
            }
            if (this.videoForm.video_type === 'upload' && !this.videoForm.video && !this.videoForm.id) {
                this.showError('Please select a video file');
                return;
            }
            if (this.videoForm.video_type !== 'upload' && !this.videoForm.video_url) {
                this.showError('Please enter video URL');
                return;
            }

            this.isSavingVideo = true;
            let formData = new FormData();
            formData.append('topic_id', this.videoForm.topic_id);
            formData.append('title', this.videoForm.title);
            formData.append('description', this.videoForm.description || '');
            formData.append('video_type', this.videoForm.video_type);
            formData.append('sort_order', this.videoForm.sort_order);
            formData.append('status', this.videoForm.status);

            if (this.videoForm.duration) {
                formData.append('duration', this.videoForm.duration);
            }

            if (this.videoForm.video_type === 'upload') {
                if (this.videoForm.video) {
                    formData.append('video', this.videoForm.video);
                }
            } else {
                formData.append('video_url', this.videoForm.video_url);
            }

            if (this.videoForm.thumbnail) {
                formData.append('thumbnail', this.videoForm.thumbnail);
            }

            let url = this.$apiUrl + '/learning_videos/save';
            if (this.videoForm.id) {
                formData.append('id', this.videoForm.id);
                url = this.$apiUrl + '/learning_videos/update';
            }

            axios.post(url, formData, {
                headers: { 'Content-Type': 'multipart/form-data' }
            })
                .then((response) => {
                    if (response.data.status === 1) {
                        this.showMessage('success', response.data.data.message || 'Video saved successfully');
                        this.showVideoModal = false;
                        this.fetchVideos();
                    } else {
                        this.showError(response.data.message || 'Failed to save video');
                    }
                    this.isSavingVideo = false;
                })
                .catch((error) => {
                    console.error('Error saving video:', error);
                    this.showError('Failed to save video');
                    this.isSavingVideo = false;
                });
        },

        updateVideoStatus(video) {
            axios.post(this.$apiUrl + '/learning_videos/update-status', {
                id: video.id,
                status: video.status
            })
                .then((response) => {
                    if (response.data.status === 1) {
                        this.showMessage('success', 'Status updated successfully');
                    } else {
                        this.showError(response.data.message || 'Failed to update status');
                        this.fetchVideos();
                    }
                })
                .catch((error) => {
                    console.error('Error updating status:', error);
                    this.showError('Failed to update status');
                    this.fetchVideos();
                });
        },

        deleteVideo(video) {
            this.$swal.fire({
                title: 'Are you sure?',
                text: 'This will delete the video. This action cannot be undone.',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#d33',
                cancelButtonColor: '#3085d6',
                confirmButtonText: 'Yes, delete it!'
            }).then((result) => {
                if (result.isConfirmed) {
                    axios.post(this.$apiUrl + '/learning_videos/delete', { id: video.id })
                        .then((response) => {
                            if (response.data.status === 1) {
                                this.showMessage('success', 'Video deleted successfully');
                                this.fetchVideos();
                            } else {
                                this.showError(response.data.message || 'Failed to delete video');
                            }
                        })
                        .catch((error) => {
                            console.error('Error deleting video:', error);
                            this.showError('Failed to delete video');
                        });
                }
            });
        },

        // Preview Methods
        previewVideo(video) {
            this.previewVideoData = video;
            this.showPreviewModal = true;
        },

        closePreview() {
            this.previewVideoData = null;
        },

        getYoutubeEmbedUrl(url) {
            if (!url) return '';
            const match = url.match(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/ ]{11})/);
            if (match && match[1]) {
                return 'https://www.youtube.com/embed/' + match[1];
            }
            return url;
        },

        getVimeoEmbedUrl(url) {
            if (!url) return '';
            const match = url.match(/vimeo\.com\/(\d+)/);
            if (match && match[1]) {
                return 'https://player.vimeo.com/video/' + match[1];
            }
            return url;
        },

        getVideoTypeBadgeClass(type) {
            switch (type) {
                case 'youtube':
                    return 'bg-danger';
                case 'vimeo':
                    return 'bg-info';
                default:
                    return 'bg-secondary';
            }
        }
    }
}
</script>

<style scoped>
.btn_refresh {
    margin-top: 24px;
}
</style>