<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SellerWithdrawalRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'seller_id',
        'amount',
        'balance_before',
        'balance_after',
        'account_number',
        'bank_ifsc_code',
        'account_name',
        'bank_name',
        'branch_name',
        'status',
        'seller_note',
        'admin_note',
        'processed_by',
        'processed_at',
        'payment_method',
        'transaction_reference',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'balance_before' => 'decimal:2',
        'balance_after' => 'decimal:2',
        'processed_at' => 'datetime',
    ];

    // Status constants
    const STATUS_PENDING = 'pending';
    const STATUS_APPROVED = 'approved';
    const STATUS_REJECTED = 'rejected';
    const STATUS_PROCESSING = 'processing';
    const STATUS_COMPLETED = 'completed';

    /**
     * Get the seller that owns the withdrawal request
     */
    public function seller()
    {
        return $this->belongsTo(Seller::class);
    }

    /**
     * Get the admin who processed this request
     */
    public function processedBy()
    {
        return $this->belongsTo(Admin::class, 'processed_by');
    }

    /**
     * Scope to get pending requests
     */
    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    /**
     * Scope to get approved requests
     */
    public function scopeApproved($query)
    {
        return $query->where('status', self::STATUS_APPROVED);
    }
}
