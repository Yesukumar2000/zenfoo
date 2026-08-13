<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LearningTopic extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'image',
        'sort_order',
        'status',
        'created_by'
    ];

    protected $appends = ['image_url', 'videos_count'];

    public static $statusActive = 1;
    public static $statusInactive = 0;

    public function videos()
    {
        return $this->hasMany(LearningVideo::class, 'topic_id');
    }

    public function activeVideos()
    {
        return $this->hasMany(LearningVideo::class, 'topic_id')
            ->where('status', LearningVideo::$statusActive)
            ->orderBy('sort_order', 'asc');
    }

    public function getImageUrlAttribute()
    {
        return $this->image;
    }

    public function getVideosCountAttribute()
    {
        return $this->videos()->count();
    }

    public function scopeActive($query)
    {
        return $query->where('status', self::$statusActive);
    }

    public function scopeOrdered($query)
    {
        return $query->orderBy('sort_order', 'asc');
    }
}
