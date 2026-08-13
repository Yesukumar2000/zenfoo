<template>
  <div>
    <CDataTable
      :items="offers"
      :fields="fields"
      :loading="loading"
      hover
      striped
      bordered
    >
      <template #banner="{item}">
        <td>
          <CImg
            v-if="item.banner_image_url"
            :src="item.banner_image_url"
            width="80"
            height="50"
            style="object-fit: cover; border-radius: 4px;"
          />
          <div v-else class="text-muted small">No banner</div>
        </td>
      </template>

      <template #name="{item}">
        <td>
          <strong>{{ item.name }}</strong>
          <br>
          <small class="text-muted">{{ item.description ? item.description.substring(0, 60) + '...' : 'No description' }}</small>
        </td>
      </template>

      <template #dates="{item}">
        <td>
          <div class="mb-1">
            <small class="text-muted">Start:</small>
            <br>
            {{ formatDate(item.start_date) }}
          </div>
          <div>
            <small class="text-muted">End:</small>
            <br>
            {{ formatDate(item.end_date) }}
          </div>
          <CBadge :color="getDateStatusColor(item)" class="mt-1">
            {{ getDateStatus(item) }}
          </CBadge>
        </td>
      </template>

      <template #conditions="{item}">
        <td>
          <div class="small">
            <div><CIcon name="cil-task" /> Min Gigs: <strong>{{ item.min_gigs_required }}</strong></div>
            <div><CIcon name="cil-ban" /> Max Skip: <strong>{{ item.max_gigs_skip }}</strong></div>
            <div><CIcon name="cil-x-circle" /> Max Cancel: <strong>{{ item.max_orders_cancel }}</strong></div>
            <div>
              <CIcon name="cil-clock" />
              Login: <strong>{{ item.login_mandatory ? 'Required' : 'Optional' }}</strong>
            </div>
          </div>
        </td>
      </template>

      <template #tiers="{item}">
        <td>
          <CBadge color="info" class="mr-1">{{ item.tiers_count }} Tiers</CBadge>
          <br>
          <small class="text-muted">Max: ₹{{ getMaxIncentive(item) }}</small>
        </td>
      </template>

      <template #participants="{item}">
        <td class="text-center">
          <div class="h4 mb-0">{{ item.enrolled_count || 0 }}</div>
          <small class="text-muted">Enrolled</small>
        </td>
      </template>

      <template #status="{item}">
        <td>
          <CSwitch
            color="success"
            :checked="item.status == 1"
            @update:checked="$emit('toggle-status', item)"
            label
            variant="opposite"
          />
        </td>
      </template>

      <template #actions="{item}">
        <td>
          <CButton
            color="info"
            size="sm"
            @click="$emit('view-progress', item)"
            class="mr-1 mb-1"
          >
            <CIcon name="cil-chart-line" /> Progress
          </CButton>
          <CButton
            color="warning"
            size="sm"
            @click="$emit('edit', item)"
            class="mr-1 mb-1"
          >
            <CIcon name="cil-pencil" /> Edit
          </CButton>
          <CButton
            color="danger"
            size="sm"
            @click="$emit('delete', item)"
            class="mb-1"
          >
            <CIcon name="cil-trash" /> Delete
          </CButton>
        </td>
      </template>
    </CDataTable>

    <!-- Empty State -->
    <CRow v-if="!loading && offers.length === 0" class="justify-content-center py-5">
      <CCol sm="6" class="text-center">
        <CIcon name="cil-gift" size="5xl" class="text-muted mb-3" />
        <h5 class="text-muted">No Offers Found</h5>
        <p class="text-muted">Create your first incentive offer to motivate delivery partners</p>
      </CCol>
    </CRow>
  </div>
</template>

<script>
import moment from 'moment'

export default {
  name: 'OffersTable',
  props: {
    offers: {
      type: Array,
      default: () => []
    },
    loading: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      fields: [
        { key: 'banner', label: 'Banner', _style: 'width: 100px' },
        { key: 'name', label: 'Offer Name' },
        { key: 'dates', label: 'Duration' },
        { key: 'conditions', label: 'Conditions' },
        { key: 'tiers', label: 'Tiers', _style: 'width: 100px' },
        { key: 'participants', label: 'Enrolled', _style: 'width: 100px' },
        { key: 'status', label: 'Active', _style: 'width: 80px' },
        { key: 'actions', label: 'Actions', _style: 'width: 280px' }
      ]
    }
  },
  methods: {
    formatDate(date) {
      return moment(date).format('DD MMM YYYY')
    },

    getDateStatus(offer) {
      const now = moment()
      const start = moment(offer.start_date)
      const end = moment(offer.end_date)

      if (now.isBefore(start)) {
        const days = start.diff(now, 'days')
        return `Starts in ${days} days`
      } else if (now.isBetween(start, end)) {
        const days = end.diff(now, 'days')
        return `${days} days left`
      } else {
        return 'Expired'
      }
    },

    getDateStatusColor(offer) {
      const now = moment()
      const start = moment(offer.start_date)
      const end = moment(offer.end_date)

      if (now.isBefore(start)) {
        return 'warning'
      } else if (now.isBetween(start, end)) {
        const days = end.diff(now, 'days')
        return days > 7 ? 'success' : 'warning'
      } else {
        return 'secondary'
      }
    },

    getMaxIncentive(offer) {
      if (!offer.max_incentive) return '0'
      return parseFloat(offer.max_incentive).toFixed(2)
    }
  }
}
</script>
