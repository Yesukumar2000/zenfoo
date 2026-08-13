<template>
    <div>
        <!-- Sub-tabs for Transaction Types -->
        <ul class="nav nav-pills mb-4">
            <li class="nav-item">
                <button
                    class="nav-link"
                    :class="{ 'active': activeSubTab === 'all' }"
                    @click="activeSubTab = 'all'"
                    type="button">
                    All Transactions
                </button>
            </li>
            <li class="nav-item">
                <button
                    class="nav-link"
                    :class="{ 'active': activeSubTab === 'paid' }"
                    @click="activeSubTab = 'paid'"
                    type="button">
                    Paid Transactions
                </button>
            </li>
            <!-- Hidden: Need to Pay tab
            <li class="nav-item">
                <button
                    class="nav-link"
                    :class="{ 'active': activeSubTab === 'needToPay' }"
                    @click="activeSubTab = 'needToPay'"
                    type="button">
                    Need to Pay
                </button>
            </li>
            -->
            <!-- Hidden: Weekly Payment tab
            <li class="nav-item">
                <button
                    class="nav-link"
                    :class="{ 'active': activeSubTab === 'weeklyPayment' }"
                    @click="activeSubTab = 'weeklyPayment'"
                    type="button">
                    Weekly Payment
                </button>
            </li>
            -->
        </ul>

        <!-- Sub-tab Content -->
        <div class="tab-content">
            <!-- All Transactions -->
            <div v-if="activeSubTab === 'all'">
                <seller-all-transactions :seller-id="sellerId"></seller-all-transactions>
            </div>

            <!-- Paid Transactions -->
            <div v-if="activeSubTab === 'paid'">
                <seller-paid-transactions :seller-id="sellerId"></seller-paid-transactions>
            </div>

            <!-- Hidden: Need to Pay
            <div v-if="activeSubTab === 'needToPay'">
                <seller-need-to-pay-transactions :seller-id="sellerId"></seller-need-to-pay-transactions>
            </div>
            -->

            <!-- Hidden: Weekly Payment
            <div v-if="activeSubTab === 'weeklyPayment'">
                <seller-weekly-payment :seller-id="sellerId"></seller-weekly-payment>
            </div>
            -->
        </div>
    </div>
</template>

<script>
import SellerAllTransactions from './SellerAllTransactions.vue';
import SellerPaidTransactions from './SellerPaidTransactions.vue';
import SellerNeedToPayTransactions from './SellerNeedToPayTransactions.vue';
import SellerWeeklyPayment from './SellerWeeklyPayment.vue';

export default {
    name: 'SellerTransactions',
    components: {
        'seller-all-transactions': SellerAllTransactions,
        'seller-paid-transactions': SellerPaidTransactions,
        'seller-need-to-pay-transactions': SellerNeedToPayTransactions,
        'seller-weekly-payment': SellerWeeklyPayment
    },
    props: {
        sellerId: {
            type: [Number, String],
            required: true
        }
    },
    data() {
        return {
            activeSubTab: 'all'
        };
    }
};
</script>

<style scoped>
.nav-pills {
    gap: 0.5rem;
    background: #f1f3f4;
    padding: 0.5rem;
    border-radius: 0.75rem;
    display: inline-flex;
}

.nav-pills .nav-item .nav-link {
    background: transparent;
    border: none;
    border-radius: 0.5rem;
    padding: 0.6rem 1.25rem;
    font-weight: 600;
    font-size: 0.875rem;
    color: #5a6169;
    transition: all 0.2s ease;
    cursor: pointer;
}

.nav-pills .nav-item .nav-link:hover {
    background: rgba(154, 196, 68, 0.15);
    color: #7a9c36;
}

.nav-pills .nav-item .nav-link.active {
    background: #9AC444;
    color: #fff;
    box-shadow: 0 2px 8px rgba(154, 196, 68, 0.4);
}

/* Dark theme support */
:deep(.theme-dark) .nav-pills,
.theme-dark .nav-pills {
    background: #2a2e33;
}

:deep(.theme-dark) .nav-pills .nav-item .nav-link,
.theme-dark .nav-pills .nav-item .nav-link {
    color: #adb5bd;
}

:deep(.theme-dark) .nav-pills .nav-item .nav-link:hover,
.theme-dark .nav-pills .nav-item .nav-link:hover {
    background: rgba(154, 196, 68, 0.2);
    color: #9AC444;
}

:deep(.theme-dark) .nav-pills .nav-item .nav-link.active,
.theme-dark .nav-pills .nav-item .nav-link.active {
    background: #9AC444;
    color: #fff;
}
</style>
