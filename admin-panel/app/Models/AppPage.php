<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AppPage extends Model
{
    use HasFactory;

    protected $fillable = [
        'page_type',
        'title',
        'content',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    /**
     * Page type constants
     */
    const TYPE_TERMS = 'terms';
    const TYPE_PRIVACY = 'privacy';
    const TYPE_ABOUT = 'about';
    const TYPE_CONTACT = 'contact';

    /**
     * Get page by type
     */
    public static function getByType($type)
    {
        return self::where('page_type', $type)
            ->where('is_active', true)
            ->first();
    }

    /**
     * Get all active pages
     */
    public static function getAllActive()
    {
        return self::where('is_active', true)
            ->orderBy('page_type')
            ->get();
    }
}
