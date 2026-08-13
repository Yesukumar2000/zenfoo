<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>{{ isEdit ? 'Edit Store Location' : 'Add New Store Location' }}</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item">
                                <router-link to="/store-locations">Store Locations</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">{{ isEdit ? 'Edit' : 'Add' }}</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/store-locations" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <div class="row">
                <!-- Form Section -->
                <div class="col-md-6 col-sm-12">
                    <div class="card h-100">
                        <div class="card-header">
                            <h4>{{ isEdit ? 'Edit Location Details' : 'Location Details' }}</h4>
                        </div>

                        <div class="card-body">
                            <div v-if="loading" class="text-center py-5">
                                <b-spinner class="align-middle"></b-spinner>
                                <p class="mt-2">Loading...</p>
                            </div>

                            <form v-else @submit.prevent="saveStoreLocation">
                                <div class="row">
                                    <!-- Location Search with Autocomplete -->
                                    <div class="col-md-12">
                                        <div class="form-group mb-3">
                                            <label for="location_search" class="form-label">{{ __('search') }} Location</label>
                                            <GmapAutocomplete
                                                class="form-control"
                                                placeholder="Search for location"
                                                @place_changed="setPlace"
                                                :options="{ fields: ['address_components','formatted_address','geometry','name','place_id','types'], strictBounds: false }"
                                                id="location_search"
                                            />
                                            <small class="text-muted">Search and select a location to auto-fill coordinates</small>
                                        </div>
                                    </div>

                                    <div class="col-md-12">
                                        <div class="form-group mb-3">
                                            <label for="city_id" class="form-label">City <span class="text-danger">*</span></label>
                                            <select
                                                class="form-control"
                                                id="city_id"
                                                v-model="form.city_id"
                                                :class="{ 'is-invalid': errors.city_id }"
                                                required
                                            >
                                                <option value="">Select City</option>
                                                <option v-for="city in cities" :key="city.id" :value="city.id">
                                                    {{ city.name }} - {{ city.zone }}
                                                </option>
                                            </select>
                                            <div v-if="errors.city_id" class="invalid-feedback">
                                                {{ errors.city_id[0] }}
                                            </div>
                                        </div>
                                    </div>

                                    <div class="col-md-12">
                                        <div class="form-group mb-3">
                                            <label for="name" class="form-label">Location Name <span class="text-danger">*</span></label>
                                            <input
                                                type="text"
                                                class="form-control"
                                                id="name"
                                                v-model="form.name"
                                                :class="{ 'is-invalid': errors.name }"
                                                placeholder="Enter location name"
                                                required
                                            />
                                            <div v-if="errors.name" class="invalid-feedback">
                                                {{ errors.name[0] }}
                                            </div>
                                        </div>
                                    </div>

                                    <div class="col-md-12">
                                        <div class="form-group mb-3">
                                            <label for="address" class="form-label">Address <span class="text-danger">*</span></label>
                                            <textarea
                                                class="form-control"
                                                id="address"
                                                v-model="form.address"
                                                :class="{ 'is-invalid': errors.address }"
                                                placeholder="Full address (auto-filled from search)"
                                                rows="3"
                                                required
                                            ></textarea>
                                            <div v-if="errors.address" class="invalid-feedback">
                                                {{ errors.address[0] }}
                                            </div>
                                        </div>
                                    </div>

                                    <div class="col-md-12">
                                        <!-- Phone number for driver / admin to reach this store location -->
                                        <div class="form-group mb-3">
                                            <label for="phone" class="form-label">Store Phone Number</label>
                                            <input
                                                type="tel"
                                                class="form-control"
                                                id="phone"
                                                v-model="form.phone"
                                                :class="{ 'is-invalid': errors.phone }"
                                                placeholder="e.g. +91 9876543210"
                                                maxlength="20"
                                            />
                                            <div v-if="errors.phone" class="invalid-feedback">
                                                {{ errors.phone[0] }}
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Hidden fields for lat/lng - work in background -->
                                    <input type="hidden" v-model="form.latitude" />
                                    <input type="hidden" v-model="form.longitude" />

                                    <div class="col-md-12" v-if="isEdit">
                                        <div class="form-group mb-3">
                                            <label for="status" class="form-label">Status</label>
                                            <b-form-checkbox
                                                v-model="form.status"
                                                :value="1"
                                                :unchecked-value="0"
                                                switch
                                            >
                                                {{ form.status == 1 ? 'Active' : 'Inactive' }}
                                            </b-form-checkbox>
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
                                                {{ isEdit ? 'Update Location' : 'Create Location' }}
                                            </span>
                                        </button>
                                        <router-link to="/store-locations" class="btn btn-secondary ms-2">
                                            <i class="fa fa-times me-1"></i> Cancel
                                        </router-link>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>

                <!-- Map Section -->
                <div class="col-md-6 col-sm-12">
                    <div class="card h-100">
                        <div class="card-header">
                            <h4>Map View</h4>
                        </div>
                        <div class="card-body">
                            <GmapMap
                                :center="center"
                                :zoom="15"
                                :map-type-control="true"
                                style="width: 100%; height: 600px"
                                ref="mapRef"
                            >
                                <GmapMarker
                                    v-for="(m, index) in markers"
                                    :key="index"
                                    :position="m.position"
                                    :draggable="true"
                                    @dragend="handleMarkerDrag"
                                />
                                <GmapInfoWindow
                                    :position="infoWindow.position"
                                    :opened="infoWindow.open"
                                    @closeclick="infoWindow.open = false"
                                >
                                    <div v-html="infoWindow.template"></div>
                                </GmapInfoWindow>
                            </GmapMap>
                            <small class="text-muted mt-2 d-block">
                                <i class="fa fa-info-circle"></i> You can drag the marker to adjust the location
                            </small>
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
import { gmapApi } from 'vue2-google-maps'

