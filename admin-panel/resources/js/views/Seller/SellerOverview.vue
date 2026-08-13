<template>
    <div>
        <div v-if="isLoading" class="text-center py-5">
            <b-spinner variant="primary" label="Loading..."></b-spinner>
            <p class="mt-2">Loading seller details...</p>
        </div>
        <div v-else-if="seller">
            <!-- Account Deleted Alert -->
            <div v-if="seller.deleted_at" class="alert alert-danger mb-4" role="alert">
                <div class="d-flex align-items-center justify-content-between">
                    <div>
                        <i class="fa fa-trash-alt me-2"></i>
                        <strong>This seller account has been deleted.</strong>
                    </div>
                    <button class="btn btn-success btn-sm" @click="restoreSeller" :disabled="isDeleting">
                        <span v-if="isDeleting"><b-spinner small></b-spinner> Restoring...</span>
                        <span v-else><i class="fa fa-undo me-1"></i> Restore Account</span>
                    </button>
                </div>
                <div class="mt-2" v-if="seller.delete_reason">
                    <strong>Reason:</strong> {{ seller.delete_reason }}
                </div>
                <div class="mt-1" v-if="seller.delete_requested_at">
                    <small style="color: #fff; font-weight: bold;">Deleted on {{ formatDate(seller.delete_requested_at) }}</small>
                </div>
            </div>

            <!-- Soft Delete Button (when not deleted) -->
            <div v-else class="d-flex justify-content-end mb-3">
                <button class="btn btn-outline-danger btn-sm" @click="softDeleteSeller" :disabled="isDeleting">
                    <span v-if="isDeleting"><b-spinner small></b-spinner> Deleting...</span>
                    <span v-else><i class="fa fa-trash me-1"></i> Delete Account</span>
                </button>
            </div>

            <!-- Seller Info -->
            <div class="row">
                <!-- Basic Info Card -->
                <div class="col-md-6 mb-4">
                    <div class="card h-100">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fa fa-user me-2"></i>Basic Information</h5>
                        </div>

                        
                        <div class="card-body">
                            <div class="d-flex align-items-center mb-3">
                                <img :src="seller.logo_url || '/images/user_default_profile.png'"
                                     class="rounded-circle me-3"
                                     style="width: 80px; height: 80px; object-fit: cover;">
                                <div>
                                    <h5 class="mb-1">{{ seller.store_name || 'NA' }}</h5>
                                    <span :class="getStatusBadgeClass(seller.status)">{{ getStatusText(seller.status) }}</span>
                                </div>
                            </div>
                            <table class="table table-borderless table-sm">
                                <tr>
                                    <td class="text-muted" width="40%">Name</td>
                                    <td><strong>{{ seller.name || 'NA' }}</strong></td>
                                </tr>
                                <tr>
                                    <td class="text-muted">Email</td>
                                    <td><strong>{{ seller.email || 'NA' }}</strong></td>
                                </tr>
                                <tr>
                                    <td class="text-muted">Mobile</td>
                                    <td><strong>{{ seller.mobile || 'NA' }}</strong></td>
                                </tr>
                                <tr>
                                    <td class="text-muted">Commission</td>
                                    <td>
                                        <strong>{{ seller.commission || 0 }}%</strong>
                                        <button class="btn btn-sm btn-outline-primary ms-2" @click="openCommissionModal">
                                            <i class="fa fa-edit"></i>
                                        </button>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="text-muted">Vendor GST</td>
                                    <td>
                                        <strong>{{ seller.vendor_gst_percent || 0 }}%</strong>
                                        <button class="btn btn-sm btn-outline-primary ms-2" @click="openGstModal">
                                            <i class="fa fa-edit"></i>
                                        </button>
                                    </td>
                                </tr>
                                <!-- <tr>
                                    <td class="text-muted">Categories</td>
                                    <td><strong>{{ seller.categories_array || 'NA' }}</strong></td>
                                </tr> -->
                                <!-- <tr>
                                    <td class="text-muted">Balance</td>
                                    <td><strong>{{ $currency }}{{ seller.balance || 0 }}</strong></td>
                                </tr> -->
                            </table>
                        </div>
                    </div>
                </div>

                <!-- Address Info Card -->
                <div class="col-md-6 mb-4">
                    <div class="card h-100">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fa fa-map-marker-alt me-2"></i>Address Information</h5>
                        </div>
                        <div class="card-body">
                            <table class="table table-borderless table-sm">
                                <tr>
                                    <td class="text-muted" width="40%">Street</td>
                                    <td><strong>{{ seller.street || 'NA' }}</strong></td>
                                </tr>
                                <tr>
                                    <td class="text-muted">City</td>
                                    <td><strong>{{ seller.city ? seller.city.name : 'NA' }}</strong></td>
                                </tr>
                                <tr>
                                    <td class="text-muted">State</td>
                                    <td><strong>{{ seller.state || 'NA' }}</strong></td>
                                </tr>
                                <tr>
                                    <td class="text-muted">Address</td>
                                    <td><strong>{{ seller.formatted_address || 'NA' }}</strong></td>
                                </tr>
                                <!-- <tr>
                                    <td class="text-muted">Coordinates</td>
                                    <td><strong>{{ seller.latitude || 'NA' }}, {{ seller.longitude || 'NA' }}</strong></td>
                                </tr> -->
                            </table>
                        </div>
                    </div>
                </div>

                <!-- Bank Info Card -->
                <div class="col-md-6 mb-4">
                    <div class="card h-100">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fa fa-university me-2"></i>Bank Details</h5>
                        </div>
                        <div class="card-body">
                            <div v-if="seller.bank_accounts && seller.bank_accounts.length > 0">
                                <div
                                    v-for="(bank, index) in seller.bank_accounts"
                                    :key="bank.id"
                                    :class="['mb-3', index < seller.bank_accounts.length - 1 ? 'pb-3 border-bottom' : '']"
                                >
                                    <div class="d-flex align-items-center mb-2">
                                        <strong class="me-2">Account {{ index + 1 }}</strong>
                                        <span v-if="bank.is_default" class="badge bg-primary me-1">Default</span>
                                        <span v-if="bank.is_verified" class="badge bg-success">Verified</span>
                                    </div>
                                    <table class="table table-borderless table-sm mb-0">
                                        <tr>
                                            <td class="text-muted" width="40%">Bank Name</td>
                                            <td><strong>{{ bank.bank_name || 'NA' }}</strong></td>
                                        </tr>
                                        <tr>
                                            <td class="text-muted">Account Holder</td>
                                            <td><strong>{{ bank.account_holder_name || 'NA' }}</strong></td>
                                        </tr>
                                        <tr>
                                            <td class="text-muted">Account Number</td>
                                            <td><strong>{{ bank.account_number || 'NA' }}</strong></td>
                                        </tr>
                                        <tr>
                                            <td class="text-muted">IFSC Code</td>
                                            <td><strong>{{ bank.ifsc_code || 'NA' }}</strong></td>
                                        </tr>
                                    </table>
                                </div>
                            </div>
                            <p v-else class="text-muted mb-0">No bank accounts added yet.</p>
                        </div>
                    </div>
                </div>

                <!-- Tax Info Card -->
                <div class="col-md-6 mb-4">
                    <div class="card h-100">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fa fa-file-invoice me-2"></i>Tax & Documents</h5>
                        </div>
                        <div class="card-body">
                            <table class="table table-borderless table-sm">
                                <tr>
                                    <td class="text-muted" width="40%">GST Business Name</td>
                                    <td><strong>{{ seller.tax_name || 'NA' }}</strong></td>
                                </tr>
                                <tr>
                                    <td class="text-muted">GSTIN Number</td>
                                    <td><strong>{{ seller.tax_number || 'NA' }}</strong></td>
                                </tr>
                                <tr>
                                    <td class="text-muted">PAN Number</td>
                                    <td><strong>{{ seller.pan_number || 'NA' }}</strong></td>
                                </tr>
                                <!-- <tr>
                                    <td class="text-muted">Products Approval</td>
                                    <td>
                                        <span :class="seller.require_products_approval ? 'badge bg-success' : 'badge bg-secondary'">
                                            {{ seller.require_products_approval ? 'Required' : 'Not Required' }}
                                        </span>
                                    </td>
                                </tr> -->
                            </table>
                        </div>
                    </div>
                </div>

                <!-- Store Timings Card -->
                <div class="col-md-12 mb-4" v-if="seller.pickup_store_timings_array && seller.pickup_store_timings_array.length > 0">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fa fa-clock me-2"></i>Store Timings</h5>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-3 col-sm-6 mb-2" v-for="(timing, index) in seller.pickup_store_timings_array" :key="index">
                                    <div class="p-2 bg-light rounded">
                                        <strong>{{ timing.day }}</strong>
                                        <br>
                                        <small v-if="timing.is_open" class="text-success">{{ timing.open_time }} - {{ timing.close_time }}</small>
                                        <small v-else class="text-danger">Closed</small>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Documents Card -->
                <div class="col-md-12 mb-4">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fa fa-file me-2"></i>Documents</h5>
                        </div>
                        <div class="card-body">
                            <div class="row">

                                <!-- Aadhar Card -->
                                <div class="col-12 mb-2"><h6>Aadhar Card</h6></div>
                                <div class="col-md-3 mb-3">
                                    <strong>Aadhar Number:</strong><br>
                                    {{ seller.aadhar_number || 'NA' }}
                                </div>
                                <div class="col-md-6 mb-3">
                                    <strong>Image:</strong><br>
                                    <img v-if="seller.national_identity_card_url" :src="seller.national_identity_card_url" @click="openDocImageModal(seller.national_identity_card_url)" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="Aadhar">
                                    <span v-else class="text-muted">NA</span>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <strong>Aadhar Status:</strong><br>
                                    <select v-model="docStatuses.aadhar" @change="updateDocStatus('aadhar')" class="form-select" :class="getDocStatusClass(docStatuses.aadhar)">
                                        <option :value="0">Pending</option>
                                        <option :value="1">Approved</option>
                                        <option :value="2">Rejected</option>
                                    </select>
                                </div>

                                <div class="col-12"><hr></div>

                                <!-- PAN Card -->
                                <div class="col-12 mb-2"><h6>PAN Card</h6></div>
                                <div class="col-md-3 mb-3">
                                    <strong>PAN Number:</strong><br>
                                    {{ seller.pan_number || 'NA' }}
                                </div>
                                <div class="col-md-6 mb-3">
                                    <strong>Image:</strong><br>
                                    <img v-if="seller.pan_img_url" :src="seller.pan_img_url" @click="openDocImageModal(seller.pan_img_url)" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="PAN">
                                    <span v-else class="text-muted">NA</span>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <strong>PAN Status:</strong><br>
                                    <select v-model="docStatuses.pan" @change="updateDocStatus('pan')" class="form-select" :class="getDocStatusClass(docStatuses.pan)">
                                        <option :value="0">Pending</option>
                                        <option :value="1">Approved</option>
                                        <option :value="2">Rejected</option>
                                    </select>
                                </div>

                                <div class="col-12"><hr></div>

                                <!-- FSSAI Certificate -->
                                <div class="col-12 mb-2"><h6>FSSAI Certificate</h6></div>
                                <div class="col-md-3 mb-3">
                                    <strong>FSSAI Number:</strong><br>
                                    {{ seller.fssai_number || 'NA' }}
                                </div>
                                <div class="col-md-6 mb-3">
                                    <strong>Image:</strong><br>
                                    <img v-if="seller.fssai_img_url" :src="seller.fssai_img_url" @click="openDocImageModal(seller.fssai_img_url)" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="FSSAI">
                                    <span v-else class="text-muted">NA</span>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <strong>FSSAI Status:</strong><br>
                                    <select v-model="docStatuses.fssai" @change="updateDocStatus('fssai')" class="form-select" :class="getDocStatusClass(docStatuses.fssai)">
                                        <option :value="0">Pending</option>
                                        <option :value="1">Approved</option>
                                        <option :value="2">Rejected</option>
                                    </select>
                                </div>

                                <!-- Address Proof (view only) -->
                                <template v-if="seller.address_proof_url">
                                    <div class="col-12"><hr></div>
                                    <div class="col-12 mb-2"><h6>Address Proof</h6></div>
                                    <div class="col-md-9 mb-3">
                                        <strong>Image:</strong><br>
                                        <img :src="seller.address_proof_url" @click="openDocImageModal(seller.address_proof_url)" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="Address Proof">
                                    </div>
                                </template>

                                <div class="col-12"><hr></div>

                                <!-- Seller Agreement -->
                                <div class="col-12 mb-2"><h6>Seller Agreement</h6></div>
                                <div class="col-md-3 mb-3">
                                    <strong>Agreement Number:</strong><br>
                                    AGR-{{ String(seller.id).padStart(6, '0') }}
                                </div>
                                <div class="col-md-6 mb-3">
                                    <strong>PDF Document:</strong><br>
                                    <a v-if="seller.agreement_pdf_url" :href="seller.agreement_pdf_url" target="_blank" class="btn btn-sm btn-primary">
                                        <i class="fa fa-download me-1"></i> Download Agreement PDF
                                    </a>
                                    <span v-else class="text-muted">Not uploaded yet</span>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <strong>Agreement Status:</strong><br>
                                    <select v-model="docStatuses.agreement" @change="updateDocStatus('agreement')" class="form-select" :class="getDocStatusClass(docStatuses.agreement)" :disabled="!seller.agreement_pdf_url">
                                        <option :value="0">Pending</option>
                                        <option :value="1">Approved</option>
                                        <option :value="2">Rejected</option>
                                    </select>
                                </div>

                            </div>
                        </div>
                    </div>
                </div>

                <!-- Store Images -->
                <div class="col-md-12 mb-4" v-if="seller.store_images_urls && seller.store_images_urls.length > 0">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fa fa-images me-2"></i>Store Images</h5>
                        </div>
                        <div class="card-body">
                            <div class="d-flex flex-wrap">
                                <img
                                    v-for="(img, i) in seller.store_images_urls"
                                    :key="i"
                                    :src="img"
                                    class="rounded shadow-sm m-2 cursor-pointer"
                                    style="height: 150px; width: auto; object-fit: cover;"
                                    @click="openDocImageModal(img)"
                                />
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Document Image Modal -->
                <b-modal v-model="showDocModal" title="Document Preview" size="xl" hide-footer centered>
                    <div class="text-center">
                        <img :src="docModalImage" class="img-fluid" style="max-height: 80vh;" />
                    </div>
                </b-modal>
            </div>
        </div>
        <div v-else class="text-center py-5">
            <p class="text-muted">No seller data found.</p>
        </div>

        <!-- Commission Edit Modal -->
        <b-modal v-model="showCommissionModal" title="Update Commission" centered hide-footer>
            <div class="mb-3">
                <label class="form-label">Commission Percentage</label>
                <div class="input-group">
                    <input type="number" class="form-control" v-model="newCommission" min="0" max="100" step="0.01">
                    <span class="input-group-text">%</span>
                </div>
                <small class="text-muted">Enter a value between 0 and 100</small>
            </div>
            <div class="d-flex justify-content-end gap-2">
                <button class="btn btn-secondary" @click="showCommissionModal = false">Cancel</button>
                <button class="btn btn-primary" @click="updateCommission" :disabled="isUpdating">
                    <span v-if="isUpdating">
                        <b-spinner small></b-spinner> Updating...
                    </span>
                    <span v-else>Update</span>
                </button>
            </div>
        </b-modal>

        <!-- GST Edit Modal -->
        <b-modal v-model="showGstModal" title="Update GST" centered hide-footer>
            <div class="mb-3">
                <label class="form-label">GST Percentage</label>
                <div class="input-group">
                    <input type="number" class="form-control" v-model="newGst" min="0" max="100" step="0.01">
                    <span class="input-group-text">%</span>
                </div>
                <small class="text-muted">Enter a value between 0 and 100</small>
            </div>
            <div class="d-flex justify-content-end gap-2">
                <button class="btn btn-secondary" @click="showGstModal = false">Cancel</button>
                <button class="btn btn-primary" @click="updateGst" :disabled="isUpdatingGst">
                    <span v-if="isUpdatingGst">
                        <b-spinner small></b-spinner> Updating...
                    </span>
                    <span v-else>Update</span>
                </button>
            </div>
        </b-modal>
    </div>
