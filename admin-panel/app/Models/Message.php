<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;

    protected $table = 'messages';

    protected $fillable = [
        'conversation_type',
        'participant_id',
        'admin_id',
        'seller_id',
        'order_id',
        'sender_type',
        'sender_id',
        'message',
        'attachment',
        'read_at',
    ];

    protected $casts = [
        'read_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Get the participant (customer, seller, or delivery_boy) based on conversation_type
     */
    public function participant()
    {
        if ($this->conversation_type === 'customer') {
            return $this->belongsTo(User::class, 'participant_id');
        }
        if ($this->conversation_type === 'seller_delivery') {
            return $this->belongsTo(DeliveryBoy::class, 'participant_id');
        }
        return $this->belongsTo(Seller::class, 'participant_id');
    }

    /**
     * Get the admin user
     */
    public function admin()
    {
        return $this->belongsTo(Admin::class, 'admin_id');
    }

    /**
     * Get the customer if conversation_type is 'customer'
     */
    public function customer()
    {
        return $this->belongsTo(User::class, 'participant_id');
    }

    /**
     * Get the seller if conversation_type is 'seller'
     */
    public function seller()
    {
        return $this->belongsTo(Seller::class, 'participant_id');
    }

    /**
     * Get the delivery boy if conversation_type is 'seller_delivery'
     */
    public function deliveryBoy()
    {
        return $this->belongsTo(DeliveryBoy::class, 'participant_id');
    }

    /**
     * Get the seller for seller_delivery conversations
     */
    public function sellerForDelivery()
    {
        return $this->belongsTo(Seller::class, 'seller_id');
    }

    /**
     * Get the order associated with this message
     */
    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    /**
     * Scope for customer conversations
     */
    public function scopeCustomerConversations($query)
    {
        return $query->where('conversation_type', 'customer');
    }

    /**
     * Scope for seller conversations
     */
    public function scopeSellerConversations($query)
    {
        return $query->where('conversation_type', 'seller');
    }

    /**
     * Scope for seller-delivery boy conversations
     */
    public function scopeSellerDeliveryConversations($query)
    {
        return $query->where('conversation_type', 'seller_delivery');
    }

    /**
     * Scope for unread messages
     */
    public function scopeUnread($query)
    {
        return $query->whereNull('read_at');
    }

    /**
     * Check if message is read
     */
    public function isRead()
    {
        return $this->read_at !== null;
    }

    /**
     * Mark message as read
     */
    public function markAsRead()
    {
        if (!$this->isRead()) {
            $this->update(['read_at' => now()]);
        }
    }
}
