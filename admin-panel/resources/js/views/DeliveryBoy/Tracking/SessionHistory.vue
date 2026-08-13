<template>
  <CRow>
    <CCol col="12">
      <CCard>
        <CCardHeader>
          <strong>Delivery Partner Session History</strong>
          <div class="card-header-actions">
            <CButton color="secondary" size="sm" @click="exportSessions">
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
                @change="loadSessions"
              />
            </CCol>
            <CCol md="2">
              <CInput
                label="From Date"
                type="date"
                v-model="filters.fromDate"
                @input="loadSessions"
              />
            </CCol>
            <CCol md="2">
              <CInput
                label="To Date"
                type="date"
                v-model="filters.toDate"
                @input="loadSessions"
              />
            </CCol>
            <CCol md="3">
              <label class="d-block">&nbsp;</label>
              <CButton color="primary" @click="loadSessions">
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
                header="Total Sessions"
                :text="String(stats.total_sessions)"
                color="primary"
              >
                <CIcon name="cil-clock" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple
                header="Total Hours"
                :text="stats.total_hours + 'h'"
                color="info"
              >
                <CIcon name="cil-history" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple
                header="Avg Session Duration"
                :text="stats.avg_session_duration"
                color="success"
              >
                <CIcon name="cil-speedometer" height="36" />
              </CWidgetSimple>
            </CCol>
            <CCol sm="3">
              <CWidgetSimple
                header="Active Today"
                :text="String(stats.active_today)"
                color="warning"
              >
                <CIcon name="cil-user-follow" height="36" />
              </CWidgetSimple>
            </CCol>
          </CRow>

          <!-- Sessions Table -->
          <CDataTable
            :items="sessions"
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

            <template #login_at="{ item }">
              <td>
                <div>{{ formatDateTime(item.login_at) }}</div>
              </td>
            </template>

            <template #logout_at="{ item }">
              <td>
                <div v-if="item.logout_at">{{ formatDateTime(item.logout_at) }}</div>
                <CBadge v-else color="success">
                  <span class="pulse-dot mr-1"></span>
                  Active
                </CBadge>
              </td>
            </template>

            <template #duration="{ item }">
              <td>
                <strong>{{ formatDuration(item.duration_minutes) }}</strong>
              </td>
            </template>

            <template #location="{ item }">
              <td>
                <CButton
                  v-if="item.login_latitude && item.login_longitude"
                  color="info"
                  size="sm"
                  @click="viewLocation(item)"
                >
                  <CIcon name="cil-location-pin" /> View
                </CButton>
                <span v-else class="text-muted">N/A</span>
              </td>
            </template>

            <template #orders="{ item }">
              <td class="text-center">
                <CBadge color="info">{{ item.orders_delivered || 0 }}</CBadge>
              </td>
            </template>

            <template #earnings="{ item }">
              <td>
                <strong class="text-success">₹{{ parseFloat(item.earnings || 0).toFixed(2) }}</strong>
              </td>
            </template>
          </CDataTable>

          <!-- Empty State -->
          <CRow v-if="!loading && sessions.length === 0" class="justify-content-center py-5">
            <CCol sm="6" class="text-center">
              <CIcon name="cil-history" size="5xl" class="text-muted mb-3" />
              <h5 class="text-muted">No Sessions Found</h5>
              <p class="text-muted">No sessions match your current filters</p>
            </CCol>
          </CRow>
        </CCardBody>
      </CCard>
    </CCol>

    <!-- Location Modal -->
    <CModal
      :title="'Session Location - ' + (selectedSession ? selectedSession.delivery_boy.name : '')"
      :show.sync="locationModal.show"
      size="xl"
    >
      <div v-if="selectedSession" style="height: 500px;">
        <iframe
          v-if="selectedSession.login_latitude && selectedSession.login_longitude"
          width="100%"
          height="100%"
          frameborder="0"
          style="border:0"
          :src="'https://www.google.com/maps?q=' + selectedSession.login_latitude + ',' + selectedSession.login_longitude + '&output=embed'"
          allowfullscreen
        ></iframe>
      </div>
      <div class="mt-3" v-if="selectedSession">
        <p><strong>Login Time:</strong> {{ formatDateTime(selectedSession.login_at) }}</p>
        <p><strong>Logout Time:</strong> {{ selectedSession.logout_at ? formatDateTime(selectedSession.logout_at) : 'Still Active' }}</p>
        <p><strong>Duration:</strong> {{ formatDuration(selectedSession.duration_minutes) }}</p>
      </div>
    </CModal>
  </CRow>
