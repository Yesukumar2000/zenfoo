<template>
  <CRow>
    <CCol col="12">
      <CCard>
        <CCardHeader>
          <strong>Incentive Offer Payouts</strong>
          <div class="card-header-actions">
            <CButton color="secondary" size="sm" @click="exportPayouts">
              <CIcon name="cil-cloud-download" /> Export Report
            </CButton>
          </div>
        </CCardHeader>
        <CCardBody>
          <!-- Filters -->
          <CRow class="mb-3">
            <CCol md="3">
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
            <CCol md="3">
              <CSelect
                label="Select Offer"
                v-model="filters.offerId"
                :options="offerOptions"
                @change="loadPayouts"
              />
            </CCol>
            <CCol md="2">
              <CSelect
                label="Status"
                v-model="filters.status"
                :options="statusOptions"
                @change="loadPayouts"
              />
            </CCol>
            <CCol md="2">
              <CInput
                label="From Date"
                type="date"
                v-model="filters.fromDate"
                @input="loadPayouts"
              />
            </CCol>
            <CCol md="2">
              <CInput
                label="To Date"
                type="date"
                v-model="filters.toDate"
                @input="loadPayouts"
              />
            </CCol>
          </CRow>

          <!-- Stats Cards -->
          <CRow class="mb-3">
            <CCol sm="3">
              <CWidgetSimple
                header="Total Payouts"
                :text="String(stats.total_payouts)"
                color="primary"
              >
                <CIcon name="cil-wallet" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple
                header="Pending Amount"
                :text="'₹' + stats.pending_amount"
                color="warning"
              >
                <CIcon name="cil-clock" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple
                header="Processed Amount"
                :text="'₹' + stats.processed_amount"
                color="success"
              >
                <CIcon name="cil-check-circle" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple
                header="Total Amount"
                :text="'₹' + stats.total_amount"
                color="info"
              >
                <CIcon name="cil-dollar" height="36" />
              </CWidgetSimple>
            </CCol>
          </CRow>

          <!-- Payouts Table -->
          <CDataTable
            :items="payouts"
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
              </td>
            </template>

            <template #tier="{ item }">
              <td>
                <div v-if="item.achieved_tier">
                  <strong>{{ item.achieved_tier.tier_name }}</strong>
                  <br>
                  <small class="text-muted">₹{{ parseFloat(item.achieved_tier.reward_amount).toFixed(2) }}</small>
                </div>
                <span v-else class="text-muted">N/A</span>
              </td>
            </template>

            <template #payout_amount="{ item }">
              <td>
                <strong class="text-success">₹{{ parseFloat(item.payout_amount).toFixed(2) }}</strong>
              </td>
            </template>

            <template #payout_status="{ item }">
              <td>
                <CBadge :color="getStatusColor(item.payout_status)">
                  {{ item.payout_status }}
                </CBadge>
              </td>
            </template>

            <template #completed_at="{ item }">
              <td>
                <small>{{ formatDateTime(item.completed_at) }}</small>
              </td>
            </template>

            <template #payout_processed_at="{ item }">
              <td>
                <small>{{ item.payout_processed_at ? formatDateTime(item.payout_processed_at) : '-' }}</small>
              </td>
            </template>

            <template #actions="{ item }">
              <td>
                <CButton
                  v-if="item.payout_status === 'pending'"
                  color="success"
                  size="sm"
                  @click="processPayout(item)"
                >
                  <CIcon name="cil-check" /> Process Payout
                </CButton>
                <CBadge v-else color="success">
                  <CIcon name="cil-check" /> Processed
                </CBadge>
              </td>
            </template>
          </CDataTable>

          <!-- Empty State -->
          <CRow v-if="!loading && payouts.length === 0" class="justify-content-center py-5">
            <CCol sm="6" class="text-center">
              <CIcon name="cil-wallet" size="5xl" class="text-muted mb-3" />
              <h5 class="text-muted">No Payouts Found</h5>
              <p class="text-muted">No payouts match your current filters</p>
            </CCol>
          </CRow>
        </CCardBody>
      </CCard>
    </CCol>
  </CRow>
