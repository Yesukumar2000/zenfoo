<?php

use Illuminate\Support\Facades\Route;

// header('Access-Control-Allow-Origin: *');
// header('Access-Control-Allow-Methods: GET, PUT, POST, DELETE, OPTIONS');
// header('Access-Control-Allow-Headers: Origin, Content-Type, Authorization, x-access-key, X-Auth-Token');

// Public: Get banners by type (no auth required)
Route::get('home_slider_images/by_type', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'getByType']);

// Public: Free delivery offer info (no auth required)
Route::get('free-delivery-offer', function () {
    $amount = \App\Models\Setting::get_value('free_delivery_order_amount');
    return response()->json([
        'success' => true,
        'offer' => "Order above ₹{$amount} and get FREE delivery on your order!",
        'free_delivery_order_amount' => (float) $amount,
    ]);
});

// Google Places API routes (public - no authentication required)
Route::get('/google_places_autocomplete', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'googlePlacesAutocomplete']);
Route::get('/google_places_details', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'googlePlacesDetails']);
Route::get('/google_maps_geocoding', [\App\Http\Controllers\API\StoreSettingsApiController::class, 'googleMapsGeocoding']);
// Brand Campaigns (Public - No authentication required)
Route::group(['prefix' => 'brand-campaigns'], function () {
    Route::get('/', [\App\Http\Controllers\API\Customer\BrandCampaignController::class, 'index']);
    Route::get('/details', [\App\Http\Controllers\API\Customer\BrandCampaignController::class, 'details']);
    Route::get('/products', [\App\Http\Controllers\API\Customer\BrandCampaignController::class, 'getProducts']);
    Route::get('/{id}', [\App\Http\Controllers\API\Customer\BrandCampaignController::class, 'show']);
});

// Customer App Home Sections (Public - No authentication required)
Route::group(['prefix' => 'home-sections'], function () {
    Route::get('/', [\App\Http\Controllers\API\Customer\CustomerAppSectionController::class, 'index']);
    Route::get('/{id}', [\App\Http\Controllers\API\Customer\CustomerAppSectionController::class, 'show']);
});

// Public: active store locations for the customer map (no auth required)
Route::get('store-locations', [\App\Http\Controllers\API\StoreLocationController::class, 'publicList']);

