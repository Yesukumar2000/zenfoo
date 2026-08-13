<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class IncentiveOfferTier extends Model
{
    use HasFactory;

    protected $fillable = [
        'incentive_offer_id',
        'earnings_target',
        'incentive_amount',
        'tier_name',
        'order_number'
    ];

    protected $casts = [
        'earnings_target' => 'decimal:2',
        'incentive_amount' => 'decimal:2',
        'order_number' => 'integer',
    ];

    public function incentiveOffer()
    {
        return $this->belongsTo(IncentiveOffer::class, 'incentive_offer_id');
    }
}
