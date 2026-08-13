# Admin Panel Frontend Implementation Guide - Gig Tracking System

## Overview
Complete admin panel implementation for managing gigs, slots, delivery partner tracking, and incentive offers.

---

## 📁 Project Structure

```
resources/js/components/
├── gigs/
│   ├── GigsList.vue
│   ├── GigForm.vue
│   ├── GigSlotsCalendar.vue
│   └── SlotManagement.vue
├── tracking/
│   ├── DeliveryBoyDashboard.vue
│   ├── LiveTracking.vue
│   ├── SessionHistory.vue
│   └── DailyReports.vue
├── offers/
│   ├── OffersList.vue
│   ├── OfferForm.vue
│   ├── TierManagement.vue
│   └── ProgressTracking.vue
└── analytics/
    ├── EarningsChart.vue
    ├── GigStats.vue
    └── IncentivePayouts.vue
```

---

## 🎨 Admin Dashboard Screens

### 1. Gigs Management Screen

**Features:**
- CRUD operations for gigs
- View gig slots calendar
- Manage slot capacity
- Enable/disable gigs

**Implementation (Vue.js):**

```vue
<!-- GigsList.vue -->
<template>
  <div class="gigs-management">
    <div class="header">
      <h2>Gigs Management</h2>
      <button @click="showCreateModal = true" class="btn-primary">
        <i class="fas fa-plus"></i> Create New Gig
      </button>
    </div>

    <!-- Gigs Table -->
    <div class="card">
      <table class="data-table">
        <thead>
          <tr>
            <th>Gig Name</th>
            <th>Time</th>
            <th>Duration</th>
            <th>Base Earnings</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="gig in gigs" :key="gig.id">
            <td>
              <strong>{{ gig.display_name }}</strong>
            </td>
            <td>{{ gig.start_time }} - {{ gig.end_time }}</td>
            <td>{{ gig.duration_hours }} hours</td>
            <td>₹{{ gig.base_earnings }}</td>
            <td>
              <span :class="['badge', gig.status == 1 ? 'badge-success' : 'badge-danger']">
                {{ gig.status == 1 ? 'Active' : 'Inactive' }}
              </span>
            </td>
            <td>
              <button @click="editGig(gig)" class="btn-sm btn-info">
                <i class="fas fa-edit"></i>
              </button>
              <button @click="manageSlots(gig)" class="btn-sm btn-warning">
                <i class="fas fa-calendar"></i> Slots
              </button>
              <button @click="toggleStatus(gig)" class="btn-sm btn-secondary">
                <i class="fas fa-power-off"></i>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Create/Edit Modal -->
    <GigFormModal
      v-if="showCreateModal"
      :gig="selectedGig"
      @save="saveGig"
      @close="showCreateModal = false"
    />
  </div>
</template>

<script>
export default {
  data() {
    return {
      gigs: [],
      showCreateModal: false,
      selectedGig: null,
      loading: false,
    };
  },

  mounted() {
    this.loadGigs();
  },

  methods: {
    async loadGigs() {
      this.loading = true;
      try {
        const response = await axios.get('/api/admin/gigs');
        this.gigs = response.data.data.gigs;
      } catch (error) {
        this.$swal.fire('Error', 'Failed to load gigs', 'error');
      }
      this.loading = false;
    },

    editGig(gig) {
      this.selectedGig = { ...gig };
      this.showCreateModal = true;
    },

    async saveGig(gigData) {
      try {
        const url = gigData.id
          ? `/api/admin/gigs/${gigData.id}`
          : '/api/admin/gigs';

        const method = gigData.id ? 'put' : 'post';

        await axios[method](url, gigData);

        this.$swal.fire('Success', 'Gig saved successfully', 'success');
        this.loadGigs();
        this.showCreateModal = false;
      } catch (error) {
        this.$swal.fire('Error', 'Failed to save gig', 'error');
      }
    },

    async toggleStatus(gig) {
      try {
        await axios.put(`/api/admin/gigs/${gig.id}/toggle-status`);
        this.$swal.fire('Success', 'Status updated', 'success');
        this.loadGigs();
      } catch (error) {
        this.$swal.fire('Error', 'Failed to update status', 'error');
      }
    },

    manageSlots(gig) {
      this.$router.push(`/admin/gigs/${gig.id}/slots`);
    },
  },
};
</script>

<style scoped>
.gigs-management {
  padding: 24px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.data-table {
  width: 100%;
  border-collapse: collapse;
}

.data-table thead {
  background: #f5f5f5;
}

.data-table th,
.data-table td {
  padding: 16px;
  text-align: left;
  border-bottom: 1px solid #e0e0e0;
}

.badge {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
}

.badge-success {
  background: #d4edda;
  color: #155724;
}

.badge-danger {
  background: #f8d7da;
  color: #721c24;
}

.btn-sm {
  padding: 6px 12px;
  margin: 0 4px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
}

.btn-info {
  background: #17a2b8;
  color: white;
}

.btn-warning {
  background: #ffc107;
  color: #212529;
}

.btn-secondary {
  background: #6c757d;
  color: white;
}
</style>
```

