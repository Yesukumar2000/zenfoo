<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PromoCode extends Model
{
    use HasFactory;

    protected $appends = ['image_url','is_applicable','validity'];
    protected $hidden = [];

    public function getImageUrlAttribute(){
        if($this->image){
            return str_starts_with($this->image, 'http') ? $this->image : url('storage/' . $this->image);
        }
        return '';
    }

    public function getIsApplicableAttribute()
    {
        $start_date = $this->start_date;
        $end_date = $this->end_date;
        $current_date = now(); // Use Laravel's now() helper for consistent timezone

        // Convert dates to Carbon instances for proper comparison
        $start = \Carbon\Carbon::parse($start_date);
        $end = \Carbon\Carbon::parse($end_date);

        // Check if current date is within the valid range
        if ($current_date->lt($start)) {
            // Current date is before start date
            return 0;
        }

        if ($current_date->gt($end)) {
            // Current date is after end date
            return 0;
        }

        // Current date is within the valid range (inclusive of start and end dates)
        return 1;
    }

    public function getValidityAttribute(){
        return ($this->is_applicable == 1) ? 'Acceptable' : 'Expired' ;
    }



}
