<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Customer App Home Screen - Products</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item"><router-link to="/dashboard">Dashboard</router-link></li>
                            <li class="breadcrumb-item active" aria-current="page">Section Products</li>
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

        <div class="row">
            <div class="col-12 col-md-12 order-md-1 order-last">
                <div class="card">
                    <div class="card-header">
                        <h4>Manage Section Products</h4>
                        <span class="pull-right">
                            <button class="btn btn-primary" @click="edit_record=true">
                                <i class="fa fa-plus"></i> Add Products
                            </button>
                        </span>
                    </div>
                    <div class="card-body">
                        <b-row class="mb-2">
                            <b-col md="3">
                                <h6 class="box-title">Section</h6>
                                <b-form-select
                                    v-model="selectedSection"
                                    :options="sectionOptions"
                                    @change="getRecords()"
                                    class="form-control form-select"
                                >
                                </b-form-select>
                            </b-col>
                            <b-col md="3" offset-md="5">
                                <h6 class="box-title">Search</h6>
                                <b-form-input
                                    id="filter-input"
                                    v-model="filter"
                                    type="search"
                                    placeholder="Search..."
                                    @input="getRecords()"
                                ></b-form-input>
                            </b-col>
                            <b-col md="1" class="text-center">
                                <button class="btn btn-primary btn_refresh" v-b-tooltip.hover title="Refresh" @click="getRecords()">
                                    <i class="fa fa-refresh" aria-hidden="true"></i>
                                </button>
                            </b-col>
                        </b-row>

                        <div v-if="selectedSection && sectionProducts.length > 0" class="alert alert-info mb-3">
                            <i class="fa fa-info-circle"></i> Drag and drop rows to reorder products
                        </div>

                        <div class="table-responsive">
                            <table class="table table-bordered table-sm">
                                <thead>
                                    <tr>
                                        <th v-if="selectedSection" width="50">Drag</th>
                                        <th width="60">ID</th>
                                        <th width="80">Image</th>
                                        <th>Product</th>
                                        <th>Category</th>
                                        <th>Section</th>
                                        <th width="80">Order</th>
                                        <th width="80">Actions</th>
                                    </tr>
                                </thead>
                                <tbody v-if="isLoading">
                                    <tr>
                                        <td :colspan="selectedSection ? 8 : 7" class="text-center py-4">
                                            <b-spinner class="align-middle"></b-spinner>
                                            <strong class="ms-2">Loading...</strong>
                                        </td>
                                    </tr>
                                </tbody>
                                <tbody v-else-if="sectionProducts.length === 0">
                                    <tr>
                                        <td :colspan="selectedSection ? 8 : 7" class="text-center py-3">
                                            No products found
                                        </td>
                                    </tr>
                                </tbody>
                                <tbody v-else>
                                    <tr
                                        v-for="(item, index) in sectionProducts"
                                        :key="item.id"
                                        :draggable="selectedSection ? 'true' : 'false'"
                                        @dragstart="selectedSection && dragStart(index, $event)"
                                        @dragover.prevent="selectedSection && dragOver(index, $event)"
                                        @dragenter.prevent="selectedSection && dragEnter(index, $event)"
                                        @dragleave="selectedSection && dragLeave($event)"
                                        @drop="selectedSection && drop(index, $event)"
                                        @dragend="selectedSection && dragEnd($event)"
                                        :class="{'dragging': draggedIndex === index, 'drag-over': dragOverIndex === index, 'draggable-row': selectedSection}"
                                    >
                                        <td v-if="selectedSection" class="text-center" style="cursor: move;">
                                            <i class="fa fa-grip-vertical text-muted"></i>
                                        </td>
                                        <td>{{ item.id }}</td>
                                        <td>
                                            <img v-if="item.product_image_url" :src="item.product_image_url" width="50" height="50" class="rounded" />
                                            <span v-else class="text-muted small">No Image</span>
                                        </td>
                                        <td>{{ item.product_name || 'N/A' }}</td>
                                        <td>{{ item.category_name || 'N/A' }}</td>
                                        <td>{{ item.section_name || 'N/A' }}</td>
                                        <td>{{ item.display_order }}</td>
                                        <td>
                                            <button class="btn btn-sm btn-danger" @click="deleteRecord(index, item.id)" v-b-tooltip.hover title="Delete">
                                                <i class="fa fa-trash"></i>
                                            </button>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>

                        <div class="text-end mt-2" v-if="hasOrderChanged && selectedSection">
                            <button @click="saveOrder" class="btn btn-success" :disabled="isSavingOrder">
                                <i class="fa fa-save"></i> {{ isSavingOrder ? 'Saving...' : 'Save Order' }}
                            </button>
                        </div>

                        <b-row class="mt-3">
                            <b-col md="2" class="my-1">
                                <b-form-group
                                    label="Per Page"
                                    label-for="per-page-select"
                                    label-align-sm="right"
                                    label-size="sm"
                                    class="mb-0">
                                    <b-form-select
                                        id="per-page-select"
                                        v-model="perPage"
                                        :options="pageOptions"
                                        size="sm"
                                        class="form-control form-select"
                                    ></b-form-select>
                                </b-form-group>
                            </b-col>
                            <b-col md="4" class="my-1" offset-md="6">
                                <label>Total Records: {{ totalRows }} </label>
                                <b-pagination
                                    v-model="currentPage"
                                    :total-rows="totalRows"
                                    :per-page="perPage"
                                    align="fill"
                                    size="sm"
                                    class="my-0"
                                ></b-pagination>
                            </b-col>
                        </b-row>
                    </div>
                </div>
            </div>
        </div>

        <!-- Add / Edit -->
        <app-edit-record
            v-if="edit_record"
            :record="edit_record"
            @modalClose="edit_record = null"
            @recordSaved="getRecords()"
        ></app-edit-record>
    </div>
