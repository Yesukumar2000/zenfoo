<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Food Products</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">Food Products</li>
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

        <!-- Zone / City / Seller Filter -->
        <div class="mb-3 d-flex gap-2">
            <select v-model="city_id" @change="onZoneChange()" class="form-control form-select city-zone-select">
                <option value="">All Zones</option>
                <option v-for="city in cities" :key="city.id" :value="city.id">{{ city.name }}</option>
                <option value="other">Other</option>
            </select>
            <select v-model="seller" @change="getRecords()" class="form-control form-select city-zone-select">
                <option value="">All Sellers</option>
                <option v-for="s in sellers" :key="s.id" :value="s.id">{{ s.name }}</option>
            </select>
        </div>

        <div class="row">
            <div class="col-12 col-md-12 order-md-1 order-last">
                <div class="card">
                    <div class="card-header">
                        <h4>Food Products</h4>
                        <!-- <span class="pull-right">
                            <router-link
                                to="/food_products/create"
                                class="btn btn-primary"
                                v-b-tooltip.hover
                                title="Add Food Product"
                                v-if="$can('product_create')"
                            >
                                {{ __('add_product') }}
                            </router-link>
                        </span> -->
                    </div>

                    <div class="card-body">
                        <div class="row">
                            <div class="form-group col-md-3">
                                <b-dropdown
                                    size="sm"
                                    dropright
                                    :text="__('actions')"
                                    split-variant="outline-primary"
                                    variant="primary"
                                    class="m-2"
                                    :disabled="selectedItems.length === 0"
                                >
                                    <b-dropdown-item href="javascript:void(0);" @click="multipleDelete">
                                        <span class="text-danger" style="font-weight: bold;">
                                            <i class="fa fa-trash"></i> {{ __('delete_selected_products') }}
                                        </span>
                                    </b-dropdown-item>
                                </b-dropdown>
                            </div>
                        </div>

                        <b-row class="mb-2">
                            <b-col md="2">
                                <h6 class="box-title">{{ __('category') }}</h6>
                                <select @change="getRecords()" v-model="category" class="form-control form-select">
                                    <option value="">{{ __('all_categories') }}</option>
                                    <option v-for="cat in categories" :key="cat.id" :value="cat.id">
                                        {{ cat.name }}
                                    </option>
                                </select>
                            </b-col>

                            <b-col md="2">
                                <h6 class="box-title">{{ __('status') }}</h6>
                                <select @change="getRecords()" v-model="is_approved" class="form-control form-select">
                                    <option value="">{{ __('select_status') }}</option>
                                    <option value="1">Approved</option>
                                    <option value="0">Not-Approved</option>
                                </select>
                            </b-col>

                            <b-col md="3" offset-md="3">
                                <h6 class="box-title">{{ __('search') }}</h6>
                                <b-form-input
                                    id="filter-input"
                                    v-model="filter"
                                    type="search"
                                    :placeholder="__('search')"
                                    @input="getRecords()"
                                ></b-form-input>
                            </b-col>

                            <b-col md="2" class="text-center">
                                <div class="btn-group btn_tool" role="group">
                                    <button
                                        type="button"
                                        class="btn btn-primary"
                                        v-b-tooltip.hover
                                        :title="__('refresh')"
                                        @click="getRecords()"
                                    >
                                        <i class="fa fa-refresh" aria-hidden="true"></i>
                                    </button>

                                    <b-dropdown dropleft menu-class="w-100 border dropdownOverflow" v-b-tooltip.hover title="Columns">
                                        <template #button-content>
                                            <i class="fa fa-th-list"></i>
                                        </template>
                                        <li class="m-1" v-for="field in fields" :key="field.key" v-if="field.key !== 'select'">
                                            <input
                                                type="checkbox"
                                                :id="field.key"
                                                :disabled="visibleFields.length == 1 && field.visible"
                                                v-model="field.visible"
                                                class="form-check-input"
                                            >
                                            <label :for="field.key">{{ field.label }}</label>
                                            <b-dropdown-divider></b-dropdown-divider>
                                        </li>
                                    </b-dropdown>
                                </div>
                            </b-col>
                        </b-row>

                        <div class="table-responsive">
                            <b-table
                                :items="products"
                                :fields="visibleFields"
                                :filter="filter"
                                :filter-included-fields="filterOn"
                                :sort-by.sync="sortBy"
                                :sort-desc.sync="sortDesc"
                                :sort-direction="sortDirection"
                                :bordered="true"
                                :busy="isLoading"
                                stacked="md"
                                show-empty
                                small
                            >
                                <template #table-busy>
                                    <div class="text-center text-black my-2">
                                        <b-spinner class="align-middle"></b-spinner>
                                        <strong>{{ __('loading') }}...</strong>
                                    </div>
                                </template>

                                <template #head(select)="row">
                                    <input type="checkbox" v-model="all_select" @click="allSelectCheckBox" class="form-check-input">
                                </template>
                                <template #cell(select)="row">
                                    <input
                                        type="checkbox"
                                        v-model="selectedItems"
                                        @change="selectCheckBox"
                                        :value="`${row.item.product_variant_id}`"
                                        class="form-check-input"
                                    >
                                </template>

                                <template #cell(image)="row">
                                    <img :src="$mediaUrl(row.item.image)" alt="Image" height="50" />
                                </template>

                                <template #cell(measurement)="row">
                                    {{ row.item.measurement }}
                                    <span v-if="row.item.stock_unit">{{ row.item.stock_unit }}</span>
                                </template>

                                <template #cell(stock)="row">
                                    <span v-if="row.item.is_unlimited_stock === 1 || row.item.is_unlimited_stock === '1'">Unlimited</span>
                                    <template v-else>{{ Math.floor(row.item.stock) }}</template>
                                </template>

                                <template #cell(availability)="row">
                                    <a class="btn btn-sm" @click="updateStatusProduct(row.index, row.item.id)">
                                        <span class="primary-toggal" v-if="row.item.status == 1">
                                            <i class="fa fa-toggle-on fa-2x"></i>
                                        </span>
                                        <span class="text-danger" v-else>
                                            <i class="fa fa-toggle-off fa-2x"></i>
                                        </span>
                                    </a>
                                </template>

                                <template #cell(approve_toggle)="row">
                                    <a class="btn btn-sm" @click="updateApproveProduct(row.index, row.item.id)">
                                        <span class="primary-toggal" v-if="row.item.is_approved == 1">
                                            <i class="fa fa-toggle-on fa-2x"></i>
                                        </span>
                                        <span class="text-danger" v-else>
                                            <i class="fa fa-toggle-off fa-2x"></i>
                                        </span>
                                    </a>
                                </template>

                                <template #cell(status)="row">
                                    <span class="badge bg-success" v-if="row.item.status == 1">Available</span>
                                    <span class="badge bg-danger" v-if="row.item.status == 0">Sold Out</span>
                                </template>

                                <template #cell(indicator)="row">
                                    <span class="badge bg-info" v-if="row.item.indicator == 0">None</span>
                                    <span class="badge bg-success" v-if="row.item.indicator == 1">Veg</span>
                                    <span class="badge bg-danger" v-if="row.item.indicator == 2">Non-Veg</span>
                                </template>

                                <template #cell(is_approved)="row">
                                    <span class="badge bg-success" v-if="row.item.is_approved == 1">Approved</span>
                                    <span class="badge bg-danger" v-if="row.item.is_approved == 0">Not-Approved</span>
                                </template>

                                <template #cell(actions)="row">
                                    <router-link
                                        :to="{ name: 'ViewProduct', params: { id: row.item.id, record: row.item } }"
                                        class="btn btn-primary btn-sm"
                                        v-b-tooltip.hover
                                        :title="__('view')"
                                    >
                                        <i class="fa fa-eye"></i>
                                    </router-link>
                                    <router-link
                                        :to="{ name: 'FoodEditProduct', params: { id: row.item.id } }"
                                        class="btn btn-success btn-sm"
                                        v-b-tooltip.hover
                                        :title="__('edit')"
                                    >
                                        <i class="fa fa-pencil-alt"></i>
                                    </router-link>
                                    <button
                                        class="btn btn-danger btn-sm"
                                        @click="deleteRecord(row.index, row.item.product_variant_id)"
                                        v-b-tooltip.hover
                                        :title="__('delete')"
                                    >
                                        <i class="fa fa-trash"></i>
                                    </button>
                                </template>
                            </b-table>
                        </div>

                        <b-row>
                            <b-col md="2">
                                <b-form-group
                                    :label="__('per_page')"
                                    label-for="per-page-select"
                                    label-align-sm="right"
                                    label-size="sm"
                                    class="mb-0"
                                >
                                    <b-form-select
                                        id="per-page-select"
                                        v-model="perPage"
                                        :options="pageOptions"
                                        size="sm"
                                        class="form-control form-select"
                                    ></b-form-select>
                                </b-form-group>
                            </b-col>
                            <b-col md="4" offset-md="6">
                                <label>{{ __('total_records') }} :- {{ totalRows }}</label>
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
    </div>
