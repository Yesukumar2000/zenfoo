<template>
  <CRow>
    <CCol col="12">
      <!-- Partner Info Card -->
      <CCard v-if="partner">
        <CCardBody>
          <CRow>
            <CCol sm="2" class="text-center">
              <CImg
                :src="partner.profile_image_url || '/img/default-avatar.png'"
                class="c-avatar-img"
                width="100"
                height="100"
                style="border-radius: 50%; object-fit: cover;"
              />
            </CCol>
            <CCol sm="7">
              <h4>{{ partner.name }}</h4>
              <p class="text-muted mb-1">
                <CIcon name="cil-phone" /> {{ partner.phone }} |
                <CIcon name="cil-envelope-closed" /> {{ partner.email }}
              </p>
              <p class="text-muted mb-1">
                <CIcon name="cil-location-pin" /> {{ partner.city_name || 'N/A' }} |
                <CIcon name="cil-truck" /> {{ partner.vehicle_name || 'Not selected' }}
              </p>
              <CBadge :color="partner.status == 1 ? 'success' : 'danger'" class="mr-2">
                {{ partner.status == 1 ? 'Active' : 'Inactive' }}
              </CBadge>
              <CBadge v-if="partner.rejection_remark" color="danger">
                Rejected
              </CBadge>
            </CCol>
            <CCol sm="3" class="text-right">
              <CButton color="success" @click="approveAll" :disabled="!canApprove || loading">
                <CIcon name="cil-check-circle" /> Approve All
              </CButton>
              <CButton color="danger" @click="showRejectPartnerModal" class="ml-2">
                <CIcon name="cil-x-circle" /> Reject Partner
              </CButton>
            </CCol>
          </CRow>
          <CAlert v-if="partner.rejection_remark" color="danger" class="mt-3">
            <strong>Rejection Reason:</strong> {{ partner.rejection_remark }}
          </CAlert>
        </CCardBody>
      </CCard>

      <!-- Documents Card -->
      <CCard>
        <CCardHeader>
          <strong>Document Verification</strong>
          <div class="card-header-actions">
            <CBadge color="info">{{ verifiedCount }} / {{ totalDocuments }} Verified</CBadge>
          </div>
        </CCardHeader>
        <CCardBody>
          <CRow v-if="loading" class="justify-content-center py-5">
            <CSpinner color="primary" />
          </CRow>

          <div v-else>
            <!-- Driving License -->
            <DocumentCard
              title="Driving License"
              :document="documents.driving_license"
              @verify="verifyDocument('driving_license')"
              @reject="showRejectModal('driving_license')"
            />

            <hr class="my-4">

            <!-- RC (Vehicle Registration) -->
            <DocumentCard
              title="RC (Vehicle Registration Certificate)"
              :document="documents.rc"
              @verify="verifyDocument('rc')"
              @reject="showRejectModal('rc')"
            />

            <hr class="my-4">

            <!-- Aadhar Card -->
            <DocumentCard
              title="Aadhar Card"
              :document="documents.aadhar"
              @verify="verifyDocument('aadhar')"
              @reject="showRejectModal('aadhar')"
            />

            <hr class="my-4">

            <!-- PAN Card -->
            <DocumentCard
              title="PAN Card"
              :document="documents.pan"
              @verify="verifyDocument('pan')"
              @reject="showRejectModal('pan')"
            />

            <hr class="my-4">

            <!-- Bank Details -->
            <CRow class="mb-4">
              <CCol sm="12">
                <h5>
                  <CIcon name="cil-bank" /> Bank Details
                  <CBadge :color="getStatusColor(documents.bank?.status)" class="ml-2">
                    {{ getStatusText(documents.bank?.status) }}
                  </CBadge>
                </h5>
              </CCol>
              <CCol sm="6">
                <p><strong>Account Holder:</strong> {{ documents.bank?.account_holder_name || 'N/A' }}</p>
                <p><strong>Account Number:</strong> {{ documents.bank?.account_number || 'N/A' }}</p>
                <p><strong>IFSC Code:</strong> {{ documents.bank?.ifsc_code || 'N/A' }}</p>
                <p><strong>Bank Name:</strong> {{ documents.bank?.bank_name || 'N/A' }}</p>
                <p><strong>Branch:</strong> {{ documents.bank?.branch_name || 'N/A' }}</p>
              </CCol>
              <CCol sm="6">
                <div v-if="documents.bank?.proof_image_url">
                  <CImg
                    :src="documents.bank.proof_image_url"
                    fluid
                    class="mb-2 document-image"
                    @click="openImageModal(documents.bank.proof_image_url)"
                  />
                </div>
                <div v-else class="no-document">
                  <CIcon name="cil-file" size="4xl" />
                  <p>No proof uploaded</p>
                </div>
              </CCol>
              <CCol sm="12" class="text-right mt-3" v-if="documents.bank">
                <CButton
                  color="success"
                  size="sm"
                  @click="verifyDocument('bank_details')"
                  :disabled="documents.bank.status === 'verified'"
                  class="mr-2"
                >
                  <CIcon name="cil-check" /> Verify
                </CButton>
                <CButton
                  color="danger"
                  size="sm"
                  @click="showRejectModal('bank_details')"
                  :disabled="documents.bank.status === 'rejected'"
                >
                  <CIcon name="cil-x" /> Reject
                </CButton>
              </CCol>
            </CRow>
          </div>
        </CCardBody>
      </CCard>
    </CCol>

    <!-- Image Modal -->
    <CModal
      title="Document Image"
      :show.sync="imageModal.show"
      size="xl"
      centered
    >
      <CImg :src="imageModal.url" fluid />
    </CModal>

    <!-- Reject Document Modal -->
    <CModal
      title="Reject Document"
      color="danger"
      :show.sync="rejectModal.show"
    >
      <p><strong>Document Type:</strong> {{ rejectModal.documentType }}</p>
      <CTextarea
        v-model="rejectModal.reason"
        label="Rejection Reason *"
        placeholder="Enter reason for rejection..."
        rows="4"
        :is-valid="rejectModal.reason.length >= 10"
      />
      <small class="text-muted">Minimum 10 characters required</small>

      <template #footer>
        <CButton @click="rejectModal.show = false" color="light">Cancel</CButton>
        <CButton
          @click="confirmRejectDocument"
          color="danger"
          :disabled="rejectModal.reason.length < 10 || rejectModal.loading"
        >
          <CSpinner v-if="rejectModal.loading" size="sm" />
          {{ rejectModal.loading ? 'Rejecting...' : 'Reject Document' }}
        </CButton>
      </template>
    </CModal>

    <!-- Reject Partner Modal -->
    <CModal
      title="Reject Partner Registration"
      color="danger"
      :show.sync="rejectPartnerModal.show"
    >
      <CTextarea
        v-model="rejectPartnerModal.reason"
        label="Rejection Reason *"
        placeholder="Enter detailed reason for rejecting entire registration..."
        rows="5"
        :is-valid="rejectPartnerModal.reason.length >= 20"
      />
      <small class="text-muted">Minimum 20 characters required for partner rejection</small>

      <template #footer>
        <CButton @click="rejectPartnerModal.show = false" color="light">Cancel</CButton>
        <CButton
          @click="confirmRejectPartner"
          color="danger"
          :disabled="rejectPartnerModal.reason.length < 20 || rejectPartnerModal.loading"
        >
          <CSpinner v-if="rejectPartnerModal.loading" size="sm" />
          {{ rejectPartnerModal.loading ? 'Rejecting...' : 'Reject Partner' }}
        </CButton>
      </template>
    </CModal>
  </CRow>