---

### 2. Gig Slots Calendar

**Features:**
- Monthly calendar view
- View slot capacity per day
- Bulk create slots
- Edit slot capacity

```vue
<!-- GigSlotsCalendar.vue -->
<template>
  <div class="slots-calendar">
    <div class="header">
      <h2>{{ gigName }} - Slots Calendar</h2>
      <div class="controls">
        <button @click="previousMonth" class="btn-secondary">
          <i class="fas fa-chevron-left"></i>
        </button>
        <span class="month-year">{{ currentMonthYear }}</span>
        <button @click="nextMonth" class="btn-secondary">
          <i class="fas fa-chevron-right"></i>
        </button>
        <button @click="bulkCreateSlots" class="btn-primary">
          <i class="fas fa-plus-circle"></i> Bulk Create Slots
        </button>
      </div>
    </div>

    <!-- Calendar Grid -->
    <div class="calendar">
      <div class="calendar-header">
        <div v-for="day in weekDays" :key="day" class="day-name">
          {{ day }}
        </div>
      </div>

      <div class="calendar-body">
        <div
          v-for="(day, index) in calendarDays"
          :key="index"
          :class="['calendar-day', getDayClass(day)]"
          @click="editSlot(day)"
        >
          <div class="date-number">{{ day.date }}</div>

          <div v-if="day.slot" class="slot-info">
            <div class="bookings">
              {{ day.slot.current_bookings }} / {{ day.slot.max_bookings }}
            </div>
            <div class="progress-bar">
              <div
                class="progress-fill"
                :style="{ width: getBookingPercentage(day.slot) + '%' }"
                :class="getProgressColor(day.slot)"
              ></div>
            </div>
            <div class="status">
              <span :class="['status-dot', day.slot.status == 1 ? 'active' : 'inactive']"></span>
              {{ day.slot.status == 1 ? 'Active' : 'Inactive' }}
            </div>
          </div>

          <div v-else class="no-slot">
            <small>No slot</small>
          </div>
        </div>
      </div>
    </div>

    <!-- Slot Edit Modal -->
    <SlotEditModal
      v-if="showSlotModal"
      :slot="selectedSlot"
      :gigId="gigId"
      @save="saveSlot"
      @close="showSlotModal = false"
    />
  </div>
</template>

<script>
import moment from 'moment';

export default {
  props: {
    gigId: {
      type: Number,
      required: true,
    },
  },

  data() {
    return {
      currentDate: moment(),
      slots: [],
      gigName: '',
      showSlotModal: false,
      selectedSlot: null,
      weekDays: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    };
  },

  computed: {
    currentMonthYear() {
      return this.currentDate.format('MMMM YYYY');
    },

    calendarDays() {
      const startOfMonth = this.currentDate.clone().startOf('month');
      const endOfMonth = this.currentDate.clone().endOf('month');
      const startDay = startOfMonth.day();
      const daysInMonth = endOfMonth.date();

      const days = [];

      // Previous month padding
      for (let i = 0; i < startDay; i++) {
        days.push({
          date: '',
          isCurrentMonth: false,
        });
      }

      // Current month days
      for (let i = 1; i <= daysInMonth; i++) {
        const dateStr = this.currentDate.clone().date(i).format('YYYY-MM-DD');
        const slot = this.slots.find((s) => s.slot_date === dateStr);

        days.push({
          date: i,
          dateStr: dateStr,
          isCurrentMonth: true,
          slot: slot,
        });
      }

      return days;
    },
  },

  mounted() {
    this.loadSlots();
  },

  methods: {
    async loadSlots() {
      try {
        const startDate = this.currentDate.clone().startOf('month').format('YYYY-MM-DD');
        const endDate = this.currentDate.clone().endOf('month').format('YYYY-MM-DD');

        const response = await axios.get(`/api/admin/gigs/${this.gigId}/slots`, {
          params: { start_date: startDate, end_date: endDate },
        });

        this.slots = response.data.data.slots;
        this.gigName = response.data.data.gig_name;
      } catch (error) {
        this.$swal.fire('Error', 'Failed to load slots', 'error');
      }
    },

    previousMonth() {
      this.currentDate = this.currentDate.clone().subtract(1, 'month');
      this.loadSlots();
    },

    nextMonth() {
      this.currentDate = this.currentDate.clone().add(1, 'month');
      this.loadSlots();
    },

    editSlot(day) {
      if (!day.isCurrentMonth) return;

      this.selectedSlot = day.slot || {
        gig_id: this.gigId,
        slot_date: day.dateStr,
        max_bookings: 50,
        current_bookings: 0,
        status: 1,
      };

      this.showSlotModal = true;
    },

    async saveSlot(slotData) {
      try {
        const url = slotData.id
          ? `/api/admin/gig-slots/${slotData.id}`
          : '/api/admin/gig-slots';

        const method = slotData.id ? 'put' : 'post';

        await axios[method](url, slotData);

        this.$swal.fire('Success', 'Slot saved successfully', 'success');
        this.loadSlots();
        this.showSlotModal = false;
      } catch (error) {
        this.$swal.fire('Error', 'Failed to save slot', 'error');
      }
    },

    async bulkCreateSlots() {
      const result = await this.$swal.fire({
        title: 'Bulk Create Slots',
        html: `
          <div>
            <label>Number of days:</label>
            <input id="days" type="number" class="swal2-input" value="30" min="1" max="90">
            <label>Max bookings per slot:</label>
            <input id="maxBookings" type="number" class="swal2-input" value="50" min="1">
          </div>
        `,
        showCancelButton: true,
        confirmButtonText: 'Create',
        preConfirm: () => {
          return {
            days: document.getElementById('days').value,
            maxBookings: document.getElementById('maxBookings').value,
          };
        },
      });

      if (result.isConfirmed) {
        try {
          await axios.post(`/api/admin/gigs/${this.gigId}/slots/bulk-create`, {
            days: result.value.days,
            max_bookings: result.value.maxBookings,
          });

          this.$swal.fire('Success', 'Slots created successfully', 'success');
          this.loadSlots();
        } catch (error) {
          this.$swal.fire('Error', 'Failed to create slots', 'error');
        }
      }
    },

    getDayClass(day) {
      if (!day.isCurrentMonth) return 'other-month';
      if (!day.slot) return 'no-slot';
      if (day.slot.current_bookings >= day.slot.max_bookings) return 'fully-booked';
      return '';
    },

    getBookingPercentage(slot) {
      return Math.round((slot.current_bookings / slot.max_bookings) * 100);
    },

    getProgressColor(slot) {
      const percentage = this.getBookingPercentage(slot);
      if (percentage >= 90) return 'progress-danger';
      if (percentage >= 70) return 'progress-warning';
      return 'progress-success';
    },
  },
};
</script>

<style scoped>
.slots-calendar {
  padding: 24px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.controls {
  display: flex;
  align-items: center;
  gap: 16px;
}

.month-year {
  font-size: 18px;
  font-weight: 600;
  min-width: 150px;
  text-align: center;
}

.calendar {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  padding: 24px;
}

.calendar-header {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 8px;
  margin-bottom: 16px;
}

.day-name {
  text-align: center;
  font-weight: 600;
  color: #666;
  padding: 8px;
}

.calendar-body {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 8px;
}

.calendar-day {
  aspect-ratio: 1;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  padding: 12px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  flex-direction: column;
}

.calendar-day:hover {
  border-color: #007bff;
  transform: scale(1.02);
}

.calendar-day.other-month {
  opacity: 0.3;
  cursor: default;
}

.calendar-day.no-slot {
  background: #f5f5f5;
}

.calendar-day.fully-booked {
  background: #fff5f5;
  border-color: #ff6b6b;
}

.date-number {
  font-weight: 600;
  margin-bottom: 8px;
}

.slot-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.bookings {
  font-size: 14px;
  font-weight: 600;
  color: #333;
  margin-bottom: 4px;
}

.progress-bar {
  height: 6px;
  background: #e0e0e0;
  border-radius: 3px;
  overflow: hidden;
  margin-bottom: 8px;
}

.progress-fill {
  height: 100%;
  transition: width 0.3s;
}

.progress-success {
  background: #28a745;
}

.progress-warning {
  background: #ffc107;
}

.progress-danger {
  background: #dc3545;
}

.status {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  color: #666;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.status-dot.active {
  background: #28a745;
}

.status-dot.inactive {
  background: #dc3545;
}

.no-slot small {
  color: #999;
  font-size: 12px;
}
</style>
```

