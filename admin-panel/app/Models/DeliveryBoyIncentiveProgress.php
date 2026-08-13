<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryBoyIncentiveProgress extends Model
{
    use HasFactory;

    protected $table = 'delivery_boy_incentive_progress';

    protected $fillable = [
        'delivery_boy_id',
        'incentive_offer_id',
        'current_earnings',
        'gigs_completed',
        'gigs_skipped',
        'orders_cancelled',
        'login_compliance',
        'is_eligible',
        'is_completed',
        'incentive_earned',
        'achieved_tier_id',
        'payout_amount',
        'payout_status',
        'payout_processed_at',
        'completed_at',
        'status'
    ];

    protected $casts = [
        'current_earnings' => 'decimal:2',
        'incentive_earned' => 'decimal:2',
        'payout_amount' => 'decimal:2',
        'gigs_completed' => 'integer',
        'gigs_skipped' => 'integer',
        'orders_cancelled' => 'integer',
        'login_compliance' => 'boolean',
        'is_eligible' => 'boolean',
        'is_completed' => 'boolean',
        'completed_at' => 'datetime',
        'payout_processed_at' => 'datetime',
    ];

    public function deliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class);
    }

    public function incentiveOffer()
    {
        return $this->belongsTo(IncentiveOffer::class, 'incentive_offer_id');
    }

    public function achievedTier()
    {
        return $this->belongsTo(IncentiveOfferTier::class, 'achieved_tier_id');
    }

    /**
     * Get all credited tiers for this progress
     */
    public function creditedTiers()
    {
        return $this->hasMany(DeliveryBoyIncentiveTierCredit::class, 'delivery_boy_incentive_progress_id');
    }

    /**
     * Get the next tier the delivery boy can achieve
     */
    public function getNextTierAttribute()
    {
        $tiers = $this->incentiveOffer->tiers()
            ->where('earnings_target', '>', $this->current_earnings)
            ->orderBy('earnings_target', 'asc')
            ->first();

        return $tiers;
    }

    /**
     * Get the current achieved tier
     */
    public function getCurrentTierAttribute()
    {
        $tiers = $this->incentiveOffer->tiers()
            ->where('earnings_target', '<=', $this->current_earnings)
            ->orderBy('earnings_target', 'desc')
            ->first();

        return $tiers;
    }
}
