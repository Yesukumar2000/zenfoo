<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Gig Bookings Management</h3>
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
                            <li class="breadcrumb-item active" aria-current="page">Bookings</li>
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
                            <h4>All Bookings</h4>
                            <button class="btn btn-secondary btn-sm float-end" @click="exportBookings">
                                <i class="fa fa-download"></i> Export Report
                            </button>
                        </div>

                        <div class="card-body">
                            <!-- Filters -->
                            <b-row class="mb-3">
                                <b-col md="3">
                                    <label>Search Partner</label>
                                    <b-form-input
                                        v-model="filters.search"
                                        placeholder="Name, phone..."
                                        @input="debounceSearch"
                                    ></b-form-input>
                                </b-col>
                                <b-col md="3">
                                    <label>Select Gig</label>
                                    <b-form-select
                                        v-model="filters.gigId"
                                        :options="gigOptions"
                                        @change="loadBookings"
                                    ></b-form-select>
                                </b-col>
                                <b-col md="2">
                                    <label>Status</label>
                                    <b-form-select
                                        v-model="filters.status"
                                        :options="statusOptions"
                                        @change="loadBookings"
                                    ></b-form-select>
                                </b-col>
                                <b-col md="2">
                                    <label>From Date</label>
                                    <b-form-input
                                        type="date"
                                        v-model="filters.fromDate"
                                        @input="loadBookings"
                                    ></b-form-input>
                                </b-col>
                                <b-col md="2">
                                    <label>To Date</label>
                                    <b-form-input
                                        type="date"
                                        v-model="filters.toDate"
                                        @input="loadBookings"
                                    ></b-form-input>
                                </b-col>
                            </b-row>

                            <!-- Stats Cards -->
                            <b-row class="mb-4">
                                <b-col sm="3">
                                    <div class="card bg-primary text-white">
                                        <div class="card-body">
                                            <div class="d-flex align-items-center">
                                                <i class="fa fa-calendar-check-o fa-3x mr-3"></i>
                                                <div>
                                                    <h5 class="mb-0">{{ stats.total_bookings }}</h5>
                                                    <small>Total Bookings</small>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </b-col>
                                <b-col sm="3">
                                    <div class="card bg-success text-white">
                                        <div class="card-body">
                                            <div class="d-flex align-items-center">
                                                <i class="fa fa-tasks fa-3x mr-3"></i>
                                                <div>
                                                    <h5 class="mb-0">{{ stats.active_today }}</h5>
                                                    <small>Active Today</small>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </b-col>
                                <b-col sm="3">
                                    <div class="card bg-info text-white">
                                        <div class="card-body">
                                            <div class="d-flex align-items-center">
                                                <i class="fa fa-check-circle fa-3x mr-3"></i>
                                                <div>
                                                    <h5 class="mb-0">{{ stats.completed_today }}</h5>
                                                    <small>Completed Today</small>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </b-col>
                                <b-col sm="3">
                                    <div class="card bg-warning text-white">
                                        <div class="card-body">
                                            <div class="d-flex align-items-center">
                                                <i class="fa fa-money fa-3x mr-3"></i>
                                                <div>
                                                    <h5 class="mb-0">{{ $currency }}{{ stats.total_earnings }}</h5>
                                                    <small>Total Earnings</small>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </b-col>
                            </b-row>

                            <!-- Bookings Table -->
                            <div class="table-responsive">
                                <b-table
                                    :items="bookings"
                                    :fields="fields"
                                    :busy="loading"
                                    hover
                                    striped
                                    bordered
                                    show-empty
                                >
                                    <template #table-busy>
                                        <div class="text-center text-black my-2">
                                            <b-spinner class="align-middle"></b-spinner>
                                            <strong>Loading...</strong>
                                        </div>
                                    </template>

                                    <template #cell(partner)="row">
                                        <div class="d-flex align-items-center">
                                            <img
                                                :src="row.item.delivery_boy.profile_image_url || '/img/default-avatar.png'"
                                                class="mr-2"
                                                width="40"
                                                height="40"
                                                style="border-radius: 50%; object-fit: cover;"
                                            />
                                            <div>
                                                <strong>{{ row.item.delivery_boy.name }}</strong>
                                                <br>
                                                <small class="text-muted">{{ row.item.delivery_boy.phone }}</small>
                                            </div>
                                        </div>
                                    </template>

                                    <template #cell(gig)="row">
                                        <strong>{{ row.item.gig_slot.gig.gig_name }}</strong>
                                        <br>
                                        <small class="text-muted">
                                            <i class="fa fa-clock-o mr-1"></i>
                                            {{ formatTime(row.item.gig_slot.gig.start_time) }} - {{ formatTime(row.item.gig_slot.gig.end_time) }}
                                        </small>
                                    </template>

                                    <template #cell(slot_date)="row">
                                        <div>{{ formatDate(row.item.gig_slot.slot_date) }}</div>
                                        <small class="text-muted">{{ formatDay(row.item.gig_slot.slot_date) }}</small>
                                    </template>

                                    <template #cell(booking_status)="row">
                                        <span class="badge" :class="'bg-' + getStatusColor(row.item.booking_status)">
                                            {{ row.item.booking_status }}
                                        </span>
                                    </template>

                                    <template #cell(orders)="row">
                                        <div class="text-center">
                                            <strong>{{ row.item.orders_completed || 0 }}</strong>
                                        </div>
                                    </template>

                                    <template #cell(earnings)="row">
                                        <strong class="text-success">{{ $currency }}{{ parseFloat(row.item.earnings_amount || 0).toFixed(2) }}</strong>
                                    </template>

                                    <template #cell(booked_at)="row">
                                        <small>{{ formatDateTime(row.item.booked_at) }}</small>
                                    </template>

                                    <template #cell(actions)="row">
                                        <button
                                            class="btn btn-info btn-sm me-1"
                                            @click="viewDetails(row.item)"
                                        >
                                            <i class="fa fa-info-circle"></i> Details
                                        </button>
                                        <button
                                            v-if="row.item.booking_status === 'booked'"
                                            class="btn btn-danger btn-sm"
                                            @click="cancelBooking(row.item)"
                                        >
                                            <i class="fa fa-times-circle"></i> Cancel
                                        </button>
                                    </template>

                                    <template #empty>
                                        <div class="text-center py-5">
                                            <i class="fa fa-calendar fa-4x text-muted mb-3"></i>
                                            <h5 class="text-muted">No Bookings Found</h5>
                                            <p class="text-muted">No bookings match your current filters</p>
                                        </div>
                                    </template>
                                </b-table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Booking Details Modal -->
        <b-modal
            v-model="showDetailsModal"
            title="Booking Details"
            size="lg"
            ok-only
            ok-title="Close"
        >
            <div v-if="selectedBooking">
                <b-row>
                    <b-col md="6">
                        <h6 class="mb-3">Partner Information</h6>
                        <div class="mb-2">
                            <strong>Name:</strong> {{ selectedBooking.delivery_boy.name }}
                        </div>
                        <div class="mb-2">
                            <strong>Phone:</strong> {{ selectedBooking.delivery_boy.phone }}
                        </div>
                        <div class="mb-2">
                            <strong>City:</strong> {{ selectedBooking.delivery_boy.city_name || 'N/A' }}
                        </div>
                    </b-col>
                    <b-col md="6">
                        <h6 class="mb-3">Gig Information</h6>
                        <div class="mb-2">
                            <strong>Gig:</strong> {{ selectedBooking.gig_slot.gig.gig_name }}
                        </div>
                        <div class="mb-2">
                            <strong>Date:</strong> {{ formatDate(selectedBooking.gig_slot.slot_date) }}
                        </div>
                        <div class="mb-2">
                            <strong>Time:</strong>
                            {{ formatTime(selectedBooking.gig_slot.gig.start_time) }} -
                            {{ formatTime(selectedBooking.gig_slot.gig.end_time) }}
                        </div>
                        <div class="mb-2">
                            <strong>Base Earning:</strong> {{ $currency }}{{ parseFloat(selectedBooking.gig_slot.gig.base_earning).toFixed(2) }}
                        </div>
                    </b-col>
                </b-row>

                <hr>

                <b-row>
                    <b-col md="6">
                        <h6 class="mb-3">Booking Status</h6>
                        <div class="mb-2">
                            <strong>Status:</strong>
                            <span class="badge ml-2" :class="'bg-' + getStatusColor(selectedBooking.booking_status)">
                                {{ selectedBooking.booking_status }}
                            </span>
                        </div>
                        <div class="mb-2">
                            <strong>Booked At:</strong> {{ formatDateTime(selectedBooking.booked_at) }}
                        </div>
                        <div v-if="selectedBooking.started_at" class="mb-2">
                            <strong>Started At:</strong> {{ formatDateTime(selectedBooking.started_at) }}
                        </div>
                        <div v-if="selectedBooking.completed_at" class="mb-2">
                            <strong>Completed At:</strong> {{ formatDateTime(selectedBooking.completed_at) }}
                        </div>
                        <div v-if="selectedBooking.cancelled_at" class="mb-2">
                            <strong>Cancelled At:</strong> {{ formatDateTime(selectedBooking.cancelled_at) }}
                        </div>
                    </b-col>
                    <b-col md="6">
                        <h6 class="mb-3">Performance</h6>
                        <div class="mb-2">
                            <strong>Orders Completed:</strong> {{ selectedBooking.orders_completed || 0 }}
                        </div>
                        <div class="mb-2">
                            <strong>Total Earnings:</strong>
                            <span class="text-success font-weight-bold">
                                {{ $currency }}{{ parseFloat(selectedBooking.earnings_amount || 0).toFixed(2) }}
                            </span>
                        </div>
                        <div v-if="selectedBooking.actual_login_hours" class="mb-2">
                            <strong>Login Hours:</strong> {{ parseFloat(selectedBooking.actual_login_hours).toFixed(2) }}h
                        </div>
                    </b-col>
                </b-row>

                <div v-if="selectedBooking.cancellation_reason" class="mt-3">
                    <h6>Cancellation Reason</h6>
                    <p class="text-muted">{{ selectedBooking.cancellation_reason }}</p>
                </div>
            </div>
        </b-modal>
    </div>