---

### 3. Delivery Boy Tracking Dashboard

**Features:**
- Live delivery boy locations on map
- Active sessions list
- Today's stats per delivery boy
- Filter by city/status

```vue
<!-- DeliveryBoyDashboard.vue -->
<template>
  <div class="tracking-dashboard">
    <div class="header">
      <h2>Delivery Partner Tracking</h2>
      <div class="filters">
        <select v-model="selectedCity" @change="loadData" class="form-select">
          <option value="">All Cities</option>
          <option v-for="city in cities" :key="city.id" :value="city.id">
            {{ city.name }}
          </option>
        </select>

        <select v-model="selectedStatus" @change="loadData" class="form-select">
          <option value="">All Status</option>
          <option value="online">Online</option>
          <option value="offline">Offline</option>
        </select>

        <button @click="exportReport" class="btn-secondary">
          <i class="fas fa-download"></i> Export
        </button>
      </div>
    </div>

    <!-- Stats Cards -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon online">
          <i class="fas fa-user-check"></i>
        </div>
        <div class="stat-content">
          <div class="stat-value">{{ stats.online_count }}</div>
          <div class="stat-label">Online Now</div>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon earnings">
          <i class="fas fa-rupee-sign"></i>
        </div>
        <div class="stat-content">
          <div class="stat-value">₹{{ stats.total_earnings_today }}</div>
          <div class="stat-label">Total Earnings Today</div>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon gigs">
          <i class="fas fa-clipboard-check"></i>
        </div>
        <div class="stat-content">
          <div class="stat-value">{{ stats.gigs_completed_today }}</div>
          <div class="stat-label">Gigs Completed Today</div>
        </div>
      </div>

      <div class="stat-card">
        <div class="stat-icon distance">
          <i class="fas fa-route"></i>
        </div>
        <div class="stat-content">
          <div class="stat-value">{{ stats.total_distance_today }} km</div>
          <div class="stat-label">Distance Traveled</div>
        </div>
      </div>
    </div>

    <!-- Delivery Boys Table -->
    <div class="card">
      <table class="data-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Phone</th>
            <th>City</th>
            <th>Status</th>
            <th>Login Hours</th>
            <th>Earnings</th>
            <th>Gigs</th>
            <th>Distance</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="db in deliveryBoys" :key="db.id">
            <td>
              <div class="name-cell">
                <img :src="db.profile_image_url || '/default-avatar.png'" class="avatar" />
                <strong>{{ db.name }}</strong>
              </div>
            </td>
            <td>{{ db.phone }}</td>
            <td>{{ db.city_name }}</td>
            <td>
              <span :class="['badge', db.online_status == 'online' ? 'badge-success' : 'badge-secondary']">
                <span class="status-dot"></span>
                {{ db.online_status }}
              </span>
            </td>
            <td>
              <span class="login-time">{{ db.login_display_time }}</span>
            </td>
            <td>₹{{ db.total_earnings_today }}</td>
            <td>{{ db.gigs_completed_today }}</td>
            <td>{{ db.total_distance_today }} km</td>
            <td>
              <button @click="viewDetails(db)" class="btn-sm btn-info">
                <i class="fas fa-eye"></i> Details
              </button>
              <button
                v-if="db.online_status == 'online'"
                @click="viewOnMap(db)"
                class="btn-sm btn-success"
              >
                <i class="fas fa-map-marker-alt"></i> Map
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      deliveryBoys: [],
      stats: {
        online_count: 0,
        total_earnings_today: 0,
        gigs_completed_today: 0,
        total_distance_today: 0,
      },
      cities: [],
      selectedCity: '',
      selectedStatus: '',
      loading: false,
    };
  },

  mounted() {
    this.loadCities();
    this.loadData();
    this.startAutoRefresh();
  },

  beforeDestroy() {
    this.stopAutoRefresh();
  },

  methods: {
    async loadCities() {
      try {
        const response = await axios.get('/api/admin/cities');
        this.cities = response.data.data.cities;
      } catch (error) {
        console.error('Failed to load cities:', error);
      }
    },

    async loadData() {
      this.loading = true;
      try {
        const response = await axios.get('/api/admin/delivery-boys/tracking', {
          params: {
            city_id: this.selectedCity,
            status: this.selectedStatus,
          },
        });

        this.deliveryBoys = response.data.data.delivery_boys;
        this.stats = response.data.data.stats;
      } catch (error) {
        this.$swal.fire('Error', 'Failed to load data', 'error');
      }
      this.loading = false;
    },

    startAutoRefresh() {
      this.refreshInterval = setInterval(() => {
        this.loadData();
      }, 60000); // Refresh every 1 minute
    },

    stopAutoRefresh() {
      if (this.refreshInterval) {
        clearInterval(this.refreshInterval);
      }
    },

    viewDetails(deliveryBoy) {
      this.$router.push(`/admin/delivery-boys/${deliveryBoy.id}/tracking`);
    },

    viewOnMap(deliveryBoy) {
      this.$router.push(`/admin/tracking/map?delivery_boy_id=${deliveryBoy.id}`);
    },

    async exportReport() {
      try {
        const response = await axios.get('/api/admin/delivery-boys/tracking/export', {
          params: {
            city_id: this.selectedCity,
            status: this.selectedStatus,
          },
          responseType: 'blob',
        });

        const url = window.URL.createObjectURL(new Blob([response.data]));
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', `tracking_report_${moment().format('YYYY-MM-DD')}.xlsx`);
        document.body.appendChild(link);
        link.click();
        link.remove();
      } catch (error) {
        this.$swal.fire('Error', 'Failed to export report', 'error');
      }
    },
  },
};
</script>

<style scoped>
.tracking-dashboard {
  padding: 24px;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.filters {
  display: flex;
  gap: 12px;
}

.form-select {
  padding: 8px 16px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 24px;
  margin-bottom: 24px;
}

.stat-card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
}

.stat-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  color: white;
}

.stat-icon.online {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.stat-icon.earnings {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.stat-icon.gigs {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
}

.stat-icon.distance {
  background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
}

.stat-value {
  font-size: 32px;
  font-weight: 700;
  color: #333;
}

.stat-label {
  font-size: 14px;
  color: #666;
}

.name-cell {
  display: flex;
  align-items: center;
  gap: 12px;
}

.avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
}

.badge {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: currentColor;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.login-time {
  font-family: 'Courier New', monospace;
  font-weight: 600;
  color: #007bff;
}
</style>
```

