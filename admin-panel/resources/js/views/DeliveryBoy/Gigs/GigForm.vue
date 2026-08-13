<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>{{ isEdit ? 'Edit' : 'Create' }} Gig</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item">
                                <router-link to="/delivery-boy/gigs/list">Gigs</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">
                                {{ isEdit ? 'Edit' : 'Create' }}
                            </li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/delivery-boy/gigs/list" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <!-- Main Form Card -->
            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h4>{{ isEdit ? 'Edit' : 'Create New' }} Gig</h4>
                        </div>
                        <div class="card-body">
                            <b-overlay :show="loading" rounded="sm">
                                <b-form @submit.prevent="saveGig">
                                    <b-row>
                                        <b-col md="6">
                                            <b-form-group
                                                label="Gig Name"
                                                label-for="gig-name"
                                                description="Enter a name for this gig shift"
                                            >
                                                <b-form-input
                                                    id="gig-name"
                                                    v-model="form.gig_name"
                                                    placeholder="e.g., Morning Shift, Evening Shift"
                                                    required
                                                ></b-form-input>
                                            </b-form-group>
                                        </b-col>

                                        <!-- <b-col md="6">
                                            <b-form-group
                                                label="Description (Optional)"
                                                label-for="description"
                                                description="Brief description of this gig"
                                            >
                                                <b-form-input
                                                    id="description"
                                                    v-model="form.description"
                                                    placeholder="e.g., Best for morning deliveries"
                                                ></b-form-input>
                                            </b-form-group>
                                        </b-col> -->
                                    </b-row>

                                    <b-row class="mt-3">
                                        <b-col md="4">
                                            <b-form-group
                                                label="Start Time"
                                                label-for="start-time"
                                            >
                                                <b-form-input
                                                    id="start-time"
                                                    v-model="form.start_time"
                                                    type="time"
                                                    required
                                                ></b-form-input>
                                            </b-form-group>
                                        </b-col>

                                        <b-col md="4">
                                            <b-form-group
                                                label="End Time"
                                                label-for="end-time"
                                            >
                                                <b-form-input
                                                    id="end-time"
                                                    v-model="form.end_time"
                                                    type="time"
                                                    required
                                                ></b-form-input>
                                            </b-form-group>
                                        </b-col>

                                        <b-col md="4">
                                            <b-form-group
                                                label="Duration (Hours)"
                                                label-for="duration"
                                                description="Auto-calculated"
                                            >
                                                <b-form-input
                                                    id="duration"
                                                    :value="calculatedDuration"
                                                    readonly
                                                    disabled
                                                ></b-form-input>
                                            </b-form-group>
                                        </b-col>
                                    </b-row>

                                    <b-row class="mt-3">
                                        <b-col md="6">
                                            <b-form-group
                                                label="Base Earnings (₹)"
                                                label-for="base-earning"
                                                description="Minimum guaranteed earnings"
                                            >
                                                <b-form-input
                                                    id="base-earning"
                                                    v-model.number="form.base_earning"
                                                    type="number"
                                                    min="0"
                                                    step="0.01"
                                                    placeholder="300.00"
                                                    required
                                                ></b-form-input>
                                            </b-form-group>
                                        </b-col>

                                        <b-col md="6">
                                            <b-form-group
                                                label="Status"
                                                label-for="is-active"
                                            >
                                                <div class="d-flex align-items-center mt-2">
                                                    <label class="toggle-switch mb-0 mr-3">
                                                        <input
                                                            type="checkbox"
                                                            v-model="form.is_active"
                                                            :true-value="1"
                                                            :false-value="0"
                                                        >
                                                        <span class="toggle-slider"></span>
                                                    </label>
                                                    <b-badge :variant="form.is_active == 1 ? 'success' : 'secondary'" class="px-3 py-2">
                                                        {{ form.is_active == 1 ? 'Active' : 'Inactive' }}
                                                    </b-badge>
                                                </div>
                                                <small class="text-muted d-block mt-2">
                                                    Only active gigs are visible to delivery partners
                                                </small>
                                            </b-form-group>
                                        </b-col>
                                    </b-row>

                                    <!-- Preview Section -->
                                    <!-- <b-row class="mt-4">
                                        <b-col md="12">
                                            <div class="alert alert-info">
                                                <h6><i class="fa fa-eye"></i> Preview</h6>
                                                <hr>
                                                <b-row>
                                                    <b-col md="6">
                                                        <p><strong>Gig Name:</strong> {{ form.gig_name || 'N/A' }}</p>
                                                        <p><strong>Description:</strong> {{ form.description || 'N/A' }}</p>
                                                        <p><strong>Time:</strong> {{ formatPreviewTime(form.start_time) }} - {{ formatPreviewTime(form.end_time) }}</p>
                                                    </b-col>
                                                    <b-col md="6">
                                                        <p><strong>Duration:</strong> {{ calculatedDuration }} hours</p>
                                                        <p><strong>Base Earnings:</strong> {{ $currency }} {{ parseFloat(form.base_earning || 0).toFixed(2) }}</p>
                                                        <p><strong>Status:</strong>
                                                            <b-badge :variant="form.is_active == 1 ? 'success' : 'secondary'">
                                                                {{ form.is_active == 1 ? 'Active' : 'Inactive' }}
                                                            </b-badge>
                                                        </p>
                                                    </b-col>
                                                </b-row>
                                            </div>
                                        </b-col>
                                    </b-row> -->

                                    <!-- Action Buttons -->
                                    <b-row class="mt-4">
                                        <b-col md="12" class="text-right">
                                            <b-button
                                                variant="secondary"
                                                @click="$router.push('/delivery-boy/gigs/list')"
                                                class="mr-2"
                                            >
                                                <i class="fa fa-times"></i> Cancel
                                            </b-button>
                                            <b-button
                                                variant="primary"
                                                type="submit"
                                                :disabled="loading || !isFormValid"
                                            >
                                                <b-spinner v-if="loading" small class="mr-1"></b-spinner>
                                                <i v-else class="fa fa-save"></i>
                                                {{ isEdit ? 'Update' : 'Create' }} Gig
                                            </b-button>
                                        </b-col>
                                    </b-row>
                                </b-form>
                            </b-overlay>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Bulk Create Slots Card (Only for Edit Mode) -->
            <!-- <div class="row mt-3" v-if="isEdit">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h4>Bulk Create Slots</h4>
                        </div>
                        <div class="card-body">
                            <p class="text-muted">Automatically create gig slots for multiple days</p>
                            <b-row>
                                <b-col md="4">
                                    <b-form-group
                                        label="Number of Days"
                                        label-for="bulk-days"
                                        description="Create slots for next N days"
                                    >
                                        <b-form-input
                                            id="bulk-days"
                                            v-model.number="bulkSlots.days"
                                            type="number"
                                            min="1"
                                            max="90"
                                            placeholder="30"
                                        ></b-form-input>
                                    </b-form-group>
                                </b-col>

                                <b-col md="4">
                                    <b-form-group
                                        label="Max Bookings per Slot"
                                        label-for="max-bookings"
                                        description="Maximum delivery partners per slot"
                                    >
                                        <b-form-input
                                            id="max-bookings"
                                            v-model.number="bulkSlots.max_bookings"
                                            type="number"
                                            min="1"
                                            max="100"
                                            placeholder="50"
                                        ></b-form-input>
                                    </b-form-group>
                                </b-col>

                                <b-col md="4" class="d-flex align-items-end">
                                    <b-button
                                        variant="success"
                                        @click="createBulkSlots"
                                        :disabled="bulkSlots.loading || !bulkSlots.days || !bulkSlots.max_bookings"
                                        block
                                    >
                                        <b-spinner v-if="bulkSlots.loading" small class="mr-1"></b-spinner>
                                        <i v-else class="fa fa-calendar-check-o"></i>
                                        Create Slots
                                    </b-button>
                                </b-col>
                            </b-row>
                        </div>
                    </div>
                </div>
            </div> -->
        
        </div>
    </div>
