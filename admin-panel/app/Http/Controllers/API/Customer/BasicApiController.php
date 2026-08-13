<?php

// namespace App\Http\Controllers\Api\Customer;
namespace App\Http\Controllers\API\Customer;

use App\Helpers\CommonHelper;


use App\Services\StoreDistanceService;
use App\Services\SellerFilterService;
use App\Services\RatingService;
use App\Services\CityZoneService;

use App\Helpers\ProductHelper;
use App\Http\Controllers\Controller;
use App\Http\Repository\CategoryRepository;
use App\Http\Repository\ProductRepository;
use App\Models\Admin;
use App\Models\Bookmark;
use App\Models\Brand;
use App\Models\Cart;
use App\Models\Category;
use App\Models\CategoryGroup;
use App\Models\CategorySubGroup;
use App\Models\Country;
use App\Models\City;
use App\Models\DeliveryBoy;
use App\Models\Faq;
use App\Models\Favorite;
use App\Models\Newsletter;
use App\Models\Notification;
use App\Models\Offer;
use App\Models\OrderStatusList;
use App\Models\ProductImages;
use App\Models\ProductVariant;
use App\Models\PromoCode;
use App\Models\Seller;
use App\Models\Product;
use App\Models\Setting;
use App\Models\Slider;
use App\Models\SocialMedia;
use App\Models\Store;
use App\Models\SellerRegistrationHelper;
use App\Models\Tax;
use App\Models\Transaction;
use App\Models\WalletTransaction;
use App\Models\PaytmTransaction;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use mysql_xdevapi\Exception;
use function App\Models\Setting;
use Response;
use App\Models\SubCategoryGroup;


class BasicApiController extends Controller
{
    public $productRepository;
    public $categoryRepository;

    public function __construct(ProductRepository $productRepository, CategoryRepository $categoryRepository)
    {
        $this->productRepository = $productRepository;
        $this->categoryRepository = $categoryRepository;
    }

    //Calculate Distance Testing for development
    public function findGoogleMapDistanceTest(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitudeFrom' => 'required',
            'longitudeFrom' => 'required',
            'latitudeTo' => 'required',
            'longitudeTo' => 'required',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $latitudeFrom = $request->latitudeFrom;
        $longitudeFrom = $request->longitudeFrom;
        $latitudeTo = $request->latitudeTo;
        $longitudeTo = $request->longitudeTo;
        $data = CommonHelper::findGoogleMapDistance($latitudeFrom, $longitudeFrom, $latitudeTo, $longitudeTo);
        echo json_encode($data);
    }

    public function getCategories(Request $request)
    {
        $limit = ($request->limit);
        $offset = ($request->offset);

        $category_id = $request->get('category_id', 0);

        $category_slug = $request->get('slug');

        if (isset($category_slug) && !empty($category_slug)) {
            $category = Category::where('status', 1)->where('slug', $category_slug)->first();

            $categories = Category::where('status', 1)->where('parent_id', $category->id);

        } else {
            $categories = Category::where('status', 1)->where('parent_id', $category_id);
        }

        $total = $categories->count();
        if (isset($limit) && $limit > 0) {
            $categories = $categories->orderBy('row_order', 'ASC')->offset($offset)->limit($limit)->get(['id', 'name', 'subtitle', 'slug', 'image']);
        } else {
            $categories = $categories->orderBy('row_order', 'ASC')->get(['id', 'name', 'subtitle', 'slug', 'image']);
        }
        $categories = $categories->makeHidden(['image']);


        if (count($categories) > 0) {
            return CommonHelper::responseWithData($categories, $total);
        } else {
            return CommonHelper::responseError(__('no_category_found'));
        }
    }

    public function getUserTransactions(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user_id = auth()->user()->id;
        $type = $request->type;
        $filter = $request->get('filter', 'all'); // New filter parameter: all, added, cashback, refund, used

        $limit = $request->get('limit', 10);
        $offset = $request->get('offset', 0);
        $total = Transaction::where('user_id', $user_id)->get();

        if ($type == "transactions") {
            $transactions = Transaction::where('user_id', $user_id)
                ->where('type', '!=', 'delivery_boy_cash_collection')
                ->orderBy('created_at', 'DESC');
            $total = $transactions->count();
            $transactions = $transactions->offset($offset)->limit($limit)->get();
            $transactions = $transactions->makeHidden(['user_id', 'order_id', 'payu_txn_id', 'updated_at', 'transaction_date']);

            return CommonHelper::responseWithData($transactions, $total);
        } elseif ($type == "wallet") {
            $wallet_transactions = WalletTransaction::where('user_id', $user_id);

            // Apply filter based on transaction type
            switch ($filter) {
                case 'added':
                    // Wallet balance added (top-ups) - credits that are NOT refunds or cashback
                    $wallet_transactions->where('type', 'credit')
                        ->where('message', 'NOT LIKE', '%Refund%')
                        ->where('message', 'NOT LIKE', '%Cashback%');
                    break;

                case 'cashback':
                    // Cashback transactions
                    $wallet_transactions->where('type', 'credit')
                        ->where('message', 'LIKE', '%Cashback%');
                    break;

                case 'refund':
                    // Refund transactions
                    $wallet_transactions->where('type', 'credit')
                        ->where('message', 'LIKE', '%Refund%');
                    break;

                case 'used':
                    // Used for order placement (debits)
                    $wallet_transactions->where('type', 'debit');
                    break;

                case 'all':
                default:
                    // No filter - show all transactions
                    break;
            }

            $wallet_transactions->orderBy('created_at', 'DESC');
            $total = $wallet_transactions->count();
            $wallet_transactions = $wallet_transactions->offset($offset)->limit($limit)->get();

            for ($i = 0; $i < count($wallet_transactions); $i++) {
                $wallet_transactions[$i]['last_updated'] = (isset($wallet_transactions[$i]['last_updated']) == null) ? "" : $wallet_transactions[$i]['last_updated'];
                $wallet_transactions[$i]['status'] = $wallet_transactions[$i]['type'];
                $wallet_transactions[$i]['message'] = $wallet_transactions[$i]['message'] == 'Used against Order Placement' ? 'Order Successfully Placed' : $wallet_transactions[$i]['message'];
            }
            return CommonHelper::responseWithData($wallet_transactions, $total);
        }
    }



    public function getUserTransactions111(Request $request)
    {
        $user_id = auth()->user()->id;
        $limit = ($request->limit) ?? 10;
        $offset = ($request->offset) ?? 0;
        $total = Transaction::where('user_id', $user_id)->count();
        $transactions = Transaction::where('user_id', $user_id)
            ->orderBy('created_at', 'DESC')
            ->offset($offset)
            ->limit($limit)
            ->get();
        $transactions = $transactions->makeHidden(['user_id', 'order_id', 'payu_txn_id', 'updated_at', 'transaction_date']);
        return CommonHelper::responseWithData($transactions, $total);
    }



    public function addWalletBalance(Request $request)
    {
        $requestId = uniqid('wallet_add_', true);

        try {
            Log::info('=== ADD WALLET BALANCE REQUEST START ===', [
                'request_id' => $requestId,
                'user_id' => auth()->id(),
                'has_transaction_id' => $request->filled('transaction_id'),
                'payment_method' => $request->payment_method ?? 'manual'
            ]);

            // Validation rules - transaction_id required if payment_method is paytm
            $validator = Validator::make($request->all(), [
                'type' => 'required|in:credit,debit',
                'amount' => 'required|numeric|min:0.01',
                'payment_method' => 'nullable|string|in:paytm,phonepe,manual',
                'transaction_id' => 'required_if:payment_method,paytm,phonepe|string',
                'message' => 'nullable|string|max:500',
                'order_id' => 'nullable|integer',
                'order_item_id' => 'nullable|integer'
            ]);

            if ($validator->fails()) {
                Log::warning('Add Wallet Balance: Validation failed', [
                    'request_id' => $requestId,
                    'errors' => $validator->errors()->toArray()
                ]);
                return CommonHelper::responseError($validator->errors()->first());
            }

            $user = auth()->user();
            if (!$user) {
                return CommonHelper::responseError('User not authenticated.');
            }

            $message = $request->get('message', 'Wallet transaction by user');
            $amount = floatval($request->amount);
            $type = $request->type;
            $order_id = $request->get('order_id', 0);
            $order_item_id = $request->order_item_id;
            $paymentMethod = $request->payment_method ?? 'manual';
            $transactionId = $request->transaction_id;

            Log::info('Add Wallet Balance: Processing request', [
                'request_id' => $requestId,
                'user_id' => $user->id,
                'type' => $type,
                'amount' => $amount,
                'payment_method' => $paymentMethod
            ]);

            // If payment method is Paytm, verify payment first
            if ($paymentMethod === 'paytm' && $transactionId) {
                Log::info('Add Wallet Balance: Paytm payment verification required', [
                    'request_id' => $requestId,
                    'transaction_id' => $transactionId
                ]);

                DB::beginTransaction();
                try {
                    // Check if Paytm payment exists and is valid
                    $paytmTransaction = PaytmTransaction::where('txn_id', $transactionId)
                        ->where('user_id', $user->id)
                        ->lockForUpdate()
                        ->first();

                    if (!$paytmTransaction) {
                        DB::rollBack();
                        Log::error('Add Wallet Balance: Paytm transaction not found', [
                            'request_id' => $requestId,
                            'transaction_id' => $transactionId,
                            'user_id' => $user->id
                        ]);
                        return CommonHelper::responseError('Payment transaction not found. Please verify your payment first.');
                    }

                    // Verify payment is successful
                    if (!$paytmTransaction->isSuccessful()) {
                        DB::rollBack();
                        Log::error('Add Wallet Balance: Paytm payment not successful', [
                            'request_id' => $requestId,
                            'transaction_id' => $transactionId,
                            'status' => $paytmTransaction->status
                        ]);
                        return CommonHelper::responseError('Payment was not successful. Status: ' . $paytmTransaction->status);
                    }

                    // Verify payment is captured
                    if (!$paytmTransaction->isCaptured()) {
                        DB::rollBack();
                        Log::error('Add Wallet Balance: Paytm payment not captured', [
                            'request_id' => $requestId,
                            'transaction_id' => $transactionId
                        ]);
                        return CommonHelper::responseError('Payment has not been captured yet.');
                    }

                    // Verify payment type is wallet topup
                    if ($paytmTransaction->type_of_payment !== PaytmTransaction::$typeWalletTopup) {
                        DB::rollBack();
                        Log::error('Add Wallet Balance: Invalid payment type', [
                            'request_id' => $requestId,
                            'transaction_id' => $transactionId,
                            'type_of_payment' => $paytmTransaction->type_of_payment,
                            'expected' => PaytmTransaction::$typeWalletTopup
                        ]);
                        return CommonHelper::responseError('This payment is not for wallet top-up.');
                    }

                    // Check if payment is already used (linked to wallet transaction)
                    if ($paytmTransaction->wallet_transaction_id !== null) {
                        DB::rollBack();
                        Log::error('Add Wallet Balance: Paytm payment already used', [
                            'request_id' => $requestId,
                            'transaction_id' => $transactionId,
                            'wallet_transaction_id' => $paytmTransaction->wallet_transaction_id
                        ]);
                        return CommonHelper::responseError('This payment has already been used for wallet credit.');
                    }

                    // Verify amount matches (allow small floating point difference)
                    if (abs($paytmTransaction->amount - $amount) > 0.01) {
                        DB::rollBack();
                        Log::error('Add Wallet Balance: Amount mismatch', [
                            'request_id' => $requestId,
                            'transaction_id' => $transactionId,
                            'payment_amount' => $paytmTransaction->amount,
                            'requested_amount' => $amount
                        ]);
                        return CommonHelper::responseError('Amount mismatch. Payment amount: ₹' . $paytmTransaction->amount . ', Requested: ₹' . $amount);
                    }

                    // Override amount with exact payment amount to avoid floating point issues
                    $amount = $paytmTransaction->amount;

                    Log::info('Add Wallet Balance: Paytm payment verified successfully', [
                        'request_id' => $requestId,
                        'transaction_id' => $transactionId,
                        'amount' => $amount
                    ]);

                    // Update message for Paytm payment
                    $message = 'Wallet recharge via Paytm (Txn: ' . $transactionId . ')';

                } catch (\Exception $e) {
                    DB::rollBack();
                    Log::error('Add Wallet Balance: Paytm verification exception', [
                        'request_id' => $requestId,
                        'transaction_id' => $transactionId,
                        'error' => $e->getMessage(),
                        'trace' => $e->getTraceAsString()
                    ]);
                    return CommonHelper::responseError('Failed to verify payment: ' . $e->getMessage());
                }
            } else {
                // Manual wallet transaction (no payment gateway)
                DB::beginTransaction();
            }

            // Calculate new balance
            $balance = $user->balance;
            $newBalance = ($type == 'credit') ? $balance + $amount : $balance - $amount;

            if ($newBalance < 0) {
                DB::rollBack();
                Log::error('Add Wallet Balance: Insufficient balance', [
                    'request_id' => $requestId,
                    'user_id' => $user->id,
                    'current_balance' => $balance,
                    'debit_amount' => $amount
                ]);
                return CommonHelper::responseError('Insufficient wallet balance.');
            }

            Log::info('Add Wallet Balance: Updating user balance', [
                'request_id' => $requestId,
                'user_id' => $user->id,
                'old_balance' => $balance,
                'new_balance' => $newBalance
            ]);

            // Update user balance
            User::where('id', $user->id)->update(['balance' => $newBalance]);

            // Create wallet transaction record
            $walletTransaction = WalletTransaction::create([
                'order_id' => $order_id,
                'order_item_id' => $order_item_id,
                'user_id' => $user->id,
                'type' => $type,
                'amount' => $amount,
                'txn_id' => $transactionId ?? null,
                'payment_type' => $paymentMethod === 'paytm' ? 'paytm' : ($paymentMethod === 'phonepe' ? 'phonepe' : 'manual'),
                'message' => $message,
                'status' => 1,
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now()
            ]);

            Log::info('Add Wallet Balance: Wallet transaction created', [
                'request_id' => $requestId,
                'wallet_transaction_id' => $walletTransaction->id,
                'user_id' => $user->id,
                'amount' => $amount
            ]);

            // If Paytm payment, link it to wallet transaction
            if ($paymentMethod === 'paytm' && isset($paytmTransaction)) {
                $paytmTransaction->update([
                    'wallet_transaction_id' => $walletTransaction->id
                ]);

                Log::info('Add Wallet Balance: Paytm transaction linked to wallet', [
                    'request_id' => $requestId,
                    'paytm_transaction_id' => $paytmTransaction->id,
                    'wallet_transaction_id' => $walletTransaction->id
                ]);
            }

            DB::commit();

            Log::info('=== ADD WALLET BALANCE SUCCESS ===', [
                'request_id' => $requestId,
                'user_id' => $user->id,
                'wallet_transaction_id' => $walletTransaction->id,
                'old_balance' => $balance,
                'new_balance' => $newBalance,
                'amount' => $amount,
                'type' => $type,
                'payment_method' => $paymentMethod
            ]);

            $data = array();
            $data['new_balance'] = $newBalance;
            $data['wallet_transaction_id'] = $walletTransaction->id;
            $data['amount'] = $amount;
            $data['type'] = $type;
            $data['message'] = __('wallet_recharged_successfully');
            return CommonHelper::responseWithData($data);

        } catch (\Exception $e) {
            if (DB::transactionLevel() > 0) {
                DB::rollBack();
            }

            Log::error('=== ADD WALLET BALANCE EXCEPTION ===', [
                'request_id' => $requestId ?? 'unknown',
                'user_id' => auth()->id(),
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString()
            ]);

            return CommonHelper::responseError('Failed to add wallet balance. Please try again later.');
        }
    }

