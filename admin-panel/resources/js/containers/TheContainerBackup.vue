<template>
    <div id="app">
        <div id="sidebar" class="active modern-sidebar">
            <div class="sidebar-wrapper active">
                <div class="sidebar-header">
                    <div class="d-flex flex-row justify-content-between align-items-center">
                        <div class="logo">
                            <router-link to="/" class="brand-link d-flex align-items-center">
                                <div class="logo-wrapper">
                                    <img class="container-logo" v-if="$appLogo != ''" :src="$storageUrl+$appLogo" alt='Logo' srcset=""/>
                                    <img class="container-logo" v-else :src="$baseUrl + '/images/logo.png'" alt='Logo' srcset=""/>
                                </div>
                                <span class="brand-text ms-3">Zenfoo Admin</span>
                            </router-link>
                        </div>
                        <div class="toggler">
                            <a href="javascript:void(0)" class="sidebar-hide d-xl-none d-block">
                                <i class="bi bi-x bi-middle"></i>
                            </a>
                        </div>
                    </div>
                </div>
                <div class="sidebar-menu">
                    <ul class="menu">

                        <li class="sidebar-item sidebar-search">
                            <div class="search-wrapper">
                                <i class="fa fa-search search-icon"></i>
                                <b-form-input v-model="search" type="search" :placeholder="__('search')"
                                              v-on:keyup="filterItem" v-on:search="filterItem" class="modern-search"></b-form-input>
                            </div>
                        </li>


                        <template v-for="item in filteredSidebarItems">
                            <!-- Sidebar Heading (non-clickable) -->
                            <li v-if="item.isHeading" class="sidebar-title" :key="item.name">
                                <span>{{ item.name }}</span>
                                <hr class="sidebar-divider">
                            </li>

                            <!-- Regular sidebar items -->
                            <li v-else class="sidebar-item" :class="{ 'active' : isActive(item.url) || subIsActive(item), 'has-sub' : isHasSub(item) }"
                                v-if=" item.role==true ? ($role('Super Admin') && (item.name=='Role' || item.name=='System Users')) : (item.permission && $can(item.permission)) || (item.permission === null && isHasSub(item) && hasAnySubmenuPermission(item))">

                                <template v-if="isHasSub(item)">
                                    <a class="sidebar-link">
                                        <i :class="`fa fa-${item.icon}`"></i>
                                        <span>{{ item.name }}</span>
                                    </a>
                                    <div class="submenu" :class="{ 'active' : subIsActive(item) } ">
                                        <template v-for="sub in item.submenu">
                                            <div class="submenu-item" :class="{ 'active' : isActive(sub.url) } " :key="sub.key"
                                             v-if="sub.role ? $role('Super Admin') && (item.name === 'Role' || item.name === 'System Users') : sub.permission && $can(sub.permission)">
                                                <router-link :to="sub.url" @click="closeSideBarMenu()">
                                                    {{ sub.name }}
                                                </router-link>
                                            </div>
                                        </template>


                                    </div>
                                </template>

                                <template v-else>
                                    <router-link class="sidebar-link" :to="item.url" @click="closeSideBarMenu()">
                                        <i :class="`fa fa-${item.icon}`"></i>
                                        <span>{{ item.name }}</span>
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

        function slideToggle(t,e,o){0===t.clientHeight?j(t,e,o,!0):j(t,e,o)}function slideUp(t,e,o){j(t,e,o)}function slideDown(t,e,o){j(t,e,o,!0)}function j(t,e,o,i){void 0===e&&(e=400),void 0===i&&(i=!1),t.style.overflow="hidden",i&&(t.style.display="block");var p,l=window.getComputedStyle(t),n=parseFloat(l.getPropertyValue("height")),a=parseFloat(l.getPropertyValue("padding-top")),s=parseFloat(l.getPropertyValue("padding-bottom")),r=parseFloat(l.getPropertyValue("margin-top")),d=parseFloat(l.getPropertyValue("margin-bottom")),g=n/e,y=a/e,m=s/e,u=r/e,h=d/e;window.requestAnimationFrame(function l(x){void 0===p&&(p=x);var f=x-p;i?(t.style.height=g*f+"px",t.style.paddingTop=y*f+"px",t.style.paddingBottom=m*f+"px",t.style.marginTop=u*f+"px",t.style.marginBottom=h*f+"px"):(t.style.height=n-g*f+"px",t.style.paddingTop=a-y*f+"px",t.style.paddingBottom=s-m*f+"px",t.style.marginTop=r-u*f+"px",t.style.marginBottom=d-h*f+"px"),f>=e?(t.style.height="",t.style.paddingTop="",t.style.paddingBottom="",t.style.marginTop="",t.style.marginBottom="",t.style.overflow="",i||(t.style.display="none"),"function"==typeof o&&o()):window.requestAnimationFrame(l)})}
        let sidebarItems = document.querySelectorAll('.sidebar-item.has-sub');
        for(var i = 0; i < sidebarItems.length; i++) {
            let sidebarItem = sidebarItems[i];
            sidebarItems[i].querySelector('.sidebar-link').addEventListener('click', function(e) {
                e.preventDefault();

                let submenu = sidebarItem.querySelector('.submenu');
                if( submenu?.classList?.contains('active') ) submenu.style.display = "block"
                if( submenu.style.display == "none" ) submenu?.classList?.add('active')
                else submenu?.classList?.remove('active')
                slideToggle(submenu, 300)
            })
        }
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
            sidebarItems :[
                {
                    name: __('dashboard'),
                    icon : 'tachometer-alt',
                    url:'/dashboard',
                    permission:'manage_dashboard'
                },
                {
                    name: __('orders'),
                    icon :'shopping-cart',
                    url:'/orders',
                    permission:'order_list'
                },
                {
                    name: "Seller Registration Helper",
                    icon :'shopping-cart',
                    url:'/seller-registration-helper',
                    permission:'order_list'
                },
                // {
                //     name: __('self_pickup_orders'),
                //     icon :'box-open',
                //     url:'/self_pickup_orders',
                //     permission:'self_pickup_order_list'
                // },
                {
                    name: 'Zenfoo Category Management',
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
                        // {
                        //     name: __('order_categories'),
                        //     icon : 'grid-fill',
                        //     url:'/categories_order',
                        //     permission:'manage_categories_order', 
                        // },
                    ]
                },
                // {
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
                    ]
                },
                {
                    name: __('sub_category_group'),
                    icon : 'bullseye',
                    permission:'category_list', 
                    submenu:[
                        // {
                        //     name: __('add_sub_category_group'),
                        //     icon : 'grid-fill',
                        //     url:'/manage_sub_category_group/create',
                        //      permission:'category_create', 
                        // },
                        {
                            name: __('manage_sub_category_group'),
                            icon : 'grid-fill',
                            url:'/manage_sub_category_group',
                             permission:'category_list', 
                        },
                    ]
                },

                {
                    name: 'Super Mart Category Management',
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
                            url:'/manage_categories_super_mart/create',
                            permission:'category_create', 
                        },
                        {
                            name: __('manage_categories'),
                            icon : 'grid-fill',
                            url:'/manage_categories_super_mart',
                            permission:'category_list', 
                        },
                        // {
                        //     name: __('order_categories'),
                        //     icon : 'grid-fill',
                        //     url:'/categories_order',
                        //     permission:'manage_categories_order', 
                        // },
                    ]
                },
                {
                    name: __('category_group'),
                    icon : 'cubes',
                    permission:'category_list', 
                    submenu:[
                        {
                            name: __('add_category_group'),
                            icon : 'grid-fill',
                            url:'/manage_category_group_super_mart/create',
                             permission:'category_create', 
                        },
                        {
                            name: __('manage_category_group'),
                            icon : 'grid-fill',
                            url:'/manage_category_group_super_mart',
                             permission:'category_list', 
                        },
                    ]
                },
                {
                    name: __('sub_category_group'),
                    icon : 'bullseye',
                    permission:'category_list', 
                    submenu:[
                        // {
                        //     name: __('add_sub_category_group'),
                        //     icon : 'grid-fill',
                        //     url:'/manage_sub_category_group/create',
                        //      permission:'category_create', 
                        // },
                        {
                            name: __('manage_sub_category_group'),
                            icon : 'grid-fill',
                            url:'/manage_sub_category_group',
                             permission:'category_list', 
                        },
                    ]
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


                // Groceries & Kitchen Section
                {
                    name: 'Grocery & Kitchen',
                    isHeading: true,
                    permission: 'product_list'
                },
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

                // Vegetables and Fruits Section
                {
                    name: 'Vegetables and Fruits',
                    isHeading: true,
                    permission: 'product_list'
                },
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

                // Sweets Section
                {
                    name: 'Sweets & Bakery',
                    isHeading: true,
                    permission: 'product_list'
                },
                {
                    name: __('add_product'),
                    icon: 'plus',
                    url: '/manage_products/create?store_id=15',
                    permission: 'product_create',
                },
                {
                    name: __('manage_products'),
                    icon: 'list',
                    url: '/manage_products?store_id=15',
                    permission: 'product_list',
                },

                // Fruits and Vegs Section
                {
                    name: 'Chicken & Meat',
                    isHeading: true,
                    permission: 'product_list'
                },
                {
                    name: __('add_product'),
                    icon: 'plus',
                    url: '/manage_products/create?store_id=14',
                    permission: 'product_create',
                },
                {
                    name: __('manage_products'),
                    icon: 'list',
                    url: '/manage_products?store_id=14',
                    permission: 'product_list',
                },

                // Product Settings Section
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
                {
                    name: __('stock_management'),
                    icon : 'cubes',
                    url:'/manage_stock',
                    permission:'stock_management',
                },
                {
                    name: __('sellers'),
                    icon: 'male',
                    permission:'seller_list',
                    submenu: [
                        // {
                        //     name: __('add_seller'),
                        //     icon : 'grid-fill',
                        //     url:'/sellers/create',
                        //     permission:'seller_create',
                        // },
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
                            name: __('seller_commissions'),
                            icon : 'grid-fill',
                            url:'/seller_commissions',
                            permission:'seller_list',
                        },
                        {
                            name: __('seller_wallet_transactions'),
                            icon : 'grid-fill',
                            url:'/seller_wallet_transactions',
                            permission:'seller_wallet_transactions',
                        },
                        {
                            name: __('policies_seller'),
                            icon : 'grid-fill',
                            url:'/privacy_policy_seller',
                            permission:'manage_privacy_policy_seller_app',
                        },
                    ],
                },
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
                {
                    name: __('offer_image'),
                    icon : 'gift',
                    permission:'new_offer_image_list',
                    submenu: [
                        {
                            name: __('add_offer_image'),
                            icon : 'grid-fill',
                            url:'/offers/create',
                            permission:'new_offer_image_create',
                        },
                        {
                            name: __('manage_offer_images'),
                            icon : 'grid-fill',
                            url:'/offers',
                            permission:'new_offer_image_list',
                        },
                        {
                            name: __('manage_popup_offer'),
                            icon : 'grid-fill',
                            url:'/popup',
                            permission:'new_offer_image_list',
                        }
                    ]
                },

                {
                    name: __('promo_code'),
                    icon : 'gift',
                    permission:'promo_code_list',
                    submenu: [
                        {
                            name: __('add_promo_code'),
                            icon : 'grid-fill',
                            url:'/promo_code/create',
                            permission:'promo_code_create',
                        },
                        {
                            name: __('manage_promo_code'),
                            icon : 'grid-fill',
                            url:'/promo_code',
                            permission:'promo_code_list',
                        }
                    ]

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
                //     name: __('return_requests'),
                //     icon : 'retweet',
                //     url:'/return_requests',
                //     permission:'return_request_list',
                // },
                // {
                //     name: __('withdrawal_requests'),
                //     icon : 'credit-card',
                //     url:'/withdrawal_requests',
                //     permission:'withdrawal_request_list',
                // },
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
                            name: __('dlivery_boy_requests'),
                            icon : 'grid-fill',
                            url:'/registered_delivery_boys',
                            permission:'delivery_boy_list',
                        },
                        {
                            name: __('manage_delivery_boys'),
                            icon : 'grid-fill',
                            url:'/delivery_boys',
                            permission:'delivery_boy_list',
                        },
                        {
                            name: __('fund_transfers'),
                            icon : 'grid-fill',
                            url:'/fund_transfers',
                            permission:'fund_transfers_list',
                        },
                        {
                            name: __('delivery_boy_cash'),
                            icon : 'grid-fill',
                            url:'/cash_collection',
                            permission:'cash_collection_list',
                        },
                        {
                            name: __('delivery_boy_policies'),
                            icon : 'grid-fill',
                            url:'/privacy_policy_delivery_boy',
                            permission:'manage_privacy_policy_delivery_boy',
                        },
                    ]
                },
                {
                    name: __('notifications'),
                    icon : 'share-square',
                    url:'/notifications',
                    permission:'notification_list',
                    submenu: [
                        {
                            name: __('send_notifications'),
                            icon : 'grid-fill',
                            url:'/notifications/create',
                            permission:'notification_create',
                        },{
                            name: __('manage_notifications'),
                            icon : 'grid-fill',
                            url:'/notifications',
                            permission:'notification_list',
                        }
                    ]
                },
                 {
                    name: __('email'),
                    icon : 'share-square',
                    url:'/emails',
                    permission:'email_templates',
                    submenu: [
                        {
                            name: __('email_templates'),
                            icon : 'grid-fill',
                            url:'/email_templates',
                            permission:'email_templates',
                        },{
                            name: __('manage_emails'),
                            icon : 'grid-fill',
                            url:'/emails',
                            permission:'manage_emails',
                        }
                    ]
                },

                {
                    name: __('system'),
                    icon: 'wrench',
                    permission: null,
                    submenu: [
                        {
                            name: __('store_settings'),
                            icon : 'grid-fill',
                            url:'/store_settings',
                            permission:'manage_store_settings',
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

                // {
                //     name:__('languages'),
                //     icon: 'language',
                //     permission:null,
                //     submenu: [
                //         {
                //             name: __('add_language'),
                //             icon: 'grid-fill',
                //             url: '/languages/create',
                //             permission:'language_create',
                //         },
                //         {
                //             name: __('manage_languages'),
                //             icon: 'grid-fill',
                //             url: '/languages',
                //             permission:'language_list',
                //         }
                //     ]
                // },

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

                // {
                //     name: __('location'),
                //     icon : 'map',
                //     permission:null,
                //     submenu: [
                //         {
                //             name: __('add_city'),
                //             icon: 'grid-fill',
                //             url: '/cities/create',
                //             permission:'city_create',
                //         },

                //         {
                //             name: __('manage_cities'),
                //             icon: 'grid-fill',
                //             url: '/cities',
                //             permission:'city_list',
                //         }
                //         // ,{
                //         //     name: __('deliverable_area'),
                //         //     icon: 'grid-fill',
                //         //     url: '/deliverable_area',
                //         //     permission:'manage_dashboard',
                //         // }
                //     ]
                // },
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
                        // {
                        //     name: __('wallet_transactions'),
                        //     icon : 'grid-fill',
                        //     url:'/wallet_transactions',
                        //     permission:'manage_customer_wallet',
                        // },
                        // {
                        //     name: __('transactions'),
                        //     icon : 'grid-fill',
                        //     url:'/transactions',
                        //     permission:'transaction_list',
                        // },
                        // {
                        //     name: __('customer_policies'),
                        //     icon : 'grid-fill',
                        //     url:'/privacy_policy',
                        //     permission:'manage_privacy_policy',
                        // },
                    
                    ]
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
                // {
                //     name: __('system_users'),
                //     icon : 'users',
                //     url:'/system_users',
                //     role : true
                // },
                // {
                //     name:__('role'),
                //     icon : 'user-secret',
                //     url:'/role',
                //     role : true
                // },
                {
                    name:__('faqs'),
                    icon : 'info',
                    url:'/faqs',
                    permission:'faq_list',
                },
            ],
            databasedownloadBtn :[
                {
                    name:__('database_backup'),
                    icon : 'info',
                    permission:'database_backup_download',
                   
                },
            ]

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
                        item.closest('ul').addClass('active');
                    }
                }
            });
        },
        subIsActive(item) {
            const paths = Array.isArray(item.submenu) ? item.submenu : [];
            return paths.some(path => {
                return this.$route.path.indexOf(path.url) === 0;
            });
        },
        isActive(url) {
            if(this.$route.path == url){
                return true;
            }
            return false;
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
        }
         

    }
}
</script>

