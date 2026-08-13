<template>
  <CRow class="mb-4">
    <CCol sm="12">
      <h5>
        <CIcon name="cil-file" /> {{ title }}
        <CBadge :color="statusColor" class="ml-2">
          {{ statusText }}
        </CBadge>
      </h5>
    </CCol>

    <CCol sm="6" v-if="document">
      <p v-if="document.number"><strong>Document Number:</strong> {{ document.number }}</p>

      <div v-if="document.status === 'rejected'" class="alert alert-danger">
        <strong>Rejection Reason:</strong> {{ document.rejection_reason || 'No reason provided' }}
      </div>

      <p v-if="document.verified_at" class="text-success">
        <CIcon name="cil-check-circle" /> Verified on {{ formatDate(document.verified_at) }}
      </p>
    </CCol>

    <CCol sm="6">
      <CRow v-if="document && (document.front_image_url || document.back_image_url || document.image_url)">
        <CCol sm="6" v-if="document.front_image_url || document.image_url">
          <div class="document-preview">
            <label class="text-muted small">{{ document.front_image_url ? 'Front Side' : 'Document' }}</label>
            <CImg
              :src="document.front_image_url || document.image_url"
              fluid
              class="document-image"
              @click="$emit('view-image', document.front_image_url || document.image_url)"
            />
          </div>
        </CCol>
        <CCol sm="6" v-if="document.back_image_url">
          <div class="document-preview">
            <label class="text-muted small">Back Side</label>
            <CImg
              :src="document.back_image_url"
              fluid
              class="document-image"
              @click="$emit('view-image', document.back_image_url)"
            />
          </div>
        </CCol>
      </CRow>

      <div v-else class="no-document">
        <CIcon name="cil-file" size="4xl" />
        <p>No document uploaded</p>
      </div>
    </CCol>

    <CCol sm="12" class="text-right mt-3" v-if="document && document.status !== 'not_uploaded'">
      <CButton
        color="success"
        size="sm"
        @click="$emit('verify')"
        :disabled="document.status === 'verified'"
        class="mr-2"
      >
        <CIcon name="cil-check" /> {{ document.status === 'verified' ? 'Verified' : 'Verify' }}
      </CButton>
      <CButton
        color="danger"
        size="sm"
        @click="$emit('reject')"
        :disabled="document.status === 'rejected'"
      >
        <CIcon name="cil-x" /> {{ document.status === 'rejected' ? 'Rejected' : 'Reject' }}
      </CButton>
    </CCol>
  </CRow>
</template>

<script>
import moment from 'moment'

export default {
  name: 'DocumentCard',
  props: {
    title: {
      type: String,
      required: true
    },
    document: {
      type: Object,
      default: null
    }
  },
  computed: {
    statusColor() {
      if (!this.document) return 'secondary'

      const colors = {
        'not_uploaded': 'secondary',
        'pending_verification': 'warning',
        'verified': 'success',
        'rejected': 'danger'
      }
      return colors[this.document.status] || 'secondary'
    },
    statusText() {
      if (!this.document) return 'Not Uploaded'

      const texts = {
        'not_uploaded': 'Not Uploaded',
        'pending_verification': 'Pending Verification',
        'verified': 'Verified',
        'rejected': 'Rejected'
      }
      return texts[this.document.status] || this.document.status
    }
  },
  methods: {
    formatDate(date) {
      return moment(date).format('DD MMM YYYY, hh:mm A')
    }
  }
}
</script>

<style scoped>
.document-preview {
  margin-bottom: 16px;
}

.document-image {
  cursor: pointer;
  border: 2px solid #dee2e6;
  border-radius: 8px;
  transition: all 0.2s;
  max-height: 200px;
  object-fit: cover;
}

.document-image:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 12px rgba(0,0,0,0.2);
}

.no-document {
  text-align: center;
  padding: 60px 20px;
  background: #f8f9fa;
  border-radius: 8px;
  color: #6c757d;
}

.no-document p {
  margin-top: 16px;
  margin-bottom: 0;
}
</style>
