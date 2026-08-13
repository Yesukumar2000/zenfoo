<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Carbon\Carbon;

class BrandCampaign extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'name',
        'description',
        'primary_image_url',
        'secondary_image_url',
        'banners',
        'brand_id',
        'product_ids',
        'category_ids',
        'start_date',
        'end_date',
        'expired_at',
        'status',
        'is_featured',
        'display_order',
        'campaign_type',
        'theme_color',
        'metadata',
    ];

    protected $casts = [
        'banners' => 'array',
        'product_ids' => 'array',
        'category_ids' => 'array',
        'metadata' => 'array',
        'start_date' => 'datetime',
        'end_date' => 'datetime',
        'expired_at' => 'datetime',
    ];

    /**
     * Get the brand associated with the campaign
     */
    public function brand()
    {
        return $this->belongsTo(Brand::class);
    }

    /**
     * Get campaign products pivot records
     */
    public function campaignProducts()
    {
        return $this->hasMany(BrandCampaignProduct::class, 'brand_campaign_id');
    }

    /**
     * Get products associated with the campaign through pivot table
     */
    public function products()
    {
        return $this->belongsToMany(Product::class, 'brand_campaign_products', 'brand_campaign_id', 'product_id')
            ->withPivot('display_order')
            ->withTimestamps()
            ->orderBy('brand_campaign_products.display_order', 'asc');
    }

    /**
     * Get product IDs array (for backward compatibility)
     */
    public function getProductIdsAttribute()
    {
        return $this->products()->pluck('products.id')->toArray();
    }

    /**
     * Check if campaign is currently active
     */
    public function isActive(): bool
    {
        $now = Carbon::now();
        return $this->status == 1
            && $now >= $this->start_date
            && $now <= $this->end_date
            && ($this->expired_at === null || $now <= $this->expired_at);
    }

    /**
     * Check if campaign is expired
     */
    public function isExpired(): bool
    {
        $now = Carbon::now();
        return $now > $this->end_date
            || ($this->expired_at !== null && $now > $this->expired_at)
            || $this->status == 0;
    }

    /**
     * Get days remaining until expiry
     */
    public function daysUntilExpiry(): ?int
    {
        $expiryDate = $this->expired_at ?? $this->end_date;
        if (!$expiryDate) {
            return null;
        }

        $days = Carbon::now()->diffInDays($expiryDate, false);
        return $days >= 0 ? $days : 0;
    }

    /**
     * Scope to get only active campaigns
     */
    public function scopeActive($query)
    {
        $now = Carbon::now();
        return $query->where('status', 1)
            ->where('start_date', '<=', $now)
            ->where('end_date', '>=', $now)
            ->where(function ($q) use ($now) {
                $q->whereNull('expired_at')
                    ->orWhere('expired_at', '>=', $now);
            });
    }

    /**
     * Scope to get the current active campaign (only one)
     * Returns the most recently started campaign
     */
    public function scopeCurrent($query)
    {
        return $query->active()
            ->orderBy('start_date', 'desc')
            ->orderBy('display_order', 'asc')
            ->limit(1);
    }

    /**
     * Scope to get featured campaigns
     */
    public function scopeFeatured($query)
    {
        return $query->where('is_featured', 1)->active();
    }

    /**
     * Scope to get campaigns by brand
     */
    public function scopeByBrand($query, $brandId)
    {
        return $query->where('brand_id', $brandId);
    }

    /**
     * Scope to get campaigns by type
     */
    public function scopeByType($query, $type)
    {
        return $query->where('campaign_type', $type);
    }
};
