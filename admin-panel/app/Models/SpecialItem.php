<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SpecialItem extends Model
{
    use HasFactory;

    protected $fillable = ['title','category_ids'];

    protected $casts = [
        'category_ids' => 'array', 
    ];

     public function getCategoryIdsArrayAttribute()
    {
        return explode(',', $this->category_ids);
    }
}