</template>

<script>
import axios from 'axios'
import moment from 'moment'

export default {
  name: 'SessionHistory',
  data() {
    return {
      loading: false,
      sessions: [],
      stats: {
        total_sessions: 0,
        total_hours: 0,
        avg_session_duration: '0h 0m',
        active_today: 0
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
        { key: 'login_at', label: 'Login Time' },
        { key: 'logout_at', label: 'Logout Time' },
        { key: 'duration', label: 'Duration' },
        { key: 'location', label: 'Location', _style: 'width: 100px' },
        { key: 'orders', label: 'Orders', _style: 'width: 80px' },
        { key: 'earnings', label: 'Earnings' }
      ],
      searchTimeout: null,
      locationModal: {
        show: false
      },
      selectedSession: null
    }
  },
  mounted() {
    this.loadCities()
    this.loadSessions()
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

    async loadSessions() {
      this.loading = true
      console.log('[SessionHistory] Loading sessions...')
      console.log('[SessionHistory] API URL:', this.$apiUrl + '/admin/delivery-boys/tracking/sessions')
      console.log('[SessionHistory] Filters:', this.filters)
      try {
        const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/tracking/sessions', {
          params: {
            token: localStorage.getItem('api_token'),
            search: this.filters.search,
            city_id: this.filters.city,
            from_date: this.filters.fromDate,
            to_date: this.filters.toDate
          }
        })
        console.log('[SessionHistory] Response:', response.data)
        console.log('[SessionHistory] Sessions array:', response.data.data?.sessions)
        console.log('[SessionHistory] Stats:', response.data.data?.stats)

        if (response.data.data && response.data.data.sessions) {
          this.sessions = response.data.data.sessions
          this.stats = response.data.data.stats
          console.log('[SessionHistory] Loaded', this.sessions.length, 'sessions')
        } else {
          console.error('[SessionHistory] Unexpected response structure:', response.data)
        }
      } catch (error) {
        console.error('[SessionHistory] Error loading sessions:', error)
        console.error('[SessionHistory] Error details:', error.response?.data || error.message)
        this.$swal.fire('Error', 'Failed to load session history: ' + (error.response?.data?.message || error.message), 'error')
      }
      this.loading = false
    },

    debounceSearch() {
      if (this.searchTimeout) clearTimeout(this.searchTimeout)
      this.searchTimeout = setTimeout(() => {
        this.loadSessions()
      }, 500)
    },

    resetFilters() {
      this.filters = {
        search: '',
        city: '',
        fromDate: moment().subtract(7, 'days').format('YYYY-MM-DD'),
        toDate: moment().format('YYYY-MM-DD')
      }
      this.loadSessions()
    },

    viewLocation(session) {
      this.selectedSession = session
      this.locationModal.show = true
    },

    async exportSessions() {
      try {
        const response = await axios.get(this.$apiUrl + '/admin/delivery-boys/tracking/sessions/export', {
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
        link.setAttribute('download', `session_history_${moment().format('YYYY-MM-DD')}.xlsx`)
        document.body.appendChild(link)
        link.click()
        link.remove()
      } catch (error) {
        this.$swal.fire('Error', 'Failed to export sessions', 'error')
      }
    },

    formatDateTime(datetime) {
      if (!datetime) return 'N/A'
      return moment(datetime).format('MMM DD, YYYY hh:mm A')
    },

    formatDuration(minutes) {
      if (!minutes) return '0m'
      const hours = Math.floor(minutes / 60)
      const mins = minutes % 60
      return hours > 0 ? `${hours}h ${mins}m` : `${mins}m`
    }
  }
}
</script>

<style scoped>
.card-header-actions {
  margin-right: 0;
}

.pulse-dot {
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: #28a745;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% {
    box-shadow: 0 0 0 0 rgba(40, 167, 69, 0.7);
  }
  70% {
    box-shadow: 0 0 0 10px rgba(40, 167, 69, 0);
  }
  100% {
    box-shadow: 0 0 0 0 rgba(40, 167, 69, 0);
  }
}
</style>
