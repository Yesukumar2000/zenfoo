<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ZenfooOffer extends Model
{
    use HasFactory;

    protected $table = 'zenfoo_offers';

    protected $fillable = [
        'title',
        'description',
        'img_url',
        'order_count',
        'amount',
        'status',
        'start_date',
        'end_date',
    ];

    protected $appends = ['is_active', 'validity'];

    public function getIsActiveAttribute()
    {
        $start_date = $this->start_date;
        $end_date = $this->end_date;
        $current_date = now();

        if (!$start_date || !$end_date) {
            return $this->status == 1 ? 1 : 0;
        }

        $start = \Carbon\Carbon::parse($start_date);
        $end = \Carbon\Carbon::parse($end_date);

        if ($current_date->lt($start)) {
            return 0;
        }

        if ($current_date->gt($end)) {
            return 0;
        }

        return $this->status == 1 ? 1 : 0;
    }

    public function getValidityAttribute()
    {
        return ($this->is_active == 1) ? 'Active' : 'Inactive';
    }
}