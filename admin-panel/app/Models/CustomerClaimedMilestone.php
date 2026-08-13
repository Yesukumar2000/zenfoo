<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CustomerClaimedMilestone extends Model
{
    use HasFactory;

    protected $table = 'customer_claimed_milestones';

    protected $fillable = [
        'customer_id',
        'milestone_id',
        'milestone_meta_data',
        'claimed_date',
        'reward_amount',
        'status',
        'used_in_order_id',
        'used_date',
    ];

    protected $casts = [
        'milestone_meta_data' => 'array',
        'reward_amount' => 'decimal:2',
        'claimed_date' => 'date',
        'used_date' => 'date',
    ];

    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function milestone()
    {
        return $this->belongsTo(UserOrderReward::class, 'milestone_id');
    }

    public function order()
    {
        return $this->belongsTo(Order::class, 'used_in_order_id');
    }
}
