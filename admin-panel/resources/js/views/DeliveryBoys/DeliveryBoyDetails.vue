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
                                <li class="breadcrumb-item"><router-link to="/registered_delivery_boys">{{ __('delivery_boys') }}</router-link></li>
                                <li class="breadcrumb-item active" aria-current="page">{{ __('details') }}</li>
                            </ol>
                        </nav>
                    </div>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/registered_delivery_boys" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <section class="section">
                <div class="card">
                    <div class="card-body" v-if="!isLoading && deliveryBoy">
                        <!-- Personal Information -->
                        <div class="row mb-4">
                            <div class="col-12">
                                <h5 class="mb-3">Personal Information</h5>
                            </div>
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
                                <strong>City/Zone:</strong><br>
                                {{ deliveryBoy.city ? deliveryBoy.city.name : '-' }}
                            </div>
                            <div class="col-md-4 mb-3">
                                <strong>Vehicle:</strong><br>
                                {{ deliveryBoy.vehicle ? deliveryBoy.vehicle.name : '-' }}
                            </div>
                            <div class="col-md-12 mb-3">
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

                        <hr>

                        <!-- Store Locations -->
                        <div class="row mb-4">
                            <div class="col-12">
                                <h5 class="mb-3">Store Locations</h5>
                            </div>
                            <div class="col-md-12 mb-3">
                                <span v-if="deliveryBoy.store_locations && deliveryBoy.store_locations.length > 0">
                                    <span v-for="(location, index) in deliveryBoy.store_locations" :key="location.id" class="badge bg-primary me-2">
                                        {{ location.name }}
                                    </span>
                                </span>
                                <span v-else>-</span>
                            </div>
                        </div>

                        <hr>

                        <!-- Bank Details -->
                        <div class="row mb-4">
                            <div class="col-12">
                                <h5 class="mb-3">Bank Details</h5>
                            </div>
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
                            <div class="col-md-9 mb-3">
                                <strong>Bank Passbook Image:</strong><br>
                                <img v-if="deliveryBoy.documents && deliveryBoy.documents.bank_passbook_image_path" :src="deliveryBoy.documents.bank_passbook_image_path" @click="openImageModal(deliveryBoy.documents.bank_passbook_image_path)" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="Bank Passbook">
                                <span v-else>-</span>
                            </div>
                            <div class="col-md-3 mb-3">
                                <strong>Bank Details Status:</strong><br>
                                <select
                                    v-model="documentStatuses.bank_details_status"
                                    @change="updateDocumentStatus('bank_details_status')"
                                    class="form-select"
                                    :class="getStatusClass(documentStatuses.bank_details_status)"
                                >
                                    <option value="not_uploaded">Not Uploaded</option>
                                    <option value="pending_verification">Pending Verification</option>
                                    <option value="verified">Verified</option>
                                    <option value="rejected">Rejected</option>
                                </select>
                            </div>
                        </div>

                        <hr>

                        <!-- Documents -->
                        <div class="row mb-4">
                            <div class="col-12">
                                <h5 class="mb-3">Documents</h5>
                            </div>

                            <!-- Driving License -->
                            <div class="col-12 mb-3">
                                <h6>Driving License</h6>
                            </div>
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
                                <strong>DL Status:</strong><br>
                                <select
                                    v-model="documentStatuses.driving_license_status"
                                    @change="updateDocumentStatus('driving_license_status')"
                                    class="form-select"
                                    :class="getStatusClass(documentStatuses.driving_license_status)"
                                >
                                    <option value="not_uploaded">Not Uploaded</option>
                                    <option value="pending_verification">Pending Verification</option>
                                    <option value="verified">Verified</option>
                                    <option value="rejected">Rejected</option>
                                </select>
                            </div>

                            <!-- RC -->
                            <div class="col-12 mb-3 mt-3">
                                <h6>RC (Registration Certificate)</h6>
                            </div>
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
                                <strong>RC Status:</strong><br>
                                <select
                                    v-model="documentStatuses.rc_status"
                                    @change="updateDocumentStatus('rc_status')"
                                    class="form-select"
                                    :class="getStatusClass(documentStatuses.rc_status)"
                                >
                                    <option value="not_uploaded">Not Uploaded</option>
                                    <option value="pending_verification">Pending Verification</option>
                                    <option value="verified">Verified</option>
                                    <option value="rejected">Rejected</option>
                                </select>
                            </div>

                            <!-- Aadhar -->
                            <div class="col-12 mb-3 mt-3">
                                <h6>Aadhar Card</h6>
                            </div>
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
                                <strong>Aadhar Status:</strong><br>
                                <select
                                    v-model="documentStatuses.aadhar_status"
                                    @change="updateDocumentStatus('aadhar_status')"
                                    class="form-select"
                                    :class="getStatusClass(documentStatuses.aadhar_status)"
                                >
                                    <option value="not_uploaded">Not Uploaded</option>
                                    <option value="pending_verification">Pending Verification</option>
                                    <option value="verified">Verified</option>
                                    <option value="rejected">Rejected</option>
                                </select>
                            </div>

                            <!-- PAN -->
                            <div class="col-12 mb-3 mt-3">
                                <h6>PAN Card</h6>
                            </div>
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
                                <strong>PAN Status:</strong><br>
                                <select
                                    v-model="documentStatuses.pan_status"
                                    @change="updateDocumentStatus('pan_status')"
                                    class="form-select"
                                    :class="getStatusClass(documentStatuses.pan_status)"
                                >
                                    <option value="not_uploaded">Not Uploaded</option>
                                    <option value="pending_verification">Pending Verification</option>
                                    <option value="verified">Verified</option>
                                    <option value="rejected">Rejected</option>
                                </select>
                            </div>
                        </div>

                        <hr>

                        <!-- Action Buttons -->
                        <div class="row">
                            <div class="col-12 text-center">
                                <button
                                    class="btn btn-success btn-lg me-3"
                                    @click="updateStatus(1)"
                                    :disabled="isUpdating || !areAllDocumentsVerified"
                                    :title="!areAllDocumentsVerified ? 'All documents must be verified before approving' : ''"
                                >
                                    <i class="fa fa-check"></i> Approve
                                </button>
                                <button class="btn btn-danger btn-lg" @click="updateStatus(2)" :disabled="isUpdating">
                                    <i class="fa fa-times"></i> Reject
                                </button>
                            </div>
                            <div class="col-12 text-center mt-2" v-if="!areAllDocumentsVerified">
                                <small class="text-muted">
                                    <i class="fa fa-info-circle"></i> All documents must be verified before approving the delivery boy
                                </small>
                            </div>
                        </div>
                    </div>

                    <!-- Loading State -->
                    <div class="card-body text-center" v-if="isLoading">
                        <b-spinner class="align-middle"></b-spinner>
                        <strong>{{ __('loading') }}...</strong>
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
    </div>