Route::group(['middleware' => ['auth.customer']], function () {

    Route::post('send_sms',[\App\Http\Controllers\API\Customer\SmsApiController::class, 'store']);
    // Route::post('verify_user',[\App\Http\Controllers\API\Customer\SmsApiController::class, 'verifyContact']);
   
    Route::post('login', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'login']);
    Route::post('verify_user', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'verifyContact']);

    // Home API 

    // Route::get('/home',[\App\Http\Controllers\API\Customer\HomeApiController::class, 'home']);

    Route::post('register', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'register']);
    Route::post('verify_email',[\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'verifyEmail']);
    Route::post('verify_user_exist',[\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'verifyUserExist']);
    Route::match(['get', 'post'], 'validate_referral_code', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'validateReferralCode']);
    Route::get('login', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'notLogin'])->name('login');
    Route::post('add_fcm_token', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'addFcmToken']);
    Route::post('forgot_password_otp', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'forgetPasswordOtp']);
    Route::post('forgot_password', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'forgotPassword']);
   

    // Guest
   
    Route::get('categories', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getCategories']);
    Route::get('categories/get_seo_things', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getSeoThings']);
    Route::get('shop', [\App\Http\Controllers\API\Customer\ShopApiController::class, 'getShopData']);
    Route::get('brands', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getBrands']);
    Route::get('countries', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getCountries']);
    Route::get('/sellers', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getSellers']);
    Route::get('/distance', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'distance']);
    Route::get('/home-data', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'home_data']);
    Route::get('/stores', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'stores']);
    Route::get('/cat_store/{id?}', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'category_subcategory_store_data']);
    Route::get('/supermart-sellers', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getSuperMartSellers']);
    Route::get('/sweethouse-sellers', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getSweetHouseSellers']);
    Route::get('/seller-category-groups', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getSellerCategoryGroups']);
    Route::get('/seller-category-tree', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getSellerCategoryTree']);
    Route::get('/supermart-product-lists', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getSuperMartProductLists']);

    Route::get('sweetshop/products-by-category', [ App\Http\Controllers\CategoryTypeController::class, 'getUserSweetshopProductsByCategory']);



    Route::group(['prefix' => 'products'], function () {
        Route::post('/', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'getProducts']);
        Route::get('/group-products', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'getGroupProducts']);
        Route::get('/combos', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'getCombos']);
        Route::get('/combos/{id}', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'getComboDetail']);
        Route::post('/filter', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'getProducts_filter']);
        Route::post('similar', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'getSimilarProducts']);
        Route::post('search', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'getSearchProducts']);
        Route::get('all_names', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'getAllProductNames']);
        Route::get('ratings_list', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'productRatingsList']);
        Route::post('rating/image_list', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'productRatingImageList']);

        Route::get('get_seo_things', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'getSeoThings']);

    });
    Route::post('/product_by_id', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'getProduct']);
    Route::post('/product_by_cat_id', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'getProductCategory']);

    Route::get('/faqs', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getFaqs']);
    Route::get('social_media', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getSocialMedia']);
    Route::get('newsletter', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getNewsletter']);

    // Settings
    Route::group(['prefix' => 'settings'], function () {
        Route::get('/', [\App\Http\Controllers\API\Customer\SettingApiController::class, 'getSettings']);
        Route::get('time_slots', [\App\Http\Controllers\API\Customer\SettingApiController::class, 'getTimeSlots']);
        Route::get('payment_methods', [\App\Http\Controllers\API\Customer\SettingApiController::class, 'getPaymentMethods']);
        Route::get('get_seo_settings', [\App\Http\Controllers\API\Customer\SettingApiController::class, 'getSeoSettings']);
        Route::get('free_delivery_amount', [\App\Http\Controllers\API\Customer\SettingApiController::class, 'getFreeDeliveryAmount']);
    });

    // App Media (Videos & Images)
    Route::get('app-media', [\App\Http\Controllers\API\Customer\SettingApiController::class, 'getAppMedia']);

    //Languages
    Route::get('system_languages', [\App\Http\Controllers\API\LanguageApiController::class, 'getSystemLanguages']);

    // city deliverable
    Route::get('/cities', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getCities']);
    Route::get('/city', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getCity']);

    Route::get('offers', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getOffers']);
    Route::get('/sliders', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getSliders']);
    Route::get('notifications', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getNotifications']);
    Route::get('/sections', [\App\Http\Controllers\API\Customer\SectionsApiController::class, 'getSections']);


    /***********************************************************************************************/
    // API After Login here

    Route::group(['middleware' => ['auth:api-customers']], function () {

        // Zenfoo Offers - Get all valid offers with customer progress
        Route::get('zenfoo_offers', [\App\Http\Controllers\API\Customer\CustomerZenfooOffersController::class, 'getOffers']);
        Route::post('zenfoo_offers/progress', [\App\Http\Controllers\API\Customer\CustomerZenfooOffersController::class, 'getOfferProgress']);
        Route::get('zenfoo_offers/with_progress', [\App\Http\Controllers\API\Customer\CustomerZenfooOffersController::class, 'getOffersWithProgress']);
        Route::post('zenfoo_offers/claim', [\App\Http\Controllers\API\Customer\CustomerZenfooOffersController::class, 'claimOffer']);
        Route::post('zenfoo_offers/claim_all', [\App\Http\Controllers\API\Customer\CustomerZenfooOffersController::class, 'claimAllOffers']);
        Route::get('zenfoo_offers/claimed', [\App\Http\Controllers\API\Customer\CustomerZenfooOffersController::class, 'getClaimedOffers']);
        Route::get('zenfoo_offers/all', [\App\Http\Controllers\API\Customer\CustomerZenfooOffersController::class, 'getAllOffersData']);

        // User Offers - Order Milestones & Banners
        Route::get('user_offers/simple', [\App\Http\Controllers\API\Customer\CustomerUserOffersController::class, 'getMilestonesSimple']);
        Route::post('user_offers/claim_with_order', [\App\Http\Controllers\API\Customer\CustomerUserOffersController::class, 'claimWithOrder']);
        Route::get('user_offers/milestones', [\App\Http\Controllers\API\Customer\CustomerUserOffersController::class, 'getOrderMilestones']);
        Route::get('user_offers/banners', [\App\Http\Controllers\API\Customer\CustomerUserOffersController::class, 'getOfferBanners']);
        Route::get('user_offers/all', [\App\Http\Controllers\API\Customer\CustomerUserOffersController::class, 'getAllUserOffersData']);
        Route::post('user_offers/claim', [\App\Http\Controllers\API\Customer\CustomerUserOffersController::class, 'claimMilestone']);
        Route::post('user_offers/claim_all', [\App\Http\Controllers\API\Customer\CustomerUserOffersController::class, 'claimAllMilestones']);
        Route::get('user_offers/claimed', [\App\Http\Controllers\API\Customer\CustomerUserOffersController::class, 'getClaimedMilestones']);
        Route::get('user_offers/available_rewards', [\App\Http\Controllers\API\Customer\CustomerUserOffersController::class, 'getAvailableRewards']);

        // User
        Route::post('logout', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'logout']);
        Route::post('delete_account', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'deleteAccount']);
        Route::post('edit_profile', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'editProfile']);
        Route::post('reset_password', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'ResetPassword']);
        Route::post('upload_profile', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'uploadProfile']);
        Route::post('update_fcm_token', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'updateFcmToken']);
        Route::get('user_details', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'getLoginUserDetails']);
        Route::get('referral_stats', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'getReferralStats']);
        Route::post('update_children_allowed', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'updateChildrenAllowed']);
        Route::get('get_children_allowed', [\App\Http\Controllers\API\Customer\CustomerAuthController::class, 'getChildrenAllowed']);


        Route::post('create_phonepe_transaction', [\App\Http\Controllers\API\WalletTransactionsApiController::class, 'createPhonePeTransaction'])->name('wallet_transactions.create_phonepe_transaction');
        Route::post('verify_phonepe_transaction', [\App\Http\Controllers\API\WalletTransactionsApiController::class, 'verifyPhonePeTransaction'])->name('wallet_transactions.verify_phonepe_transaction');
      // PhonePe Payment Routes (Alternative endpoints using PhonePeController)
    Route::group(['prefix' => 'phonepe'], function () {
        Route::post('initiate-payment', [\App\Http\Controllers\API\PhonePeController::class, 'initiatePayment'])->name('phonepe.initiate');
        Route::post('check-status', [\App\Http\Controllers\API\PhonePeController::class, 'checkStatus'])->name('phonepe.status');
        Route::post('redirect', [\App\Http\Controllers\API\PhonePeController::class, 'redirect'])->name('phonepe.redirect');
    });
        // Transactions
        Route::get('get_user_transactions', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getUserTransactions']);
        Route::post('add_wallet_balance', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'addWalletBalance']);

        // Address
        Route::group(['prefix' => 'address'], function () {
            Route::get('/', [\App\Http\Controllers\API\Customer\AddressApiController::class, 'getAddress']);
            Route::post('/add', [\App\Http\Controllers\API\Customer\AddressApiController::class, 'save']);
            Route::post('/update', [\App\Http\Controllers\API\Customer\AddressApiController::class, 'update']);
            Route::post('/delete', [\App\Http\Controllers\API\Customer\AddressApiController::class, 'delete']);
        });

        // Notes
        Route::group(['prefix' => 'notes'], function () {
            Route::get('/', [\App\Http\Controllers\API\Customer\UserNoteController::class, 'index']);
            Route::get('/selected', [\App\Http\Controllers\API\Customer\UserNoteController::class, 'getSelected']);
            Route::get('/products-by-selected-notes', [\App\Http\Controllers\API\Customer\UserNoteController::class, 'getProductsBySelectedNotes']);
            Route::post('/add', [\App\Http\Controllers\API\Customer\UserNoteController::class, 'store']);
            Route::post('/update/{id}', [\App\Http\Controllers\API\Customer\UserNoteController::class, 'update']);
            Route::post('/delete/{id}', [\App\Http\Controllers\API\Customer\UserNoteController::class, 'destroy']);
            Route::post('/{id}/toggle-select', [\App\Http\Controllers\API\Customer\UserNoteController::class, 'toggleSelect']);
            Route::post('/bulk-update', [\App\Http\Controllers\API\Customer\UserNoteController::class, 'bulkUpdate']);
        });

        // Withdrawal Requests
        Route::group(['prefix' => 'withdrawal_requests'], function () {
            Route::get('/', [\App\Http\Controllers\API\Customer\WithdrawalApiController::class, 'getRequest']);
            Route::post('/add', [\App\Http\Controllers\API\Customer\WithdrawalApiController::class, 'save']);
        });


        // Favorites
        Route::group(['prefix' => 'favorites'], function () {
            Route::get('/', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getFavorites']);
            Route::post('/add', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'addToFavorite']);
            Route::post('/remove', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'removeFromFavorite']);
        });

        // Bookmarks (for products, sellers, combos)
        Route::group(['prefix' => 'bookmarks'], function () {
            Route::get('/', [\App\Http\Controllers\API\Customer\BookmarkController::class, 'index']);
            Route::get('/{id}', [\App\Http\Controllers\API\Customer\BookmarkController::class, 'show']);
            Route::post('/', [\App\Http\Controllers\API\Customer\BookmarkController::class, 'store']);
            Route::post('/toggle', [\App\Http\Controllers\API\Customer\BookmarkController::class, 'toggle']);
            Route::delete('/{id}', [\App\Http\Controllers\API\Customer\BookmarkController::class, 'destroy']);
            Route::post('/bulk-delete', [\App\Http\Controllers\API\Customer\BookmarkController::class, 'bulkDelete']);
            Route::get('/list/tabs', [\App\Http\Controllers\API\Customer\BookmarkController::class, 'getBookmarkTabs']);
            Route::post('/list/tab-data', [\App\Http\Controllers\API\Customer\BookmarkController::class, 'getBookmarkTabData']);
            Route::get('/tabs/stores', [\App\Http\Controllers\API\Customer\BookmarkController::class, 'getBookmarkedStores']);
            Route::get('/tabs/combos', [\App\Http\Controllers\API\Customer\BookmarkController::class, 'getBookmarkedCombos']);
            Route::get('/tabs/sellers', [\App\Http\Controllers\API\Customer\BookmarkController::class, 'getBookmarkedSellers']);
            Route::get('/type/{type}', [\App\Http\Controllers\API\Customer\BookmarkController::class, 'getByType']);
            Route::post('/check-bookmarked', [\App\Http\Controllers\API\Customer\BookmarkController::class, 'checkBookmarked']);
        });

        // Carts
        Route::group(['prefix' => 'cart'], function () {
            Route::get('/', [\App\Http\Controllers\API\Customer\CartApiController::class, 'getUserCart']);
            Route::post('/add', [\App\Http\Controllers\API\Customer\CartApiController::class, 'addToCart']);
            Route::post('/remove', [\App\Http\Controllers\API\Customer\CartApiController::class, 'removeFromCart']);
            Route::post('/save_for_later', [\App\Http\Controllers\API\Customer\CartApiController::class, 'addToSaveForLater']);
            Route::post('/bulk_add_to_cart_items', [\App\Http\Controllers\API\Customer\CartApiController::class, 'BulkAddToCartItems']);
            Route::get('/get_cart_count', [\App\Http\Controllers\API\Customer\CartApiController::class, 'getCartCount']);

            // Cart Metadata (delivery tip, instructions, contact info, notes)
            Route::post('/metadata/save', [\App\Http\Controllers\API\Customer\CartApiController::class, 'saveCartMetadata']);
            Route::get('/metadata', [\App\Http\Controllers\API\Customer\CartApiController::class, 'getCartMetadata']);
            Route::post('/metadata/clear', [\App\Http\Controllers\API\Customer\CartApiController::class, 'clearCartMetadata']);
            Route::post('/remove_promocode', [\App\Http\Controllers\API\Customer\CartApiController::class, 'removePromoCode']);
        });

        // Offers
        Route::group(['prefix' => 'offers'], function () {
            Route::post('/add', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'addOffers']);
            Route::post('/remove/{id}', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'removeOffers']);
        });

        // stripeTest
        Route::get('/stripeTest', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'stripeTest']);

        Route::group(['prefix' => 'sliders'], function () {
            Route::post('/add', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'addSliders']);
            Route::post('/remove/{id}', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'removeSliders']);
        });

        // Promo Code
        Route::group(['prefix' => 'promo_code'], function () {
            Route::get('/', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getPromoCode']);
            Route::post('/validate', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'validatePromoCode']);
        });

        // Sections
        Route::group(['prefix' => 'sections'], function () {
            Route::get('/delivery_boy_notifications', [\App\Http\Controllers\API\Customer\SectionsApiController::class, 'getDeliveryBoyNotifications']);
            Route::post('/remove/{id}', [\App\Http\Controllers\API\Customer\SectionsApiController::class, 'removeSection']);
            //Route::post('/add', [\App\Http\Controllers\API\Customer\SectionsApiController::class, 'addSection']);
        });
        Route::group(['prefix' => 'products'], function () {
            Route::get('similar_from_cart', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'getSimilarProductsFromCart']);
            Route::post('rating/add', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'productRatingSave']);
            Route::post('rating/edit', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'productRatingEdit']);
            Route::post('rating/update', [\App\Http\Controllers\API\Customer\ProductsApiController::class, 'productRatingUpdate']);
        });

        // order
        Route::get('orders', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'getOrders']);
        Route::get('orders/reorderable', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'getReorderableOrders']);
        Route::post('invoice', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'generateOrderInvoice'])->name('customerInvoice');
        Route::post('invoice_download', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'downloadOrderInvoice']);

        Route::get('order_status_lists', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getOrderStatusLists']);

        Route::post('order_test', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'orderTest']);

        //Checkout
        Route::post('place_order', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'placeOrder']);
        Route::post('place_order_with_paytm', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'placeOrderWithPaytm']);
        Route::post('initiate_transaction', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'initiateTransaction']);
        Route::post('add_transaction', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'addTransaction']);
        Route::post('update_order_status', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'updateOrderStatus']);
        Route::post('delete_order', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'deletePaymentPendingOrder']);
        Route::post('cancel_order', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'cancelOrder']);

        // Preorder Status Check
        Route::get('preorder_status', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'getPreorderStatus']);

        // Order Rating
        Route::get('orders/seller-wise-items', [\App\Http\Controllers\API\Customer\RatingController::class, 'getSellerWiseItems']);
        Route::get('orders/ratings', [\App\Http\Controllers\API\Customer\RatingController::class, 'getOrderRatings']);
        Route::post('orders/submit-rating', [\App\Http\Controllers\API\Customer\RatingController::class, 'submitRating']);
        Route::post('save_order_rating', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'saveOrderRating']);

        //Phonepe
        Route::get('order_status_phonepe', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'getOrderStatusPhonepe']);
        
        //Paypal
        
        //PayTm
        Route::get('paytm_checksum', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'generatePaytmChecksum']);
        Route::get('paytm_txn_token', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'generatePaytmTxnToken']);

        // Seller
        Route::get('/seller', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getSeller']);

        // mail_settings
        Route::group(['prefix' => 'mail_settings'], function () {
            Route::get('/', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'getMailSetting']);
            Route::post('save', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'saveMailSetting']);
        });

        Route::get('/live_tracking', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'getLiveTrackingDetails']);

        // Customer Issue Report
        Route::get('issue_report/order_items', [\App\Http\Controllers\API\Customer\CustomerIssueReportController::class, 'getOrderItems']);
        Route::post('issue_report/order_item_details', [\App\Http\Controllers\API\Customer\CustomerIssueReportController::class, 'getOrderItemDetails']);
        Route::post('issue_report/store', [\App\Http\Controllers\API\Customer\CustomerIssueReportController::class, 'storeItemMissingReport']);
        Route::match(['get', 'post'], 'issue_report/reports', [\App\Http\Controllers\API\Customer\CustomerIssueReportController::class, 'getReports']);
        Route::get('issue_report/report', [\App\Http\Controllers\API\Customer\CustomerIssueReportController::class, 'getReportById']);

        // Wrong Item Report
        Route::get('wrong_item_report/store_list', [\App\Http\Controllers\API\Customer\CustomerIssueReportController::class, 'getWrongItemStoreList']);
        Route::post('wrong_item_report/store', [\App\Http\Controllers\API\Customer\CustomerIssueReportController::class, 'storeWrongItemReport']);
        Route::post('wrong_item_report/store_with_images', [\App\Http\Controllers\API\Customer\CustomerIssueReportController::class, 'storeWrongItemReportWithImages']);

        // Customer Support Chat (Customer -> Admin)
        Route::group(['prefix' => 'support-chat'], function () {
            Route::post('/send', [\App\Http\Controllers\API\AdminCustomerChatController::class, 'customerSendMessage']);
            Route::post('/order/send', [\App\Http\Controllers\API\AdminCustomerChatController::class, 'customerSendOrderMessage']);
            Route::get('/messages', [\App\Http\Controllers\API\AdminCustomerChatController::class, 'customerGetMessages']);
        });

        // Customer Suggestions
        Route::group(['prefix' => 'suggestions'], function () {
            Route::post('/submit', [\App\Http\Controllers\API\Customer\CustomerSuggestionController::class, 'store']);
            Route::get('/', [\App\Http\Controllers\API\Customer\CustomerSuggestionController::class, 'index']);
        });
    });

    //Paypal
    Route::get('paypal_payment_url', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'paypalPaymentUrl']);
    Route::match(array('GET', 'POST'), 'paypal_redirect/success', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'paypalRedirect']);
    Route::match(array('GET', 'POST'), 'paypal_redirect/fail', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'paypalRedirect']);
    Route::match(array('GET', 'POST'), 'paypal_redirect/pending', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'paypalRedirect']);
    Route::post('ipn', [\App\Http\Controllers\API\Customer\OrderApiController::class, 'ipn']);

    Route::get('distance_test', [\App\Http\Controllers\API\Customer\BasicApiController::class, 'findGoogleMapDistanceTest']);
    
});

