<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BrandCampaignProduct extends Model
{
    use HasFactory;

    protected $fillable = [
        'brand_campaign_id',
        'product_id',
        'display_order',
    ];

    /**
     * Get the campaign that owns the product
     */
    public function campaign()
    {
        return $this->belongsTo(BrandCampaign::class, 'brand_campaign_id');
    }

    /**
     * Get the product
     */
    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}
