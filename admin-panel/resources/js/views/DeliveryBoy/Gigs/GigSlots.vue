<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Gig Slots - {{ gigName }}</h3>
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
                            <li class="breadcrumb-item active" aria-current="page">Slots</li>
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
                            <h4>Gig Slots</h4>
                            <div class="float-end">
                                <button type="button" class="btn btn-success btn-sm me-2" @click="openBulkCreateModal">
                                    <i class="fa fa-calendar-plus"></i> Bulk Create Slots
                                </button>
                                <router-link to="/delivery-boy/gigs/list" class="btn btn-secondary btn-sm">
                                    <i class="fa fa-arrow-left"></i> Back to Gigs
                                </router-link>
                            </div>
                        </div>

                        <div class="card-body">
                            <b-row class="mb-3 align-items-end">
                                <b-col md="2">
                                    <b-form-group label="Year" label-for="year-select">
                                        <b-form-select
                                            id="year-select"
                                            v-model="selectedYear"
                                            :options="yearOptions"
                                            @change="onYearChange"
                                            class="bordered-select"
                                        ></b-form-select>
                                    </b-form-group>
                                </b-col>
                                <b-col md="2">
                                    <b-form-group label="Month" label-for="month-select">
                                        <b-form-select
                                            id="month-select"
                                            v-model="selectedMonth"
                                            :options="monthOptions"
                                            @change="onMonthChange"
                                            class="bordered-select"
                                        ></b-form-select>
                                    </b-form-group>
                                </b-col>
                                <b-col md="3">
                                    <b-form-group label="Day" label-for="day-select">
                                        <div class="d-flex align-items-center">
                                            <!-- Previous Day Button - Commented -->
                                            <!-- <button
                                                type="button"
                                                class="btn btn-outline-secondary btn-sm me-2"
                                                @click="goToPreviousDay"
                                                v-b-tooltip.hover
                                                title="Previous Day"
                                            >
                                                <i class="fa fa-chevron-left"></i>
                                            </button> -->
                                            <b-form-select
                                                id="day-select"
                                                v-model="selectedDay"
                                                :options="dayOptions"
                                                @change="onDayChange"
                                                class="flex-grow-1 bordered-select"
                                            ></b-form-select>
                                            <!-- Next Day Button - Commented -->
                                            <!-- <button
                                                type="button"
                                                class="btn btn-outline-secondary btn-sm ms-2"
                                                @click="goToNextDay"
                                                v-b-tooltip.hover
                                                title="Next Day"
                                            >
                                                <i class="fa fa-chevron-right"></i>
                                            </button> -->
                                        </div>
                                    </b-form-group>
                                </b-col>
                                <b-col md="2" class="d-flex align-items-end">
                                    <button type="button" class="btn btn-primary" v-b-tooltip.hover :title="__('refresh')" @click="loadSlots()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i> Refresh
                                    </button>
                                </b-col>
                            </b-row>

                            <div class="table-responsive">
                                <b-table
                                    :items="slots"
                                    :fields="fields"
                                    :bordered="true"
                                    :busy="loading"
                                    stacked="md"
                                    show-empty
                                    small>

                                    <template #table-busy>
                                        <div class="text-center my-2">
                                            <b-spinner class="align-middle"></b-spinner>
                                            <strong>{{ __('loading') }}...</strong>
                                        </div>
                                    </template>

                                    <template #empty>
                                        <div class="text-center py-5">
                                            <i class="fa fa-calendar fa-4x text-muted mb-3"></i>
                                            <h5 class="text-muted">No Slots Available</h5>
                                            <p class="text-muted">No slots available for {{ formatDate(selectedDate) }}</p>
                                            <button
                                                type="button"
                                                class="btn btn-primary mt-3"
                                                @click="createSlots"
                                            >
                                                <i class="fa fa-plus"></i> Create Slots
                                            </button>
                                        </div>
                                    </template>

                                    <template #cell(slot_date)="row">
                                        <strong>{{ formatDate(row.item.slot_date) }}</strong>
                                    </template>

                                    <template #cell(time)="row">
                                        <div>
                                            {{ formatTime(row.item.start_time) }} - {{ formatTime(row.item.end_time) }}
                                        </div>
                                    </template>

                                    <template #cell(capacity)="row">
                                        <div>
                                            <div class="text-center mb-1">
                                                <strong>{{ row.item.current_bookings }} / {{ row.item.max_bookings }}</strong>
                                            </div>
                                            <b-progress :value="row.item.current_bookings" :max="row.item.max_bookings" height="8px">
                                                <b-progress-bar :value="row.item.current_bookings" :variant="getCapacityVariant(row.item)">
                                                </b-progress-bar>
                                            </b-progress>
                                        </div>
                                    </template>

                                    <template #cell(availability)="row">
                                        <span :class="getAvailabilityClass(row.item)">
                                            {{ row.item.max_bookings - row.item.current_bookings }} available
                                        </span>
                                    </template>

                                    <template #cell(status)="row">
                                        <span v-if="row.item.status === 1" class="badge bg-success">Active</span>
                                        <span v-else class="badge bg-danger">Inactive</span>
                                    </template>

                                    <template #cell(actions)="row">
                                        <button
                                            class="btn btn-warning btn-sm me-1"
                                            v-b-tooltip.hover
                                            title="Edit Capacity"
                                            @click="editSlot(row.item)"
                                        >
                                            <i class="fa fa-edit"></i>
                                        </button>
                                        <button
                                            class="btn btn-info btn-sm"
                                            v-b-tooltip.hover
                                            :title="`View ${row.item.current_bookings} bookings`"
                                            @click="viewBookings(row.item)"
                                        >
                                            <i class="fa fa-users"></i> {{ row.item.current_bookings }}
                                        </button>
                                    </template>

                                </b-table>
                            </div>

                            <b-row>
                                <b-col md="4">
                                    <label>Total Slots: {{ slots.length }}</label>
                                </b-col>
                            </b-row>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Edit Slot Modal -->
        <b-modal v-model="showEditModal" title="Edit Slot" @ok="saveSlot" ok-title="Save" cancel-title="Cancel">
            <b-form>
                <b-form-group label="Max Bookings" label-for="max-bookings">
                    <b-form-input
                        id="max-bookings"
                        v-model.number="editForm.max_bookings"
                        type="number"
                        min="1"
                        required
                    ></b-form-input>
                    <small class="text-muted">Current bookings: {{ editForm.current_bookings }}</small>
                </b-form-group>

                <b-form-group label="Status" label-for="slot-status">
                    <b-form-checkbox
                        id="slot-status"
                        v-model="editForm.status"
                        :value="1"
                        :unchecked-value="0"
                        switch
                    >
                        {{ editForm.status == 1 ? 'Active' : 'Inactive' }}
                    </b-form-checkbox>
                </b-form-group>
            </b-form>
        </b-modal>

        <!-- Create Slots Modal -->
        <b-modal
            v-model="showCreateModal"
            title="Create Slots"
            size="lg"
            @ok="saveNewSlots"
            @cancel="resetCreateForm"
            ok-title="Create Slots"
            cancel-title="Cancel"
            :ok-disabled="!isFormValid"
        >
            <b-form>
                <div class="mb-3">
                    <h6 class="text-muted">Creating slots for: <strong>{{ formatDate(selectedDate) }}</strong></h6>
                    <p class="text-muted small mb-0">Gig: <strong>{{ gigDetails.display_name }}</strong></p>
                    <p class="text-muted small mb-0">Gig Timing: <strong>{{ formatTime(gigDetails.start_time) }} - {{ formatTime(gigDetails.end_time) }}</strong></p>
                    <p class="text-muted small">Slots will be created within this time range.</p>
                </div>

                <b-form-group label="Number of Slots" label-for="num-slots" description="How many time slots do you want to create for this day?">
                    <b-form-input
                        id="num-slots"
                        v-model.number="createForm.numSlots"
                        type="number"
                        min="1"
                        max="20"
                        required
                        @change="adjustSlotTimings"
                    ></b-form-input>
                </b-form-group>

                <hr>

                <div v-for="(slot, index) in createForm.slots" :key="index" class="slot-timing-item mb-4 p-3 border rounded">
                    <h6 class="mb-3">Slot {{ index + 1 }}</h6>

                    <b-row>
                        <!-- <b-col md="6">
                            <b-form-group :label="`Slot Name`" :label-for="`slot-name-${index}`">
                                <b-form-input
                                    :id="`slot-name-${index}`"
                                    v-model="slot.name"
                                    placeholder="e.g., Morning Shift"
                                    required
                                ></b-form-input>
                            </b-form-group>
                        </b-col> -->
                        <b-col md="12">
                            <b-form-group :label="`Max Bookings`" :label-for="`slot-capacity-${index}`">
                                <b-form-input
                                    :id="`slot-capacity-${index}`"
                                    v-model.number="slot.max_bookings"
                                    type="number"
                                    min="1"
                                    required
                                ></b-form-input>
                            </b-form-group>
                        </b-col>
                    </b-row>

                    <b-row>
                        <b-col md="6">
                            <b-form-group :label="`Start Time`" :label-for="`start-time-${index}`">
                                <b-form-input
                                    :id="`start-time-${index}`"
                                    v-model="slot.start_time"
                                    type="time"
                                    :min="getGigStartTime()"
                                    :max="getGigEndTime()"
                                    :class="{ 'invalid-time': isStartTimeInvalid(slot, index) }"
                                    required
                                ></b-form-input>
                                <small class="text-muted">Must be between {{ formatTime(gigDetails.start_time) }} and {{ formatTime(gigDetails.end_time) }}</small>
                                <small v-if="isStartTimeInvalid(slot, index)" class="text-danger d-block">
                                    {{ getStartTimeError(slot, index) }}
                                </small>
                            </b-form-group>
                        </b-col>
                        <b-col md="6">
                            <b-form-group :label="`End Time`" :label-for="`end-time-${index}`">
                                <b-form-input
                                    :id="`end-time-${index}`"
                                    v-model="slot.end_time"
                                    type="time"
                                    :min="getGigStartTime()"
                                    :max="getGigEndTime()"
                                    :class="{ 'invalid-time': isEndTimeInvalid(slot, index) }"
                                    required
                                ></b-form-input>
                                <small class="text-muted">Must be between {{ formatTime(gigDetails.start_time) }} and {{ formatTime(gigDetails.end_time) }}</small>
                                <small v-if="isEndTimeInvalid(slot, index)" class="text-danger d-block">
                                    {{ getEndTimeError(slot, index) }}
                                </small>
                            </b-form-group>
                        </b-col>
                    </b-row>

                    <b-form-group>
                        <b-form-checkbox
                            v-model="slot.is_active"
                            :value="1"
                            :unchecked-value="0"
                            switch
                        >
                            {{ slot.is_active == 1 ? 'Active' : 'Inactive' }}
                        </b-form-checkbox>
                    </b-form-group>
                </div>
            </b-form>
        </b-modal>

        <!-- Bulk Create Slots Modal -->
        <b-modal
            v-model="showBulkCreateModal"
            title="Bulk Create Slots"
            size="xl"
            @ok="saveBulkSlots"
            ok-title="Create Bulk Slots"
            cancel-title="Cancel"
            :ok-disabled="!isBulkFormValid"
        >
            <b-form>
                <div class="mb-3">
                    <h6 class="text-muted">Bulk create slots for: <strong>{{ gigDetails.display_name }}</strong></h6>
                    <p class="text-muted small mb-0">Gig Timing: <strong>{{ formatTime(gigDetails.start_time) }} - {{ formatTime(gigDetails.end_time) }}</strong></p>
                    <p class="text-muted small">Slots will be created for each day in the selected date range.</p>
                </div>

                <b-row>
                    <b-col md="6">
                        <b-form-group label="From Date" label-for="bulk-from-date">
                            <b-form-input
                                id="bulk-from-date"
                                v-model="bulkForm.from_date"
                                type="date"
                                required
                            ></b-form-input>
                        </b-form-group>
                    </b-col>
                    <b-col md="6">
                        <b-form-group label="To Date" label-for="bulk-to-date">
                            <b-form-input
                                id="bulk-to-date"
                                v-model="bulkForm.to_date"
                                type="date"
                                :min="bulkForm.from_date"
                                required
                            ></b-form-input>
                        </b-form-group>
                    </b-col>
                </b-row>

                <b-form-group label="Number of Slots Per Day" label-for="bulk-num-slots" description="How many time slots per day?">
                    <b-form-input
                        id="bulk-num-slots"
                        v-model.number="bulkForm.numSlots"
                        type="number"
                        min="1"
                        max="20"
                        required
                        @change="adjustBulkSlotTimings"
                    ></b-form-input>
                </b-form-group>

                <hr>

                <div v-for="(slot, index) in bulkForm.slots" :key="index" class="slot-timing-item mb-4 p-3 border rounded">
                    <h6 class="mb-3">Slot {{ index + 1 }} (will be created for each day)</h6>

                    <b-row>
                        <b-col md="12">
                            <b-form-group :label="`Max Bookings`" :label-for="`bulk-slot-capacity-${index}`">
                                <b-form-input
                                    :id="`bulk-slot-capacity-${index}`"
                                    v-model.number="slot.max_bookings"
                                    type="number"
                                    min="1"
                                    required
                                ></b-form-input>
                            </b-form-group>
                        </b-col>
                    </b-row>

                    <b-row>
                        <b-col md="6">
                            <b-form-group :label="`Start Time`" :label-for="`bulk-start-time-${index}`">
                                <b-form-input
                                    :id="`bulk-start-time-${index}`"
                                    v-model="slot.start_time"
                                    type="time"
                                    :min="getGigStartTime()"
                                    :max="getGigEndTime()"
                                    :class="{ 'invalid-time': isBulkStartTimeInvalid(slot, index) }"
                                    required
                                ></b-form-input>
                                <small class="text-muted">Must be between {{ formatTime(gigDetails.start_time) }} and {{ formatTime(gigDetails.end_time) }}</small>
                                <small v-if="isBulkStartTimeInvalid(slot, index)" class="text-danger d-block">
                                    {{ getBulkStartTimeError(slot, index) }}
                                </small>
                            </b-form-group>
                        </b-col>
                        <b-col md="6">
                            <b-form-group :label="`End Time`" :label-for="`bulk-end-time-${index}`">
                                <b-form-input
                                    :id="`bulk-end-time-${index}`"
                                    v-model="slot.end_time"
                                    type="time"
                                    :min="getGigStartTime()"
                                    :max="getGigEndTime()"
                                    :class="{ 'invalid-time': isBulkEndTimeInvalid(slot, index) }"
                                    required
                                ></b-form-input>
                                <small class="text-muted">Must be between {{ formatTime(gigDetails.start_time) }} and {{ formatTime(gigDetails.end_time) }}</small>
                                <small v-if="isBulkEndTimeInvalid(slot, index)" class="text-danger d-block">
                                    {{ getBulkEndTimeError(slot, index) }}
                                </small>
                            </b-form-group>
                        </b-col>
                    </b-row>

                    <b-form-group>
                        <b-form-checkbox
                            v-model="slot.is_active"
                            :value="1"
                            :unchecked-value="0"
                            switch
                        >
                            {{ slot.is_active == 1 ? 'Active' : 'Inactive' }}
                        </b-form-checkbox>
                    </b-form-group>
                </div>
            </b-form>
        </b-modal>
    </div>