// Guest Carts
Route::group(['prefix' => 'cart'], function () {
    Route::get('/guest_cart', [\App\Http\Controllers\API\Customer\CartApiController::class, 'getGuestCart']);
});

Route::get('/combos_home_page', [\App\Http\Controllers\API\Customer\ComboController::class, 'getCombosCustomerHomePage']);
Route::get('/combos_based_on_category_type', [\App\Http\Controllers\API\Customer\ComboController::class, 'getCombosCustomerBasedOnCategoryType']);
Route::get('/combo_details', [\App\Http\Controllers\API\Customer\ComboController::class, 'getSingleCombo']);
Route::post('/store_custom_combo_cart', [\App\Http\Controllers\API\Customer\ComboController::class, 'storeCustomComboCart']);
Route::delete('/delete_custom_combo_cart', [\App\Http\Controllers\API\Customer\ComboController::class, 'deleteCustomComboCart']);
Route::post('/product_add_or_edit_custom_combo', [\App\Http\Controllers\API\Customer\ComboController::class, 'addSingleCustomComboProduct']);
Route::delete('/delete_single_custom_product', [\App\Http\Controllers\API\Customer\ComboController::class, 'deleteSingleCustomComboProduct']);


Route::get('/app-launch-banner', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'getAppLaunchBanner']);
Route::get('/zenfoo_offers', [\App\Http\Controllers\API\Customer\CustomerZenfooOffersController::class, 'getOffers']);
Route::get('/promotional-banners', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'getPromotionalBanners']);
Route::get('/special-items', [\App\Http\Controllers\API\HomeSliderImagesApiController::class, 'getSpecialItemsForCustomer']);

