<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ProductImages extends Model
{
    use HasFactory;
    public $timestamps = false;

    protected $hidden = [];
    protected $appends = ['image_url'];

    public function getImageUrlAttribute(){
        if($this->image){
            return str_starts_with($this->image, 'http') ? $this->image : url('storage/' . $this->image);
        }
        return '';
    }
}
