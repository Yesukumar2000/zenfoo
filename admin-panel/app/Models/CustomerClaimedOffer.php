<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CustomerClaimedOffer extends Model
{
    protected $table = 'customer_claimed_offers';

    protected $fillable = [
        'customer_id',
        'offer_meta_data',
        'date',
        'offer_amount',
    ];

    protected $casts = [
        'offer_meta_data' => 'array',
        'date' => 'date',
        'offer_amount' => 'decimal:2',
    ];

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }
}