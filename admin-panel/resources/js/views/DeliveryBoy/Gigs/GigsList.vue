<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Gigs Management</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">Gigs</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/dashboard" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to Dashboard
                    </router-link>
                </div>
            </div>

            <div class="row">
                <div class="col-12 col-md-12 order-md-1 order-last">
                    <div class="card">
                        <div class="card-header">
                            <h4>All Gigs</h4>
                            <!-- <router-link to="/delivery-boy/gigs/create" class="btn btn-primary btn-sm float-end">
                                <i class="fa fa-plus"></i> Create New Gig
                            </router-link> -->
                        </div>

                        <div class="card-body">
                            <b-row class="mb-3">
                                <b-col md="4">
                                    <h6 class="box-title">{{ __('search') }}</h6>
                                    <b-form-input
                                        id="filter-input"
                                        v-model="filter"
                                        type="search"
                                        :placeholder="__('search')"
                                        @input="debounceSearch"
                                    ></b-form-input>
                                </b-col>
                                <b-col md="2" class="d-flex align-items-end">
                                    <button type="button" class="btn btn-primary" v-b-tooltip.hover :title="__('refresh')" @click="loadGigs()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i>
                                    </button>
                                </b-col>
                            </b-row>

                            <div class="table-responsive">
                                <b-table
                                    :items="filteredGigs"
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
                                            <i class="fa fa-briefcase fa-4x text-muted mb-3"></i>
                                            <h5 class="text-muted">No Gigs Found</h5>
                                            <p class="text-muted">No gigs available at the moment</p>
                                            <!-- <router-link to="/delivery-boy/gigs/create" class="btn btn-primary">
                                                <i class="fa fa-plus"></i> Create Gig
                                            </router-link> -->
                                        </div>
                                    </template>

                                    <template #cell(gig_name)="row">
                                        <strong>{{ row.item.gig_name || getDefaultGigName(row.item) }}</strong>
                                        <br v-if="row.item.description">
                                        <small class="text-muted">{{ row.item.description }}</small>
                                    </template>

                                    <template #cell(time)="row">
                                        <div class="d-flex align-items-center">
                                            <i class="fa fa-clock-o mr-2"></i>
                                            <div>
                                                <div>{{ formatTime(row.item.start_time) }} - {{ formatTime(row.item.end_time) }}</div>
                                                <small class="text-muted">{{ row.item.duration_hours }} hours</small>
                                            </div>
                                        </div>
                                    </template>

                                    <template #cell(base_earning)="row">
                                        <strong class="text-success">{{ $currency }} {{ parseFloat(row.item.base_earning || 0).toFixed(2) }}</strong>
                                    </template>

                                    <template #cell(slots_count)="row">
                                        <span class="badge bg-info">{{ row.item.slots_count || 0 }} slots</span>
                                    </template>

                                    <template #cell(bookings_count)="row">
                                        <span class="badge bg-primary">{{ row.item.bookings_count || 0 }} bookings</span>
                                    </template>

                                    <template #cell(is_active)="row">
                                        <span v-if="row.item.is_active === 1 || row.item.is_active === true" class="badge bg-success">Active</span>
                                        <span v-else-if="row.item.is_active === 0 || row.item.is_active === false" class="badge bg-danger">Inactive</span>
                                        <span v-else class="badge bg-secondary">Not Set</span>
                                    </template>

                                    <template #cell(actions)="row">
                                        <button
                                            class="btn btn-info btn-sm me-1"
                                            v-b-tooltip.hover
                                            title="View Slots"
                                            @click="viewSlots(row.item)"
                                        >
                                            <i class="fa fa-calendar"></i>
                                        </button>
                                        <button
                                            class="btn btn-warning btn-sm me-1"
                                            v-b-tooltip.hover
                                            title="Edit"
                                            @click="editGig(row.item)"
                                        >
                                            <i class="fa fa-edit"></i>
                                        </button>
                                        <button
                                            class="btn btn-danger btn-sm"
                                            v-b-tooltip.hover
                                            title="Delete"
                                            @click="deleteGig(row.item)"
                                        >
                                            <i class="fa fa-trash"></i>
                                        </button>
                                    </template>

                                </b-table>
                            </div>

                            <b-row>
                                <b-col md="4">
                                    <label>Total Gigs: {{ gigs.length }}</label>
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
    name: 'GigsList',
    data() {
        return {
            loading: false,
            gigs: [],
            filter: '',
            debounceTimer: null,
            fields: [
                { key: 'id', label: 'ID', sortable: true, class: 'text-center', thStyle: { width: '80px' } },
                { key: 'gig_name', label: 'Gig Name', sortable: true },
                { key: 'time', label: 'Time & Duration', class: 'text-center' },
                { key: 'base_earning', label: 'Base Earnings', class: 'text-center' },
                // { key: 'slots_count', label: 'Slots', class: 'text-center' },
                { key: 'bookings_count', label: 'Bookings', class: 'text-center' },
                { key: 'is_active', label: 'Status', class: 'text-center' },
                { key: 'actions', label: 'Actions', class: 'text-center', thStyle: { width: '150px' } }
            ]
        }
    },
    computed: {
        filteredGigs() {
            if (!this.filter) {
                return this.gigs;
            }
            const searchTerm = this.filter.toLowerCase();
            return this.gigs.filter(gig => {
                return (gig.gig_name && gig.gig_name.toLowerCase().includes(searchTerm)) ||
                       (gig.description && gig.description.toLowerCase().includes(searchTerm));
            });
        }
    },
    mounted() {
        this.loadGigs()
    },
    methods: {
        debounceSearch() {
            clearTimeout(this.debounceTimer);
            this.debounceTimer = setTimeout(() => {
                // Filter is handled by computed property
            }, 300);
        },

        async loadGigs() {
            this.loading = true
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
            this.loading = false
        },

        editGig(gig) {
            this.$router.push(`/delivery-boy/gigs/edit/${gig.id}`)
        },

        viewSlots(gig) {
            this.$router.push(`/delivery-boy/gigs/${gig.id}/slots`)
        },

        async toggleStatus(gig, newStatus) {
            try {
                await axios.post(this.$apiUrl + '/admin/delivery-boys/gigs/update', {
                    token: localStorage.getItem('api_token'),
                    gig_id: gig.id,
                    is_active: newStatus ? 1 : 0,
                    gig_name: gig.gig_name,
                    description: gig.description,
                    start_time: gig.start_time,
                    end_time: gig.end_time,
                    base_earning: gig.base_earning
                })

                this.showSuccess('Gig status updated successfully')
                this.loadGigs()
            } catch (error) {
                this.showError(error.response?.data?.message || 'Failed to update status')
                this.loadGigs()
            }
        },

        async deleteGig(gig) {
            const result = await this.$swal.fire({
                title: 'Delete Gig?',
                text: `Are you sure you want to delete "${gig.gig_name || 'this gig'}"? This will also delete all associated slots.`,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: 'Yes, Delete',
                confirmButtonColor: '#dc3545'
            })

            if (result.isConfirmed) {
                try {
                    await axios.post(this.$apiUrl + '/admin/delivery-boys/gigs/delete', {
                        token: localStorage.getItem('api_token'),
                        gig_id: gig.id
                    })

                    this.showSuccess('Gig deleted successfully')
                    this.loadGigs()
                } catch (error) {
                    this.showError(error.response?.data?.message || 'Failed to delete gig')
                }
            }
        },

        formatTime(time) {
            if (!time) return '-'
            return moment(time, 'HH:mm:ss').format('hh:mm A')
        },

        getDefaultGigName(gig) {
            const start = moment(gig.start_time, 'HH:mm:ss').format('hh:mm A')
            const end = moment(gig.end_time, 'HH:mm:ss').format('hh:mm A')
            return `Gig ${start} - ${end}`
        }
    }
}
</script>

<style scoped>
.card-header-actions {
    margin-right: 0;
}
.me-1 {
    margin-right: 0.25rem;
}
.mr-2 {
    margin-right: 0.5rem;
}
</style>
