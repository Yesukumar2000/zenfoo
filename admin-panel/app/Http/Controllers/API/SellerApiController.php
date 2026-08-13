<?php

namespace App\Http\Controllers\API;

use App\Helpers\CommonHelper;
use App\Http\Controllers\Controller;
use App\Models\Admin;
use App\Models\Category;
use App\Models\City;
use App\Models\OrderItem;
use App\Models\Role;
use App\Models\Seller;
use App\Models\SellerCommission;
use App\Models\SellerWalletTransaction;
use App\Models\Setting;
use App\Models\Tax;
use App\Services\SellerNotificationService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class SellerApiController extends Controller
{
    public function getSellers(Request $request){
        $filterStatus = $request->filterStatus ?? [1,3,7]; // Display all active, deactive & deleted
        if (!is_array($filterStatus)) {
            $filterStatus = [$filterStatus];
        }
        $sellers = Seller::with('city', 'categories');

        // Filter out Super Mart sellers (store_id = 17)
        // $sellers = $sellers->where('store_id', '!=', 17);

        if(isset($filterStatus) && $filterStatus != ""){
            $sellers = $sellers->whereIn("status",$filterStatus);
        }

        // Filter by store_id if provided
        if($request->filled('store_id')){
            $sellers = $sellers->where('store_id', $request->store_id);
        }

        $sellers = $sellers->orderBy('id','DESC')->get();

        // Filter by city/zone using seller lat_long against city boundary
        if($request->filled('city_id')){

            // "other" = sellers with no lat_long OR whose lat_long falls outside all city boundaries
            if($request->city_id === 'other'){
                $allCities = City::all();
                $sellers = $sellers->filter(function($seller) use ($allCities) {
                    return !$this->isInAnyCity($seller, $allCities);
                })->values();

            } else {
                $city = City::find($request->city_id);
                if($city){
                    $sellers = $sellers->filter(function($seller) use ($city) {
                        return $this->isSellerInCity($seller, $city);
                    })->values();
                }
            }
        }

        return CommonHelper::responseWithData($sellers);
    }

    /**
     * Ray Casting algorithm — checks if a lat/lng point lies inside a polygon.
     * Polygon points are expected as array of ['lat' => ..., 'lng' => ...].
     */
    private function isPointInPolygon(float $lat, float $lng, array $polygon): bool
    {
        $count   = count($polygon);
        $inside  = false;
        $j       = $count - 1;

        for($i = 0; $i < $count; $j = $i++){
            $xi = floatval($polygon[$i]['lat']);
            $yi = floatval($polygon[$i]['lng']);
            $xj = floatval($polygon[$j]['lat']);
            $yj = floatval($polygon[$j]['lng']);

            if((($yi > $lng) !== ($yj > $lng)) &&
               ($lat < ($xj - $xi) * ($lng - $yi) / ($yj - $yi) + $xi)){
                $inside = !$inside;
            }
        }

        return $inside;
    }

    /**
     * Haversine formula — returns the great-circle distance in km between two coordinates.
     */
    private function haversineDistance(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $R    = 6371; // Earth radius in km
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a    = sin($dLat / 2) ** 2
              + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;
        return $R * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    /**
     * Check if a seller's lat_long falls inside a given city boundary.
     * Returns false if seller has no lat_long.
     */
    private function isSellerInCity($seller, $city): bool
    {
        if (empty($seller->lat_long)) {
            return false;
        }

        $parts = explode(',', $seller->lat_long);
        if (count($parts) < 2) {
            return false;
        }

        $lat = floatval(trim($parts[0]));
        $lng = floatval(trim($parts[1]));

        if ($city->geolocation_type === 'polygon') {
            $polygon = is_string($city->boundary_points)
                ? json_decode($city->boundary_points, true)
                : $city->boundary_points;

            if (empty($polygon) || !is_array($polygon)) {
                return false;
            }

            return $this->isPointInPolygon($lat, $lng, $polygon);

        } elseif ($city->geolocation_type === 'radius') {
            $distance = $this->haversineDistance(
                $lat, $lng,
                floatval($city->latitude),
                floatval($city->longitude)
            );
            return $distance <= floatval($city->radius);
        }

        return false;
    }

    /**
     * Check if a seller belongs to ANY of the given cities.
     * Returns false if seller has no lat_long (they are "Other").
     */
    private function isInAnyCity($seller, $allCities): bool
    {
        if (empty($seller->lat_long)) {
            return false;
        }

        foreach ($allCities as $city) {
            if ($this->isSellerInCity($seller, $city)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Get Super Mart sellers (store_id = 17)
     */
    public function getMarts(Request $request){
        $filterStatus = $request->filterStatus ?? [1,3]; // Display all active & deactive
        if (!is_array($filterStatus)) {
            $filterStatus = [$filterStatus];
        }
        $sellers = Seller::with('city', 'categories');

        // Only get Super Mart sellers (store_id = 17)
        $sellers = $sellers->where('store_id', 17);

        if(isset($filterStatus) && $filterStatus != ""){
            $sellers = $sellers->whereIn("status",$filterStatus);
        }
        $sellers = $sellers->orderBy('id','DESC')->get();

        // Filter by city/zone using seller lat_long against city boundary (same as getSellers)
        if($request->filled('city_id')){
            if($request->city_id === 'other'){
                $allCities = City::all();
                $sellers = $sellers->filter(function($seller) use ($allCities) {
                    return !$this->isInAnyCity($seller, $allCities);
                })->values();
            } else {
                $city = City::find($request->city_id);
                if($city){
                    $sellers = $sellers->filter(function($seller) use ($city) {
                        return $this->isSellerInCity($seller, $city);
                    })->values();
                }
            }
        }

        return CommonHelper::responseWithData($sellers);
    }

    public function save(Request $request){

        $validator = Validator::make($request->all(),[
            'name' => 'required',
            'email' => 'email|required|unique:admins',
            'mobile' => 'required',
            'password' => 'min:6|required_with:confirm_password|same:confirm_password',
            'store_name' => 'required',
            'categories_ids' => 'required',
            'pan_number' => 'required',
            'commission' => 'required',
            'national_id_card' => 'required|mimes:jpeg,jpg,png,gif,pdf',
            'address_proof' => 'required|mimes:jpeg,jpg,png,gif,pdf',
            'store_logo' => 'required|mimes:jpeg,jpg,png,gif',
            'city_id' => 'required',
            'latitude' => 'required',
            'longitude' => 'required',
            'bank_name' => 'required',
            'account_number' => 'required',
            'ifsc_code' => 'required',
            'account_name' => 'required',
            'pickup_store_address' => 'required_if:self_pickup_mode,1',
            'pickup_latitude' => 'required_if:self_pickup_mode,1',
            'pickup_longitude' => 'required_if:self_pickup_mode,1',
            'pickup_store_timings' => 'required_if:self_pickup_mode,1'
        ]);
        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        DB::beginTransaction();
        try {
            $data = array();
            $data['username'] = $request->name;
            $data['email'] = $request->email;
            $data['password'] = bcrypt($request->password);
            $data['role_id'] = Role::$roleSeller;
            $data['created_by'] = 0;
            $admin = Admin::create($data);

            $record = new Seller();
            $record->admin_id = $admin->id;
            $record->name = $request->name;
            $record->email = $request->email;
            $record->mobile = $request->mobile;
            $record->store_url = $request->store_url;
            $record->store_name = $request->store_name;
            $record->street = $request->street;
            $record->pincode_id = ($request->pincode_id)??0;
            $record->city_id = $request->city_id;
            $record->categories = $request->categories_ids;
            $record->state = $request->state;
            $record->account_number = $request->account_number;
            $record->bank_ifsc_code = $request->ifsc_code;
            $record->bank_name = $request->bank_name;
            $record->account_name = $request->account_name;
            $record->commission = $request->commission;
            $record->tax_name = $request->tax_name;
            $record->tax_number = $request->tax_number;
            $record->pan_number = $request->pan_number;
            $record->latitude = $request->latitude;
            $record->longitude = $request->longitude;
            $record->place_name = $request->place_name;
            $record->formatted_address = $request->formatted_address;

            $record->store_description = $request->store_description;
            $record->require_products_approval = $request->require_products_approval;
            $record->customer_privacy = $request->customer_privacy;
            $record->view_order_otp = $request->view_order_otp;
            $record->assign_delivery_boy = $request->assign_delivery_boy;
            $record->change_order_status_delivered = $request->change_order_status_delivered;
            $record->self_pickup_mode = $request->self_pickup_mode ?? 0;
            $record->pickup_store_address = $request->pickup_store_address;
            $record->pickup_latitude = $request->pickup_latitude;
            $record->pickup_longitude = $request->pickup_longitude;
            $record->pickup_store_timings = $request->pickup_store_timings;
            
            $record->status = Seller::$statusActive;
            $record->slug = Str::slug($request->name);

            if($request->hasFile('store_logo')){
                $file = $request->file('store_logo');
                $fileName = time().'_'.rand(1111,99999).'.'.$file->getClientOriginalExtension();
                $image = Storage::disk('public')->putFileAs('sellers', $file, $fileName);
                $record->logo = $image;
            }

            if($request->hasFile('national_id_card')){
                $file = $request->file('national_id_card');
                $fileName = time().'_'.rand(1111,99999).'.'.$file->getClientOriginalExtension();
                $image = Storage::disk('public')->putFileAs('sellers', $file, $fileName);
                $record->national_identity_card = $image;
            }

            if($request->hasFile('address_proof')){
                $file = $request->file('address_proof');
                $fileName = time().'_'.rand(1111,99999).'.'.$file->getClientOriginalExtension();
                $image = Storage::disk('public')->putFileAs('sellers', $file,$fileName);
                $record->address_proof = $image;
            }
            $record->save();

            $categories_ids = explode(',',$request->categories_ids);
            foreach ($categories_ids as $key => $category_id){
                $commission = new SellerCommission();
                $commission->seller_id = $record->id;
                $commission->category_id = $category_id;
                $commission->save();
            }

            DB::commit();
        } catch (\Exception $e) {
            Log::info("Error : ".$e->getMessage());
            DB::rollBack();
            // throw $e;
            return CommonHelper::responseError("Something Went Wrong!");
        }


        try {
            CommonHelper::sendMailAdminStatus("seller", $record, $record->status, $request->email);
        }catch ( \Exception $e){
            Log::error("Add Seller status send mail error",[$e->getMessage()] );
        }

        return CommonHelper::responseSuccess("Seller Saved Successfully!");
    }
    public function edit($id){
        $seller = Seller::with('admin')->where('id',$id)->first();
        
        if(!$seller){
            return CommonHelper::responseError("Seller Not found!");
        }
        
        if ($seller->city_id && $seller->admin && $seller->admin->seller) {
            $cityIds = explode(',', $seller->city_id);
            $cities = City::whereIn('id', $cityIds)->get(['id', 'name']);
            
            $seller->admin->seller->cities = $cities;
        }
        
        return CommonHelper::responseWithData($seller);
    }


    public function update(Request $request){
        $validator = Validator::make($request->all(),[
            'name' => 'required',
            'email' => 'email|required|unique:admins,email,'.$request->admin_id,
            'mobile' => 'required',
            'confirm_password' => 'same:password',
            'store_name' => 'required',
            'categories_ids' => 'required',
            'pan_number' => 'required',
            'commission' => 'required',
            'city_id' => 'required',
            'latitude' => 'required',
            'longitude' => 'required',
            'pickup_store_address' => 'required_if:self_pickup_mode,1',
            'pickup_latitude' => 'required_if:self_pickup_mode,1',
            'pickup_longitude' => 'required_if:self_pickup_mode,1',
            'pickup_store_timings' => 'required_if:self_pickup_mode,1'

        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }
        if(isset($request->id)){
            $record = Seller::find($request->id);

            if($record) {

                $oldStatus = $record->status;
                DB::beginTransaction();

                    $data = array();
                    $data['username'] = $request->name;
                    $data['email'] = $request->email;

                    if (isset($request->password) && $request->password != "") {

                        $data['password'] = bcrypt($request->password);
                    }
                    Admin::where('id', $request->admin_id)->update($data);

                    $record->name = $request->name;
                    $record->email = $request->email;
                  
                    $record->mobile = $request->mobile;
                    $record->store_name = $request->store_name;

                    $record->store_url = $request->store_url;
                    $record->street = $request->street;
                    $record->pincode_id = ($request->pincode_id) ?? 0;
                    $record->city_id = $request->city_id;
                    $record->categories = $request->categories_ids;
                    $record->state = $request->state;
                    $record->account_number = $request->account_number;
                    $record->bank_ifsc_code = $request->ifsc_code;
                    $record->bank_name = $request->bank_name;
                    $record->account_name = $request->account_name;
                    $record->commission = $request->commission;
                    $record->tax_name = $request->tax_name;
                    $record->tax_number = $request->tax_number;
                    $record->pan_number = $request->pan_number;
                    $record->latitude = $request->latitude;
                    $record->longitude = $request->longitude;
                    $record->place_name = $request->place_name;
                    $record->formatted_address = $request->formatted_address;

                    $record->store_description = $request->store_description;
                    $record->require_products_approval = $request->require_products_approval;
                    $record->customer_privacy = $request->customer_privacy;
                    $record->view_order_otp = $request->view_order_otp;
                    $record->assign_delivery_boy = $request->assign_delivery_boy;
                    $record->change_order_status_delivered = $request->change_order_status_delivered;
                    $record->self_pickup_mode = $request->self_pickup_mode ?? 0;
                    $record->pickup_store_address = $request->pickup_store_address;
                    $record->pickup_latitude = $request->pickup_latitude;
                    $record->pickup_longitude = $request->pickup_longitude;
                    $record->pickup_store_timings = $request->pickup_store_timings;
                    
                    $record->status = $request->status;
                    $record->remark = $request->remark;
                    $record->slug = Str::slug($request->name);

                    if ($request->hasFile('store_logo')) {
                        $file = $request->file('store_logo');
                        $fileName = time() . '_' . rand(1111, 99999) . '.' . $file->getClientOriginalExtension();
                        $image = Storage::disk('public')
                            ->putFileAs('sellers', $file, $fileName);
                        $record->logo = $image;
                    }
                    if ($request->hasFile('national_id_card')) {
                        $file = $request->file('national_id_card');
                        $fileName = time() . '_' . rand(1111, 99999) . '.' . $file->getClientOriginalExtension();
                        $image = Storage::disk('public')->putFileAs('sellers', $file, $fileName);
                        $record->national_identity_card = $image;
                    }
                    if ($request->hasFile('address_proof')) {
                        $file = $request->file('address_proof');
                        $fileName = time() . '_' . rand(1111, 99999) . '.' . $file->getClientOriginalExtension();
                        $image = Storage::disk('public')->putFileAs('sellers', $file, $fileName);
                        $record->address_proof = $image;
                    }
                    $record->save();
                    $categories_ids = explode(',',$request->categories_ids);
                    foreach ($categories_ids as $key => $category_id) {
                        // Check if an entry already exists with the given seller_id and category_id
                        $existingCommission = SellerCommission::where('seller_id', $record->id)
                                                              ->where('category_id', $category_id)
                                                              ->first();
                    
                        if (!$existingCommission) {
                            // If no existing entry found, create a new one
                            $commission = new SellerCommission();
                            $commission->seller_id = $record->id;
                            $commission->category_id = $category_id;
                            $commission->save();
                        }
                    }

                    DB::commit();
               
                if($oldStatus !== $record->status){
                    try {
                        CommonHelper::sendMailAdminStatus("seller", $record, $record->status, $request->email);
                    }catch ( \Exception $e){
                        Log::error("Seller Update status send mail error",[$e->getMessage()] );
                    }
                }

            }else{
                return CommonHelper::responseSuccess("Seller Not Found!");
            }
        }
        return CommonHelper::responseSuccess("Seller Updated Successfully!");
    }

    public function delete(Request $request){
        if(isset($request->id)){
            $seller = Seller::find($request->id);
            if($seller){
                @Storage::disk('public')->delete($seller->logo);
                @Storage::disk('public')->delete($seller->national_identity_card);
                @Storage::disk('public')->delete($seller->address_proof);
                $seller->delete();
                return CommonHelper::responseSuccess("Seller Deleted Successfully!");
            }else{
                return CommonHelper::responseSuccess("Seller Already Deleted!");
            }
        }
    }

    public function updateStatus(Request $request)
    {
        $seller_id = $request->id ?? auth()->user()->seller->id ?? null;

        if ($seller_id) {
            $seller = Seller::find($seller_id);

           if ($seller) {
                // Validate all documents are approved before approving seller
                if ((int)$request->status === Seller::$statusActive) {
                    $unapprovedDocs = [];

                    // Check PAN Card
                    if ($seller->pan_status != 1) {
                        $unapprovedDocs[] = 'PAN Card';
                    }

                    // Check FSSAI Certificate
                    if ($seller->fssai_status != 1) {
                        $unapprovedDocs[] = 'FSSAI Certificate';
                    }

                    // Check Aadhar Card
                    if ($seller->aadhar_status != 1) {
                        $unapprovedDocs[] = 'Aadhar Card';
                    }

                    // Check Seller Agreement
                    if ($seller->agreement_status != 1) {
                        $unapprovedDocs[] = 'Seller Agreement';
                    }

                    // If any documents are not approved, prevent seller approval
                    if (!empty($unapprovedDocs)) {
                        return CommonHelper::responseError(
                            'Cannot approve seller. The following documents are not approved: ' .
                            implode(', ', $unapprovedDocs) .
                            '. Please approve all documents before activating the seller.'
                        );
                    }
                }

                $seller->status = (int)$request->status; // Ensure status is an integer
                $seller->remark = $request->remark ?? "";
                $seller->save();
            
                // Match status with strict comparison
                $status_name = match ((int)$request->status) {
                    Seller::$statusActive => Seller::$Active,
                    Seller::$statusDeactivated => Seller::$Deactivated,
                    Seller::$statusRejected => Seller::$Rejected,
                    Seller::$statusRegistered => Seller::$Registered,
                    Seller::$statusRemoved => Seller::$Removed,
                    default => 'Unknown Status', // Handles unexpected cases
                };

                // Send push notification to seller about status change
                try {
                    $notificationTitle = match ((int)$request->status) {
                        Seller::$statusActive => 'Account Approved!',
                        Seller::$statusDeactivated => 'Account Deactivated',
                        Seller::$statusRejected => 'Account Rejected',
                        default => 'Account Status Updated',
                    };

                    $notificationMessage = match ((int)$request->status) {
                        Seller::$statusActive => 'Congratulations! Your seller account has been approved. You can now start selling on Zenfoo.',
                        Seller::$statusDeactivated => 'Your seller account has been deactivated. Please contact support for more information.',
                        Seller::$statusRejected => 'Your seller account application has been rejected.' . ($request->remark ? ' Reason: ' . $request->remark : ''),
                        default => 'Your account status has been updated to: ' . $status_name,
                    };

                    SellerNotificationService::send(
                        sellerId: $seller->id,
                        title: $notificationTitle,
                        message: $notificationMessage,
                        image: '',
                        pageNavigation: 'profile',
                        navigationId: null
                    );

                    Log::info("Seller status notification sent", [
                        'seller_id' => $seller->id,
                        'status' => $status_name
                    ]);
                } catch (\Exception $e) {
                    Log::error("Seller status push notification error", [$e->getMessage()]);
                }

                // Send admin notification email
                $user = Admin::find($seller->admin_id);
                if ($user) {
                    try {
                        CommonHelper::sendMailAdminStatus("seller", $seller, $seller->status, $user->email);
                    } catch (\Exception $e) {
                        Log::error("Approve Seller status send mail error", [$e->getMessage()]);
                    }
                }

                return CommonHelper::responseSuccess("Seller " . $status_name . " Successfully!");
            } else {
                return CommonHelper::responseError("Seller Not Found!");
            }
        }

        return CommonHelper::responseError("Seller ID is required.");
    }
    public function getStatus(Request $request)
    {
        $seller_id = $request->id ?? auth()->user()->seller->id ?? null;

        if (!$seller_id) {
            return CommonHelper::responseError("Seller ID is required.");
        }

        $seller = Seller::find($seller_id);

        if (!$seller) {
            return CommonHelper::responseError("Seller Not Found!");
        }

        $data = ['status' => $seller->status];

        return CommonHelper::responseWithData($data);
    }



    public function updateCommission(){
        $date = date('Y-m-d');
        $result = OrderItem::select('categories.id as category_id', 'order_items.id', DB::raw('date(order_items.created_at) as order_date'),
            'order_items.order_id','order_items.product_variant_id','order_items.seller_id','order_items.sub_total','products.return_days')
            ->leftJoin('product_variants', 'order_items.product_variant_id', '=', 'product_variants.id')
            ->leftJoin('products', 'product_variants.product_id', '=', 'products.id')
            ->leftJoin('categories', 'products.category_id', '=', 'categories.id')
            ->where('order_items.active_status','=','delivered')
            ->where('order_items.is_credited','=', 0)
            ->where(DB::raw('DATE_ADD(DATE_FORMAT(order_items.created_at, "%Y-%m-%d"), INTERVAL products.return_days DAY)'),'<', $date)
            ->orderBy('order_items.id','DESC')
            ->get();
       
        if (!empty($result) && $result->count() !== 0) {
            foreach ($result as $row) {
                $seller_info = Seller::select('commission', 'email', 'name')->where('id',$row['seller_id'])->first();
                $commission = SellerCommission::select('commission')->where('seller_id',$row['seller_id'])->where('category_id',$row['category_id'])->first();

                $commission_perct = isset($commission['commission']) && $commission['commission'] > 0 ? $commission['commission'] : $seller_info['commission'];
                $commission_amt = $row['sub_total'] / 100 * $commission_perct;
                $transfer_amt = $row['sub_total'] - $commission_amt;

                /* get seller balance */
                $balance = Seller::select('balance')->where('id',$row['seller_id'])->first();
                $user_wallet_balance = $balance["$balance"];
                $amt = ($transfer_amt + $user_wallet_balance);

                /* update seller commission */
                DB::beginTransaction();
                try {
                    $seller = Seller::find($row['seller_id']);
                    $seller->balance = $seller->balance + $amt;
                    $seller->save();

                    $order_item = OrderItem::find($row['id']);
                    $order_item->is_credited = 1;
                    $order_item->save();

                    $sellerWalletTransactions = new SellerWalletTransaction();
                    $sellerWalletTransactions->seller_id = $row['seller_id'];
                    $sellerWalletTransactions->type = 'credit';
                    $sellerWalletTransactions->amount = $transfer_amt;
                    $sellerWalletTransactions->message = 'Commission';
                    $sellerWalletTransactions->status = 1;
                    $sellerWalletTransactions->save();

                    /* send notification  */
                    $message = "Dear, " . ucwords($seller_info['name']) . " Commission for  order item  ID : #" . $row['id'] . " was transfered. Please take note of it.";

                } catch (\Exception $e) {
                    DB::rollBack();
                    Log::info("Error : ".$e->getMessage());
                    throw $e;
                    return CommonHelper::responseError("Something Went Wrong!");
                }
                return CommonHelper::responseSuccess("Seller(s) commission updated successfully");
            }
        } else {
            return CommonHelper::responseError("Seller(s) commission already updated");
        }

    }
    public function getSellerCommission(){
        $settings = Setting::where('variable', 'seller_commission')->first();
        if (!empty($settings) && $settings->count() !== 0) {
            return CommonHelper::responseWithData($settings);
        } else {
            return CommonHelper::responseError("Seller(s) commission not available");
        }

    }

    /**
     * Update individual document status for a seller.
     * document_type: pan | fssai | aadhar | agreement
     * status: 0 = pending, 1 = approved, 2 = rejected
     */
    public function updateDocumentStatus(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'seller_id'     => 'required|exists:sellers,id',
            'document_type' => 'required|in:pan,fssai,aadhar,agreement',
            'status'        => 'required|in:0,1,2',
        ]);

        if ($validator->fails()) {
            return CommonHelper::responseError($validator->errors()->first());
        }

        $seller = Seller::find($request->seller_id);

        $column = $request->document_type . '_status'; // pan_status | fssai_status | aadhar_status | agreement_status
        $seller->{$column} = (int) $request->status;
        $seller->save();

        $statusLabel = match ((int) $request->status) {
            1 => 'Approved',
            2 => 'Rejected',
            default => 'Pending',
        };

        $docLabel = match ($request->document_type) {
            'pan'       => 'PAN Card',
            'fssai'     => 'FSSAI Certificate',
            'aadhar'    => 'Aadhar Card',
            'agreement' => 'Seller Agreement',
            default     => ucfirst($request->document_type),
        };

        $notificationTitle = $docLabel . ' ' . $statusLabel;
        $notificationMessage = match ((int) $request->status) {
            1 => 'Your ' . $docLabel . ' has been approved successfully.',
            2 => 'Your ' . $docLabel . ' has been rejected. Please contact support for more information.',
            default => 'Your ' . $docLabel . ' status has been reset to pending review.',
        };

        try {
            SellerNotificationService::send(
                sellerId: $seller->id,
                title: $notificationTitle,
                message: $notificationMessage,
                image: '',
                pageNavigation: 'profile',
                navigationId: null
            );
        } catch (\Exception $e) {
            Log::error('Document status notification error', [
                'seller_id' => $seller->id,
                'document_type' => $request->document_type,
                'error' => $e->getMessage(),
            ]);
        }

        return CommonHelper::responseSuccess($docLabel . ' ' . $statusLabel . ' successfully!');
    }

    /**
     * Get sellers by store ID (for pre-order seller assignment)
     */
    public function getSellersByStore($storeId)
    {
        try {
            $storeId = (int) $storeId;
            $now = now()->setTimezone('Asia/Kolkata')->format('H:i:s');

            // Fetch active sellers with shop open and within opening time
            // Same filters as ViewOrder eligible sellers logic
            $sellers = \DB::table('sellers')
                ->where('status', 1)
                ->where('shop_status', 1)
                ->where(function ($q) use ($now) {
                    $q->whereNull('shop_opening_time')
                      ->orWhereRaw('? >= shop_opening_time', [$now]);
                })
                ->select('id', 'name', 'store_name', 'store_id', 'other_store_ids')
                ->orderBy('name', 'ASC')
                ->get();

            // Filter: seller's primary store_id matches OR store_id is in other_store_ids
            $filtered = $sellers->filter(function ($seller) use ($storeId) {
                if ((int) $seller->store_id === $storeId) {
                    return true;
                }
                if (!empty($seller->other_store_ids)) {
                    $otherIds = json_decode($seller->other_store_ids, true);
                    if (is_array($otherIds) && in_array($storeId, array_map('intval', $otherIds))) {
                        return true;
                    }
                }
                return false;
            })->values();

            return response()->json([
                'status' => 1,
                'data' => $filtered
            ]);
        } catch (\Exception $e) {
            \Log::error('Error fetching sellers by store', [
                'store_id' => $storeId,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 0,
                'message' => 'Failed to fetch sellers'
            ], 500);
        }
    }
}
