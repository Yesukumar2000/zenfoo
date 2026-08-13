<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PaytmTransaction extends Model
{
    use HasFactory;

    protected $table = 'paytm_transactions';

    // Status constants
    public static $statusSuccess = "success";
    public static $statusFailed = "failed";
    public static $statusPending = "pending";

    // Type of payment constants
    public static $typeOrderPlacing = "order_placing";
    public static $typeWalletTopup = "wallet_topup";

    protected $fillable = [
        'user_id',
        'order_id',
        'txn_id',
        'paytm_txn_id',
        'bank_txn_id',
        'amount',
        'payment_mode',
        'bank_name',
        'gateway_name',
        'status',
        'response_code',
        'response_msg',
        'is_captured',
        'type_of_payment',
        'transaction_date',
        'metadata'
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'is_captured' => 'boolean',
        'transaction_date' => 'datetime',
        'metadata' => 'array'
    ];

    /**
     * Get the user that owns the transaction
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the order associated with the transaction (if any)
     */
    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id', 'id');
    }

    /**
     * Force output amount as float
     */
    public function getAmountAttribute($value)
    {
        return (float) $value;
    }

    /**
     * Check if transaction is successful
     */
    public function isSuccessful()
    {
        return $this->status === self::$statusSuccess;
    }

    /**
     * Check if transaction is captured
     */
    public function isCaptured()
    {
        return $this->is_captured == 1;
    }
}