</template>

<script>
import axios from 'axios'
import moment from 'moment'

export default {
    name: 'GigForm',
    data() {
        return {
            loading: false,
            isEdit: false,
            form: {
                gig_name: '',
                description: '',
                start_time: '09:00',
                end_time: '18:00',
                duration_hours: 0,
                base_earning: 0,
                is_active: 1
            },
            bulkSlots: {
                days: 30,
                max_bookings: 50,
                loading: false
            }
        }
    },
    computed: {
        gigId() {
            return this.$route.params.id
        },
        calculatedDuration() {
            if (!this.form.start_time || !this.form.end_time) return 0

            const start = moment(this.form.start_time, 'HH:mm')
            let end = moment(this.form.end_time, 'HH:mm')

            // Handle overnight shifts
            if (end.isBefore(start)) {
                end.add(1, 'day')
            }

            const duration = moment.duration(end.diff(start))
            return Math.round(duration.asHours() * 10) / 10 // Round to 1 decimal
        },
        isFormValid() {
            return this.form.gig_name.length >= 3 &&
                   this.form.start_time &&
                   this.form.end_time &&
                   this.form.base_earning > 0 &&
                   this.calculatedDuration > 0
        }
    },
    watch: {
        'form.start_time': function() {
            this.form.duration_hours = this.calculatedDuration
        },
        'form.end_time': function() {
            this.form.duration_hours = this.calculatedDuration
        }
    },
    mounted() {
        if (this.gigId) {
            this.isEdit = true
            this.loadGig()
        }
    },
    methods: {
        async loadGig() {
            this.loading = true
            try {
                const response = await axios.get(
                    `${this.$apiUrl}/admin/delivery-boys/gigs/${this.gigId}`,
                    { params: { token: localStorage.getItem('api_token') } }
                )

                if (response.data.status) {
                    const gig = response.data.data.gig
                    this.form = {
                        gig_name: gig.gig_name || '',
                        description: gig.description || '',
                        start_time: gig.start_time.substring(0, 5), // HH:mm format
                        end_time: gig.end_time.substring(0, 5),
                        duration_hours: gig.duration_hours,
                        base_earning: parseFloat(gig.base_earning || 0),
                        is_active: gig.is_active || 0
                    }
                } else {
                    this.showError('Failed to load gig')
                    this.$router.push('/delivery-boy/gigs/list')
                }
            } catch (error) {
                console.error('Error loading gig:', error)
                this.showError(error.response?.data?.message || 'Failed to load gig')
                this.$router.push('/delivery-boy/gigs/list')
            }
            this.loading = false
        },

        async saveGig() {
            if (!this.isFormValid) {
                this.showError('Please fill all required fields correctly')
                return
            }

            this.loading = true

            const payload = {
                token: localStorage.getItem('api_token'),
                gig_name: this.form.gig_name,
                description: this.form.description || '',
                start_time: this.form.start_time,
                end_time: this.form.end_time,
                duration_hours: this.calculatedDuration,
                base_earning: this.form.base_earning,
                is_active: this.form.is_active
            }

            try {
                let response
                if (this.isEdit) {
                    response = await axios.post(`${this.$apiUrl}/admin/delivery-boys/gigs/update`, {
                        ...payload,
                        gig_id: this.gigId
                    })
                } else {
                    response = await axios.post(`${this.$apiUrl}/admin/delivery-boys/gigs/create`, payload)
                }

                if (response.data.status) {
                    this.showSuccess(`Gig ${this.isEdit ? 'updated' : 'created'} successfully!`)
                    this.$router.push('/delivery-boy/gigs/list')
                } else {
                    this.showError(response.data.message || 'Operation failed')
                }
            } catch (error) {
                console.error('Error saving gig:', error)
                this.showError(error.response?.data?.message || `Failed to ${this.isEdit ? 'update' : 'create'} gig`)
            }

            this.loading = false
        },

        async createBulkSlots() {
            if (!this.bulkSlots.days || !this.bulkSlots.max_bookings) {
                this.showError('Please fill in both days and max bookings')
                return
            }

            this.bulkSlots.loading = true

            try {
                const response = await axios.post(`${this.$apiUrl}/admin/delivery-boys/gigs/slots/create`, {
                    token: localStorage.getItem('api_token'),
                    gig_id: this.gigId,
                    days: this.bulkSlots.days,
                    max_bookings: this.bulkSlots.max_bookings
                })

                if (response.data.status) {
                    this.showSuccess(`${this.bulkSlots.days} slots created successfully!`)
                } else {
                    this.showError(response.data.message || 'Failed to create slots')
                }
            } catch (error) {
                console.error('Error creating bulk slots:', error)
                this.showError(error.response?.data?.message || 'Failed to create slots')
            }

            this.bulkSlots.loading = false
        },

        formatPreviewTime(time) {
            if (!time) return 'N/A'
            return moment(time, 'HH:mm').format('hh:mm A')
        }
    }
}
</script>

<style scoped>
.card-header h4 {
    margin: 0;
}
.form-control:disabled {
    background-color: #e9ecef;
    opacity: 0.7;
}

/* Toggle Switch Styles */
.toggle-switch {
    position: relative;
    display: inline-block;
    width: 60px;
    height: 30px;
}

.toggle-switch input {
    opacity: 0;
    width: 0;
    height: 0;
}

.toggle-slider {
    position: absolute;
    cursor: pointer;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: #ccc;
    transition: 0.4s;
    border-radius: 30px;
}

.toggle-slider:before {
    position: absolute;
    content: "";
    height: 22px;
    width: 22px;
    left: 4px;
    bottom: 4px;
    background-color: white;
    transition: 0.4s;
    border-radius: 50%;
}

.toggle-switch input:checked + .toggle-slider {
    background-color: #28a745;
}

.toggle-switch input:focus + .toggle-slider {
    box-shadow: 0 0 1px #28a745;
}

.toggle-switch input:checked + .toggle-slider:before {
    transform: translateX(30px);
}

/* Disabled state */
.toggle-switch input:disabled + .toggle-slider {
    opacity: 0.5;
    cursor: not-allowed;
}
</style>