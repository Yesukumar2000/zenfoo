//import Vue from 'vue'

//window.Vue = require("vue/dist/vue.js");
import Auth from '../Auth.js';
import Router from "vue-router";
import axios from "axios";
const Install = () => import("../views/Install");

// Auth
const Login = () => import("../views/Login");
const ForgotPassword = () => import("../views/ForgotPassword");
const ResetPassword = () => import("../views/ResetPassword");

// Containers
const TheContainer = () => import("../containers/TheContainer.vue");
const TheContainerSeller = () => import("../containers/TheContainerSeller");
const TheContainerDeliveryBoy = () => import("../containers/TheContainerDeliveryBoy");
const Settings = () => import('../views/Settings');

// Views
const Dashboard = () => import("../views/Dashboard.vue");
const Orders = () => import("../views/Orders/Orders.vue");
const PreOrders = () => import("../views/PreOrders/index.vue");
const StorePreOrders = () => import("../views/PreOrders/StorePreOrders.vue");
const PreOrderItems = () => import("../views/PreOrders/PreOrderItems.vue");
const AddPreOrderItems = () => import("../views/PreOrders/AddPreOrderItems.vue");
const ViewOrder = () => import("../views/Orders/ViewOrder");
const StuckOrders = () => import("../views/Orders/StuckOrders");
const InvoiceOrder = () => import("../views/Orders/InvoiceOrder");
const OrderAnalytics = () => import("../views/Orders/OrderAnalytics.vue");
const ProfitLossComparison = () => import("../views/Orders/ProfitLossComparison.vue");
const UserAnalytics = () => import("../views/Users/UserAnalytics.vue");
const MerchantAnalytics = () => import("../views/Seller/SellerAnalytics.vue");
const DeliveryBoyAnalytics = () => import("../views/DeliveryBoys/DeliveryBoyAnalytics.vue");
const SelfPickupOrders = () => import("../views/Orders/SelfPickupOrders");
const ViewSelfPickupOrder = () => import("../views/Orders/ViewSelfPickupOrder");

// Combos
const ManageCombos = () => import("../views/Combo/Combo");
const EditCombo = () => import("../views/Combo/EditCombo");
const ViewCombo = () => import("../views/Combo/ViewCombo");

// Stores
const ManageStore = () => import("../views/Store/Store");
const EditStore = () => import("../views/Store/EditStore");

// Special Items.  

const ManageSpecialItem = () => import("../views/SpecialItems/Special");
const EditItem = () => import("../views/SpecialItems/EditItem");

// Category Group
const ManageCategoryGroup= () => import("../views/CategoryGroup/Category");
const EditCategoryGroup = () => import("../views/CategoryGroup/EditCategory");
const CreateCategoryGroup = () => import("../views/CategoryGroup/CreateCategoryGroup");
const CategoryGroupOrder = () => import("../views/CategoryGroup/CategoryGroupOrder");

const ManageCategoryGroupSuperMart= () => import("../views/CategoryGroupSuperMart/Category");
const EditCategoryGroupSuperMart = () => import("../views/CategoryGroupSuperMart/EditCategory");

// Sub Category Group
const ManageSubCategoryGroup= () => import("../views/SubCategoryGroup/SubCategory");
const EditSubCategoryGroup = () => import("../views/SubCategoryGroup/EditSubCategory");
const CreateSubCategoryGroup = () => import("../views/SubCategoryGroup/CreateSubCategoryGroup");
const SubCategoryGroupOrder = () => import("../views/SubCategoryGroup/SubCategoryGroupOrder");

const ManageSubCategoryGroupSuperMart= () => import("../views/SubCategoryGroupSuperMart/SubCategory");
const EditSubCategoryGroupSuperMart = () => import("../views/SubCategoryGroupSuperMart/EditSubCategory");


// Notification Panel
const NotificationPanel = () => import("../views/NotificationPanel.vue");

// Categories
const ManageCategories = () => import("../views/Category/ManageCategories");
const CategorySuperMartManageCategories = () => import("../views/CategorySuperMart/ManageCategories.vue");
const CategoriesOrder = () => import("../views/Category/CategoriesOrder");

// Subcategories
const SubCategories = () => import("../views/SubCategory/SubCategories");

// Products
const Products = () => import("../views/Product/Products");
const FoodProducts = () => import("../views/Product/FoodProducts");
const FoodEditProduct = () => import("../views/Product/FoodEditProduct");
const ProductsMeat = () => import("../views/Product/ProductsMeat");
const EditProductMeat = () => import("../views/Product/EditProductMeat");
const EditProduct = () => import("../views/Product/EditProduct");
const CloneProduct = () => import("../views/Product/EditProduct");
const ApproveRequests = () => import("../views/Product/ApproveRequests");
const ViewProduct = () => import("../views/Product/ViewProduct");
//const ViewRatings = () => import("../views/Product/ProductRatings");
const Taxes = () => import("../views/Product/Taxes/Taxes");
const Media = () => import("../views/Product/Media");
const ProductOrder = () => import("../views/Product/ProductOrder");
const ProductRatings = () => import("../views/Product/ProductRatings");
const BulkUpload = () => import("../views/Product/BulkUpload");
const BulkUpdate = () => import("../views/Product/BulkUpdate");
const Brands = () => import("../views/Product/Brands/Brands");
const ManageStock = () => import("../views/Product/ManageStock");

const Sellers = () => import("../views/Seller/Sellers");
const RegisteredSellers = () => import("../views/Seller/RegisteredSellers");
const RegisteredSellerDetails = () => import("../views/Seller/RegisteredSellerDetails");
const EditSeller = () => import("../views/Seller/EditSeller");
const SellerView = () => import("../views/Seller/SellerView");
const SellerProductsList = () => import("../views/Seller/SellerProductsList");
const EditSellerProduct = () => import("../views/Seller/EditSellerProduct");
const AdminSellerBulkUpload = () => import("../views/Sellers/BulkUpload");
const SellerCommissions = () => import("../views/Seller/Commissions/SellerCommissions")
const SellerWalletTransactions = () => import("../views/Seller/WalletTransactions/SellerWalletTransactions");
const SellerPendingPayouts = () => import("../views/Seller/SellerPendingPayouts");

// Marts (Super Mart Sellers)
const Marts = () => import("../views/Marts/Marts");
const MartOrders = () => import("../views/Marts/MartOrders");

//Home Slider Images
const HomeSliders = () => import("../views/HomeSliders/HomeSliders");


//Promo Code
const PromoCode = () => import("../views/PromoCode/PromoCode");

// What are you thinking
const WhatAreYouThinking = () => import("../views/WhatAreYouThinking");
const WhatAreYouThinkingAdd = () => import("../views/WhatAreYouThinking/Add");
const WhatAreYouThinkingEdit = () => import("../views/WhatAreYouThinking/Edit");

// Offers Management
const OffersManagement = () => import("../views/OffersManagement/Index");

// User Offers (Order Rewards & Banners)
const UserOffers = () => import("../views/UserOffers/Index");

//Seller Registration Helper
const SellerRegistrationHelper = () => import("../views/SellerRegistrationHelper/SellerRegistrationHelper");

//Setting - TIme Slots
const TimeSlots = () => import("../views/Setting/TimeSlots/TimeSlots");
//Setting - Store Settings
const StoreSettings = () => import("../views/Setting/StoreSettings");
//Setting - Units
const Units = () => import("../views/Product/Units/Units");

//Setting - Payment Methods
const PaymentMethods = () => import("../views/Setting/PaymentMethods");

//Setting - Notifications Settings
const NotificationSettings = () => import("../views/Setting/NotificationSettings");
//Setting - Contact Us
const ContactUs = () => import("../views/Setting/ContactUs");

//Setting - Contact Us
const AboutUs = () => import("../views/Setting/AboutUs");

//Setting - About Us & Contact Us
const AboutContact = () => import("../views/Setting/AboutContact");

// Brand Campaigns
const BrandCampaigns = () => import("../views/BrandCampaigns/BrandCampaigns");
const CreateBrandCampaign = () => import("../views/BrandCampaigns/CreateBrandCampaign");
const EditBrandCampaign = () => import("../views/BrandCampaigns/EditBrandCampaign");
const BrandCampaignProducts = () => import("../views/BrandCampaigns/BrandCampaignProducts");
const AddCampaignProduct = () => import("../views/BrandCampaigns/AddCampaignProduct");
const EditCampaignProducts = () => import("../views/BrandCampaigns/EditCampaignProducts");

//Setting - Privacy Policy
const PrivacyPolicy = () => import("../views/Setting/PrivacyPolicy");
//Setting - Delivery Boy
const PrivacyPolicyDeliveryBoy = () => import("../views/Setting/PrivacyPolicyDeliveryBoy");
//Setting - Manager App
const PrivacyPolicyManagerApp = () => import("../views/Setting/PrivacyPolicyManagerApp");
//Setting - Seller
const PrivacyPolicySeller = () => import("../views/Setting/PrivacyPolicySeller");

//Setting - ApiKey
const ApiKey = () => import("../views/Setting/ApiKey");
const FirebaseSettings = () => import("../views/Setting/FirebaseSettings");
const SmsSettings = () => import("../views/Setting/SmsSettings");
const SmsTemplates = () => import("../views/Setting/SmsTemplates/SmsTemplates");
const SeoSettings = () => import("../views/Setting/SeoSettings/SeoSettings");

