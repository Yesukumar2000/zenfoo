<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Admin;
use App\Models\Order;
use App\Models\Seller;
use App\Models\Product;
use App\Models\Setting;
use App\Models\Category;
use App\Models\Brand;
use App\Models\Section;
use App\Models\City;
use App\Models\OrderItem;
use App\Models\UserToken;
use App\Models\AdminToken;
use Illuminate\Http\Request;
use App\Helpers\CommonHelper;
use App\Models\ProductVariant;
use App\Models\OrderStatusList;
use App\Models\PanelNotification;
use App\Models\SellerWalletTransaction;
use App\Models\SellerCommission;
use App\Models\DeliveryBoyTransaction;
use App\Models\CategoryGroup;
use App\Models\SubCategoryGroup;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Session;
use App\Notifications\OrderNotification;
use Illuminate\Foundation\Bus\DispatchesJobs;
use Illuminate\Routing\Controller as BaseController;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Support\Facades\Config;

class Controller extends BaseController
{
    /**
     * Rows returned by the bell dropdown. The header renders slice(0, 5);
     * the full history lives behind "See all notifications".
     */
    const TOP_NOTIFICATIONS_LIMIT = 10;

    public function dashboard(Request $request){
        $data = array();
        $data['order_count'] = Order::where('active_status', '!=', 1)->count();
        $data['product_count'] = Product::get()->count();
        $data['customer_count'] = User::where('status','!=', 2)->get()->count();
        $data['seller_count'] = Seller::where('status',1)->get()->count();
        $data['category_count'] = Category::get()->count();
        $data['brand_count'] = Brand::get()->count();
        $data['section_count'] = Section::get()->count();
        $data['city_count'] = City::get()->count();
        $data['packet_products'] = ProductVariant::select("*")->leftJoin('products', 'product_variants.product_id', '=', 'products.id')->
        where('products.type','packet')->get()->count();
        $data['loose_products'] = ProductVariant::select("*")->leftJoin('products', 'product_variants.product_id', '=', 'products.id')->
        where('products.type','loose')->get()->count();

        $data['sold_out_count'] = ProductVariant::Join("products", "product_variants.product_id", "=", "products.id")
        ->join('sellers as s', 'products.seller_id', '=', 's.id')
            ->where('products.is_unlimited_stock',0)
            ->where('products.status',1)
            ->where('products.is_approved',1)
            ->where('product_variants.status',0)
            ->where('product_variants.stock','<=',0)
            ->count();

        $low_stock = Setting::where('variable', 'low_stock_limit')->first();
        $low_stock_limit = 0;
        if($low_stock){
            $low_stock_limit = $low_stock->value;
        }
        $data['low_stock_count'] = ProductVariant::select("*")->leftJoin('products', 'product_variants.product_id', '=', 'products.id')->
        where('product_variants.status',ProductVariant::$statusAvailable);
        if(isset($low_stock_limit) && $low_stock_limit !=="" && $low_stock_limit !==0 ){
            $data['low_stock_count'] = $data['low_stock_count']->where('product_variants.stock','<=',$low_stock_limit)->where('products.is_unlimited_stock','!=',1);
        }
        $data['low_stock_count'] = $data['low_stock_count']->get()->count();

        // Get period filters from request
        $sellersPeriod = $request->input('sellers_period', 'monthly');
        $driversPeriod = $request->input('drivers_period', 'monthly');
        $categoriesPeriod = $request->input('categories_period', 'monthly');
        $categoryGroupsPeriod = $request->input('category_groups_period', 'monthly');
        $subCategoryGroupsPeriod = $request->input('sub_category_groups_period', 'monthly');

        // Top Sellers with period filter
        $topSellersQuery = SellerWalletTransaction::select(
                DB::raw("ROUND(SUM(seller_wallet_transactions.amount), 2) as total_revenue"),
                'seller_wallet_transactions.seller_id',
                'sellers.name as seller_name',
                'sellers.store_name'
            )
            ->leftJoin('sellers', 'seller_wallet_transactions.seller_id', '=', 'sellers.id')
            ->where('sellers.name', '!=', null);

        $topSellersQuery = $this->applyPeriodFilter($topSellersQuery, $sellersPeriod, 'seller_wallet_transactions.created_at');

        $data['top_sellers'] = $topSellersQuery
            ->groupBy('seller_wallet_transactions.seller_id')
            ->orderBy('total_revenue', 'DESC')
            ->limit(10)
            ->get();

        // Top 10 Drivers with period filter
        $topDriversQuery = DeliveryBoyTransaction::select(
                'delivery_boy_transactions.delivery_boy_id',
                'delivery_boys.name as driver_name',
                DB::raw("COUNT(delivery_boy_transactions.id) as order_count"),
                DB::raw("ROUND(SUM(delivery_boy_transactions.driver_earnings), 2) as driver_earning")
            )
            ->leftJoin('delivery_boys', 'delivery_boy_transactions.delivery_boy_id', '=', 'delivery_boys.id')
            ->where('delivery_boy_transactions.type', '!=', 'incentive')
            ->where('delivery_boys.name', '!=', null);

        $topDriversQuery = $this->applyPeriodFilter($topDriversQuery, $driversPeriod, 'delivery_boy_transactions.created_at');

        $data['top_drivers'] = $topDriversQuery
            ->groupBy('delivery_boy_transactions.delivery_boy_id')
            ->orderBy('order_count', 'DESC')
            ->limit(10)
            ->get();

        // Top Categories with period filter
        $topCategoriesQuery = OrderItem::select(
                'products.category_id',
                'categories.name as category_name',
                DB::raw("ROUND(SUM(order_items.discounted_price * order_items.quantity), 2) as total_revenue")
            )
            ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
            ->leftJoin('categories', 'products.category_id', '=', 'categories.id')
            ->whereNotNull('products.category_id')
            ->whereNotNull('categories.name');

        $topCategoriesQuery = $this->applyPeriodFilter($topCategoriesQuery, $categoriesPeriod, 'order_items.created_at');

        $data['top_categories'] = $topCategoriesQuery
            ->groupBy('products.category_id')
            ->orderBy('total_revenue', 'DESC')
            ->limit(10)
            ->get();

        // Top Category Groups with period filter
        $topCategoryGroupsQuery = OrderItem::select(
                'products.category_group_id',
                'category_groups.name as category_group_name',
                DB::raw("ROUND(SUM(order_items.discounted_price * order_items.quantity), 2) as total_revenue")
            )
            ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
            ->leftJoin('category_groups', 'products.category_group_id', '=', 'category_groups.id')
            ->whereNotNull('products.category_group_id')
            ->whereNotNull('category_groups.name');

        $topCategoryGroupsQuery = $this->applyPeriodFilter($topCategoryGroupsQuery, $categoryGroupsPeriod, 'order_items.created_at');

        $data['top_category_groups'] = $topCategoryGroupsQuery
            ->groupBy('products.category_group_id')
            ->orderBy('total_revenue', 'DESC')
            ->limit(10)
            ->get();

        // Top Sub Category Groups with period filter
        $topSubCategoryGroupsQuery = OrderItem::select(
                'products.sub_category_group_id',
                'sub_category_groups.name as sub_category_group_name',
                DB::raw("ROUND(SUM(order_items.discounted_price * order_items.quantity), 2) as total_revenue")
            )
            ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
            ->leftJoin('sub_category_groups', 'products.sub_category_group_id', '=', 'sub_category_groups.id')
            ->whereNotNull('products.sub_category_group_id')
            ->whereNotNull('sub_category_groups.name');

        $topSubCategoryGroupsQuery = $this->applyPeriodFilter($topSubCategoryGroupsQuery, $subCategoryGroupsPeriod, 'order_items.created_at');

        $data['top_sub_category_groups'] = $topSubCategoryGroupsQuery
            ->groupBy('products.sub_category_group_id')
            ->orderBy('total_revenue', 'DESC')
            ->limit(10)
            ->get();

        $data['status_order_count'] = CommonHelper::getStatusOrderCount();

        return CommonHelper::responseWithData($data);
    }

