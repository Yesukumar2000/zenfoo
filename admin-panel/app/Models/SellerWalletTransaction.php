<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SellerWalletTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'order_item_id',
        'item_name',
        'products_json',
        'seller_id',
        'type',
        'amount',
        'admin_commission',
        'gst_percentage',
        'payment_gateway_fees',
        'vendor_wait_charge',
        'balance_before',
        'balance_after',
        'reference_type',
        'reference_id',
        'message',
        'admin_note',
        'status',
        'processed_by',
        'is_paid_to_seller',
        'is_refunded_to_customer',
        'refundable_amount',
        'payment_transaction_id',
        'paid_at',
        'paid_by',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'balance_before' => 'decimal:2',
        'balance_after' => 'decimal:2',
        'refundable_amount' => 'decimal:2',
        'status' => 'integer',
        'products_json' => 'array',
    ];

    /**
     * Transaction types
     */
    const TYPE_CREDIT = 'credit';
    const TYPE_DEBIT = 'debit';
    const TYPE_WITHDRAWAL = 'withdrawal';
    const TYPE_ORDER_COMMISSION = 'order_commission';
    const TYPE_REFUND = 'refund';
    const TYPE_ADJUSTMENT = 'adjustment';

    /**
     * Reference types
     */
    const REF_ORDER = 'order';
    const REF_ORDER_ITEM = 'order_item';
    const REF_WITHDRAWAL = 'withdrawal';
    const REF_REFUND = 'refund';
    const REF_COMMISSION = 'commission';
    const REF_ADJUSTMENT = 'adjustment';

    public static $rules = [
        'order_item_id' => 'unique:seller_wallet_transactions',
    ];

    /**
     * Get the seller that owns the transaction
     */
    public function seller()
    {
        return $this->belongsTo(Seller::class);
    }

    /**
     * Get the order if this is an order-related transaction
     */
    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * Get the order item if this is an order item-related transaction
     */
    public function orderItem()
    {
        return $this->belongsTo(OrderItem::class);
    }

    /**
     * Get the admin who processed this transaction
     */
    public function processedBy()
    {
        return $this->belongsTo(Admin::class, 'processed_by');
    }

    /**
     * Scope to get only credits
     */
    public function scopeCredits($query)
    {
        return $query->where('type', self::TYPE_CREDIT)
                    ->orWhere('type', self::TYPE_ORDER_COMMISSION)
                    ->orWhere('type', self::TYPE_REFUND);
    }

    /**
     * Scope to get only debits
     */
    public function scopeDebits($query)
    {
        return $query->where('type', self::TYPE_DEBIT)
                    ->orWhere('type', self::TYPE_WITHDRAWAL);
    }

    /**
     * Scope to get transactions for a date range
     */
    public function scopeDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('created_at', [$startDate, $endDate]);
    }

    /**
     * Get formatted amount with sign
     */
    public function getFormattedAmountAttribute()
    {
        $sign = in_array($this->type, [self::TYPE_CREDIT, self::TYPE_ORDER_COMMISSION, self::TYPE_REFUND]) ? '+' : '-';
        return $sign . number_format($this->amount, 2);
    }
}
