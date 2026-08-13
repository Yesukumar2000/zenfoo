<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SellerRegistrationHelper extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'img',
        'stores',
        'categories'
    ];

    protected $casts = [
        'categories' => 'array'
    ];

    protected $appends = ['image_url'];

    public function getImageUrlAttribute()
    {
        if (!$this->img) return null;
        if (str_starts_with($this->img, 'http')) return $this->img;
        return url('storage/' . $this->img);
    }

    public function store()
    {
        return $this->belongsTo(Store::class,'stores','id');
    }
}
