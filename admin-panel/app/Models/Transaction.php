<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;
    public static $statusSuccess = "success";
    public static $statusFailed = "failed";
    

    public static $paymentTypeCod = "COD";

    public static $paymentTypeStripe = "Stripe";
    public static $paymentTypeRazorpay = "Razorpay";
    public static $paymentTypePaystack = "Paystack";
    public static $paymentTypePaytm = "Paytm";
    public static $paymentTypePaypal = "Paypal";
    public static $paymentTypeWallet = "Wallet";
    public static $paymentTypeMidtrans = "Midtrans";
    public static $paymentTypePhonepe = "Phonepe";
    public static $paymentTypeCashfree = "Cashfree";
    public static $paymentTypePaytabs = "Paytabs";

    protected $fillable = ['user_id','order_id','type',
        'txn_id','payu_txn_id','amount',
        'status','message','transaction_date',
        'is_refunded','refund_transaction_id','refund_amount','refunded_at'];

     protected $casts = [
        'amount' => 'decimal:2',
        'refund_amount' => 'decimal:2',
        'refunded_at' => 'datetime',
    ];

    // Force output as float
    public function getAmountAttribute($value)
    {
        return (float) $value;
    }
}
