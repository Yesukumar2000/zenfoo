<template>
  <CRow>
    <CCol col="12">
      <CCard>
        <CCardHeader>
          <strong>Pending Document Verification</strong>
          <div class="card-header-actions">
            <CButton color="primary" size="sm" @click="loadData">
              <CIcon name="cil-reload" /> Refresh
            </CButton>
          </div>
        </CCardHeader>
        <CCardBody>
          <!-- Filters -->
          <CRow class="mb-3">
            <CCol sm="4">
              <CInput
                v-model="filters.search"
                placeholder="Search by name, phone..."
                @input="debounceSearch"
              >
                <template #prepend-content>
                  <CIcon name="cil-magnifying-glass" />
                </template>
              </CInput>
            </CCol>
            <CCol sm="3">
              <CSelect
                v-model="filters.city"
                :options="cityOptions"
                placeholder="Filter by city"
                @change="loadData"
              />
            </CCol>
            <CCol sm="3">
              <CSelect
                v-model="filters.documentStatus"
                :options="documentStatusOptions"
                @change="loadData"
              />
            </CCol>
          </CRow>

          <!-- Stats Cards -->
          <CRow class="mb-4">
            <CCol sm="3">
              <CWidgetSimple header="Pending Verification" :text="String(stats.pending_verification)" color="warning">
                <CIcon name="cil-clock" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple header="Under Review" :text="String(stats.under_review)" color="info">
                <CIcon name="cil-file" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple header="Verified Today" :text="String(stats.verified_today)" color="success">
                <CIcon name="cil-check-circle" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple header="Rejected Today" :text="String(stats.rejected_today)" color="danger">
                <CIcon name="cil-x-circle" height="36" />
              </CWidgetSimple>
            </CCol>
          </CRow>

          <!-- Table -->
          <CDataTable
            :items="deliveryBoys"
            :fields="fields"
            :loading="loading"
            hover
            striped
            bordered
            :items-per-page="perPage"
            :active-page="currentPage"
            @page-change="onPageChange"
          >
            <template #profile_image="{item}">
              <td>
                <CImg
                  :src="item.profile_image_url || '/img/default-avatar.png'"
                  class="c-avatar-img"
                  width="40"
                  height="40"
                  style="border-radius: 50%; object-fit: cover;"
                />
              </td>
            </template>

            <template #name="{item}">
              <td>
                <strong>{{ item.name }}</strong>
                <br>
                <small class="text-muted">{{ item.phone }}</small>
              </td>
            </template>

            <template #city="{item}">
              <td>
                {{ item.city_name || 'N/A' }}
              </td>
            </template>

            <template #document_status="{item}">
              <td>
                <CBadge :color="getDocumentStatusColor(item.document_status)">
                  {{ getDocumentStatusText(item.document_status) }}
                </CBadge>
                <div v-if="item.pending_documents_count > 0" class="mt-1">
                  <small class="text-warning">
                    {{ item.pending_documents_count }} documents pending
                  </small>
                </div>
              </td>
            </template>

            <template #status="{item}">
              <td>
                <CBadge :color="item.status == 1 ? 'success' : 'secondary'">
                  {{ item.status == 1 ? 'Active' : 'Inactive' }}
                </CBadge>
              </td>
            </template>

            <template #registered_at="{item}">
              <td>
                <small>{{ formatDate(item.created_at) }}</small>
              </td>
            </template>

            <template #actions="{item}">
              <td>
                <CButton
                  color="info"
                  size="sm"
                  @click="viewDocuments(item)"
                  class="mr-1"
                >
                  <CIcon name="cil-file" /> View Docs
                </CButton>
                <CButton
                  color="success"
                  size="sm"
                  @click="approvePartner(item)"
                  class="mr-1"
                  :disabled="item.document_status !== 'all_verified'"
                >
                  <CIcon name="cil-check" /> Approve
                </CButton>
                <CButton
                  color="danger"
                  size="sm"
                  @click="showRejectModal(item)"
                >
                  <CIcon name="cil-x" /> Reject
                </CButton>
              </td>
            </template>
          </CDataTable>

          <!-- Pagination -->
          <CPagination
            v-if="totalPages > 1"
            :active-page="currentPage"
            :pages="totalPages"
            @update:activePage="onPageChange"
          />
        </CCardBody>
      </CCard>
    </CCol>

    <!-- Reject Modal -->
    <CModal
      title="Reject Partner Registration"
      color="danger"
      :show.sync="rejectModal.show"
      size="lg"
    >
      <CRow v-if="rejectModal.partner">
        <CCol sm="12">
          <p><strong>Partner:</strong> {{ rejectModal.partner.name }} ({{ rejectModal.partner.phone }})</p>
          <CTextarea
            v-model="rejectModal.reason"
            label="Rejection Reason *"
            placeholder="Please provide detailed reason for rejection..."
            rows="4"
            :is-valid="rejectModal.reason.length >= 10"
          />
          <small class="text-muted">Minimum 10 characters required</small>
        </CCol>
      </CRow>

      <template #footer>
        <CButton
          @click="rejectModal.show = false"
          color="light"
        >
          Cancel
        </CButton>
        <CButton
          @click="confirmReject"
          color="danger"
          :disabled="rejectModal.reason.length < 10 || rejectModal.loading"
        >
          <CSpinner v-if="rejectModal.loading" size="sm" />
          {{ rejectModal.loading ? 'Rejecting...' : 'Reject Partner' }}
        </CButton>
      </template>
    </CModal>
  </CRow>
</template>

