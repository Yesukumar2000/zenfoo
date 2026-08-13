<?php

// namespace App\Http\Controllers\Api\Customer;
namespace App\Http\Controllers\API\Customer;

use App\Helpers\CommonHelper;
use App\Helpers\ProductHelper;
use App\Http\Controllers\Controller;
use App\Http\Repository\CategoryRepository;
use App\Http\Repository\ProductRepository;
use App\Models\Admin;
use App\Models\Cart;
use App\Models\Favorite;
use App\Models\Product;
use App\Models\ProductImages;
use App\Models\ProductVariant;
use App\Models\PromoCode;
use App\Models\Seller;
use App\Models\Setting;
use App\Models\Tax;
use App\Models\Transaction;
use App\Models\WalletTransaction;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use App\Models\User;
use App\Models\CustomerClaimedMilestone;
use App\Models\UserOrderReward;
use App\Models\Order;
use function App\Models\Setting;

use App\Services\CartStoreIdsService;
use App\Services\MultiOrderChargesService;
use App\Services\WeatherService;


use Response;

class CartApiController extends Controller
{
    public function getUserCart(Request $request)
    {

        // Initialize variables used throughout the function
        $multiOrderCharges = 0;
        $hasMultiOrder = false;
        $serviceDeliveryCharge = 0;

        $is_self_pickup = (isset($request->is_self_pickup) && $request->is_self_pickup == 1) ? true : false;

        $validationRules = [];
        if (!$is_self_pickup) {
            $validationRules = [
                'latitude' => 'required',
                'longitude' => 'required',
            ];
        }

        $validator = Validator::make($request->all(), $validationRules, [
            'latitude.required' => 'The latitude field is required.',
            'longitude.required' => 'The longitude field is required.'
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }


        $type = $request->get('type', '');
        $user_id = $request->user('api-customers') ? $request->user('api-customers')->id : '';

        $variant_ids = explode(",", $request->variant_ids);

        if (ProductHelper::isItemAvailableInUserCart($user_id)) {

            $res = Cart::with('product.store')
                ->select(
                    'carts.*',
                    'products.slug',
                    'products.cod_allowed',
                    'products.image',
                    'products.is_unlimited_stock',
                    'products.seller_id',
                    'products.store_id',
                    'stores.managed_by_admin',
                    'stores.is_super_mart as is_super_mart',
                    'sellers.longitude',
                    'sellers.latitude',
                    'sellers.city_id',
                    'sellers.name as seller_name',
                    'sellers.store_name as store_name'
                )
                ->Join('products', 'carts.product_id', '=', 'products.id')
                ->Join('product_variants', 'carts.product_variant_id', '=', 'product_variants.id')
                ->leftJoin('sellers', 'products.seller_id', '=', 'sellers.id')
                ->leftJoin('stores', 'products.store_id', '=', 'stores.id')
                ->where('carts.save_for_later', '=', 0)
                ->where('user_id', '=', $user_id);
            if ($request->variant_ids && $request->variant_ids !== "") {
                $res = $res->whereIn('carts.product_variant_id', $variant_ids);
            }
            $res = $res->orderBy('created_at', 'DESC')

                ->get();

            $seller_ids = $res->isNotEmpty() ? array_values(array_unique(array_column($res->toArray(), 'seller_id'))) : [];

            $res = $res->makeHidden(['user_id', 'id', 'save_for_later', 'type', 'stock_unit_name', 'image', 'images', 'created_at', 'updated_at']);

            foreach ($res as $key => $row) {


                if (isset($row->city_id) && $row->city_id != 0 && $row->city_id != "") {
                    if ($is_self_pickup) {
                        $row['is_deliverable'] = 1; // Self-pickup is always "deliverable"
                    } else {
                        if (CommonHelper::isDeliverable($row->city_id, $request->latitude, $request->longitude)) {
                            $row['is_deliverable'] = 1;
                        } else {
                            $row['is_deliverable'] = 0;
                        }
                    }
                } else {
                    $row['is_deliverable'] = 0;
                }


                $item = ProductVariant::select(
                    'product_variants.*',
                    'products.cod_allowed',
                    'products.seller_id as seller_id',
                    'products.name',
                    'products.type as d_type',
                    'products.cod_allowed',
                    'products.slug',
                    'products.image',
                    'products.total_allowed_quantity',
                    DB::raw('(CASE WHEN taxes.percentage != "0" THEN taxes.percentage ELSE "0" END) AS tax_percentage'),
                    DB::raw('(CASE WHEN taxes.title != "" THEN taxes.title ELSE "" END) AS tax_title'),
                    'product_variants.measurement',
                    DB::raw('(select short_code from units where units.id = product_variants.stock_unit_id) AS stock_unit_name')
                )
                    ->Join('products', 'product_variants.product_id', '=', 'products.id')
                    ->leftJoin('taxes', 'products.tax_id', '=', 'taxes.id')
                    ->where('product_variants.id', $row->product_variant_id)
                    ->groupBy('product_variants.id')
                    ->orderBy('created_at', 'DESC')
                    ->first();
                $item = $item->makeHidden(['image', 'created_at', 'updated_at']);

                $res[$key]->type = $item->type;
                $res[$key]->measurement = $item->measurement;

                $taxed = ProductHelper::getTaxableAmount($item->id);

                $res[$key]->discounted_price = CommonHelper::doubleNumber($taxed->taxable_discounted_price ?? $item->discounted_price);
                $res[$key]->price = CommonHelper::doubleNumber($taxed->taxable_price ?? $item->price);
                $res[$key]->taxable_amount = CommonHelper::doubleNumber($taxed->taxable_amount);

                $res[$key]->stock = $item->stock;
                $res[$key]->images = CommonHelper::getImages($row['id'], $row->product_variant_id);
                $res[$key]->total_allowed_quantity = $item->total_allowed_quantity;
                $res[$key]->name = $item->name;
                $res[$key]->unit_code = $item->unit->short_code ?? '';
                $res[$key]->stock_unit_name = $item->stock_unit_name;
                $res[$key]->status = $item->status;
            }


            // Check seller shop status for food store products (store_id = 15 and 17)
            $food_store_ids = [15, 17];
            $offline_seller_products = [];
            $all_sellers_online = true;

            // Get products from food stores in the cart
            $food_store_cart_items = $res->filter(function ($item) use ($food_store_ids) {
                return in_array($item->store_id, $food_store_ids);
            });

            if ($food_store_cart_items->isNotEmpty()) {
                // Get unique seller IDs from food store products
                $food_seller_ids = $food_store_cart_items->pluck('seller_id')->unique()->toArray();

                // Check shop status for these sellers
                $sellers_status = Seller::whereIn('id', $food_seller_ids)
                    ->select('id', 'shop_status')
                    ->get()
                    ->keyBy('id');

                // Check if any seller is offline (shop_status = 0)
                foreach ($food_store_cart_items as $cart_item) {
                    $seller = $sellers_status->get($cart_item->seller_id);

                    if ($seller && $seller->shop_status == 0) {
                        $all_sellers_online = false;
                        $offline_seller_products[] = [
                            'product_id' => $cart_item->product_id,
                            'product_variant_id' => $cart_item->product_variant_id,
                            'seller_id' => $cart_item->seller_id,
                            'seller_name' => $cart_item->seller_name,
                        ];
                    }
                }
            }

            // Add shop status info to response
            $response['shop_status_check'] = [
                'all_sellers_online' => $all_sellers_online ? 1 : 0,
                'offline_products' => $offline_seller_products,
                'message' => !$all_sellers_online
                    ? 'Some sellers are currently closed. These items will be removed from cart if you proceed.'
                    : 'All sellers are online'
            ];

            $grouped_by_seller = [];
            $admin_managed_store_items = [];

            foreach ($res as $item) {
                // Check if store is managed by admin
                if ($item->managed_by_admin == 1) {

                    // Add to admin managed items
                    $admin_managed_store_items[] = $item;
                    continue;
                }

                // Group by seller for non-admin managed stores
                $sellerId = $item->seller_id;
                $sellerName = $item->seller_name;
                $storeName = $item->store_name;
                $sellerStore = $item->product?->store;

                // Create group if not exists
                if (!isset($grouped_by_seller[$sellerId])) {
                    $grouped_by_seller[$sellerId] = [
                        'seller_id' => $sellerId,
                        'seller_name' => $sellerName,
                        'store_name' => $storeName,
                        'seller_store' => $sellerStore,
                        'is_super_mart' => $item->is_super_mart,
                        'items' => []
                    ];
                }

                $item->seller_id = $sellerId;
                $grouped_by_seller[$sellerId]['items'][] = $item;
            }

            $grouped_by_seller = array_values($grouped_by_seller);



            /*Save for Later*/
            if ($request->is_checkout != 1) {
                $result = Cart::with('images')->select(
                    'carts.*',
                    'products.cod_allowed',
                    'products.image',
                    'products.is_unlimited_stock',
                    'sellers.longitude',
                    'sellers.latitude'
                )
                    ->Join('products', 'carts.product_id', '=', 'products.id')
                    ->Join('product_variants', 'carts.product_variant_id', '=', 'product_variants.id')
                    ->leftJoin('sellers', 'products.seller_id', '=', 'sellers.id')
                    ->where('carts.save_for_later', 1)
                    ->where('user_id', '=', $user_id)
                    ->orderBy('created_at', 'DESC')
                    ->get();

                $result = $result->makeHidden(['user_id', 'id', 'save_for_later', 'type', 'stock_unit_name', 'image', 'images', 'created_at', 'updated_at', 'boundary_points']);
                foreach ($result as $key => $rows) {

                    if (isset($rows->max_deliverable_distance) && $rows->max_deliverable_distance != 0 && $rows->max_deliverable_distance != "") {
                        if ($is_self_pickup) {
                            $rows['is_deliverable'] = 1;
                        } else {
                            if (CommonHelper::isDeliverable($rows->max_deliverable_distance, $rows->longitude, $rows->latitude, $request->longitude, $request->latitude)) {
                                $rows['is_deliverable'] = 1;
                            } else {
                                $rows['is_deliverable'] = 0;
                            }
                        }
                    } else {
                        $rows['is_deliverable'] = 0;
                    }

                    $item = ProductVariant::select(
                        'product_variants.*',
                        'products.cod_allowed',
                        'products.seller_id as seller_id',
                        'products.name',
                        'products.type as d_type',
                        'products.cod_allowed',
                        'products.slug',
                        'products.image',
                        'products.total_allowed_quantity',
                        DB::raw('(CASE WHEN taxes.percentage != "0" THEN taxes.percentage ELSE "0" END) AS tax_percentage'),
                        DB::raw('(CASE WHEN taxes.title != "" THEN taxes.title ELSE "" END) AS tax_title'),
                        'product_variants.measurement',
                        DB::raw('(select short_code from units where units.id = product_variants.stock_unit_id) AS stock_unit_name')
                    )
                        ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
                        ->leftJoin('taxes', 'products.tax_id', '=', 'taxes.id')
                        ->where('product_variants.id', '=', $rows->product_variant_id)
                        ->groupBy('product_variants.id')
                        ->orderBy('created_at', 'DESC')
                        ->first();
                    $item = $item->makeHidden(['image', 'created_at', 'updated_at']);

                    $result[$key]->type = $item->type;
                    $result[$key]->measurement = $item->measurement;


                    $taxed = ProductHelper::getTaxableAmount($item->id);

                    $result[$key]->discounted_price = CommonHelper::doubleNumber($taxed->taxable_discounted_price ?? $item->discounted_price);
                    $result[$key]->price = CommonHelper::doubleNumber($taxed->taxable_price ?? $item->price);
                    $result[$key]->taxable_amount = CommonHelper::doubleNumber($taxed->taxable_amount);

                    $result[$key]->stock = $item->stock;
                    $result[$key]->images = CommonHelper::getImages($rows['id'], $rows->product_variant_id);
                    $result[$key]->total_allowed_quantity = $item->total_allowed_quantity;
                    $result[$key]->name = $item->name;
                    $result[$key]->unit = $item->unit->short_code ?? '';
                    $result[$key]->stock_unit_name = $item->stock_unit_name;
                    $result[$key]->status = $item->status;
                }
            }

            // Check if user has combos in cart
            $hasCustomCombos = DB::table('combo_custom_cart')
                ->where('user_id', $user_id)
                ->where('is_ordered', 0)
                ->exists();

            if (!empty($res) || !empty($result) || $hasCustomCombos) {

                $total = CommonHelper::getCartCount($user_id);

                // Use original MRP prices for display
                $sub_total = $total->save_price; // Original MRP price
                $discounted_sub_total = $total->total_amount; // Selling price

                $saved_amount = $total->save_price - $total->total_amount;
                $saved_amount = ($saved_amount <= 0) ? 0 : $saved_amount;

                if (isset($request->is_checkout) && $request->is_checkout == 1) {

                    // Validate delivery address is selected for non-self-pickup orders
                    if (!$is_self_pickup) {
                        $deliveryAddress = \App\Models\UserAddress::where('user_id', $user_id)
                            ->where('is_default', 1)
                            ->first();

                        if (!$deliveryAddress) {
                            return CommonHelper::responseError('Please select a delivery address before proceeding to checkout.');
                        }
                    }

                    $cod_payment_method = Setting::get_value('cod_payment_method');
                    if ($cod_payment_method == 1) {
                        $cod_mode = Setting::get_value('cod_mode');
                        if ($cod_mode == Setting::$codModeGlobal) {
                            $response['cod_allowed'] = 1;
                        } else {
                            $codArray = array_values(array_unique(array_column($res->toArray(), 'cod_allowed')));
                            $cod_allowed = implode(',', $codArray);
                            if ($cod_allowed == 1) {
                                $response['cod_allowed'] = intval($cod_allowed);
                            } else {
                                $response['cod_allowed'] = 0;
                            }
                        }
                    } else {
                        $response['cod_allowed'] = 0;
                    }

                    $response['product_variant_id'] = $total->product_variant_id;
                    $response['quantity'] = $total->quantity;

                    $is_self_pickup_enabled = (isset($request->is_self_pickup) && $request->is_self_pickup == 1) ? true : false;

                    if ($is_self_pickup_enabled) {
                        $data = [
                            'status' => 1,
                            'data' => [
                                'total_delivery_charge' => 0,
                                'delivery_charge' => 0,
                                'delivery_charge_details' => []
                            ]
                        ];
                    } else {
                        // For non-self-pickup orders, latitude and longitude are required
                        if (!isset($request->latitude) || !isset($request->longitude)) {
                            return CommonHelper::responseError('latitude and longitude are required for delivery orders');
                        }

                        // If user has only combos (no regular items), set default delivery data
                        // if (empty($seller_ids)) {
                        $data = [
                            'status' => 1,
                            'data' => [
                                'total_delivery_charge' => 0,
                                'delivery_charge' => 0,
                                'delivery_charge_details' => []
                            ]
                        ];
                        // } else {
                        //     $data = CommonHelper::getAllDeliveryCharge($request->latitude, $request->longitude, $seller_ids, $sub_total);
                        // }
                    }

                    if ($data['status'] == 0) {
                        return CommonHelper::responseError('sorry_we_are_not_delivering_on_selected_address');
                    } else {

                        $one_seller_cart = Setting::where('variable', 'one_seller_cart')->exists() ? (int) Setting::where('variable', 'one_seller_cart')->value('value') : 0;
                        $cartItems = Cart::select('carts.*', 'products.seller_id', 'products.name as product_name', 'sellers.name as seller_name', 'sellers.status as seller_status', 'sellers.self_pickup_mode', 'sellers.pickup_store_address')
                            ->join('products', 'carts.product_id', '=', 'products.id')
                            ->leftJoin('sellers', 'products.seller_id', '=', 'sellers.id')
                            ->where('carts.save_for_later', '=', 0)
                            ->where('user_id', '=', $user_id)
                            ->get();
                        if ($one_seller_cart == 1 && !$cartItems->isEmpty()) {
                            $firstSeller = $cartItems->first()->seller_id;
                            $allSameSeller = $cartItems->every(function ($item) use ($firstSeller) {
                                return $item->seller_id === $firstSeller;
                            });

                            if (!$allSameSeller) {
                                $data['one_seller_error_code'] = 1;
                                return CommonHelper::responseErrorWithData('all_cart_products_have_not_same_seller', $data);
                            }

                            $seller = $cartItems->first();
                            if ($seller && $seller->seller_id) {
                                $sellerData = Seller::select('id', 'name', 'self_pickup_mode', 'pickup_store_address', 'pickup_latitude', 'pickup_longitude', 'pickup_store_timings', 'mobile')
                                    ->where('id', $seller->seller_id)
                                    ->first();

                                if ($sellerData) {
                                    // Parse pickup store timings JSON
                                    $pickup_timings = json_decode($sellerData->pickup_store_timings, true);
                                    $opening_time = $pickup_timings['opening_time'] ?? '';
                                    $closing_time = $pickup_timings['closing_time'] ?? '';

                                    $response['seller_self_pickup'] = [
                                        'seller_id' => $sellerData->id,
                                        'seller_name' => $sellerData->name,
                                        'seller_mobile' => $sellerData->mobile,
                                        // 'self_pickup_mode' => $sellerData->self_pickup_mode,
                                        'pickup_store_address' => $sellerData->pickup_store_address,
                                        'pickup_latitude' => $sellerData->pickup_latitude,
                                        'pickup_longitude' => $sellerData->pickup_longitude,
                                        'opening_time' => $opening_time,
                                        'closing_time' => $closing_time,
                                    ];
                                }
                            }
                        }
                        // $deactivatedSellers = $cartItems->filter(function ($item) {
                        //     return $item->seller_status != 1;
                        // });
                        // if ($deactivatedSellers->isNotEmpty()) {
                        //     foreach ($deactivatedSellers as $item) {

                        //         $message =  "is_from_disabled_seller";
                        //         return CommonHelper::responseErrorWithData($message, $item->product_name);
                        //     }
                        // }

                        // Calculate total amount step by step
                        // Step 1: Start with items subtotal (using MRP price)
                        $total_amount = $total->save_price;

                        // Step 1b: Subtract items discount (MRP - selling price)
                        $items_discount = $total->save_price - $total->total_amount;
                        if ($items_discount > 0) {
                            $total_amount -= $items_discount;
                        }

                        // Step 2: Add delivery charge
                        $total_amount += $data['data']['total_delivery_charge'];

                        // Step 3: Get and add delivery tip from cart metadata
                        $cartMetadataForTip = \App\Models\CartMetadata::where('user_id', $user_id)->first();
                        $delivery_tip_amount = 0;
                        if ($cartMetadataForTip && $cartMetadataForTip->delivery_tip > 0) {
                            $delivery_tip_amount = $cartMetadataForTip->delivery_tip;
                        }
                        // Override with request delivery_tip if provided
                        if ($request->has('delivery_tip')) {
                            $delivery_tip_amount = $request->delivery_tip;
                        }
                        $total_amount += $delivery_tip_amount;

                        $global_self_pickup_mode = Setting::where('variable', 'self_pickup_mode')->value('value') ?? 0;
                        $seller_self_pickup_mode = $sellerData['self_pickup_mode'] ?? 0;
                        $response['self_pickup_mode'] = ($global_self_pickup_mode == 1 && $seller_self_pickup_mode == 1) ? 1 : 0;

                        // Note: Promo code discount will be applied in checkout section (lines ~725+)
                        // Total calculation order:
                        // Items Subtotal + Delivery + Tip - Discount + Additional Charges = Final Total

                        $response['delivery_charge'] = $data['data'];
                        $response['delivery_tip'] = $delivery_tip_amount;
                        $response['total_amount'] = $total_amount;
                    }


                }

                // Get custom combo cart data (ALWAYS - needed for total calculation)
                $customComboCarts = DB::table('combo_custom_cart')
                    ->where('user_id', $user_id)
                    ->where('is_ordered', 0)
                    ->get();

                $customCombos = [];
                $total_combo_price = 0; // Selling price
                $total_combo_mrp = 0; // MRP/Original price
                $total_combo_savings = 0; // Track total savings from combos
                $currency = Setting::get_value('currency');

                foreach ($customComboCarts as $customCart) {
                    $combo = DB::table('combos')->where('id', $customCart->combo_id)->first();

                    if (!$combo) {
                        continue;
                    }

                    $customProducts = DB::table('combo_custom_products')
                        ->where('combo_custom_id', $customCart->id)
                        ->get();

                    if ($customProducts->isEmpty()) {
                        continue;
                    }

                    $productIds = $customProducts->pluck('product_id')->unique();
                    $products = Product::with(['variants.unit', 'images', 'store'])
                        ->whereIn('id', $productIds)
                        ->get();

                    $productsData = [];
                    $totalProductPrice = 0;
                    $totalActualPrice = 0;

                    foreach ($customProducts as $customProduct) {
                        $product = $products->firstWhere('id', $customProduct->product_id);
                        if (!$product) {
                            continue;
                        }

                        $variant = $product->variants->firstWhere('id', $customProduct->variant_id);
                        if (!$variant) {
                            continue;
                        }

                        $price = $variant->discounted_price > 0 ? $variant->discounted_price : $variant->price;
                        $actualPrice = $variant->price;

                        $totalProductPrice += $price * $customProduct->quantity;
                        $totalActualPrice += $actualPrice * $customProduct->quantity;

                        // Only build full product data if not in checkout mode (to save processing)
                        if ($request->is_checkout != 1) {
                            // Get product rating
                            $productRatingData = DB::table('product_ratings')
                                ->where('is_combo', 0)
                                ->where('product_id', $product->id)
                                ->selectRaw('COUNT(*) as rating_count, AVG(rate) as avg_rating')
                                ->first();

                            $productsData[] = [
                                'product_id' => $product->id,
                                'product_name' => $product->name,
                                'product_image' => $product->image_url ?? null,
                                'variant_id' => $customProduct->variant_id,
                                'variant_measurement' => $variant->measurement ?? null,
                                'variant_unit' => $variant->unit->short_code ?? null,
                                'variant_stock' => $variant->stock ?? 0,
                                'price' => $price,
                                'actual_price' => $actualPrice,
                                'quantity' => $customProduct->quantity,
                                'rating' => round($productRatingData->avg_rating ?? 0, 1),
                                'rating_count' => (int) ($productRatingData->rating_count ?? 0),
                                'currency' => $currency,
                                'images' => $product->images->map(function ($image) {
                                    return [
                                        'id' => $image->id,
                                        'image_url' => $image->image ? (str_starts_with($image->image, 'http') ? $image->image : asset('storage/' . $image->image)) : null,
                                    ];
                                }),
                                'variants' => $product->variants->map(function ($variantItem) use ($currency) {
                                    return [
                                        'id' => $variantItem->id,
                                        'measurement' => $variantItem->measurement ?? null,
                                        'unit' => $variantItem->unit->short_code ?? null,
                                        'stock' => $variantItem->stock ?? 0,
                                        'price' => $variantItem->discounted_price > 0 ? $variantItem->discounted_price : $variantItem->price,
                                        'actual_price' => $variantItem->price ?? 0,
                                        'discounted_price' => $variantItem->discounted_price ?? 0,
                                        'currency' => $currency,
                                    ];
                                }),
                            ];
                        }
                    }

                    $total_combo_price += $totalProductPrice; // Selling price
                    $total_combo_mrp += $totalActualPrice; // MRP price

                    // Calculate savings from this combo (MRP - selling price)
                    $comboSavings = $totalActualPrice - $totalProductPrice;
                    if ($comboSavings > 0) {
                        $total_combo_savings += $comboSavings;
                    }

                    // Only build full combo data if not in checkout mode
                    if ($request->is_checkout != 1) {
                        $discountPercentage = $totalActualPrice > 0
                            ? round((($totalActualPrice - $totalProductPrice) / $totalActualPrice) * 100, 2)
                            : 0;

                        // Get combo rating
                        $comboRatingData = DB::table('product_ratings')
                            ->where('is_combo', 1)
                            ->where('product_id', $combo->id)
                            ->selectRaw('COUNT(*) as rating_count, AVG(rate) as avg_rating')
                            ->first();

                        $customCombos[] = [
                            'combo_custom_cart_id' => $customCart->id,
                            'combo_id' => $combo->id,
                            'combo_name' => $combo->name,
                            'combo_description' => $combo->description,
                            'combo_image_url' => $combo->image ? (str_starts_with($combo->image, 'http') ? $combo->image : asset('storage/' . $combo->image)) : null,
                            'combo_type' => $combo->type,
                            'product_count' => count($productsData),
                            'total_products_price' => $totalProductPrice,
                            'total_actual_price' => $totalActualPrice,
                            'discount_percentage' => $discountPercentage,
                            'rating' => round($comboRatingData->avg_rating ?? 0, 1),
                            'rating_count' => (int) ($comboRatingData->rating_count ?? 0),
                            'currency' => $currency,
                            'products' => $productsData,
                        ];
                    }
                }

                // Add combo MRP to subtotal (show original prices)
                $sub_total += $total_combo_mrp;

                // Add combo savings to total saved amount
                $saved_amount += $total_combo_savings;

                // If in checkout mode, add combo MRP and subtract combo savings
                if (isset($request->is_checkout) && $request->is_checkout == 1 && isset($response['total_amount'])) {
                    $response['total_amount'] += $total_combo_mrp; // Add MRP
                    $response['total_amount'] -= $total_combo_savings; // Subtract discount
                }

                $user_balance = CommonHelper::getUserWalletBalance($user_id);

                $response['user_balance'] = $user_balance;
                $response['sub_total'] = $sub_total;
                $response['saved_amount'] = $saved_amount;
                $response['combo_total'] = $total_combo_price;
                $response['combo_savings'] = $total_combo_savings;

                if ($request->is_checkout != 1) {
                    // $response['cart'] = $res;
                    $response['grouped_by_seller'] = $grouped_by_seller;
                    $response['admin_managed_store'] = [
                        'items' => $admin_managed_store_items
                    ];

                    $response['save_for_later'] = $result;
                    $response['custom_combos'] = $customCombos;

                    $global_self_pickup_mode = Setting::where('variable', 'self_pickup_mode')->value('value') ?? 0;

                    $seller_self_pickup_mode = 0;
                    if (!empty($res)) {
                        $cartItems = Cart::select('carts.*', 'products.seller_id', 'sellers.self_pickup_mode')
                            ->join('products', 'carts.product_id', '=', 'products.id')
                            ->leftJoin('sellers', 'products.seller_id', '=', 'sellers.id')
                            ->where('carts.save_for_later', '=', 0)
                            ->where('user_id', '=', $user_id)
                            ->first();

                        if ($cartItems && $cartItems->self_pickup_mode) {
                            $seller_self_pickup_mode = $cartItems->self_pickup_mode;
                        }
                    }

                    $response['self_pickup_mode'] = ($global_self_pickup_mode == 1 && $seller_self_pickup_mode == 1) ? 1 : 0;
                }

                $additionalChargesSetting = Setting::where('variable', 'additional_charges')->first();
                $additional_charges = [];
                $additional_charges_total = 0;
                if ($additionalChargesSetting && $additionalChargesSetting->value) {
                    $additional_charges = json_decode($additionalChargesSetting->value, true) ?: [];
                    foreach ($additional_charges as $charge) {
                        $amount = isset($charge['amount']) ? floatval($charge['amount']) : 0;
                        $additional_charges_total += $amount;
                    }
                }

                // Check free delivery eligibility
                $free_delivery_order_amount = floatval(Setting::get_value('free_delivery_order_amount') ?? 0);
                $is_free_delivery = ($free_delivery_order_amount > 0 && $sub_total >= $free_delivery_order_amount);
                $actual_delivery_charge = isset($data['data']['total_delivery_charge']) ? floatval($data['data']['total_delivery_charge']) : 0;

                // If free delivery, remove delivery charge from total_amount
                if ($is_free_delivery && isset($response['total_amount'])) {
                    $response['total_amount'] -= $actual_delivery_charge;
                }

                // Add to total_amount if it exists
                if (isset($response['total_amount'])) {
                    $response['total_amount'] += $additional_charges_total;
                }
                $response['additional_charges'] = $additional_charges;

                // Build comprehensive billing breakdown
                $currency = Setting::get_value('currency') ?? '$';
                $billing_breakdown = [];

                // Reuse cart metadata if already loaded, otherwise fetch it
                if (!isset($cartMetadataForTip)) {
                    $cartMetadataForTip = \App\Models\CartMetadata::where('user_id', $user_id)->first();
                }

                // Step 4: Check and fetch promo code (will be validated after to_be_paid is calculated)
                $promocode_id = $request->promocode_id ?? null;

                // If no promo code in request, fetch from saved cart metadata
                if (!$promocode_id && $cartMetadataForTip && $cartMetadataForTip->promocode_id) {
                    $promocode_id = $cartMetadataForTip->promocode_id;
                }

                // Validate promo code if present
                if ($promocode_id && $promocode_id != "") {
                    $promocode_details = CommonHelper::getValidatedPromoCode($promocode_id, $sub_total, $user_id);
                    $response['promocode_details'] = $promocode_details;
                }

                // Step 5: Check and fetch wallet amount flag (supports both 'wallet_amount' and 'use_wallet' param names)
                $use_wallet_amount = $request->has('wallet_amount') ? (bool) $request->wallet_amount : ($request->has('use_wallet') ? (bool) $request->use_wallet : null);

                // If no wallet flag in request, fetch from saved cart metadata
                if ($use_wallet_amount === null) {
                    if ($cartMetadataForTip && $cartMetadataForTip->wallet_amount) {
                        $use_wallet_amount = true;
                    } else {
                        $use_wallet_amount = false;
                    }
                }

                // How much of the balance the customer chose to apply. NULL means
                // "as much as needed", which is the default whole-balance behaviour.
                $requested_wallet_amount = null;
                if ($request->has('wallet_amount_value') && is_numeric($request->wallet_amount_value)) {
                    $requested_wallet_amount = (float) $request->wallet_amount_value;
                } elseif ($cartMetadataForTip && $cartMetadataForTip->wallet_amount_value !== null) {
                    $requested_wallet_amount = (float) $cartMetadataForTip->wallet_amount_value;
                }

                // A requested amount of 0 or less means nothing to apply.
                if ($requested_wallet_amount !== null && $requested_wallet_amount <= 0) {
                    $requested_wallet_amount = null;
                    $use_wallet_amount = false;
                }

                $delivery_tip = 0;
                if ($cartMetadataForTip && $cartMetadataForTip->delivery_tip > 0) {
                    $delivery_tip = $cartMetadataForTip->delivery_tip;
                }
                // Override with request delivery_tip if provided
                if ($request->has('delivery_tip')) {
                    $delivery_tip = $request->delivery_tip;
                }

                // 1. Items Subtotal (MRP price - without combos)
                $items_only_mrp = $sub_total - $total_combo_mrp;

                // Read platform fees configured in admin Store Settings
                $customer_gst_percent = floatval(
                    DB::table('settings')->where('variable', 'customer_gst')->value('value') ?? 0
                );
                $payment_gateway_fees_percent = floatval(
                    DB::table('settings')->where('variable', 'payment_gateway_fees')->value('value') ?? 0
                );
                // Gateway fees only apply when an online payment method is
                // explicitly selected. On cart load (no payment_method) and
                // for COD, the fee is not charged or shown.
                $selected_payment_method = strtoupper((string) $request->input('payment_method', ''));
                $online_payment_methods = ['PAYTM', 'RAZORPAY', 'PHONEPE', 'STRIPE', 'PAYPAL', 'PAYSTACK', 'CASHFREE', 'PAYTABS', 'MIDTRANS'];
                $is_online_payment = in_array($selected_payment_method, $online_payment_methods, true);
                if (!$is_online_payment) {
                    $payment_gateway_fees_percent = 0;
                }
                // Charges are computed on items+combos net of item-level discounts
                $taxable_amount = max(0, $sub_total - $saved_amount);
                $customer_gst_amount = round(($taxable_amount * $customer_gst_percent) / 100, 2);
                $payment_gateway_fees_amount = round(($taxable_amount * $payment_gateway_fees_percent) / 100, 2);
                // $billing_breakdown[] = [
                //     'type' => 'items_subtotal',
                //     'label' => 'Items Subtotal',
                //     'description' => 'Total MRP of all items in cart',
                //     'amount' => CommonHelper::doubleNumber($items_only_mrp),
                //     'currency' => $currency,
                //     'is_credit' => false
                // ];

                // // 1b. Total Discount (items + combos combined)
                // if ($saved_amount > 0) {
                //     $billing_breakdown[] = [
                //         'type' => 'discount',
                //         'label' => 'Discount',
                //         'description' => 'Total discount on items and combos',
                //         'amount' => CommonHelper::doubleNumber($saved_amount),
                //         'currency' => $currency,
                //         'is_credit' => true
                //     ];
                // }

                // // 1c. Combos Subtotal (MRP price, if any)
                // if ($total_combo_mrp > 0) {
                //     $billing_breakdown[] = [
                //         'type' => 'combo_subtotal',
                //         'label' => 'Combos',
                //         'description' => 'Custom combo meals MRP total',
                //         'amount' => CommonHelper::doubleNumber($total_combo_mrp),
                //         'currency' => $currency,
                //         'is_credit' => false
                //     ];
                // }

                // 1. Merged Items + Combos Subtotal (MRP price)
                $billing_breakdown[] = [
                    'type' => 'items_subtotal',
                    'label' => 'Items Subtotal',
                    'description' => 'Total MRP of all items and combos in cart',
                    'amount' => CommonHelper::doubleNumber($sub_total),
                    'currency' => $currency,
                    'is_credit' => false
                ];

                // 1b. Total Discount (items + combos combined)
                if ($saved_amount > 0) {
                    $billing_breakdown[] = [
                        'type' => 'discount',
                        'label' => 'Discount',
                        'description' => 'Total discount on items and combos',
                        'amount' => CommonHelper::doubleNumber($saved_amount),
                        'currency' => $currency,
                        'is_credit' => true
                    ];
                }

                // 2. Delivery Fee (if checkout and delivery charge exists)
                if (isset($request->is_checkout) && $request->is_checkout == 1 && isset($data['data']['delivery_charge_details'])) {
                    foreach ($data['data']['delivery_charge_details'] as $deliveryDetail) {
                        // Extract numeric distance value (handle both numeric and text format like "5.2 km")
                        $distance_value = isset($deliveryDetail['distance']) ? $deliveryDetail['distance'] : 0;
                        if (is_string($distance_value)) {
                            // Extract number from text like "5.2 km"
                            preg_match('/[\d.]+/', $distance_value, $matches);
                            $distance_km = isset($matches[0]) ? round($matches[0], 1) : 0;
                        } else {
                            $distance_km = round($distance_value, 1);
                        }

                        $deliveryLabel = 'Delivery charge (' . $distance_km . ' kms)';
                        if ($is_free_delivery) {
                            $deliveryLabel = 'Delivery charge: 0';
                        }
                        $deliveryFeeEntry = [
                            'type' => 'delivery_fee',
                            'label' => $deliveryLabel,
                            'description' => isset($deliveryDetail['seller_name'])
                                ? 'Delivery from ' . $deliveryDetail['seller_name']
                                : 'Delivery charge for your order',
                            'amount' => CommonHelper::doubleNumber($deliveryDetail['delivery_charge'] ?? 0),
                            'currency' => $currency,
                            'distance_km' => $distance_km,
                            'seller_id' => $deliveryDetail['seller_id'] ?? null,
                            'seller_name' => $deliveryDetail['seller_name'] ?? null,
                            'is_credit' => false
                        ];

                        if ($is_free_delivery) {
                            $deliveryFeeEntry['is_free'] = true;
                            $deliveryFeeEntry['free_delivery_message'] = 'Free delivery on orders above ' . $currency . CommonHelper::doubleNumber($free_delivery_order_amount);
                        }

                        $billing_breakdown[] = $deliveryFeeEntry;
                    }
                }

                // 3. Delivery Tip (from cart metadata or request)
                $billing_breakdown[] = [
                    'type' => 'delivery_tip',
                    'label' => 'Delivery Tip',
                    'description' => 'Tip for delivery partner',
                    'amount' => CommonHelper::doubleNumber($delivery_tip),
                    'currency' => $currency,
                    'is_credit' => false
                ];

                // 4. Customer GST (from admin Store Settings)
                $gst_amount = $customer_gst_amount; // Keep $gst_amount for downstream summary usage
                if ($customer_gst_percent > 0) {
                    $billing_breakdown[] = [
                        'type' => 'gst_charges',
                        'label' => 'GST (' . CommonHelper::doubleNumber($customer_gst_percent) . '%)',
                        'description' => 'Goods and Services Tax',
                        'amount' => CommonHelper::doubleNumber($customer_gst_amount),
                        'currency' => $currency,
                        'tax_percentage' => $customer_gst_percent,
                        'is_credit' => false
                    ];
                }

                // 4b. Payment Gateway Fees (from admin Store Settings)
                if ($payment_gateway_fees_percent > 0) {
                    $billing_breakdown[] = [
                        'type' => 'payment_gateway_fees',
                        'label' => 'Payment Gateway Fees (' . CommonHelper::doubleNumber($payment_gateway_fees_percent) . '%)',
                        'description' => 'Fee charged by the payment gateway',
                        'amount' => CommonHelper::doubleNumber($payment_gateway_fees_amount),
                        'currency' => $currency,
                        'fees_percentage' => $payment_gateway_fees_percent,
                        'is_credit' => false
                    ];
                }

                // 5. Additional Charges (platform fees, packaging, etc.)
                if (!empty($additional_charges)) {
                    foreach ($additional_charges as $charge) {
                        $billing_breakdown[] = [
                            'type' => 'additional_charge',
                            'label' => $charge['name'] ?? 'Additional Charge',
                            'description' => $charge['description'] ?? '',
                            'amount' => CommonHelper::doubleNumber($charge['amount'] ?? 0),
                            'currency' => $currency,
                            'is_credit' => false
                        ];
                    }
                }

                // 6. Promocode Discount (separate from item/combo discount)
                $discount_amount = 0;
                if (isset($response['promocode_details']['discount']) && $response['promocode_details']['discount'] > 0) {
                    $discount_amount = $response['promocode_details']['discount'];

                    // Build promo code description with details
                    $promoCode = $response['promocode_details']['promo_code'] ?? null;
                    $discountType = $response['promocode_details']['discount_type'] ?? null;
                    $discountValue = $response['promocode_details']['discount_value'] ?? null;

                    $descriptionParts = [];
                    if ($promoCode) {
                        $descriptionParts[] = "Code: {$promoCode}";
                    }
                    if ($discountType && $discountValue) {
                        if ($discountType === 'percentage') {
                            $descriptionParts[] = "{$discountValue}% off";
                        } else {
                            $descriptionParts[] = CommonHelper::doubleNumber($discountValue) . " discount";
                        }
                    }

                    $promoDescription = !empty($descriptionParts) ? implode(' - ', $descriptionParts) : 'Promotional discount';

                    $promoCodeEntry = [
                        'type' => 'promocode_discount',
                        'label' => 'Promo Code Discount',
                        'description' => $promoDescription,
                        'amount' => CommonHelper::doubleNumber($discount_amount),
                        'currency' => $currency,
                        'promo_code' => $promoCode,
                        'is_credit' => true
                    ];

                    // Add additional promo details if available
                    if ($discountType) {
                        $promoCodeEntry['discount_type'] = $discountType;
                    }
                    if ($discountValue) {
                        $promoCodeEntry['discount_value'] = $discountValue;
                    }

                    $billing_breakdown[] = $promoCodeEntry;

                    \Log::info('PromoCode: Added to billing breakdown', [
                        'user_id' => $user_id,
                        'promo_code' => $promoCode,
                        'discount_type' => $discountType,
                        'discount_value' => $discountValue,
                        'discount_amount' => $discount_amount,
                        'description' => $promoDescription
                    ]);
                }

                // 7b. Saved Amount section removed - discounts are now shown inline with items and combos

                // 7b. Calculate claimable milestone amount for the user
                $claimable_milestone_amount = 0;

                // Get the authenticated customer user ID
                $customer_user_id = $request->user('api-customers') ? $request->user('api-customers')->id : null;

                if ($customer_user_id) {
                    // Get completed orders count for this user
                    $completedOrdersCount = Order::where('user_id', $customer_user_id)
                        ->where('active_status', 6)
                        ->count();

                    // Get all active milestones
                    $allMilestones = UserOrderReward::where('status', 1)
                        ->orderBy('order_count', 'ASC')
                        ->get();

                    // Get already claimed milestone IDs for this user
                    $claimedMilestoneIds = CustomerClaimedMilestone::where('customer_id', $customer_user_id)
                        ->pluck('milestone_id')
                        ->toArray();

                    // Calculate total claimable amount
                    foreach ($allMilestones as $milestone) {
                        $isClaimed = in_array($milestone->id, $claimedMilestoneIds);
                        $isEligible = $completedOrdersCount >= $milestone->order_count;

                        // If eligible and not already claimed, add to claimable amount
                        if ($isEligible && !$isClaimed) {
                            $claimable_milestone_amount += $milestone->amount;
                        }
                    }
                }

                // 7c. Milestone Reward (if applicable)
                if ($claimable_milestone_amount > 0) {
                    $billing_breakdown[] = [
                        'type' => 'milestone_reward',
                        'label' => 'Milestone Reward',
                        'description' => "Reward for completing {$completedOrdersCount} order(s)",
                        'amount' => CommonHelper::doubleNumber($claimable_milestone_amount),
                        'currency' => $currency,
                        'is_credit' => true,
                        'completed_orders' => $completedOrdersCount
                    ];
                }

                // 8. To Be Paid / Total Amount (Sum of all charges minus discounts)
                // Calculate proper total even when not in checkout mode
                if (isset($response['total_amount'])) {
                    $to_be_paid = $response['total_amount'];

                    // Add Customer GST and Payment Gateway Fees from admin Store Settings
                    $to_be_paid += $customer_gst_amount + $payment_gateway_fees_amount;

                    // Subtract promocode discount if available
                    if (isset($response['promocode_details']['discount']) && $response['promocode_details']['discount'] > 0) {
                        $promo_discount_amount = $response['promocode_details']['discount'];
                        $to_be_paid -= $promo_discount_amount;
                        \Log::info('PromoCode: Applied to final amount (checkout mode)', [
                            'user_id' => $user_id,
                            'promo_code' => $response['promocode_details']['promo_code'] ?? null,
                            'discount_amount' => $promo_discount_amount,
                            'total_before_discount' => $to_be_paid + $promo_discount_amount,
                            'total_after_discount' => $to_be_paid
                        ]);
                    }

                    // Subtract claimable milestone amount if applicable
                    if ($claimable_milestone_amount > 0) {
                        $to_be_paid -= $claimable_milestone_amount;
                    }

                    // Apply wallet amount during checkout.
                    // The wallet covers the whole payable amount (GST, delivery,
                    // tip and additional charges included), capped at the balance.
                    if ($use_wallet_amount) {
                        $user = \App\Models\User::find($user_id);
                        $wallet_balance = $user ? $user->balance : 0;
                        $wallet_deduction = min($wallet_balance, $to_be_paid);
                        if ($requested_wallet_amount !== null) {
                            $wallet_deduction = min($wallet_deduction, $requested_wallet_amount);
                        }
                        if ($wallet_deduction > 0) {
                            $to_be_paid -= $wallet_deduction;
                            $response['wallet_deduction'] = $wallet_deduction;
                        }
                    }
                } else {
                    // Calculate total: subtotal (MRP) - savings + delivery + tip + additional - promocode discount - milestone
                    $to_be_paid = $sub_total;

                    // Subtract items and combo savings/discounts
                    $to_be_paid -= $saved_amount;

                    // Add delivery charge if available (skip if free delivery)
                    if (!$is_free_delivery && isset($data['data']['total_delivery_charge'])) {
                        $to_be_paid += $data['data']['total_delivery_charge'];
                    }

                    // Add delivery tip
                    $to_be_paid += $delivery_tip;

                    // Add additional charges
                    $to_be_paid += $additional_charges_total;

                    // Add Customer GST and Payment Gateway Fees from admin Store Settings
                    $to_be_paid += $customer_gst_amount + $payment_gateway_fees_amount;

                    // Subtract promocode discount if available
                    if (isset($response['promocode_details']['discount']) && $response['promocode_details']['discount'] > 0) {
                        $promo_discount_amount = $response['promocode_details']['discount'];
                        $to_be_paid -= $promo_discount_amount;
                        \Log::info('PromoCode: Applied to final amount', [
                            'user_id' => $user_id,
                            'promo_code' => $response['promocode_details']['promo_code'] ?? null,
                            'discount_type' => $response['promocode_details']['discount_type'] ?? null,
                            'discount_value' => $response['promocode_details']['discount_value'] ?? null,
                            'discount_amount' => $promo_discount_amount,
                            'total_before_discount' => $to_be_paid + $promo_discount_amount,
                            'total_after_discount' => $to_be_paid
                        ]);
                    }

                    // Subtract claimable milestone amount if applicable.
                    // Applied before the wallet so the wallet only ever covers
                    // what is actually left to pay.
                    if ($claimable_milestone_amount > 0) {
                        $to_be_paid -= $claimable_milestone_amount;
                    }

                    // Apply wallet amount to the whole payable amount
                    // (items, delivery, tip, additional charges and GST)
                    if ($use_wallet_amount) {
                        // Get user's wallet balance
                        $user = \App\Models\User::find($user_id);
                        $wallet_balance = $user ? $user->balance : 0;

                        // Apply only up to what is still payable, and never more
                        // than the customer asked to spend
                        $wallet_deduction = min($wallet_balance, $to_be_paid);
                        if ($requested_wallet_amount !== null) {
                            $wallet_deduction = min($wallet_deduction, $requested_wallet_amount);
                        }

                        if ($wallet_deduction > 0) {
                            $to_be_paid -= $wallet_deduction;
                            $response['wallet_deduction'] = $wallet_deduction;
                        }
                    }
                }

                // Ensure to_be_paid doesn't go negative
                if ($to_be_paid < 0) {
                    $to_be_paid = 0;
                }

                // Add wallet deduction to billing breakdown if applied
                if (isset($response['wallet_deduction']) && $response['wallet_deduction'] > 0) {
                    $walletEntry = [
                        'type' => 'wallet_deduction',
                        'label' => 'Wallet Deduction',
                        'description' => 'Amount deducted from wallet',
                        'amount' => CommonHelper::doubleNumber($response['wallet_deduction']),
                        'currency' => $currency,
                        'is_credit' => true
                    ];

                    $billing_breakdown[] = $walletEntry;
                }

                // Build detailed breakdown description
                $breakdownParts = [];
                $breakdownParts[] = 'Items MRP (' . CommonHelper::doubleNumber($items_only_mrp) . ')';

                $items_savings = $saved_amount - $total_combo_savings;
                if ($items_savings > 0) {
                    $breakdownParts[] = 'Items Discount (-' . CommonHelper::doubleNumber($items_savings) . ')';
                }

                if ($total_combo_mrp > 0) {
                    $breakdownParts[] = 'Combos MRP (' . CommonHelper::doubleNumber($total_combo_mrp) . ')';
                }

                if ($total_combo_savings > 0) {
                    $breakdownParts[] = 'Combo Discount (-' . CommonHelper::doubleNumber($total_combo_savings) . ')';
                }

                if (isset($data['data']['total_delivery_charge']) && $data['data']['total_delivery_charge'] > 0) {
                    $breakdownParts[] = 'Delivery (' . CommonHelper::doubleNumber($data['data']['total_delivery_charge']) . ')';
                }

                if ($delivery_tip > 0) {
                    $breakdownParts[] = 'Tip (' . CommonHelper::doubleNumber($delivery_tip) . ')';
                }

                if ($additional_charges_total > 0) {
                    $breakdownParts[] = 'Additional Charges (' . CommonHelper::doubleNumber($additional_charges_total) . ')';
                }

                if ($customer_gst_amount > 0) {
                    $breakdownParts[] = 'GST ' . $customer_gst_percent . '% (' . CommonHelper::doubleNumber($customer_gst_amount) . ')';
                }

                if ($payment_gateway_fees_amount > 0) {
                    $breakdownParts[] = 'Gateway Fees ' . $payment_gateway_fees_percent . '% (' . CommonHelper::doubleNumber($payment_gateway_fees_amount) . ')';
                }

                if ($discount_amount > 0) {
                    $breakdownParts[] = 'Promocode (-' . CommonHelper::doubleNumber($discount_amount) . ')';
                }

                if (isset($response['wallet_deduction']) && $response['wallet_deduction'] > 0) {
                    $breakdownParts[] = 'Wallet (-' . CommonHelper::doubleNumber($response['wallet_deduction']) . ')';
                }

                if ($claimable_milestone_amount > 0) {
                    $breakdownParts[] = 'Milestone Reward (-' . CommonHelper::doubleNumber($claimable_milestone_amount) . ')';
                }

                $breakdownDescription = implode(' + ', $breakdownParts);


                $calculationSummary = [
                    'items_mrp' => CommonHelper::doubleNumber($items_only_mrp),
                    'combo_mrp' => CommonHelper::doubleNumber($total_combo_mrp),
                    'discount' => CommonHelper::doubleNumber($saved_amount),
                    'delivery_charge' => isset($data['data']['total_delivery_charge']) ? CommonHelper::doubleNumber($data['data']['total_delivery_charge']) : 0,
                    'delivery_tip' => CommonHelper::doubleNumber($delivery_tip),
                    'additional_charges' => CommonHelper::doubleNumber($additional_charges_total),
                    'customer_gst_percent' => $customer_gst_percent,
                    'customer_gst_amount' => CommonHelper::doubleNumber($customer_gst_amount),
                    'payment_gateway_fees_percent' => $payment_gateway_fees_percent,
                    'payment_gateway_fees_amount' => CommonHelper::doubleNumber($payment_gateway_fees_amount),
                    'promocode_discount' => CommonHelper::doubleNumber($discount_amount),
                    'wallet_deduction' => isset($response['wallet_deduction']) ? CommonHelper::doubleNumber($response['wallet_deduction']) : 0,
                    'wallet_amount_value' => $requested_wallet_amount !== null ? CommonHelper::doubleNumber($requested_wallet_amount) : null,
                    'claimable_milestone_amount' => CommonHelper::doubleNumber($claimable_milestone_amount),
                    'multi_order_charge' => CommonHelper::doubleNumber($multiOrderCharges),
                    'final_total' => ceil($to_be_paid)
                ];

                // Add promo code details to calculation summary if applied
                if ($discount_amount > 0 && isset($response['promocode_details'])) {
                    $calculationSummary['promo_code'] = $response['promocode_details']['promo_code'] ?? null;
                    $calculationSummary['promo_code_discount_type'] = $response['promocode_details']['discount_type'] ?? null;
                    $calculationSummary['promo_code_discount_value'] = $response['promocode_details']['discount_value'] ?? null;
                }

                $billing_breakdown[] = [
                    'type' => 'to_be_paid',
                    'label' => 'To Be Paid',
                    'description' => $breakdownDescription,
                    'amount' => ceil($to_be_paid),
                    'currency' => $currency,
                    'is_credit' => false,
                    'is_total' => true,
                    'calculation_summary' => $calculationSummary
                ];

                $response['billing_breakdown'] = $billing_breakdown;

                // Summary for quick reference
                $response['billing_summary'] = [
                    'items_mrp' => CommonHelper::doubleNumber($items_only_mrp),
                    'combo_mrp' => CommonHelper::doubleNumber($total_combo_mrp),
                    'discount' => CommonHelper::doubleNumber($saved_amount),
                    'delivery_charge' => CommonHelper::doubleNumber($actual_delivery_charge),
                    'is_free_delivery' => $is_free_delivery,
                    'free_delivery_order_amount' => CommonHelper::doubleNumber($free_delivery_order_amount),
                    'delivery_tip' => CommonHelper::doubleNumber($delivery_tip),
                    'gst_charges' => CommonHelper::doubleNumber($gst_amount),
                    'customer_gst_percent' => $customer_gst_percent,
                    'payment_gateway_fees' => CommonHelper::doubleNumber($payment_gateway_fees_amount),
                    'payment_gateway_fees_percent' => $payment_gateway_fees_percent,
                    'additional_charges' => CommonHelper::doubleNumber($additional_charges_total),
                    'promocode_discount' => CommonHelper::doubleNumber($discount_amount),
                    'promo_code' => $discount_amount > 0 ? ($response['promocode_details']['promo_code'] ?? null) : null,
                    'wallet_deduction' => isset($response['wallet_deduction']) ? CommonHelper::doubleNumber($response['wallet_deduction']) : 0,
                    'wallet_amount_value' => $requested_wallet_amount !== null ? CommonHelper::doubleNumber($requested_wallet_amount) : null,
                    'claimable_milestone_amount' => CommonHelper::doubleNumber($claimable_milestone_amount),
                    'total_savings' => CommonHelper::doubleNumber($saved_amount + ($is_free_delivery ? $actual_delivery_charge : 0)),
                    'to_be_paid' => ceil($to_be_paid),
                    'currency' => $currency,
                    'multi_order_charge' => CommonHelper::doubleNumber($multiOrderCharges),
                ];

                // Include cart metadata in response (reuse if already loaded)
                if (!isset($cartMetadataForTip)) {
                    $cartMetadataForTip = \App\Models\CartMetadata::where('user_id', $user_id)->first();
                }

                // Save or update billing breakdown and summary to cart_metadata table
                if ($cartMetadataForTip) {
                    $cartMetadataForTip->billing_breakdown = $billing_breakdown;
                    $cartMetadataForTip->billing_summary = $response['billing_summary'];
                    $cartMetadataForTip->save();
                } else {
                    // Create new cart metadata record with billing data
                    $cartMetadataForTip = \App\Models\CartMetadata::create([
                        'user_id' => $user_id,
                        'billing_breakdown' => $billing_breakdown,
                        'billing_summary' => $response['billing_summary'],
                    ]);
                }

                $response['cart_metadata'] = $cartMetadataForTip ? $cartMetadataForTip : [
                    'promocode_id' => null,
                    'delivery_tip' => 0,
                    'delivery_instructions' => null,
                    'contact_name' => null,
                    'contact_phone' => null,
                    'contact_email' => null,
                    'seller_notes' => [],
                    'combo_notes' => [],
                    'billing_breakdown' => [],
                    'billing_summary' => [],
                ];

                // Log cart metadata with promo code info
                if ($cartMetadataForTip) {
                    if ($cartMetadataForTip->promocode_id) {
                        \Log::info('PromoCode: Cart metadata contains saved promo code', [
                            'user_id' => $user_id,
                            'promocode_id' => $cartMetadataForTip->promocode_id,
                            'promo_code' => $cartMetadataForTip->promo_code,
                            'metadata_id' => $cartMetadataForTip->id,
                            'delivery_tip' => $cartMetadataForTip->delivery_tip,
                            'has_billing_breakdown' => !empty($cartMetadataForTip->billing_breakdown),
                            'has_billing_summary' => !empty($cartMetadataForTip->billing_summary)
                        ]);
                    } else {
                        \Log::info('PromoCode: Cart metadata loaded - no promo code', [
                            'user_id' => $user_id,
                            'metadata_id' => $cartMetadataForTip->id,
                            'delivery_tip' => $cartMetadataForTip->delivery_tip
                        ]);
                    }
                } else {
                    \Log::info('PromoCode: No cart metadata found for user', [
                        'user_id' => $user_id
                    ]);
                }

                try {
                    // Get customer's default address for consistent lat/lon usage
                    $customerDefaultAddress = DB::table('user_addresses')
                        ->where('user_id', $user_id)
                        ->where('is_default', 1)
                        ->first();
                    $customerLat = floatval($customerDefaultAddress->latitude ?? 0);
                    $customerLon = floatval($customerDefaultAddress->longitude ?? 0);

                    $serviceChargeData = CartStoreIdsService::getCartStoreIds($user_id);
                    $serviceDeliveryCharge = $serviceChargeData['delivery_charge'] ?? 0;
                    $totalDistance = $serviceChargeData['total_distance'] ?? 0;

                    $order_amount_for_free_delivery = DB::table('settings')->where('variable', 'order_amount_for_free_delivery')->value('value');

                    // If order amount meets free delivery threshold, set delivery charge to 0
                    $currentTotal = $response['billing_summary']['to_be_paid'];

                    // dd($currentTotal);


                    // Determine if free delivery is unlocked
                    $isFreeUnlocked = $is_free_delivery || ($order_amount_for_free_delivery && $currentTotal >= floatval($order_amount_for_free_delivery));

                    $serviceDeliveryLabel = 'Delivery Charge (' . $totalDistance . ' kms)';
                    if ($isFreeUnlocked) {
                        $serviceDeliveryLabel = 'Delivery Charge: 0';
                    }

                    // Add delivery_charge entry to billing_breakdown (before to_be_paid)
                    $deliveryChargeEntry = [
                        'type' => 'delivery_charge',
                        'label' => $serviceDeliveryLabel,
                        'description' => 'Delivery charge for your order',
                        'amount' => CommonHelper::doubleNumber($serviceDeliveryCharge),
                        'currency' => $currency,
                        'is_credit' => false
                    ];

                    // threshold amount should use the same variable as the main logic ($is_free_delivery)
                    $thresholdAmount = $free_delivery_order_amount > 0 ? $free_delivery_order_amount : floatval($order_amount_for_free_delivery ?? 0);
                    $freeDeliveryThresholdEntry = null;
                    if ($thresholdAmount > 0) {
                        $freeDeliveryThresholdEntry = [
                            'type' => 'free_delivery_threshold',
                            'label' => $isFreeUnlocked ? 'FREE delivery unlocked!' : 'Add ' . $currency . CommonHelper::doubleNumber($thresholdAmount - $sub_total) . ' more for free delivery',
                            'description' => 'Shop for more than ' . $currency . CommonHelper::doubleNumber($thresholdAmount),
                            'amount' => 0,
                            'currency' => $currency,
                            'is_free' => $isFreeUnlocked,
                            'is_credit' => false,
                            'value_text' => 'FREE'
                        ];
                    }

                    // Check rain surcharge using customer's default address coordinates
                    $rainSurchargeAmount = 0;
                    $rainSurchargeLabel = null;
                    $rainSurchargeApplicable = false;
                    if ($customerLat && $customerLon) {
                        $rainSurcharge = WeatherService::getRainSurcharge(
                            $customerLat,
                            $customerLon,
                            $serviceDeliveryCharge
                        );
                        $rainSurchargeAmount = $rainSurcharge['applicable'] ? $rainSurcharge['surcharge'] : 0;
                        $rainSurchargeLabel = $rainSurcharge['label'] ?? 'Rain Surcharge';
                        $rainSurchargeApplicable = $rainSurcharge['applicable'];
                    }

                    $rainSurchargeEntry = [
                        'type' => 'rain_surcharge',
                        'label' => $rainSurchargeLabel ?? 'Rain Surcharge',
                        'description' => $rainSurchargeApplicable ? 'Extra charge due to rainy weather' : 'No rain surcharge',
                        'amount' => CommonHelper::doubleNumber($rainSurchargeAmount),
                        'currency' => $currency,
                        'is_credit' => false,
                        'applicable' => $rainSurchargeApplicable
                    ];

                    // Get multi-order charges using the new service
                    $multiOrderCharges = MultiOrderChargesService::getMultiOrderCharges($user_id);


                    // $hasMultiOrder = MultiOrderChargesService::hasMultiOrderScenario($user_id);
                    $hasMultiOrder = MultiOrderChargesService::hasMultiOrderScenario($user_id);

                    // dd($hasMultiOrder);

                    // Add multi_order_charges entry to billing_breakdown (before to_be_paid)
                    $multiOrderChargeEntry = [
                        'type' => 'multi_order_charge',
                        'label' => 'Multi Order Charge',
                        'description' => $hasMultiOrder ? 'Additional charge for multi-store order' : 'Single store Order No Additional charge',
                        'amount' => CommonHelper::doubleNumber($multiOrderCharges),
                        'currency' => $currency,
                        'is_credit' => false,
                        'has_multi_order' => $hasMultiOrder
                    ];

                    // Find the index of to_be_paid and insert delivery_charge and multi_order_charge before it
                    $updatedBreakdown = [];
                    foreach ($response['billing_breakdown'] as $breakdown) {
                        if ($breakdown['type'] === 'to_be_paid') {
                            // Add delivery charge entry before to_be_paid (only if not free)
                            if (!$isFreeUnlocked) {
                                $updatedBreakdown[] = $deliveryChargeEntry;
                            }

                            // Add free delivery threshold entry if available
                            if ($freeDeliveryThresholdEntry) {
                                $updatedBreakdown[] = $freeDeliveryThresholdEntry;
                            }

                            // Add rain surcharge entry before to_be_paid (only if applicable)
                            if ($rainSurchargeApplicable) {
                                $updatedBreakdown[] = $rainSurchargeEntry;
                            }

                            // Add multi order charge entry before to_be_paid
                            $updatedBreakdown[] = $multiOrderChargeEntry;

                            // Update to_be_paid calculation_summary and amount
                            $breakdown['calculation_summary']['delivery_charge'] = CommonHelper::doubleNumber($serviceDeliveryCharge);
                            $breakdown['calculation_summary']['rain_surcharge'] = CommonHelper::doubleNumber($rainSurchargeAmount);
                            $breakdown['calculation_summary']['multi_order_charges'] = CommonHelper::doubleNumber($multiOrderCharges);

                            $deliveryChargeForTotal = $isFreeUnlocked ? 0 : $serviceDeliveryCharge;

                            $breakdown['calculation_summary']['final_total'] = CommonHelper::doubleNumber(
                                $breakdown['calculation_summary']['final_total'] + $deliveryChargeForTotal + $rainSurchargeAmount + $multiOrderCharges
                            );
                            $breakdown['amount'] = CommonHelper::doubleNumber($breakdown['amount'] + $deliveryChargeForTotal + $rainSurchargeAmount + $multiOrderCharges);

                            // Update description to include delivery charge and multi-order charges
                            $descriptionParts = explode(' + ', $breakdown['description']);

                            // Add delivery charge if not zero and not free
                            if ($deliveryChargeForTotal > 0) {
                                $descriptionParts[] = 'Delivery (' . CommonHelper::doubleNumber($deliveryChargeForTotal) . ')';
                            }

                            // Add rain surcharge if applicable
                            if ($rainSurchargeAmount > 0) {
                                $descriptionParts[] = $rainSurchargeLabel . ' (' . CommonHelper::doubleNumber($rainSurchargeAmount) . ')';
                            }

                            // Add multi-order charges if not zero
                            if ($multiOrderCharges > 0) {
                                $descriptionParts[] = 'Multi Order Charge (' . CommonHelper::doubleNumber($multiOrderCharges) . ')';
                            }

                            $breakdown['description'] = implode(' + ', $descriptionParts);
                        }
                        $updatedBreakdown[] = $breakdown;
                    }
                    $response['billing_breakdown'] = $updatedBreakdown;

                    // Update delivery_charge, rain_surcharge, and multi_order_charges in billing_summary
                    $response['billing_summary']['delivery_charge'] = CommonHelper::doubleNumber($serviceDeliveryCharge);
                    $response['billing_summary']['rain_surcharge'] = CommonHelper::doubleNumber($rainSurchargeAmount);
                    $response['billing_summary']['rain_surcharge_applicable'] = $rainSurchargeApplicable;
                    $response['billing_summary']['multi_order_charges'] = CommonHelper::doubleNumber($multiOrderCharges);
                    $response['billing_summary']['is_free_delivery'] = $isFreeUnlocked;
                    $response['billing_summary']['total_savings'] = CommonHelper::doubleNumber(
                        $response['billing_summary']['discount'] + ($isFreeUnlocked ? $serviceDeliveryCharge : 0)
                    );

                    $deliveryChargeForTotal = $isFreeUnlocked ? 0 : $serviceDeliveryCharge;
                    $response['billing_summary']['to_be_paid'] = ceil(
                        $response['billing_summary']['to_be_paid'] + $deliveryChargeForTotal + $rainSurchargeAmount + $multiOrderCharges
                    );

                    // Update cart_metadata billing data and add multi_order_charges
                    if ($cartMetadataForTip) {
                        $cartMetadataForTip->billing_breakdown = $response['billing_breakdown'];
                        $cartMetadataForTip->billing_summary = $response['billing_summary'];
                        $cartMetadataForTip->multi_order_charges = $multiOrderCharges;
                        $cartMetadataForTip->has_multi_order = $hasMultiOrder;
                        $cartMetadataForTip->save();
                        $response['cart_metadata'] = $cartMetadataForTip;
                    }

                } catch (\Throwable $e) {
                    \Log::error('Delivery charge service failed', [
                        'user_id' => $user_id,
                        'error' => $e->getMessage()
                    ]);
                }

                // Log wallet amount if applied
                if (isset($response['wallet_deduction']) && $response['wallet_deduction'] > 0) {
                    \Log::info('Wallet: Amount deducted from cart', [
                        'user_id' => $user_id,
                        'wallet_deduction' => $response['wallet_deduction'],
                        'to_be_paid' => $response['billing_summary']['to_be_paid'] ?? 0
                    ]);
                }

                return CommonHelper::responseWithData($response, $total->cart_items_count);
            } else {
                return CommonHelper::responseError('no_items_found_in_users_cart');
            }
        } else {
            return CommonHelper::responseError('no_items_found_in_users_cart');
        }
    }

    public function addToCart(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'product_id' => 'required',
            'product_variant_id' => 'required',
            'qty' => 'required|numeric|min:1',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $product_id = $request->product_id;
        $variant_id = $request->product_variant_id;
        $qty = $request->get('qty', '');
        $user = auth()->user();

        Log::info('[AddToCart] START', [
            'user_id' => $user->id,
            'product_id' => $product_id,
            'variant_id' => $variant_id,
            'qty' => $qty,
        ]);

        $one_seller_cart_exist = (int) Setting::where('variable', 'one_seller_cart')->exists();
        $one_seller_cart = ($one_seller_cart_exist = Setting::where('variable', 'one_seller_cart')->exists()) ? (int) Setting::where('variable', 'one_seller_cart')->value('value') : 0;

        // Check for super mart vs non-super mart products conflict
        $productToAdd = Product::with('store')->find($product_id);

        if (!$productToAdd) {
            Log::warning('[AddToCart] FAILED - product_not_found', ['product_id' => $product_id]);
            return CommonHelper::responseError('product_not_found');
        }

        Log::info('[AddToCart] Product found', [
            'product_id' => $productToAdd->id,
            'name' => $productToAdd->name,
            'is_unlimited_stock' => $productToAdd->is_unlimited_stock,
            'status' => $productToAdd->status,
            'is_approved' => $productToAdd->is_approved,
            'seller_id' => $productToAdd->seller_id,
        ]);

        $isSuperMartProduct = $productToAdd->store?->is_super_mart == 1;

        // Get existing cart items with store information
        $existingCartItems = Cart::select('carts.*', 'products.store_id', 'stores.is_super_mart')
            ->join('products', 'carts.product_id', '=', 'products.id')
            ->leftJoin('stores', 'products.store_id', '=', 'stores.id')
            ->where('carts.save_for_later', '=', 0)
            ->where('carts.user_id', '=', $user->id)
            ->get();

        if (!$existingCartItems->isEmpty()) {
            // Check if existing cart has super mart products
            $hasExistingSuperMart = $existingCartItems->contains(function ($item) {
                return $item->is_super_mart == 1;
            });

            $hasExistingNonSuperMart = $existingCartItems->contains(function ($item) {
                return $item->is_super_mart != 1;
            });

            // Prevent mixing super mart with non-super mart
            if ($isSuperMartProduct && $hasExistingNonSuperMart) {
                $data['super_mart_conflict'] = 1;
                $data['message'] = 'Cannot add super mart products. Please clear your cart to add super mart items.';
                return CommonHelper::responseErrorWithData('super_mart_product_conflict', $data);
            }

            if (!$isSuperMartProduct && $hasExistingSuperMart) {
                $data['super_mart_conflict'] = 1;
                $data['message'] = 'Cannot add regular products. Please clear your cart to add non-super mart items.';
                return CommonHelper::responseErrorWithData('super_mart_product_conflict', $data);
            }
        }

        // Check for pre-order items vs normal items conflict
        $isPreOrderProduct = $productToAdd->is_pre_order_item == 1;

        if (!$existingCartItems->isEmpty()) {
            // Check if existing cart has pre-order items
            $hasExistingPreOrderItems = $existingCartItems->contains(function ($item) {
                $product = Product::find($item->product_id);
                return $product && $product->is_pre_order_item == 1;
            });

            $hasExistingNormalItems = $existingCartItems->contains(function ($item) {
                $product = Product::find($item->product_id);
                return $product && $product->is_pre_order_item != 1;
            });

            // Prevent mixing pre-order items with normal items
            if ($isPreOrderProduct && $hasExistingNormalItems) {
                $data['pre_order_conflict'] = 1;
                $data['message'] = 'Cannot add pre-order items with regular products. Please clear your cart to add pre-order items.';
                return CommonHelper::responseErrorWithData('pre_order_product_conflict', $data);
            }

            if (!$isPreOrderProduct && $hasExistingPreOrderItems) {
                $data['pre_order_conflict'] = 1;
                $data['message'] = 'Cannot add regular products with pre-order items. Please clear your cart to add regular products.';
                return CommonHelper::responseErrorWithData('pre_order_product_conflict', $data);
            }
        }

        // Check if user has combos in cart - only prevent adding pre-order items (normal items are allowed)
        if ($isPreOrderProduct) {
            $hasExistingCombos = DB::table('combo_custom_cart')
                ->where('user_id', $user->id)
                ->where('is_ordered', 0)
                ->exists();

            if ($hasExistingCombos) {
                $data['combo_conflict'] = 1;
                $data['message'] = 'Cannot add pre-order items when combos are in your cart. Please clear your cart or complete your combo order first.';
                return CommonHelper::responseErrorWithData('combo_product_conflict', $data);
            }
        }

        if ($one_seller_cart == 1) {
            $cart = Cart::select('carts.*', 'products.seller_id')
                ->join('products', 'carts.product_id', '=', 'products.id')
                ->leftJoin('sellers', 'products.seller_id', '=', 'sellers.id')
                ->where('carts.save_for_later', '=', 0)
                ->where('user_id', '=', $user->id)
                ->get();

            $product = Product::find($product_id);

            if (!$product) {
                // Handle the case where the product with the specified product_id is not found
                return CommonHelper::responseError('product_not_found');
            }

            $seller_id = $product->seller_id;

            if (!$cart->isEmpty()) {
                $firstSeller = $cart->first()->seller_id;

                // Check if all sellers are the same
                $allSameSeller = $cart->every(function ($item) use ($firstSeller) {
                    return $item->seller_id === $firstSeller;
                });

                if ($allSameSeller) {
                    $commonSellerId = $firstSeller;


                    $commonSeller = Seller::find($commonSellerId);
                    if ($seller_id === $commonSellerId) {

                    } else {
                        // $seller_id does not match the common seller ID
                        $data['one_seller_error_code'] = 1;
                        return CommonHelper::responseErrorWithData('seller_id_does_not_match', $data);
                    }
                } else {
                    $data['one_seller_error_code'] = 1;
                    return CommonHelper::responseErrorWithData('all_cart_products_have_not_same_seller', $data);
                }
            }
        }


        $isAvailable = ProductHelper::isItemAvailable($product_id, $variant_id);
        Log::info('[AddToCart] isItemAvailable check', ['result' => $isAvailable]);

        if ($isAvailable) {
            $isStockOk = ProductHelper::isItemAvailableWithStock($product_id, $variant_id, $qty);
            Log::info('[AddToCart] isItemAvailableWithStock check', ['result' => $isStockOk]);

            if ($isStockOk) {

                $variant = ProductVariant::select('*', DB::raw("(SELECT is_unlimited_stock FROM products as p WHERE p.id = pv.product_id) as is_unlimited_stock"))
                    ->from('product_variants as pv')->where('id', $variant_id)->first();

                if ($variant) {
                    Log::info('[AddToCart] Variant found', [
                        'variant_id' => $variant->id,
                        'variant_stock' => $variant->stock,
                        'variant_status' => $variant->status,
                        'variant_is_unlimited_stock' => $variant->is_unlimited_stock,
                        'product_is_unlimited_stock' => $productToAdd->is_unlimited_stock,
                    ]);

                    $stockCheckPass = ($productToAdd->is_unlimited_stock == 1 || $variant->stock > 0) && $variant->status == 1;
                    Log::info('[AddToCart] Stock + status check', [
                        'is_unlimited_stock == 1' => $productToAdd->is_unlimited_stock == 1,
                        'variant_stock > 0' => $variant->stock > 0,
                        'variant_status == 1' => $variant->status == 1,
                        'final_result' => $stockCheckPass,
                    ]);

                    if ($stockCheckPass) {

                        if (ProductHelper::isItemAvailableInUserCart($user->id, $variant_id)) {
                            Log::info('[AddToCart] Item already in cart, updating qty');
                            $cart = Cart::where('user_id', $user->id)
                                ->where('product_variant_id', $variant_id)->first();

                            // check for total allowed quantity
                            $total_quantity = Cart::where('user_id', $user->id)
                                ->where('product_id', $product_id)
                                ->where('save_for_later', 0)
                                ->sum('qty');

                            if ($total_quantity && !$productToAdd->is_unlimited_stock) {
                                $total_allowed_quantity = Product::where('id', $product_id)->pluck('total_allowed_quantity')->first();

                                $temp = Cart::where('user_id', $user->id)->where('product_variant_id', $variant_id)->pluck('qty')->first();

                                $total_quantity = $total_quantity - $temp;
                                $total_quantity = $total_quantity + $qty;

                                if ($total_quantity > $total_allowed_quantity) {
                                    Log::warning('[AddToCart] FAILED - max qty limit reached', [
                                        'total_quantity' => $total_quantity,
                                        'total_allowed_quantity' => $total_allowed_quantity,
                                    ]);
                                    return CommonHelper::responseError('maximum_products_quantity_limit_reached_message');
                                }
                            }

                            if ($cart) {

                                $cart->qty = $qty;
                                $cart->save_for_later = 0;
                                $cart->save();

                                Log::info('[AddToCart] SUCCESS - cart updated', ['cart_id' => $cart->id, 'qty' => $qty]);
                                $total = CommonHelper::getCartCount($user->id);
                                $sub_total = $total->total_amount;
                                $saved_amount = $total->save_price - $total->total_amount;
                                $saved_amount = ($saved_amount <= 0) ? 0 : $saved_amount;
                                return Response::json(array('status' => 1, 'message' => 'item_updated_in_users_cart_successfully', 'cart_items_count' => $total->cart_items_count, 'cart_total_qty' => $total->cart_total_qty, 'sub_total' => $sub_total, 'saved_amount' => $saved_amount));


                            } else {
                                Log::warning('[AddToCart] FAILED - item_not_found in cart after isItemAvailableInUserCart=true');
                                return CommonHelper::responseError('item_not_found');
                            }

                        } else {
                            Log::info('[AddToCart] New item, adding to cart');

                            if ($user->status == 1) {

                                if (!$productToAdd->is_unlimited_stock) {
                                    $total_allowed_quantity = Product::where('id', $product_id)->pluck('total_allowed_quantity')->first();
                                    if ($total_allowed_quantity && $qty > $total_allowed_quantity) {
                                        Log::warning('[AddToCart] FAILED - max qty limit on new add', [
                                            'qty' => $qty,
                                            'total_allowed_quantity' => $total_allowed_quantity,
                                        ]);
                                        return CommonHelper::responseError('maximum_products_quantity_limit_reached_message');
                                    }
                                }

                                /* if item not found in user's cart add it */
                                $data = array(
                                    'user_id' => $user->id,
                                    'product_id' => $product_id,
                                    'product_variant_id' => $variant_id,
                                    'qty' => $qty,
                                    'created_at' => date('Y-m-d H:i:s')
                                );
                                $insert = Cart::insert($data);
                                if ($insert) {
                                    Log::info('[AddToCart] SUCCESS - item added to cart', ['product_id' => $product_id, 'variant_id' => $variant_id, 'qty' => $qty]);
                                    $total = CommonHelper::getCartCount($user->id);
                                    $sub_total = $total->total_amount;
                                    $saved_amount = $total->save_price - $total->total_amount;
                                    $saved_amount = ($saved_amount <= 0) ? 0 : $saved_amount;
                                    return Response::json(array('status' => 1, 'message' => 'item_added_to_users_cart_successfully', 'cart_items_count' => $total->cart_items_count, 'cart_total_qty' => $total->cart_total_qty, 'sub_total' => $sub_total, 'saved_amount' => $saved_amount));

                                } else {
                                    Log::error('[AddToCart] FAILED - Cart::insert failed', ['data' => $data]);
                                    return CommonHelper::responseError('something_went_wrong');
                                }
                            } else {
                                Log::warning('[AddToCart] FAILED - user account deactivated', ['user_id' => $user->id, 'user_status' => $user->status]);
                                return CommonHelper::responseError('not_allowed_to_add_to_cart_as_your_account_is_de_activated');
                            }
                        }

                    } else {
                        Log::warning('[AddToCart] FAILED - stock check failed at controller level', [
                            'product_id' => $product_id,
                            'variant_id' => $variant_id,
                            'is_unlimited_stock' => $productToAdd->is_unlimited_stock,
                            'variant_stock' => $variant->stock,
                            'variant_status' => $variant->status,
                        ]);
                        return CommonHelper::responseError('opps_stock_is_not_available');
                    }
                } else {
                    Log::warning('[AddToCart] FAILED - variant not found', ['variant_id' => $variant_id]);
                    return CommonHelper::responseError('no_such_item_available');
                }
            } else {
                Log::warning('[AddToCart] FAILED - isItemAvailableWithStock returned false', [
                    'product_id' => $product_id,
                    'variant_id' => $variant_id,
                    'qty' => $qty,
                ]);
                return CommonHelper::responseError('opps_stock_is_not_available');
            }
        } else {
            Log::warning('[AddToCart] FAILED - isItemAvailable returned false', [
                'product_id' => $product_id,
                'variant_id' => $variant_id,
            ]);
            return CommonHelper::responseError('no_such_item_available');
        }
    }



    public function removeFromCart(Request $request)
    {
        $user_id = auth()->user()->id;
        $variant_id = $request->get('product_variant_id', '');

        // For remove all, check if user has cart items OR combo items
        if (isset($request->is_remove_all) && $request->is_remove_all == 1) {
            $hasCartItems = Cart::where('user_id', $user_id)->where('save_for_later', 0)->exists();
            $hasComboItems = DB::table('combo_custom_cart')->where('user_id', $user_id)->exists();

            if ($hasCartItems || $hasComboItems) {
                // Remove regular cart items
                Cart::where('user_id', $user_id)->where('save_for_later', 0)->delete();

                // Remove custom combos
                $customCombos = DB::table('combo_custom_cart')
                    ->where('user_id', $user_id)
                    ->get();

                foreach ($customCombos as $customCombo) {
                    DB::table('combo_custom_products')
                        ->where('combo_custom_id', $customCombo->id)
                        ->delete();
                }

                DB::table('combo_custom_cart')
                    ->where('user_id', $user_id)
                    ->delete();

                // Delete cart metadata for this user
                \App\Models\CartMetadata::where('user_id', $user_id)->delete();

                return CommonHelper::responseSuccess('all_items_removed_from_users_cart_successfully');
            } else {
                return CommonHelper::responseError('no_items_found_in_users_cart');
            }
        }

        // For removing specific items by variant_id
        if (ProductHelper::isItemAvailableInUserCart($user_id, $variant_id)) {
            $cart = Cart::where('user_id', $user_id)->where('save_for_later', 0);

            if (!empty($variant_id)) {
                $cart->where('product_variant_id', $variant_id);
                $cart = $cart->delete();
                if ($cart) {
                    // If no cart items or combo items remain, delete cart metadata
                    $remainingCartItems = Cart::where('user_id', $user_id)->where('save_for_later', 0)->exists();
                    $remainingComboItems = DB::table('combo_custom_cart')->where('user_id', $user_id)->exists();

                    if (!$remainingCartItems && !$remainingComboItems) {
                        \App\Models\CartMetadata::where('user_id', $user_id)->delete();
                    }

                    $total = CommonHelper::getCartCount($user_id);
                    $sub_total = $total->total_amount;
                    $saved_amount = $total->save_price - $total->total_amount;
                    $saved_amount = ($saved_amount <= 0) ? 0 : $saved_amount;

                    return Response::json(array('status' => 1, 'message' => 'item_removed_from_users_cart_successfully', 'cart_items_count' => $total->cart_items_count, 'cart_total_qty' => $total->cart_total_qty, 'sub_total' => $sub_total, 'saved_amount' => $saved_amount));

                } else {
                    return CommonHelper::responseError('no_product_found');
                }
            } else {
                return CommonHelper::responseError('no_items_found_in_users_cart');
            }
        } else {
            return CommonHelper::responseError('no_items_found_in_users_cart');
        }

    }

    public function addToSaveForLater(Request $request)
    {

        $validator = Validator::make($request->all(), [
            'product_id' => 'required',
            'product_variant_id' => 'required',
            'qty' => 'required|numeric|min:1',
            'save_for_later' => 'required|numeric',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }


        $user_id = auth()->user()->id;
        $product_id = $request->product_id;
        $variant_id = $request->product_variant_id;

        $save_for_later = $request->save_for_later;

        $qty = $request->get('qty', '');

        $save_for_later = $request->save_for_later;

        if (!empty($user_id) && !empty($product_id)) {
            if (!empty($variant_id)) {
                if (ProductHelper::isItemAvailable($product_id, $variant_id)) {

                    if (ProductHelper::isItemAvailableInUserCart($user_id, $variant_id)) {
                        $cart = Cart::where('user_id', $user_id)->where('product_variant_id', $variant_id);
                        if (empty($qty) || $qty == 0) {
                            $cart = $cart->delete();
                            if ($cart) {
                                return CommonHelper::responseSuccess('item_removed_users_cart_due_to_0_quantity');
                            } else {
                                return CommonHelper::responseError('something_went_wrong');
                            }
                        }
                        /* if item found in user's cart update it */
                        $data = array(
                            'qty' => $qty,
                            'save_for_later' => $save_for_later
                        );
                        $cart = $cart->first();

                        $cart->save_for_later = $save_for_later;
                        $cart->qty = $qty;
                        $cart->save();
                    } else {
                        /* if item not found in user's cart add it */
                        $data = array(
                            'user_id' => $user_id,
                            'product_id' => $product_id,
                            'product_variant_id' => $variant_id,
                            'qty' => $qty,
                            'save_for_later' => $save_for_later
                        );
                        $cart = new Cart();
                        $cart->user_id = $user_id;
                        $cart->product_id = $product_id;
                        $cart->product_variant_id = $variant_id;
                        $cart->qty = $qty;
                        $cart->save_for_later = $save_for_later;
                        $cart->save();
                    }

                    if ($cart) {
                        $x = 0;
                        $total_amount = 0;
                        $result = Cart::with('images')->select('carts.*', 'products.image')
                            ->Join('products', 'carts.product_id', '=', 'products.id')
                            ->where('save_for_later', $save_for_later)->where('user_id', $user_id)->where('product_variant_id', $variant_id)->get();
                        $result = $result->makeHidden(['image', 'created_at', 'updated_at', 'deleted_at']);


                        $res1 = Cart::select('qty', 'product_variant_id')->where('save_for_later', $save_for_later)->where('user_id', $user_id)->get();
                        foreach ($res1 as $row1) {
                            $result1 = ProductVariant::select('price', 'discounted_price')->where('id', $row1->product_variant_id)->get();
                            $price = 0;
                            foreach ($result1 as $result2) {
                                $price = $result2->discounted_price == 0 ? $result2->price * $row1->qty : $result2->discounted_price * $row1->qty;
                            }
                            $total_amount += $price;
                        }

                        foreach ($result as $key => $rows) {
                            $item = ProductVariant::with('images')
                                ->select(
                                    'product_variants.*',
                                    'products.seller_id as seller_id',
                                    'products.name',
                                    'products.type as d_type',
                                    'products.cod_allowed',
                                    'products.slug',
                                    'products.image',
                                    'products.total_allowed_quantity',
                                    DB::raw('(CASE WHEN taxes.percentage != "0" THEN taxes.percentage ELSE "0" END) AS tax_percentage'),
                                    DB::raw('(CASE WHEN taxes.title != "" THEN taxes.title ELSE "" END) AS tax_title'),
                                    'product_variants.measurement',
                                    DB::raw('(select short_code from units where units.id = product_variants.stock_unit_id) AS stock_unit_name')
                                )
                                ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
                                ->leftJoin('taxes', 'products.tax_id', '=', 'taxes.id')
                                ->where('product_variants.id', '=', $rows->product_variant_id)
                                ->groupBy('product_variants.id')
                                ->orderBy('created_at', 'DESC')
                                ->first();
                            $item = $item->makeHidden(['image', 'created_at', 'updated_at', 'deleted_at']);
                            //$result[$x]->item = $item;
                            $result[$key]->type = $item->type;
                            $result[$key]->measurement = $item->measurement;


                            $taxed = ProductHelper::getTaxableAmount($item->id);

                            $result[$key]->discounted_price = CommonHelper::doubleNumber($taxed->taxable_discounted_price ?? $item->discounted_price);
                            $result[$key]->price = CommonHelper::doubleNumber($taxed->taxable_price ?? $item->price);
                            $result[$key]->taxable_amount = CommonHelper::doubleNumber($taxed->taxable_amount);

                            $result[$key]->stock = $item->stock;
                            $result[$key]->images = CommonHelper::getImages($rows->id, $rows->product_variant_id);
                            $result[$key]->total_allowed_quantity = $item->total_allowed_quantity;
                            $result[$key]->unit = $item->unit->short_code ?? '';

                            $x++;
                        }

                        $total = CommonHelper::getCartCount($user_id);
                        $sub_total = $total->total_amount;
                        $saved_amount = $total->save_price - $total->total_amount;
                        $saved_amount = ($saved_amount <= 0) ? 0 : $saved_amount;

                        if ($save_for_later == 1) {
                            return Response::json(array('status' => 1, 'message' => 'item_added_to_save_for_later_successfully', 'cart_items_count' => $total->cart_items_count, 'cart_total_qty' => $total->cart_total_qty, 'sub_total' => $sub_total, 'saved_amount' => $saved_amount, 'data' => $result));
                        } else {
                            return Response::json(array('status' => 1, 'message' => 'item_remove_from_save_for_later_successfully', 'cart_items_count' => $total->cart_items_count, 'cart_total_qty' => $total->cart_total_qty, 'sub_total' => $sub_total, 'saved_amount' => $saved_amount, 'data' => $result));
                        }

                    } else {
                        return CommonHelper::responseError('something_went_wrong');
                    }
                } else {
                    return CommonHelper::responseError('no_such_item_available');
                }
            } else {
                return CommonHelper::responseError('please_choose_at_least_one_item');
            }
        } else {
            return CommonHelper::responseError('please_pass_all_the_fields');
        }
    }
    public function getGuestCart(Request $request)
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

        $variant_id = explode(",", $request->variant_ids);
        $quantity = explode(",", $request->quantities);
        if (count($variant_id) === count($quantity)) {
            $res = ProductVariant::select(
                'product_variants.*',
                'products.slug',
                'products.name',
                'products.cod_allowed',
                'products.image',
                'products.is_unlimited_stock',
                'products.seller_id',
                'products.total_allowed_quantity',
                'sellers.longitude',
                'sellers.latitude',
                'cities.max_deliverable_distance',
                'cities.boundary_points',
                DB::raw('(CASE WHEN taxes.percentage != "0" THEN taxes.percentage ELSE "0" END) AS tax_percentage'),
                DB::raw('(CASE WHEN taxes.title != "" THEN taxes.title ELSE "" END) AS tax_title')
            )
                ->join('products', 'product_variants.product_id', '=', 'products.id')
                ->leftJoin('sellers', 'products.seller_id', '=', 'sellers.id')
                ->leftJoin('cities', 'sellers.city_id', '=', 'cities.id')
                ->leftJoin('taxes', 'products.tax_id', '=', 'taxes.id')
                ->whereIn('product_variants.id', $variant_id)
                ->get();

            $res = $res->makeHidden(['created_at', 'updated_at', 'boundary_points']);

            foreach ($res as $key => $row) {
                if (isset($row->max_deliverable_distance) && $row->max_deliverable_distance != 0 && $row->max_deliverable_distance != "") {
                    if (CommonHelper::isDeliverable($row->max_deliverable_distance, $row->longitude, $row->latitude, $request->longitude, $request->latitude)) {
                        $row['is_deliverable'] = 1;
                    } else {
                        $row['is_deliverable'] = 0;
                    }
                } else {
                    $row['is_deliverable'] = 0;
                }
                $row['image_url'] = $row['image'] ? (str_starts_with($row['image'], 'http') ? $row['image'] : asset('storage/' . $row['image'])) : '';
                $taxed = ProductHelper::getTaxableAmount($row->id);
                $row->discounted_price = CommonHelper::doubleNumber($taxed->taxable_discounted_price ?? $row->discounted_price);
                $row->price = CommonHelper::doubleNumber($taxed->taxable_price ?? $row->price);
                $row->taxable_amount = CommonHelper::doubleNumber($taxed->taxable_amount);

                $row->images = CommonHelper::getImages($row->id, $row->id);

                $row['unit_code'] = $row->unit->short_code ?? '';

                // Map the quantity to the variant
                $variantIndex = array_search($row->id, $variant_id);
                $row->qty = $quantity[$variantIndex] ?? 0;  // Default to 0 if quantity not found
                $row->product_variant_id = $row->id;  // Default to 0 if quantity not found

            }


            if (!empty($res)) {

                $total = CommonHelper::getGuestCartCount($variant_id, $quantity);
                $sub_total = $total['total_amount'];

                $saved_amount = $total['save_price'] - $total['total_amount'];
                $saved_amount = ($saved_amount <= 0) ? 0 : $saved_amount;

                $additionalChargesSetting = Setting::where('variable', 'additional_charges')->first();
                $additional_charges = [];
                $additional_charges_total = 0;
                if ($additionalChargesSetting && $additionalChargesSetting->value) {
                    $additional_charges = json_decode($additionalChargesSetting->value, true) ?: [];
                    foreach ($additional_charges as $charge) {
                        $amount = isset($charge['amount']) ? floatval($charge['amount']) : 0;
                        $additional_charges_total += $amount;
                    }
                }
                $response['additional_charges'] = $additional_charges;

                $response['sub_total'] = $sub_total;
                $response['saved_amount'] = $saved_amount;

                if ($request->is_checkout != 1) {
                    $response['cart'] = $res;
                    //$response['save_for_later'] = $result;
                }

                return CommonHelper::responseWithData($response, $total['cart_items_count']);
            } else {
                return CommonHelper::responseError('no_items_found_in_users_cart');
            }
        } else {
            return CommonHelper::responseError('variant_and_quantity_does_not_match');
        }

    }
    public function BulkAddToCartItems(Request $request)
    {

        $variant_ids = explode(",", $request->variant_ids);
        $quantities = explode(",", $request->quantities);
        $user = auth()->user();
        $one_seller_cart = Setting::where('variable', 'one_seller_cart')->exists() ? (int) Setting::where('variable', 'one_seller_cart')->value('value') : 0;
        //check all variants are same selelr or not
        if (isset($one_seller_cart) && $one_seller_cart == 1) {
            $sellerIds = ProductVariant::join('products', 'product_variants.product_id', '=', 'products.id')
                ->whereIn('product_variants.id', explode(",", $request->variant_ids))
                ->pluck('products.seller_id')
                ->unique();
            if ($sellerIds->count() > 1) {
                return CommonHelper::responseError('all_cart_products_have_not_same_seller');
            }
        }

        if (count($variant_ids) !== count($quantities)) {
            return CommonHelper::responseError('mismatched_variants_and_quantities');
        }

        $cartItems = Cart::select('carts.*', 'products.seller_id', 'products.category_id')
            ->join('products', function ($join) {
                $join->on('carts.product_id', '=', 'products.id')
                    ->where('products.status', 1)
                    ->where('products.is_approved', 1);
            })
            ->leftJoin('sellers', 'products.seller_id', '=', 'sellers.id')
            ->join('categories', function ($join) {
                $join->on('products.category_id', '=', 'categories.id')
                    ->where('categories.status', 1);
            })
            ->where('carts.save_for_later', 0)
            ->where('carts.user_id', $user->id)
            ->get();

        if ($one_seller_cart == 1 && !$cartItems->isEmpty()) {
            $firstSeller = $cartItems->first()->seller_id;
            $allSameSeller = $cartItems->every(function ($item) use ($firstSeller) {
                return $item->seller_id === $firstSeller;
            });

            if (!$allSameSeller) {
                $data['one_seller_error_code'] = 1;
                return CommonHelper::responseErrorWithData(('all_cart_products_have_not_same_seller'), $data);
            }
        }

        // Check for pre-order items vs normal items conflict (Bulk Add)
        // Get all products being added
        $productsBeingAdded = ProductVariant::join('products', 'product_variants.product_id', '=', 'products.id')
            ->whereIn('product_variants.id', $variant_ids)
            ->select('products.*')
            ->get();

        $hasPreOrderInNewItems = $productsBeingAdded->contains(function ($product) {
            return $product->is_pre_order_item == 1;
        });

        $hasNormalInNewItems = $productsBeingAdded->contains(function ($product) {
            return $product->is_pre_order_item != 1;
        });

        if (!$cartItems->isEmpty()) {
            $hasExistingPreOrderItems = $cartItems->contains(function ($item) {
                $product = Product::find($item->product_id);
                return $product && $product->is_pre_order_item == 1;
            });

            $hasExistingNormalItems = $cartItems->contains(function ($item) {
                $product = Product::find($item->product_id);
                return $product && $product->is_pre_order_item != 1;
            });

            // Prevent adding pre-order items if cart has normal items
            if ($hasPreOrderInNewItems && $hasExistingNormalItems) {
                $data['pre_order_conflict'] = 1;
                $data['message'] = 'Cannot add pre-order items with regular products. Please clear your cart or complete your current order first.';
                return CommonHelper::responseErrorWithData('pre_order_product_conflict', $data);
            }

            // Prevent adding normal items if cart has pre-order items
            if ($hasNormalInNewItems && $hasExistingPreOrderItems) {
                $data['pre_order_conflict'] = 1;
                $data['message'] = 'Cannot add regular products with pre-order items. Please clear your cart or complete your pre-order first.';
                return CommonHelper::responseErrorWithData('pre_order_product_conflict', $data);
            }
        }

        // Also prevent mixing pre-order and normal items within the same bulk add request
        if ($hasPreOrderInNewItems && $hasNormalInNewItems) {
            $data['pre_order_conflict'] = 1;
            $data['message'] = 'Cannot add pre-order items and regular products together. Please add them separately.';
            return CommonHelper::responseErrorWithData('pre_order_product_conflict', $data);
        }

        // Check if user has combos in cart - only prevent adding pre-order items (normal items are allowed)
        if ($hasPreOrderInNewItems) {
            $hasExistingCombos = DB::table('combo_custom_cart')
                ->where('user_id', $user->id)
                ->where('is_ordered', 0)
                ->exists();

            if ($hasExistingCombos) {
                $data['combo_conflict'] = 1;
                $data['message'] = 'Cannot add pre-order items when combos are in your cart. Please clear your cart or complete your combo order first.';
                return CommonHelper::responseErrorWithData('combo_product_conflict', $data);
            }
        }

        $available_products = [];
        $out_of_stock_products = [];
        $available_products_names = '';
        $out_of_stock_products_names = '';
        foreach ($variant_ids as $index => $variant_id) {
            $qty = $quantities[$index];
            $variant = ProductVariant::select('*', DB::raw("(SELECT is_unlimited_stock FROM products as p WHERE p.id = pv.product_id) as is_unlimited_stock"))
                ->from('product_variants as pv')->where('id', $variant_id)->first();



            if (!$variant) {
                return CommonHelper::responseError('no_such_item_available');
            }

            $product_id = $variant->product_id;
            $product = Product::find($product_id);

            if (!$product) {
                return CommonHelper::responseError('product_not_found');
            }

            if ($one_seller_cart == 1 && !$cartItems->isEmpty()) {
                $commonSellerId = $cartItems->first()->seller_id;
                if ($product->seller_id !== $commonSellerId) {
                    $data['one_seller_error_code'] = 1;
                    return CommonHelper::responseErrorWithData('seller_id_does_not_match', $data);
                }
            }

            if (ProductHelper::isItemAvailableWithStock($product_id, $variant_id, $qty)) {
                $available_products[] = [
                    'product_id' => $product_id,
                    'variant_id' => $variant_id,
                    'product_name' => $product->name, // Include product name
                ];
                $available_products_names = implode(', ', array_column($available_products, 'product_name'));
                if (ProductHelper::isItemAvailableInUserCart($user->id, $variant_id)) {
                    $cart = Cart::where('user_id', $user->id)
                        ->where('product_variant_id', $variant_id)->first();

                    if ($cart) {
                        $total_quantity = Cart::where('user_id', $user->id)
                            ->where('product_id', $product_id)
                            ->where('save_for_later', 0)
                            ->sum('qty');

                        if (!$product->is_unlimited_stock) {
                            $total_allowed_quantity = Product::where('id', $product_id)->pluck('total_allowed_quantity')->first();
                            $current_quantity = Cart::where('user_id', $user->id)->where('product_variant_id', $variant_id)->pluck('qty')->first();
                            $total_quantity = $total_quantity - $current_quantity + $qty;

                            if ($total_quantity > $total_allowed_quantity) {
                                return CommonHelper::responseError('total_allowed_quantity_for_this_product_is' . $total_allowed_quantity);
                            }
                        }

                        $cart->qty = $qty;
                        $cart->save_for_later = 0;
                        $cart->save();
                    } else {
                        return CommonHelper::responseError('item_not_found');
                    }
                } else {
                    if ($user->status == 1) {
                        if (!$product->is_unlimited_stock) {
                            $total_allowed_quantity = Product::where('id', $product_id)->pluck('total_allowed_quantity')->first();
                            if ($total_allowed_quantity && $qty > $total_allowed_quantity) {
                                return CommonHelper::responseError('total_allowed_quantity_for_this_product_is' . $total_allowed_quantity . '!');
                            }
                        }

                        $data = [
                            'user_id' => $user->id,
                            'product_id' => $product_id,
                            'product_variant_id' => $variant_id,
                            'qty' => $qty
                        ];

                        Cart::insert($data);
                    } else {
                        return CommonHelper::responseError('not_allowed_to_add_to_cart_as_your_account_is_de_activated');
                    }
                }
            } else {
                $out_of_stock_products[] = ['product_id' => $product_id, 'variant_id' => $variant_id, 'product_name' => $product->name];
                $out_of_stock_products_names = implode(', ', array_column($out_of_stock_products, 'product_name'));

            }
        }

        $total = CommonHelper::getCartCount($user->id);
        $sub_total = $total->total_amount;
        $saved_amount = $total->save_price - $total->total_amount;
        $saved_amount = ($saved_amount <= 0) ? 0 : $saved_amount;
        if (!empty($available_products_names)) {

            return Response::json([
                'status' => 1,
                'message' => 'items_added_to_users_cart_successfully',
                'cart_items_count' => $total->cart_items_count,
                'cart_total_qty' => $total->cart_total_qty,
                'sub_total' => $sub_total,
                'saved_amount' => $saved_amount,
                'available_products_names' => $available_products_names,
                'out_of_stock_products_names' => $out_of_stock_products_names,
            ]);
        } else {
            return Response::json([
                'status' => 0,
                'message' => 'items_not_available',
                'cart_items_count' => $total->cart_items_count,
                'cart_total_qty' => $total->cart_total_qty,
                'sub_total' => $sub_total,
                'saved_amount' => $saved_amount,
                'available_products_names' => $available_products_names,
                'out_of_stock_products_names' => $out_of_stock_products_names,
            ]);
        }
    }
    public function getCartCount()
    {
        $userId = auth()->id(); // Example for logged-in user
        $cartCount = Cart::where('user_id', $userId)->count();
        return Response::json([
            'cart_count' => $cartCount,
        ]);
    }

    /**
     * Save cart metadata (delivery tip, instructions, contact info, notes)
     */
    public function saveCartMetadata(Request $request)
    {
        $user_id = $request->user('api-customers')->id;

        $validator = Validator::make($request->all(), [
            'delivery_tip' => 'nullable|numeric|min:0',
            'delivery_instructions' => 'nullable|string|max:1000',
            'contact_name' => 'nullable|string|max:255',
            'contact_phone' => 'nullable|string|max:20',
            'contact_email' => 'nullable|email|max:255',
            'seller_notes' => 'nullable|array',
            'seller_notes.*' => 'nullable|string|max:500',
            'combo_notes' => 'nullable|array',
            'combo_notes.*' => 'nullable|string|max:500',
            'promocode_id' => 'nullable|integer|exists:promo_codes,id',
            'promo_code' => 'nullable|string|max:50',
            'wallet_amount' => 'nullable',
            'wallet_amount_value' => 'nullable|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        try {
            \DB::beginTransaction();

            // Get or create cart metadata for this user
            $metadata = \App\Models\CartMetadata::firstOrNew(['user_id' => $user_id]);

            // Update fields if provided
            if ($request->has('promocode_id')) {
                $metadata->promocode_id = $request->promocode_id;
                \Log::info('PromoCode: Saving promo code to cart metadata', [
                    'user_id' => $user_id,
                    'promocode_id' => $request->promocode_id,
                    'promo_code' => $request->promo_code ?? null
                ]);
            }

            if ($request->has('promo_code')) {
                $metadata->promo_code = $request->promo_code;
            }

            if ($request->has('delivery_tip')) {
                $metadata->delivery_tip = $request->delivery_tip;
            }

            if ($request->has('delivery_instructions')) {
                $metadata->delivery_instructions = $request->delivery_instructions;
            }

            if ($request->has('contact_name')) {
                $metadata->contact_name = $request->contact_name;
            }

            if ($request->has('contact_phone')) {
                $metadata->contact_phone = $request->contact_phone;
            }

            if ($request->has('contact_email')) {
                $metadata->contact_email = $request->contact_email;
            }

            // Update wallet amount flag if provided
            if ($request->has('wallet_amount')) {
                $metadata->wallet_amount = (bool) $request->wallet_amount;

                // Turning the wallet off clears any partial amount, so the next
                // time it is switched on it starts from "apply everything".
                if (!$metadata->wallet_amount) {
                    $metadata->wallet_amount_value = null;
                }
            }

            // An empty string clears the partial amount (back to whole balance)
            if ($request->has('wallet_amount_value')) {
                $metadata->wallet_amount_value = is_numeric($request->wallet_amount_value) && $request->wallet_amount_value > 0
                    ? (float) $request->wallet_amount_value
                    : null;
            }

            // Handle seller notes (merge with existing, preserving keys)
            if ($request->has('seller_notes')) {
                $existingSellerNotes = $metadata->seller_notes ?? [];
                // Use array_replace to preserve numeric string keys instead of array_merge
                $metadata->seller_notes = array_replace($existingSellerNotes, $request->seller_notes);
            }

            // Handle combo notes (merge with existing, preserving keys)
            if ($request->has('combo_notes')) {
                $existingComboNotes = $metadata->combo_notes ?? [];
                // Use array_replace to preserve numeric string keys instead of array_merge
                $metadata->combo_notes = array_replace($existingComboNotes, $request->combo_notes);
            }

            // Calculate and store multi-order charges
            try {
                $multiOrderCharges = MultiOrderChargesService::getMultiOrderCharges($user_id);
                $hasMultiOrder = MultiOrderChargesService::hasMultiOrderScenario($user_id);

                $metadata->multi_order_charges = $multiOrderCharges;
                $metadata->has_multi_order = $hasMultiOrder;
            } catch (\Exception $e) {
                \Log::error('Failed to calculate multi-order charges in saveCartMetadata', [
                    'user_id' => $user_id,
                    'error' => $e->getMessage()
                ]);
                // Set defaults if calculation fails
                $metadata->multi_order_charges = 0;
                $metadata->has_multi_order = false;
            }

            $metadata->save();

            \DB::commit();

            return CommonHelper::responseWithData([
                'message' => 'Cart metadata saved successfully',
                'metadata' => $metadata
            ]);
        } catch (\Exception $e) {
            \DB::rollBack();
            \Log::error('Error saving cart metadata', [
                'user_id' => $user_id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return CommonHelper::responseError('Failed to save cart metadata: ' . $e->getMessage());
        }
    }

    /**
     * Get cart metadata
     */
    public function getCartMetadata(Request $request)
    {
        $user_id = $request->user('api-customers')->id;

        $metadata = \App\Models\CartMetadata::where('user_id', $user_id)->first();

        if (!$metadata) {
            return CommonHelper::responseWithData([
                'metadata' => [
                    'promocode_id' => null,
                    'delivery_tip' => 0,
                    'delivery_instructions' => null,
                    'contact_name' => null,
                    'contact_phone' => null,
                    'contact_email' => null,
                    'seller_notes' => [],
                    'combo_notes' => [],
                ]
            ]);
        }

        return CommonHelper::responseWithData([
            'metadata' => $metadata
        ]);
    }

    /**
     * Clear specific cart metadata fields
     */
    public function clearCartMetadata(Request $request)
    {
        $user_id = $request->user('api-customers')->id;

        $validator = Validator::make($request->all(), [
            'fields' => 'required|array',
            'fields.*' => 'in:promocode_id,promo_code,delivery_tip,delivery_instructions,contact_name,contact_phone,contact_email,seller_notes,combo_notes',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $metadata = \App\Models\CartMetadata::where('user_id', $user_id)->first();

        if ($metadata) {
            foreach ($request->fields as $field) {
                if ($field === 'seller_notes' || $field === 'combo_notes') {
                    $metadata->{$field} = [];
                } elseif ($field === 'delivery_tip') {
                    $metadata->{$field} = 0;
                } else {
                    $metadata->{$field} = null;
                }
            }
            $metadata->save();
        }

        return CommonHelper::responseWithData([
            'message' => 'Cart metadata cleared successfully'
        ]);
    }


    /**
     * Remove promo code from cart metadata
     */
    public function removePromoCode(Request $request)
    {
        $user_id = $request->user('api-customers')->id;
        $metadata = \App\Models\CartMetadata::where('user_id', $user_id)->first();

        if ($metadata) {
            $metadata->promocode_id = null;
            $metadata->promo_code = null;
            // Also invalidate saved breakdown so it's fresh
            $metadata->billing_breakdown = [];
            $metadata->billing_summary = [];
            $metadata->save();

            \Log::info('PromoCode: Removed from cart metadata', [
                'user_id' => $user_id,
                'metadata_id' => $metadata->id
            ]);
        }

        return CommonHelper::responseWithData([
            'message' => 'Promo code removed successfully'
        ]);
    }
}
