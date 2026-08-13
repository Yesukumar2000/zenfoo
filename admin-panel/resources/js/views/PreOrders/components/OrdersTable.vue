<template>
    <div>
        <b-table
            :items="orders"
            :fields="fields"
            :busy="loading"
            responsive
            striped
            hover
            show-empty
        >
            <template #table-busy>
                <div class="text-center my-2">
                    <b-spinner class="align-middle"></b-spinner>
                    <strong class="ml-2">Loading...</strong>
                </div>
            </template>

            <template #cell(id)="data">
                <router-link :to="`/orders/view/${data.item.id}`">
                    #{{ data.item.id }}
                </router-link>
            </template>

            <template #cell(user_name)="data">
                {{ data.item.user_name || 'Guest' }}
            </template>

            <template #cell(final_total)="data">
                ₹{{ data.item.final_total }}
            </template>

            <template #cell(preorder_placed_at_formatted)="data">
                <small>{{ data.item.preorder_placed_at_formatted }}</small>
            </template>

            <template #cell(preorder_process_date_formatted)="data">
                <small class="text-info">{{ data.item.preorder_process_date_formatted }}</small>
            </template>

            <template #cell(status)="data">
                <span v-if="data.item.active_status == 12" class="badge bg-warning">Preorder Pending</span>
                <span v-else-if="data.item.active_status == 2" class="badge bg-success">Processed</span>
                <span v-else-if="data.item.active_status == 3" class="badge bg-info">In Progress</span>
                <span v-else-if="data.item.active_status == 5" class="badge bg-primary">Out For Delivery</span>
                <span v-else-if="data.item.active_status == 6" class="badge bg-success">Delivered</span>
                <span v-else class="badge bg-secondary">Status {{ data.item.active_status }}</span>
            </template>

            <template #cell(actions)="data">
                <router-link :to="`/orders/view/${data.item.id}`" class="btn btn-sm btn-primary me-1">
                    <i class="fa fa-eye"></i> View
                </router-link>
                <div class="btn-group">
                    <button type="button" class="btn btn-sm btn-info dropdown-toggle" data-bs-toggle="dropdown">
                        <i class="fa fa-print"></i>
                    </button>
                    <ul class="dropdown-menu">
                        <li><a class="dropdown-item" href="#" @click.prevent="printThermal(data.item.id)">
                            <i class="fa fa-receipt"></i> Thermal Print (80mm)
                        </a></li>
                        <li><a class="dropdown-item" href="#" @click.prevent="printUSB(data.item.id)">
                            <i class="fa fa-usb"></i> Direct USB Print
                        </a></li>
                        <li><hr class="dropdown-divider"></li>
                        <li><a class="dropdown-item" href="#" @click.prevent="downloadPDF(data.item.id)">
                            <i class="fa fa-file-pdf"></i> Download PDF
                        </a></li>
                    </ul>
                </div>
            </template>
        </b-table>

        <!-- Pagination -->
        <div class="row mt-3">
            <div class="col-md-6">
                <p>Showing {{ orders.length }} of {{ totalRows }} orders</p>
            </div>
            <div class="col-md-6">
                <b-pagination
                    :value="currentPage"
                    :total-rows="totalRows"
                    :per-page="perPage"
                    align="right"
                    size="sm"
                    @input="$emit('page-change', $event)"
                ></b-pagination>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    name: 'OrdersTable',
    props: {
        orders: {
            type: Array,
            default: () => []
        },
        loading: {
            type: Boolean,
            default: false
        },
        currentPage: {
            type: Number,
            default: 1
        },
        perPage: {
            type: Number,
            default: 10
        },
        totalRows: {
            type: Number,
            default: 0
        }
    },
    data() {
        return {
            fields: [
                { key: 'id', label: 'Order ID', sortable: true },
                { key: 'user_name', label: 'Customer', sortable: false },
                { key: 'mobile', label: 'Mobile', sortable: false },
                { key: 'final_total', label: 'Total', sortable: false },
                { key: 'payment_method', label: 'Payment', sortable: false },
                { key: 'preorder_placed_at_formatted', label: 'Placed At', sortable: false },
                { key: 'preorder_process_date_formatted', label: 'Process Date', sortable: false },
                { key: 'status', label: 'Status', sortable: false },
                { key: 'actions', label: 'Actions', sortable: false }
            ]
        }
    },
    methods: {
        printThermal(orderId) {
            this.$emit('print-thermal', orderId);
        },
        printUSB(orderId) {
            this.$emit('print-usb', orderId);
        },
        downloadPDF(orderId) {
            this.$emit('download-pdf', orderId);
        }
    }
}
</script>

<style scoped>
.badge {
    padding: 5px 10px;
}
.me-1 {
    margin-right: 0.25rem;
}
</style>