<?php

namespace App\Helpers;

use App\AssessmentDetail;
use App\AssessmentDetailUser;
use App\Models\Cart;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductImages;
use App\Models\ProductVariant;
use App\Permission;
use App\Role;
use App\StudentDetails;
use App\Tenant;
use App\Todo;
use App\TodoAccess;
use App\TodoTask;
use DateTime;
use DateTimeZone;
use \DB;
use App\Yoyaku;
use App\Settings;
use App\Students;
use App\Schedules;
use Carbon\Carbon;
use App\ClassUsage;
use App\Attendances;
use App\ClassesOffDays;
use App\Helpers\ScheduleHelper;
use App\Jobs\SendMail;
use App\NumberOfLesson;
use App\User;
use Exception;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\Storage;
use Response;

class ProductHelper{

    public static function isItemAvailable($product_id, $product_variant_id){

        $variant = ProductVariant::where('product_id',$product_id)->where('id',$product_variant_id)->first();
        if($variant){
                $product = Product::where('id',$product_id)->where('status',1)->first();
                return !empty($product);
        }else{
            return false;
        }
    }

    public static function isItemAvailableWithStock($product_id = null, $product_variant_id, $qty)
    {
        Log::info('=== CART ADD - Stock Check START ===', [
            'product_id' => $product_id,
            'variant_id' => $product_variant_id,
            'requested_qty' => $qty
        ]);

        // Fetch the variant first
        $variant = ProductVariant::where('id', $product_variant_id)
            ->where('status', 1)
            ->first();

        if (!$variant) {
            Log::warning('CART ADD - Variant not found or inactive', [
                'variant_id' => $product_variant_id
            ]);
            return false;
        }

        // Use product_id from the variant if not provided
        $product_id = $product_id ?? $variant->product_id;

        // Fetch the product
        $product = Product::where('id', $product_id)->where('status', 1)->first();

        if (!$product) {
            Log::warning('CART ADD - Product not found or inactive', [
                'product_id' => $product_id
            ]);
            return false;
        }

        Log::info('CART ADD - Product fetched', [
            'product_id' => $product->id,
            'product_name' => $product->name,
            'is_unlimited_stock' => $product->is_unlimited_stock,
            'type' => $product->type,
            'variant_stock' => $variant->stock,
            'variant_status' => $variant->status
        ]);

        // If is_unlimited_stock is enabled, return true immediately
        if ($product->is_unlimited_stock == 1) {
            Log::info('CART ADD - Unlimited stock enabled, allowing add to cart', [
                'product_id' => $product->id,
                'is_unlimited_stock' => $product->is_unlimited_stock
            ]);
            return true;
        }

        // Ensure stock is enough for the requested qty
        if($product->type == 'packet'){
            $stockAvailable = $variant->stock >= $qty;
            Log::info('CART ADD - Stock check (packet)', [
                'product_id' => $product->id,
                'variant_stock' => $variant->stock,
                'requested_qty' => $qty,
                'stock_available' => $stockAvailable
            ]);
            return $stockAvailable;
        }elseif($product->type == 'loose'){
            $requiredStock = $variant->measurement * $qty;
            $stockAvailable = $variant->stock >= $requiredStock;
            Log::info('CART ADD - Stock check (loose)', [
                'product_id' => $product->id,
                'variant_stock' => $variant->stock,
                'variant_measurement' => $variant->measurement,
                'requested_qty' => $qty,
                'required_stock' => $requiredStock,
                'stock_available' => $stockAvailable
            ]);
            return $stockAvailable;
        }
    }
    public static function isItemAvailableWithStockWithProductName($product_variant_id, $qty) {
        // Fetch the variant first
        $variant = ProductVariant::where('id', $product_variant_id)
            ->where('status', 1)
            ->first();
    
        // Check if the variant exists
        if (!$variant) {
            return ['status' => false, 'message' => 'Product variant not found'];
        }
    
        // Fetch the associated product
        $product = Product::where('id', $variant->product_id)
            ->where('status', 1)
            ->first();
    
        if (!$product) {
            return ['status' => false, 'message' => 'Product not found'];
        }
    
        // If unlimited stock is enabled, return true immediately
        if ($product->is_unlimited_stock == 1) {
            return ['status' => true, 'message' => 'Unlimited stock available'];
        }
    
        // Check if the requested quantity is available
        if ($variant->stock >= $qty) {
            return ['status' => true, 'message' => 'Stock is sufficient'];
        }
    
        // If stock is less than requested quantity, return low stock message
        return [
            'status' => false,
            'message' => "Low stock: Only {$variant->stock} available for {$product->name}"
        ];
    }
    