</template>

<script>
import axios from 'axios'
import moment from 'moment'

export default {
    name: 'GigBookings',
    data() {
        return {
            loading: false,
            bookings: [],
            gigs: [],
            stats: {
                total_bookings: 0,
                active_today: 0,
                completed_today: 0,
                total_earnings: 0
            },
            filters: {
                search: '',
                gigId: '',
                status: '',
                fromDate: moment().startOf('month').format('YYYY-MM-DD'),
                toDate: moment().endOf('month').format('YYYY-MM-DD')
            },
            statusOptions: [
                { value: '', text: 'All Status' },
                { value: 'booked', text: 'Booked' },
                { value: 'active', text: 'Active' },
                { value: 'completed', text: 'Completed' },
                { value: 'cancelled', text: 'Cancelled' },
                { value: 'no_show', text: 'No Show' }
            ],
            fields: [
                { key: 'partner', label: 'Delivery Partner' },
                { key: 'gig', label: 'Gig Details' },
                { key: 'slot_date', label: 'Date' },
                { key: 'booking_status', label: 'Status' },
                { key: 'orders', label: 'Orders', class: 'text-center' },
                { key: 'earnings', label: 'Earnings' },
                { key: 'booked_at', label: 'Booked At' },
                { key: 'actions', label: 'Actions' }
            ],
            searchTimeout: null,
            showDetailsModal: false,
            selectedBooking: null
        }
    },
    computed: {
        gigOptions() {
            return [
                { value: '', text: 'All Gigs' },
                ...this.gigs.map(gig => ({
                    value: gig.id,
                    text: `${gig.gig_name || 'Unnamed Gig'} (${this.formatTime(gig.start_time)} - ${this.formatTime(gig.end_time)})`
                }))
            ]
        }
    },
    mounted() {
        this.loadGigs()
        this.loadBookings()
    },
    methods: {
        async loadGigs() {
            try {
                const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/gigs', {
                    params: { token: localStorage.getItem('api_token') }
                })
                if (response.data.status) {
                    this.gigs = response.data.data.gigs
                }
            } catch (error) {
                console.error('Failed to load gigs:', error)
            }
        },

        async loadBookings() {
            this.loading = true
            try {
                const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/gigs/bookings', {
                    params: {
                        token: localStorage.getItem('api_token'),
                        search: this.filters.search,
                        gig_id: this.filters.gigId,
                        status: this.filters.status,
                        from_date: this.filters.fromDate,
                        to_date: this.filters.toDate
                    }
                })
                if (response.data.status) {
                    this.bookings = response.data.data.bookings || []
                    this.stats = response.data.data.stats || this.stats
                } else {
                    this.showError(response.data.message || 'Failed to load bookings')
                }
            } catch (error) {
                this.showError(error.response?.data?.message || 'Failed to load bookings')
            }
            this.loading = false
        },

        debounceSearch() {
            if (this.searchTimeout) clearTimeout(this.searchTimeout)
            this.searchTimeout = setTimeout(() => {
                this.loadBookings()
            }, 500)
        },

        viewDetails(booking) {
            this.selectedBooking = booking
            this.showDetailsModal = true
        },

        async cancelBooking(booking) {
            const result = await this.$swal.fire({
                title: 'Cancel Booking?',
                text: `Are you sure you want to cancel this booking for ${booking.delivery_boy.name}?`,
                icon: 'warning',
                input: 'textarea',
                inputLabel: 'Cancellation Reason',
                inputPlaceholder: 'Enter reason for cancellation...',
                inputValidator: (value) => {
                    if (!value) {
                        return 'Please provide a cancellation reason'
                    }
                },
                showCancelButton: true,
                confirmButtonText: 'Yes, Cancel Booking',
                confirmButtonColor: '#dc3545'
            })

            if (result.isConfirmed) {
                try {
                    const response = await axios.post(this.$apiUrl + '/admin/delivery-boys/gigs/bookings/cancel', {
                        token: localStorage.getItem('api_token'),
                        booking_id: booking.id,
                        cancellation_reason: result.value
                    })

                    if (response.data.status) {
                        this.showSuccess('Booking cancelled successfully')
                        this.loadBookings()
                    } else {
                        this.showError(response.data.message || 'Failed to cancel booking')
                    }
                } catch (error) {
                    this.showError(error.response?.data?.message || 'Failed to cancel booking')
                }
            }
        },

        async exportBookings() {
            try {
                const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/gigs/bookings/export', {
                    params: {
                        token: localStorage.getItem('api_token'),
                        gig_id: this.filters.gigId,
                        status: this.filters.status,
                        from_date: this.filters.fromDate,
                        to_date: this.filters.toDate
                    },
                    responseType: 'blob'
                })

                const url = window.URL.createObjectURL(new Blob([response.data]))
                const link = document.createElement('a')
                link.href = url
                link.setAttribute('download', `gig_bookings_${moment().format('YYYY-MM-DD')}.xlsx`)
                document.body.appendChild(link)
                link.click()
                link.remove()

                this.showSuccess('Bookings exported successfully')
            } catch (error) {
                this.showError('Failed to export bookings')
            }
        },

        formatDate(date) {
            return moment(date).format('MMM DD, YYYY')
        },

        formatDay(date) {
            return moment(date).format('dddd')
        },

        formatTime(time) {
            if (!time) return 'N/A'
            return moment(time, 'HH:mm:ss').format('hh:mm A')
        },

        formatDateTime(datetime) {
            if (!datetime) return 'N/A'
            return moment(datetime).format('MMM DD, YYYY hh:mm A')
        },

        getStatusColor(status) {
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
.me-1 {
    margin-right: 0.25rem;
}
.mr-2 {
    margin-right: 0.5rem;
}
.mr-3 {
    margin-right: 1rem;
}
</style>