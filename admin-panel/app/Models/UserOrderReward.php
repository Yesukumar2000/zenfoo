<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserOrderReward extends Model
{
    use HasFactory;

    protected $table = 'user_order_rewards';

    protected $fillable = [
        'order_count',
        'amount',
        'status',
    ];

    protected $casts = [
        'order_count' => 'integer',
        'amount' => 'decimal:2',
        'status' => 'boolean',
    ];
}