    /**
     * Apply period filter to a query
     * @param $query - The query builder instance
     * @param string $period - Period type (daily, weekly, monthly, yearly, all)
     * @param string $dateColumn - The date column to filter on
     * @return mixed
     */
    private function applyPeriodFilter($query, $period, $dateColumn)
    {
        $now = now();

        switch ($period) {
            case 'daily':
                $query->whereDate($dateColumn, $now->toDateString());
                break;
            case 'weekly':
                $query->whereBetween($dateColumn, [
                    $now->startOfWeek()->toDateTimeString(),
                    $now->endOfWeek()->toDateTimeString()
                ]);
                break;
            case 'monthly':
                $query->whereMonth($dateColumn, $now->month)
                      ->whereYear($dateColumn, $now->year);
                break;
            case 'yearly':
                $query->whereYear($dateColumn, $now->year);
                break;
            case 'all':
                // No filter applied - get all data
                break;
            default:
                // Default to monthly if unknown period
                $query->whereMonth($dateColumn, $now->month)
                      ->whereYear($dateColumn, $now->year);
                break;
        }

        return $query;
    }
    public function doLanguageChange(Request $request)
    {
        Session::put('lang',$request->language);
        Session::put('app_locale', $request->language);
        // Log::info('session : '.Session::get('lang'));
        return response()->json(['status' => true]);
    }
    public function createSlug($text){
        $slug = CommonHelper::slugify($text);
        return CommonHelper::responseWithData($slug);
    }