</template>

<script>
export default {
    name: 'SellerOverview',
    props: {
        sellerId: {
            type: [String, Number],
            required: true
        }
    },
    data() {
        return {
            isLoading: false,
            seller: null,
            showCommissionModal: false,
            newCommission: 0,
            isUpdating: false,
            showGstModal: false,
            newGst: 0,
            isUpdatingGst: false,
            isDeleting: false,
            docStatuses: { aadhar: 0, pan: 0, fssai: 0, agreement: 0 },
            showDocModal: false,
            docModalImage: ''
        }
    },
    created() {
        this.fetchOverview();
    },
    methods: {
        fetchOverview() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/sellers/view/' + this.sellerId + '/overview')
                .then((response) => {
                    if (response.data.status === 1) {
                        this.seller = response.data.data;
                        this.docStatuses.aadhar = this.seller.aadhar_status ?? 0;
                        this.docStatuses.pan    = this.seller.pan_status    ?? 0;
                        this.docStatuses.fssai  = this.seller.fssai_status  ?? 0;
                        this.docStatuses.agreement = this.seller.agreement_status ?? 0;
                    } else {
                        this.showError(response.data.message);
                    }
                    this.isLoading = false;
                })
                .catch((error) => {
                    console.error('Error fetching seller overview:', error);
                    this.showError('Failed to fetch seller details');
                    this.isLoading = false;
                });
        },
        getStatusBadgeClass(status) {
            const statusClasses = {
                0: 'badge bg-primary',
                1: 'badge bg-success',
                2: 'badge bg-warning',
                3: 'badge bg-danger',
                7: 'badge bg-dark',
            };
            return statusClasses[status] || 'badge bg-secondary';
        },
        getStatusText(status) {
            const statusTexts = {
                0: 'Registered',
                1: 'Active',
                2: 'Rejected',
                3: 'Deactivated',
                7: 'Removed',
            };
            return statusTexts[status] || 'Unknown';
        },
        openCommissionModal() {
            this.newCommission = this.seller.commission || 0;
            this.showCommissionModal = true;
        },
        openGstModal() {
            this.newGst = this.seller.vendor_gst_percent || 0;
            this.showGstModal = true;
        },
        getDocStatusClass(status) {
            if (status === 1) return 'bg-success text-white';
            if (status === 2) return 'bg-danger text-white';
            return 'bg-warning text-dark';
        },
        openDocImageModal(imageUrl) {
            this.docModalImage = imageUrl;
            this.showDocModal = true;
        },
        updateDocStatus(documentType) {
            const status = this.docStatuses[documentType];
            const prevStatus = this.seller[documentType + '_status'] ?? 0;
            const docLabels = { pan: 'PAN Card', fssai: 'FSSAI Certificate', aadhar: 'Aadhar Card', agreement: 'Seller Agreement' };
            const docLabel = docLabels[documentType] || documentType;

            axios.post(this.$apiUrl + '/sellers/update_document_status', {
                seller_id: this.sellerId,
                document_type: documentType,
                status: status
            })
            .then((response) => {
                if (response.data.status === 1) {
                    this.seller[documentType + '_status'] = status;
                    this.$toast.success(response.data.message);

                    // When document is rejected, also reject the seller with the document name as remark
                    if (status === 2) {
                        axios.post(this.$apiUrl + '/sellers/update_status', {
                            id: this.sellerId,
                            status: 2,
                            remark: docLabel + ' rejected'
                        })
                        .then((statusRes) => {
                            if (statusRes.data.status === 1) {
                                this.seller.status = 2;
                                this.$toast.success('Seller account rejected due to ' + docLabel + ' rejection');
                            }
                        })
                        .catch((err) => {
                            console.error('Failed to update seller rejection status', err);
                        });
                    }
                } else {
                    this.docStatuses[documentType] = prevStatus;
                    this.$toast.error(response.data.message || 'Failed to update document status');
                }
            })
            .catch(() => {
                this.docStatuses[documentType] = prevStatus;
                this.$toast.error('Failed to update document status');
            });
        },
        updateCommission() {
            if (this.newCommission < 0 || this.newCommission > 100) {
                this.$toast.error('Commission must be between 0 and 100');
                return;
            }

            this.isUpdating = true;
            axios.post(this.$apiUrl + '/sellers/view/update-commission', {
                seller_id: this.sellerId,
                commission: this.newCommission
            })
            .then((response) => {
                if (response.data.status === 1) {
                    this.seller.commission = this.newCommission;
                    this.showCommissionModal = false;
                    this.$toast.success('Commission updated successfully');
                } else {
                    this.$toast.error(response.data.message || 'Failed to update commission');
                }
                this.isUpdating = false;
            })
            .catch((error) => {
                console.error('Error updating commission:', error);
                this.$toast.error('Failed to update commission');
                this.isUpdating = false;
            });
        },
        updateGst() {
            if (this.newGst < 0 || this.newGst > 100) {
                this.$toast.error('GST must be between 0 and 100');
                return;
            }

            this.isUpdatingGst = true;
            axios.post(this.$apiUrl + '/sellers/view/update-gst', {
                seller_id: this.sellerId,
                vendor_gst_percent: this.newGst
            })
            .then((response) => {
                if (response.data.status === 1) {
                    this.seller.vendor_gst_percent = this.newGst;
                    this.showGstModal = false;
                    this.$toast.success('GST updated successfully');
                } else {
                    this.$toast.error(response.data.message || 'Failed to update GST');
                }
                this.isUpdatingGst = false;
            })
            .catch((error) => {
                console.error('Error updating GST:', error);
                this.$toast.error('Failed to update GST');
                this.isUpdatingGst = false;
            });
        },
        softDeleteSeller() {
            if (!confirm('Are you sure you want to delete this seller account?')) return;

            this.isDeleting = true;
            axios.post(this.$apiUrl + '/seller-account-deletion/soft-delete', {
                seller_id: this.sellerId
            })
            .then((response) => {
                if (response.data.status === 1) {
                    this.$toast.success(response.data.message);
                    this.fetchOverview();
                } else {
                    this.$toast.error(response.data.message || 'Failed to delete seller account');
                }
                this.isDeleting = false;
            })
            .catch((error) => {
                console.error('Error deleting seller:', error);
                this.$toast.error('Failed to delete seller account');
                this.isDeleting = false;
            });
        },
        restoreSeller() {
            if (!confirm('Are you sure you want to restore this seller account?')) return;

            this.isDeleting = true;
            axios.post(this.$apiUrl + '/seller-account-deletion/restore', {
                seller_id: this.sellerId
            })
            .then((response) => {
                if (response.data.status === 1) {
                    this.$toast.success(response.data.message);
                    this.fetchOverview();
                } else {
                    this.$toast.error(response.data.message || 'Failed to restore seller account');
                }
                this.isDeleting = false;
            })
            .catch((error) => {
                console.error('Error restoring seller:', error);
                this.$toast.error('Failed to restore seller account');
                this.isDeleting = false;
            });
        },
        formatDate(dateStr) {
            if (!dateStr) return '';
            const date = new Date(dateStr);
            return date.toLocaleDateString('en-IN', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
        }
    }
}
</script>

<style scoped>
.card-header h5 {
    font-weight: 600;
}

.table-borderless td {
    padding: 8px 0;
}
</style>