<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PendingDeliveryAssignment extends Model
{
    use HasFactory;

    protected $table = 'pending_delivery_assignments';

    protected $fillable = [
        'order_id',
        'seller_locations',
        'attempts',
        'last_attempted_at',
        'status',
        'last_error'
    ];

    protected $casts = [
        'seller_locations' => 'array',
        'last_attempted_at' => 'datetime',
    ];

    // Status constants
    const STATUS_PENDING = 'pending';
    const STATUS_ASSIGNED = 'assigned';
    const STATUS_FAILED = 'failed';
    const STATUS_CANCELLED = 'cancelled';

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * Scope to get pending assignments
     */
    public function scopePending($query)
    {
        return $query->where('status', self::STATUS_PENDING);
    }

    /**
     * Increment attempt count
     */
    public function incrementAttempt()
    {
        $this->attempts += 1;
        $this->last_attempted_at = now();
        $this->save();
    }

    /**
     * Mark as assigned
     */
    public function markAsAssigned()
    {
        $this->status = self::STATUS_ASSIGNED;
        $this->save();
    }

    /**
     * Mark as failed with error
     */
    public function markAsFailed($error = null)
    {
        $this->status = self::STATUS_FAILED;
        $this->last_error = $error;
        $this->save();
    }
}