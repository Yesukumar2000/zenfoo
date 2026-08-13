<template>
    <div class="p-3">
        <div class="d-flex justify-content-between align-items-center">
            <div>
                <h5>Incentives</h5>
                <p class="text-muted mb-0">View incentive offers and progress for this delivery boy.</p>
            </div>
        </div>
        <hr>

        <!-- Loading State -->
        <div class="text-center py-4" v-if="isLoading">
            <b-spinner class="align-middle"></b-spinner>
            <strong class="ms-2">Loading incentives...</strong>
        </div>

        <!-- Summary Cards -->
        <div class="row mb-4" v-if="!isLoading && flattenedIncentives.length">
            <div class="col-md-4 col-sm-6 mb-2">
                <div class="card bg-primary text-white">
                    <div class="card-body text-center py-3">
                        <h6 class="mb-1">Total Incentive</h6>
                        <h4 class="mb-0">{{ $currency }} {{ parseFloat(totalIncentiveEarned).toFixed(2) }}</h4>
                    </div>
                </div>
            </div>
            <div class="col-md-4 col-sm-6 mb-2">
                <div class="card bg-success text-white">
                    <div class="card-body text-center py-3">
                        <h6 class="mb-1">Already Settled</h6>
                        <h4 class="mb-0">{{ $currency }} {{ parseFloat(settledAmount).toFixed(2) }}</h4>
                    </div>
                </div>
            </div>
            <div class="col-md-4 col-sm-6 mb-2">
                <div class="card bg-warning text-dark">
                    <div class="card-body text-center py-3">
                        <h6 class="mb-1">Pending Settlement</h6>
                        <h4 class="mb-0">{{ $currency }} {{ parseFloat(pendingAmount).toFixed(2) }}</h4>
                    </div>
                </div>
            </div>
        </div>

        <!-- Incentive Content -->
        <!-- <div v-else-if="incentiveProgress.length > 0">
            <div class="row mb-4">
                <div class="col-md-3 col-sm-6 mb-2">
                    <div class="card bg-primary text-white">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Active Offers</h6>
                            <h4 class="mb-0">{{ activeOffersCount }}</h4>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 col-sm-6 mb-2">
                    <div class="card bg-success text-white">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Total Earned</h6>
                            <h4 class="mb-0">{{ $currency }} {{ parseFloat(totalIncentiveEarned).toFixed(2) }}</h4>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 col-sm-6 mb-2">
                    <div class="card bg-info text-white">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Current Earnings</h6>
                            <h4 class="mb-0">{{ $currency }} {{ parseFloat(totalCurrentEarnings).toFixed(2) }}</h4>
                        </div>
                    </div>
                </div>
                <div class="col-md-3 col-sm-6 mb-2">
                    <div class="card bg-warning text-dark">
                        <div class="card-body text-center py-3">
                            <h6 class="mb-1">Gigs Completed</h6>
                            <h4 class="mb-0">{{ totalGigsCompleted }}</h4>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row">
                <div class="col-12" v-for="progress in incentiveProgress" :key="progress.id">
                    <div class="card mb-3" :class="getOfferCardClass(progress)">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <div>
                                <h6 class="mb-0">{{ progress.offer_name }}</h6>
                                <small class="text-muted">
                                    {{ formatDate(progress.offer_start_date) }} - {{ formatDate(progress.offer_end_date) }}
                                </small>
                            </div>
                            <div class="d-flex align-items-center">
                                <span class="badge me-2" :class="getStatusBadgeClass(progress)">
                                    {{ getStatusText(progress) }}
                                </span>
                                <span class="badge" :class="getEligibilityBadgeClass(progress.is_eligible)">
                                    {{ progress.is_eligible ? 'Eligible' : 'Not Eligible' }}
                                </span>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-6">
                                    <h6 class="text-muted mb-3">Progress</h6>
                                    <div class="row">
                                        <div class="col-6 mb-2">
                                            <small class="text-muted d-block">Current Earnings</small>
                                            <strong>{{ $currency }} {{ parseFloat(progress.current_earnings).toFixed(2) }}</strong>
                                        </div>
                                        <div class="col-6 mb-2">
                                            <small class="text-muted d-block">Gigs Completed</small>
                                            <strong>{{ progress.gigs_completed }}</strong>
                                        </div>
                                        <div class="col-6 mb-2">
                                            <small class="text-muted d-block">Gigs Skipped</small>
                                            <strong :class="progress.gigs_skipped > 0 ? 'text-warning' : ''">
                                                {{ progress.gigs_skipped }}
                                            </strong>
                                        </div>
                                        <div class="col-6 mb-2">
                                            <small class="text-muted d-block">Orders Cancelled</small>
                                            <strong :class="progress.orders_cancelled > 0 ? 'text-danger' : ''">
                                                {{ progress.orders_cancelled }}
                                            </strong>
                                        </div>
                                        <div class="col-6 mb-2">
                                            <small class="text-muted d-block">Incentive Earned</small>
                                            <strong class="text-success">{{ $currency }} {{ parseFloat(progress.incentive_earned).toFixed(2) }}</strong>
                                        </div>
                                        <div class="col-6 mb-2">
                                            <small class="text-muted d-block">Login Compliance</small>
                                            <strong :class="progress.login_compliance ? 'text-success' : 'text-danger'">
                                                {{ progress.login_compliance ? 'Yes' : 'No' }}
                                            </strong>
                                        </div>
                                    </div>
                                </div>

                                <div class="col-md-6">
                                    <h6 class="text-muted mb-3">Tier Progress</h6>

                                    <div v-if="progress.current_tier" class="mb-2">
                                        <small class="text-muted d-block">Current Tier Achieved</small>
                                        <span class="badge bg-success">
                                            {{ progress.current_tier.tier_name }}
                                            - {{ $currency }} {{ parseFloat(progress.current_tier.incentive_amount).toFixed(2) }}
                                        </span>
                                    </div>
                                    <div v-else class="mb-2">
                                        <small class="text-muted d-block">Current Tier</small>
                                        <span class="badge bg-secondary">No tier achieved yet</span>
                                    </div>

                                    <div v-if="progress.next_tier" class="mb-2">
                                        <small class="text-muted d-block">Next Tier</small>
                                        <span class="badge bg-info">
                                            {{ progress.next_tier.tier_name }}
                                            - Target: {{ $currency }} {{ parseFloat(progress.next_tier.earnings_target).toFixed(2) }}
                                        </span>
                                        <div class="mt-2">
                                            <small class="text-muted">
                                                Remaining: {{ $currency }} {{ parseFloat(progress.next_tier.remaining_earnings).toFixed(2) }}
                                            </small>
                                            <b-progress :value="progress.next_tier.progress_percentage" :max="100" class="mt-1" height="8px">
                                                <b-progress-bar :value="progress.next_tier.progress_percentage" variant="info"></b-progress-bar>
                                            </b-progress>
                                        </div>
                                    </div>
                                    <div v-else-if="progress.current_tier" class="mb-2">
                                        <small class="text-muted d-block">Next Tier</small>
                                        <span class="badge bg-success">Maximum tier achieved!</span>
                                    </div>

                                    <div class="mt-3" v-if="progress.days_remaining !== undefined">
                                        <small class="text-muted d-block">Days Remaining</small>
                                        <strong :class="progress.days_remaining < 0 ? 'text-danger' : (progress.days_remaining <= 3 ? 'text-warning' : 'text-success')">
                                            {{ progress.days_remaining < 0 ? 'Expired' : progress.days_remaining + ' days' }}
                                        </strong>
                                    </div>
                                </div>
                            </div>

                            <div class="mt-4" v-if="progress.tiers && progress.tiers.length > 0">
                                <h6 class="text-muted mb-3">All Tiers</h6>
                                <div class="table-responsive">
                                    <table class="table table-sm table-bordered">
                                        <thead>
                                            <tr>
                                                <th>Tier</th>
                                                <th>Earnings Target</th>
                                                <th>Incentive Amount</th>
                                                <th>Status</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="tier in progress.tiers" :key="tier.tier_name" :class="tier.is_achieved ? 'table-success' : ''">
                                                <td>{{ tier.tier_name }}</td>
                                                <td>{{ $currency }} {{ parseFloat(tier.earnings_target).toFixed(2) }}</td>
                                                <td>{{ $currency }} {{ parseFloat(tier.incentive_amount).toFixed(2) }}</td>
                                                <td>
                                                    <span v-if="tier.is_achieved" class="badge bg-success">Achieved</span>
                                                    <span v-else class="badge bg-secondary">Pending</span>
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            <div class="mt-3" v-if="progress.credited_tiers && progress.credited_tiers.length > 0">
                                <h6 class="text-muted mb-2">Credited Incentives</h6>
                                <div class="table-responsive">
                                    <table class="table table-sm table-bordered">
                                        <thead>
                                            <tr>
                                                <th>Amount</th>
                                                <th>Credited At</th>
                                                <th>Transaction ID</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <tr v-for="credit in progress.credited_tiers" :key="credit.transaction_id">
                                                <td class="text-success fw-bold">{{ $currency }} {{ parseFloat(credit.incentive_amount).toFixed(2) }}</td>
                                                <td>{{ formatDateTime(credit.credited_at) }}</td>
                                                <td><code>{{ credit.transaction_id }}</code></td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>

                            <div class="mt-3" v-if="progress.eligibility_status && !progress.eligibility_status.is_eligible">
                                <div class="alert alert-warning mb-0">
                                    <h6 class="alert-heading"><i class="fa fa-exclamation-triangle me-1"></i>Eligibility Issues</h6>
                                    <ul class="mb-0 ps-3">
                                        <li v-for="issue in progress.eligibility_status.issues" :key="issue">{{ issue }}</li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div> -->

        <!-- No Incentives -->
        <!-- <div class="text-center py-4" v-else>
            <i class="fa fa-gift fa-3x text-muted mb-3"></i>
            <p>No incentive progress found for this delivery boy.</p>
            <p class="text-muted">The delivery boy hasn't participated in any incentive offers yet.</p>
        </div> -->

        <div class="table-responsive" v-if="flattenedIncentives.length">
            <table class="table table-bordered table-sm">
                <thead class="table-light">
                    <tr>
                        <th>Offer Name</th>
                        <th>Tier</th>
                        <th>Earnings Target</th>
                        <th>Incentive Amount</th>
                        <th>Added At</th>
                        <th>Transaction ID</th>
                        <th>Settled At</th>
                        <th>Bank Account</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="(row, i) in flattenedIncentives" :key="i">
                        <td>{{ row.offer_name }}</td>
                        <td>{{ row.tier_name }}</td>
                        <td>{{ $currency }} {{ parseFloat(row.earnings_target).toFixed(2) }}</td>
                        <td class="text-success fw-bold">
                            {{ $currency }} {{ parseFloat(row.incentive_amount).toFixed(2) }}
                        </td>
                        <td>
                            <span v-if="row.credited_at">
                                {{ formatDateTime(row.credited_at) }}
                            </span>
                            <span v-else class="text-muted">Not credited</span>
                        </td>
                        <td>
                            <code v-if="row.transaction_id">#{{ row.transaction_id }}</code>
                            <span v-else class="text-muted">-</span>
                        </td>
                        <td>
                            <span v-if="row.settled_at" class="text-success">
                                {{ formatDateTime(row.settled_at) }}
                            </span>
                            <span v-else class="badge bg-warning text-dark">Pending</span>
                        </td>
                        <td>
                            <span v-if="row.bank_acc_number">{{ row.bank_acc_number }}</span>
                            <span v-else class="text-muted">-</span>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>

    </div>