    // Favorites
    public function getFavorites(Request $request)
    {

        $validator = Validator::make($request->all(), [
            'latitude' => 'required',
            'longitude' => 'required',
        ], [
            'latitude.required' => 'The latitude field is required.',
            'longitude.required' => 'The longitude field is required.'
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }


        $user_id = auth()->user()->id;
        $limit = ($request->limit) ?? 10;
        $offset = ($request->offset) ?? 0;

        $total = Favorite::select(DB::raw('COUNT(favorites.id) AS total'))->from('favorites')->Join('products', 'favorites.product_id', '=', 'products.id')->where('favorites.user_id', '=', $user_id)->first();


        try {
            $products = Favorite::select(
                'favorites.id',
                'favorites.user_id',
                'favorites.product_id',
                'products.tax_id',
                'products.row_order',
                'products.name',
                'products.slug',
                'products.category_id',
                'products.indicator',
                'products.manufacturer',
                'products.made_in',
                'products.return_status',
                'products.cancelable_status',
                'products.till_status',
                'products.image',
                'products.seller_id',
                'taxes.percentage as tax_percentage',
                'taxes.title as tax_title',
                'products.description',
                'products.status',
                'products.created_at',
                'cities.boundary_points',
                'co.name as country_made_in'
            )
                ->Join('products', 'favorites.product_id', '=', 'products.id')
                ->leftJoin("countries as co", "products.made_in", "=", "co.id")
                ->leftJoin('sellers', 'products.seller_id', '=', 'sellers.id')
                ->leftJoin('cities', 'sellers.city_id', '=', 'cities.id')
                ->leftJoin('taxes', 'products.tax_id', '=', 'taxes.id')
                ->where('favorites.user_id', '=', $user_id)
                ->orderBy('favorites.created_at', 'DESC')
                ->skip($offset)->take($limit)->get();

        } catch (\Exception $e) {
            Log::info("Favorites Error : " . $e->getMessage());
            throw $e;
            return CommonHelper::responseError("Something Went Wrong!");
        }
        $productArray = array();
        foreach ($products as $key => $row) {
            array_push($productArray, CommonHelper::getProductDetails($row->product_id, $user_id, true, $request));
        }

        if (!empty($productArray)) {
            return CommonHelper::responseWithData($productArray, $total->total);
        } else {
            return CommonHelper::responseError(__('no_items_found'));
        }

    }

    public function addToFavorite(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'product_id' => 'required',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $favorite = Favorite::where('user_id', auth()->user()->id)->where('product_id', $request->product_id)->first();
        if ($favorite) {
            return CommonHelper::responseError(__('product_already_added_as_favorite'));
        } else {
            $product = Product::where('id', $request->product_id)->first();
            if (!empty($product)) {
                $favorite = new Favorite();
                $favorite->user_id = auth()->user()->id;
                $favorite->product_id = $request->product_id;
                $favorite->save();
                return CommonHelper::responseSuccess(__('item_added_in_users_favorite_list_successfully'));
            } else {
                return CommonHelper::responseError(__('no_products_found'));
            }

        }
    }
    public function removeFromFavorite(Request $request)
    {
        $favorite = Favorite::where('user_id', auth()->user()->id);
        if (isset($request->product_id)) {
            $favorite->where('product_id', $request->product_id)->first();
            if ($favorite) {
                $favorite->delete();
                return CommonHelper::responseSuccess(__('item_removed_from_users_favorite_list_successfully'));
            } else {
                return CommonHelper::responseError(__('no_product_found'));
            }
        } else {
            $favorite->get();
            if (count($favorite) > 0) {
                $favorite->delete();
                return CommonHelper::responseSuccess(__('all_items_removed_from_users_favorite_list_successfully'));
            } else {
                return CommonHelper::responseError(__('no_product_found'));
            }
        }
    }

    // Faqs
    public function getFaqs(Request $request)
    {
        $limit = ($request->limit) ?? 10;
        $offset = ($request->offset) ?? 0;
        $total = Faq::where('role', 'customer')->count();
        $faqs = Faq::where('role', 'customer')->orderBy('id', 'DESC')->offset($offset)->limit($limit)->get();
        if ($faqs->count() > 0) {
            return CommonHelper::responseWithData($faqs, $total);
        } else {
            return CommonHelper::responseError(__('no_faq_found'));
        }
    }
    // Newsletter
    public function getNewsletter()
    {
        $newsletter = Newsletter::orderBy('id', 'DESC')->get();
        if (count($newsletter) > 0) {
            return CommonHelper::responseWithData($newsletter);
        } else {
            return CommonHelper::responseError(__('no_newsletter_found'));
        }
    }

    // Offer images
    public function addOffers(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'image' => 'required|mimes:jpeg,jpg,png,gif',
            'position' => 'required',
            'section_id' => ($request->position === 'below_section') ? 'required' : ""
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $offer = new Offer();
        $image = '';
        if ($request->hasFile('image')) {
            $file = $request->file('image');
            $fileName = time() . '_' . rand(1111, 99999) . '.' . $file->getClientOriginalExtension();
            $image = Storage::disk('public')->putFileAs('offers', $file, $fileName);
        }
        $offer->image = $image;
        $offer->position = $request->position;
        $offer->section_position = $request->section_id;
        $offer->save();
        return CommonHelper::responseSuccess(__('offer_saved_successfully'));
    }

    public function getOffers(Request $request)
    {
        $limit = $request->limit ?? 10;
        $offset = $request->offset ?? 0;
        $total = Offer::count();
        $offers = Offer::orderBy('id', 'DESC')->skip($offset)->take($limit)->get(['id', 'position', 'section_position', 'image']);
        $offers->makeHidden(['image']);
        if (count($offers)) {
            return CommonHelper::responseWithData($offers, $total);
        } else {
            return CommonHelper::responseError(__('no_offer_found'));
        }

    }
    public function removeOffers($id)
    {
        $offer = Offer::find($id);
        if ($offer) {
            @Storage::disk('public')->delete($offer->image);
            $offer->delete();
            return CommonHelper::responseSuccess(__('offer_deleted_successfully'));
        } else {
            return CommonHelper::responseSuccess(__('no_offer_found'));
        }
    }

    // slider
    public function addSliders(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required',
            'image' => 'required|mimes:jpeg,jpg,png,gif'
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $slider = new Slider();
        $slider->type = $request->type;
        $slider->type_id = $request->type_id ?? 0;
        $image = '';
        if ($request->hasFile('image')) {
            $file = $request->file('image');
            $fileName = time() . '_' . rand(1111, 99999) . '.' . $file->getClientOriginalExtension();
            $image = Storage::disk('public')->putFileAs('sliders', $file, $fileName);
        }
        $slider->image = $image;
        $slider->slider_url = $request->slider_url;
        $slider->save();
        return CommonHelper::responseSuccess(__('slider_images_saved_successfully'));
    }

    public function getSliders(Request $request)
    {
        $limit = $request->limit ?? 10;
        $offset = $request->offset ?? 0;

        $query = Slider::where('status', 1);
        $total = $query->count();
        $slider = $query->orderBy('id', 'DESC')->skip($offset)->take($limit)->get(['type', 'type_id', 'image']);

        $slider = $slider->makeHidden(['product', 'category', 'image']);
        if (count($slider) > 0) {
            return CommonHelper::responseWithData($slider, $total);
        } else {
            return CommonHelper::responseError(__('no_slider_found'));
        }
    }

    public function removeSliders($id)
    {
        $slider = Slider::find($id);
        if ($slider) {
            @Storage::disk('public')->delete($slider->image);
            $slider->delete();
            return CommonHelper::responseSuccess(__('slider_deleted_successfully'));
        } else {
            return CommonHelper::responseSuccess(__('no_slider_found'));
        }
    }

    // Promo Code
    public function validatePromoCode(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'promo_code' => 'required',
            'total' => 'required'
        ]);