<style scoped>
/* Base Transitions */
.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.3s;
}
.fade-enter,
.fade-leave-to {
    opacity: 0;
}

/* Modern Sidebar Container */
#sidebar.modern-sidebar {
    background: linear-gradient(180deg, #1e293b 0%, #0f172a 100%);
    box-shadow: 4px 0 24px rgba(0, 0, 0, 0.15);
    position: fixed;
    height: 100vh;
    width: 280px;
    z-index: 1000;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

#sidebar.modern-sidebar::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 300px;
    background: radial-gradient(circle at 50% 0%, rgba(59, 130, 246, 0.12), transparent 70%);
    pointer-events: none;
    z-index: 0;
}

.sidebar-wrapper {
    position: relative;
    height: 100%;
    display: flex;
    flex-direction: column;
    z-index: 1;
}

/* Header Styling */
.sidebar-header {
    padding: 1.5rem 1.25rem;
    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
    background: rgba(255, 255, 255, 0.02);
    backdrop-filter: blur(10px);
    position: relative;
}

.brand-link {
    text-decoration: none;
    display: flex;
    align-items: center;
    gap: 0.875rem;
    transition: all 0.3s ease;
}

.brand-link:hover {
    transform: translateX(4px);
}

.logo-wrapper {
    width: 48px;
    height: 48px;
    border-radius: 12px;
    background: #ffffff;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 6px;
    transition: all 0.3s ease;
}

