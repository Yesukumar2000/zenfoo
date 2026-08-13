<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>{{ isEdit ? 'Edit Vehicle' : 'Add New Vehicle' }}</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item">
                                <router-link to="/delivery-boy/vehicles/list">Vehicles</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">{{ isEdit ? 'Edit' : 'Add' }}</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/delivery-boy/vehicles/list" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12 col-md-8">
                    <div class="card">
                        <div class="card-header">
                            <h4>{{ isEdit ? 'Edit Vehicle Details' : 'Vehicle Details' }}</h4>
                        </div>

                        <div class="card-body">
                            <div v-if="loading" class="text-center py-5">
                                <b-spinner class="align-middle"></b-spinner>
                                <p class="mt-2">Loading...</p>
                            </div>

                            <form v-else @submit.prevent="saveVehicle">
                                <div class="row">
                                    <div class="col-md-12">
                                        <div class="form-group mb-3">
                                            <label for="name" class="form-label">Vehicle Name <span class="text-danger">*</span></label>
                                            <input
                                                type="text"
                                                class="form-control"
                                                id="name"
                                                v-model="form.name"
                                                :class="{ 'is-invalid': errors.name }"
                                                placeholder="Enter vehicle name (e.g., Bike, Scooter, Bicycle)"
                                                required
                                            />
                                            <div v-if="errors.name" class="invalid-feedback">
                                                {{ errors.name[0] }}
                                            </div>
                                        </div>
                                    </div>

                                    <div class="col-md-12">
                                        <div class="form-group mb-3">
                                            <label for="image" class="form-label">Vehicle Image</label>
                                            <div class="d-flex align-items-start">
                                                <div class="image-preview me-3" v-if="imagePreview || form.image_url">
                                                    <img
                                                        :src="imagePreview || form.image_url"
                                                        alt="Vehicle Image"
                                                        class="img-thumbnail"
                                                        style="max-width: 120px; max-height: 120px; object-fit: cover;"
                                                    />
                                                    <button
                                                        type="button"
                                                        class="btn btn-sm btn-danger mt-2"
                                                        @click="removeImage"
                                                    >
                                                        <i class="fa fa-times"></i> Remove
                                                    </button>
                                                </div>
                                                <div class="flex-grow-1">
                                                    <input
                                                        type="file"
                                                        class="form-control"
                                                        id="image"
                                                        ref="imageInput"
                                                        @change="handleImageChange"
                                                        accept="image/jpeg,image/png,image/jpg,image/gif,image/webp"
                                                        :class="{ 'is-invalid': errors.image }"
                                                    />
                                                    <small class="text-muted">Accepted formats: JPEG, PNG, JPG, GIF, WEBP. Max size: 2MB</small>
                                                    <div v-if="errors.image" class="invalid-feedback">
                                                        {{ errors.image[0] }}
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="row mt-4">
                                    <div class="col-12">
                                        <button
                                            type="submit"
                                            class="btn btn-primary"
                                            :disabled="saving"
                                        >
                                            <span v-if="saving">
                                                <b-spinner small class="me-1"></b-spinner>
                                                Saving...
                                            </span>
                                            <span v-else>
                                                <i class="fa fa-save me-1"></i>
                                                {{ isEdit ? 'Update Vehicle' : 'Create Vehicle' }}
                                            </span>
                                        </button>
                                        <router-link to="/delivery-boy/vehicles/list" class="btn btn-secondary ms-2">
                                            <i class="fa fa-times me-1"></i> Cancel
                                        </router-link>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>

                <div class="col-12 col-md-4">
                    <div class="card">
                        <div class="card-header">
                            <h4>Help</h4>
                        </div>
                        <div class="card-body">
                            <p><strong>Vehicle Name:</strong> Enter a descriptive name for the vehicle type (e.g., Bike, Scooter, Bicycle, Electric Bike).</p>
                            <p><strong>Image:</strong> Upload an image representing the vehicle type. This helps in quick identification.</p>
                        </div>
                    </div>

                    <div class="card" v-if="isEdit && vehicle">
                        <div class="card-header">
                            <h4>Vehicle Info</h4>
                        </div>
                        <div class="card-body">
                            <p><strong>ID:</strong> {{ vehicle.id }}</p>
                            <p><strong>Created:</strong> {{ formatDate(vehicle.created_at) }}</p>
                            <p><strong>Assigned to:</strong> {{ vehicle.delivery_boys_count || 0 }} delivery partners</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import axios from 'axios'
