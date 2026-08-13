<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\PromoCode;
use App\Models\Slider;
use App\Models\Seller;
use App\Models\ProductVariant;
use App\Models\Cart;
use App\Services\MediaUploadService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class PromoCodeApiController extends Controller
{
    public function index()
    {
        $promocode = PromoCode::orderBy('id', 'DESC')->get();

        return CommonHelper::responseWithData($promocode);
    }

    public function save(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'promo_code' => 'required',
            'message' => 'required',
            'start_date' => 'required',
            'end_date' => 'required',
            'no_of_users' => 'nullable',
            'minimum_order_amount' => 'required',
            'discount_type' => 'required',
            'discount' => 'required',
           
            'repeat_usage' => 'nullable',
            
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $promocode = new PromoCode();
        $promocode->promo_code = $request->promo_code;
        $promocode->message = $request->message;
        $promocode->start_date = $request->start_date;
        $promocode->end_date = $request->end_date;
        $promocode->no_of_users = $request->no_of_users ?? 0;
        $promocode->minimum_order_amount = $request->minimum_order_amount;
        $promocode->discount = $request->discount;
        $promocode->discount_type = $request->discount_type;
        $promocode->max_discount_amount = $request->max_discount_amount ?? 0;
        $promocode->repeat_usage = $request->repeat_usage ?? 0;
        $promocode->no_of_repeat_usage = ($request->repeat_usage === 1 )?$request->no_of_repeat_usage:0;
        $promocode->status = 1;

        $promocode->is_specific_sellers = $request->is_selected_sellers ?? 0;
        $promocode->seller_ids = $request->seller_ids ?? "";
        $promocode->store_ids = $request->store_ids ?? "";

        if($request->hasFile('image')){
            $promocode->image = MediaUploadService::upload(
                $request->file('image'),
                'promocode'
            );
        } else {
            $promocode->image = '';
        }

        $promocode->save();
        return CommonHelper::responseSuccess("Promo Code Saved Successfully!");
    }

    public function update(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'promo_code' => 'required',
            'message' => 'required',
            'start_date' => 'required',
            'end_date' => 'required',
            'no_of_users' => 'nullable',
            'minimum_order_amount' => 'required',
            'discount' => 'required',
            'discount_type' => 'required',
           
            'repeat_usage' => 'nullable',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        if (isset($request->id)) {
            $promocode = PromoCode::find($request->id);
            $promocode->promo_code = $request->promo_code;
            $promocode->message = $request->message;
            $promocode->start_date = $request->start_date;
            $promocode->end_date = $request->end_date;
            $promocode->no_of_users = $request->no_of_users ?? 0;
            $promocode->minimum_order_amount = $request->minimum_order_amount;
            $promocode->discount = $request->discount;
            $promocode->discount_type = $request->discount_type;
            $promocode->max_discount_amount = $request->max_discount_amount ?? 0;
            $promocode->repeat_usage = $request->repeat_usage ?? 0;


            $promocode->is_specific_sellers = $request->is_selected_sellers ?? 0;
            $promocode->seller_ids = $request->seller_ids ?? "";
            $promocode->store_ids = $request->store_ids ?? "";


            if($promocode->repeat_usage == 1){
                $promocode->no_of_repeat_usage = $request->no_of_repeat_usage;
            }
            else{
                $promocode->no_of_repeat_usage = 0;
            }
            $promocode->status = $request->status;
            if($request->hasFile('image')){
                $promocode->image = MediaUploadService::upload(
                    $request->file('image'),
                    'promocode',
                    'public',
                    $promocode->image
                );
            }
            $promocode->save();
        }
        return CommonHelper::responseSuccess("Promo Code Updated Successfully!");
    }

    public function delete(Request $request)
    {

        if (isset($request->id)) {

            $promocode = PromoCode::find($request->id);
            if ($promocode) {
                $promocode->delete();
                return CommonHelper::responseSuccess("Promo Code Deleted Successfully!");
            } else {
                return CommonHelper::responseSuccess("Promo Code Already Deleted!");
            }
        }
    }



    
    public function getSellers(Request $request)
    {
        $sellers = Seller::select('id','store_name')
            ->whereNotNull('store_name')
            ->get()
            ->map(function($seller){
                return [
                    'id' => $seller->id,
                    'store_name' => $seller->store_name
                ];
            }
        );

        return response()->json([
            'status' => 1,
            'data' => $sellers,
        ]);
    }



    // public function getCouponsForCustomer(Request $request){

    //     $today = now()->setTimezone('Asia/Kolkata')->format('Y-m-d');

    //     $auth_user = auth()->guard('api')->user();

    //     // dd(request()->header('Authorization'),$auth_user);
    //     $user_id = $auth_user->id;

    //     $cart_data = Cart::where('user_id', $user_id)->get();

    //     $cart_value = $cart_data->reduce(
    //         function ($carry, $cart){
    //             $variant_price = ProductVariant::where('id', $cart->variant_id)->value('discounted_price');
    //             $quantity = $cart->quantity ?? 1;
    //             $value_with_quantity = $quantity * $variant_price;
    //             return $carry + $value_with_quantity;
    //         },0);

    //     $coupons = PromoCode::where('status',1)
    //                 ->whereDate('start_date', '<=', $today)
    //                 ->whereDate('end_date', '>=', $today)
    //                 ->orderBy('id','DESC')
    //                 ->get();
        
    //     return CommonHelper::responseWithData($coupons);

    // }


    public function getCouponsForCustomer(Request $request)
    {
        $today = now()->setTimezone('Asia/Kolkata')->format('Y-m-d');

        $auth_user = auth()->guard('api-customers')->user();
        if (!$auth_user) {
            return CommonHelper::responseError("Unauthorized");
        }

        $user_id = $auth_user->id;

        $cart_data = Cart::with(['product:id,store_id,seller_id'])
            ->where('user_id', $user_id)
            ->get();

        if ($cart_data->isEmpty()) {
            return CommonHelper::responseError("Your cart is empty.");
        }

        $cart_value = $cart_data->reduce(function ($carry, $cart) {
            $variant_price = ProductVariant::where('id', $cart->variant_id)->value('discounted_price');
            $quantity = $cart->quantity ?? 1;
            return $carry + ($variant_price * $quantity);
        }, 0);

        $cart_sellers = $cart_data->pluck('product.seller_id')->unique()->toArray();
        $cart_stores  = $cart_data->pluck('product.store_id')->unique()->toArray();

        // dd($cart_sellers,$cart_stores);


        $coupons = PromoCode::where('status', 1)
            ->whereDate('start_date', '<=', $today)
            ->whereDate('end_date', '>=', $today)
            ->orderBy('id', 'DESC')
            ->get();

        $response = [];

        foreach ($coupons as $coupon) {

            $is_applicable = $cart_value >= $coupon->minimum_order_amount;

            if ($coupon->is_selected_sellers == 1 && !empty($coupon->seller_ids)) {

                $allowed_sellers = explode(",", $coupon->seller_ids);

                if (!array_intersect($allowed_sellers, $cart_sellers)) {
                    $is_applicable = false;
                }
            }

            if (!empty($coupon->store_ids)) {

                $allowed_stores = explode(",", $coupon->store_ids);

                if (!array_intersect($allowed_stores, $cart_stores)) {
                    $is_applicable = false;
                }
            }

            if ($is_applicable) {

                if ($coupon->discount_type == "percentage") {

                    $discount_amount = ($coupon->discount / 100) * $cart_value;

                    // Apply max cap
                    if ($coupon->max_discount_amount > 0) {
                        $discount_amount = min($discount_amount, $coupon->max_discount_amount);
                    }

                } else { 
                    // amount type
                    $discount_amount = $coupon->discount;
                }

                $message = "You will get a {$coupon->discount_type} discount of {$coupon->discount}";

                if ($coupon->discount_type == "percentage" && $coupon->max_discount_amount > 0) {
                    $message .= " (max ₹{$coupon->max_discount_amount})";
                }

            } else {

                // Amount needed to unlock coupon
                $remaining = max(0, $coupon->minimum_order_amount - $cart_value);

                $message =
                    "Add ₹{$remaining} more to unlock " .
                    ($coupon->discount_type == 'percentage'
                        ? "{$coupon->discount}% discount"
                        : "₹{$coupon->discount} discount");
                
                $discount_amount = 0;
            }

            $response[] = [
                "id" => $coupon->id,
                "promo_code" => $coupon->promo_code,
                "message" => $message,
                "is_applicable" => $is_applicable ? 1 : 0,
                "discount_value" => $discount_amount,
                "minimum_order_amount" => $coupon->minimum_order_amount,
                "cart_value" => $cart_value,
                "seller_restriction" => $coupon->seller_ids,
                "store_restriction" => $coupon->store_ids
            ];
        }

        return CommonHelper::responseWithData($response);
    }




}
