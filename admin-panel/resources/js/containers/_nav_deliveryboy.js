export default [
  {
    _name: 'CSidebarNav',
    _children: [
      {
        _name: 'CSidebarNavItem',
        name: 'Dashboard',
        to: '/delivery-boy/dashboard',
        icon: 'cil-speedometer',
      },
      {
        _name: 'CSidebarNavTitle',
        _children: ['Delivery Partner Management']
      },
      {
        _name: 'CSidebarNavDropdown',
        name: 'Registrations',
        route: '/delivery-boy/registrations',
        icon: 'cil-user-plus',
        items: [
          {
            name: 'Pending Verification',
            to: '/delivery-boy/registrations/pending',
            icon: 'cil-clock',
            badge: {
              color: 'warning',
              text: 'NEW'
            }
          },
          {
            name: 'All Registrations',
            to: '/delivery-boy/registrations/all',
            icon: 'cil-list'
          },
          {
            name: 'Rejected',
            to: '/delivery-boy/registrations/rejected',
            icon: 'cil-x-circle'
          }
        ]
      },
      {
        _name: 'CSidebarNavDropdown',
        name: 'Partners',
        route: '/delivery-boy/partners',
        icon: 'cil-people',
        items: [
          {
            name: 'All Partners',
            to: '/delivery-boy/partners/all',
            icon: 'cil-user'
          },
          {
            name: 'Active Partners',
            to: '/delivery-boy/partners/active',
            icon: 'cil-check-circle'
          },
          {
            name: 'Inactive Partners',
            to: '/delivery-boy/partners/inactive',
            icon: 'cil-ban'
          }
        ]
      },
      {
        _name: 'CSidebarNavItem',
        name: 'Document Verification',
        to: '/delivery-boy/documents/verification',
        icon: 'cil-file',
        badge: {
          color: 'danger',
          text: 'PENDING'
        }
      },
      {
        _name: 'CSidebarNavTitle',
        _children: ['Gig Management']
      },
      {
        _name: 'CSidebarNavDropdown',
        name: 'Gigs',
        route: '/delivery-boy/gigs',
        icon: 'cil-briefcase',
        items: [
          {
            name: 'All Gigs',
            to: '/delivery-boy/gigs/list',
            icon: 'cil-list'
          },
          {
            name: 'Create Gig',
            to: '/delivery-boy/gigs/create',
            icon: 'cil-plus'
          },
          {
            name: 'Gig Slots Calendar',
            to: '/delivery-boy/gigs/calendar',
            icon: 'cil-calendar'
          }
        ]
      },
      {
        _name: 'CSidebarNavItem',
        name: 'Bookings',
        to: '/delivery-boy/gigs/bookings',
        icon: 'cil-bookmark'
      },
      {
        _name: 'CSidebarNavTitle',
        _children: ['Tracking & Analytics']
      },
      {
        _name: 'CSidebarNavItem',
        name: 'Live Tracking',
        to: '/delivery-boy/tracking/live',
        icon: 'cil-location-pin',
        badge: {
          color: 'success',
          text: 'LIVE'
        }
      },
      {
        _name: 'CSidebarNavItem',
        name: 'Session History',
        to: '/delivery-boy/tracking/sessions',
        icon: 'cil-history'
      },
      {
        _name: 'CSidebarNavItem',
        name: 'Daily Reports',
        to: '/delivery-boy/tracking/reports',
        icon: 'cil-chart-line'
      },
      {
        _name: 'CSidebarNavTitle',
        _children: ['Incentives']
      },
      {
        _name: 'CSidebarNavDropdown',
        name: 'Offers',
        route: '/delivery-boy/offers',
        icon: 'cil-gift',
        items: [
          {
            name: 'All Offers',
            to: '/delivery-boy/offers/list',
            icon: 'cil-list'
          },
          {
            name: 'Create Offer',
            to: '/delivery-boy/offers/create',
            icon: 'cil-plus'
          },
          {
            name: 'Active Offers',
            to: '/delivery-boy/offers/active',
            icon: 'cil-star'
          }
        ]
      },
      {
        _name: 'CSidebarNavItem',
        name: 'Partner Progress',
        to: '/delivery-boy/offers/progress',
        icon: 'cil-chart-pie'
      },
      {
        _name: 'CSidebarNavItem',
        name: 'Payout Management',
        to: '/delivery-boy/offers/payouts',
        icon: 'cil-dollar'
      },
      {
        _name: 'CSidebarNavDivider',
        _class: 'm-2'
      },
      {
        _name: 'CSidebarNavTitle',
        _children: ['Settings']
      },
      {
        _name: 'CSidebarNavItem',
        name: 'Store Locations',
        to: '/delivery-boy/settings/locations',
        icon: 'cil-home'
      },
      {
        _name: 'CSidebarNavItem',
        name: 'Vehicles',
        to: '/delivery-boy/settings/vehicles',
        icon: 'cil-truck'
      }
    ]
  }
]
