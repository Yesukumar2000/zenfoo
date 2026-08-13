<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Combo extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'category_type', 'banner_video', 'description', 'price', 'image', 'type', 'type_id', 'store_id', 'status'];

    protected $appends = ['image_url', 'banner_video_url'];

    public function getImageUrlAttribute(){

        if($this->image){
            $image_url = $this->image;
        }else{
            $image_url = '';
        }
        return $image_url;
    }

    public function getBannerVideoUrlAttribute(){

        if($this->banner_video){
            $banner_video_url = $this->banner_video;
        }else{
            $banner_video_url = '';
        }
        return $banner_video_url;
    }
    

    public function categories()
    {
        return $this->belongsToMany(Category::class);
    }

    public function products()
    {
        return $this->belongsToMany(Product::class, 'combo_products')
            ->withPivot('variant_id', 'quantity')
            ->withTimestamps();
    }
}
