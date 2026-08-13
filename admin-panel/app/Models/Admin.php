<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Log;
use Laravel\Passport\HasApiTokens;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Traits\HasRoles;


class Admin extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable,HasRoles;

    protected $appends = ['allPermissions','seller_status','delivery_boy_status'];
    protected $hidden = ['password'];

    protected $fillable = ['username','email','password','role_id','created_by','department_id','is_blocked','login_count','two_factor_enabled'];

    public function role(){
        return $this->hasOne(Role::class,'id','role_id');
    }

    public function department(){
        return $this->belongsTo(Department::class,'department_id','id');
    }

    public function loginLogs(){
        return $this->hasMany(AdminLoginLog::class,'admin_id','id');
    }

    public function sessions(){
        return $this->hasMany(AdminSession::class,'admin_id','id');
    }

    public function kyc(){
        return $this->hasOne(AdminKyc::class,'admin_id','id')->latestOfMany();
    }

    public function getAllPermissionsAttribute()
    {
        $permissions = [];
       
        if ($this->role){
            $rolePermissions = \DB::table('role_has_permissions')
                ->where('role_id', $this->role->id)
                ->get()->pluck('permission_id')->toArray();
        $permissions = Permission::whereIn('id', $rolePermissions)->get()->pluck('name')->toArray();
        }
        return $permissions;
    }

    public function notifications()
    {
        return $this->morphMany(PanelNotification::class, 'notifiable')->orderBy('created_at', 'desc');
    }

    public function seller(){
        return $this->belongsTo(Seller::class,'id','admin_id');
    }

    public function getSellerStatusAttribute()
    {
        $status = 0;
        if($this->seller){
            $status = $this->seller->status;
        }
        return $status;
    }

    public function deliveryBoy(){
        return $this->belongsTo(DeliveryBoy::class,'id','admin_id');
    }

    public function getDeliveryBoyStatusAttribute()
    {
        $status = 0;
        if($this->deliveryBoy){
            $status = $this->deliveryBoy->status;
        }
        return $status;
    }


}