import moment from 'moment'

export default {
    name: 'VehicleForm',
    data() {
        return {
            loading: false,
            saving: false,
            vehicle: null,
            form: {
                name: '',
                image: null,
                image_url: null
            },
            imagePreview: null,
            errors: {}
        }
    },
    computed: {
        isEdit() {
            return this.$route.params.id !== undefined
        },
        vehicleId() {
            return this.$route.params.id
        }
    },
    mounted() {
        if (this.isEdit) {
            this.loadVehicle()
        }
    },
    methods: {
        async loadVehicle() {
            this.loading = true
            try {
                const response = await axios.get(this.$apiUrl + `/admin/vehicles/${this.vehicleId}`, {
                    params: { token: localStorage.getItem('api_token') }
                })

                if (response.data.status) {
                    this.vehicle = response.data.data.vehicle
                    this.form = {
                        name: this.vehicle.name,
                        image: null,
                        image_url: this.vehicle.image_url
                    }
                } else {
                    this.showError(response.data.message || 'Failed to load vehicle')
                    this.$router.push('/delivery-boy/vehicles/list')
                }
            } catch (error) {
                this.showError(error.response?.data?.message || 'Failed to load vehicle')
                this.$router.push('/delivery-boy/vehicles/list')
            }
            this.loading = false
        },

        handleImageChange(event) {
            const file = event.target.files[0]
            if (file) {
                if (file.size > 2 * 1024 * 1024) {
                    this.showError('Image size must be less than 2MB')
                    event.target.value = ''
                    return
                }

                this.form.image = file
                this.imagePreview = URL.createObjectURL(file)
            }
        },

        removeImage() {
            this.form.image = null
            this.imagePreview = null
            this.form.image_url = null
            if (this.$refs.imageInput) {
                this.$refs.imageInput.value = ''
            }
        },

        async saveVehicle() {
            this.saving = true
            this.errors = {}

            try {
                const formData = new FormData()
                formData.append('token', localStorage.getItem('api_token'))
                formData.append('name', this.form.name)

                if (this.form.image) {
                    formData.append('image', this.form.image)
                }

                let response
                if (this.isEdit) {
                    formData.append('vehicle_id', this.vehicleId)
                    response = await axios.post(this.$apiUrl + '/admin/vehicles/update', formData, {
                        headers: { 'Content-Type': 'multipart/form-data' }
                    })
                } else {
                    response = await axios.post(this.$apiUrl + '/admin/vehicles/create', formData, {
                        headers: { 'Content-Type': 'multipart/form-data' }
                    })
                }

                if (response.data.status) {
                    this.showSuccess(this.isEdit ? 'Vehicle updated successfully' : 'Vehicle created successfully')
                    this.$router.push('/delivery-boy/vehicles/list')
                } else {
                    this.showError(response.data.message || 'Failed to save vehicle')
                }
            } catch (error) {
                if (error.response?.status === 422 && error.response?.data?.errors) {
                    this.errors = error.response.data.errors
                } else {
                    this.showError(error.response?.data?.message || 'Failed to save vehicle')
                }
            }
            this.saving = false
        },

        formatDate(date) {
            if (!date) return '-'
            return moment(date).format('DD MMM YYYY, hh:mm A')
        }
    },
    beforeDestroy() {
        if (this.imagePreview) {
            URL.revokeObjectURL(this.imagePreview)
        }
    }
}
</script>

<style scoped>
.me-1 {
    margin-right: 0.25rem;
}
.me-3 {
    margin-right: 1rem;
}
.ms-2 {
    margin-left: 0.5rem;
}
.image-preview {
    display: flex;
    flex-direction: column;
    align-items: center;
}
</style>
