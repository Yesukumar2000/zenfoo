<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Slot Bookings</h3>
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
                            <li class="breadcrumb-item">
                                <a href="#" @click.prevent="goBack">Slots</a>
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
                            <h4>Slot Details & Bookings</h4>
                            <button class="btn btn-secondary btn-sm float-end" @click="goBack">
                                <i class="fa fa-arrow-left"></i> Back to Slots
                            </button>
                        </div>

                        <div class="card-body">
                            <!-- Slot Information -->
                            <div class="alert alert-info mb-4" v-if="slotInfo">
                                <div class="row">
                                    <div class="col-md-3">
                                        <strong>Gig:</strong> {{ slotInfo.gig_name }}
                                    </div>
                                    <div class="col-md-3">
                                        <strong>Date:</strong> {{ formatDate(slotInfo.slot_date) }}
                                    </div>
                                    <div class="col-md-3">
                                        <strong>Time:</strong> {{ formatTime(slotInfo.start_time) }} - {{ formatTime(slotInfo.end_time) }}
                                    </div>
                                    <div class="col-md-3">
                                        <strong>Capacity:</strong> {{ slotInfo.current_bookings }} / {{ slotInfo.max_bookings }}
                                    </div>
                                </div>
                            </div>

                            <!-- Bookings Table -->
                            <div class="table-responsive">
                                <b-table
                                    :items="bookings"
                                    :fields="fields"
                                    :bordered="true"
                                    :busy="loading"
                                    stacked="md"
                                    show-empty
                                    small>

                                    <template #table-busy>
                                        <div class="text-center text-black my-2">
                                            <b-spinner class="align-middle"></b-spinner>
                                            <strong>{{ __('loading') }}...</strong>
                                        </div>
                                    </template>

                                    <template #empty>
                                        <div class="text-center py-5">
                                            <i class="fa fa-users fa-4x text-muted mb-3"></i>
                                            <h5 class="text-muted">No Bookings Found</h5>
                                            <p class="text-muted">No delivery partners have booked this slot yet</p>
                                        </div>
                                    </template>

                                    <template #cell(delivery_boy)="row">
                                        <div>
                                            <!-- Image commented for now -->
                                            <!-- <div class="d-flex align-items-center">
                                                <div class="avatar me-2">
                                                    <img
                                                        v-if="row.item.delivery_boy.profile_image_url"
                                                        :src="row.item.delivery_boy.profile_image_url"
                                                        @error="handleImageError($event)"
                                                        alt="Profile"
                                                        class="rounded-circle"
                                                        width="40"
                                                        height="40"
                                                    >
                                                    <div v-else class="avatar-placeholder">
                                                        {{ getInitials(row.item.delivery_boy.name) }}
                                                    </div>
                                                </div>
                                            </div> -->
                                            <strong>{{ row.item.delivery_boy.name }}</strong>
                                            <br>
                                            <small class="text-muted">{{ row.item.delivery_boy.phone || 'No phone' }}</small>
                                        </div>
                                    </template>

                                    <template #cell(booking_status)="row">
                                        <span v-if="row.item.booking_status === 'booked'" class="badge bg-primary">Booked</span>
                                        <span v-else-if="row.item.booking_status === 'completed'" class="badge bg-success">Completed</span>
                                        <span v-else-if="row.item.booking_status === 'cancelled'" class="badge bg-danger">Cancelled</span>
                                        <span v-else class="badge bg-secondary">{{ row.item.booking_status }}</span>
                                    </template>

                                    <template #cell(booked_at)="row">
                                        {{ formatDateTime(row.item.booked_at) }}
                                    </template>

                                    <template #cell(earnings)="row">
                                        <span v-if="row.item.earnings_amount">
                                            {{ $currency }} {{ parseFloat(row.item.earnings_amount).toFixed(2) }}
                                        </span>
                                        <span v-else class="text-muted">-</span>
                                    </template>

                                    <template #cell(performance)="row">
                                        <div v-if="row.item.booking_status === 'completed'">
                                            <small>
                                                <strong>Orders:</strong> {{ row.item.orders_completed || 0 }}
                                                <span v-if="row.item.orders_cancelled" class="text-danger">
                                                    ({{ row.item.orders_cancelled }} cancelled)
                                                </span>
                                            </small>
                                            <br>
                                            <small v-if="row.item.distance_km">
                                                <strong>Distance:</strong> {{ parseFloat(row.item.distance_km).toFixed(2) }} km
                                            </small>
                                        </div>
                                        <span v-else class="text-muted">-</span>
                                    </template>

                                    <template #cell(actions)="row">
                                        <button
                                            v-if="row.item.booking_status === 'booked'"
                                            class="btn btn-danger btn-sm"
                                            v-b-tooltip.hover
                                            title="Cancel Booking"
                                            @click="cancelBooking(row.item)"
                                        >
                                            <i class="fa fa-times"></i>
                                        </button>
                                        <button
                                            class="btn btn-info btn-sm ms-1"
                                            v-b-tooltip.hover
                                            title="View Details"
                                            @click="viewDeliveryBoyDetails(row.item)"
                                        >
                                            <i class="fa fa-eye"></i>
                                        </button>
                                    </template>

                                </b-table>
                            </div>

                            <b-row class="mt-3">
                                <b-col md="6">
                                    <label>Total Bookings: {{ bookings.length }}</label>
                                </b-col>
                                <b-col md="6" class="text-right">
                                    <span class="me-3">
                                        <b-badge variant="primary">Booked: {{ getStatusCount('booked') }}</b-badge>
                                    </span>
                                    <span class="me-3">
                                        <b-badge variant="success">Completed: {{ getStatusCount('completed') }}</b-badge>
                                    </span>
                                    <span>
                                        <b-badge variant="danger">Cancelled: {{ getStatusCount('cancelled') }}</b-badge>
                                    </span>
                                </b-col>
                            </b-row>
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
    name: 'SlotBookings',
    data() {
        return {
            loading: false,
            slotId: null,
            gigId: null,
            slotInfo: null,
            bookings: [],
            fields: [
                { key: 'delivery_boy', label: 'Delivery Partner', sortable: true },
                { key: 'booking_status', label: 'Status', class: 'text-center', sortable: true },
                { key: 'booked_at', label: 'Booked At', class: 'text-center', sortable: true },
                { key: 'earnings', label: 'Earnings', class: 'text-center' },
                { key: 'performance', label: 'Performance', class: 'text-center' },
                { key: 'actions', label: 'Actions', class: 'text-center' }
            ]
        }
    },
    mounted() {
        this.slotId = this.$route.params.slotId
        this.gigId = this.$route.params.id
        this.loadBookings()
    },
    methods: {
        async loadBookings() {
            this.loading = true
            try {
                const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/gigs/slots/bookings', {
                    params: {
                        token: localStorage.getItem('api_token'),
                        slot_id: this.slotId
                    }
                })

                if (response.data.status) {
                    const data = response.data.data
                    this.slotInfo = data.slot
                    this.bookings = data.bookings || []
                } else {
                    this.showError(response.data.message || 'Failed to load bookings')
                }
            } catch (error) {
                console.error('Error loading bookings:', error)
                this.showError(error.response?.data?.message || 'Failed to load bookings')
            }
            this.loading = false
        },

        async cancelBooking(booking) {
            const result = await this.$swal.fire({
                title: 'Cancel Booking?',
                text: `Are you sure you want to cancel ${booking.delivery_boy.name}'s booking?`,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: 'Yes, Cancel',
                confirmButtonColor: '#dc3545'
            })

            if (result.isConfirmed) {
                try {
                    const response = await axios.post(this.$apiUrl + '/admin/delivery-boys/gigs/bookings/cancel', {
                        token: localStorage.getItem('api_token'),
                        booking_id: booking.id
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

        viewDeliveryBoyDetails(booking) {
            // Navigate to delivery boy details page
            this.$router.push(`/delivery_boy_details/${booking.delivery_boy.id}`)
        },

        handleImageError(event) {
            // Set a dummy/placeholder image when the image fails to load
            event.target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHJlY3Qgd2lkdGg9IjQwIiBoZWlnaHQ9IjQwIiBmaWxsPSIjZTllY2VmIi8+PHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtc2l6ZT0iMTgiIGZpbGw9IiM2Yzc1N2QiIGRvbWluYW50LWJhc2VsaW5lPSJtaWRkbGUiIHRleHQtYW5jaG9yPSJtaWRkbGUiPjw/PC90ZXh0Pjwvc3ZnPg=='
            event.target.onerror = null // Prevent infinite loop
        },

        goBack() {
            this.$router.push(`/delivery-boy/gigs/${this.gigId}/slots`)
        },

        formatDate(date) {
            return moment(date).format('MMM DD, YYYY')
        },

        formatTime(time) {
            if (!time) return '-'
            return moment(time, 'HH:mm:ss').format('hh:mm A')
        },

        formatDateTime(datetime) {
            if (!datetime) return '-'
            return moment(datetime).format('MMM DD, YYYY hh:mm A')
        },

        getInitials(name) {
            if (!name) return '?'
            return name.split(' ').map(n => n[0]).join('').toUpperCase()
        },

        getStatusCount(status) {
            return this.bookings.filter(b => b.booking_status === status).length
        }
    }
}
</script>

<style scoped>
.avatar-placeholder {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background-color: #6c757d;
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
}

.me-2 {
    margin-right: 0.5rem;
}

.ms-1 {
    margin-left: 0.25rem;
}

.me-3 {
    margin-right: 1rem;
}
</style>