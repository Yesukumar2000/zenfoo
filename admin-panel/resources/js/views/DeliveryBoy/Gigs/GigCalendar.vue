<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Gig Calendar & Slot Management</h3>
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
                            <li class="breadcrumb-item active" aria-current="page">Calendar</li>
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

            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h4>Slot Calendar</h4>
                            <button class="btn btn-primary btn-sm float-end" @click="showBulkCreateModal = true">
                                <i class="fa fa-calendar-check-o"></i> Bulk Create Slots
                            </button>
                        </div>

                        <div class="card-body">
                            <!-- Filters -->
                            <b-row class="mb-3">
                                <b-col md="4">
                                    <label>Select Gig</label>
                                    <b-form-select
                                        v-model="selectedGigId"
                                        :options="gigOptions"
                                        @change="loadSlots"
                                    ></b-form-select>
                                </b-col>
                                <b-col md="3">
                                    <label>From Date</label>
                                    <b-form-input
                                        type="date"
                                        v-model="filters.fromDate"
                                        @input="loadSlots"
                                    ></b-form-input>
                                </b-col>
                                <b-col md="3">
                                    <label>To Date</label>
                                    <b-form-input
                                        type="date"
                                        v-model="filters.toDate"
                                        @input="loadSlots"
                                    ></b-form-input>
                                </b-col>
                                <b-col md="2" class="d-flex align-items-end">
                                    <button type="button" class="btn btn-primary" @click="loadSlots()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i> Refresh
                                    </button>
                                </b-col>
                            </b-row>

                            <!-- Loading State -->
                            <div v-if="loading" class="text-center py-5">
                                <b-spinner class="align-middle"></b-spinner>
                                <p class="mt-2">Loading calendar...</p>
                            </div>

                            <!-- No Gig Selected -->
                            <div v-else-if="!selectedGigId" class="text-center py-5">
                                <i class="fa fa-calendar fa-4x text-muted mb-3"></i>
                                <h5 class="text-muted">Select a Gig to View Calendar</h5>
                            </div>

                            <!-- Calendar Grid -->
                            <div v-else>
                                <div v-if="slots.length > 0" class="calendar-grid">
                                    <div
                                        v-for="slot in slots"
                                        :key="slot.id"
                                        class="calendar-slot"
                                        :class="{
                                            'slot-full': slot.booked_count >= slot.capacity,
                                            'slot-inactive': !slot.is_active,
                                            'slot-past': isPast(slot.slot_date)
                                        }"
                                    >
                                        <div class="slot-date">
                                            {{ formatDate(slot.slot_date) }}
                                        </div>
                                        <div class="slot-info">
                                            <div class="slot-capacity">
                                                <i class="fa fa-users mr-1"></i>
                                                {{ slot.booked_count }}/{{ slot.capacity }}
                                            </div>
                                            <div class="slot-status">
                                                <span class="badge" :class="'bg-' + getSlotStatusColor(slot)">
                                                    {{ getSlotStatus(slot) }}
                                                </span>
                                            </div>
                                        </div>
                                        <div class="slot-actions">
                                            <button
                                                class="btn btn-info btn-sm"
                                                v-b-tooltip.hover
                                                title="View Bookings"
                                                @click="viewSlotDetails(slot)"
                                            >
                                                <i class="fa fa-list"></i>
                                            </button>
                                            <button
                                                class="btn btn-warning btn-sm"
                                                v-b-tooltip.hover
                                                title="Edit Slot"
                                                @click="editSlot(slot)"
                                            >
                                                <i class="fa fa-edit"></i>
                                            </button>
                                            <button
                                                class="btn btn-sm"
                                                :class="slot.is_active ? 'btn-danger' : 'btn-success'"
                                                v-b-tooltip.hover
                                                :title="slot.is_active ? 'Deactivate' : 'Activate'"
                                                @click="toggleSlotStatus(slot)"
                                            >
                                                <i :class="slot.is_active ? 'fa fa-ban' : 'fa fa-check'"></i>
                                            </button>
                                        </div>
                                    </div>
                                </div>

                                <!-- Empty State -->
                                <div v-else class="text-center py-5">
                                    <i class="fa fa-calendar fa-4x text-muted mb-3"></i>
                                    <h5 class="text-muted">No Slots Found</h5>
                                    <p class="text-muted">Create slots for this gig to get started</p>
                                    <button class="btn btn-primary" @click="showBulkCreateModal = true">
                                        <i class="fa fa-plus"></i> Create Slots
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Bulk Create Slots Modal -->
        <b-modal
            v-model="showBulkCreateModal"
            title="Bulk Create Gig Slots"
            size="lg"
            @ok="createBulkSlots"
            ok-title="Create Slots"
            ok-variant="primary"
        >
            <b-form>
                <b-form-group label="Select Gig">
                    <b-form-select
                        v-model="bulkCreate.gigId"
                        :options="gigOptions"
                        required
                    ></b-form-select>
                </b-form-group>

                <b-row>
                    <b-col md="6">
                        <b-form-group label="Start Date">
                            <b-form-input
                                type="date"
                                v-model="bulkCreate.startDate"
                                required
                            ></b-form-input>
                        </b-form-group>
                    </b-col>
                    <b-col md="6">
                        <b-form-group label="End Date">
                            <b-form-input
                                type="date"
                                v-model="bulkCreate.endDate"
                                required
                            ></b-form-input>
                        </b-form-group>
                    </b-col>
                </b-row>

                <b-form-group label="Capacity per Slot">
                    <b-form-input
                        type="number"
                        v-model="bulkCreate.capacity"
                        min="1"
                        required
                    ></b-form-input>
                </b-form-group>

                <b-form-group>
                    <b-form-checkbox
                        v-model="bulkCreate.isActive"
                        switch
                        size="lg"
                    >
                        Active
                    </b-form-checkbox>
                </b-form-group>
            </b-form>
        </b-modal>

        <!-- Edit Slot Modal -->
        <b-modal
            v-model="showEditModal"
            title="Edit Slot"
            @ok="updateSlot"
            ok-title="Update Slot"
            ok-variant="warning"
        >
            <b-form v-if="editingSlot">
                <b-form-group label="Date">
                    <b-form-input
                        type="date"
                        v-model="editingSlot.slot_date"
                        disabled
                    ></b-form-input>
                </b-form-group>

                <b-form-group label="Capacity">
                    <b-form-input
                        type="number"
                        v-model="editingSlot.capacity"
                        min="1"
                        required
                    ></b-form-input>
                </b-form-group>

                <b-form-group label="Booked">
                    <b-form-input
                        type="number"
                        v-model="editingSlot.booked_count"
                        disabled
                    ></b-form-input>
                </b-form-group>

                <b-form-group>
                    <b-form-checkbox
                        v-model="editingSlot.is_active"
                        switch
                        size="lg"
                    >
                        Active
                    </b-form-checkbox>
                </b-form-group>
            </b-form>
        </b-modal>

        <!-- Slot Details Modal -->
        <b-modal
            v-model="showDetailsModal"
            title="Slot Bookings"
            size="lg"
            ok-only
            ok-title="Close"
        >
            <div v-if="selectedSlot">
                <h6>{{ selectedGigName }} - {{ formatDate(selectedSlot.slot_date) }}</h6>
                <p>Capacity: {{ selectedSlot.booked_count }}/{{ selectedSlot.capacity }}</p>

                <b-table
                    :items="slotBookings"
                    :fields="bookingFields"
                    :busy="loadingBookings"
                    hover
                    striped
                    show-empty
                >
                    <template #table-busy>
                        <div class="text-center text-black my-2">
                            <b-spinner class="align-middle"></b-spinner>
                            <strong>Loading...</strong>
                        </div>
                    </template>

                    <template #cell(partner)="row">
                        <strong>{{ row.item.delivery_boy ? row.item.delivery_boy.name : 'N/A' }}</strong>
                        <br>
                        <small>{{ row.item.delivery_boy ? row.item.delivery_boy.phone : '' }}</small>
                    </template>

                    <template #cell(status)="row">
                        <span class="badge" :class="'bg-' + getBookingStatusColor(row.item.booking_status)">
                            {{ row.item.booking_status }}
                        </span>
                    </template>

                    <template #empty>
                        <div class="text-center py-3">
                            <p class="text-muted">No bookings found for this slot</p>
                        </div>
                    </template>
                </b-table>
            </div>
        </b-modal>
    </div>
