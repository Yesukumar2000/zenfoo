<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LearningVideo extends Model
{
    use HasFactory;

    protected $fillable = [
        'topic_id',
        'title',
        'description',
        'video_url',
        'video_type',
        'thumbnail',
        'duration',
        'sort_order',
        'status',
        'created_by'
    ];

    protected $appends = ['video_url_full', 'thumbnail_url', 'formatted_duration'];

    public static $statusActive = 1;
    public static $statusInactive = 0;

    public static $typeUpload = 'upload';
    public static $typeYoutube = 'youtube';
    public static $typeVimeo = 'vimeo';

    public function topic()
    {
        return $this->belongsTo(LearningTopic::class, 'topic_id');
    }

    public function getVideoUrlFullAttribute()
    {
        return $this->video_url;
    }

    public function getThumbnailUrlAttribute()
    {
        if ($this->thumbnail) {
            return $this->thumbnail;
        }

        // Generate thumbnail from YouTube URL if applicable
        if ($this->video_type === self::$typeYoutube && $this->video_url) {
            preg_match('/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/ ]{11})/', $this->video_url, $match);
            if (isset($match[1])) {
                return 'https://img.youtube.com/vi/' . $match[1] . '/hqdefault.jpg';
            }
        }

        return null;
    }

    public function getFormattedDurationAttribute()
    {
        if (!$this->duration) {
            return null;
        }

        $hours = floor($this->duration / 3600);
        $minutes = floor(($this->duration % 3600) / 60);
        $seconds = $this->duration % 60;

        if ($hours > 0) {
            return sprintf('%02d:%02d:%02d', $hours, $minutes, $seconds);
        }
        return sprintf('%02d:%02d', $minutes, $seconds);
    }

    public function scopeActive($query)
    {
        return $query->where('status', self::$statusActive);
    }

    public function scopeOrdered($query)
    {
        return $query->orderBy('sort_order', 'asc');
    }

    public function scopeByTopic($query, $topicId)
    {
        return $query->where('topic_id', $topicId);
    }
}
