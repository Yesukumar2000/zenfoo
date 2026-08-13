<?php

namespace App\Models;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    //use HasFactory,SoftDeletes;
    use HasFactory;
    protected $fillable = [
        'name',
        'category_id',
        'indicator',
        'manufacturer',
        'made_in',
        'return_status',
        'cancelable_status',
        'till_status',
        'description',
        'image',
        'seller_id',
        'is_approved',
        'brand_id',
        'return_days',
        'tax_id',
        'fssai_lic_no',
        'barcode',
        'meta_title',
        'meta_description',
        'meta_keyword',
        'schema_markup',
        'is_unlimited_stock',
        'type',
        'tags',
        'other_info',
        'total_allowed_quantity',
        'is_pre_order_item',
        'store_id',
        'category_group_id',
        'sub_category_group_id',
        'item_type_id',
        'tax',
        'other_images',
        'slug',
        'row_order',
        'status',
        'cod_allowed',
        'is_skinned_one',
        'is_cleaned',
        'before_cleaning_weight',
        'after_cleaning_weight',
        'pieces',
        'video_url',
    ];

    protected $appends = ['image_url'];

    protected $hidden=['created_at','updated_at','deleted_at'];

    public function seller(){

        return $this->belongsTo(Seller::class,'seller_id','id');
    }

    public function tax(){
        return $this->belongsTo(Tax::class,'tax_id','id');
    }

    public function madeInCountry(){
        return $this->belongsTo(Country::class,'made_in','id');
    }

    public function category(){
        return $this->belongsTo(Category::class,'category_id','id');
    }

    public function variants(){

        return $this->hasMany(ProductVariant::class,'product_id','id');
    }

    public function images(){

        return $this->hasMany(ProductImages::class,'product_id','id')
            ->where('product_variant_id',0);
    }

    public function brand(){
        return $this->belongsTo(Brand::class,'brand_id','id');
    }


    public function getImageUrlAttribute(){
        if($this->image){
            return str_starts_with($this->image, 'http') ? $this->image : url('storage/' . $this->image);
        }
        return '';
    }
    public function ratings()
    {
        return $this->hasMany(ProductRating::class, 'product_id');
    }
    public function tags()
    {
        return $this->belongsToMany(Tag::class, 'product_tag');
    }

    public function combos()
    {
        return $this->belongsToMany(Combo::class, 'combo_products')
            ->withPivot('variant_id', 'quantity')
            ->withTimestamps();
    }




    public function categoryType()
    {
        return $this->belongsTo(CategoryType::class, 'item_type_id');
    }


    public function categoryGroup()
    {
        return $this->belongsTo(CategoryGroup::class, 'category_group_id');
    }

    public function subCategoryGroup()
    {
        return $this->belongsTo(SubCategoryGroup::class, 'sub_category_group_id');
    }

    public function store()
    {
        return $this->belongsTo(Store::class);
    }


}