</template>

<script>
import axios from 'axios'
import moment from 'moment'

export default {
    name: 'GigSlots',
    data() {
        const today = moment()
        return {
            loading: false,
            gigId: null,
            gigName: '',
            gigDetails: {
                id: null,
                name: '',
                display_name: '',
                start_time: '06:00:00',
                end_time: '13:00:00',
                duration_hours: 7
            },
            slots: [],
            selectedYear: today.year(),
            selectedMonth: today.month() + 1, // moment months are 0-indexed
            selectedDay: today.date(),
            fields: [
                { key: 'slot_date', label: 'Date', sortable: true, class: 'text-center' },
                // { key: 'slot_name', label: 'Slot Name', sortable: true },
                { key: 'time', label: 'Time', class: 'text-center' },
                { key: 'capacity', label: 'Capacity', class: 'text-center' },
                { key: 'availability', label: 'Availability', class: 'text-center' },
                { key: 'status', label: 'Status', class: 'text-center' },
                { key: 'actions', label: 'Actions', class: 'text-center' }
            ],
            showEditModal: false,
            editForm: {
                slot_id: null,
                max_bookings: 0,
                current_bookings: 0,
                status: 1
            },
            showCreateModal: false,
            createForm: {
                numSlots: 1,
                slots: [
                    {
                        name: 'Morning Shift',
                        start_time: '09:00',
                        end_time: '12:00',
                        max_bookings: 10,
                        is_active: 1
                    }
                ]
            },
            showBulkCreateModal: false,
            bulkForm: {
                from_date: moment().format('YYYY-MM-DD'),
                to_date: moment().add(7, 'days').format('YYYY-MM-DD'),
                numSlots: 1,
                slots: [
                    {
                        name: 'Morning Shift',
                        start_time: '09:00',
                        end_time: '12:00',
                        max_bookings: 10,
                        is_active: 1
                    }
                ]
            }
        }
    },
    computed: {
        yearOptions() {
            const years = []
            const startYear = 2026
            const endYear = 3000
            for (let i = startYear; i <= endYear; i++) {
                years.push({ value: i, text: i.toString() })
            }
            return years
        },
        monthOptions() {
            return [
                { value: 1, text: 'January' },
                { value: 2, text: 'February' },
                { value: 3, text: 'March' },
                { value: 4, text: 'April' },
                { value: 5, text: 'May' },
                { value: 6, text: 'June' },
                { value: 7, text: 'July' },
                { value: 8, text: 'August' },
                { value: 9, text: 'September' },
                { value: 10, text: 'October' },
                { value: 11, text: 'November' },
                { value: 12, text: 'December' }
            ]
        },
        dayOptions() {
            const daysInMonth = moment(`${this.selectedYear}-${this.selectedMonth}`, 'YYYY-M').daysInMonth()
            const days = []
            for (let i = 1; i <= daysInMonth; i++) {
                const dateStr = moment(`${this.selectedYear}-${this.selectedMonth}-${i}`, 'YYYY-M-D').format('DD - dddd')
                days.push({ value: i, text: dateStr })
            }
            return days
        },
        selectedDate() {
            return moment(`${this.selectedYear}-${this.selectedMonth}-${this.selectedDay}`, 'YYYY-M-D').format('YYYY-MM-DD')
        },
        isFormValid() {
            const gigStartTime = this.getGigStartTime()
            const gigEndTime = this.getGigEndTime()

            for (let slot of this.createForm.slots) {
                // Check if all required fields are filled (slot.name is nullable)
                if (!slot.start_time || !slot.end_time || !slot.max_bookings) {
                    return false
                }

                // Check if times are within gig range
                if (slot.start_time < gigStartTime || slot.start_time > gigEndTime) {
                    return false
                }

                if (slot.end_time < gigStartTime || slot.end_time > gigEndTime) {
                    return false
                }

                // Check if start time is before end time
                if (slot.start_time >= slot.end_time) {
                    return false
                }
            }

            return true
        },
        isBulkFormValid() {
            if (!this.bulkForm.from_date || !this.bulkForm.to_date) {
                return false
            }

            const gigStartTime = this.getGigStartTime()
            const gigEndTime = this.getGigEndTime()

            for (let slot of this.bulkForm.slots) {
                if (!slot.start_time || !slot.end_time || !slot.max_bookings) {
                    return false
                }

                if (slot.start_time < gigStartTime || slot.start_time > gigEndTime) {
                    return false
                }

                if (slot.end_time < gigStartTime || slot.end_time > gigEndTime) {
                    return false
                }

                if (slot.start_time >= slot.end_time) {
                    return false
                }
            }

            return true
        }
    },
    mounted() {
        this.gigId = this.$route.params.id
        this.loadGigDetails()
        this.loadSlots()
    },
    methods: {
        async loadGigDetails() {
            try {
                // Load gig details from the gigs list API
                const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/gigs', {
                    params: {
                        token: localStorage.getItem('api_token')
                    }
                })

                if (response.data.status && response.data.data.gigs) {
                    const gig = response.data.data.gigs.find(g => g.id == this.gigId)
                    if (gig) {
                        this.gigDetails = {
                            id: gig.id,
                            name: gig.name,
                            display_name: gig.display_name,
                            start_time: gig.start_time,
                            end_time: gig.end_time,
                            duration_hours: gig.duration_hours
                        }
                        this.gigName = this.gigDetails.display_name || this.gigDetails.name
                    }
                }
            } catch (error) {
                console.error('Failed to load gig details:', error)
                // Fallback - don't show error, just use default values
            }
        },

        async loadSlots() {
            this.loading = true
            try {
                const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/gigs/slots', {
                    params: {
                        token: localStorage.getItem('api_token'),
                        gig_id: this.gigId,
                        from_date: this.selectedDate,
                        to_date: this.selectedDate
                    }
                })

                if (response.data.status) {
                    this.slots = response.data.data.slots
                    if (this.slots.length > 0 && this.slots[0].gig) {
                        this.gigName = this.slots[0].gig.display_name || this.slots[0].gig.name
                    }
                } else {
                    this.showError(response.data.message || 'Failed to load slots')
                }
            } catch (error) {
                this.showError(error.response?.data?.message || 'Failed to load slots')
            }
            this.loading = false
        },

        onYearChange() {
            // Check if selected day is valid for the new year/month combination
            const daysInMonth = moment(`${this.selectedYear}-${this.selectedMonth}`, 'YYYY-M').daysInMonth()
            if (this.selectedDay > daysInMonth) {
                this.selectedDay = daysInMonth
            }
            this.loadSlots()
        },

        onMonthChange() {
            // Check if selected day is valid for the new month
            const daysInMonth = moment(`${this.selectedYear}-${this.selectedMonth}`, 'YYYY-M').daysInMonth()
            if (this.selectedDay > daysInMonth) {
                this.selectedDay = daysInMonth
            }
            this.loadSlots()
        },

        onDayChange() {
            this.loadSlots()
        },

        goToPreviousDay() {
            const currentDate = moment(`${this.selectedYear}-${this.selectedMonth}-${this.selectedDay}`, 'YYYY-M-D')
            const previousDay = currentDate.subtract(1, 'day')

            this.selectedYear = previousDay.year()
            this.selectedMonth = previousDay.month() + 1
            this.selectedDay = previousDay.date()

            this.loadSlots()
        },

        goToNextDay() {
            const currentDate = moment(`${this.selectedYear}-${this.selectedMonth}-${this.selectedDay}`, 'YYYY-M-D')
            const nextDay = currentDate.add(1, 'day')

            this.selectedYear = nextDay.year()
            this.selectedMonth = nextDay.month() + 1
            this.selectedDay = nextDay.date()

            this.loadSlots()
        },

        createSlots() {
            this.resetCreateForm()
            this.showCreateModal = true
        },

        adjustSlotTimings() {
            const currentLength = this.createForm.slots.length
            const targetLength = this.createForm.numSlots

            if (targetLength > currentLength) {
                // Calculate slot duration based on gig timing and number of slots
                const gigStart = moment(this.gigDetails.start_time, 'HH:mm:ss')
                const gigEnd = moment(this.gigDetails.end_time, 'HH:mm:ss')

                // Handle overnight shifts (e.g., 22:00:00 to 02:00:00)
                if (gigEnd.isBefore(gigStart)) {
                    gigEnd.add(1, 'day')
                }

                const totalMinutes = gigEnd.diff(gigStart, 'minutes')
                const slotDurationMinutes = Math.floor(totalMinutes / targetLength)

                // Add new slots
                for (let i = currentLength; i < targetLength; i++) {
                    const prevSlot = this.createForm.slots[i - 1]
                    let startMoment

                    if (prevSlot) {
                        // Continue from previous slot's end time
                        startMoment = moment(prevSlot.end_time, 'HH:mm')
                    } else {
                        // Start from gig start time for the first slot
                        startMoment = moment(this.gigDetails.start_time, 'HH:mm:ss')
                    }

                    const endMoment = startMoment.clone().add(slotDurationMinutes, 'minutes')

                    // Generate slot name from time range (e.g., "12:00 AM - 02:00 AM")
                    const slotName = `${startMoment.format('hh:mm A')} - ${endMoment.format('hh:mm A')}`

                    this.createForm.slots.push({
                        name: slotName,
                        start_time: startMoment.format('HH:mm'),
                        end_time: endMoment.format('HH:mm'),
                        max_bookings: 10,
                        is_active: 1
                    })
                }
            } else if (targetLength < currentLength) {
                // Remove excess slots
                this.createForm.slots.splice(targetLength)
            }
        },

        resetCreateForm() {
            // Use gig's start and end times
            const gigStart = moment(this.gigDetails.start_time, 'HH:mm:ss')
            const gigEnd = moment(this.gigDetails.end_time, 'HH:mm:ss')

            // Handle overnight shifts
            if (gigEnd.isBefore(gigStart)) {
                gigEnd.add(1, 'day')
            }

            // Generate slot name from time range (e.g., "06:00 AM - 01:00 PM")
            const slotName = `${gigStart.format('hh:mm A')} - ${gigEnd.format('hh:mm A')}`

            this.createForm = {
                numSlots: 1,
                slots: [
                    {
                        name: slotName,
                        start_time: gigStart.format('HH:mm'),
                        end_time: gigEnd.format('HH:mm'),
                        max_bookings: 10,
                        is_active: 1
                    }
                ]
            }
        },

        async saveNewSlots(bvModalEvent) {
            // Prevent modal from closing by default
            bvModalEvent.preventDefault()

            const gigStartTime = this.getGigStartTime()
            const gigEndTime = this.getGigEndTime()

            // Validate the form (slot.name is nullable)
            for (let i = 0; i < this.createForm.slots.length; i++) {
                const slot = this.createForm.slots[i]
                if (!slot.start_time || !slot.end_time || !slot.max_bookings) {
                    this.showError(`Please fill in all fields for Slot ${i + 1}`)
                    return
                }

                // Validate time is within gig range
                if (slot.start_time < gigStartTime || slot.start_time > gigEndTime) {
                    this.showError(`Slot ${i + 1}: Start time must be between ${this.formatTime(this.gigDetails.start_time)} and ${this.formatTime(this.gigDetails.end_time)}`)
                    return
                }

                if (slot.end_time < gigStartTime || slot.end_time > gigEndTime) {
                    this.showError(`Slot ${i + 1}: End time must be between ${this.formatTime(this.gigDetails.start_time)} and ${this.formatTime(this.gigDetails.end_time)}`)
                    return
                }

                // Validate time
                if (slot.start_time >= slot.end_time) {
                    this.showError(`Start time must be before end time for Slot ${i + 1}`)
                    return
                }
            }

            try {
                // Transform slots to match API expected format (capacity instead of max_bookings)
                const slotsPayload = this.createForm.slots.map(slot => ({
                    name: slot.name,
                    start_time: slot.start_time,
                    end_time: slot.end_time,
                    capacity: slot.max_bookings,
                    is_active: slot.is_active
                }))

                const response = await axios.post(this.$apiUrl + '/admin/delivery-boys/gigs/slots/create-multiple', {
                    token: localStorage.getItem('api_token'),
                    gig_id: this.gigId,
                    start_date: this.selectedDate,
                    end_date: this.selectedDate,
                    slots: slotsPayload
                })

                if (response.data.status) {
                    this.showSuccess('Slots created successfully')
                    this.showCreateModal = false
                    this.loadSlots()
                } else {
                    // Show error but keep modal open
                    this.showError(response.data.message || 'Failed to create slots')
                }
            } catch (error) {
                // Show error but keep modal open
                this.showError(error.response?.data?.message || 'Failed to create slots')
            }
        },

        editSlot(slot) {
            this.editForm = {
                slot_id: slot.id,
                max_bookings: slot.max_bookings,
                current_bookings: slot.current_bookings,
                status: slot.status
            }
            this.showEditModal = true
        },

        async saveSlot() {
            if (this.editForm.max_bookings < this.editForm.current_bookings) {
                this.showError('Max bookings cannot be less than current bookings')
                return
            }

            try {
                const response = await axios.post(this.$apiUrl + '/admin/delivery-boys/gigs/slots/update', {
                    token: localStorage.getItem('api_token'),
                    slot_id: this.editForm.slot_id,
                    capacity: this.editForm.max_bookings,
                    is_active: this.editForm.status
                })

                if (response.data.status) {
                    this.showSuccess('Slot updated successfully')
                    this.loadSlots()
                } else {
                    this.showError(response.data.message || 'Failed to update slot')
                }
            } catch (error) {
                this.showError(error.response?.data?.message || 'Failed to update slot')
            }
        },

        viewBookings(slot) {
            this.$router.push(`/delivery-boy/gigs/${this.gigId}/slots/${slot.id}/bookings`)
        },

        formatDate(date) {
            return moment(date).format('MMM DD, YYYY')
        },

        formatTime(time) {
            if (!time) return '-'
            return moment(time, 'HH:mm:ss').format('hh:mm A')
        },

        getAvailabilityClass(slot) {
            const available = slot.max_bookings - slot.current_bookings
            const percentage = (available / slot.max_bookings) * 100

            if (percentage > 50) return 'badge bg-success'
            if (percentage > 20) return 'badge bg-warning'
            return 'badge bg-danger'
        },

        getCapacityVariant(slot) {
            const percentage = (slot.current_bookings / slot.max_bookings) * 100

            if (percentage >= 80) return 'danger'  // Red when >= 80% full
            if (percentage >= 50) return 'warning' // Yellow when >= 50% full
            return 'success'                        // Green when < 50% full
        },

        getGigStartTime() {
            // Return time in HH:mm format for input min/max
            return moment(this.gigDetails.start_time, 'HH:mm:ss').format('HH:mm')
        },

        getGigEndTime() {
            // Return time in HH:mm format for input min/max
            return moment(this.gigDetails.end_time, 'HH:mm:ss').format('HH:mm')
        },

        isSlotInvalid(slot) {
            const gigStartTime = this.getGigStartTime()
            const gigEndTime = this.getGigEndTime()

            // Check if all required fields are filled
            if (!slot.name || !slot.start_time || !slot.end_time || !slot.max_bookings) {
                return true
            }

            // Check if times are within gig range
            if (slot.start_time < gigStartTime || slot.start_time > gigEndTime) {
                return true
            }

            if (slot.end_time < gigStartTime || slot.end_time > gigEndTime) {
                return true
            }

            // Check if start time is before end time
            if (slot.start_time >= slot.end_time) {
                return true
            }

            return false
        },

        isStartTimeInvalid(slot, index) {
            if (!slot.start_time) return false

            const gigStartTime = this.getGigStartTime()
            const gigEndTime = this.getGigEndTime()

            // Check if within gig range
            if (slot.start_time < gigStartTime || slot.start_time > gigEndTime) {
                return true
            }

            // Check if start time is before end time (if end time exists)
            if (slot.end_time && slot.start_time >= slot.end_time) {
                return true
            }

            // Check for overlap with other slots
            return this.hasOverlapWithOthers(index)
        },

        isEndTimeInvalid(slot, index) {
            if (!slot.end_time) return false

            const gigStartTime = this.getGigStartTime()
            const gigEndTime = this.getGigEndTime()

            // Check if within gig range
            if (slot.end_time < gigStartTime || slot.end_time > gigEndTime) {
                return true
            }

            // Check if end time is after start time (if start time exists)
            if (slot.start_time && slot.start_time >= slot.end_time) {
                return true
            }

            // Check for overlap with other slots
            return this.hasOverlapWithOthers(index)
        },

        hasOverlapWithOthers(currentIndex) {
            const currentSlot = this.createForm.slots[currentIndex]
            if (!currentSlot.start_time || !currentSlot.end_time) return false

            for (let i = 0; i < this.createForm.slots.length; i++) {
                if (i === currentIndex) continue

                const otherSlot = this.createForm.slots[i]
                if (!otherSlot.start_time || !otherSlot.end_time) continue

                // Check if slots overlap
                // Overlap occurs if: (StartA < EndB) and (EndA > StartB)
                if (currentSlot.start_time < otherSlot.end_time && currentSlot.end_time > otherSlot.start_time) {
                    return true
                }
            }

            return false
        },

        getStartTimeError(slot, index) {
            const gigStartTime = this.getGigStartTime()
            const gigEndTime = this.getGigEndTime()

            if (slot.start_time < gigStartTime || slot.start_time > gigEndTime) {
                return `Time outside gig range (${this.formatTime(this.gigDetails.start_time)} - ${this.formatTime(this.gigDetails.end_time)})`
            }

            if (slot.end_time && slot.start_time >= slot.end_time) {
                return 'Start time must be before end time'
            }

            if (this.hasOverlapWithOthers(index)) {
                return 'Timings overlapped with another slot'
            }

            return ''
        },

        getEndTimeError(slot, index) {
            const gigStartTime = this.getGigStartTime()
            const gigEndTime = this.getGigEndTime()

            if (slot.end_time < gigStartTime || slot.end_time > gigEndTime) {
                return `Time outside gig range (${this.formatTime(this.gigDetails.start_time)} - ${this.formatTime(this.gigDetails.end_time)})`
            }

            if (slot.start_time && slot.start_time >= slot.end_time) {
                return 'End time must be after start time'
            }

            if (this.hasOverlapWithOthers(index)) {
                return 'Timings overlapped with another slot'
            }

            return ''
        },

        // Bulk create modal methods
        openBulkCreateModal() {
            this.resetBulkForm()
            this.showBulkCreateModal = true
        },

        resetBulkForm() {
            const gigStart = moment(this.gigDetails.start_time, 'HH:mm:ss')
            const gigEnd = moment(this.gigDetails.end_time, 'HH:mm:ss')

            if (gigEnd.isBefore(gigStart)) {
                gigEnd.add(1, 'day')
            }

            const slotName = `${gigStart.format('hh:mm A')} - ${gigEnd.format('hh:mm A')}`

            this.bulkForm = {
                from_date: moment().format('YYYY-MM-DD'),
                to_date: moment().add(7, 'days').format('YYYY-MM-DD'),
                numSlots: 1,
                slots: [
                    {
                        name: slotName,
                        start_time: gigStart.format('HH:mm'),
                        end_time: gigEnd.format('HH:mm'),
                        max_bookings: 10,
                        is_active: 1
                    }
                ]
            }
        },

        adjustBulkSlotTimings() {
            const currentLength = this.bulkForm.slots.length
            const targetLength = this.bulkForm.numSlots

            if (targetLength > currentLength) {
                const gigStart = moment(this.gigDetails.start_time, 'HH:mm:ss')
                const gigEnd = moment(this.gigDetails.end_time, 'HH:mm:ss')

                if (gigEnd.isBefore(gigStart)) {
                    gigEnd.add(1, 'day')
                }

                const totalMinutes = gigEnd.diff(gigStart, 'minutes')
                const slotDurationMinutes = Math.floor(totalMinutes / targetLength)

                for (let i = currentLength; i < targetLength; i++) {
                    const prevSlot = this.bulkForm.slots[i - 1]
                    let startMoment

                    if (prevSlot) {
                        startMoment = moment(prevSlot.end_time, 'HH:mm')
                    } else {
                        startMoment = moment(this.gigDetails.start_time, 'HH:mm:ss')
                    }

                    const endMoment = startMoment.clone().add(slotDurationMinutes, 'minutes')
                    const slotName = `${startMoment.format('hh:mm A')} - ${endMoment.format('hh:mm A')}`

                    this.bulkForm.slots.push({
                        name: slotName,
                        start_time: startMoment.format('HH:mm'),
                        end_time: endMoment.format('HH:mm'),
                        max_bookings: 10,
                        is_active: 1
                    })
                }
            } else if (targetLength < currentLength) {
                this.bulkForm.slots.splice(targetLength)
            }
        },

        async saveBulkSlots(bvModalEvent) {
            bvModalEvent.preventDefault()

            const gigStartTime = this.getGigStartTime()
            const gigEndTime = this.getGigEndTime()

            // Validate dates
            if (!this.bulkForm.from_date || !this.bulkForm.to_date) {
                this.showError('Please select both From and To dates')
                return
            }

            // Validate form
            for (let i = 0; i < this.bulkForm.slots.length; i++) {
                const slot = this.bulkForm.slots[i]
                if (!slot.start_time || !slot.end_time || !slot.max_bookings) {
                    this.showError(`Please fill in all fields for Slot ${i + 1}`)
                    return
                }

                if (slot.start_time < gigStartTime || slot.start_time > gigEndTime) {
                    this.showError(`Slot ${i + 1}: Start time must be between ${this.formatTime(this.gigDetails.start_time)} and ${this.formatTime(this.gigDetails.end_time)}`)
                    return
                }

                if (slot.end_time < gigStartTime || slot.end_time > gigEndTime) {
                    this.showError(`Slot ${i + 1}: End time must be between ${this.formatTime(this.gigDetails.start_time)} and ${this.formatTime(this.gigDetails.end_time)}`)
                    return
                }

                if (slot.start_time >= slot.end_time) {
                    this.showError(`Start time must be before end time for Slot ${i + 1}`)
                    return
                }
            }

            try {
                const slotsPayload = this.bulkForm.slots.map(slot => ({
                    name: slot.name,
                    start_time: slot.start_time,
                    end_time: slot.end_time,
                    capacity: slot.max_bookings,
                    is_active: slot.is_active
                }))

                const response = await axios.post(this.$apiUrl + '/admin/delivery-boys/gigs/slots/create-multiple', {
                    token: localStorage.getItem('api_token'),
                    gig_id: this.gigId,
                    start_date: this.bulkForm.from_date,
                    end_date: this.bulkForm.to_date,
                    slots: slotsPayload
                })

                if (response.data.status) {
                    this.showSuccess(`${response.data.data.slots_created} slots created successfully`)
                    this.showBulkCreateModal = false
                    this.loadSlots()
                } else {
                    this.showError(response.data.message || 'Failed to create slots')
                }
            } catch (error) {
                this.showError(error.response?.data?.message || 'Failed to create slots')
            }
        },

        // Bulk form validation methods
        isBulkStartTimeInvalid(slot, index) {
            if (!slot.start_time) return false

            const gigStartTime = this.getGigStartTime()
            const gigEndTime = this.getGigEndTime()

            if (slot.start_time < gigStartTime || slot.start_time > gigEndTime) {
                return true
            }

            if (slot.end_time && slot.start_time >= slot.end_time) {
                return true
            }

            return this.hasBulkOverlapWithOthers(index)
        },

        isBulkEndTimeInvalid(slot, index) {
            if (!slot.end_time) return false

            const gigStartTime = this.getGigStartTime()
            const gigEndTime = this.getGigEndTime()

            if (slot.end_time < gigStartTime || slot.end_time > gigEndTime) {
                return true
            }

            if (slot.start_time && slot.start_time >= slot.end_time) {
                return true
            }

            return this.hasBulkOverlapWithOthers(index)
        },

        hasBulkOverlapWithOthers(currentIndex) {
            const currentSlot = this.bulkForm.slots[currentIndex]
            if (!currentSlot.start_time || !currentSlot.end_time) return false

            for (let i = 0; i < this.bulkForm.slots.length; i++) {
                if (i === currentIndex) continue

                const otherSlot = this.bulkForm.slots[i]
                if (!otherSlot.start_time || !otherSlot.end_time) continue

                if (currentSlot.start_time < otherSlot.end_time && currentSlot.end_time > otherSlot.start_time) {
                    return true
                }
            }

            return false
        },

        getBulkStartTimeError(slot, index) {
            const gigStartTime = this.getGigStartTime()
            const gigEndTime = this.getGigEndTime()

            if (slot.start_time < gigStartTime || slot.start_time > gigEndTime) {
                return `Time outside gig range (${this.formatTime(this.gigDetails.start_time)} - ${this.formatTime(this.gigDetails.end_time)})`
            }

            if (slot.end_time && slot.start_time >= slot.end_time) {
                return 'Start time must be before end time'
            }

            if (this.hasBulkOverlapWithOthers(index)) {
                return 'Timings overlapped with another slot'
            }

            return ''
        },

        getBulkEndTimeError(slot, index) {
            const gigStartTime = this.getGigStartTime()
            const gigEndTime = this.getGigEndTime()

            if (slot.end_time < gigStartTime || slot.end_time > gigEndTime) {
                return `Time outside gig range (${this.formatTime(this.gigDetails.start_time)} - ${this.formatTime(this.gigDetails.end_time)})`
            }

            if (slot.start_time && slot.start_time >= slot.end_time) {
                return 'End time must be after start time'
            }

            if (this.hasBulkOverlapWithOthers(index)) {
                return 'Timings overlapped with another slot'
            }

            return ''
        }
    }
}
</script>