//Notifications - Send Notifications
const Notifications = () => import("../views/Notifications/Notifications");
const NotificationsAllIndex = () => import("../views/NotificationsAll/Index");
const NotificationsAllCreate = () => import("../views/NotificationsAll/Create");
const NotificationAnalytics = () => import("../views/NotificationAnalytics/NotificationAnalytics");
const RefundsDisputes = () => import("../views/RefundsDisputes/RefundsDisputes");
const PayoutsSettlement = () => import("../views/PayoutsSettlement/PayoutsSettlement");
const Emails = () => import("../views/Emails/Emails");
const EmailTemplates = () => import("../views/Emails/EmailTemplates");
// Featured Section to show products
const Sections = () => import("../views/Sections/Sections");
const SectionsOrder = () => import("../views/Sections/SectionsOrder");
// New Offers for Customers
const Offers = () => import("../views/Offers/Offers");
const PopupOffer = () => import("../views/Offers/PopupOffer");

// DeliveryBoys
const DeliveryBoys = () => import("../views/DeliveryBoys/DeliveryBoys");
const EditDeliveryBoy = () => import("../views/DeliveryBoys/EditDeliveryBoy");
const ViewDeliveryBoy = () => import("../views/DeliveryBoys/DeliveryBoyView");
const DeliveryBoyUnsettledPayouts = () => import("../views/DeliveryBoys/DeliveryBoyUnsettledPayouts");
const DeliveryBoyPendingPayouts = () => import("../views/DeliveryBoys/DeliveryBoyPendingPayouts");
const ManualPayments = () => import("../views/DeliveryBoys/ManualPayments");
const RegisteredDeliveryBoys = () => import("../views/DeliveryBoys/RegisteredDeliveryBoys");
const ProblematicDrivers = () => import("../views/DeliveryBoys/ProblematicDrivers");
const RegisteredDeliveryBoyDetails = () => import("../views/DeliveryBoys/DeliveryBoyDetails");

// Fund Transfers
const FundTransfers = () => import("../views/DeliveryBoys/FundTransfers/FundTransfers");

// Cash Collection
const CashCollection = () => import("../views/DeliveryBoys/CashCollection/CashCollection");


// Front End Header
const GeneralWebSettings = () => import("../views/WebSetings/GeneralWebSettings");

// Front End About
const FrontEndAbout = () => import("../views/WebSetings/FrontEndAbout");

// Front End Policies
const FrontEndPolicies = () => import("../views/WebSetings/FrontEndPolicies");

// Social Media
const SocialMedia = () => import("../views/WebSetings/SocialMedia/SocialMedia");




//Customers
const Customers = () => import("../views/Customers/Customers");
const CustomerView = () => import("../views/Customers/CustomerView");

//Customers Wallet Transactions
const WalletTransactions = () => import("../views/Customers/WalletTransactions/WalletTransactions");
// Transactions
const Transactions = () => import("../views/Customers/Transactions");
// Paytm Transactions
const PaytmTransactions = () => import("../views/PaytmTransactions/Index");
// Wishlists
const Wishlists = () => import("../views/Customers/Wishlists");

// Customer Messages
const CustomerMessages = () => import("../views/Customers/CustomerMessages");

// Customer Support
const CustomerSupport = () => import("../views/CustomerSupport/Index");
const ViewCustomerReport = () => import("../views/CustomerSupport/ViewReport");

// Customer Suggestions
const CustomerSuggestions = () => import("../views/CustomerSuggestions/Index");

// Withdrawal Requests
const WithdrawalRequests = () => import("../views/WithdrawalRequests/WithdrawalRequests");

// Return Requests
const ReturnRequests = () => import("../views/ReturnRequests/ReturnRequests");

// Customer App Home Screen
const CustomerAppSections = () => import("../views/CustomerAppHomeScreen/Sections");
const CustomerAppProducts = () => import("../views/CustomerAppHomeScreen/Products");
const CustomerAppSectionOrder = () => import("../views/CustomerAppHomeScreen/SectionOrder");

// Sales Reports
const SalesReports = () => import("../views/Reports/SalesReports");
const PosReports = () => import("../views/Reports/PosReports");

// Product Sales Reports
const ProductSalesReports = () => import("../views/Reports/ProductSalesReports");

// System Users
const SystemUsers = () => import("../views/SystemUsers/SystemUsers");
const Role = () => import("../views/Role/Role");
// User Management (separate dashboard)
const UserManagement = () => import("../views/UserManagement/UserManagement");
// Rider Analytics (separate dashboard, under Tracking & Analytics)
const RiderAnalytics = () => import("../views/RiderAnalytics/RiderAnalytics");


// Errors
const PageNotFound = () => import("../views/errors/404");
const Unauthorized = () => import("../views/errors/403");
const ServerError = () => import("../views/errors/500");

//PurchaseCode for System Registration
const PurchaseCode = () => import("../views/Setting/PurchaseCode");
const SystemUpdater = () => import("../views/Setting/SystemUpdater");
// ShippingMethods
const ShippingMethods = () => import("../views/Setting/ShippingMethods");

// Newsletter
const Newsletter = () => import("../views/Newsletter");

// Location
const City = () => import("../views/City/City");
const EditCity = () => import("../views/City/EditCity");
const DeliverableArea = () => import("../views/City/DeliverableArea");
//Faqs
const Faqs = () => import("../views/Faqs/Faqs");
// ProductInfo for  Sold Out Products
const ProductInfo = () => import("../views/Dashboard/ProductInfo");

// Languages
const Languages = () => import("../views/Languages/Languages")

// Countries
const Countries = () => import("../views/Countries/Countries")

/***********************************************************/
/*Seller*/
const SellerRegister = () => import("../views/Sellers/SellerRegister");
const SellerDetails = () => import("../views/Sellers/SellerDetails");
const SellerLogin = () => import("../views/Sellers/SellerLogin");

const SellerDashboard = () => import("../views/Sellers/Dashboard");
const SellerProductInfo = () => import("../views/Sellers/ProductInfo");
const SellerOrders = () => import("../views/Sellers/Orders");
const SellerViewOrder = () => import("../views/Orders/ViewOrder");
const SellerInvoiceOrder = () => import("../views/Orders/InvoiceOrder");

const SellerCategories = () => import("../views/Sellers/Categories");
const SellerReturnRequests = () => import("../views/ReturnRequests/ReturnRequests");
const SellerWithdrawalRequests = () => import("../views/Sellers/WithdrawalRequests/WithdrawalRequests");
const SellerProductSalesReports = () => import("../views/Sellers/ProductSalesReports");
const SellerSalesReports = () => import("../views/Sellers/SalesReports");
const SellerTaxes = () => import("../views/Sellers/Taxes");
const SellerBrands = () => import("../views/Sellers/Brands");
const SellerUnits = () => import("../views/Sellers/Units");

const SellerProducts = () => import("../views/Product/Products");
const SellerEditProduct = () => import("../views/Product/EditProduct");
const SellerViewProduct = () => import("../views/Product/ViewProduct");
const SellerProductRatings = () => import("../views/Product/ProductRatings");
const SellerCloneProduct = () => import("../views/Product/EditProduct");
const SellerManageStock = () => import("../views/Product/ManageStock");
const SellerMedia = () => import("../views/Product/Media");
const SellerSettings = () => import('../views/Settings');
const SellerProfile = () => import("../views/Seller/EditSeller");
const SellerPointOfSale = () => import("../views/Sellers/PointOfSale");
const SellerPosReports = () => import("../views/Sellers/PosReport");
//const SellerWalletTransactions = () => import("../views/Seller/WalletTransactions/SellerWalletTransactions");
//const SellerWalletTransactions = () => import("../views/Seller/SellerWalletTransactions");
/***********************************************************/
/*Delivery Boy*/
const DeliveryBoyRegister = () => import("../views/DeliveryBoy/DeliveryBoyRegister");
const DeliveryBoyDetails = () => import("../views/DeliveryBoy/DeliveryBoyDetails");
const DeliveryBoyLogin = () => import("../views/DeliveryBoy/DeliveryBoyLogin");

const DeliveryBoyDashboard = () => import("../views/DeliveryBoy/Dashboard");

const DeliveryBoyOrders = () => import("../views/DeliveryBoy/Orders");
const DeliveryBoyOrder = () => import("../views/Orders/ViewOrder");
const DeliveryBoyReturnRequests = () => import("../views/ReturnRequests/ReturnRequests");
const DeliveryBoyWithdrawalRequests = () => import("../views/DeliveryBoy/WithdrawalRequests/WithdrawalRequests");
const DeliveryBoyFundTransfers = () => import("../views/DeliveryBoy/FundTransfers");
const DeliveryBoyCashCollection = () => import("../views/DeliveryBoy/CashCollection");

const DeliveryBoyProductSalesReports = () => import("../views/DeliveryBoy/ProductSalesReports");
const DeliveryBoySalesReports = () => import("../views/DeliveryBoy/SalesReports");
const DeliverySettings = () => import('../views/Settings');
const DeliveryProfile = () => import("../views/DeliveryBoys/EditDeliveryBoy");
const DeliveryBoyInvoiceOrder = () => import("../views/Orders/InvoiceOrder");

const DeliveryBoyViewProduct = () => import("../views/Product/ViewProduct");

// Delivery Boy Gig System
const GigsList = () => import("../views/DeliveryBoy/Gigs/GigsList");
const GigForm = () => import("../views/DeliveryBoy/Gigs/GigForm");
const GigSlots = () => import("../views/DeliveryBoy/Gigs/GigSlots");
const SlotBookings = () => import("../views/DeliveryBoy/Gigs/SlotBookings");
const GigCalendar = () => import("../views/DeliveryBoy/Gigs/GigCalendar");
const GigBookings = () => import("../views/DeliveryBoy/Gigs/GigBookings");
const LiveTracking = () => import("../views/DeliveryBoy/Tracking/LiveTracking");