</template>

<script>
import axios from 'axios'
import DocumentCard from './DocumentCard.vue'

export default {
  name: 'DocumentVerification',
  components: {
    DocumentCard
  },
  data() {
    return {
      loading: false,
      partner: null,
      documents: {
        driving_license: null,
        rc: null,
        aadhar: null,
        pan: null,
        bank: null
      },
      imageModal: {
        show: false,
        url: ''
      },
      rejectModal: {
        show: false,
        documentType: '',
        documentKey: '',
        reason: '',
        loading: false
      },
      rejectPartnerModal: {
        show: false,
        reason: '',
        loading: false
      }
    }
  },
  computed: {
    deliveryBoyId() {
      return this.$route.params.id
    },
    totalDocuments() {
      return 5 // DL, RC, Aadhar, PAN, Bank
    },
    verifiedCount() {
      let count = 0
      if (this.documents.driving_license?.status === 'verified') count++
      if (this.documents.rc?.status === 'verified') count++
      if (this.documents.aadhar?.status === 'verified') count++
      if (this.documents.pan?.status === 'verified') count++
      if (this.documents.bank?.status === 'verified') count++
      return count
    },
    canApprove() {
      return this.verifiedCount === this.totalDocuments
    }
  },
  mounted() {
    this.loadData()
  },
  methods: {
    async loadData() {
      this.loading = true
      try {
        const response = await axios.get(
          `${this.$apiAdress}/api/admin/delivery-boys/${this.deliveryBoyId}/documents`,
          {
            params: { token: localStorage.getItem('api_token') }
          }
        )

        this.partner = response.data.data.partner
        this.documents = response.data.data.documents
      } catch (error) {
        this.$swal.fire('Error', 'Failed to load documents', 'error')
      }
      this.loading = false
    },

    async verifyDocument(documentKey) {
      try {
        await axios.post(`${this.$apiAdress}/api/admin/delivery-boys/documents/verify`, {
          token: localStorage.getItem('api_token'),
          delivery_boy_id: this.deliveryBoyId,
          document_type: documentKey
        })

        this.$swal.fire('Success', 'Document verified successfully!', 'success')
        this.loadData()
      } catch (error) {
        this.$swal.fire('Error', error.response?.data?.message || 'Failed to verify document', 'error')
      }
    },

    showRejectModal(documentKey) {
      const titles = {
        'driving_license': 'Driving License',
        'rc': 'RC (Vehicle Registration)',
        'aadhar': 'Aadhar Card',
        'pan': 'PAN Card',
        'bank_details': 'Bank Details'
      }

      this.rejectModal.documentType = titles[documentKey]
      this.rejectModal.documentKey = documentKey
      this.rejectModal.reason = ''
      this.rejectModal.show = true
    },

    async confirmRejectDocument() {
      this.rejectModal.loading = true
      try {
        await axios.post(`${this.$apiAdress}/api/admin/delivery-boys/documents/reject`, {
          token: localStorage.getItem('api_token'),
          delivery_boy_id: this.deliveryBoyId,
          document_type: this.rejectModal.documentKey,
          rejection_reason: this.rejectModal.reason
        })

        this.$swal.fire('Success', 'Document rejected', 'success')
        this.rejectModal.show = false
        this.loadData()
      } catch (error) {
        this.$swal.fire('Error', error.response?.data?.message || 'Failed to reject document', 'error')
      }
      this.rejectModal.loading = false
    },

    async approveAll() {
      const result = await this.$swal.fire({
        title: 'Approve All Documents?',
        text: 'This will activate the delivery partner',
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Yes, Approve All',
        confirmButtonColor: '#28a745'
      })

      if (result.isConfirmed) {
        try {
          await axios.post(`${this.$apiAdress}/api/admin/delivery-boys/approve`, {
            token: localStorage.getItem('api_token'),
            delivery_boy_id: this.deliveryBoyId
          })

          this.$swal.fire('Success', 'All documents approved! Partner is now active.', 'success')
          this.$router.push('/delivery-boy/partners/all')
        } catch (error) {
          this.$swal.fire('Error', error.response?.data?.message || 'Failed to approve', 'error')
        }
      }
    },

    showRejectPartnerModal() {
      this.rejectPartnerModal.reason = ''
      this.rejectPartnerModal.show = true
    },

    async confirmRejectPartner() {
      this.rejectPartnerModal.loading = true
      try {
        await axios.post(`${this.$apiAdress}/api/admin/delivery-boys/reject`, {
          token: localStorage.getItem('api_token'),
          delivery_boy_id: this.deliveryBoyId,
          rejection_reason: this.rejectPartnerModal.reason
        })

        this.$swal.fire('Success', 'Partner registration rejected', 'success')
        this.$router.push('/delivery-boy/registrations/rejected')
      } catch (error) {
        this.$swal.fire('Error', error.response?.data?.message || 'Failed to reject partner', 'error')
      }
      this.rejectPartnerModal.loading = false
    },

    openImageModal(url) {
      this.imageModal.url = url
      this.imageModal.show = true
    },

    getStatusColor(status) {
      const colors = {
        'not_uploaded': 'secondary',
        'pending_verification': 'warning',
        'verified': 'success',
        'rejected': 'danger'
      }
      return colors[status] || 'secondary'
    },

    getStatusText(status) {
      const texts = {
        'not_uploaded': 'Not Uploaded',
        'pending_verification': 'Pending',
        'verified': 'Verified',
        'rejected': 'Rejected'
      }
      return texts[status] || status
    }
  }
}
</script>

<style scoped>
.document-image {
  cursor: pointer;
  border: 2px solid #dee2e6;
  border-radius: 8px;
  transition: transform 0.2s;
}

.document-image:hover {
  transform: scale(1.02);
  box-shadow: 0 4px 8px rgba(0,0,0,0.2);
}

.no-document {
  text-align: center;
  padding: 40px;
  background: #f8f9fa;
  border-radius: 8px;
  color: #6c757d;
}

.card-header-actions {
  margin-right: 0;
}
</style>
