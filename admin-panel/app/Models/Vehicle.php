<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Vehicle extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'name',
        'image',
        'status',
    ];

    protected $appends = ['image_url'];

    /**
     * Get delivery boys using this vehicle.
     *
     * @return \Illuminate\Database\Eloquent\Relations\HasMany
     */
    public function deliveryBoys()
    {
        return $this->hasMany(DeliveryBoy::class, 'vehicle_id');
    }

    /**
     * Get the image URL attribute.
     *
     * @return string|null
     */
    public function getImageUrlAttribute()
    {
        return $this->image;
    }

    /**
     * Scope a query to only include active vehicles.
     *
     * @param \Illuminate\Database\Eloquent\Builder $query
     * @return \Illuminate\Database\Eloquent\Builder
     */
    public function scopeActive($query)
    {
        return $query->where('status', 1);
    }
}
