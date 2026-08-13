<template>
    <div>
        <div class="page-heading">
            <div class="page-title">
                <div class="row">
                    <div class="col-12 col-md-6 order-md-1 order-last">
                        <h3>{{ __('delivery_boy_details') }}</h3>
                    </div>
                    <div class="col-12 col-md-6 order-md-2 order-first">
                        <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                            <ol class="breadcrumb">
                                <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                                <li class="breadcrumb-item"><router-link to="/delivery_boys">{{ __('delivery_boys') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">{{ __('view') }}</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/delivery_boys" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <section class="section">
                <div class="card">
                    <div class="card-header">
                        <h4 class="card-title" v-if="deliveryBoy">{{ deliveryBoy.name }}</h4>
                    </div>
                    <div class="card-body">
                        <!-- Loading State -->
                        <div class="text-center py-5" v-if="isLoading">
                            <b-spinner class="align-middle"></b-spinner>
                            <strong class="ms-2">{{ __('loading') }}...</strong>
                        </div>

                        <!-- Tabs -->
                        <div v-if="!isLoading && deliveryBoy">
                            <!-- Account Deleted Alert -->
                            <div v-if="deliveryBoy.deleted_at" class="alert alert-danger mb-4" role="alert">
                                <div class="d-flex align-items-center justify-content-between">
                                    <div>
                                        <i class="fa fa-trash-alt me-2"></i>
                                        <strong>This driver account has been deleted.</strong>
                                    </div>
                                    <button class="btn btn-success btn-sm" @click="restoreDriver" :disabled="isDeleting">
                                        <span v-if="isDeleting"><b-spinner small></b-spinner> Restoring...</span>
                                        <span v-else><i class="fa fa-undo me-1"></i> Restore Account</span>
                                    </button>
                                </div>
                                <div class="mt-2" v-if="deliveryBoy.delete_reason">
                                    <strong>Reason:</strong> {{ deliveryBoy.delete_reason }}
                                </div>
                                <div class="mt-1" v-if="deliveryBoy.delete_requested_at">
                                    <small style="color: #fff; font-weight: bold;">Deleted on {{ formatDate(deliveryBoy.delete_requested_at) }}</small>
                                </div>
                            </div>

                            <!-- Soft Delete Button (when not deleted) -->
                            <div v-else class="d-flex justify-content-end mb-3">
                                <button class="btn btn-outline-danger btn-sm" @click="softDeleteDriver" :disabled="isDeleting">
                                    <span v-if="isDeleting"><b-spinner small></b-spinner> Deleting...</span>
                                    <span v-else><i class="fa fa-trash me-1"></i> Delete Account</span>
                                </button>
                            </div>

                            <b-tabs v-model="activeTabIndex" content-class="mt-3" fill>
                                <!-- Details Tab -->
                                <b-tab title="Details">
                                    <div class="p-3">
                                        <!-- Personal Information -->
                                        <h5>Personal Information</h5>
                                        <hr>
                                        <div class="row">
                                            <div class="col-md-4 mb-3">
                                                <strong>Name:</strong><br>
                                                {{ deliveryBoy.name || '-' }}
                                            </div>
                                            <div class="col-md-4 mb-3">
                                                <strong>Mobile:</strong><br>
                                                {{ deliveryBoy.mobile || '-' }}
                                            </div>
                                            <div class="col-md-4 mb-3">
                                                <strong>Email:</strong><br>
                                                {{ deliveryBoy.email || '-' }}
                                            </div>
                                            <div class="col-md-4 mb-3">
                                                <strong>Date of Birth:</strong><br>
                                                {{ deliveryBoy.dob ? new Date(deliveryBoy.dob).toLocaleDateString('en-GB') : '-' }}
                                            </div>
                                            <div class="col-md-4 mb-3">
                                                <strong>Status:</strong><br>
                                                <span :class="getStatusBadgeClass(deliveryBoy.status)">
                                                    {{ getStatusText(deliveryBoy.status) }}
                                                </span>
                                            </div>
                                            <div class="col-md-4 mb-3">
                                                <strong>City/Zone:</strong><br>
                                                {{ deliveryBoy.city ? deliveryBoy.city.name : '-' }}
                                            </div>
                                            <div class="col-md-4 mb-3">
                                                <strong>Vehicle:</strong><br>
                                                {{ deliveryBoy.vehicle ? deliveryBoy.vehicle.name : '-' }}
                                            </div>
                                            <div class="col-md-8 mb-3">
                                                <strong>Address:</strong><br>
                                                {{ deliveryBoy.address || '-' }}
                                            </div>
                                            <div class="col-md-4 mb-3">
                                                <strong>Latitude:</strong><br>
                                                {{ deliveryBoy.latitude || '-' }}
                                            </div>
                                            <div class="col-md-4 mb-3">
                                                <strong>Longitude:</strong><br>
                                                {{ deliveryBoy.longitude || '-' }}
                                            </div>
                                            <div class="col-md-4 mb-3">
                                                <strong>Profile Image:</strong><br>
                                                <img v-if="deliveryBoy.profile_image" :src="deliveryBoy.profile_image" @click="openImageModal(deliveryBoy.profile_image)" class="img-thumbnail cursor-pointer" style="max-width: 150px;" alt="Profile">
                                                <span v-else>-</span>
                                            </div>
                                        </div>

                                        <!-- Emergency Contacts -->
                                        <h5 class="mt-4">Emergency Contacts</h5>
                                        <hr>
                                        <div class="row">
                                            <div class="col-md-12">
                                                <div v-if="deliveryBoy.emergency_contacts && deliveryBoy.emergency_contacts.length > 0" class="table-responsive">
                                                    <table class="table table-bordered table-sm mb-0">
                                                        <thead>
                                                            <tr>
                                                                <th>Name</th>
                                                                <th>Mobile Number</th>
                                                                <th>Relation</th>
                                                            </tr>
                                                        </thead>
                                                        <tbody>
                                                            <tr v-for="contact in deliveryBoy.emergency_contacts" :key="contact.id">
                                                                <td>{{ contact.name || '-' }}</td>
                                                                <td>{{ contact.mobile_number || '-' }}</td>
                                                                <td>{{ contact.relation || '-' }}</td>
                                                            </tr>
                                                        </tbody>
                                                    </table>
                                                </div>
                                                <span v-else>-</span>
                                            </div>
                                        </div>

                                        <!-- Store Locations -->
                                        <h5 class="mt-4">Store Locations</h5>
                                        <hr>
                                        <div class="row">
                                            <div class="col-md-12 mb-3">
                                                <span v-if="deliveryBoy.store_locations && deliveryBoy.store_locations.length > 0">
                                                    <span v-for="(location, index) in deliveryBoy.store_locations" :key="location.id" class="badge bg-primary me-2">
                                                        {{ location.name }}
                                                    </span>
                                                </span>
                                                <span v-else>-</span>
                                            </div>
                                        </div>

                                        <!-- Hand Cash Limit -->
                                        <h5 class="mt-4">Hand Cash Limit Settings</h5>
                                        <hr>
                                        <div class="row">
                                            <div class="col-md-6 mb-3">
                                                <div class="form-group">
                                                    <label for="handCashLimit" class="form-label"><strong>Maximum Hand Cash Limit:</strong></label>
                                                    <div class="input-group">
                                                        <input
                                                            type="number"
                                                            id="handCashLimit"
                                                            v-model="handCashLimit"
                                                            class="form-control"
                                                            placeholder="Enter maximum hand cash limit"
                                                            min="0"
                                                            step="0.01"
                                                        >
                                                        <button
                                                            @click="updateHandCashLimit"
                                                            :disabled="isSavingHandCash"
                                                            class="btn btn-primary"
                                                        >
                                                            <b-spinner small v-if="isSavingHandCash"></b-spinner>
                                                            {{ isSavingHandCash ? 'Saving...' : 'Update' }}
                                                        </button>
                                                    </div>
                                                    <small class="text-muted">
                                                        Set the maximum amount of hand cash this driver can hold. Leave empty to use the default system setting.
                                                    </small>
                                                </div>
                                            </div>
                                            <div class="col-md-6 mb-3 d-flex align-items-center">
                                                <div class="alert alert-info mb-0 w-100">
                                                    <i class="bi bi-info-circle me-2"></i>
                                                    <strong>Current Value:</strong> {{ handCashLimit ? '₹' + parseFloat(handCashLimit).toFixed(2) : 'Using System Default' }}
                                                </div>
                                            </div>
                                        </div>

                                        <!-- Bank Details -->
                                        <h5 class="mt-4">Bank Details</h5>
                                        <hr>
                                        <div class="row">
                                            <div class="col-md-3 mb-3">
                                                <strong>Bank Name:</strong><br>
                                                {{ deliveryBoy.documents ? deliveryBoy.documents.bank_name : '-' }}
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Account Holder Name:</strong><br>
                                                {{ deliveryBoy.documents ? deliveryBoy.documents.account_holder_name : '-' }}
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Account Number:</strong><br>
                                                {{ deliveryBoy.documents ? deliveryBoy.documents.account_number : '-' }}
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>IFSC Code:</strong><br>
                                                {{ deliveryBoy.documents ? deliveryBoy.documents.ifsc_code : '-' }}
                                            </div>
                                            <div class="col-md-6 mb-3">
                                                <strong>Bank Passbook Image:</strong><br>
                                                <img v-if="deliveryBoy.documents && deliveryBoy.documents.bank_passbook_image_path" :src="deliveryBoy.documents.bank_passbook_image_path" @click="openImageModal(deliveryBoy.documents.bank_passbook_image_path)" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="Bank Passbook">
                                                <span v-else>-</span>
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Bank Details Status:</strong><br>
                                                <select
                                                    v-model="documentStatuses.bank_details_status"
                                                    @change="updateDocumentStatus('bank_details_status')"
                                                    class="form-select form-select-sm"
                                                    :class="getSelectStatusClass(documentStatuses.bank_details_status)"
                                                >
                                                    <option value="not_uploaded">Not Uploaded</option>
                                                    <option value="pending_verification">Pending Verification</option>
                                                    <option value="verified">Verified</option>
                                                    <option value="rejected">Rejected</option>
                                                </select>
                                            </div>
                                        </div>

                                        <!-- UPI Payment Details -->
                                        <h5 class="mt-4">UPI Payment Details</h5>
                                        <hr>
                                        <div class="row">
                                            <div class="col-md-3 mb-3">
                                                <strong>UPI ID:</strong><br>
                                                <span v-if="deliveryBoy.upi_id" class="text-primary">{{ deliveryBoy.upi_id }}</span>
                                                <span v-else class="text-muted">-</span>
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Verification Status:</strong><br>
                                                <span v-if="deliveryBoy.is_upi_verified" class="badge bg-success">
                                                    <i class="fa fa-check-circle me-1"></i>Verified
                                                </span>
                                                <span v-else class="badge bg-warning text-dark">
                                                    <i class="fa fa-clock me-1"></i>Not Verified
                                                </span>
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Verified At:</strong><br>
                                                <span v-if="deliveryBoy.upi_verified_at">{{ formatDate(deliveryBoy.upi_verified_at) }}</span>
                                                <span v-else class="text-muted">-</span>
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Payment Mode:</strong><br>
                                                <span class="badge bg-info">{{ deliveryBoy.payment_mode || 'UPI' }}</span>
                                            </div>
                                            <div class="col-md-4 mb-3">
                                                <strong>Verification Transaction ID:</strong><br>
                                                <span v-if="deliveryBoy.upi_verification_transaction_id" class="text-monospace">
                                                    {{ deliveryBoy.upi_verification_transaction_id }}
                                                </span>
                                                <span v-else class="text-muted">-</span>
                                            </div>
                                            <div class="col-md-8 mb-3" v-if="deliveryBoy.other_payment_information">
                                                <strong>Payment Information:</strong><br>
                                                <button
                                                    class="btn btn-sm btn-outline-primary"
                                                    @click="showPaymentInfoModal = true"
                                                >
                                                    <i class="fa fa-eye me-1"></i>View Full Details
                                                </button>
                                            </div>
                                        </div>

                                        <!-- Documents Section -->
                                        <h5 class="mt-4">Documents</h5>
                                        <hr>

                                        <!-- Driving License -->
                                        <h6 class="mt-3">Driving License</h6>
                                        <div class="row">
                                            <div class="col-md-3 mb-3">
                                                <strong>License Number:</strong><br>
                                                {{ deliveryBoy.documents ? deliveryBoy.documents.driving_license_number : '-' }}
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Front Image:</strong><br>
                                                <img v-if="deliveryBoy.documents && deliveryBoy.documents.driving_license_front_path" :src="deliveryBoy.documents.driving_license_front_path" @click="openImageModal(deliveryBoy.documents.driving_license_front_path)" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="DL Front">
                                                <span v-else>-</span>
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Back Image:</strong><br>
                                                <img v-if="deliveryBoy.documents && deliveryBoy.documents.driving_license_back_path" :src="deliveryBoy.documents.driving_license_back_path" @click="openImageModal(deliveryBoy.documents.driving_license_back_path)" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="DL Back">
                                                <span v-else>-</span>
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Status:</strong><br>
                                                <select
                                                    v-model="documentStatuses.driving_license_status"
                                                    @change="updateDocumentStatus('driving_license_status')"
                                                    class="form-select form-select-sm"
                                                    :class="getSelectStatusClass(documentStatuses.driving_license_status)"
                                                >
                                                    <option value="not_uploaded">Not Uploaded</option>
                                                    <option value="pending_verification">Pending Verification</option>
                                                    <option value="verified">Verified</option>
                                                    <option value="rejected">Rejected</option>
                                                </select>
                                            </div>
                                        </div>

                                        <!-- RC -->
                                        <h6 class="mt-3">RC (Registration Certificate)</h6>
                                        <div class="row">
                                            <div class="col-md-3 mb-3">
                                                <strong>RC Number:</strong><br>
                                                {{ deliveryBoy.documents ? deliveryBoy.documents.rc_number : '-' }}
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Front Image:</strong><br>
                                                <img v-if="deliveryBoy.documents && deliveryBoy.documents.rc_front_path" :src="deliveryBoy.documents.rc_front_path" @click="openImageModal(deliveryBoy.documents.rc_front_path)" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="RC Front">
                                                <span v-else>-</span>
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Back Image:</strong><br>
                                                <img v-if="deliveryBoy.documents && deliveryBoy.documents.rc_back_path" :src="deliveryBoy.documents.rc_back_path" @click="openImageModal(deliveryBoy.documents.rc_back_path)" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="RC Back">
                                                <span v-else>-</span>
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Status:</strong><br>
                                                <select
                                                    v-model="documentStatuses.rc_status"
                                                    @change="updateDocumentStatus('rc_status')"
                                                    class="form-select form-select-sm"
                                                    :class="getSelectStatusClass(documentStatuses.rc_status)"
                                                >
                                                    <option value="not_uploaded">Not Uploaded</option>
                                                    <option value="pending_verification">Pending Verification</option>
                                                    <option value="verified">Verified</option>
                                                    <option value="rejected">Rejected</option>
                                                </select>
                                            </div>
                                        </div>

                                        <!-- Aadhar Card -->
                                        <h6 class="mt-3">Aadhar Card</h6>
                                        <div class="row">
                                            <div class="col-md-3 mb-3">
                                                <strong>Aadhar Number:</strong><br>
                                                {{ deliveryBoy.documents ? deliveryBoy.documents.aadhar_number : '-' }}
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Front Image:</strong><br>
                                                <img v-if="deliveryBoy.documents && deliveryBoy.documents.aadhar_front_path" :src="deliveryBoy.documents.aadhar_front_path" @click="openImageModal(deliveryBoy.documents.aadhar_front_path)" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="Aadhar Front">
                                                <span v-else>-</span>
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Back Image:</strong><br>
                                                <img v-if="deliveryBoy.documents && deliveryBoy.documents.aadhar_back_path" :src="deliveryBoy.documents.aadhar_back_path" @click="openImageModal(deliveryBoy.documents.aadhar_back_path)" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="Aadhar Back">
                                                <span v-else>-</span>
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Status:</strong><br>
                                                <select
                                                    v-model="documentStatuses.aadhar_status"
                                                    @change="updateDocumentStatus('aadhar_status')"
                                                    class="form-select form-select-sm"
                                                    :class="getSelectStatusClass(documentStatuses.aadhar_status)"
                                                >
                                                    <option value="not_uploaded">Not Uploaded</option>
                                                    <option value="pending_verification">Pending Verification</option>
                                                    <option value="verified">Verified</option>
                                                    <option value="rejected">Rejected</option>
                                                </select>
                                            </div>
                                        </div>

                                        <!-- PAN Card -->
                                        <h6 class="mt-3">PAN Card</h6>
                                        <div class="row">
                                            <div class="col-md-3 mb-3">
                                                <strong>PAN Number:</strong><br>
                                                {{ deliveryBoy.documents ? deliveryBoy.documents.pan_number : '-' }}
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Front Image:</strong><br>
                                                <img v-if="deliveryBoy.documents && deliveryBoy.documents.pan_front_path" :src="deliveryBoy.documents.pan_front_path" @click="openImageModal(deliveryBoy.documents.pan_front_path)" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="PAN Front">
                                                <span v-else>-</span>
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Back Image:</strong><br>
                                                <img v-if="deliveryBoy.documents && deliveryBoy.documents.pan_back_path" :src="deliveryBoy.documents.pan_back_path" @click="openImageModal(deliveryBoy.documents.pan_back_path)" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="PAN Back">
                                                <span v-else>-</span>
                                            </div>
                                            <div class="col-md-3 mb-3">
                                                <strong>Status:</strong><br>
                                                <select
                                                    v-model="documentStatuses.pan_status"
                                                    @change="updateDocumentStatus('pan_status')"
                                                    class="form-select form-select-sm"
                                                    :class="getSelectStatusClass(documentStatuses.pan_status)"
                                                >
                                                    <option value="not_uploaded">Not Uploaded</option>
                                                    <option value="pending_verification">Pending Verification</option>
                                                    <option value="verified">Verified</option>
                                                    <option value="rejected">Rejected</option>
                                                </select>
                                            </div>
                                        </div>
                                    </div>
                                </b-tab>

                                <!-- Orders Tab -->
                                <b-tab title="Orders">
                                    <DeliveryBoyOrders :delivery-boy-id="$route.params.id" />
                                </b-tab>

                                <!-- Hand Cash Tab -->
                                <b-tab title="Hand Cash">
                                    <DeliveryBoyHandCash :delivery-boy-id="$route.params.id" />
                                </b-tab>

                                <!-- Payout Tab -->
                                <b-tab title="Payout">
                                    <DeliveryBoyPayout :delivery-boy-id="$route.params.id" />
                                </b-tab>

                                <!-- Incentives Tab -->
                                <b-tab title="Incentives">
                                    <DeliveryBoyIncentives :delivery-boy-id="$route.params.id" />
                                </b-tab>

                                <!-- Surge Charges Tab -->
                                <b-tab title="Surge Charges">
                                    <DeliveryBoySurgeCharges :delivery-boy-id="$route.params.id" />
                                </b-tab>

                                <!-- Track Tab -->
                                <b-tab title="Track">
                                    <DeliveryBoyTrack :delivery-boy-id="$route.params.id" />
                                </b-tab>

                                <!-- Ratings Tab -->
                                <b-tab title="Ratings">
                                    <DriverRatings :delivery-boy-id="$route.params.id" />
                                </b-tab>

                                <!-- Analytics Tab -->
                                <!-- <b-tab title="Analytics">
                                    <DeliveryBoyAnalytics :delivery-boy-id="$route.params.id" />
                                </b-tab> -->

                                <!-- Support Tab -->
                                <b-tab title="Support">
                                    <DeliveryBoySupportTab :delivery-boy-id="$route.params.id" />
                                </b-tab>
                            </b-tabs>
                        </div>
                    </div>
                </div>
            </section>
        </div>

        <!-- Image Modal -->
        <b-modal v-model="showImageModal" size="xl" hide-footer centered>
            <template #modal-title>
                Document Image
            </template>
            <div class="text-center">
                <img :src="selectedImage" class="img-fluid" alt="Document" style="max-width: 100%; height: auto;">
            </div>
        </b-modal>

        <!-- Payment Information Modal -->
        <b-modal v-model="showPaymentInfoModal" size="lg" hide-footer centered>
            <template #modal-title>
                UPI Verification - Payment Information
            </template>
            <div v-if="deliveryBoy && deliveryBoy.other_payment_information">
                <pre class="bg-light p-3 rounded" style="max-height: 500px; overflow-y: auto;">{{ formatPaymentInfo(deliveryBoy.other_payment_information) }}</pre>
            </div>
        </b-modal>
    </div>
</template>

<script>
import DeliveryBoyOrders from './DeliveryBoyOrders.vue';
import DeliveryBoyHandCash from './DeliveryBoyHandCash.vue';
import DeliveryBoyPayout from './DeliveryBoyPayout.vue';
import DeliveryBoyIncentives from './DeliveryBoyIncentives.vue';
import DeliveryBoyTrack from './DeliveryBoyTrack.vue';
import DeliveryBoySurgeCharges from './DeliveryBoySurgeCharges.vue';
import DeliveryBoyAnalytics from './DeliveryBoyAnalyticsTab.vue';
import DeliveryBoySupportTab from './DeliveryBoySupportTab.vue';
import DriverRatings from './DriverRatings.vue';

export default {
    components: {
        DeliveryBoyOrders,
        DeliveryBoyHandCash,
        DeliveryBoyPayout,
        DeliveryBoyIncentives,
        DeliveryBoySurgeCharges,
        DeliveryBoyTrack,
        DeliveryBoySupportTab,
        DriverRatings
    },
    data() {
        return {
            deliveryBoy: null,
            isLoading: false,
            isDeleting: false,
            showImageModal: false,
            showPaymentInfoModal: false,
            selectedImage: null,
            activeTabIndex: 0,
            handCashLimit: null,
            isSavingHandCash: false,
            documentStatuses: {
                driving_license_status: 'not_uploaded',
                rc_status: 'not_uploaded',
                aadhar_status: 'not_uploaded',
                pan_status: 'not_uploaded',
                bank_details_status: 'not_uploaded'
            }
        };
    },
    created() {
        this.getDeliveryBoyDetails();

        // Check if tab query parameter is set (e.g., from notification navigation)
        if (this.$route.query.tab === 'support') {
            this.activeTabIndex = 8; // Support tab is at index 8
        }
    },
    methods: {
        getDeliveryBoyDetails() {
            const id = this.$route.params.id;
            this.isLoading = true;

            axios.get(this.$apiUrl + '/delivery_boys/' + id)
                .then((response) => {
                    this.isLoading = false;
                    if (response.data.status === 1) {
                        this.deliveryBoy = response.data.data;

                        // Initialize hand cash limit
                        this.handCashLimit = this.deliveryBoy.hand_cash_limit || null;

                        // Initialize document statuses from API response
                        if (this.deliveryBoy.documents) {
                            this.documentStatuses = {
                                driving_license_status: this.deliveryBoy.documents.driving_license_status || 'not_uploaded',
                                rc_status: this.deliveryBoy.documents.rc_status || 'not_uploaded',
                                aadhar_status: this.deliveryBoy.documents.aadhar_status || 'not_uploaded',
                                pan_status: this.deliveryBoy.documents.pan_status || 'not_uploaded',
                                bank_details_status: this.deliveryBoy.documents.bank_details_status || 'not_uploaded'
                            };
                        }
                    } else {
                        this.showError(response.data.message);
                        setTimeout(() => {
                            this.$router.push({ path: '/delivery_boys' });
                        }, 1000);
                    }
                })
                .catch(() => {
                    this.isLoading = false;
                    this.showError("Failed to load delivery boy details");
                    setTimeout(() => {
                        this.$router.push({ path: '/delivery_boys' });
                    }, 1000);
                });
        },
        openImageModal(imageUrl) {
            this.selectedImage = imageUrl;
            this.showImageModal = true;
        },
        getStatusText(status) {
            switch (status) {
                case 0: return 'Registered';
                case 1: return 'Approved';
                case 2: return 'Not Approved';
                case 3: return 'Deactivated';
                case 7: return 'Removed';
                default: return 'Unknown';
            }
        },
        getStatusBadgeClass(status) {
            switch (status) {
                case 0: return 'badge bg-primary';
                case 1: return 'badge bg-success';
                case 2: return 'badge bg-warning text-dark';
                case 3: return 'badge bg-danger';
                case 7: return 'badge bg-danger';
                default: return 'badge bg-secondary';
            }
        },
        getDocumentStatusText(status) {
            switch (status) {
                case 'verified': return 'Verified';
                case 'rejected': return 'Rejected';
                case 'pending_verification': return 'Pending Verification';
                case 'not_uploaded': return 'Not Uploaded';
                default: return 'Not Uploaded';
            }
        },
        getDocumentStatusClass(status) {
            switch (status) {
                case 'verified': return 'badge bg-success';
                case 'rejected': return 'badge bg-danger';
                case 'pending_verification': return 'badge bg-warning text-dark';
                default: return 'badge bg-secondary';
            }
        },
        getSelectStatusClass(status) {
            switch (status) {
                case 'verified': return 'bg-success text-white';
                case 'rejected': return 'bg-danger text-white';
                case 'pending_verification': return 'bg-warning text-dark';
                default: return 'bg-secondary text-white';
            }
        },
        async updateDocumentStatus(field) {
            try {
                const response = await axios.post(this.$apiUrl + '/delivery_boys/update-document-status', {
                    delivery_boy_id: this.deliveryBoy.id,
                    field: field,
                    status: this.documentStatuses[field]
                });

                if (response.data.status === 1) {
                    this.showMessage('success', 'Document status updated successfully');
                    // Update the deliveryBoy documents object
                    if (this.deliveryBoy.documents) {
                        this.deliveryBoy.documents[field] = this.documentStatuses[field];
                    }
                } else {
                    this.showError(response.data.message || 'Failed to update document status');
                    // Revert the status on error
                    if (this.deliveryBoy.documents) {
                        this.documentStatuses[field] = this.deliveryBoy.documents[field];
                    }
                }
            } catch (error) {
                this.showError('Failed to update document status');
                // Revert the status on error
                if (this.deliveryBoy.documents) {
                    this.documentStatuses[field] = this.deliveryBoy.documents[field];
                }
            }
        },
        softDeleteDriver() {
            if (!confirm('Are you sure you want to delete this driver account?')) return;

            this.isDeleting = true;
            axios.post(this.$apiUrl + '/driver-account-deletion/soft-delete', {
                delivery_boy_id: this.deliveryBoy.id
            })
            .then((response) => {
                if (response.data.status === 1) {
                    this.$toast.success(response.data.message);
                    this.getDeliveryBoyDetails();
                } else {
                    this.$toast.error(response.data.message || 'Failed to delete driver account');
                }
                this.isDeleting = false;
            })
            .catch((error) => {
                console.error('Error deleting driver:', error);
                this.$toast.error('Failed to delete driver account');
                this.isDeleting = false;
            });
        },
        restoreDriver() {
            if (!confirm('Are you sure you want to restore this driver account?')) return;

            this.isDeleting = true;
            axios.post(this.$apiUrl + '/driver-account-deletion/restore', {
                delivery_boy_id: this.deliveryBoy.id
            })
            .then((response) => {
                if (response.data.status === 1) {
                    this.$toast.success(response.data.message);
                    this.getDeliveryBoyDetails();
                } else {
                    this.$toast.error(response.data.message || 'Failed to restore driver account');
                }
                this.isDeleting = false;
            })
            .catch((error) => {
                console.error('Error restoring driver:', error);
                this.$toast.error('Failed to restore driver account');
                this.isDeleting = false;
            });
        },
        formatDate(dateStr) {
            if (!dateStr) return '';
            const date = new Date(dateStr);
            return date.toLocaleDateString('en-IN', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
        },
        formatPaymentInfo(paymentInfo) {
            try {
                // If it's already an object, stringify it
                if (typeof paymentInfo === 'object') {
                    return JSON.stringify(paymentInfo, null, 2);
                }
                // If it's a string, parse and re-stringify for formatting
                const parsed = JSON.parse(paymentInfo);
                return JSON.stringify(parsed, null, 2);
            } catch (e) {
                // If parsing fails, return as is
                return paymentInfo;
            }
        },
        async updateHandCashLimit() {
            try {
                // Validate input
                if (this.handCashLimit !== null && this.handCashLimit < 0) {
                    this.showError('Hand cash limit cannot be negative');
                    return;
                }

                this.isSavingHandCash = true;

                const response = await axios.post(this.$apiUrl + '/delivery_boys/update-hand-cash-limit', {
                    delivery_boy_id: this.deliveryBoy.id,
                    hand_cash_limit: this.handCashLimit || 0
                });

                if (response.data.status === 1) {
                    this.showMessage('success', 'Hand cash limit updated successfully');
                    // Update the deliveryBoy object
                    this.deliveryBoy.hand_cash_limit = this.handCashLimit;
                } else {
                    this.showError(response.data.message || 'Failed to update hand cash limit');
                    // Revert the value on error
                    this.handCashLimit = this.deliveryBoy.hand_cash_limit || null;
                }
            } catch (error) {
                this.showError('Failed to update hand cash limit');
                // Revert the value on error
                this.handCashLimit = this.deliveryBoy.hand_cash_limit || null;
            } finally {
                this.isSavingHandCash = false;
            }
        }
    }
};
</script>

<style scoped>
.cursor-pointer {
    cursor: pointer;
}

.text-monospace {
    font-family: 'Courier New', Courier, monospace;
    font-size: 0.9rem;
    background: #f8f9fa;
    padding: 0.25rem 0.5rem;
    border-radius: 0.25rem;
    display: inline-block;
}

/* Modern Tabs Styling */
:deep(.nav-tabs) {
    gap: 0.5rem;
    background: #f1f3f4;
    padding: 0.75rem;
    border-radius: 0.75rem;
    border: none;
    display: flex;
    flex-wrap: wrap;
    width: 100%;
    margin-bottom: 1rem;
}

:deep(.nav-tabs .nav-item) {
    margin-bottom: 0;
}

:deep(.nav-tabs .nav-link) {
    background: transparent;
    border: none;
    border-radius: 0.5rem;
    padding: 0.75rem 1.5rem;
    font-weight: 600;
    font-size: 0.95rem;
    color: #5a6169;
    transition: all 0.2s ease;
    cursor: pointer;
}

:deep(.nav-tabs .nav-link:hover) {
    background: rgba(154, 196, 68, 0.15);
    color: #7a9c36;
    border: none;
}

:deep(.nav-tabs .nav-link.active) {
    background: #9AC444;
    color: #fff;
    border: none;
    box-shadow: 0 2px 8px rgba(154, 196, 68, 0.4);
}

</style>

<!-- Dark Mode Styles (unscoped to access body.theme-dark) -->
<style>
.theme-dark .nav-tabs {
    background: #2a2e33 !important;
}

.theme-dark .nav-tabs .nav-link {
    color: #adb5bd !important;
}

.theme-dark .nav-tabs .nav-link:hover {
    background: rgba(154, 196, 68, 0.2) !important;
    color: #9AC444 !important;
}

.theme-dark .nav-tabs .nav-link.active {
    background: #9AC444 !important;
    color: #fff !important;
}

.theme-dark .text-monospace {
    background: #2a2e33;
    color: #c2c2d9;
}
</style>
