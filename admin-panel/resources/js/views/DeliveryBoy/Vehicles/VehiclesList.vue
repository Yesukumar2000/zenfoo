<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>Delivery Vehicles</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item">
                                <router-link to="/dashboard">{{ __('dashboard') }}</router-link>
                            </li>
                            <li class="breadcrumb-item active" aria-current="page">Vehicles</li>
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
                            <h4>All Vehicles</h4>
                            <router-link to="/delivery-boy/vehicles/create" class="btn btn-primary btn-sm">
                                <i class="fa fa-plus"></i> Add New Vehicle
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
                                    <button type="button" class="btn btn-primary" v-b-tooltip.hover :title="__('refresh')" @click="loadVehicles()">
                                        <i class="fa fa-refresh" aria-hidden="true"></i>
                                    </button>
                                </b-col>
                            </b-row>

                            <div class="table-responsive">
                                <b-table
                                    :items="filteredVehicles"
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
                                            <i class="fa fa-truck fa-4x text-muted mb-3"></i>
                                            <h5 class="text-muted">No Vehicles Found</h5>
                                            <p class="text-muted">Add your first vehicle to get started</p>
                                            <router-link to="/delivery-boy/vehicles/create" class="btn btn-primary">
                                                <i class="fa fa-plus"></i> Add Vehicle
                                            </router-link>
                                        </div>
                                    </template>

                                    <template #cell(image)="row">
                                        <div class="vehicle-image">
                                            <img
                                                v-if="row.item.image_url"
                                                :src="row.item.image_url"
                                                :alt="row.item.name"
                                                class="img-thumbnail"
                                                style="max-width: 60px; max-height: 60px; object-fit: cover;"
                                            />
                                            <span v-else>-</span>
                                        </div>
                                    </template>

                                    <template #cell(name)="row">
                                        <strong>{{ row.item.name }}</strong>
                                    </template>

                                    <template #cell(delivery_boys_count)="row">
                                        <span class="badge bg-info">{{ row.item.delivery_boys_count || 0 }} assigned</span>
                                    </template>

                                    <template #cell(actions)="row">
                                        <button
                                            class="btn btn-primary btn-sm me-1"
                                            v-b-tooltip.hover
                                            title="Edit"
                                            @click="editVehicle(row.item)"
                                        >
                                            <i class="fa fa-pencil-alt"></i>
                                        </button>
                                        <button
                                            class="btn btn-danger btn-sm"
                                            v-b-tooltip.hover
                                            title="Delete"
                                            @click="deleteVehicle(row.item)"
                                        >
                                            <i class="fa fa-trash"></i>
                                        </button>
                                    </template>

                                </b-table>
                            </div>

                            <b-row class="mt-3">
                                <b-col md="6">
                                    <label>Total Vehicles: {{ vehicles.length }}</label>
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
    name: 'VehiclesList',
    data() {
        return {
            loading: false,
            vehicles: [],
            filter: '',
            fields: [
                { key: 'id', label: 'ID', sortable: true, class: 'text-center' },
                { key: 'image', label: 'Image', class: 'text-center' },
                { key: 'name', label: 'Vehicle Name', sortable: true, class: 'text-center' },
                { key: 'delivery_boys_count', label: 'Assigned To', class: 'text-center' },
                { key: 'actions', label: 'Actions', class: 'text-center' }
            ]
        }
    },
    computed: {
        filteredVehicles() {
            if (!this.filter) {
                return this.vehicles
            }
            const searchTerm = this.filter.toLowerCase()
            return this.vehicles.filter(vehicle => {
                return vehicle.name && vehicle.name.toLowerCase().includes(searchTerm)
            })
        }
    },
    mounted() {
        this.loadVehicles()
    },
    methods: {
        async loadVehicles() {
            this.loading = true
            try {
                const params = {
                    token: localStorage.getItem('api_token')
                }

                const response = await axios.get(this.$apiUrl + '/admin/vehicles', { params })

                if (response.data.status) {
                    this.vehicles = response.data.data.vehicles
                } else {
                    this.showError(response.data.message || 'Failed to load vehicles')
                }
            } catch (error) {
                this.showError(error.response?.data?.message || 'Failed to load vehicles')
            }
            this.loading = false
        },

        editVehicle(vehicle) {
            this.$router.push(`/delivery-boy/vehicles/edit/${vehicle.id}`)
        },

        async deleteVehicle(vehicle) {
            const result = await this.$swal.fire({
                title: 'Delete Vehicle?',
                text: `Are you sure you want to delete "${vehicle.name}"?`,
                icon: 'warning',
                showCancelButton: true,
                confirmButtonText: 'Yes, Delete',
                confirmButtonColor: '#dc3545'
            })

            if (result.isConfirmed) {
                try {
                    const response = await axios.post(this.$apiUrl + '/admin/vehicles/delete', {
                        token: localStorage.getItem('api_token'),
                        vehicle_id: vehicle.id
                    })

                    if (response.data.status) {
                        this.showSuccess('Vehicle deleted successfully')
                        this.loadVehicles()
                    } else {
                        this.showError(response.data.message || 'Failed to delete vehicle')
                    }
                } catch (error) {
                    this.showError(error.response?.data?.message || 'Failed to delete vehicle')
                }
            }
        }
    }
}
</script>

<style scoped>
.vehicle-image {
    display: flex;
    justify-content: center;
    align-items: center;
}
.me-1 {
    margin-right: 0.25rem;
}
</style>