---

### 4. Incentive Offers Management

**Features:**
- Create/edit offers
- Manage tiers
- View delivery boy progress
- Calculate payouts

```vue
<!-- OfferForm.vue -->
<template>
  <div class="offer-form">
    <div class="header">
      <h2>{{ offer.id ? 'Edit' : 'Create' }} Incentive Offer</h2>
    </div>

    <form @submit.prevent="saveOffer" class="card">
      <!-- Basic Info -->
      <div class="form-section">
        <h3>Basic Information</h3>

        <div class="form-group">
          <label>Offer Name *</label>
          <input
            v-model="offer.name"
            type="text"
            class="form-control"
            placeholder="e.g., Diwali Mega Bonus 2025"
            required
          />
        </div>

        <div class="form-group">
          <label>Description *</label>
          <textarea
            v-model="offer.description"
            class="form-control"
            rows="4"
            placeholder="Detailed description of the offer..."
            required
          ></textarea>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>Start Date *</label>
            <input v-model="offer.start_date" type="datetime-local" class="form-control" required />
          </div>

          <div class="form-group">
            <label>End Date *</label>
            <input v-model="offer.end_date" type="datetime-local" class="form-control" required />
          </div>
        </div>

        <div class="form-group">
          <label>Banner Image</label>
          <input type="file" @change="handleImageUpload" accept="image/*" class="form-control" />
          <img
            v-if="offer.banner_image_url"
            :src="offer.banner_image_url"
            class="preview-image"
            alt="Banner preview"
          />
        </div>
      </div>

      <!-- Eligibility Conditions -->
      <div class="form-section">
        <h3>Eligibility Conditions</h3>

        <div class="form-row">
          <div class="form-group">
            <label>Minimum Gigs Required *</label>
            <input
              v-model.number="offer.min_gigs_required"
              type="number"
              class="form-control"
              min="0"
              required
            />
            <small class="form-text">
              Out of total gigs in offer period, minimum gigs to complete
            </small>
          </div>

          <div class="form-group">
            <label>Max Gigs Can Skip</label>
            <input
              v-model.number="offer.max_gigs_skip"
              type="number"
              class="form-control"
              min="0"
            />
            <small class="form-text">Maximum number of gigs that can be skipped</small>
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label>Max Orders Can Cancel</label>
            <input
              v-model.number="offer.max_orders_cancel"
              type="number"
              class="form-control"
              min="0"
            />
          </div>

          <div class="form-group">
            <label>Login Mandatory</label>
            <div class="form-check">
              <input
                v-model="offer.login_mandatory"
                type="checkbox"
                class="form-check-input"
                id="loginMandatory"
              />
              <label class="form-check-label" for="loginMandatory">
                Require daily login compliance
              </label>
            </div>
          </div>
        </div>
      </div>

      <!-- Reward Tiers -->
      <div class="form-section">
        <h3>Reward Tiers</h3>
        <button type="button" @click="addTier" class="btn-secondary mb-3">
          <i class="fas fa-plus"></i> Add Tier
        </button>

        <div v-for="(tier, index) in offer.tiers" :key="index" class="tier-row">
          <div class="form-group">
            <label>Tier Name</label>
            <input
              v-model="tier.tier_name"
              type="text"
              class="form-control"
              placeholder="e.g., Bronze, Silver, Gold"
            />
          </div>

          <div class="form-group">
            <label>Earnings Target (₹)</label>
            <input
              v-model.number="tier.earnings_target"
              type="number"
              class="form-control"
              min="0"
              step="0.01"
            />
          </div>

          <div class="form-group">
            <label>Incentive Amount (₹)</label>
            <input
              v-model.number="tier.incentive_amount"
              type="number"
              class="form-control"
              min="0"
              step="0.01"
            />
          </div>

          <div class="form-group">
            <label>Order</label>
            <input
              v-model.number="tier.order_number"
              type="number"
              class="form-control"
              min="1"
            />
          </div>

          <button type="button" @click="removeTier(index)" class="btn-danger btn-sm">
            <i class="fas fa-trash"></i>
          </button>
        </div>
      </div>

      <!-- Actions -->
      <div class="form-actions">
        <button type="button" @click="$router.go(-1)" class="btn-secondary">Cancel</button>
        <button type="submit" class="btn-primary" :disabled="loading">
          <i class="fas fa-save"></i> {{ offer.id ? 'Update' : 'Create' }} Offer
        </button>
      </div>
    </form>
  </div>
</template>

<script>
export default {
  data() {
    return {
      offer: {
        name: '',
        description: '',
        start_date: '',
        end_date: '',
        banner_image: null,
        banner_image_url: null,
        min_gigs_required: 20,
        max_gigs_skip: 2,
        max_orders_cancel: 3,
        login_mandatory: true,
        status: 1,
        tiers: [
          { tier_name: 'Bronze', earnings_target: 500, incentive_amount: 100, order_number: 1 },
          { tier_name: 'Silver', earnings_target: 1000, incentive_amount: 250, order_number: 2 },
          { tier_name: 'Gold', earnings_target: 2000, incentive_amount: 600, order_number: 3 },
        ],
      },
      loading: false,
    };
  },

  mounted() {
    if (this.$route.params.id) {
      this.loadOffer();
    }
  },

  methods: {
    async loadOffer() {
      try {
        const response = await axios.get(`/api/admin/offers/${this.$route.params.id}`);
        this.offer = response.data.data.offer;
      } catch (error) {
        this.$swal.fire('Error', 'Failed to load offer', 'error');
      }
    },

    addTier() {
      const lastOrder = this.offer.tiers.length > 0
        ? Math.max(...this.offer.tiers.map(t => t.order_number))
        : 0;

      this.offer.tiers.push({
        tier_name: '',
        earnings_target: 0,
        incentive_amount: 0,
        order_number: lastOrder + 1,
      });
    },

    removeTier(index) {
      this.offer.tiers.splice(index, 1);
    },

    handleImageUpload(event) {
      const file = event.target.files[0];
      if (file) {
        this.offer.banner_image = file;
        this.offer.banner_image_url = URL.createObjectURL(file);
      }
    },

    async saveOffer() {
      this.loading = true;

      try {
        const formData = new FormData();

        // Append basic fields
        Object.keys(this.offer).forEach(key => {
          if (key !== 'tiers' && key !== 'banner_image_url') {
            formData.append(key, this.offer[key]);
          }
        });

        // Append tiers as JSON
        formData.append('tiers', JSON.stringify(this.offer.tiers));

        const url = this.offer.id
          ? `/api/admin/offers/${this.offer.id}`
          : '/api/admin/offers';

        const config = {
          headers: { 'Content-Type': 'multipart/form-data' },
        };

        if (this.offer.id) {
          formData.append('_method', 'PUT');
          await axios.post(url, formData, config);
        } else {
          await axios.post(url, formData, config);
        }

        this.$swal.fire('Success', 'Offer saved successfully', 'success');
        this.$router.push('/admin/offers');
      } catch (error) {
        this.$swal.fire('Error', 'Failed to save offer', 'error');
      }

      this.loading = false;
    },
  },
};
</script>

<style scoped>
.offer-form {
  padding: 24px;
  max-width: 1200px;
  margin: 0 auto;
}

.form-section {
  margin-bottom: 32px;
  padding-bottom: 32px;
  border-bottom: 1px solid #e0e0e0;
}

.form-section h3 {
  margin-bottom: 20px;
  color: #333;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 600;
  color: #555;
}

.form-control {
  width: 100%;
  padding: 10px 14px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 20px;
}

.preview-image {
  margin-top: 12px;
  max-width: 300px;
  border-radius: 8px;
}

.tier-row {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 100px 50px;
  gap: 12px;
  align-items: end;
  margin-bottom: 12px;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding-top: 24px;
}

.form-text {
  display: block;
  margin-top: 4px;
  font-size: 12px;
  color: #666;
}

.mb-3 {
  margin-bottom: 16px;
}
</style>
```

