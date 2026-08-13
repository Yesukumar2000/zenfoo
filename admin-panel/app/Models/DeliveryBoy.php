<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryBoy extends Model
{
    use HasFactory;
    protected $appends = ['pending_order_count', 'driving_license_url', 'national_identity_card_url', 'profile_image_url'];

    public static $bonusFixed = 0;
    public static $bonusCommission = 1;
    public static $commission = "Commission";
    public static $fixed = "Fixed/Salaried";


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

    // Order Priority Constants
    public static $priorityBoth = 0;
    public static $priorityFoodGrocery = 1;
    public static $priorityMultiOrders = 2;

    public static $PriorityBoth = "Both";
    public static $PriorityFoodGrocery = "Grocery";
    public static $PriorityMultiOrders = "Multi Orders";

    public function admin(){
        return $this->belongsTo(Admin::class,'admin_id','id');
    }

    public function getPendingOrderCountAttribute(){
        $ignoreStatus = array(
            OrderStatusList::$paymentPending,
            OrderStatusList::$delivered,
            OrderStatusList::$cancelled,
            OrderStatusList::$returned,
        );
        return Order::where('delivery_boy_id', $this->id)->whereNotIn('active_status', $ignoreStatus)->count();
    }

    public function city(){
        return $this->belongsTo(City::class,'city_id','id');
    }

    public function vehicle(){
        return $this->belongsTo(Vehicle::class,'vehicle_id','id');
    }

    public function storeLocations(){
        return $this->belongsToMany(StoreLocation::class, 'delivery_boy_store_location', 'delivery_boy_id', 'store_location_id')->withTimestamps();
    }

    public function documents(){
        return $this->hasOne(DeliveryBoyDocument::class, 'delivery_boy_id');
    }

    public function activeSessions(){
        return $this->hasMany(DeliveryBoySession::class, 'delivery_boy_id');
    }

    public function getDrivingLicenseUrlAttribute(){
        if($this->driving_license){
            $driving_licence_url = $this->driving_license;
            return $driving_licence_url;
        }
        return $this->driving_license;
    }

    public function getNationalIdentityCardUrlAttribute(){
        if($this->national_identity_card){
            $national_identity_card_url = $this->national_identity_card;
            return $national_identity_card_url;
        }
        return $this->national_identity_card;
    }

    public function getProfileImageUrlAttribute(){
        if($this->profile_image){
            $profile_image_url = $this->profile_image;
            return $profile_image_url;
        }
        return null;
    }

    /**
     * Get all emergency contacts for this delivery boy
     */
    public function emergencyContacts()
    {
        return $this->hasMany(DeliveryBoyEmergencyContact::class, 'delivery_boy_id');
    }
}