</template>

<script>
import EditRecord from './EditProduct.vue';

export default {
    components: {
        'app-edit-record': EditRecord,
    },
    data() {
        return {
            sectionProducts: [],
            originalProductsOrder: [],
            fields: [
                { key: 'drag', label: '' },
                { key: 'id', label: 'ID', sortable: true },
                { key: 'product_image', label: 'Image' },
                { key: 'product_name', label: 'Product', sortable: true },
                { key: 'category_name', label: 'Category', sortable: true },
                { key: 'section_name', label: 'Section', sortable: true },
                { key: 'display_order', label: 'Order', sortable: true },
                { key: 'actions', label: 'Actions' }
            ],
            filter: '',
            filterOn: ['product_name'],
            sortBy: 'display_order',
            sortDesc: false,
            sortDirection: 'asc',
            currentPage: 1,
            perPage: 10,
            pageOptions: [10, 25, 50, 100],
            totalRows: 0,
            isLoading: false,
            edit_record: null,
            sections: [],
            selectedSection: null,
            sectionOptions: [],
            // Drag and drop
            draggedIndex: null,
            dragOverIndex: null,
            isSavingOrder: false
        }
    },
    computed: {
        hasOrderChanged() {
            if (!this.selectedSection) return false;
            if (this.sectionProducts.length !== this.originalProductsOrder.length) {
                return true;
            }
            return this.sectionProducts.some((product, index) =>
                product.id !== this.originalProductsOrder[index]?.id
            );
        }
    },
    mounted() {
        this.getSections();
        this.getRecords();
    },
    watch: {
        currentPage: function() {
            this.getRecords();
        },
        perPage: function() {
            this.getRecords();
        }
    },
    methods: {
        getSections() {
            axios.get(this.$apiUrl + '/products/customer-app-sections', {
                params: { per_page: 1000 }
            }).then((response) => {
                this.sections = response.data.data;
                this.sectionOptions = [
                    { value: null, text: 'All Sections' },
                    ...this.sections.map(section => ({ value: section.id, text: section.name }))
                ];
            }).catch(() => {
                console.error('Failed to fetch sections');
            });
        },
        getRecords() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/products/customer-app-section-products', {
                params: {
                    page: this.currentPage,
                    per_page: this.perPage,
                    filter: this.filter,
                    section_id: this.selectedSection
                }
            }).then((response) => {
                this.sectionProducts = response.data.data;
                this.totalRows = response.data.total;
                // Store original order for comparison
                this.originalProductsOrder = JSON.parse(JSON.stringify(this.sectionProducts));
                this.isLoading = false;
            }).catch((error) => {
                console.error('Error fetching section products:', error);
                this.isLoading = false;
                this.showMessage('error', 'Failed to load section products');
            });
        },
        deleteRecord(index, id) {
            this.$swal.fire({
                title: 'Are you sure?',
                text: "You won't be able to revert this!",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
                confirmButtonText: 'Yes, delete it!'
            }).then((result) => {
                if (result.value) {
                    this.isLoading = true;
                    axios.post(this.$apiUrl + '/products/customer-app-section-products/delete', { id: id })
                        .then((response) => {
                            if (response.data.status === 1) {
                                this.showMessage('success', response.data.message);
                                this.sectionProducts.splice(index, 1);
                                this.getRecords();
                            } else {
                                this.showMessage('error', response.data.message);
                            }
                            this.isLoading = false;
                        })
                        .catch((error) => {
                            console.error('Error deleting record:', error);
                            this.showMessage('error', 'Failed to delete record');
                            this.isLoading = false;
                        });
                }
            });
        },

        // Drag and Drop methods
        dragStart(index, event) {
            this.draggedIndex = index;
            event.dataTransfer.effectAllowed = 'move';
            event.target.style.opacity = '0.5';
        },

        dragOver(index, event) {
            event.dataTransfer.dropEffect = 'move';
        },

        dragEnter(index, event) {
            this.dragOverIndex = index;
        },

        dragLeave(event) {
            // Only clear if we're leaving the entire row
            if (event.target.tagName === 'TR') {
                this.dragOverIndex = null;
            }
        },

        drop(index, event) {
            event.stopPropagation();

            if (this.draggedIndex !== null && this.draggedIndex !== index) {
                // Reorder the array
                const draggedItem = this.sectionProducts[this.draggedIndex];
                this.sectionProducts.splice(this.draggedIndex, 1);
                this.sectionProducts.splice(index, 0, draggedItem);

                // Update display_order for all items
                this.sectionProducts.forEach((item, idx) => {
                    item.display_order = idx;
                });
            }

            this.dragOverIndex = null;
        },

        dragEnd(event) {
            event.target.style.opacity = '1';
            this.draggedIndex = null;
            this.dragOverIndex = null;
        },

        async saveOrder() {
            this.isSavingOrder = true;

            try {
                const items = this.sectionProducts.map((product, index) => ({
                    id: product.id,
                    display_order: index
                }));

                const res = await axios.post(this.$apiUrl + '/products/customer-app-section-products/reorder', {
                    items: items
                });

                if (res.data.status === 1) {
                    this.showMessage('success', 'Product order saved successfully');
                    // Update original order after successful save
                    this.originalProductsOrder = JSON.parse(JSON.stringify(this.sectionProducts));
                } else {
                    this.showMessage('error', res.data.message || 'Failed to save order');
                }
            } catch (error) {
                console.error('Error:', error);
                this.showMessage('error', 'Failed to save product order');
            } finally {
                this.isSavingOrder = false;
            }
        }
    }
}
</script>

<style scoped>
.btn_refresh {
    margin-top: 25px;
}
.pull-right {
    float: right;
}

.draggable-row {
    cursor: move;
    transition: all 0.2s;
}

.draggable-row.dragging {
    opacity: 0.5;
    background-color: #f0f0f0;
}

.draggable-row.drag-over {
    border-top: 3px solid #9AC444;
}

.draggable-row:hover {
    background-color: #f8f9fa;
}
</style>