    /**
     * Feeds the bell dropdown, which polls every 40s and shows the newest few.
     * Scoped by notifiable_type as well as id: the table's only index is the
     * morph composite (notifiable_type, notifiable_id), so filtering on the id
     * alone cannot use it, and an admin would match a row belonging to another
     * notifiable type that happens to share the id.
     */
    public function getTopNotifications(){
        $notifications = PanelNotification::where('notifiable_type', Admin::class)
            ->where('notifiable_id', auth()->user()->id);

        $data = array();
        $data['unread'] = (clone $notifications)->whereNull('read_at')->count();
        $data['notifications'] = (clone $notifications)
            ->orderBy('created_at','DESC')
            ->limit(self::TOP_NOTIFICATIONS_LIMIT)
            ->get();

        return CommonHelper::responseWithData($data);
    }

    public function markAsReadNotifications(Request $request){
        auth()->user()
            ->unreadNotifications
            ->when($request->input('id'), function ($query) use ($request) {
                return $query->where('id', $request->input('id'));
            })
            ->markAsRead();
        return CommonHelper::responseWithData("Notification Mark as Read Successfully!");
    }

    public function markAllNotificationsAsRead(){
        auth()->user()->unreadNotifications->markAsRead();
        return CommonHelper::responseWithData("All notifications marked as read!");
    }

    public function deploy(){

       

     
        exec("git pull origin 1.9 2>&1", $output);
        echo "<pre>";
        var_dump($output);
        echo "</pre>";

       
        exec("composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev");
        exec("php artisan migrate");

    
        echo "<br><br>Done";
    }