.logo-wrapper:hover {
    transform: scale(1.05);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.container-logo {
    width: 100%;
    height: 100%;
    object-fit: contain;
}

.brand-text {
    font-size: 1.125rem;
    font-weight: 700;
    background: linear-gradient(135deg, #fff 0%, #e2e8f0 100%);
    background-clip: text;
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    letter-spacing: -0.02em;
    white-space: nowrap;
}

.sidebar-hide {
    width: 36px;
    height: 36px;
    border-radius: 8px;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.1);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #cbd5e1;
    transition: all 0.3s ease;
    text-decoration: none;
}

.sidebar-hide:hover {
    background: rgba(239, 68, 68, 0.15);
    border-color: rgba(239, 68, 68, 0.3);
    color: #ef4444;
    transform: scale(1.05);
}

/* Search Bar */
.sidebar-search {
    padding: 1rem 1.25rem;
    list-style: none;
}

.search-wrapper {
    position: relative;
}

.search-icon {
    position: absolute;
    left: 1rem;
    top: 50%;
    transform: translateY(-50%);
    color: #64748b;
    font-size: 0.875rem;
    pointer-events: none;
    z-index: 2;
}

.modern-search {
    width: 100%;
    padding: 0.75rem 1rem 0.75rem 2.75rem;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 10px;
    color: #e2e8f0;
    font-size: 0.875rem;
    transition: all 0.3s ease;
}

.modern-search::placeholder {
    color: #64748b;
}

.modern-search:focus {
    background: rgba(255, 255, 255, 0.08);
    border-color: rgba(59, 130, 246, 0.5);
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
    outline: none;
}

/* Menu Container */
.sidebar-menu {
    flex: 1;
    overflow-y: auto;
    overflow-x: hidden;
    padding: 0.5rem 0;
}

.sidebar-menu::-webkit-scrollbar {
    width: 6px;
}

.sidebar-menu::-webkit-scrollbar-track {
    background: transparent;
}

.sidebar-menu::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.15);
    border-radius: 10px;
}

