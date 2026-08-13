<template>
    <div id="app">
        <div id="sidebar" class="active">
            <div class="sidebar-wrapper active">
                <div class="sidebar-header">

                    <div class="d-flex flex-row justify-content-center align-items-center position-relative">
                        <div class="logo">
                            <router-link to="/" class="d-flex flex-column align-items-center justify-content-center align-content-center flex-wrap ">
                                <img class="container-logo" v-if="$appLogo != ''" :src="$storageUrl+$appLogo" alt='Logo' srcset=""/>
                                <img class="container-logo" v-else :src="$baseUrl + '/images/logo.png'" alt='Logo' srcset=""/>

                            </router-link>
                        </div>
                        <div class="toggler position-absolute" style="right: 1rem;">
                            <a href="javascript:void(0)" class="sidebar-hide d-xl-none d-block"><i class="bi bi-x bi-middle"></i></a>
                        </div>
                    </div>
                </div>
                <div class="sidebar-menu">
                    <ul class="menu">

                        <li class="sidebar-item sidebar-search">
                            <b-form-input v-model="search" type="search" :placeholder="__('search')"
                                          v-on:keyup="filterItem" v-on:search="filterItem"></b-form-input>
                        </li>


                        <template v-for="item in filteredSidebarItems">
                            <!-- Sidebar Heading (non-clickable) - Only show if user has permission to see items in this section -->
                            <li v-if="item.isHeading && shouldShowHeading(item)" class="sidebar-title" :key="item.name">
                                {{ item.name }}
                            </li>

                            <!-- Sidebar Divider -->
                            <li v-else-if="item.isDivider" class="sidebar-divider" :key="'divider-' + Math.random()">
                                <hr>
                            </li>

                            <!-- Regular sidebar items -->
                            <li v-else class="sidebar-item" :class="{ 'active' : isActive(item.url) || subIsActive(item), 'has-sub' : isHasSub(item) }"
                                v-if=" item.role==true ? ($role('Super Admin') && (item.name=='Role' || item.name=='System Users')) : (item.permission && $can(item.permission)) || (item.permission === null && isHasSub(item) && hasAnySubmenuPermission(item))">

                                <template v-if="isHasSub(item)">
                                    <a class="sidebar-link">
                                        <i :class="`fa fa-${item.icon}`"></i>
                                        <!-- <span>{{ item.name }}</span> -->
                                        <span style="font-weight: 400; font-style: bold;">{{ item.name }}</span>
                                    </a>
                                    <ul class="submenu" :class="{ 'active' : subIsActive(item) } ">
                                        <template v-for="sub in item.submenu">
                                            <li class="submenu-item" :class="{ 'active' : isActive(sub.url) } " :key="sub.key"
                                             v-if="sub.role ? $role('Super Admin') && (item.name === 'Role' || item.name === 'System Users') : sub.permission && $can(sub.permission)">
                                                <router-link :to="sub.url" @click="closeSideBarMenu()" class="d-flex justify-content-between align-items-center">
                                                    <span style="font-weight: 400; font-style: bold;">{{ sub.name }}</span>
                                                    <span v-if="item.name === 'Orders' && (sub.url === '/orders' || sub.url.includes('status_id='))" class="order-count-badge">
                                                        {{ getOrderCount(sub.url) }}
                                                    </span>
                                                </router-link>
                                            </li>
                                        </template>


                                    </ul>
                                </template>

                                <template v-else>
                                    <router-link class="sidebar-link" :to="item.url" @click="closeSideBarMenu()">
                                        <i :class="`fa fa-${item.icon}`"></i>
                                        <!-- <span>{{ item.name }}</span> -->
                                        <span style="font-weight: 400; font-style: bold;">{{ item.name }}</span>
                                    </router-link>
                                </template>

                            </li>
                        </template>
                        <template v-for="item in filteredDatabaseDownloadBtn">
                            <div v-if=" item.role==true ? ($role('Super Admin') && (item.name=='Role' || item.name=='System Users')) : (item.permission && $can(item.permission) )">
                                <button class="btn btn-primary" @click="downloadDatabase"><i :class="`fa fa-download`"></i><b-spinner v-if="isLoading" small label="Spinning"></b-spinner> Download Database</button>
                            </div>
                        </template>
                    </ul>
                </div>
                <button class="sidebar-toggler btn x"><i data-feather="x"></i></button>
            </div>
        </div>
        <vertical-header></vertical-header>
        <div id="main">
            <div>
                <router-view></router-view>
            </div>
            <the-footer></the-footer>
        </div>
    </div>
</template>
<script>
import TheSidebar from './TheSidebar'
import TheFooter from './TheFooter'
import VerticalHeader from './VerticalHeader'
import Auth from "../Auth";
import axios from "axios";