    public function updateToken(Request $request){
        Log::info('=== FCM Token Update Started ===');
        Log::info('Request token: ' . ($request->token ?? 'NULL'));
        Log::info('Request all: ', $request->all());

        try {
            $user = auth()->user();

            if (!$user) {
                Log::error('FCM Token Update: No authenticated user');
                return response()->json(['success' => false, 'error' => 'No authenticated user']);
            }

            Log::info('Authenticated user ID: ' . $user->id);
            Log::info('User role: ' . ($user->role->name ?? 'No role'));

            if (!$request->token) {
                Log::error('FCM Token Update: No token provided in request');
                return response()->json(['success' => false, 'error' => 'No token provided']);
            }

            // Add token for current user (keep existing tokens for other users too)
            $adminToken = AdminToken::firstOrCreate(
                [
                    'user_id' => $user->id,
                    'fcm_token' => $request->token
                ],
                [
                    'type' => $user->role->name,
                    'platform' => 'web'
                ]
            );

            Log::info('Token saved for user_id: ' . $user->id);

            Log::info('AdminToken created/found: ', $adminToken->toArray());
            Log::info('=== FCM Token Update Completed Successfully ===');

            return response()->json(['success' => true]);

        } catch (\Exception $e) {
            Log::error('FCM Token Update Exception: ' . $e->getMessage());
            Log::error('Stack trace: ' . $e->getTraceAsString());
            return response()->json(['success' => false, 'error' => $e->getMessage()]);
        }
    }

    public function test(){
        $admins = Admin::get();
        foreach ($admins as $admin){
            $admin->notify(new OrderNotification(1,'new'));
            die;
        }
    }

    /**
     * Log notification click from service worker (for debugging)
     */
    public function logNotificationClick(Request $request){
        Log::info('=== NOTIFICATION CLICK FROM SERVICE WORKER ===');
        Log::info('Click URL: ' . ($request->url ?? 'NULL'));
        Log::info('Click Data: ', $request->all());
        Log::info('=== END NOTIFICATION CLICK LOG ===');

        return response()->json(['success' => true, 'logged' => true]);
    }
    public function setSellerWalletTransaction()
    {
        try {
            $items = OrderItem::with(['productVariant', 'seller'])
                ->where('active_status', 6)->where('is_credited', 0)
                ->get();
            $productIds = $items->pluck('productVariant.product_id')->unique();
            $productInfo = Product::whereIn('id', $productIds)
                ->select('id', 'return_status', 'return_days','seller_id','category_id')
                ->get()
                ->keyBy('id');
    
            foreach ($items as $item) {
               try {
               
                    if (is_object($item->productVariant)) {
                       
                        $productId = $item->productVariant->product_id;
                        $product_info = $productInfo->get($productId);
    
                        if ($product_info && $product_info->return_status == 1) {
                            if (today() > $item->created_at->addDays($product_info->return_days)) {
                                $this->processSellerTransaction($item, $product_info);
                            }
                        } else {
                            $this->processSellerTransaction($item, $product_info);
                        }
                    }
                } catch (Exception $e) {
                    \Log::error("Set seller wallet transaction :",[$e->getMessage()] );
                }
            }
        } catch (Exception $e) {
           
            \Log::error("Set seller wallet transactions :",[$e->getMessage()] );
        }
    }
    
