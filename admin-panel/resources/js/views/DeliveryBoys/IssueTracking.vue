<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>Driver Issues</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">Driver Issues</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/dashboard" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to Dashboard
                    </router-link>
                </div>
            </div>

            <section class="section">
                <div class="card">
                    <!-- Filters -->
                    <div class="card-header">
                        <div class="row">
                            <div class="col-md-3">
                                <label class="form-label">Issue Type</label>
                                <select v-model="activeTab" class="form-control form-select">
                                    <option value="order_earning">Order Earning</option>
                                    <option value="incorrect_payout">Incorrect Payout</option>
                                    <option value="incentive">Incentive</option>
                                    <option value="multi_order">Multi Order</option>
                                    <option value="joining_bonus">Joining Bonus</option>
                                    <option value="pocketing_issue">Pocketing Issues</option>
                                    <option value="not_getting_order_issue">Not Getting Orders</option>
                                    <option value="extra_floating_deposited">Extra Floating Deposited</option>
                                    <option value="cash_deposit_issue">Cash Deposit Issue</option>
                                </select>
                            </div>
                            <div class="col-md-3">
                                <label class="form-label">Filter by City</label>
                                <select v-model="selectedCityId" @change="onCityChange" class="form-control form-select">
                                    <option value="">All Cities</option>
                                    <option v-for="city in cities" :key="city.id" :value="city.id">
                                        {{ city.name }}
                                    </option>
                                </select>
                            </div>
                        </div>
                    </div>

                    <div class="card-body">
                        <!-- Tab Components -->
                        <OrderEarningIssues v-if="activeTab === 'order_earning'" :cityId="selectedCityId" />
                        <IncorrectPayoutIssues v-if="activeTab === 'incorrect_payout'" :cityId="selectedCityId" />
                        <IncentiveIssues v-if="activeTab === 'incentive'" :cityId="selectedCityId" />
                        <MultiOrderIssues v-if="activeTab === 'multi_order'" :cityId="selectedCityId" />
                        <JoiningBonusIssues v-if="activeTab === 'joining_bonus'" :cityId="selectedCityId" />
                        <PocketingIssues v-if="activeTab === 'pocketing_issue'" :cityId="selectedCityId" />
                        <NotGettingOrderIssues v-if="activeTab === 'not_getting_order_issue'" :cityId="selectedCityId" />
                        <ExtraFloatingDepositedIssues v-if="activeTab === 'extra_floating_deposited'" :cityId="selectedCityId" />
                        <CashDepositIssues v-if="activeTab === 'cash_deposit_issue'" :cityId="selectedCityId" />
                    </div>
                </div>
            </section>
        </div>
    </div>
</template>

<script>
import OrderEarningIssues from './DriverIssues/OrderEarningIssues.vue';
import IncorrectPayoutIssues from './DriverIssues/IncorrectPayoutIssues.vue';
import IncentiveIssues from './DriverIssues/IncentiveIssues.vue';
import MultiOrderIssues from './DriverIssues/MultiOrderIssues.vue';
import JoiningBonusIssues from './DriverIssues/JoiningBonusIssues.vue';
import PocketingIssues from './DriverIssues/PocketingIssues.vue';
import NotGettingOrderIssues from './DriverIssues/NotGettingOrderIssues.vue';
import ExtraFloatingDepositedIssues from './DriverIssues/ExtraFloatingDepositedIssues.vue';
import CashDepositIssues from './DriverIssues/CashDepositIssues.vue';

export default {
    name: 'IssueTracking',
    components: {
        OrderEarningIssues,
        IncorrectPayoutIssues,
        IncentiveIssues,
        MultiOrderIssues,
        JoiningBonusIssues,
        PocketingIssues,
        NotGettingOrderIssues,
        ExtraFloatingDepositedIssues,
        CashDepositIssues
    },
    data() {
        return {
            activeTab: 'order_earning',
            selectedCityId: '',
            cities: []
        }
    },
    created() {
        this.fetchCities();
    },
    methods: {
        fetchCities() {
            axios.get(this.$apiUrl + '/cities')
                .then((response) => {
                    if (response.data.status === 1) {
                        this.cities = response.data.data;
                    }
                })
                .catch((error) => {
                    console.error('Error fetching cities:', error);
                });
        },
        onCityChange() {
            // City change is handled by passing prop to child components
        }
    }
}
</script>

