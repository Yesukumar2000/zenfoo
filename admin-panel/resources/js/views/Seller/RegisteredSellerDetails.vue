<template>
    <div>
        <div class="page-heading">
            <div class="row">
                <div class="col-12 col-md-6 order-md-1 order-last">
                    <h3>{{ __('seller_details') }}</h3>
                </div>
                <div class="col-12 col-md-6 order-md-2 order-first">
                    <nav aria-label="breadcrumb" class="breadcrumb-header float-start float-lg-end">
                        <ol class="breadcrumb">
                            <li class="breadcrumb-item"><router-link to="/dashboard">{{ __('dashboard') }}</router-link></li>
                            <li class="breadcrumb-item"><router-link to="/registered_sellers">{{ __('new_registered_sellers') }}</router-link></li>
                            <li class="breadcrumb-item active" aria-current="page">{{ __('seller_details') }}</li>
                        </ol>
                    </nav>
                </div>
            </div>

            <div class="row mb-3">
                <div class="col-12">
                    <router-link to="/registered_sellers" class="btn btn-secondary btn-sm">
                        <i class="fa fa-arrow-left me-1"></i> Back to List
                    </router-link>
                </div>
            </div>

            <div class="row" v-if="isLoading">
                <div class="col-12 text-center py-5">
                    <b-spinner class="align-middle"></b-spinner>
                    <strong class="ms-2">{{ __('loading') }}...</strong>
                </div>
            </div>

            <div class="row" v-else-if="storeData">
                <!-- Header Card -->
                <div class="col-12">
                    <div class="card">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-auto">
                                    <img
                                        :src="storeData.logo_url"
                                        alt="Store Logo"
                                        class="rounded"
                                        style="height: 100px; width: 100px; object-fit: cover;"
                                        v-if="storeData.logo_url"
                                    />
                                    <div v-else class="bg-light rounded d-flex align-items-center justify-content-center" style="height: 100px; width: 100px;">
                                        <i class="fa fa-store fa-3x text-muted"></i>
                                    </div>
                                </div>
                                <div class="col">
                                    <h3 class="mb-1">{{ storeData.store_name || '-' }}</h3>
                                    <p class="text-muted mb-2" v-html="storeData.store_description || '-'"></p>
                                    <span
                                        v-if="storeData.is_approved == 1"
                                        class="badge bg-success"
                                    >Approved</span>
                                    <span
                                        v-else
                                        class="badge bg-warning"
                                    >Pending</span>
                                </div>
                                <div class="col-auto">
                                    <button class="btn btn-secondary" @click="goBack">
                                        <i class="fa fa-arrow-left me-1"></i> {{ __('back') }}
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Basic Information Card -->
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fa fa-info-circle me-2"></i>{{ __('basic_information') }}</h5>
                        </div>
                        <div class="card-body">
                            <table class="table table-borderless">
                                <tbody>
                                    <tr>
                                        <th width="40%">{{ __('name') }}</th>
                                        <td>{{ storeData.name || '-' }}</td>
                                    </tr>
                                    <tr>
                                        <th>{{ __('email') }}</th>
                                        <td>{{ storeData.email || '-' }}</td>
                                    </tr>
                                    <tr>
                                        <th>{{ __('location') }}</th>
                                        <td>{{ storeData.store_location || '-' }}</td>
                                    </tr>
                                    <tr>
                                        <th>{{ __('city') }}</th>
                                        <td>{{ storeData.store_city || '-' }}</td>
                                    </tr>
                                    <tr>
                                        <th>{{ __('store_name') }}</th>
                                        <td>{{ storeData.store ? storeData.store.name : '-' }}</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!-- Additional Details Card -->
                <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fa fa-file-text me-2"></i>{{ __('additional_details') }}</h5>
                        </div>
                        <div class="card-body">
                            <table class="table table-borderless">
                                <tbody>
                                    <tr>
                                        <th width="40%">{{ __('tax_name') }}</th>
                                        <td>{{ storeData.tax_name || '-' }}</td>
                                    </tr>
                                    <tr>
                                        <th>{{ __('tax_no') }}</th>
                                        <td>{{ storeData.tax_number || '-' }}</td>
                                    </tr>
                                    <!-- <tr>
                                        <th>{{ __('pan_no') }}</th>
                                        <td>{{ storeData.pan_number || '-' }}</td>
                                    </tr> -->
                                    <!-- <tr>
                                        <th>{{ __('lat_long') }}</th>
                                        <td>{{ storeData.lat_long || '-' }}</td>
                                    </tr> -->
                                    <tr>
                                        <th>{{ __('status') }}</th>
                                        <td>
                                            <span v-if="storeData.is_approved == 1" class="badge bg-success">Approved</span>
                                            <span v-else class="badge bg-warning">Pending</span>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!-- Documents Card -->
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fa fa-file me-2"></i>{{ __('documents') }}</h5>
                        </div>
                        <div class="card-body">
                            <div class="row">

                                <!-- Aadhar Card -->
                                <div class="col-12 mb-2"><h6>{{ __('aadhar_image') }}</h6></div>
                                <div class="col-md-3 mb-3">
                                    <strong>Aadhar Number:</strong><br>
                                    {{ storeData.aadhar_number || '-' }}
                                </div>
                                <div class="col-md-6 mb-3">
                                    <strong>Image:</strong><br>
                                    <img v-if="storeData.national_id_card" :src="storeData.national_id_card" @click="openImageModal(storeData.national_id_card, __('aadhar_image'))" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="Aadhar">
                                    <span v-else class="text-muted">-</span>
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
                                <div class="col-12 mb-2"><h6>{{ __('pan_card') }}</h6></div>
                                <div class="col-md-3 mb-3">
                                    <strong>PAN Number:</strong><br>
                                    {{ storeData.pan_number || '-' }}
                                </div>
                                <div class="col-md-6 mb-3">
                                    <strong>Image:</strong><br>
                                    <img v-if="storeData.pan_img_url" :src="storeData.pan_img_url" @click="openImageModal(storeData.pan_img_url, __('pan_card'))" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="PAN">
                                    <span v-else class="text-muted">-</span>
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
                                <div class="col-12 mb-2"><h6>{{ __('fssai_certificate') }}</h6></div>
                                <div class="col-md-3 mb-3">
                                    <strong>FSSAI Number:</strong><br>
                                    {{ storeData.fssai_number || '-' }}
                                </div>
                                <div class="col-md-6 mb-3">
                                    <strong>Image:</strong><br>
                                    <img v-if="storeData.fssai_img_url" :src="storeData.fssai_img_url" @click="openImageModal(storeData.fssai_img_url, __('fssai_certificate'))" class="img-thumbnail cursor-pointer" style="max-width: 200px;" alt="FSSAI">
                                    <span v-else class="text-muted">-</span>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <strong>FSSAI Status:</strong><br>
                                    <select v-model="docStatuses.fssai" @change="updateDocStatus('fssai')" class="form-select" :class="getDocStatusClass(docStatuses.fssai)">
                                        <option :value="0">Pending</option>
                                        <option :value="1">Approved</option>
                                        <option :value="2">Rejected</option>
                                    </select>
                                </div>

                                <div class="col-12"><hr></div>

                                <!-- Seller Agreement -->
                                <div class="col-12 mb-2"><h6>Seller Agreement</h6></div>
                                <div class="col-md-2 mb-3">
                                    <strong>Agreement Number:</strong><br>
                                    AGR-{{ String(storeData.id).padStart(6, '0') }}
                                </div>
                                <div class="col-md-3 mb-3">
                                    <strong>PDF Document:</strong><br>
                                    <a v-if="storeData.agreement_pdf_url" :href="storeData.agreement_pdf_url" target="_blank" class="btn btn-sm btn-primary">
                                        <i class="fa fa-download me-1"></i> Download Agreement PDF
                                    </a>
                                    <span v-else class="text-muted">Not uploaded yet</span>
                                </div>
                                <div class="col-md-4 mb-3">
                                    <strong>Signature:</strong><br>
                                    <img v-if="storeData.agreement_signature_url" :src="storeData.agreement_signature_url" @click="openImageModal(storeData.agreement_signature_url, 'Seller Signature')" class="img-thumbnail cursor-pointer bg-white" style="max-width: 220px; max-height: 90px; object-fit: contain;" alt="Signature">
                                    <span v-else class="text-muted">Not signed yet</span>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <strong>Agreement Status:</strong><br>
                                    <select v-model="docStatuses.agreement" @change="updateDocStatus('agreement')" class="form-select" :class="getDocStatusClass(docStatuses.agreement)" :disabled="!storeData.agreement_pdf_url">
                                        <option :value="0">Pending</option>
                                        <option :value="1">Approved</option>
                                        <option :value="2">Rejected</option>
                                    </select>
                                </div>

                            </div>
                        </div>
                    </div>
                </div>

                <!-- Address Proof -->
                <!-- <div class="col-md-6">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fa fa-home me-2"></i>{{ __('address_proof') }}</h5>
                        </div>
                        <div class="card-body text-center">
                            <img
                                v-if="storeData.address_proof"
                                :src="storeData.address_proof"
                                class="img-fluid rounded shadow-sm"
                                style="max-height: 250px;"
                            />
                            <p v-else class="text-muted mb-0">{{ __('no_image') }}</p>
                        </div>
                    </div>
                </div> -->

                <!-- Store Images -->
                <div class="col-12">
                    <div class="card">
                        <div class="card-header">
                            <h5 class="mb-0"><i class="fa fa-images me-2"></i>{{ __('store_images') }}</h5>
                        </div>
                        <div class="card-body">
                            <div class="d-flex flex-wrap" v-if="storeData.store_images && storeData.store_images.length > 0">
                                <img
                                    v-for="(img, i) in storeData.store_images"
                                    :key="i"
                                    :src="img"
                                    class="rounded shadow-sm m-2 clickable-image"
                                    style="height: 150px; width: auto; object-fit: cover;"
                                    @click="openImageModal(img, __('store_images') + ' ' + (i + 1))"
                                />
                            </div>
                            <p v-else class="text-muted mb-0">{{ __('no_images_available') }}</p>
                        </div>
                    </div>
                </div>

                <!-- Action Buttons -->
                <div class="col-12">
                    <div class="card">
                        <div class="card-body">
                            <div class="d-flex justify-content-end gap-2">
                                <button
                                    class="btn btn-success"
                                    @click="updateStatus(1)"
                                    :disabled="isUpdating"
                                >
                                    <i class="fa fa-check me-1"></i> {{ __('approve') }}
                                </button>
                                <button
                                    class="btn btn-danger"
                                    @click="updateStatus(2)"
                                    :disabled="isUpdating"
                                >
                                    <i class="fa fa-times me-1"></i> {{ __('reject') }}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="row" v-else>
                <div class="col-12">
                    <div class="alert alert-warning">
                        {{ __('no_data_found') }}
                    </div>
                </div>
            </div>
        </div>

        <!-- Image Preview Modal -->
        <b-modal
            v-model="showImageModal"
            :title="imageModalTitle"
            size="xl"
            hide-footer
            centered
        >
            <div class="text-center">
                <img
                    :src="selectedImage"
                    class="img-fluid"
                    style="max-height: 80vh;"
                />
            </div>
        </b-modal>
    </div>