.sidebar-menu::-webkit-scrollbar-thumb:hover {
    background: rgba(255, 255, 255, 0.25);
}

.menu {
    list-style: none;
    padding: 0;
    margin: 0;
}

/* Sidebar Heading Styles */
.sidebar-title {
    padding: 1.25rem 1.125rem 0.5rem !important;
    margin: 1rem 0 0.375rem 0 !important;
    font-size: 0.65rem !important;
    font-weight: 700;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    color: #64748b;
    opacity: 1;
    list-style: none !important;
    text-align: left !important;
    display: block !important;
    width: 100%;
}

.sidebar-title:first-of-type {
    margin-top: 0.5rem !important;
}

.sidebar-divider {
    border: none;
    border-top: 1px solid rgba(100, 116, 139, 0.25);
    margin: 0.5rem 0 0 0;
    width: 100%;
}

/* Sidebar Items */
.sidebar-item {
    margin: 0 0.875rem 0.25rem;
    border-radius: 8px;
    list-style: none;
    transition: all 0.3s ease;
}

.sidebar-item.active > .sidebar-link,
.sidebar-item.active > a.sidebar-link {
    background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
    color: #ffffff;
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
}

.sidebar-item.active > .sidebar-link i,
.sidebar-item.active > a.sidebar-link i {
    color: #ffffff;
}

