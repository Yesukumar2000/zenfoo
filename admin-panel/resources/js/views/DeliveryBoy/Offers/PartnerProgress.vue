<template>
  <CRow>
    <CCol col="12">
      <CCard>
        <CCardHeader>
          <strong>Partner Incentive Progress</strong>
          <div class="card-header-actions">
            <CButton color="secondary" size="sm" @click="exportProgress">
              <CIcon name="cil-cloud-download" /> Export Report
            </CButton>
          </div>
        </CCardHeader>
        <CCardBody>
          <!-- Filters -->
          <CRow class="mb-3">
            <CCol md="4">
              <CInput
                label="Search Partner"
                v-model="filters.search"
                placeholder="Name, phone..."
                @input="debounceSearch"
              >
                <template #prepend-content>
                  <CIcon name="cil-magnifying-glass" />
                </template>
              </CInput>
            </CCol>
            <CCol md="4">
              <CSelect
                label="Select Offer"
                v-model="filters.offerId"
                :options="offerOptions"
                @change="loadProgress"
              />
            </CCol>
            <CCol md="4">
              <CSelect
                label="Status"
                v-model="filters.status"
                :options="statusOptions"
                @change="loadProgress"
              />
            </CCol>
          </CRow>

          <!-- Stats Cards -->
          <CRow class="mb-3">
            <CCol sm="3">
              <CWidgetSimple
                header="Total Participants"
                :text="String(stats.total_participants)"
                color="primary"
              >
                <CIcon name="cil-people" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple
                header="Eligible for Payout"
                :text="String(stats.eligible_count)"
                color="success"
              >
                <CIcon name="cil-check-circle" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple
                header="In Progress"
                :text="String(stats.in_progress_count)"
                color="warning"
              >
                <CIcon name="cil-clock" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple
                header="Total Potential Payout"
                :text="'₹' + stats.total_potential_payout"
                color="info"
              >
                <CIcon name="cil-dollar" height="36" />
              </CWidgetSimple>
            </CCol>
          </CRow>

          <!-- Progress Table -->
          <CDataTable
            :items="progressList"
            :fields="fields"
            :loading="loading"
            hover
            striped
            bordered
            responsive
          >
            <template #partner="{ item }">
              <td>
                <div class="d-flex align-items-center">
                  <CImg
                    :src="item.delivery_boy.profile_image_url || '/img/default-avatar.png'"
                    class="c-avatar-img mr-2"
                    width="40"
                    height="40"
                    style="border-radius: 50%; object-fit: cover;"
                  />
                  <div>
                    <strong>{{ item.delivery_boy.name }}</strong>
                    <br>
                    <small class="text-muted">{{ item.delivery_boy.phone }}</small>
                  </div>
                </div>
              </td>
            </template>

            <template #offer="{ item }">
              <td>
                <strong>{{ item.incentive_offer.name }}</strong>
                <br>
                <small class="text-muted">
                  {{ formatDate(item.incentive_offer.start_date) }} -
                  {{ formatDate(item.incentive_offer.end_date) }}
                </small>
              </td>
            </template>

            <template #progress="{ item }">
              <td>
                <div class="mb-2">
                  <strong>Earnings:</strong> ₹{{ parseFloat(item.current_earnings || 0).toFixed(2) }}
                </div>
                <div class="mb-2">
                  <strong>Gigs:</strong> {{ item.gigs_completed || 0 }}
                  <span class="text-muted">/ {{ item.incentive_offer.min_gigs_required }}</span>
                </div>
                <CProgress
                  :value="calculateProgress(item)"
                  color="success"
                  :precision="1"
                  showPercentage
                  class="mb-1"
                />
              </td>
            </template>

            <template #current_tier="{ item }">
              <td>
                <div v-if="item.current_tier">
                  <CBadge color="info">{{ item.current_tier.tier_name }}</CBadge>
                  <br>
                  <small class="text-muted">₹{{ parseFloat(item.current_tier.reward_amount).toFixed(2) }}</small>
                </div>
                <span v-else class="text-muted">No tier achieved</span>
              </td>
            </template>

            <template #next_tier="{ item }">
              <td>
                <div v-if="item.next_tier">
                  <CBadge color="warning">{{ item.next_tier.tier_name }}</CBadge>
                  <br>
                  <small class="text-muted">
                    Need ₹{{ (parseFloat(item.next_tier.earnings_target) - parseFloat(item.current_earnings || 0)).toFixed(2) }} more
                  </small>
                </div>
                <span v-else class="text-success">Max tier achieved</span>
              </td>
            </template>

            <template #compliance="{ item }">
              <td>
                <div class="mb-1">
                  <small>Gigs Skipped:</small>
                  <CBadge :color="(item.gigs_skipped || 0) <= item.incentive_offer.max_gigs_skip ? 'success' : 'danger'" class="ml-1">
                    {{ item.gigs_skipped || 0 }} / {{ item.incentive_offer.max_gigs_skip }}
                  </CBadge>
                </div>
                <div class="mb-1">
                  <small>Orders Cancelled:</small>
                  <CBadge :color="(item.orders_cancelled || 0) <= item.incentive_offer.max_orders_cancel ? 'success' : 'danger'" class="ml-1">
                    {{ item.orders_cancelled || 0 }} / {{ item.incentive_offer.max_orders_cancel }}
                  </CBadge>
                </div>
                <div v-if="item.incentive_offer.login_mandatory">
                  <small>Login:</small>
                  <CBadge :color="item.login_compliance ? 'success' : 'danger'" class="ml-1">
                    {{ item.login_compliance ? 'Compliant' : 'Non-compliant' }}
                  </CBadge>
                </div>
              </td>
            </template>

            <template #eligible="{ item }">
              <td class="text-center">
                <CBadge :color="item.is_eligible ? 'success' : 'danger'">
                  {{ item.is_eligible ? 'Yes' : 'No' }}
                </CBadge>
              </td>
            </template>

            <template #actions="{ item }">
              <td>
                <CButton
                  color="info"
                  size="sm"
                  @click="viewDetails(item)"
                >
                  <CIcon name="cil-info" /> Details
                </CButton>
              </td>
            </template>
          </CDataTable>

          <!-- Empty State -->
          <CRow v-if="!loading && progressList.length === 0" class="justify-content-center py-5">
            <CCol sm="6" class="text-center">
              <CIcon name="cil-chart-pie" size="5xl" class="text-muted mb-3" />
              <h5 class="text-muted">No Progress Data Found</h5>
              <p class="text-muted">No partners are participating in incentive offers yet</p>
            </CCol>
          </CRow>
        </CCardBody>
      </CCard>
    </CCol>

    <!-- Details Modal -->
    <CModal
      :title="'Progress Details - ' + (selectedProgress ? selectedProgress.delivery_boy.name : '')"
      :show.sync="detailsModal.show"
      size="lg"
    >
      <div v-if="selectedProgress">
        <CRow>
          <CCol md="6">
            <h6 class="mb-3">Partner Information</h6>
            <div class="mb-2">
              <strong>Name:</strong> {{ selectedProgress.delivery_boy.name }}
            </div>
            <div class="mb-2">
              <strong>Phone:</strong> {{ selectedProgress.delivery_boy.phone }}
            </div>
            <div class="mb-2">
              <strong>City:</strong> {{ selectedProgress.delivery_boy.city_name || 'N/A' }}
            </div>
          </CCol>
          <CCol md="6">
            <h6 class="mb-3">Offer Information</h6>
            <div class="mb-2">
              <strong>Offer:</strong> {{ selectedProgress.incentive_offer.name }}
            </div>
            <div class="mb-2">
              <strong>Period:</strong>
              {{ formatDate(selectedProgress.incentive_offer.start_date) }} -
              {{ formatDate(selectedProgress.incentive_offer.end_date) }}
            </div>
          </CCol>
        </CRow>

        <hr>

        <CRow>
          <CCol md="12">
            <h6 class="mb-3">Progress Summary</h6>
            <CProgress
              :value="calculateProgress(selectedProgress)"
              color="success"
              :precision="1"
              showPercentage
              class="mb-3"
              height="25px"
            />

            <CRow>
              <CCol md="6">
                <div class="mb-2">
                  <strong>Current Earnings:</strong>
                  <span class="text-success ml-2">₹{{ parseFloat(selectedProgress.current_earnings || 0).toFixed(2) }}</span>
                </div>
                <div class="mb-2">
                  <strong>Gigs Completed:</strong> {{ selectedProgress.gigs_completed || 0 }}
                </div>
                <div class="mb-2">
                  <strong>Current Tier:</strong>
                  <CBadge v-if="selectedProgress.current_tier" color="info" class="ml-2">
                    {{ selectedProgress.current_tier.tier_name }}
                  </CBadge>
                  <span v-else class="text-muted ml-2">None</span>
                </div>
              </CCol>
              <CCol md="6">
                <div class="mb-2">
                  <strong>Gigs Skipped:</strong>
                  <CBadge
                    :color="(selectedProgress.gigs_skipped || 0) <= selectedProgress.incentive_offer.max_gigs_skip ? 'success' : 'danger'"
                    class="ml-2"
                  >
                    {{ selectedProgress.gigs_skipped || 0 }} / {{ selectedProgress.incentive_offer.max_gigs_skip }}
                  </CBadge>
                </div>
                <div class="mb-2">
                  <strong>Orders Cancelled:</strong>
                  <CBadge
                    :color="(selectedProgress.orders_cancelled || 0) <= selectedProgress.incentive_offer.max_orders_cancel ? 'success' : 'danger'"
                    class="ml-2"
                  >
                    {{ selectedProgress.orders_cancelled || 0 }} / {{ selectedProgress.incentive_offer.max_orders_cancel }}
                  </CBadge>
                </div>
                <div class="mb-2">
                  <strong>Eligible for Payout:</strong>
                  <CBadge :color="selectedProgress.is_eligible ? 'success' : 'danger'" class="ml-2">
                    {{ selectedProgress.is_eligible ? 'Yes' : 'No' }}
                  </CBadge>
                </div>
              </CCol>
            </CRow>
          </CCol>
        </CRow>

        <hr>

        <div v-if="selectedProgress.incentive_offer.tiers && selectedProgress.incentive_offer.tiers.length">
          <h6 class="mb-3">All Tiers</h6>
          <CListGroup>
            <CListGroupItem
              v-for="tier in selectedProgress.incentive_offer.tiers"
              :key="tier.id"
              :color="tier.id === (selectedProgress.current_tier ? selectedProgress.current_tier.id : null) ? 'success' : ''"
            >
              <div class="d-flex justify-content-between align-items-center">
                <div>
                  <strong>{{ tier.tier_name }}</strong>
                  <br>
                  <small>Target: ₹{{ parseFloat(tier.earnings_target).toFixed(2) }}</small>
                </div>
                <div>
                  <CBadge color="primary">₹{{ parseFloat(tier.reward_amount).toFixed(2) }}</CBadge>
                </div>
              </div>
            </CListGroupItem>
          </CListGroup>
        </div>
      </div>
      <template #footer>
        <CButton color="secondary" @click="detailsModal.show = false">
          Close
        </CButton>
      </template>
    </CModal>
  </CRow>
