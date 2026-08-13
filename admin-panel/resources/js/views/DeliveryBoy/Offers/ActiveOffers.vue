<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Active Incentive Offers</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item">
                                <router-link to="/delivery-boy/offers/list">Incentive Offers</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">Active Offers</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/delivery-boy/offers/list" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <!-- Stats Cards -->
            <div class="row mb-4">
                <div class="col-md-3">
                    <div class="card bg-success text-white">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-center">
                                <div>
                                    <h6 class="mb-0">Active Offers</h6>
                                    <h3 class="mb-0">{{ stats.active_offers }}</h3>
                                </div>
                                <i class="fa fa-star fa-2x opacity-50"></i>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-primary text-white">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-center">
                                <div>
                                    <h6 class="mb-0">Total Participants</h6>
                                    <h3 class="mb-0">{{ stats.total_participants }}</h3>
                                </div>
                                <i class="fa fa-users fa-2x opacity-50"></i>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-info text-white">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-center">
                                <div>
                                    <h6 class="mb-0">Eligible Partners</h6>
                                    <h3 class="mb-0">{{ stats.eligible_partners }}</h3>
                                </div>
                                <i class="fa fa-check-circle fa-2x opacity-50"></i>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-warning text-white">
                        <div class="card-body">
                            <div class="d-flex justify-content-between align-items-center">
                                <div>
                                    <h6 class="mb-0">Total Rewards Pool</h6>
                                    <h3 class="mb-0">{{ $currency }}{{ stats.total_rewards_pool }}</h3>
                                </div>
                                <i class="fa fa-dollar fa-2x opacity-50"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h4 class="mb-0">Active Offers</h4>
                            <router-link to="/delivery-boy/offers/create" class="btn btn-primary btn-sm">
                                <i class="fa fa-plus"></i> Create New Offer
                            </router-link>
                        </div>

                        <div class="card-body">
                            <!-- Refresh Button -->
                            <b-row class="mb-3">
                                <b-col md="2">
                                    <button type="button" class="btn btn-primary" v-b-tooltip.hover :title="__('refresh')" @click="loadActiveOffers()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i>
                                    </button>
                                </b-col>
                            </b-row>

                            <div class="table-responsive">
                                <b-table
                                    :items="activeOffers"
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
                                            <i class="fa fa-gift fa-4x text-muted mb-3"></i>
                                            <h5 class="text-muted">No Active Offers</h5>
                                            <p class="text-muted">Create incentive offers to motivate your delivery partners</p>
                                            <router-link to="/delivery-boy/offers/create" class="btn btn-primary">
                                                <i class="fa fa-plus"></i> Create First Offer
                                            </router-link>
                                        </div>
                                    </template>

                                    <template #cell(banner)="row">
                                        <img
                                            v-if="row.item.banner_image_url"
                                            :src="row.item.banner_image_url"
                                            width="80"
                                            height="60"
                                            style="object-fit: cover; border-radius: 4px;"
                                        />
                                        <div v-else class="text-muted small">
                                            <i class="fa fa-image fa-2x"></i>
                                        </div>
                                    </template>

                                    <template #cell(name)="row">
                                        <strong>{{ row.item.name }}</strong>
                                        <br>
                                        <small class="text-muted">{{ row.item.description }}</small>
                                    </template>

                                    <template #cell(period)="row">
                                        <div>
                                            <i class="fa fa-calendar me-1"></i>
                                            {{ formatDate(row.item.start_date) }}
                                        </div>
                                        <div class="text-muted">to</div>
                                        <div>
                                            <i class="fa fa-calendar me-1"></i>
                                            {{ formatDate(row.item.end_date) }}
                                        </div>
                                        <span :class="'badge bg-' + getDaysRemainingColor(row.item)" class="mt-1">
                                            {{ getDaysRemaining(row.item) }} days left
                                        </span>
                                    </template>

                                    <template #cell(requirements)="row">
                                        <div class="mb-1">
                                            <small>Min Gigs:</small>
                                            <span class="badge bg-info ms-1">{{ row.item.min_gigs_required }}</span>
                                        </div>
                                        <div class="mb-1">
                                            <small>Max Skips:</small>
                                            <span class="badge bg-warning ms-1">{{ row.item.max_gigs_skip }}</span>
                                        </div>
                                        <div class="mb-1">
                                            <small>Max Cancels:</small>
                                            <span class="badge bg-danger ms-1">{{ row.item.max_orders_cancel }}</span>
                                        </div>
                                        <div v-if="row.item.login_mandatory">
                                            <span class="badge bg-primary">Login Mandatory</span>
                                        </div>
                                    </template>

                                    <template #cell(tiers)="row">
                                        <div v-if="row.item.tiers && row.item.tiers.length > 0">
                                            <div
                                                v-for="tier in row.item.tiers.slice(0, 3)"
                                                :key="tier.id"
                                                class="mb-1"
                                            >
                                                <small>{{ tier.tier_name }}:</small>
                                                <span class="badge bg-success ms-1">
                                                    {{ $currency }}{{ parseFloat(tier.reward_amount).toFixed(0) }}
                                                </span>
                                            </div>
                                            <span
                                                v-if="row.item.tiers.length > 3"
                                                class="badge bg-secondary mt-1"
                                            >
                                                +{{ row.item.tiers.length - 3 }} more
                                            </span>
                                        </div>
                                        <span v-else class="text-muted">No tiers</span>
                                    </template>

                                    <template #cell(participants)="row">
                                        <div class="text-center">
                                            <div class="h5 mb-0 text-primary">{{ row.item.participants_count }}</div>
                                            <small class="text-muted">Enrolled</small>
                                        </div>
                                    </template>

                                    <template #cell(actions)="row">
                                        <button
                                            class="btn btn-info btn-sm me-1 mb-1"
                                            v-b-tooltip.hover
                                            title="View Progress"
                                            @click="viewProgress(row.item)"
                                        >
                                            <i class="fa fa-line-chart"></i>
                                        </button>
                                        <button
                                            class="btn btn-warning btn-sm mb-1"
                                            v-b-tooltip.hover
                                            title="Edit"
                                            @click="editOffer(row.item)"
                                        >
                                            <i class="fa fa-edit"></i>
                                        </button>
                                    </template>

                                </b-table>
                            </div>

                            <b-row>
                                <b-col md="4">
                                    <label>Total Active Offers: {{ activeOffers.length }}</label>
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
    name: 'ActiveOffers',
    data() {
        return {
            loading: false,
            activeOffers: [],
            stats: {
                active_offers: 0,
                total_participants: 0,
                eligible_partners: 0,
                total_rewards_pool: 0
            },
            fields: [
                { key: 'banner', label: 'Banner', thStyle: { width: '100px' } },
                { key: 'name', label: 'Offer Name' },
                { key: 'period', label: 'Period' },
                { key: 'requirements', label: 'Requirements' },
                { key: 'tiers', label: 'Reward Tiers' },
                { key: 'participants', label: 'Participants', class: 'text-center', thStyle: { width: '100px' } },
                { key: 'actions', label: 'Actions', class: 'text-center', thStyle: { width: '150px' } }
            ]
        }
    },
    mounted() {
        this.loadActiveOffers()
    },
    methods: {
        async loadActiveOffers() {
            this.loading = true
            try {
                const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/offers/active', {
                    params: { token: localStorage.getItem('api_token') }
                })
                this.activeOffers = response.data.data.offers
                this.stats = response.data.data.stats
            } catch (error) {
                this.$swal.fire('Error', 'Failed to load active offers', 'error')
            }
            this.loading = false
        },

        editOffer(offer) {
            this.$router.push(`/delivery-boy/offers/edit/${offer.id}`)
        },

        viewProgress(offer) {
            this.$router.push({
                path: '/delivery-boy/offers/progress',
                query: { offer_id: offer.id }
            })
        },

        formatDate(date) {
            return moment(date).format('MMM DD, YYYY')
        },

        getDaysRemaining(offer) {
            const now = moment()
            const endDate = moment(offer.end_date)
            return Math.max(0, endDate.diff(now, 'days'))
        },

        getDaysRemainingColor(offer) {
            const days = this.getDaysRemaining(offer)
            if (days > 7) return 'success'
            if (days > 3) return 'warning'
            return 'danger'
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
.opacity-50 {
    opacity: 0.5;
}
</style>
