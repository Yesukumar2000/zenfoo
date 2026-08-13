<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StoreLocation extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'address',
        'latitude',
        'longitude',
        'phone',
        'email',
        'city_id',
        'status'
    ];

    protected $casts = [
        'status' => 'integer',
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
    ];

    /**
     * Get the city that owns the store location
     */
    public function city()
    {
        return $this->belongsTo(City::class, 'city_id');
    }

    /**
     * Get delivery boys assigned to this store location
     */
    public function deliveryBoys()
    {
        return $this->belongsToMany(DeliveryBoy::class, 'delivery_boy_store_location', 'store_location_id', 'delivery_boy_id')->withTimestamps();
    }

    /**
     * Get the Zenfoo seller (store admin) for this store location
     * Assumes there's one seller per city who manages the Zenfoo store location
     */
    public function seller()
    {
        // Return the seller (admin) from the store if it exists, or null
        // StoreLocation is for Zenfoo, so we get the seller managing this city's Zenfoo store
        return $this->belongsTo(Seller::class, 'city_id', 'city_id');
    }

    /**
     * Scope for active store locations
     */
    public function scopeActive($query)
    {
        return $query->where('status', 1);
    }

    /**
     * Scope for filtering by city
     */
    public function scopeByCity($query, $cityId)
    {
        return $query->where('city_id', $cityId);
    }
}