</template>

<script>
import axios from 'axios'
import moment from 'moment'

export default {
    name: 'GigCalendar',
    data() {
        return {
            loading: false,
            loadingBookings: false,
            selectedGigId: '',
            selectedGigName: '',
            gigs: [],
            slots: [],
            slotBookings: [],
            selectedSlot: null,
            editingSlot: null,
            filters: {
                fromDate: moment().startOf('month').format('YYYY-MM-DD'),
                toDate: moment().endOf('month').format('YYYY-MM-DD')
            },
            showBulkCreateModal: false,
            showEditModal: false,
            showDetailsModal: false,
            bulkCreate: {
                gigId: '',
                startDate: moment().format('YYYY-MM-DD'),
                endDate: moment().add(30, 'days').format('YYYY-MM-DD'),
                capacity: 10,
                isActive: true
            },
            bookingFields: [
                { key: 'partner', label: 'Delivery Partner' },
                { key: 'booked_at', label: 'Booked At' },
                { key: 'status', label: 'Status' }
            ]
        }
    },
    computed: {
        gigOptions() {
            return [
                { value: '', text: 'Select a Gig' },
                ...this.gigs.map(gig => ({
                    value: gig.id,
                    text: `${gig.gig_name || 'Unnamed Gig'} (${gig.start_time} - ${gig.end_time})`
                }))
            ]
        }
    },
    mounted() {
        this.loadGigs()
    },
    methods: {
        async loadGigs() {
            try {
                const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/gigs', {
                    params: { token: localStorage.getItem('api_token') }
                })
                if (response.data.status) {
                    this.gigs = response.data.data.gigs
                } else {
                    this.showError(response.data.message || 'Failed to load gigs')
                }
            } catch (error) {
                this.showError(error.response?.data?.message || 'Failed to load gigs')
            }
        },

        async loadSlots() {
            if (!this.selectedGigId) return

            this.loading = true
            try {
                const selectedGig = this.gigs.find(g => g.id == this.selectedGigId)
                this.selectedGigName = selectedGig ? selectedGig.gig_name : ''

                const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/gigs/slots', {
                    params: {
                        token: localStorage.getItem('api_token'),
                        gig_id: this.selectedGigId,
                        from_date: this.filters.fromDate,
                        to_date: this.filters.toDate
                    }
                })
                if (response.data.status) {
                    this.slots = response.data.data.slots
                } else {
                    this.showError(response.data.message || 'Failed to load slots')
                }
            } catch (error) {
                this.showError(error.response?.data?.message || 'Failed to load slots')
            }
            this.loading = false
        },

        async createBulkSlots(evt) {
            evt.preventDefault()

            if (!this.bulkCreate.gigId || !this.bulkCreate.startDate || !this.bulkCreate.endDate || !this.bulkCreate.capacity) {
                this.showError('Please fill all required fields')
                return
            }

            try {
                const response = await axios.post(this.$apiUrl + '/admin/delivery-boys/gigs/slots/create', {
                    token: localStorage.getItem('api_token'),
                    gig_id: this.bulkCreate.gigId,
                    start_date: this.bulkCreate.startDate,
                    end_date: this.bulkCreate.endDate,
                    capacity: this.bulkCreate.capacity,
                    is_active: this.bulkCreate.isActive ? 1 : 0
                })

                if (response.data.status) {
                    this.showSuccess('Slots created successfully')
                    this.showBulkCreateModal = false

                    // Select the gig and reload
                    this.selectedGigId = this.bulkCreate.gigId
                    this.loadSlots()
                } else {
                    this.showError(response.data.message || 'Failed to create slots')
                }
            } catch (error) {
                this.showError(error.response?.data?.message || 'Failed to create slots')
            }
        },

        editSlot(slot) {
            this.editingSlot = { ...slot }
            this.showEditModal = true
        },

        async updateSlot(evt) {
            evt.preventDefault()

            try {
                const response = await axios.post(this.$apiUrl + '/admin/delivery-boys/gigs/slots/update', {
                    token: localStorage.getItem('api_token'),
                    slot_id: this.editingSlot.id,
                    capacity: this.editingSlot.capacity,
                    is_active: this.editingSlot.is_active ? 1 : 0
                })

                if (response.data.status) {
                    this.showSuccess('Slot updated successfully')
                    this.showEditModal = false
                    this.loadSlots()
                } else {
                    this.showError(response.data.message || 'Failed to update slot')
                }
            } catch (error) {
                this.showError(error.response?.data?.message || 'Failed to update slot')
            }
        },

        async toggleSlotStatus(slot) {
            try {
                const response = await axios.post(this.$apiUrl + '/admin/delivery-boys/gigs/slots/update', {
                    token: localStorage.getItem('api_token'),
                    slot_id: slot.id,
                    capacity: slot.capacity,
                    is_active: slot.is_active ? 0 : 1
                })

                if (response.data.status) {
                    this.showSuccess('Slot status updated')
                    this.loadSlots()
                } else {
                    this.showError(response.data.message || 'Failed to update status')
                }
            } catch (error) {
                this.showError(error.response?.data?.message || 'Failed to update status')
            }
        },

        async viewSlotDetails(slot) {
            this.selectedSlot = slot
            this.showDetailsModal = true
            this.loadingBookings = true

            try {
                const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/gigs/slots/bookings', {
                    params: {
                        token: localStorage.getItem('api_token'),
                        slot_id: slot.id
                    }
                })
                if (response.data.status) {
                    this.slotBookings = response.data.data.bookings || []
                } else {
                    this.showError(response.data.message || 'Failed to load bookings')
                }
            } catch (error) {
                this.showError(error.response?.data?.message || 'Failed to load bookings')
            }
            this.loadingBookings = false
        },

        formatDate(date) {
            return moment(date).format('MMM DD, YYYY (ddd)')
        },

        isPast(date) {
            return moment(date).isBefore(moment(), 'day')
        },

        getSlotStatus(slot) {
            if (!slot.is_active) return 'Inactive'
            if (slot.booked_count >= slot.capacity) return 'Full'
            if (this.isPast(slot.slot_date)) return 'Past'
            return 'Available'
        },

        getSlotStatusColor(slot) {
            if (!slot.is_active) return 'secondary'
            if (slot.booked_count >= slot.capacity) return 'danger'
            if (this.isPast(slot.slot_date)) return 'dark'
            return 'success'
        },

        getBookingStatusColor(status) {
            const colors = {
                booked: 'info',
                active: 'primary',
                completed: 'success',
                cancelled: 'danger',
                no_show: 'warning'
            }
            return colors[status] || 'secondary'
        }
    }
}
</script>

<style scoped>
.calendar-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 15px;
    margin-top: 20px;
}

.calendar-slot {
    border: 2px solid #e3e6f0;
    border-radius: 8px;
    padding: 15px;
    background: #fff;
    transition: all 0.3s ease;
}

.calendar-slot:hover {
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    transform: translateY(-2px);
}

.slot-full {
    border-color: #e74a3b;
    background-color: #fef5f5;
}

.slot-inactive {
    border-color: #d1d3e2;
    background-color: #f8f9fc;
    opacity: 0.7;
}

.slot-past {
    border-color: #d1d3e2;
    background-color: #f5f5f5;
}

.slot-date {
    font-weight: 600;
    font-size: 14px;
    color: #5a5c69;
    margin-bottom: 10px;
}

.slot-info {
    margin-bottom: 10px;
}

.slot-capacity {
    display: flex;
    align-items: center;
    font-size: 13px;
    color: #858796;
    margin-bottom: 5px;
}

.slot-status {
    margin-top: 5px;
}

.slot-actions {
    display: flex;
    gap: 5px;
    margin-top: 10px;
}

.slot-actions .btn {
    flex: 1;
    padding: 5px;
}

.mr-1 {
    margin-right: 0.25rem;
}
</style>