export default {
    name: 'StoreLocationForm',
    data() {
        return {
            loading: false,
            saving: false,
            storeLocation: null,
            cities: [],
            form: {
                city_id: '',
                name: '',
                address: '',
                phone: '',
                latitude: '',
                longitude: '',
                status: 1
            },
            markers: [],
            center: { lat: 17.4486, lng: 78.3908 }, // Default center (Hyderabad)
            infoWindow: {
                position: { lat: 0, lng: 0 },
                open: false,
                template: ''
            },
            errors: {}
        }
    },
    computed: {
        isEdit() {
            return this.$route.params.id !== undefined
        },
        locationId() {
            return this.$route.params.id
        },
        google() {
            return gmapApi()
        }
    },
    mounted() {
        this.loadCities()
        if (this.isEdit) {
            this.loadStoreLocation()
        } else {
            // Set default marker for new locations
            this.markers = [{ position: this.center }]
        }
    },
    methods: {
        async loadCities() {
            try {
                const response = await axios.get(this.$apiUrl + '/cities')
                if (response.data.status == 1 || response.data.data) {
                    this.cities = response.data.data || []
                }
            } catch (error) {
                console.error('Error loading cities:', error)
                this.$toast.error('Failed to load cities')
            }
        },
        setPlace(place) {
            if (!place || !place.geometry) return

            // Auto-fill form fields from selected place
            this.form.latitude = place.geometry.location.lat()
            this.form.longitude = place.geometry.location.lng()
            this.form.address = place.formatted_address || ''

            // If name is empty, use place name
            if (!this.form.name) {
                this.form.name = place.name || ''
            }

            // Update map
            this.center = {
                lat: this.form.latitude,
                lng: this.form.longitude
            }
            this.markers = [{ position: this.center }]
            this.infoWindow = {
                position: this.center,
                open: true,
                template: `<b>${this.form.name || 'Store Location'}</b><br>${this.form.address}`
            }
        },

        handleMarkerDrag(event) {
            // Update coordinates when marker is dragged
            const lat = event.latLng.lat()
            const lng = event.latLng.lng()

            this.form.latitude = lat
            this.form.longitude = lng

            // Update center
            this.center = { lat, lng }
            this.infoWindow.position = this.center

            // Perform reverse geocoding to get address and name
            this.reverseGeocode(lat, lng)
        },

        reverseGeocode(lat, lng) {
            if (!this.google || !this.google.maps) return

            const geocoder = new this.google.maps.Geocoder()
            const latlng = { lat, lng }

            geocoder.geocode({ location: latlng }, (results, status) => {
                if (status === 'OK' && results[0]) {
                    // Update address with formatted address
                    this.form.address = results[0].formatted_address

                    // Extract a meaningful name from the results
                    // Try to get the establishment name or use the first address component
                    let placeName = ''

                    // Check if there's an establishment name
                    const establishment = results.find(r => r.types.includes('establishment'))
                    if (establishment) {
                        placeName = establishment.name || this.extractPlaceName(establishment.address_components)
                    } else {
                        // Use the first result's address components to create a name
                        placeName = this.extractPlaceName(results[0].address_components)
                    }

                    // Only update name if it's empty or if user wants to update
                    if (!this.form.name || this.form.name === '') {
                        this.form.name = placeName
                    }

                    // Update info window
                    this.infoWindow = {
                        position: this.center,
                        open: true,
                        template: `<b>${this.form.name || placeName}</b><br>${this.form.address}`
                    }
                } else {
                    console.error('Geocoder failed:', status)
                    this.$toast.warning('Could not fetch address for this location')
                }
            })
        },

        extractPlaceName(addressComponents) {
            // Try to create a meaningful name from address components
            const locality = addressComponents.find(c => c.types.includes('locality'))
            const sublocality = addressComponents.find(c => c.types.includes('sublocality'))
            const route = addressComponents.find(c => c.types.includes('route'))

            if (sublocality) return sublocality.long_name
            if (route) return route.long_name
            if (locality) return locality.long_name

            return 'Selected Location'
        },
        async loadStoreLocation() {
            this.loading = true
            try {
                const response = await axios.get(this.$apiUrl + `/store-locations/edit/${this.locationId}`)

                if (response.data.status == 1 || response.data.data) {
                    this.storeLocation = response.data.data
                    this.form = {
                        city_id: this.storeLocation.city_id || '',
                        name: this.storeLocation.name || '',
                        address: this.storeLocation.address || '',
                        phone: this.storeLocation.phone || '',
                        latitude: parseFloat(this.storeLocation.latitude) || '',
                        longitude: parseFloat(this.storeLocation.longitude) || '',
                        status: this.storeLocation.status || 1
                    }

                    // Update map with loaded location
                    if (this.form.latitude && this.form.longitude) {
                        this.center = {
                            lat: this.form.latitude,
                            lng: this.form.longitude
                        }
                        this.markers = [{ position: this.center }]
                        this.infoWindow = {
                            position: this.center,
                            open: true,
                            template: `<b>${this.form.name}</b><br>${this.form.address}`
                        }
                    }
                } else {
                    this.$toast.error(response.data.message || 'Failed to load location')
                    this.$router.push('/store-locations')
                }
            } catch (error) {
                console.error('Error loading store location:', error)
                this.$toast.error(error.response?.data?.message || 'Failed to load location')
                this.$router.push('/store-locations')
            }
            this.loading = false
        },

        async saveStoreLocation() {
            this.saving = true
            this.errors = {}

            try {
                const formData = new FormData()
                formData.append('city_id', this.form.city_id)
                formData.append('name', this.form.name)
                if (this.form.address) formData.append('address', this.form.address)
                formData.append('phone', this.form.phone || '')
                if (this.form.latitude) formData.append('latitude', this.form.latitude)
                if (this.form.longitude) formData.append('longitude', this.form.longitude)

                let response
                if (this.isEdit) {
                    formData.append('id', this.locationId)
                    if (this.form.status !== undefined) formData.append('status', this.form.status)
                    response = await axios.post(this.$apiUrl + '/store-locations/update', formData)
                } else {
                    response = await axios.post(this.$apiUrl + '/store-locations/save', formData)
                }

                if (response.data.status == 1) {
                    this.$toast.success(this.isEdit ? 'Location updated successfully' : 'Location created successfully')
                    this.$router.push('/store-locations')
                } else {
                    this.$toast.error(response.data.message || 'Failed to save location')
                }
            } catch (error) {
                console.error('Error saving store location:', error)
                if (error.response?.status === 422 && error.response?.data?.errors) {
                    this.errors = error.response.data.errors
                } else {
                    this.$toast.error(error.response?.data?.message || 'Failed to save location')
                }
            }
            this.saving = false
        },

        formatDate(date) {
            if (!date) return '-'
            return moment(date).format('DD MMM YYYY, hh:mm A')
        }
    }
}
</script>

<style scoped>
.me-1 {
    margin-right: 0.25rem;
}
.ms-2 {
    margin-left: 0.5rem;
    
}
</style>
