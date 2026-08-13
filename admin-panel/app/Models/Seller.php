<?php

namespace App\Models;

//use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Seller extends Model
{
    use HasFactory;
    protected $hidden = [];
    protected $appends = ['logo_url','national_identity_card_url','address_proof_url','pan_img_url','fssai_img_url','agreement_pdf_url','agreement_signature_url','categories_array','pickup_store_timings_array','store_images_urls'];
    protected $casts = [
        'other_store_ids' => 'array',
    ];

    public static $statusRegistered = 0;
    public static $statusActive = 1;
    public static $statusRejected = 2;
    public static $statusDeactivated = 3;
    public static $statusRemoved = 7;

    public static $Registered = "Registered";
    public static $Active = "Active";
    public static $Rejected = "Rejected";
    public static $Deactivated = "Deactivated";
    public static $Removed = "Removed";



    public function getLogoUrlAttribute(){
        if($this->logo){
            return str_starts_with($this->logo, 'http') ? $this->logo : url('storage/' . $this->logo);
        }
        return $this->logo;
    }

    public function getNationalIdentityCardUrlAttribute(){
        if($this->national_identity_card){
            return str_starts_with($this->national_identity_card, 'http') ? $this->national_identity_card : url('storage/' . $this->national_identity_card);
        }
        return $this->national_identity_card;
    }

    public function getAddressProofUrlAttribute(){
        if($this->address_proof){
            return str_starts_with($this->address_proof, 'http') ? $this->address_proof : url('storage/' . $this->address_proof);
        }
        return $this->address_proof;
    }

    public function getPanImgUrlAttribute(){
        if($this->pan_img){
            return str_starts_with($this->pan_img, 'http') ? $this->pan_img : url('storage/' . $this->pan_img);
        }
        return $this->pan_img;
    }

    public function getFssaiImgUrlAttribute(){
        if($this->fssai_img){
            return str_starts_with($this->fssai_img, 'http') ? $this->fssai_img : url('storage/' . $this->fssai_img);
        }
        return $this->fssai_img;
    }

    public function getAgreementPdfUrlAttribute(){
        if($this->agreement_pdf){
            return str_starts_with($this->agreement_pdf, 'http') ? $this->agreement_pdf : url('storage/' . $this->agreement_pdf);
        }
        return $this->agreement_pdf;
    }

    public function getAgreementSignatureUrlAttribute(){
        if($this->agreement_signature){
            return str_starts_with($this->agreement_signature, 'http') ? $this->agreement_signature : url('storage/' . $this->agreement_signature);
        }
        return $this->agreement_signature;
    }

    public function admin(){
        return $this->belongsTo(Admin::class,'admin_id','id');
    }

    public function city(){
        return $this->belongsTo(City::class,'city_id','id');
    }

    public function store(){
        return $this->belongsTo(Store::class,'store_id','id');
    }

    public function categories()
    {
        return $this->belongsToMany(Category::class, 'sellers', 'id', 'categories');
    }
    public function getCategoriesArrayAttribute()
    {
        $categoriesArray = is_string($this->categories) ? explode(',', $this->categories): [];
        $categoriesCollection = collect($categoriesArray); 
        $categoryNames = Category::whereIn('id', $categoriesCollection)->pluck('name')->toArray();
        $commaSeparatedNames = implode(', ', $categoryNames);
        return $commaSeparatedNames;
    }

    /**
     * Get pickup store timings as array
     */
    public function getPickupStoreTimingsArrayAttribute()
    {
        if ($this->pickup_store_timings) {
            return json_decode($this->pickup_store_timings, true);
        }
        return [];
    }

    /**
     * Set pickup store timings from array
     */
    public function setPickupStoreTimingsAttribute($value)
    {
        if (is_array($value)) {
            $this->attributes['pickup_store_timings'] = json_encode($value);
        } else {
            $this->attributes['pickup_store_timings'] = $value;
        }
    }

    /**
     * Get store images URLs as array
     */
    public function getStoreImagesUrlsAttribute()
    {
        if (!empty($this->store_images)) {
            $storeImages = json_decode($this->store_images, true);
            if (is_array($storeImages)) {
                return array_map(fn($img) => str_starts_with($img, 'http') ? $img : url('storage/' . $img), $storeImages);
            }
        }
        return [];
    }

    /**
     * Get seller bank accounts
     */
    public function bankAccounts()
    {
        return $this->hasMany(SellerBankAccount::class, 'seller_id', 'id');
    }
}
