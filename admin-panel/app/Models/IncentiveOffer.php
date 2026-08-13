<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class IncentiveOffer extends Model
{
    use HasFactory;

    protected $table = 'incentive_offers';

    protected $fillable = [
        'name',
        'banner_image',
        'description',
        'start_date',
        'end_date',
        'status',
        'min_gigs_required',
        'max_gigs_skip',
        'max_orders_cancel',
        'login_mandatory',
        'eligible_gig_ids'
    ];

    protected $casts = [
        'start_date' => 'datetime',
        'end_date' => 'datetime',
        'status' => 'integer',
        'min_gigs_required' => 'integer',
        'max_gigs_skip' => 'integer',
        'max_orders_cancel' => 'integer',
        'login_mandatory' => 'boolean',
        'eligible_gig_ids' => 'array',
    ];

    public function tiers()
    {
        return $this->hasMany(IncentiveOfferTier::class, 'incentive_offer_id')->orderBy('order_number');
    }

    public function progress()
    {
        return $this->hasMany(DeliveryBoyIncentiveProgress::class, 'incentive_offer_id');
    }

    public function participants()
    {
        return $this->hasMany(DeliveryBoyIncentiveProgress::class, 'incentive_offer_id');
    }

    public function scopeActive($query)
    {
        return $query->where('status', 1)
            ->where('start_date', '<=', now())
            ->where('end_date', '>=', now());
    }

    public function getBannerImageUrlAttribute()
    {
        return $this->banner_image ? $this->banner_image : null;
    }
}