---

## 📊 Charts and Analytics

### Earnings Chart (Chart.js)
```vue
<!-- EarningsChart.vue -->
<template>
  <div class="earnings-chart">
    <canvas ref="chartCanvas"></canvas>
  </div>
</template>

<script>
import Chart from 'chart.js/auto';

export default {
  props: {
    data: {
      type: Array,
      required: true,
    },
  },

  mounted() {
    this.renderChart();
  },

  watch: {
    data() {
      this.renderChart();
    },
  },

  methods: {
    renderChart() {
      const ctx = this.$refs.chartCanvas.getContext('2d');

      if (this.chart) {
        this.chart.destroy();
      }

      this.chart = new Chart(ctx, {
        type: 'line',
        data: {
          labels: this.data.map(d => d.date),
          datasets: [
            {
              label: 'Earnings',
              data: this.data.map(d => d.earnings),
              borderColor: '#007bff',
              backgroundColor: 'rgba(0, 123, 255, 0.1)',
              tension: 0.4,
            },
          ],
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              display: true,
              position: 'top',
            },
          },
          scales: {
            y: {
              beginAtZero: true,
              ticks: {
                callback: value => '₹' + value,
              },
            },
          },
        },
      });
    },
  },

  beforeDestroy() {
    if (this.chart) {
      this.chart.destroy();
    }
  },
};
</script>
```

---

## 🔧 Required Dependencies

### package.json
```json
{
  "dependencies": {
    "vue": "^2.6.14",
    "vue-router": "^3.5.3",
    "axios": "^0.27.2",
    "chart.js": "^3.9.1",
    "moment": "^2.29.4",
    "sweetalert2": "^11.4.29",
    "@fortawesome/fontawesome-free": "^6.1.2"
  }
}
```

---

## ✅ Admin Panel Features Checklist

- [ ] Gigs CRUD operations
- [ ] Gig slots calendar view
- [ ] Bulk create slots (30/60/90 days)
- [ ] Edit slot capacity
- [ ] View delivery boy tracking
- [ ] Live map with active delivery boys
- [ ] Session history reports
- [ ] Create/edit incentive offers
- [ ] Manage reward tiers
- [ ] View delivery boy progress
- [ ] Calculate and export payouts
- [ ] Analytics dashboard with charts
- [ ] Export reports (Excel/PDF)

---

This guide provides a complete admin panel implementation. Customize the design to match your brand and add additional features as needed!