        if ($validator->fails()) {
            Log::warning('validatePromoCode: Validation failed', [
                'errors' => $validator->errors()->toArray(),
            ]);
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user_id = auth()->user()->id;
        $promo_code = $request->promo_code;
        $total = $request->total;

        Log::info('validatePromoCode: Starting promo code validation', [
            'user_id' => $user_id,
            'promo_code' => $promo_code,
            'cart_total' => $total,
        ]);

        $response = CommonHelper::validatePromoCode($user_id, $promo_code, $total);

        if ($response['is_applicable'] == 0) {
            Log::info('validatePromoCode: Promo code not applicable', [
                'user_id' => $user_id,
                'promo_code' => $promo_code,
                'reason' => $response['message'],
            ]);
            return CommonHelper::responseError($response['message']);
        } else {
            Log::info('validatePromoCode: Promo code validated successfully', [
                'user_id' => $user_id,
                'promo_code' => $promo_code,
                'promo_code_id' => $response['promo_code_id'],
                'discount' => $response['discount'],
                'discounted_amount' => $response['discounted_amount'],
            ]);

            // Save promo code data to cart_metadata and update billing
            try {
                $cartMetadata = \App\Models\CartMetadata::firstOrCreate(['user_id' => $user_id]);

                Log::info('validatePromoCode: Cart metadata fetched', [
                    'user_id' => $user_id,
                    'cart_metadata_id' => $cartMetadata->id,
                    'existing_promocode_id' => $cartMetadata->promocode_id,
                    'has_billing_summary' => !empty($cartMetadata->billing_summary),
                    'has_billing_breakdown' => !empty($cartMetadata->billing_breakdown),
                ]);

                // Save promo code info
                $cartMetadata->promocode_id = $response['promo_code_id'];
                $cartMetadata->promo_code = $response['promo_code'];

                $promoDiscount = $response['discount'];

                // Update billing_summary with promocode_discount and recalculate to_be_paid
                if ($cartMetadata->billing_summary) {
                    $billingSummary = $cartMetadata->billing_summary;
                    $oldToBePaid = $billingSummary['to_be_paid'] ?? 0;
                    $oldPromoDiscount = $billingSummary['promocode_discount'] ?? 0;

                    $billingSummary['promocode_discount'] = CommonHelper::doubleNumber($promoDiscount);

                    // Recalculate to_be_paid
                    $toBePaid = ($billingSummary['items_mrp'] ?? 0)
                        + ($billingSummary['combo_mrp'] ?? 0)
                        - ($billingSummary['discount'] ?? 0)
                        + ($billingSummary['delivery_charge'] ?? 0)
                        + ($billingSummary['delivery_tip'] ?? 0)
                        + ($billingSummary['additional_charges'] ?? 0)
                        + ($billingSummary['multi_order_charges'] ?? 0)
                        - $promoDiscount
                        - ($billingSummary['claimable_milestone_amount'] ?? 0);

                    if ($toBePaid < 0) {
                        $toBePaid = 0;
                    }

                    $billingSummary['to_be_paid'] = ceil($toBePaid);
                    $cartMetadata->billing_summary = $billingSummary;

                    Log::info('validatePromoCode: Updated billing_summary', [
                        'user_id' => $user_id,
                        'items_mrp' => $billingSummary['items_mrp'] ?? 0,
                        'combo_mrp' => $billingSummary['combo_mrp'] ?? 0,
                        'discount' => $billingSummary['discount'] ?? 0,
                        'delivery_charge' => $billingSummary['delivery_charge'] ?? 0,
                        'delivery_tip' => $billingSummary['delivery_tip'] ?? 0,
                        'additional_charges' => $billingSummary['additional_charges'] ?? 0,
                        'multi_order_charges' => $billingSummary['multi_order_charges'] ?? 0,
                        'old_promocode_discount' => $oldPromoDiscount,
                        'new_promocode_discount' => $promoDiscount,
                        'claimable_milestone_amount' => $billingSummary['claimable_milestone_amount'] ?? 0,
                        'old_to_be_paid' => $oldToBePaid,
                        'new_to_be_paid' => ceil($toBePaid),
                    ]);
                } else {
                    Log::warning('validatePromoCode: No billing_summary found in cart_metadata', [
                        'user_id' => $user_id,
                    ]);
                }

                // Update billing_breakdown with promocode_discount entry and update to_be_paid
                if ($cartMetadata->billing_breakdown) {
                    $billingBreakdown = $cartMetadata->billing_breakdown;
                    $updatedBreakdown = [];
                    $promoEntryExists = false;

                    foreach ($billingBreakdown as $entry) {
                        // Check if promo entry already exists
                        if ($entry['type'] === 'promocode_discount') {
                            $promoEntryExists = true;
                            $entry['amount'] = CommonHelper::doubleNumber($promoDiscount);
                            $entry['description'] = 'Discount from promo code: ' . $response['promo_code'];
                            $updatedBreakdown[] = $entry;
                        } elseif ($entry['type'] === 'to_be_paid') {
                            // Add promo entry before to_be_paid if it doesn't exist
                            if (!$promoEntryExists && $promoDiscount > 0) {
                                $updatedBreakdown[] = [
                                    'type' => 'promocode_discount',
                                    'label' => 'Coupon Discount',
                                    'description' => 'Discount from promo code: ' . $response['promo_code'],
                                    'amount' => CommonHelper::doubleNumber($promoDiscount),
                                    'currency' => $cartMetadata->billing_summary['currency'] ?? '₹',
                                    'is_credit' => true,
                                ];
                                Log::info('validatePromoCode: Added promocode_discount entry to billing_breakdown', [
                                    'user_id' => $user_id,
                                    'promo_code' => $response['promo_code'],
                                    'discount_amount' => $promoDiscount,
                                ]);
                            }

                            // Update to_be_paid calculation_summary and amount
                            if (isset($entry['calculation_summary'])) {
                                $entry['calculation_summary']['promocode_discount'] = CommonHelper::doubleNumber($promoDiscount);
                                $entry['calculation_summary']['final_total'] = ceil($cartMetadata->billing_summary['to_be_paid'] ?? 0);
                            }
                            $entry['amount'] = ceil($cartMetadata->billing_summary['to_be_paid'] ?? 0);

                            // Update description to include promo discount
                            if ($promoDiscount > 0) {
                                $entry['description'] = ($entry['description'] ?? '') . ' + Coupon (-' . CommonHelper::doubleNumber($promoDiscount) . ')';
                            }

                            $updatedBreakdown[] = $entry;
                        } else {
                            $updatedBreakdown[] = $entry;
                        }
                    }

                    $cartMetadata->billing_breakdown = $updatedBreakdown;

                    Log::info('validatePromoCode: Updated billing_breakdown', [
                        'user_id' => $user_id,
                        'promo_entry_existed' => $promoEntryExists,
                        'breakdown_count' => count($updatedBreakdown),
                    ]);
                } else {
                    Log::warning('validatePromoCode: No billing_breakdown found in cart_metadata', [
                        'user_id' => $user_id,
                    ]);
                }

                $cartMetadata->save();

                Log::info('validatePromoCode: Successfully saved promo code to cart_metadata', [
                    'user_id' => $user_id,
                    'promocode_id' => $response['promo_code_id'],
                    'promo_code' => $response['promo_code'],
                    'discount' => $promoDiscount,
                    'final_to_be_paid' => $cartMetadata->billing_summary['to_be_paid'] ?? 'N/A',
                ]);

            } catch (\Exception $e) {
                Log::error('validatePromoCode: Failed to save promo code to cart_metadata', [
                    'user_id' => $user_id,
                    'promo_code' => $promo_code,
                    'error' => $e->getMessage(),
                    'trace' => $e->getTraceAsString(),
                ]);
            }

            return CommonHelper::responseWithData($response);
        }
    }
    public function getPromoCode(Request $request)
    {
        $user_id = auth()->user()->id;
        $limit = ($request->limit) ?? 10;
        $offset = ($request->offset) ?? 0;
        $sort = ($request->sort) ?? 'id';
        $order = ($request->order) ?? 'DESC';
        if (!isset($request->amount) || empty($request->amount)) {
            return CommonHelper::responseError("Please Pass User id and amount");
        }
        $amount = $request->amount;

        $codes = PromoCode::select('id', 'message', 'promo_code', 'image', 'discount', 'discount_type', 'max_discount_amount', 'minimum_order_amount', 'start_date', 'end_date', 'repeat_usage', 'no_of_repeat_usage', 'no_of_users')
            ->where('status', '=', 1)
            ->whereRaw('CURDATE() between start_date and end_date');
        $total = $codes->count();
        $codes = $codes->orderBy($sort, $order)->skip($offset)->take($limit)->get()->toArray();
        if (!empty($codes)) {
            $currency = \App\Models\Setting::get_value('currency') ?? '₹';
            foreach ($codes as $key => $code) {
                $promo_code = $code["promo_code"];
                $validated = CommonHelper::validatePromoCode($user_id, $promo_code, $amount);
                $codes[$key]['is_applicable'] = $validated['is_applicable'] ?? 0;
                $codes[$key]['applicable_message'] = $validated['message'] ?? '';
                $codes[$key]['image_url'] = !empty($validated['image_url']) ? $validated['image_url'] : $code["image_url"];
                $codes[$key]['promo_code_message'] = !empty($validated['promo_code_message']) ? $validated['promo_code_message'] : $code["message"];
                $codes[$key]['calculated_discount'] = (isset($validated['discount']) && $validated['discount'] > 0) ? $validated['discount'] : 0;
                $codes[$key]['discounted_amount'] = (isset($validated['discounted_amount']) && $validated['discounted_amount'] > 0) ? $validated['discounted_amount'] : 0;

                // Build see_more details
                $see_more = [];
                if ($code['discount_type'] === 'percentage') {
                    $see_more[] = 'Get ' . $code['discount'] . '% off up to ' . $currency . $code['max_discount_amount'];
                } else {
                    $see_more[] = 'Get flat ' . $currency . $code['discount'] . ' off';
                }
                $see_more[] = 'Minimum order amount: ' . $currency . $code['minimum_order_amount'];
                $see_more[] = 'Valid from ' . date('d M Y', strtotime($code['start_date'])) . ' to ' . date('d M Y', strtotime($code['end_date']));
                if ($code['repeat_usage'] == 1 && $code['no_of_repeat_usage'] > 0) {
                    $see_more[] = 'Can be used ' . $code['no_of_repeat_usage'] . ' time(s) per user';
                } else {
                    $see_more[] = 'One time use only';
                }
                $see_more[] = 'Available for first ' . $code['no_of_users'] . ' users';

                $codes[$key]['see_more'] = $see_more;

                // Remove raw fields from response
                unset($codes[$key]['discount_type'], $codes[$key]['max_discount_amount'],
                      $codes[$key]['minimum_order_amount'], $codes[$key]['start_date'],
                      $codes[$key]['end_date'], $codes[$key]['repeat_usage'],
                      $codes[$key]['no_of_repeat_usage'], $codes[$key]['no_of_users']);
            }
            return CommonHelper::responseWithData($codes, $total);
        } else {
            return CommonHelper::responseError("Data not Found!");
        }
    }

    public function getSocialMedia()
    {
        $socialMedia = SocialMedia::orderBy('id', 'DESC')->get();
        if (count($socialMedia)) {
            return CommonHelper::responseWithData($socialMedia);
        } else {
            return CommonHelper::responseError("No Offer Found!");
        }
    }
    public function getCities(Request $request)
    {
        $limit = $request->limit ?? 10;
        $offset = $request->offset ?? 0;

        if (isset($request->search) && $request->search != '') {
            $search = $request->search;
            $where = " `id` like '%" . $search . "%' OR `name` like '%";
        }
        $total = City::count();
        $sql = City::select("*");
        if (isset($where) && $where != "") {
            $sql = $sql->whereRaw($where);
        }
        $city = $sql->orderBy("id", "DESC")->skip($offset)->take($limit)->get();
        $city = $city->makeHidden(['range_wise_charges', 'geolocation_type', 'radius', 'boundary_points']);
        if (count($city)) {
            return CommonHelper::responseWithData($city, $total);
        } else {
            return CommonHelper::responseError(__('no_city_found'));
        }
    }

    public function getCity(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required',
            'longitude' => 'required',
        ], [
            'required' => 'The city :attribute field is required.'
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $city = CommonHelper::getDeliverableCity($request->latitude, $request->longitude);

        if (empty($city) && isDemoMode()) {
            $city = CommonHelper::getDefaultCity();
        }

        if (empty($city)) {
            return CommonHelper::responseError(__('we_doesnt_delivery_at_selected_city'));
        }

        // Convert city object to array to modify specific fields
        $cityArray = $city->toArray();

        // Decode range_wise_charges from JSON string to array
        if (isset($cityArray['range_wise_charges']) && !empty($cityArray['range_wise_charges'])) {
            $cityArray['range_wise_charges'] = json_decode($cityArray['range_wise_charges'], true);
        } else {
            $cityArray['range_wise_charges'] = [];
        }

        // Decode boundary_points from JSON string to array
        if (isset($cityArray['boundary_points']) && !empty($cityArray['boundary_points'])) {
            $cityArray['boundary_points'] = json_decode($cityArray['boundary_points'], true);
        } else {
            $cityArray['boundary_points'] = [];
        }

        return CommonHelper::responseWithData($cityArray);
    }

    public function getSeller(Request $request)
    {

        if (!isset($request->product_id) && !isset($request->seller_id)) {
            return CommonHelper::responseError(__('something_is_missing'));
        }

        if (
            isset($request->product_id) && !empty(isset($request->product_id)) &&
            $request->product_id !== 0
        ) {
            $product = Product::where("id", $request->product_id)->first();
            if ($product) {
                $seller_id = $product->seller_id;
            } else {
                return CommonHelper::responseError(__('seller_not_found'));
            }
        } else {
            $seller_id = $request->seller_id;
        }
        $seller = Seller::select('id', 'name', 'store_name', 'email', 'mobile', 'store_url', 'logo')->where("id", $seller_id)->first();
        $seller = $seller->makeHidden(['logo']);
        if ($seller) {
            // Add is_bookmarked status
            $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : null;
            $seller->is_bookmarked = $user_id ? $this->checkSellerBookmarked($user_id, $seller->id) : 0;
            // Convert to array to ensure is_bookmarked is included in response
            $sellerArray = $seller->toArray() + ['is_bookmarked' => $seller->is_bookmarked];
            return CommonHelper::responseWithData($sellerArray);
        } else {
            return CommonHelper::responseError(__('seller_not_found'));
        }
    }

    public function getSellers(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required',
            'longitude' => 'required',
        ], [
            'latitude.required' => 'The latitude field is required.',
            'longitude.required' => 'The longitude field is required.'
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : null;

        $sellers = Seller::select('sellers.id', 'sellers.name', 'sellers.store_name', 'sellers.logo', DB::raw("ROUND(6371 * acos(cos(radians(" . $request->latitude . "))
                                * cos(radians(sellers.latitude)) * cos(radians(sellers.longitude) - radians(" . $request->longitude . "))
                                + sin(radians(" . $request->latitude . ")) * sin(radians(sellers.latitude))), 2) AS distance"), 'cities.max_deliverable_distance')
            ->leftJoin("cities", "sellers.city_id", "cities.id")
            ->where('status', Seller::$statusActive)
            ->whereExists(function ($query) {
                $query->select(DB::raw(1))
                    ->from('products')
                    ->whereColumn('products.seller_id', 'sellers.id');
            })
            ->orderBy('distance', 'asc')
            ->get();

        // Add is_bookmarked flag for each seller
        if ($user_id) {
            $sellers = $sellers->map(function ($seller) use ($user_id) {
                $isBookmarked = Bookmark::where('user_id', $user_id)
                    ->where('type', 'seller')
                    ->where('bookmarkable_type', 'App\Models\Seller')
                    ->where('bookmarkable_id', $seller->id)
                    ->exists();
                $seller->is_bookmarked = $isBookmarked ? 1 : 0;
                return $seller;
            });
        } else {
            // For non-authenticated users, set is_bookmarked to 0
            $sellers = $sellers->map(function ($seller) {
                $seller->is_bookmarked = 0;
                return $seller;
            });
        }

        // Convert to array to ensure is_bookmarked and other fields are properly serialized
        $sellersArray = $sellers->map(function ($seller) {
            return $seller->makeHidden(['national_identity_card_url', 'address_proof_url', 'logo'])->toArray() + ['is_bookmarked' => $seller->is_bookmarked];
        })->all();

        $total = count($sellersArray);
        if ($total > 0) {
            return CommonHelper::responseWithData($sellersArray, $total);
        } else {
            return CommonHelper::responseError(__('seller_not_found'));
        }
    }