</template>

<script>
export default {
    name: 'DeliveryBoyIncentives',
    props: {
        deliveryBoyId: {
            type: [Number, String],
            required: true
        }
    },
    data() {
        return {
            incentives: [],
            totalIncentiveEarned: 0,
            settledAmount: 0,
            pendingAmount: 0,
            isLoading: false,
            isLoaded: false
        };
    },
    computed: {
        flattenedIncentives() {
            return this.incentives;
        }
    },
    mounted() {
        this.loadIncentives();
    },
    methods: {
        loadIncentives() {
            if (this.isLoaded) return;

            this.isLoading = true;

            axios.get(this.$apiUrl + '/delivery_boys/' + this.deliveryBoyId + '/incentives')
                .then((response) => {
                    this.isLoading = false;
                    this.isLoaded = true;
                    if (response.data.status === 1) {
                        this.incentives = response.data.data.incentives || [];
                        this.totalIncentiveEarned = response.data.data.total_incentive_earned || 0;
                        this.settledAmount = response.data.data.settled_amount || 0;
                        this.pendingAmount = response.data.data.pending_amount || 0;
                    } else {
                        this.incentives = [];
                    }
                })
                .catch(() => {
                    this.isLoading = false;
                    this.isLoaded = true;
                    this.incentives = [];
                });
        },
        formatDate(dateString) {
            if (!dateString) return '-';
            const date = new Date(dateString);
            return date.toLocaleDateString('en-GB');
        },
        formatDateTime(dateString) {
            if (!dateString) return '-';
            const date = new Date(dateString);
            return date.toLocaleDateString('en-GB') + ' ' + date.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
        }
    }
};
</script>

<style scoped>
.fw-bold {
    font-weight: bold;
}
.card {
    border-width: 2px;
}
</style>
