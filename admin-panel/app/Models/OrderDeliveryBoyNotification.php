<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderDeliveryBoyNotification extends Model
{
    use HasFactory;

    protected $table = 'order_delivery_boy_notifications';

    protected $fillable = [
        'order_id',
        'attempt_number',
        'delivery_boy_ids',
        'drivers_notified_count',
        'on_ride_driver_ids',
        'on_ride_count',
        'status',
        'accepted_by',
        'accepted_at',
        'notified_at',
        'error_message',
        'skip_reasons',
    ];

    protected $casts = [
        'delivery_boy_ids' => 'array',
        'on_ride_driver_ids' => 'array',
        'skip_reasons' => 'array',
        'accepted_at' => 'datetime',
        'notified_at' => 'datetime',
    ];

    // Status constants
    const STATUS_SENT = 'sent';
    const STATUS_ACCEPTED = 'accepted';
    const STATUS_EXPIRED = 'expired';
    const STATUS_FAILED = 'failed';

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function acceptedByDeliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class, 'accepted_by');
    }

    /**
     * Get the latest attempt for an order
     */
    public static function getLatestAttempt(int $orderId): ?self
    {
        return self::where('order_id', $orderId)
            ->orderBy('attempt_number', 'desc')
            ->first();
    }

    /**
     * Get the next attempt number for an order
     */
    public static function getNextAttemptNumber(int $orderId): int
    {
        $latest = self::getLatestAttempt($orderId);
        return $latest ? $latest->attempt_number + 1 : 1;
    }

    /**
     * Get total drivers notified across all attempts for an order
     */
    public static function getTotalDriversNotified(int $orderId): int
    {
        return self::where('order_id', $orderId)
            ->sum('drivers_notified_count');
    }

    /**
     * Get all attempts for an order
     */
    public static function getAttemptsByOrder(int $orderId)
    {
        return self::where('order_id', $orderId)
            ->orderBy('attempt_number', 'asc')
            ->get();
    }

    /**
     * Mark as accepted by a delivery boy
     */
    public function markAsAccepted(int $deliveryBoyId): void
    {
        $this->status = self::STATUS_ACCEPTED;
        $this->accepted_by = $deliveryBoyId;
        $this->accepted_at = now();
        $this->save();
    }

    /**
     * Mark as expired
     */
    public function markAsExpired(): void
    {
        $this->status = self::STATUS_EXPIRED;
        $this->save();
    }

    /**
     * Mark as failed with error
     */
    public function markAsFailed(string $error): void
    {
        $this->status = self::STATUS_FAILED;
        $this->error_message = $error;
        $this->save();
    }
}