// Driver Management - New Sidebars
const PerformanceDashboard = () => import("../views/DeliveryBoys/PerformanceDashboard");
const Leaderboard = () => import("../views/DeliveryBoys/Leaderboard");
const DriverRatings = () => import("../views/DeliveryBoys/DriverRatings");
const TrainingModules = () => import("../views/DeliveryBoys/TrainingModules");
const IssueTracking = () => import("../views/DeliveryBoys/IssueTracking");
const DriverIssueView = () => import("../views/DeliveryBoys/DriverIssues/DriverIssueView");
const DriverNotifications = () => import("../views/DeliveryBoys/DriverNotifications");

// Delivery Vehicles
const VehiclesList = () => import("../views/DeliveryBoy/Vehicles/VehiclesList");
const VehicleForm = () => import("../views/DeliveryBoy/Vehicles/VehicleForm");

// Store Locations
const StoreLocationsList = () => import("../views/StoreLocation/StoreLocationsList");
const StoreLocationForm = () => import("../views/StoreLocation/StoreLocationForm");

const SessionHistory = () => import("../views/DeliveryBoy/Tracking/SessionHistory");
const DailyReports = () => import("../views/DeliveryBoy/Tracking/DailyReports");
const OffersList = () => import("../views/DeliveryBoy/Offers/OffersList");
const OfferForm = () => import("../views/DeliveryBoy/Offers/OfferForm");
const ActiveOffers = () => import("../views/DeliveryBoy/Offers/ActiveOffers");
const PartnerProgress = () => import("../views/DeliveryBoy/Offers/PartnerProgress");
const OfferPayouts = () => import("../views/DeliveryBoy/Offers/OfferPayouts");


let router = new Router({
    //mode: "hash", // https://router.vuejs.org/api/#mode
    mode: "history",
    scrollBehavior: () => ({y: 0}),
    routes: configRoutes(),
    //linkActiveClass: 'active',
});

var roleSuperAdmin = "Super Admin";
var roleSeller = "Seller";
var roleDeliveryBoy = "Delivery Boy";
var roleName = "Super Admin";
var appName = window.appName;

router.beforeEach((to, from, next) => {
    //if (to.matched.some(record => record.meta.requiresAuth) ) {
    if(isInstalled) {
        if(to.name == 'install'){
            router.push('/404').catch(()=>{});
        }
        var title = to.meta && to.meta.title ? to.meta.title : 'Dashboard';
        window.document.title = title + ' - ' + appName;

        Auth.validate(to.path);
        var nonloginRoute = ['install', 'login', 'seller_register', 'delivery_boy_register', 'forgot_password', 'reset_password', 'seller_login', 'delivery_boy_login'];
        if (!nonloginRoute.includes(to.name)) {
            if (Auth.check()) {
                if (!Auth.user || !Auth.user.role) {
                    // User data is incomplete or missing, clear session and redirect to login
                    window.localStorage.clear();
                    router.push('/login');
                    return;
                }
                roleName = Auth.user.role.name;
                //Seller
                if (Auth.user.role_id === 3 && Auth.user.seller_status === 0) {
                    if (to.name == "seller_details") {
                        next();
                        return;
                    }
                    router.push('/seller/details');
                    return;
                } else if (Auth.user.role_id === 3 && Auth.user.seller_status === 1 && to.name == "Dashboard") {

                    if (to.name == "seller_dashboard") {
                        next();
                        return;
                    }
                    router.push('/seller/dashboard');
                    return;
                } else if (Auth.user.role_id === 4 && Auth.user.delivery_boy_status === 0) {
                    //Delivery boy
                    if (to.name == "delivery_boy_details") {
                        next();
                        return;
                    }
                    router.push('/delivery_boy/details');
                    return;
                } else if (Auth.user.role_id === 4 && Auth.user.delivery_boy_status === 1 && to.name == "Dashboard") {
                    //Delivery boy
                    if (to.name == "deliveryBoy_dashboard") {
                        next();
                        return;
                    }
                    router.push('/delivery_boy/dashboard');
                    return;
                } else {

                    //Check Role Wise Access
                    if (to.meta.role && !to.meta.role.includes(roleName)) {
                        if (roleName == roleSeller) {
                            router.push('seller', () => {
                            });
                            return;
                        } else if (roleName == roleDeliveryBoy) {
                            router.push('delivery_boy', () => {
                            });
                            return;
                        } else {
                            router.push('dashboard', () => {
                            });
                            return;
                        }
                    }

                    next();
                    return;
                }

            } else {
                router.push('/login').catch(()=>{});
            }
        } else {
            next();
        }
        
    }else{
        next();
    }

});
export default router;

