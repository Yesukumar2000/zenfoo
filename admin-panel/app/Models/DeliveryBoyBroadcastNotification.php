<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryBoyBroadcastNotification extends Model
{
    use HasFactory;

    protected $table = 'delivery_boy_broadcast_notifications';

    protected $fillable = [
        'title',
        'message',
        'image',
        'type',
        'total_delivery_boys',
        'success_count',
        'failed_count',
        'status',
        'sent_by',
        'sent_at',
    ];

    protected $casts = [
        'sent_at' => 'datetime',
        'total_delivery_boys' => 'integer',
        'success_count' => 'integer',
        'failed_count' => 'integer',
    ];

    const STATUS_PENDING = 'pending';
    const STATUS_SENDING = 'sending';
    const STATUS_COMPLETED = 'completed';
    const STATUS_FAILED = 'failed';

    const TYPE_GENERAL = 'general';
    const TYPE_PROMO = 'promo';
    const TYPE_ANNOUNCEMENT = 'announcement';

    /**
     * Relationship to the admin user who sent the notification
     */
    public function sentByAdmin()
    {
        return $this->belongsTo(Admin::class, 'sent_by');
    }

    /**
     * Get the image URL attribute
     * Since we now store full URL directly, just return the image field
     */
    public function getImageUrlAttribute()
    {
        return $this->image;
    }

    /**
     * Scope for completed notifications
     */
    public function scopeCompleted($query)
    {
        return $query->where('status', self::STATUS_COMPLETED);
    }

    /**
     * Scope for recent notifications
     */
    public function scopeRecent($query, $days = 30)
    {
        return $query->where('created_at', '>=', now()->subDays($days));
    }
}
