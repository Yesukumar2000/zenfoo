<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ThinkingItem extends Model
{
    use HasFactory;

    protected $table = 'thinking_items';

    protected $fillable = [
        'name',
        'img_url',
        'status',
        'category_id'
    ];

    protected $casts = [
        'status' => 'integer',
        'category_id' => 'integer'
    ];

    /**
     * Get the category that owns the thinking item.
     */
    public function category()
    {
        return $this->belongsTo(Category::class, 'category_id');
    }
}
