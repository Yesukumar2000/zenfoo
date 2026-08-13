<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CartMetadata extends Model
{
    use HasFactory;

    protected $table = 'cart_metadata';

    protected $fillable = [
        'user_id',
        'promocode_id',
        'promo_code',
        'wallet_amount',
        'wallet_amount_value',
        'delivery_tip',
        'delivery_instructions',
        'contact_name',
        'contact_phone',
        'contact_email',
        'seller_notes',
        'combo_notes',
        'billing_breakdown',
        'billing_summary',
    ];

    protected $casts = [
        'seller_notes' => 'array',
        'combo_notes' => 'array',
        'billing_breakdown' => 'array',
        'billing_summary' => 'array',
        'delivery_tip' => 'decimal:2',
        'wallet_amount' => 'boolean',
        'wallet_amount_value' => 'decimal:2',
    ];

    // Relationship to user
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    // Relationship to promocode
    public function promocode()
    {
        return $this->belongsTo(PromoCode::class, 'promocode_id');
    }
}
