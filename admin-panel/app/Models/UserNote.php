<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class UserNote extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id',
        'note_text',
        'is_selected',
        'order_index',
    ];

    protected $casts = [
        'is_selected' => 'boolean',
        'order_index' => 'integer',
    ];

    /**
     * Relationship with User
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Scope to get only selected notes
     */
    public function scopeSelected($query)
    {
        return $query->where('is_selected', true);
    }

    /**
     * Scope to order by order_index
     */
    public function scopeOrdered($query)
    {
        return $query->orderBy('order_index', 'asc')->orderBy('created_at', 'desc');
    }
}
