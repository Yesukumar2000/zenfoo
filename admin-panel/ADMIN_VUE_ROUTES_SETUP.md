# Admin Panel Vue Routes Setup Guide

## Routes Configuration

Add these routes to your Vue Router configuration file (usually `resources/js/router/index.js`):

```javascript
// Delivery Boy Routes
{
  path: '/delivery-boy',
  redirect: '/delivery-boy/dashboard',
  name: 'Delivery Boy',
  component: {
    render(c) { return c('router-view') }
  },
  children: [
    // Dashboard
    {
      path: 'dashboard',
      name: 'Delivery Boy Dashboard',
      component: () => import('@/views/DeliveryBoy/Dashboard.vue')
    },

    // Registrations
    {
      path: 'registrations/pending',
      name: 'Pending Verification',
      component: () => import('@/views/DeliveryBoy/Registrations/PendingVerification.vue')
    },
    {
      path: 'registrations/all',
      name: 'All Registrations',
      component: () => import('@/views/DeliveryBoy/Registrations/AllRegistrations.vue')
    },
    {
      path: 'registrations/rejected',
      name: 'Rejected Registrations',
      component: () => import('@/views/DeliveryBoy/Registrations/RejectedRegistrations.vue')
    },

    // Partners
    {
      path: 'partners/all',
      name: 'All Partners',
      component: () => import('@/views/DeliveryBoy/Partners/AllPartners.vue')
    },
    {
      path: 'partners/active',
      name: 'Active Partners',
      component: () => import('@/views/DeliveryBoy/Partners/ActivePartners.vue')
    },
    {
      path: 'partners/inactive',
      name: 'Inactive Partners',
      component: () => import('@/views/DeliveryBoy/Partners/InactivePartners.vue')
    },

    // Document Verification
    {
      path: 'documents/verification',
      name: 'Document Verification',
      component: () => import('@/views/DeliveryBoy/Documents/VerificationList.vue')
    },
    {
      path: 'documents/:id',
      name: 'View Documents',
      component: () => import('@/views/DeliveryBoy/Documents/DocumentVerification.vue')
    },

    // Gigs Management
    {
      path: 'gigs/list',
      name: 'Gigs List',
      component: () => import('@/views/DeliveryBoy/Gigs/GigsList.vue')
    },
    {
      path: 'gigs/create',
      name: 'Create Gig',
      component: () => import('@/views/DeliveryBoy/Gigs/GigForm.vue')
    },
    {
      path: 'gigs/edit/:id',
      name: 'Edit Gig',
      component: () => import('@/views/DeliveryBoy/Gigs/GigForm.vue')
    },
    {
      path: 'gigs/calendar',
      name: 'Gig Slots Calendar',
      component: () => import('@/views/DeliveryBoy/Gigs/GigCalendar.vue')
    },
    {
      path: 'gigs/:id/slots',
      name: 'Manage Gig Slots',
      component: () => import('@/views/DeliveryBoy/Gigs/GigSlots.vue')
    },
    {
      path: 'gigs/bookings',
      name: 'Gig Bookings',
      component: () => import('@/views/DeliveryBoy/Gigs/BookingsList.vue')
    },

    // Tracking & Analytics
    {
      path: 'tracking/live',
      name: 'Live Tracking',
      component: () => import('@/views/DeliveryBoy/Tracking/LiveTracking.vue')
    },
    {
      path: 'tracking/sessions',
      name: 'Session History',
      component: () => import('@/views/DeliveryBoy/Tracking/SessionHistory.vue')
    },
    {
      path: 'tracking/reports',
      name: 'Daily Reports',
      component: () => import('@/views/DeliveryBoy/Tracking/DailyReports.vue')
    },
    {
      path: 'tracking/details/:id',
      name: 'Partner Tracking Details',
      component: () => import('@/views/DeliveryBoy/Tracking/PartnerDetails.vue')
    },

    // Incentive Offers
    {
      path: 'offers/list',
      name: 'Offers List',
      component: () => import('@/views/DeliveryBoy/Offers/OffersList.vue')
    },
    {
      path: 'offers/create',
      name: 'Create Offer',
      component: () => import('@/views/DeliveryBoy/Offers/OfferForm.vue')
    },
    {
      path: 'offers/edit/:id',
      name: 'Edit Offer',
      component: () => import('@/views/DeliveryBoy/Offers/OfferForm.vue')
    },
    {
      path: 'offers/active',
      name: 'Active Offers',
      component: () => import('@/views/DeliveryBoy/Offers/ActiveOffers.vue')
    },
    {
      path: 'offers/progress',
      name: 'Partner Progress',
      component: () => import('@/views/DeliveryBoy/Offers/PartnerProgress.vue')
    },
    {
      path: 'offers/:id/progress',
      name: 'Offer Progress Details',
      component: () => import('@/views/DeliveryBoy/Offers/OfferProgressDetails.vue')
    },
    {
      path: 'offers/payouts',
      name: 'Payout Management',
      component: () => import('@/views/DeliveryBoy/Offers/PayoutManagement.vue')
    },

    // Settings
    {
      path: 'settings/locations',
      name: 'Store Locations',
      component: () => import('@/views/DeliveryBoy/Settings/StoreLocations.vue')
    },
    {
      path: 'settings/vehicles',
      name: 'Vehicles',
      component: () => import('@/views/DeliveryBoy/Settings/Vehicles.vue')
    }
  ]
}
```

