<?php

namespace App\Http\Controllers\API\Customer;

use App\Helpers\CommonHelper;
use App\Helpers\ProductHelper;
use App\Helpers\Paypal;
use App\Helpers\PaypalClient;
use App\Helpers\Paystack;
use App\Helpers\Paytm;
use App\Helpers\TransactionHelper;
use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Models\AppUsage;
use App\Models\Order;
use App\Models\Cart;
use App\Models\OrderItem;
use App\Models\OrderComboItem;
use App\Models\OrderStatus;
use App\Models\OrderStatusList;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\Setting;
use App\Models\Transaction;
use App\Models\PaytmTransaction;
use App\Models\WalletTransaction;
use App\Models\Unit;
use App\Models\User;
use App\Models\LiveTracking;
use App\Models\PromoCode;
use App\Models\ReturnRequest;
use App\Models\Seller;
use App\Notifications\OrderNotification;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Mpdf\Mpdf;
use Mpdf\Output\Destination;
use Response;
use Illuminate\Validation\Rule;
use App\Jobs\SendEmailJob;
use App\Jobs\SendSellerOrderNotification;
use App\Services\UserOfferClaimService;
use App\Services\StoreLocationService;
use App\Services\FirestoreOrderSellerTrackingService;
use App\Services\SellerNotificationService;
use App\Services\CustomerNotificationService;
use App\Services\AdminNotificationService;
use App\Services\OrderArrivalTimeService;
use App\Services\FirestoreOrderETAService;
use App\Services\PhonePeRefundService;
use App\Services\PaytmRefundService;
use App\Services\ProductOrderPolicyService;
use App\Services\OrderItemsService;
use App\Models\DeliveryBoyLocationHistory;

