<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderComboItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'orders_id',
        'user_id',
        'combo_id',
        'combo_custom_cart_id',
        'combo_name',
        'combo_description',
        'product_count',
        'total_products_price',
        'total_actual_price',
        'discount_percentage',
        'sub_total',
        'products',
        'status',
        'active_status',
        'seller_id',
    ];

    protected $casts = [
        'products' => 'array',
        'status' => 'array',
        'total_products_price' => 'decimal:2',
        'total_actual_price' => 'decimal:2',
        'discount_percentage' => 'decimal:2',
        'sub_total' => 'decimal:2',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function combo()
    {
        return $this->belongsTo(Combo::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