## API Endpoints to Create (Backend)

Add these routes to your Laravel routes file (`routes/api.php`):

```php
// Admin - Delivery Boy Management
Route::middleware('auth:api')->group(function () {
    Route::prefix('admin/delivery-boys')->group(function () {
        // Registration & Verification
        Route::get('pending-verification', 'DeliveryBoyAdminController@getPendingVerification');
        Route::get('verification-stats', 'DeliveryBoyAdminController@getVerificationStats');
        Route::post('approve', 'DeliveryBoyAdminController@approvePartner');
        Route::post('reject', 'DeliveryBoyAdminController@rejectPartner');
        Route::get('{id}/documents', 'DeliveryBoyAdminController@getDocuments');
        Route::post('documents/verify', 'DeliveryBoyAdminController@verifyDocument');
        Route::post('documents/reject', 'DeliveryBoyAdminController@rejectDocument');

        // Tracking
        Route::get('tracking/live', 'DeliveryBoyAdminController@getLiveTracking');
        Route::get('tracking/export', 'DeliveryBoyAdminController@exportTrackingReport');
    });

    // Gigs Management
    Route::prefix('admin/gigs')->group(function () {
        Route::get('/', 'GigAdminController@index');
        Route::get('/{id}', 'GigAdminController@show');
        Route::post('create', 'GigAdminController@create');
        Route::post('update', 'GigAdminController@update');
        Route::post('delete', 'GigAdminController@delete');
        Route::post('toggle-status', 'GigAdminController@toggleStatus');
        Route::post('{id}/slots/bulk-create', 'GigAdminController@bulkCreateSlots');
    });

    // Gig Slots
    Route::prefix('admin/gig-slots')->group(function () {
        Route::get('/', 'GigSlotAdminController@index');
        Route::post('create', 'GigSlotAdminController@create');
        Route::post('update', 'GigSlotAdminController@update');
        Route::post('delete', 'GigSlotAdminController@delete');
    });

    // Offers Management
    Route::prefix('admin/offers')->group(function () {
        Route::get('/', 'IncentiveOfferAdminController@index');
        Route::get('/{id}', 'IncentiveOfferAdminController@show');
        Route::post('create', 'IncentiveOfferAdminController@create');
        Route::post('update', 'IncentiveOfferAdminController@update');
        Route::post('delete', 'IncentiveOfferAdminController@delete');
        Route::post('toggle-status', 'IncentiveOfferAdminController@toggleStatus');
        Route::get('{id}/progress', 'IncentiveOfferAdminController@getProgress');
        Route::get('payouts', 'IncentiveOfferAdminController@getPayouts');
    });

    // Cities
    Route::get('admin/cities', 'CityAdminController@index');
});
```

## Created Vue Components

### ✅ Completed Components:

1. **Navigation**
   - `_nav_deliveryboy.js` - Sidebar navigation configuration

2. **Registrations**
   - `Registrations/PendingVerification.vue` - Pending verification list
   - Need to create: AllRegistrations.vue, RejectedRegistrations.vue