// Thinking Items for Customer App (Public - no auth required)
Route::get('/thinking-items', [\App\Http\Controllers\API\ThinkingItemsApiController::class, 'getForCustomer'])->name('customer.thinking-items');
Route::get('/thinking-items/title', [\App\Http\Controllers\API\ThinkingItemsApiController::class, 'getTitle'])->name('customer.thinking-items.title');

// Chatbot
Route::get('/chatbot/questions', [\App\Http\Controllers\API\Customer\ChatbotController::class, 'getQuestions']);
Route::middleware(['auth:api-customers'])->group(function () {
    Route::post('/chatbot/answer', [\App\Http\Controllers\API\Customer\ChatbotController::class, 'getAnswer']);
});

// Paytm Payment Routes (Customer)
Route::middleware(['auth:api-customers'])->group(function () {
    Route::group(['prefix' => 'paytm'], function () {
        // Get Paytm configuration (public keys only, NOT merchant_key)
        Route::get('config', [\App\Http\Controllers\API\PaytmPaymentController::class, 'getConfig'])->name('customer.paytm.config');

        // Main payment verification endpoint (stores in DB)
        Route::post('verify-payment', [\App\Http\Controllers\API\PaytmPaymentController::class, 'verifyPayment'])->name('customer.paytm.verify');

        // Check payment status (does not store in DB, just queries Paytm)
        Route::post('check-status', [\App\Http\Controllers\API\PaytmPaymentController::class, 'checkStatus'])->name('customer.paytm.status');

        // TEST ROUTES - FOR DEVELOPMENT ONLY (Remove in production)
        Route::group(['prefix' => 'test'], function () {
            Route::post('create-mock-payment', [\App\Http\Controllers\API\PaytmTestController::class, 'createMockPayment'])->name('customer.paytm.test.create');
            Route::get('transactions', [\App\Http\Controllers\API\PaytmTestController::class, 'getTestTransactions'])->name('customer.paytm.test.list');
            Route::delete('clear-transactions', [\App\Http\Controllers\API\PaytmTestController::class, 'clearTestTransactions'])->name('customer.paytm.test.clear');
        });
    });
});

// Nearest Zenfoo Store (Public - no auth required)
// Returns the nearest store name and travel time using Haversine distance.
Route::get('/nearest-store', [\App\Http\Controllers\API\Customer\NearestStoreController::class, 'findNearest'])->name('customer.nearest-store');