<style scoped>
.me-1 {
    margin-right: 0.25rem;
}

.me-2 {
    margin-right: 0.5rem;
}

.ms-2 {
    margin-left: 0.5rem;
}

.flex-grow-1 {
    flex-grow: 1;
}

/* Add borders to the date filter dropdowns */
.bordered-select {
    border: 2px solid #dee2e6 !important;
    border-radius: 0.25rem;
    padding: 0.375rem 0.75rem;
}

.bordered-select:focus {
    border-color: #80bdff !important;
    box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
}

/* Slot timing item styling */
.slot-timing-item {
    background-color: #f8f9fa;
    border: 1px solid #dee2e6;
    border-radius: 0.5rem;
    transition: all 0.2s ease-in-out;
}

.slot-timing-item:hover {
    background-color: #e9ecef;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

/* Invalid time input field styling with red border */
.invalid-time {
    border: 2px solid #dc3545 !important;
    background-color: #fff5f5;
}

.invalid-time:focus {
    border-color: #dc3545 !important;
    box-shadow: 0 0 0 0.2rem rgba(220, 53, 69, 0.25);
}
</style>

<!-- Dark Mode Styles (unscoped to access body.theme-dark) -->
<style>
/* GigSlots - Dark Mode Overrides */

/* Modal dark mode */
.theme-dark .modal-content {
    background-color: #2a2e33;
    color: #c2c2d9;
    border-color: #3d4147;
}

.theme-dark .modal-header {
    border-bottom-color: #3d4147;
}

.theme-dark .modal-header .close,
.theme-dark .modal-header .btn-close {
    color: #c2c2d9;
    filter: invert(1);
}

.theme-dark .modal-footer {
    border-top-color: #3d4147;
}

/* Form inputs inside modals */
.theme-dark .modal-body .form-control {
    background-color: #1e2227;
    color: #c2c2d9;
    border-color: #3d4147;
}

.theme-dark .modal-body .form-control:focus {
    background-color: #1e2227;
    color: #c2c2d9;
    border-color: #9AC444;
    box-shadow: 0 0 0 0.2rem rgba(154, 196, 68, 0.25);
}

/* Labels and text inside modals */
.theme-dark .modal-body label,
.theme-dark .modal-body .col-form-label {
    color: #c2c2d9;
}

.theme-dark .modal-body h6 {
    color: #c2c2d9;
}

/* Custom switch/checkbox in modals */
.theme-dark .modal-body .custom-control-label {
    color: #c2c2d9;
}

.theme-dark .modal-body .custom-switch .custom-control-label::before {
    background-color: #3d4147;
    border-color: #3d4147;
}

/* Slot timing items inside modals */
.theme-dark .slot-timing-item {
    background-color: #1e2227 !important;
    border-color: #3d4147 !important;
}

.theme-dark .slot-timing-item:hover {
    background-color: #252a30 !important;
}

/* HR divider in modals */
.theme-dark .modal-body hr {
    border-color: #3d4147;
}

/* Bordered select (date filters on page) */
.theme-dark .bordered-select {
    border-color: #3d4147 !important;
    background-color: #1e2227;
    color: #c2c2d9;
}

.theme-dark .bordered-select:focus {
    border-color: #9AC444 !important;
    box-shadow: 0 0 0 0.2rem rgba(154, 196, 68, 0.25);
}

/* Invalid time field in dark mode */
.theme-dark .invalid-time {
    background-color: rgba(220, 53, 69, 0.15) !important;
}

/* Form description text in modals */
.theme-dark .modal-body .form-text {
    color: #adb5bd !important;
}

/* Modal backdrop for dark mode */
.theme-dark .modal-body .text-muted strong {
    color: #c2c2d9;
}
</style>