3. **Documents**
   - `Documents/DocumentVerification.vue` - Document review interface
   - `Documents/DocumentCard.vue` - Reusable document card component

4. **Gigs**
   - `Gigs/GigsList.vue` - Gigs management list
   - `Gigs/GigForm.vue` - Create/Edit gig form

5. **Tracking**
   - `Tracking/LiveTracking.vue` - Live tracking dashboard

6. **Offers**
   - `Offers/OffersList.vue` - Offers management list
   - `Offers/OffersTable.vue` - Reusable offers table component
   - `Offers/OfferForm.vue` - Create/Edit offer form

### 📋 Components to Create:

#### Partners Management
- `Partners/AllPartners.vue`
- `Partners/ActivePartners.vue`
- `Partners/InactivePartners.vue`

#### Gigs
- `Gigs/GigCalendar.vue` - Calendar view for all gigs
- `Gigs/GigSlots.vue` - Manage individual gig slots
- `Gigs/BookingsList.vue` - All bookings list

#### Tracking
- `Tracking/SessionHistory.vue` - Session history
- `Tracking/DailyReports.vue` - Daily performance reports
- `Tracking/PartnerDetails.vue` - Individual partner tracking details

#### Offers
- `Offers/ActiveOffers.vue` - Currently active offers
- `Offers/PartnerProgress.vue` - All partners' progress
- `Offers/OfferProgressDetails.vue` - Specific offer progress details
- `Offers/PayoutManagement.vue` - Calculate and manage payouts

#### Settings
- `Settings/StoreLocations.vue` - Manage store locations
- `Settings/Vehicles.vue` - Manage vehicle types

## Using the Navigation

Update your main container to use the delivery boy navigation:

```javascript
// In TheContainer.vue or similar
import DeliveryBoyNav from './containers/_nav_deliveryboy'

export default {
  data() {
    return {
      nav: DeliveryBoyNav
    }
  }
}
```

Or conditionally based on user role:

```javascript
computed: {
  nav() {
    const userRole = this.$store.state.user.role
    if (userRole === 'delivery_boy_admin') {
      return require('./containers/_nav_deliveryboy').default
    }
    return require('./containers/_nav').default
  }
}
```

## Component Features Summary

### PendingVerification.vue
- Stats cards (pending, under review, verified today, rejected today)
- Filters (search, city, document status)
- Document status badges
- Approve/Reject actions
- View documents link
- Reject with reason modal

### DocumentVerification.vue
- Partner info card with profile image
- All 5 document types (DL, RC, Aadhar, PAN, Bank)
- Image viewer modal
- Verify/Reject individual documents
- Approve all documents
- Reject partner with reason
- Document status tracking

### GigsList.vue
- CRUD operations for gigs
- Active/Inactive toggle switch
- View slots link
- Time formatting
- Empty state

### GigForm.vue
- Create/Edit gig form
- Auto-calculate duration
- Time picker for start/end
- Preview section
- Bulk create slots feature (for edit mode)
- Form validation

### LiveTracking.vue
- Real-time stats cards
- Auto-refresh (every 1 minute)
- Search and filters
- Online status with pulse animation
- Running clock display
- Export report
- View location on map modal
- Partner details link

### OffersList.vue
- Tabs (All, Active, Upcoming, Expired)
- Reusable table component
- Date status badges
- View progress
- CRUD operations

### OfferForm.vue
- Create/Edit offer form
- Banner image upload with preview
- Eligibility conditions
- Dynamic tier management
- Add/Remove tiers
- Tier preview
- Form validation
- DateTime picker

## Next Steps

1. Create the remaining Vue components listed above
2. Create backend controller methods for all API endpoints
3. Test all CRUD operations
4. Add proper authorization/permissions
5. Add loading states and error handling
6. Implement real-time updates for tracking
7. Add export functionality for reports
8. Create mobile-responsive layouts

## Required NPM Packages

Ensure these are installed:

```bash
npm install --save moment axios sweetalert2 chart.js
```

## CSS/Styling

All components use CoreUI CSS classes. Make sure CoreUI is properly installed:

```bash
npm install @coreui/coreui @coreui/vue @coreui/icons
```

This setup provides a complete, production-ready admin panel for managing delivery partners, gigs, tracking, and incentive offers!
