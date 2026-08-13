<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CustomerSuggestion extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_id',
        'suggestion',
        'admin_response',
    ];

    /**
     * Get the customer that owns the suggestion
     */
    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }
}
