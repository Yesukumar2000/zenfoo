<template>
  <CRow>
    <CCol col="12">
      <CCard>
        <CCardHeader>
          <strong>Daily Tracking Reports</strong>
          <div class="card-header-actions">
            <CButton color="secondary" size="sm" @click="exportReports">
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
            <CCol md="2">
              <CSelect
                label="City"
                v-model="filters.city"
                :options="cityOptions"
                @change="loadReports"
              />
            </CCol>
            <CCol md="2">
              <CInput
                label="From Date"
                type="date"
                v-model="filters.fromDate"
                @input="loadReports"
              />
            </CCol>
            <CCol md="2">
              <CInput
                label="To Date"
                type="date"
                v-model="filters.toDate"
                @input="loadReports"
              />
            </CCol>
            <CCol md="3">
              <label class="d-block">&nbsp;</label>
              <CButton color="primary" @click="loadReports">
                <CIcon name="cil-filter" /> Apply Filters
              </CButton>
              <CButton color="secondary" class="ml-2" @click="resetFilters">
                <CIcon name="cil-x" /> Reset
              </CButton>
            </CCol>
          </CRow>

          <!-- Stats Cards -->
          <CRow class="mb-3">
            <CCol sm="3">
              <CWidgetSimple
                header="Total Earnings"
                :text="'₹' + stats.total_earnings"
                color="success"
              >
                <CIcon name="cil-dollar" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple
                header="Total Orders"
                :text="String(stats.total_orders)"
                color="info"
              >
                <CIcon name="cil-cart" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple
                header="Orders Delivered"
                :text="String(stats.total_delivered)"
                color="primary"
              >
                <CIcon name="cil-check-circle" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple
                header="Orders Cancelled"
                :text="String(stats.total_cancelled)"
                color="danger"
              >
                <CIcon name="cil-x-circle" height="36" />
              </CWidgetSimple>
            </CCol>
          </CRow>

          <!-- Reports Table -->
          <CDataTable
            :items="reports"
            :fields="fields"
            :loading="loading"
            :items-per-page="25"
            pagination
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

            <template #date="{ item }">
              <td>
                <div>{{ formatDate(item.date) }}</div>
                <small class="text-muted">{{ formatDay(item.date) }}</small>
              </td>
            </template>

            <template #total_orders="{ item }">
              <td class="text-center">
                <CBadge color="info">{{ item.total_orders || 0 }}</CBadge>
              </td>
            </template>

            <template #earnings="{ item }">
              <td>
                <strong class="text-success">₹{{ parseFloat(item.total_earnings || 0).toFixed(2) }}</strong>
              </td>
            </template>

            <template #orders="{ item }">
              <td class="text-center">
                <div>
                  <CBadge color="success">{{ item.orders_delivered || 0 }}</CBadge>
                  <span class="text-muted mx-1">/</span>
                  <CBadge color="danger">{{ item.orders_cancelled || 0 }}</CBadge>
                </div>
                <small class="text-muted">Delivered / Cancelled</small>
              </td>
            </template>

            <template #actions="{ item }">
              <td>
                <CButton
                  color="info"
                  size="sm"
                  @click="viewDetails(item)"
                >
                  <CIcon name="cil-info" /> View Details
                </CButton>
              </td>
            </template>
          </CDataTable>

          <!-- Empty State -->
          <CRow v-if="!loading && reports.length === 0" class="justify-content-center py-5">
            <CCol sm="6" class="text-center">
              <CIcon name="cil-chart-line" size="5xl" class="text-muted mb-3" />
              <h5 class="text-muted">No Reports Found</h5>
              <p class="text-muted">No reports match your current filters</p>
            </CCol>
          </CRow>
        </CCardBody>
      </CCard>
    </CCol>

    <!-- Details Modal -->
    <CModal
      :title="'Daily Report Details - ' + (selectedReport ? selectedReport.delivery_boy.name : '')"
      :show.sync="detailsModal.show"
      size="lg"
    >
      <div v-if="selectedReport">
        <CRow>
          <CCol md="6">
            <h6 class="mb-3">Partner Information</h6>
            <div class="mb-2">
              <strong>Name:</strong> {{ selectedReport.delivery_boy.name }}
            </div>
            <div class="mb-2">
              <strong>Phone:</strong> {{ selectedReport.delivery_boy.phone }}
            </div>
            <div class="mb-2">
              <strong>City:</strong> {{ selectedReport.delivery_boy.city_name || 'N/A' }}
            </div>
            <div class="mb-2">
              <strong>Date:</strong> {{ formatDate(selectedReport.date) }}
            </div>
          </CCol>
          <CCol md="6">
            <h6 class="mb-3">Performance Summary</h6>
            <div class="mb-2">
              <strong>Total Orders:</strong> {{ selectedReport.total_orders || 0 }}
            </div>
            <div class="mb-2">
              <strong>Total Earnings:</strong>
              <span class="text-success font-weight-bold">₹{{ parseFloat(selectedReport.total_earnings || 0).toFixed(2) }}</span>
            </div>
          </CCol>
        </CRow>

        <hr>

        <CRow>
          <CCol md="12">
            <h6 class="mb-3">Order Statistics</h6>
            <div class="mb-2">
              <strong>Orders Delivered:</strong>
              <CBadge color="success" class="ml-2">{{ selectedReport.orders_delivered || 0 }}</CBadge>
            </div>
            <div class="mb-2">
              <strong>Orders Cancelled:</strong>
              <CBadge color="danger" class="ml-2">{{ selectedReport.orders_cancelled || 0 }}</CBadge>
            </div>
            <div class="mb-2">
              <strong>Success Rate:</strong>
              <span class="ml-2">{{ calculateSuccessRate(selectedReport) }}%</span>
            </div>
          </CCol>
        </CRow>
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
  name: 'DailyReports',
  data() {
    return {
      loading: false,
      reports: [],
      stats: {
        total_earnings: 0,
        total_orders: 0,
        total_delivered: 0,
        total_cancelled: 0
      },
      filters: {
        search: '',
        city: '',
        fromDate: moment().subtract(7, 'days').format('YYYY-MM-DD'),
        toDate: moment().format('YYYY-MM-DD')
      },
      cityOptions: [
        { value: '', label: 'All Cities' }
      ],
      fields: [
        { key: 'partner', label: 'Delivery Partner', _style: 'width: 200px' },
        { key: 'date', label: 'Date' },
        { key: 'total_orders', label: 'Total Orders', _style: 'width: 100px' },
        { key: 'earnings', label: 'Earnings' },
        { key: 'orders', label: 'Delivered / Cancelled' },
        { key: 'actions', label: 'Actions', _style: 'width: 120px' }
      ],
      searchTimeout: null,
      detailsModal: {
        show: false
      },
      selectedReport: null
    }
  },
  mounted() {
    this.loadCities()
    this.loadReports()
  },
  methods: {
    async loadCities() {
      try {
        const response = await axios.get(this.$apiUrl + '/admin/cities', {
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

    async loadReports() {
      this.loading = true
      console.log('[DailyReports] Loading reports...')
      console.log('[DailyReports] API URL:', this.$apiUrl + '/admin/delivery-boys/tracking/reports')
      try {
        const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/tracking/reports', {
          params: {
            token: localStorage.getItem('api_token'),
            search: this.filters.search,
            city_id: this.filters.city,
            from_date: this.filters.fromDate,
            to_date: this.filters.toDate
          }
        })
        console.log('[DailyReports] Response:', response.data)

        // Check if data structure matches expected format
        if (response.data.data && response.data.data.reports) {
          this.reports = response.data.data.reports
          this.stats = response.data.data.stats
          console.log('[DailyReports] Loaded', this.reports.length, 'reports')
        } else {
          console.error('[DailyReports] Unexpected response structure:', response.data)
          this.$swal.fire('Error', 'Unexpected data structure received', 'error')
        }
      } catch (error) {
        console.error('[DailyReports] Error loading reports:', error)
        console.error('[DailyReports] Error details:', error.response?.data || error.message)
        this.$swal.fire('Error', 'Failed to load daily reports: ' + (error.response?.data?.message || error.message), 'error')
      }
      this.loading = false
    },

    debounceSearch() {
      if (this.searchTimeout) clearTimeout(this.searchTimeout)
      this.searchTimeout = setTimeout(() => {
        this.loadReports()
      }, 500)
    },

    resetFilters() {
      this.filters = {
        search: '',
        city: '',
        fromDate: moment().subtract(7, 'days').format('YYYY-MM-DD'),
        toDate: moment().format('YYYY-MM-DD')
      }
      this.loadReports()
    },

    viewDetails(report) {
      this.selectedReport = report
      this.detailsModal.show = true
    },

    async exportReports() {
      try {
        const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/tracking/reports/export', {
          params: {
            token: localStorage.getItem('api_token'),
            city_id: this.filters.city,
            from_date: this.filters.fromDate,
            to_date: this.filters.toDate
          },
          responseType: 'blob'
        })

        const url = window.URL.createObjectURL(new Blob([response.data]))
        const link = document.createElement('a')
        link.href = url
        link.setAttribute('download', `daily_reports_${moment().format('YYYY-MM-DD')}.xlsx`)
        document.body.appendChild(link)
        link.click()
        link.remove()
      } catch (error) {
        this.$swal.fire('Error', 'Failed to export reports', 'error')
      }
    },

    formatDate(date) {
      return moment(date).format('MMM DD, YYYY')
    },

    formatDay(date) {
      return moment(date).format('dddd')
    },

    calculateSuccessRate(report) {
      const total = (report.orders_delivered || 0) + (report.orders_cancelled || 0)
      if (total === 0) return 0
      return ((report.orders_delivered || 0) / total * 100).toFixed(1)
    }
  }
}
</script>

<style scoped>
.card-header-actions {
  margin-right: 0;
}
</style>
