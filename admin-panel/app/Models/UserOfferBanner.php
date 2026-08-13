<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserOfferBanner extends Model
{
    use HasFactory;

    protected $table = 'user_offer_banners';

    protected $fillable = [
        'title',
        'image_url',
        'sort_order',
        'status',
    ];

    protected $casts = [
        'sort_order' => 'integer',
        'status' => 'boolean',
    ];
}