    private function processSellerTransaction($item, $product_info)
    {
        try {
            $existsInSellerWalletTransaction = SellerWalletTransaction::where('order_item_id', $item->id)->exists();
    
            if (!$existsInSellerWalletTransaction) {
               
                $commission = isset($item->seller->commission) ? $item->seller->commission : 0;

                $seller_amount = $item->sub_total - ($item->sub_total * $commission / 100);
                $seller_id = $item->seller_id;
    
                $getSellerWalletBalance = CommonHelper::getSellerWalletBalance($seller_id);
                $new_balance = $getSellerWalletBalance + $seller_amount;
    
                CommonHelper::updateSellerWalletBalance($new_balance, $seller_id);
                CommonHelper::addSellerWalletTransaction($item->order_id, $item->id, $seller_id, 'credit', $seller_amount, 'Order Item Commission');
    
                OrderItem::where('id', $item->id)->update(['is_credited' => 1]);
            }
        } catch (Exception $e) {
            
            \Log::error("Process seller transaction :",[$e->getMessage()] );
        }
    }
    public function unauthorized()
    {
        $data = [];
        $invoice = view('unauthorized', $data)->render();
        return $invoice;
    }
    public function getAdminSettings()
    {
        $logo = "";
        $app_name = "";
        $support_email = "";
        $support_number = "";
        $google_place_api_key = "";
        $google_map_api_key = "";
        $googleMapApiKey = "";
        $currency = "";
        $purchase_code = "";
        $logo_full_path = "";
        $delivery_boy_bonus_settings = 0;
        $isDemoMode = 0;

        $website_url = "";
        $copyright_details = "";

        // Firebase keys
        $apiKey = "";
        $authDomain = "";
        $projectId = "";
        $storageBucket = "";
        $messagingSenderId = "";
        $appId = "";
        $measurementId = "";

        
            $app_name = Setting::get_value('app_name') ?? "eGrocer";
            $support_email = Setting::get_value('support_email') ?? "";
            $support_number = Setting::get_value('support_number') ?? "";

            $logo = Setting::get_value('logo') ?? "";
            if ($logo !== "") {
                $logo_full_path = url('/') . '/storage/' . $logo;
            } else {
                $logo_full_path = asset('images/favicon.png');
            }

            $panel_login_background_img = Setting::get_value('panel_login_background_img') ?? "";
            $panel_login_background_img_full_path = '';
            if ($panel_login_background_img !== "") {
                $panel_login_background_img_full_path = url('/') . '/storage/' . $panel_login_background_img;
            } else {
                $panel_login_background_img_full_path = asset('images/panel_login_background_img.jpg');
            }

            $google_place_api_key = Setting::get_value('google_place_api_key') ?? "";
            $google_map_api_key = Setting::get_value('google_map_api_key') ?? "";
            $apiKey = Setting::get_value('apiKey') ?? "";
            $googleMapApiKey = Setting::get_value('googleMapApiKey') ?? "";
            $currency = Setting::get_value('currency') ?? "$";
            $purchase_code = Setting::get_value('purchase_code') ?? "";

            $website_url = Setting::get_value('website_url') ?? "";
            $copyright_details = Setting::get_value('copyright_details') ?? "";

            $delivery_boy_bonus_settings = Setting::get_value('delivery_boy_bonus_settings') ?? 0;

            // Firebase keys
            $authDomain = Setting::get_value('authDomain') ?? "";
            $projectId = Setting::get_value('projectId') ?? "";
            $storageBucket = Setting::get_value('storageBucket') ?? "";
            $messagingSenderId = Setting::get_value('messagingSenderId') ?? "";
            $appId = Setting::get_value('appId') ?? "";
            $measurementId = Setting::get_value('measurementId') ?? "";

            $isDemoMode = isDemoMode() ?? 0;
       

        return response()->json([
            'app_name' => $app_name,
            'support_email' => $support_email,
            'support_number' => $support_number,
            'logo_full_path' => $logo_full_path,
            'panel_login_background_img_full_path' => $panel_login_background_img_full_path,
            'google_place_api_key' => $google_place_api_key,
            'google_map_api_key' => $google_map_api_key,
            'googleMapApiKey' => $googleMapApiKey,
            'currency' => $currency,
            'purchase_code' => $purchase_code,
            'website_url' => $website_url,
            'copyright_details' => $copyright_details,
            'delivery_boy_bonus_settings' => $delivery_boy_bonus_settings,
            'firebase' => [
                'apiKey' => $apiKey,
                'authDomain' => $authDomain,
                'projectId' => $projectId,
                'storageBucket' => $storageBucket,
                'messagingSenderId' => $messagingSenderId,
                'appId' => $appId,
                'measurementId' => $measurementId,
            ],
            'isDemoMode' => $isDemoMode,
        ]);
    }

}
