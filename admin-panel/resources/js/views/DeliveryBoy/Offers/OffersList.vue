<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Incentive Offers Management</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">Incentive Offers</li>
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
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h4 class="mb-0">All Offers</h4>
                            <router-link to="/delivery-boy/offers/create" class="btn btn-primary btn-sm">
                                <i class="fa fa-plus"></i> Create New Offer
                            </router-link>
                        </div>

                        <div class="card-body">
                            <!-- Filter Tabs -->
                            <b-tabs content-class="mt-3" v-model="activeTab">
                                <b-tab title="All Offers" active>
                                    <template #title>
                                        All Offers <span class="badge bg-secondary ms-1">{{ allOffers.length }}</span>
                                    </template>
                                </b-tab>
                                <b-tab title="Active">
                                    <template #title>
                                        Active <span class="badge bg-success ms-1">{{ activeOffers.length }}</span>
                                    </template>
                                </b-tab>
                                <b-tab title="Upcoming">
                                    <template #title>
                                        Upcoming <span class="badge bg-warning ms-1">{{ upcomingOffers.length }}</span>
                                    </template>
                                </b-tab>
                                <b-tab title="Expired">
                                    <template #title>
                                        Expired <span class="badge bg-secondary ms-1">{{ expiredOffers.length }}</span>
                                    </template>
                                </b-tab>
                            </b-tabs>

                            <!-- Search and Refresh -->
                            <b-row class="mb-3 mt-3">
                                <b-col md="4">
                                    <h6 class="box-title">{{ __('search') }}</h6>
                                    <b-form-input
                                        id="filter-input"
                                        v-model="filter"
                                        type="search"
                                        :placeholder="__('search')"
                                    ></b-form-input>
                                </b-col>
                                <b-col md="2" class="d-flex align-items-end">
                                    <button type="button" class="btn btn-primary" v-b-tooltip.hover :title="__('refresh')" @click="loadOffers()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i>
                                    </button>
                                </b-col>
                            </b-row>

                            <div class="table-responsive">
                                <b-table
                                    :items="currentOffers"
                                    :fields="fields"
                                    :bordered="true"
                                    :busy="loading"
                                    :filter="filter"
                                    :filter-included-fields="['name', 'description']"
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
                                            <i class="fa fa-gift fa-4x text-muted mb-3"></i>
                                            <h5 class="text-muted">No Offers Found</h5>
                                            <p class="text-muted">Create your first incentive offer to motivate delivery partners</p>
                                            <router-link to="/delivery-boy/offers/create" class="btn btn-primary">
                                                <i class="fa fa-plus"></i> Create New Offer
                                            </router-link>
                                        </div>
                                    </template>

                                    <template #cell(banner)="row">
                                        <img
                                            v-if="row.item.banner_image_url"
                                            :src="row.item.banner_image_url"
                                            width="80"
                                            height="50"
                                            style="object-fit: cover; border-radius: 4px;"
                                        />
                                        <div v-else class="text-muted small">No banner</div>
                                    </template>

                                    <template #cell(name)="row">
                                        <strong>{{ row.item.name }}</strong>
                                        <br>
                                        <small class="text-muted">{{ row.item.description ? (row.item.description.length > 60 ? row.item.description.substring(0, 60) + '...' : row.item.description) : 'No description' }}</small>
                                    </template>

                                    <template #cell(dates)="row">
                                        <div class="mb-1">
                                            <small class="text-muted">Start:</small>
                                            <br>
                                            {{ formatDate(row.item.start_date) }}
                                        </div>
                                        <div>
                                            <small class="text-muted">End:</small>
                                            <br>
                                            {{ formatDate(row.item.end_date) }}
                                        </div>
                                        <span :class="'badge bg-' + getDateStatusColor(row.item)" class="mt-1">
                                            {{ getDateStatus(row.item) }}
                                        </span>
                                    </template>

                                    <template #cell(conditions)="row">
                                        <div class="small">
                                            <div><i class="fa fa-check-circle"></i> Min Gigs: <strong>{{ row.item.min_gigs_required }}</strong></div>
                                            <div><i class="fa fa-ban"></i> Max Skip: <strong>{{ row.item.max_gigs_skip }}</strong></div>
                                            <div><i class="fa fa-times-circle"></i> Max Cancel: <strong>{{ row.item.max_orders_cancel }}</strong></div>
                                            <div>
                                                <i class="fa fa-clock-o"></i>
                                                Login: <strong>{{ row.item.login_mandatory ? 'Required' : 'Optional' }}</strong>
                                            </div>
                                        </div>
                                    </template>

                                    <template #cell(tiers)="row">
                                        <span class="badge bg-info me-1">{{ row.item.tiers_count }} Tiers</span>
                                        <br>
                                        <small class="text-muted">Max: {{ $currency }}{{ parseFloat(row.item.max_incentive || 0).toFixed(2) }}</small>
                                    </template>

                                    <template #cell(participants)="row">
                                        <div class="text-center">
                                            <div class="h5 mb-0">{{ row.item.enrolled_count || 0 }}</div>
                                            <small class="text-muted">Enrolled</small>
                                        </div>
                                    </template>

                                    <template #cell(status)="row">
                                        <div class="form-check form-switch">
                                            <input
                                                class="form-check-input"
                                                type="checkbox"
                                                :checked="row.item.status == 1"
                                                @change="toggleStatus(row.item)"
                                            >
                                        </div>
                                    </template>

                                    <template #cell(actions)="row">
                                        <!-- <button
                                            class="btn btn-info btn-sm me-1 mb-1"
                                            v-b-tooltip.hover
                                            title="View Progress"
                                            @click="viewProgress(row.item)"
                                        >
                                            <i class="fa fa-line-chart"></i>
                                        </button> -->
                                        <button
                                            class="btn btn-warning btn-sm me-1 mb-1"
                                            v-b-tooltip.hover
                                            title="Edit"
                                            @click="editOffer(row.item)"
                                        >
                                            <i class="fa fa-edit"></i>
                                        </button>
                                        <button
                                            class="btn btn-danger btn-sm mb-1"
                                            v-b-tooltip.hover
                                            title="Delete"
                                            @click="deleteOffer(row.item)"
                                        >
                                            <i class="fa fa-trash"></i>
                                        </button>
                                    </template>

                                </b-table>
                            </div>

                            <b-row>
                                <b-col md="4">
                                    <label>Total Offers: {{ currentOffers.length }}</label>
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
    name: 'OffersList',
    data() {
        return {
            loading: false,
            offers: [],
            activeTab: 0,
            filter: '',
            fields: [
                { key: 'banner', label: 'Banner', thStyle: { width: '100px' } },
                { key: 'name', label: 'Offer Name', sortable: true },
                { key: 'dates', label: 'Duration' },
                { key: 'conditions', label: 'Conditions' },
                { key: 'tiers', label: 'Tiers', thStyle: { width: '100px' } },
                { key: 'participants', label: 'Enrolled', class: 'text-center', thStyle: { width: '100px' } },
                { key: 'status', label: 'Active', class: 'text-center', thStyle: { width: '80px' } },
                { key: 'actions', label: 'Actions', class: 'text-center', thStyle: { width: '180px' } }
            ]
        }
    },
    computed: {
        allOffers() {
            return this.offers
        },
        activeOffers() {
            const now = moment()
            return this.offers.filter(offer => {
                const start = moment(offer.start_date)
                const end = moment(offer.end_date)
                return offer.status == 1 && now.isBetween(start, end)
            })
        },
        upcomingOffers() {
            const now = moment()
            return this.offers.filter(offer => {
                const start = moment(offer.start_date)
                return offer.status == 1 && now.isBefore(start)
            })
        },
        expiredOffers() {
            const now = moment()
            return this.offers.filter(offer => {
                const end = moment(offer.end_date)
                return now.isAfter(end)
            })
        },
        currentOffers() {
            switch(this.activeTab) {
                case 0: return this.allOffers
                case 1: return this.activeOffers
                case 2: return this.upcomingOffers
                case 3: return this.expiredOffers
                default: return this.allOffers
            }
        }
    },
    mounted() {
        this.loadOffers()
    },
    methods: {
        async loadOffers() {
            this.loading = true
            try {
                const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/offers', {
                    params: { token: localStorage.getItem('api_token') }
                })
                console.log('Offers API Response:', response.data)
                if (response.data && response.data.data && response.data.data.offers) {
                    this.offers = response.data.data.offers
                    console.log('Offers loaded:', this.offers.length)
                } else {
                    console.error('Invalid response structure:', response.data)
                    this.offers = []
                }
            } catch (error) {
                console.error('Failed to load offers:', error)
                this.$swal.fire('Error', 'Failed to load offers', 'error')
                this.offers = []
            }
            this.loading = false
        },

        formatDate(date) {
            return moment(date).format('DD MMM YYYY')
        },

        getDateStatus(offer) {
            const now = moment()
            const start = moment(offer.start_date)
            const end = moment(offer.end_date)

            if (now.isBefore(start)) {
                const days = start.diff(now, 'days')
                return `Starts in ${days} days`
            } else if (now.isBetween(start, end)) {
                const days = end.diff(now, 'days')
                return `${days} days left`
            } else {
                return 'Expired'
            }
        },

        getDateStatusColor(offer) {
            const now = moment()
            const start = moment(offer.start_date)
            const end = moment(offer.end_date)

            if (now.isBefore(start)) {
                return 'warning'
            } else if (now.isBetween(start, end)) {
                const days = end.diff(now, 'days')
                return days > 7 ? 'success' : 'warning'
            } else {
                return 'secondary'
            }
        },

        editOffer(offer) {
            this.$router.push(`/delivery-boy/offers/edit/${offer.id}`)
        },

        viewProgress(offer) {
            this.$router.push(`/delivery-boy/offers/${offer.id}/progress`)
        },

        async toggleStatus(offer) {
            try {
                const newStatus = offer.status == 1 ? 0 : 1
                
                console.log("offer loaded here", offer.tiers);

                await axios.post(this.$apiUrl + '/admin/delivery-boys/offers/update-status-toggle-admin', {
                    token: localStorage.getItem('api_token'),
                    offer_id: offer.id,
                    name: offer.name,
                    description: offer.description,
                    start_date: offer.start_date,
                    end_date: offer.end_date,
                    status: newStatus,
                    tiers: offer.tiers || []
                })

                this.$swal.fire('Success', 'Offer status updated', 'success')
                this.loadOffers()
            } catch (error) {
                this.$swal.fire('Error', 'Failed to update status', 'error')
            }
        },

        async deleteOffer(offer) {
            const result = await this.$swal.fire({
                title: 'Delete Offer?',
                text: `Are you sure you want to delete "${offer.name}"? This will also delete all progress tracking.`,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: 'Yes, Delete',
                confirmButtonColor: '#dc3545'
            })

            if (result.isConfirmed) {
                try {
                    await axios.post(this.$apiUrl + '/admin/delivery-boys/offers/delete', {
                        token: localStorage.getItem('api_token'),
                        offer_id: offer.id
                    })

                    this.$swal.fire('Deleted', 'Offer deleted successfully', 'success')
                    this.loadOffers()
                } catch (error) {
                    this.$swal.fire('Error', error.response?.data?.message || 'Failed to delete offer', 'error')
                }
            }
        }
    }
}
</script>

<style scoped>
.card-header {
    background-color: #f8f9fa;
}
.me-1 {
    margin-right: 0.25rem;
}
.ms-1 {
    margin-left: 0.25rem;
}
.form-check-input {
    cursor: pointer;
}
</style>