function configRoutes() {
    var roleSuperAdmin = "Super Admin";
    var roleAdmin = "Admin";
    var roleSeller = "Seller";
    var roleDeliveryBoy = "Delivery Boy";
    var roleName = "Super Admin";

    var adminSuperadminRoles = [roleSuperAdmin,roleAdmin];
  var sellerRoles = [roleSeller];
     var deliveryBoyRoles = [roleDeliveryBoy];

async function fetchData() {
    try {
        const response = await axios.get(window.baseUrl + '/api/role');
        const data = response.data.data.map(role => role.name);
        const roles = data;
        return roles; // Return adminRoles if needed
    } catch (error) {
        // Handle error
        console.error('Error fetching roles:', error);
    }
}
let adminRoles;
fetchData();
    fetchData().then(result => {
        const otherroles =  result.filter(role => role !== 'Seller' && role !== 'Delivery Boy');
        const adminRoles = otherroles;
        
    });
         return [
        {
            path: "/install",
            name: "install",
            component: Install,
            meta: {
                title:'Install'
            },
        },
        {
            path: "/",
            // redirect: "/dashboard",
            name: "Home",
            component: TheContainer,
            meta: {
                requiresAuth: true,
                role: adminRoles,
                title:'Admin Dashboard'
            },
            redirect: (to) => {
                return Auth.check() ? '/dashboard' : '/login';
            },
            children: [
                { path: "/unauthorized", component: Unauthorized, meta: { title:'Unauthorized' } },
                {
                    path: "dashboard",
                    name: "Dashboard",
                    component: Dashboard,
                    meta: {
                        requiresAuth: true,
                        role: adminRoles,
                        title:'Admin Dashboard'
                    },
                },
                {
                    path: "orders",
                    name: "Orders",
                    component: Orders,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Orders'
                    },
                },
                {
                    path: "order-analytics",
                    name: "OrderAnalytics",
                    component: OrderAnalytics,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Order Analytics'
                    },
                },
                {
                    path: "profit-loss",
                    name: "ProfitLossComparison",
                    component: ProfitLossComparison,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Profit / Loss'
                    },
                },
                {
                    path: "user-analytics",
                    name: "UserAnalytics",
                    component: UserAnalytics,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'User Analytics'
                    },
                },
                {
                    path: "merchant-analytics",
                    name: "MerchantAnalytics",
                    component: MerchantAnalytics,
                    meta: {
                        permission: 'seller_list',
                        role: adminRoles,
                        title:'Merchant Analytics'
                    },
                },
                {
                    // Old sidebar path, kept so existing links/bookmarks land on
                    // the renamed page rather than 404.
                    path: "seller-analytics",
                    redirect: { name: "MerchantAnalytics" },
                },
                {
                    path: "delivery-boy-analytics",
                    name: "DeliveryBoyAnalytics",
                    component: DeliveryBoyAnalytics,
                    meta: {
                        permission: 'delivery_boy_list',
                        role: adminRoles,
                        title:'Delivery Boy Analytics'
                    },
                },
                {
                    path: "preorders",
                    name: "PreOrders",
                    component: PreOrders,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Pre Orders'
                    },
                },
                {
                    path: "preorders/store/:storeId",
                    name: "StorePreOrders",
                    component: StorePreOrders,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Store Pre Orders'
                    },
                },
                {
                    path: "preorder-items",
                    name: "PreOrderItems",
                    component: PreOrderItems,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Pre Order Items'
                    },
                },
                {
                    path: "preorder-items/add",
                    name: "AddPreOrderItems",
                    component: AddPreOrderItems,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Add Pre Order Items'
                    },
                },
                {
                    path: "self_pickup_orders",
                    name: "SelfPickupOrders",
                    component: SelfPickupOrders,
                    meta: {
                        permission: 'self_pickup_order_list',
                        role: adminRoles,
                        title:'Self Pickup Orders'
                    },
                },
                {
                    path: "self_pickup_orders/view/:id",
                    name: "ViewSelfPickupOrder",
                    component: ViewSelfPickupOrder,
                    meta: {
                        permission: 'self_pickup_order_list',
                        role: adminRoles,
                        title:'Self Pickup Order View'
                    },
                },
                {
                    path: "orders/stuck",
                    name: "StuckOrders",
                    component: StuckOrders,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Stuck Orders'
                    },
                },
                {
                    path: "orders/view/:id",
                    name: "ViewOrder",
                    component: ViewOrder,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Order View'

                    },
                },
                {
                    path: "orders/invoice/:id",
                    name: "InvoiceOrder",
                    component: InvoiceOrder,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Invoice Order'
                    },
                },
                
                {
                    path: "notification_panel",
                    name: "NotificationPanel",
                    component: NotificationPanel,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Notification'
                    },
                },
                {
                    path: "manage_categories/:create",
                    name: "manage_categories_create",
                    component: ManageCategories,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Categories'

                    },
                },
                {
                    path: "manage_categories",
                    name: "manage_categories",
                    component: ManageCategories,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Categories'

                    },
                },
                {
                    path: "supermart/manage_categories/:create?",
                    name: "supermart_manage_categories",
                    component: CategorySuperMartManageCategories,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Categories'

                    },
                },
                {
                    path: "supermart_manage_categories",
                    name: "supermart_manage_categories",
                    component: CategorySuperMartManageCategories,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Categories'

                    },
                },

                {
                    path: "categories_order",
                    name: "categories_order",
                    component: CategoriesOrder,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Categories Order'

                    },
                },
                {
                    path: "subcategories",
                    name: "Subcategories",
                    component: SubCategories,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'SubCategories'

                    },
                },
                {
                    path: "subcategories/:id",
                    name: "Subcategories_edit",
                    component: SubCategories,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles

                    },
                },
                {
                    path: "manage_products",
                    name: "ManageProducts",
                    component: Products,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Manage Products'

                    },
                },
                {
                    path: "food_products",
                    name: "FoodProducts",
                    component: FoodProducts,
                    meta: {
                        permission: 'product_list',
                        role: adminRoles,
                        title: 'Food Products',
                    },
                },
                {
                    path: "food_products/create",
                    name: "FoodCreateProduct",
                    component: FoodEditProduct,
                    meta: {
                        permission: 'product_create',
                        role: adminRoles,
                        title: 'Create Food Product',
                    },
                },
                {
                    path: "food_products/edit/:id",
                    name: "FoodEditProduct",
                    component: FoodEditProduct,
                    meta: {
                        permission: 'product_update',
                        role: adminRoles,
                        title: 'Edit Food Product',
                    },
                },
                {
                    path: "manage_meat_products",
                    name: "ManageMeatProducts",
                    component: ProductsMeat,
                    meta: {
                        permission: 'product_list',
                        role: adminRoles,
                        title:'Chicken & Meat Products'
                    },
                },
                {
                    path: "manage_meat_products/create",
                    name: "CreateMeatProduct",
                    component: EditProductMeat,
                    meta: {
                        permission: 'product_create',
                        role: adminRoles,
                        title:'Create Meat Product'
                    },
                },
                {
                    path: "manage_meat_products/edit/:id",
                    name: "EditMeatProduct",
                    component: EditProductMeat,
                    props: true,
                    meta: {
                        permission: 'product_update',
                        role: adminRoles,
                        title:'Edit Meat Product'
                    },
                },
                {
                    path: "approve_requests",
                    name: "ApproveRequests",
                    component: ApproveRequests,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Approve Requests'

                    },
                },
                {
                    path: "manage_products/create",
                    name: "Create Product",
                    component: EditProduct,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Create Product'

                    },
                },
                {
                    path: "manage_products/edit/:id",
                    name: "EditProduct",
                    component: EditProduct,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Edit Product'

                    },
                },
                {
                    path: "manage_products/view/:id",
                    name: "ViewProduct",
                    component: ViewProduct,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Product View'

                    },
                },
                {
                    path: "product_ratings/view/:id",
                    name: "ProductRatings",
                    component: ProductRatings,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Product View'

                    },
                },
                {
                    path: "manage_products/clone/:id/:clone",
                    name: "CloneProduct",
                    component: CloneProduct,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Clone Product'

                    },
                },
                {
                    path: "bulk_upload",
                    name: "BulkUpload",
                    component: BulkUpload,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Bulk Upload'
                    },
                },
                {
                    path: "bulk_update",
                    name: "BulkUpdate",
                    component: BulkUpdate,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Bulk Update'
                    },
                },
                {
                    path: "taxes",
                    name: "Taxes",
                    component: Taxes,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Taxes'

                    },
                },
                {
                    path: "brands",
                    name: "Brands",
                    component: Brands,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Brands'

                    },
                },
                {
                    path: "manage_stock",
                    name: "Stock Management",
                    component: ManageStock,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Stock Management'

                    },
                },
                {
                    path: "registered_sellers",
                    name: "RegisteredSellers",
                    component: RegisteredSellers,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Seller Requests'
                    },
                },
                {
                    path: "registered_sellers/view/:id",
                    name: "RegisteredSellerDetails",
                    component: RegisteredSellerDetails,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Seller Details'
                    },
                },
                {
                    path: "sellers",
                    name: "Sellers",
                    component: Sellers,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Sellers'

                    },
                },
                {
                    path: "sellers/create",
                    name: "CreateSellers",
                    component: EditSeller,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Create Sellers'

                    },
                },
                {
                    path: "sellers/edit/:id",
                    name: "EditSeller",
                    component: EditSeller,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Edit Seller'

                    },
                },
                {
                    path: "sellers/view/:id",
                    name: "SellerView",
                    component: SellerView,
                    props: true,
                    meta: {
                        permission: 'seller_list',
                        role: adminRoles,
                        title:'Seller Details'
                    },
                },
                {
                    path: "sellers/products",
                    name: "SellerProductsList",
                    component: SellerProductsList,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Seller Products'
                    },
                },
                {
                    path: "sellers/products/edit/:id",
                    name: "EditSellerProduct",
                    component: EditSellerProduct,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Edit Seller Product'
                    },
                },
                {
                    path: "sellers/bulk-upload",
                    name: "AdminSellerBulkUpload",
                    component: AdminSellerBulkUpload,
                    meta: {
                        permission: 'seller_list',
                        role: adminRoles,
                        title: 'Seller Bulk Product Upload',
                    },
                },
                {
                    path: "seller-pending-payouts",
                    name: "SellerPendingPayouts",
                    component: SellerPendingPayouts,
                    meta: {
                        permission: 'seller_list',
                        role: adminRoles,
                        title: 'Seller Pending Payouts',
                    },
                },
                {
                    path: "seller_commissions",
                    name: "Seller Commissions",
                    component: SellerCommissions,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Seller Commissions'

                    },
                },
                {
                    path: "seller_wallet_transactions",
                    name: "Seller Wallet Transactions",
                    component: SellerWalletTransactions,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Seller Wallet Transactions'

                    },
                },
                // Marts (Super Mart Sellers)
                {
                    path: "marts",
                    name: "Marts",
                    component: Marts,
                    meta: {
                        permission: 'seller_list',
                        role: adminRoles,
                        title:'Marts'
                    },
                },
                {
                    path: "mart_orders",
                    name: "MartOrders",
                    component: MartOrders,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Mart Orders'
                    },
                },
                {
                    path: "home_sliders/:create",
                    name: "HomeSlidersCreate",
                    component: HomeSliders,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Home Sliders Create'

                    },
                },
                {
                    path: "home_sliders",
                    name: "HomeSliders",
                    component: HomeSliders,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Home Sliders'

                    },
                },
                {
                    path: "promo_code/:create",
                    name: "promo_code_create",
                    component: PromoCode,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Promo Code Create'
                    },
                },
                {
                    path: "promo_code",
                    name: "promo_code",
                    component: PromoCode,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Promo Code'
                    },
                },
                {
                    path: "what-are-you-thinking",
                    name: "WhatAreYouThinking",
                    component: WhatAreYouThinking,
                    meta: {
                        permission: 'product_list',
                        role: adminRoles,
                        title:'What are you thinking?'
                    },
                },
                {
                    path: "what-are-you-thinking/create",
                    name: "WhatAreYouThinkingCreate",
                    component: WhatAreYouThinkingAdd,
                    meta: {
                        permission: 'product_list',
                        role: adminRoles,
                        title:'Add Thinking Item'
                    },
                },
                {
                    path: "what-are-you-thinking/edit/:id",
                    name: "WhatAreYouThinkingEdit",
                    component: WhatAreYouThinkingEdit,
                    meta: {
                        permission: 'product_list',
                        role: adminRoles,
                        title:'Edit Thinking Item'
                    },
                },
                {
                    path: "offers-management",
                    name: "OffersManagement",
                    component: OffersManagement,
                    meta: {
                        permission: 'offers_list',
                        role: adminRoles,
                        title:'Offers Management'
                    },
                },
                {
                    path: "user-offers",
                    name: "UserOffers",
                    component: UserOffers,
                    meta: {
                        permission: 'offers_list',
                        role: adminRoles,
                        title:'User Offers'
                    },
                },
                {
                    path: "seller-registration-helper/:create",
                    name: "seller_registration_helper_create",
                    component: SellerRegistrationHelper,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Seller Registration Helper Create'
                    },
                },
                {
                    path: "seller-registration-helper",
                    name: "seller_registration_helper",
                    component: SellerRegistrationHelper,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Seller Registration Helper'
                    },
                },
                {
                    path: "delivery_settings",
                    name: "Delivery Settings",
                    component: TimeSlots,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Delivery Settings'

                    },
                },
                {
                    path: "store_settings",
                    name: "Store Settings",
                    component: StoreSettings,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Store Settings'

                    },
                },
                {
                    path: "units",
                    name: "Units",
                    component: Units,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Units'

                    },
                },
                {
                    path: "payment_methods",
                    name: "Payment Methods",
                    component: PaymentMethods,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Payment Methods'

                    },
                },
                {
                    path: "contact_us",
                    name: "Contact Us",
                    component: ContactUs,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Contact Us'

                    },
                },
                {
                    path: "about_us",
                    name: "About Us",
                    component: AboutUs,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'About Us'

                    },
                },
                {
                    path: "privacy_policy",
                    name: "Privacy Policy",
                    component: PrivacyPolicy,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Privacy Policy'

                    },
                },
                {
                    path: "privacy_policy_delivery_boy",
                    name: "Privacy Policy Delivery Boy",
                    component: PrivacyPolicyDeliveryBoy,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Privacy Policy Delivery Boy'

                    },
                },
                {
                    path: "privacy_policy_manager_app",
                    name: "Privacy Policy Manager App",
                    component: PrivacyPolicyManagerApp,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Privacy Policy Manager App'

                    },
                },
                {
                    path: "privacy_policy_seller",
                    name: "Privacy Policy Seller",
                    component: PrivacyPolicySeller,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Privacy Policy Seller'
                    },
                },
                {
                    path: "about_contact",
                    name: "About Us & Contact Us",
                    component: AboutContact,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title: 'About Us & Contact Us'
                    },
                },
                {
                    path: "brand-campaigns",
                    name: "Brand Campaigns",
                    component: BrandCampaigns,
                    meta: {
                        permission: 'product_list',
                        role: adminRoles,
                        title: 'Brand Campaigns'
                    },
                },
                {
                    path: "brand-campaigns/create",
                    name: "Create Brand Campaign",
                    component: CreateBrandCampaign,
                    meta: {
                        permission: 'product_create',
                        role: adminRoles,
                        title: 'Create Brand Campaign'
                    },
                },
                {
                    path: "brand-campaigns/:id/edit",
                    name: "Edit Brand Campaign",
                    component: EditBrandCampaign,
                    meta: {
                        permission: 'product_create',
                        role: adminRoles,
                        title: 'Edit Brand Campaign'
                    },
                },
                {
                    path: "brand-campaign-products",
                    name: "Campaign Products",
                    component: BrandCampaignProducts,
                    meta: {
                        permission: 'product_list',
                        role: adminRoles,
                        title: 'Campaign Products'
                    },
                },
                {
                    path: "brand-campaign-products/add",
                    name: "Add Campaign Product",
                    component: AddCampaignProduct,
                    meta: {
                        permission: 'product_create',
                        role: adminRoles,
                        title: 'Add Campaign Product'
                    },
                },
                {
                    path: "brand-campaign-products/edit/:id",
                    name: "Edit Campaign Products",
                    component: EditCampaignProducts,
                    meta: {
                        permission: 'product_edit',
                        role: adminRoles,
                        title: 'Edit Campaign Products'
                    },
                },
                {
                    path: "api_key",
                    name: "Secret Key",
                    component: ApiKey,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Secret Key'

                    },
                },
                {
                    path: "firebase-settings",
                    name: "FirebaseSettings",
                    component: FirebaseSettings,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Firebase Settings'
                    },
                },
                {
                    path: "sms-settings",
                    name: "SmsSettings",
                    component: SmsSettings,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'SMS Settings'
                    },
                },
                {
                    path: "sms-templates",
                    name: "SmsTemplates",
                    component: SmsTemplates,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Sms Templates'
                    },
                },

                {
                    path: "seo-settings",
                    name: "SeoSettings",
                    component: SeoSettings,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'SEO Settings'
                    },
                },

                {
                    path: "notifications/:create",
                    name: "SendNotifications_create",
                    component: Notifications,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Send Notification'

                    },
                },
                {
                    path: "notifications",
                    name: "SendNotifications",
                    component: Notifications,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Manage Notifications'

                    },
                },

                // Notifications All - New
                {
                    path: "notifications-all",
                    name: "NotificationsAllIndex",
                    component: NotificationsAllIndex,
                    meta: {
                        permission: 'notification_list',
                        role: adminRoles,
                        title:'All Notifications'
                    },
                },
                {
                    path: "notifications-all/create",
                    name: "NotificationsAllCreate",
                    component: NotificationsAllCreate,
                    meta: {
                        permission: 'notification_create',
                        role: adminRoles,
                        title:'Send Notification'
                    },
                },
                {
                    path: "notification-analytics",
                    name: "NotificationAnalytics",
                    component: NotificationAnalytics,
                    meta: {
                        permission: 'notification_list',
                        role: adminRoles,
                        title:'Notification Analytics'
                    },
                },
                {
                    path: "refunds-disputes",
                    name: "RefundsDisputes",
                    component: RefundsDisputes,
                    meta: {
                        role: adminRoles,
                        title:'Refunds & Disputes'
                    },
                },
                {
                    path: "payouts-settlement",
                    name: "PayoutsSettlement",
                    component: PayoutsSettlement,
                    meta: {
                        role: adminRoles,
                        title:'Payouts & Settlement'
                    },
                },

                {
                    path: "emails/:create",
                    name: "SendEmails_create",
                    component: EmailTemplates,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Send Email'

                    },
                },
                {
                    path: "email_templates",
                    name: "EmailTemplates",
                    component: EmailTemplates,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Manage Email Templates'

                    },
                },
                {
                    path: "emails/:create",
                    name: "SendEmails_create",
                    component: Emails,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Send Email'

                    },
                },
                {
                    path: "emails",
                    name: "SendEmails",
                    component: Emails,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Manage Emails'

                    },
                },
                {
                    path: "notification_settings",
                    name: "NotificationsSettings",
                    component: NotificationSettings,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Notifications Settings'

                    },
                },

                {
                    path: "sections/:create",
                    name: "addSection",
                    component: Sections,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Section'
                    },
                },
                {
                    path: "sections",
                    name: "FeaturedSections",
                    component: Sections,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Featured Sections'
                    },
                },
                {
                    path: "section_order",
                    name: "section_order",
                    component: SectionsOrder,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Secctions Order'

                    },
                },

                {
                    path: "offers/:create",
                    name: "Offers_create",
                    component: Offers,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Offer Create'
                    },
                },
                {
                    path: "offers",
                    name: "Offers",
                    component: Offers,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Offers'

                    },
                },
                {
                    path: "popup",
                    name: "PopupOffer",
                    component: PopupOffer,
                    meta: {
                        permission: 'popup_offer',
                        role: adminRoles,
                        title:'Popup Offer'
                    },
                },
                {
                    path: "offers",
                    name: "New Offers Image",
                    component: Offers,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'New Offers Image'

                    },
                },
                /*{
                    path: "delivery_boys/:create",
                    name: "DeliveryBoys_create",
                    component: DeliveryBoys,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Delivery Boy Create'

                    },
                },*/
                {
                    path: "delivery_boys/create",
                    name: "CreateDeliveryBoy",
                    component: EditDeliveryBoy,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Create Delivery Boy'

                    },
                },
                {
                    path: "delivery_boys/edit/:id",
                    name: "EditDeliveryBoy",
                    component: EditDeliveryBoy,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Edit Delivery Boy'

                    },
                },
                {
                    path: "delivery_boys/view/:id",
                    name: "ViewDeliveryBoy",
                    component: ViewDeliveryBoy,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'View Delivery Boy'
                    },
                },
                {
                    path: "delivery_boys/:id/unsettled-payouts",
                    name: "DeliveryBoyUnsettledPayouts",
                    component: DeliveryBoyUnsettledPayouts,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Unsettled Payouts'
                    },
                },
                {
                    path: "delivery_boys/pending-payouts",
                    name: "DeliveryBoyPendingPayouts",
                    component: DeliveryBoyPendingPayouts,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Delivery Boy Pending Payouts'
                    },
                },
                {
                    path: "delivery_boys/manual-payments",
                    name: "ManualPayments",
                    component: ManualPayments,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Driver Manual Payments'
                    },
                },
                {
                    path: "registered_delivery_boys",
                    name: "RegisteredDeliveryBoys",
                    component: RegisteredDeliveryBoys,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Delivery Boys'

                    },
                },
                {
                    path: "delivery_boys/problematic",
                    name: "ProblematicDrivers",
                    component: ProblematicDrivers,
                    meta: {
                        permission: 'delivery_boy_list',
                        role: adminRoles,
                        title:'Problematic Drivers'
                    },
                },
                {
                    path: "delivery_boy_details/:id",
                    name: "DeliveryBoyDetails",
                    component: RegisteredDeliveryBoyDetails,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Delivery Boy Details'
                    },
                },
                {
                    path: "delivery_boys",
                    name: "DeliveryBoys",
                    component: DeliveryBoys,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Delivery Boys'

                    },
                },
                {
                    path: "fund_transfers",
                    name: "Fund Transfers",
                    component: FundTransfers,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Fund Transfers'

                    },
                },
                {
                    path: "cash_collection",
                    name: "Delivery boy cash",
                    component: CashCollection,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Delivery boy cash'

                    },
                },

                // Delivery Boy Gig System Routes
                {
                    path: "delivery-boy/gigs/list",
                    name: "Gigs List",
                    component: GigsList,
                    meta: {
                        permission: 'delivery_boy_list',
                        role: adminRoles,
                        title:'Gigs List'
                    },
                },
                {
                    path: "delivery-boy/gigs/create",
                    name: "Create Gig",
                    component: GigForm,
                    meta: {
                        permission: 'delivery_boy_create',
                        role: adminRoles,
                        title:'Create Gig'
                    },
                },
                {
                    path: "delivery-boy/gigs/edit/:id",
                    name: "Edit Gig",
                    component: GigForm,
                    meta: {
                        permission: 'delivery_boy_edit',
                        role: adminRoles,
                        title:'Edit Gig'
                    },
                },
                {
                    path: "delivery-boy/gigs/:id/slots",
                    name: "Gig Slots",
                    component: GigSlots,
                    meta: {
                        permission: 'delivery_boy_list',
                        role: adminRoles,
                        title:'Gig Slots'
                    },
                },
                {
                    path: "delivery-boy/gigs/:id/slots/:slotId/bookings",
                    name: "Slot Bookings",
                    component: SlotBookings,
                    meta: {
                        permission: 'delivery_boy_list',
                        role: adminRoles,
                        title:'Slot Bookings'
                    },
                },
                {
                    path: "delivery-boy/gigs/calendar",
                    name: "Gig Calendar",
                    component: GigCalendar,
                    meta: {
                        permission: 'delivery_boy_list',
                        role: adminRoles,
                        title:'Gig Calendar'
                    },
                },
                {
                    path: "delivery-boy/gigs/bookings",
                    name: "Gig Bookings",
                    component: GigBookings,
                    meta: {
                        permission: 'delivery_boy_list',
                        role: adminRoles,
                        title:'Gig Bookings'
                    },
                },
                {
                    path: "delivery-boy/tracking/live",
                    name: "Live Tracking",
                    component: LiveTracking,
                    meta: {
                        permission: 'delivery_boy_list',
                        role: adminRoles,
                        title:'Live Tracking'
                    },
                },
                // New Driver Management Routes
                {
                    path: "delivery-boys/performance/dashboard",
                    name: "Performance Dashboard",
                    component: PerformanceDashboard,
                    meta: {
                        permission: 'driver_performance_view',
                        role: adminRoles,
                        title:'Performance Dashboard'
                    },
                },
                {
                    path: "delivery-boys/leaderboard",
                    name: "Rankings & Leaderboard",
                    component: Leaderboard,
                    meta: {
                        permission: 'driver_leaderboard_view',
                        role: adminRoles,
                        title:'Rankings & Leaderboard'
                    },
                },
                {
                    path: "delivery-boys/ratings",
                    name: "Driver Ratings",
                    component: DriverRatings,
                    meta: {
                        permission: 'driver_ratings_view',
                        role: adminRoles,
                        title:'Driver Ratings'
                    },
                },
                {
                    path: "delivery-boys/training/modules",
                    name: "Training Modules",
                    component: TrainingModules,
                    meta: {
                        permission: 'driver_training_manage',
                        role: adminRoles,
                        title:'Training Modules'
                    },
                },
                {
                    path: "delivery-boys/issues",
                    name: "Issue Tracking",
                    component: IssueTracking,
                    meta: {
                        permission: 'driver_issues_view',
                        role: adminRoles,
                        title:'Issue Tracking'
                    },
                },
                {
                    path: "delivery-boys/issues/view/:id",
                    name: "Driver Issue View",
                    component: DriverIssueView,
                    meta: {
                        permission: 'driver_issues_view',
                        role: adminRoles,
                        title:'Issue Details'
                    },
                },
                {
                    path: "delivery-boys/notifications",
                    name: "Driver Notifications",
                    component: DriverNotifications,
                    meta: {
                        permission: 'driver_notifications_manage',
                        role: adminRoles,
                        title:'Driver Notifications'
                    },
                },
                {
                    path: "delivery-boy/tracking/sessions",
                    name: "Session History",
                    component: SessionHistory,
                    meta: {
                        permission: 'delivery_boy_list',
                        role: adminRoles,
                        title:'Session History'
                    },
                },
                {
                    path: "delivery-boy/tracking/reports",
                    name: "Daily Reports",
                    component: DailyReports,
                    meta: {
                        permission: 'delivery_boy_list',
                        role: adminRoles,
                        title:'Daily Reports'
                    },
                },
                {
                    path: "delivery-boy/offers/list",
                    name: "Offers List",
                    component: OffersList,
                    meta: {
                        permission: 'delivery_boy_list',
                        role: adminRoles,
                        title:'Incentive Offers'
                    },
                },
                {
                    path: "delivery-boy/offers/create",
                    name: "Create Offer",
                    component: OfferForm,
                    meta: {
                        permission: 'delivery_boy_create',
                        role: adminRoles,
                        title:'Create Offer'
                    },
                },
                {
                    path: "delivery-boy/offers/edit/:id",
                    name: "Edit Offer",
                    component: OfferForm,
                    meta: {
                        permission: 'delivery_boy_edit',
                        role: adminRoles,
                        title:'Edit Offer'
                    },
                },
                {
                    path: "delivery-boy/offers/active",
                    name: "Active Offers",
                    component: ActiveOffers,
                    meta: {
                        permission: 'delivery_boy_list',
                        role: adminRoles,
                        title:'Active Offers'
                    },
                },
                {
                    path: "delivery-boy/offers/progress",
                    name: "Partner Progress",
                    component: PartnerProgress,
                    meta: {
                        permission: 'delivery_boy_list',
                        role: adminRoles,
                        title:'Partner Progress'
                    },
                },
                {
                    path: "delivery-boy/offers/payouts",
                    name: "Offer Payouts",
                    component: OfferPayouts,
                    meta: {
                        permission: 'delivery_boy_list',
                        role: adminRoles,
                        title:'Payout Management'
                    },
                },

                // Delivery Vehicles Routes
                {
                    path: "delivery-boy/vehicles/list",
                    name: "Vehicles List",
                    component: VehiclesList,
                    meta: {
                        permission: 'delivery_vehicle_list',
                        role: adminRoles,
                        title:'Vehicles List'
                    },
                },
                {
                    path: "delivery-boy/vehicles/create",
                    name: "Add Vehicle",
                    component: VehicleForm,
                    meta: {
                        permission: 'delivery_vehicle_create',
                        role: adminRoles,
                        title:'Add Vehicle'
                    },
                },
                {
                    path: "delivery-boy/vehicles/edit/:id",
                    name: "Edit Vehicle",
                    component: VehicleForm,
                    meta: {
                        permission: 'delivery_vehicle_update',
                        role: adminRoles,
                        title:'Edit Vehicle'
                    },
                },

                // Store Locations Routes
                {
                    path: "store-locations",
                    name: "Store Locations",
                    component: StoreLocationsList,
                    meta: {
                        permission: 'store_location_list',
                        role: adminRoles,
                        title:'Store Locations'
                    },
                },
                {
                    path: "store-locations/create",
                    name: "Add Store Location",
                    component: StoreLocationForm,
                    meta: {
                        permission: 'store_location_edit',
                        role: adminRoles,
                        title:'Add Store Location'
                    },
                },
                {
                    path: "store-locations/edit/:id",
                    name: "Edit Store Location",
                    component: StoreLocationForm,
                    meta: {
                        permission: 'store_location_edit',
                        role: adminRoles,
                        title:'Edit Store Location'
                    },
                },

                {
                    path: "general_settings",
                    name: "GeneralWebSettings",
                    component: GeneralWebSettings,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'General Web Settings'

                    },
                },
                {
                    path: "front_end_policies",
                    name: "Policies",
                    component: FrontEndPolicies,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Policies'

                    },
                },
                {
                    path: "front_end_about",
                    name: "About",
                    component: FrontEndAbout,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'About'

                    },
                },
                {
                    path: "social_media",
                    name: "SocialMedia",
                    component: SocialMedia,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Social Media'

                    },
                },
                {
                    path: "users",
                    name: "Customers",
                    component: Customers,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Customers'

                    },
                },
                {
                    path: "users/view/:id",
                    name: "CustomerView",
                    component: CustomerView,
                    props: true,
                    meta: {
                        permission: 'customer_list',
                        role: adminRoles,
                        title:'Customer View'
                    },
                },
                {
                    path: "wishlists",
                    name: "Wishlists",
                    component: Wishlists,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Wishlists'

                    },
                },
                {
                    path: "customer-app-home-screen/sections",
                    name: "CustomerAppSections",
                    component: CustomerAppSections,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Customer App Home Screen - Sections'
                    },
                },
                {
                    path: "customer-app-home-screen/products",
                    name: "CustomerAppProducts",
                    component: CustomerAppProducts,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Customer App Home Screen - Products'
                    },
                },
                {
                    path: "customer-app-home-screen/section-order",
                    name: "CustomerAppSectionOrder",
                    component: CustomerAppSectionOrder,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Customer App Home Screen - Section Order'
                    },
                },
                {
                    path: "transactions",
                    name: "Transactions",
                    component: Transactions,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Transactions'

                    },
                },
                {
                    path: "wallet_transactions",
                    name: "Manage Customer Wallet",
                    component: WalletTransactions,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Manage Customer Wallet'

                    },
                },
                {
                    path: "paytm_transactions",
                    name: "Paytm Transactions",
                    component: PaytmTransactions,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Paytm Transactions'

                    },
                },
                {
                    path: "customer-messages",
                    name: "Customer Messages",
                    component: CustomerMessages,
                    meta: {
                        permission: 'customer_list',
                        role: adminRoles,
                        title:'Customer Messages'

                    },
                },
                {
                    path: "customer-support",
                    name: "Customer Support",
                    component: CustomerSupport,
                    meta: {
                        permission: 'customer_list',
                        role: adminRoles,
                        title:'Customer Support'
                    },
                },
                {
                    path: "customer-support/view/:id",
                    name: "ViewCustomerReport",
                    component: ViewCustomerReport,
                    props: true,
                    meta: {
                        permission: 'customer_list',
                        role: adminRoles,
                        title:'View Report'
                    },
                },
                {
                    path: "customer-suggestions",
                    name: "Customer Suggestions",
                    component: CustomerSuggestions,
                    meta: {
                        permission: 'customer_list',
                        role: adminRoles,
                        title:'Customer Suggestions'
                    },
                },
                {
                    path: "withdrawal_requests",
                    name: "Withdrawal Requests",
                    component: WithdrawalRequests,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Withdrawal Requests'

                    },
                },
                {
                    path: "return_requests",
                    name: "Return Requests",
                    component: ReturnRequests,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Return Requests'

                    },
                },
                {
                    path: "product_sales_reports",
                    name: "Product Sales Reports",
                    component: ProductSalesReports,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Product Sales Reports'

                    },
                },
                {
                    path: "sales_reports",
                    name: "SalesReports",
                    component: SalesReports,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Sales Reports'

                    },
                },
                {
                    path: "pos_reports",
                    name: "POS Reports",
                    component: PosReports,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'POS Reports'

                    },
                },
                {
                    path: "system_users",
                    name: "System Users",
                    component: SystemUsers,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'System Users'

                    },
                },
                {
                    path: "user-management",
                    name: "User Management",
                    component: UserManagement,
                    meta: {
                        permission: 'manage_system_users',
                        title:'User Management'
                    },
                },
                {
                    path: "rider-analytics",
                    name: "Rider Analytics",
                    component: RiderAnalytics,
                    meta: {
                        permission: 'driver_performance_view',
                        title:'Rider Analytics'
                    },
                },
                {
                    path: "role",
                    name: "Role",
                    component: Role,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Role'

                    },
                },
                {
                    path: "media",
                    name: "Media",
                    component: Media,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Media'

                    },
                },
                {

                    path: "/settings",
                    name: "Settings",
                    component: Settings,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Settings'

                    },
                },
                {
                    path: "product_order",
                    name: "Product Order",
                    component: ProductOrder,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Product Order'

                    },
                },
                {
                    path: "product_ratings",
                    name: "Product Ratings",
                    component: ProductRatings,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Product Ratings'

                    },
                },
                {
                    path: "purchase_code",
                    name: "System Registration",
                    component: PurchaseCode,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'System Registration'

                    },
                },
                {
                    path: "system_updater",
                    name: "SystemUpdater",
                    component: SystemUpdater,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'System Updater'

                    },
                },
                {
                    path: "shipping_methods",
                    name: "Shipping Methods",
                    component: ShippingMethods,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Shipping Methods'

                    },
                },
                {
                    path: "newsletter",
                    name: "Newsletter",
                    component: Newsletter,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Newsletter'

                    },
                },
                {
                    path: "cities",
                    name: "City",
                    component: City,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'City'

                    },
                },
                {
                    path: "cities/create",
                    name: "addCity",
                    component: EditCity,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'City Create'

                    },
                },
                {
                    path: "cities/edit/:id",
                    name: "EditCity",
                    component: EditCity,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'City Edit'
                    },
                },
                {
                    path: "deliverable_area",
                    name: "DeliverableArea",
                    component: DeliverableArea,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Deliverable Area'

                    },
                },
                {
                    path: "faqs",
                    name: "FAQs",
                    component: Faqs,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'FAQs'

                    },
                },
                {
                    path: "product_info/:type",
                    name: "ProductInfo",
                    component: ProductInfo,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Product Info'

                    },
                },
                {
                    path: "languages/:create",
                    name: "languages_create",
                    component: Languages,
                    meta: {
                        permission: 'manage_dashboard',
                        role: adminRoles,
                        title:'Languages'

                    },
                },
                {
                    path: "languages",
                    name: "languages",
                    component: Languages,
                    meta: {
                        permission: 'manage_dashboard',
                        role: adminRoles,
                        title:'Languages'
                    },
                },
                // Combos
                {
                    path: "manage_combos",
                    name: "ManageCombos",
                    component: ManageCombos,
                    meta: {
                        permission: "combo_list",
                        role: adminRoles,
                        title: "Manage Combos",
                    },
                },
                {
                    path: "manage_combos/create",
                    name: "CreateCombo",
                    component: EditCombo,
                    meta: {
                        permission: "combo_create",
                        role: adminRoles,
                        title: "Create Combo",
                    },
                },
                {
                    path: "manage_combos/edit/:id",
                    name: "EditCombo",
                    component: EditCombo,
                    props: true,
                    meta: {
                        permission: "combo_edit",
                        role: adminRoles,
                        title: "Edit Combo",
                    },
                },
                {
                    path: "manage_combos/view/:id",
                    name: "ViewCombo",
                    component: ViewCombo,
                    props: true,
                    meta: {
                        permission: "combo_view",
                        role: adminRoles,
                        title: "View Combo",
                    },
                },
                // Store
                {
                    path: "manage_store",
                    name: "ManageStore",
                    component: ManageStore,
                    meta: {
                        permission: "combo_list",
                        role: adminRoles,
                        title: "Manage Store",
                    },
                },
                {
                    path: "manage_store/create",
                    name: "CreateStore",
                    component: EditStore,
                    meta: {
                        permission: "combo_create",
                        role: adminRoles,
                        title: "Create Store",
                    },
                },
                {
                    path: "manage_store/edit/:id",
                    name: "EditStore",
                    component: EditStore,
                    props: true,
                    meta: {
                        permission: "combo_edit",
                        role: adminRoles,
                        title: "Edit Store",
                    },
                },
                //special Items
                {
                    path: "manage_special_item",
                    name: "ManageItem",
                    component: ManageSpecialItem,
                    meta: {
                        permission: "special_item_list",
                        role: adminRoles,
                        title: "Manage Combos",
                    },
                },
                {
                    path: "manage_special_item/create",
                    name: "CreateSpecialItem",
                    component: EditItem,
                    meta: {
                        permission: "special_item_create",
                        role: adminRoles,
                        title: "Create Special Item",
                    },
                },
                {
                    path: "manage_special_item/edit/:id",
                    name: "EditItem",
                    component: EditItem,
                    props: true,
                    meta: {
                        permission: "special_item_edit",
                        role: adminRoles,
                        title: "Edit Special Item",
                    },
                },
                // Category Group
                {
                    path: "manage_category_group",
                    name: "ManageCategoryGroup",
                    component: ManageCategoryGroup,
                    meta: {
                        permission: "category_group_list",
                        role: adminRoles,
                        title: "Manage Category",
                    },
                },
                {
                    path: "manage_category_group/create",
                    name: "CreateCategoryGroup",
                    component: CreateCategoryGroup,
                    meta: {
                        permission: "category_group_create",
                        role: adminRoles,
                        title: "Create Category Group",
                    },
                },
                {
                    path: "manage_category_group/edit/:id",
                    name: "EditCategoryGroup",
                    component: CreateCategoryGroup,
                    props: true,
                    meta: {
                        permission: "category_group_edit",
                        role: adminRoles,
                        title: "Edit Category Group",
                    },
                },
                {
                    path: "category_group_order",
                    name: "CategoryGroupOrder",
                    component: CategoryGroupOrder,
                    meta: {
                        permission: "category_group_list",
                        role: adminRoles,
                        title: "Category Group Order",
                    },
                },

                {
                    path: "super_mart_manage_category_group",
                    name: "ManageCategoryGroup",
                    component: ManageCategoryGroupSuperMart,
                    meta: {
                        permission: "category_group_list",
                        role: adminRoles,
                        title: "Manage Category",
                    },
                },
                {
                    path: "super_mart_manage_category_group/create",
                    name: "CreateCategoryGroup",
                    component: EditCategoryGroupSuperMart,
                    meta: {
                        permission: "category_group_create",
                        role: adminRoles,
                        title: "Create Category Group",
                    },
                },
                {
                    path: "super_mart_manage_category_group/edit/:id",
                    name: "EditCategoryGroup",
                    component: EditCategoryGroupSuperMart,
                    props: true,
                    meta: {
                        permission: "category_group_edit",
                        role: adminRoles,
                        title: "Edit Category Group",
                    },
                },

                

                // Sub-Category Group
                {
                    path: "super_mart_manage_sub_category_group",
                    name: "ManageSubCategoryGroup",
                    component: ManageSubCategoryGroupSuperMart,
                    meta: {
                        permission: "sub_category_group_list",
                        role: adminRoles,
                        title: "Manage Sub Category",
                    },
                },
                {
                    path: "super_mart_manage_sub_category_group/create",
                    name: "CreateSubCategoryGroup",
                    component: EditSubCategoryGroupSuperMart,
                    meta: {
                        permission: "category_group_create",
                        role: adminRoles,
                        title: "Create Sub-Category Group",
                    },
                },
                {
                    path: "super_mart_manage_sub_category_group/edit/:id",
                    name: "EditSubCategoryGroup",
                    component: EditSubCategoryGroupSuperMart,
                    props: true,
                    meta: {
                        permission: "sub_category_group_edit",
                        role: adminRoles,
                        title: "Edit Sub-Category Group",
                    },
                },


                // Sub-Category Group
                {
                    path: "manage_sub_category_group",
                    name: "ManageSubCategoryGroup",
                    component: ManageSubCategoryGroup,
                    meta: {
                        permission: "sub_category_group_list",
                        role: adminRoles,
                        title: "Manage Sub Category",
                    },
                },
                {
                    path: "manage_sub_category_group/create",
                    name: "CreateSubCategoryGroup",
                    component: CreateSubCategoryGroup,
                    meta: {
                        permission: "category_group_create",
                        role: adminRoles,
                        title: "Create Sub-Category Group",
                    },
                },
                {
                    path: "manage_sub_category_group/edit/:id",
                    name: "EditSubCategoryGroup",
                    component: CreateSubCategoryGroup,
                    props: true,
                    meta: {
                        permission: "sub_category_group_edit",
                        role: adminRoles,
                        title: "Edit Sub-Category Group",
                    },
                },
                {
                    path: "sub_category_group_order",
                    name: "SubCategoryGroupOrder",
                    component: SubCategoryGroupOrder,
                    meta: {
                        permission: "sub_category_group_list",
                        role: adminRoles,
                        title: "Sub Category Group Order",
                    },
                },
                {
                    path: "countries/:create",
                    name: "countries_create",
                    component: Countries,
                    meta: {
                        permission: 'manage_dashboard',
                        role: adminRoles,
                        title:'Countries'

                    },
                },
                {
                    path: "countries",
                    name: "countries",
                    component: Countries,
                    meta: {
                        permission: 'manage_dashboard',
                        role: adminRoles,
                        title:'Countries'
                    },
                },
            ],
        },
        {
            path: "/seller/login",
            name: "seller_login",
            component: SellerLogin,
            meta: {
                title:'Seller Login'
            },
        },
        {
            path: "/seller/register",
            name: "seller_register",
            component: SellerRegister,
            meta: {
                title:'Seller Register'
            },
        },
        {
            path: "/seller/details",
            name: "seller_details",
            component: SellerDetails,
            meta: {
                role: sellerRoles,
                title:'Seller Details'
            }
        },
        {
            /* Here the name of the route is not usable. if you enable the name of this route then display the warning in the console.
            *[vue-router] Named Route 'Seller' has a default child route. When navigating to this named route (:to="{name: 'Seller'"),
            * the default child route will not be rendered. Remove the name from this route and use the name of the default child route for named links instead.
            * */

            path: "/seller",
            // name: "Seller",
            component: TheContainerSeller,
            redirect: "/seller",
            name: "Home",
            children: [
                {
                    path: "/",
                    name: "SellerDashboard",
                    component: SellerDashboard,
                    meta: {
                        requiresAuth: true,
                        role: sellerRoles,
                        title:'Dashboard1'
                    },
                },
                {
                    path: "dashboard",
                    name: "seller_dashboard",
                    component: SellerDashboard,
                    meta: {
                        requiresAuth: true,
                        role: sellerRoles,
                        title:'Dashboard2'
                    },
                },
                {
                    path: "orders",
                    name: "SellerOrders",
                    component: SellerOrders,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Orders'
                    },
                },
                {
                    path: "self_pickup_orders",
                    name: "SelfPickupOrders",
                    component: SelfPickupOrders,
                    meta: {
                        permission: 'self_pickup_order_list',
                        role: sellerRoles,
                        title:'Self Pickup Orders'
                    },
                },
                {
                    path: "orders/view/:id",
                    name: "SellerViewOrder",
                    component: SellerViewOrder,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Order View'
                    },
                },
                {
                    path: "seller/orders/invoice/:id",
                    name: "SellerInvoiceOrder",
                    component: SellerInvoiceOrder,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Order Invoice'
                    },
                },
                {
                    path: "seller/product_info/:type",
                    name: "SellerProductInfo",
                    component: SellerProductInfo,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Product Info'

                    },
                },
                {
                    path: "categories",
                    name: "SellerCategories",
                    component: SellerCategories,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Categories'
                    },
                },

                {
                    path: "manage_products",
                    name: "SellerManageProducts",
                    component: SellerProducts,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Products'
                    },
                },

                {
                    path: "manage_products/create",
                    name: "SellerCreateProduct",
                    component: SellerEditProduct,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Product Create'
                    },

                },
                {
                    path: "manage_products/edit/:id",
                    name: "SellerEditProduct",
                    component: SellerEditProduct,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Product Edit'
                    },
                },
                {
                    path: "manage_products/view/:id",
                    name: "SellerViewProduct",
                    component: SellerViewProduct,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Product View'
                    },
                },
                {
                    path: "product_ratings/view/:id",
                    name: "SellerProductRatings",
                    component: SellerProductRatings,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Product View'
                    },
                },
                {
                    path: "manage_products/clone/:id/:clone",
                    name: "SellerCloneProduct",
                    component: SellerCloneProduct,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Clone Product'

                    },
                },
                {
                    path: "manage_stock",
                    name: "SellerManageStock",
                    component: SellerManageStock,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Stock Management'

                    },
                },  
                {
                    path: "/seller/units",
                    name: "SellerUnits",
                    component: SellerUnits,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Units'
                    },
                },
                {
                    path: "/seller/media",
                    name: "seller_media",
                    component: SellerMedia,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Media'
                    },
                },
                {
                    path: "/seller/taxes",
                    name: "seller_taxes",
                    component: SellerTaxes,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Taxes'
                    },
                },
                {
                    path: "/seller/brands",
                    name: "seller_brands",
                    component: SellerBrands,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Brands'
                    },
                },
                {
                    path: "bulk_upload",
                    name: "SellerBulkUpload",
                    component: BulkUpload,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Bulk Upload'
                    },
                },
                {
                    path: "bulk_update",
                    name: "SellerBulkUpdate",
                    component: BulkUpdate,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Bulk Update'
                    },
                },
                {
                    path: "product_sales_reports",
                    name: "SellerProductSalesReports",
                    component: SellerProductSalesReports,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Product Sales Reports'
                    }
                },
                {
                    path: "sales_reports",
                    name: "SellerSalesReports",
                    component: SellerSalesReports,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Sales Reports'
                    }
                },
                {
                    path: "pos_reports",
                    name: "SellerPosReports",
                    component: SellerPosReports,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'POS Reports'
                    }
                },
                {
                    path: "settings",
                    name: "Settings_setting",
                    component: SellerSettings,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Settings'

                    },
                },
                {
                    path: "return_requests",
                    name: "SellerReturnRequests",
                    component: SellerReturnRequests,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Return Requests'
                    },
                },
                {
                    path: "point_of_sale",
                    name: "SellerPointOfSale",
                    component: SellerPointOfSale,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Point of Sale'
                    },
                },
                {
                    path: "profile",
                    name: "SellerProfile",
                    component: SellerProfile,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'My Profile'
                    },
                },
                {
                    path: "/seller/seller_wallet_transactions",
                    name: "SellerWalletTransactions",
                    component: SellerWalletTransactions,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Wallet Transactions'
                    },
                },
                {
                    path: "/seller/notification_panel",
                    name: "NotificationPanel",
                    component: NotificationPanel,
                    meta: {
                        permission: 'order_list',
                        role: adminRoles,
                        title:'Notification'
                    },
                },
                {
                    path: "/seller/withdrawal_requests",
                    name: "SellerWithdrawalRequests",
                    component: SellerWithdrawalRequests,
                    meta: {
                        permission: 'order_list',
                        role: sellerRoles,
                        title:'Withdrawal Requests'
                    },
                },

            ],
        },
        {
            path: "/delivery_boy/login",
            name: "delivery_boy_login",
            component: DeliveryBoyLogin,
            meta: {
                title:'Delivery Boy Login'
            },
        },
        {
            path: "/delivery_boy/register",
            name: "delivery_boy_register",
            component: DeliveryBoyRegister,
            meta: {
                title:'Delivery Boy Register'
            }
        },
        {
            path: "/delivery_boy/details",
            name: "delivery_boy_details",
            component: DeliveryBoyDetails,
            meta: {
                role: deliveryBoyRoles,
                title:'Delivery Boy Details'
            }
        },
        
        
        {
            /* Here the name of the route is not usable. if you enable the name of this route then display the warning in the console.
            * [vue-router] Named Route 'delivery_boy' has a default child route. When navigating to this named route (:to="{name: 'delivery_boy'"),
            * the default child route will not be rendered. Remove the name from this route and use the name of the default child route for named links instead.
            * */

            path: "/delivery_boy",
            // name: "delivery_boy",
            component: TheContainerDeliveryBoy,
            children: [
                {
                    path: "/",
                    name: "DeliveryBoyDashboard",
                    component:  DeliveryBoyDashboard,
                    meta: {
                        requiresAuth: true,
                        role: deliveryBoyRoles,
                        title:'Dashboard'
                    },
                },
                {
                    path: "dashboard",
                    name: "deliveryBoy_dashboard",
                    component: DeliveryBoyDashboard,
                    meta: {
                        requiresAuth: true,
                        role: deliveryBoyRoles,
                        title:'Dashboard'
                    },
                },
               
                {
                    path: "orders",
                    name: "DeliveryBoyOrders",
                    component: DeliveryBoyOrders,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'Orders'
                    },
                },
                {
                    path: "return_requests",
                    name: "DeliveryBoyReturnRequests",
                    component: DeliveryBoyReturnRequests,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'Return Requests'
                    },
                },
                {
                    path: "orders/view/:id",
                    name: "DeliveryBoyOrder",
                    component: DeliveryBoyOrder,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'View Orders'
                    },
                },
                {
                    path: "/delivery_boy/withdrawal_requests",
                    name: "DeliveryBoyWithdrawalRequests",
                    component: DeliveryBoyWithdrawalRequests,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'Withdrawal Requests'
                    },
                },
                {
                    path: "/delivery_boy/orders/invoice/:id",
                    name: "DeliveryBoyInvoiceOrder",
                    component: DeliveryBoyInvoiceOrder,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'Delivery Boy Invoice Order'
                    },
                },
                {
                    path: "fund_transfers",
                    name: "DeliveryBoyFundTransfers",
                    component: DeliveryBoyFundTransfers,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'Fund Transfers'
                    },
                },
                {
                    path: "cash_collection",
                    name: "DeliveryBoyCashCollection",
                    component: DeliveryBoyCashCollection,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'Delivery boy cash'
                    },
                },

                {
                    path: "product_sales_reports",
                    name: "DeliveryBoyProductSalesReports",
                    component: DeliveryBoyProductSalesReports,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'Product Sales Report'
                    }
                },
                {
                    path: "sales_reports",
                    name: "DeliveryBoySalesReports",
                    component: DeliveryBoySalesReports,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'Sales Report'
                    }
                },

                /*{
                    path: "fund_transfers",
                    name: "Seller Fund Transfers",
                    component: FundTransfers,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'Fund Transfers'
                    },
                },
                {
                    path: "cash_collection",
                    name: "Seller Delivery boy cash",
                    component: CashCollection,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'Cash Collection'
                    },
                },
                {
                    path: "settings",
                    name: "seller_settings",
                    component: Settings,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'Settings'
                    },
                },*/

                {
                    path: "settings",
                    name: "DeliverySettings",
                    component: DeliverySettings,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'Settings'

                    },
                },
                {
                    path: "profile",
                    name: "DeliveryProfile",
                    component: DeliveryProfile,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'My Profile'
                    },
                },
                {
                    path: "manage_products/view/:id",
                    name: "DeliveryBoyViewProduct",
                    component: DeliveryBoyViewProduct,
                    props: true,
                    meta: {
                        permission: 'order_list',
                        role: deliveryBoyRoles,
                        title:'Product View'
                    },
                },
            ],
        },

        {
            path: "/login",
            name: "login",
            component: Login,
            meta: {
                title:'Login'
            },
        },
        {
            path: "/forgot-password",
            name: "forgot_password",
            component: ForgotPassword,
            meta: {
                title:'Forgot Password'
            },
        },
        {
            path: "/reset-password",
            name: "reset_password",
            component: ResetPassword,
            meta: {
                title:'Reset Password'
            },
        },

        /*Other Pages*/
       
        { path: "/error_500", component: ServerError, meta: { title:'Server Error' } },
        { path: "*", component: PageNotFound, meta: { title:'404 Page Not Found' } }

    ];

   
      // Return the routes for further processing
   
    
   
}

