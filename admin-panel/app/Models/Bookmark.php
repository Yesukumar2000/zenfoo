<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Bookmark extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'bookmarkable_type',
        'bookmarkable_id',
        'type',
    ];

    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Relationships
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Polymorphic relationship to Product, Seller, or Combo
     */
    public function bookmarkable()
    {
        return $this->morphTo();
    }

    /**
     * Convenience relationships for easy access
     */
    public function product()
    {
        return $this->morphOne(Product::class, 'bookmarkable');
    }

    public function seller()
    {
        return $this->morphOne(Seller::class, 'bookmarkable');
    }

    public function combo()
    {
        return $this->morphOne(Combo::class, 'bookmarkable');
    }

    /**
     * Scopes
     */
    public function scopeByUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeProducts($query)
    {
        return $query->where('type', 'product');
    }

    public function scopeSellers($query)
    {
        return $query->where('type', 'seller');
    }

    public function scopeCombos($query)
    {
        return $query->where('type', 'combo');
    }

    /**
     * Accessors
     */
    public function getImageUrlAttribute()
    {
        if ($this->bookmarkable) {
            return $this->bookmarkable->image ?? null;
        }
        return null;
    }
}
