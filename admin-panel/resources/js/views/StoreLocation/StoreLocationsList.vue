<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Store Locations</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">Store Locations</li>
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
                            <h4>All Store Locations</h4>
                            <router-link to="/store-locations/create" class="btn btn-primary btn-sm">
                                <i class="fa fa-plus"></i> Add New Location
                            </router-link>
                        </div>

                        <div class="card-body">
                            <b-row class="mb-3">
                                <b-col md="3">
                                    <h6 class="box-title">{{ __('search') }}</h6>
                                    <b-form-input
                                        id="filter-input"
                                        v-model="filter"
                                        type="search"
                                        :placeholder="__('search')"
                                    ></b-form-input>
                                </b-col>
                                <b-col md="2" class="d-flex align-items-end">
                                    <button type="button" class="btn btn-primary" v-b-tooltip.hover :title="__('refresh')" @click="loadStoreLocations()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i>
                                    </button>
                                </b-col>
                            </b-row>

                            <div class="table-responsive">
                                <b-table
                                    :items="filteredStoreLocations"
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
                                            <i class="fa fa-map-marker-alt fa-4x text-muted mb-3"></i>
                                            <h5 class="text-muted">No Store Locations Found</h5>
                                            <p class="text-muted">Add your first store location to get started</p>
                                            <router-link to="/store-locations/create" class="btn btn-primary">
                                                <i class="fa fa-plus"></i> Add Location
                                            </router-link>
                                        </div>
                                    </template>

                                    <template #cell(name)="row">
                                        <strong>{{ row.item.name }}</strong>
                                    </template>

                                    <template #cell(address)="row">
                                        <span>{{ row.item.address || '-' }}</span>
                                    </template>

                                    <template #cell(status)="row">
                                        <b-form-checkbox
                                            :checked="row.item.status == 1"
                                            switch
                                            @change="updateStatus(row.item)"
                                        >
                                            {{ row.item.status == 1 ? 'Active' : 'Inactive' }}
                                        </b-form-checkbox>
                                    </template>

                                    <template #cell(actions)="row">
                                        <div class="d-flex gap-2 justify-content-center">
                                            <button
                                                type="button"
                                                class="btn btn-primary btn-sm"
                                                v-b-tooltip.hover
                                                title="Edit"
                                                @click="editStoreLocation(row.item)"
                                            >
                                                <i class="fa fa-pencil-alt"></i>
                                            </button>
                                            <button
                                                type="button"
                                                class="btn btn-danger btn-sm"
                                                v-b-tooltip.hover
                                                title="Delete"
                                                @click.prevent="deleteStoreLocation(row.item)"
                                            >
                                                <i class="fa fa-trash"></i>
                                            </button>
                                        </div>
                                    </template>

                                </b-table>
                            </div>

                            <b-row class="mt-3">
                                <b-col md="6">
                                    <label>Total Locations: {{ storeLocations.length }}</label>
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

export default {
    name: 'StoreLocationsList',
    data() {
        return {
            loading: false,
            storeLocations: [],
            filter: '',
            fields: [
                { key: 'id', label: 'ID', sortable: true, class: 'text-center' },
                { key: 'name', label: 'Location Name', sortable: true, class: 'text-center' },
                { key: 'address', label: 'Address', class: 'text-center' },
                { key: 'status', label: 'Status', class: 'text-center' },
                { key: 'actions', label: 'Actions', class: 'text-center' }
            ]
        }
    },
    computed: {
        filteredStoreLocations() {
            if (!this.filter) {
                return this.storeLocations
            }
            return this.storeLocations.filter(location => {
                return (
                    location.name?.toLowerCase().includes(this.filter.toLowerCase()) ||
                    location.address?.toLowerCase().includes(this.filter.toLowerCase())
                )
            })
        }
    },
    mounted() {
        this.loadStoreLocations()
    },
    methods: {
        async loadStoreLocations() {
            this.loading = true
            try {
                const response = await axios.get(this.$apiUrl + '/store-locations')
                if (response.data.status == 1) {
                    this.storeLocations = response.data.data || []
                } else {
                    this.$toast.error(response.data.message || 'Failed to load store locations')
                }
            } catch (error) {
                console.error('Error loading store locations:', error)
                this.$toast.error(error.response?.data?.message || 'Failed to load store locations')
            } finally {
                this.loading = false
            }
        },
        editStoreLocation(location) {
            this.$router.push(`/store-locations/edit/${location.id}`)
        },
        async updateStatus(location) {
            try {
                const newStatus = location.status == 1 ? 0 : 1
                const response = await axios.post(this.$apiUrl + '/store-locations/update-status', {
                    id: location.id,
                    status: newStatus
                })
                if (response.data.status == 1) {
                    location.status = newStatus
                    this.$toast.success('Status updated successfully')
                } else {
                    this.$toast.error(response.data.message || 'Failed to update status')
                }
            } catch (error) {
                console.error('Error updating status:', error)
                this.$toast.error(error.response?.data?.message || 'Failed to update status')
            }
        },
        async deleteStoreLocation(location) {
            // Use native confirm for reliability
            const confirmed = confirm(`Are you sure you want to delete "${location.name}"?\n\nThis action cannot be undone.`)

            if (confirmed) {
                try {
                    const response = await axios.post(this.$apiUrl + '/store-locations/delete', {
                        id: location.id
                    })
                    if (response.data.status == 1) {
                        this.$toast.success('Store location deleted successfully')
                        this.loadStoreLocations()
                    } else {
                        this.$toast.error(response.data.message || 'Failed to delete')
                    }
                } catch (error) {
                    console.error('Error deleting store location:', error)
                    this.$toast.error(error.response?.data?.message || 'Failed to delete')
                }
            }
        }
    }
}
</script>

<style scoped>
.vehicle-image img {
    border-radius: 8px;
}

.d-flex.gap-2 > * {
    margin-right: 0.5rem;
}

.d-flex.gap-2 > *:last-child {
    margin-right: 0;
}

.btn {
    cursor: pointer;
    pointer-events: auto;
}
</style>