export default {
    name: 'TheContainer',
    components: {
        TheSidebar,
        TheFooter,
        VerticalHeader
    },
    created() {
        // this.updateCurrency(window.localStorage.getItem('currency'));
        this.closeSideBarMenu();
        this.checkPermissions();
        this.fetchOrderStatusCounts();
    },
    watch: {
        '$route': 'checkPermissions'
    },
    mounted() {
        //lang
        if(window.localStorage.getItem('lang')){
            this.lang = window.localStorage.getItem('lang');
            console.log(this.lang);
        }

        // Initialize FCM for push notifications when dashboard loads
        // This ensures service worker is registered even after page refresh
        if (window.initFCM) {
            console.log('[TheContainer] Initializing FCM on mount...');
            window.initFCM();
        }

        // Initialize sidebar click handlers
        this.initializeSidebarClickHandlers();
        window.addEventListener('DOMContentLoaded', (event) => {
            var w = window.innerWidth;
            if(w < 1200) {
                document.getElementById('sidebar')?.classList?.remove('active');
            }
        });
        window.addEventListener('resize', (event) => {
            var w = window.innerWidth;
            if(w < 1200) {
                document.getElementById('sidebar')?.classList?.remove('active');
            }else{
                document.getElementById('sidebar')?.classList?.add('active');
            }
        });
        document.querySelector('.burger-btn').addEventListener('click', () => {
            document.getElementById('sidebar')?.classList?.toggle('active');
        })
        document.querySelector('.sidebar-hide').addEventListener('click', () => {
            document.getElementById('sidebar')?.classList?.toggle('active');
        })
        // Perfect Scrollbar Init
        if(typeof PerfectScrollbar.default == 'function') {
            const container = document.querySelector(".sidebar-wrapper");
            const ps = new PerfectScrollbar.default(container, {
                wheelPropagation: false
            });
        }

        // Scroll into active sidebar
        if(document.querySelector('.sidebar-item.active')){
            document.querySelector('.sidebar-item.active').scrollIntoView(false)
        }


    },
    data: function() {
        return {
           lang: 'en',
            search: '',
            isLoading: false,
            suspecious: null,
            orderStatusCounts: {
                all: 0,
                payment_pending: 0,
                received: 0,
                processed: 0,
                // shipped: 0,
                out_for_delivery: 0,
                delivered: 0,
                cancelled: 0,
                returned: 0
            },
            sidebarItems :[
                {
                    name: __('dashboard'),
                    icon : 'tachometer-alt',
                    url:'/dashboard',
                    permission:'manage_dashboard'
                },
                {
                    name: 'Order Management',
                    isHeading: true,
                    permission: 'product_list'
                },
                // {
                //     name: __('orders'),
                //     icon :'shopping-cart',
                //     url:'/orders',
                //     permission:'order_list'
                // },
                {
                    name: "Orders",
                    icon: "shopping-cart",
                    permission: "order_list",
                    submenu: [
                        {
                            name: "All",
                            icon: "shopping-cart",
                            url: "/orders",
                            permission: "order_list"
                        },
                        {
                            name: "Stuck Orders (No GPS)",
                            icon: "shopping-cart",
                            url: "/orders/stuck",
                            permission: "order_list"
                        },

                        // {
                        //     name: "Payment Pending",
                        //     icon: "grid-fill",
                        //     url: "/orders?status_id=1",
                        //     permission: "order_list"
                        // },
                        {
                            name: "Received",
                            icon: "grid-fill",
                            url: "/orders?status_id=2",
                            permission: "order_list"
                        },
                        {
                            name: "Processed",
                            icon: "grid-fill",
                            url: "/orders?status_id=3",
                            permission: "order_list"
                        },
                        // {
                        //     name: "Shipped",
                        //     icon: "grid-fill",
                        //     url: "/orders?status_id=4",
                        //     permission: "order_list"
                        // },
                        {
                            name: "Out For Delivery",
                            icon: "grid-fill",
                            url: "/orders?status_id=5",
                            permission: "order_list"
                        },
                        {
                            name: "Delivered",
                            icon: "grid-fill",
                            url: "/orders?status_id=6",
                            permission: "order_list"
                        },
                        {
                            name: "Cancelled",
                            icon: "grid-fill",
                            url: "/orders?status_id=7",
                            permission: "order_list"
                        },
                        {
                            name: "Returned",
                            icon: "grid-fill",
                            url: "/orders?status_id=8",
                            permission: "order_list"
                        }
                    ]
                },
                {
                    name: "Pre Orders",
                    icon: "calendar-check",
                    permission: "order_list",
                    submenu: [
                        // {
                        //     name: "All Pre Orders",
                        //     icon: "calendar-check",
                        //     url: "/preorders",
                        //     permission: "order_list"
                        // },
                        {
                            name: "Pending",
                            icon: "clock",
                            url: "/preorders?status=12",
                            permission: "order_list"
                        },
                        {
                            name: "Processed",
                            icon: "check-circle",
                            url: "/preorders?status=2",
                            permission: "order_list"
                        }
                    ]
                },
                {
                    name: "Pre Order Items",
                    icon: "list-ul",
                    url: "/preorder-items",
                    permission: "order_list"
                },

                {
                    name: 'Analytics',
                    isHeading: true,
                    permission: 'order_list'
                },
                {
                    name: "Order Analytics",
                    icon: "chart-bar",
                    url: "/order-analytics",
                    permission: "order_list"
                },
                {
                    name: "Profit / Loss",
                    icon: "chart-line",
                    url: "/profit-loss",
                    permission: "order_list"
                },
                {
                    name: "User Analytics",
                    icon: "users",
                    url: "/user-analytics",
                    permission: "order_list"
                },
                {
                    name: "Merchant Analytics",
                    icon: "store",
                    url: "/merchant-analytics",
                    permission: "seller_list"
                },
                {
                    name: "Refunds & Disputes",
                    icon: "hand-holding-usd",
                    url: "/refunds-disputes",
                    permission: "order_list"
                },
                {
                    name: "Payouts & Settlement",
                    icon: "money-check-alt",
                    url: "/payouts-settlement",
                    permission: "order_list"
                },

                //{
                //    name: "Delivery Boy Analytics",
                //    icon: "chart-bar",
                //    url: "/delivery-boy-analytics",
                //    permission: "order_list"
                //},

                // {
                //     name: __('return_requests'),
                //     icon : 'retweet',
                //     url:'/return_requests',
                //     permission:'return_request_list',
                // },

                // {
                //     isDivider: true,
                //     permission: null
                // },


                // {
                //     name: __('self_pickup_orders'),
                //     icon :'box-open',
                //     url:'/self_pickup_orders',
                //     permission:'self_pickup_order_list'
                // },

                {
                    name: 'Seller Management',
                    isHeading: true,
                    permission: 'product_list'
                },

                {
                    name: __('sellers'),
                    icon: 'male',
                    permission:'seller_list',
                    submenu: [
                        {
                            name: __('add_seller'),
                            icon : 'grid-fill',
                            url:'/sellers/create',
                            permission:'seller_create',
                        },
                        {
                            name: __('seller_requests'),
                            icon : 'grid-fill',
                            url:'/registered_sellers',
                            permission:'seller_requests',
                        },
                        {
                            name: __('manage_sellers'),
                            icon : 'grid-fill',
                            url:'/sellers',
                            permission:'seller_list',
                        },
                        {
                            name: 'Seller Pending Payouts',
                            icon : 'grid-fill',
                            url:'/seller-pending-payouts',
                            permission:'seller_list',
                        },
                        // {
                        //     name: __('seller_commissions'),
                        //     icon : 'grid-fill',
                        //     url:'/seller_commissions',
                        //     permission:'seller_list',
                        // },

                    ],
                },

                // {
                //     name: __('seller_wallet_transactions'),
                //     icon : 'dollar',
                //     url:'/seller_wallet_transactions',
                //     permission:'seller_wallet_transactions',
                // },
                {
                    name: __('policies_seller'),
                    icon : 'lock',
                    url:'/privacy_policy_seller',
                    permission:'manage_privacy_policy_seller_app',
                },

                
                {
                    name: 'Driver Management',
                    isHeading: true,
                    permission: 'product_list'
                },

                {
                    name: __('delivery_boys'),
                    icon : 'male',
                    permission:'delivery_boy_list',
                    submenu: [
                        {
                            name: __('add_delivery_boy'),
                            icon : 'grid-fill',
                            url:'/delivery_boys/create',
                            permission:'delivery_boy_create',
                        },

                        {
                            name: __('manage_delivery_boys'),
                            icon : 'grid-fill',
                            url:'/delivery_boys',
                            permission:'delivery_boy_list',
                        },

                        {
                            name: __('dlivery_boy_requests'),
                            icon : 'grid-fill',
                            url:'/registered_delivery_boys',
                            permission:'delivery_boy_list',
                        },

                        {
                            name: 'Problematic Drivers',
                            icon : 'grid-fill',
                            url:'/delivery_boys/problematic',
                            permission:'delivery_boy_list',
                        },

                        {
                            name: 'Pending Payouts',
                            icon : 'grid-fill',
                            url:'/delivery_boys/pending-payouts',
                            permission:'delivery_boy_list',
                        },

                        {
                            name: 'Manual Payments',
                            icon : 'money',
                            url:'/delivery_boys/manual-payments',
                            permission:'delivery_boy_list',
                        },

                    ]
                },

                // {
                //     name: __('delivery_boy_cash'),
                //     icon : 'money',
                //     url:'/cash_collection',
                //     permission:'cash_collection_list',
                // },

                {
                    name: __('delivery_boy_policies'),
                    icon : 'file-text',
                    url:'/privacy_policy_delivery_boy',
                    permission:'manage_privacy_policy_delivery_boy',
                },

                // {
                //     name: __('fund_transfers'),
                //     icon : 'random',
                //     url:'/fund_transfers',
                //     permission:'fund_transfers_list',
                // },


                // Delivery Boy Gig System
                {
                    name: 'Gig Management',
                    isHeading: true,
                    permission: 'gig_list'
                },

                {
                    name: 'Gigs',
                    icon: 'briefcase',
                    permission: 'gig_list',
                    submenu: [
                        {
                            name: 'All Gigs',
                            icon: 'list',
                            url: '/delivery-boy/gigs/list',
                            permission: 'gig_list',
                        },
                        // {
                        //     name: 'Create Gig',
                        //     icon: 'plus',
                        //     url: '/delivery-boy/gigs/create',
                        //     permission: 'gig_create',
                        // },
                        // {
                        //     name: 'Gig Calendar',
                        //     icon: 'calendar',
                        //     url: '/delivery-boy/gigs/calendar',
                        //     permission: 'gig_calendar_view',
                        // },
                    ]
                },

                // {
                //     name: 'Bookings',
                //     icon: 'bookmark',
                //     url: '/delivery-boy/gigs/bookings',
                //     permission: 'gig_booking_list',
                // },

                {
                    name: 'Tracking & Analytics',
                    isHeading: true,
                    permission: 'live_tracking_view'
                },

                {
                    name: 'Live Tracking',
                    icon: 'map-marker-alt',
                    url: '/delivery-boy/tracking/live',
                    permission: 'live_tracking_view',
                },

                {
                    name: 'Rider Analytics',
                    icon: 'motorcycle',
                    url: '/rider-analytics',
                    permission: 'driver_performance_view',
                },

                // {
                //     name: 'Session History',
                //     icon: 'history',
                //     url: '/delivery-boy/tracking/sessions',
                //     permission: 'session_history_list',
                // },

                // {
                //     name: 'Daily Reports',
                //     icon: 'chart-line',
                //     url: '/delivery-boy/tracking/reports',
                //     permission: 'daily_reports_view',
                // },

                {
                    name: 'Incentives',
                    isHeading: true,
                    permission: 'delivery_boy_list'
                },

                {
                    name: 'Offers',
                    icon: 'gift',
                    permission: 'delivery_boy_list',
                    submenu: [
                        {
                            name: 'All Offers',
                            icon: 'list',
                            url: '/delivery-boy/offers/list',
                            permission: 'delivery_boy_list',
                        },
                        {
                            name: 'Create Offer',
                            icon: 'plus',
                            url: '/delivery-boy/offers/create',
                            permission: 'delivery_boy_create',
                        },
                        {
                            name: 'Active Offers',
                            icon: 'star',
                            url: '/delivery-boy/offers/active',
                            permission: 'delivery_boy_list',
                        },
                    ]
                },

                // {
                //     name: 'Partner Progress',
                //     icon: 'chart-pie',
                //     url: '/delivery-boy/offers/progress',
                //     permission: 'partner_progress_view',
                // },

                // {
                //     name: 'Payout Management',
                //     icon: 'dollar-sign',
                //     url: '/delivery-boy/offers/payouts',
                //     permission: 'payout_management',
                // },

                // Delivery Vehicles
                {
                    name: 'Delivery Vehicles',
                    isHeading: true,
                    permission: 'delivery_vehicle_list'
                },

                {
                    name: 'Vehicles',
                    icon: 'truck',
                    permission: 'delivery_vehicle_list',
                    submenu: [
                        {
                            name: 'All Vehicles',
                            icon: 'list',
                            url: '/delivery-boy/vehicles/list',
                            permission: 'delivery_vehicle_list',
                        },
                        {
                            name: 'Add Vehicle',
                            icon: 'plus',
                            url: '/delivery-boy/vehicles/create',
                            permission: 'delivery_vehicle_create',
                        },
                    ]
                },

                // Driver Performance & Analytics
                {
                    name: 'Driver Performance',
                    isHeading: true
                },

                {
                    name: 'Performance Dashboard',
                    icon: 'tachometer-alt',
                    url: '/delivery-boys/performance/dashboard',
                    permission: 'driver_performance_view',
                },

                // {
                //     name: 'Rankings & Leaderboard',
                //     icon: 'medal',
                //     url: '/delivery-boys/leaderboard',
                //     permission: 'driver_leaderboard_view',
                // },

                // {
                //     name: 'Driver Ratings',
                //     icon: 'star',
                //     url: '/delivery-boys/ratings',
                //     permission: 'driver_ratings_view',
                // },

                // Driver Training & Development
                {
                    name: 'Driver Training',
                    isHeading: true
                },

                {
                    name: 'Training Modules',
                    icon: 'book',
                    url: '/delivery-boys/training/modules',
                    permission: 'driver_training_manage',
                },

                // Driver Support & Issues
                {
                    name: 'Driver Support',
                    isHeading: true
                },

                {
                    name: 'Issue Tracking',
                    icon: 'exclamation-circle',
                    url: '/delivery-boys/issues',
                    permission: 'driver_issues_view',
                },

                {
                    name: 'Driver Notifications',
                    icon: 'bell',
                    url: '/delivery-boys/notifications',
                    permission: 'driver_notifications_manage',
                },

                {
                    name: 'Customer Management',
                    isHeading: true,
                    permission: 'product_list'
                },


                {
                    name: __('customers'),
                    icon : 'male',
                    permission: null,
                    submenu: [
                        {
                            name: __('customers'),
                            icon : 'grid-fill',
                            url:'/users',
                            permission:'customer_list',
                        },
                        {
                            name: __('wishlists'),
                            icon : 'grid-fill',
                            url:'/wishlists',
                            permission:'manage_wishlists',
                        },

                        {
                            name: __('customer_policies'),
                            icon : 'grid-fill',
                            url:'/privacy_policy',
                            permission:'manage_privacy_policy',
                        },
                    
                    ]
                },

                // {
                //     name: __('wallet_transactions'),
                //     icon : 'credit-card',
                //     url:'/wallet_transactions',
                //     permission:'manage_customer_wallet',
                // },
                // {
                //     name: __('transactions'),
                //     icon : 'history',
                //     url:'/transactions',
                //     permission:'transaction_list',
                // },

                // {
                //     name: 'Customer Messages',
                //     icon : 'comments',
                //     url:'/customer-messages',
                //     permission:'customer_messages',
                // },

                // {
                //     name: 'Customer Support',
                //     icon : 'headphones',
                //     url:'/customer-support',
                //     permission:'customer_list',
                // },

                {
                    name: 'Zenfoo Category',
                    isHeading: true,
                    permission: 'product_list'
                },

                {
                    name: __('categories'),
                    icon : 'bullseye',
                    permission:'category_list', 
                    submenu:[
                        {
                            name: __('add_category'),
                            icon : 'grid-fill',
                            url:'/manage_categories/create',
                             permission:'category_create', 
                        },
                        {
                            name: __('manage_categories'),
                            icon : 'grid-fill',
                            url:'/manage_categories',
                            permission:'category_list', 
                        },
                        {
                            name: __('order_categories'),
                            icon : 'grid-fill',
                            url:'/categories_order',
                            permission:'manage_categories_order', 
                        },
                    ]
                },
                // {a
                //     name: __('special_itmes'),
                //     icon : 'bullseye',
                //     permission:'category_list', 
                //     submenu:[
                //         {
                //             name: __('add_item'),
                //             icon : 'grid-fill',
                //             url:'/manage_special_item/create',
                //              permission:'category_create', 
                //         },
                //         {
                //             name: __('manage_special_item'),
                //             icon : 'grid-fill',
                //             url:'/manage_special_item',
                //              permission:'category_list', 
                //         },
                //     ]
                // },
                {
                    name: __('category_group'),
                    icon : 'cubes',
                    permission:'category_list',
                    submenu:[
                        {
                            name: __('add_category_group'),
                            icon : 'grid-fill',
                            url:'/manage_category_group/create',
                             permission:'category_create',
                        },
                        {
                            name: __('manage_category_group'),
                            icon : 'grid-fill',
                            url:'/manage_category_group',
                             permission:'category_list',
                        },
                        {
                            name: 'Order Category Group',
                            icon : 'grid-fill',
                            url:'/category_group_order',
                             permission:'category_list',
                        },
                    ]
                },
                {
                    name: __('sub_category_group'),
                    icon : 'bullseye',
                    permission:'category_list',
                    submenu:[
                        {
                            name: __('add_sub_category_group'),
                            icon : 'grid-fill',
                            url:'/manage_sub_category_group/create',
                             permission:'category_create',
                        },
                        {
                            name: __('manage_sub_category_group'),
                            icon : 'grid-fill',
                            url:'/manage_sub_category_group',
                            permission:'category_list',
                        },
                        {
                            name: 'Order Sub Category Group',
                            icon : 'grid-fill',
                            url:'/sub_category_group_order',
                            permission:'category_list',
                        },
                    ]
                },


                {
                    name: 'Super Mart',
                    isHeading: true,
                    permission: 'product_list'
                },

                {
                    name: 'Marts',
                    icon : 'store',
                    permission:'seller_list',
                    url:'/marts',
                },

                // {
                //     name: 'Orders',
                //     icon : 'shopping-cart',
                //     permission:'order_list',
                //     url:'/mart_orders',
                // },

                // {
                //     name: __('categories'),
                //     icon : 'bullseye',
                //     permission:'category_list',
                //     submenu:[
                //         {
                //             name: __('add_category'),
                //             icon : 'grid-fill',
                //             url:'/supermart/manage_categories/create',
                //             permission:'category_create',
                //         },
                //         {
                //             name: __('manage_categories'),
                //             icon : 'grid-fill',
                //             url:'/supermart/manage_categories',
                //             permission:'category_list',
                //         },
                //         // {
                //         //     name: __('order_categories'),
                //         //     icon : 'grid-fill',
                //         //     url:'/categories_order',
                //         //     permission:'manage_categories_order',
                //         // },
                //     ]
                // },
                // {
                //     name: __('category_group'),
                //     icon : 'cubes',
                //     permission:'category_list', 
                //     submenu:[
                //         {
                //             name: __('add_category_group'),
                //             icon : 'grid-fill',
                //             url:'/super_mart_manage_category_group/create',
                //              permission:'category_create', 
                //         },
                //         {
                //             name: __('manage_category_group'),
                //             icon : 'grid-fill',
                //             url:'/super_mart_manage_category_group',
                //              permission:'category_list', 
                //         },
                //     ]
                // },
                // {
                //     name: __('sub_category_group'),
                //     icon : 'bullseye',
                //     permission:'category_list', 
                //     submenu:[
                //         {
                //             name: __('add_sub_category_group'),
                //             icon : 'grid-fill',
                //             url:'/super_mart_manage_sub_category_group/create',
                //             permission:'category_create', 
                //         },
                //         {
                //             name: __('manage_sub_category_group'),
                //             icon : 'grid-fill',
                //             url:'/super_mart_manage_sub_category_group',
                //             permission:'category_list', 
                //         },
                //     ]
                // },


                
                {
                    name: 'Combo Management',
                    isHeading: true,
                    permission: 'product_list'
                },
                
                {
                    name: __('combos'),
                    icon : 'cubes',
                    permission:'category_list', 
                    submenu:[
                        {
                            name: __('add_combo'),
                            icon : 'grid-fill',
                            url:'/manage_combos/create',
                             permission:'category_create', 
                        },
                        {
                            name: __('manage_combos'),
                            icon : 'grid-fill',
                            url:'/manage_combos',
                             permission:'category_list', 
                        },
                    ]
                },


                
                {
                    name: 'Store Management',
                    isHeading: true,
                    permission: 'product_list'
                },

                {
                    name: __('store'),
                    icon : 'bullseye',
                    permission:'category_list', 
                    submenu:[
                        {
                            name: __('add_store'),
                            icon : 'grid-fill',
                            url:'/manage_store/create',
                             permission:'category_create', 
                        },
                        {
                            name: __('manage_store'),
                            icon : 'grid-fill',
                            url:'/manage_store',
                             permission:'category_list', 
                        },
                    ]
                },

                
                {
                    name: 'Product Management',
                    isHeading: true,
                    permission: 'product_list'
                },
                {
                    name: "Groceries & Kitchen",
                    icon : 'bullseye',
                    permission:'category_list', 
                    submenu:[
                        {
                            name: __('add_product'),
                            icon: 'plus',
                            url: '/manage_products/create?store_id=12',
                            permission: 'product_create',
                        },
                        {
                            name: __('manage_products'),
                            icon: 'list',
                            url: '/manage_products?store_id=12',
                            permission: 'product_list',
                        },
                    ]
                },


                
                {
                    name: "Vegetables and Fruits",
                    icon : 'bullseye',
                    permission:'category_list', 
                    submenu:[
                        {
                            name: __('add_product'),
                            icon: 'plus',
                            url: '/manage_products/create?store_id=13',
                            permission: 'product_create',
                        },
                        {
                            name: __('manage_products'),
                            icon: 'list',
                            url: '/manage_products?store_id=13',
                            permission: 'product_list',
                        },
                    ]
                },


                
                {
                    name: "Food",
                    icon : 'bullseye',
                    permission:'category_list', 
                    submenu:[
                        // {
                        //     name: __('add_product'),
                        //     icon: 'plus',
                        //     url: '/food_products/create',
                        //     permission: 'product_create',
                        // },
                        {
                            name: __('manage_products'),
                            icon: 'list',
                            url: '/food_products',
                            permission: 'product_list',
                        },
                    ]
                },

                {
                    name: "Chicken and Meat",
                    icon : 'bullseye',
                    permission:'category_list',
                    submenu:[
                        {
                            name: __('add_product'),
                            icon: 'plus',
                            url: '/manage_meat_products/create',
                            permission: 'product_create',
                        },
                        {
                            name: __('manage_products'),
                            icon: 'list',
                            url: '/manage_meat_products',
                            permission: 'product_list',
                        },
                    ]
                },



                {
                    name: __('product_settings'),
                    icon : 'cog',
                    permission:'product_list',
                    submenu:[
                        // {
                        //     name: __('add_product'),
                        //     icon : 'grid-fill',
                        //     url:'/manage_products/create',
                        //     permission:'product_create',
                        // },
                        // {
                        //     name: __('manage_products'),
                        //     icon : 'grid-fill',
                        //     url:'/manage_products',
                        //     permission:'product_list',
                        // },
                        // {
                        //     name: __('approve_requests'),
                        //     icon : 'grid-fill',
                        //     url:'/approve_requests',
                        //     permission:'approve_requests',
                        // },
                        {
                            name: __('units'),
                            icon : 'grid-fill',
                            url:'/units',
                            permission:'manage_units',
                        },
                        {
                            name: __('product_ratings'),
                            icon : 'grid-fill',
                            url:'/product_ratings',
                            permission:'product_ratings',
                        },
                        // {
                        //     name: __('media'),
                        //     icon : 'grid-fill',
                        //     url:'/media',
                        //     permission:'manage_media',
                        // },
                        // {
                        //     name: __('bulk_upload'),
                        //     icon : 'grid-fill',
                        //     url:'/bulk_upload',
                        //     permission:'manage_product_bulk_upload',
                        // },
                        // {
                        //     name: __('bulk_update'),
                        //     icon : 'grid-fill',
                        //     url:'/bulk_update',
                        //     permission:'manage_product_bulk_upload',
                        // },
                        // {
                        //     name: __('taxes'),
                        //     icon : 'grid-fill',
                        //     url:'/taxes',
                        //     permission:'taxes',
                        // },
                        {
                            name: __('brands'),
                            icon : 'grid-fill',
                            url:'/brands',
                            permission:'brands',
                        },
                        // {
                        //     name: __('product_order'),
                        //     icon : 'grid-fill',
                        //     url:'/product_order',
                        //     permission:'manage_product_order',
                        // },
                    ]
                },
                // {
                //     name: __('stock_management'),
                //     icon : 'cubes',
                //     url:'/manage_stock',
                //     permission:'stock_management',
                // },

                
                



                {
                    name: "Banners",
                    icon : 'picture-o',
                    permission:'home_slider_image_list',
                    submenu: [
                        {
                            name: "Add Banner",
                            icon : 'grid-fill',
                            url:'/home_sliders/create',
                            permission:'home_slider_image_create',
                        },
                        {
                            name: "Manage Banners",
                            icon : 'grid-fill',
                            url:'/home_sliders',
                            permission:'home_slider_image_list',
                        }
                    ]
                },

                // {
                //     name: __('offer_image'),
                //     icon : 'gift',
                //     permission:'new_offer_image_list',
                //     submenu: [
                //         {
                //             name: __('add_offer_image'),
                //             icon : 'grid-fill',
                //             url:'/offers/create',
                //             permission:'new_offer_image_create',
                //         },
                //         {
                //             name: __('manage_offer_images'),
                //             icon : 'grid-fill',
                //             url:'/offers',
                //             permission:'new_offer_image_list',
                //         },
                //         {
                //             name: __('manage_popup_offer'),
                //             icon : 'grid-fill',
                //             url:'/popup',
                //             permission:'new_offer_image_list',
                //         }
                //     ]
                // },

                
                {
                    name: 'Coupons Management',
                    isHeading: true,
                    permission: 'product_list'
                },

                {
                    name: "Coupons",
                    icon : 'gift',
                    permission:'promo_code_list',
                    submenu: [
                        {
                            name: "Add",
                            icon : 'grid-fill',
                            url:'/promo_code/create',
                            permission:'promo_code_create',
                        },
                        {
                            name: "Manage",
                            icon : 'grid-fill',
                            url:'/promo_code',
                            permission:'promo_code_list',
                        }
                    ]

                },

                {
                    name: "What are you thinking?",
                    icon : 'lightbulb',
                    url:'/what-are-you-thinking',
                    permission:'promo_code_list',
                },

                // {
                //     name: "Offers",
                //     icon : 'tags',
                //     url:'/offers-management',
                //     permission:'offers_list',
                // },

                {
                    name: "Offers",
                    icon : 'gift',
                    url:'/user-offers',
                    permission:'offers_list',
                },

                // {
                //     name: __('featured_sections'),
                //     icon : 'puzzle-piece',
                //     permission:'featured_section_list',
                //     submenu: [
                //         {
                //             name: __('add_section'),
                //             icon : 'grid-fill',
                //             url:'/sections/create',
                //             permission:'featured_section_create',
                //         },
                //         {
                //             name: __('manage_section'),
                //             icon : 'grid-fill',
                //             url:'/sections',
                //             permission:'featured_section_list',
                //         },
                //         // {
                //         //     name: __('order_section'),
                //         //     icon : 'grid-fill',
                //         //     url:'/section_order',
                //         //     permission:'featured_section_create',
                //         // },
                //     ]

                // },

                // {
                //     name: __('withdrawal_requests'),
                //     icon : 'credit-card',
                //     url:'/withdrawal_requests',
                //     permission:'withdrawal_request_list',
                // },

                
                {
                    name: 'Notification Management',
                    isHeading: true,
                    permission: 'product_list'
                },

                // OLD NOTIFICATIONS - COMMENTED OUT
                // {
                //     name: __('notifications'),
                //     icon : 'share-square',
                //     url:'/notifications',
                //     permission:'notification_list',
                //     submenu: [
                //         {
                //             name: __('send_notifications'),
                //             icon : 'grid-fill',
                //             url:'/notifications/create',
                //             permission:'notification_create',
                //         },{
                //             name: __('manage_notifications'),
                //             icon : 'grid-fill',
                //             url:'/notifications',
                //             permission:'notification_list',
                //         }
                //     ]
                // },

                // NEW NOTIFICATIONS ALL
                {
                    name: 'Notifications',
                    icon: 'bell',
                    permission: 'notification_list',
                    submenu: [
                        {
                            name: 'Send Notification',
                            icon: 'grid-fill',
                            url: '/notifications-all/create',
                            permission: 'notification_create',
                        },
                        {
                            name: 'Manage Notifications',
                            icon: 'grid-fill',
                            url: '/notifications-all',
                            permission: 'notification_list',
                        },
                        {
                            name: 'Notification Analytics',
                            icon: 'chart-line',
                            url: '/notification-analytics',
                            permission: 'notification_list',
                        }
                    ]
                },


                //  {
                //     name: __('email'),
                //     icon : 'share-square',
                //     url:'/emails',
                //     permission:'email_templates',
                //     submenu: [
                //         {
                //             name: __('email_templates'),
                //             icon : 'grid-fill',
                //             url:'/email_templates',
                //             permission:'email_templates',
                //         },{
                //             name: __('manage_emails'),
                //             icon : 'grid-fill',
                //             url:'/emails',
                //             permission:'manage_emails',
                //         }
                //     ]
                // },

                
                {
                    name: 'System Management',
                    isHeading: true,
                    permission: 'product_list'
                },

                {
                    name: __('system'),
                    icon: 'wrench',
                    permission: null,
                    submenu: [
                        {
                            name: "System Settings",
                            icon : 'grid-fill',
                            url:'/store_settings',
                            permission:'manage_settings',
                        },
                        {
                            name: __('delivery_settings'),
                            icon : 'grid-fill',
                            url:'/delivery_settings',
                            permission:'manage_time_slots',
                        },
                        {
                            name: __('payment_methods'),
                            icon : 'grid-fill',
                            url:'/payment_methods',
                            permission:'manage_payment_methods',
                        },
                        {
                            name: __('contact_us'),
                            icon : 'grid-fill',
                            url:'/contact_us',
                            permission:'manage_contact_us',
                        },
                        {
                            name: __('about_us'),
                            icon : 'grid-fill',
                            url:'/about_us',
                            permission:'manage_about_us',
                        },
                       
                        {
                            name: __('firebase_settings'),
                            icon : 'grid-fill',
                            url:'/firebase-settings',
                            permission:'manage_store_settings',
                        },
                        {
                            name: __('sms_settings'),
                            icon : 'grid-fill',
                            url:'/sms-settings',
                            permission:'manage_store_settings',
                        },
                        {
                            name: __('sms_templates'),
                            icon : 'grid-fill',
                            url:'/sms-templates',
                            permission:'manage_store_settings',
                        },
                        {
                            name: __('seo_settings'),
                            icon : 'grid-fill',
                            url:'/seo-settings',
                            permission:'manage_store_settings',
                        },
                    ],
                },



                // {
                //     name: __('web_settings'),
                //     // icon : 'gear fa-spin',
                //     icon : 'gear',
                //     permission:null,
                //     submenu: [
                //         {
                //             name:  __('general_web_settings'),
                //             icon : 'grid-fill',
                //             url:'/general_settings',
                //             permission:'general_settings',
                //         },
                //         {
                //             name: __('social_media'),
                //             icon : 'grid-fill',
                //             url:'/social_media',
                //             permission:'manage_social_media_list',
                //         },
                       
                //     ]
                // },

                {
                    name:__('languages'),
                    icon: 'language',
                    permission:null,
                    submenu: [
                        {
                            name: __('add_language'),
                            icon: 'grid-fill',
                            url: '/languages/create',
                            permission:'language_create',
                        },
                        {
                            name: __('manage_languages'),
                            icon: 'grid-fill',
                            url: '/languages',
                            permission:'language_list',
                        }
                    ]
                },

                // {
                //     name:__('countries'),
                //     icon: 'globe-asia',
                //     permission:null,
                //     submenu: [
                //         {
                //             name: __('add_country'),
                //             icon: 'grid-fill',
                //             url: '/countries/create',
                //             permission:'country_create',
                //         },
                //         {
                //             name: __('manage_countries'),
                //             icon: 'grid-fill',
                //             url: '/countries',
                //             permission:'country_list',
                //         }
                //     ]
                // },

                
                {
                    name: 'Zone Management',
                    isHeading: true,
                    permission: 'product_list'
                },
                {
                    name: __('location'),
                    icon : 'map',
                    permission:null,
                    submenu: [
                        {
                            name: "Add Zone",
                            icon: 'grid-fill',
                            url: '/cities/create',
                            permission:'city_create',
                        },

                        {
                            name: "Manage Zones",
                            icon: 'grid-fill',
                            url: '/cities',
                            permission:'city_list',
                        },
                    ]
                },

                {
                    name: 'Store Locations',
                    icon: 'map-marker-alt',
                    permission: 'store_location_list',
                    submenu: [
                        {
                            name: 'Add Location',
                            icon: 'grid-fill',
                            url: '/store-locations/create',
                            permission: 'store_location_edit',
                        },
                        {
                            name: 'Manage Locations',
                            icon: 'grid-fill',
                            url: '/store-locations',
                            permission: 'store_location_list',
                        },
                    ]
                },
                
                
                {
                    name: 'Report Management',
                    isHeading: true,
                    permission: 'product_list'
                },

                // {
                //     name: __('reports'),
                //     icon : 'folder-open',
                //     permission: null,
                //     submenu: [
                //         {
                //             name: __('product_sales_report'),
                //             icon: 'grid-fill',
                //             url: '/product_sales_reports',
                //             permission:'product_sales_reports',
                //         },
                //         {
                //             name: __('sales_reports'),
                //             icon: 'grid-fill',
                //             url: '/sales_reports',
                //             permission:'sales_reports',
                //         }
                //     ]
                // },


                
                {
                    name: 'Role Management',
                    isHeading: true,
                    permission: 'product_list'
                },

                {
                    name: 'User Management',
                    icon : 'users-cog',
                    url:'/user-management',
                    permission:'manage_system_users',

                },
                {
                    name: __('system_users'),
                    icon : 'users',
                    url:'/system_users',
                    //role : true
                    permission:'manage_system_users',

                },
                {
                    name:__('role'),
                    icon : 'user-secret',
                    url:'/role',
                    //role : true
                    permission:'manage_roles',
                
                },

                
                // {
                //     name: 'FAQ Management',
                //     isHeading: true,
                //     permission: 'product_list'
                // },

                // {
                //     name:__('faqs'),
                //     icon : 'info',
                //     url:'/faqs',
                //     permission:'faq_list',
                // },

                {
                    name: "Seller Registration Module",
                    icon :'shopping-cart',
                    url:'/seller-registration-helper',
                    permission:'order_list'
                },

                {
                    name: 'About Us & Contact Us',
                    isHeading: true,
                    permission: 'order_list'
                },

                {
                    name: 'About Us & Contact Us',
                    icon: 'info',
                    url: '/about_contact',
                    permission: 'order_list',
                },
                {
                    name: 'Campaign Management',
                    isHeading: true,
                    permission: 'product_list'
                },

                {
                    name: 'Campaigns',
                    icon: 'bullhorn',
                    permission: 'product_list',
                    submenu: [
                        {
                            name: 'Add Campaign',
                            icon: 'plus',
                            url: '/brand-campaigns/create',
                            permission: 'product_create',
                        },
                        {
                            name: 'Manage Campaigns',
                            icon: 'list',
                            url: '/brand-campaigns',
                            permission: 'product_list',
                        },
                        {
                            name: 'Campaign Products',
                            icon: 'shopping-bag',
                            url: '/brand-campaign-products',
                            permission: 'product_list',
                        },
                        // {
                        //     name: 'Add Product to Campaign',
                        //     icon: 'plus-square',
                        //     url: '/brand-campaign-products/add',
                        //     permission: 'product_create',
                        // },
                    ]
                },

                {
                    name: 'Customer App Home Screen',
                    isHeading: true,
                    permission: 'product_list'
                },

                {
                    name: 'Customer App Home Screen',
                    icon: 'mobile-alt',
                    permission: 'product_list',
                    submenu: [
                        {
                            name: 'Sections',
                            icon: 'th-large',
                            url: '/customer-app-home-screen/sections',
                            permission: 'product_list',
                        },
                        {
                            name: 'Products',
                            icon: 'box',
                            url: '/customer-app-home-screen/products',
                            permission: 'product_list',
                        },
                        {
                            name: 'Order Sections',
                            icon: 'sort',
                            url: '/customer-app-home-screen/section-order',
                            permission: 'product_list',
                        },
                    ]
                },

                {
                    name: 'Customer Suggestions',
                    isHeading: true,
                    permission: 'product_list'
                },

                {
                    name: 'Customer Suggestions',
                    icon: 'comments',
                    url: '/customer-suggestions',
                    permission: 'product_list',
                },

            ],
            // databasedownloadBtn :[
            //     {
            //         name:__('database_backup'),
            //         icon : 'info',
            //         permission:'database_backup_download',
                   
            //     },
            // ]

        }
    },
    computed: {
        filteredSidebarItems() {
            return this.sidebarItems;
        },
        filteredDatabaseDownloadBtn() {
            return this.databasedownloadBtn;
        }
    },
    methods: {

        initializeSidebarClickHandlers() {
            // Remove existing event listeners first to prevent duplicates
            let sidebarItems = document.querySelectorAll('.sidebar-item.has-sub');

            // Function definition for slideToggle (reusable)
            function slideToggle(t,e,o){0===t.clientHeight?j(t,e,o,!0):j(t,e,o)}function slideUp(t,e,o){j(t,e,o)}function slideDown(t,e,o){j(t,e,o,!0)}function j(t,e,o,i){void 0===e&&(e=400),void 0===i&&(i=!1),t.style.overflow="hidden",i&&(t.style.display="block");var p,l=window.getComputedStyle(t),n=parseFloat(l.getPropertyValue("height")),a=parseFloat(l.getPropertyValue("padding-top")),s=parseFloat(l.getPropertyValue("padding-bottom")),r=parseFloat(l.getPropertyValue("margin-top")),d=parseFloat(l.getPropertyValue("margin-bottom")),g=n/e,y=a/e,m=s/e,u=r/e,h=d/e;window.requestAnimationFrame(function l(x){void 0===p&&(p=x);var f=x-p;i?(t.style.height=g*f+"px",t.style.paddingTop=y*f+"px",t.style.paddingBottom=m*f+"px",t.style.marginTop=u*f+"px",t.style.marginBottom=h*f+"px"):(t.style.height=n-g*f+"px",t.style.paddingTop=a-y*f+"px",t.style.paddingBottom=s-m*f+"px",t.style.marginTop=r-u*f+"px",t.style.marginBottom=d-h*f+"px"),f>=e?(t.style.height="",t.style.paddingTop="",t.style.paddingBottom="",t.style.marginTop="",t.style.marginBottom="",t.style.overflow="",i||(t.style.display="none"),"function"==typeof o&&o()):window.requestAnimationFrame(l)})}

            for(var i = 0; i < sidebarItems.length; i++) {
                let sidebarItem = sidebarItems[i];
                let sidebarLink = sidebarItems[i].querySelector('.sidebar-link');

                // Remove any existing click handler by cloning and replacing the node
                let newSidebarLink = sidebarLink.cloneNode(true);
                sidebarLink.parentNode.replaceChild(newSidebarLink, sidebarLink);

                // Add the click handler to the new element
                newSidebarLink.addEventListener('click', function(e) {
                    e.preventDefault();

                    let submenu = sidebarItem.querySelector('.submenu');
                    if( submenu?.classList?.contains('active') ) submenu.style.display = "block"
                    if( submenu.style.display == "none" ) submenu?.classList?.add('active')
                    else submenu?.classList?.remove('active')
                    slideToggle(submenu, 300)
                })
            }
        },

        filterItem(){

            var filter = this.search;
            $(`.sidebar-menu li:not(.sidebar-search)`).each(function (index, element) {
                const item = $(element);
                const parentListIsNested = item.closest('ul').hasClass('submenu');

                if (item.text().match(new RegExp(filter, 'gi'))) {
                    item.fadeIn();
                    if (parentListIsNested){
                        item.closest('ul').removeClass('active');
                    }
                } else {
                    item.fadeOut();
                    if (parentListIsNested){
                        item.closest('ul').removeClass('active');
                    }
                }
            });

            // Re-initialize click handlers after filtering
            this.$nextTick(() => {
                this.initializeSidebarClickHandlers();
            });
        },
        // subIsActive(item) {
        //     const paths = Array.isArray(item.submenu) ? item.submenu : [];
        //     return paths.some(path => {
        //         return this.$route.path.indexOf(path.url) === 0;
        //     });
        // },
        // isActive(url) {
        //     if(this.$route.path == url){
        //         return true;
        //     }
        //     return false;
        // },
        isActive(url) {
            if (!url || typeof url !== 'string') return false;

            const currentPath = this.$route.path;
            const currentQuery = this.$route.query || {};

            // ✅ CASE 1: No query parameters in URL
            if (!url.includes('?')) {
                return currentPath === url && Object.keys(currentQuery).length === 0;
            }

            // ✅ CASE 2: With query parameters (status_id, category, store_id, status, etc.)
            const urlObj = new URL(url, window.location.origin);
            const menuStatusId = urlObj.searchParams.get('status_id');
            const menuStatus = urlObj.searchParams.get('status');
            const menuCategory = urlObj.searchParams.get('category');
            const menuStoreId = urlObj.searchParams.get('store_id');

            // Check path matches
            if (currentPath !== urlObj.pathname) {
                return false;
            }

            // Check status_id if present in menu URL
            if (menuStatusId && String(currentQuery.status_id || '') !== String(menuStatusId)) {
                return false;
            }

            // Check status if present in menu URL (for preorders)
            if (menuStatus && String(currentQuery.status || '') !== String(menuStatus)) {
                return false;
            }

            // Check category if present in menu URL
            if (menuCategory && String(currentQuery.category || '') !== String(menuCategory)) {
                return false;
            }

            // Check store_id if present in menu URL
            if (menuStoreId && String(currentQuery.store_id || '') !== String(menuStoreId)) {
                return false;
            }

            return true;
        },


        subIsActive(item) {
            if (!item || !Array.isArray(item.submenu)) return false;

            return item.submenu.some(sub => {
                return this.isActive(sub.url);
            });
        },


        isHasSub(item){
            if(item.hasOwnProperty("submenu")){
                if(item.submenu.length > 0){
                    return true;
                }
            }
            return false;
        },
        hasAnySubmenuPermission(item){
            if(!item.submenu || item.submenu.length === 0){
                return false;
            }
            return item.submenu.some(submenu => {
                if(submenu.role){
                    return this.$role('Super Admin') && (item.name === 'Role' || item.name === 'System Users');
                }
                return submenu.permission && this.$can(submenu.permission);
            });
        },
        shouldShowHeading(headingItem) {
            // Find the index of the heading in sidebarItems
            const headingIndex = this.sidebarItems.findIndex(item => item === headingItem);
            if (headingIndex === -1) return false;

            // Find all items between this heading and the next heading (or end of array)
            const itemsInSection = [];
            for (let i = headingIndex + 1; i < this.sidebarItems.length; i++) {
                const item = this.sidebarItems[i];
                // Stop when we hit the next heading or divider
                if (item.isHeading) break;
                if (!item.isDivider) {
                    itemsInSection.push(item);
                }
            }

            // Check if user has permission to see at least one item in this section
            return itemsInSection.some(item => {
                // Check for role-based items (System Users, Role)
                if (item.role === true) {
                    return this.$role('Super Admin');
                }
                // Check if item has permission and user has that permission
                if (item.permission && this.$can(item.permission)) {
                    return true;
                }
                // Check if item has submenu and user has permission to see any submenu item
                if (item.permission === null && this.isHasSub(item) && this.hasAnySubmenuPermission(item)) {
                    return true;
                }
                return false;
            });
        },
        checkPermissions() {
            var current_path = this.$route.path;
            var permission = '';

            this.sidebarItems.forEach(menu => {
                //Only Main Categories
                if(menu.submenu && menu.submenu.length>0) {
                    menu.submenu.forEach(submenu => {
                        if(submenu.url === current_path){
                            permission = submenu.permission;
                        }
                    });
                }else{
                    if(menu.url === current_path){
                        permission = menu.permission;
                    }
                }
            });

            if(Auth.check() && UserPermissions.length === 0){
                //this.$router.push({path:'/login'});
                if(window.localStorage.getItem('loginCheck') == 1){
                    Auth.logout();
                }
                window.localStorage.setItem('loginCheck',1);
                window.location.reload();
            }
            else if(Auth.check() && permission && !this.$can(permission)){
                this.$router.push({path:'/unauthorized'});
            }

        },

        closeSideBarMenu() {
            var w = window.innerWidth;
            if(w < 1200) {
                document.getElementById('sidebar')?.classList?.remove('active');
            }
        },
     
        downloadDatabase() {
            this.isLoading = true;

   axios({
        method: 'get',
        url:this.$apiUrl + '/database_backup_download',
        responseType: 'blob',  // important: responseType must be 'blob' for file download
      })
        .then((response) => {
          const blob = new Blob([response.data]);
          const link = document.createElement('a');
          link.href = window.URL.createObjectURL(blob);

          // Extracting the filename from the response headers
          const contentDisposition = response.headers['content-disposition'];
          const filenameMatch = contentDisposition && contentDisposition.match(/filename="(.+?)"/);
          const filename = filenameMatch ? filenameMatch[1] : 'downloaded-database-backup.sql';

          link.download = filename;
          link.click();
          this.showMessage("success", __('database_downloaded_successfully'));
       this.isLoading = false;
        })
        .catch((error) => {
          console.error('Error downloading file:', error);
          // Handle error accordingly
        });
        },

        fetchOrderStatusCounts() {
            axios.get(this.$apiUrl + '/orders/status-counts')
                .then((response) => {
                    if (response.data.status === 1) {
                        this.orderStatusCounts = response.data.data;
                    }
                })
                .catch((error) => {
                    console.error('Error fetching order status counts:', error);
                });
        },

        getOrderCount(url) {
            if (!url || !url.includes('status_id=')) {
                return this.orderStatusCounts.all;
            }
            const statusId = url.split('status_id=')[1];
            const statusMap = {
                '1': this.orderStatusCounts.payment_pending,
                '2': this.orderStatusCounts.received,
                '3': this.orderStatusCounts.processed,
                // '4': this.orderStatusCounts.shipped,
                '5': this.orderStatusCounts.out_for_delivery,
                '6': this.orderStatusCounts.delivered,
                '7': this.orderStatusCounts.cancelled,
                '8': this.orderStatusCounts.returned,
            };
            return statusMap[statusId] || 0;
        }

    }
}
</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.3s;
}
.fade-enter,
.fade-leave-to {
    opacity: 0;
}

/* Sidebar heading styles */
.sidebar-title {
    padding: 1rem 1.5rem 0.5rem;
    margin: "1.5rem -38px 1rem";
    /* font-size: 0.5rem; */
    font-weight: 900;
    font-style: bold;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    /* color: #6c757d; */
    color: #9AC444 !important;
    /*d opacity: 0.5; */
    list-style: none;
    text-align: left;
    align-self: flex-start;
    
}

.sidebar-title:first-of-type {
    margin-top: 0;
}

/* Order count badge styles */
.order-count-badge {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 20px;
    height: 20px;
    padding: 0 6px;
    font-size: 11px;
    font-weight: 600;
    color: #fff;
    background-color: #9AC444;
    border-radius: 50%;
    margin-left: 8px;
}
</style>