    public static function isItemAvailableInUserCart($user_id, $product_variant_id = "")
    {
        // Check regular cart items
        $cart = Cart::where('user_id',$user_id);
            if($product_variant_id!='') {
                $cart->where('product_variant_id', $product_variant_id);
            }

        $hasCartItems = $cart->exists();

        // If cart has items, return true
        if ($hasCartItems) {
            return true;
        }

        // Also check for custom combos (if no product_variant_id specified)
        if ($product_variant_id == '') {
            $hasCombos = DB::table('combo_custom_cart')
                ->where('user_id', $user_id)
                ->where('is_ordered', 0)
                ->exists();

            return $hasCombos;
        }

        return false;
    }

    public static function getTaxableAmount($product_variant_id)
    {
        /*$sql = "SELECT pv.id,pv.discounted_price,t.percentage,pv.price,
                CASE when pv.discounted_price !=0
                    THEN pv.discounted_price+(pv.discounted_price*t.percentage)/100
                    ELSE pv.price+(pv.price*t.percentage)/100 END as taxable_amount
                from product_variant pv left JOIN products p on pv.product_id=p.id LEFT JOIN taxes t on t.id=p.tax_id where pv.id=$product_variant_id";*/
                if (DB::table('product_variants')->where('id', $product_variant_id)->exists()) {
                    $sql = "SELECT 
                                pv.id,
                                pv.discounted_price,
                                t.percentage,
                                pv.price,
                                CASE 
                                    WHEN pv.discounted_price != 0 THEN pv.discounted_price + (pv.discounted_price * t.percentage) / 100
                                    ELSE pv.price + (pv.price * t.percentage) / 100 
                                END AS taxable_amount,
                                CASE 
                                    WHEN pv.discounted_price != 0 THEN pv.discounted_price + (pv.discounted_price * t.percentage) / 100
                                    ELSE pv.discounted_price 
                                END AS taxable_discounted_price,
                                CASE 
                                    WHEN pv.price != 0 THEN pv.price + (pv.price * t.percentage) / 100
                                    ELSE pv.price 
                                END AS taxable_price
                            FROM product_variants pv 
                            LEFT JOIN products p ON pv.product_id = p.id 
                            LEFT JOIN taxes t ON t.id = p.tax_id 
                            WHERE pv.id = :product_variant_id";
                
                    $result = DB::select($sql, ['product_variant_id' => $product_variant_id]);

        $result = !empty($result) ? $result[0] : array();
       
        //$result = $result[0];

        /*$result->discounted_price = floatval($result->discounted_price);
        $result->percentage = floatval($result->percentage);
        $result->price = floatval($result->price);
        $result->taxable_amount = floatval($result->taxable_amount);
        $result->taxable_discounted_price = floatval($result->taxable_discounted_price);
        $result->taxable_price = floatval($result->taxable_price);*/

        if (empty($result->percentage) && $result->discounted_price != 0) {
            $result->taxable_amount = $result->discounted_price;
        } else if (empty($result->percentage && $result->price != 0 )) {
            $result->taxable_amount = $result->price;
        } else if (!(empty($result->percentage)) && $result->discounted_price != 0) {
            $result->taxable_amount = $result->discounted_price + $result->discounted_price * ($result->percentage/100);
        }else if (!(empty($result->percentage)) && $result->price != 0) {
            $result->taxable_amount = $result->price + $result->price * ($result->percentage/100);
        }

        // dd($result->taxable_price, gettype($result->taxable_price), $result->taxable_discounted_price, gettype($result->taxable_discounted_price), $result->taxable_amount, gettype($result->taxable_amount), $result->price, gettype($result->price), $result->percentage, gettype($result->percentage), $result->discounted_price, gettype($result->discounted_price));

        return $result;


        /*$sql = "SELECT pv.id,pv.discounted_price,t.percentage,pv.price, p.tax_included_in_price,
        CASE when pv.discounted_price !=0 THEN pv.discounted_price+(pv.discounted_price*t.percentage)/100
                                        ELSE pv.price+(pv.price*t.percentage)/100 END as taxable_amount
        from product_variants pv left JOIN products p on pv.product_id=p.id LEFT JOIN taxes t on t.id=p.tax_id where pv.id=$product_variant_id";
        $result = DB::select(\DB::raw($sql));

        $result = !empty($result) ? $result[0] : array();
        if ($result->tax_included_in_price == 1 || empty($result->percentage)) {
            $result->taxable_amount = 0;
        }

        $result->percentage = $result->percentage??0;
        $result->taxable_amount = $result->taxable_amount??"";
        //    dd($result);
        return $result;*/
    }


    }
    

}
?>