</template>

<script>
import axios from 'axios';

export default {
    name: 'FoodProducts',
    data() {
        return {
            fields: [
                { key: 'select',             label: '',                    visible: true,  class: 'text-center' },
                { key: 'product_variant_id', label: __('id'),              visible: true,  sortable: true, sortDirection: 'desc', class: 'text-center' },
                { key: 'product_id',         label: __('product_id'),      visible: true,  sortable: true, sortDirection: 'desc', class: 'text-center' },
                { key: 'name',               label: __('name'),            visible: true,  sortable: true, class: 'text-center' },
                { key: 'image',              label: __('image'),           visible: true,  class: 'text-center' },
                { key: 'price',              label: __('price') + '(' + this.$currency + ')', visible: true, class: 'text-center', sortable: true },
                { key: 'discounted_price',   label: 'D.Price',             visible: true,  class: 'text-center', sortable: true },
                { key: 'indicator',          label: __('indicator'),       visible: false, class: 'text-center', sortable: true },
                { key: 'is_approved',        label: __('is_approved'),     visible: false, class: 'text-center', sortable: true },
                { key: 'availability',       label: __('availability'),    visible: true,  class: 'text-center' },
                { key: 'approve_toggle',     label: __('is_approved'),     visible: true,  class: 'text-center' },
                { key: 'actions',            label: __('actions'),         visible: true },
            ],

            totalRows: 0,
            currentPage: 1,
            perPage: this.$perPage,
            pageOptions: this.$pageOptions,
            sortBy: '',
            sortDesc: false,
            sortDirection: 'asc',
            filter: null,
            filterOn: [],

            isLoading: false,
            products: [],
            categories: [],
            sellers: [],

            category: '',
            seller: '',
            is_approved: '',

            selectedItems: [],
            all_select: false,

            // Zone filter
            city_id: '',
            cities: [],
        };
    },
    computed: {
        visibleFields() {
            return this.fields.filter(f => f.visible);
        },
    },
    created() {
        this.getCities();
        this.getRecords();
    },
    watch: {
        currentPage() { this.getRecords(); },
        perPage()      { this.getRecords(); },
        category()     { this.resetSelection(); },
        seller()       { this.resetSelection(); },
        is_approved()  { this.resetSelection(); },
        filter()       { this.resetSelection(); },
    },
    methods: {
        onZoneChange() {
            this.seller = '';
            this.getRecords();
        },

        getCities() {
            axios.get(this.$apiUrl + '/cities')
                .then(res => {
                    this.cities = res.data.data || res.data;
                })
                .catch(() => {});
        },

        getRecords() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/food-products', {
                params: {
                    category:    this.category,
                    seller:      this.seller,
                    is_approved: this.is_approved,
                    page:        this.currentPage,
                    per_page:    this.perPage,
                    filter:      this.filter,
                    city_id:     this.city_id,
                },
            }).then(res => {
                this.isLoading = false;
                this.categories = res.data.data.categories;
                this.sellers    = res.data.data.sellers;
                this.products   = res.data.data.products;
                this.totalRows  = res.data.total;
            }).catch(() => {
                this.isLoading = false;
            });
        },

        deleteRecord(index, id) {
            this.$swal.fire({
                title: 'Are you Sure?',
                text: 'You want be able to revert this',
                confirmButtonText: 'Yes, Sure',
                cancelButtonText: 'Cancel',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
            }).then(result => {
                if (result.value) {
                    this.isLoading = true;
                    axios.post(this.$apiUrl + '/products/delete', { id })
                        .then(res => {
                            this.isLoading = false;
                            this.products.splice(index, 1);
                            this.showMessage('success', res.data.message);
                        });
                }
            });
        },

        updateStatusProduct(index, id) {
            this.$swal.fire({
                title: 'Are you Sure?',
                text: 'You want to change status.',
                confirmButtonText: 'Yes, Sure',
                cancelButtonText: 'Cancel',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
            }).then(result => {
                if (result.value) {
                    this.isLoading = true;
                    axios.post(this.$apiUrl + '/products/change', { id })
                        .then(res => {
                            this.isLoading = false;
                            this.getRecords();
                            this.showMessage('success', res.data.message);
                        });
                }
            });
        },

        updateApproveProduct(index, id) {
            this.$swal.fire({
                title: 'Are you Sure?',
                text: 'You want to change approval status.',
                confirmButtonText: 'Yes, Sure',
                cancelButtonText: 'Cancel',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
            }).then(result => {
                if (result.value) {
                    this.isLoading = true;
                    axios.post(this.$apiUrl + '/products/change-approve', { id })
                        .then(res => {
                            this.isLoading = false;
                            this.getRecords();
                            this.showMessage('success', res.data.message);
                        });
                }
            });
        },

        allSelectCheckBox() {
            if (this.all_select === false) {
                this.all_select = true;
                this.products.forEach(p => {
                    if (!this.selectedItems.includes(p.product_variant_id)) {
                        this.selectedItems.push(p.product_variant_id);
                    }
                });
            } else {
                this.all_select = false;
                const ids = this.products.map(p => p.product_variant_id);
                this.selectedItems = this.selectedItems.filter(id => !ids.includes(id));
            }
        },

        selectCheckBox() {
            const unique = [...new Set(this.selectedItems)];
            const ids = this.products.map(p => p.product_variant_id);
            this.all_select = ids.length > 0 && ids.every(id => unique.includes(id));
        },

        resetSelection() {
            this.selectedItems = [];
            this.all_select = false;
        },

        multipleDelete() {
            const unique = [...new Set(this.selectedItems)];
            if (unique.length === 0) {
                this.showWarning('Select at least one record!');
                return;
            }
            this.$swal.fire({
                title: 'Are you Sure?',
                text: 'You want be able to revert this',
                confirmButtonText: 'Yes, Sure',
                cancelButtonText: 'Cancel',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
            }).then(result => {
                if (result.value) {
                    this.isLoading = true;
                    axios.post(this.$apiUrl + '/products/multiple_delete', { ids: unique.toString() })
                        .then(res => {
                            this.isLoading = false;
                            this.getRecords();
                            this.selectedItems = [];
                            this.all_select = false;
                            this.showMessage('success', res.data.message);
                        });
                }
            });
        },
    },
};
</script>

<style scoped>
.city-zone-select {
    max-width: 220px;
}
</style>