<script>
import axios from 'axios'
import moment from 'moment'

export default {
  name: 'PendingVerification',
  data() {
    return {
      loading: false,
      deliveryBoys: [],
      stats: {
        pending_verification: 0,
        under_review: 0,
        verified_today: 0,
        rejected_today: 0
      },
      filters: {
        search: '',
        city: '',
        documentStatus: 'pending'
      },
      cityOptions: [
        { value: '', label: 'All Cities' }
      ],
      documentStatusOptions: [
        { value: '', label: 'All Statuses' },
        { value: 'pending', label: 'Pending Verification' },
        { value: 'partial', label: 'Partially Verified' },
        { value: 'all_verified', label: 'All Verified' },
        { value: 'has_rejected', label: 'Has Rejected Docs' }
      ],
      fields: [
        { key: 'profile_image', label: '', _style: 'width: 60px' },
        { key: 'name', label: 'Name' },
        { key: 'city', label: 'City' },
        { key: 'document_status', label: 'Documents' },
        { key: 'status', label: 'Status' },
        { key: 'registered_at', label: 'Registered' },
        { key: 'actions', label: 'Actions', _style: 'width: 300px' }
      ],
      currentPage: 1,
      perPage: 20,
      totalPages: 1,
      searchTimeout: null,
      rejectModal: {
        show: false,
        partner: null,
        reason: '',
        loading: false
      }
    }
  },
  mounted() {
    this.loadCities()
    this.loadData()
    this.loadStats()
  },
  methods: {
    async loadData() {
      this.loading = true
      try {
        const response = await axios.get(this.$apiAdress + '/api/admin/delivery-boys/pending-verification', {
          params: {
            token: localStorage.getItem('api_token'),
            page: this.currentPage,
            per_page: this.perPage,
            search: this.filters.search,
            city_id: this.filters.city,
            document_status: this.filters.documentStatus
          }
        })

        this.deliveryBoys = response.data.data.delivery_boys
        this.totalPages = response.data.data.pagination.total_pages
      } catch (error) {
        this.$swal.fire('Error', 'Failed to load delivery partners', 'error')
      }
      this.loading = false
    },

    async loadStats() {
      try {
        const response = await axios.get(this.$apiAdress + '/api/admin/delivery-boys/verification-stats', {
          params: { token: localStorage.getItem('api_token') }
        })
        this.stats = response.data.data.stats
      } catch (error) {
        console.error('Failed to load stats:', error)
      }
    },

    async loadCities() {
      try {
        const response = await axios.get(this.$apiAdress + '/api/admin/cities', {
          params: { token: localStorage.getItem('api_token') }
        })
        const cities = response.data.data.cities.map(city => ({
          value: city.id,
          label: city.name
        }))
        this.cityOptions = [{ value: '', label: 'All Cities' }, ...cities]
      } catch (error) {
        console.error('Failed to load cities:', error)
      }
    },

    debounceSearch() {
      if (this.searchTimeout) clearTimeout(this.searchTimeout)
      this.searchTimeout = setTimeout(() => {
        this.loadData()
      }, 500)
    },

    onPageChange(page) {
      this.currentPage = page
      this.loadData()
    },

    viewDocuments(partner) {
      this.$router.push(`/delivery-boy/documents/${partner.id}`)
    },

    async approvePartner(partner) {
      const result = await this.$swal.fire({
        title: 'Approve Partner?',
        text: `Activate ${partner.name} as a delivery partner?`,
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Yes, Approve',
        confirmButtonColor: '#28a745'
      })

      if (result.isConfirmed) {
        try {
          await axios.post(this.$apiAdress + '/api/admin/delivery-boys/approve', {
            token: localStorage.getItem('api_token'),
            delivery_boy_id: partner.id
          })

          this.$swal.fire('Success', 'Partner approved successfully!', 'success')
          this.loadData()
          this.loadStats()
        } catch (error) {
          this.$swal.fire('Error', error.response?.data?.message || 'Failed to approve partner', 'error')
        }
      }
    },

    showRejectModal(partner) {
      this.rejectModal.partner = partner
      this.rejectModal.reason = ''
      this.rejectModal.show = true
    },

    async confirmReject() {
      this.rejectModal.loading = true
      try {
        await axios.post(this.$apiAdress + '/api/admin/delivery-boys/reject', {
          token: localStorage.getItem('api_token'),
          delivery_boy_id: this.rejectModal.partner.id,
          rejection_reason: this.rejectModal.reason
        })

        this.$swal.fire('Success', 'Partner registration rejected', 'success')
        this.rejectModal.show = false
        this.loadData()
        this.loadStats()
      } catch (error) {
        this.$swal.fire('Error', error.response?.data?.message || 'Failed to reject partner', 'error')
      }
      this.rejectModal.loading = false
    },

    getDocumentStatusColor(status) {
      const colors = {
        'not_uploaded': 'secondary',
        'pending_verification': 'warning',
        'all_verified': 'success',
        'has_rejected': 'danger',
        'partial': 'info'
      }
      return colors[status] || 'secondary'
    },

    getDocumentStatusText(status) {
      const texts = {
        'not_uploaded': 'Not Uploaded',
        'pending_verification': 'Pending',
        'all_verified': 'All Verified',
        'has_rejected': 'Has Rejected',
        'partial': 'Partial'
      }
      return texts[status] || status
    },

    formatDate(date) {
      return moment(date).format('DD MMM YYYY, hh:mm A')
    }
  }
}
</script>

<style scoped>
.card-header-actions {
  margin-right: 0;
}
</style>