    public function distance(Request $request)
    {
        try {
            Log::info('distance: Request received', [
                'latitude' => $request->latitude,
                'longitude' => $request->longitude,
                'ip' => $request->ip(),
            ]);

            $validator = Validator::make($request->all(), [
                'latitude' => 'required',
                'longitude' => 'required',
            ], [
                'latitude.required' => 'The latitude field is required.',
                'longitude.required' => 'The longitude field is required.'
            ]);
            if ($validator->fails()) {
                Log::warning('distance: Validation failed', [
                    'errors' => $validator->errors()->toArray(),
                ]);
                return CommonHelper::responseError($validator->errors()->first());
            }

            $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : '';
            $customerLat = (float) $request->latitude;
            $customerLon = (float) $request->longitude;

            Log::info('distance: Processing distance calculation', [
                'user_id' => $user_id ?: 'guest',
                'customer_lat' => $customerLat,
                'customer_lon' => $customerLon,
            ]);

            // Step 1: Detect which city the customer is in by checking boundary_points
            $detectedCity = CityZoneService::detectCity($customerLat, $customerLon);

            if (!$detectedCity) {
                Log::warning('distance: Customer location not within any city boundary', [
                    'customer_lat' => $customerLat,
                    'customer_lon' => $customerLon,
                ]);

                // Fallback: Return default estimated time
                return CommonHelper::responseWithData([
                    'estimated_time' => 30,
                    'distance_km' => 0,
                    'zones' => [],
                    'total_zones' => 0,
                    'city_detected' => false,
                    'nearest_store' => null,
                    'message' => 'Service not available in your location'
                ]);
            }

            Log::info('distance: City detected', [
                'city_id' => $detectedCity->id,
                'city_name' => $detectedCity->name,
                'customer_lat' => $customerLat,
                'customer_lon' => $customerLon,
            ]);

            // Step 2: Get all active store locations for this city using city_id
            $storeLocations = DB::table('store_locations')
                ->where('city_id', $detectedCity->id)
                ->where('status', 1)
                ->get();

            if ($storeLocations->isEmpty()) {
                Log::warning('distance: No active store locations found for city', [
                    'city_id' => $detectedCity->id,
                    'city_name' => $detectedCity->name,
                ]);

                return CommonHelper::responseWithData([
                    'estimated_time' => 30,
                    'distance_km' => 0,
                    'zones' => [],
                    'total_zones' => 0,
                    'city_detected' => true,
                    'city_id' => $detectedCity->id,
                    'city_name' => $detectedCity->name,
                    'nearest_store' => null,
                    'message' => 'No store locations available in your city'
                ]);
            }

            Log::info('distance: Store locations fetched for city', [
                'city_id' => $detectedCity->id,
                'city_name' => $detectedCity->name,
                'total_locations' => $storeLocations->count(),
            ]);

            // Step 3: Calculate distance to each store and find the nearest
            $nearestStore = null;
            $nearestDistance = PHP_FLOAT_MAX;
            $zonesData = [];

            foreach ($storeLocations as $location) {
                try {
                    $storeDistance = CommonHelper::calculateDistance(
                        $customerLat,
                        $customerLon,
                        $location->latitude,
                        $location->longitude
                    );

                    $storeEstimatedTime = CommonHelper::estimateTravelTime($storeDistance);

                    // Ensure minimum 15 minutes delivery time
                    if ($storeEstimatedTime < 15) {
                        $storeEstimatedTime = 15;
                    }

                    // Track nearest store
                    if ($storeDistance < $nearestDistance) {
                        $nearestDistance = $storeDistance;
                        $nearestStore = [
                            'id' => $location->id,
                            'name' => $location->name,
                            'latitude' => $location->latitude,
                            'longitude' => $location->longitude,
                            'distance' => $storeDistance,
                            'estimated_time' => $storeEstimatedTime,
                        ];
                    }

                    $zonesData[] = [
                        'store_id' => (int) $location->id,
                        'store_name' => $location->name,
                        'address' => $location->address,
                        'phone' => $location->phone,
                        'email' => $location->email,
                        'latitude' => (float) $location->latitude,
                        'longitude' => (float) $location->longitude,
                        'distance_km' => round($storeDistance, 2),
                        'estimated_time_minutes' => $storeEstimatedTime,
                        'estimated_time_formatted' => $this->formatEstimatedTime($storeEstimatedTime),
                        'is_nearest' => false, // Will update this below
                    ];

                    Log::info('distance: Store calculation completed', [
                        'store_id' => $location->id,
                        'store_name' => $location->name,
                        'distance' => $storeDistance,
                        'estimated_time' => $storeEstimatedTime,
                    ]);
                } catch (\Exception $e) {
                    Log::error('distance: Store calculation failed', [
                        'store_id' => $location->id,
                        'store_name' => $location->name,
                        'error' => $e->getMessage(),
                    ]);
                    // Continue with next store if one fails
                }
            }

            // Mark the nearest store in zones data
            if ($nearestStore) {
                foreach ($zonesData as &$zone) {
                    if ($zone['store_id'] === $nearestStore['id']) {
                        $zone['is_nearest'] = true;
                        break;
                    }
                }
            }

            Log::info('distance: Nearest store found', [
                'user_id' => $user_id ?: 'guest',
                'city_id' => $detectedCity->id,
                'city_name' => $detectedCity->name,
                'nearest_store_id' => $nearestStore ? $nearestStore['id'] : null,
                'nearest_store_name' => $nearestStore ? $nearestStore['name'] : null,
                'nearest_distance' => $nearestStore ? $nearestStore['distance'] : null,
                'nearest_estimated_time' => $nearestStore ? $nearestStore['estimated_time'] : null,
            ]);

            // Step 4: Build response using nearest store's data
            $output = [
                'estimated_time' => $nearestStore ? $nearestStore['estimated_time'] : 30,
                'distance_km' => $nearestStore ? round($nearestStore['distance'], 2) : 0,
                'nearest_store' => $nearestStore ? [
                    'id' => $nearestStore['id'],
                    'name' => $nearestStore['name'],
                    'latitude' => (float) $nearestStore['latitude'],
                    'longitude' => (float) $nearestStore['longitude'],
                ] : null,
                'city_detected' => true,
                'city_id' => $detectedCity->id,
                'city_name' => $detectedCity->name,
                'zones' => $zonesData,
                'total_zones' => count($zonesData),
            ];

            return CommonHelper::responseWithData($output);

        } catch (\Exception $e) {
            Log::error('distance: API error occurred', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            // Return default 30 minutes if error occurs
            $output = [
                'estimated_time' => 30,
                'distance_km' => 0,
                'zones' => [],
                'total_zones' => 0,
                'city_detected' => false,
                'nearest_store' => null,
                'error' => 'Unable to calculate distance',
            ];

            return CommonHelper::responseWithData($output);
        }
    }

    /**
     * Format estimated time in minutes to a readable string
     *
     * @param int $minutes
     * @return string
     */
    private function formatEstimatedTime($minutes)
    {
        if ($minutes < 60) {
            return $minutes . ' mins';
        }

        $hours = \intdiv($minutes, 60);
        $mins = $minutes % 60;

        if ($mins == 0) {
            return $hours . ' hr' . ($hours > 1 ? 's' : '');
        }

        return $hours . ' hr' . ($hours > 1 ? 's' : '') . ' ' . $mins . ' mins';
    }


    public function getNotifications(Request $request)
    {
        $limit = ($request->limit) ?? 10;
        $offset = ($request->offset) ?? 0;
        $sort = ($request->sort) ?? 'id';
        $order = ($request->sort) ?? 'DESC';
        $where = '';
        if (isset($request->search) && $request->search != '') {
            $search = $request->search;
            $where = " `id` like '%" . $search . "%' OR `title` like '%" . $search . "%' OR `message` like '%" . $search . "%' OR `image` like '%" . $search . "%' OR `date_sent` like '%" . $search . "%' ";
        }

        $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : '';
        if (isset($user_id) && $user_id != '') {
            // Get notifications for this specific customer OR broadcast notifications (no user_id)
            $sql = Notification::where(function ($query) use ($user_id) {
                $query->where(function ($q) use ($user_id) {
                    $q->where('user_id', $user_id)
                        ->where('role_name', 'customer');
                })->orWhereNull('user_id');
            });
        } else {
            // Only get broadcast notifications (no user_id)
            $sql = Notification::whereNull('user_id');
        }
        if ($where != "") {
            $sql = $sql->whereRaw($where);
        }
        $total = $sql->count();
        $notifications = $sql->orderBy($sort, $order)->skip($offset)->take($limit)->get();

        if (!empty($notifications)) {
            $rows = array();
            foreach ($notifications as $row) {
                $tempRow = array();
                $tempRow['id'] = $row->id;
                $tempRow['title'] = $row->title;
                $tempRow['message'] = $row->message;
                $tempRow['type'] = $row->type;
                $tempRow['type_id'] = $row->type_id;
                $tempRow['image_url'] = CommonHelper::getImage($row->image);
                $tempRow['link_url'] = $row->type_link;
                $tempRow['date_sent'] = $row->date_sent;
                $rows[] = $tempRow;
            }
            return CommonHelper::responseWithData($rows, $total);
        } else {
            return CommonHelper::responseError(__('no_notification_found'));
        }

    }

    public function getBrands(Request $request)
    {
        $offset = $request->get('offset', 0);
        $limit = $request->get('limit', 10);
        $latitude = $request->get('latitude');
        $longitude = $request->get('longitude');

        // Validate if latitude & longitude are provided
        if (!$latitude || !$longitude) {
            return CommonHelper::responseError(__('Latitude and longitude are required.'));
        }

        // Get seller IDs based on location
        $seller_ids = CommonHelper::getSellerIds($latitude, $longitude);

        // If no sellers found in the area, return error
        if (empty($seller_ids)) {
            return CommonHelper::responseError(__('No sellers found in this area.'));
        }

        // Fetch brands with products sold by sellers in the area
        $brands = Brand::where('status', 1)
            ->whereHas('products', function ($query) use ($seller_ids) {
                $query->whereIn('products.seller_id', $seller_ids)
                    ->where('products.status', 1)
                    ->where('products.is_approved', 1)
                    ->whereExists(function ($categoryQuery) {
                        $categoryQuery->select(DB::raw(1))
                            ->from('categories')
                            ->whereColumn('categories.id', 'products.category_id')
                            ->where('categories.status', 1);
                    });
            })
            ->orderBy('id', 'ASC');

        // Get total count before applying pagination
        $total = $brands->count();

        // Apply pagination
        $brands = $brands->offset($offset)->limit($limit)->get();
        $brands = $brands->makeHidden(['created_at', 'updated_at', 'image', 'status']);

        if ($brands->isNotEmpty()) {
            return CommonHelper::responseWithData($brands, $total);
        } else {
            return CommonHelper::responseError(__('No brands found in this area.'));
        }
    }
    public function getCountries(Request $request)
    {
        $offset = $request->get('offset', 0);
        $limit = $request->get('limit', 10);
        $latitude = $request->get('latitude');
        $longitude = $request->get('longitude');

        $seller_ids = CommonHelper::getSellerIds($latitude, $longitude);

        // If no sellers found in the area, return error
        if (empty($seller_ids)) {
            return CommonHelper::responseError(__('No sellers found in this area.'));
        }

        $countries = Country::orderBy('id', 'ASC')
            ->where('status', 1)
            ->whereExists(function ($query) use ($seller_ids) {
                $query->select(DB::raw(1))
                    ->from('products')
                    ->whereColumn('products.made_in', 'countries.id')
                    ->whereIn('products.seller_id', $seller_ids)  // Check seller_id
                    ->where('products.status', 1)                // Product status = 1
                    ->where('products.is_approved', 1)           // Product is approved
                    ->whereExists(function ($subQuery) {
                        $subQuery->select(DB::raw(1))
                            ->from('categories')
                            ->whereColumn('categories.id', 'products.category_id')
                            ->where('categories.status', 1);   // Category status = 1
                    });
            });

        $total = $countries->count();
        $countries = $countries->offset($offset)->limit($limit)->get();
        $countries = $countries->makeHidden(['created_at', 'updated_at', 'status']);
        if (!empty($countries)) {
            return CommonHelper::responseWithData($countries, $total);
        } else {
            return CommonHelper::responseError(__('no_countries_found'));
        }
    }

    public function getOrderStatusLists()
    {
        $statuses = OrderStatusList::orderBy('id', 'ASC')->get();
        $total = $statuses->count();
        if (!empty($statuses)) {
            return CommonHelper::responseWithData($statuses, $total);
        } else {
            return CommonHelper::responseError('Status not found.');
        }
    }

    public function getMailSetting()
    {
        $user_id = auth()->user()->id;
        $user_type = 0;
        $setting = CommonHelper::getMailSetting($user_type, $user_id);
        $setting = $setting->makeHidden(['user_id', 'user_type', 'created_at', 'updated_at']);
        return CommonHelper::responseWithData($setting);
    }
    public function saveMailSetting(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'status_ids' => 'required',
            'mail_statuses' => 'required',
            'mobile_statuses' => 'required'
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $user_id = auth()->user()->id;
        $user_type = 0;
        $status_ids = is_array($request->status_ids) ? $request->status_ids : explode(",", $request->status_ids);
        $mail_statuses = is_array($request->mail_statuses) ? $request->mail_statuses : explode(",", $request->mail_statuses);
        $mobile_statuses = is_array($request->mobile_statuses) ? $request->mobile_statuses : explode(",", $request->mobile_statuses);

        $order_status_ids = OrderStatusList::get()->pluck('id')->toArray();
        if (array_intersect($status_ids, $order_status_ids) != $status_ids) {
            return CommonHelper::responseError("Status ids is not belongs to order status list id.");
        }

        CommonHelper::saveMailSetting($user_id, $user_type, $status_ids, $mail_statuses, $mobile_statuses, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
        return CommonHelper::responseSuccess("Mail Settings Saved Successfully!");
    }

    public function stripeTest()
    {

        $stripe_secret_key = config('services.stripe.secret');
        try {
            $stripe = new \Stripe\StripeClient(
                $stripe_secret_key
            );

            $tran = $stripe->paymentIntents->retrieve(
                "pi_3MMPKcSEKxefYE6M00PuXMt4",
                []
            );
        } catch (\Exception $e) {
            Log::error("Installer -> Database Error : ", [$e]);
            return CommonHelper::responseError($e->getMessage());
        }


    }
    public function deleteSellerAccount(Request $request)
    {
        try {
            $seller_admin_id = auth()->user()->id;
            $seller = Seller::where('admin_id', $seller_admin_id)->first();

            if (!$seller) {
                return CommonHelper::responseError("Seller account not found!");
            }

            if ($seller->email == 'seller@gmail.com' && isDemoMode()) {
                return CommonHelper::responseError("This function is not available in demo mode!");
            }

            if ($seller->deleted_at) {
                return CommonHelper::responseError("Account is already deleted!");
            }

            // Soft delete the seller immediately
            $seller->delete_reason = $request->reason ?? 'No reason provided';
            $seller->delete_requested_at = now();
            $seller->deleted_at = now();
            $seller->status = Seller::$statusRemoved;
            $seller->save();

            // Notify admin about the deletion
            \App\Services\AdminNotificationService::notifySellerDeleteRequest(
                $seller->id,
                $seller->store_name ?? $seller->name ?? 'Seller #' . $seller->id
            );

            return CommonHelper::responseSuccess("Your seller account has been deleted successfully.");
        } catch (\Exception $e) {
            Log::error('deleteSellerAccount: ' . $e->getMessage());
            return CommonHelper::responseError($e->getMessage());
        }
    }

    public function deleteDeliveryBoyAccount(Request $request)
    {
        try {
            $delivery_boy_admin_id = auth()->user()->id;
            $delivery_boy = DeliveryBoy::where('admin_id', $delivery_boy_admin_id)->first();

            if (!$delivery_boy) {
                return CommonHelper::responseError("Delivery boy account not found!");
            }

            if ($delivery_boy->email == 'delivery@gmail.com' && isDemoMode()) {
                return CommonHelper::responseError("This function is not available in demo mode!");
            }

            // Soft delete the delivery boy account
            $delivery_boy->delete_reason = $request->reason ?? 'No reason provided';
            $delivery_boy->delete_requested_at = now();
            $delivery_boy->deleted_at = now();
            $delivery_boy->status = DeliveryBoy::$statusRemoved;
            $delivery_boy->save();

            // Notify admin about driver account deletion
            \App\Services\AdminNotificationService::notifyDriverDeleteRequest(
                $delivery_boy->id,
                $delivery_boy->name ?? 'Driver #' . $delivery_boy->id
            );

            return CommonHelper::responseSuccess("Your delivery boy account has been deleted successfully.");
        } catch (\Exception $e) {
            Log::error('deleteDeliveryBoyAccount: ' . $e->getMessage());
            return CommonHelper::responseError($e->getMessage());
        }
    }

    public function getSeoThings(Request $request)
    {
        $slug = $request->input('slug');

        $category = Category::select('meta_title', 'meta_keywords', 'meta_description', 'schema_markup', 'image')
            ->where('slug', $slug)
            ->first();

        if (!$category) {
            return CommonHelper::responseError("Category not available");
        }
        $seoThings = [];
        $seoThings['meta_title'] = $category->meta_title;
        $seoThings['meta_keywords'] = $category->meta_keywords;
        $seoThings['meta_description'] = $category->meta_description;
        $seoThings['schema_markup'] = $category->schema_markup;
        $seoThings['og_image'] = $category->image_url;
        $faviconVal = Setting::get_value('favicon');
        $seoThings['favicon'] = $faviconVal ? (str_starts_with($faviconVal, 'http') ? $faviconVal : asset('storage/' . $faviconVal)) : '';

        return CommonHelper::responseWithData($seoThings);
    }

    public function home_data()
    {

        // $stores = Store::with('categoryGroups','categoryGroups.subCategoryGroups','categoryGroups.subCategoryGroups.categories')->get();
        $stores = Store::with('categoryGroups', 'categoryGroups.subCategoryGroups')
            ->where('is_active', true)
            ->get();

        return CommonHelper::responseWithData($stores);

    }

    public function stores()
    {
        $stores = Store::where('is_active', true)
            ->where(function ($q) {
                $q->where('is_meat', false)
                  ->orWhere('id', 14);
            })
            ->get();
        return CommonHelper::responseWithData($stores);
    }

    // public function category_subcategory_store_data($id = null){

    //     if ($id) {
    //         $stores = Store::with('categoryGroups', 'categoryGroups.subCategoryGroups')
    //                     ->where('id', $id)
    //                     ->get();
    //     } else {
    //         $stores = Store::with('categoryGroups', 'categoryGroups.subCategoryGroups')->get();
    //     }
    //     // $stores = Store::with('categoryGroups','categoryGroups.subCategoryGroups')->where('id',$id)->get();

    //     $stores->transform(function ($store) {
    //         if ($store->managed_by_admin == 0) {

    //             $sellerIds = DB::table('sellers')
    //                 ->where('store_id', $store->id)
    //                 ->pluck('id');

    //             $categories = Category::whereIn('seller_id', $sellerIds)->get();
    //             $sellers = Seller::whereIn('id', $sellerIds)->get();

    //             $store->setRelation('categoryGroups', collect([]));
    //             $store->setRelation('categories', $categories);
    //             $store->setRelation('sellers', $sellers);

    //         }
    //         return $store;
    //     });

    //     return CommonHelper::responseWithData($stores);

    // }




    // OLD VERSION - Commented on 2026-03-26
    // public function category_subcategory_store_data(Request $request, $id = null)
    // {
    //     $userLat = $request->lat;
    //     $userLon = $request->lon;

    //     if (!$userLat || !$userLon) {
    //         return CommonHelper::responseError("lat and lon are required");
    //     }

    //     // Get authenticated user's is_children_allowed setting (default to 0 if not authenticated)
    //     $userIsChildrenAllowed = 0;
    //     $authenticatedUser = $request->user('api-customers');

    //     if ($authenticatedUser) {
    //         $userIsChildrenAllowed = $authenticatedUser->is_children_allowed ?? 0;
    //     }

    //     // Pagination parameters for sellers
    //     $sellerPerPage = $request->input('seller_per_page', 10);
    //     $sellerPage = $request->input('seller_page', 1);

    //     // Sorting parameter for sellers
    //     $sortBy = $request->input('sort_by', SellerFilterService::SORT_DISTANCE);

    //     // Food type filter parameter (veg/non_veg/all)
    //     $foodType = $request->input('food_type', SellerFilterService::FOOD_TYPE_ALL);

    //     // Category filter parameter
    //     $categoryId = $request->input('category_id', null);

    //     // City zone detection (done once, used for all stores)
    //     $zoneFilterEnabled = CityZoneService::isZoneFilterEnabled();
    //     $customerCity = null;
    //     if ($zoneFilterEnabled) {
    //         $customerCity = CityZoneService::detectCity((float) $userLat, (float) $userLon);
    //         if (!$customerCity) {
    //             // Customer outside all zones - no delivery coverage
    //             return CommonHelper::responseErrorWithData(
    //                 'We are not available in your area',
    //                 ['available_zones' => CityZoneService::getAvailableZones()]
    //             );
    //         }
    //     }

    //     if ($id) {
    //         $stores = Store::with([
    //             'categoryGroups',
    //             'categoryGroups.subCategoryGroups'
    //         ])
    //             ->where('id', $id)
    //             ->where('is_active', true)
    //             ->get();

    //         // If the requested store is a meat store, merge category groups from all other is_meat=1 stores
    //         if ($stores->isNotEmpty() && $stores->first()->is_meat) {
    //             $otherMeatStores = Store::with([
    //                 'categoryGroups',
    //                 'categoryGroups.subCategoryGroups'
    //             ])
    //                 ->where('is_meat', true)
    //                 ->where('id', '!=', $id)
    //                 ->where('is_active', true)
    //                 ->get();

    //             $mergedCategoryGroups = $stores->first()->categoryGroups;
    //             foreach ($otherMeatStores as $meatStore) {
    //                 $mergedCategoryGroups = $mergedCategoryGroups->merge($meatStore->categoryGroups);
    //             }
    //             $mergedCategoryGroups = $mergedCategoryGroups
    //                 ->sortByDesc(fn($group) => $group->subCategoryGroups->count())
    //                 ->values();
    //             $stores->first()->setRelation('categoryGroups', $mergedCategoryGroups);
    //         }
    //     } else {
    //         $stores = Store::with([
    //             'categoryGroups',
    //             'categoryGroups.subCategoryGroups'
    //         ])
    //             ->where('is_active', true)
    //             ->get();
    //     }

    //     $stores->transform(function ($store) use ($userLat, $userLon, $sellerPerPage, $sellerPage, $userIsChildrenAllowed, $id, $sortBy, $foodType, $categoryId, $authenticatedUser, $customerCity, $zoneFilterEnabled) {

    //         // Get authenticated user ID for bookmark checks
    //         $user_id = $authenticatedUser ? $authenticatedUser->id : null;

    //         // Check if store is managed by admin
    //         $isManagedByAdmin = $store->managed_by_admin == 1;

    //         // Get sliders for this specific store:
    //         // 1. type=store banners where type_id matches the store
    //         // 2. category/product banners that were assigned to this store via store_id
    //         $sliders = Slider::where(function ($q) use ($store) {
    //                 $q->where('type', 'store')
    //                   ->where('type_id', $store->id);
    //             })
    //             ->orWhere('store_id', $store->id)
    //             ->get()
    //             ->map(function ($slider) {
    //                 if ($slider->type === 'category') {
    //                     $slider->is_category = 1;
    //                     $slider->sub_category_name_field = $slider->sub_category_group_id
    //                         ? (SubCategoryGroup::find($slider->sub_category_group_id)->name ?? null)
    //                         : null;
    //                 } else {
    //                     $slider->is_category = 0;
    //                     $slider->sub_category_name_field = null;
    //                 }

    //                 if ($slider->type === 'store') {
    //                     $sliderStore = Store::find($slider->type_id);
    //                     if ($sliderStore && $sliderStore->is_meat == 1) {
    //                         $slider->type_id = "14";
    //                     }
    //                 }

    //                 return $slider;
    //             });

    //         $store->sliders = $sliders;

    //         // Check if store is sweet house (non-admin, non-super mart)
    //         $isSweetHouse = (!$isManagedByAdmin && !$store->is_super_mart);

    //         if (!$isManagedByAdmin) {
    //             // For non-admin stores, get all sellers including closed ones
    //             // We'll add a status field to indicate if shop is currently open or closed
    //             $sellersQuery = Seller::where('store_id', $store->id)
    //                 ->where('status', 1); // Only filter by active status, show both online and offline

    //             // Filter sellers by customer's city zone
    //             if ($zoneFilterEnabled && $customerCity) {
    //                 $allSellerIds = (clone $sellersQuery)->pluck('id')->toArray();
    //                 $filteredIds = CityZoneService::filterSellersByZone($allSellerIds, $customerCity, (float) $userLat, (float) $userLon);

    //                 if (!empty($filteredIds)) {
    //                     $sellersQuery->whereIn('id', $filteredIds);
    //                 } else {
    //                     // No sellers found - set to impossible condition
    //                     $sellersQuery->whereRaw('1 = 0');
    //                 }
    //             }

    //             // Apply category filter if category_id is provided
    //             if ($categoryId) {
    //                 // Get seller IDs that have the selected category
    //                 $sellerIdsWithCategory = Category::where('id', $categoryId)
    //                     ->where('status', 1)
    //                     ->pluck('seller_id')
    //                     ->toArray();

    //                 $sellersQuery->whereIn('id', $sellerIdsWithCategory);
    //             }

    //             // Only load categories if $id is provided AND store is sweet house
    //             if ($id && $isSweetHouse) {
    //                 // Get all seller IDs for this store (include all sellers regardless of shop_status)
    //                 $allSellerIds = Seller::where('store_id', $store->id)
    //                     ->where('status', 1) // Only filter by active status
    //                     ->pluck('id');

    //                 // Get categories directly from categories table for these sellers
    //                 $categories = Category::select('id', 'name', 'seller_id', 'image')
    //                     ->whereIn('seller_id', $allSellerIds)
    //                     ->where('status', 1)
    //                     ->get()
    //                     ->map(function ($category) {
    //                         $category->image_url = $category->image_url;
    //                         return $category;
    //                     });

    //                 $store->categories = $categories;

    //                 // Add selected_category_id to response for reference
    //                 $store->selected_category_id = $categoryId;
    //             }

    //             // Only load sellers and pagination data if $id is provided
    //             if ($id) {
    //                 // Paginate sellers
    //                 $sellersPaginated = $sellersQuery->paginate($sellerPerPage, ['*'], 'seller_page', $sellerPage);

    //                 $sellers = collect($sellersPaginated->items())->map(function ($seller) use ($userLat, $userLon, $user_id) {

    //                     // Determine shop open/closed status based on shop_status only
    //                     // If seller is online (shop_status = 1), they are accepting orders regardless of scheduled times
    //                     $isOpen = ($seller->shop_status == 1);
    //                     $seller->is_shop_open = $isOpen;
    //                     $seller->shop_status_message = $isOpen ? 'Shop is open' : 'Shop is currently offline';

    //                     // Get dynamic rating from RatingService
    //                     $ratingData = RatingService::getSellerRating($seller->id, $seller->store_id);
    //                     $seller->rating = $ratingData['rating'];
    //                     $seller->rating_count = $ratingData['rating_count'];

    //                     // Get seller's store details
    //                     $sellerStore = Store::find($seller->store_id);
    //                     if ($sellerStore) {
    //                         $seller->store_details = [
    //                             'id' => $sellerStore->id,
    //                             'name' => $sellerStore->name,
    //                             'icon' => $sellerStore->icon_url,
    //                             'color' => $sellerStore->color,
    //                             'image' => $sellerStore->image_url,
    //                             'description' => $sellerStore->description,
    //                             'managed_by_admin' => $sellerStore->managed_by_admin,
    //                             'is_super_mart' => $sellerStore->is_super_mart,
    //                             'is_sweet_house' => (!$sellerStore->managed_by_admin && !$sellerStore->is_super_mart),
    //                         ];
    //                     }

    //                     $seller->is_bookmarked = $user_id ? $this->checkSellerBookmarked($user_id, $seller->id) : 0;

    //                     $latLong = $seller->lat_long;
    //                     if (!$latLong) {
    //                         $seller->distance_km = null;
    //                         $seller->travel_time_min = null;
    //                         return $seller;
    //                     }

    //                     list($sLat, $sLon) = explode(",", $latLong);

    //                     $distanceKm = StoreDistanceService::haversine(
    //                         $userLat,
    //                         $userLon,
    //                         $sLat,
    //                         $sLon
    //                     );

    //                     $travelMin = StoreDistanceService::estimateTravelTimeMinutes($distanceKm);

    //                     $google = StoreDistanceService::googleMapsDistance(
    //                         $userLat,
    //                         $userLon,
    //                         $sLat,
    //                         $sLon
    //                     );

    //                     $seller->distance_km = StoreDistanceService::formatDistance($distanceKm);
    //                     $seller->travel_time_min = StoreDistanceService::formatTime($travelMin);

    //                     if ($google) {
    //                         $seller->distance_km = StoreDistanceService::formatDistance($google['distance_km']);
    //                         $seller->travel_time_min = StoreDistanceService::formatTime($google['time_min']);
    //                     }

    //                     // Add is_bookmarked status
    //                     $seller->is_bookmarked = $user_id ? $this->checkSellerBookmarked($user_id, $seller->id) : 0;

    //                     return $seller;
    //                 });

    //                 // Attach food_type to each seller
    //                 $sellers = SellerFilterService::attachFoodTypeToSellers($sellers);

    //                 // Apply food type filter using SellerFilterService
    //                 $sellers = SellerFilterService::applyFoodTypeFilter($sellers, $foodType);

    //                 // Apply sorting using SellerFilterService
    //                 $sellers = SellerFilterService::applySorting($sellers, $sortBy);

    //                 // Convert to array to ensure all custom fields are included in response
    //                 $sellersArray = $sellers->map(function ($seller) {
    //                     $sellerArray = $seller->toArray();
    //                     // Explicitly include custom fields to ensure they're in the response
    //                     $sellerArray['is_bookmarked'] = $seller->is_bookmarked ?? 0;
    //                     $sellerArray['is_shop_open'] = $seller->is_shop_open ?? true;
    //                     $sellerArray['shop_status_message'] = $seller->shop_status_message ?? 'Shop is open';
    //                     return $sellerArray;
    //                 })->all();

    //                 // Create sellers pagination data
    //                 $sellersPaginationData = [
    //                     'total' => $sellersPaginated->total(),
    //                     'per_page' => $sellersPaginated->perPage(),
    //                     'current_page' => $sellersPaginated->currentPage(),
    //                     'last_page' => $sellersPaginated->lastPage(),
    //                     'sort_by' => $sortBy,
    //                     'sort_options' => SellerFilterService::getSortOptions(),
    //                     'food_type' => $foodType,
    //                     'food_type_options' => SellerFilterService::getFoodTypeOptions(),
    //                     'data' => $sellersArray
    //                 ];

    //                 $store->sellers_pagination = $sellersPaginationData;

    //                 // Add top_rated_sellers - sorted by rating in descending order (top 10)
    //                 $topRatedSellersArray = array_map(function ($seller) {
    //                     return is_array($seller) ? $seller : $seller->toArray() + [
    //                         'is_bookmarked' => $seller->is_bookmarked ?? 0,
    //                         'is_shop_open' => $seller->is_shop_open ?? true,
    //                         'shop_status_message' => $seller->shop_status_message ?? 'Shop is open'
    //                     ];
    //                 }, $sellers->sortByDesc('rating')->take(10)->values()->all());
    //                 $store->top_rated_sellers = $topRatedSellersArray;
    //             }
    //         }

    //         return $store;
    //     });

    //     return CommonHelper::responseWithData($stores);
    // }

    /**
     * NEW VERSION - Modified on 2026-03-26
     * For meat stores (is_meat=1): Groups subcategories by store name instead of category groups
     */
    public function category_subcategory_store_data(Request $request, $id = null)
    {
        $userLat = $request->lat;
        $userLon = $request->lon;

        if (!$userLat || !$userLon) {
            return CommonHelper::responseError("lat and lon are required");
        }

        // Get authenticated user's is_children_allowed setting (default to 0 if not authenticated)
        $userIsChildrenAllowed = 0;
        $authenticatedUser = $request->user('api-customers');

        if ($authenticatedUser) {
            $userIsChildrenAllowed = $authenticatedUser->is_children_allowed ?? 0;
        }

        // Pagination parameters for sellers
        $sellerPerPage = $request->input('seller_per_page', 10);
        $sellerPage = $request->input('seller_page', 1);

        // Sorting parameter for sellers
        $sortBy = $request->input('sort_by', SellerFilterService::SORT_DISTANCE);

        // Food type filter parameter (veg/non_veg/all)
        $foodType = $request->input('food_type', SellerFilterService::FOOD_TYPE_ALL);

        // Category filter parameter
        $categoryId = $request->input('category_id', null);

        // City zone detection (done once, used for all stores)
        $zoneFilterEnabled = CityZoneService::isZoneFilterEnabled();
        $customerCity = null;
        if ($zoneFilterEnabled) {
            $customerCity = CityZoneService::detectCity((float) $userLat, (float) $userLon);
            if (!$customerCity) {
                // Customer outside all zones - no delivery coverage
                return CommonHelper::responseErrorWithData(
                    'We are not available in your area',
                    ['available_zones' => CityZoneService::getAvailableZones()]
                );
            }
        }

        if ($id) {
            $stores = Store::with([
                'categoryGroups',
                'categoryGroups.subCategoryGroups'
            ])
                ->where('id', $id)
                ->where('is_active', true)
                ->get();

            // NEW LOGIC: If the requested store is a meat store, group by store names instead of category groups
            if ($stores->isNotEmpty() && $stores->first()->is_meat) {
                // Get ALL meat stores (including current store)
                $allMeatStores = Store::with([
                    'categoryGroups.subCategoryGroups'
                ])
                    ->where('is_meat', true)
                    ->where('is_active', true)
                    ->get();

                // Build new structure: each store becomes a "categoryGroup"
                $storeBasedGroups = collect();

                foreach ($allMeatStores as $meatStore) {
                    // Collect all SubCategoryGroup objects from this store
                    $allSubCategoryGroups = collect();

                    foreach ($meatStore->categoryGroups as $categoryGroup) {
                        foreach ($categoryGroup->subCategoryGroups as $subCategoryGroup) {
                            $allSubCategoryGroups->push($subCategoryGroup);
                        }
                    }

                    // Create a "fake" categoryGroup object with store info
                    // Using the same field names as non-meat stores for consistency
                    $storeBasedGroup = new \stdClass();
                    $storeBasedGroup->id = $meatStore->id;
                    $storeBasedGroup->seller_id = null;
                    $storeBasedGroup->name = $meatStore->name;
                    $storeBasedGroup->icon = $meatStore->icon;
                    $storeBasedGroup->image = $meatStore->image;
                    $storeBasedGroup->color = $meatStore->color;
                    $storeBasedGroup->category_ids = null;
                    $storeBasedGroup->status = 1;
                    $storeBasedGroup->row_order = 0;
                    $storeBasedGroup->is_super_mart = 0;
                    $storeBasedGroup->created_at = $meatStore->created_at;
                    $storeBasedGroup->updated_at = $meatStore->updated_at;
                    $storeBasedGroup->image_url = $meatStore->image_url;
                    // Add SubCategoryGroup objects from this store
                    $storeBasedGroup->sub_category_groups = $allSubCategoryGroups;

                    $storeBasedGroups->push($storeBasedGroup);
                }

                // Sort by subcategory count descending (matching original logic)
                $storeBasedGroups = $storeBasedGroups
                    ->sortByDesc(fn($group) => $group->sub_category_groups->count())
                    ->values();

                // Add "Pre Order" category group for pre-order products from meat stores
                $meatStoreIds = $allMeatStores->pluck('id')->toArray();

                $preOrderSubCategoryGroupIds = Product::where('is_pre_order_item', 1)
                    ->where('status', 1)
                    ->where('is_approved', 1)
                    ->whereIn('store_id', $meatStoreIds) // Only from meat stores
                    ->whereNotNull('sub_category_group_id')
                    ->distinct()
                    ->pluck('sub_category_group_id')
                    ->filter()
                    ->toArray();

                if (!empty($preOrderSubCategoryGroupIds)) {
                    $preOrderSubCategoryGroups = CategorySubGroup::whereIn('id', $preOrderSubCategoryGroupIds)
                        ->get();

                    if ($preOrderSubCategoryGroups->isNotEmpty()) {
                        // Create "Pre Order" category group
                        $preOrderGroup = new \stdClass();
                        $preOrderGroup->id = 0; // Special ID for pre-order
                        $preOrderGroup->seller_id = null;
                        $preOrderGroup->name = "Pre Order";
                        $preOrderGroup->icon = null;
                        $preOrderGroup->image = null;
                        $preOrderGroup->color = "#ff0000";
                        $preOrderGroup->category_ids = null;
                        $preOrderGroup->status = 1;
                        $preOrderGroup->row_order = -1; // Put it first
                        $preOrderGroup->is_super_mart = 0;
                        $preOrderGroup->created_at = now();
                        $preOrderGroup->updated_at = now();
                        $preOrderGroup->image_url = null;
                        $preOrderGroup->sub_category_groups = $preOrderSubCategoryGroups;

                        // Add to the end of the collection
                        $storeBasedGroups->push($preOrderGroup);
                    }
                }

                // Replace categoryGroups with store-based groups
                $stores->first()->setRelation('categoryGroups', $storeBasedGroups);
            }
        } else {
            $stores = Store::with([
                'categoryGroups',
                'categoryGroups.subCategoryGroups'
            ])
                ->where('is_active', true)
                ->get();
        }

        $stores->transform(function ($store) use ($userLat, $userLon, $sellerPerPage, $sellerPage, $userIsChildrenAllowed, $id, $sortBy, $foodType, $categoryId, $authenticatedUser, $customerCity, $zoneFilterEnabled) {

            // Get authenticated user ID for bookmark checks
            $user_id = $authenticatedUser ? $authenticatedUser->id : null;

            // Check if store is managed by admin
            $isManagedByAdmin = $store->managed_by_admin == 1;

            // Get sliders for this specific store:
            // 1. type=store banners where type_id matches the store
            // 2. category/product banners that were assigned to this store via store_id
            $sliders = Slider::where(function ($q) use ($store) {
                    $q->where('type', 'store')
                      ->where('type_id', $store->id);
                })
                ->orWhere('store_id', $store->id)
                ->get()
                ->map(function ($slider) {
                    if ($slider->type === 'category') {
                        $slider->is_category = 1;
                        $slider->sub_category_name_field = $slider->sub_category_group_id
                            ? (SubCategoryGroup::find($slider->sub_category_group_id)->name ?? null)
                            : null;
                    } else {
                        $slider->is_category = 0;
                        $slider->sub_category_name_field = null;
                    }

                    if ($slider->type === 'store') {
                        $sliderStore = Store::find($slider->type_id);
                        if ($sliderStore && $sliderStore->is_meat == 1) {
                            $slider->type_id = "14";
                        }
                    }

                    return $slider;
                });

            $store->sliders = $sliders;

            // Check if store is sweet house (non-admin, non-super mart)
            $isSweetHouse = (!$isManagedByAdmin && !$store->is_super_mart);

            if (!$isManagedByAdmin) {
                // For non-admin stores, get all sellers including closed ones
                // We'll add a status field to indicate if shop is currently open or closed
                $sellersQuery = Seller::where('store_id', $store->id)
                    ->where('status', 1); // Only filter by active status, show both online and offline

                // Filter sellers by customer's city zone
                if ($zoneFilterEnabled && $customerCity) {
                    $allSellerIds = (clone $sellersQuery)->pluck('id')->toArray();
                    $filteredIds = CityZoneService::filterSellersByZone($allSellerIds, $customerCity, (float) $userLat, (float) $userLon);

                    if (!empty($filteredIds)) {
                        $sellersQuery->whereIn('id', $filteredIds);
                    } else {
                        // No sellers found - set to impossible condition
                        $sellersQuery->whereRaw('1 = 0');
                    }
                }

                // Apply category filter if category_id is provided
                // Only include sellers that actually have at least one approved + active product
                // in this category. Sellers with empty categories should not appear, otherwise
                // the user lands on a restaurant with no menu items.
                if ($categoryId) {
                    $sellerIdsWithCategory = Product::where('category_id', $categoryId)
                        ->where('is_approved', 1)
                        ->where('status', 1)
                        ->distinct()
                        ->pluck('seller_id')
                        ->toArray();

                    $sellersQuery->whereIn('id', $sellerIdsWithCategory);
                }

                // Only load categories if $id is provided AND store is sweet house
                if ($id && $isSweetHouse) {
                    // Get all seller IDs for this store (include all sellers regardless of shop_status)
                    $allSellerIds = Seller::where('store_id', $store->id)
                        ->where('status', 1) // Only filter by active status
                        ->pluck('id');

                    // Get categories directly from categories table for these sellers
                    $categories = Category::select('id', 'name', 'seller_id', 'image')
                        ->whereIn('seller_id', $allSellerIds)
                        ->where('status', 1)
                        ->get()
                        ->map(function ($category) {
                            $category->image_url = $category->image_url;
                            return $category;
                        });

                    $store->categories = $categories;

                    // Add selected_category_id to response for reference
                    $store->selected_category_id = $categoryId;
                }

                // Only load sellers and pagination data if $id is provided
                if ($id) {
                    // Paginate sellers
                    $sellersPaginated = $sellersQuery->paginate($sellerPerPage, ['*'], 'seller_page', $sellerPage);

                    $sellers = collect($sellersPaginated->items())->map(function ($seller) use ($userLat, $userLon, $user_id) {

                        // Determine shop open/closed status based on shop_status only
                        // If seller is online (shop_status = 1), they are accepting orders regardless of scheduled times
                        $isOpen = ($seller->shop_status == 1);
                        $seller->is_shop_open = $isOpen;
                        $seller->shop_status_message = $isOpen ? 'Shop is open' : 'Shop is currently offline';

                        // Get dynamic rating from RatingService
                        $ratingData = RatingService::getSellerRating($seller->id, $seller->store_id);
                        $seller->rating = $ratingData['rating'];
                        $seller->rating_count = $ratingData['rating_count'];

                        // Get seller's store details
                        $sellerStore = Store::find($seller->store_id);
                        if ($sellerStore) {
                            $seller->store_details = [
                                'id' => $sellerStore->id,
                                'name' => $sellerStore->name,
                                'icon' => $sellerStore->icon_url,
                                'color' => $sellerStore->color,
                                'image' => $sellerStore->image_url,
                                'description' => $sellerStore->description,
                                'managed_by_admin' => $sellerStore->managed_by_admin,
                                'is_super_mart' => $sellerStore->is_super_mart,
                                'is_sweet_house' => (!$sellerStore->managed_by_admin && !$sellerStore->is_super_mart),
                            ];
                        }

                        $seller->is_bookmarked = $user_id ? $this->checkSellerBookmarked($user_id, $seller->id) : 0;

                        $latLong = $seller->lat_long;
                        if (!$latLong) {
                            $seller->distance_km = null;
                            $seller->travel_time_min = null;
                            return $seller;
                        }

                        list($sLat, $sLon) = explode(",", $latLong);

                        $distanceKm = StoreDistanceService::haversine(
                            $userLat,
                            $userLon,
                            $sLat,
                            $sLon
                        );

                        $travelMin = StoreDistanceService::estimateTravelTimeMinutes($distanceKm);

                        $google = StoreDistanceService::googleMapsDistance(
                            $userLat,
                            $userLon,
                            $sLat,
                            $sLon
                        );

                        $seller->distance_km = StoreDistanceService::formatDistance($distanceKm);
                        $seller->travel_time_min = StoreDistanceService::formatTime($travelMin);

                        if ($google) {
                            $seller->distance_km = StoreDistanceService::formatDistance($google['distance_km']);
                            $seller->travel_time_min = StoreDistanceService::formatTime($google['time_min']);
                        }

                        // Add is_bookmarked status
                        $seller->is_bookmarked = $user_id ? $this->checkSellerBookmarked($user_id, $seller->id) : 0;

                        return $seller;
                    });

                    // Attach food_type to each seller
                    $sellers = SellerFilterService::attachFoodTypeToSellers($sellers);

                    // Apply food type filter using SellerFilterService
                    $sellers = SellerFilterService::applyFoodTypeFilter($sellers, $foodType);

                    // Apply sorting using SellerFilterService
                    $sellers = SellerFilterService::applySorting($sellers, $sortBy);

                    // Convert to array to ensure all custom fields are included in response
                    $sellersArray = $sellers->map(function ($seller) {
                        $sellerArray = $seller->toArray();
                        // Explicitly include custom fields to ensure they're in the response
                        $sellerArray['is_bookmarked'] = $seller->is_bookmarked ?? 0;
                        $sellerArray['is_shop_open'] = $seller->is_shop_open ?? true;
                        $sellerArray['shop_status_message'] = $seller->shop_status_message ?? 'Shop is open';
                        return $sellerArray;
                    })->all();

                    // Create sellers pagination data
                    $sellersPaginationData = [
                        'total' => $sellersPaginated->total(),
                        'per_page' => $sellersPaginated->perPage(),
                        'current_page' => $sellersPaginated->currentPage(),
                        'last_page' => $sellersPaginated->lastPage(),
                        'sort_by' => $sortBy,
                        'sort_options' => SellerFilterService::getSortOptions(),
                        'food_type' => $foodType,
                        'food_type_options' => SellerFilterService::getFoodTypeOptions(),
                        'data' => $sellersArray
                    ];

                    $store->sellers_pagination = $sellersPaginationData;

                    // Add top_rated_sellers - sorted by rating in descending order (top 10)
                    $topRatedSellersArray = array_map(function ($seller) {
                        return is_array($seller) ? $seller : $seller->toArray() + [
                            'is_bookmarked' => $seller->is_bookmarked ?? 0,
                            'is_shop_open' => $seller->is_shop_open ?? true,
                            'shop_status_message' => $seller->shop_status_message ?? 'Shop is open'
                        ];
                    }, $sellers->sortByDesc('rating')->take(10)->values()->all());
                    $store->top_rated_sellers = $topRatedSellersArray;
                }
            }

            return $store;
        });

        // Resolve each tile's `subcategory_ids` CSV into the real category
        // rows so the home screen can label a tile with what actually sits
        // inside it ("Oils,Ghee & Massala" -> Massala, Oils, Ghee) without
        // the customer having to open it first.
        $this->attachTileSubcategories($stores);

        return CommonHelper::responseWithData($stores);
    }

    /**
     * Attach a resolved `subcategories` list to every sub-category group in
     * the cat_store payload.
     *
     * Each `sub_category_groups.subcategory_ids` row holds a comma-separated
     * list of `categories` ids. This walks the payload once, resolves every
     * referenced id in a single query, and writes the result back in the
     * order the CSV declared — the same resolution products/group-products
     * already performs for a single tile.
     *
     * Handles both payload shapes: normal stores expose the Eloquent
     * `categoryGroups` relation, while the meat branch swaps in stdClass
     * groups carrying a `sub_category_groups` property.
     */
    private function attachTileSubcategories($stores)
    {
        // Flatten every sub-category group in the payload.
        $tiles = [];

        foreach ($stores as $store) {
            $groups = $store->categoryGroups ?? [];

            foreach ($groups as $group) {
                // stdClass (meat branch) exposes sub_category_groups;
                // Eloquent exposes the camelCase relation.
                $subGroups = $group->sub_category_groups
                    ?? $group->subCategoryGroups
                    ?? [];

                foreach ($subGroups as $tile) {
                    $tiles[] = $tile;
                }
            }
        }

        if (empty($tiles)) {
            return;
        }

        // Collect every referenced id up front so this costs one query
        // regardless of how many tiles the payload carries.
        $allIds = [];
        foreach ($tiles as $tile) {
            foreach ($this->parseIdCsv($tile->subcategory_ids ?? '') as $catId) {
                $allIds[$catId] = true;
            }
        }

        $resolved = empty($allIds)
            ? collect()
            : Category::select('id', 'name', 'image')
                ->whereIn('id', array_keys($allIds))
                ->get()
                ->keyBy('id');

        foreach ($tiles as $tile) {
            $tile->subcategories = collect($this->parseIdCsv($tile->subcategory_ids ?? ''))
                ->map(fn($catId) => $resolved->get($catId))
                ->filter()
                ->map(function ($cat) {
                    return [
                        'id'        => $cat->id,
                        'name'      => $cat->name,
                        'image_url' => $cat->image
                            ? (str_starts_with($cat->image, 'http')
                                ? $cat->image
                                : asset('storage/' . $cat->image))
                            : null,
                    ];
                })
                ->values()
                ->all();
        }
    }

    /**
     * Split a comma-separated id list into unique positive ints, preserving
     * the order the list declared. Ids that are blank or non-numeric are
     * dropped rather than becoming 0.
     */
    private function parseIdCsv($csv)
    {
        if (empty($csv)) {
            return [];
        }

        $ids = [];
        foreach (explode(',', $csv) as $part) {
            $catId = (int) trim($part);
            if ($catId > 0 && !in_array($catId, $ids, true)) {
                $ids[] = $catId;
            }
        }

        return $ids;
    }

    public function getSuperMartSellers(Request $request)
    {
        $userLat = $request->lat;
        $userLon = $request->lon;

        if (!$userLat || !$userLon) {
            return CommonHelper::responseError("lat and lon are required");
        }

        // City zone check
        $zoneFilterEnabled = CityZoneService::isZoneFilterEnabled();
        $customerCity = null;
        if ($zoneFilterEnabled) {
            $customerCity = CityZoneService::detectCity((float) $userLat, (float) $userLon);
            if (!$customerCity) {
                // Customer outside all zones - no delivery coverage
                return CommonHelper::responseErrorWithData(
                    'We are not available in your area',
                    ['available_zones' => CityZoneService::getAvailableZones()]
                );
            }
        }

        $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : null;

        // If seller_id is provided, return that specific seller's details
        $seller_id = $request->input('seller_id');
        if ($seller_id) {
            $seller = Seller::find($seller_id);
            if (!$seller) {
                return CommonHelper::responseError("Seller not found");
            }

            // Get store details for this seller
            $store = Store::find($seller->store_id);
            if (!$store || !$store->is_super_mart) {
                return CommonHelper::responseError("Seller is not part of SuperMart stores");
            }

            // Determine shop open/closed status based on shop_status only
            // If seller is online (shop_status = 1) and active (status = 1), they are accepting orders
            $isOpen = ($seller->status == 1 && $seller->shop_status == 1);
            $closedReason = 'Shop is currently offline';

            if ($seller->status != 1) {
                $closedReason = 'Seller is inactive';
            }

            $seller->is_shop_open = $isOpen;
            $seller->shop_status_message = $isOpen ? 'Shop is open' : $closedReason;

            // Calculate distance and travel time
            $latLong = $seller->lat_long;
            if ($latLong) {
                list($sLat, $sLon) = explode(",", $latLong);

                $distanceKm = StoreDistanceService::haversine($userLat, $userLon, $sLat, $sLon);
                $travelMin = StoreDistanceService::estimateTravelTimeMinutes($distanceKm);

                $google = StoreDistanceService::googleMapsDistance($userLat, $userLon, $sLat, $sLon);

                $seller->distance_km = StoreDistanceService::formatDistance($distanceKm);
                $seller->travel_time_min = StoreDistanceService::formatTime($travelMin);

                if ($google) {
                    $seller->distance_km = StoreDistanceService::formatDistance($google['distance_km']);
                    $seller->travel_time_min = StoreDistanceService::formatTime($google['time_min']);
                }
            } else {
                $seller->distance_km = null;
                $seller->travel_time_min = null;
            }

            // Get dynamic rating from RatingService
            $ratingData = RatingService::getSellerRating($seller->id, $seller->store_id);
            $seller->rating = $ratingData['rating'];
            $seller->rating_count = $ratingData['rating_count'];

            // Add is_bookmarked flag
            $seller->is_bookmarked = $user_id ? $this->checkSellerBookmarked($user_id, $seller->id) : 0;

            // Convert to array to ensure all custom fields are included in response
            $sellerArray = $seller->toArray() + [
                'is_bookmarked' => $seller->is_bookmarked,
                'is_shop_open' => $seller->is_shop_open,
                'shop_status_message' => $seller->shop_status_message
            ];

            // Return as array to maintain consistent API structure
            $response = [
                'total' => 1,
                'per_page' => 1,
                'current_page' => 1,
                'last_page' => 1,
                'data' => [$sellerArray]
            ];
            return CommonHelper::responseWithData($response);
        }

        // Pagination parameters
        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        // Get all supermart store IDs
        $superMartStoreIds = Store::where('is_super_mart', 1)->pluck('id');

        // Query sellers where store_id is in those supermart store IDs
        // Show all sellers including closed ones with status indicators
        $sellersQuery = Seller::whereIn('store_id', $superMartStoreIds)
            ->where('status', 1); // Only filter by active status

        // Search filter by store name or seller name
        $search = $request->input('search');
        if ($search) {
            $sellersQuery->where(function ($q) use ($search) {
                $q->where('store_name', 'LIKE', '%' . $search . '%')
                  ->orWhere('name', 'LIKE', '%' . $search . '%');
            });
        }

        // Filter sellers by customer's city zone
        if ($zoneFilterEnabled && $customerCity) {
            $allSellerIds = (clone $sellersQuery)->pluck('id')->toArray();
            $filteredIds = CityZoneService::filterSellersByZone($allSellerIds, $customerCity, (float) $userLat, (float) $userLon);

            if (!empty($filteredIds)) {
                $sellersQuery->whereIn('id', $filteredIds);
            } elseif (!$search) {
                // No sellers in zone and no search query - return zone error
                return CommonHelper::responseError("No sellers are currently online in your area");
            } else {
                // Search active but no sellers in zone - return empty list
                $sellersQuery->whereRaw('1 = 0');
            }
        }

        // Paginate sellers
        $sellersPaginated = $sellersQuery->paginate($perPage, ['*'], 'page', $page);

        // Calculate distance and travel time for each seller
        $sellers = collect($sellersPaginated->items())->map(function ($seller) use ($userLat, $userLon, $user_id) {
            // Determine shop open/closed status based on shop_status only
            // If seller is online (shop_status = 1), they are accepting orders regardless of scheduled times
            $isOpen = ($seller->shop_status == 1);
            $seller->is_shop_open = $isOpen;
            $seller->shop_status_message = $isOpen ? 'Shop is open' : 'Shop is currently offline';

            $latLong = $seller->lat_long;
            if (!$latLong) {
                $seller->distance_km = null;
                $seller->travel_time_min = null;
            } else {
                list($sLat, $sLon) = explode(",", $latLong);

                $distanceKm = StoreDistanceService::haversine(
                    $userLat,
                    $userLon,
                    $sLat,
                    $sLon
                );

                $travelMin = StoreDistanceService::estimateTravelTimeMinutes($distanceKm);

                $google = StoreDistanceService::googleMapsDistance(
                    $userLat,
                    $userLon,
                    $sLat,
                    $sLon
                );

                $seller->distance_km = StoreDistanceService::formatDistance($distanceKm);
                $seller->travel_time_min = StoreDistanceService::formatTime($travelMin);

                if ($google) {
                    $seller->distance_km = StoreDistanceService::formatDistance($google['distance_km']);
                    $seller->travel_time_min = StoreDistanceService::formatTime($google['time_min']);
                }
            }

            // Get dynamic rating from RatingService
            $ratingData = RatingService::getSellerRating($seller->id, $seller->store_id);
            $seller->rating = $ratingData['rating'];
            $seller->rating_count = $ratingData['rating_count'];

            // Add is_bookmarked flag
            $seller->is_bookmarked = $user_id ? $this->checkSellerBookmarked($user_id, $seller->id) : 0;

            return $seller;
        });

        // Sort sellers by distance (nearest first)
        $sellers = $sellers->sortBy('distance_km')->values();

        // Convert to array to ensure all custom fields are included in response
        $sellersArray = $sellers->map(function ($seller) {
            return $seller->toArray() + [
                'is_bookmarked' => $seller->is_bookmarked,
                'is_shop_open' => $seller->is_shop_open ?? true,
                'shop_status_message' => $seller->shop_status_message ?? 'Shop is open'
            ];
        })->all();

        // Fetch banners/sliders for supermart stores
        $banners = Slider::whereIn('store_id', $superMartStoreIds)
            ->where('status', 1)
            ->get();

        // Create pagination response
        $response = [
            'total' => $sellersPaginated->total(),
            'per_page' => $sellersPaginated->perPage(),
            'current_page' => $sellersPaginated->currentPage(),
            'last_page' => $sellersPaginated->lastPage(),
            'data' => $sellersArray,
            'banners' => $banners
        ];

        return CommonHelper::responseWithData($response);
    }

    /**
     * Get sweet house sellers with pagination and filtering
     * Sweet houses are individual seller stores (non-admin, non-super mart)
     */
    public function getSweetHouseSellers(Request $request)
    {
        $userLat = $request->lat;
        $userLon = $request->lon;

        if (!$userLat || !$userLon) {
            return CommonHelper::responseError("lat and lon are required");
        }

        // City zone check
        $zoneFilterEnabled = CityZoneService::isZoneFilterEnabled();
        $customerCity = null;
        if ($zoneFilterEnabled) {
            $customerCity = CityZoneService::detectCity((float) $userLat, (float) $userLon);
            if (!$customerCity) {
                // Customer outside all zones - no delivery coverage
                return CommonHelper::responseErrorWithData(
                    'We are not available in your area',
                    ['available_zones' => CityZoneService::getAvailableZones()]
                );
            }
        }

        // Get authenticated user ID for bookmark checks
        $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : null;

        // Pagination parameters
        $perPage = $request->input('per_page', 10);
        $page = $request->input('page', 1);

        // Filtering and sorting parameters
        $sortBy = $request->input('sort_by', SellerFilterService::SORT_DISTANCE);
        $foodType = $request->input('food_type', SellerFilterService::FOOD_TYPE_ALL);
        $searchQuery = $request->input('search', ''); // search by seller name or store name
        $cityId = $request->input('city_id', null);

        // Get all sweet house store IDs (non-admin, non-super mart)
        $sweetHouseStoreIds = Store::where('managed_by_admin', 0)
            ->where('is_super_mart', 0)
            ->where('is_active', true)
            ->pluck('id');

        // Start building the query
        $sellersQuery = Seller::whereIn('store_id', $sweetHouseStoreIds);

        // Apply search filter
        if (!empty($searchQuery)) {
            $sellersQuery = $sellersQuery->where(function ($query) use ($searchQuery) {
                $query->where('name', 'like', "%{$searchQuery}%")
                    ->orWhereHas('store', function ($query) use ($searchQuery) {
                        $query->where('name', 'like', "%{$searchQuery}%");
                    });
            });
        }

        // Apply city filter if provided
        if (!empty($cityId)) {
            $sellersQuery = $sellersQuery->where('city_id', $cityId);
        }

        // Filter sellers by customer's city zone
        if ($zoneFilterEnabled && $customerCity) {
            $allSellerIds = (clone $sellersQuery)->pluck('id')->toArray();
            $filteredIds = CityZoneService::filterSellersByZone($allSellerIds, $customerCity, (float) $userLat, (float) $userLon);

            if (!empty($filteredIds)) {
                $sellersQuery->whereIn('id', $filteredIds);
            } else {
                // No sellers found - return error with available zones
                return CommonHelper::responseErrorWithData(
                    'We are not available in your area',
                    ['available_zones' => CityZoneService::getAvailableZones()]
                );
            }
        }

        // Paginate sellers
        $sellersPaginated = $sellersQuery->paginate($perPage, ['*'], 'page', $page);

        // Calculate distance, rating, and travel time for each seller
        $sellers = collect($sellersPaginated->items())->map(function ($seller) use ($userLat, $userLon, $user_id) {
            // Determine shop open/closed status based on shop_status only
            // If seller is online (shop_status = 1), they are accepting orders regardless of scheduled times
            $isOpen = ($seller->shop_status == 1);
            $seller->is_shop_open = $isOpen;
            $seller->shop_status_message = $isOpen ? 'Shop is open' : 'Shop is currently offline';

            // Get dynamic rating from RatingService
            $ratingData = RatingService::getSellerRating($seller->id, $seller->store_id);
            $seller->rating = $ratingData['rating'];
            $seller->rating_count = $ratingData['rating_count'];

            $latLong = $seller->lat_long;
            if (!$latLong) {
                $seller->distance_km = null;
                $seller->travel_time_min = null;
                $seller->is_bookmarked = $user_id ? $this->checkSellerBookmarked($user_id, $seller->id) : 0;
                return $seller;
            }

            list($sLat, $sLon) = explode(",", $latLong);

            $distanceKm = StoreDistanceService::haversine(
                $userLat,
                $userLon,
                $sLat,
                $sLon
            );

            $travelMin = StoreDistanceService::estimateTravelTimeMinutes($distanceKm);

            $google = StoreDistanceService::googleMapsDistance(
                $userLat,
                $userLon,
                $sLat,
                $sLon
            );

            $seller->distance_km = StoreDistanceService::formatDistance($distanceKm);
            $seller->travel_time_min = StoreDistanceService::formatTime($travelMin);

            if ($google) {
                $seller->distance_km = StoreDistanceService::formatDistance($google['distance_km']);
                $seller->travel_time_min = StoreDistanceService::formatTime($google['time_min']);
            }

            // Add is_bookmarked status
            $seller->is_bookmarked = $user_id ? $this->checkSellerBookmarked($user_id, $seller->id) : 0;

            return $seller;
        });

        // Attach food_type to each seller
        $sellers = SellerFilterService::attachFoodTypeToSellers($sellers);

        // Apply food type filter using SellerFilterService
        $sellers = SellerFilterService::applyFoodTypeFilter($sellers, $foodType);

        // Apply sorting using SellerFilterService
        $sellers = SellerFilterService::applySorting($sellers, $sortBy);

        // Convert to array to ensure all custom fields are included in response
        $sellersArray = $sellers->map(function ($seller) {
            $sellerArray = $seller->toArray();
            // Explicitly include custom fields to ensure they're in the response
            $sellerArray['is_bookmarked'] = $seller->is_bookmarked ?? 0;
            $sellerArray['is_shop_open'] = $seller->is_shop_open ?? true;
            $sellerArray['shop_status_message'] = $seller->shop_status_message ?? 'Shop is open';
            return $sellerArray;
        })->all();

        // Create pagination response
        $response = [
            'total' => $sellersPaginated->total(),
            'per_page' => $sellersPaginated->perPage(),
            'current_page' => $sellersPaginated->currentPage(),
            'last_page' => $sellersPaginated->lastPage(),
            'from' => $sellersPaginated->firstItem(),
            'to' => $sellersPaginated->lastItem(),
            'sort_by' => $sortBy,
            'sort_options' => SellerFilterService::getSortOptions(),
            'food_type' => $foodType,
            'food_type_options' => SellerFilterService::getFoodTypeOptions(),
            'data' => $sellersArray
        ];

        return CommonHelper::responseWithData($response);
    }

    public function getSellerCategoryGroups(Request $request)
    {
        $sellerId = $request->seller_id;

        if (!$sellerId) {
            return CommonHelper::responseError("seller_id is required");
        }

        // Verify the seller exists
        $seller = Seller::find($sellerId);
        if (!$seller) {
            return CommonHelper::responseError("Seller not found");
        }

        $store = Store::find($seller->store_id);
        if (!$store || !$store->is_super_mart) {
            return CommonHelper::responseError("This seller is not in a supermart store");
        }

        // Get category groups for this seller with subcategory groups
        $categoryGroups = CategoryGroup::where('seller_id', $sellerId)
            ->where('status', 1)
            ->with(['subCategoryGroups'])
            ->get();

        // Get categories created by this seller for supermart
        $categories = Category::where('seller_id', $sellerId)
            ->where('status', 1)
            ->get();

        $response = [
            'seller_id' => $sellerId,
            'store_id' => $store->id,
            'store_name' => $store->name,
            'category_groups' => $categoryGroups,
            'categories' => $categories
        ];

        return CommonHelper::responseWithData($response);
    }

    public function getSellerCategoryTree(Request $request)
    {
        $sellerId = $request->seller_id;

        if (!$sellerId) {
            return CommonHelper::responseError("seller_id is required");
        }

        $seller = Seller::find($sellerId);
        if (!$seller) {
            return CommonHelper::responseError("Seller not found");
        }

        // Category groups with their sub-category groups, ordered
        $categoryGroups = CategoryGroup::where('seller_id', $sellerId)
            ->with(['subCategoryGroups' => function ($q) {
                $q->orderBy('row_order', 'ASC');
            }])
            ->orderBy('row_order', 'ASC')
            ->get();

        // Flat categories added by this seller (not inside any group)
        $categories = Category::where('seller_id', $sellerId)
            ->where('status', 1)
            ->orderBy('row_order', 'ASC')
            ->get();

        $response = [
            'seller_id'       => (int) $sellerId,
            'category_groups' => $categoryGroups,
            'categories'      => $categories,
        ];

        return CommonHelper::responseWithData($response);
    }

    public function getSuperMartProductLists(Request $request)
    {
        $sellerId = $request->seller_id;

        if (!$sellerId) {
            return CommonHelper::responseError("seller_id is required");
        }

        // Get authenticated user ID for bookmark checks
        $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : null;

        // Verify the seller exists and is in a supermart
        $seller = Seller::find($sellerId);
        if (!$seller) {
            return CommonHelper::responseError("Seller not found");
        }

        // Get the seller's store and check if it's a supermart
        $store = Store::find($seller->store_id);
        if (!$store) {
            return CommonHelper::responseError("Seller store not found");
        }

        if (!$store->is_super_mart) {
            return CommonHelper::responseError("This seller is not in a supermart store");
        }

        // Limit per list (can be customized via request)
        $limitPerList = $request->input('limit_per_list', 10);

        // Base query for seller's products with variants and necessary relationships
        $baseQuery = Product::where('products.seller_id', $sellerId)
            ->where('products.status', 1)
            ->where('products.is_approved', 1)
            ->with([
                'variants' => function ($query) {
                    $query->select('id', 'product_id', 'price', 'discounted_price', 'stock', 'measurement', 'stock_unit_id');
                },
                'variants.stockUnit',
                'images',
                'brand',
                'category'
            ]);

        // 1. Top Picks - Products with highest average ratings
        $topPicks = Product::where('products.seller_id', $sellerId)
            ->where('products.status', 1)
            ->where('products.is_approved', 1)
            ->with([
                'variants' => function ($query) {
                    $query->select('id', 'product_id', 'price', 'discounted_price', 'stock', 'measurement', 'stock_unit_id');
                },
                'variants.stockUnit',
                'images',
                'brand',
                'category'
            ])
            ->leftJoin('order_product_ratings', 'products.id', '=', 'order_product_ratings.product_id')
            ->select('products.*',
                DB::raw('COALESCE(AVG(order_product_ratings.rating), 0) as average_rating'),
                DB::raw('COUNT(order_product_ratings.id) as rating_count')
            )
            ->groupBy('products.id')
            ->orderBy('average_rating', 'desc')
            ->orderBy('products.id', 'desc')
            ->limit($limitPerList)
            ->get()
            ->map(function ($product) {
                if (empty($product->average_rating) || $product->average_rating == 0) {
                    $product->average_rating = round(mt_rand(40, 50) / 10, 1); // random 4.0–5.0
                    $product->rating_count = mt_rand(50, 500);
                }
                return $product;
            });

        // Helper to add dummy rating if no real rating exists
        $withDummyRating = function ($products) {
            return $products->map(function ($product) {
                if (empty($product->average_rating) || $product->average_rating == 0) {
                    $product->average_rating = round(mt_rand(40, 50) / 10, 1); // random 4.0–5.0
                    $product->rating_count = mt_rand(50, 500);
                }
                return $product;
            });
        };

        // 2. Best Selling - Products sorted by row_order (featured products)
        $bestSelling = $withDummyRating((clone $baseQuery)
            ->orderBy('row_order', 'asc')
            ->limit($limitPerList)
            ->get());

        // 3. New Arrivals - Recently added products
        $newArrivals = $withDummyRating((clone $baseQuery)
            ->orderBy('created_at', 'desc')
            ->limit($limitPerList)
            ->get());

        // 4. Best in Class - Products with highest discount percentage
        $bestInClass = Product::where('products.seller_id', $sellerId)
            ->where('products.status', 1)
            ->where('products.is_approved', 1)
            ->with([
                'variants' => function ($query) {
                    $query->select('id', 'product_id', 'price', 'discounted_price', 'stock', 'measurement', 'stock_unit_id')
                        ->where('discounted_price', '>', 0);
                },
                'variants.stockUnit',
                'images',
                'brand',
                'category'
            ])
            ->whereHas('variants', function ($query) {
                $query->where('discounted_price', '>', 0);
            })
            ->get()
            ->map(function ($product) {
                // Calculate max discount percentage for each product
                $maxDiscount = 0;
                foreach ($product->variants as $variant) {
                    if ($variant->price > 0 && $variant->discounted_price > 0) {
                        $discount = (($variant->price - $variant->discounted_price) / $variant->price) * 100;
                        if ($discount > $maxDiscount) {
                            $maxDiscount = $discount;
                        }
                    }
                }
                $product->max_discount_percentage = round($maxDiscount, 2);
                if (empty($product->average_rating) || $product->average_rating == 0) {
                    $product->average_rating = round(mt_rand(40, 50) / 10, 1); // random 4.0–5.0
                    $product->rating_count = mt_rand(50, 500);
                }
                return $product;
            })
            ->sortByDesc('max_discount_percentage')
            ->take($limitPerList)
            ->values();

        // Helper function to add is_bookmarked to products and convert to array
        $addBookmarkStatus = function($products) use ($user_id) {
            return $products->map(function($product) use ($user_id) {
                $productArray = $product->toArray();
                $productArray['is_bookmarked'] = $user_id ? $this->checkProductBookmarked($user_id, $product->id) : 0;
                return $productArray;
            })->values()->all();
        };

        $response = [
            'seller_id' => $sellerId,
            'store_id' => $store->id,
            'store_name' => $store->name,
            'product_lists' => [
                [
                    'title' => 'Top Picks',
                    'products' => $addBookmarkStatus($topPicks)
                ],
                [
                    'title' => 'Best Selling',
                    'products' => $addBookmarkStatus($bestSelling)
                ],
                [
                    'title' => 'New Arrivals',
                    'products' => $addBookmarkStatus($newArrivals)
                ],
                [
                    'title' => 'Best in Class',
                    'products' => $addBookmarkStatus($bestInClass)
                ]
            ]
        ];

        return CommonHelper::responseWithData($response);
    }

    /**
     * Helper method to check if a seller is bookmarked by a user
     */
    private function checkSellerBookmarked($user_id, $seller_id)
    {
        return Bookmark::where('user_id', $user_id)
            ->where('type', 'seller')
            ->where('bookmarkable_type', 'App\Models\Seller')
            ->where('bookmarkable_id', $seller_id)
            ->exists() ? 1 : 0;
    }

    /**
     * Helper method to check if a product is bookmarked by a user
     */
    private function checkProductBookmarked($user_id, $product_id)
    {
        return Bookmark::where('user_id', $user_id)
            ->where('type', 'product')
            ->where('bookmarkable_type', 'App\Models\Product')
            ->where('bookmarkable_id', $product_id)
            ->exists() ? 1 : 0;
    }

}