</template>

<script>
export default {
    data() {
        return {
            deliveryBoy: null,
            isLoading: false,
            isUpdating: false,
            showImageModal: false,
            selectedImage: null,
            documentStatuses: {
                driving_license_status: 'not_uploaded',
                rc_status: 'not_uploaded',
                aadhar_status: 'not_uploaded',
                pan_status: 'not_uploaded',
                bank_details_status: 'not_uploaded'
            }
        };
    },
    computed: {
        areAllDocumentsVerified() {
            // Check if all document statuses are verified
            return (
                this.documentStatuses.driving_license_status === 'verified' &&
                this.documentStatuses.rc_status === 'verified' &&
                this.documentStatuses.aadhar_status === 'verified' &&
                this.documentStatuses.pan_status === 'verified' &&
                this.documentStatuses.bank_details_status === 'verified'
            );
        }
    },
    created() {
        this.getDeliveryBoyDetails();
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
                            this.$router.push({ path: '/registered_delivery_boys' });
                        }, 1000);
                    }
                })
                .catch(() => {
                    this.isLoading = false;
                    this.showError("Failed to load delivery boy details");
                    setTimeout(() => {
                        this.$router.push({ path: '/registered_delivery_boys' });
                    }, 1000);
                });
        },
        openImageModal(imageUrl) {
            this.selectedImage = imageUrl;
            this.showImageModal = true;
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
        getStatusClass(status) {
            switch (status) {
                case 'verified':
                    return 'bg-success text-white';
                case 'rejected':
                    return 'bg-danger text-white';
                case 'pending_verification':
                    return 'bg-warning text-dark';
                default:
                    return 'bg-secondary text-white';
            }
        },
        async updateStatus(selectedStatus) {
            let remarks = "";

            if (selectedStatus === 2) {
                const { value: text } = await this.$swal.fire({
                    title: 'Remarks',
                    input: 'textarea',
                    inputPlaceholder: 'Type your remarks here...',
                    inputAttributes: {
                        'aria-label': 'Type your remarks here'
                    },
                    confirmButtonText: "Submit",
                    cancelButtonText: "Cancel",
                    showCancelButton: true,
                    inputValidator: (value) => {
                        return new Promise((resolve) => {
                            if (value !== '') {
                                resolve();
                            } else {
                                resolve('The Remarks field is required');
                            }
                        });
                    }
                });

                if (!text) return;
                remarks = text;
            }

            this.isUpdating = true;
            let postData = {
                id: this.deliveryBoy.id,
                status: selectedStatus,
                remark: remarks
            };

            axios.post(this.$apiUrl + '/delivery_boys/update-status', postData)
                .then((response) => {
                    this.isUpdating = false;
                    let data = response.data;
                    this.showMessage('success', data.message);
                    setTimeout(() => {
                        this.$router.push({ path: '/registered_delivery_boys' });
                    }, 1500);
                })
                .catch(() => {
                    this.isUpdating = false;
                    this.showError("Failed to update status");
                });
        },
    }
};
</script>

<style scoped>
.cursor-pointer {
    cursor: pointer;
}
</style>