.sidebar-link {
    display: flex;
    align-items: center;
    padding: 0.75rem 1rem;
    color: #cbd5e1;
    text-decoration: none;
    font-size: 0.9rem;
    font-weight: 500;
    border-radius: 8px;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
    cursor: pointer;
    gap: 0.75rem;
}

.sidebar-link:hover {
    background: rgba(59, 130, 246, 0.15);
    color: #ffffff;
    transform: translateX(4px);
    text-decoration: none;
}

.sidebar-link i {
    font-size: 1.05rem;
    color: #94a3b8;
    transition: all 0.3s ease;
    min-width: 22px;
    text-align: center;
    display: inline-flex;
    align-items: center;
    justify-content: center;
}

.sidebar-link:hover i {
    color: #3b82f6;
    transform: scale(1.1);
}

.sidebar-item.active .sidebar-link:hover i {
    color: #ffffff;
}

/* Submenu Styles */
.sidebar-item.has-sub .sidebar-link::after {
    content: '\f107';
    font-family: 'FontAwesome';
    margin-left: auto;
    font-size: 0.8rem;
    transition: transform 0.3s ease;
    color: #64748b;
    opacity: 0.7;
}

.sidebar-item.has-sub.active .sidebar-link::after {
    transform: rotate(180deg);
    color: #94a3b8;
    opacity: 1;
}

