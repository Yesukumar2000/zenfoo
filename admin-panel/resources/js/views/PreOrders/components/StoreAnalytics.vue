<template>
    <section class="section">
        <div class="card">
            <div class="card-header d-flex justify-content-between align-items-center">
                <h4 class="card-title mb-0">Store-wise Pre Order Analytics</h4>
                <button class="btn btn-sm btn-primary" @click="$emit('refresh')">
                    <i class="fa fa-refresh"></i> Refresh
                </button>
            </div>
            <div class="card-body">
                <div v-if="loading" class="text-center py-4">
                    <b-spinner></b-spinner>
                    <p class="mt-2">Loading analytics...</p>
                </div>
                <div v-else-if="storeData.length === 0" class="text-center py-4 text-muted">
                    <i class="fa fa-inbox fa-3x mb-3"></i>
                    <p>No store data available</p>
                </div>
                <div v-else class="table-responsive">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Store Name</th>
                                <th class="text-center">Pre Orders</th>
                                <th class="text-center">Total Items</th>
                                <th class="text-right">Total Amount</th>
                                <th class="text-center">Avg Order Value</th>
                                <th class="text-center">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="(store, index) in storeData" :key="store.store_id">
                                <td>{{ index + 1 }}</td>
                                <td><strong>{{ store.store_name }}</strong></td>
                                <td class="text-center">
                                    <span class="badge bg-primary">{{ store.order_count }}</span>
                                </td>
                                <td class="text-center">{{ store.item_count }}</td>
                                <td class="text-right"><strong>₹{{ parseFloat(store.total_amount).toFixed(2) }}</strong></td>
                                <td class="text-center">₹{{ (store.total_amount / store.order_count).toFixed(2) }}</td>
                                <td class="text-center">
                                    <button class="btn btn-sm btn-info me-1" @click="viewStore(store)" title="View Orders">
                                        <i class="fa fa-eye"></i>
                                    </button>
                                    <!-- <button class="btn btn-sm btn-danger me-1" @click="printPDF(store)" title="Print PDF">
                                        <i class="fa fa-file-pdf"></i>
                                    </button> -->
                                    <!-- <button class="btn btn-sm btn-success" @click="printInvoice(store)" title="Print Invoice">
                                        <i class="fa fa-print"></i>
                                    </button> -->
                                </td>
                            </tr>
                        </tbody>
                        <tfoot>
                            <tr class="table-info">
                                <td colspan="2"><strong>Total</strong></td>
                                <td class="text-center"><strong>{{ totalOrders }}</strong></td>
                                <td class="text-center"><strong>{{ totalItems }}</strong></td>
                                <td class="text-right"><strong>₹{{ totalAmount.toFixed(2) }}</strong></td>
                                <td class="text-center"><strong>₹{{ avgOrderValue.toFixed(2) }}</strong></td>
                                <td></td>
                            </tr>
                        </tfoot>
                    </table>
                </div>
            </div>
        </div>
    </section>
</template>

<script>
export default {
    name: 'StoreAnalytics',
    props: {
        storeData: {
            type: Array,
            default: () => []
        },
        loading: {
            type: Boolean,
            default: false
        }
    },
    computed: {
        totalOrders() {
            return this.storeData.reduce((sum, store) => sum + parseInt(store.order_count), 0);
        },
        totalItems() {
            return this.storeData.reduce((sum, store) => sum + parseInt(store.item_count), 0);
        },
        totalAmount() {
            return this.storeData.reduce((sum, store) => sum + parseFloat(store.total_amount), 0);
        },
        avgOrderValue() {
            return this.totalOrders > 0 ? this.totalAmount / this.totalOrders : 0;
        }
    },
    methods: {
        viewStore(store) {
            this.$emit('view-store', store);
        },
        printPDF(store) {
            this.$emit('print-pdf', store);
        },
        printInvoice(store) {
            this.$emit('print-invoice', store);
        }
    }
}
</script>

<style scoped>
.card {
    box-shadow: 0 0 10px rgba(0,0,0,0.05);
}
.me-1 {
    margin-right: 0.25rem;
}

/* Light mode styling for table footer */
.table-info {
    background-color: #f3e8ff !important;
    border-color: #d8b4fe !important;
}

.table-info td {
    color: #16a34a !important;
    border-color: #d8b4fe !important;
}

.table-info strong {
    color: #16a34a !important;
    font-weight: 600 !important;
}

/* Dark mode support for table footer */
@media (prefers-color-scheme: dark) {
    .table-info {
        background-color: #2e1065 !important;
        border-color: #6b21a8 !important;
    }

    .table-info td {
        color: #4ade80 !important;
        border-color: #6b21a8 !important;
    }

    .table-info strong {
        color: #4ade80 !important;
    }
}

/* Explicit dark mode class support */
:global(.dark) .table-info {
    background-color: #2e1065 !important;
    border-color: #6b21a8 !important;
}

:global(.dark) .table-info td {
    color: #4ade80 !important;
    border-color: #6b21a8 !important;
}

:global(.dark) .table-info strong {
    color: #4ade80 !important;
}
</style>