</template>

<script>
import axios from 'axios'
import moment from 'moment'

export default {
  name: 'OfferPayouts',
  data() {
    return {
      loading: false,
      payouts: [],
      offers: [],
      stats: {
        total_payouts: 0,
        pending_amount: 0,
        processed_amount: 0,
        total_amount: 0
      },
      filters: {
        search: '',
        offerId: '',
        status: '',
        fromDate: moment().startOf('month').format('YYYY-MM-DD'),
        toDate: moment().endOf('month').format('YYYY-MM-DD')
      },
      statusOptions: [
        { value: '', label: 'All Status' },
        { value: 'pending', label: 'Pending' },
        { value: 'processed', label: 'Processed' }
      ],
      fields: [
        { key: 'partner', label: 'Delivery Partner', _style: 'width: 200px' },
        { key: 'offer', label: 'Incentive Offer' },
        { key: 'tier', label: 'Achieved Tier' },
        { key: 'payout_amount', label: 'Payout Amount' },
        { key: 'payout_status', label: 'Status', _style: 'width: 100px' },
        { key: 'completed_at', label: 'Completed At' },
        { key: 'payout_processed_at', label: 'Processed At' },
        { key: 'actions', label: 'Actions', _style: 'width: 150px' }
      ],
      searchTimeout: null
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
    this.loadPayouts()
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

    async loadPayouts() {
      this.loading = true
      try {
        const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/offers/payouts', {
          params: {
            token: localStorage.getItem('api_token'),
            search: this.filters.search,
            offer_id: this.filters.offerId,
            status: this.filters.status,
            from_date: this.filters.fromDate,
            to_date: this.filters.toDate
          }
        })
        this.payouts = response.data.data.payouts
        this.stats = response.data.data.stats
      } catch (error) {
        this.$swal.fire('Error', 'Failed to load payouts', 'error')
      }
      this.loading = false
    },

    debounceSearch() {
      if (this.searchTimeout) clearTimeout(this.searchTimeout)
      this.searchTimeout = setTimeout(() => {
        this.loadPayouts()
      }, 500)
    },

    async processPayout(payout) {
      const result = await this.$swal.fire({
        title: 'Process Payout?',
        text: `Process payout of ₹${parseFloat(payout.payout_amount).toFixed(2)} for ${payout.delivery_boy.name}?`,
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Yes, Process',
        confirmButtonColor: '#28a745'
      })

      if (result.isConfirmed) {
        try {
          await axios.post(this.$apiUrl + '/admin/delivery-boys/offers/payouts/process', {
            token: localStorage.getItem('api_token'),
            progress_id: payout.id
          })

          this.$swal.fire('Success', 'Payout processed successfully', 'success')
          this.loadPayouts()
        } catch (error) {
          this.$swal.fire('Error', error.response?.data?.message || 'Failed to process payout', 'error')
        }
      }
    },

    async exportPayouts() {
      try {
        const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/offers/payouts/export', {
          params: {
            token: localStorage.getItem('api_token'),
            offer_id: this.filters.offerId,
            status: this.filters.status,
            from_date: this.filters.fromDate,
            to_date: this.filters.toDate
          },
          responseType: 'blob'
        })

        const url = window.URL.createObjectURL(new Blob([response.data]))
        const link = document.createElement('a')
        link.href = url
        link.setAttribute('download', `offer_payouts_${moment().format('YYYY-MM-DD')}.xlsx`)
        document.body.appendChild(link)
        link.click()
        link.remove()
      } catch (error) {
        this.$swal.fire('Error', 'Failed to export payouts', 'error')
      }
    },

    formatDateTime(datetime) {
      if (!datetime) return 'N/A'
      return moment(datetime).format('MMM DD, YYYY hh:mm A')
    },

    getStatusColor(status) {
      const colors = {
        pending: 'warning',
        processed: 'success'
      }
      return colors[status] || 'secondary'
    }
  }
}
</script>

<style scoped>
.card-header-actions {
  margin-right: 0;
}
</style>