class OrderApiController extends Controller
{
    public function placeOrder(Request $request)
    {
        try {
            // ===== DEBUG LOGGING START =====
            Log::info('=== PLACE ORDER DEBUG ===');
            Log::info('Request Data:', $request->all());
            Log::info('custom_combos raw value:', ['value' => $request->custom_combos, 'type' => gettype($request->custom_combos)]);
            // ===== DEBUG LOGGING END =====

            // Check if order has combos - decode JSON string if necessary
            $customCombosInput = $request->custom_combos;
            if (is_string($customCombosInput) && !empty($customCombosInput)) {
                $customCombosInput = json_decode($customCombosInput, true);
            }

            // IMPORTANT: Check if custom_combos parameter exists (not just if it's empty)
            // An empty array [] should still allow cart-based ordering
            $hasCustomCombos = $request->has('custom_combos');

            Log::info('Validation Logic:', [
                'customCombosInput' => $customCombosInput,
                'hasCustomCombos' => $hasCustomCombos,
                'quantity_rule' => $hasCustomCombos ? 'nullable' : 'required',
                'product_variant_id_rule' => $hasCustomCombos ? 'nullable' : 'required'
            ]);

            $validator = Validator::make($request->all(), [
                'total' => 'required',
                'delivery_charge' => 'required_if:order_type,doorstep',
                'delivery_time' => 'required_if:order_type,doorstep',
                'final_total' => 'required',
                'payment_method' => 'required',
                'address_id' => 'required_if:order_type,doorstep',
                'quantity' => $hasCustomCombos ? 'nullable' : 'required',
                'product_variant_id' => $hasCustomCombos ? 'nullable' : 'required',
                'order_note' => 'nullable|string|max:256',
                'order_type' => 'required|in:doorstep,selfpickup'
            ], [
                'required' => 'The :attribute field is required.',
                'order_note.max' => 'Order note cannot exceed 256 characters.',
                'address_id.required_if' => 'Address is required for doorstep delivery.',
                'order_type.in' => 'Order type must be either doorstep or selfpickup.',
            ]);

            if ($validator->fails()) {
                Log::error('Validation Failed:', ['errors' => $validator->errors()->all()]);
                return CommonHelper::responseError($validator->errors()->first());
            }
            $user = auth()->user();
            if (!isset($user->status) || $user->status == 0) {
                return CommonHelper::responseError(__('not_allowed_to_place_order_as_your_account_is_de_activated'));
            }

            $order_type = $request->order_type ?? 'doorstep';
            $one_seller_cart = Setting::where('variable', 'one_seller_cart')->exists() ? (int) Setting::where('variable', 'one_seller_cart')->value('value') : 0;

            // For self pickup orders, one seller cart must be enabled
            if ($order_type == 'selfpickup' && $one_seller_cart != 1) {
                return CommonHelper::responseError(__('self_pickup_orders_require_one_seller_cart_to_be_enabled'));
            }

            $cartItems = Cart::select('carts.*', 'products.seller_id', 'products.store_id', 'products.name as product_name', 'products.is_pre_order_item', 'sellers.name as seller_name', 'sellers.status as seller_status', 'sellers.self_pickup_mode', 'sellers.pickup_store_address', 'sellers.pickup_latitude', 'sellers.pickup_longitude', 'sellers.pickup_store_timings', 'sellers.mobile', 'stores.managed_by_admin')
                ->join('products', 'carts.product_id', '=', 'products.id')
                ->leftJoin('sellers', 'products.seller_id', '=', 'sellers.id')
                ->leftJoin('stores', 'products.store_id', '=', 'stores.id')
                ->where('carts.save_for_later', '=', 0)
                ->where('user_id', '=', $user->id)
                ->get();

            // Also get custom combos
            $customComboCarts = DB::table('combo_custom_cart')
                ->where('user_id', $user->id)
                ->where('is_ordered', 0)
                ->get();

            if ($cartItems->isEmpty() && $customComboCarts->isEmpty()) {
                return CommonHelper::responseError(__('cart_is_empty'));
            }

            // PREORDER LOGIC - Auto-detect based on cart products (backend decides, not client)
            // Check if ALL products in cart are preorder items
            $is_preorder = false;

            if (!$cartItems->isEmpty()) {
                // Check if all regular cart items are preorder products
                $is_preorder = $cartItems->every(function($item) {
                    return $item->is_pre_order_item == 1;
                });
            } elseif (!$customComboCarts->isEmpty()) {
                // If only combo items exist, check combo products
                $allComboProductIds = [];
                foreach ($customComboCarts as $customCart) {
                    $customProducts = DB::table('combo_custom_products')
                        ->where('combo_custom_id', $customCart->id)
                        ->pluck('product_id')
                        ->toArray();
                    $allComboProductIds = array_merge($allComboProductIds, $customProducts);
                }

                if (!empty($allComboProductIds)) {
                    $comboProductsPreorderCheck = DB::table('products')
                        ->whereIn('id', array_unique($allComboProductIds))
                        ->pluck('is_pre_order_item')
                        ->toArray();

                    // Check if all combo products are preorder items
                    $is_preorder = !empty($comboProductsPreorderCheck) && count(array_filter($comboProductsPreorderCheck, function($val) {
                        return $val == 1;
                    })) === count($comboProductsPreorderCheck);
                }
            }

            Log::info('Preorder Auto-Detection', [
                'is_preorder' => $is_preorder,
                'cart_items_count' => $cartItems->count(),
                'combo_items_count' => $customComboCarts->count(),
                'detection_method' => 'backend_auto_detect_from_products'
            ]);

            // If it's a preorder, verify preorder is currently available
            if ($is_preorder) {
                $preorderStatus = \App\Helpers\PreorderHelper::getPreorderStatus();

                if ($preorderStatus['status'] != 1) {
                    return CommonHelper::responseError(__($preorderStatus['message']));
                }
            }

            if ($order_type == 'selfpickup') {
                // Check if we have valid sellers from regular items or combos (skip for admin-managed stores)
                $hasValidSeller = false;
                $hasAdminManagedStore = false;

                if (!$cartItems->isEmpty()) {
                    // Check if any items are from admin-managed stores
                    $adminManagedItems = $cartItems->filter(function ($item) {
                        return $item->managed_by_admin == 1;
                    });
                    $hasAdminManagedStore = $adminManagedItems->isNotEmpty();

                    // Check for valid sellers only from seller-managed stores
                    $validSellers = $cartItems->filter(function ($item) {
                        return $item->managed_by_admin != 1 && $item->seller_id && $item->seller_status == 1;
                    });
                    $hasValidSeller = $validSellers->isNotEmpty();
                }

                // If no valid sellers from cart items, check combos
                if (!$hasValidSeller && !$hasAdminManagedStore && !$customComboCarts->isEmpty()) {
                    foreach ($customComboCarts as $customCart) {
                        $customProduct = DB::table('combo_custom_products')
                            ->where('combo_custom_id', $customCart->id)
                            ->first();

                        if ($customProduct) {
                            $product = Product::with('store')->find($customProduct->product_id);
                            if ($product) {
                                // Skip seller check if from admin-managed store
                                if ($product->store && $product->store->managed_by_admin == 1) {
                                    $hasAdminManagedStore = true;
                                    break;
                                }

                                if ($product->seller_id) {
                                    $seller = Seller::where('id', $product->seller_id)->where('status', 1)->first();
                                    if ($seller) {
                                        $hasValidSeller = true;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }

                // Only error if no valid seller AND no admin-managed store items
                if (!$hasValidSeller && !$hasAdminManagedStore) {
                    return CommonHelper::responseError(__('no_valid_sellers_for_self_pickup'));
                }
            }

            if ($one_seller_cart == 1 && !$cartItems->isEmpty()) {
                // Check if all items are from admin-managed stores
                $allAdminManaged = $cartItems->every(function ($item) {
                    return $item->managed_by_admin == 1;
                });

                // Only validate seller consistency if NOT all admin-managed
                if (!$allAdminManaged) {
                    // Get first non-admin-managed item's seller_id for comparison
                    $firstNonAdminItem = $cartItems->first(function ($item) {
                        return $item->managed_by_admin != 1;
                    });

                    $firstSeller = $firstNonAdminItem ? $firstNonAdminItem->seller_id : null;

                    $allSameSeller = $cartItems->every(function ($item) use ($firstSeller) {
                        // Skip admin-managed stores in seller validation (they can mix with any seller)
                        if ($item->managed_by_admin == 1) {
                            return true;
                        }
                        // Allow null seller_id for Zenfoo store products (admin-managed products without seller)
                        if ($firstSeller === null && $item->seller_id === null) {
                            return true;
                        }
                        return $item->seller_id === $firstSeller;
                    });

                    if (!$allSameSeller) {
                        $data['one_seller_error_code'] = 1;
                        return CommonHelper::responseErrorWithData(__('all_cart_products_have_not_same_seller'), $data);
                    }

                    if ($order_type == 'selfpickup') {
                        // Find first non-admin-managed item for seller validation
                        $sellerItem = $cartItems->first(function ($item) {
                            return $item->managed_by_admin != 1;
                        });

                        if ($sellerItem) {
                            if (!$sellerItem->seller_id) {
                                return CommonHelper::responseError(__('invalid_seller_for_self_pickup'));
                            }
                            if ($sellerItem->self_pickup_mode != 1) {
                                return CommonHelper::responseError(__('seller_does_not_support_self_pickup'));
                            }
                            if (empty($sellerItem->pickup_store_address)) {
                                return CommonHelper::responseError(__('seller_pickup_address_not_configured'));
                            }
                        }
                    }
                }
            }
            // $deactivatedSellers = $cartItems->filter(function ($item) {
            //     return $item->seller_status != 1;
            // });
            // if ($deactivatedSellers->isNotEmpty()) {
            //     foreach ($deactivatedSellers as $item) {

            //         $message = "is_from_disabled_seller";
            //         return CommonHelper::responseErrorWithData($message, $item->product_name);
            //     }
            // }

            $address_id = ($order_type == 'doorstep') ? ($request->address_id ?? 0) : 0;
            $address = '';
            $mobile = '';
            $latitude = '';
            $longitude = '';
            $pincode_id = 0;
            $area_id = 0;
            $pickup_address = '';

            if ($order_type == 'doorstep') {
                $user_address = CommonHelper::getUserAddress($request->address_id);
                if (!empty($user_address)) {
                    $address = $user_address->address . ' ' . $user_address->landmark . ' ' . $user_address->area . ' ' . $user_address->city . ' ' . $user_address->state . ' ' . $user_address->country . '-' . $user_address->pincode . ' ' . $user_address->name . ' ' . $user_address->mobile . '/' . $user_address->alternate_mobile;
                    $mobile = $user_address->mobile;
                    $latitude = $user_address->latitude;
                    $longitude = $user_address->longitude;
                    $pincode_id = $user_address->pincode_id;
                    $area_id = $user_address->area_id ?? 0;

                    // Check delivery availability after address is populated (skip for admin-managed stores)
                    $seller_ids = [];

                    // Get seller IDs from cart items (excluding admin-managed stores)
                    if (!$cartItems->isEmpty()) {
                        $seller_ids = $cartItems->filter(function ($item) {
                            return $item->managed_by_admin != 1 && $item->seller_id;
                        })->pluck('seller_id')->unique()->values()->all();
                    }

                    // If no regular items, get seller ID from combos (excluding admin-managed stores)
                    if (empty($seller_ids) && !$customComboCarts->isEmpty()) {
                        foreach ($customComboCarts as $customCart) {
                            $customProducts = DB::table('combo_custom_products')
                                ->where('combo_custom_id', $customCart->id)
                                ->first();

                            if ($customProducts) {
                                $product = Product::with('store')->find($customProducts->product_id);
                                if ($product) {
                                    // Skip admin-managed stores
                                    if ($product->store && $product->store->managed_by_admin == 1) {
                                        continue;
                                    }
                                    if ($product->seller_id) {
                                        $seller_ids[] = $product->seller_id;
                                        break; // Just need one seller ID for delivery check
                                    }
                                }
                            }
                        }
                    }

                    // Only check delivery availability if there are seller-managed items
                    if (!empty($seller_ids) && !CommonHelper::isDeliverableOrder($address_id, $latitude, $longitude, $seller_ids[0]) && !isDemoMode()) {
                        return CommonHelper::responseError(__('sorry_we_are_not_delivering_on_selected_address'));
                    }
                } else {
                    return CommonHelper::responseError(__('something_is_missing_in_your_address'));
                }
            } else if ($order_type == 'selfpickup') {
                $mobile = $user->mobile;
                $seller = null;
                $isAdminManaged = false;

                // Try to get seller from cart items first (skip admin-managed stores)
                if (!$cartItems->isEmpty()) {
                    // Check if all items are from admin-managed stores
                    $hasAdminManagedItems = $cartItems->filter(function ($item) {
                        return $item->managed_by_admin == 1;
                    })->isNotEmpty();

                    if ($hasAdminManagedItems) {
                        $isAdminManaged = true;
                    }

                    // Get first non-admin-managed seller item
                    $sellerItem = $cartItems->first(function ($item) {
                        return $item->managed_by_admin != 1;
                    });

                    if ($sellerItem) {
                        $seller = $sellerItem;
                    }
                }

                // If no cart items, get seller from combos (skip admin-managed stores)
                if (!$seller && !$customComboCarts->isEmpty()) {
                    foreach ($customComboCarts as $customCart) {
                        $customProduct = DB::table('combo_custom_products')
                            ->where('combo_custom_id', $customCart->id)
                            ->first();

                        if ($customProduct) {
                            $product = Product::with(['seller', 'store'])->find($customProduct->product_id);
                            if ($product) {
                                // Check if from admin-managed store
                                if ($product->store && $product->store->managed_by_admin == 1) {
                                    $isAdminManaged = true;
                                    continue;
                                }

                                if ($product->seller) {
                                    // Create a seller object that matches the cart item structure
                                    $seller = (object) [
                                        'seller_id' => $product->seller->id,
                                        'pickup_store_address' => $product->seller->pickup_store_address,
                                        'pickup_latitude' => $product->seller->pickup_latitude,
                                        'pickup_longitude' => $product->seller->pickup_longitude,
                                        'pickup_store_timings' => $product->seller->pickup_store_timings,
                                        'mobile' => $product->seller->mobile,
                                    ];
                                    break;
                                }
                            }
                        }
                    }
                }

                // Only require seller pickup address if NOT admin-managed
                if ($seller && $seller->pickup_store_address) {
                    $pickup_timings = json_decode($seller->pickup_store_timings, true);
                    $opening_time = $pickup_timings['opening_time'] ?? '';
                    $closing_time = $pickup_timings['closing_time'] ?? '';

                    $pickup_address = json_encode([
                        'pickup_latitude' => $seller->pickup_latitude,
                        'pickup_longitude' => $seller->pickup_longitude,
                        'pickup_store_address' => $seller->pickup_store_address,
                        'opening_time' => $opening_time,
                        'closing_time' => $closing_time,
                        'seller_mobile' => $seller->mobile
                    ]);
                } else if (!$isAdminManaged) {
                    // Only error if not admin-managed
                    return CommonHelper::responseError(__('seller_pickup_address_not_available'));
                } else {
                    // For admin-managed stores, use empty pickup address
                    $pickup_address = '';
                }
            }

            $user_id = auth()->user()->id;
            $order_note = (isset($request->order_note) && !empty($request->order_note)) ? $request->order_note : "";
            $wallet_used = 'false'; // Will be set from cart metadata below
            $items = $request->product_variant_id ?? '';

            $total = floatval($request->total);
            $delivery_charge = ($order_type == 'selfpickup') ? 0 : floatval($request->delivery_charge);
            $final_total = floatval($request->final_total);

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

            $promo_code = "";
            $promo_discount = 0;
            $promo_code_id = 0;

            if (isset($request->promocode_id) && $request->promocode_id && $request->promocode_id != "") {

                $code = PromoCode::find($request->promocode_id);

                if (empty($code)) {
                    return CommonHelper::responseError("Promo code not found!");
                }
                $promo = CommonHelper::validatePromoCode($user_id, $code->promo_code, $total);

                if ($promo['is_applicable'] == 0) {
                    return CommonHelper::responseError($promo['message']);
                }

                if (isset($promo['promo_code_id']) && $request->promocode_id == $promo['promo_code_id']) {
                    // $final_total = $promo['discounted_amount'] + $delivery_charge;
                    $promo_discount = $promo['discount'];
                    $promo_code = $promo['promo_code'] . "(" . $promo['discount'] . ")";
                    $promo_code_id = $promo['promo_code_id'];
                }
            }

            // Read wallet usage from cart metadata (source of truth)
            $cartMetaForWallet = \App\Models\CartMetadata::where('user_id', auth()->user()->id)->first();
            $wallet_balance = 0;
            if ($cartMetaForWallet && $cartMetaForWallet->wallet_amount && $cartMetaForWallet->billing_summary && isset($cartMetaForWallet->billing_summary['wallet_deduction'])) {
                $wallet_balance = floatval($cartMetaForWallet->billing_summary['wallet_deduction']);
                $wallet_used = 'true';
            }

            // The customer app posts delivery_charge from the cart response's
            // delivery_charge.total_delivery_charge, which is always 0. The real
            // charge is calculated server-side (CartStoreIdsService) and kept in
            // cart_metadata.billing_summary.delivery_charge. Persist that value:
            // it is what the delivery boy is paid, and it stays payable even when
            // the customer got free delivery (free_delivery_order_amount) — the
            // customer's total comes from billing_summary.to_be_paid, not from here.
            if ($order_type != 'selfpickup' && $cartMetaForWallet && $cartMetaForWallet->billing_summary) {
                $meta_delivery_charge = floatval($cartMetaForWallet->billing_summary['delivery_charge'] ?? 0);

                // A 0 here means the cart-side calculation never landed (the
                // delivery-charge block in CartApiController is wrapped in a
                // try/catch that swallows failures, leaving the hardcoded 0).
                // The driver is paid from this value, so recompute rather than
                // ship a ₹0 order to them.
                if ($meta_delivery_charge <= 0) {
                    try {
                        $recalculated = \App\Services\CartStoreIdsService::getCartStoreIds($user_id);
                        $meta_delivery_charge = floatval($recalculated['delivery_charge'] ?? 0);

                        if ($meta_delivery_charge > 0) {
                            $summary = $cartMetaForWallet->billing_summary;
                            $summary['delivery_charge'] = $meta_delivery_charge;
                            $cartMetaForWallet->billing_summary = $summary;
                            $cartMetaForWallet->save();

                            Log::warning('placeOrder: billing_summary.delivery_charge was 0, recalculated for driver payout', [
                                'user_id' => $user_id,
                                'recalculated_charge' => $meta_delivery_charge,
                            ]);
                        }
                    } catch (\Throwable $e) {
                        Log::error('placeOrder: delivery charge recalculation failed', [
                            'user_id' => $user_id,
                            'error' => $e->getMessage(),
                        ]);
                    }
                }

                if ($meta_delivery_charge > 0) {
                    $delivery_charge = $meta_delivery_charge;
                }
            }

            $formatted_wallet_balance = number_format($wallet_balance, 2);
            $payment_method = $request->payment_method;
            $delivery_time = (isset($request->delivery_time)) ? $request->delivery_time : "";

            // PREORDER STATUS - Set to Preorder Pending if it's a preorder
            if ($is_preorder) {
                $active_status = OrderStatusList::$preorderPending;
            } else if ($order_type == 'selfpickup') {
                $active_status = $payment_method == Transaction::$paymentTypeCod ? OrderStatusList::$selfPickupPending : OrderStatusList::$paymentPending;
                if ($payment_method == 'Wallet') {
                    $active_status = OrderStatusList::$selfPickupPending;
                }
            } else {
                $active_status = $payment_method == Transaction::$paymentTypeCod ? OrderStatusList::$received : OrderStatusList::$paymentPending;
                if ($payment_method == 'Wallet') {
                    $active_status = OrderStatusList::$received;
                }
            }
            $order_from = (isset($request->order_from) && !empty($request->order_from)) ? $request->order_from : 0;

            $status[] = array($active_status, date("d-m-Y h:i:sa"));

            $quantity = $request->quantity ?? '';

            // Handle regular items (if any)
            $item_arr = [];
            $quantity_arr = [];
            $item_details = collect();
            $order_total_tax_amt = 0;
            $order_total_tax_per = 0;

            if (!empty($items) && !empty($quantity)) {
                $quantity_arr = explode(",", $quantity);
                $item_arr = explode(",", $items);

                foreach ($item_arr as $key => $item) {
                    $variant = ProductVariant::where("id", $item)->first();

                    // Check if the variant exists
                    if (empty($variant)) {
                        return CommonHelper::responseError(__('found_one_or_more_items_in_order_is_not_available_for_order'));
                    }

                    // Ensure the requested quantity is correctly retrieved
                    $requested_qty = $quantity_arr[$key] ?? 1; // Default to 1 if missing

                    // Check stock availability
                    if (!ProductHelper::isItemAvailableWithStock(null, $item, $requested_qty)) {
                        return CommonHelper::responseError(__("Low stock: Only {$variant->stock} available for {$variant->product->name}"));
                    }
                }

                $item_details = CommonHelper::getProductByVariantId($item_arr);

                $totalTax = CommonHelper::calculateOrderTotalTax($item_details, $quantity_arr);
                $order_total_tax_amt = $totalTax['order_total_tax_amt'];
                $order_total_tax_per = $totalTax['order_total_tax_per'];
            }

            $generate_otp = Setting::get_value("generate_otp");
            if ($generate_otp == 1) {
                $otp_number = mt_rand(100000, 999999);
            } else {
                $otp_number = 0;
            }

            // Generate 4-digit PIN for delivery boy
            $delivery_pin = str_pad(mt_rand(0, 9999), 4, '0', STR_PAD_LEFT);

            /* check for wallet balance */
            if ($wallet_used == 'true') {
                $user_wallet_balance = auth()->user()->balance;
                if ($user_wallet_balance < $wallet_balance) {
                    return CommonHelper::responseError(__('insufficient_wallet_balance'));
                }
            }

            /* check for minimum order amount */
            $min_order_amount = Setting::get_value("min_order_amount");
            if ($wallet_used == 'true') {
                $user_wallet_balance = auth()->user()->balance;
                if ($user_wallet_balance + $final_total < $min_order_amount) {
                    return CommonHelper::responseError("Minimum order amount is " . $min_order_amount . ".");
                }
            } else {
                if ($final_total < $min_order_amount) {
                    return CommonHelper::responseError("Minimum order amount is " . $min_order_amount . ".");
                }
            }

            $walletvalue = ($wallet_used == 'true') ? $wallet_balance : 0;
            $order_status = json_encode($status);

            /* insert data into order table */
            /* the customer facing order number (ZF-0001) is derived from the order
               primary key, so it can only be filled in once the row exists */
            $orders_id = null;

            DB::beginTransaction();
            try {

                $order = new Order();
                $order->user_id = $user_id;
                $order->delivery_boy_id = 0;
                $order->transaction_id = 0;
                $order->orders_id = $orders_id;
                $order->otp = $otp_number;
                $order->delivery_pin = $delivery_pin;
                $order->mobile = $mobile;
                $order->order_note = $order_note;
                $order->total = $total;
                $order->remaining_total = $total;
                $order->delivery_charge = $delivery_charge;

                // Rain surcharge from cart_metadata
                $cartMeta = \App\Models\CartMetadata::where('user_id', $user_id)->first();
                if ($cartMeta && $cartMeta->billing_summary && !empty($cartMeta->billing_summary['rain_surcharge_applicable'])) {
                    $order->is_rain_surcharge = true;
                    $order->rain_surcharge_amount = floatval($cartMeta->billing_summary['rain_surcharge'] ?? 0);
                }

                $order->tax_amount = $order_total_tax_amt;
                $order->tax_percentage = $order_total_tax_per;
                $order->wallet_balance = $walletvalue;
                $order->promo_code_id = $promo_code_id;
                $order->promo_code = $promo_code;
                $order->promo_discount = $promo_discount;

                $order->final_total = $final_total;
                $order->remaining_final = $final_total;
                $order->payment_method = $payment_method;
                $order->address = $address;
                $order->latitude = $latitude;
                $order->longitude = $longitude;
                $order->delivery_time = $delivery_time;
                $order->status = $order_status;
                $order->active_status = $active_status;
                $order->order_from = $order_from;
                $order->pincode_id = $pincode_id;
                $order->area_id = $area_id;
                $order->address_id = $address_id;
                $order->order_type = $order_type;
                $order->pickup_address = $pickup_address;
                $order->additional_charges = json_encode($additional_charges);

                // PREORDER FIELDS - Set preorder data if applicable
                if ($is_preorder) {
                    $order->is_preorder = 1;
                    $order->preorder_placed_at = \Carbon\Carbon::now('Asia/Kolkata');
                    $order->preorder_process_date = \App\Helpers\PreorderHelper::getNextProcessDate();
                } else {
                    $order->is_preorder = 0;
                }

                // Build and save cart metadata with grouped structure
                $cart_metadata = [
                    'grouped_by_seller' => [],
                    'custom_combos' => [],
                    'delivery_tip' => $request->delivery_tip ?? 0,
                ];

                $order->cart_metadata = $cart_metadata;
                $order->save();

                // Find nearest active Zenfoo store location using Haversine
                if (!empty($latitude) && !empty($longitude)) {
                    $nearestLocation = DB::selectOne("
                        SELECT id,
                            (6371 * ACOS(
                                COS(RADIANS(?)) * COS(RADIANS(latitude)) *
                                COS(RADIANS(longitude) - RADIANS(?)) +
                                SIN(RADIANS(?)) * SIN(RADIANS(latitude))
                            )) AS distance
                        FROM store_locations
                        WHERE status = 1
                        ORDER BY distance ASC
                        LIMIT 1
                    ", [$latitude, $longitude, $latitude]);
                    if ($nearestLocation) {
                        $order->store_location_id = $nearestLocation->id;
                        $order->save();
                    }
                }

                $order_id = $order->id;
                if ($order_id == "") {
                    return CommonHelper::responseError(__('order_can_not_place_due_to_some_reason_try_again_after_some_time'));
                }

                /* now that the auto increment id exists, stamp the customer facing
                   order number on the order and carry it onto every line item */
                $orders_id = CommonHelper::formatOrderNumber($order_id);
                $order->orders_id = $orders_id;
                $order->save();
                /* process wallet balance */
                $user_wallet_balance = $user->balance;
                /* process each product in order from variants of products */
                foreach ($item_details as $key => $item) {
                    $product_id = $item->product_id;
                    $product_name = $item->product_name;
                    $measurement = $item->measurement;
                    $variant_name = $measurement . ' ' . $item->stock_unit_name;
                    $product_variant_id = $item->id;
                    $stock_unit_id = $item->stock_unit_id;
                    $price = $item->price;
                    $discounted_price = (empty($item->discounted_price) || $item->discounted_price == "") ? 0 : $item->discounted_price;
                    $is_unlimited_stock = $item->is_unlimited_stock;
                    $type = $item->product_type;

                    $total_stock = $item->stock;
                    $quantity = $quantity_arr[$key];
                    $tax_title = $item->tax_title;
                    $seller_id = (!empty($item->seller_id)) ? $item->seller_id : null;
                    $tax_percentage = (empty($item->tax_percentage) || $item->tax_percentage == "") ? 0 : $item->tax_percentage;
                    $tax_amt = $discounted_price != 0 ? (($tax_percentage / 100) * $discounted_price) : (($tax_percentage / 100) * $price);
                    $sub_total = $discounted_price != 0 ? ($discounted_price + ($tax_percentage / 100) * $discounted_price) * $quantity : ($price + ($tax_percentage / 100) * $price) * $quantity;

                    $neworder_id = $order_id;
                    $tax_amount = $tax_amt;
                    $order_sub_total = $sub_total;
                    $order_item_status = json_encode($status);

                    $order_item = new OrderItem();
                    $order_item->user_id = $user_id;
                    $order_item->order_id = $neworder_id;

                    $order_item->orders_id = $orders_id;

                    $order_item->product_name = $product_name;
                    $order_item->variant_name = $variant_name;
                    $order_item->product_variant_id = $product_variant_id;
                    $order_item->quantity = $quantity;

                    $order_item->price = $price;
                    $order_item->discounted_price = $discounted_price;

                    $order_item->tax_amount = $tax_amount;
                    $order_item->tax_percentage = $tax_percentage;
                    $order_item->sub_total = $order_sub_total;
                    $order_item->status = $order_item_status;
                    $order_item->active_status = $active_status;
                    $order_item->seller_id = $seller_id;
                    $order_item->save();

                    /* here $is_unlimited_stock  0 = Limited and 1 = Unlimited */
                    if ($is_unlimited_stock != 1) {
                        $product_variant = ProductVariant::where("id", $product_variant_id)->first();
                        if ($type == 'packet') {
                            $stock = $total_stock - $quantity;
                            $product_variant->stock = $stock;
                            $product_variant->save();
                            if ($product_variant->stock <= 0) {
                                $product_variant->status = 0; // here status 0 => "Sold Out" & 1 => "Available"
                                $product_variant->save();
                            }

                        } elseif ($type == 'loose') {
                            $stock = max(0, $total_stock - ($measurement * $quantity));
                            // Update main product variant stock
                            $product_variant->stock = $stock;
                            if ($stock <= 0) {
                                $product_variant->status = 0; // 0 => "Sold Out"
                            }
                            $product_variant->save();
                            ProductVariant::where("product_id", $product_id)
                                ->where("stock_unit_id", $stock_unit_id) // Only same unit type
                                ->where("id", '!=', $product_variant_id) // Exclude current variant
                                ->update([
                                    'stock' => $stock,
                                    'status' => $stock <= 0 ? 0 : 1 // 0 => "Sold Out", 1 => "Available"
                                ]);

                        }
                    }
                }

                // Process custom combo items
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

                    // Calculate combo prices
                    $productIds = $customProducts->pluck('product_id')->unique();
                    $products = Product::with(['variants'])->whereIn('id', $productIds)->get();

                    $productsData = [];
                    $totalProductPrice = 0;
                    $totalActualPrice = 0;
                    $comboSellerId = null;

                    foreach ($customProducts as $customProduct) {
                        $product = $products->firstWhere('id', $customProduct->product_id);
                        if (!$product) {
                            continue;
                        }

                        // Set seller_id from first product
                        if ($comboSellerId === null && $product->seller_id) {
                            $comboSellerId = $product->seller_id;
                        }

                        $variant = $product->variants->firstWhere('id', $customProduct->variant_id);
                        if (!$variant) {
                            continue;
                        }

                        $price = $variant->discounted_price > 0 ? $variant->discounted_price : $variant->price;
                        $actualPrice = $variant->price;
                        $quantity = $customProduct->quantity;

                        $totalProductPrice += $price * $quantity;
                        $totalActualPrice += $actualPrice * $quantity;

                        // Get product images
                        $productImages = DB::table('product_images')
                            ->where('product_id', $product->id)
                            ->get()
                            ->map(function ($img) {
                                return [
                                    'id' => $img->id,
                                    'image' => $img->image ? $img->image : null,
                                ];
                            })
                            ->toArray();

                        $productsData[] = [
                            'product_id' => $product->id,
                            'product_name' => $product->name,
                            'product_image' => $product->image ? $product->image : null,
                            'product_images' => $productImages,
                            'variant_id' => $customProduct->variant_id,
                            'variant_measurement' => $variant->measurement ?? null,
                            'variant_stock_unit_id' => $variant->stock_unit_id ?? null,
                            'original_price' => $actualPrice, // MRP/Original price
                            'discounted_price' => $variant->discounted_price > 0 ? $variant->discounted_price : 0,
                            'price' => $price, // Selling price (discounted or regular)
                            'actual_price' => $actualPrice, // For backward compatibility
                            'quantity' => $quantity,
                            'sub_total' => $price * $quantity,
                        ];

                        // Deduct stock for combo products
                        if ($product->is_unlimited_stock != 1) {
                            $product_variant = ProductVariant::where("id", $variant->id)->first();
                            if ($product_variant) {
                                if ($product->type == 'packet') {
                                    $stock = $product_variant->stock - $quantity;
                                    $product_variant->stock = $stock;
                                    $product_variant->save();
                                    if ($product_variant->stock <= 0) {
                                        $product_variant->status = 0;
                                        $product_variant->save();
                                    }
                                } elseif ($product->type == 'loose') {
                                    $stock = max(0, $product_variant->stock - ($variant->measurement * $quantity));
                                    $product_variant->stock = $stock;
                                    if ($stock <= 0) {
                                        $product_variant->status = 0;
                                    }
                                    $product_variant->save();

                                    ProductVariant::where("product_id", $product->id)
                                        ->where("stock_unit_id", $variant->stock_unit_id)
                                        ->where("id", '!=', $variant->id)
                                        ->update([
                                            'stock' => $stock,
                                            'status' => $stock <= 0 ? 0 : 1
                                        ]);
                                }
                            }
                        }
                    }

                    $discountPercentage = $totalActualPrice > 0
                        ? round((($totalActualPrice - $totalProductPrice) / $totalActualPrice) * 100, 2)
                        : 0;

                    // Create order combo item
                    $orderComboItem = new OrderComboItem();
                    $orderComboItem->order_id = $order_id;
                    $orderComboItem->orders_id = $orders_id;
                    $orderComboItem->user_id = $user_id;
                    $orderComboItem->combo_id = $combo->id;
                    $orderComboItem->combo_custom_cart_id = $customCart->id;
                    $orderComboItem->combo_name = $combo->name;
                    $orderComboItem->combo_description = $combo->description ?? '';
                    $orderComboItem->product_count = count($productsData);
                    $orderComboItem->total_products_price = $totalProductPrice;
                    $orderComboItem->total_actual_price = $totalActualPrice;
                    $orderComboItem->discount_percentage = $discountPercentage;
                    $orderComboItem->sub_total = $totalProductPrice;
                    $orderComboItem->products = json_encode($productsData);
                    $orderComboItem->status = $order_status;
                    $orderComboItem->active_status = $active_status;
                    $orderComboItem->seller_id = $comboSellerId;
                    $orderComboItem->save();

                    // Mark combo as ordered
                    DB::table('combo_custom_cart')
                        ->where('id', $customCart->id)
                        ->update(['is_ordered' => 1]);
                }

                // Fetch cart metadata from cart_metadata table (includes billing details)
                $cartMetadata = \App\Models\CartMetadata::where('user_id', $user_id)->first();

                // Build cart metadata to save in order
                $metadataToSave = [];

                // Add cart metadata fields if available
                if ($cartMetadata) {
                    $metadataToSave['cart_info'] = [
                        'promocode_id' => $cartMetadata->promocode_id,
                        'delivery_tip' => $cartMetadata->delivery_tip,
                        'delivery_instructions' => $cartMetadata->delivery_instructions,
                        'contact_name' => $cartMetadata->contact_name,
                        'contact_phone' => $cartMetadata->contact_phone,
                        'contact_email' => $cartMetadata->contact_email,
                        'seller_notes' => $cartMetadata->seller_notes,
                        'combo_notes' => $cartMetadata->combo_notes,
                        'multi_order_charges' => $cartMetadata->multi_order_charges ?? 0,
                        'has_multi_order' => $cartMetadata->has_multi_order ?? false,
                    ];

                    // Use billing breakdown and summary from cart_metadata if available
                    if ($cartMetadata->billing_breakdown) {
                        // Strip informational rows that don't belong in the
                        // persisted order (e.g. "Add X more for free delivery").
                        $metadataToSave['billing_breakdown'] = array_values(array_filter(
                            $cartMetadata->billing_breakdown,
                            fn($row) => ($row['type'] ?? null) !== 'free_delivery_threshold'
                        ));
                    }
                    if ($cartMetadata->billing_summary) {
                        $metadataToSave['billing_summary'] = $cartMetadata->billing_summary;
                    }
                } else {
                    // Fallback if no cart metadata exists
                    $metadataToSave['cart_info'] = [
                        'delivery_tip' => $request->delivery_tip ?? 0,
                        'delivery_instructions' => $request->delivery_instructions ?? null,
                        'multi_order_charges' => 0,
                        'has_multi_order' => false,
                    ];
                }

                // Update order with cart metadata
                $order->cart_metadata = $metadataToSave;

                // Update total with to_be_paid from billing_summary if available
                if ($cartMetadata && $cartMetadata->billing_summary && isset($cartMetadata->billing_summary['to_be_paid'])) {
                    $order->total = $cartMetadata->billing_summary['to_be_paid'];

                    // Payment gateway fees only apply to online payments — strip them for COD
                    if ($payment_method === Transaction::$paymentTypeCod) {
                        $cartGatewayFees = floatval($cartMetadata->billing_summary['payment_gateway_fees'] ?? 0);
                        if ($cartGatewayFees > 0) {
                            $order->total = max(0, $order->total - $cartGatewayFees);
                        }
                    }
                }

                $order->save();

                if ($wallet_used == 'true' && $wallet_balance > 0) {
                    /* deduct the balance & set the wallet transaction */
                    $new_balance = $user_wallet_balance < $wallet_balance ? 0 : $user_wallet_balance - $wallet_balance;
                    CommonHelper::updateUserWalletBalance($new_balance, $user_id);
                    CommonHelper::addWalletTransaction($order_id, 0, $user_id, 'debit', $wallet_balance, 'Used against Order Placement', 1, $payment_method);
                }

                Log::info("Order Seller Tracking - Starting for order_id: {$order_id}");
                $allProductIds = [];

                $orderItemVariantIds = DB::table('order_items')
                    ->where('order_id', $order_id)
                    ->pluck('product_variant_id')
                    ->toArray();
                Log::info("Order Seller Tracking - Order item variant IDs: ", ['variant_ids' => $orderItemVariantIds]);

                if (!empty($orderItemVariantIds)) {
                    $regularProductIds = DB::table('product_variants')
                        ->whereIn('id', $orderItemVariantIds)
                        ->pluck('product_id')
                        ->toArray();
                    Log::info("Order Seller Tracking - Regular product IDs from variants: ", ['product_ids' => $regularProductIds]);
                    $allProductIds = array_merge($allProductIds, $regularProductIds);
                }

                $comboItems = DB::table('order_combo_items')
                    ->where('order_id', $order_id)
                    ->pluck('products')
                    ->toArray();
                Log::info("Order Seller Tracking - Combo items count: " . count($comboItems));

                foreach ($comboItems as $productsJson) {
                    $products = json_decode($productsJson, true);
                    // Handle double-encoded JSON (string inside JSON)
                    if (is_string($products)) {
                        $products = json_decode($products, true);
                    }
                    Log::info("Order Seller Tracking - Combo products JSON decoded: ", ['products' => $products ?? []]);
                    if (is_array($products)) {
                        foreach ($products as $product) {
                            if (isset($product['product_id'])) {
                                $allProductIds[] = $product['product_id'];
                                Log::info("Order Seller Tracking - Added combo product_id: " . $product['product_id']);
                            }
                        }
                    }
                }

                $allProductIds = array_unique($allProductIds);
                Log::info("Order Seller Tracking - All unique product IDs: ", ['product_ids' => array_values($allProductIds)]);

                if (!empty($allProductIds)) {
                    // Get seller_id and store_id pairs from products
                    $sellerStoreData = DB::table('products')
                        ->whereIn('id', $allProductIds)
                        ->whereIn('store_id', [15, 17, 12, 13])
                        // ->whereNotNull('seller_id')
                        ->select('seller_id', 'store_id')
                        ->distinct()
                        ->get();
                    Log::info("Order Seller Tracking - Seller/Store data for store_id 15,17,12,13: ", ['data' => $sellerStoreData->toArray()]);


                    $store_location_id = StoreLocationService::getStoreLocationIdByOrderId($order_id);


                    if ($sellerStoreData->isNotEmpty()) {
                        $now = now()->setTimezone('Asia/Kolkata');
                        // Single OTP shared by all Zenfoo store rows (12, 13) of the same order
                        // so the driver verifies once and both rows advance together.
                        $zenfooSharedOtp = str_pad(random_int(0, 9999), 4, '0', STR_PAD_LEFT);
                        foreach ($sellerStoreData as $record) {
                            $isZenfooStore = isset($record->store_id) && in_array($record->store_id, [12, 13]);
                            $otp = $isZenfooStore
                                ? $zenfooSharedOtp
                                : str_pad(random_int(0, 9999), 4, '0', STR_PAD_LEFT);
                            DB::table('order_seller_status_tracking')->insert([
                                'order_id' => $order_id,
                                'seller_id' => $record->seller_id ?? null,
                                'store_id' => $record->store_id,
                                'status' => 'assigned_to_seller',
                                'otp' => $otp,
                                'is_zenfoo_store' => $isZenfooStore ? 1 : 0,
                                'store_location_id' => $isZenfooStore ? $store_location_id : 0,
                                'created_at' => $now,
                                'updated_at' => $now,
                            ]);
                            Log::info("Order Seller Tracking - Inserted tracking record for order_id: {$order_id}, seller_id: {$record->seller_id}, store_id: {$record->store_id}");

                            // Send push notification to seller about new order
                            if ($record->seller_id) {
                                try {
                                    SellerNotificationService::send(
                                        sellerId: $record->seller_id,
                                        title: 'New Order Received!',
                                        message: "You have received a new order #{$order_id}. Please check and prepare the items.",
                                        image: '',
                                        pageNavigation: 'new_order',
                                        navigationId: $order_id
                                    );
                                    Log::info("Order Seller Tracking - Notification sent to seller", [
                                        'order_id' => $order_id,
                                        'seller_id' => $record->seller_id
                                    ]);
                                } catch (\Exception $e) {
                                    Log::error("Order Seller Tracking - Failed to send notification to seller", [
                                        'order_id' => $order_id,
                                        'seller_id' => $record->seller_id,
                                        'error' => $e->getMessage()
                                    ]);
                                }
                            }
                        }

                        // Sync order seller tracking data to Firestore
                        $firestoreResult = FirestoreOrderSellerTrackingService::syncOrderSellerTracking($order_id);
                        if ($firestoreResult['success']) {
                            Log::info("Order Seller Tracking - Synced to Firestore successfully", [
                                'order_id' => $order_id,
                                'sellers_count' => $firestoreResult['sellers_count'] ?? 0
                            ]);
                        } else {
                            Log::warning("Order Seller Tracking - Failed to sync to Firestore", [
                                'order_id' => $order_id,
                                'error' => $firestoreResult['message'] ?? 'Unknown error'
                            ]);
                        }
                    } else {
                        Log::info("Order Seller Tracking - No sellers found for store_id 15 or 17");
                    }
                } else {
                    Log::info("Order Seller Tracking - No product IDs found for order_id: {$order_id}");
                }

                // Calculate estimated arrival time and store in order
                try {
                    $arrivalTimeResult = OrderArrivalTimeService::calculateArrivalTime($order_id);

                    if ($arrivalTimeResult['success']) {
                        $arrivalData = $arrivalTimeResult['data'];

                        // Update order with locations_json and estimated_time_of_delivery
                        $order->locations_json = [
                            'customer_location' => $arrivalData['customer_location'],
                            'pickup_locations' => $arrivalData['pickup_locations'],
                            'total_pickup_points' => $arrivalData['total_pickup_points'],
                            'has_admin_managed' => $arrivalData['has_admin_managed'],
                            'has_non_admin_managed' => $arrivalData['has_non_admin_managed'],
                            'is_mixed_order' => $arrivalData['is_mixed_order'],
                            'route_calculation' => $arrivalData['route_calculation']
                        ];
                        $order->estimated_time_of_delivery = (int) round($arrivalData['route_calculation']['estimated_time_min']);

                        // Calculate and store seller_count (unique stores in the order)
                        $order->seller_count = OrderArrivalTimeService::getSellerCount($order_id);

                        // Store complete order items snapshot for future reference
                        $order->order_items_snapshot = OrderArrivalTimeService::getOrderItemsSnapshot($order_id);

                        $order->save();

                        Log::info("Order Arrival Time - Calculated and saved for order_id: {$order_id}", [
                            'estimated_time_min' => $arrivalData['route_calculation']['estimated_time_min'],
                            'total_distance_km' => $arrivalData['route_calculation']['total_distance_km']
                        ]);

                        // Sync ETA to Firestore (including seller_count)
                        $etaMinutes = (int) round($arrivalData['route_calculation']['estimated_time_min']);
                        $firestoreETAResult = FirestoreOrderETAService::syncOrderETA($order_id, $etaMinutes, $order->seller_count);

                        if ($firestoreETAResult['success']) {
                            Log::info("Order Arrival Time - Synced to Firestore for order_id: {$order_id}", [
                                'eta' => $etaMinutes,
                                'stored_at' => $firestoreETAResult['data']['stored_at'] ?? null,
                                'seller_count' => $order->seller_count
                            ]);
                        } else {
                            Log::warning("Order Arrival Time - Failed to sync to Firestore for order_id: {$order_id}", [
                                'message' => $firestoreETAResult['message'] ?? 'Unknown error'
                            ]);
                        }
                    } else {
                        Log::warning("Order Arrival Time - Failed to calculate for order_id: {$order_id}", [
                            'message' => $arrivalTimeResult['message']
                        ]);
                    }
                } catch (\Exception $e) {
                    Log::error("Order Arrival Time - Exception for order_id: {$order_id}", [
                        'error' => $e->getMessage()
                    ]);
                    // Don't fail the order placement if arrival time calculation fails
                }

                DB::commit();

                // Clear regular cart items after successful order placement
                Cart::where('user_id', $user_id)
                    ->where('save_for_later', 0)
                    ->delete();

                Log::info('Cart cleared after order placement', [
                    'user_id' => $user_id,
                    'order_id' => $order_id
                ]);

            } catch (\Exception $e) {
                DB::rollBack();
                throw $e;
                return CommonHelper::responseError(__('could_not_place_order_try_again'));
            }
            // PREORDER - Skip notifications for preorders (they will be sent when processed on Friday)
            if (!empty($order) && !$is_preorder && ($payment_method == Transaction::$paymentTypeCod || $payment_method == Transaction::$paymentTypeWallet)) {
                try {
                    dispatch(function () use ($order) {
                        CommonHelper::sendNotificationOrderStatus($order);
                        $admins = Admin::get();
                        foreach ($admins as $admin) {
                            $admin->notify(new OrderNotification($order->id, 'new_order'));
                        }
                    })->afterResponse();
                } catch (\Exception $e) {
                    Log::error("Place orderNotification error :", [$e->getMessage()]);
                }

                // Send push notification to customer about order confirmation
                try {
                    CustomerNotificationService::send(
                        customerId: $order->user_id,
                        title: 'Order Placed Successfully!',
                        message: "Your order #{$order->id} has been placed successfully. We'll notify you once the seller starts preparing your order.",
                        image: '',
                        pageNavigation: 'order',
                        navigationId: $order->id
                    );
                    Log::info('Customer notification sent for order placed', [
                        'order_id' => $order->id,
                        'customer_id' => $order->user_id
                    ]);
                } catch (\Exception $e) {
                    Log::error('Failed to send customer notification for order placed', [
                        'order_id' => $order->id,
                        'error' => $e->getMessage()
                    ]);
                }

                // Send push notification to admin about new order
                try {
                    AdminNotificationService::notifyNewOrder($order->id, "#{$order->id}");
                    Log::info('Admin notification sent for new order', [
                        'order_id' => $order->id
                    ]);
                } catch (\Exception $e) {
                    Log::error('Failed to send admin notification for new order', [
                        'order_id' => $order->id,
                        'error' => $e->getMessage()
                    ]);
                }

                // Send notification to sellers
                try {
                    Log::info("Dispatching seller notification job for order", ['order_id' => $order->id]);
                    dispatch(new SendSellerOrderNotification($order->id))->afterResponse();
                } catch (\Exception $e) {
                    Log::error("Place order - Seller notification job error:", [$e->getMessage()]);
                }

                try {

                    Log::info("Place order send mail :", [$order]);
                    dispatch(new SendEmailJob($order))->afterResponse();
                } catch (\Exception $e) {
                    Log::error("Place order Send mail error :", [$e->getMessage()]);
                }

                //Place Order Send SMS
                try {
                    CommonHelper::sendSmsOrderStatus($order, $order->active_status);
                } catch (\Exception $e) {
                    Log::error("Place order SMS error :", [$e->getMessage()]);
                }

            }
            try {
                if (!$item_details->isEmpty()) {
                    CommonHelper::sendLowStockNotification($item_details);
                }
            } catch (\Exception $e) {
                Log::error("Low stock notification error: " . $e->getMessage());
            }

            // Check for claimable milestone rewards and claim them
            try {
                $cartMetaData = $order->cart_metadata;
                $claimableMilestoneAmount = $cartMetaData['billing_summary']['claimable_milestone_amount'] ?? 0;

                if ($claimableMilestoneAmount > 0) {
                    Log::info("Milestone Claim - Attempting to claim milestones for order_id: {$order->id}, user_id: {$user_id}, claimable_amount: {$claimableMilestoneAmount}");
                    $claimResult = UserOfferClaimService::claimWithOrder($order->id, $user_id);
                    Log::info("Milestone Claim - Result: ", $claimResult);
                } else {
                    Log::info("Milestone Claim - No claimable milestones for order_id: {$order->id}, user_id: {$user_id}, claimable_amount: {$claimableMilestoneAmount}");
                }
            } catch (\Exception $e) {
                Log::error("Milestone Claim error: " . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            }

            if ($payment_method == Transaction::$paymentTypeCod) {
                $order_status = array();
                $order_status['order_id'] = $order->id;
                $order_status['order_item_id'] = 0;
                // PREORDER - Use preorder status for preorders
                if ($is_preorder) {
                    $order_status['status'] = OrderStatusList::$preorderPending;
                } else {
                    $order_status['status'] = ($order_type == 'selfpickup') ? OrderStatusList::$selfPickupPending : OrderStatusList::$received;
                }
                $order_status['created_by'] = $user_id;
                $order_status['user_type'] = OrderStatus::$userTypeUser;
                CommonHelper::setOrderStatus($order_status);
                return response()->json([
                    'status' => 1,
                    'message' => 'success',
                    'is_pre_order' => $is_preorder ? 1 : 0,
                    'total' => (string) $order->final_total,
                    'data' => [
                        'order_id' => (string) $order->id,
                        'delivery_pin' => $order->delivery_pin
                    ]
                ]);

            } else {
                return response()->json([
                    'status' => 1,
                    'message' => 'success',
                    'is_pre_order' => $is_preorder ? 1 : 0,
                    'total' => (string) $order->final_total,
                    'data' => [
                        'order_id' => (string) $order->id,
                        'delivery_pin' => $order->delivery_pin
                    ]
                ]);
            }
        } catch (\Exception $e) {
            Log::error("Place order error: " . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return CommonHelper::responseError(__('could_not_place_order_try_again'));
        }

    }

    /**
     * Place order with Paytm payment (Payment verified BEFORE order creation)
     *
     * Flow:
     * 1. User pays via Paytm SDK (gets transaction_id)
     * 2. verify-payment API verifies and stores in paytm_transactions
     * 3. THIS API creates order and links payment
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function placeOrderWithPaytm(Request $request)
    {
        try {
            // Validate request - transaction_id is REQUIRED
            $validator = Validator::make($request->all(), [
                'transaction_id' => 'required|string',
                'total' => 'required',
                'delivery_charge' => 'required_if:order_type,doorstep',
                'delivery_time' => 'required_if:order_type,doorstep',
                'final_total' => 'required',
                'address_id' => 'required_if:order_type,doorstep',
                'quantity' => 'nullable',  // Can be from cart or custom_combos
                'product_variant_id' => 'nullable',
                'order_note' => 'nullable|string|max:256',
                'order_type' => 'required|in:doorstep,selfpickup'
            ]);

            if ($validator->fails()) {
                return CommonHelper::responseError($validator->errors()->first());
            }

            $user = auth()->user();

            // STEP 1: Verify Paytm payment exists and is valid
            $paytmTransaction = PaytmTransaction::where('txn_id', $request->transaction_id)
                ->where('user_id', $user->id)
                ->first();

            if (!$paytmTransaction) {
                Log::error('Paytm transaction not found', [
                    'transaction_id' => $request->transaction_id,
                    'user_id' => $user->id
                ]);
                return CommonHelper::responseError('Payment verification failed. Transaction not found.');
            }

            // Verify payment is successful
            if (!$paytmTransaction->isSuccessful()) {
                Log::error('Paytm transaction not successful', [
                    'transaction_id' => $request->transaction_id,
                    'status' => $paytmTransaction->status
                ]);
                return CommonHelper::responseError('Payment was not successful. Please try again.');
            }

            // Verify payment is captured
            if (!$paytmTransaction->isCaptured()) {
                Log::error('Paytm transaction not captured', [
                    'transaction_id' => $request->transaction_id
                ]);
                return CommonHelper::responseError('Payment not captured. Please contact support.');
            }

            // Verify payment not already used
            if ($paytmTransaction->order_id !== null) {
                Log::error('Paytm transaction already used', [
                    'transaction_id' => $request->transaction_id,
                    'existing_order_id' => $paytmTransaction->order_id
                ]);
                return CommonHelper::responseError('This payment has already been used for another order.');
            }

            // Verify amount matches (optional but recommended)
            if ($request->has('final_total') && abs($paytmTransaction->amount - floatval($request->final_total)) > 0.01) {
                Log::error('Paytm amount mismatch', [
                    'transaction_amount' => $paytmTransaction->amount,
                    'order_amount' => $request->final_total
                ]);
                return CommonHelper::responseError('Payment amount does not match order amount.');
            }

            // STEP 2: Create order using SAME logic as placeOrder (COD flow)
            // Add payment_method to request
            $request->merge(['payment_method' => 'Paytm']);

            // Call the existing placeOrder function logic
            // (We'll reuse the existing code by calling placeOrder, but override the payment status)

            // Create order via existing logic
            $orderResponse = $this->placeOrder($request);

            // Check if order creation was successful
            $orderData = json_decode($orderResponse->getContent(), true);

            if (!isset($orderData['status']) || $orderData['status'] != 1) {
                Log::error('Order creation failed after payment', [
                    'transaction_id' => $request->transaction_id,
                    'error' => $orderData['message'] ?? 'Unknown error'
                ]);
                return CommonHelper::responseError('Order creation failed: ' . ($orderData['message'] ?? 'Unknown error'));
            }

            $orderId = $orderData['data']['order_id'];
            $order = Order::find($orderId);

            if (!$order) {
                Log::error('Order not found after creation', ['order_id' => $orderId]);
                return CommonHelper::responseError('Order creation failed.');
            }

            // STEP 3: Update order status to CONFIRMED (not payment_pending)
            // Because payment is already verified!
            $order_type = $request->order_type ?? 'doorstep';
            $is_preorder = $order->is_pre_order ?? false;

            if ($is_preorder) {
                $confirmed_status = OrderStatusList::$preorderPending;
            } else if ($order_type == 'selfpickup') {
                $confirmed_status = OrderStatusList::$selfPickupPending;
            } else {
                $confirmed_status = OrderStatusList::$received;
            }

            $order->active_status = $confirmed_status;
            $order->payment_method = 'Paytm';  // Update payment method
            $order->transaction_id = $paytmTransaction->paytm_txn_id;  // Store Paytm transaction ID
            $order->save();

            // Update order status
            $order_status = array();
            $order_status['order_id'] = $order->id;
            $order_status['order_item_id'] = 0;
            $order_status['status'] = $confirmed_status;
            $order_status['created_by'] = $user->id;
            $order_status['user_type'] = OrderStatus::$userTypeUser;
            CommonHelper::setOrderStatus($order_status);

            // STEP 4: Link Paytm transaction to order
            $paytmTransaction->update(['order_id' => $order->id]);

            Log::info('Paytm transaction linked to order', [
                'transaction_id' => $request->transaction_id,
                'order_id' => $order->id
            ]);

            // STEP 5: Create record in transactions table (for consistency)
            Transaction::create([
                'user_id' => $user->id,
                'order_id' => $order->id,
                'type' => Transaction::$paymentTypePaytm,
                'txn_id' => $paytmTransaction->paytm_txn_id ?? $paytmTransaction->txn_id,
                'amount' => $paytmTransaction->amount,
                'status' => Transaction::$statusSuccess,
                'message' => 'Payment successful via Paytm',
                'transaction_date' => $paytmTransaction->transaction_date ?? now(),
                'created_at' => now(),
                'updated_at' => now()
            ]);

            Log::info('Order placed successfully with Paytm payment', [
                'order_id' => $order->id,
                'transaction_id' => $request->transaction_id,
                'amount' => $paytmTransaction->amount
            ]);

            // STEP 6: Return success response
            return response()->json([
                'status' => 1,
                'message' => 'Order placed successfully',
                'is_pre_order' => $is_preorder ? 1 : 0,
                'total' => (string) $order->final_total,
                'data' => [
                    'order_id' => (string) $order->id,
                    'delivery_pin' => $order->delivery_pin,
                    'payment_status' => 'paid',
                    'payment_method' => 'Paytm',
                    'transaction_id' => $paytmTransaction->paytm_txn_id
                ]
            ]);

        } catch (\Exception $e) {
            Log::error("Place order with Paytm error: " . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
                'transaction_id' => $request->transaction_id ?? null
            ]);
            return CommonHelper::responseError(__('could_not_place_order_try_again'));
        }
    }

    public function deletePaymentPendingOrder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required'
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $order = Order::find($request->order_id);
        $user = auth()->user();
        $user_wallet_balance = $user->balance;

        if (empty($order)) {
            return CommonHelper::responseError("Order Not found!");
        }

        if ($order->active_status != OrderStatusList::$paymentPending) {
            $statusName = OrderStatusList::where('id', $order->active_status)->value('status');
            return CommonHelper::responseError("Now you order status is " . $statusName);

        }

        DB::beginTransaction();
        try {
            // Retrieve the order items before deletion
            $orderItems = OrderItem::where('order_id', $request->order_id)->get();

            // Delete the order items
            OrderItem::where('order_id', $request->order_id)->delete();

            // Loop through each order item and update the stock of the corresponding product variant
            foreach ($orderItems as $item) {
                $productVariant = ProductVariant::find($item->product_variant_id);

                if ($productVariant) {
                    // Assuming you are adding the quantity back to stock
                    $productVariant->stock += $item->quantity;
                    $productVariant->status = 1;
                    $productVariant->save();
                }
            }
            $order->delete();


            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            Log::info("Error : " . $e->getMessage());
            throw $e;
            return CommonHelper::responseError("Something Went Wrong!");
        }
        return CommonHelper::responseSuccess("Order deleted successfully");
    }

    public function orderTest(Request $request)
    {
        $result = CommonHelper::findGoogleMapDistanceLocal(23.24114205388701, 69.66720847135304, 23.235700208395272, 69.7287490771754);
        return CommonHelper::responseWithData($result);
    }

    public function initiateTransaction(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'payment_method' => 'required',
            'type' => 'required',
            'order_id' => 'required_if:type,order',
            'wallet_amount' => 'required_if:type,wallet',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        if ($request->type == 'order') {
            $order = Order::with('user')->where('id', $request->order_id)
                ->first();
            if (!$order) {
                return CommonHelper::responseError("Order not found!");
            }
        }

        $out['payment_method'] = $request->payment_method;

        $transaction_id = "";

        if ($request->payment_method == "Razorpay") {

            \Log::error("payment_method = " . $request->payment_method);

            $transaction_id = TransactionHelper::createOrderonRazorpay($request->type, $request->order_id ?? 0, $request->wallet_amount ?? 0);
            if ($transaction_id == "") {
                return CommonHelper::responseError("Error while communicating with razorpay server");
            }
        } else if ($request->payment_method == "Paypal") {

            $user_id = auth()->user()->id;
            if ($request->type == 'order') {
                $order_id = $request->order_id;
                $order = Order::where('id', $order_id)->first();

                if (!empty($order)) {
                    if ($request->request_from == 'website') {
                        $out['paypal_redirect_url'] = url('customer/paypal_payment_url?user_id=' . $user_id . '&order_id=' . $order_id . '&type=order&request_from=website');
                    } else {
                        $out['paypal_redirect_url'] = url('customer/paypal_payment_url?user_id=' . $user_id . '&order_id=' . $order_id . '&type=order');
                    }
                }
            } elseif ($request->type == 'wallet') {
                if ($request->request_from == 'website') {
                    $out['paypal_redirect_url'] = url('customer/paypal_payment_url?user_id=' . $user_id . '&wallet_amount=' . $request->wallet_amount . '&type=wallet&request_from=website');
                } else {
                    $out['paypal_redirect_url'] = url('customer/paypal_payment_url?user_id=' . $user_id . '&wallet_amount=' . $request->wallet_amount . '&type=wallet');
                }
            }


        } else if ($request->payment_method == "Stripe") {

            \Log::error("payment_method = " . $request->payment_method);

            if ($request->type == 'order') {
                $order_id = $request->order_id;
                $order = Order::where('id', $order_id)->first();

                if (!empty($order)) {
                    $response = TransactionHelper::createOrderOnStripe($order->final_total);
                }
            } elseif ($request->type == 'wallet') {
                $response = TransactionHelper::createOrderOnStripe($request->wallet_amount);

            }

            if ($response == "") {
                return CommonHelper::responseError("Error while communicating with Stripe server");
            }
            $out = $response->toArray();

        } else if ($request->payment_method == "Midtrans") {
            $midtrans_redirect_url = TransactionHelper::createOrderonMidtrans($request->type, $request->order_id ?? 0, $request->wallet_amount ?? 0);
            if ($midtrans_redirect_url == "") {
                return CommonHelper::responseError("Error while communicating with Midtrans server");
            }


            // Return the URL for redirection
            return CommonHelper::responseWithData($midtrans_redirect_url);
        } else if ($request->payment_method == "Phonepe") {
            $phonepay_data = TransactionHelper::createOrderonPhonepe($request->type, $request->order_id ?? 0, $request->wallet_amount ?? 0);
            if ($phonepay_data == "") {
                return CommonHelper::responseError("Error while communicating with Phonepe server");
            }
            // Return the URL for redirection
            return $phonepay_data;
        } else if ($request->payment_method == "Cashfree") {
            $cashfree_redirect_url = TransactionHelper::createOrderonCashfree($request->type, $request->order_id ?? 0, $request->wallet_amount ?? 0);
            if ($cashfree_redirect_url == "") {
                return CommonHelper::responseError("Error while communicating with Cashfree server");
            }
            // Return the URL for redirection
            return CommonHelper::responseWithData($cashfree_redirect_url);
        } else if ($request->payment_method == "Paytabs") {
            $paytabs_redirect_url = TransactionHelper::createOrderonPaytabs($request->type, $request->order_id ?? 0, $request->wallet_amount ?? 0);

            if ($paytabs_redirect_url == "") {
                return CommonHelper::responseError("Error while communicating with Paytabs server");
            }
            // Return the URL for redirection
            return CommonHelper::responseWithData($paytabs_redirect_url);
        } else {
            return CommonHelper::responseError("Invalid payment methods.");

        }
        if ($request->type == 'order') {
            $order->payment_method = $request->payment_method;
            $order->save();
        }

        if ($transaction_id != "") {
            $out['transaction_id'] = $transaction_id;
        }
        return CommonHelper::responseWithData($out);
    }

    /*Paypal Start*/
    public function paypalPaymentUrl(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required',
            'type' => 'required',
            'order_id' => 'required_if:type,order',
            'wallet_amount' => 'required_if:type,wallet',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $app_name = Setting::get_value('app_name');
        $user = User::where('id', $request->user_id)->first();
        if ($request->type == 'order') {
            $order = Order::where('id', $request->order_id)->first();
            $order_amount = $order->final_total;
            $order_id = $order->id;
        } elseif ($request->type == 'wallet') {
            $order_amount = $request->wallet_amount;
            $order_id = 'wallet_recharge-' . $user->id;
        }

        if ($order_amount) {

            header("Content-Type: html");

            $data['user'] = $user;

            $data['payment_type'] = "paypal";

            $websiteUrl = Setting::where('variable', 'website_url')->value('value');
            $websiteUrl = trim($websiteUrl, '/');
            $returnURL = $request->request_from == 'website' ? url($websiteUrl . '/web-payment-status?amount=' . $order_amount . '&status=pending&type=wallet') : url('customer/paypal_redirect/pending');
            if ($request->type == 'order') {
                if ($request->request_from == 'website') {
                    $returnURL = url($websiteUrl . '/web-payment-status?amount=' . $order_amount . '&status=pending&type=order&order_id=' . $order_id);
                } else {
                    $returnURL = url('customer/paypal_redirect/pending');
                }
            } elseif ($request->type == 'wallet') {
                if ($request->request_from == 'website') {
                    $returnURL = url($websiteUrl . '/web-payment-status?amount=' . $order_amount . '&status=pending&type=wallet');
                } else {
                    $returnURL = url('customer/paypal_redirect/pending');
                }
            }
            //$returnURL = url('customer/paypal_redirect/pending') ;
            $cancelURL = url('customer/paypal_redirect/fail');
            $pendingURL = url('customer/paypal_redirect/pending');
            $notifyURL = url('customer/ipn');
            $txn_id = time() . "-" . rand();
            // Get current user ID from the session
            $userID = $data['user']['id'];
            //$order_id = $order_id;
            $payeremail = $data['user']['email'];
            // $userID = $data['user']->id;

            $paypal = new Paypal();
            // Add fields to paypal form
            $paypal->add_field('return', $returnURL);
            $paypal->add_field('pending', $pendingURL);
            $paypal->add_field('cancel_return', $cancelURL);
            $paypal->add_field('notify_url', $notifyURL);
            $paypal->add_field('item_name', $app_name);
            $paypal->add_field('custom', $userID . '|' . $payeremail);
            $paypal->add_field('item_number', $order_id);
            $paypal->add_field('amount', $order_amount);

            // Render paypal form
            $paypal->paypal_auto_form();
        }

    }

    public function paypalRedirect(Request $request)
    {
        $paypalInfo = $request->all();
        $website_url = config('app.website_url');

        Log::info("paypalRedirect : ", [$paypalInfo]);
        $order_status = Transaction::$statusFailed;
        if (!empty($paypalInfo) && isset($paypalInfo['payment_status']) && strtolower($paypalInfo['payment_status']) == "completed") {
            $response['error'] = false;
            $response['message'] = "Payment Completed Successfully";
            $response['data'] = $paypalInfo;
            $order_status = Transaction::$statusSuccess;

        } elseif (!empty($paypalInfo) && isset($paypalInfo['payment_status']) && strtolower($paypalInfo['payment_status']) == "authorized") {
            $response['error'] = false;
            $response['message'] = "Your payment is has been Authorized successfully. We will capture your transaction within 30 minutes, once we process your order. After successful capture coins wil be credited automatically.";
            $response['data'] = $paypalInfo;
            $order_status = Transaction::$statusSuccess;

        } elseif (!empty($paypalInfo) && isset($paypalInfo['payment_status']) && strtolower($paypalInfo['payment_status']) == "pending") {
            $response['error'] = false;
            $response['message'] = "Your payment is pending and is under process. We will notify you once the status is updated.";
            $response['data'] = $paypalInfo;

        } else {
            $response['error'] = true;
            $response['message'] = "Payment Cancelled / Declined ";
            $response['data'] = (isset($paypalInfo)) ? $paypalInfo : "";

        }

        echo "<html>
        <body>
        Redirecting...!
        </body>
        <script>
            //const parentOrigin = window.opener.location.origin;
            const parentOrigin = '" . $website_url . "';
            console.log('Parent origin:', parentOrigin);
            console.log('started')
            window.addEventListener('load', function(){
            console.log('loaded')
            window.opener.postMessage('" . $order_status . "',parentOrigin);
            window.close();
            });
        </script>
        </html>";
    }

    public function ipn(Request $request)
    {
        $paypalInfo = $request->all();
        Log::info("Paypal IPN : ", [$paypalInfo]);

        if (!empty($paypalInfo)) {
            // Validate and get the ipn response
            $paypal = new Paypal();
            $ipnCheck = $paypal->validate_ipn($paypalInfo);
            // Check whether the transaction is valid
            if ($ipnCheck) {

                $userData = explode('|', $paypalInfo['custom']);

                //for react app
                if (is_null($paypalInfo["item_number"]) && isset($userData[2])) {
                    $paypalInfo["item_number"] = $userData[2];
                }

                $order_id = $paypalInfo["item_number"];
                /* if its not numeric then it is for the wallet recharge */
                if (
                    $paypalInfo["payment_status"] == 'Completed' &&
                    !is_numeric($order_id) && strpos($order_id, "wallet_recharge") !== false
                ) {
                    $temp = explode("-", $order_id); /* Order ID format for wallet recharge >> wallet_recharge-{user_id}  */
                    if (isset($temp[1]) && is_numeric($temp[1]) && !empty($temp[1] && $temp[1] != '')) {
                        $user_id = $temp[1];
                    } else {
                        $user_id = 0;
                    }
                    $amount = $paypalInfo["mc_gross"];
                    /* IPN for user wallet recharge */

                    $data['payment_type'] = "Paypal";
                    $data['user_id'] = $user_id;
                    $data['order_id'] = $order_id;
                    $data['type'] = "credit";
                    $data['txn_id'] = $paypalInfo["txn_id"];
                    $data['payu_txn_id'] = "";
                    $data['amount'] = $amount;
                    $data['status'] = Transaction::$statusSuccess;
                    $data['message'] = "Wallet successfully recharged.";
                    $data['transaction_date'] = date('Y-m-d H:i:s');
                    $wallet_transaction = WalletTransaction::create($data);

                    if ($data['status'] == WalletTransaction::$statusSuccess) {
                        $newBalance = CommonHelper::addUserWalletBalance($amount, $user_id);
                        $data['user_balance'] = $newBalance;
                        return CommonHelper::responseSuccessWithData("Amount Added in Wallet Successfully", $data);
                    } else {
                        return CommonHelper::responseError("Transaction Failed, Please try again!");
                    }


                } else {
                    /* IPN for normal Order  */
                    // Insert the transaction data in the database
                    $userData = explode('|', $paypalInfo['custom']);


                    $data['transaction_type'] = 'Transaction';
                    $data['user_id'] = $userData[0];
                    $data['order_id'] = $paypalInfo["item_number"];
                    $data['type'] = 'paypal';
                    $data['txn_id'] = $paypalInfo["txn_id"];
                    $data['payu_txn_id'] = "";
                    $data['amount'] = $paypalInfo["mc_gross"];
                    $data['status'] = Transaction::$statusSuccess;
                    $data['message'] = 'Payment Verified';
                    $data['transaction_date'] = date('Y-m-d H:i:s');

                    $order = Order::where('id', $data['order_id'])->first();
                    if ($paypalInfo["payment_status"] == 'Completed') {

                        $transaction = Transaction::create($data);
                        if ($order->order_type == 'selfpickup') {
                            $order->active_status = OrderStatusList::$selfPickupPending;
                        } else {
                            $order->active_status = OrderStatusList::$received;
                        }
                        $order->transaction_id = $transaction->id ?? 0;
                        $order->save();

                    } else if (
                        $paypalInfo["payment_status"] == 'Expired' || $paypalInfo["payment_status"] == 'Failed'
                        || $paypalInfo["payment_status"] == 'Refunded' || $paypalInfo["payment_status"] == 'Reversed'
                    ) {
                        /* if transaction wasn't completed successfully then cancel the order and transaction */
                        $data['transaction_type'] = 'Transaction';
                        $data['user_id'] = $userData[0];
                        $data['order_id'] = $paypalInfo["item_number"];
                        $data['type'] = 'paypal';
                        $data['txn_id'] = $paypalInfo["txn_id"];
                        $data['payu_txn_id'] = "";
                        $data['amount'] = $paypalInfo["mc_gross"];
                        $data['currency_code'] = $paypalInfo["mc_currency"];
                        $data['status'] = $paypalInfo["payment_status"];
                        $data['message'] = 'Payment could not be completed due to one or more reasons!';
                        $data['transaction_date'] = date('Y-m-d H:i:s');

                        $transaction = Transaction::create($data);
                        //Mark payment received
                        $order->active_status = OrderStatusList::$cancelled;
                        $order->transaction_id = $transaction->id ?? 0;
                        $order->save();

                    }
                }
            }
        }
    }
    /*Paypal End*/

    public function addTransaction(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required',
            'order_id' => 'required_if:type,order',
            'wallet_amount' => 'required_if:type,wallet',
            'device_type' => 'required',
            'app_version' => 'required',
            'payment_method' => 'required',
            'transaction_id' => 'required'
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        $user = auth()->user();
        if ($request->type == 'order') {
            $order = Order::withTrashed()->where('id', $request->order_id)->first();
            if (!$order) {
                return CommonHelper::responseError("Invalid Order Id");
            }
        }

        // Save Device details
        if ($request->device_type) {
            $app_usage = array();
            $app_usage['order_id'] = $order->id ?? 'wallet';
            $app_usage['device_type'] = $request->device_type;
            $app_usage['app_version'] = $request->app_version;
            AppUsage::create($app_usage);
        }

        $status = Transaction::$statusFailed;

        $txn_id = $request->transaction_id;

        if (
            isset($request->payment_method) && in_array(
                $request->payment_method,
                array(
                    Transaction::$paymentTypeRazorpay,
                    Transaction::$paymentTypePaystack,
                    Transaction::$paymentTypeStripe,
                    Transaction::$paymentTypePaytm,
                    Transaction::$paymentTypeMidtrans
                )
            )
        ) {


            if ($request->payment_method == Transaction::$paymentTypeRazorpay) {
                $signatureIsVaid = TransactionHelper::verifyRazorpaySignature(
                    $request->razorpay_order_id,
                    $request->razorpay_payment_id,
                    $request->razorpay_signature
                );

                if (!$signatureIsVaid) {
                    $status = Transaction::$statusSuccess;
                }

            } else if ($request->payment_method == Transaction::$paymentTypePaystack) {

                $paystack = new Paystack();
                $payment = $paystack->verify_transaction($txn_id);

                Log::info("payment Paystack :  ", [$payment]);

                if (!empty($payment)) {
                    $payment = json_decode($payment, true);
                    if (isset($payment['data']['status']) && $payment['data']['status'] == 'success') {
                        $status = Transaction::$statusSuccess;
                    }
                }
            } else if ($request->payment_method == Transaction::$paymentTypeStripe) {

                try {

                    $stripe_secret_key = Setting::get_value('stripe_secret_key');
                    $stripe = new \Stripe\StripeClient(
                        $stripe_secret_key
                    );

                    $paymentIntent = $stripe->paymentIntents->retrieve(
                        $txn_id,
                        []
                    );

                    $status = Transaction::$statusSuccess;


                } catch (\Exception $e) {
                    Log::error("Stripe Error : ", [$e]);
                    return CommonHelper::responseError($e->getMessage());
                }
            } else if ($request->payment_method == Transaction::$paymentTypePaytm) {

                $payment = Paytm::transaction_status($order->id);

                if (!empty($payment)) {
                    $payment = json_decode($payment, true);

                    if (isset($payment['body']['resultInfo']['resultCode']) && ($payment['body']['resultInfo']['resultCode'] == '01' && $payment['body']['resultInfo']['resultStatus'] == 'TXN_SUCCESS')) {
                        $status = Transaction::$statusSuccess;
                    } elseif (isset($payment['body']['resultInfo']['resultCode']) && ($payment['body']['resultInfo']['resultStatus'] == 'TXN_FAILURE')) {
                        $status = Transaction::$statusFailed;
                    } else if (isset($payment['body']['resultInfo']['resultCode']) && ($payment['body']['resultInfo']['resultStatus'] == 'PENDING')) {
                        //PENDING
                    } else {
                        $status = Transaction::$statusFailed;
                    }
                } else {
                    $status = Transaction::$statusFailed;
                }


            } else if ($request->payment_method == Transaction::$paymentTypePaypal) {

                $transaction_id = $request->transaction_id;

                $paypalClient = new PaypalClient();
                $server_output = $paypalClient->getPayment($transaction_id);
                $result = json_decode($server_output, 1);

                \Log::info('-------------Paypal start---------------');
                \Log::info('paypal result : ', [$result]);

                $status = Transaction::$statusFailed;

                if (isset($result['state']) && $result['state'] == 'approved') {
                    $status = Transaction::$statusSuccess;
                    $gateway_amount = $result['transactions'][0]['amount']['total'];
                }
            }
            if ($request->type == 'order') {
                $transactionData = array();
                $transactionData['user_id'] = $order->user_id;
                $transactionData['order_id'] = $order->id;
                $transactionData['type'] = $request->payment_method; // Razorpay / Paystack / Paypal
                $transactionData['txn_id'] = $txn_id;
                $transactionData['payu_txn_id'] = "";
                $transactionData['amount'] = $order->final_total;
                $transactionData['status'] = $status;
                $transactionData['message'] = "";
                $transactionData['transaction_date'] = date('Y-m-d H:i:s');

                $transaction = Transaction::create($transactionData);
                if ($status == Transaction::$statusSuccess) {

                    if ($order->order_type == 'selfpickup') {
                        $order->active_status = OrderStatusList::$selfPickupPending;
                    } else {
                        $order->active_status = OrderStatusList::$received;
                    }
                    $order->transaction_id = $transaction->id ?? 0;
                    $order->save();

                    return CommonHelper::responseSuccess("Order Placed Successfully");
                } else {
                    return CommonHelper::responseError("Transaction Failed, Please try again!");
                }
            } elseif ($request->type == 'wallet') {

                $walletTransactionData = array();
                $walletTransactionData['user_id'] = $user->id;
                $walletTransactionData['order_id'] = '';
                $walletTransactionData['type'] = 'credit';
                $walletTransactionData['payment_type'] = $request->payment_method; // Razorpay / Paystack / Paypal
                $walletTransactionData['txn_id'] = $txn_id;
                $walletTransactionData['amount'] = $request->wallet_amount;
                $walletTransactionData['status'] = $status;
                $walletTransactionData['message'] = "Wallet successfully recharged.";
                $walletTransactionData['transaction_date'] = date('Y-m-d H:i:s');
                $wallet_transaction = WalletTransaction::create($walletTransactionData);
                if ($status == WalletTransaction::$statusSuccess) {

                    //Mark credit amount in user balance
                    $balance = $user->balance;
                    $newBalance = $balance + $request->wallet_amount;

                    $user = User::where('id', $user->id)->update(['balance' => $newBalance]);
                    $data = array();
                    $data['user_balance'] = $newBalance;
                    return CommonHelper::responseSuccessWithData("Amount Added in Wallet Successfully", $data);
                } else {
                    return CommonHelper::responseError("Transaction Failed, Please try again!");
                }
            }
        }


    }

    public function updateOrderStatus(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_item_id' => 'required',
            'status' => 'required',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $order_item_id = $request->order_item_id;
        $order_item = OrderItem::select("*")->where("id", $order_item_id)->first();


        if (empty($order_item)) {
            return CommonHelper::responseError('Order Item Not found.');
        }

        if (isset($request->order_id)) {
            $id = $request->order_id;
        } else {
            $id = $order_item->order_id;
        }
        $order = Order::select("*")->where("id", $id)->first();
        if (empty($order)) {
            return CommonHelper::responseError('Order Not found.');
        }

        $user = User::select("*")->where('id', $order->user_id)->first();
        if (empty($user)) {
            return CommonHelper::responseError('User Not found.');
        }

        $postStatus = $request->status;
        $status = OrderStatusList::where('id', $postStatus)->first();
        if (empty($status)) {
            return CommonHelper::responseError('Status Not found.');
        }
        $selectedStatus = $status->status;
        if ($order_item->active_status == $postStatus) {
            return CommonHelper::responseError("This Order Item is already " . $selectedStatus . "!");
        }


        /* Cannot return order unless it is delivered */
        if (CommonHelper::isOrderItemReturned($order_item->active_status, $postStatus)) {
            return CommonHelper::responseError(__('cannot_return_order_unless_it_is_delivered'));
        }

        /* Could not update order status once cancelled or returned! */
        if (CommonHelper::isOrderItemCancelled($order_item_id)) {
            return CommonHelper::responseError(__('could_not_update_order_status_cancelled_or_returned'));
        }

        if (!empty($postStatus)) {

            if ($postStatus == OrderStatusList::$delivered) {

                if ($order->payment_method == Transaction::$paymentTypeCod) {

                    // Save Device details
                    if ($request->device_type) {
                        $app_usage = array();
                        $app_usage['order_id'] = $order->id;
                        $app_usage['device_type'] = $request->device_type;
                        $app_usage['app_version'] = $request->app_version;
                        AppUsage::create($app_usage);
                    }

                    $transactionData = array();
                    $transactionData['user_id'] = $order->user_id;
                    $transactionData['order_id'] = $order->id;
                    $transactionData['type'] = "COD";
                    $transactionData['txn_id'] = round(microtime(true) * 1000);
                    $transactionData['payu_txn_id'] = "";
                    $transactionData['amount'] = $order->total;
                    $transactionData['status'] = Transaction::$statusSuccess;
                    $transactionData['message'] = "";
                    $transactionData['transaction_date'] = date('Y-m-d H:i:s');
                    $transaction = Transaction::create($transactionData);
                    $order->transaction_id = $transaction->id ?? 0;
                }

                $order->active_status = OrderStatusList::$delivered;
                $order->save();

                $order_item->active_status = OrderStatusList::$delivered;
                $order_item->save();

                CommonHelper::sendOrderItemStatusMailNotification($order_item, 'order_item_status_update');
                return CommonHelper::responseSuccess("Order Status Updated Successfully");
                /*Send Notification*/
            } else if ($postStatus == OrderStatusList::$cancelled) {
                // Check if any seller has started preparing the order
                $sellerStartedPreparing = DB::table('order_seller_status_tracking')
                    ->where('order_id', $order->id)
                    ->where('is_seller_started_preparing', 1)
                    ->exists();

                if ($sellerStartedPreparing) {
                    return CommonHelper::responseError('Order cannot be cancelled as the seller has already started preparing your order.');
                }

                DB::beginTransaction();
                // try {

                $itemNum = OrderItem::where("order_id", $order->id)->count();
                $lastItemNum = 0;
                if ($itemNum > 1) {
                    $lastItemNum = OrderItem::where("order_id", $order->id)->where('status', '!=', OrderStatusList::$cancelled)->count();
                }

                if ($itemNum == 1 || $lastItemNum == 1) {
                    $order_status = array();
                    $order_status['order_id'] = $order->id;
                    $order_status['order_item_id'] = $order_item->id;
                    $order_status['status'] = $postStatus;
                    $order_status['created_by'] = auth()->user()->id;
                    $order_status['user_type'] = OrderStatus::$userTypeUser;
                    CommonHelper::setOrderStatus($order_status);
                    $order->active_status = OrderStatusList::$cancelled;

                    $order->save();
                }
                $user = User::find($order->user_id);
                $currentBalance = $user->balance;

                // Initialize additional charges total at the beginning
                $additional_charges = json_decode($order->additional_charges, true) ?? [];
                $additional_charges_total = array_sum(array_column($additional_charges, 'amount'));

                if ($order->payment_method !== Transaction::$paymentTypeCod) {
                    if ($itemNum == 1 || $lastItemNum == 1) {
                        // For single/last item - refund entire wallet balance + remaining_final (excluding additional charges)
                        $refundable = $order->wallet_balance + ($order->remaining_final - $additional_charges_total);

                        // Process refund
                        $new_balance = $currentBalance + $refundable;
                        CommonHelper::updateUserWalletBalance($new_balance, $order->user_id);
                        CommonHelper::addWalletTransaction($order->id, $order_item->id, $order->user_id, 'credit', $refundable, 'Order Item Cancelled');

                        // Update order
                        $order->remaining_total = 0;
                        $order->remaining_final = $additional_charges_total;
                        $order->wallet_balance = 0;
                        $order->save();
                    } else {
                        // For multiple items - calculate refund
                        $total_items_amount = OrderItem::where('order_id', $order->id)
                            ->where('active_status', '!=', OrderStatusList::$cancelled)
                            ->sum('sub_total');

                        // Calculate refund amount based on the item being cancelled
                        $refundable = $order_item->sub_total;

                        // If wallet was used, calculate proportional wallet refund
                        if ($order->wallet_balance > 0) {
                            $wallet_portion = $order_item->sub_total / $total_items_amount;
                            $wallet_refund = $order->wallet_balance * $wallet_portion;
                            $refundable = $order_item->sub_total;

                            // Update wallet balance
                            $new_balance = $currentBalance + $wallet_refund;
                            CommonHelper::updateUserWalletBalance($new_balance, $order->user_id);
                            CommonHelper::addWalletTransaction($order->id, $order_item->id, $order->user_id, 'credit', $wallet_refund, 'Order Item Cancelled');

                            // Update order wallet balance
                            $order->wallet_balance = $order->wallet_balance - $wallet_refund;
                        }

                        // Process main refund
                        if ($refundable > 0) {
                            CommonHelper::addWalletTransaction($order->id, $order_item->id, $order->user_id, 'credit', $refundable, 'Order Item Amount Refunded');
                            $new_balance = $currentBalance + $refundable;
                            CommonHelper::updateUserWalletBalance($new_balance, $order->user_id);
                        }

                        // Update order
                        $order->remaining_total = floatval($order->remaining_total) - floatval($order_item->sub_total);
                        $order->remaining_final = floatval($order->remaining_total) + $additional_charges_total;
                        $order->save();
                    }
                } else {
                    // For COD orders - only refund wallet balance if used
                    if ($order->wallet_balance > 0) {
                        if ($itemNum == 1 || $lastItemNum == 1) {
                            // For single/last item - refund entire wallet balance
                            $refundable = $order->wallet_balance;

                            // Process wallet refund
                            $new_balance = $currentBalance + $refundable;
                            CommonHelper::updateUserWalletBalance($new_balance, $order->user_id);
                            CommonHelper::addWalletTransaction($order->id, $order_item->id, $order->user_id, 'credit', $refundable, 'Order Item Cancelled');

                            // Update order
                            $order->remaining_total = 0;
                            $order->remaining_final = $additional_charges_total;
                            $order->wallet_balance = 0;
                        } else {
                            // For multiple items - calculate proportional wallet refund
                            $total_items_amount = OrderItem::where('order_id', $order->id)
                                ->where('active_status', '!=', OrderStatusList::$cancelled)
                                ->sum('sub_total');

                            $wallet_portion = $order_item->sub_total / $total_items_amount;
                            $wallet_refund = $order->wallet_balance * $wallet_portion;

                            // Process wallet refund
                            if ($wallet_refund > 0) {
                                $new_balance = $currentBalance + $wallet_refund;
                                CommonHelper::updateUserWalletBalance($new_balance, $order->user_id);
                                CommonHelper::addWalletTransaction($order->id, $order_item->id, $order->user_id, 'credit', $wallet_refund, 'Order Item Cancelled');
                            }

                            // Update order
                            $order->remaining_total = floatval($order->remaining_total) - floatval($order_item->sub_total);
                            $order->remaining_final = floatval($order->remaining_total) + $additional_charges_total;
                            $order->wallet_balance = $order->wallet_balance - $wallet_refund;
                        }
                        $order->save();
                    } else {
                        // No wallet balance used, just update order totals
                        $order->remaining_total = floatval($order->remaining_total) - floatval($order_item->sub_total);
                        $order->remaining_final = floatval($order->remaining_total) + $additional_charges_total;
                        $order->save();
                    }
                }
                $order_item->active_status = $postStatus;
                $order_item->cancellation_reason = $request->cancellation_reason;
                $order_item->canceled_at = now();
                $order_item->save();
                // Find the product variant by id
                $product_variant_id = $order_item->product_variant_id;
                $product_variant = ProductVariant::where('id', $product_variant_id)->first();

                if ($product_variant) {
                    // Update the stock value
                    $new_stock_value = $product_variant->stock + $order_item->quantity;
                    $product_variant->stock = $new_stock_value; // Set the new stock value
                    $product_variant->save(); // Save the changes to the database
                }
                if (isset($order->promo_code) && $order->promo_code != null && isset($order->promo_discount) && $order->promo_discount != null) {
                    $promo_code = explode("(", $order->promo_code);
                    $minimum_order_amount = PromoCode::where('promo_code', $promo_code[0])->first()->minimum_order_amount;
                    if (isset($minimum_order_amount) && $minimum_order_amount != null && $order->total < $minimum_order_amount) {
                        $order_id = $order->id;
                        CommonHelper::updateOrderPromoCode($order_id, $order->promo_discount);
                    }
                }

                DB::commit();
                // } catch (\Exception $e) {
                //     DB::rollBack();
                //     return CommonHelper::responseError(__('something_went_wrong'));
                // }
                CommonHelper::sendOrderItemStatusMailNotification($order_item, 'order_item_status_update');
                //Order Item cancelled Send SMS
                try {
                    CommonHelper::sendSmsOrderStatus($order_item, OrderStatusList::$cancelled); // case 7
                } catch (\Exception $e) {
                    Log::error("Place order SMS error :", [$e->getMessage()]);
                }

                // Send push notification to customer about order cancellation
                try {
                    CustomerNotificationService::send(
                        customerId: $order->user_id,
                        title: 'Order Cancelled',
                        message: "Your order #{$order->id} has been cancelled successfully. Any applicable refund will be processed shortly.",
                        image: '',
                        pageNavigation: 'order',
                        navigationId: $order->id
                    );
                    Log::info('Customer notification sent for order cancellation', [
                        'order_id' => $order->id,
                        'customer_id' => $order->user_id
                    ]);
                } catch (\Exception $e) {
                    Log::error('Failed to send customer notification for order cancellation', [
                        'order_id' => $order->id,
                        'error' => $e->getMessage()
                    ]);
                }

                // Send push notification to all assigned sellers about order cancellation
                try {
                    $assignedSellers = DB::table('order_seller_status_tracking')
                        ->where('order_id', $order->id)
                        ->whereNotNull('seller_id')
                        ->distinct()
                        ->pluck('seller_id');

                    foreach ($assignedSellers as $sellerId) {
                        SellerNotificationService::send(
                            sellerId: $sellerId,
                            title: 'Order Cancelled by Customer',
                            message: "Order #{$order->id} has been cancelled by the customer." . ($request->cancellation_reason ? " Reason: {$request->cancellation_reason}" : ""),
                            image: '',
                            pageNavigation: 'order',
                            navigationId: $order->id
                        );
                        Log::info('Seller notification sent for order cancellation', [
                            'order_id' => $order->id,
                            'seller_id' => $sellerId
                        ]);
                    }
                } catch (\Exception $e) {
                    Log::error('Failed to send seller notification for order cancellation', [
                        'order_id' => $order->id,
                        'error' => $e->getMessage()
                    ]);
                }

                return CommonHelper::responseSuccessWithData("Order " . OrderStatusList::$orderCancelled . " Successfully", $order);

            } elseif ($postStatus == OrderStatusList::$returned) {
                $validator = Validator::make($request->all(), [
                    'order_item_id' => [
                        'required',
                        Rule::unique('return_requests')->ignore($request->order_item_id),
                    ],
                ], [
                    'order_item_id.unique' => 'Return request has been sent already.',
                ]);
                if ($validator->fails()) {
                    return CommonHelper::responseError($validator->errors()->first());
                }
                $returnRequest = new ReturnRequest();
                $returnRequest->user_id = $order_item->user_id;
                $returnRequest->product_variant_id = $order_item->product_variant_id;
                $returnRequest->order_id = $request->order_id;
                $returnRequest->order_item_id = $request->order_item_id;
                $returnRequest->reason = $request->reason;
                $returnRequest->status = 1;    //request is pending
                $returnRequest->delivery_boy_id = 0;    //request is pending, so no delivery boy assigned
                $returnRequest->remarks = $request->remarks ?? '';
                $returnRequest->save();
                CommonHelper::sendOrderItemStatusMailNotification($order_item, 'return_request_sent');
                CommonHelper::sendSmsOrderStatus($order_item, 8);  // case 8
                return CommonHelper::responseSuccess("Order Return Request Sent Successfully");
            } else {

                $order_item->active_status = $postStatus;

                $order_item->save();
                CommonHelper::sendOrderItemStatusMailNotification($order_item, 'order_item_status_update');


                return CommonHelper::responseSuccess("Order Status Updated Successfully");
            }
        }
    }

    public function getOrders(Request $request)
    {

        $limit = ($request->limit) ?? 12;
        $offset = ($request->offset) ?? 0;
        $page = $request->get('page', 0);

        $order_id = $request->order_id;
        $user_id = auth()->user()->id;

        $sql = Order::select(DB::raw("count(id) as total"))
            ->where("user_id", $user_id);
        if (!empty($order_id)) {
            $sql = $sql->where("id", $order_id);
        }

        if (isset($request->order_status_id) && $request->order_status_id != 0 && $request->order_status_id != "") {
            $sql = $sql->where("active_status", "=", $request->order_status_id);
        }

        if (isset($request->order_type) && !empty($request->order_type)) {
            $sql = $sql->where("order_type", "=", $request->order_type);
        }

        // Always return all orders (active + previous) - type filter removed

        $total = $sql->first();
        $sql = Order::select(
            "orders.*",
            'orders.address as order_address',
            'orders.mobile as order_mobile',
            'orders.id as order_id',
            "obt.message as bank_transfer_message",
            "obt.status as bank_transfer_status",
            "dboys.name as delivery_boy_name",
            "dboys.mobile as delivery_boy_mobile",
            "dboys.profile_image as delivery_boy_profile_image",

            DB::raw('(select name from users as u where u.id = orders.user_id) as user_name'),
            'address.address',
            'address.landmark',
            'address.area',
            'address.city',
            'address.state',
            'address.pincode',
            'address.country'
        )->from("orders")
            ->leftJoin("order_bank_transfers as obt", "obt.order_id", "=", "orders.id")
            ->leftJoin('user_addresses as address', 'orders.address_id', '=', 'address.id')
            ->leftJoin('delivery_boys as dboys', 'orders.delivery_boy_id', '=', 'dboys.id')
            ->where("orders.user_id", "=", $user_id);
        if (!empty($order_id)) {
            $sql = $sql->where("orders.id", "=", $order_id);
        }

        if (isset($request->order_status_id) && $request->order_status_id != 0 && $request->order_status_id != "") {
            $sql = $sql->where("orders.active_status", "=", $request->order_status_id);
        }

        if (isset($request->order_type) && !empty($request->order_type)) {
            $sql = $sql->where("orders.order_type", "=", $request->order_type);
        }

        // Always return all orders (active + previous) - type filter removed

        $res = $sql->orderBy("orders.id", "DESC")->skip($offset)->take($limit)->get();

        $res = $res->makeHidden(['image', 'updated_at', 'deleted_at', 'current_status']);

        $i = 0;
        foreach ($res as $key => $row) {
            $res[$key]->address = $row->address . " " . $row->landmark . " " . $row->area . " " . $row->city . " " . $row->state . "-" . $row->pincode . " " . $row->country;
            if (is_string($row->additional_charges)) {
                $res[$i]['additional_charges'] = json_decode($row->additional_charges, true) ?? [];
            } elseif (is_array($row->additional_charges)) {
                $res[$i]['additional_charges'] = $row->additional_charges;
            } else {
                $res[$i]['additional_charges'] = [];
            }
            $generate_otp = Setting::get_value("generate_otp");
            if ($generate_otp == 0) {
                $res[$key]->otp = 0;
            }

            // Add delivery PIN to response - generate if null
            if (empty($row->delivery_pin)) {
                // Generate a new 4-digit PIN if it doesn't exist
                $newPin = str_pad(mt_rand(0, 9999), 4, '0', STR_PAD_LEFT);
                Order::where('id', $row->id)->update(['delivery_pin' => $newPin]);
                $res[$key]->delivery_pin = $newPin;
            } else {
                $res[$key]->delivery_pin = $row->delivery_pin;
            }

            // Add delivery boy details to response
            $deliveryBoyInfo = [];
            if (!empty($row->delivery_boy_id) && !empty($row->delivery_boy_name)) {
                // Construct profile image URL if exists
                $profileImageUrl = null;
                if (!empty($row->delivery_boy_profile_image)) {
                    $profileImageUrl = str_starts_with($row->delivery_boy_profile_image, 'http') ? $row->delivery_boy_profile_image : asset('storage/' . $row->delivery_boy_profile_image);
                }

                // Calculate average rating for delivery boy
                $avgRating = DB::table('order_driver_ratings')
                    ->where('delivery_boy_id', $row->delivery_boy_id)
                    ->avg('rating');

                // Round to 1 decimal place, default to 4.0 if no ratings
                $avgRating = $avgRating ? round($avgRating, 1) : 4.0;

                // Add rating at root level alongside other delivery boy fields
                $res[$key]->delivery_boy_rating = $avgRating;

                $deliveryBoyInfo = [
                    'id' => $row->delivery_boy_id,
                    'name' => $row->delivery_boy_name,
                    'mobile' => $row->delivery_boy_mobile,
                    'profile_image' => $profileImageUrl,
                    'rating' => $avgRating,
                    'status' => 'assigned'
                ];
            }
            $res[$key]->delivery_boy = $deliveryBoyInfo;

            $final_sub_total = 0;
            $sub_total = 0;

            $row->promo_code = explode('(', $row->promo_code)[0];

            if ($row->discount > 0) {

                $discounted_amount = $row->total * $row->discount / 100;
                $final_total = $row->total - $discounted_amount;
                $discount_in_rupees = $row->total - $final_total;
            } else {
                $discount_in_rupees = 0;
            }

            $res[$i]['discount_rupees'] = $discount_in_rupees;
            $final_total = $res[$i]['final_total'];
            $res[$i]['final_total'] = $final_total;

            $res[$i]['date'] = Carbon::parse($row->created_at)->format('Y-m-d H:i:s');
            $res[$i]['created_at'] = Carbon::parse($row->created_at)->format('Y-m-d H:i:s');


            $res[$i]['bank_transfer_message'] = !empty($res[$i]['bank_transfer_message']) ? $res[$i]['bank_transfer_message'] : "";
            $res[$i]['bank_transfer_status'] = !empty($res[$i]['bank_transfer_status']) ? $res[$i]['bank_transfer_status'] : 0;

            if ($row->order_type == 'selfpickup' && !empty($row->pickup_address)) {
                if (is_string($row->pickup_address)) {
                    $pickupAddress = json_decode($row->pickup_address, true) ?? [];
                } else {
                    $pickupAddress = $row->pickup_address;
                }

                if (empty($pickupAddress['seller_mobile'])) {
                    $sellerMobile = OrderItem::where('order_id', $row->id)
                        ->join('sellers', 'order_items.seller_id', '=', 'sellers.id')
                        ->value('sellers.mobile');

                    if ($sellerMobile) {
                        $pickupAddress['seller_mobile'] = $sellerMobile;
                    }
                }

                $res[$i]['pickup_address'] = $pickupAddress;
            } else {
                $res[$i]['pickup_address'] = [];
            }

            $orderStatus = orderStatus::where('order_id', $row['id'])->get();
            $data = array();
            foreach ($orderStatus as $status) {
                $subData = array();
                array_push($subData, $status->status, Carbon::parse($status->created_at));
                array_push($data, $subData);
            }
            $res[$i]['status'] = json_encode($data);



            $items = OrderItem::with('images')->select(
                'oi.*',
                'v.id as variant_id',
                'p.id as product_id',
                'p.name',
                'p.image',
                'p.manufacturer',
                'p.made_in',
                'p.return_status',
                'p.return_days',
                'p.cancelable_status',
                'p.till_status',
                'p.store_id',
                'p.is_pre_order_item',
                'v.measurement',
                DB::raw('(select short_code from units as u where u.id = v.stock_unit_id) as unit'),
                'co.name as country_made_in',
                's.store_name as seller_name',
                's.formatted_address as seller_address',
                's.logo as seller_logo',
                's.place_name as seller_place_name',
                's.lat_long as seller_lat_long',
                's.latitude as seller_latitude',
                's.longitude as seller_longitude',
                's.mobile as seller_mobile',
                'st.name as store_name',
                'st.managed_by_admin',
                'st.icon as store_icon',
                'st.color as store_color',
                'st.image as store_image',
                'st.description as store_description',
                'st.is_super_mart',
                DB::raw('(SELECT status FROM return_requests WHERE order_item_id = oi.id) as return_requested'),
                DB::raw('(SELECT reason FROM return_requests WHERE order_item_id = oi.id) as return_reason'),
                DB::raw('(SELECT remarks FROM return_requests WHERE order_item_id = oi.id) as return_remarks')
            )
                ->from('order_items as oi')
                ->leftJoin('product_variants as v', 'oi.product_variant_id', '=', 'v.id')
                ->leftJoin('products as p', 'v.product_id', '=', 'p.id')
                ->leftJoin('sellers as s', 'oi.seller_id', '=', 's.id')
                ->leftJoin('stores as st', 'p.store_id', '=', 'st.id')
                ->leftJoin("countries as co", "p.made_in", "=", "co.id")
                ->where('oi.order_id', '=', $row['id'])
                ->orderBy('oi.id', 'ASC')
                ->get();


            foreach ($items as $subkey => $item) {

                $taxed = ProductHelper::getTaxableAmount($item->product_variant_id);

                $items[$subkey]->made_in = $item->country_made_in ?? "";
                $items[$subkey]->created_at = Carbon::parse($item->created_at)->format('Y-m-d H:i:s');

                // Show discounted_price if available, otherwise show regular price
                $items[$subkey]->price = (float) CommonHelper::doubleNumber(
                    ($item->discounted_price !== null && $item->discounted_price != 0)
                    ? $item->discounted_price
                    : $item->price
                );
                $items[$subkey]->discounted_price = (float) CommonHelper::doubleNumber($item->discounted_price);

                $items[$subkey]->effective_price = (float) CommonHelper::doubleNumber(
                    ($item->discounted_price !== null && $item->discounted_price != 0)
                    ? $item->discounted_price
                    : ($taxed->taxable_amount ?? $item->price)
                );
                $cancelableStatusList = array(OrderStatusList::$received, OrderStatusList::$processed, OrderStatusList::$shipped, OrderStatusList::$outForDelivery);

                if (($item->cancelable_status == 1) && intval($row->active_status) <= intval($item->till_status) && in_array($row->active_status, $cancelableStatusList)) {
                    $items[$subkey]->cancelable_status = 1;
                } else {
                    $items[$subkey]->cancelable_status = 0;
                }

                $created_at = date_create(date('Y-m-d', strtotime($row->created_at)));
                $current_data = date_create(date('Y-m-d'));
                $order_days = abs(date_diff($created_at, $current_data)->format('%R%a'));

                if (($item->return_status == 1) && intval($order_days) <= intval($item->return_days) && intval($row->active_status) == OrderStatusList::$delivered) {
                    $items[$subkey]->return_status = 1;
                } else {
                    $items[$subkey]->return_status = 0;
                }
                $items[$subkey]->item_rating = CommonHelper::productRatingOfUser($item->product_id, $item->user_id);
            }

            // Fetch combo items for this order
            $comboItems = OrderComboItem::where('order_id', $row['id'])->get();
            if ($comboItems->isNotEmpty()) {
                foreach ($comboItems as $comboItem) {
                    // Decode products JSON if it's a string
                    if (is_string($comboItem->products)) {
                        $comboItem->products = json_decode($comboItem->products, true);
                    }

                    // Format the combo item data
                    $comboItem->makeHidden(['updated_at', 'deleted_at']);
                }
            }

            // Fetch prep_time data for all sellers in this order
            $prepTimeData = DB::table('order_seller_status_tracking')
                ->where('order_id', $row['id'])
                ->select('seller_id', 'prep_time')
                ->get()
                ->keyBy('seller_id');

            // Build grouped structure from order items - group by store first
            $grouped_by_store = [];

            foreach ($items as $item) {
                $storeId = $item->store_id ?? 0;

                // Initialize store group if not exists
                if (!isset($grouped_by_store[$storeId])) {
                    // Fetch store details from database
                    $store = \App\Models\Store::find($storeId);

                    $grouped_by_store[$storeId] = [
                        'store_id' => $storeId,
                        'store_name' => $store->name ?? '',
                        'store_icon' => $store && $store->icon ? $store->icon : '',
                        'store_color' => $store->color ?? '',
                        'store_image' => $store && $store->image ? $store->image : '',
                        'store_description' => $store->description ?? '',
                        'is_super_mart' => $store->is_super_mart ?? 0,
                        'managed_by_admin' => $store->managed_by_admin ?? 0,
                        'sellers' => [],
                        'items' => []
                    ];
                }

                // Get managed_by_admin value from fetched store data
                $managedByAdmin = $grouped_by_store[$storeId]['managed_by_admin'];

                // Clone item and hide store/seller fields for cleaner response
                $cleanItem = clone $item;
                $cleanItem->makeHidden(['store_name', 'store_icon', 'store_color', 'store_image', 'store_description', 'managed_by_admin', 'seller_name', 'seller_address', 'seller_place_name', 'seller_latitude', 'seller_longitude']);

                // For non-admin-managed stores, group by sellers
                if ($managedByAdmin == 0) {
                    $sellerId = $item->seller_id ?? 0;

                    if (!isset($grouped_by_store[$storeId]['sellers'][$sellerId])) {
                        // Get prep_time for this seller
                        $prepTime = isset($prepTimeData[$sellerId]) ? json_decode($prepTimeData[$sellerId]->prep_time, true) : null;

                        $grouped_by_store[$storeId]['sellers'][$sellerId] = [
                            'seller_id' => $sellerId,
                            'seller_name' => $item->seller_name ?? '',
                            'seller_image' => $item->seller_logo ?? '',
                            'seller_address' => $item->seller_address ?? '',
                            'seller_place_name' => $item->seller_place_name ?? '',
                            'seller_latitude' => $item->seller_latitude ?? '',
                            'seller_longitude' => $item->seller_longitude ?? '',
                            'seller_lat_long' => $item->seller_lat_long ?? '',
                            'seller_mobile' => $item->seller_mobile ?? '',
                            'prep_time' => $prepTime,
                            'items' => []
                        ];
                    }

                    $grouped_by_store[$storeId]['sellers'][$sellerId]['items'][] = $cleanItem;
                } else {
                    // For admin-managed stores, add items directly without seller grouping
                    $grouped_by_store[$storeId]['items'][] = $cleanItem;
                }
            }

            // Convert sellers associative array to indexed array for each store
            foreach ($grouped_by_store as $storeId => $store) {
                $grouped_by_store[$storeId]['sellers'] = array_values($store['sellers']);
            }

            $res[$i]['grouped_by_store'] = array_values($grouped_by_store);

            // Calculate overall order prep_time (max from all sellers + buffer)
            $maxPrepMinutes = 0;
            $latestPrepTime = null;

            foreach ($prepTimeData as $sellerId => $data) {
                $prepTimeJson = $data->prep_time;
                if ($prepTimeJson) {
                    $prepTimeArray = json_decode($prepTimeJson, true);
                    if ($prepTimeArray && isset($prepTimeArray[0])) {
                        $minutes = (int) $prepTimeArray[0];
                        if ($minutes > $maxPrepMinutes) {
                            $maxPrepMinutes = $minutes;
                            $latestPrepTime = $prepTimeArray[1] ?? null;
                        }
                    }
                }
            }

            // Add buffer of 5-10 minutes (using 7 as average)
            if ($maxPrepMinutes > 0) {
                $totalMinutes = $maxPrepMinutes + 7;
                $res[$i]['prep_time'] = [
                    $totalMinutes,
                    $latestPrepTime
                ];
            } else {
                $res[$i]['prep_time'] = null;
            }

            // Hide store/seller fields from original items collection for backward compatibility
            $items = $items->makeHidden(['image', 'images', 'updated_at', 'deleted_at', 'status', 'current_status', 'country_made_in', 'store_name', 'store_icon', 'store_color', 'store_image', 'store_description', 'managed_by_admin', 'seller_name', 'seller_address', 'seller_place_name', 'seller_latitude', 'seller_longitude']);

            // Format combo items similar to cart API
            $custom_combos = [];
            foreach ($comboItems as $comboItem) {
                $custom_combos[] = [
                    'combo_id' => $comboItem->combo_id,
                    'combo_custom_cart_id' => $comboItem->combo_custom_cart_id,
                    'combo_name' => $comboItem->combo_name,
                    'combo_description' => $comboItem->combo_description,
                    'product_count' => $comboItem->product_count,
                    'total_products_price' => $comboItem->total_products_price,
                    'total_actual_price' => $comboItem->total_actual_price,
                    'discount_percentage' => $comboItem->discount_percentage,
                    'sub_total' => $comboItem->sub_total,
                    'products' => $comboItem->products,
                    'seller_id' => $comboItem->seller_id,
                ];
            }
            $res[$i]['custom_combos'] = $custom_combos;

            // Add cart metadata info if available
            if (!empty($row->cart_metadata) && is_array($row->cart_metadata)) {
                $res[$i]['cart_info'] = $row->cart_metadata['cart_info'] ?? [];
                $res[$i]['billing_breakdown'] = $row->cart_metadata['billing_breakdown'] ?? [];
                $res[$i]['billing_summary'] = $row->cart_metadata['billing_summary'] ?? [];
            }

            // Keep flat structure for backward compatibility
            $res[$i]['items'] = $items;
            $res[$i]['combo_items'] = $comboItems;

            $res[$i]['status'] = json_decode($res[$i]['status']);
            $res[$i]['final_total'] = strval($row['final_total']);
            $res[$i]['total'] = strval($row['total']);
            if ($row->order_type == 'selfpickup') {
                unset($res[$i]['delivery_charge']);
            }

            // Add delivery location details
            $res[$i]['delivery_location'] = [
                'latitude' => $row->latitude ? (float) $row->latitude : null,
                'longitude' => $row->longitude ? (float) $row->longitude : null,
                'address' => $row->delivery_address ?? ''
            ];

            // Add nearest Zenfoo store location
            if (!empty($row->store_location_id)) {
                $storeLocation = \App\Models\StoreLocation::find($row->store_location_id);
                $res[$i]['zenfoo_store_location'] = $storeLocation ? [
                    'id'        => $storeLocation->id,
                    'name'      => $storeLocation->name,
                    'address'   => $storeLocation->address,
                    'latitude'  => (float) $storeLocation->latitude,
                    'longitude' => (float) $storeLocation->longitude,
                ] : null;
            } else {
                $res[$i]['zenfoo_store_location'] = null;
            }

            // Add delivery boy location history if order is delivered and assigned to a delivery boy
            if ($row->delivery_boy_id && in_array($row->active_status, [5, 6])) {
                $locationHistory = DeliveryBoyLocationHistory::where('delivery_boy_id', $row->delivery_boy_id)
                    ->where('tracked_at', '>=', $row->created_at->copy()->subHours(2))
                    ->where('tracked_at', '<=', $row->updated_at)
                    ->orderBy('tracked_at', 'asc')
                    ->get();

                $res[$i]['delivery_boy_location_history'] = $locationHistory->map(function ($location) {
                    return [
                        'latitude' => (float) $location->latitude,
                        'longitude' => (float) $location->longitude,
                        'distance_from_last_km' => (float) $location->distance_from_last_km,
                        'tracked_at' => $location->tracked_at->toDateString(),
                        'tracked_time' => $location->tracked_at->format('H:i:s'),
                        'timestamp' => $location->tracked_at->toIso8601String()
                    ];
                })->values()->toArray();
            } else {
                $res[$i]['delivery_boy_location_history'] = [];
            }

            $i++;
        }

        if (!empty($res) && $total->total !== 0) {
            return CommonHelper::responseWithData($res, $total->total);
        } else {
            return CommonHelper::responseError(__('no_orders_found'));
        }
    }

    public function generateOrderInvoice(Request $request)
    {
        $data = CommonHelper::getOrderDetails($request->order_id, true);
        if (!$data["order"]) {
            return CommonHelper::responseError("Order Not found!");
        }
        CommonHelper::AdditionalChargesArray($data['order']);
        $invoice = CommonHelper::generateOrderInvoice($data);
        return CommonHelper::responseWithData($invoice);
    }

    public function downloadOrderInvoice(Request $request)
    {
        $data = CommonHelper::getOrderDetails($request->order_id, true);
        if (!$data["order"]) {
            return CommonHelper::responseError("Order Not found!");
        }
        CommonHelper::AdditionalChargesArray($data['order']);
        return CommonHelper::downloadOrderInvoice($request->order_id);
    }


    public function getOrders_new(Request $request)
    {

        $limit = ($request->limit) ?? 12;
        $offset = ($request->offset) ?? 0;
        $order_id = $request->order_id;
        $user_id = auth()->user()->id;

        $sql = Order::select(DB::raw("count(oi.id) as total"))->leftJoin('order_items as oi', 'oi.order_id', '=', 'orders.id')
            ->where("orders.user_id", $user_id);
        if (!empty($order_id)) {
            $sql = $sql->where("oi.id", $order_id);
        }
        if (isset($request->order_status_id) && $request->order_status_id != 0 && $request->order_status_id != "") {
            $sql = $sql->where("oi.active_status", "=", $request->order_status_id);
        }

        $total = $sql->first();


        $sql = Order::select(
            "orders.*",
            "orders.id as order_id",
            "obt.message as bank_transfer_message",
            "obt.status as bank_transfer_status",
            DB::raw('(select name from users as u where u.id = orders.user_id) as user_name'),
            'address.address',
            'address.landmark',
            'address.area',
            'address.city',
            'address.state',
            'address.pincode',
            'address.country',

            'oi.*',
            'v.id as variant_id',
            'p.name',
            'p.image',
            'p.manufacturer',
            'p.made_in',
            'p.return_status',
            'p.return_days',
            'p.cancelable_status',
            'p.till_status',
            'v.measurement',
            DB::raw('(select short_code from units as u where u.id = v.stock_unit_id) as unit'),
            'os.status as current_status',
            'os.id as order_status_id',
            'co.name as country_made_in',
            's.name as seller_name'
        )->from("orders as orders")

            ->leftJoin('order_items as oi', 'oi.order_id', '=', 'orders.id')

            ->leftJoin('product_variants as v', 'oi.product_variant_id', '=', 'v.id')
            ->leftJoin('products as p', 'v.product_id', '=', 'p.id')
            ->leftJoin('sellers as s', 'oi.seller_id', '=', 's.id')
            ->leftJoin("countries as co", "p.made_in", "=", "co.id")
            ->leftJoin('order_status_lists as os', 'oi.active_status', '=', 'os.id')

            ->leftJoin("order_bank_transfers as obt", "obt.order_id", "=", "orders.id")
            ->leftJoin('user_addresses as address', 'orders.address_id', '=', 'address.id')

            ->where("orders.user_id", "=", $user_id);
        if (!empty($order_id)) {
            $sql = $sql->where("orders.id", "=", $order_id);
        }

        if (isset($request->order_status_id) && $request->order_status_id != 0 && $request->order_status_id != "") {
            $sql = $sql->where("oi.active_status", "=", $request->order_status_id);
        }

        $res = $sql->orderBy("orders.id", "DESC")->skip($offset)->take($limit)->get();
        $res = $res->makeHidden(['image', 'images', 'updated_at', 'deleted_at', 'current_status', 'status', 'country_made_in', 'order_status_id']);

        $i = 0;
        foreach ($res as $key => $row) {
            $res[$key]->active_status = $row->current_status ?? "";
            $res[$key]->address = $row->address . " " . $row->landmark . " " . $row->area . " " . $row->city . " " . $row->state . "-" . $row->pincode . " " . $row->country;
            $res[$key]->active_status = $row->current_status ?? "";
            $res[$key]->made_in = $row->country_made_in ?? "";
            $res[$key]->created_at = Carbon::createFromFormat('Y-m-d', date('Y-m-d', strtotime($row->created_at)))->format('Y-m-d');

            if ($row->order_status_id == $row->till_status) {
                $res[$key]->cancelable_status = 1;
            } else {
                $res[$key]->cancelable_status = 0;
            }

            $created_at = date_create(date('Y-m-d', strtotime($row->created_at)));
            $current_data = date_create(date('Y-m-d'));
            $order_days = abs(date_diff($created_at, $current_data)->format('%R%a'));
            if ($order_days <= $row->return_days) {
                $res[$key]->return_status = 1;
            } else {
                $res[$key]->return_status = 0;
            }

            if ($row->discount > 0) {
                $discounted_amount = $row->total * $row->discount / 100;
                $final_total = $row->total - $discounted_amount;
                $discount_in_rupees = $row->total - $final_total;
            } else {
                $discount_in_rupees = 0;
            }
            $res[$i]['discount_rupees'] = $discount_in_rupees;
            $final_total = ceil($res[$i]['final_total']);
            $res[$i]['final_total'] = $final_total;
            $res[$i]['created_at'] = date('Y-m-d', strtotime($res[$i]['created_at']));
            $res[$i]['bank_transfer_message'] = !empty($res[$i]['bank_transfer_message']) ? $res[$i]['bank_transfer_message'] : "";
            $res[$i]['bank_transfer_status'] = !empty($res[$i]['bank_transfer_status']) ? $res[$i]['bank_transfer_status'] : "0";
            $res[$i]['image_url'] = CommonHelper::getImage($res[$i]['image']);
            $res[$i]['status'] = json_decode($res[$i]['status']);
            $res[$i]['final_total'] = strval($row['final_total']);
            $res[$i]['total'] = strval($row['total']);
            // Add additional_charges to each order from the order's column
            $res[$i]['additional_charges'] = $row->additional_charges ? json_decode($row->additional_charges, true) : [];
            $i++;
        }

        if (!empty($res) && $total->total !== 0) {
            return CommonHelper::responseWithData($res, $total->total);
        } else {
            return CommonHelper::responseError(__('no_orders_found'));
        }
    }

    /*Paytm*/
    public function generatePaytmChecksum(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'type' => 'required',
            'order_id' => 'required_if:type,order',
            'amount' => 'required_if:type,order',
            'wallet_amount' => 'required_if:type,wallet',
            'website' => 'required',
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $credentials = Paytm::get_credentials();
        $paytm_merchant_id = Setting::get_value('paytm_merchant_id');
        $paytm_params["MID"] = $paytm_merchant_id;

        $paytm_params["ORDER_ID"] = ($request->type === 'order') ? $request->order_id : 'wallet_recharge-' . auth()->user()->id;
        $paytm_params["TXN_AMOUNT"] = ($request->type === 'order') ? $request->amount : $request->wallet_amount;
        $paytm_params["CUST_ID"] = auth()->user()->id;

        $paytm_params["WEBSITE"] = $request->get('website', 'DEFAULT');
        $paytm_params["CALLBACK_URL"] = $credentials['url'] . "theia/paytmCallback?ORDER_ID=" . $paytm_params["ORDER_ID"];


        $paytm_checksum = Paytm::generateSignature($paytm_params, $paytm_merchant_id);

        Log::info("paytm_checksum : ", [$paytm_checksum]);
        $response = array();
        if (!empty($paytm_checksum)) {
            $response['order id'] = $paytm_params["ORDER_ID"];
            $response['data'] = $paytm_params;
            $response['signature'] = $paytm_checksum;
            return CommonHelper::responseSuccessWithData('Checksum created successfully', $response);

        } else {
            return CommonHelper::responseError('Data not found!');
        }

    }

    public function generatePaytmTxnToken(Request $request)
    {
        $requestId = uniqid('paytm_txn_', true);

        Log::info('=== PAYTM TXN TOKEN REQUEST START ===', [
            'request_id' => $requestId,
            'user_id' => auth()->id(),
            'type' => $request->type,
            'order_id' => $request->order_id,
            'amount' => $request->amount ?? $request->wallet_amount
        ]);

        $validator = Validator::make($request->all(), [
            'type' => 'required',
            'order_id' => 'nullable',  // Made optional - auto-generates if not provided
            'amount' => 'required_if:type,order',
            'wallet_amount' => 'required_if:type,wallet',
        ]);
        if ($validator->fails()) {
            Log::error('Paytm TxnToken: Validation failed', [
                'request_id' => $requestId,
                'errors' => $validator->errors()->toArray()
            ]);
            return CommonHelper::responseError($validator->errors()->first());
        }

        $credentials = Paytm::get_credentials();
        $user_id = auth()->user()->id;

        // Generate order_id and amount based on type
        if ($request->type === 'order') {
            // Auto-generate temporary order_id if not provided (for pre-payment flow)
            $order_id = $request->order_id ?? 'ONLINE_PAYMENT_ORDER_' . $user_id . '_' . time() . '_' . uniqid();
            $amount = $request->amount;
            Log::info('Paytm TxnToken: Order payment', [
                'request_id' => $requestId,
                'order_id' => $order_id,
                'amount' => $amount,
                'auto_generated' => !$request->has('order_id')
            ]);
        } else {
            // Wallet topup: always generate unique order_id
            $order_id = 'WALLET_TOPUP_' . $user_id . '_' . time();
            $amount = $request->wallet_amount;
            Log::info('Paytm TxnToken: Wallet topup', [
                'request_id' => $requestId,
                'order_id' => $order_id,
                'amount' => $amount
            ]);
        }

        $paytmParams = array();

        $paytmParams["body"] = array(
            "requestType" => "Payment",
            "mid" => $credentials['paytm_merchant_id'],
            "websiteName" => $credentials['paytm_website'],
            "orderId" => $order_id,
            "callbackUrl" => $credentials['url'] . "theia/paytmCallback?ORDER_ID=" . $order_id,
            "txnAmount" => array(
                "value" => $amount,
                "currency" => "INR",
            ),
            "userInfo" => array(
                "custId" => $user_id,
            ),
        );



        /*
         * Generate checksum by parameters we have in body
         * Find your Merchant Key in your Paytm Dashboard at https://dashboard.paytm.com/next/apikeys
         */
        $checksum = Paytm::generateSignature(json_encode($paytmParams["body"], JSON_UNESCAPED_SLASHES), $credentials['paytm_merchant_key']);



        $paytmParams["head"] = array(
            "signature" => $checksum
        );

        $post_data = json_encode($paytmParams, JSON_UNESCAPED_SLASHES);

        /* for Staging */
        $url = $credentials['url'] . "theia/api/v1/initiateTransaction?mid=" . $credentials['paytm_merchant_id'] . "&orderId=" . $order_id;

        Log::info('Paytm TxnToken: Calling Paytm API', [
            'request_id' => $requestId,
            'url' => $url,
            'order_id' => $order_id,
            'amount' => $amount,
            'environment' => $credentials['paytm_payment_mode'],
            'merchant_id' => $credentials['paytm_merchant_id'],
            'website_name' => $credentials['paytm_website']
        ]);

        /* for Production */

        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_POST, 1);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $post_data);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);

        curl_setopt($ch, CURLOPT_HTTPHEADER, array("Content-Type: application/json"));
        $paytm_response = curl_exec($ch);

        if (curl_errno($ch)) {
            $error_msg = curl_error($ch);
            Log::error("Paytm TxnToken: Curl error", [
                'request_id' => $requestId,
                'error' => $error_msg
            ]);
        }
        curl_close($ch);

        Log::info("Paytm TxnToken: API Response received", [
            'request_id' => $requestId,
            'response_length' => strlen($paytm_response ?? ''),
            'response' => $paytm_response
        ]);

        $response = array();
        if (!empty($paytm_response)) {
            $paytm_response = json_decode($paytm_response, true);
            if (isset($paytm_response['body']['resultInfo']['resultMsg']) && ($paytm_response['body']['resultInfo']['resultMsg'] == "Success" || $paytm_response['body']['resultInfo']['resultMsg'] == "Success Idempotent")) {
                $response['txn_token'] = $paytm_response['body']['txnToken'];
                $response['order_id'] = $order_id;  // Include order_id so Flutter knows which order_id was used
                $response['amount'] = $amount;      // Include amount for reference
                $response['paytm_response'] = $paytm_response;

                Log::info('=== PAYTM TXN TOKEN SUCCESS ===', [
                    'request_id' => $requestId,
                    'order_id' => $order_id,
                    'amount' => $amount,
                    'txn_token_length' => strlen($paytm_response['body']['txnToken'])
                ]);

                return CommonHelper::responseSuccessWithData('Transaction token generated successfully', $response);

            } else {
                $response['message'] = $paytm_response['body']['resultInfo']['resultMsg'];
                $response['txn_token'] = "";
                $response['paytm_response'] = $paytm_response;

                Log::error('Paytm TxnToken: Failed', [
                    'request_id' => $requestId,
                    'order_id' => $order_id,
                    'error' => $paytm_response['body']['resultInfo']['resultMsg'],
                    'result_code' => $paytm_response['body']['resultInfo']['resultCode'] ?? null
                ]);

                return CommonHelper::responseError($paytm_response['body']['resultInfo']['resultMsg']);
            }
        } else {
            $response['error'] = true;
            $response['message'] = "Could not generate transaction token. Try again!";
            $response['txn_token'] = "";
            $response['paytm_response'] = $paytm_response;

            Log::error('Paytm TxnToken: Empty response from Paytm', [
                'request_id' => $requestId,
                'order_id' => $order_id
            ]);

            return CommonHelper::responseError("Could not generate transaction token. Try again!");
        }
    }
    /*Midtrans*/
    public function midtransCallback(Request $request)
    {
        $notification = $request->all();

        // Log the notification for debugging
        \Log::info("Midtrans Callback: " . print_r($notification, true));


        if ($notification['status_code'] == 200) {

            //transaction
            $order_id = $notification['order_id'];
            $explode = explode('-', $order_id);
            if ($explode[0] == 'order') {
                $transactionData = array();
                $transactionData['user_id'] = $explode[2];
                $transactionData['order_id'] = $explode[1];
                $transactionData['type'] = 'Midtrans';
                $transactionData['txn_id'] = $notification['transaction_id'];
                $transactionData['payu_txn_id'] = "";
                $transactionData['amount'] = $notification['gross_amount'] / 1000;
                $transactionData['status'] = $notification['transaction_status'];
                $transactionData['message'] = $notification['status_message'];
                $transactionData['transaction_date'] = $notification['transaction_time'];

                $transaction = Transaction::create($transactionData);
                $order = Order::withTrashed()->where('id', $explode[1])->first();
                if (!$order) {
                    return CommonHelper::responseError("Invalid Order Id");
                }

                if ($order->order_type == 'selfpickup') {
                    $order->active_status = OrderStatusList::$selfPickupPending;
                } else {
                    $order->active_status = OrderStatusList::$received;
                }
                $order->transaction_id = $transaction->id ?? 0;
                $order->save();

                //CommonHelper::addSellerWiseOrder($order->id);

                return CommonHelper::responseSuccess("Order Placed Successfully");

            } elseif ($explode[0] == 'wallet') {
                \Log::info("Midtrans Callbackwall: " . print_r($notification, true));

                $walletTransactionData = array();
                $walletTransactionData['user_id'] = $explode[2];
                $walletTransactionData['order_id'] = '';
                $walletTransactionData['type'] = 'credit';
                $walletTransactionData['payment_type'] = 'Midtrans';
                $walletTransactionData['txn_id'] = $notification['transaction_id'];
                $walletTransactionData['amount'] = $notification['gross_amount'] / 1000;
                $walletTransactionData['status'] = $notification['transaction_status'];
                $walletTransactionData['message'] = "Wallet successfully recharged.";
                $walletTransactionData['transaction_date'] = $notification['transaction_time'];
                $wallet_transaction = WalletTransaction::create($walletTransactionData);

                $user = User::where('id', $explode[2])->first();
                //Mark credit amount in user balance
                $balance = $user->balance;
                $newBalance = $balance + $walletTransactionData['amount'];

                $user = User::where('id', $user->id)->update(['balance' => $newBalance]);
                $data = array();
                $data['user_balance'] = $newBalance;
                return CommonHelper::responseSuccessWithData("Amount Added in Wallet Successfully", $data);

            }
        }
    }
    public function getLiveTrackingDetails(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'order_id' => 'required|numeric|exists:orders,id',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        // Retrieve the order ID from the request
        $orderId = $request->input('order_id');

        // Fetch the live tracking details based on the order ID
        $trackingData = LiveTracking::where('order_id', $orderId)
            ->orderBy('id', 'desc')
            ->first();

        // Check if the tracking data exists
        if ($trackingData) {
            return CommonHelper::responseSuccessWithData("Live Tracking Detail fetched successfully.", $trackingData);

        } else {
            return CommonHelper::responseError("Live Tracking Not available.");
        }
    }
    public function getOrderStatusPhonepe(Request $request)
    {
        $request->validate([
            'transaction_id' => 'required|string'
        ]);

        try {
            $transactionId = $request->transaction_id;

            $mode = Setting::get_value('phonepay_mode'); // 'uat' or 'production'
            $merchantId = Setting::get_value('phonepay_merchant_id');
            $clientId = Setting::get_value('phonepay_client_id');
            $clientVersion = Setting::get_value('phonepay_client_version') ?? '1';
            $clientSecret = Setting::get_value('phonepay_client_secret');

            // Validate credentials
            if (!$merchantId || !$clientId || !$clientSecret) {
                \Log::error('PhonePe: Credentials not configured for status check');
                return CommonHelper::responseError("PhonePe credentials are not configured");
            }

            // Determine token URL based on mode
            $tokenUrl = $mode === 'production'
                ? 'https://api.phonepe.com/apis/identity-manager/v1/oauth/token'
                : 'https://api-preprod.phonepe.com/apis/pg-sandbox/v1/oauth/token';

            // Get access token (use cached if available, otherwise request new one)
            $accessToken = TransactionHelper::getPhonePeAccessToken($clientId, $clientVersion, $clientSecret, $tokenUrl);

            if (!$accessToken) {
                \Log::error('PhonePe: Failed to obtain access token');
                return CommonHelper::responseError("Failed to obtain PhonePe access token");
            }

            $statusUrl = $mode === 'production'
                ? "https://api.phonepe.com/apis/pg/v1/status/$transactionId?details=false"
                : "https://api-preprod.phonepe.com/apis/pg-sandbox/checkout/v2/order/$transactionId/status?details=false";

                
            $curl = curl_init();

            curl_setopt_array($curl, [
                CURLOPT_URL => $statusUrl,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_ENCODING => '',
                CURLOPT_MAXREDIRS => 10,
                CURLOPT_TIMEOUT => 0,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
                CURLOPT_CUSTOMREQUEST => 'GET',
                CURLOPT_HTTPHEADER => [
                    'Content-Type: application/json',
                    'Authorization: O-Bearer ' . $accessToken
                ],
            ]);

            $response = curl_exec($curl);
            curl_close($curl);

            $response = json_decode($response, true);
            //return response()->json($result);

            // Validate response structure
            if (!$response || !is_array($response)) {
                \Log::error('PhonePe: Invalid response structure', ['response' => $response]);
                return CommonHelper::responseError("Invalid response from PhonePe");
            }

            if (!isset($response['paymentDetails']) || !is_array($response['paymentDetails']) || count($response['paymentDetails']) === 0) {
                \Log::error('PhonePe: Missing or empty paymentDetails', ['response' => $response]);
                return CommonHelper::responseError("Invalid payment details in PhonePe response");
            }

            if (!isset($response['metaInfo']) || !is_array($response['metaInfo'])) {
                \Log::error('PhonePe: Missing or invalid metaInfo', ['response' => $response]);
                return CommonHelper::responseError("Invalid metadata in PhonePe response");
            }

            $website_url = Setting::get_value('website_url') ?? "";

            try {
                if ($response['paymentDetails'][0]['state'] == 'COMPLETED') {
                    // transaction

                    $order_id = $response['metaInfo']['order_id'];

                    if ($response['metaInfo']['type'] == 'order') {

                        $transactionData = array();
                        $transactionData['user_id'] = $response['metaInfo']['user_id'];
                        $transactionData['order_id'] = $response['metaInfo']['order_id'];
                        $transactionData['type'] = Transaction::$paymentTypePhonepe;
                        $transactionData['txn_id'] = $response['paymentDetails'][0]['transactionId'];
                        $transactionData['payu_txn_id'] = "";
                        $transactionData['amount'] = $response['paymentDetails'][0]['amount'] / 100;
                        $transactionData['status'] = Transaction::$statusSuccess;
                        $transactionData['message'] = "Phonepe order payment";
                        $transactionData['transaction_date'] = now();

                        $transaction = Transaction::create($transactionData);
                        $order = Order::withTrashed()->where('id', $response['metaInfo']['order_id'])->first();
                        $user = User::where('id', $response['metaInfo']['user_id'])->first();
                        $user_wallet_balance = $user->balance;
                        if (!$order) {
                            return CommonHelper::responseError("Invalid Order Id");
                        }

                        if ($order->order_type == 'selfpickup') {
                            $order->active_status = OrderStatusList::$selfPickupPending;
                        } else {
                            $order->active_status = OrderStatusList::$received;
                        }
                        $order->transaction_id = $transaction->id ?? 0;

                        if (isset($order->wallet_balance) && $order->wallet_balance > 0) {
                            // Deduct the balance & set the wallet transaction
                            $new_balance = $user_wallet_balance < $order->wallet_balance ? 0 : $user_wallet_balance - $order->wallet_balance;
                            CommonHelper::updateUserWalletBalance($new_balance, $user->id);
                            CommonHelper::addWalletTransaction($order_id, 0, $user->id, 'debit', $order->wallet_balance, 'Used against Order Placement');
                        }

                        $order->save();
                        return CommonHelper::responseWithData(['status' => $response['paymentDetails'][0]['state'], 'order_id' => $response['metaInfo']['order_id'], 'user_id' => $response['metaInfo']['user_id'], 'type' => $response['metaInfo']['type']]);




                    } elseif ($response['metaInfo']['type'] == 'wallet') {
                        // \Log::info("phonepe Callbackwallet: " . print_r($response, true));

                        $walletTransactionData = array();
                        $walletTransactionData['user_id'] = $response['metaInfo']['user_id'];
                        $walletTransactionData['order_id'] = '';
                        $walletTransactionData['type'] = 'credit';
                        $walletTransactionData['payment_type'] = Transaction::$paymentTypePhonepe;
                        $walletTransactionData['txn_id'] = $response['paymentDetails'][0]['transactionId'];
                        $walletTransactionData['amount'] = $response['paymentDetails'][0]['amount'] / 100;
                        $walletTransactionData['status'] = Transaction::$statusSuccess;
                        $walletTransactionData['message'] = "Wallet successfully recharged.";
                        $walletTransactionData['transaction_date'] = now();
                        $wallet_transaction = WalletTransaction::create($walletTransactionData);

                        $newBalance = CommonHelper::addUserWalletBalance($walletTransactionData['amount'], $response['metaInfo']['user_id']);

                        return CommonHelper::responseWithData(['status' => $response['paymentDetails'][0]['state'], 'order_id' => $response['metaInfo']['order_id'], 'user_id' => $response['metaInfo']['user_id'], 'type' => $response['metaInfo']['type']]);
                    }
                } else {

                    if ($response['metaInfo']['type'] == 'order') {
                        Order::where('id', $response['metaInfo']['order_id'])->update(['active_status' => OrderStatusList::$cancelled]);
                        return CommonHelper::responseWithData(['status' => $response['paymentDetails'][0]['state'], 'order_id' => $response['metaInfo']['order_id'], 'user_id' => $response['metaInfo']['user_id'], 'type' => $response['metaInfo']['type']]);
                    }
                }
            } catch (\Exception $e) {
                \Log::error("Error processing Phonepe callback: " . $e->getMessage());
                return CommonHelper::responseError("An error occurred while processing the callback.");
            }

        } catch (\Exception $e) {
            \Log::error('PhonePe Status Check Error: ' . $e->getMessage());
            return response()->json([
                'error' => true,
                'message' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get reorderable orders (only delivered and picked up orders)
     * Returns orders with current product and variant information for easy reordering
     *
     * GET /api/customer/orders/reorderable
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getReorderableOrders(Request $request)
    {
        try {
            $limit = $request->get('limit', 10);
            $offset = $request->get('offset', 0);
            $user_id = auth()->user()->id;

            // Only get delivered and self-pickup picked orders
            $deliveredStatuses = [
                OrderStatusList::$delivered,
                OrderStatusList::$selfPickupPicked
            ];

            // Get total count
            $total = Order::where('user_id', $user_id)
                ->whereIn('active_status', $deliveredStatuses)
                ->count();

            // Get orders
            $orders = Order::select(
                'orders.id as order_id',
                'orders.created_at as order_date',
                'orders.final_total',
                'orders.active_status',
                'orders.order_type'
            )
                ->where('orders.user_id', $user_id)
                ->whereIn('orders.active_status', $deliveredStatuses)
                ->orderBy('orders.id', 'DESC')
                ->skip($offset)
                ->take($limit)
                ->get();

            $result = [];

            foreach ($orders as $order) {
                // Get order items with current product and variant information
                $items = OrderItem::select(
                    'oi.id as order_item_id',
                    'oi.quantity as ordered_quantity',
                    'oi.price as ordered_price',
                    'oi.discounted_price as ordered_discounted_price',
                    'oi.sub_total as ordered_sub_total',
                    'p.id as product_id',
                    'p.name as product_name',
                    'p.image as product_image',
                    'p.status as product_status',
                    'p.is_approved',
                    'p.is_unlimited_stock',
                    'v.id as variant_id',
                    'v.type as variant_type',
                    'v.measurement',
                    'v.price as current_price',
                    'v.discounted_price as current_discounted_price',
                    'v.stock as current_stock',
                    'v.status as variant_status',
                    DB::raw('(select short_code from units as u where u.id = v.stock_unit_id) as unit'),
                    's.id as seller_id',
                    's.store_name as seller_name',
                    's.status as seller_status',
                    'st.id as store_id',
                    'st.name as store_name',
                    'st.icon as store_icon',
                    'st.managed_by_admin as store_managed_by_admin'
                )
                    ->from('order_items as oi')
                    ->leftJoin('product_variants as v', 'oi.product_variant_id', '=', 'v.id')
                    ->leftJoin('products as p', 'v.product_id', '=', 'p.id')
                    ->leftJoin('sellers as s', 'oi.seller_id', '=', 's.id')
                    ->leftJoin('stores as st', 'p.store_id', '=', 'st.id')
                    ->where('oi.order_id', $order->order_id)
                    ->get();

                $formattedItems = [];
                $availableCount = 0;
                $unavailableCount = 0;

                foreach ($items as $item) {
                    // Check if product and variant are still available
                    $isAvailable = (
                        $item->product_status == 1 &&
                        $item->is_approved == 1 &&
                        $item->variant_status == 1 &&
                        ($item->store_managed_by_admin == 1 || $item->seller_status == 1) &&
                        ($item->is_unlimited_stock == 1 || $item->current_stock > 0)
                    );

                    if ($isAvailable) {
                        $availableCount++;
                    } else {
                        $unavailableCount++;
                    }

                    // Get current effective price
                    $currentEffectivePrice = ($item->current_discounted_price && $item->current_discounted_price > 0)
                        ? $item->current_discounted_price
                        : $item->current_price;

                    // Calculate price change
                    $orderedEffectivePrice = ($item->ordered_discounted_price && $item->ordered_discounted_price > 0)
                        ? $item->ordered_discounted_price
                        : $item->ordered_price;

                    $priceDifference = $currentEffectivePrice - $orderedEffectivePrice;
                    $priceChangePercentage = $orderedEffectivePrice > 0
                        ? round(($priceDifference / $orderedEffectivePrice) * 100, 2)
                        : 0;

                    $formattedItems[] = [
                        'order_item_id' => $item->order_item_id,
                        'product_id' => $item->product_id,
                        'product_name' => $item->product_name,
                        'product_image' => $item->product_image ? $item->product_image : '',
                        'variant_id' => $item->variant_id,
                        'variant_type' => $item->variant_type,
                        'measurement' => $item->measurement,
                        'unit' => $item->unit,
                        'ordered_quantity' => $item->ordered_quantity,
                        'ordered_price' => (string) $orderedEffectivePrice,
                        'ordered_sub_total' => (string) $item->ordered_sub_total,
                        'current_price' => (string) $currentEffectivePrice,
                        'current_stock' => $item->current_stock,
                        'price_difference' => (string) $priceDifference,
                        'price_change_percentage' => (string) $priceChangePercentage,
                        'is_available' => $isAvailable,
                        'availability_reason' => !$isAvailable ? $this->getUnavailabilityReason($item) : null,
                        'seller_id' => $item->seller_id,
                        'seller_name' => $item->seller_name,
                        'store_id' => $item->store_id,
                        'store_name' => $item->store_name,
                        'store_icon' => $item->store_icon ? $item->store_icon : '',
                    ];
                }

                $result[] = [
                    'order_id' => $order->order_id,
                    'order_date' => Carbon::parse($order->order_date)->format('Y-m-d H:i:s'),
                    'order_date_formatted' => Carbon::parse($order->order_date)->format('d M Y'),
                    'final_total' => (string) $order->final_total,
                    'order_status' => $order->active_status == OrderStatusList::$delivered
                        ? OrderStatusList::$orderDelivered
                        : OrderStatusList::$orderSelfPickupPicked,
                    'order_type' => $order->order_type,
                    'total_items' => count($formattedItems),
                    'available_items_count' => $availableCount,
                    'unavailable_items_count' => $unavailableCount,
                    'can_reorder_all' => $unavailableCount == 0,
                    'items' => $formattedItems,
                ];
            }

            return CommonHelper::responseWithData($result, $total);
        } catch (\Exception $e) {
            Log::error('Failed to get reorderable orders', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => auth()->id()
            ]);
            return CommonHelper::responseError('Failed to retrieve reorderable orders');
        }
    }

    /**
     * Helper function to get unavailability reason
     *
     * @param object $item
     * @return string
     */
    private function getUnavailabilityReason($item)
    {
        if ($item->product_status != 1) {
            return 'Product is no longer available';
        }
        if ($item->is_approved != 1) {
            return 'Product is not approved';
        }
        if ($item->variant_status != 1) {
            return 'This variant is no longer available';
        }
        if ($item->store_managed_by_admin != 1 && $item->seller_status != 1) {
            return 'Seller is not available';
        }
        if ($item->is_unlimited_stock != 1 && $item->current_stock <= 0) {
            return 'Out of stock';
        }
        return 'Currently unavailable';
    }

    /**
     * Save order rating from customer app
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function saveOrderRating(Request $request)
    {
        try {
            Log::info('saveOrderRating: Starting order rating process', [
                'request_data' => $request->all(),
                'user_id' => auth()->id()
            ]);

            $validator = \Validator::make($request->all(), [
                'order_id' => 'required|integer|exists:orders,id',
                'zenfoo_rating' => 'nullable|integer|min:1|max:5',
                'store_rating' => 'nullable|integer|min:1|max:5',
                'review' => 'nullable|string|max:1000',
            ]);

            if ($validator->fails()) {
                Log::warning('saveOrderRating: Validation failed', [
                    'errors' => $validator->errors()->toArray(),
                    'user_id' => auth()->id()
                ]);
                return CommonHelper::responseError($validator->errors()->first());
            }

            $user = auth()->user();
            $orderId = $request->order_id;
            $zenfooRating = $request->zenfoo_rating;
            $storeRating = $request->store_rating;
            $review = $request->review ?? '';

            Log::info('saveOrderRating: Validated input', [
                'order_id' => $orderId,
                'zenfoo_rating' => $zenfooRating,
                'store_rating' => $storeRating,
                'review_length' => strlen($review),
                'user_id' => $user->id
            ]);

            // Get order seller status tracking data to get seller_id and store_id
            $orderTracking = \DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->first();

            Log::info('saveOrderRating: Order tracking query result', [
                'order_id' => $orderId,
                'order_tracking_found' => $orderTracking ? true : false,
                'seller_id' => $orderTracking->seller_id ?? null,
                'store_id' => $orderTracking->store_id ?? null
            ]);

            if (!$orderTracking) {
                Log::warning('saveOrderRating: Order tracking data not found', [
                    'order_id' => $orderId,
                    'user_id' => $user->id
                ]);
                return CommonHelper::responseError('Order tracking data not found');
            }

            $sellerId = $orderTracking->seller_id;
            $storeId = $orderTracking->store_id;

            // Get store to check managed_by_admin
            $store = \App\Models\Store::find($storeId);

            Log::info('saveOrderRating: Store query result', [
                'store_id' => $storeId,
                'store_found' => $store ? true : false,
                'managed_by_admin' => $store->managed_by_admin ?? null,
                'store_name' => $store->name ?? null
            ]);

            if (!$store) {
                Log::warning('saveOrderRating: Store not found', [
                    'store_id' => $storeId,
                    'user_id' => $user->id
                ]);
                return CommonHelper::responseError('Store not found');
            }

            // Determine which rating to use based on managed_by_admin
            $ratingValue = null;
            $isZenfooStore = 0;

            if ($store->managed_by_admin == 1) {
                // Admin-managed store - use zenfoo_rating
                if ($zenfooRating) {
                    $ratingValue = $zenfooRating;
                    $isZenfooStore = 1;
                }
                Log::info('saveOrderRating: Admin-managed store detected', [
                    'store_id' => $storeId,
                    'using_zenfoo_rating' => $zenfooRating,
                    'is_zenfoo_store' => $isZenfooStore
                ]);
            } else {
                // Seller-managed store - use store_rating
                if ($storeRating) {
                    $ratingValue = $storeRating;
                    $isZenfooStore = 0;
                }
                Log::info('saveOrderRating: Seller-managed store detected', [
                    'store_id' => $storeId,
                    'using_store_rating' => $storeRating,
                    'is_zenfoo_store' => $isZenfooStore
                ]);
            }

            if (!$ratingValue) {
                Log::warning('saveOrderRating: No rating value provided', [
                    'managed_by_admin' => $store->managed_by_admin,
                    'zenfoo_rating' => $zenfooRating,
                    'store_rating' => $storeRating,
                    'user_id' => $user->id
                ]);
                return CommonHelper::responseError('Rating value is required');
            }

            // Get order items by order_id to get product_variant_ids
            $orderItems = \DB::table('order_items')
                ->where('order_id', $orderId)
                ->pluck('product_variant_id');

            Log::info('saveOrderRating: Order items query result', [
                'order_id' => $orderId,
                'order_items_count' => $orderItems->count(),
                'product_variant_ids' => $orderItems->toArray()
            ]);

            if ($orderItems->isEmpty()) {
                Log::warning('saveOrderRating: No order items found', [
                    'order_id' => $orderId,
                    'user_id' => $user->id
                ]);
                return CommonHelper::responseError('No order items found');
            }

            // Get product_ids from product_variants table
            $productIds = \DB::table('product_variants')
                ->whereIn('id', $orderItems)
                ->pluck('product_id')
                ->unique();

            Log::info('saveOrderRating: Product IDs from variants', [
                'product_variant_ids' => $orderItems->toArray(),
                'product_ids' => $productIds->toArray(),
                'unique_product_count' => $productIds->count()
            ]);

            if ($productIds->isEmpty()) {
                Log::warning('saveOrderRating: No products found for rating', [
                    'order_id' => $orderId,
                    'product_variant_ids' => $orderItems->toArray(),
                    'user_id' => $user->id
                ]);
                return CommonHelper::responseError('No products found for rating');
            }

            $ratingsCreated = 0;
            $ratingsUpdated = 0;

            // Insert/Update ratings for each product
            foreach ($productIds as $productId) {
                // Check if rating already exists for this user and product
                $existingRating = \App\Models\ProductRating::where('user_id', $user->id)
                    ->where('product_id', $productId)
                    ->first();

                Log::info('saveOrderRating: Processing product rating', [
                    'product_id' => $productId,
                    'user_id' => $user->id,
                    'existing_rating_found' => $existingRating ? true : false,
                    'existing_rating_id' => $existingRating->id ?? null
                ]);

                if ($existingRating) {
                    // Update existing rating
                    $existingRating->update([
                        'rate' => $ratingValue,
                        'review' => $review,
                        'seller_id' => $sellerId,
                        'order_id' => $orderId,
                        'store_id' => $storeId,
                        'is_zenfoo_store' => $isZenfooStore,
                    ]);
                    $ratingsUpdated++;

                    Log::info('saveOrderRating: Updated existing rating', [
                        'rating_id' => $existingRating->id,
                        'product_id' => $productId,
                        'rate' => $ratingValue,
                        'seller_id' => $sellerId,
                        'store_id' => $storeId,
                        'is_zenfoo_store' => $isZenfooStore
                    ]);
                } else {
                    // Create new rating
                    $newRating = \App\Models\ProductRating::create([
                        'product_id' => $productId,
                        'user_id' => $user->id,
                        'rate' => $ratingValue,
                        'review' => $review,
                        'seller_id' => $sellerId,
                        'order_id' => $orderId,
                        'store_id' => $storeId,
                        'is_zenfoo_store' => $isZenfooStore,
                        'status' => 1,
                    ]);
                    $ratingsCreated++;

                    Log::info('saveOrderRating: Created new rating', [
                        'rating_id' => $newRating->id,
                        'product_id' => $productId,
                        'user_id' => $user->id,
                        'rate' => $ratingValue,
                        'seller_id' => $sellerId,
                        'store_id' => $storeId,
                        'is_zenfoo_store' => $isZenfooStore
                    ]);
                }
            }

            Log::info('saveOrderRating: Order rating process completed successfully', [
                'order_id' => $orderId,
                'user_id' => $user->id,
                'ratings_created' => $ratingsCreated,
                'ratings_updated' => $ratingsUpdated,
                'total_products_rated' => $productIds->count()
            ]);

            return CommonHelper::responseWithData([
                'message' => 'Rating saved successfully',
                'ratings_created' => $ratingsCreated,
                'ratings_updated' => $ratingsUpdated,
            ]);

        } catch (\Exception $e) {
            Log::error('saveOrderRating: Exception occurred', [
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
                'user_id' => auth()->id(),
                'order_id' => $request->order_id ?? null
            ]);
            return CommonHelper::responseError('Failed to save rating');
        }
    }

    /**
     * Cancel an order from customer app
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function cancelOrder(Request $request)
    {
        try {
            Log::info('cancelOrder: [STEP 1] Request received', [
                'request_data' => $request->all()
            ]);

            $validator = Validator::make($request->all(), [
                'order_id' => 'required|integer',
            ]);

            if ($validator->fails()) {
                Log::warning('cancelOrder: [STEP 1] Validation failed', [
                    'errors' => $validator->errors()->toArray()
                ]);
                return CommonHelper::responseError($validator->errors()->first());
            }

            $user = Auth::guard('api-customers')->user();
            $orderId = $request->order_id;

            Log::info('cancelOrder: [STEP 2] User authenticated', [
                'user_id' => $user->id,
                'order_id' => $orderId
            ]);

            // Check if order exists and belongs to the authenticated user
            $order = Order::where('id', $orderId)
                ->where('user_id', $user->id)
                ->first();

            if (!$order) {
                Log::warning('cancelOrder: [STEP 2] Order not found or unauthorized', [
                    'order_id' => $orderId,
                    'user_id' => $user->id
                ]);
                return CommonHelper::responseError('Order not found or does not belong to you.');
            }

            Log::info('cancelOrder: [STEP 3] Order found', [
                'order_id' => $orderId,
                'payment_method' => $order->payment_method,
                'active_status' => $order->active_status
            ]);

            // Preorder: allow cancel only while preorder window is open (before Friday cutoff)
            if ($order->is_preorder) {
                if (!\App\Helpers\PreorderHelper::isPreorderTimeWindow()) {
                    Log::warning('cancelOrder: [STEP 3] Preorder cancellation blocked — past cutoff deadline', [
                        'order_id' => $orderId,
                    ]);
                    return CommonHelper::responseError('Preorder cannot be cancelled after the order cutoff time. Cancellations are only allowed up to Thursday night.');
                }

                Log::info('cancelOrder: [STEP 3] Preorder within cancellation window — skipping all policy checks', [
                    'order_id' => $orderId,
                ]);
            } else {
                // Block cancellation only if any seller has already handed to delivery partner
                $givenToDriver = DB::table('order_seller_status_tracking')
                    ->where('order_id', $orderId)
                    ->where('status', 'given_to_delivery_partner')
                    ->first();

                if ($givenToDriver) {
                    Log::warning('cancelOrder: [STEP 3] Cancellation blocked — already handed to delivery partner', [
                        'order_id'  => $orderId,
                        'seller_id' => $givenToDriver->seller_id,
                        'status'    => $givenToDriver->status,
                    ]);
                    return CommonHelper::responseError('Order cannot be cancelled as it has already been handed to the delivery partner.');
                }

                Log::info('cancelOrder: [STEP 4] Pre-checks passed — order not cancelled, seller not preparing', [
                    'order_id'       => $orderId,
                    'active_status'  => $order->active_status,
                    'payment_method' => $order->payment_method,
                ]);

                // [STEP 4.5] Check product-level cancel policy for all items (normal + combo)
                $orderItemsService = new OrderItemsService();
                $orderItemsData    = $orderItemsService->getOrderItems($orderId);
                $productIds        = $orderItemsData['all_product_ids'];

                Log::info('cancelOrder: [STEP 4.5] Checking product cancel policies', [
                    'order_id'            => $orderId,
                    'product_ids'         => $productIds,
                    'count'               => count($productIds),
                    'normal_items_count'  => count($orderItemsData['normal_items']),
                    'combo_items_count'   => count($orderItemsData['combo_items']),
                ]);

                $policyService = new ProductOrderPolicyService();
                foreach ($productIds as $productId) {
                    $policyResult = $policyService->checkCancelPolicy(
                        (int) $productId,
                        (int) $order->active_status
                    );
                    if ($policyResult['can_cancel_now']) {
                        Log::info('cancelOrder: [STEP 4.5] Product cancel policy — PASSED', [
                            'order_id'   => $orderId,
                            'product_id' => $productId,
                            'product'    => $policyResult['product_name'] ?? $productId,
                            'reason'     => $policyResult['reason'],
                        ]);
                    } else {
                        Log::warning('cancelOrder: [STEP 4.5] Product cancel policy — BLOCKED', [
                            'order_id'     => $orderId,
                            'product_id'   => $productId,
                            'product'      => $policyResult['product_name'] ?? $productId,
                            'cancellable'  => $policyResult['cancellable'],
                            'till_status'  => $policyResult['till_status'],
                            'order_status' => $policyResult['current_order_status'],
                            'reason'       => $policyResult['reason'],
                        ]);
                        return CommonHelper::responseError(
                            'This order cannot be cancelled. Due to product "' . ($policyResult['product_name'] ?? "ID:{$productId}") . '": ' . $policyResult['reason']
                        );
                    }
                }

                Log::info('cancelOrder: [STEP 4.5] All product cancel policies passed — proceeding to DB transaction', [
                    'order_id'         => $orderId,
                    'products_checked' => count($productIds),
                ]);
            }

            DB::beginTransaction();
            Log::info('cancelOrder: [STEP 5] Transaction started', ['order_id' => $orderId]);

            $refundResult = null;

            // Check if payment method is not COD - need to process refund
            $paymentMethod = strtolower($order->payment_method ?? '');
            Log::info('cancelOrder: [STEP 6] Checking payment method', [
                'order_id' => $orderId,
                'payment_method' => $paymentMethod
            ]);

            if ($paymentMethod !== 'cod') {
                Log::info('cancelOrder: [STEP 7] Non-COD payment, looking for transaction', [
                    'order_id' => $orderId
                ]);

                // Get the transaction for this order
                $transaction = Transaction::where('order_id', $orderId)
                    ->where('status', Transaction::$statusSuccess)
                    ->first();

                if ($transaction && $transaction->txn_id) {
                    Log::info('cancelOrder: [STEP 8] Transaction found', [
                        'order_id' => $orderId,
                        'transaction_id' => $transaction->id,
                        'txn_id' => $transaction->txn_id,
                        'type' => $transaction->type,
                        'amount' => $transaction->amount
                    ]);

                    // Refund amount from transaction
                    $refundAmount = $transaction->amount ?? 0;

                    if ($refundAmount > 0) {
                        // Check payment type and initiate appropriate refund
                        if (strtolower($transaction->type) === 'phonepe') {
                            Log::info('cancelOrder: [STEP 9] Initiating PhonePe refund', [
                                'order_id' => $orderId,
                                'txn_id' => $transaction->txn_id,
                                'refund_amount' => $refundAmount
                            ]);

                            $phonePeRefundService = new PhonePeRefundService();
                            $refundResult = $phonePeRefundService->initiateRefund(
                                $transaction->txn_id,
                                $refundAmount,
                                $orderId
                            );

                            Log::info('cancelOrder: [STEP 10] PhonePe refund response', [
                                'order_id' => $orderId,
                                'refund_result' => $refundResult
                            ]);

                            if (!$refundResult['success']) {
                                DB::rollBack();
                                Log::error('cancelOrder: [STEP 10] PhonePe refund failed - Rolling back', [
                                    'order_id' => $orderId,
                                    'error' => $refundResult['error'] ?? 'Unknown error',
                                    'refund_result' => $refundResult
                                ]);
                                return CommonHelper::responseError('Order cancellation failed: Unable to process refund. Please try again or contact support.');
                            }

                            Log::info('cancelOrder: [STEP 11] PhonePe refund successful', [
                                'order_id' => $orderId,
                                'refund_transaction_id' => $refundResult['refund_transaction_id'] ?? null
                            ]);

                            // Update transaction with refund details
                            $transaction->is_refunded = 1;
                            $transaction->refund_transaction_id = $refundResult['refund_transaction_id'] ?? null;
                            $transaction->refund_amount = $refundAmount;
                            $transaction->refunded_at = now();
                            $transaction->save();

                            Log::info('cancelOrder: [STEP 11.1] Transaction updated with refund details', [
                                'order_id' => $orderId,
                                'transaction_id' => $transaction->id,
                                'refund_transaction_id' => $transaction->refund_transaction_id,
                                'refund_amount' => $transaction->refund_amount
                            ]);

                        } elseif (strtolower($transaction->type) === 'paytm') {
                            // Fetch paytm_transactions record to get original ORDER_ID
                            $paytmTransaction = \App\Models\PaytmTransaction::where('order_id', $orderId)
                                ->orderBy('id', 'desc')
                                ->first();

                            if (!$paytmTransaction) {
                                DB::rollBack();
                                Log::error('cancelOrder: [STEP 9] Paytm transaction record NOT FOUND in paytm_transactions table', [
                                    'order_id' => $orderId,
                                    'transactions_table_txn_id' => $transaction->txn_id,
                                    'transactions_table_type' => $transaction->type,
                                    'note' => 'No record in paytm_transactions for this order_id. Was the payment captured properly?',
                                ]);
                                return CommonHelper::responseError('Order cancellation failed: Paytm transaction record not found.');
                            }

                            // Calculate time since payment for diagnosis
                            $paymentTime = $paytmTransaction->transaction_date ?? $paytmTransaction->created_at;
                            $timeSincePayment = $paymentTime ? now()->diffInMinutes($paymentTime) : null;

                            Log::info('cancelOrder: [STEP 9] Paytm transaction record found — full details', [
                                'order_id' => $orderId,
                                'paytm_transactions_db_id' => $paytmTransaction->id,
                                'paytm_order_id (txn_id)' => $paytmTransaction->txn_id,
                                'paytm_txn_id' => $paytmTransaction->paytm_txn_id,
                                'bank_txn_id' => $paytmTransaction->bank_txn_id,
                                'payment_mode' => $paytmTransaction->payment_mode,
                                'bank_name' => $paytmTransaction->bank_name,
                                'gateway_name' => $paytmTransaction->gateway_name,
                                'amount' => $paytmTransaction->amount,
                                'status' => $paytmTransaction->status,
                                'is_captured' => $paytmTransaction->is_captured,
                                'response_code' => $paytmTransaction->response_code,
                                'response_msg' => $paytmTransaction->response_msg,
                                'transaction_date' => $paytmTransaction->transaction_date,
                                'created_at' => $paytmTransaction->created_at,
                                'minutes_since_payment' => $timeSincePayment,
                                'refund_amount' => $refundAmount,
                                'metadata' => $paytmTransaction->metadata,
                            ]);

                            Log::info('cancelOrder: [STEP 9] Initiating Paytm refund', [
                                'order_id' => $orderId,
                                'paytm_order_id' => $paytmTransaction->txn_id,
                                'paytm_txn_id' => $paytmTransaction->paytm_txn_id,
                                'refund_amount' => $refundAmount,
                                'payment_mode' => $paytmTransaction->payment_mode,
                                'bank_name' => $paytmTransaction->bank_name,
                                'minutes_since_payment' => $timeSincePayment,
                            ]);

                            $paytmRefundService = new PaytmRefundService();
                            $refundResult = $paytmRefundService->initiateRefund(
                                $paytmTransaction->paytm_txn_id,  // Paytm transaction ID
                                $refundAmount,
                                $orderId,
                                $paytmTransaction->txn_id  // Original ORDER_ID (ONLINE_PAYMENT_ORDER_40_...)
                            );

                            Log::info('cancelOrder: [STEP 10] Paytm refund response', [
                                'order_id' => $orderId,
                                'refund_result' => $refundResult
                            ]);

                            if (!$refundResult['success']) {
                                DB::rollBack();
                                Log::error('cancelOrder: [STEP 10] Paytm refund FAILED — Rolling back', [
                                    'order_id' => $orderId,
                                    'error' => $refundResult['error'] ?? 'Unknown error',
                                    'error_code' => $refundResult['code'] ?? 'UNKNOWN',
                                    'error_status' => $refundResult['status'] ?? 'UNKNOWN',
                                    'diagnosis' => $refundResult['diagnosis'] ?? null,
                                    'recommended_action' => $refundResult['recommended_action'] ?? null,
                                    'payment_mode' => $paytmTransaction->payment_mode ?? null,
                                    'bank_name' => $paytmTransaction->bank_name ?? null,
                                    'gateway_name' => $paytmTransaction->gateway_name ?? null,
                                    'paytm_order_id' => $paytmTransaction->txn_id ?? null,
                                    'paytm_txn_id' => $paytmTransaction->paytm_txn_id ?? null,
                                    'refund_amount' => $refundAmount,
                                    'environment' => config('app.env'),
                                ]);
                                return CommonHelper::responseError('Order cancellation failed: Unable to process Paytm refund. Please try again or contact support.');
                            }

                            Log::info('cancelOrder: [STEP 11] Paytm refund successful', [
                                'order_id' => $orderId,
                                'refund_transaction_id' => $refundResult['refund_transaction_id'] ?? null,
                                'message' => $refundResult['message'] ?? 'Refund successful'
                            ]);

                            // Update transaction with refund details
                            $transaction->is_refunded = 1;
                            $transaction->refund_transaction_id = $refundResult['refund_transaction_id'] ?? null;
                            $transaction->refund_amount = $refundAmount;
                            $transaction->refunded_at = now();
                            $transaction->save();

                            Log::info('cancelOrder: [STEP 11.1] Transaction updated with Paytm refund details', [
                                'order_id' => $orderId,
                                'transaction_id' => $transaction->id,
                                'refund_transaction_id' => $transaction->refund_transaction_id,
                                'refund_amount' => $transaction->refund_amount
                            ]);

                            // Also update paytm_transactions table if record exists
                            $paytmTransaction = \App\Models\PaytmTransaction::where('order_id', $orderId)
                                ->where('user_id', $user->id)
                                ->first();

                            if ($paytmTransaction) {
                                $paytmTransaction->is_refunded = 1;
                                $paytmTransaction->internal_refund_id = $refundResult['internal_refund_id'] ?? null;
                                $paytmTransaction->refund_id = $refundResult['refund_transaction_id'] ?? null;
                                $paytmTransaction->refund_amount = $refundAmount;
                                $paytmTransaction->refunded_at = now();
                                $paytmTransaction->save();

                                Log::info('cancelOrder: [STEP 11.2] Paytm transaction table updated with refund', [
                                    'order_id' => $orderId,
                                    'paytm_transaction_id' => $paytmTransaction->id,
                                    'internal_refund_id' => $paytmTransaction->internal_refund_id,
                                    'refund_id' => $paytmTransaction->refund_id
                                ]);
                            }

                        } else {
                            Log::info('cancelOrder: [STEP 9] Non-PhonePe/Paytm payment type, skipping refund API', [
                                'order_id' => $orderId,
                                'payment_type' => $transaction->type,
                                'note' => 'Manual refund may be required'
                            ]);
                        }
                    } else {
                        Log::warning('cancelOrder: [STEP 8] Refund amount is zero or negative', [
                            'order_id' => $orderId,
                            'refund_amount' => $refundAmount
                        ]);
                    }
                } else {
                    Log::warning('cancelOrder: [STEP 7] No successful transaction found for order', [
                        'order_id' => $orderId,
                        'transaction_exists' => $transaction ? true : false,
                        'txn_id_exists' => $transaction ? ($transaction->txn_id ? true : false) : false
                    ]);
                }
            } else {
                Log::info('cancelOrder: [STEP 7] COD payment, no refund needed', [
                    'order_id' => $orderId
                ]);
            }

            // Archive rows to cancelled_order_seller_tracking before deleting
            Log::info('cancelOrder: [STEP 12] Archiving order_seller_status_tracking records', [
                'order_id' => $orderId
            ]);

            $trackingRows = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->get();

            if ($trackingRows->isNotEmpty()) {
                $now = now();
                $archive = $trackingRows->map(function ($row) use ($now) {
                    return [
                        'original_tracking_id' => $row->id,
                        'order_id'             => $row->order_id,
                        'seller_id'            => $row->seller_id,
                        'store_id'             => $row->store_id,
                        'store_location_id'    => $row->store_location_id,
                        'is_zenfoo_store'      => $row->is_zenfoo_store,
                        'is_driver_picked'     => $row->is_driver_picked,
                        'driver_captured_images_when_marked_as_pickup' => $row->driver_captured_images_when_marked_as_pickup,
                        'status'                      => $row->status,
                        'otp'                         => $row->otp,
                        'is_seller_started_preparing' => $row->is_seller_started_preparing,
                        'delayed_time_in_min'         => $row->delayed_time_in_min,
                        'driver_arrived_at_seller'    => $row->driver_arrived_at_seller,
                        'prep_time'                   => $row->prep_time,
                        'cancelled_by'                => 'customer',
                        'cancelled_at'                => $now,
                        'created_at'                  => $now,
                        'updated_at'                  => $now,
                    ];
                })->toArray();

                DB::table('cancelled_order_seller_tracking')->insert($archive);

                Log::info('cancelOrder: [STEP 12.1] Archived tracking records to cancelled_order_seller_tracking', [
                    'order_id'      => $orderId,
                    'archived_rows' => count($archive),
                    'original_ids'  => $trackingRows->pluck('id')->toArray(),
                    'seller_ids'    => $trackingRows->pluck('seller_id')->unique()->values()->toArray(),
                ]);
            } else {
                Log::info('cancelOrder: [STEP 12] No tracking rows found — nothing to archive', [
                    'order_id' => $orderId,
                ]);
            }

            $deletedRows = DB::table('order_seller_status_tracking')
                ->where('order_id', $orderId)
                ->delete();

            Log::info('cancelOrder: [STEP 13] Deleted order_seller_status_tracking records', [
                'order_id'     => $orderId,
                'deleted_rows' => $deletedRows,
            ]);

            // Update order active_status to 7 (cancelled)
            Log::info('cancelOrder: [STEP 14] Updating order status to cancelled', [
                'order_id' => $orderId,
                'old_status' => $order->active_status,
                'new_status' => 7
            ]);

            $order->active_status = 7;
            $order->save();

            Log::info('cancelOrder: [STEP 15] Order status updated successfully', [
                'order_id'      => $orderId,
                'active_status' => $order->active_status,
            ]);

            // [STEP 15.5] Refund wallet amount if wallet was used for this order
            if ($order->wallet_balance > 0) {
                $currentBalance = $user->balance;
                $walletRefund = floatval($order->wallet_balance);
                $newBalance = $currentBalance + $walletRefund;

                CommonHelper::updateUserWalletBalance($newBalance, $user->id);
                CommonHelper::addWalletTransaction($orderId, 0, $user->id, 'credit', $walletRefund, 'Refund - Order Cancelled', 1, $order->payment_method);

                // Reset wallet_balance on order so it's not refunded again
                $order->wallet_balance = 0;
                $order->save();

                Log::info('cancelOrder: [STEP 15.5] Wallet amount refunded', [
                    'order_id'        => $orderId,
                    'wallet_refund'   => $walletRefund,
                    'old_balance'     => $currentBalance,
                    'new_balance'     => $newBalance,
                ]);
            }

            DB::commit();
            Log::info('cancelOrder: [STEP 16] Transaction committed successfully', [
                'order_id' => $orderId
            ]);

            // Update order status to "Cancelled" in Firestore
            try {
                $orderStatusResult = FirestoreOrderETAService::updateOrderStatus(
                    $orderId,
                    'Order Cancelled',
                    'Your order has been cancelled'
                );
                Log::info('cancelOrder: [STEP 16.1] Firestore order status updated to Cancelled', [
                    'order_id' => $orderId,
                    'result' => $orderStatusResult
                ]);
            } catch (\Exception $firestoreException) {
                Log::error('cancelOrder: [STEP 16.1] Failed to update Firestore order status', [
                    'order_id' => $orderId,
                    'error' => $firestoreException->getMessage()
                ]);
                // Continue execution even if Firestore update fails
            }

            $successMessage = 'Order cancelled successfully.';
            if ($refundResult && $refundResult['success']) {
                $successMessage = 'Order cancelled successfully. Refund has been initiated and will be credited to your account.';
            }

            Log::info('cancelOrder: [STEP 17] Order cancellation completed', [
                'order_id' => $orderId,
                'refund_initiated' => $refundResult && $refundResult['success'] ? true : false,
                'message' => $successMessage
            ]);

            return CommonHelper::responseSuccess($successMessage);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('cancelOrder: Exception occurred', [
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
                'trace' => $e->getTraceAsString(),
                'user_id' => Auth::guard('api-customers')->id(),
                'order_id' => $request->order_id ?? null
            ]);
            return CommonHelper::responseError('Failed to cancel order.');
        }
    }

    /**
     * Check preorder availability for customer app
     * Returns status 1 if preorder is available, 0 otherwise
     */
    public function getPreorderStatus(Request $request)
    {
        try {
            $result = \App\Helpers\PreorderHelper::getPreorderStatus();

            return response()->json([
                'error' => false,
                'message' => $result['message'],
                'data' => [
                    'preorder_status' => $result['status'],
                    'reason' => $result['reason'],
                    'next_process_date' => $result['next_process_date'] ?? null,
                    'current_time' => \Carbon\Carbon::now('Asia/Kolkata')->format('Y-m-d H:i:s')
                ]
            ]);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Error checking preorder status: ' . $e->getMessage());
            return CommonHelper::responseError('Unable to check preorder status');
        }
    }
}
