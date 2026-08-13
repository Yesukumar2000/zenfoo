<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryBoyIncentiveTierCredit extends Model
{
    use HasFactory;

    protected $table = 'delivery_boy_incentive_tier_credits';

    protected $fillable = [
        'delivery_boy_incentive_progress_id',
        'tier_id',
        'incentive_amount',
        'transaction_id',
        'credited_at'
    ];

    protected $casts = [
        'incentive_amount' => 'decimal:2',
        'credited_at' => 'datetime'
    ];

    /**
     * Relationship: belongs to incentive progress
     */
    public function progress()
    {
        return $this->belongsTo(DeliveryBoyIncentiveProgress::class, 'delivery_boy_incentive_progress_id');
    }

    /**
     * Relationship: belongs to tier
     */
    public function tier()
    {
        return $this->belongsTo(IncentiveOfferTier::class, 'tier_id');
    }

    /**
     * Relationship: belongs to transaction (if credited)
     */
    public function transaction()
    {
        return $this->belongsTo(DeliveryBoyTransaction::class, 'transaction_id');
    }
}