.submenu {
    list-style: none;
    padding: 0.5rem 0;
    margin: 0.5rem 0 0.5rem 0;
    /* background: rgba(15, 23, 42, 0.6); */
    border-radius: 8px;
    backdrop-filter: blur(10px);
    display: none;
    overflow: hidden;
}

.submenu.active {
    display: block;
}

.submenu-item {
    margin: 0.125rem 0.75rem;
    list-style: none;
    position: relative;
}

.submenu-item a {
    display: block;
    padding: 0.65rem 1rem 0.65rem 2.5rem;
    color: #cbd5e1;
    text-decoration: none;
    font-size: 0.85rem;
    font-weight: 500;
    border-radius: 6px;
    transition: all 0.3s ease;
    position: relative;
}

.submenu-item a::before {
    content: '';
    position: absolute;
    left: 1.25rem;
    top: 50%;
    transform: translateY(-50%);
    width: 5px;
    height: 5px;
    border-radius: 50%;
    background: #64748b;
    transition: all 0.3s ease;
}

.submenu-item a:hover {
    background: rgba(59, 130, 246, 0.1);
    color: #ffffff;
    text-decoration: none;
    transform: translateX(4px);
}

.submenu-item a:hover::before {
    background: #3b82f6;
    transform: translateY(-50%) scale(1.3);
}

.submenu-item.active a {
    background: rgba(59, 130, 246, 0.2);
    color: #ffffff;
}

.submenu-item.active a::before {
    background: #3b82f6;
    box-shadow: 0 0 8px rgba(59, 130, 246, 0.6);
}

/* Download Button */
.btn-primary {
    margin: 1rem 1.25rem;
    padding: 0.875rem 1.25rem;
    background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
    border: none;
    border-radius: 10px;
    color: #ffffff;
    font-weight: 600;
    font-size: 0.9375rem;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
    width: calc(100% - 2.5rem);
}

.btn-primary:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 20px rgba(59, 130, 246, 0.4);
    background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
}

.btn-primary:active {
    transform: translateY(0);
}

/* Responsive Design */
@media (max-width: 1199px) {
    #sidebar.modern-sidebar:not(.active) {
        transform: translateX(-100%);
    }
}

@media (max-width: 768px) {
    #sidebar.modern-sidebar {
        width: 280px;
    }
}

/* Animation Keyframes */
@keyframes slideIn {
    from {
        opacity: 0;
        transform: translateX(-10px);
    }
    to {
        opacity: 1;
        transform: translateX(0);
    }
}

.sidebar-item {
    animation: slideIn 0.3s ease forwards;
}

.sidebar-item:nth-child(1) { animation-delay: 0.05s; }
.sidebar-item:nth-child(2) { animation-delay: 0.1s; }
.sidebar-item:nth-child(3) { animation-delay: 0.15s; }
.sidebar-item:nth-child(4) { animation-delay: 0.2s; }
.sidebar-item:nth-child(5) { animation-delay: 0.25s; }

/* Focus States for Accessibility */
.sidebar-link:focus,
.submenu-item a:focus {
    outline: 2px solid #3b82f6;
    outline-offset: 2px;
}

/* Sidebar Toggler */
.sidebar-toggler {
    display: none;
}
</style>