</template>

<script>
export default {
    name: 'RegisteredSellerDetails',
    data() {
        return {
            sellerId: null,
            storeData: null,
            isLoading: false,
            isUpdating: false,
            docStatuses: { aadhar: 0, pan: 0, fssai: 0, agreement: 0 },
            showImageModal: false,
            selectedImage: null,
            imageModalTitle: ''
        }
    },
    created() {
        this.sellerId = this.$route.params.id;
        this.getSellerDetails();
    },
    methods: {
        getSellerDetails() {
            this.isLoading = true;
            axios.get(this.$apiUrl + '/get-store-data-for-admin/' + this.sellerId)
                .then(res => {
                    this.isLoading = false;
                    if (res.data.status === 1) {
                        this.storeData = res.data.data.seller;
                        this.docStatuses.aadhar = this.storeData.aadhar_status ?? 0;
                        this.docStatuses.pan    = this.storeData.pan_status    ?? 0;
                        this.docStatuses.fssai  = this.storeData.fssai_status  ?? 0;
                        this.docStatuses.agreement = this.storeData.agreement_status ?? 0;
                    } else {
                        this.$swal.fire("Error", res.data.message, "error");
                    }
                })
                .catch(err => {
                    this.isLoading = false;
                    this.$swal.fire("Error", err.message, "error");
                });
        },
        goBack() {
            this.$router.push('/registered_sellers');
        },
        getDocStatusClass(status) {
            if (status === 1) return 'bg-success text-white';
            if (status === 2) return 'bg-danger text-white';
            return 'bg-warning text-dark';
        },
        updateDocStatus(documentType) {
            const status = this.docStatuses[documentType];
            const prevStatus = this.storeData[documentType + '_status'] ?? 0;
            const docLabels = { pan: 'PAN Card', fssai: 'FSSAI Certificate', aadhar: 'Aadhar Card', agreement: 'Seller Agreement' };
            const docLabel = docLabels[documentType] || documentType;

            axios.post(this.$apiUrl + '/sellers/update_document_status', {
                seller_id: this.sellerId,
                document_type: documentType,
                status: status
            })
            .then((response) => {
                if (response.data.status === 1) {
                    this.storeData[documentType + '_status'] = status;
                    this.showMessage('success', response.data.message);

                    // When document is rejected, also reject the seller with the document name as remark
                    if (status === 2) {
                        axios.post(this.$apiUrl + '/sellers/update_status', {
                            id: this.sellerId,
                            status: 2,
                            remark: docLabel + ' rejected'
                        })
                        .then((statusRes) => {
                            if (statusRes.data.status === 1) {
                                this.showMessage('success', 'Seller account rejected due to ' + docLabel + ' rejection');
                                this.$router.push('/registered_sellers');
                            }
                        })
                        .catch((err) => {
                            console.error('Failed to update seller rejection status', err);
                        });
                    }
                } else {
                    this.docStatuses[documentType] = prevStatus;
                    this.showMessage('error', response.data.message || 'Failed to update document status');
                }
            })
            .catch(() => {
                this.docStatuses[documentType] = prevStatus;
                this.showMessage('error', 'Failed to update document status');
            });
        },
        openImageModal(imageUrl, title) {
            this.selectedImage = imageUrl;
            this.imageModalTitle = title;
            this.showImageModal = true;
        },
        updateStatus(selectedStatus) {
            this.$swal.fire({
                title: "Are you Sure?",
                text: "You won't be able to revert this",
                confirmButtonText: "Yes, Sure",
                cancelButtonText: "Cancel",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#9AC444',
                cancelButtonColor: '#d33',
            }).then(async result => {
                if (result.value) {
                    let remarks = "";
                    if (selectedStatus === 2) {
                        const {value: text} = await this.$swal.fire({
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
                                        resolve()
                                    } else {
                                        resolve('The Remarks field is required')
                                    }
                                })
                            }
                        })
                        if (text) {
                            remarks = text;
                        }
                    }
                    if (selectedStatus === 1 || (selectedStatus === 2 && remarks !== "")) {
                        this.isUpdating = true;
                        let postData = {
                            id: this.sellerId,
                            status: selectedStatus,
                            remark: remarks
                        }
                        axios.post(this.$apiUrl + '/sellers/update_status', postData)
                            .then((response) => {
                                this.isUpdating = false;
                                let data = response.data;

                                // Check if operation was successful
                                if (data.status === 1) {
                                    this.showMessage('success', data.message);
                                    this.$router.push('/registered_sellers');
                                } else {
                                    // Show error message and stay on the same page
                                    this.$swal.fire("Error", data.message, "error");
                                }
                            })
                            .catch(err => {
                                this.isUpdating = false;
                                this.$swal.fire("Error", err.response?.data?.message || err.message, "error");
                            });
                    }
                }
            });
        }
    }
}
</script>

<style scoped>
.card {
    margin-bottom: 1.5rem;
    box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
}

.card-header h5 {
    font-weight: 600;
}

.table-borderless th {
    font-weight: 500;
}

.gap-2 {
    gap: 0.5rem;
}

.clickable-image {
    cursor: pointer;
    transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.clickable-image:hover {
    transform: scale(1.02);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}
</style>
