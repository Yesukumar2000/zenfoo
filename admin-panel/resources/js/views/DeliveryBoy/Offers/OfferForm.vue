<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>{{ isEdit ? 'Edit' : 'Create' }} Incentive Offer</h3>
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
                            <li class="breadcrumb-item active" aria-current="page">{{ isEdit ? 'Edit' : 'Create' }}</li>
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

            <div class="row">
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h4 class="mb-0">{{ isEdit ? 'Edit' : 'Create New' }} Offer</h4>
                        </div>
                        <div class="card-body">
                            <form @submit.prevent="saveOffer">
                                <!-- Basic Information -->
                                <h5 class="mb-3">
                                    <i class="fa fa-info-circle"></i> Basic Information
                                </h5>

                                <div class="row mb-3">
                                    <div class="col-md-12">
                                        <label class="form-label">Offer Name <span class="text-danger">*</span></label>
                                        <input
                                            type="text"
                                            class="form-control"
                                            v-model="form.name"
                                            placeholder="e.g., Diwali Mega Bonus 2025"
                                            :class="{ 'is-valid': form.name.length >= 5, 'is-invalid': form.name.length > 0 && form.name.length < 5 }"
                                            required
                                        />
                                        <div class="invalid-feedback" v-if="form.name.length > 0 && form.name.length < 5">
                                            Offer name must be at least 5 characters ({{ form.name.length }}/5)
                                        </div>
                                        <small class="text-muted" v-else>Minimum 5 characters required</small>
                                    </div>
                                </div>

                                <div class="row mb-3">
                                    <div class="col-md-12">
                                        <label class="form-label">Description <span class="text-danger">*</span></label>
                                        <textarea
                                            class="form-control"
                                            v-model="form.description"
                                            placeholder="Detailed description of the offer..."
                                            rows="4"
                                            :class="{ 'is-valid': form.description.length >= 20, 'is-invalid': form.description.length > 0 && form.description.length < 20 }"
                                            required
                                        ></textarea>
                                        <div class="invalid-feedback" v-if="form.description.length > 0 && form.description.length < 20">
                                            Description must be at least 20 characters ({{ form.description.length }}/20)
                                        </div>
                                        <small class="text-muted" v-else>Minimum 20 characters required</small>
                                    </div>
                                </div>

                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <label class="form-label">Start Date & Time <span class="text-danger">*</span></label>
                                        <input
                                            type="datetime-local"
                                            v-model="form.start_date"
                                            class="form-control"
                                            required
                                        />
                                    </div>
                                    <div class="col-md-6">
                                        <label class="form-label">End Date & Time <span class="text-danger">*</span></label>
                                        <input
                                            type="datetime-local"
                                            v-model="form.end_date"
                                            class="form-control"
                                            :min="form.start_date"
                                            required
                                        />
                                    </div>
                                </div>

                                <div class="row mb-3">
                                    <div class="col-md-12">
                                        <label class="form-label">Banner Image</label>
                                        <input
                                            type="file"
                                            @change="handleBannerUpload"
                                            accept="image/*"
                                            class="form-control"
                                            ref="bannerInput"
                                        />
                                        <small class="text-muted">Recommended size: 1200x400px</small>
                                        <div v-if="form.banner_preview" class="mt-2">
                                            <img
                                                :src="form.banner_preview"
                                                width="300"
                                                style="border-radius: 8px;"
                                            />
                                            <button
                                                type="button"
                                                class="btn btn-danger btn-sm ms-2"
                                                @click="removeBanner"
                                            >
                                                <i class="fa fa-times"></i> Remove
                                            </button>
                                        </div>
                                    </div>
                                </div>

                                <hr class="my-4">

                                <!-- Eligibility Conditions -->
                                <h5 class="mb-3">
                                    <i class="fa fa-check-circle"></i> Eligibility Conditions
                                </h5>

                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <label class="form-label">Minimum Gigs Required <span class="text-danger">*</span></label>
                                        <input
                                            type="number"
                                            class="form-control"
                                            v-model.number="form.min_gigs_required"
                                            min="0"
                                            placeholder="e.g., 20"
                                            required
                                        />
                                        <small class="text-muted">Out of total gigs in offer period</small>
                                    </div>
                                    <div class="col-md-6">
                                        <label class="form-label">Maximum Gigs Can Skip</label>
                                        <input
                                            type="number"
                                            class="form-control"
                                            v-model.number="form.max_gigs_skip"
                                            min="0"
                                            placeholder="e.g., 2"
                                        />
                                        <small class="text-muted">Number of gigs partner can skip</small>
                                    </div>
                                </div>

                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <label class="form-label">Maximum Orders Can Cancel</label>
                                        <input
                                            type="number"
                                            class="form-control"
                                            v-model.number="form.max_orders_cancel"
                                            min="0"
                                            placeholder="e.g., 3"
                                        />
                                        <small class="text-muted">Maximum order cancellations allowed</small>
                                    </div>
                                    <div class="col-md-6">
                                        <label class="form-label">Login Mandatory</label>
                                        <div class="form-check form-switch mt-2">
                                            <input
                                                class="form-check-input"
                                                type="checkbox"
                                                v-model="form.login_mandatory"
                                                id="loginMandatory"
                                            />
                                            <label class="form-check-label" for="loginMandatory">
                                                {{ form.login_mandatory ? 'Required' : 'Optional' }}
                                            </label>
                                        </div>
                                        <small class="text-muted">Require daily login compliance</small>
                                    </div>
                                </div>

                                <hr class="my-4">

                                <!-- Reward Tiers -->
                                <div class="d-flex justify-content-between align-items-center mb-3">
                                    <h5 class="mb-0">
                                        <i class="fa fa-star"></i> Reward Tiers
                                    </h5>
                                    <button
                                        type="button"
                                        class="btn btn-success btn-sm"
                                        @click="addTier"
                                    >
                                        <i class="fa fa-plus"></i> Add Tier
                                    </button>
                                </div>

                                <div v-for="(tier, index) in form.tiers" :key="index" class="tier-card mb-3 p-3">
                                    <div class="row">
                                        <div class="col-md-3">
                                            <label class="form-label">Tier {{ index + 1 }} Name <span class="text-danger">*</span></label>
                                            <input
                                                type="text"
                                                class="form-control"
                                                v-model="tier.tier_name"
                                                placeholder="e.g., Bronze, Silver"
                                                required
                                            />
                                        </div>
                                        <div class="col-md-3">
                                            <label class="form-label">Earnings Target ({{ $currency }}) <span class="text-danger">*</span></label>
                                            <input
                                                type="number"
                                                class="form-control"
                                                v-model.number="tier.earnings_target"
                                                min="0"
                                                step="0.01"
                                                placeholder="e.g., 500"
                                                required
                                            />
                                        </div>
                                        <div class="col-md-4">
                                            <label class="form-label">Incentive Amount ({{ $currency }}) <span class="text-danger">*</span></label>
                                            <input
                                                type="number"
                                                class="form-control"
                                                v-model.number="tier.incentive_amount"
                                                min="0"
                                                step="0.01"
                                                placeholder="e.g., 100"
                                                required
                                            />
                                        </div>
                                        <div class="col-md-1 d-flex align-items-end pb-2">
                                            <button
                                                type="button"
                                                class="btn btn-danger btn-sm"
                                                @click="removeTier(index)"
                                                :disabled="form.tiers.length === 1"
                                            >
                                                <i class="fa fa-trash"></i>
                                            </button>
                                        </div>
                                    </div>

                                    <!-- Tier Preview -->
                                    <div class="tier-preview mt-2 p-2 rounded">
                                        <small>
                                            <strong>{{ tier.tier_name || 'Unnamed' }}:</strong>
                                            Earn {{ $currency }}{{ parseFloat(tier.earnings_target || 0).toFixed(2) }}
                                            &rarr; Get {{ $currency }}{{ parseFloat(tier.incentive_amount || 0).toFixed(2) }} bonus
                                        </small>
                                    </div>
                                </div>

                                <hr class="my-4">

                                <!-- Status -->
                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <label class="form-label">Offer Status</label>
                                        <div class="form-check form-switch mt-2">
                                            <input
                                                class="form-check-input"
                                                type="checkbox"
                                                v-model="form.status"
                                                :true-value="1"
                                                :false-value="0"
                                                id="offerStatus"
                                            />
                                            <label class="form-check-label" for="offerStatus">
                                                {{ form.status == 1 ? 'Active' : 'Inactive' }}
                                            </label>
                                        </div>
                                        <small class="text-muted">Only active offers are visible to partners</small>
                                    </div>
                                </div>

                                <!-- Actions -->
                                <div class="row mt-4">
                                    <div class="col-12 text-end">
                                        <button
                                            type="button"
                                            class="btn btn-secondary me-2"
                                            @click="$router.go(-1)"
                                        >
                                            <i class="fa fa-arrow-left"></i> Cancel
                                        </button>
                                        <button
                                            type="submit"
                                            class="btn btn-primary"
                                            :disabled="loading || !isFormValid"
                                        >
                                            <span v-if="loading">
                                                <i class="fa fa-spinner fa-spin"></i> Saving...
                                            </span>
                                            <span v-else>
                                                <i class="fa fa-save"></i> {{ isEdit ? 'Update' : 'Create' }} Offer
                                            </span>
                                        </button>
                                    </div>
                                </div>
                            </form>
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
    name: 'OfferForm',
    data() {
        return {
            loading: false,
            isEdit: false,
            form: {
                name: '',
                description: '',
                start_date: '',
                end_date: '',
                banner_image: null,
                banner_preview: null,
                min_gigs_required: 20,
                max_gigs_skip: 2,
                max_orders_cancel: 3,
                login_mandatory: true,
                status: 1,
                tiers: [
                    { tier_name: 'Bronze', earnings_target: 500, incentive_amount: 100, order_number: 1 },
                    { tier_name: 'Silver', earnings_target: 1000, incentive_amount: 250, order_number: 2 },
                    { tier_name: 'Gold', earnings_target: 2000, incentive_amount: 600, order_number: 3 }
                ]
            }
        }
    },
    computed: {
        offerId() {
            return this.$route.params.id
        },
        isFormValid() {
            return this.form.name.length >= 5 &&
                this.form.description.length >= 20 &&
                this.form.start_date &&
                this.form.end_date &&
                this.form.tiers.length > 0 &&
                this.form.tiers.every(t =>
                    t.tier_name && t.earnings_target > 0 && t.incentive_amount > 0
                )
        }
    },
    mounted() {
        if (this.offerId) {
            this.isEdit = true
            this.loadOffer()
        } else {
            // Set default dates (start: tomorrow, end: +30 days)
            this.form.start_date = moment().add(1, 'day').format('YYYY-MM-DDTHH:mm')
            this.form.end_date = moment().add(31, 'days').format('YYYY-MM-DDTHH:mm')
        }
    },
    methods: {
        async loadOffer() {
            this.loading = true
            try {
                const response = await axios.get(
                    `${this.$apiUrl}/admin/delivery-boys/offers/${this.offerId}`,
                    { params: { token: localStorage.getItem('api_token') } }
                )

                const offer = response.data.data.offer
                this.form = {
                    name: offer.name,
                    description: offer.description,
                    start_date: moment(offer.start_date).format('YYYY-MM-DDTHH:mm'),
                    end_date: moment(offer.end_date).format('YYYY-MM-DDTHH:mm'),
                    banner_image: null,
                    banner_preview: offer.banner_image_url,
                    min_gigs_required: offer.min_gigs_required,
                    max_gigs_skip: offer.max_gigs_skip,
                    max_orders_cancel: offer.max_orders_cancel,
                    login_mandatory: offer.login_mandatory,
                    status: offer.status,
                    tiers: offer.tiers || []
                }
            } catch (error) {
                this.$swal.fire('Error', 'Failed to load offer', 'error')
                this.$router.go(-1)
            }
            this.loading = false
        },

        async saveOffer() {
            this.loading = true

            const formData = new FormData()
            formData.append('token', localStorage.getItem('api_token'))
            formData.append('name', this.form.name)
            formData.append('description', this.form.description)
            formData.append('start_date', this.form.start_date)
            formData.append('end_date', this.form.end_date)
            formData.append('min_gigs_required', this.form.min_gigs_required)
            formData.append('max_gigs_skip', this.form.max_gigs_skip)
            formData.append('max_orders_cancel', this.form.max_orders_cancel)
            formData.append('login_mandatory', this.form.login_mandatory ? 1 : 0)
            formData.append('status', this.form.status)
            formData.append('tiers', JSON.stringify(this.form.tiers))

            if (this.form.banner_image) {
                formData.append('banner_image', this.form.banner_image)
            }

            try {
                let url = this.$apiUrl + '/admin/delivery-boys/offers'
                if (this.isEdit) {
                    url += `/update`
                    formData.append('offer_id', this.offerId)
                } else {
                    url += '/create'
                }

                await axios.post(url, formData, {
                    headers: { 'Content-Type': 'multipart/form-data' }
                })

                this.$swal.fire(
                    'Success',
                    `Offer ${this.isEdit ? 'updated' : 'created'} successfully!`,
                    'success'
                )
                this.$router.push('/delivery-boy/offers/list')
            } catch (error) {
                this.$swal.fire(
                    'Error',
                    error.response?.data?.message || `Failed to ${this.isEdit ? 'update' : 'create'} offer`,
                    'error'
                )
            }

            this.loading = false
        },

        handleBannerUpload(event) {
            const file = event.target.files[0]
            if (file) {
                this.form.banner_image = file
                this.form.banner_preview = URL.createObjectURL(file)
            }
        },

        removeBanner() {
            this.form.banner_image = null
            this.form.banner_preview = null
            this.$refs.bannerInput.value = ''
        },

        addTier() {
            const lastOrder = this.form.tiers.length > 0
                ? Math.max(...this.form.tiers.map(t => t.order_number))
                : 0

            this.form.tiers.push({
                tier_name: '',
                earnings_target: 0,
                incentive_amount: 0,
                order_number: lastOrder + 1
            })
        },

        removeTier(index) {
            this.form.tiers.splice(index, 1)
            // Reorder
            this.form.tiers.forEach((tier, i) => {
                tier.order_number = i + 1
            })
        }
    }
}
</script>

<style scoped>
.tier-card {
    border: 1px solid #dee2e6;
    border-radius: 8px;
    background: #f8f9fa;
}

.tier-preview {
    border: 1px dashed #6c757d;
    background: #e9ecef;
}

.form-check-input {
    cursor: pointer;
}
</style>

<style>
/* Dark mode support - unscoped for .theme-dark parent */
.theme-dark .tier-card {
    background: #2a2e33 !important;
    border-color: #3d4147 !important;
}

.theme-dark .tier-preview {
    background: #1e2125 !important;
    border-color: #3d4147 !important;
}

.theme-dark .tier-card .form-label {
    color: #adb5bd !important;
}

.theme-dark .tier-card .form-control {
    background: #1e2125 !important;
    border-color: #3d4147 !important;
    color: #fff !important;
}

.theme-dark .tier-preview small {
    color: #adb5bd !important;
}
</style>