</template>

<script>
import axios from 'axios'
import moment from 'moment'

export default {
  name: 'PartnerProgress',
  data() {
    return {
      loading: false,
      progressList: [],
      offers: [],
      stats: {
        total_participants: 0,
        eligible_count: 0,
        in_progress_count: 0,
        total_potential_payout: 0
      },
      filters: {
        search: '',
        offerId: '',
        status: ''
      },
      statusOptions: [
        { value: '', label: 'All Status' },
        { value: 'eligible', label: 'Eligible' },
        { value: 'not_eligible', label: 'Not Eligible' }
      ],
      fields: [
        { key: 'partner', label: 'Delivery Partner', _style: 'width: 200px' },
        { key: 'offer', label: 'Incentive Offer' },
        { key: 'progress', label: 'Progress' },
        { key: 'current_tier', label: 'Current Tier' },
        { key: 'next_tier', label: 'Next Tier' },
        { key: 'compliance', label: 'Compliance' },
        { key: 'eligible', label: 'Eligible', _style: 'width: 80px' },
        { key: 'actions', label: 'Actions', _style: 'width: 120px' }
      ],
      searchTimeout: null,
      detailsModal: {
        show: false
      },
      selectedProgress: null
    }
  },
  computed: {
    offerOptions() {
      return [
        { value: '', label: 'All Offers' },
        ...this.offers.map(offer => ({
          value: offer.id,
          label: offer.name
        }))
      ]
    }
  },
  mounted() {
    this.loadOffers()
    this.loadProgress()
  },
  methods: {
    async loadOffers() {
      try {
        const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/offers', {
          params: { token: localStorage.getItem('api_token') }
        })
        this.offers = response.data.data.offers
      } catch (error) {
        console.error('Failed to load offers:', error)
      }
    },

    async loadProgress() {
      this.loading = true
      try {
        const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/offers/progress', {
          params: {
            token: localStorage.getItem('api_token'),
            search: this.filters.search,
            offer_id: this.filters.offerId,
            status: this.filters.status
          }
        })
        this.progressList = response.data.data.progress
        this.stats = response.data.data.stats
      } catch (error) {
        this.$swal.fire('Error', 'Failed to load partner progress', 'error')
      }
      this.loading = false
    },

    debounceSearch() {
      if (this.searchTimeout) clearTimeout(this.searchTimeout)
      this.searchTimeout = setTimeout(() => {
        this.loadProgress()
      }, 500)
    },

    viewDetails(progress) {
      this.selectedProgress = progress
      this.detailsModal.show = true
    },

    async exportProgress() {
      try {
        const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/offers/progress/export', {
          params: {
            token: localStorage.getItem('api_token'),
            offer_id: this.filters.offerId,
            status: this.filters.status
          },
          responseType: 'blob'
        })

        const url = window.URL.createObjectURL(new Blob([response.data]))
        const link = document.createElement('a')
        link.href = url
        link.setAttribute('download', `partner_progress_${moment().format('YYYY-MM-DD')}.xlsx`)
        document.body.appendChild(link)
        link.click()
        link.remove()
      } catch (error) {
        this.$swal.fire('Error', 'Failed to export progress', 'error')
      }
    },

    formatDate(date) {
      return moment(date).format('MMM DD, YYYY')
    },

    calculateProgress(item) {
      if (!item.incentive_offer || !item.incentive_offer.min_gigs_required) return 0
      const progress = ((item.gigs_completed || 0) / item.incentive_offer.min_gigs_required) * 100
      return Math.min(progress, 100)
    }
  }
}
</script>

<style scoped>
.card-header-actions {
  margin-right: 0;
}
</style>
